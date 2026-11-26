-- ============================================================
-- GearSetImprover - SpecSets.lua (WoW Forever)
-- Per character (by GUID): the Equipment Sets of each spec and the weights
-- each set turns on, the names of the sets GSI saves, the "which set?"
-- prompt, dual spec (talent group per spec, /gsi go, /gsi toggle) and the
-- set <-> weights links.
-- ============================================================

GSI_SpecSets = GSI_SpecSets or {}
GSI_UI = GSI_UI or {}

local L = GSI_L

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

-- ---------------------------------------------------------------
-- The names of the Equipment Sets GSI saves. A preset's set is named after
-- the preset without GSI's "GSI: " prefix, in the client's language
-- ("GSI: Cat ST" -> "Cat ST", on a Russian client "Кошка"; GSI_SET_NAMES,
-- Locales\ruRU_Macros.lua). Sets saved under the older "GSI: ..." names
-- stay GSI's and are renamed when they can be (MigratePresetSetNames).
-- Macros keep their "GSI: ..." names.
-- ---------------------------------------------------------------

-- At most 16 characters (Equipment Set and macro names), whole UTF-8 letters
local function Trim16(name)
    if type(name) ~= "string" then return name end
    local count = 0
    for pos in name:gmatch("()[%z\1-\127\194-\244][\128-\191]*") do
        count = count + 1
        if count > 16 then return name:sub(1, pos - 1) end
    end
    return name
end

local function SetNameExists(name)
    return name ~= nil and C_EquipmentSet ~= nil and C_EquipmentSet.GetEquipmentSetID ~= nil
        and C_EquipmentSet.GetEquipmentSetID(name) ~= nil
end

-- A set name for an English short name ("Cat ST", or a spec name): the set
-- name table first (short enough for a set name), then the texts
local function LocalSetName(short)
    return Trim16((GSI_SET_NAMES and GSI_SET_NAMES[short]) or L[short])
end

local function OldPresetSetName(p)
    return Trim16(p.name)
end

local function NewPresetSetName(p)
    return LocalSetName((p.name:gsub("^GSI: ", "")))
end

-- The set GSI uses for a preset now: the older "GSI: ..." one while a set by
-- that name is still there, else the new name.
local function PresetSetName(p)
    local old = OldPresetSetName(p)
    if SetNameExists(old) then return old end
    return NewPresetSetName(p)
end

local function IsPresetSetName(p, name)
    return name ~= nil and (name == OldPresetSetName(p) or name == NewPresetSetName(p))
end

-- What the Macros tab calls a preset: the name of its set ("Кошка"), or for
-- a macro without a set its name without "GSI" ("Dual Spec"). The macros
-- themselves keep their "GSI: ..." names, by which GSI finds them.
function GSI_UI:GetPresetTitle(def)
    if not (def and def.name) then return "" end
    if def.noSet then return L[(def.name:gsub("^GSI:? ", ""))] end
    return NewPresetSetName(def)
end

-- The set of a spec that has no preset: old "GSI: <spec>", new "<spec>"
local function OldSpecSetName(specName)
    return Trim16("GSI: " .. specName)
end

local function SpecSetNameNow(specName)
    local old = OldSpecSetName(specName)
    if SetNameExists(old) then return old end
    return LocalSetName(specName)
end

-- For UI_Tab_Macros.lua (GetEquipmentSetNameAndIcon, SaveEquipmentSetForProfile)
GSI_SpecSets.Trim16 = Trim16
GSI_SpecSets.PresetSetName = PresetSetName
GSI_SpecSets.SpecSetNameNow = SpecSetNameNow

-- ---------------------------------------------------------------
-- Equipment Set per spec
-- Each character can tie one of its Equipment Manager sets to each spec
-- (GearSetImproverDB.specSets["Name-Realm"][specIndex] = set name). When the
-- talent-detected spec changes, that set is put on (queued until combat
-- ends), unless GearSetImproverDB.specSetAutoEquip is false.
-- ---------------------------------------------------------------

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
-- [specIndex] is a list of set names (an older single name still reads), an
-- empty list when every set was taken off. nil: Auto, the sets GSI saved.
local function StoredSpecSets(specIndex)
    local all = GearSetImproverDB and GearSetImproverDB.specSets
    local t = all and all[SpecSetCharKey(all)]
    local v = t and t[tonumber(specIndex) or 0]
    if type(v) == "string" then return (v ~= "") and { v } or nil end
    if type(v) ~= "table" then return nil end
    local list = {}
    for _, n in ipairs(v) do
        if type(n) == "string" and n ~= "" then list[#list + 1] = n end
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
            return PresetSetName(p)
        end
    end
    return nil
end

-- The sets GSI has saved for a spec ("Cat ST", "Resto AoE", ...; older
-- "GSI: ..." names too), those that exist, the one for modeVal first.
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
            if p.specIndex == specIndex and not p.noSet then Add(PresetSetName(p)) end
        end
    end
    Add(SpecSetNameNow(SpecDisplayName(specIndex))) -- the name without a preset
    return list
end

-- One of GSI's own sets of the spec (a preset's, old or new name, or the
-- spec's set without a preset), not one of the player's.
function GSI_UI:IsGSISetName(specIndex, setName)
    specIndex = tonumber(specIndex)
    if not setName then return false end
    local presets = GSI_MACRO_PRESETS[PlayerClassKey()]
    if presets then
        for _, p in ipairs(presets) do
            if p.specIndex == specIndex and not p.noSet and IsPresetSetName(p, setName) then return true end
        end
    end
    local specName = SpecDisplayName(specIndex)
    return setName == OldSpecSetName(specName) or setName == LocalSetName(specName)
end

-- The sets of a spec: the ones chosen in Settings, else the ones GSI saved
-- for it. Second return: true when chosen in Settings.
function GSI_UI:GetSpecSets(specIndex, modeVal)
    local stored = StoredSpecSets(specIndex)
    if stored then return stored, true end
    return self:GetAutoSpecSets(specIndex, modeVal), false
end

-- The first set of a spec, or nil (older callers).
function GSI_UI:GetSpecSetName(specIndex)
    return (self:GetSpecSets(specIndex, CurrentModeFor(tonumber(specIndex))))[1]
end

-- nil: back to the sets GSI saved for the spec (Auto). A list, also an
-- empty one, is the spec's own choice.
function GSI_UI:SetSpecSets(specIndex, names)
    specIndex = tonumber(specIndex)
    if not specIndex then return end
    if not GearSetImproverDB then GearSetImproverDB = {} end
    GearSetImproverDB.specSets = GearSetImproverDB.specSets or {}
    local key = SpecSetCharKey(GearSetImproverDB.specSets)
    GearSetImproverDB.specSets[key] = GearSetImproverDB.specSets[key] or {}
    local list = nil
    if type(names) == "table" then
        list = {}
        for _, n in ipairs(names) do list[#list + 1] = n end
    end
    GearSetImproverDB.specSets[key][specIndex] = list
end

function GSI_UI:SetSpecSetName(specIndex, setName)
    self:SetSpecSets(specIndex, (setName and setName ~= "") and { setName } or nil)
end

-- Adds a set to the spec's list, or takes it out. A spec on Auto starts its
-- own list from the sets it has now, so the others stay.
function GSI_UI:ToggleSpecSet(specIndex, setName)
    local list = (self:GetSpecSets(specIndex, CurrentModeFor(tonumber(specIndex))))
    local copy = {}
    for _, n in ipairs(list) do copy[#copy + 1] = n end
    for i, n in ipairs(copy) do
        if n == setName then
            table.remove(copy, i)
            self:SetSpecSets(specIndex, copy)
            return false
        end
    end
    copy[#copy + 1] = setName
    self:SetSpecSets(specIndex, copy)
    return true
end

-- The weights a set turns on when it goes on (weightMode ST / AOE, tank
-- specs tankMode Survival / DMG). Chosen in Settings per spec and set:
-- GearSetImproverDB.specSetModes["Name-Realm"][specIndex][setName] = mode,
-- false = none (the header's mode stays). Not chosen: the mode GSI saved the
-- set for ("GSI: Resto AoE" = AOE); your own sets have none.
local CANON_MODE = { ST = "ST", AOE = "AOE", SURVIVAL = "Survival", DMG = "DMG" }
local function CanonMode(m)
    return m and CANON_MODE[NormMode(m)] or nil
end

local function StoredSetModes(specIndex, create)
    specIndex = tonumber(specIndex)
    if not specIndex then return nil end
    if create and not GearSetImproverDB then GearSetImproverDB = {} end
    local db = GearSetImproverDB
    if not db then return nil end
    local key = SpecSetCharKey(db.specSetModes)
    if create then
        db.specSetModes = db.specSetModes or {}
        db.specSetModes[key] = db.specSetModes[key] or {}
        db.specSetModes[key][specIndex] = db.specSetModes[key][specIndex] or {}
    end
    local all = db.specSetModes and db.specSetModes[key]
    return all and all[specIndex]
end

local function PresetModeOf(specIndex, setName)
    local presets = GSI_MACRO_PRESETS[PlayerClassKey()]
    if not presets then return nil end
    for _, p in ipairs(presets) do
        if p.specIndex == specIndex and p.mode and IsPresetSetName(p, setName) then
            return CanonMode(p.mode)
        end
    end
    return nil
end

-- The two modes a spec is scored in: { "ST", "AOE" } or { "Survival", "DMG" }.
function GSI_UI:GetSpecModes(specIndex)
    specIndex = tonumber(specIndex)
    local out = {}
    if self.GetClassProfiles then
        for _, p in ipairs(self:GetClassProfiles(PlayerClassKey()) or {}) do
            if p.specIndex == specIndex then out[#out + 1] = CanonMode(p.mode) end
        end
    end
    if #out == 0 then out = { "ST", "AOE" } end
    return out
end

local MODE_LABELS = { ST = "Single Target", AOE = "AoE / Trash", Survival = "Survival", DMG = "Threat / DPS" }
function GSI_UI:GetModeLabel(mode)
    return mode and L[MODE_LABELS[mode] or mode] or nil
end

-- The set's mode ("ST", "AOE", "Survival", "DMG"), or nil: it leaves the
-- mode as it is.
function GSI_UI:GetSetMode(specIndex, setName)
    specIndex = tonumber(specIndex)
    local t = StoredSetModes(specIndex)
    local m = t and t[setName]
    if m == false then return nil end
    if m then return CanonMode(m) end
    return PresetModeOf(specIndex, setName)
end

-- Gives the set a mode ("ST", "AOE", "Survival", "DMG"), or none (nil: it
-- leaves the weights as they are).
function GSI_UI:SetSetMode(specIndex, setName, mode)
    specIndex = tonumber(specIndex)
    if not (specIndex and setName) then return end
    mode = CanonMode(mode)
    local preset = PresetModeOf(specIndex, setName)
    local t = StoredSetModes(specIndex, true)
    if mode == preset then
        t[setName] = nil
    elseif mode == nil then
        t[setName] = false
    else
        t[setName] = mode
    end
    -- Tooltip lines of other specs are scored in the set's mode
    if GSI_TooltipHook and GSI_TooltipHook.RefreshShownTooltips then
        pcall(GSI_TooltipHook.RefreshShownTooltips, GSI_TooltipHook)
    end
end

-- Next mode for the set: the spec's first mode, its second, none, again.
function GSI_UI:CycleSetMode(specIndex, setName)
    specIndex = tonumber(specIndex)
    if not (specIndex and setName) then return nil end
    local modes = self:GetSpecModes(specIndex)
    local cur = self:GetSetMode(specIndex, setName)
    local nextMode
    if cur == nil then
        nextMode = modes[1]
    elseif cur == modes[1] then
        nextMode = modes[2]
    else
        nextMode = nil
    end
    self:SetSetMode(specIndex, setName, nextMode)
    return nextMode
end

-- Sets GSI saved under the older "GSI: ..." names get their new names
-- ("GSI: Cat ST" -> "Кошка" on a Russian client), unless a set by the new
-- name is already there (a set of the player's own: the old one then keeps
-- its name and stays GSI's). The spec set lists and set modes of this
-- character follow the rename. Out of combat only; runs again later.
local function MigratePresetSetNames()
    if not (C_EquipmentSet and C_EquipmentSet.ModifyEquipmentSet and C_EquipmentSet.GetEquipmentSetID) then return end
    if InCombatLockdown and InCombatLockdown() then return end
    local pairsToRename = {}
    for _, list in ipairs({ GSI_MACRO_PRESETS.UNIVERSAL or {}, GSI_MACRO_PRESETS[PlayerClassKey()] or {} }) do
        for _, p in ipairs(list) do
            if not p.noSet then
                pairsToRename[#pairsToRename + 1] = { old = OldPresetSetName(p), new = NewPresetSetName(p), spec = p.specIndex }
            end
        end
    end
    local numSpecs = (PlayerClassKey() == "DRUID") and 4 or 3
    for s = 1, numSpecs do
        local specName = SpecDisplayName(s)
        pairsToRename[#pairsToRename + 1] = { old = OldSpecSetName(specName), new = LocalSetName(specName), spec = s }
    end

    local renamed = {}
    for _, r in ipairs(pairsToRename) do
        if r.old ~= r.new and not renamed[r.old] and SetNameExists(r.old) and not SetNameExists(r.new) then
            local setID = C_EquipmentSet.GetEquipmentSetID(r.old)
            local okI, _, icon = pcall(C_EquipmentSet.GetEquipmentSetInfo, setID)
            local ok = pcall(C_EquipmentSet.ModifyEquipmentSet, setID, r.new, (okI and icon) or nil)
            if ok and SetNameExists(r.new) then renamed[r.old] = r.new end
        end
    end
    if not next(renamed) then return end

    -- This character's spec set lists and set modes use the new names
    local db = GearSetImproverDB
    local key = SpecSetCharKey(db and db.specSets)
    local lists = db and db.specSets and db.specSets[key]
    if type(lists) == "table" then
        for s, list in pairs(lists) do
            if type(list) == "string" then
                lists[s] = renamed[list] or list
            elseif type(list) == "table" then
                for i, n in ipairs(list) do list[i] = renamed[n] or n end
            end
        end
    end
    local modesKey = SpecSetCharKey(db and db.specSetModes)
    local modes = db and db.specSetModes and db.specSetModes[modesKey]
    if type(modes) == "table" then
        for _, t in pairs(modes) do
            if type(t) == "table" then
                for old, new in pairs(renamed) do
                    if t[old] ~= nil and t[new] == nil then t[new] = t[old] end
                    t[old] = nil
                end
            end
        end
    end

    local shown = {}
    for old, new in pairs(renamed) do shown[#shown + 1] = old .. " -> " .. new end
    table.sort(shown)
    print(string.format(L["|cffffcc00[GearSetImprover]|r Equipment Sets renamed: %s."], table.concat(shown, ", ")))
    if GSI_TooltipHook and GSI_TooltipHook.RefreshShownTooltips then
        pcall(GSI_TooltipHook.RefreshShownTooltips, GSI_TooltipHook)
    end
    if GSI_UI.RefreshSpecSetRows then pcall(GSI_UI.RefreshSpecSetRows) end
end

do
    local renameFrame = CreateFrame and CreateFrame("Frame")
    if renameFrame then
        local queued = false
        local function Run()
            queued = false
            pcall(MigratePresetSetNames)
        end
        renameFrame:SetScript("OnEvent", function(_, event)
            if queued then return end
            queued = true
            -- The sets are known a moment after login
            C_Timer.After(event == "PLAYER_ENTERING_WORLD" and 3 or 1, Run)
        end)
        for _, ev in ipairs({ "PLAYER_ENTERING_WORLD", "EQUIPMENT_SETS_CHANGED", "PLAYER_REGEN_ENABLED" }) do
            pcall(renameFrame.RegisterEvent, renameFrame, ev)
        end
    end
end

-- The set's mode as tooltip lines name it ("ST", "AOE", "Survival", "Threat").
local function SetLineMode(specIndex, setName)
    local m = GSI_UI:GetSetMode(specIndex, setName)
    if m == "DMG" then return "Threat" end
    return m
end

-- What a tooltip line of a spec you are not playing compares with: every
-- set of that spec, { { name = , mode = }, ... }. A set with a mode (Settings,
-- or the one GSI saved it for) is scored in that mode ("GSI: Resto AoE" with
-- the AoE weights); any other set in the line's own mode. equipped: the set
-- is fully on now.
function GSI_UI:GetCompareSetsForProfile(specIndex, lineMode)
    local out = {}
    for _, n in ipairs((self:GetSpecSets(specIndex, lineMode))) do
        if SetExists(n) then
            local setID = C_EquipmentSet.GetEquipmentSetID(n)
            local okI, _, _, _, isEquipped = pcall(C_EquipmentSet.GetEquipmentSetInfo, setID)
            out[#out + 1] = {
                name = n,
                mode = SetLineMode(specIndex, n) or lineMode,
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
    local t = all and all[SpecSetCharKey(all)]
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
        local stored = StoredSpecSets(s)
        parts[#parts + 1] = stored and ("=" .. table.concat(stored, "+")) or "auto"
    end
    return table.concat(parts, "/")
end

function GSI_UI:IsSpecSetAutoEquip()
    return not (GearSetImproverDB and GearSetImproverDB.specSetAutoEquip == false)
end

-- A set put on turns its weights on (GearSetImproverDB.setChangesWeights,
-- default on).
function GSI_UI:IsSetChangesWeights()
    return not (GearSetImproverDB and GearSetImproverDB.setChangesWeights == false)
end

-- Weights picked in GSI (the header's mode, /gsi mode) put on the spec's set
-- for them (GearSetImproverDB.weightsEquipSet, default on).
function GSI_UI:IsWeightsEquipSet()
    return not (GearSetImproverDB and GearSetImproverDB.weightsEquipSet == false)
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

-- A set with a mode (Settings, or the one GSI saved it for: "GSI: Resto
-- AoE") turns that mode's weights on, as the mode dropdown in the header
-- does, when it belongs to the spec played: the modes are shared by all the
-- specs, so a set of another spec leaves them. Sets without a mode leave it.
local function ApplySetWeightMode(specIndex, setName)
    if not GSI_UI:IsSetChangesWeights() then return end
    specIndex = tonumber(specIndex)
    local m = GSI_UI:GetSetMode(specIndex, setName)
    if not m then return end
    local SW = GSI_StatWeights
    if SW and SW.GetActiveSpecIndex and SW:GetActiveSpecIndex() ~= specIndex then return end
    if not GearSetImproverDB then GearSetImproverDB = {} end
    local db = GearSetImproverDB
    local key, value, current
    if m == "Survival" or m == "DMG" then
        key, value = "tankMode", m
        current = db.tankMode or "Survival"
    else
        key, value = "weightMode", m
        current = db.weightMode or "ST"
    end
    if NormMode(current) == NormMode(value) then return end
    db[key] = value
    if GSI_StatWeights and GSI_StatWeights.RefreshScores then GSI_StatWeights:RefreshScores() end
    print(string.format(L["|cffffcc00[GearSetImprover]|r Weights: |cff00ff00%s|r (set '|cffffcc00%s|r')."],
        L[MODE_LABELS[value] or value], setName))
end

-- After the weights were changed in GSI (the header's mode or spec, /gsi
-- mode, /gsi spec): the spec's set for the mode now on goes on (the first
-- one with that mode; after combat when fighting). anySet (a spec picked):
-- without a set for the mode, the spec's set as on a spec change (its only
-- one, or the "which set?" prompt). specIndex: the spec played by default.
function GSI_UI:EquipSetForCurrentMode(specIndex, anySet)
    if not self:IsWeightsEquipSet() then return end
    local SW = GSI_StatWeights
    local spec = tonumber(specIndex) or (SW and SW.GetActiveSpecIndex and SW:GetActiveSpecIndex())
    if not spec then return end
    local modeNow = CurrentModeFor(spec)
    local want = CanonMode(modeNow)
    for _, name in ipairs((self:GetSpecSets(spec, modeNow))) do
        if SetExists(name) and self:GetSetMode(spec, name) == want then
            self:EquipNamedSet(name, spec, false)
            return
        end
    end
    if anySet then self:EquipSpecSet(spec, true, false) end
end

-- Puts on one Equipment Manager set (after combat when fighting) and turns
-- on the weights of the mode it was saved for. Returns true when it is on
-- or was just equipped.
function GSI_UI:EquipNamedSet(setName, specIndex, verbose)
    if not (setName and C_EquipmentSet and C_EquipmentSet.GetEquipmentSetID and C_EquipmentSet.UseEquipmentSet) then
        return false
    end
    local setID = C_EquipmentSet.GetEquipmentSetID(setName)
    if not setID then
        print(string.format(L["|cffff4444[GearSetImprover]|r Equipment Set '|cffffcc00%s|r' no longer exists."], setName))
        return false
    end
    ApplySetWeightMode(specIndex, setName)
    local okI, _, _, _, isEquipped = pcall(C_EquipmentSet.GetEquipmentSetInfo, setID)
    if okI and isEquipped then
        if verbose then
            print(string.format(L["|cffffcc00[GearSetImprover]|r Equipment Set '|cffffcc00%s|r' is already on."], setName))
        end
        return true
    end
    if InCombatLockdown and InCombatLockdown() then
        WaitForCombatEnd(setName, specIndex)
        print(string.format(L["|cffffcc00[GearSetImprover]|r Equipment Set '|cffffcc00%s|r' will be equipped when combat ends."], setName))
        return false
    end
    local ok = pcall(C_EquipmentSet.UseEquipmentSet, setID)
    if ok then
        print(string.format(L["|cff00ff00[GearSetImprover]|r Equipped set '|cffffcc00%s|r' for |cff00ff00%s|r."], setName, L[SpecDisplayName(specIndex)]))
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

-- "Which set?" prompt in the upgrade toast's look (GSI_UpgradeToast.Style):
-- the spec's icon and name, one row per set, the close button or Esc keeps
-- the gear on. It opens under the toast so both stay readable.
local CHOOSER_HEADER_H = 54
local CHOOSER_ROW_H = 24
local CHOOSER_ROW_STEP = 27
local CHOOSER_FOOTER_H = 26

local function SpecIcon(specIndex)
    local cd = GSI_ClassicData and GSI_ClassicData.Classes and GSI_ClassicData.Classes[PlayerClassKey()]
    local sd = cd and cd.specs and cd.specs[specIndex]
    return (sd and sd.icon) or 134400
end

local function CreateChooserRow(f, S)
    local b = CreateFrame("Button", nil, f)
    b:SetHeight(CHOOSER_ROW_H)
    b:RegisterForClicks("LeftButtonUp")

    local bg = b:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(b)
    bg:SetColorTexture(0.10, 0.12, 0.17, 0.75)

    local hl = b:CreateTexture(nil, "ARTWORK", nil, -2)
    hl:SetTexture(S.TEXTURE_FILE)
    hl:SetTexCoord(136/1024, 264/1024, 72/512, 104/512)
    hl:SetAllPoints(b)
    hl:SetAlpha(0)

    b.icon = b:CreateTexture(nil, "ARTWORK")
    b.icon:SetSize(18, 18)
    b.icon:SetPoint("LEFT", b, "LEFT", 4, 0)
    b.icon:SetTexCoord(0.0625, 0.9375, 0.0625, 0.9375)
    local border = b:CreateTexture(nil, "OVERLAY")
    border:SetAllPoints(b.icon)
    border:SetTexture(S.ICON_BORDER_FILE)
    border:SetVertexColor(0.55, 0.60, 0.70, 1)

    b.tag = b:CreateFontString(nil, "OVERLAY")
    S.ApplyFont(b.tag, 9.5, "OUTLINE", true)
    b.tag:SetPoint("RIGHT", b, "RIGHT", -8, 0)
    b.tag:SetJustifyH("RIGHT")

    b.label = b:CreateFontString(nil, "OVERLAY")
    S.ApplyFont(b.label, 11.5, "OUTLINE", false)
    b.label:SetPoint("LEFT", b.icon, "RIGHT", 7, 0)
    b.label:SetPoint("RIGHT", b.tag, "LEFT", -6, 0)
    b.label:SetJustifyH("LEFT")
    b.label:SetWordWrap(false)
    b.label:SetTextColor(0.94, 0.95, 0.97, 1)

    b:SetScript("OnEnter", function()
        hl:SetAlpha(0.65)
        b.label:SetTextColor(1, 1, 1, 1)
    end)
    b:SetScript("OnLeave", function()
        hl:SetAlpha(0)
        b.label:SetTextColor(0.94, 0.95, 0.97, 1)
    end)
    return b
end

local function CreateSetChooser(S)
    local f = CreateFrame("Frame", "GSI_SetChooser", UIParent)
    f:SetFrameStrata("DIALOG")
    f:SetClampedToScreen(true)
    f:EnableMouse(true)
    f:SetMovable(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        self.userMoved = true
    end)
    S.BuildCardBackground(f, S.WIDTH, 120)
    local cr, cg, cb = GSI_UI:GetClassColor()
    f:SetQualityColor(cr, cg, cb)

    local iconBox = CreateFrame("Frame", nil, f)
    iconBox:SetSize(38, 38)
    iconBox:SetPoint("TOPLEFT", f, "TOPLEFT", 11, -9)
    local glow = iconBox:CreateTexture(nil, "BACKGROUND", nil, -1)
    glow:SetSize(54, 54)
    glow:SetPoint("CENTER", iconBox, "CENTER", 0, 0)
    glow:SetTexture(S.ICON_OVERLAY_FILE)
    glow:SetBlendMode("ADD")
    glow:SetAlpha(0.32)
    f.icon = iconBox:CreateTexture(nil, "ARTWORK")
    f.icon:SetAllPoints(iconBox)
    f.icon:SetTexCoord(0.0625, 0.9375, 0.0625, 0.9375)
    local iconBorder = iconBox:CreateTexture(nil, "OVERLAY")
    iconBorder:SetAllPoints(iconBox)
    iconBorder:SetTexture(S.ICON_BORDER_FILE)
    iconBorder:SetVertexColor(cr, cg, cb, 1)

    f.close = S.CreateCloseButton(f, function() f:Hide() end)
    f.close:SetPoint("TOPRIGHT", f, "TOPRIGHT", -6, -6)

    local headerTag = f:CreateFontString(nil, "OVERLAY")
    S.ApplyFont(headerTag, 9, "OUTLINE", true)
    headerTag:SetPoint("TOPLEFT", f, "TOPLEFT", 57, -11)
    headerTag:SetPoint("RIGHT", f.close, "LEFT", -6, 0)
    headerTag:SetJustifyH("LEFT")
    headerTag:SetWordWrap(false)
    headerTag:SetTextColor(0.68, 0.72, 0.80, 1)
    headerTag:SetText(L["CHOOSE EQUIPMENT SET"])

    f.title = f:CreateFontString(nil, "OVERLAY")
    S.ApplyFont(f.title, 12.5, "OUTLINE", false)
    f.title:SetPoint("TOPLEFT", f, "TOPLEFT", 57, -27)
    f.title:SetPoint("RIGHT", f, "RIGHT", -10, 0)
    f.title:SetJustifyH("LEFT")
    f.title:SetWordWrap(false)

    -- Footer: what a click does, and the way out
    local hint = f:CreateFontString(nil, "OVERLAY")
    S.ApplyFont(hint, 9.5, "OUTLINE", true)
    hint:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 12, 9)
    hint:SetTextColor(0.55, 0.60, 0.68, 1)
    hint:SetText(L["Click a set to put it on"])

    local keep = CreateFrame("Button", nil, f)
    keep:SetHeight(14)
    keep:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -9, 8)
    local capBg = keep:CreateTexture(nil, "BACKGROUND")
    capBg:SetHeight(13)
    capBg:SetPoint("LEFT", keep, "LEFT", 0, 0)
    capBg:SetColorTexture(0.16, 0.19, 0.26, 0.92)
    local key = keep:CreateFontString(nil, "OVERLAY")
    S.ApplyFont(key, 8.5, "OUTLINE", false)
    key:SetPoint("CENTER", capBg, "CENTER", 0, 0)
    key:SetTextColor(0.95, 0.96, 0.98, 1)
    key:SetText("Esc")
    local keepLabel = keep:CreateFontString(nil, "OVERLAY")
    S.ApplyFont(keepLabel, 9.5, "OUTLINE", true)
    keepLabel:SetPoint("LEFT", capBg, "RIGHT", 4, 0)
    keepLabel:SetTextColor(0.72, 0.76, 0.84, 1)
    keepLabel:SetText(L["Keep current gear"])
    -- Widths once the font is there (it can report 0 before its first draw)
    function f:SizeFooter()
        local kw = key:GetStringWidth() or 0
        local lw = keepLabel:GetStringWidth() or 0
        if kw <= 0 then kw = 16 end
        if lw <= 0 then lw = 90 end
        capBg:SetWidth(kw + 6)
        keep:SetWidth(kw + 6 + 4 + lw + 2)
    end
    keep:SetScript("OnEnter", function() keepLabel:SetTextColor(1, 1, 1, 1) end)
    keep:SetScript("OnLeave", function() keepLabel:SetTextColor(0.72, 0.76, 0.84, 1) end)
    keep:SetScript("OnClick", function() f:Hide() end)

    f.rows = {}
    if UISpecialFrames then table.insert(UISpecialFrames, "GSI_SetChooser") end
    f:Hide()
    return f
end

function GSI_UI:ShowSetChooser(specIndex, choices)
    local S = GSI_UpgradeToast and GSI_UpgradeToast.Style
    if not S then return end
    local f = GSI_UI.setChooser
    if not f then
        f = CreateSetChooser(S)
        GSI_UI.setChooser = f
    end

    f.icon:SetTexture(SpecIcon(specIndex))
    local _, _, _, hex = GSI_UI:GetClassColor()
    f.title:SetText(string.format(L["|cff%s%s|r: which set?"], hex, L[SpecDisplayName(specIndex)]))
    f:SizeFooter()

    local y = -CHOOSER_HEADER_H
    for i, c in ipairs(choices) do
        local b = f.rows[i] or CreateChooserRow(f, S)
        f.rows[i] = b
        local setID = C_EquipmentSet.GetEquipmentSetID(c.name)
        local okI, _, icon, _, isEquipped = pcall(C_EquipmentSet.GetEquipmentSetInfo, setID)
        b.icon:SetTexture((okI and icon) or 134400)
        b.label:SetText(c.name)
        if okI and isEquipped then
            b.tag:SetText(L["ON"])
            b.tag:SetTextColor(0.25, 1.0, 0.62, 1)
        elseif c.spec ~= specIndex then
            -- A tree mate's set (Bear while Cat is detected)
            b.tag:SetText(L[SpecDisplayName(c.spec)])
            b.tag:SetTextColor(0.62, 0.66, 0.74, 1)
        else
            -- The weights the set turns on
            local m = GSI_UI:GetSetMode(c.spec, c.name)
            local ml = m and GSI_UI:GetModeLabel(m)
            -- string.upper does not upper-case Cyrillic: the Russian label stays as it is
            b.tag:SetText(ml and ((GSI_LOCALE == "ruRU") and ml or string.upper(ml)) or "")
            b.tag:SetTextColor(0.62, 0.66, 0.74, 1)
        end
        b:ClearAllPoints()
        b:SetPoint("TOPLEFT", f, "TOPLEFT", 12, y)
        b:SetPoint("RIGHT", f, "RIGHT", -10, 0)
        y = y - CHOOSER_ROW_STEP
        b:SetScript("OnClick", function()
            f:Hide()
            -- A tree mate's set switches the feral role too
            if c.spec ~= specIndex and GSI_StatWeights and GSI_StatWeights.ChooseSpec then
                GSI_StatWeights:ChooseSpec(c.spec)
                pcall(function() GSI_UI:UpdateSpecButton() end)
            end
            GSI_UI:EquipNamedSet(c.name, c.spec, true)
        end)
        b:Show()
    end
    for i = #choices + 1, #f.rows do f.rows[i]:Hide() end

    local height = CHOOSER_HEADER_H + #choices * CHOOSER_ROW_STEP + CHOOSER_FOOTER_H
    f:SetSize(S.WIDTH, height)
    if f.slateBg then
        f.slateBg:SetTexCoord(0.5, 0.5 + 0.5 * math.min(1, S.WIDTH / 512), 0, math.min(1, height / 512))
    end

    -- Under the upgrade toast, unless the player dragged the prompt elsewhere
    if not f.userMoved then
        f:ClearAllPoints()
        local toast = _G.GSI_UpgradeToastFrame
        if toast then
            f:SetPoint("TOP", toast, "BOTTOM", 0, -8)
        else
            f:SetPoint("TOP", UIParent, "TOP", 0, S.DEFAULT_Y - S.HEIGHT - 8)
        end
    end
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
            print(string.format(L["|cffffcc00[GearSetImprover]|r No Equipment Set for |cff00ff00%s|r yet: GSI saves one when it equips gear for the spec (/gsi equip), or choose sets in the Settings tab."], L[SpecDisplayName(specIndex)]))
        end
        return false, "none"
    end
    if #choices == 1 then
        return self:EquipNamedSet(choices[1].name, choices[1].spec, verbose)
    end
    self:ShowSetChooser(specIndex, choices)
    return true, "asked"
end

-- Any set put on (the character pane's Equipment Manager, another addon,
-- GSI itself) turns its weights on (Settings: a set turns its weights on):
-- the spec the set belongs to (the spec played first, then Bear/Cat, then
-- the other specs) becomes the spec scored, and the set's mode goes on.
-- That spec is the one your talents play: back to Auto; otherwise it is
-- picked as in the header dropdown.
local function SpecOfSet(setName, active)
    for _, c in ipairs(SpecSetChoices(active, true)) do
        if c.name == setName then return c.spec end
    end
    local numSpecs = (PlayerClassKey() == "DRUID") and 4 or 3
    for s = 1, numSpecs do
        if s ~= active then
            for _, n in ipairs((GSI_UI:GetSpecSets(s, CurrentModeFor(s)))) do
                if n == setName then return s end
            end
        end
    end
    return nil
end

do
    local swapFrame = CreateFrame and CreateFrame("Frame")
    if swapFrame then
        swapFrame:SetScript("OnEvent", function(_, _, result, setID)
            if not GSI_UI:IsSetChangesWeights() then return end
            if not (result and setID and C_EquipmentSet and C_EquipmentSet.GetEquipmentSetInfo) then return end
            local okI, name = pcall(C_EquipmentSet.GetEquipmentSetInfo, setID)
            if not okI or not name then return end
            local SW = GSI_StatWeights
            local active = SW and SW.GetActiveSpecIndex and SW:GetActiveSpecIndex()
            if not active then return end
            local spec = SpecOfSet(name, active)
            if not spec then return end
            if spec ~= active then
                SW:InvalidateSpecCache()
                local detected, fromTalents = SW:DetectCurrentSpec()
                if fromTalents and detected == spec and not SW:IsSpecAuto() then
                    SW:SetSpecAuto(true)
                else
                    SW:ChooseSpec(spec)
                end
                pcall(function() GSI_UI:UpdateSpecButton() end)
                pcall(function() GSI_UI:UpdateModeUI() end)
                print(string.format(L["|cffffcc00[GearSetImprover]|r Specialization: |cff00ff00%s|r (set '|cffffcc00%s|r')."],
                    L[SpecDisplayName(spec)], name))
            end
            ApplySetWeightMode(spec, name)
        end)
        pcall(swapFrame.RegisterEvent, swapFrame, "EQUIPMENT_SWAP_FINISHED")
    end
end

-- ---------------------------------------------------------------
-- One button: switch to a spec and put on its gear (/gsi go <spec> [mode]).
-- Switches to the spec's talent group when it is not the active one (dual
-- spec), sets the feral role for Bear / Cat, then puts on the spec's
-- Equipment Set, or the best gear in the bags when no set is tied to it.
-- The group switch is a cast: the gear waits until the new group is active,
-- so the swap cannot interrupt it.
-- ---------------------------------------------------------------
local pendingGo = nil -- { spec, group, started, expires, castGUID }

local function PendingGoActive()
    if pendingGo and GetTime and GetTime() > pendingGo.expires then pendingGo = nil end
    return pendingGo ~= nil
end

local function StartPendingGo(specIndex, group)
    local now = (GetTime and GetTime()) or 0
    pendingGo = { spec = specIndex, group = group, started = now, expires = now + 30 }
end

-- A switch is under way while its cast runs, for a moment after it was asked
-- for (the cast has not started yet), and once the group is active until its
-- gear goes on. An interrupted or failed cast is none of these: the pending
-- switch is dropped, so the next press starts a new one.
local function SwitchUnderWay()
    if not PendingGoActive() then return false end
    if GSI_StatWeights:GetActiveTalentGroup() == pendingGo.group then return true end
    if type(UnitCastingInfo) == "function" and UnitCastingInfo("player") then return true end
    if type(UnitChannelInfo) == "function" and UnitChannelInfo("player") then return true end
    if GetTime and GetTime() - (pendingGo.started or 0) < 1.5 then return true end
    pendingGo = nil
    return false
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
        print(L["|cffff0000[GearSetImprover]|r Cannot change specialization or gear while in combat!"])
        return
    end
    if SwitchUnderWay() then
        print(L["|cffffcc00[GearSetImprover]|r A talent group switch is already under way."])
        return
    end
    local SW = GSI_StatWeights
    if SW:GetNumTalentGroups() < 2 then
        print(L["|cffffcc00[GearSetImprover]|r Dual specialization is not learned."])
        return
    end
    local target = (SW:GetActiveTalentGroup() == 1) and 2 or 1
    if not SW:ActivateTalentGroup(target) then
        print(string.format(L["|cffff4444[GearSetImprover]|r Could not switch to talent group %d."], target))
        return
    end
    StartPendingGo(nil, target)
    local _, names = SW:GetTalentGroupPoints(target)
    local lead = SW:GetTalentGroupLeadTree(target)
    local label = (lead and names and names[lead]) or string.format(L["group %d"], target)
    print(string.format(L["|cffffcc00[GearSetImprover]|r Switching to talent group %d (|cff00ff00%s|r); the gear goes on when the switch is done."], target, label))
end

function GSI_UI:GoToSpec(specIndex, targetMode)
    specIndex = tonumber(specIndex)
    if not specIndex then return end
    if InCombatLockdown and InCombatLockdown() then
        print(L["|cffff0000[GearSetImprover]|r Cannot change specialization or gear while in combat!"])
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

    local specName = L[SpecDisplayName(specIndex)]
    local group, why = self:ResolveSpecTalentGroup(specIndex)
    local active = SW:GetActiveTalentGroup()
    if group and group ~= active then
        if SW:ActivateTalentGroup(group) then
            StartPendingGo(specIndex, group)
            print(string.format(L["|cffffcc00[GearSetImprover]|r Switching to talent group %d for |cff00ff00%s|r; the gear goes on when the switch is done."], group, specName))
            return
        end
        print(string.format(L["|cffff4444[GearSetImprover]|r Could not switch to talent group %d; equipping the gear for %s only."], group, specName))
    elseif why == "ambiguous" then
        print(string.format(L["|cffffcc00[GearSetImprover]|r Both talent groups use the tree of %s: choose its group in Settings (Specialization & Equipment Set). Staying in group %d."], specName, active))
    elseif why == "none" then
        print(string.format(L["|cffffcc00[GearSetImprover]|r No talent group plays %s; only its gear is put on."], specName))
    elseif why == "single" then
        local lead = SW:GetTalentGroupLeadTree(active)
        if lead and lead ~= SW:SpecTree(specIndex) then
            print(string.format(L["|cffffcc00[GearSetImprover]|r Dual specialization is not learned: only the gear for %s is put on."], specName))
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

    -- The switch cast: the first cast the player starts right after the switch
    -- was asked for. When that cast is interrupted or fails before the group
    -- changes, the switch is dropped at once (and the next press retries).
    local castFrame = CreateFrame and CreateFrame("Frame")
    if castFrame and castFrame.RegisterUnitEvent then
        castFrame:SetScript("OnEvent", function(_, event, _, castGUID)
            if not PendingGoActive() then return end
            if event == "UNIT_SPELLCAST_START" or event == "UNIT_SPELLCAST_CHANNEL_START" then
                if not pendingGo.castGUID and GetTime and GetTime() - (pendingGo.started or 0) < 1.5 then
                    pendingGo.castGUID = castGUID or true
                end
                return
            end
            if not pendingGo.castGUID then return end
            if pendingGo.castGUID == true then
                -- No cast GUIDs on this client: another spell failing says nothing
                if event == "UNIT_SPELLCAST_FAILED" then return end
            elseif castGUID ~= pendingGo.castGUID then
                return
            end
            if GSI_StatWeights:GetActiveTalentGroup() == pendingGo.group then return end
            pendingGo = nil
            print(L["|cffffcc00[GearSetImprover]|r Talent group switch interrupted; press the macro again to retry."])
        end)
        for _, ev in ipairs({ "UNIT_SPELLCAST_START", "UNIT_SPELLCAST_CHANNEL_START",
                              "UNIT_SPELLCAST_INTERRUPTED", "UNIT_SPELLCAST_FAILED" }) do
            pcall(castFrame.RegisterUnitEvent, castFrame, ev, "player")
        end
    end
end

if GSI_StatWeights and GSI_StatWeights.RegisterSpecChangeCallback then
    GSI_StatWeights:RegisterSpecChangeCallback(function(newSpec)
        -- The other group may read differently now (e.g. the feral role changed)
        GSI_UI:ScheduleDualSpecIconRefresh()
        -- A /gsi go or /gsi toggle switch puts on its gear once the group is active
        if SwitchUnderWay() then return end
        if not GSI_UI:IsSpecSetAutoEquip() then return end
        -- A switch made elsewhere (talent window, a dual spec button):
        -- the new spec's set, or a choice when there are several
        GSI_UI:EquipSpecSet(newSpec, true, false, true)
    end)
end
