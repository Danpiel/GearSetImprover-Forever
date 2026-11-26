-- ============================================================
-- GearSetImprover - CompareEngine.lua (WoW Forever)
-- Evaluates hovered / candidate items holistically against the
-- player's currently equipped setup using GSI_OptimizationEngine.
-- ============================================================

local INVSLOT_FINGER1  = _G.INVSLOT_FINGER1 or 11
local INVSLOT_FINGER2  = _G.INVSLOT_FINGER2 or 12
local INVSLOT_MAINHAND = _G.INVSLOT_MAINHAND or 16
local INVSLOT_OFFHAND  = _G.INVSLOT_OFFHAND or 17

local GetItemInfo = (C_Item and C_Item.GetItemInfo) or _G.GetItemInfo or function() return nil end
local GetItemInfoInstant = (C_Item and C_Item.GetItemInfoInstant) or _G.GetItemInfoInstant or function() return nil end
local IsEquippableItemFn = (C_Item and C_Item.IsEquippableItem) or _G.IsEquippableItem

local DEFAULT_EQUIP_SLOTS = {
    1, 2, 3, 15, 5, 9, 10, 6, 7, 8, 11, 12, 16, 17, 18
}

GSI_CompareEngine = {}

-- Tooltip-hover snapshot caches (invalidated automatically on equipment,
-- OptimizationEngine cache version, or GSI_TooltipCache revision changes)
local cachedSetup = nil
local cachedSlotLinks = {}
local cachedBaseScores = {}
local cachedOptVersion = -1
local cachedTooltipRev = -1
local reusableHoverObj = { link = nil, source = "hover", slot = nil }

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

local function GetPlayerClassKey()
    if GSI_ClassicData and GSI_ClassicData.GetPlayerClass then
        return GSI_ClassicData:GetPlayerClass()
    end
    return select(2, UnitClass("player")) or "WARRIOR"
end

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

function GSI_CompareEngine:ResetCache()
    cachedSetup = nil
    for k in pairs(cachedBaseScores) do
        cachedBaseScores[k] = nil
    end
    for k in pairs(cachedSlotLinks) do
        cachedSlotLinks[k] = nil
    end
    cachedOptVersion = -1
    cachedTooltipRev = -1
    if self._ClearSetSetups then self._ClearSetSetups() end
end

local function EnsureSetupSnapshot(specIndex, effectiveMode)
    local optVer = (GSI_OptimizationEngine and GSI_OptimizationEngine._cacheVersion) or 0
    local tipRev = (GSI_TooltipCache and GSI_TooltipCache.revision) or 0
    local equipSlots = (GSI_OptimizationEngine and GSI_OptimizationEngine.EQUIP_SLOTS)
                    or (GSI_ClassicData and GSI_ClassicData.EQUIP_SLOTS)
                    or DEFAULT_EQUIP_SLOTS

    local needsRefresh = (cachedSetup == nil) or (optVer ~= cachedOptVersion) or (tipRev ~= cachedTooltipRev)
    local equipmentChanged = false

    for _, slotID in ipairs(equipSlots) do
        local curLink = (GetInventoryItemLink and GetInventoryItemLink("player", slotID)) or ""
        if cachedSlotLinks[slotID] ~= curLink then
            equipmentChanged = true
            needsRefresh = true
            break
        end
    end

    if equipmentChanged and GSI_OptimizationEngine and GSI_OptimizationEngine.ResetCache then
        -- Sync OptimizationEngine BaselineCapCache if an equipment swap occurred silently
        GSI_OptimizationEngine:ResetCache()
        optVer = GSI_OptimizationEngine._cacheVersion or optVer
        tipRev = (GSI_TooltipCache and GSI_TooltipCache.revision) or tipRev
    end

    if needsRefresh then
        if not cachedSetup then
            cachedSetup = {}
        else
            for k in pairs(cachedSetup) do
                cachedSetup[k] = nil
            end
        end
        for k in pairs(cachedBaseScores) do
            cachedBaseScores[k] = nil
        end

        for _, slotID in ipairs(equipSlots) do
            local curLink = (GetInventoryItemLink and GetInventoryItemLink("player", slotID)) or ""
            cachedSlotLinks[slotID] = curLink
            if curLink ~= "" then
                cachedSetup[slotID] = { link = curLink, source = "equipped", slot = slotID }
            end
        end

        cachedOptVersion = optVer
        cachedTooltipRev = tipRev
    end

    local baseKey = tostring(specIndex) .. ":" .. tostring(effectiveMode)
    local baseScore = cachedBaseScores[baseKey]
    if baseScore == nil then
        baseScore = (GSI_OptimizationEngine and GSI_OptimizationEngine.EvaluateSetup and GSI_OptimizationEngine:EvaluateSetup(cachedSetup, specIndex, effectiveMode)) or 0
        cachedBaseScores[baseKey] = baseScore
    end

    return cachedSetup, baseScore
end

-- ------------------------------------------------------------
-- An Equipment Manager set as a setup, so a tooltip line for another spec
-- can compare the item with that spec's own gear instead of what is worn.
-- Slots the set ignores keep the worn item. Each set item is looked up by its
-- item ID: worn first, then the bags, else its plain link (in the bank).
-- Kept until the tooltip cache revision or the optimizer cache changes
-- (gear swaps, talents, EQUIPMENT_SETS_CHANGED reset the tooltip cache).
-- ------------------------------------------------------------
local setSetups = {} -- [setName] = { rev = , opt = , setup = , bases = {} }
GSI_CompareEngine._ClearSetSetups = function()
    for k in pairs(setSetups) do setSetups[k] = nil end
end

local function IndexBagLinksByID()
    local byID = {}
    local CC = C_Container
    if not (CC and CC.GetContainerNumSlots and CC.GetContainerItemID and CC.GetContainerItemLink) then return byID end
    local lastBag = _G.NUM_TOTAL_EQUIPPED_BAG_SLOTS or _G.NUM_BAG_SLOTS or 4
    for bag = 0, lastBag do
        local okN, n = pcall(CC.GetContainerNumSlots, bag)
        for slot = 1, (okN and n) or 0 do
            local id = CC.GetContainerItemID(bag, slot)
            if id and not byID[id] then
                byID[id] = CC.GetContainerItemLink(bag, slot)
            end
        end
    end
    return byID
end

local function BuildSetSetup(setID)
    local CE = C_EquipmentSet
    local okIds, ids = pcall(CE.GetItemIDs, setID)
    if not okIds or type(ids) ~= "table" then return nil end
    local ignored = {}
    if CE.GetIgnoredSlots then
        local okIg, ig = pcall(CE.GetIgnoredSlots, setID)
        if okIg and type(ig) == "table" then ignored = ig end
    end
    local equipSlots = (GSI_OptimizationEngine and GSI_OptimizationEngine.EQUIP_SLOTS)
                    or (GSI_ClassicData and GSI_ClassicData.EQUIP_SLOTS)
                    or DEFAULT_EQUIP_SLOTS
    local worn, wornByID = {}, {}
    for _, slotID in ipairs(equipSlots) do
        local link = GetInventoryItemLink and GetInventoryItemLink("player", slotID)
        if link then
            worn[slotID] = link
            local id = GetInventoryItemID and GetInventoryItemID("player", slotID)
            if id and not wornByID[id] then wornByID[id] = link end
        end
    end
    local bagByID = nil
    local setup = {}
    for _, slotID in ipairs(equipSlots) do
        local id = ids[slotID]
        local link = nil
        if ignored[slotID] then
            link = worn[slotID]
        elseif type(id) == "number" and id > 1 then
            if GetInventoryItemID and GetInventoryItemID("player", slotID) == id then
                link = worn[slotID]
            end
            link = link or wornByID[id]
            if not link then
                bagByID = bagByID or IndexBagLinksByID()
                link = bagByID[id]
            end
            link = link or select(2, GetItemInfo(id)) or ("item:" .. id)
        end
        if link then
            setup[slotID] = { link = link, source = "equipped", slot = slotID }
        end
    end
    return setup
end

-- Returns the set's setup and its score for specIndex / mode (nil when the
-- set does not exist).
function GSI_CompareEngine:GetSetSetup(setName, specIndex, overrideMode)
    if not setName or not (C_EquipmentSet and C_EquipmentSet.GetEquipmentSetID and C_EquipmentSet.GetItemIDs) then
        return nil
    end
    local setID = C_EquipmentSet.GetEquipmentSetID(setName)
    if not setID then return nil end
    local rev = (GSI_TooltipCache and GSI_TooltipCache.revision) or 0
    local opt = (GSI_OptimizationEngine and GSI_OptimizationEngine._cacheVersion) or 0
    local entry = setSetups[setName]
    if not entry or entry.rev ~= rev or entry.opt ~= opt then
        local setup = BuildSetSetup(setID)
        if not setup then return nil end
        entry = { rev = rev, opt = opt, setup = setup, bases = {} }
        setSetups[setName] = entry
    end
    local effectiveMode = ResolveEffectiveMode(GetPlayerClassKey(), specIndex, overrideMode)
    local baseKey = tostring(specIndex) .. ":" .. tostring(effectiveMode)
    local base = entry.bases[baseKey]
    if base == nil then
        base = (GSI_OptimizationEngine and GSI_OptimizationEngine.EvaluateSetup
            and GSI_OptimizationEngine:EvaluateSetup(entry.setup, specIndex, effectiveMode)) or 0
        entry.bases[baseKey] = base
    end
    return entry.setup, base
end

-- Compares itemLink against the best replacement slot in currentSetupObjs (or player's equipped gear).
-- Returns: bestEquippedLink, bestEquippedScore, bestNewScore, finalDelta, isUpgrade, bestSlotID, isLevelTooHigh, minLevel
function GSI_CompareEngine:Compare(itemLink, currentSetupObjs, baseFullScore, overrideSpecIndex, overrideMode)
    if not itemLink or itemLink == "" then
        return nil, nil, nil, nil, nil
    end

    if IsEquippableItemFn then
        local eq = IsEquippableItemFn(itemLink)
        if eq == false then
            return nil, nil, nil, nil, nil
        end
    end

    if GSI_OptimizationEngine and GSI_OptimizationEngine.IsItemUsableForPlayer then
        if not GSI_OptimizationEngine:IsItemUsableForPlayer(itemLink, nil, nil, true) then
            return nil, nil, nil, nil, nil
        end
    end

    local _, _, _, _, minLevel = GetItemInfo(itemLink)
    minLevel = minLevel or 0
    local playerLevel = UnitLevel("player") or 60
    local isLevelTooHigh = (minLevel > playerLevel)

    local equipLoc = GetItemEquipLoc(itemLink)
    if not equipLoc or equipLoc == "INVTYPE_NON_EQUIP" or equipLoc == "INVTYPE_TRINKET" then
        return nil, nil, nil, nil, nil
    end

    local defaultSlot = GSI_ClassicData and GSI_ClassicData.EquipLocToSlot and GSI_ClassicData.EquipLocToSlot[equipLoc]
    if not defaultSlot then
        return nil, nil, nil, nil, nil
    end

    local class = GetPlayerClassKey()
    local specIndex = overrideSpecIndex or (GSI_StatWeights and GSI_StatWeights.GetActiveSpecIndex and GSI_StatWeights:GetActiveSpecIndex()) or 1
    local effectiveMode = ResolveEffectiveMode(class, specIndex, overrideMode)

    local newScore = GSI_ItemScore and GSI_ItemScore:Calculate(itemLink, specIndex, nil, effectiveMode, defaultSlot)
    if not newScore then
        return nil, nil, nil, nil, nil
    end

    local setupObjs = currentSetupObjs
    local baseScore = baseFullScore
    if not setupObjs then
        setupObjs, baseScore = EnsureSetupSnapshot(specIndex, effectiveMode)
    elseif baseScore == nil then
        baseScore = (GSI_OptimizationEngine and GSI_OptimizationEngine.EvaluateSetup and GSI_OptimizationEngine:EvaluateSetup(setupObjs, specIndex, effectiveMode)) or 0
    end

    if not GSI_OptimizationEngine or not GSI_OptimizationEngine.EvaluateSetup then
        return nil, nil, nil, nil, nil
    end

    -- Prepare reusable hover item descriptor without stale fields
    reusableHoverObj.link = itemLink
    reusableHoverObj.source = "hover"
    reusableHoverObj.slot = nil

    local bestDelta = -math.huge
    local bestEquippedLink = nil
    local bestEquippedScore = 0
    local bestSlotID = nil
    local bestNewScore = newScore

    local function TestReplacement(slotID)
        if not slotID then return end

        -- Enforce Unique / Unique-Equipped / Unique-Equipped family rules via OptimizationEngine
        if GSI_OptimizationEngine.HasUniqueConflict then
            if GSI_OptimizationEngine:HasUniqueConflict(itemLink, setupObjs, slotID, equipLoc) then
                return
            end
        end

        local oldObj = setupObjs[slotID]
        local eqLink = oldObj and oldObj.link
        local eqScore = 0
        if eqLink then
            eqScore = (GSI_ItemScore and GSI_ItemScore:Calculate(eqLink, specIndex, nil, effectiveMode, slotID)) or 0
        end

        local savedOH = nil
        local savedMH = nil

        if slotID == INVSLOT_MAINHAND and equipLoc == "INVTYPE_2HWEAPON" then
            savedOH = setupObjs[INVSLOT_OFFHAND]
            if savedOH and savedOH.link then
                eqScore = eqScore + ((GSI_ItemScore and GSI_ItemScore:Calculate(savedOH.link, specIndex, nil, effectiveMode, INVSLOT_OFFHAND)) or 0)
                if not eqLink then
                    eqLink = savedOH.link
                end
            end
        elseif slotID == INVSLOT_OFFHAND and setupObjs[INVSLOT_MAINHAND] then
            local mhLoc = GetItemEquipLoc(setupObjs[INVSLOT_MAINHAND].link)
            if mhLoc == "INVTYPE_2HWEAPON" then
                savedMH = setupObjs[INVSLOT_MAINHAND]
                if savedMH and savedMH.link then
                    eqScore = eqScore + ((GSI_ItemScore and GSI_ItemScore:Calculate(savedMH.link, specIndex, nil, effectiveMode, INVSLOT_MAINHAND)) or 0)
                    if not eqLink then
                        eqLink = savedMH.link
                    end
                end
            end
        end

        -- Mutate temporarily and protect restoration even if EvaluateSetup errors
        setupObjs[slotID] = reusableHoverObj
        if savedOH ~= nil then
            setupObjs[INVSLOT_OFFHAND] = nil
        end
        if savedMH ~= nil then
            setupObjs[INVSLOT_MAINHAND] = nil
        end

        local okEval, newFullScore = pcall(GSI_OptimizationEngine.EvaluateSetup, GSI_OptimizationEngine, setupObjs, specIndex, effectiveMode)

        setupObjs[slotID] = oldObj
        if savedOH ~= nil then
            setupObjs[INVSLOT_OFFHAND] = savedOH
        end
        if savedMH ~= nil then
            setupObjs[INVSLOT_MAINHAND] = savedMH
        end

        if not okEval or type(newFullScore) ~= "number" then
            return
        end

        local delta = newFullScore - baseScore
        if bestSlotID == nil or delta > bestDelta + 1e-6 then
            bestDelta = delta
            bestEquippedLink = eqLink
            bestEquippedScore = eqScore
            bestSlotID = slotID
            if slotID == defaultSlot then
                bestNewScore = newScore
            else
                bestNewScore = (GSI_ItemScore and GSI_ItemScore:Calculate(itemLink, specIndex, nil, effectiveMode, slotID)) or newScore
            end
        end
    end

    if equipLoc == "INVTYPE_FINGER" then
        -- Compare against the weaker ring (or empty slot) first so ties replace the weaker slot
        local obj1 = setupObjs[INVSLOT_FINGER1]
        local obj2 = setupObjs[INVSLOT_FINGER2]
        local sc1 = (obj1 and obj1.link) and ((GSI_ItemScore and GSI_ItemScore:Calculate(obj1.link, specIndex, nil, effectiveMode, INVSLOT_FINGER1)) or 0) or -1
        local sc2 = (obj2 and obj2.link) and ((GSI_ItemScore and GSI_ItemScore:Calculate(obj2.link, specIndex, nil, effectiveMode, INVSLOT_FINGER2)) or 0) or -1

        if sc1 <= sc2 then
            TestReplacement(INVSLOT_FINGER1)
            TestReplacement(INVSLOT_FINGER2)
        else
            TestReplacement(INVSLOT_FINGER2)
            TestReplacement(INVSLOT_FINGER1)
        end
    elseif equipLoc == "INVTYPE_WEAPON" then
        TestReplacement(INVSLOT_MAINHAND)
        local playerClass = (GSI_ClassicData and GSI_ClassicData.GetPlayerClass and GSI_ClassicData:GetPlayerClass()) or (UnitClass and select(2, UnitClass("player")))
        local isShieldTank = (playerClass == "WARRIOR" and specIndex == 3) or (playerClass == "PALADIN" and specIndex == 2)
        local canDW = GSI_ClassicData and GSI_ClassicData.CanDualWield and GSI_ClassicData:CanDualWield()
        if canDW and not isShieldTank then
            local mhObj = setupObjs[INVSLOT_MAINHAND]
            local mhLoc = mhObj and mhObj.link and GetItemEquipLoc(mhObj.link)
            if mhLoc ~= "INVTYPE_2HWEAPON" then
                local role = (GSI_StatWeights and GSI_StatWeights.GetRole and GSI_StatWeights:GetRole(specIndex, effectiveMode)) or "dps"
                local ohObj = setupObjs[INVSLOT_OFFHAND]
                local ohLoc = ohObj and ohObj.link and GetItemEquipLoc(ohObj.link)
                local protectShield = (role == "tank" and effectiveMode == "Survival" and ohLoc == "INVTYPE_SHIELD")
                if not protectShield then
                    TestReplacement(INVSLOT_OFFHAND)
                end
            end
        end
    elseif equipLoc == "INVTYPE_WEAPONOFFHAND" then
        local playerClass = (GSI_ClassicData and GSI_ClassicData.GetPlayerClass and GSI_ClassicData:GetPlayerClass()) or (UnitClass and select(2, UnitClass("player")))
        local isShieldTank = (playerClass == "WARRIOR" and specIndex == 3) or (playerClass == "PALADIN" and specIndex == 2)
        local canDW = GSI_ClassicData and GSI_ClassicData.CanDualWield and GSI_ClassicData:CanDualWield()
        if canDW and not isShieldTank then
            TestReplacement(INVSLOT_OFFHAND)
        else
            return nil, nil, nil, nil, nil
        end
    elseif equipLoc == "INVTYPE_2HWEAPON" then
        local playerClass = (GSI_ClassicData and GSI_ClassicData.GetPlayerClass and GSI_ClassicData:GetPlayerClass()) or (UnitClass and select(2, UnitClass("player")))
        local isShieldTank = (playerClass == "WARRIOR" and specIndex == 3) or (playerClass == "PALADIN" and specIndex == 2)
        if isShieldTank then
            return nil, nil, nil, nil, nil
        end
        TestReplacement(INVSLOT_MAINHAND)
    else
        TestReplacement(defaultSlot)
    end

    if not bestSlotID then
        return nil, 0, newScore, 0, false, nil, isLevelTooHigh, minLevel
    end

    local finalDelta = math.floor(bestDelta * 100 + 0.5) / 100
    return bestEquippedLink, bestEquippedScore, bestNewScore, finalDelta, (finalDelta > 0), bestSlotID, isLevelTooHigh, minLevel
end
