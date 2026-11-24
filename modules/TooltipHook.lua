-- ============================================================
-- GearSetImprover - TooltipHook.lua (WoW Forever)
-- Appends GSI Scores, comparison deltas, talent hints, overrides,
-- and set progression lines to item tooltips.
-- ============================================================

GSI_TooltipHook = {
    _revision = 1,
    _initialized = false,
    _hooksInstalled = false,
}

local GetItemInfo = (C_Item and C_Item.GetItemInfo) or _G.GetItemInfo or function() return nil end
local GetItemInfoInstant = (C_Item and C_Item.GetItemInfoInstant) or _G.GetItemInfoInstant or function() return nil end

local COLOR_BETTER  = "|cff44ff44"
local COLOR_WORSE   = "|cffff4444"
local COLOR_LABEL   = "|cffffcc00"
local COLOR_VALUE   = "|cffffffff"
local COLOR_SUB     = "|cffaaaaaa"
local COLOR_END     = "|r"

local GSI_IsProcessing = false
local SKIP_TOOLTIPS = {
    GSI_ScanTooltip = true,
    GSI_SetScanTooltip = true,
    GSI_OptScanTooltip = true,
}

-- Static key tables for zero-allocation cacheKey construction
local KNOWN_PROFILE_KEYS = {
    "1:ST", "1:AOE", "1:Survival", "1:Threat",
    "2:ST", "2:AOE", "2:Survival", "2:Threat",
    "3:ST", "3:AOE", "3:Survival", "3:Threat",
    "4:ST", "4:AOE", "4:Survival", "4:Threat",
}

local SPELL_SCHOOL_KEYS = {
    "ArcaneSpellPower",
    "FireSpellPower",
    "FrostSpellPower",
    "ShadowSpellPower",
    "NatureSpellPower",
    "HolySpellPower",
}

local CLASS_SPEC_KEYS = {
    WARRIOR = { "WARRIOR-1", "WARRIOR-2", "WARRIOR-3", "WARRIOR-4" },
    PALADIN = { "PALADIN-1", "PALADIN-2", "PALADIN-3", "PALADIN-4" },
    HUNTER  = { "HUNTER-1",  "HUNTER-2",  "HUNTER-3",  "HUNTER-4"  },
    ROGUE   = { "ROGUE-1",   "ROGUE-2",   "ROGUE-3",   "ROGUE-4"   },
    PRIEST  = { "PRIEST-1",  "PRIEST-2",  "PRIEST-3",  "PRIEST-4"  },
    SHAMAN  = { "SHAMAN-1",  "SHAMAN-2",  "SHAMAN-3",  "SHAMAN-4"  },
    MAGE    = { "MAGE-1",    "MAGE-2",    "MAGE-3",    "MAGE-4"    },
    WARLOCK = { "WARLOCK-1", "WARLOCK-2", "WARLOCK-3", "WARLOCK-4" },
    DRUID   = { "DRUID-1",   "DRUID-2",   "DRUID-3",   "DRUID-4"   },
}

local function GetResolvedPlayerClass()
    if GSI_ClassicData and GSI_ClassicData.GetPlayerClass then
        return GSI_ClassicData:GetPlayerClass()
    end
    return select(2, UnitClass("player")) or "WARRIOR"
end

local function BuildCacheKey(isShoppingTip, itemLink, playerClass, activeSpecIndex, specKey, db)
    local activeWeightMode = (db and db.weightMode) or (GSI_Config and GSI_Config.WeightMode) or "ST"
    local activeTankMode = (db and db.tankMode) or (GSI_Config and GSI_Config.TankMode) or "Survival"

    local ignoreEnchants = db and db.ignoreEnchants
    if ignoreEnchants == nil then
        ignoreEnchants = (not GSI_Config) or (GSI_Config.IgnoreEnchants ~= false)
    end
    local debugFlag = (db and db.debug == true)
    local canDW = (GSI_ClassicData and GSI_ClassicData.CanDualWield and GSI_ClassicData:CanDualWield()) == true

    local flags = (isShoppingTip and 1 or 0)
        + (ignoreEnchants and 2 or 0)
        + (debugFlag and 4 or 0)
        + (canDW and 8 or 0)

    local incSit = db and db.includeSituational
    local sitTag
    if incSit == true then
        sitTag = "T"
    elseif incSit == false then
        sitTag = "F"
    else
        sitTag = "N:" .. tostring((db and db.contentMode) or "DUNGEON")
    end

    local reqResists = db and db.requiredResists
    local resMask = 0
    if reqResists then
        if reqResists.Fire   then resMask = resMask + 1 end
        if reqResists.Nature then resMask = resMask + 2 end
        if reqResists.Frost  then resMask = resMask + 4 end
        if reqResists.Shadow then resMask = resMask + 8 end
        if reqResists.Arcane then resMask = resMask + 16 end
    end
    local resWeight = (db and db.resistPriorityWeight) or 5

    -- Trit-encoded spell school flags for current spec (0=nil, 1=true, 2=false)
    local schMask = 0
    local esDB = db and db.enabledSpellSchools
    local enabledSchools = esDB and (
        esDB[specKey .. ":" .. activeWeightMode]
        or esDB[specKey .. ":" .. activeTankMode]
        or esDB[specKey]
    )
    if enabledSchools then
        local mult = 1
        for i = 1, 6 do
            local v = enabledSchools[SPELL_SCHOOL_KEYS[i]]
            local digit = (v == true and 1) or (v == false and 2) or 0
            schMask = schMask + (digit * mult)
            mult = mult * 3
        end
    end

    -- Bitmask for configured tooltipProfiles / legacy tooltipSpecs
    local tpMask = 0
    local cfgProfiles = db and db.tooltipProfiles and db.tooltipProfiles[playerClass]
    local cfgSpecs = db and db.tooltipSpecs and db.tooltipSpecs[playerClass]
    if cfgProfiles and type(cfgProfiles) == "table" then
        local bitVal = 1
        for i = 1, 16 do
            if cfgProfiles[KNOWN_PROFILE_KEYS[i]] then
                tpMask = tpMask + bitVal
            end
            bitVal = bitVal * 2
        end
    elseif cfgSpecs and type(cfgSpecs) == "table" then
        local bitVal = 1
        for i = 1, 4 do
            if cfgSpecs[i] then
                tpMask = tpMask + bitVal
            end
            bitVal = bitVal * 2
        end
        tpMask = -tpMask - 1
    end

    -- Active profile names across all specs of player's class (covers mode-scoped & multi-profile tooltips)
    local profSig = "-"
    local ap = db and db.activeProfile
    if ap then
        local function ResolveProfileSig(sk)
            local v = ap[sk .. ":" .. activeWeightMode]
            if v == nil then v = ap[sk .. ":" .. activeTankMode] end
            if v == nil then v = ap[sk] end
            if v == false then return "0" end
            return (type(v) == "string" and v) or ""
        end
        local specKeys = CLASS_SPEC_KEYS[playerClass]
        if specKeys then
            local p1 = ResolveProfileSig(specKeys[1])
            local p2 = ResolveProfileSig(specKeys[2])
            local p3 = ResolveProfileSig(specKeys[3])
            local p4 = ResolveProfileSig(specKeys[4])
            if p1 ~= "" or p2 ~= "" or p3 ~= "" or p4 ~= "" then
                profSig = p1 .. "/" .. p2 .. "/" .. p3 .. "/" .. p4
            end
        else
            local pSingle = ResolveProfileSig(specKey)
            if pSingle ~= "" then
                profSig = pSingle
            end
        end
    end

    local cacheRev = (GSI_TooltipCache and (GSI_TooltipCache.GetRevision and GSI_TooltipCache:GetRevision() or GSI_TooltipCache.revision)) or 0
    local hookRev = GSI_TooltipHook._revision or 1
    local playerLevel = (UnitLevel and UnitLevel("player")) or 60
    -- Other specs' lines compare with the set tied to them (option + set names)
    local setSig = (GSI_UI and GSI_UI.GetSpecSetSignature and GSI_UI:GetSpecSetSignature()) or ""

    return string.format(
        "%d|%s|%s|%s|%s|%s|%d|%s|%d|%d|%d|%d|%d|%s|%s",
        flags,
        setSig,
        tostring(specKey),
        tostring(activeWeightMode),
        tostring(activeTankMode),
        tostring(profSig),
        sitTag,
        resMask,
        tostring(resWeight),
        schMask,
        tpMask,
        playerLevel,
        cacheRev,
        hookRev,
        tostring(itemLink)
    )
end

-- Checks talent rank using both English and German patterns so hints work on EN & DE clients
local function HasTalentRank(enPattern, dePattern)
    if not GSI_TalentIntegration or not GSI_TalentIntegration.GetTalentRankByPattern then
        return false
    end
    local r = GSI_TalentIntegration:GetTalentRankByPattern(enPattern)
    if (not r or r == 0) and dePattern then
        local rDE = GSI_TalentIntegration:GetTalentRankByPattern(dePattern)
        if rDE and rDE > (r or 0) then
            r = rDE
        end
    end
    return r and r > 0
end

-- The lines GSI wrote, font string -> its text: the duplicate guard finds
-- them without a tag in the text.
local ownLines = setmetatable({}, { __mode = "k" })
-- Font strings drawn bold, tooltip -> { [fontString] = original font }
local boldLines = setmetatable({}, { __mode = "k" })
local clearHooked = setmetatable({}, { __mode = "k" })

local function RestoreFonts(tip)
    local list = boldLines[tip]
    if not list then return end
    boldLines[tip] = nil
    for fs, orig in pairs(list) do
        if orig.object then
            fs:SetFontObject(orig.object)
        else
            fs:SetFont(orig.font, orig.size, orig.flags or "")
        end
    end
end

-- Adds a line to the tooltip. bold: the line's own font with an outline,
-- put back when the tooltip is cleared (OnTooltipCleared).
local function AddOwnLine(tip, text, r, g, b, wrap, bold)
    if r then
        tip:AddLine(text, r, g, b, wrap)
    else
        tip:AddLine(text)
    end
    local name = tip.GetName and tip:GetName()
    local fs = name and tip.NumLines and _G[name .. "TextLeft" .. tip:NumLines()]
    if not fs then return end
    ownLines[fs] = fs:GetText()
    if not bold then return end
    if not clearHooked[tip] then
        if not (tip.HasScript and tip:HasScript("OnTooltipCleared")) then return end
        tip:HookScript("OnTooltipCleared", RestoreFonts)
        clearHooked[tip] = true
    end
    local font, size, flags = fs:GetFont()
    if not font then return end
    local list = boldLines[tip] or {}
    boldLines[tip] = list
    if not list[fs] then
        list[fs] = { object = fs:GetFontObject(), font = font, size = size, flags = flags }
    end
    fs:SetFont(font, size, "OUTLINE")
end

local function AppendScoreToTooltip(tooltip, itemLink)
    local cachedLines = nil
    local shouldCache = true

    local okTotal = pcall(function()
        if not tooltip or not itemLink then return end
        if GSI_IsProcessing then return end

        local tipName = (tooltip.GetName and tooltip:GetName()) or ""
        if SKIP_TOOLTIPS[tipName] then return end

        local db = GearSetImproverDB
        if not db or db.enabled == false then return end

        -- Duplicate guard: prevent appending duplicate score lines on repeated tooltip updates
        local numLines = (tooltip.NumLines and tooltip:NumLines()) or 0
        if numLines > 0 and tipName ~= "" then
            for i = numLines, math.max(1, numLines - 15), -1 do
                local lineObj = _G[tipName .. "TextLeft" .. i]
                local text = lineObj and lineObj.GetText and lineObj:GetText()
                if text and (ownLines[lineObj] == text or text:find("[GSI Override:", 1, true)) then
                    return
                end
            end
        end

        local isShoppingTip = (tipName:find("ShoppingTooltip", 1, true) ~= nil)
            or (tipName:find("Comparison", 1, true) ~= nil)
            or (tooltip.isShopping == true)

        local playerClass = GetResolvedPlayerClass()
        local activeSpecIndex = (GSI_StatWeights and GSI_StatWeights.GetActiveSpecIndex and GSI_StatWeights:GetActiveSpecIndex()) or 1
        local specKey = (GSI_StatWeights and GSI_StatWeights.GetSpecKey and GSI_StatWeights:GetSpecKey())
            or (playerClass .. "-" .. tostring(activeSpecIndex))

        if GSI_SetBonus and GSI_SetBonus.EnsureEquippedSetsUpdated then
            GSI_SetBonus:EnsureEquippedSetsUpdated()
        end

        local cacheKey = BuildCacheKey(isShoppingTip, itemLink, playerClass, activeSpecIndex, specKey, db)

        -- LRU Cache Lookup (Zero-Allocation Fast Path)
        if GSI_TooltipCache and GSI_TooltipCache.Get then
            local hitLines = GSI_TooltipCache:Get(cacheKey)
            if hitLines then
                if #hitLines == 0 then
                    return -- Known non-equippable or ignored item
                end
                for i = 1, #hitLines do
                    local l = hitLines[i]
                    AddOwnLine(tooltip, l.text, l.r, l.g, l.b, l.wrap, l.bold)
                end
                tooltip:Show()
                return
            end
        end

        -- Verify item is equippable
        local isEquip = (C_Item and C_Item.IsEquippableItem and C_Item.IsEquippableItem(itemLink))
        if isEquip == nil then
            isEquip = (_G.IsEquippableItem and _G.IsEquippableItem(itemLink))
        end
        if isEquip == false then
            if GSI_TooltipCache and GSI_TooltipCache.Set then
                local emptyLines = GSI_TooltipCache:AcquireLinesContainer()
                GSI_TooltipCache:Set(cacheKey, emptyLines)
            end
            return
        end

        local equipLoc = select(9, GetItemInfo(itemLink))
        if not equipLoc or equipLoc == "" or type(equipLoc) ~= "string" then
            equipLoc = select(4, (C_Item and C_Item.GetItemInfoInstant or GetItemInfoInstant)(itemLink))
        end
        if not equipLoc or type(equipLoc) ~= "string" or equipLoc == "" or equipLoc == "INVTYPE_NON_EQUIP" then
            if GSI_TooltipCache and GSI_TooltipCache.Set then
                local emptyLines = GSI_TooltipCache:AcquireLinesContainer()
                GSI_TooltipCache:Set(cacheKey, emptyLines)
            end
            return
        end

        -- Must map to a valid GSI equipment slot
        if not GSI_ClassicData or not GSI_ClassicData.EquipLocToSlot or not GSI_ClassicData.EquipLocToSlot[equipLoc] then
            if GSI_TooltipCache and GSI_TooltipCache.Set then
                local emptyLines = GSI_TooltipCache:AcquireLinesContainer()
                GSI_TooltipCache:Set(cacheKey, emptyLines)
            end
            return
        end

        -- Trinkets are excluded from scoring
        if equipLoc == "INVTYPE_TRINKET" then
            if GSI_TooltipCache and GSI_TooltipCache.Set then
                local emptyLines = GSI_TooltipCache:AcquireLinesContainer()
                GSI_TooltipCache:Set(cacheKey, emptyLines)
            end
            return
        end

        local activeTankMode = db.tankMode or (GSI_Config and GSI_Config.TankMode) or "Survival"
        local activeWeightMode = db.weightMode or (GSI_Config and GSI_Config.WeightMode) or "ST"
        local classData = GSI_ClassicData.Classes and GSI_ClassicData.Classes[playerClass]

        -- Build available profiles for class
        local availableProfiles = {}
        if GSI_UI and GSI_UI.GetClassProfiles then
            availableProfiles = GSI_UI:GetClassProfiles(playerClass) or {}
        end

        -- Determine which profiles to display in tooltip
        local profilesToShow = {}
        local cfgProfiles = db.tooltipProfiles and db.tooltipProfiles[playerClass]
        local cfgSpecs = db.tooltipSpecs and db.tooltipSpecs[playerClass]

        if cfgProfiles and type(cfgProfiles) == "table" then
            for _, pInfo in ipairs(availableProfiles) do
                if cfgProfiles[pInfo.key] then
                    profilesToShow[#profilesToShow + 1] = pInfo
                end
            end
        elseif cfgSpecs and type(cfgSpecs) == "table" then
            -- Fallback migration from legacy tooltipSpecs
            for _, pInfo in ipairs(availableProfiles) do
                if cfgSpecs[pInfo.specIndex] then
                    if pInfo.mode == "ST" or pInfo.mode == "Survival" then
                        profilesToShow[#profilesToShow + 1] = pInfo
                    end
                end
            end
        end

        -- Fallback: show active spec + active mode
        if #profilesToShow == 0 then
            for _, pInfo in ipairs(availableProfiles) do
                if pInfo.specIndex == activeSpecIndex then
                    local isMatch = false
                    if pInfo.mode == "Survival" or pInfo.mode == "Threat" or pInfo.mode == "DMG" then
                        isMatch = (pInfo.mode == activeTankMode) or (activeTankMode == "DMG" and pInfo.mode == "Threat")
                    else
                        isMatch = (pInfo.mode == activeWeightMode)
                    end
                    if isMatch then
                        profilesToShow[#profilesToShow + 1] = pInfo
                        break
                    end
                end
            end
            if #profilesToShow == 0 then
                for _, pInfo in ipairs(availableProfiles) do
                    if pInfo.specIndex == activeSpecIndex and (pInfo.mode == "ST" or pInfo.mode == "Survival") then
                        profilesToShow[#profilesToShow + 1] = pInfo
                        break
                    end
                end
            end
            if #profilesToShow == 0 and #availableProfiles > 0 then
                profilesToShow[1] = availableProfiles[1]
            end
        end

        if GSI_TooltipCache and GSI_TooltipCache.AcquireLinesContainer then
            cachedLines = GSI_TooltipCache:AcquireLinesContainer()
        end

        local function AddTipLine(text, r, g, b, wrap, bold)
            AddOwnLine(tooltip, text, r, g, b, wrap, bold)
            if cachedLines and GSI_TooltipCache and GSI_TooltipCache.AcquireLine then
                local l = GSI_TooltipCache:AcquireLine(text, r, g, b, wrap)
                l.bold = bold and true or nil
                cachedLines[#cachedLines + 1] = l
            end
        end

        -- Equipment Sets in tooltips (Settings, on by default): every spec of
        -- the class gets one line per set it has (the sets GSI saved for it,
        -- or those chosen in Settings), "vs <set>", each in the mode the set
        -- was saved for (own sets: the spec's ticked modes, else its current
        -- one). A spec you are not playing compares only with its sets; the
        -- active spec keeps its lines against the gear worn and adds its other
        -- sets, so both give the same lines. A line two sources would give
        -- shows once.
        local linesToShow = profilesToShow
        if GSI_UI and GSI_UI.IsCompareSpecSets and GSI_UI:IsCompareSpecSets()
            and GSI_UI.GetCompareSetsForProfile and GSI_UI.GetCurrentModeFor and GSI_CompareEngine.GetSetSetup then
            local function ModeLabel(specIdx, mode)
                for _, p in ipairs(availableProfiles) do
                    if p.specIndex == specIdx and p.mode == mode then return p.modeLabel end
                end
                return nil
            end
            local numSpecs = (playerClass == "DRUID") and 4 or 3
            local tickedModes, tickedLines, specOrder, inOrder = {}, {}, {}, {}
            for _, pInfo in ipairs(profilesToShow) do
                local s = pInfo.specIndex
                tickedModes[s] = tickedModes[s] or {}
                tickedModes[s][#tickedModes[s] + 1] = pInfo.mode
                tickedLines[s] = tickedLines[s] or {}
                tickedLines[s][#tickedLines[s] + 1] = pInfo
                if not inOrder[s] then inOrder[s] = true; specOrder[#specOrder + 1] = s end
            end
            for s = 1, numSpecs do
                if not inOrder[s] then inOrder[s] = true; specOrder[#specOrder + 1] = s end
            end

            -- A set of the active spec that is fully on is the gear worn: its line
            -- is left out only when the spec already has a line against the worn
            -- gear in the set's mode (Resto Single ticked, "GSI: Resto AoE" on:
            -- the AoE line stays, as it does while another spec is played).
            local function HasWornLine(s, mode)
                for _, m in ipairs(tickedModes[s] or {}) do
                    if m == mode then return true end
                end
                return false
            end

            local seenLine = {}
            local setLines = {}
            for s = 1, numSpecs do
                for _, lineMode in ipairs(tickedModes[s] or { GSI_UI:GetCurrentModeFor(s) }) do
                    for _, set in ipairs(GSI_UI:GetCompareSetsForProfile(s, lineMode)) do
                        local key = tostring(s) .. "|" .. tostring(set.mode) .. "|" .. set.name
                        if not seenLine[key]
                            and not (s == activeSpecIndex and set.equipped and HasWornLine(s, set.mode)) then
                            seenLine[key] = true
                            setLines[s] = setLines[s] or {}
                            setLines[s][#setLines[s] + 1] = {
                                specIndex = s,
                                mode = set.mode,
                                modeLabel = ModeLabel(s, set.mode) or set.mode,
                                setName = set.name,
                            }
                        end
                    end
                end
            end

            -- Spec by spec: its lines against the gear worn (the active spec,
            -- or a ticked spec without sets), then its set lines
            linesToShow = {}
            for _, s in ipairs(specOrder) do
                if s == activeSpecIndex or not setLines[s] then
                    for _, pInfo in ipairs(tickedLines[s] or {}) do
                        linesToShow[#linesToShow + 1] = pInfo
                    end
                end
                for _, l in ipairs(setLines[s] or {}) do
                    linesToShow[#linesToShow + 1] = l
                end
            end
        end

        local addedAnyScore = false
        local itemLoading = false
        local canDW = (GSI_ClassicData.CanDualWield and GSI_ClassicData:CanDualWield()) == true
        local itemStats = nil
        local statsFetched = false
        local shownHints = nil

        local function AddHintOnce(hintKey, text)
            if not shownHints then shownHints = {} end
            if shownHints[hintKey] then return end
            shownHints[hintKey] = true
            AddTipLine(text, 1, 0.67, 0, true)
        end

        for _, pInfo in ipairs(linesToShow) do
            local specIdx = pInfo.specIndex
            local modeVal = pInfo.mode
            local vsSetName = pInfo.setName

            GSI_IsProcessing = true
            local ok, _, _, newScore, delta, isBetter, targetSlotID, isLevelTooHigh, minLevel = pcall(function()
                local setSetup, setBase = nil, nil
                if vsSetName then
                    setSetup, setBase = GSI_CompareEngine:GetSetSetup(vsSetName, specIdx, modeVal)
                    if not setSetup then vsSetName = nil end
                end
                return GSI_CompareEngine:Compare(itemLink, setSetup, setBase, specIdx, modeVal)
            end)
            GSI_IsProcessing = false

            if not ok then
                shouldCache = false
            elseif newScore ~= nil then
                addedAnyScore = true

                local color = COLOR_VALUE
                if not isShoppingTip then
                    if delta > 0 then
                        color = COLOR_BETTER
                    elseif delta < 0 then
                        color = COLOR_WORSE
                    end
                end

                local deltaPart = ""
                if not isShoppingTip then
                    local sign = (delta >= 0) and "+" or ""
                    local absDelta = math.abs(delta)
                    local deltaFormatted = (absDelta < 10 and absDelta > 0)
                        and string.format("%.2f", delta)
                        or string.format("%.1f", delta)
                    local slotSuffix = ""
                    if equipLoc == "INVTYPE_WEAPON" and targetSlotID == 17 then
                        slotSuffix = " vs OH"
                    elseif equipLoc == "INVTYPE_WEAPON" and targetSlotID == 16 and canDW then
                        slotSuffix = " vs MH"
                    elseif equipLoc == "INVTYPE_FINGER" and targetSlotID then
                        local sNum = (targetSlotID == 12) and "2" or "1"
                        slotSuffix = " vs Finger " .. sNum
                    end
                    deltaPart = string.format(" %s(%s%s%s)%s", color, sign, deltaFormatted, slotSuffix, COLOR_END)
                end

                local levelNotice = ""
                if isLevelTooHigh and minLevel then
                    levelNotice = string.format(" %s[Req. Lvl %d]%s", COLOR_WORSE, minLevel, COLOR_END)
                end

                local scoreFormatted = (newScore < 100)
                    and string.format("%.2f", newScore)
                    or string.format("%.1f", newScore)

                -- "Restoration AoE vs Resto AoE: 11.19 (+4.05)": spec and mode, the
                -- set without GSI's "GSI: " prefix; the spec you play is bold
                local sData = classData and classData.specs and classData.specs[specIdx]
                local sName = (sData and sData.name) or ("Spec " .. specIdx)
                local rawMode = pInfo.modeLabel or modeVal
                local modeName = (rawMode == "AoE / Raid") and "AoE" or rawMode
                if vsSetName then
                    local shownSet = (vsSetName:gsub("^GSI: ", ""))
                    modeName = modeName .. " |cff999999vs " .. shownSet .. "|r"
                end
                AddTipLine(string.format(
                    "%s%s %s%s: %s%s%s%s%s",
                    COLOR_LABEL, sName, modeName, COLOR_LABEL,
                    COLOR_VALUE, scoreFormatted, deltaPart, levelNotice, COLOR_END
                ), nil, nil, nil, nil, specIdx == activeSpecIndex)

                -- Talent dependency hints (EN + DE talent pattern detection, strictly English hints)
                if not statsFetched then
                    statsFetched = true
                    itemStats = GSI_ItemScore and GSI_ItemScore.GetParsedStats and GSI_ItemScore:GetParsedStats(itemLink)
                end

                if itemStats then
                    local hasInt = itemStats.Intellect and itemStats.Intellect > 0
                    local hasSpi = itemStats.Spirit and itemStats.Spirit > 0
                    local hasMana = itemStats.Mana and itemStats.Mana > 0

                    if playerClass == "SHAMAN" and specIdx == 2 and hasInt then
                        if not HasTalentRank("mental dexterity", "geistige gewandtheit") then
                            AddHintOnce("SHAMAN_MD", "  |cffffaa00Note: INT assumes 'Mental Dexterity' talent|r")
                        end
                    elseif playerClass == "HUNTER" and (specIdx == 2 or specIdx == 3) and hasInt then
                        if not HasTalentRank("careful aim", "sorgfältiges zielen") then
                            AddHintOnce("HUNTER_CA", "  |cffffaa00Note: INT assumes 'Careful Aim' talent|r")
                        end
                    elseif playerClass == "PALADIN" and specIdx == 1 and hasSpi then
                        if not HasTalentRank("reverence", "ehrfurcht") then
                            AddHintOnce("PALADIN_REV", "  |cffffaa00Note: SPI assumes 'Reverence' talent|r")
                        end
                    elseif playerClass == "PALADIN" and specIdx == 3 and hasInt then
                        if not HasTalentRank("champion of the light", "champion des lichts") then
                            AddHintOnce("PALADIN_COTL", "  |cffffaa00Note: INT assumes 'Champion of the Light' talent|r")
                        end
                    elseif playerClass == "MAGE" and specIdx == 1 and (hasInt or hasMana) then
                        local hasAB = HasTalentRank("arcane blast", "arkanschlag")
                        local hasAW = HasTalentRank("arcane wrath", "arkaner zorn")
                        if hasInt then
                            if not hasAB and not hasAW then
                                AddHintOnce("MAGE_ARC_BOTH", "  |cffffaa00Note: INT assumes 'Arcane Blast' & 'Arcane Wrath'|r")
                            elseif not hasAB then
                                AddHintOnce("MAGE_AB", "  |cffffaa00Note: INT assumes 'Arcane Blast' talent|r")
                            elseif not hasAW then
                                AddHintOnce("MAGE_AW_INT", "  |cffffaa00Note: INT assumes 'Arcane Wrath' talent|r")
                            end
                        elseif hasMana and not hasAW then
                            AddHintOnce("MAGE_AW_MANA", "  |cffffaa00Note: Mana assumes 'Arcane Wrath' talent|r")
                        end
                    elseif playerClass == "DRUID" and specIdx == 4 and hasInt then
                        if not HasTalentRank("natural instinct", "natürlicher instinkt") then
                            AddHintOnce("DRUID_NI", "  |cffffaa00Note: INT assumes 'Natural Instinct' talent|r")
                        end
                    end
                end
            elseif isBetter == nil then
                -- Item info is still loading asynchronously from server; do not cache incomplete result
                itemLoading = true
                shouldCache = false
            end
        end

        if addedAnyScore then
            -- Overrides & Situational Effects
            if GSI_Overrides and GSI_Overrides.GetOverride then
                local overrideScore, reason, _, isSituational, context = GSI_Overrides:GetOverride(itemLink, playerClass, db.contentMode, false, activeSpecIndex)
                if reason then
                    if isSituational then
                        local active = GSI_Overrides:IsSituationalActive(context)
                        if active and overrideScore and overrideScore > 0 then
                            AddTipLine(string.format(
                                "|cffffaa00[Situational: +%.1f]|r |cffaaaaaa(%s: %s)|r",
                                overrideScore, context or "Context", reason
                            ), 1, 1, 1, true)
                        else
                            AddTipLine(string.format(
                                "|cffffaa00[Situational]|r |cffaaaaaa(%s: %s)|r",
                                context or "Context", reason
                            ), 1, 1, 1, true)
                        end
                    elseif overrideScore and overrideScore > 0 then
                        AddTipLine(string.format(
                            "|cff00ffff[GSI Override: +%.1f]|r |cffaaaaaa(%s)|r",
                            overrideScore, reason
                        ), 1, 1, 1, true)
                    end
                end
            end

            -- Set Bonus Threshold Progression & Piece Limits
            if GSI_SetBonus and GSI_SetBonus.GetThresholdProgression then
                local prog = GSI_SetBonus:GetThresholdProgression(itemLink)
                if prog and prog.setName then
                    if prog.maxEquipped and prog.count >= prog.maxEquipped then
                        AddTipLine(string.format(
                            "|cffff8800Set: %s (%d/%d Limit Reached)|r",
                            prog.setName, prog.count, prog.maxEquipped
                        ), 1, 1, 1, true)
                    elseif prog.nextThreshold then
                        local gainText = (prog.nextScoreDelta and prog.nextScoreDelta > 0)
                            and string.format(" (+%.1f GSI)", prog.nextScoreDelta)
                            or ""
                        AddTipLine(string.format(
                            "|cff00ff00Set: %s|r |cffaaaaaa(%d pcs, next at %d)%s|r",
                            prog.setName, prog.count, prog.nextThreshold, gainText
                        ), 1, 1, 1, true)
                    end
                end
            end

            -- Debug stat weights line
            if db.debug and GSI_StatWeights and GSI_StatWeights.GetWeights then
                local w = GSI_StatWeights:GetWeights()
                if w then
                    local dbg
                    if (w.SpellPower or 0) >= (w.AttackPower or 0) and (w.SpellPower or 0) > (w.Defense or 0) then
                        dbg = string.format(
                            "%sW: Int:%.2f Spi:%.2f SP:%.2f Crit:%.2f Hit:%.2f%s",
                            COLOR_SUB, w.Intellect or 0, w.Spirit or 0, w.SpellPower or 0, w.Crit or 0, w.Hit or 0, COLOR_END
                        )
                    else
                        dbg = string.format(
                            "%sW: Sta:%.2f Agi:%.2f Def:%.2f Arm:%.3f Str:%.2f%s",
                            COLOR_SUB, w.Stamina or 0, w.Agility or 0, w.Defense or 0, w.Armor or 0, w.Strength or 0, COLOR_END
                        )
                    end
                    AddTipLine(dbg, 0.67, 0.67, 0.67, true)
                end
            end
        end

        if cachedLines and GSI_TooltipCache then
            if shouldCache and not itemLoading and GSI_TooltipCache.Set then
                GSI_TooltipCache:Set(cacheKey, cachedLines)
                cachedLines = nil
            elseif GSI_TooltipCache.ReleaseLinesContainer then
                GSI_TooltipCache:ReleaseLinesContainer(cachedLines)
                cachedLines = nil
            end
        end

        if addedAnyScore then
            tooltip:Show()
        end
    end)

    if not okTotal then
        GSI_IsProcessing = false
        if cachedLines and GSI_TooltipCache and GSI_TooltipCache.ReleaseLinesContainer then
            GSI_TooltipCache:ReleaseLinesContainer(cachedLines)
        end
    end
end

function GSI_TooltipHook:ResetCache()
    self._revision = (self._revision or 1) + 1
    if GSI_TooltipCache then
        if GSI_TooltipCache.ResetCache then
            GSI_TooltipCache:ResetCache()
        elseif GSI_TooltipCache.Invalidate then
            GSI_TooltipCache:Invalidate()
        end
    end
end

-- An item tooltip that is already open keeps the score lines it was built
-- with. After a spec or talent change rebuild the open ones from fresh scores:
-- RefreshData (retail tooltip data) re-runs the item post-call, which appends
-- the new lines; older tooltips get the same link set again.
local OPEN_TIP_NAMES = {
    "GameTooltip", "ShoppingTooltip1", "ShoppingTooltip2",
    "ItemRefTooltip", "ItemRefShoppingTooltip1", "ItemRefShoppingTooltip2",
}
function GSI_TooltipHook:RefreshShownTooltips()
    self:ResetCache()
    for _, name in ipairs(OPEN_TIP_NAMES) do
        local tip = _G[name]
        if tip and tip.IsShown and tip:IsShown() and tip.GetItem then
            local okItem, _, link = pcall(tip.GetItem, tip)
            if okItem and link then
                if tip.RefreshData then
                    pcall(tip.RefreshData, tip)
                elseif tip.SetHyperlink then
                    pcall(tip.SetHyperlink, tip, link)
                end
            end
        end
    end
end

function GSI_TooltipHook.AppendScoreToTooltip(self_or_tip, tip_or_link, link_maybe)
    if link_maybe ~= nil then
        AppendScoreToTooltip(tip_or_link, link_maybe)
    elseif self_or_tip == GSI_TooltipHook then
        AppendScoreToTooltip(tip_or_link, nil)
    else
        AppendScoreToTooltip(self_or_tip, tip_or_link)
    end
end

function GSI_TooltipHook:Initialize()
    if self._initialized then return end
    self._initialized = true

    if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall then
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, function(tooltip, data)
            if not tooltip or not data then return end
            local link = data.hyperlink
            if not link and data.guid then
                link = C_Item and C_Item.GetItemLinkByGUID and C_Item.GetItemLinkByGUID(data.guid)
            end
            if not link and data.id then
                link = select(2, GetItemInfo(data.id)) or ("item:" .. data.id)
            end
            if not link and tooltip.GetItem then
                local _, itemLink = tooltip:GetItem()
                link = itemLink
            end

            if link then
                AppendScoreToTooltip(tooltip, link)
            end
        end)
    end

    local function HookTip(tip)
        if not tip then return end
        -- OnTooltipSetItem no longer exists on the WoW Forever client (retail
        -- tooltip system, items go through TooltipDataProcessor above); hooking
        -- it throws and aborted the rest of Initialize. Hook it only if present.
        if tip.HookScript and tip.HasScript and tip:HasScript("OnTooltipSetItem") then
            tip:HookScript("OnTooltipSetItem", function(selfTip)
                local _, link = selfTip:GetItem()
                if link then AppendScoreToTooltip(selfTip, link) end
            end)
        end
        if tip.SetHyperlink then
            hooksecurefunc(tip, "SetHyperlink", function(selfTip, link)
                if link then AppendScoreToTooltip(selfTip, link) end
            end)
        end
    end

    HookTip(GameTooltip)
    HookTip(ItemRefTooltip)
    HookTip(ShoppingTooltip1)
    HookTip(ShoppingTooltip2)
    HookTip(ItemRefShoppingTooltip1)
    HookTip(ItemRefShoppingTooltip2)

    -- Keep tooltip cache synchronized with equipment, talent, level, and profile changes
    if not self._hooksInstalled then
        self._hooksInstalled = true

        local function OnStateInvalidated()
            GSI_TooltipHook:ResetCache()
        end

        if hooksecurefunc then
            if GSI_StatWeights then
                if GSI_StatWeights.SetActiveProfile then hooksecurefunc(GSI_StatWeights, "SetActiveProfile", OnStateInvalidated) end
                if GSI_StatWeights.SaveProfile then hooksecurefunc(GSI_StatWeights, "SaveProfile", OnStateInvalidated) end
                if GSI_StatWeights.DeleteProfile then hooksecurefunc(GSI_StatWeights, "DeleteProfile", OnStateInvalidated) end
                if GSI_StatWeights.RenameProfile then hooksecurefunc(GSI_StatWeights, "RenameProfile", OnStateInvalidated) end
                if GSI_StatWeights.SetSchoolEnabled then hooksecurefunc(GSI_StatWeights, "SetSchoolEnabled", OnStateInvalidated) end
            end
            if GSI_TalentIntegration and GSI_TalentIntegration.Invalidate then
                hooksecurefunc(GSI_TalentIntegration, "Invalidate", OnStateInvalidated)
            end
            if GSI_SetBonus and GSI_SetBonus.UpdateEquippedSets then
                hooksecurefunc(GSI_SetBonus, "UpdateEquippedSets", OnStateInvalidated)
            end
        end

        if CreateFrame then
            local evtFrame = CreateFrame("Frame", "GSI_TooltipCacheEventFrame")
            local events = {
                "PLAYER_EQUIPMENT_CHANGED",
                "EQUIPMENT_SWAP_FINISHED",
                "EQUIPMENT_SETS_CHANGED", -- a set tied to a spec was saved again
                "PLAYER_TALENT_UPDATE",
                "CHARACTER_POINTS_CHANGED",
                "PLAYER_LEVEL_UP",
                "PLAYER_ENTERING_WORLD",
                "ACTIVE_TALENT_GROUP_CHANGED",
                "LEARNED_SPELL_IN_TAB",
                "SPELLS_CHANGED",
            }
            for _, ev in ipairs(events) do
                pcall(function() evtFrame:RegisterEvent(ev) end)
            end
            evtFrame:SetScript("OnEvent", OnStateInvalidated)
            self._eventFrame = evtFrame
        end
    end
end
