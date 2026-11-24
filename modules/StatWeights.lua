-- ============================================================
-- GearSetImprover - StatWeights.lua (WoW Forever 1.60.1)
-- Computes active stat weights for the current character spec and mode.
-- Integrates Profiles_v2_2, custom SavedVariables, racials, and talents.
-- ============================================================

GSI_StatWeights = {}

local GetItemInfo = (C_Item and C_Item.GetItemInfo) or _G.GetItemInfo or function() return nil end

local function SafeCopyTable(orig)
    if type(_G.CopyTable) == "function" then
        return _G.CopyTable(orig)
    end
    if type(orig) ~= "table" then return orig end
    local copy = {}
    for k, v in pairs(orig) do
        if type(v) == "table" then
            copy[k] = SafeCopyTable(v)
        else
            copy[k] = v
        end
    end
    return copy
end

local function GetPlayerClass()
    if GSI_ClassicData and GSI_ClassicData.GetPlayerClass then
        return GSI_ClassicData:GetPlayerClass()
    end
    local locClass, engClass = UnitClass("player")
    return engClass or locClass or "WARRIOR"
end

local function IsTankSpec(class, specIndex)
    return (class == "WARRIOR" and specIndex == 3)
        or (class == "PALADIN" and specIndex == 2)
        or (class == "DRUID" and specIndex == 2)
end

local function HasScopedPrefix(tbl, baseSpecKey)
    if type(tbl) ~= "table" or not baseSpecKey then
        return false
    end
    local prefix = baseSpecKey .. ":"
    local prefixLen = #prefix
    for k, _ in pairs(tbl) do
        if type(k) == "string" and k:sub(1, prefixLen) == prefix then
            return true
        end
    end
    return false
end

local function ResolveSafeNumber(val)
    if type(val) ~= "number" then
        return nil
    end
    if type(_G.issecretvalue) == "function" and _G.issecretvalue(val) then
        return nil
    end
    if val ~= val then -- NaN guard
        return nil
    end
    return val
end

-- ------------------------------------------------------------
-- Specialization: by default the spec the character actually plays,
-- read from its talents. A manual pick (dropdown, /gsi spec, an equip
-- macro for another spec) switches to manual mode until "Auto" is
-- picked again (GearSetImproverDB.specAuto == false means manual).
--
-- Talents cannot tell a Cat from a Bear: for the Feral tree the druid's
-- feral role (GearSetImproverDB.feralSpec, 2 Bear / 3 Cat, default Cat)
-- decides, and picking Bear or Cat while auto-detected as Feral only
-- changes that role and stays in auto mode.
-- ------------------------------------------------------------

-- WoW Forever has one specialization per class (C_SpecializationInfo always
-- answers 1) and no talent-tab API: the class's three vanilla trees are trait
-- groups of the active config's single trait tree, in tree order by orderIndex,
-- and the points spent in each come from the group currency (the same reading
-- as EllesmereUI's Forever talent window and dual spec block).
-- Returns points ({ [treeIndex] = points }), names, state: "ok", "notready" (no
-- active config yet, e.g. at login) or "nogroups" (a client without these trees).
local function ByOrderIndex(a, b) return (a.orderIndex or 0) < (b.orderIndex or 0) end
local function TraitGroupPoints(configID)
    if not (C_ClassTalents and C_ClassTalents.GetActiveConfigID and C_Traits and C_Traits.GetConfigInfo
            and C_Traits.GetGroupDisplayInfoByTreeID and C_Traits.GetGroupCurrencyInfo) then
        return nil
    end
    configID = configID or C_ClassTalents.GetActiveConfigID()
    local config = configID and C_Traits.GetConfigInfo(configID)
    local treeID = config and config.treeIDs and config.treeIDs[1]
    if not treeID then return nil, nil, "notready" end
    local groups = C_Traits.GetGroupDisplayInfoByTreeID(treeID)
    if type(groups) ~= "table" or #groups == 0 then return nil, nil, "nogroups" end
    table.sort(groups, ByOrderIndex)
    local ids, names = {}, {}
    for i, g in ipairs(groups) do
        ids[i] = g.groupID
        names[i] = g.displayName
    end
    local spent = {}
    for _, g in ipairs(C_Traits.GetGroupCurrencyInfo(configID, ids) or {}) do
        local c = g.currencyInfos and g.currencyInfos[1]
        if c and g.traitNodeGroupID then spent[g.traitNodeGroupID] = c.spent or 0 end
    end
    local points = {}
    for i, id in ipairs(ids) do points[i] = spent[id] or 0 end
    return points, names, "ok"
end
local traitTreesSeen = false
GSI_StatWeights.TraitGroupPoints = function()
    local ok, points, names, state = pcall(TraitGroupPoints)
    if not ok then return nil, nil, "notready" end
    -- Once the trees have been read, an empty answer means they are being
    -- reloaded (e.g. while a talent is learned), not a client without them:
    -- it must not fall through to the specialization API, whose spec 1 would
    -- look like a respec to Balance and swap the gear set.
    if state == "ok" then
        traitTreesSeen = true
    elseif state == "nogroups" and traitTreesSeen then
        state = "notready"
    end
    return points, names, state
end

-- ------------------------------------------------------------
-- Dual spec (WoW Forever): up to two talent groups, each with its own build.
-- The switch is C_SpecializationInfo.SetActiveSpecGroup, a cast the game
-- refuses in combat; a group's build is read from its combat config
-- (GetCombatConfigIDForSpecGroup), as EllesmereUI's Dual Spec block does.
-- ------------------------------------------------------------
function GSI_StatWeights:GetNumTalentGroups()
    local ok, n = pcall(function() return GetNumSpecGroups and GetNumSpecGroups() end)
    return (ok and tonumber(n)) or 1
end

function GSI_StatWeights:GetActiveTalentGroup()
    local SI = C_SpecializationInfo
    local ok, g = pcall(function() return SI and SI.GetActiveSpecGroup and SI.GetActiveSpecGroup() end)
    return (ok and tonumber(g)) or 1
end

-- Points per tree and tree names of a group's build, or nil when unreadable.
function GSI_StatWeights:GetTalentGroupPoints(group)
    local SI = C_SpecializationInfo
    if not (SI and SI.GetCombatConfigIDForSpecGroup) then return nil end
    local ok, configID = pcall(SI.GetCombatConfigIDForSpecGroup, group)
    if not ok or not configID then return nil end
    local okP, points, names, state = pcall(TraitGroupPoints, configID)
    if not okP or state ~= "ok" then return nil end
    return points, names
end

-- The tree with the most points in a group's build (leftmost on a tie),
-- nil when none are spent or the build is unreadable.
function GSI_StatWeights:GetTalentGroupLeadTree(group)
    local points = self:GetTalentGroupPoints(group)
    if not points then return nil end
    local lead, best = nil, 0
    for i, p in ipairs(points) do
        if p > best then lead, best = i, p end
    end
    return lead
end

-- The talent tree a GSI spec plays from (druid: Bear and Cat share Feral).
function GSI_StatWeights:SpecTree(specIndex)
    specIndex = tonumber(specIndex) or 1
    if GetPlayerClass() == "DRUID" then
        if specIndex == 1 then return 1 end
        if specIndex == 4 then return 3 end
        return 2
    end
    return specIndex
end

-- Starts the switch to a talent group. Returns true when the game took it.
function GSI_StatWeights:ActivateTalentGroup(group)
    local SI = C_SpecializationInfo
    if not (SI and SI.SetActiveSpecGroup) then return false end
    if InCombatLockdown and InCombatLockdown() then return false end
    return pcall(SI.SetActiveSpecGroup, group) and true or false
end

local function TalentPointsPerTab()
    if type(GetNumTalentTabs) ~= "function" then
        local points = GSI_StatWeights.TraitGroupPoints()
        if not points then return nil end
        local total = 0
        for _, p in ipairs(points) do total = total + (tonumber(p) or 0) end
        if total == 0 then return nil end
        return points
    end
    local ok, numTabs = pcall(GetNumTalentTabs)
    if not ok or type(numTabs) ~= "number" or numTabs < 1 then return nil end
    local points, total = {}, 0
    for tab = 1, numTabs do
        local sum = 0
        -- Sum the ranks (5th return of GetTalentInfo, as TalentIntegration reads it)
        if type(GetNumTalents) == "function" and type(GetTalentInfo) == "function" then
            local okN, n = pcall(GetNumTalents, tab)
            if okN and type(n) == "number" then
                for i = 1, n do
                    local okT, _, _, _, _, rank = pcall(GetTalentInfo, tab, i)
                    if okT and type(rank) == "number" and rank > 0 then sum = sum + rank end
                end
            end
        end
        -- Fallback: pointsSpent from GetTalentTabInfo. Old clients return it
        -- 3rd (name, icon, points), Wrath-style ones 5th (id, name, desc, icon, points).
        if sum == 0 and type(GetTalentTabInfo) == "function" then
            local r = { pcall(GetTalentTabInfo, tab) }
            if r[1] then
                local v = (type(r[6]) == "number" and r[6]) or (type(r[4]) == "number" and r[4]) or 0
                if v > 0 then sum = v end
            end
        end
        points[tab] = sum
        total = total + sum
    end
    if total == 0 then return nil end
    return points
end

function GSI_StatWeights:IsSpecAuto()
    return not (GearSetImproverDB and GearSetImproverDB.specAuto == false)
end

function GSI_StatWeights:GetFeralSpec()
    local v = GearSetImproverDB and tonumber(GearSetImproverDB.feralSpec)
    if v == 2 or v == 3 then return v end
    return 3
end

-- Which talent tree holds the most points (nil when none are spent).
-- On a tie the previously detected tree wins, so spending points evenly
-- does not flip the spec back and forth.
function GSI_StatWeights:GetPrimaryTalentTab()
    local points = TalentPointsPerTab()
    if not points then return nil end
    local best, bestPts = nil, -1
    for tab, pts in ipairs(points) do
        if pts > bestPts or (pts == bestPts and tab == self._lastPrimaryTab) then
            best, bestPts = tab, pts
        end
    end
    self._lastPrimaryTab = best
    return best
end

-- A druid specialization index -> GSI druid spec (1 Balance, 2 Bear, 3 Cat,
-- 4 Restoration). The order differs between clients (retail: Balance, Feral,
-- Guardian, Restoration; a classic-style client may have just three), so the
-- spec's role and primary stat decide, with the position as the fallback.
function GSI_StatWeights:MapDruidSpecialization(specIdx)
    local getInfo = (C_SpecializationInfo and C_SpecializationInfo.GetSpecializationInfo) or _G.GetSpecializationInfo
    local role, primaryStat
    if type(getInfo) == "function" then
        local ok, _, _, _, _, r, p = pcall(getInfo, specIdx)
        if ok then role, primaryStat = r, p end
    end
    local numSpecs = 4
    local getNum = _G.GetNumSpecializations
        or (C_SpecializationInfo and C_SpecializationInfo.GetNumSpecializations)
    if type(getNum) == "function" then
        local ok, n = pcall(getNum)
        if ok and type(n) == "number" and n > 0 then numSpecs = n end
    end

    if role == "HEALER" then return 4 end
    if primaryStat == 4 then return 1 end -- LE_UNIT_STAT_INTELLECT, not healer: Balance
    if role == "TANK" and numSpecs >= 4 then return 2 end
    if role == "DAMAGER" and numSpecs >= 4 and primaryStat and primaryStat ~= 4 then return 3 end
    if role ~= nil or primaryStat ~= nil then
        -- A combined Feral spec (three-spec client): the feral role decides
        if role == "TANK" or role == "DAMAGER" then return self:GetFeralSpec() end
    end

    -- Position only
    if numSpecs >= 4 then
        if specIdx == 1 then return 1 elseif specIdx == 2 then return 3 elseif specIdx == 3 then return 2 end
        return 4
    end
    if specIdx == 1 then return 1 elseif specIdx == 3 then return 4 end
    return self:GetFeralSpec()
end

-- The spec index (1..3, or 1..4 for Druid) the character plays right now.
-- Second return: true when it came from talents / specialization data
-- (false: no points spent, or the data is not loaded yet).
local function DetectUncached(self)
    local class = GetPlayerClass()
    local tab = self:GetPrimaryTalentTab()
    if tab then
        if class == "DRUID" then
            if tab == 1 then return 1, true end  -- Balance
            if tab == 3 then return 4, true end  -- Restoration
            return self:GetFeralSpec(), true     -- Feral Combat: Bear or Cat
        end
        if tab > 3 then return 3, true end
        return tab, true
    end

    -- On Forever the trait trees are the only real source: while they are not
    -- loaded yet (login) or hold no points, do not ask the specialization API,
    -- which always answers spec 1 there (Balance for a druid).
    if type(GetNumTalentTabs) ~= "function" then
        local _, _, traitState = GSI_StatWeights.TraitGroupPoints()
        if traitState == "ok" or traitState == "notready" then
            if class == "DRUID" then return self:GetFeralSpec(), false end
            return 1, false
        end
    end

    -- Specialization API (clients with real specializations)
    local getSpec = (C_SpecializationInfo and C_SpecializationInfo.GetSpecialization) or _G.GetSpecialization
    if type(getSpec) == "function" then
        local ok, specIdx = pcall(getSpec)
        if ok and type(specIdx) == "number" and specIdx >= 1 and specIdx <= 4 then
            if class == "DRUID" then
                return self:MapDruidSpecialization(specIdx), true
            end
            if specIdx > 3 then return 3, true end
            return specIdx, true
        end
    end

    -- No talent points spent yet
    if class == "DRUID" then
        return self:GetFeralSpec(), false
    end
    return 1, false
end

-- Scoring asks for the spec on every item, so the answer is cached until a
-- talent event or a feral-role / mode change clears it (InvalidateSpecCache).
function GSI_StatWeights:DetectCurrentSpec()
    local c = self._detectCache
    if not c then
        local spec, fromTalents = DetectUncached(self)
        c = { spec = spec, fromTalents = fromTalents }
        -- A guess (talent data not loaded yet, no points) is not kept: the next
        -- call looks again, so the real spec shows up without waiting for an event.
        if fromTalents then self._detectCache = c end
    end
    return c.spec, c.fromTalents
end

function GSI_StatWeights:InvalidateSpecCache()
    self._detectCache = nil
end

-- Determines the active specialization index (1..3, or 1..4 for Druid)
function GSI_StatWeights:GetActiveSpecIndex()
    if not self:IsSpecAuto() and GearSetImproverDB and GearSetImproverDB.selectedSpec then
        return tonumber(GearSetImproverDB.selectedSpec) or 1
    end
    return (self:DetectCurrentSpec())
end

-- Everything scored with the old spec's weights is rebuilt: caches, the bag
-- scan result (rescanned), open item tooltips and upgrade toasts.
local function RefreshAfterSpecChange()
    if GSI_ItemScore and GSI_ItemScore.ResetCache then pcall(GSI_ItemScore.ResetCache, GSI_ItemScore) end
    if GSI_OptimizationEngine and GSI_OptimizationEngine.ResetCache then pcall(GSI_OptimizationEngine.ResetCache, GSI_OptimizationEngine) end
    if GSI_TooltipHook and GSI_TooltipHook.ResetCache then pcall(GSI_TooltipHook.ResetCache, GSI_TooltipHook) end
    if GSI_UI and GSI_UI.MarkScanStale then pcall(GSI_UI.MarkScanStale, GSI_UI) end
    if GSI_TooltipHook and GSI_TooltipHook.RefreshShownTooltips then pcall(GSI_TooltipHook.RefreshShownTooltips, GSI_TooltipHook) end
    if GSI_UpgradeToast and GSI_UpgradeToast.ReevaluatePending then
        -- After the spec's gear set has been put on (the callbacks run right
        -- after this), so toasts compare against the gear actually worn.
        local function Reevaluate() pcall(GSI_UpgradeToast.ReevaluatePending, GSI_UpgradeToast) end
        if C_Timer and C_Timer.After then C_Timer.After(1.0, Reevaluate) else Reevaluate() end
    end
    if GSI_UI then
        if GSI_UI.UpdateSpecButton then pcall(GSI_UI.UpdateSpecButton, GSI_UI) end
        if GSI_UI.UpdateModeUI then pcall(GSI_UI.UpdateModeUI, GSI_UI) end
        if GSI_UI.UpdateTitleScore then pcall(GSI_UI.UpdateTitleScore, GSI_UI) end
        local mf = GSI_UI.mainFrame
        if mf and mf:IsShown() and GSI_UI.RefreshPanel then pcall(GSI_UI.RefreshPanel, GSI_UI, true) end
    end
end

function GSI_StatWeights:SetSpecAuto(enabled)
    if not GearSetImproverDB then GearSetImproverDB = {} end
    self:InvalidateSpecCache()
    GearSetImproverDB.specAuto = enabled and true or false
    if enabled then
        GearSetImproverDB.selectedSpec = nil
    elseif not GearSetImproverDB.selectedSpec then
        GearSetImproverDB.selectedSpec = self:DetectCurrentSpec()
    end
    RefreshAfterSpecChange()
end

-- A spec picked by the player (dropdown, /gsi spec, equip macro).
-- Returns true when this left auto mode on.
function GSI_StatWeights:ChooseSpec(specIndex)
    specIndex = tonumber(specIndex)
    if not specIndex then return false end
    if not GearSetImproverDB then GearSetImproverDB = {} end
    local class = GetPlayerClass()
    if class == "DRUID" and (specIndex == 2 or specIndex == 3) then
        GearSetImproverDB.feralSpec = specIndex
    end
    self:InvalidateSpecCache()
    local detected, fromTalents = self:DetectCurrentSpec()
    local staysAuto = self:IsSpecAuto() and specIndex == detected
    if staysAuto then
        GearSetImproverDB.selectedSpec = nil
    else
        GearSetImproverDB.specAuto = false
        GearSetImproverDB.selectedSpec = specIndex
    end
    -- A new feral role is the player's own pick, not an in-game spec change:
    -- move the watcher's baseline so it does not fire set swaps for it later.
    if fromTalents and self._lastDetectedSpec ~= nil then
        self._lastDetectedSpec = detected
    end
    RefreshAfterSpecChange()
    return staysAuto
end

-- Spec change watcher: callbacks get (newSpec, oldSpec) when the talent-
-- detected spec changes (not when the manual pick changes).
GSI_StatWeights._specCallbacks = GSI_StatWeights._specCallbacks or {}

function GSI_StatWeights:RegisterSpecChangeCallback(fn)
    if type(fn) == "function" then
        table.insert(self._specCallbacks, fn)
    end
end

do
    local watcher = CreateFrame and CreateFrame("Frame")
    if watcher then
        local pending = false
        local function Evaluate()
            pending = false
            GSI_StatWeights:InvalidateSpecCache()
            local ok, spec, fromTalents = pcall(GSI_StatWeights.DetectCurrentSpec, GSI_StatWeights)
            -- No baseline until talent data is there: at login it can arrive after
            -- PLAYER_ENTERING_WORLD, and a fallback guess would look like a respec.
            if not ok or not spec or not fromTalents then return end
            local old = GSI_StatWeights._lastDetectedSpec
            GSI_StatWeights._lastDetectedSpec = spec
            if old == nil or old == spec then return end
            if GSI_StatWeights:IsSpecAuto() then
                RefreshAfterSpecChange()
            end
            for _, fn in ipairs(GSI_StatWeights._specCallbacks) do
                pcall(fn, spec, old)
            end
        end
        watcher:SetScript("OnEvent", function(_, event, unit)
            if event == "PLAYER_SPECIALIZATION_CHANGED" and unit and unit ~= "player" then return end
            GSI_StatWeights:InvalidateSpecCache()
            if pending then return end
            pending = true
            if C_Timer and C_Timer.After then
                C_Timer.After(0.5, Evaluate)
            else
                Evaluate()
            end
        end)
        for _, ev in ipairs({
            "PLAYER_ENTERING_WORLD", "PLAYER_TALENT_UPDATE", "CHARACTER_POINTS_CHANGED",
            "ACTIVE_TALENT_GROUP_CHANGED", "PLAYER_SPECIALIZATION_CHANGED", "TRAIT_CONFIG_UPDATED",
            "ACTIVE_PLAYER_SPECIALIZATION_CHANGED", "TRAIT_TREE_CURRENCY_INFO_UPDATED", "SPELLS_CHANGED",
        }) do
            pcall(watcher.RegisterEvent, watcher, ev)
        end
    end
end

function GSI_StatWeights:GetSpecKey()
    local class = GetPlayerClass()
    local specIndex = self:GetActiveSpecIndex()
    return class .. "-" .. specIndex
end

-- Resolves active scoring mode for a class/spec ("Survival"|"DMG" for tanks, "ST"|"AOE" otherwise)
function GSI_StatWeights:ResolveActiveMode(class, specIndex, overrideMode)
    class = class or GetPlayerClass()
    specIndex = specIndex or self:GetActiveSpecIndex()

    if IsTankSpec(class, specIndex) then
        local mode = overrideMode
        if mode == "Threat" then mode = "DMG" end
        if mode ~= "Survival" and mode ~= "DMG" then
            mode = (GearSetImproverDB and GearSetImproverDB.tankMode)
                or (GSI_Config and GSI_Config.TankMode)
                or "Survival"
            if mode == "Threat" then mode = "DMG" end
        end
        return mode
    end

    return overrideMode or (GearSetImproverDB and GearSetImproverDB.weightMode) or "ST"
end

-- Resolves a mode-scoped key "CLASS-SPEC:MODE" while preserving already-scoped keys
function GSI_StatWeights:ResolveScopedKey(specKey, overrideMode)
    specKey = specKey or self:GetSpecKey()

    local explicitBase, explicitMode = specKey:match("^([^:]+):(.+)$")
    if explicitBase and explicitMode then
        return specKey, explicitBase, explicitMode
    end

    local cls, spIdxStr = specKey:match("^([^-]+)%-(%d+)$")
    local clsResolved = cls or GetPlayerClass()
    local spIdx = tonumber(spIdxStr) or self:GetActiveSpecIndex()
    local mode = self:ResolveActiveMode(clsResolved, spIdx, overrideMode)
    return specKey .. ":" .. mode, specKey, mode
end

-- Checks whether the player wears their primary armor proficiency
function GSI_StatWeights:HasArmorSkill()
    local class = GetPlayerClass()
    local level = UnitLevel("player") or 60
    local requiredType = nil -- 1 = Cloth, 2 = Leather, 3 = Mail, 4 = Plate

    if class == "WARRIOR" or class == "PALADIN" then
        requiredType = (level >= 40) and 4 or 3
    elseif class == "HUNTER" or class == "SHAMAN" then
        requiredType = (level >= 40) and 3 or 2
    elseif class == "ROGUE" or class == "DRUID" then
        requiredType = 2
    elseif class == "PRIEST" or class == "MAGE" or class == "WARLOCK" then
        requiredType = 1
    end

    if not requiredType then return true end

    local armorSlots = {
        INVSLOT_HEAD, INVSLOT_SHOULDER, INVSLOT_CHEST, INVSLOT_WRIST,
        INVSLOT_HAND, INVSLOT_WAIST, INVSLOT_LEGS, INVSLOT_FEET
    }

    for _, slot in ipairs(armorSlots) do
        local link = GetInventoryItemLink("player", slot)
        if link then
            local _, _, _, _, _, _, _, _, _, _, _, classID, subClassID = GetItemInfo(link)
            -- classID 4 is Armor in WoW
            if classID == 4 and subClassID and subClassID ~= requiredType then
                return false
            end
        end
    end
    return true
end

-- Internal helper: resolves custom weights or active profile for a scoped/legacy key
function GSI_StatWeights:_LookupCustomWeights(scopedKey, baseSpecKey, activeMode)
    if not GearSetImproverDB then
        return nil, nil, false
    end

    local activeProf = self:GetActiveProfileName(baseSpecKey, activeMode)
    if activeProf then
        local wp = GearSetImproverDB.weightProfiles
        if wp and wp[scopedKey] and wp[scopedKey][activeProf] then
            local isAoECustom = (activeMode == "AOE") or (activeProf:lower():find("aoe", 1, true) ~= nil)
            return SafeCopyTable(wp[scopedKey][activeProf]), activeProf, isAoECustom
        end
        if wp and wp[baseSpecKey] and wp[baseSpecKey][activeProf] and not HasScopedPrefix(wp, baseSpecKey) then
            local isAoECustom = (activeMode == "AOE") or (activeProf:lower():find("aoe", 1, true) ~= nil)
            return SafeCopyTable(wp[baseSpecKey][activeProf]), activeProf, isAoECustom
        end
    end

    local cw = GearSetImproverDB.customWeights
    if cw then
        if cw[scopedKey] then
            return SafeCopyTable(cw[scopedKey]), activeProf, (activeMode == "AOE")
        end
        local explicitlyReset = GearSetImproverDB.activeProfile
            and GearSetImproverDB.activeProfile[scopedKey] == false
        if not explicitlyReset and cw[baseSpecKey] and not HasScopedPrefix(cw, baseSpecKey) then
            return SafeCopyTable(cw[baseSpecKey]), activeProf, false
        end
    end

    return nil, activeProf, false
end

-- Returns final stat weights for the specified or current specialization and mode
function GSI_StatWeights:GetWeights(overrideSpecIndex, overrideMode)
    local class = GetPlayerClass()
    local specIndex = overrideSpecIndex or self:GetActiveSpecIndex()
    local specKey = class .. "-" .. specIndex
    local activeMode = self:ResolveActiveMode(class, specIndex, overrideMode)
    local scopedKey = specKey .. ":" .. activeMode

    local finalWeights = nil
    local isDedicatedAoE = false

    -- 1. Check active custom profile or mode-scoped customWeights
    local customWeights, _, customIsAoE = self:_LookupCustomWeights(scopedKey, specKey, activeMode)
    if customWeights then
        finalWeights = customWeights
        if customIsAoE then
            isDedicatedAoE = true
        end
    else
        -- 2. Base weights: primarily from validated v2.2 profiles (Profiles_v2_2.lua)
        local activeProfileObj = GSI_Config and GSI_Config.GetProfile and GSI_Config:GetProfile(class, specIndex, activeMode)
        if activeProfileObj and (
            activeProfileObj.isAoEProfile
            or activeProfileObj.mode == "AOE"
            or (type(activeProfileObj.id) == "string" and activeProfileObj.id:match("_aoe$") ~= nil)
        ) then
            isDedicatedAoE = true
        end

        local profWeights = GSI_Config and GSI_Config.GetProfileWeights and GSI_Config:GetProfileWeights(class, specIndex, activeMode)
        if profWeights then
            finalWeights = SafeCopyTable(profWeights)
        else
            -- 3. Fallback: Config.DefaultWeights
            local classTable = GSI_Config and GSI_Config.DefaultWeights and GSI_Config.DefaultWeights[class]
            local specWeights = classTable and classTable[specIndex]

            if not specWeights then
                -- Universal emergency fallback
                finalWeights = {
                    Strength = 1.0, Agility = 1.0, Stamina = 1.0, Intellect = 1.0, Spirit = 0.5,
                    AttackPower = 0.8, SpellPower = 1.0, Hit = 10.0, Crit = 10.0, WeaponDamage = 10.0
                }
            else
                local activeWeights = nil
                if specWeights.Survival or specWeights.DMG then
                    local tankMode = activeMode or "Survival"
                    activeWeights = specWeights[tankMode] or specWeights.Survival or specWeights.DMG
                else
                    activeWeights = specWeights
                end

                finalWeights = SafeCopyTable(activeWeights)
            end
        end

        -- 4. Apply Racial Modifiers
        if GSI_RaceBonus and GSI_RaceBonus.GetStatModifiers then
            local raceMods = GSI_RaceBonus:GetStatModifiers()
            for stat, mod in pairs(raceMods) do
                if finalWeights[stat] then
                    finalWeights[stat] = finalWeights[stat] * mod
                end
            end
        end

        -- 5. Apply Talent Modifiers
        if GSI_TalentIntegration and GSI_TalentIntegration.GetStatModifiers then
            local talentMods = GSI_TalentIntegration:GetStatModifiers()
            for stat, mod in pairs(talentMods) do
                if finalWeights[stat] then
                    finalWeights[stat] = finalWeights[stat] * mod
                end
            end

            -- v2.2 Class/Spec Talent Dynamic Scaling:
            -- Enhancement Shaman (Spec 2): Intellect 0.20..0.87 via Mental Dexterity (33/66/100% AP) & Mental Quickness (15/30% SP/Heal)
            if class == "SHAMAN" and specIndex == 2 and GSI_TalentIntegration.GetShamanEnhancementIntWeight then
                local dynamicInt = GSI_TalentIntegration:GetShamanEnhancementIntWeight()
                if dynamicInt then
                    finalWeights.Intellect = dynamicInt
                end
            end

            -- Marksmanship Hunter (Spec 2): Intellect 0.15..0.56 via Careful Aim (20..100% INT -> AP)
            if class == "HUNTER" and specIndex == 2 and GSI_TalentIntegration.GetHunterMMIntWeight then
                local dynamicInt = GSI_TalentIntegration:GetHunterMMIntWeight()
                if dynamicInt then
                    finalWeights.Intellect = dynamicInt
                end
            end

            -- Survival Hunter (Spec 3): Intellect 0.20..0.70 via Careful Aim
            if class == "HUNTER" and specIndex == 3 and GSI_TalentIntegration.GetHunterSurvivalIntWeight then
                local dynamicInt = GSI_TalentIntegration:GetHunterSurvivalIntWeight()
                if dynamicInt then
                    finalWeights.Intellect = dynamicInt
                end
            end

            -- Holy Paladin (Spec 1): Spirit 0.15..0.60 via Reverence (15/30% FSR mana regen)
            if class == "PALADIN" and specIndex == 1 and GSI_TalentIntegration.GetPaladinHolySpiritWeight then
                local dynamicSpi = GSI_TalentIntegration:GetPaladinHolySpiritWeight()
                if dynamicSpi then
                    finalWeights.Spirit = dynamicSpi
                end
            end

            -- Retribution Paladin (Spec 3): Intellect via Champion of the Light (12/24/36/48/60% INT -> SP)
            if class == "PALADIN" and specIndex == 3 and GSI_TalentIntegration.GetPaladinRetIntWeight then
                local dynamicInt = GSI_TalentIntegration:GetPaladinRetIntWeight()
                if dynamicInt then
                    finalWeights.Intellect = dynamicInt
                end
            end

            -- Arcane Mage (Spec 1): Intellect & Mana via Arcane Blast & Arcane Wrath
            if class == "MAGE" and specIndex == 1 then
                if GSI_TalentIntegration.GetMageArcaneIntWeight then
                    local dynamicInt = GSI_TalentIntegration:GetMageArcaneIntWeight()
                    if dynamicInt then finalWeights.Intellect = dynamicInt end
                end
                if GSI_TalentIntegration.GetMageArcaneManaWeight then
                    local dynamicMana = GSI_TalentIntegration:GetMageArcaneManaWeight()
                    if dynamicMana then finalWeights.Mana = dynamicMana end
                end
            end

            -- Priest (all specs): Mental Strength (+2/4/6/8/10% Intellect in Discipline Row 2)
            if class == "PRIEST" and GSI_TalentIntegration.GetPriestMentalStrengthBonus then
                local msBonus = GSI_TalentIntegration:GetPriestMentalStrengthBonus()
                if msBonus and msBonus > 0 then
                    finalWeights.Intellect = (finalWeights.Intellect or 0.3) * (1.0 + msBonus)
                end
            end

            -- Druid Natural Instinct (Feral Row 5):
            -- +10/20% melee ability crit damage (Bear/Cat) & +12/25% INT -> HealingPower (Resto/hybrid)
            if class == "DRUID" then
                if (specIndex == 2 or specIndex == 3) and GSI_TalentIntegration.GetDruidNaturalInstinctFeralCritMod then
                    local feralCritMod = GSI_TalentIntegration:GetDruidNaturalInstinctFeralCritMod()
                    if feralCritMod and feralCritMod > 1.0 and finalWeights.Crit then
                        finalWeights.Crit = finalWeights.Crit * feralCritMod
                    end
                    if GSI_TalentIntegration.GetDruidRestoIntBonus and finalWeights.HealingPower and finalWeights.HealingPower > 0 then
                        local hybridInt = GSI_TalentIntegration:GetDruidRestoIntBonus()
                        if hybridInt and hybridInt > 0 then
                            finalWeights.Intellect = (finalWeights.Intellect or 0) + (hybridInt * 0.25)
                        end
                    end
                elseif specIndex == 4 and GSI_TalentIntegration.GetDruidRestoIntBonus then
                    local bonusInt = GSI_TalentIntegration:GetDruidRestoIntBonus()
                    if bonusInt and bonusInt > 0 then
                        finalWeights.Intellect = (finalWeights.Intellect or 0.6) + bonusInt
                    end
                end
            end
        end

        -- 6. Universal SpellPower vs HealingPower handling
        -- Per Rules_v2_2.healer_spell_damage_weight = 0, healers MUST keep SpellPower = 0
        -- ("+damage and healing" items already map via HealingPower in ItemScore.lua).
        local role = self:GetRole(overrideSpecIndex, overrideMode)
        if role ~= "healer" then
            if not finalWeights.HealingPower and finalWeights.SpellPower and finalWeights.SpellPower > 0 then
                finalWeights.HealingPower = math.floor((finalWeights.SpellPower / 3) * 100 + 0.5) / 100
            end
        else
            finalWeights.SpellPower = 0
        end

        if GSI_Config and GSI_Config.TertiaryWeights then
            for stat, w in pairs(GSI_Config.TertiaryWeights) do
                if not finalWeights[stat] then
                    finalWeights[stat] = w
                end
            end
        end
    end

    -- 7. AoE Fallback Multipliers (only when AOE is selected and NO dedicated AoE profile exists)
    if activeMode == "AOE" and not isDedicatedAoE then
        if finalWeights.Hit then
            finalWeights.Hit = finalWeights.Hit * 0.55
        end
        -- Scale Agility & RangedAttackPower alongside Strength/AP/FeralAP to preserve Primary > 2 * AP
        local physAoEKeys = { "Strength", "Agility", "AttackPower", "RangedAttackPower", "FeralAttackPower" }
        for _, pKey in ipairs(physAoEKeys) do
            if finalWeights[pKey] then
                finalWeights[pKey] = finalWeights[pKey] * 1.20
            end
        end
        if finalWeights.SpellPower and finalWeights.SpellPower > 0 then
            finalWeights.SpellPower = finalWeights.SpellPower * 1.20
        end
        local spellSchools = { "ArcaneSpellPower", "FireSpellPower", "FrostSpellPower", "ShadowSpellPower", "NatureSpellPower", "HolySpellPower" }
        for _, schoolKey in ipairs(spellSchools) do
            if finalWeights[schoolKey] and finalWeights[schoolKey] > 0 then
                finalWeights[schoolKey] = finalWeights[schoolKey] * 1.20
            end
        end
        if finalWeights.Crit then
            finalWeights.Crit = finalWeights.Crit * 1.15
        end
    end

    -- 8. Elemental Resistances:
    -- Active only when the corresponding resistance checkbox is checked; otherwise 0.
    local reqResists = GearSetImproverDB and GearSetImproverDB.requiredResists
    local defaultResistWeight = (GSI_Config and GSI_Config.DefaultResistWeight) or 5.0
    local resistMap = {
        FireResist   = "Fire",
        NatureResist = "Nature",
        FrostResist  = "Frost",
        ShadowResist = "Shadow",
        ArcaneResist = "Arcane",
    }
    for rKey, elem in pairs(resistMap) do
        local configuredVal = (customWeights and customWeights[rKey]) or finalWeights[rKey] or defaultResistWeight
        if not configuredVal or configuredVal == 0 then
            configuredVal = defaultResistWeight
        end
        if reqResists and reqResists[elem] then
            finalWeights[rKey] = configuredVal
        else
            finalWeights[rKey] = 0
        end
    end

    -- 9. Magic Schools (Spell Power):
    -- Preserves configured/profile weight cleanly without jumping inactive 0 values to 1.0.
    local schoolMap = {
        ArcaneSpellPower = "Arcane",
        FireSpellPower   = "Fire",
        FrostSpellPower  = "Frost",
        ShadowSpellPower = "Shadow",
        NatureSpellPower = "Nature",
        HolySpellPower   = "Holy",
    }
    local enabledSchoolsDB = GearSetImproverDB and GearSetImproverDB.enabledSpellSchools
    local enabledSchools = enabledSchoolsDB and (
        enabledSchoolsDB[scopedKey]
        or (not HasScopedPrefix(enabledSchoolsDB, specKey) and enabledSchoolsDB[specKey])
    ) or nil

    for sKey, _ in pairs(schoolMap) do
        local configuredVal = (finalWeights[sKey] ~= nil) and finalWeights[sKey] or 0

        local isEnabled
        if enabledSchools and enabledSchools[sKey] ~= nil then
            isEnabled = enabledSchools[sKey]
        else
            isEnabled = (configuredVal > 0)
        end

        if isEnabled then
            finalWeights[sKey] = configuredVal
        else
            finalWeights[sKey] = 0
        end
    end

    return finalWeights
end

-- Returns the configured weight of a resistance stat (default: 5.0)
function GSI_StatWeights:GetResistWeight(statOrElem, overrideMode)
    local scopedKey, baseSpecKey = self:ResolveScopedKey(self:GetSpecKey(), overrideMode)
    local cw = GearSetImproverDB and GearSetImproverDB.customWeights
    local scopedCW = cw and (cw[scopedKey] or (not HasScopedPrefix(cw, baseSpecKey) and cw[baseSpecKey])) or nil
    local defaultWeight = (GSI_Config and GSI_Config.DefaultResistWeight) or 5.0
    local key = statOrElem
    if not key:find("Resist$") then
        key = key .. "Resist"
    end
    if scopedCW and scopedCW[key] and scopedCW[key] > 0 then
        return scopedCW[key]
    end
    return defaultWeight
end

-- Returns the configured weight of a magic school without fabricating 1.0 when inactive/0
function GSI_StatWeights:GetSchoolWeight(schoolKey, overrideMode)
    local class = GetPlayerClass()
    local specIndex = self:GetActiveSpecIndex()
    local specKey = class .. "-" .. specIndex
    local activeMode = self:ResolveActiveMode(class, specIndex, overrideMode)
    local scopedKey = specKey .. ":" .. activeMode

    local customWeights = self:_LookupCustomWeights(scopedKey, specKey, activeMode)
    if customWeights and customWeights[schoolKey] ~= nil then
        return customWeights[schoolKey]
    end

    local profWeights = GSI_Config and GSI_Config.GetProfileWeights and GSI_Config:GetProfileWeights(class, specIndex, activeMode)
    if profWeights and profWeights[schoolKey] ~= nil then
        return profWeights[schoolKey]
    end

    local classTable = GSI_Config and GSI_Config.DefaultWeights and GSI_Config.DefaultWeights[class]
    local specWeights = classTable and classTable[specIndex]
    if specWeights then
        if specWeights.Survival or specWeights.DMG then
            specWeights = specWeights[activeMode] or specWeights.Survival or specWeights.DMG
        end
        if specWeights and specWeights[schoolKey] ~= nil then
            return specWeights[schoolKey]
        end
    end

    return 0
end

-- Checks whether a magic school is enabled for the current spec and mode
function GSI_StatWeights:IsSchoolEnabled(specKey, schoolKey, overrideMode)
    local scopedKey, baseSpecKey, activeMode = self:ResolveScopedKey(specKey, overrideMode)
    local db = GearSetImproverDB and GearSetImproverDB.enabledSpellSchools
    if db then
        if db[scopedKey] and db[scopedKey][schoolKey] ~= nil then
            return db[scopedKey][schoolKey]
        end
        if not HasScopedPrefix(db, baseSpecKey) and db[baseSpecKey] and db[baseSpecKey][schoolKey] ~= nil then
            return db[baseSpecKey][schoolKey]
        end
    end

    local class, spIdxStr = baseSpecKey:match("^([^-]+)%-(%d+)$")
    class = class or GetPlayerClass()
    local specIndex = tonumber(spIdxStr) or self:GetActiveSpecIndex()

    local customWeights = self:_LookupCustomWeights(scopedKey, baseSpecKey, activeMode)
    if customWeights and customWeights[schoolKey] ~= nil then
        return customWeights[schoolKey] > 0
    end

    local profWeights = GSI_Config and GSI_Config.GetProfileWeights and GSI_Config:GetProfileWeights(class, specIndex, activeMode)
    if profWeights and profWeights[schoolKey] and profWeights[schoolKey] > 0 then
        return true
    end

    local classTable = GSI_Config and GSI_Config.DefaultWeights and GSI_Config.DefaultWeights[class]
    local specWeights = classTable and classTable[specIndex]
    if specWeights then
        if specWeights.Survival or specWeights.DMG then
            specWeights = specWeights[activeMode] or specWeights.Survival or specWeights.DMG
        end
        return (specWeights and specWeights[schoolKey] and specWeights[schoolKey] > 0) or false
    end
    return false
end

-- Enables or disables a magic school for the current spec and mode
function GSI_StatWeights:SetSchoolEnabled(specKey, schoolKey, isEnabled, overrideMode)
    local scopedKey = self:ResolveScopedKey(specKey, overrideMode)
    if not GearSetImproverDB then GearSetImproverDB = {} end
    if not GearSetImproverDB.enabledSpellSchools then
        GearSetImproverDB.enabledSpellSchools = {}
    end
    if not GearSetImproverDB.enabledSpellSchools[scopedKey] then
        GearSetImproverDB.enabledSpellSchools[scopedKey] = {}
    end
    GearSetImproverDB.enabledSpellSchools[scopedKey][schoolKey] = isEnabled
end

-- Returns whether the given or active specialization is a spell caster
function GSI_StatWeights:IsCasterSpec(overrideSpecIndex)
    local class = GetPlayerClass()
    local specIndex = overrideSpecIndex or self:GetActiveSpecIndex()
    local classData = GSI_ClassicData and GSI_ClassicData.Classes and GSI_ClassicData.Classes[class]
    if classData and classData.specs and classData.specs[specIndex] then
        return classData.specs[specIndex].caster == true
    end
    return false
end

-- Determines player role ("tank" | "healer" | "dps") for backwards compatibility
function GSI_StatWeights:GetRole(overrideSpecIndex, overrideMode)
    local class = GetPlayerClass()
    local specIndex = overrideSpecIndex or self:GetActiveSpecIndex()

    local classData = GSI_ClassicData and GSI_ClassicData.Classes and GSI_ClassicData.Classes[class]
    if classData and classData.specs and classData.specs[specIndex] then
        local specInfo = classData.specs[specIndex]
        if specInfo.role == "hybrid" then
            local tankMode = overrideMode or (GearSetImproverDB and GearSetImproverDB.tankMode) or "Survival"
            return (tankMode == "Survival") and "tank" or "dps"
        end
        return specInfo.role or "dps"
    end

    return "dps"
end

-- Safely computes the player's current enemy Dodge/Parry avoidance reduction (%)
-- Combines equipped gear AvoidanceReduction, set bonuses, client expertise API (if present & non-secret),
-- and Rogue Weapon Expertise without double-counting API values against gear/talents.
function GSI_StatWeights:GetCurrentAvoidanceReduction(includeTalents)
    local gearAvoid = 0

    if GSI_ItemScore and GSI_ItemScore.GetParsedStats and type(GetInventoryItemLink) == "function" then
        for slot = 1, 18 do
            local ok, link = pcall(GetInventoryItemLink, "player", slot)
            if ok and link then
                local stats = GSI_ItemScore:GetParsedStats(link)
                if stats and stats.AvoidanceReduction and stats.AvoidanceReduction > 0 then
                    gearAvoid = gearAvoid + stats.AvoidanceReduction
                end
            end
        end
    end

    if GSI_SetBonus and GSI_SetBonus.GetActiveSetBonusStats then
        local setStats = GSI_SetBonus:GetActiveSetBonusStats()
        if setStats and setStats.AvoidanceReduction and setStats.AvoidanceReduction > 0 then
            gearAvoid = gearAvoid + setStats.AvoidanceReduction
        end
    end

    local class = GetPlayerClass()
    local talentAvoid = 0
    if class == "ROGUE" and GSI_TalentIntegration and GSI_TalentIntegration.GetRogueWeaponExpertiseReduction then
        talentAvoid = GSI_TalentIntegration:GetRogueWeaponExpertiseReduction() or 0
    end

    local apiAvoid = 0
    if type(_G.GetExpertisePercent) == "function" then
        local ok, mainExp = pcall(_G.GetExpertisePercent)
        if ok then
            local safeExp = ResolveSafeNumber(mainExp)
            if safeExp and safeExp > 0 then
                apiAvoid = safeExp
            end
        end
    elseif type(_G.GetExpertise) == "function" then
        -- Forever 1.60.1 GetExpertise() returns percentage directly
        local ok, mainExp = pcall(_G.GetExpertise)
        if ok then
            local safeExp = ResolveSafeNumber(mainExp)
            if safeExp and safeExp > 0 and safeExp <= 100 then
                apiAvoid = safeExp
            end
        end
    end

    local totalWithTalents = math.max(gearAvoid + talentAvoid, apiAvoid)
    if includeTalents == false then
        return math.max(gearAvoid, math.max(0, totalWithTalents - talentAvoid))
    end
    return totalWithTalents
end

-- ============================================================
-- Mode-Aware Profile Management for Custom Stat Weights
-- ============================================================
function GSI_StatWeights:GetProfiles(specKey, overrideMode)
    local scopedKey, baseSpecKey = self:ResolveScopedKey(specKey, overrideMode)
    local list = {}
    local wp = GearSetImproverDB and GearSetImproverDB.weightProfiles
    if not wp then return list end

    local source = wp[scopedKey]
    if not source and not HasScopedPrefix(wp, baseSpecKey) then
        source = wp[baseSpecKey]
    end

    if source then
        for name, _ in pairs(source) do
            table.insert(list, name)
        end
        table.sort(list)
    end
    return list
end

function GSI_StatWeights:GetActiveProfileName(specKey, overrideMode)
    local scopedKey, baseSpecKey = self:ResolveScopedKey(specKey, overrideMode)
    local ap = GearSetImproverDB and GearSetImproverDB.activeProfile
    if not ap then return nil end

    local val = ap[scopedKey]
    if val == false then
        return nil
    end
    if type(val) == "string" and val ~= "" then
        return val
    end

    if not HasScopedPrefix(ap, baseSpecKey) then
        local legacyVal = ap[baseSpecKey]
        if type(legacyVal) == "string" and legacyVal ~= "" then
            return legacyVal
        end
    end
    return nil
end

function GSI_StatWeights:SetActiveProfile(specKey, profileName, overrideMode)
    local scopedKey, baseSpecKey, activeMode = self:ResolveScopedKey(specKey, overrideMode)
    if not GearSetImproverDB then return end
    if not GearSetImproverDB.activeProfile then GearSetImproverDB.activeProfile = {} end
    if not GearSetImproverDB.customWeights then GearSetImproverDB.customWeights = {} end

    if not profileName or profileName == "" or profileName == "Default" then
        if GearSetImproverDB.activeProfile[baseSpecKey] ~= nil then
            GearSetImproverDB.activeProfile[scopedKey] = false
        else
            GearSetImproverDB.activeProfile[scopedKey] = nil
        end
        GearSetImproverDB.customWeights[scopedKey] = nil
        if activeMode == "ST" or activeMode == "Survival" or not HasScopedPrefix(GearSetImproverDB.customWeights, baseSpecKey) then
            GearSetImproverDB.customWeights[baseSpecKey] = nil
        end
    else
        GearSetImproverDB.activeProfile[scopedKey] = profileName
        local wp = GearSetImproverDB.weightProfiles
        local profWeights = (wp and wp[scopedKey] and wp[scopedKey][profileName])
            or (wp and not HasScopedPrefix(wp, baseSpecKey) and wp[baseSpecKey] and wp[baseSpecKey][profileName])
        if profWeights then
            GearSetImproverDB.customWeights[scopedKey] = SafeCopyTable(profWeights)
        end
    end

    if GSI_ItemScore then GSI_ItemScore:ResetCache() end
    if GSI_OptimizationEngine then GSI_OptimizationEngine:ResetCache() end
end

function GSI_StatWeights:SaveProfile(specKey, profileName, weightsTable, overrideMode)
    local scopedKey, baseSpecKey = self:ResolveScopedKey(specKey, overrideMode)
    if not GearSetImproverDB then return end
    if not GearSetImproverDB.weightProfiles then GearSetImproverDB.weightProfiles = {} end
    if not GearSetImproverDB.weightProfiles[scopedKey] then
        -- Migrate legacy unscoped profiles into this mode once if no scoped bucket existed yet
        if GearSetImproverDB.weightProfiles[baseSpecKey] and not HasScopedPrefix(GearSetImproverDB.weightProfiles, baseSpecKey) then
            GearSetImproverDB.weightProfiles[scopedKey] = SafeCopyTable(GearSetImproverDB.weightProfiles[baseSpecKey])
        else
            GearSetImproverDB.weightProfiles[scopedKey] = {}
        end
    end
    if not GearSetImproverDB.activeProfile then GearSetImproverDB.activeProfile = {} end
    if not GearSetImproverDB.customWeights then GearSetImproverDB.customWeights = {} end

    GearSetImproverDB.weightProfiles[scopedKey][profileName] = SafeCopyTable(weightsTable)
    GearSetImproverDB.activeProfile[scopedKey] = profileName
    GearSetImproverDB.customWeights[scopedKey] = SafeCopyTable(weightsTable)

    if GSI_ItemScore then GSI_ItemScore:ResetCache() end
    if GSI_OptimizationEngine then GSI_OptimizationEngine:ResetCache() end
end

function GSI_StatWeights:DeleteProfile(specKey, profileName, overrideMode)
    local scopedKey, baseSpecKey = self:ResolveScopedKey(specKey, overrideMode)
    local wp = GearSetImproverDB and GearSetImproverDB.weightProfiles
    if not wp then return end

    local bucketKey = wp[scopedKey] and scopedKey or (not HasScopedPrefix(wp, baseSpecKey) and wp[baseSpecKey] and baseSpecKey)
    if not bucketKey then return end

    wp[bucketKey][profileName] = nil

    if GearSetImproverDB.activeProfile then
        if GearSetImproverDB.activeProfile[scopedKey] == profileName then
            GearSetImproverDB.activeProfile[scopedKey] = nil
            if GearSetImproverDB.customWeights then
                GearSetImproverDB.customWeights[scopedKey] = nil
            end
        elseif bucketKey == baseSpecKey and GearSetImproverDB.activeProfile[baseSpecKey] == profileName then
            GearSetImproverDB.activeProfile[baseSpecKey] = nil
            if GearSetImproverDB.customWeights then
                GearSetImproverDB.customWeights[baseSpecKey] = nil
            end
        end
    end

    if GSI_ItemScore then GSI_ItemScore:ResetCache() end
    if GSI_OptimizationEngine then GSI_OptimizationEngine:ResetCache() end
end

function GSI_StatWeights:RenameProfile(specKey, oldName, newName, overrideMode)
    local scopedKey, baseSpecKey = self:ResolveScopedKey(specKey, overrideMode)
    local wp = GearSetImproverDB and GearSetImproverDB.weightProfiles
    if not wp then return end

    local bucketKey = wp[scopedKey] and scopedKey or (not HasScopedPrefix(wp, baseSpecKey) and wp[baseSpecKey] and baseSpecKey)
    if not bucketKey then return end
    if not newName or newName == "" or newName == oldName then return end

    local data = wp[bucketKey][oldName]
    if data then
        wp[bucketKey][newName] = data
        wp[bucketKey][oldName] = nil
        if GearSetImproverDB.activeProfile then
            if GearSetImproverDB.activeProfile[scopedKey] == oldName then
                GearSetImproverDB.activeProfile[scopedKey] = newName
            elseif bucketKey == baseSpecKey and GearSetImproverDB.activeProfile[baseSpecKey] == oldName then
                GearSetImproverDB.activeProfile[baseSpecKey] = newName
            end
        end
    end
end
