-- ============================================================
-- GearSetImprover - TooltipCache.lua (WoW Forever)
-- Zero-Allocation O(1) LRU Tooltip Cache for GSI Scores & Lines
-- ============================================================

GSI_TooltipCache = {
    capacity = 300,
    count = 0,
    head = nil,
    tail = nil,
    map = {},            -- [key] -> node
    nodePool = {},       -- recycled { key, lines, prev, next }
    containerPool = {},  -- recycled { line1, line2, ... }
    linePool = {},       -- recycled { text, r, g, b, wrap }
    stats = {
        hits = 0,
        misses = 0,
        evictions = 0,
        invalidations = 0,
    },
    revision = 1,
}

local Cache = GSI_TooltipCache
local nodePoolTop = 0
local containerPoolTop = 0
local linePoolTop = 0

-- ----------------------------------------------------------------------------
-- Internal Pool Helpers (O(1) stack operations, zero table.insert/remove)
-- ----------------------------------------------------------------------------
local function PushNode(node)
    node.key = nil
    node.lines = nil
    node.prev = nil
    node.next = nil
    local maxPool = (Cache.capacity or 300) + 16
    if nodePoolTop < maxPool then
        nodePoolTop = nodePoolTop + 1
        Cache.nodePool[nodePoolTop] = node
    end
end

local function PopNode()
    if nodePoolTop > 0 then
        local node = Cache.nodePool[nodePoolTop]
        Cache.nodePool[nodePoolTop] = nil
        nodePoolTop = nodePoolTop - 1
        return node
    end
    return {}
end

local function ReleaseLinesContainerInternal(container)
    if type(container) ~= "table" then return end

    local linePool = Cache.linePool
    local maxLinePool = (Cache.capacity or 300) * 10
    for i = #container, 1, -1 do
        local line = container[i]
        container[i] = nil
        if type(line) == "table" then
            line.text = nil
            line.r = nil
            line.g = nil
            line.b = nil
            line.wrap = nil
            line.bold = nil
            line.right = nil
            line.divider = nil
            if linePoolTop < maxLinePool then
                linePoolTop = linePoolTop + 1
                linePool[linePoolTop] = line
            end
        end
    end

    local maxContainerPool = (Cache.capacity or 300) + 32
    if containerPoolTop < maxContainerPool then
        containerPoolTop = containerPoolTop + 1
        Cache.containerPool[containerPoolTop] = container
    end
end

-- ----------------------------------------------------------------------------
-- Doubly Linked List Helpers (MRU at head, LRU at tail)
-- ----------------------------------------------------------------------------
local function UnlinkNode(node)
    local prev = node.prev
    local nxt = node.next
    if prev then
        prev.next = nxt
    else
        Cache.head = nxt
    end
    if nxt then
        nxt.prev = prev
    else
        Cache.tail = prev
    end
    node.prev = nil
    node.next = nil
end

local function InsertAtHead(node)
    local head = Cache.head
    node.prev = nil
    node.next = head
    if head then
        head.prev = node
    end
    Cache.head = node
    if not Cache.tail then
        Cache.tail = node
    end
end

local function MoveToHead(node)
    if Cache.head == node then return end
    UnlinkNode(node)
    InsertAtHead(node)
end

local function EvictTailNode()
    local node = Cache.tail
    if not node then return nil end

    Cache.stats.evictions = Cache.stats.evictions + 1

    if node.key ~= nil then
        Cache.map[node.key] = nil
        node.key = nil
    end

    if node.lines then
        ReleaseLinesContainerInternal(node.lines)
        node.lines = nil
    end

    local prev = node.prev
    if prev then
        prev.next = nil
        Cache.tail = prev
    else
        Cache.head = nil
        Cache.tail = nil
    end
    node.prev = nil
    node.next = nil

    Cache.count = Cache.count - 1
    return node
end

local function EvictTail()
    local node = EvictTailNode()
    if node then
        PushNode(node)
    end
end

local function RemoveNode(node)
    if not node then return end
    if node.key ~= nil then
        Cache.map[node.key] = nil
    end
    if node.lines then
        ReleaseLinesContainerInternal(node.lines)
    end
    UnlinkNode(node)
    Cache.count = Cache.count - 1
    PushNode(node)
end

-- ----------------------------------------------------------------------------
-- Public Memory Pooling Helpers (Supports both Cache:Method and Cache.Method)
-- ----------------------------------------------------------------------------
function Cache.AcquireLinesContainer()
    if containerPoolTop > 0 then
        local c = Cache.containerPool[containerPoolTop]
        Cache.containerPool[containerPoolTop] = nil
        containerPoolTop = containerPoolTop - 1
        for i = #c, 1, -1 do
            c[i] = nil
        end
        return c
    end
    return {}
end

function Cache.AcquireLine(self_or_text, text_or_r, r_or_g, g_or_b, b_or_wrap, wrap_or_nil)
    local text, r, g, b, wrap
    if self_or_text == Cache then
        text = text_or_r
        r = r_or_g
        g = g_or_b
        b = b_or_wrap
        wrap = wrap_or_nil
    else
        text = self_or_text
        r = text_or_r
        g = r_or_g
        b = g_or_b
        wrap = b_or_wrap
    end

    if linePoolTop > 0 then
        local l = Cache.linePool[linePoolTop]
        Cache.linePool[linePoolTop] = nil
        linePoolTop = linePoolTop - 1
        l.text = text
        l.r = r
        l.g = g
        l.b = b
        l.wrap = wrap
        return l
    end
    return { text = text, r = r, g = g, b = b, wrap = wrap }
end

function Cache.ReleaseLinesContainer(self_or_container, container_or_nil)
    local container = (self_or_container == Cache) and container_or_nil or self_or_container
    ReleaseLinesContainerInternal(container)
end

-- ----------------------------------------------------------------------------
-- Cache Access Methods (Supports both Cache:Method and Cache.Method)
-- ----------------------------------------------------------------------------
function Cache.Get(self_or_key, key_or_nil)
    local key = (self_or_key == Cache) and key_or_nil or self_or_key
    if key == nil then return nil end

    local node = Cache.map[key]
    if node then
        Cache.stats.hits = Cache.stats.hits + 1
        MoveToHead(node)
        return node.lines
    end

    Cache.stats.misses = Cache.stats.misses + 1
    return nil
end

function Cache.Set(self_or_key, key_or_lines, lines_or_nil)
    local key, lines
    if self_or_key == Cache then
        key = key_or_lines
        lines = lines_or_nil
    else
        key = self_or_key
        lines = key_or_lines
    end
    if key == nil then return end

    local cap = Cache.capacity or 300
    if cap < 1 then
        if lines then ReleaseLinesContainerInternal(lines) end
        return
    end

    local existing = Cache.map[key]
    if existing then
        if lines == nil then
            RemoveNode(existing)
            return
        end
        if existing.lines ~= lines then
            ReleaseLinesContainerInternal(existing.lines)
            existing.lines = lines
        end
        MoveToHead(existing)
        return
    end

    if lines == nil then return end

    -- Reuse the evicted LRU node directly when cache is at capacity
    local node
    if Cache.count >= cap then
        while Cache.count > cap and Cache.tail do
            EvictTail()
        end
        if Cache.count == cap and Cache.tail then
            node = EvictTailNode()
        end
    end
    if not node then
        node = PopNode()
    end

    node.key = key
    node.lines = lines
    InsertAtHead(node)

    Cache.map[key] = node
    Cache.count = Cache.count + 1
end

function Cache.Delete(self_or_key, key_or_nil)
    local key = (self_or_key == Cache) and key_or_nil or self_or_key
    if key == nil then return false end

    local node = Cache.map[key]
    if not node then return false end

    RemoveNode(node)
    return true
end
Cache.Remove = Cache.Delete

-- ----------------------------------------------------------------------------
-- Invalidation, Reset & State Management
-- ----------------------------------------------------------------------------
function Cache.Invalidate()
    Cache.stats.invalidations = Cache.stats.invalidations + 1

    local cur = Cache.head
    while cur do
        local nxt = cur.next
        if cur.lines then
            ReleaseLinesContainerInternal(cur.lines)
        end
        PushNode(cur)
        cur = nxt
    end

    Cache.head = nil
    Cache.tail = nil

    if next(Cache.map) ~= nil then
        for k in pairs(Cache.map) do
            Cache.map[k] = nil
        end
    end

    Cache.count = 0
    Cache.revision = Cache.revision + 1
end

function Cache.ResetCache(self_or_flag, flag_or_nil)
    local resetStats = (self_or_flag == Cache) and flag_or_nil or self_or_flag
    Cache.Invalidate()
    if resetStats == true then
        Cache.ResetStats()
    end
end

function Cache.SetCapacity(self_or_cap, cap_or_nil)
    local newCap = (self_or_cap == Cache) and cap_or_nil or self_or_cap
    newCap = tonumber(newCap)
    if not newCap then return end
    if newCap < 1 then newCap = 1 end
    Cache.capacity = math.floor(newCap)
    while Cache.count > Cache.capacity and Cache.tail do
        EvictTail()
    end
end

function Cache.GetRevision()
    return Cache.revision
end

function Cache.GetStats()
    return {
        hits = Cache.stats.hits,
        misses = Cache.stats.misses,
        evictions = Cache.stats.evictions,
        invalidations = Cache.stats.invalidations,
        count = Cache.count,
        capacity = Cache.capacity,
        nodePoolSize = nodePoolTop,
        pooledNodes = nodePoolTop,
        containerPoolSize = containerPoolTop,
        linePoolSize = linePoolTop,
        revision = Cache.revision,
    }
end

function Cache.ResetStats()
    Cache.stats.hits = 0
    Cache.stats.misses = 0
    Cache.stats.evictions = 0
    Cache.stats.invalidations = 0
end
