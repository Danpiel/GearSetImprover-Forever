-- ============================================================
-- GearSetImprover -- UI_Tab_Weights.lua (WoW Forever)
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

-- TAB 3: STAT WEIGHTS
-- ---------------------------------------------------------------
local function FormatProfileBtnText(btn, arrow)
    local fs = btn and btn:GetFontString()
    if not fs then return end
    fs:ClearAllPoints()
    fs:SetPoint("LEFT", btn, "LEFT", 8, 0)
    if arrow then
        fs:SetPoint("RIGHT", arrow, "LEFT", -4, 0)
    else
        fs:SetPoint("RIGHT", btn, "RIGHT", -22, 0)
    end
    fs:SetJustifyH("LEFT")
    fs:SetWordWrap(false)
end

local function CollectEditBoxWeights(parent)
    local collected = {}
    local existing = GSI_StatWeights and GSI_StatWeights.GetWeights and GSI_StatWeights:GetWeights()
    if type(existing) == "table" then
        for k, v in pairs(existing) do
            if type(v) == "number" then
                collected[k] = v
            end
        end
    end
    for k, box in pairs((parent and parent.editBoxes) or {}) do
        collected[k] = tonumber(box:GetText()) or 0
    end
    return collected
end

-- ---------------------------------------------------------------
-- PROFILE PROMPT MODAL (NEW / RENAME)
-- ---------------------------------------------------------------
function GSI_UI:OpenProfilePromptModal(parent, mode, currentName)
    if not self.profilePromptFrame then
        local f = CreateFrame("Frame", "GSI_ProfilePromptModal", UIParent, BACKDROP_TEMPLATE)
        f:SetSize(360, 160)
        f:SetPoint("CENTER", UIParent, "CENTER", 0, 50)
        f:EnableMouse(true)
        f:SetMovable(true)
        f:RegisterForDrag("LeftButton")
        f:SetScript("OnDragStart", f.StartMoving)
        f:SetScript("OnDragStop", f.StopMovingOrSizing)
        f:SetFrameStrata("FULLSCREEN_DIALOG")
        f:SetFrameLevel(600)
        SkinFrame(f, "dialog")
        f:SetBackdropColor(0.06, 0.06, 0.08, 0.98)
        f:SetBackdropBorderColor(0.18, 0.18, 0.22, 1)

        f.header = GSI_UI:CreateText(f, "TITLE", "")
        f.header:SetPoint("TOPLEFT", 16, -16)

        f.subText = GSI_UI:CreateText(f, "SMALL", L["Enter profile name:"])
        f.subText:SetPoint("TOPLEFT", 16, -42)

        local eb = CreateFrame("EditBox", nil, f, BACKDROP_TEMPLATE)
        eb:SetSize(328, 26)
        eb:SetPoint("TOPLEFT", 16, -65)
        eb:SetFont(GSI_UI:GetFontPath(), 11, "")
        eb:SetTextInsets(6, 6, 0, 0)
        SkinFrame(eb)
        eb:SetBackdropColor(0.15, 0.15, 0.15, 1)
        if eb.SetTextColor then eb:SetTextColor(1, 1, 1, 1) end
        eb:SetAutoFocus(true)
        f.editBox = eb

        local okBtn = CreateFrame("Button", nil, f, BACKDROP_TEMPLATE)
        okBtn:SetSize(100, 24)
        okBtn:SetPoint("BOTTOMRIGHT", -16, 14)
        SkinButton(okBtn)
        f.okBtn = okBtn

        local cancelBtn = CreateFrame("Button", nil, f, BACKDROP_TEMPLATE)
        cancelBtn:SetSize(90, 24)
        cancelBtn:SetPoint("RIGHT", okBtn, "LEFT", -10, 0)
        cancelBtn:SetText(L["Cancel"])
        SkinButton(cancelBtn)
        cancelBtn:SetScript("OnClick", function() f:Hide() end)
        f.cancelBtn = cancelBtn

        local topClose = CreateFrame("Button", nil, f, BACKDROP_TEMPLATE)
        topClose:SetSize(22, 22)
        topClose:SetPoint("TOPRIGHT", -6, -6)
        topClose:SetText("X")
        SkinButton(topClose, true)
        topClose:SetScript("OnClick", function() f:Hide() end)

        eb:SetScript("OnEscapePressed", function() f:Hide() end)
        eb:SetScript("OnEnterPressed", function() f.okBtn:Click() end)

        if self.RegisterModalForEscape then
            self:RegisterModalForEscape(f)
        end

        self.profilePromptFrame = f
    end

    local f = self.profilePromptFrame
    local eb = f.editBox
    local specKey = GSI_StatWeights:GetSpecKey()

    if mode == "NEW" then
        f.header:SetText(L["New Stat Weight Profile"])
        f.okBtn:SetText(L["Create"])
        eb:SetText("")
        eb:SetFocus()
        f.okBtn:SetScript("OnClick", function()
            local name = eb:GetText()
            if name and name:gsub("%s+", "") ~= "" then
                name = name:gsub("^%s+", ""):gsub("%s+$", "")
                local collected = CollectEditBoxWeights(parent)
                GSI_StatWeights:SaveProfile(specKey, name, collected)
                print(string.format(L["|cff00ff00[GearSetImprover]|r Profile |cffffcc00%s|r created!"], name))
                f:Hide()
                GSI_UI:UpdateWeights(parent)
                GSI_UI:RefreshPanel(true)
            end
        end)
    elseif mode == "RENAME" then
        f.header:SetText(L["Rename Profile"])
        f.okBtn:SetText(L["Save"])
        eb:SetText(currentName or "")
        eb:HighlightText()
        eb:SetFocus()
        f.okBtn:SetScript("OnClick", function()
            local newName = eb:GetText()
            if newName and newName:gsub("%s+", "") ~= "" and newName ~= currentName then
                newName = newName:gsub("^%s+", ""):gsub("%s+$", "")
                GSI_StatWeights:RenameProfile(specKey, currentName, newName)
                print(string.format(L["|cff00ff00[GearSetImprover]|r Profile renamed to |cffffcc00%s|r!"], newName))
                f:Hide()
                GSI_UI:UpdateWeights(parent)
                GSI_UI:RefreshPanel(true)
            end
        end)
    end

    f:Show()
end

-- ---------------------------------------------------------------
-- TAB 3: STAT WEIGHTS
-- ---------------------------------------------------------------
function GSI_UI:DrawWeights(parent)
    local title = GSI_UI:CreateText(parent, "TITLE", L["Customize Stat Weights"])
    title:SetPoint("TOPLEFT", 15, -12)
    title:SetPoint("TOPRIGHT", -20, -12)
    title:SetWordWrap(false)

    -- Profile Selector Bar
    local profLabel = GSI_UI:CreateText(parent, "CARD_TITLE", L["Profile:"])
    profLabel:SetPoint("TOPLEFT", 15, -38)

    local profBtn = CreateFrame("Button", nil, parent, BACKDROP_TEMPLATE)
    profBtn:SetSize(180, 24)
    profBtn:SetPoint("LEFT", profLabel, "RIGHT", 8, 0)
    SkinButton(profBtn)
    parent.profileBtn = profBtn

    local profArrow = profBtn:CreateTexture(nil, "ARTWORK")
    profArrow:SetSize(12, 12)
    profArrow:SetPoint("RIGHT", profBtn, "RIGHT", -6, 0)
    profArrow:SetTexture("Interface\\ChatFrame\\ChatFrameExpandArrow")
    parent.profileArrow = profArrow
    FormatProfileBtnText(profBtn, profArrow)

    local profMenu = CreateFrame("Frame", "GSI_ProfileDropdownMenu", UIParent, BACKDROP_TEMPLATE)
    profMenu:SetFrameStrata("DIALOG")
    profMenu:SetClampedToScreen(true)
    SkinFrame(profMenu, "dialog")
    profMenu:SetBackdropColor(0.06, 0.06, 0.08, 0.98)
    profMenu:SetBackdropBorderColor(0.18, 0.18, 0.22, 1)
    profMenu:Hide()
    parent.profileMenu = profMenu

    local function CloseProfileMenu()
        profMenu:Hide()
    end

    local function OpenProfileMenu()
        if profMenu:IsShown() then
            profMenu:Hide()
            return
        end

        local specKey = GSI_StatWeights:GetSpecKey()
        local activeProf = GSI_StatWeights:GetActiveProfileName(specKey)
        local profiles = GSI_StatWeights:GetProfiles(specKey)

        if profMenu.buttons then
            for _, b in ipairs(profMenu.buttons) do b:Hide() end
        else
            profMenu.buttons = {}
        end

        local items = { "Default (Baseline)" }
        for _, pName in ipairs(profiles) do
            table.insert(items, pName)
        end

        local menuWidth = 200
        local itemHeight = 22
        local totalHeight = (#items * itemHeight) + 12

        profMenu:SetSize(menuWidth, totalHeight)
        profMenu:ClearAllPoints()
        profMenu:SetPoint("TOPLEFT", profBtn, "BOTTOMLEFT", 0, -2)

        for i, name in ipairs(items) do
            local b = profMenu.buttons[i]
            if not b then
                b = CreateFrame("Button", nil, profMenu, BACKDROP_TEMPLATE)
                b:SetSize(menuWidth - 12, itemHeight)
                SkinButton(b)
                profMenu.buttons[i] = b
            end

            b:ClearAllPoints()
            b:SetPoint("TOPLEFT", profMenu, "TOPLEFT", 6, -6 - ((i - 1) * itemHeight))

            local isSelected = (name == "Default (Baseline)" and not activeProf) or (activeProf == name)
            if isSelected then
                b:SetText(string.format("  |cff00ff00%s|r", L[name]))
            else
                b:SetText(string.format("  %s", L[name]))
            end
            local txt = b:GetFontString()
            if txt then
                txt:ClearAllPoints()
                txt:SetPoint("LEFT", b, "LEFT", 6, 0)
                txt:SetPoint("RIGHT", b, "RIGHT", -6, 0)
                txt:SetJustifyH("LEFT")
                txt:SetWordWrap(false)
            end

            b:SetScript("OnClick", function()
                CloseProfileMenu()
                if name == "Default (Baseline)" then
                    GSI_StatWeights:SetActiveProfile(specKey, nil)
                else
                    GSI_StatWeights:SetActiveProfile(specKey, name)
                end
                GSI_UI:UpdateWeights(parent)
                GSI_UI:RefreshPanel(true)
            end)
            b:Show()
        end

        profMenu:Show()
    end

    profBtn:SetScript("OnClick", OpenProfileMenu)

    local newProfBtn = CreateFrame("Button", nil, parent, BACKDROP_TEMPLATE)
    newProfBtn:SetSize(60, 24)
    newProfBtn:SetPoint("LEFT", profBtn, "RIGHT", 6, 0)
    newProfBtn:SetText(L["+ New"])
    SkinButton(newProfBtn)
    newProfBtn:SetScript("OnClick", function()
        CloseProfileMenu()
        GSI_UI:OpenProfilePromptModal(parent, "NEW")
    end)
    parent.newProfBtn = newProfBtn

    local renameProfBtn = CreateFrame("Button", nil, parent, BACKDROP_TEMPLATE)
    renameProfBtn:SetSize(68, 24)
    renameProfBtn:SetPoint("LEFT", newProfBtn, "RIGHT", 6, 0)
    renameProfBtn:SetText(L["Rename"])
    SkinButton(renameProfBtn)
    renameProfBtn:SetScript("OnClick", function()
        CloseProfileMenu()
        local specKey = GSI_StatWeights:GetSpecKey()
        local act = GSI_StatWeights:GetActiveProfileName(specKey)
        if act then
            GSI_UI:OpenProfilePromptModal(parent, "RENAME", act)
        end
    end)
    parent.renameProfBtn = renameProfBtn

    local deleteProfBtn = CreateFrame("Button", nil, parent, BACKDROP_TEMPLATE)
    deleteProfBtn:SetSize(65, 24)
    deleteProfBtn:SetPoint("LEFT", renameProfBtn, "RIGHT", 6, 0)
    deleteProfBtn:SetText(L["Delete"])
    SkinButton(deleteProfBtn, true)
    deleteProfBtn:SetScript("OnClick", function()
        CloseProfileMenu()
        local specKey = GSI_StatWeights:GetSpecKey()
        local act = GSI_StatWeights:GetActiveProfileName(specKey)
        if act then
            GSI_StatWeights:DeleteProfile(specKey, act)
            print(string.format(L["|cffff4444[GearSetImprover]|r Profile |cffffcc00%s|r deleted."], act))
            GSI_UI:UpdateWeights(parent)
            GSI_UI:RefreshPanel(true)
        end
    end)
    parent.deleteProfBtn = deleteProfBtn

    local desc = GSI_UI:CreateText(parent, "BODY", L["Adjust stat weights for the active profile (negative numbers allowed for weapon speed):"])
    desc:SetPoint("TOPLEFT", 15, -68)
    desc:SetPoint("TOPRIGHT", -20, -68)
    desc:SetWordWrap(false)

    local scroll = CreateFrame("ScrollFrame", "GSI_WeightsScroll", parent, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 10, -90)
    scroll:SetPoint("BOTTOMRIGHT", -26, 45)
    if GSI_UI and GSI_UI.SkinScrollBar then
        GSI_UI:SkinScrollBar(scroll)
    end

    local child = CreateFrame("Frame", nil, scroll)
    child:SetSize(706, 1080)
    scroll:SetScrollChild(child)
    parent.scrollChild = child
    parent.editBoxes = {}
    parent.sliders = {}
    parent.schoolRows = {}
    parent.resistRows = {}

    local STAT_LIST = {
        { key = "Stamina",            name = L["Stamina"] },
        { key = "Agility",            name = L["Agility"] },
        { key = "Armor",              name = L["Armor"] },
        { key = "Defense",            name = L["Defense"] },
        { key = "Dodge",              name = L["Dodge"] },
        { key = "Strength",           name = L["Strength"] },
        { key = "AttackPower",        name = L["Attack Power (AP)"] },
        { key = "Hit",                name = L["Hit Chance (% Hit)"] },
        { key = "Crit",               name = L["Critical Strike (% Crit)"] },
        { key = "Haste",              name = L["Haste"] },
        { key = "ArmorPenetration",   name = L["Armor Penetration"] },
        { key = "WeaponDamage",       name = L["Weapon Damage (DPS)"] },
        { key = "WeaponDamageOH",     name = L["Off-Hand DPS (OH)"] },
        { key = "FlatWeaponDamage",   name = L["Weapon Damage (Flat)"] },
        { key = "RangedDPS",          name = L["Ranged Weapon DPS"] },
        { key = "WeaponSpeed",        name = L["Weapon Speed (Speed, +/-)"], isSpeed = true },
        { key = "Parry",              name = L["Parry"] },
        { key = "Block",              name = L["Block Chance"] },
        { key = "BlockValue",         name = L["Block Value"] },
        { key = "Intellect",          name = L["Intellect"] },
        { key = "Spirit",             name = L["Spirit"] },
        { key = "Mana",               name = L["Max Mana"] },
        { key = "SpellPower",         name = L["Spell Power (SP)"] },
        { key = "SpellPenetration",   name = L["Spell Penetration"] },
        { key = "HealingPower",       name = L["Healing Power"] },
        { key = "MP5",                name = L["Mana per 5 sec (MP5)"] },
        { key = "HP5",                name = L["Health per 5 sec (HP5)"] },
        { key = "RangedAttackPower",  name = L["Ranged AP (RAP)"] },
        { key = "FeralAttackPower",   name = L["Feral Attack Power (FAP)"] },
        { key = "WeaponSkill",        name = L["Weapon Skill"] },
        { key = "AvoidanceReduction", name = L["Avoidance Reduction"] },
        { key = "Speed",              name = L["Movement Speed (%)"] },
    }

    local SCHOOL_LIST = {
        { key = "ArcaneSpellPower", elem = "Arcane", name = L["Arcane"], color = "ffff77ff" },
        { key = "FireSpellPower",   elem = "Fire",   name = L["Fire"],   color = "ffff6600" },
        { key = "FrostSpellPower",  elem = "Frost",  name = L["Frost"],  color = "ff00ffff" },
        { key = "ShadowSpellPower", elem = "Shadow", name = L["Shadow"], color = "ffa335ee" },
        { key = "NatureSpellPower", elem = "Nature", name = L["Nature"], color = "ff44ff44" },
        { key = "HolySpellPower",   elem = "Holy",   name = L["Holy"],   color = "ffffffaa" },
    }

    local RESIST_LIST = {
        { key = "FireResist",   elem = "Fire",   name = L["Fire"],   color = "ffff6600" },
        { key = "NatureResist", elem = "Nature", name = L["Nature"], color = "ff44ff44" },
        { key = "FrostResist",  elem = "Frost",  name = L["Frost"],  color = "ff00ffff" },
        { key = "ShadowResist", elem = "Shadow", name = L["Shadow"], color = "ffa335ee" },
        { key = "ArcaneResist", elem = "Arcane", name = L["Arcane"], color = "ffff77ff" },
    }

    local function SetToggleRowVisuals(row, isChecked)
        row.cb:SetChecked(isChecked)
        local thumb = row.slider and row.slider:GetThumbTexture()
        if isChecked then
            row.lbl:SetText(string.format("|c%s%s|r", row.itemColor, row.itemName))
            row.slider:Enable()
            row.slider:EnableMouse(true)
            row.slider:SetAlpha(1.0)
            if row.sliderBg then row.sliderBg:SetAlpha(1.0) end
            if thumb and thumb.SetVertexColor then thumb:SetVertexColor(0.65, 0.65, 0.65, 1) end
            row.eb:EnableMouse(true)
            row.eb:SetAlpha(1.0)
            if row.eb.SetTextColor then row.eb:SetTextColor(1, 1, 1, 1) end
            row.eb:SetBackdropBorderColor(0.2, 0.2, 0.2, 1)
        else
            row.lbl:SetText(string.format("|cff777777%s|r", row.itemName))
            row.slider:Disable()
            row.slider:EnableMouse(false)
            row.slider:SetAlpha(0.35)
            if row.sliderBg then row.sliderBg:SetAlpha(0.35) end
            if thumb and thumb.SetVertexColor then thumb:SetVertexColor(0.35, 0.35, 0.35, 0.5) end
            row.eb:EnableMouse(false)
            row.eb:ClearFocus()
            row.eb:SetAlpha(0.35)
            if row.eb.SetTextColor then row.eb:SetTextColor(0.5, 0.5, 0.5, 1) end
            row.eb:SetBackdropBorderColor(0.15, 0.15, 0.15, 0.5)
        end
    end
    parent.SetSchoolRowVisuals = SetToggleRowVisuals
    parent.SetResistRowVisuals = SetToggleRowVisuals

    local function CreateCategoryHeader(yOffset, headerTitle)
        local hdr = CreateFrame("Frame", nil, child)
        hdr:SetSize(696, 24)
        hdr:SetPoint("TOPLEFT", child, "TOPLEFT", 6, -yOffset)

        local titleFs = GSI_UI:CreateText(hdr, "CARD_TITLE", headerTitle)
        titleFs:SetPoint("LEFT", 0, 0)

        local line = hdr:CreateTexture(nil, "ARTWORK")
        line:SetPoint("LEFT", titleFs, "RIGHT", 10, 0)
        line:SetPoint("RIGHT", hdr, "RIGHT", -8, 0)
        line:SetHeight(1)
        line:SetColorTexture(0.35, 0.35, 0.35, 0.6)
        return hdr
    end

    local function CreateWeightRow(yOffset, item, checkPrefix, defaultVal, minVal)
        local row = CreateFrame("Frame", nil, child)
        row:SetSize(696, 26)
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", child, "TOPLEFT", 6, -yOffset)

        local cb, lbl
        if checkPrefix then
            cb = CreateFrame("CheckButton", checkPrefix .. item.elem, row, "UICheckButtonTemplate")
            cb:SetSize(20, 20)
            cb:SetPoint("LEFT", 0, 0)

            lbl = GSI_UI:CreateText(row, "STAT_LABEL", item.name)
            lbl:SetPoint("LEFT", cb, "RIGHT", 6, 0)
            lbl:SetWidth(184)
        else
            lbl = GSI_UI:CreateText(row, "STAT_LABEL", item.name)
            lbl:SetPoint("LEFT", 0, 0)
            lbl:SetWidth(210)
        end
        lbl:SetJustifyH("LEFT")
        lbl:SetWordWrap(false)

        local eb = CreateFrame("EditBox", nil, row, BACKDROP_TEMPLATE)
        eb:SetSize(65, 22)
        eb:SetPoint("RIGHT", -8, 0)
        eb:SetFont(GSI_UI:GetFontPath(), 11, "")
        eb:SetJustifyH("CENTER")
        eb:SetTextInsets(4, 4, 0, 0)
        eb:SetAutoFocus(false)
        SkinFrame(eb)
        eb:SetBackdropColor(0.15, 0.15, 0.15, 1)
        if eb.SetTextColor then eb:SetTextColor(1, 1, 1, 1) end
        eb:SetText(FormatWeight(defaultVal or 0))

        local sliderBg = CreateFrame("Frame", nil, row, BACKDROP_TEMPLATE)
        sliderBg:SetPoint("LEFT", lbl, "RIGHT", 15, 0)

        local slider = CreateFrame("Slider", nil, row)
        slider:SetPoint("LEFT", lbl, "RIGHT", 15, 0)
        SkinSlider(slider, sliderBg, 378, 8)
        slider:SetMinMaxValues(minVal or 0, 50)
        slider:SetValue(defaultVal or 0)
        slider:SetValueStep(0.05)

        slider:SetScript("OnValueChanged", function(_, val)
            if parent.isUpdatingUI then return end
            local v = math.floor(val * 100 + 0.5) / 100
            if not eb:HasFocus() then
                eb:SetText(FormatWeight(v))
            end
        end)

        eb:SetScript("OnTextChanged", function(self, userInput)
            if userInput and not parent.isUpdatingUI then
                local v = tonumber(self:GetText())
                if v then
                    local sMin, sMax = slider:GetMinMaxValues()
                    local clamped = math.max(sMin, math.min(sMax, v))
                    slider:SetValue(clamped)
                end
            end
        end)

        eb:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
        eb:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
        eb:SetScript("OnEditFocusGained", function(self)
            self:SetBackdropBorderColor(1, 0.82, 0, 1)
            self:HighlightText()
        end)
        eb:SetScript("OnEditFocusLost", function(self)
            self:SetBackdropBorderColor(0.2, 0.2, 0.2, 1)
            self:HighlightText(0, 0)
        end)

        row.cb = cb
        row.lbl = lbl
        row.eb = eb
        row.slider = slider
        row.sliderBg = sliderBg

        parent.editBoxes[item.key] = eb
        parent.sliders[item.key] = slider
        return row
    end

    local yOff = 0

    -- Standard Stats Rows
    for _, item in ipairs(STAT_LIST) do
        CreateWeightRow(yOff, item, nil, 0, item.isSpeed and -50 or 0)
        yOff = yOff + 28
    end

    -- Category: Magic Schools (School Spell Power)
    yOff = yOff + 8
    CreateCategoryHeader(yOff, L["|cffffcc00Magic Schools (Spell Power)|r"])
    yOff = yOff + 28

    for _, item in ipairs(SCHOOL_LIST) do
        local row = CreateWeightRow(yOff, item, "GSI_WeightSchoolCheck_", 1.0, 0)
        row.cb:SetScript("OnClick", function(self)
            local isChecked = self:GetChecked()
            local specKey = GSI_StatWeights:GetSpecKey()
            GSI_StatWeights:SetSchoolEnabled(specKey, item.key, isChecked)
            SetToggleRowVisuals(row, isChecked)
            GSI_ItemScore:ResetCache()
        end)

        row.elem = item.elem
        row.itemColor = item.color
        row.itemName = item.name
        parent.schoolRows[item.key] = row

        yOff = yOff + 28
    end

    -- Category: Resistances
    yOff = yOff + 8
    CreateCategoryHeader(yOff, L["|cffffcc00Resistances|r"])
    yOff = yOff + 28

    for _, item in ipairs(RESIST_LIST) do
        local row = CreateWeightRow(yOff, item, "GSI_WeightResistCheck_", 5.0, 0)
        row.cb:SetScript("OnClick", function(self)
            local isChecked = self:GetChecked()
            if not GearSetImproverDB.requiredResists then
                GearSetImproverDB.requiredResists = {}
            end
            GearSetImproverDB.requiredResists[item.elem] = isChecked
            SetToggleRowVisuals(row, isChecked)
            GSI_ItemScore:ResetCache()
        end)

        row.elem = item.elem
        row.itemColor = item.color
        row.itemName = item.name
        parent.resistRows[item.elem] = row

        yOff = yOff + 28
    end

    child:SetHeight(yOff + 30)

    -- Save, Reset Defaults, Export & Import Buttons
    local saveBtn = CreateFrame("Button", nil, parent, BACKDROP_TEMPLATE)
    saveBtn:SetSize(90, 26)
    saveBtn:SetPoint("BOTTOMRIGHT", -20, 12)
    saveBtn:SetText(L["Save"])
    SkinButton(saveBtn, nil, true)
    saveBtn:SetScript("OnClick", function()
        local specKey = GSI_StatWeights:GetSpecKey()
        local activeProf = GSI_StatWeights:GetActiveProfileName(specKey) or "Custom"

        local collected = CollectEditBoxWeights(parent)
        GSI_StatWeights:SaveProfile(specKey, activeProf, collected)
        print(string.format(L["|cff00ff00[GearSetImprover]|r Stat weights for |cffffcc00%s (%s)|r saved successfully!"], specKey, activeProf))
        GSI_ItemScore:ResetCache()
        GSI_UI:UpdateWeights(parent)
        GSI_UI:RefreshPanel(true)
    end)

    local resetBtn = CreateFrame("Button", nil, parent, BACKDROP_TEMPLATE)
    resetBtn:SetSize(120, 26)
    resetBtn:SetPoint("RIGHT", saveBtn, "LEFT", -8, 0)
    resetBtn:SetText(L["Reset Defaults"])
    SkinButton(resetBtn)
    resetBtn:SetScript("OnClick", function()
        local specKey = GSI_StatWeights:GetSpecKey()
        GSI_StatWeights:SetActiveProfile(specKey, nil)
        if GearSetImproverDB.requiredResists then
            GearSetImproverDB.requiredResists = {}
        end
        if GearSetImproverDB.enabledSpellSchools then
            GearSetImproverDB.enabledSpellSchools[specKey] = nil
        end
        GSI_UI:UpdateWeights(parent)
        GSI_ItemScore:ResetCache()
        GSI_UI:RefreshPanel(true)
        print(string.format(L["|cff00ff00[GearSetImprover]|r Default weights for |cffffcc00%s|r restored!"], specKey))
    end)

    local exportBtn = CreateFrame("Button", nil, parent, BACKDROP_TEMPLATE)
    exportBtn:SetSize(80, 26)
    exportBtn:SetPoint("RIGHT", resetBtn, "LEFT", -8, 0)
    exportBtn:SetText(L["Export"])
    SkinButton(exportBtn)
    exportBtn:SetScript("OnClick", function()
        GSI_UI:OpenWeightsIOModal(parent, "EXPORT")
    end)

    local importBtn = CreateFrame("Button", nil, parent, BACKDROP_TEMPLATE)
    importBtn:SetSize(80, 26)
    importBtn:SetPoint("RIGHT", exportBtn, "LEFT", -8, 0)
    importBtn:SetText(L["Import"])
    SkinButton(importBtn)
    importBtn:SetScript("OnClick", function()
        GSI_UI:OpenWeightsIOModal(parent, "IMPORT")
    end)
end

function GSI_UI:UpdateWeights(parent)
    if not parent or not parent.editBoxes then return end
    parent.isUpdatingUI = true

    local weights = {}
    pcall(function() weights = GSI_StatWeights:GetWeights() end)
    weights = weights or {}

    local specKey = GSI_StatWeights:GetSpecKey()
    local activeProf = GSI_StatWeights:GetActiveProfileName(specKey)

    -- Update profile dropdown button text and controls
    if parent.profileBtn then
        local displayName = activeProf or "Default (Baseline)"
        parent.profileBtn:SetText(L[displayName])
        FormatProfileBtnText(parent.profileBtn, parent.profileArrow)
        if parent.renameProfBtn then
            if activeProf then
                parent.renameProfBtn:Enable()
                parent.renameProfBtn:SetAlpha(1.0)
            else
                parent.renameProfBtn:Disable()
                parent.renameProfBtn:SetAlpha(0.4)
            end
        end
        if parent.deleteProfBtn then
            if activeProf then
                parent.deleteProfBtn:Enable()
                parent.deleteProfBtn:SetAlpha(1.0)
            else
                parent.deleteProfBtn:Disable()
                parent.deleteProfBtn:SetAlpha(0.4)
            end
        end
    end

    -- 1. Update standard stat rows
    for k, eb in pairs(parent.editBoxes) do
        if not (parent.schoolRows and parent.schoolRows[k]) and not k:find("Resist$") then
            local val = weights[k] or 0
            eb:SetText(FormatWeight(val))
            local sl = parent.sliders and parent.sliders[k]
            if sl then
                local minVal, maxVal = sl:GetMinMaxValues()
                local clampVal = math.min(maxVal, math.max(minVal, val))
                sl:SetValue(clampVal)
            end
        end
    end

    -- 2. Update magic school rows
    if parent.schoolRows then
        for sKey, row in pairs(parent.schoolRows) do
            local eb = parent.editBoxes[sKey]
            local sl = parent.sliders and parent.sliders[sKey]
            local isEnabled = GSI_StatWeights:IsSchoolEnabled(specKey, sKey)
            local val = weights[sKey] or 0
            if val == 0 then
                val = GSI_StatWeights:GetSchoolWeight(sKey)
            end

            if eb then eb:SetText(FormatWeight(val)) end
            if sl then
                local minVal, maxVal = sl:GetMinMaxValues()
                local clampVal = math.min(maxVal, math.max(minVal, val))
                sl:SetValue(clampVal)
            end

            if parent.SetSchoolRowVisuals then
                parent.SetSchoolRowVisuals(row, isEnabled)
            end
        end
    end

    -- 3. Update resistance rows
    local resistMap = {
        FireResist   = "Fire",
        NatureResist = "Nature",
        FrostResist  = "Frost",
        ShadowResist = "Shadow",
        ArcaneResist = "Arcane",
    }
    local reqResists = GearSetImproverDB and GearSetImproverDB.requiredResists
    for rKey, elem in pairs(resistMap) do
        local eb = parent.editBoxes[rKey]
        local sl = parent.sliders and parent.sliders[rKey]
        local row = parent.resistRows and parent.resistRows[elem]

        local val = GSI_StatWeights:GetResistWeight(rKey)

        if eb then
            eb:SetText(FormatWeight(val))
        end
        if sl then
            local minVal, maxVal = sl:GetMinMaxValues()
            local clampVal = math.min(maxVal, math.max(minVal, val))
            sl:SetValue(clampVal)
        end

        local isChecked = (reqResists and reqResists[elem]) or false
        if row and parent.SetResistRowVisuals then
            parent.SetResistRowVisuals(row, isChecked)
        end
    end

    parent.isUpdatingUI = false
end

-- ---------------------------------------------------------------
-- STAT WEIGHTS: EXPORT & IMPORT (GSI / PAWN COMPATIBLE)
-- ---------------------------------------------------------------
function GSI_UI:GetWeightsExportString(targetSpecKey)
    local specKey = targetSpecKey or GSI_StatWeights:GetSpecKey()
    local weights = GSI_StatWeights:GetWeights() or {}
    local parts = {}
    for statKey, val in pairs(weights) do
        if type(val) == "number" and val ~= 0 then
            table.insert(parts, { key = statKey, val = val })
        end
    end
    table.sort(parts, function(a, b) return a.key < b.key end)
    local formatted = {}
    for _, item in ipairs(parts) do
        local entry = string.format("%s=%s", item.key, FormatWeight(item.val))
        table.insert(formatted, entry)
    end
    return string.format("( GSI:v2:%s: %s )", specKey or "Custom", table.concat(formatted, ", "))
end

local GSI_WEIGHT_ALIASES = {
    agility = "Agility", agi = "Agility",
    strength = "Strength", str = "Strength",
    stamina = "Stamina", sta = "Stamina",
    intellect = "Intellect", int = "Intellect",
    spirit = "Spirit", spi = "Spirit",
    armor = "Armor",
    defense = "Defense", def = "Defense", defrating = "Defense",
    dodge = "Dodge", dodgerating = "Dodge",
    parry = "Parry", parryrating = "Parry",
    block = "Block", blockchance = "Block", blockrating = "Block",
    blockvalue = "BlockValue",
    attackpower = "AttackPower", ap = "AttackPower",
    rangedattackpower = "RangedAttackPower", rap = "RangedAttackPower",
    feralattackpower = "FeralAttackPower", feralap = "FeralAttackPower", fap = "FeralAttackPower",
    hit = "Hit", hitrating = "Hit",
    crit = "Crit", critrating = "Crit",
    haste = "Haste", hasterating = "Haste",
    armorpenetration = "ArmorPenetration", armorpen = "ArmorPenetration", arp = "ArmorPenetration", armorpenetrationrating = "ArmorPenetration",
    weapondamage = "WeaponDamage", dps = "WeaponDamage", meleedps = "WeaponDamage",
    weapondamageoh = "WeaponDamageOH", ohdps = "WeaponDamageOH", offhanddps = "WeaponDamageOH",
    flatweapondamage = "FlatWeaponDamage", flatwdps = "FlatWeaponDamage", weaponflatdamage = "FlatWeaponDamage",
    rangeddps = "RangedDPS", rangedweapondps = "RangedDPS", rdps = "RangedDPS",
    weaponspeed = "WeaponSpeed", wpnspeed = "WeaponSpeed",
    speed = "Speed", movementspeed = "Speed", runspeed = "Speed",
    spellpower = "SpellPower", sp = "SpellPower", spelldamage = "SpellPower", spelldmg = "SpellPower",
    spellpiercing = "SpellPenetration", spellpierce = "SpellPenetration", spellpenetration = "SpellPenetration", spellpen = "SpellPenetration",
    healingpower = "HealingPower", healing = "HealingPower", heal = "HealingPower", bonushealing = "HealingPower",
    mana = "Mana", maxmana = "Mana",
    mp5 = "MP5", manaregen = "MP5",
    hp5 = "HP5", healthregen = "HP5", hpregen = "HP5",
    arcanespellpower = "ArcaneSpellPower", arcanesp = "ArcaneSpellPower", arcanedamage = "ArcaneSpellPower",
    firespellpower = "FireSpellPower", firesp = "FireSpellPower", firedamage = "FireSpellPower",
    frostspellpower = "FrostSpellPower", frostsp = "FrostSpellPower", frostdamage = "FrostSpellPower",
    shadowspellpower = "ShadowSpellPower", shadowsp = "ShadowSpellPower", shadowdamage = "ShadowSpellPower",
    naturespellpower = "NatureSpellPower", naturesp = "NatureSpellPower", naturedamage = "NatureSpellPower",
    holyspellpower = "HolySpellPower", holysp = "HolySpellPower", holydamage = "HolySpellPower",
    fireresist = "FireResist", fireresistance = "FireResist",
    natureresist = "NatureResist", natureresistance = "NatureResist",
    frostresist = "FrostResist", frostresistance = "FrostResist",
    shadowresist = "ShadowResist", shadowresistance = "ShadowResist",
    arcaneresist = "ArcaneResist", arcaneresistance = "ArcaneResist",
    weaponskill = "WeaponSkill", skill = "WeaponSkill",
    avoidancereduction = "AvoidanceReduction",
}

function GSI_UI:ParseWeightsString(str)
    if not str or type(str) ~= "string" or str:gsub("%s+", "") == "" then
        return nil, 0, nil, L["The entered string is empty."]
    end

    local parsed = {}
    local count = 0
    local isPawnString = str:find("Pawn:") ~= nil

    for key, val in str:gmatch("([%a_]+)%s*[:=]%s*([%-]?%d+%.?%d*)") do
        local lowerKey = key:lower()
        local actualStat = GSI_WEIGHT_ALIASES[lowerKey]
        if lowerKey == "speed" and isPawnString then
            actualStat = "WeaponSpeed"
        end
        local num = tonumber(val)
        if actualStat and num then
            parsed[actualStat] = num
            count = count + 1
        end
    end

    if count == 0 then
        return nil, 0, nil, L["No valid stat weights found. Supported: Key=Value (GSI or Pawn format)."]
    end

    -- Extract profile name from Pawn or GSI strings if present
    local suggestedName = nil
    local pawnName = str:match('Pawn:[^"]*"([^"]+)"')
    if pawnName and pawnName ~= "" then
        suggestedName = pawnName
    else
        local gsiName = str:match('%a+%-%d+%s*%(([^%)]+)%)')
        if gsiName and gsiName ~= "" then
            suggestedName = gsiName
        end
    end

    return parsed, count, suggestedName, nil
end

function GSI_UI:PromptImportProfileChoice(parent, specKey, parsedWeights, count, suggestedName)
    if not self.importChoiceFrame then
        local f = CreateFrame("Frame", "GSI_ImportProfileChoiceDialog", UIParent, BACKDROP_TEMPLATE)
        f:SetSize(460, 270)
        f:SetPoint("CENTER", 0, 30)
        f:SetMovable(true)
        f:EnableMouse(true)
        f:RegisterForDrag("LeftButton")
        f:SetScript("OnDragStart", f.StartMoving)
        f:SetScript("OnDragStop", f.StopMovingOrSizing)
        f:SetFrameStrata("FULLSCREEN_DIALOG")
        f:SetFrameLevel(600)
        SkinFrame(f)
        f:SetBackdropColor(0.08, 0.08, 0.08, 0.98)
        f:SetBackdropBorderColor(1, 0.82, 0, 1)

        f.header = GSI_UI:CreateText(f, "TITLE", L["Import Stat Weights"])
        f.header:SetPoint("TOPLEFT", 16, -16)

        f.subText = GSI_UI:CreateText(f, "SMALL", "")
        f.subText:SetPoint("TOPLEFT", 16, -42)
        f.subText:SetPoint("RIGHT", -16, 0)
        f.subText:SetJustifyH("LEFT")

        -- Radio Button 1: Overwrite active profile
        local rbOverwrite = CreateFrame("CheckButton", "GSI_ImportRB_Overwrite", f, "UIRadioButtonTemplate")
        rbOverwrite:SetPoint("TOPLEFT", 16, -82)
        rbOverwrite.text = GSI_UI:CreateText(rbOverwrite, "BODY", "")
        rbOverwrite.text:SetPoint("LEFT", rbOverwrite, "RIGHT", 6, 0)
        rbOverwrite.text:SetPoint("RIGHT", f, "RIGHT", -16, 0)
        rbOverwrite.text:SetJustifyH("LEFT")
        f.rbOverwrite = rbOverwrite

        -- Radio Button 2: Create new profile
        local rbNew = CreateFrame("CheckButton", "GSI_ImportRB_New", f, "UIRadioButtonTemplate")
        rbNew:SetPoint("TOPLEFT", 16, -118)
        rbNew.text = GSI_UI:CreateText(rbNew, "BODY", L["Create as new profile:"])
        rbNew.text:SetPoint("LEFT", rbNew, "RIGHT", 6, 0)
        f.rbNew = rbNew

        -- Name EditBox for new profile
        local nameEb = CreateFrame("EditBox", "GSI_ImportProfileNameEB", f, BACKDROP_TEMPLATE)
        nameEb:SetSize(380, 26)
        nameEb:SetPoint("TOPLEFT", 40, -144)
        nameEb:SetFont(GSI_UI:GetFontPath(), 11, "")
        nameEb:SetTextInsets(6, 6, 0, 0)
        SkinFrame(nameEb)
        nameEb:SetBackdropColor(0.15, 0.15, 0.15, 1)
        nameEb:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
        if nameEb.SetTextColor then nameEb:SetTextColor(1, 1, 1, 1) end
        nameEb:SetAutoFocus(false)
        f.nameEb = nameEb

        local function SetChoice(isNew)
            f.isNewChoice = (isNew == true)
            rbNew:SetChecked(isNew == true)
            rbOverwrite:SetChecked(isNew ~= true)
            if isNew then
                nameEb:SetAlpha(1.0)
                nameEb:EnableMouse(true)
                nameEb:SetBackdropBorderColor(1, 0.82, 0, 1)
            else
                nameEb:SetAlpha(0.4)
                nameEb:ClearFocus()
                nameEb:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
            end
        end
        f.SetChoice = SetChoice

        rbOverwrite:SetScript("OnClick", function() SetChoice(false) end)
        rbNew:SetScript("OnClick", function()
            SetChoice(true)
            nameEb:SetFocus()
            nameEb:HighlightText()
        end)

        nameEb:SetScript("OnEditFocusGained", function()
            SetChoice(true)
        end)
        nameEb:SetScript("OnEditFocusLost", function(self)
            if f.isNewChoice then
                self:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)
            end
        end)
        nameEb:SetScript("OnEscapePressed", function() f:Hide() end)

        local okBtn = CreateFrame("Button", nil, f, BACKDROP_TEMPLATE)
        okBtn:SetSize(110, 24)
        okBtn:SetPoint("BOTTOMRIGHT", -16, 14)
        okBtn:SetText(L["Import"])
        SkinButton(okBtn)
        f.okBtn = okBtn

        local cancelBtn = CreateFrame("Button", nil, f, BACKDROP_TEMPLATE)
        cancelBtn:SetSize(90, 24)
        cancelBtn:SetPoint("RIGHT", okBtn, "LEFT", -10, 0)
        cancelBtn:SetText(L["Cancel"])
        SkinButton(cancelBtn)
        cancelBtn:SetScript("OnClick", function() f:Hide() end)
        f.cancelBtn = cancelBtn

        local topClose = CreateFrame("Button", nil, f, BACKDROP_TEMPLATE)
        topClose:SetSize(22, 22)
        topClose:SetPoint("TOPRIGHT", -6, -6)
        topClose:SetText("X")
        SkinButton(topClose, true)
        topClose:SetScript("OnClick", function() f:Hide() end)

        nameEb:SetScript("OnEnterPressed", function() okBtn:Click() end)

        if self.RegisterModalForEscape then
            self:RegisterModalForEscape(f)
        end

        self.importChoiceFrame = f
    end

    local f = self.importChoiceFrame
    local activeProf = GSI_StatWeights:GetActiveProfileName(specKey)
    local activeLabel = L[activeProf or "Default (Baseline)"]

    f.subText:SetText(string.format(L["|cff00ff00%d stat weights detected|r for |cffffcc00%s|r.\nWould you like to overwrite the active profile or create a new one?"], count, specKey))
    f.rbOverwrite.text:SetText(string.format(L["Overwrite active profile: |cffffcc00%s|r"], activeLabel))

    local defaultNewName = suggestedName
    if not defaultNewName or defaultNewName == "" then
        defaultNewName = activeProf and (activeProf .. " (New)") or "Imported"
    end
    f.nameEb:SetText(defaultNewName)

    if suggestedName and suggestedName ~= "" then
        f.SetChoice(true)
        C_Timer.After(0.05, function()
            if f:IsShown() then
                f.nameEb:SetFocus()
                f.nameEb:HighlightText()
            end
        end)
    else
        f.SetChoice(false)
    end

    f.okBtn:SetScript("OnClick", function()
        local isNew = f.isNewChoice
        local targetProfileName = nil

        if isNew then
            local n = f.nameEb:GetText()
            n = n and n:gsub("^%s+", ""):gsub("%s+$", "") or ""
            if n == "" then n = "Imported" end
            targetProfileName = n
            GSI_StatWeights:SaveProfile(specKey, targetProfileName, parsedWeights)
        else
            if activeProf then
                targetProfileName = activeProf
                GSI_StatWeights:SaveProfile(specKey, activeProf, parsedWeights)
            else
                targetProfileName = "Custom"
                GSI_StatWeights:SaveProfile(specKey, targetProfileName, parsedWeights)
            end
        end

        if GSI_ItemScore then GSI_ItemScore:ResetCache() end
        if GSI_OptimizationEngine then GSI_OptimizationEngine:ResetCache() end
        GSI_UI:UpdateWeights(parent)
        GSI_UI:RefreshPanel(true)

        f:Hide()
        if self.weightsIOFrame then self.weightsIOFrame:Hide() end

        print(string.format(L["|cff00ff00[GearSetImprover]|r %d stat weights successfully imported into profile '|cffffcc00%s|r'!"], count, targetProfileName))
    end)

    f:Show()
end

function GSI_UI:ParseAndImportWeightsString(str, targetSpecKey, targetProfileName)
    local parsed, count, suggestedName, err = self:ParseWeightsString(str)
    if not parsed then
        return nil, err
    end

    local specKey = targetSpecKey or GSI_StatWeights:GetSpecKey()
    local profName = targetProfileName or suggestedName

    if profName and profName ~= "" and profName ~= "Default (Baseline)" then
        GSI_StatWeights:SaveProfile(specKey, profName, parsed)
    else
        if not GearSetImproverDB.customWeights then
            GearSetImproverDB.customWeights = {}
        end
        local modeKey = (GearSetImproverDB and GearSetImproverDB.weightMode) or "ST"
        GearSetImproverDB.customWeights[specKey .. ":" .. modeKey] = parsed
        GearSetImproverDB.customWeights[specKey] = parsed
    end

    if GSI_ItemScore then GSI_ItemScore:ResetCache() end
    if GSI_OptimizationEngine then GSI_OptimizationEngine:ResetCache() end
    return parsed, count, profName
end

function GSI_UI:OpenWeightsIOModal(parent, mode)
    if not self.weightsIOFrame then
        local f = CreateFrame("Frame", "GSI_WeightsIOFrame", UIParent, BACKDROP_TEMPLATE)
        f:SetSize(540, 390)
        f:SetPoint("CENTER")
        f:SetMovable(true)
        f:EnableMouse(true)
        f:RegisterForDrag("LeftButton")
        f:SetScript("OnDragStart", f.StartMoving)
        f:SetScript("OnDragStop", f.StopMovingOrSizing)
        f:SetFrameStrata("DIALOG")
        SkinFrame(f)
        f:SetBackdropColor(0.08, 0.08, 0.08, 0.98)
        f:SetBackdropBorderColor(1, 0.82, 0, 1)

        f.header = GSI_UI:CreateText(f, "TITLE", "")
        f.header:SetPoint("TOPLEFT", 16, -16)

        f.subText = GSI_UI:CreateText(f, "SMALL", "")
        f.subText:SetPoint("TOPLEFT", 16, -42)
        f.subText:SetPoint("RIGHT", -16, 0)
        f.subText:SetJustifyH("LEFT")

        -- Inset container for the EditBox with distinct background and border
        local inputBg = CreateFrame("Frame", "GSI_WeightsIOInputBg", f, BACKDROP_TEMPLATE)
        inputBg:SetPoint("TOPLEFT", 16, -72)
        inputBg:SetPoint("BOTTOMRIGHT", -16, 48)
        SkinFrame(inputBg)
        inputBg:SetBackdropColor(0.04, 0.04, 0.04, 0.98)
        inputBg:SetBackdropBorderColor(0.35, 0.35, 0.35, 1)
        inputBg:EnableMouse(true)
        f.inputBg = inputBg

        local sf = CreateFrame("ScrollFrame", "GSI_WeightsIOScroll", inputBg, "UIPanelScrollFrameTemplate")
        sf:SetPoint("TOPLEFT", 8, -6)
        sf:SetPoint("BOTTOMRIGHT", -26, 6)
        sf:EnableMouse(true)
        if GSI_UI and GSI_UI.SkinScrollBar then
            GSI_UI:SkinScrollBar(sf)
        end

        local eb = CreateFrame("EditBox", "GSI_WeightsIOEditBox", sf)
        if eb.SetMultiLine then eb:SetMultiLine(true) end
        eb:SetFont(GSI_UI:GetFontPath(), 11, "")
        eb:SetWidth(460)
        eb:SetHeight(240)
        eb:SetAutoFocus(false)
        eb:SetTextInsets(4, 4, 4, 4)
        eb:SetScript("OnEscapePressed", function() f:Hide() end)
        sf:SetScrollChild(eb)
        f.editBox = eb

        local placeholder = GSI_UI:CreateText(inputBg, "SMALL", L["Click here and press Ctrl+V to paste...\n\nSupported formats:\n• GSI:   DRUID-2, Agility=0.66, Strength=0.1, Crit=3.09\n• Pawn:  ( Pawn: v1: \"Feral\": Agility=0.66, CritRating=3.09 )"])
        placeholder:SetPoint("TOPLEFT", 12, -10)
        placeholder:SetPoint("RIGHT", -30, 0)
        placeholder:SetJustifyH("LEFT")
        placeholder:SetText(L["Click here and press Ctrl+V to paste...\n\nSupported formats:\n• GSI:   DRUID-2, Agility=0.66, Strength=0.1, Crit=3.09\n• Pawn:  ( Pawn: v1: \"Feral\": Agility=0.66, CritRating=3.09 )"])
        f.placeholder = placeholder

        local function UpdateEditBoxState()
            local text = eb:GetText()
            if text == nil or text == "" then
                if f._mode == "IMPORT" then
                    placeholder:Show()
                else
                    placeholder:Hide()
                end
            else
                placeholder:Hide()
            end
            local lines = (eb.GetNumLines and eb:GetNumLines()) or 1
            local h = math.max(240, lines * 15 + 10)
            eb:SetHeight(h)
        end
        f.UpdateEditBoxState = UpdateEditBoxState

        eb:SetScript("OnTextChanged", function(self, isUserInput)
            UpdateEditBoxState()
        end)

        eb:SetScript("OnCursorChanged", function(self, x, y, w, h)
            if y then
                local scrollY = -y - 80
                if scrollY < 0 then scrollY = 0 end
                sf:SetVerticalScroll(scrollY)
            end
        end)

        eb:SetScript("OnEditFocusGained", function()
            inputBg:SetBackdropBorderColor(1, 0.82, 0, 1)
        end)

        eb:SetScript("OnEditFocusLost", function()
            inputBg:SetBackdropBorderColor(0.35, 0.35, 0.35, 1)
            UpdateEditBoxState()
        end)

        inputBg:SetScript("OnMouseDown", function()
            eb:SetFocus()
        end)

        sf:SetScript("OnMouseDown", function()
            eb:SetFocus()
        end)

        local actionBtn = CreateFrame("Button", nil, f, BACKDROP_TEMPLATE)
        actionBtn:SetSize(110, 24)
        actionBtn:SetPoint("BOTTOMRIGHT", -16, 14)
        SkinButton(actionBtn)
        f.actionBtn = actionBtn

        local cancelBtn = CreateFrame("Button", nil, f, BACKDROP_TEMPLATE)
        cancelBtn:SetSize(100, 24)
        cancelBtn:SetPoint("RIGHT", actionBtn, "LEFT", -10, 0)
        cancelBtn:SetText(L["Close"])
        SkinButton(cancelBtn)
        cancelBtn:SetScript("OnClick", function() f:Hide() end)
        f.cancelBtn = cancelBtn

        local topClose = CreateFrame("Button", nil, f, BACKDROP_TEMPLATE)
        topClose:SetSize(22, 22)
        topClose:SetPoint("TOPRIGHT", -6, -6)
        topClose:SetText("X")
        SkinButton(topClose, true)
        topClose:SetScript("OnClick", function() f:Hide() end)

        if self.RegisterModalForEscape then
            self:RegisterModalForEscape(f)
        end

        self.weightsIOFrame = f
    end

    local f = self.weightsIOFrame
    local eb = f.editBox
    local specKey = GSI_StatWeights:GetSpecKey()
    f._mode = mode

    if mode == "EXPORT" then
        f.header:SetText(L["Export Stat Weights"])
        f.subText:SetText(string.format(L["Copy string using Ctrl+C (Profile: |cffffcc00%s|r):"], tostring(specKey)))
        if f.placeholder then f.placeholder:Hide() end
        local exportStr = GSI_UI:GetWeightsExportString(specKey)
        eb:SetText(exportStr)
        eb:HighlightText()
        if f.UpdateEditBoxState then f.UpdateEditBoxState() end
        C_Timer.After(0.05, function()
            if f:IsShown() then
                eb:SetFocus()
                eb:HighlightText()
            end
        end)
        f.actionBtn:SetText(L["Close"])
        f.actionBtn:SetScript("OnClick", function() f:Hide() end)
        f.cancelBtn:Hide()
    else -- IMPORT
        f.header:SetText(L["Import Stat Weights"])
        f.subText:SetText(string.format(L["Paste string here using Ctrl+V (Target Profile: |cffffcc00%s|r):\n|cffaaaaaaSupports GSI format and Pawn strings.|r"], tostring(specKey)))
        eb:SetText("")
        if f.placeholder then f.placeholder:Show() end
        if f.UpdateEditBoxState then f.UpdateEditBoxState() end
        C_Timer.After(0.05, function()
            if f:IsShown() then
                eb:SetFocus()
            end
        end)
        f.actionBtn:SetText(L["Import"])
        f.cancelBtn:Show()
        f.actionBtn:SetScript("OnClick", function()
            local text = eb:GetText()
            local parsed, count, suggestedName, err = GSI_UI:ParseWeightsString(text)
            if not parsed then
                print(string.format(L["|cffff4444[GearSetImprover] Import error:|r %s"], tostring(err or L["No valid stat weights found."])))
                return
            end

            GSI_UI:PromptImportProfileChoice(parent, specKey, parsed, count, suggestedName)
        end)
    end

    f:Show()
end

-- ---------------------------------------------------------------
