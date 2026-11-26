-- ============================================================
-- GearSetImprover - SpecSets.lua (WoW Forever 1.60.1)
-- GUID-safe per-character Spec-to-Set & Dual-Spec Talent Group bindings.
-- ============================================================

GSI_SpecSets = GSI_SpecSets or {}
GSI_UI = GSI_UI or {}

local BackdropTemplateMixin = _G.BackdropTemplateMixin
local BACKDROP_TEMPLATE = BackdropTemplateMixin and "BackdropTemplate" or nil
local function SkinFrame(f, s, t) if GSI_UI.SkinFrame then return GSI_UI:SkinFrame(f, s, t) end end
local function SkinButton(b, r, p) if GSI_UI.SkinButton then return GSI_UI:SkinButton(b, r, p) end end
local print = function(...)
    if GSI_Print then
        GSI_Print(...)
    elseif not (GearSetImproverDB and (GearSetImproverDB.disableChatOutput or GearSetImproverDB.disableChat)) then
        _G.print(...)
    end
end

local function SpecSetCharKey(dbTable)
    local guid = type(UnitGUID) == "function" and UnitGUID("player") or nil
    if guid and guid ~= "" then
        if dbTable and not dbTable[guid] then
            local firstName, surname = nil, nil
            if type(UnitName) == "function" then
                firstName, surname = UnitName("player")
            end
            local realm = type(GetRealmName) == "function" and (GetRealmName() or "") or ""
            local candidates = {}
            if firstName and firstName ~= "" then
                if surname and surname ~= "" then
                    candidates[#candidates + 1] = firstName .. " " .. surname .. "-" .. realm
                    candidates[#candidates + 1] = firstName .. " " .. surname .. "-"
                end
                candidates[#candidates + 1] = firstName .. "-" .. realm
                candidates[#candidates + 1] = firstName .. "-"
                candidates[#candidates + 1] = firstName .. "-?"
            end
            for _, ck in ipairs(candidates) do
                if dbTable[ck] then
                    dbTable[guid] = dbTable[ck]
                    break
                end
            end
        end
        return guid
    end
    local name = (type(UnitName) == "function" and UnitName("player")) or "?"
    local realm = (type(GetRealmName) == "function" and GetRealmName()) or ""
    return name .. "-" .. realm
end

local function SpecDisplayName(specIndex)
    local class = (GSI_ClassicData and GSI_ClassicData.GetPlayerClass and GSI_ClassicData:GetPlayerClass())
        or select(2, UnitClass("player")) or "WARRIOR"
    local cd = GSI_ClassicData and GSI_ClassicData.Classes and GSI_ClassicData.Classes[class]
    local sd = cd and cd.specs and cd.specs[specIndex]
    return (sd and sd.name) or ("Spec " .. tostring(specIndex))
end

local function PlayerClassKey()
    return (GSI_ClassicData and GSI_ClassicData.GetPlayerClass and GSI_ClassicData:GetPlayerClass())
        or select(2, UnitClass("player")) or "WARRIOR"
end

local function SetExists(name)
    return name ~= nil and C_EquipmentSet ~= nil and C_EquipmentSet.GetEquipmentSetID ~= nil
        and C_EquipmentSet.GetEquipmentSetID(name) ~= nil
end

local function Trim16(name)
    if name and #name > 16 then return name:sub(1, 16) end
    return name
end

-- The mode a spec is scored in now (tank specs: tankMode, others: weightMode).
local function CurrentModeFor(specIndex)
    local cd = GSI_ClassicData and GSI_ClassicData.Classes and GSI_ClassicData.Classes[PlayerClassKey()]
    local sd = cd and cd.specs and cd.specs[tonumber(specIndex) or 0]
    local role = sd and sd.role
    if role == "tank" or role == "hybrid" then
        return (GearSetImproverDB and GearSetImproverDB.tankMode) or "Survival"
    end
    return (GearSetImproverDB and GearSetImproverDB.weightMode) or "ST"
end

-- Sets chosen in Settings for a spec: GearSetImproverDB.specSets["Name-Realm"]
-- [specIndex] is a list of set names (an older single name still reads).
local function ManualSpecSets(specIndex)
    local all = GearSetImproverDB and GearSetImproverDB.specSets
    local t = all and all[SpecSetCharKey(GearSetImproverDB.specSets)]
    local v = t and t[tonumber(specIndex) or 0]
    if type(v) == "string" and v ~= "" then return { v } end
    local list = {}
    if type(v) == "table" then
        for _, n in ipairs(v) do
            if type(n) == "string" and n ~= "" then list[#list + 1] = n end
        end
    end
    return list
end

-- The name GSI gives the set it saves for a spec in a mode (the class macro
-- preset's name, as SaveEquipmentSetForProfile names it), or nil.
-- Tank "Threat" (tooltip lines) and "DMG" (presets, tankMode) are one mode.
local function NormMode(m)
    m = tostring(m or ""):upper()
    if m == "THREAT" then return "DMG" end
    return m
end

local function ModeSetName(specIndex, modeVal)
    local presets = GSI_MACRO_PRESETS[PlayerClassKey()]
    if not presets or not modeVal then return nil end
    for _, p in ipairs(presets) do
        if p.specIndex == specIndex and p.mode and NormMode(p.mode) == NormMode(modeVal) then
            return Trim16(p.name)
        end
    end
    return nil
end

-- The sets GSI has saved for a spec ("GSI: Cat ST", "GSI: Resto AoE", ...),
-- those that exist, the one for modeVal first.
function GSI_UI:GetAutoSpecSets(specIndex, modeVal)
    specIndex = tonumber(specIndex)
    local list, seen = {}, {}
    local function Add(name)
        name = Trim16(name)
        if name and not seen[name] and SetExists(name) then
            seen[name] = true
            list[#list + 1] = name
        end
    end
    Add(ModeSetName(specIndex, modeVal))
    local presets = GSI_MACRO_PRESETS[PlayerClassKey()]
    if presets then
        for _, p in ipairs(presets) do
            if p.specIndex == specIndex then Add(p.name) end
        end
    end
    Add("GSI: " .. SpecDisplayName(specIndex)) -- the name without a preset
    return list
end

-- The sets of a spec: the ones chosen in Settings, else the ones GSI saved
-- for it. Second return: true when chosen in Settings.
function GSI_UI:GetSpecSets(specIndex, modeVal)
    local manual = ManualSpecSets(specIndex)
    if #manual > 0 then return manual, true end
    return self:GetAutoSpecSets(specIndex, modeVal), false
end

-- The first set of a spec, or nil (older callers).
function GSI_UI:GetSpecSetName(specIndex)
    return (self:GetSpecSets(specIndex, CurrentModeFor(tonumber(specIndex))))[1]
end

-- nil or an empty list: back to the sets GSI saved for the spec.
function GSI_UI:SetSpecSets(specIndex, names)
    specIndex = tonumber(specIndex)
    if not specIndex then return end
    if not GearSetImproverDB then GearSetImproverDB = {} end
    GearSetImproverDB.specSets = GearSetImproverDB.specSets or {}
    local key = SpecSetCharKey(GearSetImproverDB.specSets)
    GearSetImproverDB.specSets[key] = GearSetImproverDB.specSets[key] or {}
    GearSetImproverDB.specSets[key][specIndex] = (type(names) == "table" and #names > 0) and names or nil
end

function GSI_UI:SetSpecSetName(specIndex, setName)
    self:SetSpecSets(specIndex, (setName and setName ~= "") and { setName } or nil)
end

-- Adds a set to the spec's own list, or takes it out.
function GSI_UI:ToggleSpecSet(specIndex, setName)
    local list = ManualSpecSets(specIndex)
    for i, n in ipairs(list) do
        if n == setName then
            table.remove(list, i)
            self:SetSpecSets(specIndex, list)
            return false
        end
    end
    list[#list + 1] = setName
    self:SetSpecSets(specIndex, list)
    return true
end

-- The mode a set GSI saved for a spec was made for, as tooltip lines name it
-- ("ST", "AOE", "Survival", "Threat"), or nil for any other set.
local function SetPresetMode(specIndex, setName)
    local presets = GSI_MACRO_PRESETS[PlayerClassKey()]
    if not presets then return nil end
    for _, p in ipairs(presets) do
        if p.specIndex == specIndex and p.mode and Trim16(p.name) == setName then
            return (NormMode(p.mode) == "DMG") and "Threat" or p.mode
        end
    end
    return nil
end

-- What a tooltip line of a spec you are not playing compares with: every
-- set of that spec, { { name = , mode = }, ... }. A set GSI saved for a mode
-- is scored in that mode ("GSI: Resto AoE" with the AoE weights); any other
-- set in the line's own mode. equipped: the set is fully on now.
function GSI_UI:GetCompareSetsForProfile(specIndex, lineMode)
    local out = {}
    for _, n in ipairs((self:GetSpecSets(specIndex, lineMode))) do
        if SetExists(n) then
            local setID = C_EquipmentSet.GetEquipmentSetID(n)
            local okI, _, _, _, isEquipped = pcall(C_EquipmentSet.GetEquipmentSetInfo, setID)
            out[#out + 1] = {
                name = n,
                mode = SetPresetMode(specIndex, n) or lineMode,
                equipped = (okI and isEquipped) and true or false,
            }
        end
    end
    return out
end

-- The mode a spec is scored in now, as tooltip lines name it.
function GSI_UI:GetCurrentModeFor(specIndex)
    local m = CurrentModeFor(specIndex)
    return (NormMode(m) == "DMG") and "Threat" or m
end

-- Talent group (dual spec) per spec, chosen in Settings:
-- GearSetImproverDB.specTalentGroups["Name-Realm"][specIndex] = 1 or 2.
-- Not chosen = Auto: the only group whose leading tree is the spec's tree.
function GSI_UI:GetSpecTalentGroup(specIndex)
    local all = GearSetImproverDB and GearSetImproverDB.specTalentGroups
    local t = all and all[SpecSetCharKey(GearSetImproverDB.specTalentGroups)]
    local g = t and tonumber(t[tonumber(specIndex) or 0])
    if g == 1 or g == 2 then return g end
    return nil
end

function GSI_SpecSets:GetSpecBoundTalentGroup(specIndex)
    return GSI_UI:GetSpecTalentGroup(specIndex)
end

function GSI_UI:SetSpecTalentGroup(specIndex, group)
    specIndex = tonumber(specIndex)
    if not specIndex then return end
    if not GearSetImproverDB then GearSetImproverDB = {} end
    GearSetImproverDB.specTalentGroups = GearSetImproverDB.specTalentGroups or {}
    local key = SpecSetCharKey(GearSetImproverDB.specTalentGroups)
    GearSetImproverDB.specTalentGroups[key] = GearSetImproverDB.specTalentGroups[key] or {}
    group = tonumber(group)
    GearSetImproverDB.specTalentGroups[key][specIndex] = (group == 1 or group == 2) and group or nil
    -- A Feral group bound to Bear or Cat changes the dual spec macro's icon
    if self.ScheduleDualSpecIconRefresh then self:ScheduleDualSpecIconRefresh(0.2) end
end

-- The talent group that plays specIndex, and how it was found:
-- "bound" (chosen in Settings), "auto" (the only group on the spec's tree),
-- "single" (no dual spec: the active group), or nil with "none" (no group on
-- that tree) / "ambiguous" (both groups on it, e.g. a Cat and a Bear build).
function GSI_UI:ResolveSpecTalentGroup(specIndex)
    local SW = GSI_StatWeights
    if not (SW and SW.GetNumTalentGroups) then return 1, "single" end
    local n = SW:GetNumTalentGroups()
    if n < 2 then return SW:GetActiveTalentGroup(), "single" end
    local bound = self:GetSpecTalentGroup(specIndex)
    if bound and bound <= n then return bound, "bound" end
    local tree = SW:SpecTree(specIndex)
    local found, count = nil, 0
    for g = 1, n do
        if SW:GetTalentGroupLeadTree(g) == tree then
            found = found or g
            count = count + 1
        end
    end
    if count == 1 then return found, "auto" end
    if count == 0 then return nil, "none" end
    return nil, "ambiguous"
end

-- The GSI spec the inactive talent group plays: where the GSI Dual Spec macro
-- goes. A Feral group is Bear or Cat by the group chosen for them in Settings,
-- else by the feral role. nil without dual spec, or while that group's build
-- cannot be read yet.
function GSI_UI:GetDualSpecTarget()
    local SW = GSI_StatWeights
    if not (SW and SW.GetNumTalentGroups) or SW:GetNumTalentGroups() < 2 then return nil end
    local target = (SW:GetActiveTalentGroup() == 1) and 2 or 1
    local lead = SW:GetTalentGroupLeadTree(target)
    if not lead then return nil end
    if PlayerClassKey() ~= "DRUID" then return lead end
    if lead == 1 then return 1 end
    if lead == 3 then return 4 end
    local bear = self:GetSpecTalentGroup(2) == target
    local cat = self:GetSpecTalentGroup(3) == target
    if bear ~= cat then return bear and 2 or 3 end
    return SW:GetFeralSpec()
end

local DUAL_SPEC_MACRO = "GSI Dual Spec"

-- The official icon of the spec the other talent group plays (ClassicData),
-- nil while that is not known.
local function DualSpecTargetIcon()
    local spec = GSI_UI:GetDualSpecTarget()
    local cd = GSI_ClassicData and GSI_ClassicData.Classes and GSI_ClassicData.Classes[PlayerClassKey()]
    local sd = spec and cd and cd.specs and cd.specs[spec]
    return sd and sd.icon
end

function GSI_UI:GetDualSpecIcon()
    return DualSpecTargetIcon() or 134400 -- INV_Misc_QuestionMark
end

-- Points the existing GSI Dual Spec macro at the spec it now switches to
-- (macros cannot be edited in combat: that waits for the combat to end).
local dualIconAfterCombat = false
function GSI_UI:RefreshDualSpecMacroIcon()
    if InCombatLockdown() then
        dualIconAfterCombat = true
        return
    end
    dualIconAfterCombat = false
    local idx = self:FindMacro(DUAL_SPEC_MACRO)
    local want = DualSpecTargetIcon()
    if not (idx and want) then return end
    local name, icon, body = GetMacroInfo(idx)
    if icon ~= want then
        EditMacro(idx, name, want, body)
    end
end

do
    local iconFrame = CreateFrame and CreateFrame("Frame")
    local scheduled = false
    local function Run()
        scheduled = false
        pcall(GSI_UI.RefreshDualSpecMacroIcon, GSI_UI)
    end
    function GSI_UI:ScheduleDualSpecIconRefresh(delay)
        if scheduled then return end
        scheduled = true
        if C_Timer and C_Timer.After then C_Timer.After(delay or 1.5, Run) else Run() end
    end
    if iconFrame then
        iconFrame:SetScript("OnEvent", function(_, event)
            if event == "PLAYER_REGEN_ENABLED" then
                if dualIconAfterCombat then GSI_UI:ScheduleDualSpecIconRefresh(0.5) end
                return
            end
            -- At login the talent groups' builds are read a little later
            GSI_UI:ScheduleDualSpecIconRefresh(event == "PLAYER_ENTERING_WORLD" and 3 or 1.5)
        end)
        for _, ev in ipairs({ "PLAYER_ENTERING_WORLD", "ACTIVE_TALENT_GROUP_CHANGED", "PLAYER_TALENT_UPDATE",
                              "TRAIT_CONFIG_UPDATED", "PLAYER_REGEN_ENABLED" }) do
            pcall(iconFrame.RegisterEvent, iconFrame, ev)
        end
    end
end

-- Tooltips: a line for a spec other than the active one is compared with the
-- Equipment Set tied to that spec instead of the gear worn now (default on).
function GSI_UI:IsCompareSpecSets()
    return not (GearSetImproverDB and GearSetImproverDB.compareSpecSets == false)
end

-- For the tooltip cache key: the option and the sets chosen for each spec
-- (GSI's own sets coming and going reset the cache: EQUIPMENT_SETS_CHANGED).
function GSI_UI:GetSpecSetSignature()
    if not self:IsCompareSpecSets() then return "off" end
    local parts = { "on" }
    for s = 1, 4 do
        parts[#parts + 1] = table.concat(ManualSpecSets(s), "+")
    end
    return table.concat(parts, "/")
end

function GSI_UI:IsSpecSetAutoEquip()
    return not (GearSetImproverDB and GearSetImproverDB.specSetAutoEquip == false)
end

-- The character's Equipment Manager sets: { {id=, name=, icon=, equipped=}, ... }
function GSI_UI:GetEquipmentSetList()
    local list = {}
    if not (C_EquipmentSet and C_EquipmentSet.GetEquipmentSetIDs and C_EquipmentSet.GetEquipmentSetInfo) then
        return list
    end
    local ok, ids = pcall(C_EquipmentSet.GetEquipmentSetIDs)
    if not ok or type(ids) ~= "table" then return list end
    for _, id in ipairs(ids) do
        local okI, name, icon, _, isEquipped = pcall(C_EquipmentSet.GetEquipmentSetInfo, id)
        if okI and name then
            list[#list + 1] = { id = id, name = name, icon = icon, equipped = isEquipped and true or false }
        end
    end
    table.sort(list, function(a, b) return a.name < b.name end)
    return list
end

local pendingSpecSet = nil
local specSetRegenFrame = nil

local function WaitForCombatEnd(setName, specIndex)
    pendingSpecSet = { name = setName, spec = specIndex }
    if not specSetRegenFrame and CreateFrame then
        specSetRegenFrame = CreateFrame("Frame")
        specSetRegenFrame:SetScript("OnEvent", function(self)
            self:UnregisterEvent("PLAYER_REGEN_ENABLED")
            local p = pendingSpecSet
            pendingSpecSet = nil
            if p then GSI_UI:EquipNamedSet(p.name, p.spec) end
        end)
    end
    if specSetRegenFrame then
        specSetRegenFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
    end
end

-- Puts on one Equipment Manager set (after combat when fighting).
-- Returns true when it is on or was just equipped.
function GSI_UI:EquipNamedSet(setName, specIndex, verbose)
    if not (setName and C_EquipmentSet and C_EquipmentSet.GetEquipmentSetID and C_EquipmentSet.UseEquipmentSet) then
        return false
    end
    local setID = C_EquipmentSet.GetEquipmentSetID(setName)
    if not setID then
        print(string.format("|cffff4444[GearSetImprover]|r Equipment Set '|cffffcc00%s|r' no longer exists.", setName))
        return false
    end
    local okI, _, _, _, isEquipped = pcall(C_EquipmentSet.GetEquipmentSetInfo, setID)
    if okI and isEquipped then
        if verbose then
            print(string.format("|cffffcc00[GearSetImprover]|r Equipment Set '|cffffcc00%s|r' is already on.", setName))
        end
        return true
    end
    if InCombatLockdown and InCombatLockdown() then
        WaitForCombatEnd(setName, specIndex)
        print(string.format("|cffffcc00[GearSetImprover]|r Equipment Set '|cffffcc00%s|r' will be equipped when combat ends.", setName))
        return false
    end
    local ok = pcall(C_EquipmentSet.UseEquipmentSet, setID)
    if ok then
        print(string.format("|cff00ff00[GearSetImprover]|r Equipped set '|cffffcc00%s|r' for |cff00ff00%s|r.", setName, SpecDisplayName(specIndex)))
    end
    return ok
end

-- The sets to offer for a spec: { { name = , spec = }, ... }. withTreeMates:
-- also the sets of the specs on the same talent tree (a druid's Feral group
-- can be Cat or Bear; picking a Bear set makes the feral role Bear).
local function SpecSetChoices(specIndex, withTreeMates)
    local specs = { specIndex }
    local SW = GSI_StatWeights
    if withTreeMates and SW and SW.SpecTree then
        local numSpecs = (PlayerClassKey() == "DRUID") and 4 or 3
        local tree = SW:SpecTree(specIndex)
        for s = 1, numSpecs do
            if s ~= specIndex and SW:SpecTree(s) == tree then specs[#specs + 1] = s end
        end
    end
    local choices, seen = {}, {}
    for _, s in ipairs(specs) do
        for _, name in ipairs((GSI_UI:GetSpecSets(s, CurrentModeFor(s)))) do
            if not seen[name] and SetExists(name) then
                seen[name] = true
                choices[#choices + 1] = { name = name, spec = s }
            end
        end
    end
    return choices
end

-- "Which set?" window: one button per set; Esc or "Keep current gear" closes it.
function GSI_UI:ShowSetChooser(specIndex, choices)
    local f = GSI_UI.setChooser
    if not f then
        f = CreateFrame("Frame", "GSI_SetChooser", UIParent, BACKDROP_TEMPLATE)
        f:SetFrameStrata("DIALOG")
        f:SetClampedToScreen(true)
        f:EnableMouse(true)
        f:SetMovable(true)
        f:RegisterForDrag("LeftButton")
        f:SetScript("OnDragStart", f.StartMoving)
        f:SetScript("OnDragStop", f.StopMovingOrSizing)
        f:SetPoint("TOP", UIParent, "TOP", 0, -180)
        SkinFrame(f, GSI_UI.THEME and GSI_UI.THEME.bgCardBottom, true)
        f.title = GSI_UI:CreateText(f, "CARD_TITLE", "")
        f.title:SetPoint("TOP", f, "TOP", 0, -12)
        f.buttons = {}
        f.cancel = CreateFrame("Button", nil, f, BACKDROP_TEMPLATE)
        f.cancel:SetSize(260, 24)
        f.cancel:SetText("Keep current gear")
        SkinButton(f.cancel, nil, false)
        f.cancel:SetScript("OnClick", function() f:Hide() end)
        if UISpecialFrames then table.insert(UISpecialFrames, "GSI_SetChooser") end
        GSI_UI.setChooser = f
    end
    f.title:SetText("Equipment Set for " .. SpecDisplayName(specIndex) .. "?")
    local y = -40
    for i, c in ipairs(choices) do
        local b = f.buttons[i]
        if not b then
            b = CreateFrame("Button", nil, f, BACKDROP_TEMPLATE)
            b:SetSize(260, 26)
            b:SetText(" ")
            SkinButton(b, nil, false)
            b.icon = b:CreateTexture(nil, "ARTWORK")
            b.icon:SetSize(18, 18)
            b.icon:SetPoint("LEFT", b, "LEFT", 6, 0)
            b.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
            f.buttons[i] = b
        end
        local setID = C_EquipmentSet.GetEquipmentSetID(c.name)
        local okI, _, icon, _, isEquipped = pcall(C_EquipmentSet.GetEquipmentSetInfo, setID)
        local label = c.name
        if c.spec ~= specIndex then label = label .. " |cff888888(" .. SpecDisplayName(c.spec) .. ")|r" end
        if okI and isEquipped then label = label .. " |cff00ff00(on)|r" end
        b:SetText(label)
        b.icon:SetTexture((okI and icon) or 134400)
        b:ClearAllPoints()
        b:SetPoint("TOP", f, "TOP", 0, y)
        y = y - 30
        b:SetScript("OnClick", function()
            f:Hide()
            -- A tree mate's set (Bear while Cat is detected) switches the feral role too
            if c.spec ~= specIndex and GSI_StatWeights and GSI_StatWeights.ChooseSpec then
                GSI_StatWeights:ChooseSpec(c.spec)
                pcall(function() GSI_UI:UpdateSpecButton() end)
            end
            GSI_UI:EquipNamedSet(c.name, c.spec, true)
        end)
        b:Show()
    end
    for i = #choices + 1, #f.buttons do f.buttons[i]:Hide() end
    f.cancel:ClearAllPoints()
    f.cancel:SetPoint("TOP", f, "TOP", 0, y - 6)
    f:SetSize(284, -(y - 6) + 24 + 12)
    f:Show()
    if f.Raise then f:Raise() end
end

-- Puts on the gear of a spec: its only set at once, a choice when there are
-- several. quiet: no chat line when it has none. withTreeMates: see
-- SpecSetChoices. Returns ok, and "none" when the spec has no set.
function GSI_UI:EquipSpecSet(specIndex, quiet, verbose, withTreeMates)
    specIndex = tonumber(specIndex)
    if not specIndex then return false, "none" end
    local choices = SpecSetChoices(specIndex, withTreeMates)
    if #choices == 0 then
        if not quiet then
            print(string.format("|cffffcc00[GearSetImprover]|r No Equipment Set for |cff00ff00%s|r yet: GSI saves one when it equips gear for the spec (/gsi equip), or choose sets in the Settings tab.", SpecDisplayName(specIndex)))
        end
        return false, "none"
    end
    if #choices == 1 then
        return self:EquipNamedSet(choices[1].name, choices[1].spec, verbose)
    end
    self:ShowSetChooser(specIndex, choices)
    return true, "asked"
end

-- ---------------------------------------------------------------
-- One button: switch to a spec and put on its gear (/gsi go <spec> [mode]).
-- Switches to the spec's talent group when it is not the active one (dual
-- spec), sets the feral role for Bear / Cat, then puts on the spec's
-- Equipment Set, or the best gear in the bags when no set is tied to it.
-- The group switch is a cast: the gear waits until the new group is active,
-- so the swap cannot interrupt it.
-- ---------------------------------------------------------------
local pendingGo = nil -- { spec, group, expires }

local function PendingGoActive()
    if pendingGo and GetTime and GetTime() > pendingGo.expires then pendingGo = nil end
    return pendingGo ~= nil
end

local function FinishGoToSpec(specIndex)
    local SW = GSI_StatWeights
    SW:InvalidateSpecCache()
    local detected, fromTalents = SW:DetectCurrentSpec()
    -- Talents now play this spec: scores follow them (Auto); otherwise the
    -- spec is pinned, as a pick in the header dropdown does.
    if fromTalents and detected == specIndex and not SW:IsSpecAuto() then
        SW:SetSpecAuto(true)
    else
        SW:ChooseSpec(specIndex)
    end
    pcall(function() GSI_UI:UpdateSpecButton() end)
    pcall(function() GSI_UI:UpdateModeUI() end)
    pcall(function() GSI_UI:UpdateTitleScore() end)
    local _, why = GSI_UI:EquipSpecSet(specIndex, true, true)
    if why == "none" then
        GSI_UI:EquipBestInBag(specIndex)
    end
end

-- After /gsi toggle: scores follow the new group's talents, and the gear of
-- the spec it plays goes on (a choice when there are several sets; the Feral
-- group offers the Cat and the Bear sets).
local function FinishToggle()
    local SW = GSI_StatWeights
    SW:InvalidateSpecCache()
    if not SW:IsSpecAuto() then SW:SetSpecAuto(true) end
    local spec = SW:GetActiveSpecIndex()
    pcall(function() GSI_UI:UpdateSpecButton() end)
    pcall(function() GSI_UI:UpdateModeUI() end)
    pcall(function() GSI_UI:UpdateTitleScore() end)
    local _, why = GSI_UI:EquipSpecSet(spec, true, true, true)
    if why == "none" then
        GSI_UI:EquipBestInBag(spec)
    end
end

-- Dual spec back and forth in one press (/gsi toggle): starts the switch to
-- the other talent group; the gear goes on once it is active.
function GSI_UI:ToggleTalentGroup()
    if InCombatLockdown and InCombatLockdown() then
        print("|cffff0000[GearSetImprover]|r Cannot change specialization or gear while in combat!")
        return
    end
    if PendingGoActive() then
        print("|cffffcc00[GearSetImprover]|r A talent group switch is already under way.")
        return
    end
    local SW = GSI_StatWeights
    if SW:GetNumTalentGroups() < 2 then
        print("|cffffcc00[GearSetImprover]|r Dual specialization is not learned.")
        return
    end
    local target = (SW:GetActiveTalentGroup() == 1) and 2 or 1
    if not SW:ActivateTalentGroup(target) then
        print(string.format("|cffff4444[GearSetImprover]|r Could not switch to talent group %d.", target))
        return
    end
    pendingGo = { spec = nil, group = target, expires = (GetTime and GetTime() or 0) + 30 }
    local _, names = SW:GetTalentGroupPoints(target)
    local lead = SW:GetTalentGroupLeadTree(target)
    local label = (lead and names and names[lead]) or ("group " .. target)
    print(string.format("|cffffcc00[GearSetImprover]|r Switching to talent group %d (|cff00ff00%s|r); the gear goes on when the switch is done.", target, label))
end

function GSI_UI:GoToSpec(specIndex, targetMode)
    specIndex = tonumber(specIndex)
    if not specIndex then return end
    if InCombatLockdown and InCombatLockdown() then
        print("|cffff0000[GearSetImprover]|r Cannot change specialization or gear while in combat!")
        return
    end
    if not GearSetImproverDB then GearSetImproverDB = {} end
    if targetMode then
        if targetMode.type == "tank" then
            GearSetImproverDB.tankMode = targetMode.value
        elseif targetMode.type == "dps" then
            GearSetImproverDB.weightMode = targetMode.value
        end
    end
    pendingGo = nil

    local SW = GSI_StatWeights
    local class = (GSI_ClassicData and GSI_ClassicData.GetPlayerClass and GSI_ClassicData:GetPlayerClass())
        or select(2, UnitClass("player")) or "WARRIOR"
    -- Bear / Cat: the feral role is set first, so the Feral group reads as this spec
    if class == "DRUID" and (specIndex == 2 or specIndex == 3) then
        GearSetImproverDB.feralSpec = specIndex
        SW:InvalidateSpecCache()
    end

    local specName = SpecDisplayName(specIndex)
    local group, why = self:ResolveSpecTalentGroup(specIndex)
    local active = SW:GetActiveTalentGroup()
    if group and group ~= active then
        if SW:ActivateTalentGroup(group) then
            pendingGo = { spec = specIndex, group = group, expires = (GetTime and GetTime() or 0) + 30 }
            print(string.format("|cffffcc00[GearSetImprover]|r Switching to talent group %d for |cff00ff00%s|r; the gear goes on when the switch is done.", group, specName))
            return
        end
        print(string.format("|cffff4444[GearSetImprover]|r Could not switch to talent group %d; equipping the gear for %s only.", group, specName))
    elseif why == "ambiguous" then
        print(string.format("|cffffcc00[GearSetImprover]|r Both talent groups use the tree of %s: choose its group in Settings (Specialization & Equipment Set). Staying in group %d.", specName, active))
    elseif why == "none" then
        print(string.format("|cffffcc00[GearSetImprover]|r No talent group plays %s; only its gear is put on.", specName))
    elseif why == "single" then
        local lead = SW:GetTalentGroupLeadTree(active)
        if lead and lead ~= SW:SpecTree(specIndex) then
            print(string.format("|cffffcc00[GearSetImprover]|r Dual specialization is not learned: only the gear for %s is put on.", specName))
        end
    end
    FinishGoToSpec(specIndex)
end

do
    local goFrame = CreateFrame and CreateFrame("Frame")
    if goFrame then
        local scheduled = false
        local function Resolve()
            scheduled = false
            if not PendingGoActive() then return end
            -- Not switched yet (the cast is still going): a later event retries
            if GSI_StatWeights:GetActiveTalentGroup() ~= pendingGo.group then return end
            local spec = pendingGo.spec
            pendingGo = nil
            if spec then FinishGoToSpec(spec) else FinishToggle() end
        end
        goFrame:SetScript("OnEvent", function()
            if scheduled or not PendingGoActive() then return end
            scheduled = true
            -- After the spec watcher (0.5 s) has seen the new group
            if C_Timer and C_Timer.After then C_Timer.After(1.0, Resolve) else Resolve() end
        end)
        for _, ev in ipairs({ "ACTIVE_TALENT_GROUP_CHANGED", "PLAYER_TALENT_UPDATE", "TRAIT_CONFIG_UPDATED",
                              "PLAYER_SPECIALIZATION_CHANGED", "SPELLS_CHANGED" }) do
            pcall(goFrame.RegisterEvent, goFrame, ev)
        end
    end
end

if GSI_StatWeights and GSI_StatWeights.RegisterSpecChangeCallback then
    GSI_StatWeights:RegisterSpecChangeCallback(function(newSpec)
        -- The other group may read differently now (e.g. the feral role changed)
        GSI_UI:ScheduleDualSpecIconRefresh()
        -- A /gsi go or /gsi toggle switch puts on its gear once the group is active
        if PendingGoActive() then return end
        if not GSI_UI:IsSpecSetAutoEquip() then return end
        -- A switch made elsewhere (talent window, a dual spec button):
        -- the new spec's set, or a choice when there are several
        GSI_UI:EquipSpecSet(newSpec, true, false, true)
    end)
end
