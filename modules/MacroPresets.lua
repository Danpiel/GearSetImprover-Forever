-- ============================================================
-- GearSetImprover -- MacroPresets.lua (WoW Forever)
-- The macro presets of every class, the macros made from them, and
-- /gsi equip (best gear from the bags).
-- ============================================================

GSI_UI = GSI_UI or {}

local L = GSI_L

local GetItemInfo = (C_Item and C_Item.GetItemInfo) or _G.GetItemInfo or function() return nil end
local GetItemInfoInstant = (C_Item and C_Item.GetItemInfoInstant) or _G.GetItemInfoInstant or function() return nil end
local BackdropTemplateMixin = _G.BackdropTemplateMixin
local BACKDROP_TEMPLATE = BackdropTemplateMixin and 'BackdropTemplate' or nil

local function SkinFrame(f, s, t) if GSI_UI.SkinFrame then return GSI_UI:SkinFrame(f, s, t) end end
local function SkinButton(b, r, p) if GSI_UI.SkinButton then return GSI_UI:SkinButton(b, r, p) end end
local function SkinSlider(s, bg, w, h) if GSI_UI.SkinSlider then return GSI_UI:SkinSlider(s, bg, w, h) end end
local function FormatWeight(v) return GSI_UI.FormatWeight and GSI_UI:FormatWeight(v) or tostring(v) end
local function FormatStatValue(k, v) return GSI_UI.FormatStatValue and GSI_UI:FormatStatValue(k, v) or tostring(v) end
local STAT_DISPLAY_NAMES = GSI_UI.STAT_DISPLAY_NAMES or {}
local T = GSI_UI.THEME

local print = function(...)
    if GSI_Print then
        GSI_Print(...)
    elseif not (GearSetImproverDB and (GearSetImproverDB.disableChatOutput or GearSetImproverDB.disableChat)) then
        _G.print(...)
    end
end

-- TAB: MACRO MANAGER & ACTION BAR PRESETS
-- ---------------------------------------------------------------

GSI_MACRO_PRESETS = {
    UNIVERSAL = {
        {
            id = "bib_active",
            name = "GSI: BiB Equip",
            icon = 132626, -- INV_Misc_Bag_08
            command = "/gsi equip",
            desc = "Active Profile",
        },
    },
    WARRIOR = {
        {
            id = "arms",
            name = "GSI: Arms",
            icon = 132355,
            command = "/gsi equip arms st",
            desc = "Arms Single Target DPS",
            specIndex = 1,
            mode = "ST",
        },
        {
            id = "arms_aoe",
            name = "GSI: Arms AoE",
            icon = 132337,
            command = "/gsi equip arms aoe",
            desc = "Arms AoE / Sweeping Strikes",
            specIndex = 1,
            mode = "AOE",
        },
        {
            id = "fury_st",
            name = "GSI: Fury ST",
            icon = 132347,
            command = "/gsi equip fury st",
            desc = "Fury Single Target",
            specIndex = 2,
            mode = "ST",
        },
        {
            id = "fury_aoe",
            name = "GSI: Fury AoE",
            icon = 132333,
            command = "/gsi equip fury aoe",
            desc = "Fury AoE / Cleave",
            specIndex = 2,
            mode = "AOE",
        },
        {
            id = "prot_def",
            name = "GSI: Prot Def",
            icon = 132341,
            command = "/gsi equip prot survival",
            desc = "Tank Survival (Mitigation)",
            specIndex = 3,
            mode = "Survival",
        },
        {
            id = "prot_aggro",
            name = "GSI: Prot Aggro",
            icon = 132288,
            command = "/gsi equip prot threat",
            desc = "Tank Threat / DPS",
            specIndex = 3,
            mode = "DMG",
        },
    },
    PALADIN = {
        {
            id = "holy",
            name = "GSI: Holy ST",
            icon = 135920,
            command = "/gsi equip holy st",
            desc = "Holy Healing Single Target",
            specIndex = 1,
            mode = "ST",
        },
        {
            id = "holy_aoe",
            name = "GSI: Holy AoE",
            icon = 135921,
            command = "/gsi equip holy aoe",
            desc = "Holy AoE / Light's Vigil",
            specIndex = 1,
            mode = "AOE",
        },
        {
            id = "prot_def",
            name = "GSI: Prot Def",
            icon = 236264,
            command = "/gsi equip prot survival",
            desc = "Paladin Tank Survival",
            specIndex = 2,
            mode = "Survival",
        },
        {
            id = "prot_aggro",
            name = "GSI: Prot Aggro",
            icon = 135964,
            command = "/gsi equip prot threat",
            desc = "Paladin Tank Threat / DPS",
            specIndex = 2,
            mode = "DMG",
        },
        {
            id = "ret",
            name = "GSI: Ret ST",
            icon = 135873,
            command = "/gsi equip ret st",
            desc = "Retribution Single Target",
            specIndex = 3,
            mode = "ST",
        },
        {
            id = "ret_aoe",
            name = "GSI: Ret AoE",
            icon = 135874,
            command = "/gsi equip ret aoe",
            desc = "Retribution AoE / Consecration",
            specIndex = 3,
            mode = "AOE",
        },
    },
    DRUID = {
        {
            id = "balance",
            name = "GSI: Balance",
            icon = 136096,
            command = "/gsi equip balance st",
            desc = "Balance Moonkin Single Target",
            specIndex = 1,
            mode = "ST",
        },
        {
            id = "balance_aoe",
            name = "GSI: Balance AoE",
            icon = 136018,
            command = "/gsi equip balance aoe",
            desc = "Balance AoE / Hurricane / Starfall",
            specIndex = 1,
            mode = "AOE",
        },
        {
            id = "bear_def",
            name = "GSI: Bear Def",
            icon = 132276,
            command = "/gsi equip bear survival",
            desc = "Bear Tank Survival (Mitigation)",
            specIndex = 2,
            mode = "Survival",
        },
        {
            id = "bear_aggro",
            name = "GSI: Bear Aggro",
            icon = 132145,
            command = "/gsi equip bear threat",
            desc = "Bear Tank Threat / DPS",
            specIndex = 2,
            mode = "DMG",
        },
        {
            id = "cat_st",
            name = "GSI: Cat ST",
            icon = 132115,
            command = "/gsi equip cat st",
            desc = "Cat Single Target DPS",
            specIndex = 3,
            mode = "ST",
        },
        {
            id = "cat_aoe",
            name = "GSI: Cat AoE",
            icon = 132143,
            command = "/gsi equip cat aoe",
            desc = "Cat Swipe / AoE Trash",
            specIndex = 3,
            mode = "AOE",
        },
        {
            id = "resto",
            name = "GSI: Resto",
            icon = 136041,
            command = "/gsi equip resto st",
            desc = "Restoration Single Target Healing",
            specIndex = 4,
            mode = "ST",
        },
        {
            id = "druid_resto_aoe",
            name = "GSI: Resto AoE",
            icon = 136042,
            command = "/gsi equip resto aoe",
            desc = "Restoration AoE / Wild Growth",
            specIndex = 4,
            mode = "AOE",
        },
    },
    HUNTER = {
        {
            id = "bm",
            name = "GSI: BeastMaster",
            icon = 461112,
            command = "/gsi equip bm st",
            desc = "Beast Mastery Single Target",
            specIndex = 1,
            mode = "ST",
        },
        {
            id = "bm_aoe",
            name = "GSI: BM AoE",
            icon = 132221,
            command = "/gsi equip bm aoe",
            desc = "Beast Mastery AoE / Volley",
            specIndex = 1,
            mode = "AOE",
        },
        {
            id = "mm",
            name = "GSI: Marksman",
            icon = 236179,
            command = "/gsi equip mm st",
            desc = "Marksmanship Single Target",
            specIndex = 2,
            mode = "ST",
        },
        {
            id = "mm_aoe",
            name = "GSI: MM AoE",
            icon = 132221,
            command = "/gsi equip mm aoe",
            desc = "Marksmanship AoE / Multi-Shot",
            specIndex = 2,
            mode = "AOE",
        },
        {
            id = "surv",
            name = "GSI: Survival",
            icon = 461113,
            command = "/gsi equip surv st",
            desc = "Survival Single Target",
            specIndex = 3,
            mode = "ST",
        },
        {
            id = "surv_aoe",
            name = "GSI: Surv AoE",
            icon = 132221,
            command = "/gsi equip surv aoe",
            desc = "Survival AoE / Explosive Trap",
            specIndex = 3,
            mode = "AOE",
        },
    },
    ROGUE = {
        {
            id = "assa",
            name = "GSI: Assassinate",
            icon = 236270,
            command = "/gsi equip assa st",
            desc = "Assassination Single Target",
            specIndex = 1,
            mode = "ST",
        },
        {
            id = "assa_aoe",
            name = "GSI: Assa AoE",
            icon = 132338,
            command = "/gsi equip assa aoe",
            desc = "Assassination AoE / Fan of Knives",
            specIndex = 1,
            mode = "AOE",
        },
        {
            id = "combat_st",
            name = "GSI: Combat ST",
            icon = 236286,
            command = "/gsi equip combat st",
            desc = "Combat Single Target",
            specIndex = 2,
            mode = "ST",
        },
        {
            id = "combat_aoe",
            name = "GSI: Combat AoE",
            icon = 132338,
            command = "/gsi equip combat aoe",
            desc = "Combat Blade Flurry / AoE",
            specIndex = 2,
            mode = "AOE",
        },
        {
            id = "sub",
            name = "GSI: Subtlety",
            icon = 132320,
            command = "/gsi equip sub st",
            desc = "Subtlety Single Target",
            specIndex = 3,
            mode = "ST",
        },
        {
            id = "sub_aoe",
            name = "GSI: Sub AoE",
            icon = 132338,
            command = "/gsi equip sub aoe",
            desc = "Subtlety AoE / Fan of Knives",
            specIndex = 3,
            mode = "AOE",
        },
    },
    PRIEST = {
        {
            id = "disc",
            name = "GSI: Discipline",
            icon = 135940,
            command = "/gsi equip disc st",
            desc = "Discipline Single Target Healing",
            specIndex = 1,
            mode = "ST",
        },
        {
            id = "disc_aoe",
            name = "GSI: Disc AoE",
            icon = 136224,
            command = "/gsi equip disc aoe",
            desc = "Discipline AoE / Prayer of Healing",
            specIndex = 1,
            mode = "AOE",
        },
        {
            id = "holy",
            name = "GSI: Holy Heal",
            icon = 237542,
            command = "/gsi equip holy st",
            desc = "Holy Single Target Healing",
            specIndex = 2,
            mode = "ST",
        },
        {
            id = "holy_aoe",
            name = "GSI: Holy AoE",
            icon = 136224,
            command = "/gsi equip holy aoe",
            desc = "Holy AoE / Circle of Healing",
            specIndex = 2,
            mode = "AOE",
        },
        {
            id = "shadow",
            name = "GSI: Shadow DPS",
            icon = 136207,
            command = "/gsi equip shadow st",
            desc = "Shadow Single Target DPS",
            specIndex = 3,
            mode = "ST",
        },
        {
            id = "shadow_aoe",
            name = "GSI: Shadow AoE",
            icon = 136224,
            command = "/gsi equip shadow aoe",
            desc = "Shadow AoE / Mind Sear",
            specIndex = 3,
            mode = "AOE",
        },
    },
    SHAMAN = {
        {
            id = "ele",
            name = "GSI: Elemental",
            icon = 136048,
            command = "/gsi equip ele st",
            desc = "Elemental Single Target DPS",
            specIndex = 1,
            mode = "ST",
        },
        {
            id = "ele_aoe",
            name = "GSI: Ele AoE",
            icon = 136015,
            command = "/gsi equip ele aoe",
            desc = "Elemental AoE / Chain Lightning",
            specIndex = 1,
            mode = "AOE",
        },
        {
            id = "enh",
            name = "GSI: Enhancement",
            icon = 237581,
            command = "/gsi equip enh st",
            desc = "Enhancement Single Target DPS",
            specIndex = 2,
            mode = "ST",
        },
        {
            id = "enh_aoe",
            name = "GSI: Enh AoE",
            icon = 136015,
            command = "/gsi equip enh aoe",
            desc = "Enhancement AoE / Fire Nova",
            specIndex = 2,
            mode = "AOE",
        },
        {
            id = "resto",
            name = "GSI: Restoration",
            icon = 136052,
            command = "/gsi equip resto st",
            desc = "Restoration Single Target Healing",
            specIndex = 3,
            mode = "ST",
        },
        {
            id = "shaman_resto_aoe",
            name = "GSI: Resto AoE",
            icon = 136015,
            command = "/gsi equip resto aoe",
            desc = "Restoration AoE / Chain Heal",
            specIndex = 3,
            mode = "AOE",
        },
    },
    MAGE = {
        {
            id = "arcane",
            name = "GSI: Arcane",
            icon = 135932,
            command = "/gsi equip arcane st",
            desc = "Arcane Single Target DPS",
            specIndex = 1,
            mode = "ST",
        },
        {
            id = "arcane_aoe",
            name = "GSI: Arcane AoE",
            icon = 135857,
            command = "/gsi equip arcane aoe",
            desc = "Arcane AoE / Arcane Explosion",
            specIndex = 1,
            mode = "AOE",
        },
        {
            id = "fire",
            name = "GSI: Fire ST",
            icon = 135810,
            command = "/gsi equip fire st",
            desc = "Fire Single Target DPS",
            specIndex = 2,
            mode = "ST",
        },
        {
            id = "fire_aoe",
            name = "GSI: Fire AoE",
            icon = 135857,
            command = "/gsi equip fire aoe",
            desc = "Fire AoE / Flamestrike",
            specIndex = 2,
            mode = "AOE",
        },
        {
            id = "frost",
            name = "GSI: Frost ST",
            icon = 135846,
            command = "/gsi equip frost st",
            desc = "Frost Single Target DPS",
            specIndex = 3,
            mode = "ST",
        },
        {
            id = "frost_aoe",
            name = "GSI: Frost AoE",
            icon = 135857,
            command = "/gsi equip frost aoe",
            desc = "Frost AoE / Blizzard",
            specIndex = 3,
            mode = "AOE",
        },
    },
    WARLOCK = {
        {
            id = "aff",
            name = "GSI: Affliction",
            icon = 136145,
            command = "/gsi equip aff st",
            desc = "Affliction Single Target DPS",
            specIndex = 1,
            mode = "ST",
        },
        {
            id = "aff_aoe",
            name = "GSI: Affli AoE",
            icon = 136187,
            command = "/gsi equip aff aoe",
            desc = "Affliction AoE / Seed of Corruption",
            specIndex = 1,
            mode = "AOE",
        },
        {
            id = "demo",
            name = "GSI: Demonology",
            icon = 136172,
            command = "/gsi equip demo st",
            desc = "Demonology Single Target DPS",
            specIndex = 2,
            mode = "ST",
        },
        {
            id = "demo_aoe",
            name = "GSI: Demo AoE",
            icon = 136187,
            command = "/gsi equip demo aoe",
            desc = "Demonology AoE / Hellfire",
            specIndex = 2,
            mode = "AOE",
        },
        {
            id = "dest",
            name = "GSI: Destruction",
            icon = 136186,
            command = "/gsi equip dest st",
            desc = "Destruction Single Target DPS",
            specIndex = 3,
            mode = "ST",
        },
        {
            id = "dest_aoe",
            name = "GSI: Destro AoE",
            icon = 136187,
            command = "/gsi equip dest aoe",
            desc = "Destruction AoE / Rain of Fire",
            specIndex = 3,
            mode = "AOE",
        },
    },
}

function GSI_UI:GetClassMacroPresets(playerClass)
    local list = {}
    if GSI_MACRO_PRESETS.UNIVERSAL then
        for _, def in ipairs(GSI_MACRO_PRESETS.UNIVERSAL) do
            table.insert(list, def)
        end
    end
    local classList = GSI_MACRO_PRESETS[playerClass or ""]
    if classList then
        for _, def in ipairs(classList) do
            table.insert(list, def)
        end
    end
    -- Dual spec back and forth plus the gear of the spec it lands in (/gsi toggle).
    -- Its icon is the spec of the other talent group, the one a press switches to.
    table.insert(list, {
        id = "dualspec",
        name = "GSI Dual Spec",
        icon = (self.GetDualSpecIcon and self:GetDualSpecIcon()) or 134400,
        -- It puts on the sets of the specs it lands in: no Equip button, no set of its own
        noSet = true,
        command = "/gsi toggle",
        desc = "Switches to your other talent group (dual spec) and, once the switch is done, puts on that spec's Equipment Set: the sets GSI saved for it, or the ones chosen in Settings. With several sets it asks which one; without any it equips the best gear from your bags. The icon shows the spec it switches to.",
    })
    return list
end

function GSI_UI:FindMacro(name)
    if not name then return nil end
    if GetMacroIndexByName then
        local idx = GetMacroIndexByName(name)
        if idx and idx > 0 then return idx end
    end
    local numAccount, numCharacter = GetNumMacros()
    numAccount = numAccount or 0
    numCharacter = numCharacter or 0
    local maxAccount = MAX_ACCOUNT_MACROS or 120

    -- Check character-specific macros first
    for i = maxAccount + 1, maxAccount + numCharacter do
        local mName = GetMacroInfo(i)
        if mName and mName:lower() == name:lower() then
            return i
        end
    end
    -- Check account macros
    for i = 1, numAccount do
        local mName = GetMacroInfo(i)
        if mName and mName:lower() == name:lower() then
            return i
        end
    end
    return nil
end

function GSI_UI:EnsureMacro(macroDef)
    if not macroDef or not macroDef.name then return nil end
    if InCombatLockdown and InCombatLockdown() then
        print(L["|cffff0000[GearSetImprover]|r Cannot create or edit macros while in combat!"])
        return nil
    end

    local existingIdx = self:FindMacro(macroDef.name)
    local body = macroDef.command or "/gsi equip"
    local icon = macroDef.icon or 134400
    -- The list may have been built before a spec switch: the icon of now
    if macroDef.id == "dualspec" and self.GetDualSpecIcon then
        icon = self:GetDualSpecIcon()
    end

    if existingIdx then
        local ok, err = pcall(function()
            EditMacro(existingIdx, macroDef.name, icon, body)
        end)
        if not ok then
            print(string.format(L["|cffff0000[GearSetImprover]|r Error updating macro: %s"], tostring(err)))
        end
        return existingIdx
    else
        local numAccount, numCharacter = GetNumMacros()
        numAccount = numAccount or 0
        numCharacter = numCharacter or 0

        local maxChar = MAX_CHARACTER_MACROS or 18
        local maxAccount = MAX_ACCOUNT_MACROS or 120
        local isChar = 1

        if numCharacter >= maxChar then
            if numAccount < maxAccount then
                isChar = nil
            else
                print(L["|cffff0000[GearSetImprover]|r Cannot create macro: Character and Account macro slots are both full! Please delete an unused macro via /macro."])
                return nil
            end
        end

        local newIdx = nil
        local ok, err = pcall(function()
            newIdx = CreateMacro(macroDef.name, icon, body, isChar)
        end)
        if not ok or not newIdx then
            print(string.format(L["|cffff0000[GearSetImprover]|r Failed to create macro: %s"], tostring(err or L["unknown error"])))
            return nil
        end
        print(string.format(L["|cff00ff00[GearSetImprover]|r Created macro '|cffffcc00%s|r' (%s)!"], macroDef.name, isChar and L["Character"] or L["Account"]))
        return newIdx
    end
end

function GSI_UI:PickupMacroDef(macroDef)
    if InCombatLockdown and InCombatLockdown() then
        print(L["|cffff0000[GearSetImprover]|r Cannot pick up macros while in combat!"])
        return
    end

    local idx = self:FindMacro(macroDef.name)
    if not idx then
        idx = self:EnsureMacro(macroDef)
        if not idx then return end
    end

    local ok, err = pcall(function()
        PickupMacro(idx)
    end)
    if ok then
        print(string.format(L["|cff00ff00[GearSetImprover]|r Macro '|cffffcc00%s|r' attached to cursor! Click an Action Bar slot to place it."], macroDef.name))
    else
        print(string.format(L["|cffff0000[GearSetImprover]|r PickupMacro error: %s"], tostring(err)))
    end

    local mainFrame = self.mainFrame or GSI_UI.mainFrame
        if self.activeTab == "MACROS" and mainFrame and mainFrame:IsShown() then
        local frame = mainFrame.tabFrames and mainFrame.tabFrames["MACROS"]
        if frame then self:UpdateMacros(frame) end
    end
end

function GSI_UI:CreateAllMacros()
    if InCombatLockdown and InCombatLockdown() then
        print(L["|cffff0000[GearSetImprover]|r Cannot create macros while in combat!"])
        return
    end

    local playerClass = (GSI_ClassicData and GSI_ClassicData.GetPlayerClass and GSI_ClassicData:GetPlayerClass()) or select(2, UnitClass("player")) or "WARRIOR"
    local presets = self:GetClassMacroPresets(playerClass)
    local createdCount = 0
    local updatedCount = 0

    for _, def in ipairs(presets) do
        local existed = self:FindMacro(def.name) ~= nil
        local idx = self:EnsureMacro(def)
        if idx then
            if existed then
                updatedCount = updatedCount + 1
            else
                createdCount = createdCount + 1
            end
        end
    end

    print(string.format(L["|cff00ff00[GearSetImprover]|r Macro setup complete: %d created, %d updated."], createdCount, updatedCount))
    local mainFrame = self.mainFrame or GSI_UI.mainFrame
        if self.activeTab == "MACROS" and mainFrame and mainFrame:IsShown() then
        local frame = mainFrame.tabFrames and mainFrame.tabFrames["MACROS"]
        if frame then self:UpdateMacros(frame) end
    end
end

function GSI_UI:EquipBestInBag(targetSpec, targetMode, onDone, targetPreset)
    if InCombatLockdown and InCombatLockdown() then
        print(L["|cffff0000[GearSetImprover]|r Cannot equip gear while in combat!"])
        if onDone then onDone(false, "in_combat") end
        return
    end

    if targetSpec then
        -- Equipping for the spec already detected keeps Auto on; another spec pins it.
        if GSI_StatWeights.ChooseSpec then
            GSI_StatWeights:ChooseSpec(tonumber(targetSpec))
        else
            GearSetImproverDB.selectedSpec = tonumber(targetSpec)
        end
    end
    if targetMode then
        if targetMode.type == "tank" then
            GearSetImproverDB.tankMode = targetMode.value
        elseif targetMode.type == "dps" then
            GearSetImproverDB.weightMode = targetMode.value
        end
    end

    GSI_ItemScore:ResetCache()
    GSI_OptimizationEngine:ResetCache()
    pcall(function() GSI_UI:UpdateSpecButton() end)
    pcall(function() GSI_UI:UpdateModeUI() end)
    pcall(function() GSI_UI:UpdateTitleScore() end)

    local class = (GSI_ClassicData and GSI_ClassicData.GetPlayerClass and GSI_ClassicData:GetPlayerClass()) or select(2, UnitClass("player")) or "WARRIOR"
    local specIndex = GSI_StatWeights:GetActiveSpecIndex()
    local classData = GSI_ClassicData and GSI_ClassicData.Classes and GSI_ClassicData.Classes[class]
    local specData = classData and classData.specs and classData.specs[specIndex]
    local specName = L[specData and (specData.name or specData.nameDE) or ("Spec " .. tostring(specIndex))]
    local role = GSI_StatWeights:GetRole()
    local modeLabel = ""
    if role == "tank" then
        local tMode = (GearSetImproverDB and GearSetImproverDB.tankMode) or "Survival"
        modeLabel = (tMode == "Survival") and L["Survival"] or L["Threat / DPS"]
    else
        local wMode = (GearSetImproverDB and GearSetImproverDB.weightMode) or "ST"
        modeLabel = (wMode == "ST") and L["Single Target"] or L["AoE / Trash"]
    end

    print(string.format(L["|cffffcc00[GearSetImprover]|r Optimizing Best Available Gear for |cff00ff00%s (%s)|r..."], specName, modeLabel))

    GSI_OptimizationEngine:OptimizeBagGearAsync(nil, function(bestSetup, bestScore, upgrades, totalGain, scanStats)
        local list = {}
        local lockedCount = 0
        for sID, u in pairs(upgrades or {}) do
            local isLocked = u.isLocked or (GearSetImproverDB and GearSetImproverDB.lockedGearSlots and GearSetImproverDB.lockedGearSlots[sID])
            if isLocked then
                lockedCount = lockedCount + 1
            else
                table.insert(list, { slotID = sID, up = u })
            end
        end

        if #list == 0 then
            if lockedCount > 0 then
                print(string.format(L["|cffffcc00[GearSetImprover]|r [|cff00ff00%s (%s)|r]: All available upgrades are on locked slots. Unlock them first to equip."], specName, modeLabel))
            else
                print(string.format(L["|cffffcc00[GearSetImprover]|r [|cff00ff00%s (%s)|r]: Current gear is already optimal! (No upgrades found in bags)"], specName, modeLabel))
            end
            GSI_UI:SaveEquipmentSetForProfile(specIndex, targetMode, targetPreset)
            if onDone then onDone(true, 0) end
            local mainFrame = GSI_UI.mainFrame
        if GSI_UI.activeTab == "BIB" and mainFrame and mainFrame:IsShown() then
                local frame = mainFrame.tabFrames and mainFrame.tabFrames["BIB"]
                if frame then
                    frame.scanned = true
                    frame.upgrades = upgrades
                    frame.totalGain = 0
                    frame.scanStats = scanStats
                    GSI_UI:UpdateBiBList(frame)
                end
            end
            return
        end

        print(string.format(L["|cffffcc00[GearSetImprover]|r Found |cff00ff00%d upgrade(s)|r (+%.1f GSI Score) for |cff00ff00%s (%s)|r. Equipping..."], #list, totalGain or 0, specName, modeLabel))

        local idx = 1
        GSI_UI.isEquippingAll = true
        local function StepEquip()
            if InCombatLockdown and InCombatLockdown() then
                GSI_UI.isEquippingAll = false
                print(L["|cffff0000[GearSetImprover]|r Equipping interrupted: entered combat!"])
                if onDone then onDone(false, "in_combat") end
                return
            end

            if idx > #list then
                GSI_UI.isEquippingAll = false
                print(string.format(L["|cff00ff00[GearSetImprover]|r All %d upgrade(s) equipped! Total GSI Score gain: +%.1f for %s (%s)."], #list, totalGain or 0, specName, modeLabel))
                local function DoFinish()
                    GSI_UI:SaveEquipmentSetForProfile(specIndex, targetMode, targetPreset)
                    if onDone then onDone(true, #list) end
                    pcall(function() GSI_UI:UpdateTitleScore() end)
                    local mainFrame = GSI_UI.mainFrame
                    if GSI_UI.ScheduleOptimization then
                        GSI_UI:ScheduleOptimization(0.15, true)
                    elseif mainFrame and mainFrame:IsShown() then
                        GSI_UI:RefreshPanel(true)
                    end
                end

                if C_Timer and C_Timer.After then
                    C_Timer.After(0.2, DoFinish)
                else
                    DoFinish()
                end
                return
            end

            local item = list[idx]
            idx = idx + 1
            GSI_UI:EquipUpgradeItem(item.up, item.slotID)

            if C_Timer and C_Timer.After then
                C_Timer.After(0.15, StepEquip)
            else
                StepEquip()
            end
        end

        StepEquip()
    end)
end
