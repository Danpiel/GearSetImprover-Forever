-- ============================================================
-- GearSetImprover -- UI_Tab_Macros.lua (WoW Forever)
-- ============================================================

GSI_UI = GSI_UI or {}

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

local GSI_MACRO_PRESETS = {
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
            icon = 135893,
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
            icon = 132144,
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
            icon = 132212,
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
            icon = 132222,
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
            icon = 132223,
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
            icon = 132292,
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
            icon = 132344,
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
            icon = 135920,
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
            icon = 136051,
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
            icon = 136096,
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
            icon = 135812,
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
        print("|cffff0000[GearSetImprover]|r Cannot create or edit macros while in combat!")
        return nil
    end

    local existingIdx = self:FindMacro(macroDef.name)
    local body = macroDef.command or "/gsi equip"
    local icon = macroDef.icon or 134400

    if existingIdx then
        local ok, err = pcall(function()
            EditMacro(existingIdx, macroDef.name, icon, body)
        end)
        if not ok then
            print("|cffff0000[GearSetImprover]|r Error updating macro: " .. tostring(err))
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
                print("|cffff0000[GearSetImprover]|r Cannot create macro: Character and Account macro slots are both full! Please delete an unused macro via /macro.")
                return nil
            end
        end

        local newIdx = nil
        local ok, err = pcall(function()
            newIdx = CreateMacro(macroDef.name, icon, body, isChar)
        end)
        if not ok or not newIdx then
            print("|cffff0000[GearSetImprover]|r Failed to create macro: " .. tostring(err or "unknown error"))
            return nil
        end
        print(string.format("|cff00ff00[GearSetImprover]|r Created macro '|cffffcc00%s|r' (%s)!", macroDef.name, isChar and "Character" or "Account"))
        return newIdx
    end
end

function GSI_UI:PickupMacroDef(macroDef)
    if InCombatLockdown and InCombatLockdown() then
        print("|cffff0000[GearSetImprover]|r Cannot pick up macros while in combat!")
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
        print(string.format("|cff00ff00[GearSetImprover]|r Macro '|cffffcc00%s|r' attached to cursor! Click an Action Bar slot to place it.", macroDef.name))
    else
        print("|cffff0000[GearSetImprover]|r PickupMacro error: " .. tostring(err))
    end

    local mainFrame = self.mainFrame or GSI_UI.mainFrame
        if self.activeTab == "MACROS" and mainFrame and mainFrame:IsShown() then
        local frame = mainFrame.tabFrames and mainFrame.tabFrames["MACROS"]
        if frame then self:UpdateMacros(frame) end
    end
end

function GSI_UI:CreateAllMacros()
    if InCombatLockdown and InCombatLockdown() then
        print("|cffff0000[GearSetImprover]|r Cannot create macros while in combat!")
        return
    end

    local playerClass = select(2, UnitClass("player")) or "WARRIOR"
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

    print(string.format("|cff00ff00[GearSetImprover]|r Macro setup complete: %d created, %d updated.", createdCount, updatedCount))
    local mainFrame = self.mainFrame or GSI_UI.mainFrame
        if self.activeTab == "MACROS" and mainFrame and mainFrame:IsShown() then
        local frame = mainFrame.tabFrames and mainFrame.tabFrames["MACROS"]
        if frame then self:UpdateMacros(frame) end
    end
end

function GSI_UI:DrawMacros(parent)
    local createAllBtn = CreateFrame("Button", nil, parent, BACKDROP_TEMPLATE)
    createAllBtn:SetSize(145, 24)
    createAllBtn:SetPoint("TOPRIGHT", -25, -16)
    createAllBtn:SetText("Create All Macros")
    SkinButton(createAllBtn, nil, true)
    createAllBtn:SetScript("OnClick", function()
        GSI_UI:CreateAllMacros()
    end)
    createAllBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine("Create All Macros", 1, 0.82, 0)
        GameTooltip:AddLine("Automatically creates all recommended Best Available macros for your class.", 1, 1, 1, true)
        GameTooltip:Show()
    end)
    createAllBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    local refreshBtn = CreateFrame("Button", nil, parent, BACKDROP_TEMPLATE)
    refreshBtn:SetSize(145, 22)
    refreshBtn:SetPoint("TOPRIGHT", -25, -44)
    refreshBtn:SetText("Refresh Status")
    SkinButton(refreshBtn)
    refreshBtn:SetScript("OnClick", function()
        GSI_UI:UpdateMacros(parent)
    end)

    local title = self:CreateText(parent, "TITLE", "Best Available - Macro Manager")
    title:SetPoint("TOPLEFT", 15, -15)
    title:SetPoint("TOPRIGHT", createAllBtn, "TOPLEFT", -12, 1)
    title:SetJustifyH("LEFT")
    title:SetWordWrap(false)

    local desc = self:CreateText(parent, "BODY", "Click or drag any macro card directly into an Action Bar slot!")
    desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4)
    desc:SetPoint("TOPRIGHT", title, "BOTTOMRIGHT", 0, -4)
    desc:SetJustifyH("LEFT")
    desc:SetWordWrap(false)

    local slotInfo = self:CreateText(parent, "SMALL", "Macro Capacity: Loading...")
    slotInfo:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", 0, -4)
    slotInfo:SetPoint("TOPRIGHT", desc, "BOTTOMRIGHT", 0, -4)
    slotInfo:SetJustifyH("LEFT")
    slotInfo:SetWordWrap(false)
    parent.slotInfoText = slotInfo

    local scroll = CreateFrame("ScrollFrame", "GSI_MacrosScroll", parent, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 10, -78)
    scroll:SetPoint("BOTTOMRIGHT", -26, 12)
    if GSI_UI and GSI_UI.SkinScrollBar then
        GSI_UI:SkinScrollBar(scroll)
    end

    local child = CreateFrame("Frame", nil, scroll)
    child:SetSize(696, 500)
    scroll:SetScrollChild(child)
    parent.scrollChild = child
    parent.rows = {}
end

function GSI_UI:UpdateMacros(parent)
    if not parent or not parent.scrollChild then return end

    local numAccount, numCharacter = GetNumMacros()
    numAccount = numAccount or 0
    numCharacter = numCharacter or 0
    local maxAccount = MAX_ACCOUNT_MACROS or 120
    local maxCharacter = MAX_CHARACTER_MACROS or 18

    if parent.slotInfoText then
        parent.slotInfoText:SetText(string.format("Macro Capacity: |cffffffffCharacter:|r |cff00ff00%d/%d|r  |  |cffffffffAccount:|r |cff00ff00%d/%d|r", numCharacter, maxCharacter, numAccount, maxAccount))
    end

    local playerClass = select(2, UnitClass("player")) or "WARRIOR"
    local presets = self:GetClassMacroPresets(playerClass)

    for _, r in ipairs(parent.rows or {}) do r:Hide() end

    local yOff = 0
    for i, def in ipairs(presets) do
        local row = parent.rows[i]
        if not row then
            row = CreateFrame("Frame", nil, parent.scrollChild, BACKDROP_TEMPLATE)
            row:SetSize(696, 50)
            SkinFrame(row, "card")

            row:SetScript("OnEnter", function(self)
                self:SetBackdropColor(0.12, 0.12, 0.16, 0.95)
                self:SetBackdropBorderColor(0.24, 0.24, 0.32, 1)
                if self.def then
                    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                    GameTooltip:AddLine(self.def.name, 1, 0.82, 0)
                    GameTooltip:AddLine(self.def.command, 0.4, 0.8, 1)
                    if self.def.desc then
                        GameTooltip:AddLine(self.def.desc, 0.85, 0.85, 0.85, true)
                    end
                    GameTooltip:Show()
                end
            end)
            row:SetScript("OnLeave", function(self)
                self:SetBackdropColor(0.08, 0.08, 0.10, 0.85)
                self:SetBackdropBorderColor(0.16, 0.16, 0.20, 1)
                GameTooltip:Hide()
            end)

            local btn = CreateFrame("Button", nil, row, BACKDROP_TEMPLATE)
            btn:SetSize(36, 36)
            btn:SetPoint("LEFT", 8, 0)
            SkinFrame(btn)
            btn:SetBackdropColor(0.08, 0.08, 0.10, 1)
            btn:SetBackdropBorderColor(0.22, 0.22, 0.28, 1)

            local icon = btn:CreateTexture(nil, "ARTWORK")
            icon:SetSize(32, 32)
            icon:SetPoint("CENTER")
            icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
            btn.icon = icon

            btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
            btn:RegisterForDrag("LeftButton")

            local hl = btn:CreateTexture(nil, "HIGHLIGHT")
            hl:SetAllPoints(icon)
            hl:SetColorTexture(1, 1, 1, 0.25)

            btn:SetScript("OnEnter", function(self)
                if self.def then
                    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                    GameTooltip:AddLine(self.def.name, 1, 0.82, 0)
                    GameTooltip:AddLine("Left-Click or Drag to place on Action Bar", 0, 1, 0)
                    GameTooltip:AddLine(self.def.command, 0.4, 0.8, 1)
                    GameTooltip:AddLine(self.def.desc, 0.8, 0.8, 0.8, true)
                    GameTooltip:Show()
                end
            end)
            btn:SetScript("OnLeave", function() GameTooltip:Hide() end)

            btn:SetScript("OnDragStart", function(self)
                if self.def then
                    GSI_UI:PickupMacroDef(self.def)
                end
            end)
            btn:SetScript("OnClick", function(self)
                if self.def then
                    GSI_UI:PickupMacroDef(self.def)
                end
            end)
            row.macroBtn = btn

            local createBtn = CreateFrame("Button", nil, row, BACKDROP_TEMPLATE)
            createBtn:SetSize(64, 24)
            createBtn:SetPoint("RIGHT", -8, 0)
            createBtn:SetText("Create")
            SkinButton(createBtn)
            createBtn:SetScript("OnClick", function(self)
                if self.def then
                    GSI_UI:EnsureMacro(self.def)
                    GSI_UI:UpdateMacros(parent)
                end
            end)
            row.createBtn = createBtn

            local dragBtn = CreateFrame("Button", nil, row, BACKDROP_TEMPLATE)
            dragBtn:SetSize(80, 24)
            dragBtn:SetPoint("RIGHT", createBtn, "LEFT", -6, 0)
            dragBtn:SetText("Drag to Bar")
            SkinButton(dragBtn)
            dragBtn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
            dragBtn:RegisterForDrag("LeftButton")

            dragBtn:SetScript("OnDragStart", function(self)
                if self.def then
                    GSI_UI:PickupMacroDef(self.def)
                end
            end)
            dragBtn:SetScript("OnClick", function(self)
                if self.def then
                    GSI_UI:PickupMacroDef(self.def)
                end
            end)
            dragBtn:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:AddLine("Drag to Action Bar", 1, 0.82, 0)
                GameTooltip:AddLine("Picks up this macro onto your mouse cursor so you can drop it into any Action Bar slot.", 1, 1, 1, true)
                GameTooltip:Show()
            end)
            dragBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
            row.dragBtn = dragBtn

            local equipBtn = CreateFrame("Button", nil, row, BACKDROP_TEMPLATE)
            equipBtn:SetSize(64, 24)
            equipBtn:SetPoint("RIGHT", dragBtn, "LEFT", -6, 0)
            equipBtn:SetText("Equip")
            SkinButton(equipBtn)
            equipBtn:SetScript("OnClick", function(self)
                if self.def then
                    GSI_UI:EquipPreset(self.def)
                end
            end)
            equipBtn:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:AddLine("Equip Preset", 1, 0.82, 0)
                GameTooltip:AddLine("Equips Best Available for this preset and saves it as an Equipment Set in your Character Profile.", 1, 1, 1, true)
                GameTooltip:Show()
            end)
            equipBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
            row.equipBtn = equipBtn

            row.nameText = GSI_UI:CreateText(row, "CARD_TITLE", "")
            row.nameText:SetJustifyH("LEFT")
            row.nameText:SetWordWrap(false)

            row.statusBadge = GSI_UI:CreateText(row, "SMALL", "")
            row.statusBadge:SetJustifyH("RIGHT")
            row.statusBadge:SetWordWrap(false)

            row.cmdText = GSI_UI:CreateText(row, "BODY", "")
            row.cmdText:SetJustifyH("LEFT")
            row.cmdText:SetWordWrap(false)

            parent.rows[i] = row
        end

        row.def = def
        row.macroBtn.def = def
        row.dragBtn.def = def
        row.createBtn.def = def
        row.equipBtn.def = def

        row:SetSize(696, 50)

        -- Position text elements cleanly without vertical distortion or button overlap
        row.statusBadge:ClearAllPoints()
        row.statusBadge:SetPoint("RIGHT", row.equipBtn, "LEFT", -8, 9)

        row.nameText:ClearAllPoints()
        row.nameText:SetPoint("LEFT", row.macroBtn, "RIGHT", 10, 9)
        row.nameText:SetPoint("RIGHT", row.statusBadge, "LEFT", -8, 0)

        row.cmdText:ClearAllPoints()
        row.cmdText:SetPoint("LEFT", row.macroBtn, "RIGHT", 10, -9)
        row.cmdText:SetPoint("RIGHT", row.equipBtn, "LEFT", -8, -9)

        local macroIdx = GSI_UI:FindMacro(def.name)
        if macroIdx then
            local _, _, _, isLocal = GetMacroInfo(macroIdx)
            local locStr = isLocal and "Char" or "Account"
            row.statusBadge:SetText(string.format("|cff00ff00[Ready]|r |cff888888(%s)|r", locStr))
            row.createBtn:SetText("Update")
            row.macroBtn:SetBackdropBorderColor(0, 0.8, 0, 1)
        else
            row.statusBadge:SetText("|cff888888[Not Created]|r")
            row.createBtn:SetText("|cff00ff00Create|r")
            row.macroBtn:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
        end

        row.macroBtn.icon:SetTexture(def.icon or 134400)
        row.nameText:SetText(def.name)
        row.cmdText:SetText(string.format("|cffffcc00%s|r  |cffaaaaaa- %s|r", def.command, def.desc))

        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", parent.scrollChild, "TOPLEFT", 0, -yOff)
        row:Show()

        yOff = yOff + 54
    end

    parent.scrollChild:SetHeight(math.max(yOff + 10, 10))
end

-- ===============================================================
-- SLASH COMMANDS & MACRO SUPPORT: BEST AVAILABLE
-- ===============================================================

local CLASS_SPEC_ALIASES = {
    WARRIOR = {
        [1] = { "arms", "waffen" },
        [2] = { "fury", "furor" },
        [3] = { "protection", "prot", "schutz", "tank" },
    },
    PALADIN = {
        [1] = { "holy", "heilig", "heal", "healer" },
        [2] = { "protection", "prot", "schutz", "tank" },
        [3] = { "retribution", "ret", "vergeltung", "dps" },
    },
    HUNTER = {
        [1] = { "beast mastery", "beastmastery", "bm", "beast", "tierherrschaft" },
        [2] = { "marksmanship", "mm", "marks", "treffsicherheit" },
        [3] = { "survival", "surv", "überleben", "ueberleben", "melee" },
    },
    ROGUE = {
        [1] = { "assassination", "assa", "meucheln", "dagger" },
        [2] = { "combat", "kampf", "sword", "mace" },
        [3] = { "subtlety", "sub", "täuschung", "taeuschung" },
    },
    PRIEST = {
        [1] = { "discipline", "disc", "disziplin" },
        [2] = { "holy", "heilig", "heal", "healer" },
        [3] = { "shadow", "schatten", "spriest", "dps" },
    },
    SHAMAN = {
        [1] = { "elemental", "ele", "elementar", "caster" },
        [2] = { "enhancement", "enh", "verstärkung", "verstaerkung", "melee" },
        [3] = { "restoration", "resto", "wiederherstellung", "heal", "healer" },
    },
    MAGE = {
        [1] = { "arcane", "arkan" },
        [2] = { "fire", "feuer" },
        [3] = { "frost" },
    },
    WARLOCK = {
        [1] = { "affliction", "affli", "aff", "gebrechen", "dot" },
        [2] = { "demonology", "demo", "dämonologie", "daemonologie", "pet" },
        [3] = { "destruction", "destro", "zerstörung", "zerstoerung", "burst" },
    },
    DRUID = {
        [1] = { "balance", "moonkin", "boomkin", "gleichgewicht", "owl" },
        [2] = { "feral bear", "bear", "baer", "bär", "tank", "feral tank", "guardian", "feral" },
        [3] = { "feral cat", "cat", "katze", "kitty", "feral dps", "dps" },
        [4] = { "restoration", "resto", "wiederherstellung", "heal", "healer", "tree" },
    },
}

local TANK_MODE_ALIASES = {
    survival      = "Survival",
    surv          = "Survival",
    def           = "Survival",
    defense       = "Survival",
    mitigation    = "Survival",
    ehp           = "Survival",
    ["überleben"] = "Survival",
    ueberleben    = "Survival",
    threat        = "DMG",
    aggro         = "DMG",
    dmg           = "DMG",
    dps           = "DMG",
    offtank       = "DMG",
    ot            = "DMG",
}

local DPS_MODE_ALIASES = {
    st            = "ST",
    single        = "ST",
    singletarget  = "ST",
    boss          = "ST",
    aoe           = "AOE",
    trash         = "AOE",
    multi         = "AOE",
    multitarget   = "AOE",
    cleave        = "AOE",
    swipe         = "AOE",
}

local function ParseSpecAndModeTokens(tokens)
    local targetSpec = nil
    local targetMode = nil
    local playerClass = select(2, UnitClass("player")) or "WARRIOR"

    -- Combine multi-word spec and mode phrases before single-token parsing
    local normalized = {}
    local idx = 1
    while idx <= #tokens do
        local t1 = tostring(tokens[idx]):lower()
        local t2 = tokens[idx + 1] and tostring(tokens[idx + 1]):lower()
        local pair = t2 and (t1 .. " " .. t2)
        if pair and (pair == "feral bear" or pair == "feral tank" or pair == "feral cat" or pair == "feral dps"
            or pair == "beast mastery" or pair == "single target" or pair == "multi target") then
            table.insert(normalized, pair)
            idx = idx + 2
        else
            table.insert(normalized, t1)
            idx = idx + 1
        end
    end

    for _, token in ipairs(normalized) do
        if token == "1" or token == "2" or token == "3" or token == "4" then
            targetSpec = tonumber(token)
        elseif token == "single target" then
            targetMode = { type = "dps", value = "ST" }
        elseif token == "multi target" then
            targetMode = { type = "dps", value = "AOE" }
        elseif playerClass == "DRUID" and (token == "bear" or token == "baer" or token == "bär" or token == "feral bear" or token == "feral tank" or token == "guardian") then
            targetSpec = 2
            if not targetMode or targetMode.type ~= "tank" then
                targetMode = { type = "tank", value = "Survival" }
            end
        elseif playerClass == "DRUID" and (token == "cat" or token == "katze" or token == "kitty" or token == "feral cat" or token == "feral dps") then
            targetSpec = 3
            if not targetMode or targetMode.type ~= "dps" then
                targetMode = { type = "dps", value = "ST" }
            end
        elseif playerClass == "DRUID" and (token == "resto" or token == "restoration" or token == "wiederherstellung" or token == "tree" or token == "heal") then
            targetSpec = 4
            if targetMode and targetMode.type == "tank" then
                targetMode = nil
            end
        elseif playerClass == "DRUID" and (token == "balance" or token == "moonkin" or token == "boomkin" or token == "gleichgewicht" or token == "owl") then
            targetSpec = 1
            if targetMode and targetMode.type == "tank" then
                targetMode = nil
            end
        elseif playerClass == "DRUID" and token == "feral" then
            if not targetSpec then
                targetSpec = 2
                if not targetMode then
                    targetMode = { type = "tank", value = "Survival" }
                end
            end
        else
            local matchedSpec = false
            local classSpecs = CLASS_SPEC_ALIASES[playerClass]
            if classSpecs then
                for sIdx, aliasList in pairs(classSpecs) do
                    for _, alias in ipairs(aliasList) do
                        if token == alias then
                            targetSpec = sIdx
                            matchedSpec = true
                            break
                        end
                    end
                    if matchedSpec then break end
                end
            end

            if not matchedSpec then
                if TANK_MODE_ALIASES[token] then
                    targetMode = { type = "tank", value = TANK_MODE_ALIASES[token] }
                elseif DPS_MODE_ALIASES[token] then
                    targetMode = { type = "dps", value = DPS_MODE_ALIASES[token] }
                end
            end
        end
    end

    return targetSpec, targetMode
end
GSI_UI.ParseSpecAndModeTokens = ParseSpecAndModeTokens
_G.GSI_ParseSpecAndModeTokens = ParseSpecAndModeTokens

function GSI_UI:PrintSlashHelp()
    print("|cffffcc00[GearSetImprover]|r Commands & Help:")
    print("  |cff00ff00/gsi|r - Open / close main window")
    print("  |cff00ff00/gsi gear|r (or |cff00ff00/gsi bib|r) - Open 'Best Available Gear'")
    print("  |cff00ff00/gsi cleanup|r (or |cff00ff00/gsi junk|r) - Open 'Clean-up'")
    print("  |cff00ff00/gsi weights|r - Open 'Stat Weights'")
    print("  |cff00ff00/gsi options|r (or |cff00ff00/gsi settings|r) - Open Addon Settings")
    print("  |cff00ff00/gsi tutorial|r - Open interactive tutorial")
    print("  |cff00ff00/gsi changelog|r - Show release notes (Changelog)")
    print("  |cff00ff00/gsi credits|r - View credits & acknowledgments")
    print("  |cff00ff00/gsi log|r - Open Log Export window")
    print("  |cff00ff00/gsi equip|r (or |cff00ff00/gsiequip|r) - Equip Best Available Gear")
    print("  |cff00ff00/gsi equip <spec> [mode]|r - Equip Best Available Gear for a specific profile")
    print("    |cffffffaaExamples:|r")
    print("      |cffffff00/gsi equip arms|r or |cffffff00/gsi equip fury aoe|r")
    print("      |cffffff00/gsi equip prot survival|r or |cffffff00/gsi equip prot threat|r")
    print("      |cffffff00/gsiequip bear survival|r or |cffffff00/gsiequip cat st|r (Druid)")
    print("  |cff00ff00/gsi macros|r - Macro Manager for 1-click Action Bar macros")
    print("  |cff00ff00/gsi spec <1-3|name>|r - Pin a specialization (scores stop following your talents)")
    print("  |cff00ff00/gsi spec auto|r - Follow your current talent specialization (default)")
    print("  |cff00ff00/gsi set|r - Equip the Equipment Set chosen for the current spec (Settings tab)")
    print("  |cff00ff00/gsi dump|r - Save item/tooltip/spec diagnostics to SavedVariables (then /reload)")
    print("  |cff00ff00/gsi mode <survival|threat|st|aoe>|r - Switch active mode")
    print("  |cff00ff00/gsi toast|r (or |cff00ff00/gsi testtoast|r) - Test on-screen upgrade toast alert")
    print("  |cff00ff00/gsi anchor|r - Toggle movable screen anchor for upgrade toasts")
    print("  |cff00ff00/gsi help|r - Show this command list")
end

function GSI_UI:GetEquipmentSetNameAndIcon(specIndex, targetMode, explicitPreset)
    if explicitPreset and explicitPreset.name then
        local name = explicitPreset.name
        if string.len(name) > 16 then name = string.sub(name, 1, 16) end
        return name, explicitPreset.icon or 134400
    end

    local playerClass = select(2, UnitClass("player")) or "WARRIOR"
    local activeSpec = tonumber(specIndex) or GSI_StatWeights:GetActiveSpecIndex()
    local role = GSI_StatWeights:GetRole()
    local modeVal = nil

    if targetMode then
        modeVal = type(targetMode) == "table" and targetMode.value or targetMode
    else
        if role == "tank" then
            modeVal = (GearSetImproverDB and GearSetImproverDB.tankMode) or "Survival"
        else
            modeVal = (GearSetImproverDB and GearSetImproverDB.weightMode) or "ST"
        end
    end

    local presets = GSI_MACRO_PRESETS[playerClass]
    if presets then
        -- 1. Try exact match on both spec and mode
        for _, p in ipairs(presets) do
            if p.specIndex == activeSpec and p.mode and modeVal and (p.mode:upper() == modeVal:upper()) then
                local name = p.name
                if string.len(name) > 16 then name = string.sub(name, 1, 16) end
                return name, p.icon or 134400
            end
        end

        -- 2. Try match on specIndex where preset has no specific mode restriction
        for _, p in ipairs(presets) do
            if p.specIndex == activeSpec and not p.mode then
                local name = p.name
                if string.len(name) > 16 then name = string.sub(name, 1, 16) end
                return name, p.icon or 134400
            end
        end

        -- 3. Try match on mode only (e.g. AoE presets)
        for _, p in ipairs(presets) do
            if not p.specIndex and p.mode and modeVal and (p.mode:upper() == modeVal:upper()) then
                local name = p.name
                if string.len(name) > 16 then name = string.sub(name, 1, 16) end
                return name, p.icon or 134400
            end
        end
    end

    -- Fallback: Use class spec data
    local classData = GSI_ClassicData and GSI_ClassicData.Classes and GSI_ClassicData.Classes[playerClass]
    local specData = classData and classData.specs and classData.specs[activeSpec]
    local rawSpec = specData and (specData.name or specData.nameDE) or ("Spec " .. tostring(activeSpec))
    local setName = "GSI: " .. rawSpec
    if string.len(setName) > 16 then
        setName = string.sub(setName, 1, 16)
    end
    local icon = specData and specData.icon or 134400
    return setName, icon
end

function GSI_UI:SaveEquipmentSetForProfile(specIndex, targetMode, explicitPreset)
    if InCombatLockdown and InCombatLockdown() then
        return false, "in_combat"
    end

    if GearSetImproverDB and GearSetImproverDB.autoSaveEquipmentSet == false then
        return false, "disabled"
    end

    if not C_EquipmentSet then
        return false, "no_api"
    end

    local setName, icon = self:GetEquipmentSetNameAndIcon(specIndex, targetMode, explicitPreset)
    if not setName or string.len(setName) == 0 then
        return false, "invalid_name"
    end
    if string.len(setName) > 16 then
        setName = string.sub(setName, 1, 16)
    end
    icon = icon or 134400

    local ok, res = pcall(function()
        local setID = C_EquipmentSet.GetEquipmentSetID and C_EquipmentSet.GetEquipmentSetID(setName)

        if setID ~= nil then
            -- Set already exists: clear ignored slots and update
            if C_EquipmentSet.ClearIgnoredSlotsForSave then
                pcall(C_EquipmentSet.ClearIgnoredSlotsForSave)
            end
            local saveOk = pcall(C_EquipmentSet.SaveEquipmentSet, setID, icon)
            if not saveOk then
                pcall(C_EquipmentSet.SaveEquipmentSet, setID)
            end
            if C_EquipmentSet.ModifyEquipmentSet then
                pcall(C_EquipmentSet.ModifyEquipmentSet, setID, setName, icon)
            end
            return true, "updated", setID
        else
            -- Set does not exist yet: check capacity limit
            local maxSets = MAX_EQUIPMENT_SETS_PER_PLAYER or 10
            local numSets = (C_EquipmentSet.GetNumEquipmentSets and C_EquipmentSet.GetNumEquipmentSets()) or 0
            if numSets >= maxSets then
                print(string.format("|cffff0000[GearSetImprover]|r Cannot save Equipment Set: maximum limit of %d sets reached! Please delete an unused set in your Character Profile.", maxSets))
                return false, "full"
            end

            if C_EquipmentSet.CreateEquipmentSet then
                local newID = C_EquipmentSet.CreateEquipmentSet(setName, icon)
                if newID == nil and C_EquipmentSet.GetEquipmentSetID then
                    newID = C_EquipmentSet.GetEquipmentSetID(setName)
                end
                if newID ~= nil and C_EquipmentSet.SaveEquipmentSet then
                    if C_EquipmentSet.ClearIgnoredSlotsForSave then
                        pcall(C_EquipmentSet.ClearIgnoredSlotsForSave)
                    end
                    local saveOk = pcall(C_EquipmentSet.SaveEquipmentSet, newID, icon)
                    if not saveOk then
                        pcall(C_EquipmentSet.SaveEquipmentSet, newID)
                    end
                end
                return true, "created", newID
            end
        end
        return false, "unsupported"
    end)

    if ok and res then
        print(string.format("|cff00ff00[GearSetImprover]|r Saved Equipment Set '|cffffcc00%s|r' in Character Profile.", setName))
        if PaperDollEquipmentManagerPane_Update then
            pcall(PaperDollEquipmentManagerPane_Update)
        end
        if GearManagerDialog_Update then
            pcall(GearManagerDialog_Update)
        end
        return true, setName
    elseif not ok then
        print(string.format("|cffff0000[GearSetImprover]|r Error saving equipment set: %s", tostring(res)))
        return false, tostring(res)
    end

    return false
end

function GSI_UI:EquipPreset(macroDef)
    if not macroDef then return end
    if InCombatLockdown and InCombatLockdown() then
        print("|cffff0000[GearSetImprover]|r Cannot equip gear while in combat!")
        return
    end

    local tokens = {}
    for word in (macroDef.command or ""):gmatch("%S+") do
        table.insert(tokens, word:lower())
    end
    if tokens[1] == "/gsi" then table.remove(tokens, 1) end
    if tokens[1] == "equip" or tokens[1] == "bib" then table.remove(tokens, 1) end

    local targetSpec, targetMode = ParseSpecAndModeTokens(tokens)
    if macroDef.specIndex then targetSpec = macroDef.specIndex end
    if macroDef.mode then
        local role = GSI_StatWeights:GetRole(macroDef.specIndex)
        if role == "tank" or (macroDef.mode == "Survival" or macroDef.mode == "Threat" or macroDef.mode == "DMG") then
            targetMode = { type = "tank", value = (macroDef.mode == "Threat" and "DMG" or macroDef.mode) }
        else
            targetMode = { type = "dps", value = macroDef.mode }
        end
    end

    self:EquipBestInBag(targetSpec, targetMode, nil, macroDef)
end

function GSI_UI:EquipBestInBag(targetSpec, targetMode, onDone, targetPreset)
    if InCombatLockdown and InCombatLockdown() then
        print("|cffff0000[GearSetImprover]|r Cannot equip gear while in combat!")
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

    local class = select(2, UnitClass("player")) or "WARRIOR"
    local specIndex = GSI_StatWeights:GetActiveSpecIndex()
    local classData = GSI_ClassicData and GSI_ClassicData.Classes and GSI_ClassicData.Classes[class]
    local specData = classData and classData.specs and classData.specs[specIndex]
    local specName = specData and (specData.name or specData.nameDE) or ("Spec " .. tostring(specIndex))
    local role = GSI_StatWeights:GetRole()
    local modeLabel = ""
    if role == "tank" then
        local tMode = (GearSetImproverDB and GearSetImproverDB.tankMode) or "Survival"
        modeLabel = (tMode == "Survival") and "Survival" or "Threat / DPS"
    else
        local wMode = (GearSetImproverDB and GearSetImproverDB.weightMode) or "ST"
        modeLabel = (wMode == "ST") and "Single Target" or "AoE / Trash"
    end

    print(string.format("|cffffcc00[GearSetImprover]|r Optimizing Best Available Gear for |cff00ff00%s (%s)|r...", specName, modeLabel))

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
                print(string.format("|cffffcc00[GearSetImprover]|r [|cff00ff00%s (%s)|r]: All available upgrades are on locked slots. Unlock them first to equip.", specName, modeLabel))
            else
                print(string.format("|cffffcc00[GearSetImprover]|r [|cff00ff00%s (%s)|r]: Current gear is already optimal! (No upgrades found in bags)", specName, modeLabel))
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

        print(string.format("|cffffcc00[GearSetImprover]|r Found |cff00ff00%d upgrade(s)|r (+%.1f GSI Score) for |cff00ff00%s (%s)|r. Equipping...", #list, totalGain or 0, specName, modeLabel))

        local idx = 1
        GSI_UI.isEquippingAll = true
        local function StepEquip()
            if InCombatLockdown and InCombatLockdown() then
                GSI_UI.isEquippingAll = false
                print("|cffff0000[GearSetImprover]|r Equipping interrupted: entered combat!")
                if onDone then onDone(false, "in_combat") end
                return
            end

            if idx > #list then
                GSI_UI.isEquippingAll = false
                print(string.format("|cff00ff00[GearSetImprover]|r All %d upgrade(s) equipped! Total GSI Score gain: +%.1f for %s (%s).", #list, totalGain or 0, specName, modeLabel))
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

-- ---------------------------------------------------------------
-- Equipment Set per spec
-- Each character can tie one of its Equipment Manager sets to each spec
-- (GearSetImproverDB.specSets["Name-Realm"][specIndex] = set name). When the
-- talent-detected spec changes, that set is put on (queued until combat
-- ends), unless GearSetImproverDB.specSetAutoEquip is false.
-- ---------------------------------------------------------------

local function SpecSetCharKey()
    local name = UnitName and UnitName("player") or "?"
    local realm = GetRealmName and GetRealmName() or "?"
    return tostring(name) .. "-" .. tostring(realm)
end

local function SpecDisplayName(specIndex)
    local class = (GSI_ClassicData and GSI_ClassicData.GetPlayerClass and GSI_ClassicData:GetPlayerClass())
        or select(2, UnitClass("player")) or "WARRIOR"
    local cd = GSI_ClassicData and GSI_ClassicData.Classes and GSI_ClassicData.Classes[class]
    local sd = cd and cd.specs and cd.specs[specIndex]
    return (sd and sd.name) or ("Spec " .. tostring(specIndex))
end

function GSI_UI:GetSpecSetName(specIndex)
    local all = GearSetImproverDB and GearSetImproverDB.specSets
    local t = all and all[SpecSetCharKey()]
    return t and t[tonumber(specIndex) or 0] or nil
end

function GSI_UI:SetSpecSetName(specIndex, setName)
    specIndex = tonumber(specIndex)
    if not specIndex then return end
    if not GearSetImproverDB then GearSetImproverDB = {} end
    GearSetImproverDB.specSets = GearSetImproverDB.specSets or {}
    local key = SpecSetCharKey()
    GearSetImproverDB.specSets[key] = GearSetImproverDB.specSets[key] or {}
    GearSetImproverDB.specSets[key][specIndex] = (setName and setName ~= "") and setName or nil
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

local function WaitForCombatEnd(specIndex)
    pendingSpecSet = specIndex
    if not specSetRegenFrame and CreateFrame then
        specSetRegenFrame = CreateFrame("Frame")
        specSetRegenFrame:SetScript("OnEvent", function(self)
            self:UnregisterEvent("PLAYER_REGEN_ENABLED")
            local spec = pendingSpecSet
            pendingSpecSet = nil
            if spec then GSI_UI:EquipSpecSet(spec) end
        end)
    end
    if specSetRegenFrame then
        specSetRegenFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
    end
end

-- Puts on the set tied to specIndex. quiet: no chat line when nothing is tied.
-- Returns true when the set is on (or was just equipped).
function GSI_UI:EquipSpecSet(specIndex, quiet, verbose)
    specIndex = tonumber(specIndex)
    local setName = specIndex and self:GetSpecSetName(specIndex)
    if not setName then
        if not quiet then
            print(string.format("|cffffcc00[GearSetImprover]|r No Equipment Set chosen for |cff00ff00%s|r. Pick one in the Settings tab.", SpecDisplayName(specIndex)))
        end
        return false
    end
    if not (C_EquipmentSet and C_EquipmentSet.GetEquipmentSetID and C_EquipmentSet.UseEquipmentSet) then
        return false
    end
    local setID = C_EquipmentSet.GetEquipmentSetID(setName)
    if not setID then
        print(string.format("|cffff4444[GearSetImprover]|r Equipment Set '|cffffcc00%s|r' (for %s) no longer exists.", setName, SpecDisplayName(specIndex)))
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
        WaitForCombatEnd(specIndex)
        print(string.format("|cffffcc00[GearSetImprover]|r Equipment Set '|cffffcc00%s|r' will be equipped when combat ends.", setName))
        return false
    end
    local ok = pcall(C_EquipmentSet.UseEquipmentSet, setID)
    if ok then
        print(string.format("|cff00ff00[GearSetImprover]|r Equipped set '|cffffcc00%s|r' for |cff00ff00%s|r.", setName, SpecDisplayName(specIndex)))
    end
    return ok
end

if GSI_StatWeights and GSI_StatWeights.RegisterSpecChangeCallback then
    GSI_StatWeights:RegisterSpecChangeCallback(function(newSpec)
        if not GSI_UI:IsSpecSetAutoEquip() then return end
        GSI_UI:EquipSpecSet(newSpec, true)
    end)
end
