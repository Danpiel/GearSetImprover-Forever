-- ============================================================
-- GearSetImprover - OptimizationEngine.lua (WoW Forever)
-- Evaluates and optimizes complete equipment setups across slots.
-- Scans bags for upgrades for the active specialization.
-- ============================================================

GSI_OptimizationEngine = {}

local GetItemInfo = (C_Item and C_Item.GetItemInfo) or _G.GetItemInfo or function() return nil end
local GetItemInfoInstant = (C_Item and C_Item.GetItemInfoInstant) or _G.GetItemInfoInstant or function() return nil end

-- Safe slot constants with numeric fallbacks
local INVSLOT_HEAD      = _G.INVSLOT_HEAD or 1
local INVSLOT_NECK      = _G.INVSLOT_NECK or 2
local INVSLOT_SHOULDER  = _G.INVSLOT_SHOULDER or 3
local INVSLOT_CHEST     = _G.INVSLOT_CHEST or 5
local INVSLOT_WAIST     = _G.INVSLOT_WAIST or 6
local INVSLOT_LEGS      = _G.INVSLOT_LEGS or 7
local INVSLOT_FEET      = _G.INVSLOT_FEET or 8
local INVSLOT_WRIST     = _G.INVSLOT_WRIST or 9
local INVSLOT_HAND      = _G.INVSLOT_HAND or 10
local INVSLOT_FINGER1   = _G.INVSLOT_FINGER1 or 11
local INVSLOT_FINGER2   = _G.INVSLOT_FINGER2 or 12
local INVSLOT_TRINKET1  = _G.INVSLOT_TRINKET1 or 13
local INVSLOT_TRINKET2  = _G.INVSLOT_TRINKET2 or 14
local INVSLOT_BACK      = _G.INVSLOT_BACK or 15
local INVSLOT_MAINHAND  = _G.INVSLOT_MAINHAND or 16
local INVSLOT_OFFHAND   = _G.INVSLOT_OFFHAND or 17
local INVSLOT_RANGED    = _G.INVSLOT_RANGED or 18

GSI_OptimizationEngine.EQUIP_SLOTS = {
    INVSLOT_HEAD, INVSLOT_NECK, INVSLOT_SHOULDER, INVSLOT_BACK, INVSLOT_CHEST,
    INVSLOT_WRIST, INVSLOT_HAND, INVSLOT_WAIST, INVSLOT_LEGS, INVSLOT_FEET,
    INVSLOT_FINGER1, INVSLOT_FINGER2,
    INVSLOT_MAINHAND, INVSLOT_OFFHAND, INVSLOT_RANGED
}

local TRINKET_SLOTS = { INVSLOT_TRINKET1, INVSLOT_TRINKET2 }

-- Internal caches (synchronized with ResetCache and GSI_TooltipCache.revision)
local ItemBaseCache = {}
local BaselineCapCache = {}
local SetBonusStatsCache = {}
local SetBonusThresholdsCache = {}
local UniqueInfoCache = {}
local UniqueInfoCount = 0
local MAX_UNIQUE_CACHE = 1000
local LastTooltipRevision = -1

GSI_OptimizationEngine._cacheVersion = 1

local function SafeCopyTable(tbl)
    if type(_G.CopyTable) == "function" then
        return _G.CopyTable(tbl)
    end
    local copy = {}
    if type(tbl) == "table" then
        for k, v in pairs(tbl) do
            if type(v) == "table" then
                copy[k] = SafeCopyTable(v)
            else
                copy[k] = v
            end
        end
    end
    return copy
end

local function SyncCacheRevision()
    local rev = (GSI_TooltipCache and GSI_TooltipCache.revision) or 0
    if rev ~= LastTooltipRevision then
        ItemBaseCache = {}
        BaselineCapCache = {}
        SetBonusStatsCache = {}
        SetBonusThresholdsCache = {}
        LastTooltipRevision = rev
    end
end

local function probeArithmetic(val)
    return val + 0
end

local function GetSafeNumber(val, fallback)
    if type(val) ~= "number" then
        return fallback or 0
    end
    if type(issecretvalue) == "function" and issecretvalue(val) then
        return fallback or 0
    end
    local ok, result = pcall(probeArithmetic, val)
    if ok then
        return result
    end
    return fallback or 0
end

local function GetItemEquipLoc(link)
    if not link or link == "" then return nil end
    local equipLoc = select(9, GetItemInfo(link))
    if not equipLoc or equipLoc == "" or type(equipLoc) ~= "string" then
        equipLoc = select(4, GetItemInfoInstant(link))
    end
    if type(equipLoc) == "string" and equipLoc ~= "" then
        return equipLoc
    end
    return nil
end

local function GetItemClassSubClass(link)
    if not link or link == "" then return nil, nil end
    local _, _, _, _, _, _, _, _, _, _, _, classID, subClassID = GetItemInfo(link)
    if not classID then
        _, _, _, _, _, classID, subClassID = GetItemInfoInstant(link)
    end
    return classID, subClassID
end

local function GetPlayerClassKey()
    if GSI_ClassicData and GSI_ClassicData.GetPlayerClass then
        return GSI_ClassicData:GetPlayerClass()
    end
    return select(2, UnitClass("player")) or "WARRIOR"
end

-- Safe container APIs (compatible with C_Container and legacy globals)
local function GetNumBagSlots(bag)
    if C_Container and C_Container.GetContainerNumSlots then
        return C_Container.GetContainerNumSlots(bag) or 0
    elseif GetContainerNumSlots then
        return GetContainerNumSlots(bag) or 0
    end
    return 0
end

local function GetBagItemLink(bag, slot)
    if C_Container and C_Container.GetContainerItemLink then
        return C_Container.GetContainerItemLink(bag, slot)
    elseif GetContainerItemLink then
        return GetContainerItemLink(bag, slot)
    end
    return nil
end

-- Weapon subclasses per class (WoW Forever 1.60.1):
-- 0=1H Axe, 1=2H Axe, 2=Bow, 3=Gun, 4=1H Mace, 5=2H Mace, 6=Polearm,
-- 7=1H Sword, 8=2H Sword, 10=Staff, 13=Fist, 14=Misc, 15=Dagger,
-- 16=Thrown, 18=Crossbow, 19=Wand, 20=Fishing Pole
local CLASS_ALLOWED_WEAPONS = {
    WARRIOR = { [0]=true, [1]=true, [2]=true, [3]=true, [4]=true, [5]=true, [6]=true, [7]=true, [8]=true, [10]=true, [13]=true, [14]=true, [15]=true, [16]=true, [18]=true, [20]=true },
    PALADIN = { [0]=true, [1]=true, [4]=true, [5]=true, [6]=true, [7]=true, [8]=true, [14]=true, [20]=true },
    HUNTER  = { [0]=true, [1]=true, [2]=true, [3]=true, [6]=true, [7]=true, [8]=true, [10]=true, [13]=true, [14]=true, [15]=true, [16]=true, [18]=true, [20]=true },
    ROGUE   = { [0]=true, [2]=true, [3]=true, [4]=true, [7]=true, [13]=true, [14]=true, [15]=true, [16]=true, [18]=true, [20]=true },
    PRIEST  = { [4]=true, [10]=true, [14]=true, [15]=true, [19]=true, [20]=true },
    SHAMAN  = { [0]=true, [1]=true, [4]=true, [5]=true, [10]=true, [13]=true, [14]=true, [15]=true, [20]=true },
    MAGE    = { [7]=true, [10]=true, [14]=true, [15]=true, [19]=true, [20]=true },
    WARLOCK = { [7]=true, [10]=true, [14]=true, [15]=true, [19]=true, [20]=true },
    DRUID   = { [4]=true, [5]=true, [6]=true, [10]=true, [13]=true, [14]=true, [15]=true, [20]=true },
}

local _optScanTip = nil
local TOOLTIP_LINE_PREFIXES = { "GSI_OptScanTooltipTextLeft", "GSI_OptScanTooltipTextRight" }
local function EnsureOptScanTooltip()
    if not _optScanTip then
        _optScanTip = CreateFrame("GameTooltip", "GSI_OptScanTooltip", nil, "GameTooltipTemplate")
        _optScanTip:SetOwner(WorldFrame or UIParent, "ANCHOR_NONE")
    end
    return _optScanTip
end

local function IsRedUnmetRequirementLine(fontString, ignoreLevel)
    if not fontString or not fontString.GetText then return false end
    local text = fontString:GetText()
    if not text or text == "" then return false end
    local r, g, b = fontString:GetTextColor()
    if not (r and g and b and r > 0.85 and g < 0.25 and b < 0.25) then
        return false
    end
    local ltext = text:lower()
    local isDurability = ltext:find("durability") or ltext:find("haltbarkeit")
    if isDurability then return false end
    local isLevel = ignoreLevel and (
        ltext:find("require.*level") or ltext:find("benötigt.*stufe")
        or ltext:find("level%s*%d+") or ltext:find("stufe%s*%d+")
    )
    return not isLevel
end

-- Checks tooltip text for red requirement lines (e.g. untrained weapon skill, level too low, class restriction)
local function HasUnmetRequirements(link, bag, slot, ignoreLevel)
    local tip = EnsureOptScanTooltip()
    tip:ClearLines()

    local ok = false
    if bag and slot then
        local bagFn = (C_Container and C_Container.GetContainerItemLink) or GetContainerItemLink
        local curLink = bagFn and bagFn(bag, slot)
        if curLink then
            ok = pcall(function() tip:SetBagItem(bag, slot) end)
        end
    end
    if not ok or tip:NumLines() == 0 then
        if link then
            ok = pcall(function() tip:SetHyperlink(link) end)
        end
    end
    if not ok then return false end

    local numLines = tip:NumLines() or 0
    if numLines == 0 then return false end

    for i = 1, numLines do
        if IsRedUnmetRequirementLine(_G["GSI_OptScanTooltipTextLeft" .. i], ignoreLevel)
            or IsRedUnmetRequirementLine(_G["GSI_OptScanTooltipTextRight" .. i], ignoreLevel) then
            return true
        end
    end
    return false
end

-- Parses a single tooltip text line for Unique / Unique-Equipped tags (EN & DE)
local function ParseUniqueLine(rawText)
    if not rawText or rawText == "" then return nil end
    local clean = rawText:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
    clean = clean:gsub("^%s+", ""):gsub("%s+$", "")
    if clean == "" then return nil end
    local lower = clean:lower()

    if not lower:find("^unique") and not lower:find("^einzigartig") then
        return nil
    end

    -- 1. Standalone Unique / Unique-Equipped
    if lower == "unique" or lower == "einzigartig"
        or lower == "unique-equipped" or lower == "unique equipped"
        or lower == "einzigartig anlegbar" or lower == "einzigartig-anlegbar" then
        return true, 1, nil
    end

    -- 2. Unique (N) / Unique-Equipped (N) without family
    local n = lower:match("^unique%s*%((%d+)%)$")
           or lower:match("^einzigartig%s*%((%d+)%)$")
           or lower:match("^unique[%s%-]+equipped%s*%((%d+)%)$")
           or lower:match("^einzigartig[%s%-]+anlegbar%s*%((%d+)%)$")
    if n then
        return true, tonumber(n) or 1, nil
    end

    -- 3. Unique / Unique-Equipped with family AND (N)
    local fam, cnt = lower:match("^unique[%s%-]+equipped:%s*(.-)%s*%((%d+)%)$")
    if not fam then fam, cnt = lower:match("^einzigartig[%s%-]+anlegbar:%s*(.-)%s*%((%d+)%)$") end
    if not fam then fam, cnt = lower:match("^unique:%s*(.-)%s*%((%d+)%)$") end
    if not fam then fam, cnt = lower:match("^einzigartig:%s*(.-)%s*%((%d+)%)$") end
    if fam then
        fam = fam:gsub("^%s+", ""):gsub("%s+$", "")
        if fam ~= "" then
            return true, tonumber(cnt) or 1, fam
        end
    end

    -- 4. Unique / Unique-Equipped with family (default limit 1)
    fam = lower:match("^unique[%s%-]+equipped:%s*(.+)$")
       or lower:match("^einzigartig[%s%-]+anlegbar:%s*(.+)$")
       or lower:match("^unique:%s*(.+)$")
       or lower:match("^einzigartig:%s*(.+)$")
    if fam then
        fam = fam:gsub("^%s+", ""):gsub("%s+$", "")
        if fam ~= "" then
            return true, 1, fam
        end
    end

    return nil
end

-- Cached tooltip + API uniqueness inspector.
-- Distinguishes non-unique items (allows dual-equipping identical non-unique rings/weapons)
-- from Unique, Unique (N), Unique-Equipped, and Unique-Equipped family items.
function GSI_OptimizationEngine:GetItemUniqueInfo(link)
    if not link or link == "" then
        return { isUnique = false, limit = nil, family = nil, apiFamily = nil }
    end

    local cached = UniqueInfoCache[link]
    if cached then
        return cached
    end

    local isUnique = false
    local limit = nil
    local family = nil
    local apiFamily = nil

    local tip = EnsureOptScanTooltip()
    tip:ClearLines()
    local ok = pcall(function() tip:SetHyperlink(link) end)
    local numLines = (ok and tip:NumLines()) or 0

    -- Skip line 1 (item name) to avoid false positives if an item name starts with "Unique"
    if ok and numLines >= 2 then
        for i = 2, numLines do
            for _, prefix in ipairs(TOOLTIP_LINE_PREFIXES) do
                local fs = _G[prefix .. i]
                if fs and fs.GetText then
                    local u, lim, fam = ParseUniqueLine(fs:GetText())
                    if u then
                        isUnique = true
                        if not limit or (lim and lim < limit) then
                            limit = lim
                        end
                        if fam and not family then
                            family = fam
                        end
                    end
                end
            end
        end
    end

    -- Supplementary client API uniqueness check (for Unique-Equipped family IDs)
    local getUniquenessFn = (C_Item and C_Item.GetItemUniquenessByID) or _G.GetItemUniqueness
    if getUniquenessFn then
        local okApi, uFam, maxEq = pcall(getUniquenessFn, link)
        if okApi and type(maxEq) == "number" and maxEq > 0 then
            isUnique = true
            if not limit or maxEq < limit then
                limit = maxEq
            end
            if type(uFam) == "number" and uFam > 0 then
                apiFamily = uFam
            elseif type(uFam) == "string" and uFam ~= "" and not family then
                family = uFam:lower()
            end
        end
    end

    local info = {
        isUnique = isUnique,
        limit = isUnique and (limit or 1) or nil,
        family = family,
        apiFamily = apiFamily,
    }

    -- Only cache once tooltip has loaded (>= 2 lines) or uniqueness was confirmed
    if numLines >= 2 or isUnique then
        if UniqueInfoCount >= MAX_UNIQUE_CACHE then
            UniqueInfoCache = {}
            UniqueInfoCount = 0
        end
        UniqueInfoCache[link] = info
        UniqueInfoCount = UniqueInfoCount + 1
    end

    return info
end

-- Checks whether equipping candLink in targetSlotID violates Unique / Unique-Equipped rules
-- against the remaining active items in setup (plus equipped trinkets for cross-slot families).
function GSI_OptimizationEngine:HasUniqueConflict(candLink, setup, targetSlotID, candEquipLoc)
    if not candLink or not setup then return false end

    local uInfo = self:GetItemUniqueInfo(candLink)
    if not uInfo or not uInfo.isUnique then
        return false
    end

    local limit = uInfo.limit or 1
    local candID = candLink:match("item:(%d+)")
    candEquipLoc = candEquipLoc or GetItemEquipLoc(candLink)

    local mhLink = setup[INVSLOT_MAINHAND] and setup[INVSLOT_MAINHAND].link
    local mhLoc = mhLink and GetItemEquipLoc(mhLink)
    local mhIs2H = (mhLoc == "INVTYPE_2HWEAPON")

    local skipOH = (targetSlotID == INVSLOT_MAINHAND and candEquipLoc == "INVTYPE_2HWEAPON") or mhIs2H
    local skipMH = (targetSlotID == INVSLOT_OFFHAND and mhIs2H)

    local function MatchesUniqueTarget(otherLink)
        if not otherLink or otherLink == "" then return false end
        if uInfo.family or uInfo.apiFamily then
            local otherInfo = self:GetItemUniqueInfo(otherLink)
            if otherInfo and otherInfo.isUnique then
                if uInfo.family and otherInfo.family and uInfo.family == otherInfo.family then
                    return true
                end
                if uInfo.apiFamily and otherInfo.apiFamily and uInfo.apiFamily == otherInfo.apiFamily then
                    return true
                end
            end
            -- Fallback if family string exists on one and itemID is identical
            if candID and otherLink:match("item:(%d+)") == candID then
                return true
            end
            return false
        else
            local otherID = otherLink:match("item:(%d+)")
            return candID ~= nil and otherID == candID
        end
    end

    local matchCount = 0
    for checkSlotID, eqObj in pairs(setup) do
        if checkSlotID ~= targetSlotID
            and not (skipOH and checkSlotID == INVSLOT_OFFHAND)
            and not (skipMH and checkSlotID == INVSLOT_MAINHAND)
            and eqObj and eqObj.link then
            if MatchesUniqueTarget(eqObj.link) then
                matchCount = matchCount + 1
                if matchCount >= limit then
                    return true
                end
            end
        end
    end

    -- Cross-category Unique-Equipped family check against fixed trinket slots (13 & 14)
    if uInfo.family or uInfo.apiFamily then
        for _, tSlot in ipairs(TRINKET_SLOTS) do
            if tSlot ~= targetSlotID and not setup[tSlot] and GetInventoryItemLink then
                local tLink = GetInventoryItemLink("player", tSlot)
                if tLink and MatchesUniqueTarget(tLink) then
                    matchCount = matchCount + 1
                    if matchCount >= limit then
                        return true
                    end
                end
            end
        end
    end

    return false
end

-- Checks if an item can be equipped by the player (class, level, armor type, weapon skill, tooltip requirements)
function GSI_OptimizationEngine:IsItemUsableForPlayer(link, bag, slot, ignoreLevel)
    if not link or link == "" then return false end

    local _, _, _, _, _, _, _, _, equipLoc, _, _, classID, subClassID = GetItemInfo(link)
    if not classID then
        _, _, _, equipLoc, _, classID, subClassID = GetItemInfoInstant(link)
    end

    if not equipLoc or type(equipLoc) ~= "string" or equipLoc == "" or equipLoc == "INVTYPE_NON_EQUIP" then return false end
    if not GSI_ClassicData or not GSI_ClassicData.EquipLocToSlot or not GSI_ClassicData.EquipLocToSlot[equipLoc] then return false end

    local playerClass = GetPlayerClassKey()
    local playerLevel = UnitLevel("player") or 60

    -- Level requirement check
    if not ignoreLevel then
        local minLevel = select(5, GetItemInfo(link))
        if minLevel and minLevel > playerLevel then return false end
    end

    -- Armor types (classID == 4)
    -- subClassID: 0=Generic, 1=Cloth, 2=Leather, 3=Mail, 4=Plate, 6=Shield
    if classID == 4 then
        if equipLoc == "INVTYPE_SHIELD" or subClassID == 6 then
            if playerClass ~= "WARRIOR" and playerClass ~= "PALADIN" and playerClass ~= "SHAMAN" then
                return false
            end
        else
            local isGeneralSlot = (equipLoc == "INVTYPE_CLOAK" or equipLoc == "INVTYPE_TABARD"
                                or equipLoc == "INVTYPE_BODY" or equipLoc == "INVTYPE_FINGER"
                                or equipLoc == "INVTYPE_TRINKET" or equipLoc == "INVTYPE_NECK"
                                or equipLoc == "INVTYPE_HOLDABLE")
            if not isGeneralSlot then
                if playerClass == "DRUID" or playerClass == "ROGUE" then
                    if subClassID and subClassID > 2 then return false end
                elseif playerClass == "MAGE" or playerClass == "PRIEST" or playerClass == "WARLOCK" then
                    if subClassID and subClassID > 1 then return false end
                elseif playerClass == "HUNTER" or playerClass == "SHAMAN" then
                    local maxSub = (playerLevel >= 40) and 3 or 2
                    if subClassID and subClassID > maxSub then return false end
                elseif playerClass == "WARRIOR" or playerClass == "PALADIN" then
                    local maxSub = (playerLevel >= 40) and 4 or 3
                    if subClassID and subClassID > maxSub then return false end
                end
            end
        end
    end

    -- Weapon types (classID == 2)
    if classID == 2 then
        if equipLoc == "INVTYPE_WEAPONOFFHAND" then
            if GSI_ClassicData and GSI_ClassicData.CanDualWield and not GSI_ClassicData:CanDualWield() then
                return false
            end
        end
        local allowed = CLASS_ALLOWED_WEAPONS[playerClass]
        if allowed and subClassID and not allowed[subClassID] then
            return false
        end
    end

    -- Live tooltip check: detects untrained weapon skills, class restrictions, or unmet requirements
    if HasUnmetRequirements(link, bag, slot, ignoreLevel) then
        return false
    end

    return true
end

function GSI_OptimizationEngine:ResetCache()
    ItemBaseCache = {}
    BaselineCapCache = {}
    SetBonusStatsCache = {}
    SetBonusThresholdsCache = {}
    self._cacheVersion = (self._cacheVersion or 1) + 1
    self.isStopped = false
    if GSI_CompareEngine and GSI_CompareEngine.ResetCache then
        GSI_CompareEngine:ResetCache()
    end
end

function GSI_OptimizationEngine:StopOptimization()
    self.isStopped = true
end

-- Returns the player's currently equipped setup across all optimizable slots
function GSI_OptimizationEngine:GetCurrentSetup()
    local setup = {}
    for _, slotID in ipairs(self.EQUIP_SLOTS) do
        local link = GetInventoryItemLink("player", slotID)
        if link then
            setup[slotID] = { link = link, source = "equipped", slot = slotID }
        end
    end
    return setup
end

-- Resolves active mode string consistently for profile & cap lookup
local function ResolveEffectiveMode(class, specIndex, overrideMode)
    local isTankSpec = (class == "WARRIOR" and specIndex == 3)
                    or (class == "PALADIN" and specIndex == 2)
                    or (class == "DRUID" and specIndex == 2)
    local mode = overrideMode
    if not mode or mode == "default" then
        if isTankSpec then
            mode = (GearSetImproverDB and GearSetImproverDB.tankMode)
                or (GSI_Config and GSI_Config.TankMode)
                or "Survival"
        else
            mode = (GearSetImproverDB and GearSetImproverDB.weightMode)
                or (GSI_Config and GSI_Config.WeightMode)
                or "ST"
        end
    end
    return mode
end

local function IsCasterSpec(role, class, specIndex)
    return (role == "caster")
        or (role == "healer")
        or (class == "MAGE" or class == "WARLOCK")
        or (class == "PRIEST" and specIndex == 3)
        or (class == "SHAMAN" and specIndex == 1)
        or (class == "DRUID" and specIndex == 1)
end

local function IsShieldTankSpec(class, specIndex)
    return (class == "WARRIOR" and specIndex == 3) or (class == "PALADIN" and specIndex == 2)
end

local function GetCanonicalSetName(rawSetName)
    if not rawSetName or not GSI_SetBonus then return rawSetName end
    if GSI_SetBonus.GetSetDefinition then
        local _, canonical = GSI_SetBonus:GetSetDefinition(rawSetName)
        return canonical or rawSetName
    end
    return rawSetName
end

local function GetCachedSetBonusStats(setCounts)
    if not GSI_SetBonus or not GSI_SetBonus.GetActiveSetBonusStats then
        return nil
    end

    local keys = {}
    local anyThreshold = false
    for sName, count in pairs(setCounts) do
        if count and count >= 2 then
            anyThreshold = true
        end
        table.insert(keys, sName)
    end
    if not anyThreshold then
        return nil
    end

    table.sort(keys)
    local parts = {}
    for _, sName in ipairs(keys) do
        table.insert(parts, sName .. "=" .. tostring(setCounts[sName]))
    end
    local cacheKey = table.concat(parts, ";")

    local cached = SetBonusStatsCache[cacheKey]
    if cached then
        return cached
    end

    local bonusStats = GSI_SetBonus:GetActiveSetBonusStats(setCounts) or {}
    SetBonusStatsCache[cacheKey] = bonusStats
    return bonusStats
end

local function GetCachedSetBonusThresholds(setCounts)
    if not GSI_SetBonus or not GSI_SetBonus.GetActiveSetBonusThresholds then
        return nil
    end

    local keys = {}
    local anyThreshold = false
    for sName, count in pairs(setCounts) do
        if count and count >= 2 then
            anyThreshold = true
        end
        table.insert(keys, sName)
    end
    if not anyThreshold then
        return nil
    end

    table.sort(keys)
    local parts = {}
    for _, sName in ipairs(keys) do
        table.insert(parts, sName .. "=" .. tostring(setCounts[sName]))
    end
    local cacheKey = table.concat(parts, ";")

    local cached = SetBonusThresholdsCache[cacheKey]
    if cached then
        return cached
    end

    local activeThresholds = GSI_SetBonus:GetActiveSetBonusThresholds(setCounts) or {}
    SetBonusThresholdsCache[cacheKey] = activeThresholds
    return activeThresholds
end

-- Computes total stats across an equipment setup (respecting 2H/DW consistency and active set bonuses)
function GSI_OptimizationEngine:CalculateStats(setup)
    local totalStats = {
        Stamina = 0, Agility = 0, Strength = 0, Intellect = 0, Spirit = 0,
        Armor = 0, Defense = 0, Dodge = 0, Parry = 0, Block = 0, BlockValue = 0,
        AttackPower = 0, RangedAttackPower = 0, FeralAttackPower = 0,
        SpellPower = 0, HealingPower = 0,
        ArcaneSpellPower = 0, FireSpellPower = 0, FrostSpellPower = 0,
        ShadowSpellPower = 0, NatureSpellPower = 0, HolySpellPower = 0,
        Hit = 0, Crit = 0, Haste = 0,
        ArmorPenetration = 0, SpellPenetration = 0,
        WeaponSkill = 0, AvoidanceReduction = 0, FlatWeaponDamage = 0,
        MP5 = 0, HP5 = 0, Mana = 0, Speed = 0,
        FireResist = 0, NatureResist = 0, FrostResist = 0, ShadowResist = 0, ArcaneResist = 0,
        WeaponDamage = 0, WeaponDamageOH = 0, RangedDPS = 0, WeaponSpeed = 0
    }

    setup = setup or self:GetCurrentSetup()

    local mhLink = setup[INVSLOT_MAINHAND] and setup[INVSLOT_MAINHAND].link
    local mhLoc = mhLink and GetItemEquipLoc(mhLink)
    local mhIs2H = (mhLoc == "INVTYPE_2HWEAPON")
    local canDualWield = GSI_ClassicData and GSI_ClassicData.CanDualWield and GSI_ClassicData:CanDualWield()

    local setCounts = {}

    for slotID, itemObj in pairs(setup) do
        local link = itemObj and itemObj.link
        if link then
            local skipSlot = false
            if slotID == INVSLOT_OFFHAND then
                if mhIs2H then
                    skipSlot = true
                else
                    local ohLoc = GetItemEquipLoc(link)
                    if (ohLoc == "INVTYPE_WEAPON" or ohLoc == "INVTYPE_WEAPONOFFHAND") and not canDualWield then
                        skipSlot = true
                    end
                end
            end

            if not skipSlot then
                local stats = GSI_ItemScore and GSI_ItemScore.GetParsedStats and GSI_ItemScore:GetParsedStats(link)
                if stats then
                    for k, v in pairs(stats) do
                        if totalStats[k] ~= nil and type(v) == "number" and v > 0 then
                            totalStats[k] = totalStats[k] + v
                        end
                    end
                end

                if slotID == INVSLOT_MAINHAND or slotID == INVSLOT_OFFHAND or slotID == INVSLOT_RANGED then
                    local wInfo = GSI_ItemScore and GSI_ItemScore.GetWeaponInfo and GSI_ItemScore:GetWeaponInfo(link)
                    if wInfo then
                        if slotID == INVSLOT_MAINHAND then
                            if wInfo.dps then
                                totalStats.WeaponDamage = totalStats.WeaponDamage + wInfo.dps
                            end
                            if wInfo.speed and wInfo.speed > 0 then
                                totalStats.WeaponSpeed = wInfo.speed
                            end
                        elseif slotID == INVSLOT_OFFHAND then
                            if wInfo.dps then
                                totalStats.WeaponDamageOH = totalStats.WeaponDamageOH + wInfo.dps
                            end
                        elseif slotID == INVSLOT_RANGED then
                            if wInfo.dps then
                                totalStats.RangedDPS = totalStats.RangedDPS + wInfo.dps
                            end
                            if totalStats.WeaponSpeed == 0 and wInfo.speed and wInfo.speed > 0 then
                                totalStats.WeaponSpeed = wInfo.speed
                            end
                        end
                    end
                end

                if GSI_SetBonus and GSI_SetBonus.GetSetNameFromLink then
                    local sName = GSI_SetBonus:GetSetNameFromLink(link)
                    if sName then
                        sName = GetCanonicalSetName(sName)
                        setCounts[sName] = (setCounts[sName] or 0) + 1
                    end
                end
            end
        end
    end

    -- Include passive stats from equipped trinkets if not already part of setup
    if GetInventoryItemLink and GSI_ItemScore and GSI_ItemScore.GetParsedStats then
        for _, tSlot in ipairs(TRINKET_SLOTS) do
            if not setup[tSlot] then
                local tLink = GetInventoryItemLink("player", tSlot)
                if tLink then
                    local tStats = GSI_ItemScore:GetParsedStats(tLink)
                    if tStats then
                        for k, v in pairs(tStats) do
                            if totalStats[k] ~= nil and type(v) == "number" and v > 0 then
                                totalStats[k] = totalStats[k] + v
                            end
                        end
                    end
                end
            end
        end
    end

    if GSI_SetBonus and GSI_SetBonus.GetActiveSetBonusStats then
        local bonusStats = GetCachedSetBonusStats(setCounts)
        if bonusStats then
            for k, v in pairs(bonusStats) do
                if totalStats[k] ~= nil and type(v) == "number" and v > 0 then
                    totalStats[k] = totalStats[k] + v
                end
            end
        end
    end

    return totalStats
end

-- Computes effective non-cap weight for a stat, matching ItemScore rules
local function GetEffectiveStatWeight(stat, weights, role, class, specIndex, isUniversalSP, itemHealingPower, itemSpellPower)
    local w = (weights and weights[stat]) or 0

    if stat == "HealingPower" and role ~= "healer" then
        if (itemSpellPower or 0) > 0 then
            -- Never double-count HealingPower on items/thresholds that already carry SpellPower
            w = 0
        elseif weights.HealingPower == nil and (weights.SpellPower or 0) > 0 then
            local healToDmgFactor = (GSI_Config and GSI_Config.Rules_v2_2 and GSI_Config.Rules_v2_2.heal_to_damage and GSI_Config.Rules_v2_2.heal_to_damage.factor)
                or (GSI_Config and GSI_Config.Rules and GSI_Config.Rules.HealToDamageFactor)
                or (1 / 3)
            w = (weights.SpellPower or 0) * healToDmgFactor
        end
    end
    if stat == "SpellPower" and role == "healer" then
        if isUniversalSP and (itemHealingPower or 0) == 0 then
            w = weights.HealingPower or weights.HEAL or 1.0
        else
            w = (GSI_Config and GSI_Config.Rules_v2_2 and GSI_Config.Rules_v2_2.healer_spell_damage_weight)
                or (GSI_Config and GSI_Config.Rules and GSI_Config.Rules.HealerSpellDamageWeight)
                or 0
        end
    end
    if stat == "FeralAttackPower" and w == 0 then
        if class == "DRUID" and (specIndex == 2 or specIndex == 3) then
            w = weights.AttackPower or 0.5
        end
    end

    return w
end

-- Evaluates a single item's non-cap, non-set-preview score + extracted cap stats
-- Cached per (itemLink, specIndex, effectiveMode, slotID) within current tooltip revision
local function GetItemSetupEntry(link, specIndex, effectiveMode, slotID, class, role, weights)
    local cacheKey = tostring(link) .. ":" .. tostring(specIndex) .. ":" .. tostring(effectiveMode) .. ":" .. tostring(slotID)
    local cached = ItemBaseCache[cacheKey]
    if cached then
        return cached
    end

    local zeroEntry = {
        baseScore = 0,
        hit = 0,
        defense = 0,
        avoidRed = 0,
        weaponSkill = 0,
        weaponSkillType = nil,
        setName = nil,
    }

    local isEquip = (C_Item and C_Item.IsEquippableItem and C_Item.IsEquippableItem(link))
    if isEquip == nil then
        isEquip = (_G.IsEquippableItem and _G.IsEquippableItem(link))
    end
    if isEquip == false then
        ItemBaseCache[cacheKey] = zeroEntry
        return zeroEntry
    end

    local itemName, _, _, itemLevel, _, _, itemSubType, _, equipLoc, _, _, wClassID, wSubClassID = GetItemInfo(link)
    if not equipLoc or equipLoc == "" or type(equipLoc) ~= "string" then
        equipLoc = select(4, GetItemInfoInstant(link))
    end
    if not itemName and (not equipLoc or equipLoc == "") then
        return zeroEntry -- Item data not yet loaded; do not cache
    end

    if not equipLoc or type(equipLoc) ~= "string" or equipLoc == "" or equipLoc == "INVTYPE_NON_EQUIP" or equipLoc == "INVTYPE_TRINKET" then
        ItemBaseCache[cacheKey] = zeroEntry
        return zeroEntry
    end
    if not GSI_ClassicData or not GSI_ClassicData.EquipLocToSlot or not GSI_ClassicData.EquipLocToSlot[equipLoc] then
        ItemBaseCache[cacheKey] = zeroEntry
        return zeroEntry
    end

    -- Feral Bear/Cat offhand/shield rule
    if class == "DRUID" and (specIndex == 2 or specIndex == 3) then
        if equipLoc == "INVTYPE_SHIELD" or equipLoc == "INVTYPE_HOLDABLE" or equipLoc == "INVTYPE_WEAPONOFFHAND" or slotID == INVSLOT_OFFHAND then
            ItemBaseCache[cacheKey] = zeroEntry
            return zeroEntry
        end
    end

    -- Shield-Tank specs (Protection Warrior / Protection Paladin): 1H + Shield only
    if IsShieldTankSpec(class, specIndex) then
        if equipLoc == "INVTYPE_2HWEAPON" or equipLoc == "INVTYPE_WEAPONOFFHAND" or equipLoc == "INVTYPE_HOLDABLE"
            or (slotID == INVSLOT_OFFHAND and equipLoc ~= "INVTYPE_SHIELD") then
            ItemBaseCache[cacheKey] = zeroEntry
            return zeroEntry
        end
    end

    local score = 0
    local isWand = false
    if equipLoc == "INVTYPE_RANGED" or equipLoc == "INVTYPE_RANGEDRIGHT" then
        if itemSubType and (itemSubType:lower():find("wand") or itemSubType:lower():find("zauberstab")) then
            isWand = true
        end
    end

    -- 1. Weapon / Ranged DPS contribution
    if GSI_ItemScore and GSI_ItemScore.IsWeapon and GSI_ItemScore:IsWeapon(equipLoc) then
        local wInfo = GSI_ItemScore:GetWeaponInfo(link)
        local dps = (wInfo and wInfo.dps) or 0
        local isOffHand = (equipLoc == "INVTYPE_WEAPONOFFHAND" or slotID == INVSLOT_OFFHAND)

        if class == "DRUID" and (specIndex == 2 or specIndex == 3) then
            local dpsWeight = weights.WeaponDamage or (specIndex == 3 and 8.30 or 1.35)
            score = score + (dps * dpsWeight)
        else
            local wSpeed = wInfo and wInfo.speed
            local wSpeedWeight = weights.WeaponSpeed or 0
            if wSpeed and wSpeedWeight ~= 0 and not isOffHand then
                score = score + (wSpeed * wSpeedWeight)
            end

            local isCaster = IsCasterSpec(role, class, specIndex)
            if isCaster then
                score = score + (dps * 0.5)
            elseif class == "HUNTER" and (specIndex == 1 or specIndex == 2) then
                local dpsWeight = weights.WeaponDamage or 0.5
                score = score + (dps * dpsWeight)
            else
                local speed = (wInfo and wInfo.speed) or 2.0
                local speedMultiplier = 1.0
                if not isOffHand and not IsShieldTankSpec(class, specIndex) then
                    if speed >= 3.3 then speedMultiplier = 1.15
                    elseif speed >= 2.6 then speedMultiplier = 1.08
                    elseif speed <= 1.8 and not (class == "ROGUE" and (specIndex == 1 or specIndex == 3)) then speedMultiplier = 0.95 end
                end

                local dpsWeight = weights.WeaponDamage or (GSI_Config and GSI_Config.WeaponDPSWeight) or 14.0
                if isOffHand then
                    if weights.WeaponDamageOH and weights.WeaponDamageOH > 0 then
                        dpsWeight = weights.WeaponDamageOH
                    elseif GSI_ClassicData and GSI_ClassicData.CanDualWield and GSI_ClassicData:CanDualWield() then
                        dpsWeight = dpsWeight * 0.5
                    end
                end
                score = score + (dps * dpsWeight * speedMultiplier)
            end
        end

        if not wClassID then
            wClassID, wSubClassID = GetItemClassSubClass(link)
        end
        if wClassID == 2 and GSI_RaceBonus and GSI_RaceBonus.GetWeaponCritBonus then
            local raceCritBonus = GSI_RaceBonus:GetWeaponCritBonus(wSubClassID)
            if raceCritBonus and raceCritBonus > 0 then
                score = score + (raceCritBonus * (weights.Crit or 0))
            end
        end
    elseif GSI_ItemScore and GSI_ItemScore.IsRanged and GSI_ItemScore:IsRanged(equipLoc) then
        local wInfo = GSI_ItemScore:GetWeaponInfo(link)
        local dps = (wInfo and wInfo.dps) or 0
        local wSpeed = wInfo and wInfo.speed
        local wSpeedWeight = weights.WeaponSpeed or 0
        if wSpeed and wSpeedWeight ~= 0 then
            score = score + (wSpeed * wSpeedWeight)
        end
        if class == "HUNTER" then
            local rWeight = weights.RangedDPS or weights.WeaponDamage or (GSI_Config and GSI_Config.RangedDPSWeight) or 16.0
            score = score + (dps * rWeight)
        elseif weights.RangedDPS and weights.RangedDPS > 0 then
            score = score + (dps * weights.RangedDPS)
        end
    end

    -- 2. Non-cap stats (capped stats Hit, Defense, AvoidanceReduction, WeaponSkill are accumulated setup-wide)
    local stats = (GSI_ItemScore and GSI_ItemScore.GetParsedStats and GSI_ItemScore:GetParsedStats(link)) or {}
    local isUniSP = GSI_ItemScore and GSI_ItemScore.IsUniversalSpellPower and GSI_ItemScore:IsUniversalSpellPower(link) or false
    local hasAnyStat = false
    local itemHit = 0
    local itemDef = 0
    local itemAvoid = 0
    local itemWpnSkill = 0
    local itemWpnSkillType = stats.WeaponSkillType

    for stat, val in pairs(stats) do
        if stat ~= "WeaponSkillType" and type(val) == "number" and val > 0 then
            hasAnyStat = true
            if stat == "Hit" then
                itemHit = itemHit + val
            elseif stat == "Defense" then
                itemDef = itemDef + val
            elseif stat == "AvoidanceReduction" then
                itemAvoid = itemAvoid + val
            elseif stat == "WeaponSkill" then
                itemWpnSkill = itemWpnSkill + val
            elseif stat == "FlatWeaponDamage" then
                local mhDPSWeight = weights.WeaponDamage or 7.0
                local fScore = (val / 2.6) * mhDPSWeight
                if weights.WeaponDamageOH and weights.WeaponDamageOH > 0 then
                    fScore = fScore + ((val / 1.8) * weights.WeaponDamageOH * 0.5)
                end
                score = score + fScore
            else
                local w = GetEffectiveStatWeight(stat, weights, role, class, specIndex, isUniSP, stats.HealingPower, stats.SpellPower)
                score = score + (val * w)
            end
        end
    end

    -- Statless armor fallback
    local isWeapon = GSI_ItemScore and GSI_ItemScore.IsWeapon and GSI_ItemScore:IsWeapon(equipLoc)
    local isRanged = GSI_ItemScore and GSI_ItemScore.IsRanged and GSI_ItemScore:IsRanged(equipLoc)
    if not hasAnyStat and not isWeapon and not isRanged and equipLoc ~= "INVTYPE_HOLDABLE" and (stats.Armor and stats.Armor > 0) then
        score = (itemLevel or 1) * ((GSI_Config and GSI_Config.IlvlScoreFactor) or 0.5)
    end

    -- 3. Enchants & Sockets (Note: single-item SetBonus preview is deliberately omitted here;
    --    full-setup set bonuses are evaluated once across the complete setup!)
    local ignoreEnchants = GearSetImproverDB and GearSetImproverDB.ignoreEnchants
    if ignoreEnchants == nil then
        ignoreEnchants = (GSI_Config and GSI_Config.IgnoreEnchants ~= false)
    end
    if not ignoreEnchants and GSI_EnchantBonus and GSI_EnchantBonus.GetEnchantScore then
        score = score + (GSI_EnchantBonus:GetEnchantScore(link, specIndex, effectiveMode) or 0)
    end
    if GSI_SocketBonus and GSI_SocketBonus.GetSocketScore then
        score = score + (GSI_SocketBonus:GetSocketScore(link) or 0)
    end

    -- 4. Overrides
    if GSI_Overrides and GSI_Overrides.GetOverride then
        local overrideScore = GSI_Overrides:GetOverride(link, class, nil, false, specIndex)
        if overrideScore and overrideScore > 0 then
            score = score + overrideScore
        end
    end

    -- 5. Required Boss Resists extra weight
    local reqResists = GearSetImproverDB and GearSetImproverDB.requiredResists
    if reqResists then
        local resistPriorityWeight = (GearSetImproverDB and GearSetImproverDB.resistPriorityWeight) or 5.0
        local resistMap = {
            Fire = "FireResist",
            Nature = "NatureResist",
            Frost = "FrostResist",
            Shadow = "ShadowResist",
            Arcane = "ArcaneResist",
        }
        for elem, sKey in pairs(resistMap) do
            if reqResists[elem] and stats[sKey] and stats[sKey] > 0 then
                local baseW = weights[sKey] or 0
                local effectiveW = math.max(baseW, resistPriorityWeight)
                local extraW = effectiveW - baseW
                if extraW > 0 then
                    score = score + (stats[sKey] * extraW)
                end
            end
        end
    end

    local setName = nil
    if GSI_SetBonus and GSI_SetBonus.GetSetNameFromLink then
        local rawSet = GSI_SetBonus:GetSetNameFromLink(link)
        if rawSet then
            setName = GetCanonicalSetName(rawSet)
        end
    end

    local entry = {
        baseScore = score,
        hit = itemHit,
        defense = itemDef,
        avoidRed = itemAvoid,
        weaponSkill = itemWpnSkill,
        weaponSkillType = itemWpnSkillType,
        setName = setName,
    }

    if itemName then
        ItemBaseCache[cacheKey] = entry
    end
    return entry
end

-- Computes baseline cap totals (talents, racials, fixed trinkets, base defense/skill)
-- not originating from the 15 optimizable equipment slots
local function GetBaselineCapStats(specIndex, effectiveMode, class, role)
    local t1 = GetInventoryItemLink and GetInventoryItemLink("player", INVSLOT_TRINKET1) or ""
    local t2 = GetInventoryItemLink and GetInventoryItemLink("player", INVSLOT_TRINKET2) or ""
    local cacheKey = tostring(class) .. ":" .. tostring(specIndex) .. ":" .. tostring(effectiveMode) .. ":" .. t1 .. ":" .. t2
    local cached = BaselineCapCache[cacheKey]
    if cached then
        return cached
    end

    -- Sum currently equipped Hit, Defense, AvoidanceReduction across the 15 optimizable slots vs trinket slots
    local equippedSetupHit, equippedSetupDef, equippedSetupAvoid = 0, 0, 0
    local eqSetCounts = {}
    local eqMH = GetInventoryItemLink and GetInventoryItemLink("player", INVSLOT_MAINHAND)
    local eqMHLoc = eqMH and GetItemEquipLoc(eqMH)
    local eqMHIs2H = (eqMHLoc == "INVTYPE_2HWEAPON")
    local canDW = GSI_ClassicData and GSI_ClassicData.CanDualWield and GSI_ClassicData:CanDualWield()

    for _, slotID in ipairs(GSI_OptimizationEngine.EQUIP_SLOTS) do
        local link = GetInventoryItemLink and GetInventoryItemLink("player", slotID)
        if link then
            local skipOH = false
            if slotID == INVSLOT_OFFHAND then
                if eqMHIs2H then
                    skipOH = true
                else
                    local ohLoc = GetItemEquipLoc(link)
                    if (ohLoc == "INVTYPE_WEAPON" or ohLoc == "INVTYPE_WEAPONOFFHAND") and not canDW then
                        skipOH = true
                    end
                end
            end
            if not skipOH and GSI_ItemScore and GSI_ItemScore.GetParsedStats then
                local st = GSI_ItemScore:GetParsedStats(link)
                if st then
                    equippedSetupHit = equippedSetupHit + (st.Hit or 0)
                    equippedSetupDef = equippedSetupDef + (st.Defense or 0)
                    equippedSetupAvoid = equippedSetupAvoid + (st.AvoidanceReduction or 0)
                end
                if GSI_SetBonus and GSI_SetBonus.GetSetNameFromLink then
                    local sName = GSI_SetBonus:GetSetNameFromLink(link)
                    if sName then
                        sName = GetCanonicalSetName(sName)
                        eqSetCounts[sName] = (eqSetCounts[sName] or 0) + 1
                    end
                end
            end
        end
    end

    local eqSetBonus = GetCachedSetBonusStats(eqSetCounts)
    if eqSetBonus then
        equippedSetupHit = equippedSetupHit + (eqSetBonus.Hit or 0)
        equippedSetupDef = equippedSetupDef + (eqSetBonus.Defense or 0)
        equippedSetupAvoid = equippedSetupAvoid + (eqSetBonus.AvoidanceReduction or 0)
    end

    local trinketHit, trinketDef, trinketAvoid = 0, 0, 0
    for _, tSlot in ipairs(TRINKET_SLOTS) do
        local tLink = GetInventoryItemLink and GetInventoryItemLink("player", tSlot)
        if tLink and GSI_ItemScore and GSI_ItemScore.GetParsedStats then
            local st = GSI_ItemScore:GetParsedStats(tLink)
            if st then
                trinketHit = trinketHit + (st.Hit or 0)
                trinketDef = trinketDef + (st.Defense or 0)
                trinketAvoid = trinketAvoid + (st.AvoidanceReduction or 0)
            end
        end
    end

    local equippedAllHit = equippedSetupHit + trinketHit

    local v22ProfForCap = (GSI_Config and GSI_Config.GetProfileV22 and GSI_Config:GetProfileV22(class, specIndex, effectiveMode))
                       or (GSI_Config and GSI_Config.GetProfile and GSI_Config:GetProfile(class, specIndex, effectiveMode))
    local capMeta = v22ProfForCap and v22ProfForCap.caps
    local specMeta = GSI_ClassicData and GSI_ClassicData.Classes and GSI_ClassicData.Classes[class]
        and GSI_ClassicData.Classes[class].specs and GSI_ClassicData.Classes[class].specs[specIndex]
    local usesSpellHit = IsCasterSpec(role, class, specIndex) or (capMeta and capMeta.SPELL_HIT ~= nil and capMeta.HIT == nil)
    local isRangedSpec = (specMeta and specMeta.ranged == true)
        or (class == "HUNTER" and (specIndex == 1 or specIndex == 2))

    -- Racial & Talent Hit bonuses (matching ItemScore.lua universal vs school-specific separation)
    local rHit = (GSI_RaceBonus and GSI_RaceBonus.GetRacialHitBonus and GetSafeNumber(GSI_RaceBonus:GetRacialHitBonus(), 0)) or 0
    local universalTalentHit = 0
    local schoolTalentHit = 0
    if GSI_TalentIntegration and GSI_TalentIntegration.GetClassHitTalentBonus then
        local tHit = GetSafeNumber(GSI_TalentIntegration:GetClassHitTalentBonus(class, specIndex), 0)
        if tHit > 0 then
            if class == "SHAMAN" then
                universalTalentHit = tHit
            elseif class == "ROGUE" or class == "HUNTER" or class == "PALADIN" then
                if not usesSpellHit then
                    universalTalentHit = tHit
                end
            elseif usesSpellHit then
                schoolTalentHit = tHit
            end
        end
        if usesSpellHit and GSI_TalentIntegration.GetSchoolHitTalentBonus then
            if (class == "PALADIN" and specIndex == 1) or (class == "PRIEST" and specIndex ~= 3) then
                schoolTalentHit = schoolTalentHit + GetSafeNumber(GSI_TalentIntegration:GetSchoolHitTalentBonus(class, specIndex, "Holy"), 0)
            end
        end
    end

    -- Query school-appropriate Hit API (parity with ItemScore.lua; never mix GetHitModifier into caster SpellHit)
    local apiHit = nil
    if usesSpellHit then
        if type(GetSpellHitModifier) == "function" then
            local ok, rawSpellHit = pcall(GetSpellHitModifier)
            if ok then
                apiHit = GetSafeNumber(rawSpellHit, nil)
            end
        end
        if apiHit ~= nil and CR_HIT_SPELL and type(GetCombatRatingBonus) == "function" then
            local ok, crBonus = pcall(GetCombatRatingBonus, CR_HIT_SPELL)
            if ok then
                apiHit = apiHit + GetSafeNumber(crBonus, 0)
            end
        end
    elseif isRangedSpec then
        if type(GetRangedHitModifier) == "function" then
            local ok, rawRangedHit = pcall(GetRangedHitModifier)
            if ok then
                apiHit = GetSafeNumber(rawRangedHit, nil)
            end
        end
        if apiHit == nil and type(GetHitModifier) == "function" then
            local ok, rawHit = pcall(GetHitModifier)
            if ok then
                apiHit = GetSafeNumber(rawHit, nil)
            end
        end
        if apiHit ~= nil and CR_HIT_RANGED and type(GetCombatRatingBonus) == "function" then
            local ok, crBonus = pcall(GetCombatRatingBonus, CR_HIT_RANGED)
            if ok then
                apiHit = apiHit + GetSafeNumber(crBonus, 0)
            end
        end
    else
        if type(GetHitModifier) == "function" then
            local ok, rawHit = pcall(GetHitModifier)
            if ok then
                apiHit = GetSafeNumber(rawHit, nil)
            end
        end
        if apiHit ~= nil and CR_HIT_MELEE and type(GetCombatRatingBonus) == "function" then
            local ok, crBonus = pcall(GetCombatRatingBonus, CR_HIT_MELEE)
            if ok then
                apiHit = apiHit + GetSafeNumber(crBonus, 0)
            end
        end
    end

    -- Determine non-setup Hit without double-counting talents/racials already reflected in API hit
    local usedApiHit = (apiHit ~= nil)
    local apiPassiveBonus = usedApiHit and math.max(0, apiHit - equippedAllHit) or 0
    local extraUniversal = usedApiHit and math.max(0, (universalTalentHit + rHit) - apiPassiveBonus) or (universalTalentHit + rHit)
    local remainingApiPassive = usedApiHit and math.max(0, apiPassiveBonus - (universalTalentHit + rHit)) or 0
    local extraSchool = (usedApiHit and schoolTalentHit > 0 and remainingApiPassive >= schoolTalentHit) and 0 or schoolTalentHit
    local nonSetupHit = trinketHit + apiPassiveBonus + extraUniversal + extraSchool

    -- Defense baseline (Forever 1.60.1: UnitDefenseSkill before UnitDefense; parity with ItemScore.lua)
    local playerLevel = UnitLevel("player") or 60
    local baseLevelDef = playerLevel * 5
    local nonSetupDef = baseLevelDef + trinketDef
    local liveDefBase, liveDefTotal = nil, nil
    if type(UnitDefenseSkill) == "function" then
        local ok, bDef, aDef = pcall(UnitDefenseSkill, "player")
        if ok then
            local safeB = GetSafeNumber(bDef, nil)
            if safeB then
                liveDefBase = safeB
                liveDefTotal = safeB + GetSafeNumber(aDef, 0)
            end
        end
    end
    if not liveDefTotal and type(UnitDefense) == "function" then
        local ok, bDef, aDef = pcall(UnitDefense, "player")
        if ok then
            local safeB = GetSafeNumber(bDef, nil)
            if safeB then
                liveDefBase = safeB
                liveDefTotal = safeB + GetSafeNumber(aDef, 0)
            end
        end
    end
    if liveDefTotal then
        nonSetupDef = math.max((liveDefBase or baseLevelDef) + trinketDef, liveDefTotal - equippedSetupDef)
    end

    -- Avoidance Reduction talent reduction (Rogue Weapon Expertise)
    local rogueTalentAvoid = 0
    if class == "ROGUE" and GSI_TalentIntegration and GSI_TalentIntegration.GetRogueWeaponExpertiseReduction then
        rogueTalentAvoid = GetSafeNumber(GSI_TalentIntegration:GetRogueWeaponExpertiseReduction(), 0)
    end

    -- Base Weapon Skill
    local baseWeaponSkill = 300
    if GSI_RaceBonus and GSI_RaceBonus.GetWeaponSkillBonus then
        baseWeaponSkill = baseWeaponSkill + GetSafeNumber(GSI_RaceBonus:GetWeaponSkillBonus("ALL"), 0)
    end

    local result = {
        hit = math.max(0, nonSetupHit),
        def = math.max(baseLevelDef, nonSetupDef),
        avoid = math.max(0, trinketAvoid),
        rogueTalentAvoid = rogueTalentAvoid,
        weaponSkill = baseWeaponSkill,
    }
    BaselineCapCache[cacheKey] = result
    return result
end

-- Evaluates cumulative value of a capped stat over [startVal, endVal]
local function EvaluateCapRange(startVal, endVal, capCfg, baseWeight, overrideCapThreshold, overrideAboveWeight)
    if endVal <= startVal then return 0 end

    if not capCfg then
        return (endVal - startVal) * (baseWeight or 0)
    end

    local total = 0
    if capCfg.tiers and #capCfg.tiers > 0 then
        local maxTierTo = 0
        for _, tier in ipairs(capCfg.tiers) do
            local tFrom = tier.from_pct or 0
            local tTo = tier.to_pct or 999
            local tWeight = tier.w or baseWeight or 0
            if tTo > maxTierTo and tTo < 900 then maxTierTo = tTo end
            if endVal > tFrom and startVal < tTo then
                local segStart = math.max(startVal, tFrom)
                local segEnd = math.min(endVal, tTo)
                if segEnd > segStart then
                    total = total + (segEnd - segStart) * tWeight
                end
            end
        end
        if endVal > maxTierTo and maxTierTo > 0 then
            local rem = endVal - math.max(startVal, maxTierTo)
            if rem > 0 then
                local aboveW = overrideAboveWeight ~= nil and overrideAboveWeight or (capCfg.above_w or 0)
                total = total + rem * aboveW
            end
        end
    else
        local capVal = overrideCapThreshold or capCfg.cap_total_pct or capCfg.cap_total or 999
        if startVal < capVal then
            local chunkUnder = math.min(endVal, capVal) - startVal
            if chunkUnder > 0 then
                total = total + chunkUnder * (baseWeight or 0)
            end
        end
        if endVal > capVal then
            local currentStart = math.max(startVal, capVal)
            local remaining = endVal - currentStart
            if remaining > 0 then
                local aboveW = overrideAboveWeight ~= nil and overrideAboveWeight or (capCfg.above_w or 0)
                total = total + remaining * aboveW
            end
        end
    end
    return total
end

local RANGED_WEAPON_SKILL_TYPES = {
    BOW = true,
    GUN = true,
    CROSSBOW = true,
    THROWN = true,
    WAND = true,
}

local function WeaponMatchesSkillType(wsType, classID, subClassID)
    if classID ~= 2 or not subClassID then return false end
    if wsType == "AXE" then return (subClassID == 0 or subClassID == 1)
    elseif wsType == "BOW" then return (subClassID == 2)
    elseif wsType == "GUN" then return (subClassID == 3)
    elseif wsType == "MACE" then return (subClassID == 4 or subClassID == 5)
    elseif wsType == "POLEARM" then return (subClassID == 6)
    elseif wsType == "SWORD" then return (subClassID == 7 or subClassID == 8)
    elseif wsType == "STAFF" then return (subClassID == 10)
    elseif wsType == "FIST" then return (subClassID == 13)
    elseif wsType == "DAGGER" then return (subClassID == 15)
    elseif wsType == "THROWN" then return (subClassID == 16)
    elseif wsType == "CROSSBOW" then return (subClassID == 18)
    elseif wsType == "WAND" then return (subClassID == 19)
    end
    return false
end

-- Evaluates total setup strength holistically:
-- - Enforces 2H vs Offhand and Dual-Wield consistency across stats AND set counts
-- - Accumulates Hit / Defense / AvoidanceReduction / WeaponSkill across all active slots & set bonuses
-- - Applies cap tier curves once on the cumulative totals (no cap overcounting, no set-bonus double counting)
function GSI_OptimizationEngine:EvaluateSetup(setup, overrideSpecIndex, overrideMode)
    if not setup then return 0 end

    SyncCacheRevision()

    local class = GetPlayerClassKey()
    local specIndex = overrideSpecIndex or (GSI_StatWeights and GSI_StatWeights.GetActiveSpecIndex and GSI_StatWeights:GetActiveSpecIndex()) or 1
    local effectiveMode = ResolveEffectiveMode(class, specIndex, overrideMode)

    local weights = (GSI_StatWeights and GSI_StatWeights.GetWeights and GSI_StatWeights:GetWeights(specIndex, effectiveMode)) or {}
    local role = (GSI_StatWeights and GSI_StatWeights.GetRole and GSI_StatWeights:GetRole(specIndex, effectiveMode)) or "dps"
    local canDualWield = GSI_ClassicData and GSI_ClassicData.CanDualWield and GSI_ClassicData:CanDualWield()

    local v22Profile = (GSI_Config and GSI_Config.GetProfileV22 and GSI_Config:GetProfileV22(class, specIndex, effectiveMode))
                    or (GSI_Config and GSI_Config.GetProfile and GSI_Config:GetProfile(class, specIndex, effectiveMode))
                    or (GSI_Config and GSI_Config.GetProfileV21 and GSI_Config:GetProfileV21(class, specIndex, effectiveMode))
    local caps = v22Profile and v22Profile.caps

    -- Determine active weapons (for 2H/DW consistency and WeaponSkill matching)
    local mhLink = setup[INVSLOT_MAINHAND] and setup[INVSLOT_MAINHAND].link
    local mhLoc = mhLink and GetItemEquipLoc(mhLink)
    local mhIs2H = (mhLoc == "INVTYPE_2HWEAPON")
    local mhClassID, mhSubClassID = nil, nil
    if mhLink then
        mhClassID, mhSubClassID = GetItemClassSubClass(mhLink)
    end

    local ohActive = false
    local ohLink = setup[INVSLOT_OFFHAND] and setup[INVSLOT_OFFHAND].link
    local ohClassID, ohSubClassID = nil, nil
    if ohLink and not mhIs2H then
        local ohLoc = GetItemEquipLoc(ohLink)
        if class == "DRUID" and (specIndex == 2 or specIndex == 3) then
            ohActive = false
        elseif IsShieldTankSpec(class, specIndex) and ohLoc ~= "INVTYPE_SHIELD" then
            ohActive = false
        elseif (ohLoc == "INVTYPE_WEAPON" or ohLoc == "INVTYPE_WEAPONOFFHAND") and not canDualWield then
            ohActive = false
        else
            ohActive = true
            ohClassID, ohSubClassID = GetItemClassSubClass(ohLink)
        end
    end

    local rLink = setup[INVSLOT_RANGED] and setup[INVSLOT_RANGED].link
    local rClassID, rSubClassID = nil, nil
    if rLink then
        rClassID, rSubClassID = GetItemClassSubClass(rLink)
    end

    local hasAnyWeapon = (mhClassID == 2) or (ohActive and ohClassID == 2)

    local totalScore = 0
    local setupHit = 0
    local setupDef = 0
    local setupAvoid = 0
    local setupWpnSkill = 0
    local setCounts = {}

    -- 1. Sum non-cap base scores and accumulate capped stats & set counts across active slots
    for slotID, itemObj in pairs(setup) do
        local link = itemObj and itemObj.link
        if link and (slotID ~= INVSLOT_OFFHAND or ohActive) then
            local entry = GetItemSetupEntry(link, specIndex, effectiveMode, slotID, class, role, weights)
            totalScore = totalScore + entry.baseScore
            setupHit = setupHit + entry.hit
            setupDef = setupDef + entry.defense
            setupAvoid = setupAvoid + entry.avoidRed

            if entry.weaponSkill > 0 then
                local wsType = entry.weaponSkillType
                local matches = false
                if not wsType or wsType == "ALL" then
                    matches = true
                elseif wsType ~= "UNKNOWN" then
                    if RANGED_WEAPON_SKILL_TYPES[wsType] then
                        if rClassID == 2 then
                            matches = WeaponMatchesSkillType(wsType, rClassID, rSubClassID)
                        elseif not rLink and class == "HUNTER" then
                            matches = true
                        end
                    else
                        matches = (not hasAnyWeapon)
                            or WeaponMatchesSkillType(wsType, mhClassID, mhSubClassID)
                            or (ohActive and WeaponMatchesSkillType(wsType, ohClassID, ohSubClassID))
                    end
                end
                if matches then
                    setupWpnSkill = setupWpnSkill + entry.weaponSkill
                end
            end

            if entry.setName then
                setCounts[entry.setName] = (setCounts[entry.setName] or 0) + 1
            end
        end
    end

    -- 2. Apply active set bonuses per-threshold (prevents SP/Heal double-counting for both healers & non-healers
    --    while preserving multi-tier sets like Soulforge 4pc+6pc or Devout 3pc+6pc+8pc)
    if GSI_SetBonus then
        local activeThresholds = GetCachedSetBonusThresholds(setCounts)
        if activeThresholds then
            for _, thStats in ipairs(activeThresholds) do
                local thHeal = thStats.HealingPower or 0
                local thSP = thStats.SpellPower or 0
                local isUniThresholdSP = (thHeal == 0)
                for stat, val in pairs(thStats) do
                    if type(val) == "number" and val > 0 then
                        if stat == "Hit" then
                            setupHit = setupHit + val
                        elseif stat == "Defense" then
                            setupDef = setupDef + val
                        elseif stat == "AvoidanceReduction" then
                            setupAvoid = setupAvoid + val
                        elseif stat == "WeaponSkill" then
                            setupWpnSkill = setupWpnSkill + val
                        else
                            local w = GetEffectiveStatWeight(stat, weights, role, class, specIndex, isUniThresholdSP, thHeal, thSP)
                            totalScore = totalScore + (val * w)
                        end
                    end
                end
            end
        else
            local bonusStats = GetCachedSetBonusStats(setCounts)
            if bonusStats then
                local bHeal = bonusStats.HealingPower or 0
                local bSP = bonusStats.SpellPower or 0
                for stat, val in pairs(bonusStats) do
                    if type(val) == "number" and val > 0 then
                        if stat == "Hit" then
                            setupHit = setupHit + val
                        elseif stat == "Defense" then
                            setupDef = setupDef + val
                        elseif stat == "AvoidanceReduction" then
                            setupAvoid = setupAvoid + val
                        elseif stat == "WeaponSkill" then
                            setupWpnSkill = setupWpnSkill + val
                        else
                            local w = GetEffectiveStatWeight(stat, weights, role, class, specIndex, (bHeal == 0), bHeal, bSP)
                            totalScore = totalScore + (val * w)
                        end
                    end
                end
            end
        end

        if GSI_SetBonus.GetMaxEquipped then
            for setName, count in pairs(setCounts) do
                local maxEq = GSI_SetBonus:GetMaxEquipped(setName)
                if maxEq and count > maxEq then
                    totalScore = totalScore - (10000 * (count - maxEq))
                end
            end
        end
    end

    -- 3. Evaluate cumulative capped stats across the complete setup
    local baseline = GetBaselineCapStats(specIndex, effectiveMode, class, role)

    if setupHit > 0 then
        local hitCapCfg = caps and (caps.HIT or caps.SPELL_HIT)
        if hitCapCfg then
            local isAoEProfile = (v22Profile and v22Profile.isAoEProfile) or (effectiveMode == "AOE")
            local usesSpellHit = IsCasterSpec(role, class, specIndex) or (caps and caps.SPELL_HIT ~= nil and caps.HIT == nil)
            local capThreshold = hitCapCfg.cap_total_pct or hitCapCfg.cap_total or (usesSpellHit and 16 or 9)
            if usesSpellHit and not isAoEProfile and capThreshold >= 16 and GSI_Config and GSI_Config.Caps and GSI_Config.Caps.SpellHitCap then
                capThreshold = GSI_Config.Caps.SpellHitCap
            end
            totalScore = totalScore + EvaluateCapRange(baseline.hit, baseline.hit + setupHit, hitCapCfg, weights.Hit or 0, capThreshold)
        else
            totalScore = totalScore + (setupHit * (weights.Hit or 0))
        end
    end

    if setupDef > 0 then
        local defCapCfg = caps and caps.DEFENSE
        if defCapCfg then
            local capThreshold = defCapCfg.cap_total or defCapCfg.cap_total_pct or 440
            totalScore = totalScore + EvaluateCapRange(baseline.def, baseline.def + setupDef, defCapCfg, weights.Defense or 0, capThreshold, defCapCfg.above_w or 0.5)
        else
            totalScore = totalScore + (setupDef * (weights.Defense or 0))
        end
    end

    if setupAvoid > 0 then
        local avoidCapCfg = caps and caps.AVOID_RED
        if avoidCapCfg then
            local avoidCap = avoidCapCfg.cap_total_pct or 5.6
            local effectiveCap = math.max(0, avoidCap - (baseline.rogueTalentAvoid or 0))
            totalScore = totalScore + EvaluateCapRange(baseline.avoid, baseline.avoid + setupAvoid, avoidCapCfg, weights.AvoidanceReduction or 0, effectiveCap, avoidCapCfg.above_w or 0)
        else
            totalScore = totalScore + (setupAvoid * (weights.AvoidanceReduction or 0))
        end
    end

    if setupWpnSkill > 0 then
        local wpnCapCfg = caps and caps.WEAPON_SKILL
        if wpnCapCfg then
            local capThreshold = wpnCapCfg.cap_total_pct or wpnCapCfg.cap_total or 308
            totalScore = totalScore + EvaluateCapRange(baseline.weaponSkill, baseline.weaponSkill + setupWpnSkill, wpnCapCfg, weights.WeaponSkill or 0, capThreshold, wpnCapCfg.above_w or 0.5)
        else
            totalScore = totalScore + (setupWpnSkill * (weights.WeaponSkill or 0))
        end
    end

    return math.floor(totalScore * 100 + 0.5) / 100
end

-- Scans player bags for equippable upgrade candidates per slot
function GSI_OptimizationEngine:ScanBags(overrideSpecIndex, overrideMode)
    local candidatesBySlot = {}
    for _, s in ipairs(self.EQUIP_SLOTS) do
        candidatesBySlot[s] = {}
    end

    local canDualWield = GSI_ClassicData and GSI_ClassicData.CanDualWield and GSI_ClassicData:CanDualWield()
    local class = GetPlayerClassKey()
    local specIndex = overrideSpecIndex or (GSI_StatWeights and GSI_StatWeights.GetActiveSpecIndex and GSI_StatWeights:GetActiveSpecIndex()) or 1
    local isShieldTank = IsShieldTankSpec(class, specIndex)
    local isFeralDruid = (class == "DRUID" and (specIndex == 2 or specIndex == 3))
    local totalScanned = 0
    local equippableFound = 0

    for bag = 0, 5 do
        local numSlots = GetNumBagSlots(bag)
        for slot = 1, numSlots do
            totalScanned = totalScanned + 1
            local link = GetBagItemLink(bag, slot)
            if link then
                local equipLoc = GetItemEquipLoc(link)
                local classID, subClassID = GetItemClassSubClass(link)

                -- Skip non-equippable, trinkets (feature disabled), and fishing poles (subClassID 20)
                if equipLoc and equipLoc ~= "INVTYPE_NON_EQUIP" and equipLoc ~= "INVTYPE_TRINKET"
                    and not (classID == 2 and subClassID == 20) then
                    if self:IsItemUsableForPlayer(link, bag, slot) then
                        equippableFound = equippableFound + 1
                        local targetSlots = (GSI_ClassicData and GSI_ClassicData.GetEquipSlots and GSI_ClassicData:GetEquipSlots(equipLoc))
                                         or (GSI_ClassicData and GSI_ClassicData.EquipLocToSlots and GSI_ClassicData.EquipLocToSlots[equipLoc])
                        if targetSlots then
                            for _, targetSlot in ipairs(targetSlots) do
                                local skipSlot = (targetSlot == INVSLOT_OFFHAND and equipLoc == "INVTYPE_WEAPON" and not canDualWield)
                                    or (isFeralDruid and (equipLoc == "INVTYPE_SHIELD" or equipLoc == "INVTYPE_HOLDABLE" or equipLoc == "INVTYPE_WEAPONOFFHAND" or targetSlot == INVSLOT_OFFHAND))
                                    or (isShieldTank and (equipLoc == "INVTYPE_2HWEAPON" or equipLoc == "INVTYPE_WEAPONOFFHAND" or equipLoc == "INVTYPE_HOLDABLE" or (targetSlot == INVSLOT_OFFHAND and equipLoc ~= "INVTYPE_SHIELD")))
                                if skipSlot then
                                    -- Incompatible weapon/off-hand slot for this spec -> skip
                                else
                                    local itemScore = (GSI_ItemScore and GSI_ItemScore:Calculate(link, overrideSpecIndex, nil, overrideMode, targetSlot)) or 0
                                    table.insert(candidatesBySlot[targetSlot], {
                                        link = link,
                                        score = itemScore,
                                        bag = bag,
                                        slot = slot,
                                        sourceID = bag .. ":" .. slot,
                                        equipLoc = equipLoc
                                    })
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    for _, slotID in ipairs(self.EQUIP_SLOTS) do
        table.sort(candidatesBySlot[slotID], function(a, b) return (a.score or 0) > (b.score or 0) end)
    end

    self.lastScanStats = { totalScanned = totalScanned, equippableFound = equippableFound }
    return candidatesBySlot
end

-- Checks if a candidate carries capped stats or belongs to a set (so it stays in bounded pools even if raw score is lower)
local function HasSynergyStats(link)
    if not link then return false end
    if GSI_SetBonus and GSI_SetBonus.GetSetNameFromLink and GSI_SetBonus:GetSetNameFromLink(link) then
        return true
    end
    local stats = GSI_ItemScore and GSI_ItemScore.GetParsedStats and GSI_ItemScore:GetParsedStats(link)
    if stats then
        if (stats.Hit or 0) > 0 or (stats.Defense or 0) > 0
            or (stats.AvoidanceReduction or 0) > 0 or (stats.WeaponSkill or 0) > 0 then
            return true
        end
    end
    return false
end

-- Builds a bounded, deduplicated candidate pool (keeping up to maxCopies of identical itemLinks for dual-equip)
local function BuildCandidatePool(candidates, maxBase, maxCopies, filterFn)
    local pool = {}
    local seenLinks = {}
    local countBase = 0

    for _, cand in ipairs(candidates or {}) do
        if not filterFn or filterFn(cand) then
            local link = cand.link
            local copies = seenLinks[link] or 0
            if copies < maxCopies then
                if countBase < maxBase or HasSynergyStats(link) then
                    seenLinks[link] = copies + 1
                    table.insert(pool, cand)
                    countBase = countBase + 1
                end
            end
        end
    end

    return pool
end

-- Runs Best-in-Bag optimization across bags and equipped gear
function GSI_OptimizationEngine:OptimizeBagGearAsync(onProgress, onComplete, overrideSpecIndex, overrideMode)
    self.isStopped = false
    SyncCacheRevision()

    local class = GetPlayerClassKey()
    local specIndex = overrideSpecIndex or (GSI_StatWeights and GSI_StatWeights.GetActiveSpecIndex and GSI_StatWeights:GetActiveSpecIndex()) or 1
    local modeVal = ResolveEffectiveMode(class, specIndex, overrideMode)
    local role = (GSI_StatWeights and GSI_StatWeights.GetRole and GSI_StatWeights:GetRole(specIndex, modeVal)) or "dps"
    local canDualWield = GSI_ClassicData and GSI_ClassicData.CanDualWield and GSI_ClassicData:CanDualWield()

    local currentSetup = self:GetCurrentSetup()
    local baseScore = self:EvaluateSetup(currentSetup, specIndex, modeVal)

    local bestSetup = SafeCopyTable(currentSetup)
    local bestScore = baseScore

    local bagCandidates = self:ScanBags(specIndex, modeVal)
    local upgrades = {}
    local usedBagItems = {}
    local lockedSlots = (GearSetImproverDB and GearSetImproverDB.lockedGearSlots) or {}

    local function RecordBagSwap(slotID, newCand, gainDelta)
        local prevObj = bestSetup[slotID]
        if prevObj and prevObj.source == "bag" and prevObj.sourceID then
            usedBagItems[prevObj.sourceID] = nil
        end

        if newCand and newCand.source == "bag" then
            local sKey = newCand.sourceID or (newCand.bag .. ":" .. newCand.slot)
            bestSetup[slotID] = {
                link = newCand.link,
                source = "bag",
                bag = newCand.bag,
                slot = newCand.slot,
                sourceID = sKey,
            }
            usedBagItems[sKey] = true
            local prevDelta = (upgrades[slotID] and upgrades[slotID].delta) or 0
            upgrades[slotID] = {
                slotID   = slotID,
                itemLink = newCand.link,
                bag      = newCand.bag,
                slot     = newCand.slot,
                sourceID = sKey,
                delta    = prevDelta + gainDelta,
                oldLink  = currentSetup[slotID] and currentSetup[slotID].link,
                isLocked = false,
            }
        else
            -- Reverted or cleared (e.g., OH cleared when equipping 2H)
            bestSetup[slotID] = newCand
            upgrades[slotID] = nil
        end
    end

    -- Helper for ring pair optimization (jointly evaluates Finger 1 & Finger 2)
    local function OptimizeRingPair()
        local is11Locked = lockedSlots[INVSLOT_FINGER1]
        local is12Locked = lockedSlots[INVSLOT_FINGER2]
        if is11Locked and is12Locked then return end

        local cur11 = bestSetup[INVSLOT_FINGER1]
        local cur12 = bestSetup[INVSLOT_FINGER2]
        local allRings = bagCandidates[INVSLOT_FINGER1] or bagCandidates[INVSLOT_FINGER2] or {}
        if #allRings == 0 then return end

        local ringPool = BuildCandidatePool(allRings, 12, 2, function(cand)
            local sKey = cand.sourceID or (cand.bag .. ":" .. cand.slot)
            if not sKey then return false end
            if usedBagItems[sKey] then
                return (cur11 and cur11.sourceID == sKey) or (cur12 and cur12.sourceID == sKey)
            end
            return true
        end)

        -- Prepend current items as keep options
        local opt11 = {}
        local opt12 = {}
        if cur11 then table.insert(opt11, cur11) else table.insert(opt11, false) end
        if cur12 then table.insert(opt12, cur12) else table.insert(opt12, false) end

        if not is11Locked then
            for _, c in ipairs(ringPool) do
                if not cur11 or cur11.sourceID ~= c.sourceID then
                    table.insert(opt11, { link = c.link, source = "bag", bag = c.bag, slot = c.slot, sourceID = c.sourceID, score = c.score, equipLoc = c.equipLoc })
                end
            end
        end
        if not is12Locked then
            for _, c in ipairs(ringPool) do
                if not cur12 or cur12.sourceID ~= c.sourceID then
                    table.insert(opt12, { link = c.link, source = "bag", bag = c.bag, slot = c.slot, sourceID = c.sourceID, score = c.score, equipLoc = c.equipLoc })
                end
            end
        end

        -- Determine weaker slot first so single-ring upgrades replace the weaker ring on ties
        local sc11 = cur11 and (GSI_ItemScore and GSI_ItemScore:Calculate(cur11.link, specIndex, nil, modeVal, INVSLOT_FINGER1) or 0) or 0
        local sc12 = cur12 and (GSI_ItemScore and GSI_ItemScore:Calculate(cur12.link, specIndex, nil, modeVal, INVSLOT_FINGER2) or 0) or 0
        local testOrderFirst11 = (sc11 <= sc12)

        local testSetup = SafeCopyTable(bestSetup)
        local bestPair11, bestPair12 = cur11, cur12
        local bestPairScore = bestScore

        local function TryPair(c11, c12)
            local obj11 = c11 or nil
            local obj12 = c12 or nil
            if obj11 and obj12 and obj11.sourceID and obj12.sourceID and obj11.sourceID == obj12.sourceID then
                return
            end
            -- Skip unchanged pair
            if obj11 == cur11 and obj12 == cur12 then
                return
            end

            testSetup[INVSLOT_FINGER1] = obj11
            testSetup[INVSLOT_FINGER2] = obj12

            if obj11 and self:HasUniqueConflict(obj11.link, testSetup, INVSLOT_FINGER1, "INVTYPE_FINGER") then
                return
            end
            if obj12 and self:HasUniqueConflict(obj12.link, testSetup, INVSLOT_FINGER2, "INVTYPE_FINGER") then
                return
            end

            local newScore = self:EvaluateSetup(testSetup, specIndex, modeVal)
            if newScore > bestPairScore + 1e-6 then
                bestPairScore = newScore
                bestPair11 = obj11
                bestPair12 = obj12
            end
        end

        if testOrderFirst11 then
            -- First evaluate replacing Finger 1 only, then Finger 2 only, then joint pairs
            for _, c11 in ipairs(opt11) do
                TryPair(c11, opt12[1])
            end
            for _, c12 in ipairs(opt12) do
                TryPair(opt11[1], c12)
            end
        else
            for _, c12 in ipairs(opt12) do
                TryPair(opt11[1], c12)
            end
            for _, c11 in ipairs(opt11) do
                TryPair(c11, opt12[1])
            end
        end

        for i = 2, #opt11 do
            for j = 2, #opt12 do
                TryPair(opt11[i], opt12[j])
            end
        end

        if bestPairScore > bestScore + 1e-6 then
            local totalPairGain = bestPairScore - bestScore
            local changed11 = (bestPair11 ~= cur11)
            local changed12 = (bestPair12 ~= cur12)
            local isBag11 = (bestPair11 and bestPair11.source == "bag")
            local isBag12 = (bestPair12 and bestPair12.source == "bag")

            if changed11 and not changed12 then
                RecordBagSwap(INVSLOT_FINGER1, bestPair11, isBag11 and totalPairGain or 0)
            elseif changed12 and not changed11 then
                RecordBagSwap(INVSLOT_FINGER2, bestPair12, isBag12 and totalPairGain or 0)
            elseif changed11 and changed12 then
                if isBag11 and not isBag12 then
                    RecordBagSwap(INVSLOT_FINGER2, bestPair12, 0)
                    RecordBagSwap(INVSLOT_FINGER1, bestPair11, totalPairGain)
                elseif isBag12 and not isBag11 then
                    RecordBagSwap(INVSLOT_FINGER1, bestPair11, 0)
                    RecordBagSwap(INVSLOT_FINGER2, bestPair12, totalPairGain)
                elseif isBag11 and isBag12 then
                    local g1 = math.max(0.01, (bestPair11.score or 0) - sc11)
                    local g2 = math.max(0.01, (bestPair12.score or 0) - sc12)
                    local d1 = totalPairGain * (g1 / (g1 + g2))
                    local d2 = totalPairGain - d1
                    RecordBagSwap(INVSLOT_FINGER1, bestPair11, d1)
                    RecordBagSwap(INVSLOT_FINGER2, bestPair12, d2)
                else
                    RecordBagSwap(INVSLOT_FINGER1, bestPair11, 0)
                    RecordBagSwap(INVSLOT_FINGER2, bestPair12, 0)
                end
            end
            bestScore = bestPairScore
        end
    end

    -- Helper for weapon pair optimization (jointly evaluates Main Hand vs Off Hand / 2H)
    local function OptimizeWeaponPair()
        local isMHLocked = lockedSlots[INVSLOT_MAINHAND]
        local isOHLocked = lockedSlots[INVSLOT_OFFHAND]
        if isMHLocked and isOHLocked then return end

        local curMH = bestSetup[INVSLOT_MAINHAND]
        local curOH = bestSetup[INVSLOT_OFFHAND]
        local curMHLoc = curMH and GetItemEquipLoc(curMH.link)
        local curMHIs2H = (curMHLoc == "INVTYPE_2HWEAPON")

        -- If Main Hand is locked with a 2H weapon, Off-Hand cannot be equipped
        if isMHLocked and curMHIs2H then
            return
        end

        local curOHLoc = curOH and GetItemEquipLoc(curOH.link)
        local isShieldTank = IsShieldTankSpec(GetPlayerClassKey(), specIndex)
        local protectTankShield = (role == "tank" and modeVal == "Survival" and curOHLoc == "INVTYPE_SHIELD")

        local mhAll = bagCandidates[INVSLOT_MAINHAND] or {}
        local ohAll = bagCandidates[INVSLOT_OFFHAND] or {}

        local mhOneHandPool = {}
        local mhTwoHandPool = {}
        if not isMHLocked then
            mhOneHandPool = BuildCandidatePool(mhAll, 8, 2, function(cand)
                if cand.equipLoc == "INVTYPE_2HWEAPON" then return false end
                local sKey = cand.sourceID or (cand.bag .. ":" .. cand.slot)
                if not sKey then return false end
                if usedBagItems[sKey] then
                    return (curMH and curMH.sourceID == sKey) or (curOH and curOH.sourceID == sKey)
                end
                return true
            end)
            -- Only consider 2H weapons if Off-Hand is NOT locked and not a Shield-Tank spec!
            -- (Important: skip 2H rather than breaking so 1H MH candidates remain evaluated!)
            if not isOHLocked and not isShieldTank then
                mhTwoHandPool = BuildCandidatePool(mhAll, 6, 1, function(cand)
                    if cand.equipLoc ~= "INVTYPE_2HWEAPON" then return false end
                    local sKey = cand.sourceID or (cand.bag .. ":" .. cand.slot)
                    if not sKey then return false end
                    if usedBagItems[sKey] then
                        return (curMH and curMH.sourceID == sKey)
                    end
                    return true
                end)
            end
        end

        local ohPool = {}
        if not isOHLocked then
            ohPool = BuildCandidatePool(ohAll, 8, 2, function(cand)
                if isShieldTank and cand.equipLoc ~= "INVTYPE_SHIELD" then
                    return false
                end
                if protectTankShield and (cand.equipLoc == "INVTYPE_WEAPON" or cand.equipLoc == "INVTYPE_WEAPONOFFHAND") then
                    return false
                end
                local sKey = cand.sourceID or (cand.bag .. ":" .. cand.slot)
                if not sKey then return false end
                if usedBagItems[sKey] then
                    return (curMH and curMH.sourceID == sKey) or (curOH and curOH.sourceID == sKey)
                end
                return true
            end)
        end

        local opt1HMH = {}
        if curMH and not curMHIs2H then
            table.insert(opt1HMH, curMH)
        elseif currentSetup[INVSLOT_MAINHAND] and GetItemEquipLoc(currentSetup[INVSLOT_MAINHAND].link) ~= "INVTYPE_2HWEAPON" then
            table.insert(opt1HMH, currentSetup[INVSLOT_MAINHAND])
        elseif not curMH then
            table.insert(opt1HMH, false)
        end
        for _, c in ipairs(mhOneHandPool) do
            if not curMH or curMH.sourceID ~= c.sourceID then
                table.insert(opt1HMH, { link = c.link, source = "bag", bag = c.bag, slot = c.slot, sourceID = c.sourceID, score = c.score, equipLoc = c.equipLoc })
            end
        end

        local optOH = {}
        if curOH then
            table.insert(optOH, curOH)
        elseif currentSetup[INVSLOT_OFFHAND] and not isOHLocked then
            table.insert(optOH, currentSetup[INVSLOT_OFFHAND])
        else
            table.insert(optOH, false)
        end
        for _, c in ipairs(ohPool) do
            if not curOH or curOH.sourceID ~= c.sourceID then
                table.insert(optOH, { link = c.link, source = "bag", bag = c.bag, slot = c.slot, sourceID = c.sourceID, score = c.score, equipLoc = c.equipLoc })
            end
        end

        local testSetup = SafeCopyTable(bestSetup)
        local bestPairMH, bestPairOH = curMH, curOH
        local bestPairScore = bestScore

        local function TryWeaponPair(cMH, cOH)
            local objMH = cMH or nil
            local objOH = cOH or nil

            if curMH and not objMH then
                return
            end
            if objMH and objOH and objMH.sourceID and objOH.sourceID and objMH.sourceID == objOH.sourceID then
                return
            end
            if objMH == curMH and objOH == curOH then
                return
            end

            -- Enforce 2H vs OH mutual exclusion & Shield-Tank rules
            local mhLoc = objMH and (objMH.equipLoc or GetItemEquipLoc(objMH.link))
            if mhLoc == "INVTYPE_2HWEAPON" then
                if isOHLocked or isShieldTank then return end
                objOH = nil
            elseif objOH then
                local ohLoc = objOH.equipLoc or GetItemEquipLoc(objOH.link)
                if isShieldTank and ohLoc ~= "INVTYPE_SHIELD" then
                    return
                elseif (ohLoc == "INVTYPE_WEAPON" or ohLoc == "INVTYPE_WEAPONOFFHAND") and not canDualWield then
                    return
                end
            end

            testSetup[INVSLOT_MAINHAND] = objMH
            testSetup[INVSLOT_OFFHAND] = objOH

            if objMH and self:HasUniqueConflict(objMH.link, testSetup, INVSLOT_MAINHAND, mhLoc) then
                return
            end
            if objOH and self:HasUniqueConflict(objOH.link, testSetup, INVSLOT_OFFHAND, objOH.equipLoc) then
                return
            end

            local newScore = self:EvaluateSetup(testSetup, specIndex, modeVal)
            if newScore > bestPairScore + 1e-6 then
                bestPairScore = newScore
                bestPairMH = objMH
                bestPairOH = objOH
            end
        end

        -- 1. Evaluate 1H/MH + OH pairs
        for _, cMH in ipairs(opt1HMH) do
            for _, cOH in ipairs(optOH) do
                TryWeaponPair(cMH, cOH)
            end
        end

        -- 2. Evaluate 2H MH candidates (with OH cleared) when OH is not locked and not a Shield-Tank spec
        if not isMHLocked and not isOHLocked and not isShieldTank then
            for _, c in ipairs(mhTwoHandPool) do
                if not curMH or curMH.sourceID ~= c.sourceID then
                    TryWeaponPair({ link = c.link, source = "bag", bag = c.bag, slot = c.slot, sourceID = c.sourceID, score = c.score, equipLoc = c.equipLoc }, nil)
                end
            end
        end

        if bestPairScore > bestScore + 1e-6 then
            local totalPairGain = bestPairScore - bestScore
            local changedMH = (bestPairMH ~= curMH)
            local changedOH = (bestPairOH ~= curOH)
            local isBagMH = (bestPairMH and bestPairMH.source == "bag")
            local isBagOH = (bestPairOH and bestPairOH.source == "bag")

            if changedMH and not changedOH then
                RecordBagSwap(INVSLOT_MAINHAND, bestPairMH, isBagMH and totalPairGain or 0)
            elseif changedOH and not changedMH then
                RecordBagSwap(INVSLOT_OFFHAND, bestPairOH, isBagOH and totalPairGain or 0)
            elseif changedMH and changedOH then
                if isBagMH and not isBagOH then
                    -- Switched to a 2H weapon (cleared OH) or reverted OH to equipped
                    RecordBagSwap(INVSLOT_OFFHAND, bestPairOH, 0)
                    RecordBagSwap(INVSLOT_MAINHAND, bestPairMH, totalPairGain)
                elseif isBagOH and not isBagMH then
                    -- Reverted MH to equipped while equipping a bag OH
                    RecordBagSwap(INVSLOT_MAINHAND, bestPairMH, 0)
                    RecordBagSwap(INVSLOT_OFFHAND, bestPairOH, totalPairGain)
                elseif isBagMH and isBagOH then
                    local curMHScore = curMH and (GSI_ItemScore and GSI_ItemScore:Calculate(curMH.link, specIndex, nil, modeVal, INVSLOT_MAINHAND) or 0) or 0
                    local curOHScore = curOH and (GSI_ItemScore and GSI_ItemScore:Calculate(curOH.link, specIndex, nil, modeVal, INVSLOT_OFFHAND) or 0) or 0
                    local gMH = math.max(0.01, (bestPairMH.score or 0) - curMHScore)
                    local gOH = math.max(0.01, (bestPairOH.score or 0) - curOHScore)
                    local dMH = totalPairGain * (gMH / (gMH + gOH))
                    local dOH = totalPairGain - dMH
                    RecordBagSwap(INVSLOT_MAINHAND, bestPairMH, dMH)
                    RecordBagSwap(INVSLOT_OFFHAND, bestPairOH, dOH)
                else
                    RecordBagSwap(INVSLOT_MAINHAND, bestPairMH, 0)
                    RecordBagSwap(INVSLOT_OFFHAND, bestPairOH, 0)
                end
            end
            bestScore = bestPairScore
        end
    end

    -- Multi-pass convergence (bounded to 3 passes with early exit)
    local MAX_PASSES = 3
    for _ = 1, MAX_PASSES do
        if self.isStopped then break end
        local passStartScore = bestScore

        OptimizeRingPair()
        if self.isStopped then break end

        OptimizeWeaponPair()
        if self.isStopped then break end

        local testSetup = SafeCopyTable(bestSetup)
        for _, slotID in ipairs(self.EQUIP_SLOTS) do
            if self.isStopped then break end
            if slotID ~= INVSLOT_FINGER1 and slotID ~= INVSLOT_FINGER2
                and slotID ~= INVSLOT_MAINHAND and slotID ~= INVSLOT_OFFHAND then
                if not lockedSlots[slotID] then
                    local curSlotObj = bestSetup[slotID]
                    local candidates = bagCandidates[slotID] or {}
                    local bestCand = nil
                    local bestCandScore = bestScore

                    for _, cand in ipairs(candidates) do
                        local sKey = cand.sourceID or (cand.bag .. ":" .. cand.slot)
                        local isAvailable = sKey and (not usedBagItems[sKey] or (curSlotObj and curSlotObj.sourceID == sKey))
                        if isAvailable and (not curSlotObj or curSlotObj.sourceID ~= sKey) then
                            if not self:HasUniqueConflict(cand.link, testSetup, slotID, cand.equipLoc) then
                                testSetup[slotID] = { link = cand.link, source = "bag", bag = cand.bag, slot = cand.slot, sourceID = sKey }
                                local newScore = self:EvaluateSetup(testSetup, specIndex, modeVal)
                                if newScore > bestCandScore + 1e-6 then
                                    bestCandScore = newScore
                                    bestCand = cand
                                end
                            end
                        end
                    end

                    if bestCand and bestCandScore > bestScore + 1e-6 then
                        local gainDelta = bestCandScore - bestScore
                        bestScore = bestCandScore
                        RecordBagSwap(slotID, {
                            link = bestCand.link,
                            source = "bag",
                            bag = bestCand.bag,
                            slot = bestCand.slot,
                            sourceID = bestCand.sourceID or (bestCand.bag .. ":" .. bestCand.slot),
                        }, gainDelta)
                        testSetup[slotID] = bestSetup[slotID]
                    else
                        testSetup[slotID] = curSlotObj
                    end
                end
            end
        end

        if (bestScore - passStartScore) < 0.01 then
            break
        end
    end

    -- Informational upgrade check for locked slots (never modifies bestSetup or totalGain)
    local finalTestSetup = SafeCopyTable(bestSetup)
    for _, slotID in ipairs(self.EQUIP_SLOTS) do
        if self.isStopped then break end
        if lockedSlots[slotID] and not upgrades[slotID] then
            local candidates = bagCandidates[slotID] or {}
            local bestLockedCand = nil
            local bestLockedScore = bestScore
            local isOHLocked = lockedSlots[INVSLOT_OFFHAND]

            for _, cand in ipairs(candidates) do
                local sKey = cand.sourceID or (cand.bag .. ":" .. cand.slot)
                if sKey and not usedBagItems[sKey] then
                    local blocked2H = (slotID == INVSLOT_MAINHAND and cand.equipLoc == "INVTYPE_2HWEAPON" and (isOHLocked or IsShieldTankSpec(GetPlayerClassKey(), specIndex)))
                    if not blocked2H and not self:HasUniqueConflict(cand.link, finalTestSetup, slotID, cand.equipLoc) then
                        local prevObj = finalTestSetup[slotID]
                        local prevOH = finalTestSetup[INVSLOT_OFFHAND]
                        finalTestSetup[slotID] = { link = cand.link, source = "bag", bag = cand.bag, slot = cand.slot, sourceID = sKey }
                        if slotID == INVSLOT_MAINHAND and cand.equipLoc == "INVTYPE_2HWEAPON" then
                            finalTestSetup[INVSLOT_OFFHAND] = nil
                        end
                        local newScore = self:EvaluateSetup(finalTestSetup, specIndex, modeVal)
                        finalTestSetup[slotID] = prevObj
                        finalTestSetup[INVSLOT_OFFHAND] = prevOH
                        if newScore > bestLockedScore + 0.01 then
                            bestLockedScore = newScore
                            bestLockedCand = cand
                        end
                    end
                end
            end

            if bestLockedCand then
                local sKey = bestLockedCand.sourceID or (bestLockedCand.bag .. ":" .. bestLockedCand.slot)
                upgrades[slotID] = {
                    slotID   = slotID,
                    itemLink = bestLockedCand.link,
                    bag      = bestLockedCand.bag,
                    slot     = bestLockedCand.slot,
                    sourceID = sKey,
                    delta    = math.floor((bestLockedScore - bestScore) * 100 + 0.5) / 100,
                    oldLink  = currentSetup[slotID] and currentSetup[slotID].link,
                    isLocked = true,
                }
            end
        end
    end

    -- Ensure final rounding on upgrade deltas and remove any cleared OH upgrade if MH ended up 2H
    if bestSetup[INVSLOT_MAINHAND] and GetItemEquipLoc(bestSetup[INVSLOT_MAINHAND].link) == "INVTYPE_2HWEAPON" then
        upgrades[INVSLOT_OFFHAND] = nil
    end
    for slotID, up in pairs(upgrades) do
        if up and up.delta then
            up.delta = math.floor(up.delta * 100 + 0.5) / 100
        end
        if up and up.delta and up.delta <= 0 then
            upgrades[slotID] = nil
        end
    end

    local totalGain = math.floor((bestScore - baseScore) * 100 + 0.5) / 100
    local scanStats = self.lastScanStats or { totalScanned = 0, equippableFound = 0 }

    if onComplete then
        onComplete(bestSetup, bestScore, upgrades, totalGain, scanStats)
    end
end
