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
        print("|cffff0000[GearSetImprover]|r Cannot create or edit macros while in combat!")
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

        -- A macro without a set of its own (dual spec) has no Equip button
        local textEdge = row.equipBtn
        if def.noSet then
            row.equipBtn:Hide()
            textEdge = row.dragBtn
        else
            row.equipBtn:Show()
        end

        -- Position text elements cleanly without vertical distortion or button overlap
        row.statusBadge:ClearAllPoints()
        row.statusBadge:SetPoint("RIGHT", textEdge, "LEFT", -8, 9)

        row.nameText:ClearAllPoints()
        row.nameText:SetPoint("LEFT", row.macroBtn, "RIGHT", 10, 9)
        row.nameText:SetPoint("RIGHT", row.statusBadge, "LEFT", -8, 0)

        row.cmdText:ClearAllPoints()
        row.cmdText:SetPoint("LEFT", row.macroBtn, "RIGHT", 10, -9)
        row.cmdText:SetPoint("RIGHT", textEdge, "LEFT", -8, -9)

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
    print("  |cff00ff00/gsi set|r - Equip the current spec's Equipment Set (asks which one when there are several)")
    print("  |cff00ff00/gsi toggle|r - Dual spec: switch to the other talent group, then put on that spec's set (the 'GSI Dual Spec' macro)")
    print("  |cff00ff00/gsi go <spec> [mode]|r - Switch to the spec's talent group (dual spec) and put on its set, e.g. |cffffff00/gsi go bear|r")
    print("  |cff00ff00/gsi dump|r - Save item/tooltip/spec diagnostics to SavedVariables (then /reload)")
    print("  |cff00ff00/gsi mode <survival|threat|st|aoe>|r - Switch active mode")
    print("  |cff00ff00/gsi toast|r (or |cff00ff00/gsi testtoast|r) - Test on-screen upgrade toast alert")
    print("  |cff00ff00/gsi anchor|r - Toggle movable screen anchor for upgrade toasts")
    print("  |cff00ff00/gsi help|r - Show this command list")
end

function GSI_UI:GetEquipmentSetNameAndIcon(specIndex, targetMode, explicitPreset)
    if explicitPreset and explicitPreset.name and not explicitPreset.noSet then
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
    if not macroDef or macroDef.noSet then return end
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
-- [specIndex] is a list of set names (an older single name still reads), an
-- empty list when every set was taken off. nil: Auto, the sets GSI saved.
local function StoredSpecSets(specIndex)
    local all = GearSetImproverDB and GearSetImproverDB.specSets
    local t = all and all[SpecSetCharKey()]
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
    local key = SpecSetCharKey()
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
    local key = SpecSetCharKey()
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
        if p.specIndex == specIndex and p.mode and Trim16(p.name) == setName then
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
    return mode and (MODE_LABELS[mode] or mode) or nil
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
    local preset = PresetModeOf(specIndex, setName)
    local t = StoredSetModes(specIndex, true)
    if nextMode == preset then
        t[setName] = nil
    elseif nextMode == nil then
        t[setName] = false
    else
        t[setName] = nextMode
    end
    -- Tooltip lines of other specs are scored in the set's mode
    if GSI_TooltipHook and GSI_TooltipHook.RefreshShownTooltips then
        pcall(GSI_TooltipHook.RefreshShownTooltips, GSI_TooltipHook)
    end
    return nextMode
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
    local t = all and all[SpecSetCharKey()]
    local g = t and tonumber(t[tonumber(specIndex) or 0])
    if g == 1 or g == 2 then return g end
    return nil
end

function GSI_UI:SetSpecTalentGroup(specIndex, group)
    specIndex = tonumber(specIndex)
    if not specIndex then return end
    if not GearSetImproverDB then GearSetImproverDB = {} end
    GearSetImproverDB.specTalentGroups = GearSetImproverDB.specTalentGroups or {}
    local key = SpecSetCharKey()
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
    print(string.format("|cffffcc00[GearSetImprover]|r Weights: |cff00ff00%s|r (set '|cffffcc00%s|r').",
        MODE_LABELS[value] or value, setName))
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
        print(string.format("|cffff4444[GearSetImprover]|r Equipment Set '|cffffcc00%s|r' no longer exists.", setName))
        return false
    end
    ApplySetWeightMode(specIndex, setName)
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
    headerTag:SetText("CHOOSE EQUIPMENT SET")

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
    hint:SetText("Click a set to put it on")

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
    keepLabel:SetText("Keep current gear")
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
    f.title:SetText("|cff" .. hex .. SpecDisplayName(specIndex) .. "|r: which set?")
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
            b.tag:SetText("ON")
            b.tag:SetTextColor(0.25, 1.0, 0.62, 1)
        elseif c.spec ~= specIndex then
            -- A tree mate's set (Bear while Cat is detected)
            b.tag:SetText(SpecDisplayName(c.spec))
            b.tag:SetTextColor(0.62, 0.66, 0.74, 1)
        else
            -- The weights the set turns on
            local m = GSI_UI:GetSetMode(c.spec, c.name)
            b.tag:SetText(m and string.upper(GSI_UI:GetModeLabel(m)) or "")
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

-- A set put on any other way (the character pane's Equipment Manager,
-- another addon) turns its weights on too, when it is one of the sets of the
-- spec played; a set of Bear or Cat while the other is played makes that the
-- feral role first, as the "which set?" prompt does.
do
    local swapFrame = CreateFrame and CreateFrame("Frame")
    if swapFrame then
        swapFrame:SetScript("OnEvent", function(_, _, result, setID)
            if not (result and setID and C_EquipmentSet and C_EquipmentSet.GetEquipmentSetInfo) then return end
            local okI, name = pcall(C_EquipmentSet.GetEquipmentSetInfo, setID)
            if not okI or not name then return end
            local SW = GSI_StatWeights
            local active = SW and SW.GetActiveSpecIndex and SW:GetActiveSpecIndex()
            if not active then return end
            for _, c in ipairs(SpecSetChoices(active, true)) do
                if c.name == name then
                    if c.spec ~= active then
                        SW:ChooseSpec(c.spec)
                        pcall(function() GSI_UI:UpdateSpecButton() end)
                    end
                    ApplySetWeightMode(c.spec, name)
                    return
                end
            end
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
        print("|cffff0000[GearSetImprover]|r Cannot change specialization or gear while in combat!")
        return
    end
    if SwitchUnderWay() then
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
    StartPendingGo(nil, target)
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
            StartPendingGo(specIndex, group)
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
            print("|cffffcc00[GearSetImprover]|r Talent group switch interrupted; press the macro again to retry.")
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
