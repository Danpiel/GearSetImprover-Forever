-- ============================================================
-- GearSetImprover - SocketBonus.lua (WoW Forever)
-- Evaluates empty socket slots on items using GSI_Config.SocketValue.
-- ============================================================

GSI_SocketBonus = {}

local function SafeGetItemStats(itemLink)
    if C_Item and C_Item.GetItemStats then
        return C_Item.GetItemStats(itemLink)
    end
    if GetItemStats then
        return GetItemStats(itemLink)
    end
    return nil
end

local SOCKET_STAT_KEYS = {
    "EMPTY_SOCKET_PRISMATIC",
    "EMPTY_SOCKET_RED",
    "EMPTY_SOCKET_YELLOW",
    "EMPTY_SOCKET_BLUE",
    "EMPTY_SOCKET_META",
}

-- Returns the total number of empty sockets on an item
function GSI_SocketBonus:GetSocketCount(itemLink)
    if not itemLink then return 0 end
    local stats = SafeGetItemStats(itemLink)
    if not stats then return 0 end

    local socketCount = 0
    for _, key in ipairs(SOCKET_STAT_KEYS) do
        local count = stats[key]
        if type(count) == "number" and count > 0 then
            socketCount = socketCount + count
        end
    end
    return socketCount
end

-- Returns the score contribution of all empty sockets on an item
function GSI_SocketBonus:GetSocketScore(itemLink)
    local socketCount = self:GetSocketCount(itemLink)
    if socketCount == 0 then return 0 end
    local socketVal = (GSI_Config and GSI_Config.SocketValue) or 0
    return socketCount * socketVal
end
