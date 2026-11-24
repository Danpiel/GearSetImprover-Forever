-- ============================================================
-- GearSetImprover -- UI_Tab_Settings.lua (WoW Forever)
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

-- Helper: Returns list of available profiles/orientations for a class
-- ---------------------------------------------------------------
function GSI_UI:GetClassProfiles(playerClass)
    local classData = GSI_ClassicData and GSI_ClassicData.Classes and GSI_ClassicData.Classes[playerClass]
    local numSpecs = (playerClass == "DRUID") and 4 or 3
    local list = {}

    for i = 1, numSpecs do
        local specInfo = classData and classData.specs and classData.specs[i]
        local sName = (specInfo and specInfo.name) or ("Spec " .. i)
        local role = specInfo and specInfo.role

        -- Check if spec has tank modes (Survival vs Threat)
        local hasTankModes = false
        if playerClass == "WARRIOR" and i == 3 then hasTankModes = true end
        if playerClass == "DRUID" and i == 2 then hasTankModes = true end
        if playerClass == "PALADIN" and i == 2 then hasTankModes = true end

        if hasTankModes then
            table.insert(list, {
                key = i .. ":Survival",
                specIndex = i,
                mode = "Survival",
                modeLabel = "Survival",
                label = string.format("%s (Survival)", sName)
            })
            table.insert(list, {
                key = i .. ":Threat",
                specIndex = i,
                mode = "Threat",
                modeLabel = "Threat",
                label = string.format("%s (Threat / DMG)", sName)
            })
        elseif role == "healer" then
            table.insert(list, {
                key = i .. ":ST",
                specIndex = i,
                mode = "ST",
                modeLabel = "Single",
                label = string.format("%s (Single Target / Direct)", sName)
            })
            table.insert(list, {
                key = i .. ":AOE",
                specIndex = i,
                mode = "AOE",
                modeLabel = "AoE / Raid",
                label = string.format("%s (AoE / Raid)", sName)
            })
        else
            -- Standard DPS specs
            table.insert(list, {
                key = i .. ":ST",
                specIndex = i,
                mode = "ST",
                modeLabel = "ST",
                label = string.format("%s (Single Target)", sName)
            })
            table.insert(list, {
                key = i .. ":AOE",
                specIndex = i,
                mode = "AOE",
                modeLabel = "AoE",
                label = string.format("%s (AoE / Trash)", sName)
            })
        end
    end

    return list
end

-- ---------------------------------------------------------------
-- ---------------------------------------------------------------
-- TAB 5: SETTINGS
-- ---------------------------------------------------------------
function GSI_UI:DrawSettings(parent)
    local title = self:CreateText(parent, "TITLE", "Addon Settings")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetPoint("RIGHT", parent, "RIGHT", -16, 0)
    if title.SetWordWrap then title:SetWordWrap(false) end

    local sf = CreateFrame("ScrollFrame", "GSI_SettingsScroll", parent, "UIPanelScrollFrameTemplate")
    sf:SetPoint("TOPLEFT", 0, -46)
    sf:SetPoint("BOTTOMRIGHT", -28, 12)
    if self.SkinScrollBar then
        self:SkinScrollBar(sf)
    end

    local scrollChild = CreateFrame("Frame", nil, sf)
    scrollChild:SetSize(math.max(400, (sf:GetWidth() or 710) - 4), 560)
    sf:SetScrollChild(scrollChild)

    sf:HookScript("OnSizeChanged", function(selfSf, width)
        if width and width > 100 then
            scrollChild:SetWidth(math.max(400, width - 4))
        end
    end)

    local desc = self:CreateText(scrollChild, "BODY", "All addon settings are integrated into the official WoW Interface Options.")
    desc:SetPoint("TOPLEFT", 16, -4)
    desc:SetPoint("RIGHT", scrollChild, "RIGHT", -16, 0)
    desc:SetJustifyH("LEFT")
    if desc.SetWordWrap then desc:SetWordWrap(true) end

    local openBtn = CreateFrame("Button", nil, scrollChild, BACKDROP_TEMPLATE)
    openBtn:SetSize(200, 28)
    openBtn:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", 0, -14)
    openBtn:SetText("Open Interface Options")
    SkinButton(openBtn, nil, true)
    openBtn:SetScript("OnClick", function()
        if GSI_UI.OpenSettings then
            GSI_UI:OpenSettings()
        end
    end)

    local deMacroBtn = CreateFrame("Button", nil, scrollChild, BACKDROP_TEMPLATE)
    deMacroBtn:SetSize(160, 28)
    deMacroBtn:SetPoint("LEFT", openBtn, "RIGHT", 10, 0)
    deMacroBtn:SetText("Pickup DE Macro")
    SkinButton(deMacroBtn, nil, false)
    deMacroBtn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    deMacroBtn:RegisterForDrag("LeftButton")
    deMacroBtn:SetScript("OnDragStart", function()
        if GSI_UI.PickupDisenchantMacro then
            GSI_UI:PickupDisenchantMacro()
        end
    end)
    deMacroBtn:SetScript("OnClick", function()
        if GSI_UI.PickupDisenchantMacro then
            GSI_UI:PickupDisenchantMacro()
        end
    end)
    deMacroBtn:SetScript("OnEnter", function(selfBtn)
        GameTooltip:SetOwner(selfBtn, "ANCHOR_TOP")
        GameTooltip:ClearLines()
        GameTooltip:AddLine("|cffffcc00Disenchant Clean-up Macro|r", 1, 1, 1)
        GameTooltip:AddLine("Click or drag to place a macro ('GSI: DE Clean') on your Action Bar that disenchants obsolete gear items from the Clean-up list one by one.", 0.9, 0.9, 0.9, true)
        GameTooltip:AddLine("|cff00ff00Click / Drag:|r Attach macro to cursor", 0, 1, 0)
        GameTooltip:Show()
    end)
    deMacroBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    -- General Settings
    local generalHeader = self:CreateText(scrollChild, "CARD_TITLE", "General Options")
    generalHeader:SetPoint("TOPLEFT", openBtn, "BOTTOMLEFT", 0, -20)
    generalHeader:SetPoint("RIGHT", scrollChild, "RIGHT", -16, 0)
    if generalHeader.SetWordWrap then generalHeader:SetWordWrap(false) end

    local cbDisableChat = CreateFrame("CheckButton", nil, scrollChild, "UICheckButtonTemplate")
    cbDisableChat:SetPoint("TOPLEFT", generalHeader, "BOTTOMLEFT", 0, -8)
    cbDisableChat.text = self:CreateText(cbDisableChat, "BODY", "Disable Chat Output (Silent Mode)")
    cbDisableChat.text:SetPoint("LEFT", cbDisableChat, "RIGHT", 6, 0)
    cbDisableChat.text:SetPoint("RIGHT", scrollChild, "RIGHT", -16, 0)
    cbDisableChat.text:SetJustifyH("LEFT")
    if cbDisableChat.text.SetWordWrap then cbDisableChat.text:SetWordWrap(true) end
    cbDisableChat:SetChecked(GearSetImproverDB and GearSetImproverDB.disableChatOutput == true)
    cbDisableChat:SetScript("OnClick", function(selfBtn)
        if not GearSetImproverDB then GearSetImproverDB = {} end
        GearSetImproverDB.disableChatOutput = selfBtn:GetChecked() and true or false
        if GSI_UI.blizzOptionsPanel and GSI_UI.blizzOptionsPanel.cbDisableChat then
            GSI_UI.blizzOptionsPanel.cbDisableChat:SetChecked(GearSetImproverDB.disableChatOutput)
        end
    end)
    cbDisableChat:SetScript("OnEnter", function(selfBtn)
        GameTooltip:SetOwner(selfBtn, "ANCHOR_RIGHT")
        GameTooltip:AddLine("Disable Chat Output (Silent Mode)", 1, 0.82, 0)
        GameTooltip:AddLine("Disables all chat messages from the addon (e.g. login greeting, gear notifications, profile confirmations).", 1, 1, 1, true)
        GameTooltip:Show()
    end)
    cbDisableChat:SetScript("OnLeave", function() GameTooltip:Hide() end)
    GSI_UI.cbDisableChat = cbDisableChat

    local cbMerchantOverlay = CreateFrame("CheckButton", nil, scrollChild, "UICheckButtonTemplate")
    cbMerchantOverlay:SetPoint("TOPLEFT", cbDisableChat, "BOTTOMLEFT", 0, -6)
    cbMerchantOverlay.text = self:CreateText(cbMerchantOverlay, "BODY", "Show Clean-up sell window at merchant")
    cbMerchantOverlay.text:SetPoint("LEFT", cbMerchantOverlay, "RIGHT", 6, 0)
    cbMerchantOverlay.text:SetPoint("RIGHT", scrollChild, "RIGHT", -16, 0)
    cbMerchantOverlay.text:SetJustifyH("LEFT")
    if cbMerchantOverlay.text.SetWordWrap then cbMerchantOverlay.text:SetWordWrap(true) end
    cbMerchantOverlay:SetChecked(not (GearSetImproverDB and GearSetImproverDB.merchantOverlayEnabled == false))
    cbMerchantOverlay:SetScript("OnClick", function(selfBtn)
        local val = selfBtn:GetChecked() and true or false
        if GSI_UI.SetMerchantOverlayEnabled then
            GSI_UI:SetMerchantOverlayEnabled(val)
        else
            if not GearSetImproverDB then GearSetImproverDB = {} end
            GearSetImproverDB.merchantOverlayEnabled = val
            if GSI_UI.UpdateMerchantPanel then
                GSI_UI:UpdateMerchantPanel()
            elseif not val then
                if GSI_UI.merchantOverlay then GSI_UI.merchantOverlay:Hide() end
                if _G["GSI_MerchantOverlay"] then _G["GSI_MerchantOverlay"]:Hide() end
                if _G["GSI_MerchantToggleBtn"] then _G["GSI_MerchantToggleBtn"]:Hide() end
            end
        end
        if GSI_UI.blizzOptionsPanel and GSI_UI.blizzOptionsPanel.cbMerchantOverlay then
            GSI_UI.blizzOptionsPanel.cbMerchantOverlay:SetChecked(val)
        end
        local junkFrame = GSI_UI.mainFrame and GSI_UI.mainFrame.tabFrames and GSI_UI.mainFrame.tabFrames["JUNK"]
        if junkFrame and GSI_UI.UpdateJunkList then
            pcall(function() GSI_UI:UpdateJunkList(junkFrame) end)
        end
    end)
    cbMerchantOverlay:SetScript("OnEnter", function(selfBtn)
        GameTooltip:SetOwner(selfBtn, "ANCHOR_RIGHT")
        GameTooltip:AddLine("Show Clean-up sell window at merchant", 1, 0.82, 0)
        GameTooltip:AddLine("Automatically docks the Clean-up sell panel next to the merchant window with a 'Sell All' button.", 1, 1, 1, true)
        GameTooltip:Show()
    end)
    cbMerchantOverlay:SetScript("OnLeave", function() GameTooltip:Hide() end)
    GSI_UI.cbMerchantOverlay = cbMerchantOverlay

    -- Tooltip Orientations (Multi-Profile Selection: ST, AoE, Survival, Threat)
    local specHeader = self:CreateText(scrollChild, "CARD_TITLE", "Tooltip Orientations & Specs (ST, AoE, Tank)")
    specHeader:SetPoint("TOPLEFT", cbMerchantOverlay, "BOTTOMLEFT", 0, -20)
    specHeader:SetPoint("RIGHT", scrollChild, "RIGHT", -16, 0)
    if specHeader.SetWordWrap then specHeader:SetWordWrap(true) end

    local specDesc = self:CreateText(scrollChild, "BODY", "Select which orientations display a GSI Score in tooltips (e.g. Bear Survival, Cat ST & AoE):")
    specDesc:SetPoint("TOPLEFT", specHeader, "BOTTOMLEFT", 0, -8)
    specDesc:SetPoint("RIGHT", scrollChild, "RIGHT", -16, 0)
    specDesc:SetJustifyH("LEFT")
    if specDesc.SetWordWrap then specDesc:SetWordWrap(true) end

    local playerClass = (GSI_ClassicData and GSI_ClassicData.GetPlayerClass and GSI_ClassicData:GetPlayerClass())
        or select(2, UnitClass("player")) or "WARRIOR"
    local profiles = self:GetClassProfiles(playerClass)

    local profileCheckboxes = {}
    local lastElem = specDesc
    for _, pInfo in ipairs(profiles) do
        local cb = CreateFrame("CheckButton", nil, scrollChild, "UICheckButtonTemplate")
        cb:SetPoint("TOPLEFT", lastElem, "BOTTOMLEFT", 0, -6)
        cb.text = self:CreateText(cb, "BODY", pInfo.label)
        cb.text:SetPoint("LEFT", cb, "RIGHT", 6, 0)
        cb.text:SetPoint("RIGHT", scrollChild, "RIGHT", -16, 0)
        cb.text:SetJustifyH("LEFT")
        if cb.text.SetWordWrap then cb.text:SetWordWrap(true) end
        cb.profileKey = pInfo.key

        local curChecked = false
        if GearSetImproverDB and GearSetImproverDB.tooltipProfiles and GearSetImproverDB.tooltipProfiles[playerClass] then
            curChecked = (GearSetImproverDB.tooltipProfiles[playerClass][pInfo.key] == true)
        end
        cb:SetChecked(curChecked)

        cb:SetScript("OnClick", function(selfBtn)
            if not GearSetImproverDB then GearSetImproverDB = {} end
            if not GearSetImproverDB.tooltipProfiles then GearSetImproverDB.tooltipProfiles = {} end
            if not GearSetImproverDB.tooltipProfiles[playerClass] then GearSetImproverDB.tooltipProfiles[playerClass] = {} end
            GearSetImproverDB.tooltipProfiles[playerClass][selfBtn.profileKey] = selfBtn:GetChecked() and true or false
            if GSI_TooltipCache and GSI_TooltipCache.Invalidate then
                GSI_TooltipCache:Invalidate()
            end
            if GSI_UI.blizzOptionsPanel and GSI_UI.blizzOptionsPanel.refresh then
                GSI_UI.blizzOptionsPanel.refresh()
            end
        end)
        table.insert(profileCheckboxes, cb)
        lastElem = cb
    end

    -- Specialization detection & Equipment Set per spec
    local setHeader = self:CreateText(scrollChild, "CARD_TITLE", "Specialization & Equipment Set per Spec")
    setHeader:SetPoint("TOPLEFT", lastElem, "BOTTOMLEFT", 0, -20)
    setHeader:SetPoint("RIGHT", scrollChild, "RIGHT", -16, 0)
    if setHeader.SetWordWrap then setHeader:SetWordWrap(true) end

    local cbSpecAuto = CreateFrame("CheckButton", nil, scrollChild, "UICheckButtonTemplate")
    cbSpecAuto:SetPoint("TOPLEFT", setHeader, "BOTTOMLEFT", 0, -8)
    cbSpecAuto.text = self:CreateText(cbSpecAuto, "BODY", "Detect the specialization from your talents (follows respecs)")
    cbSpecAuto.text:SetPoint("LEFT", cbSpecAuto, "RIGHT", 6, 0)
    cbSpecAuto.text:SetPoint("RIGHT", scrollChild, "RIGHT", -16, 0)
    cbSpecAuto.text:SetJustifyH("LEFT")
    cbSpecAuto:SetScript("OnClick", function(selfBtn)
        if GSI_StatWeights and GSI_StatWeights.SetSpecAuto then
            GSI_StatWeights:SetSpecAuto(selfBtn:GetChecked() and true or false)
        end
    end)
    cbSpecAuto:SetScript("OnEnter", function(selfBtn)
        GameTooltip:SetOwner(selfBtn, "ANCHOR_RIGHT")
        GameTooltip:AddLine("Auto-detect specialization", 1, 0.82, 0)
        GameTooltip:AddLine("Uses the talent tree with the most points. Picking a spec in the header dropdown (or /gsi spec <name>) pins it and turns this off; /gsi spec auto turns it back on.", 1, 1, 1, true)
        GameTooltip:AddLine("Feral druids: talents cannot tell Cat from Bear, so your last Cat/Bear pick decides.", 0.7, 0.9, 1, true)
        GameTooltip:Show()
    end)
    cbSpecAuto:SetScript("OnLeave", function() GameTooltip:Hide() end)

    local cbSetAuto = CreateFrame("CheckButton", nil, scrollChild, "UICheckButtonTemplate")
    cbSetAuto:SetPoint("TOPLEFT", cbSpecAuto, "BOTTOMLEFT", 0, -6)
    cbSetAuto.text = self:CreateText(cbSetAuto, "BODY", "Equip the chosen set when your spec changes")
    cbSetAuto.text:SetPoint("LEFT", cbSetAuto, "RIGHT", 6, 0)
    cbSetAuto.text:SetPoint("RIGHT", scrollChild, "RIGHT", -16, 0)
    cbSetAuto.text:SetJustifyH("LEFT")
    cbSetAuto:SetScript("OnClick", function(selfBtn)
        if not GearSetImproverDB then GearSetImproverDB = {} end
        GearSetImproverDB.specSetAutoEquip = selfBtn:GetChecked() and true or false
    end)
    cbSetAuto:SetScript("OnEnter", function(selfBtn)
        GameTooltip:SetOwner(selfBtn, "ANCHOR_RIGHT")
        GameTooltip:AddLine("Equip set on spec change", 1, 0.82, 0)
        GameTooltip:AddLine("When the talent-detected spec changes, the Equipment Manager set chosen below for the new spec is put on (after combat if you are fighting). /gsi set equips it by hand.", 1, 1, 1, true)
        GameTooltip:Show()
    end)
    cbSetAuto:SetScript("OnLeave", function() GameTooltip:Hide() end)

    local cbCompareSets = CreateFrame("CheckButton", nil, scrollChild, "UICheckButtonTemplate")
    cbCompareSets:SetPoint("TOPLEFT", cbSetAuto, "BOTTOMLEFT", 0, -6)
    cbCompareSets.text = self:CreateText(cbCompareSets, "BODY", "Tooltips: compare other specs with their own set, not the gear you wear")
    cbCompareSets.text:SetPoint("LEFT", cbCompareSets, "RIGHT", 6, 0)
    cbCompareSets.text:SetPoint("RIGHT", scrollChild, "RIGHT", -16, 0)
    cbCompareSets.text:SetJustifyH("LEFT")
    cbCompareSets:SetScript("OnClick", function(selfBtn)
        if not GearSetImproverDB then GearSetImproverDB = {} end
        GearSetImproverDB.compareSpecSets = selfBtn:GetChecked() and true or false
        if GSI_TooltipHook and GSI_TooltipHook.RefreshShownTooltips then GSI_TooltipHook:RefreshShownTooltips() end
    end)
    cbCompareSets:SetScript("OnEnter", function(selfBtn)
        GameTooltip:SetOwner(selfBtn, "ANCHOR_RIGHT")
        GameTooltip:AddLine("Compare other specs with their set", 1, 0.82, 0)
        GameTooltip:AddLine("When the tooltip shows several specs (Tooltip Orientations above), a spec you are not playing gets one line per Equipment Set of that spec (\"vs <set>\"): the sets GSI saved for it, or the ones chosen below. A set GSI saved for a mode is scored with that mode's weights (\"GSI: Resto AoE\" with AoE), your own sets with the line's mode. The active spec always compares with the gear you wear, and so do specs without a set.", 1, 1, 1, true)
        GameTooltip:Show()
    end)
    cbCompareSets:SetScript("OnLeave", function() GameTooltip:Hide() end)

    local setDesc = self:CreateText(scrollChild, "BODY", "Equipment Manager set and talent group (dual spec) for each spec; the set and group belong to this character:")
    setDesc:SetPoint("TOPLEFT", cbCompareSets, "BOTTOMLEFT", 0, -8)
    setDesc:SetPoint("RIGHT", scrollChild, "RIGHT", -16, 0)
    setDesc:SetJustifyH("LEFT")
    if setDesc.SetWordWrap then setDesc:SetWordWrap(true) end

    -- Set picker popup (one shared list, re-filled on open)
    local NONE_LABEL = "|cff888888(none)|r"
    local picker = GSI_UI.specSetPicker
    if not picker then
        picker = CreateFrame("Frame", "GSI_SpecSetPicker", UIParent, BACKDROP_TEMPLATE)
        picker:SetFrameStrata("FULLSCREEN_DIALOG")
        picker:SetFrameLevel(520)
        picker:SetClampedToScreen(true)
        picker:EnableMouse(true)
        picker:Hide()
        SkinFrame(picker, GSI_UI.THEME and GSI_UI.THEME.bgCardBottom, true)
        picker.items = {}
        local catcher = CreateFrame("Button", nil, UIParent)
        catcher:SetFrameStrata("FULLSCREEN_DIALOG")
        catcher:SetFrameLevel(515)
        catcher:SetAllPoints(UIParent)
        catcher:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        catcher:SetScript("OnClick", function() picker:Hide() end)
        catcher:Hide()
        picker.catcher = catcher
        picker:SetScript("OnShow", function() catcher:Show() end)
        picker:SetScript("OnHide", function() catcher:Hide() end)
        GSI_UI.specSetPicker = picker
    end

    local setRows = {}
    local RefreshSetRows

    -- Several sets per spec: each click adds or removes one (the list stays
    -- open); the top entry goes back to the sets GSI saved for the spec.
    local function OpenPicker(anchor, specIndex)
        local sets = GSI_UI.GetEquipmentSetList and GSI_UI:GetEquipmentSetList() or {}
        local chosen, isManual = {}, false
        if GSI_UI.GetSpecSets then chosen, isManual = GSI_UI:GetSpecSets(specIndex) end
        local selected = {}
        if isManual then
            for idx, n in ipairs(chosen) do selected[n] = idx end
        end
        local autoLabel = isManual and "|cff888888Auto: sets GSI saved|r" or "|cff00ff00Auto: sets GSI saved|r"
        local entries = { { name = nil, label = autoLabel } }
        for _, s in ipairs(sets) do
            local label = s.name
            if selected[s.name] then label = "|cff00ff00" .. selected[s.name] .. ". " .. s.name .. "|r" end
            entries[#entries + 1] = { name = s.name, label = label, icon = s.icon }
        end
        for i, e in ipairs(entries) do
            local b = picker.items[i]
            if not b then
                b = CreateFrame("Button", nil, picker, BACKDROP_TEMPLATE)
                b:SetSize(212, 24)
                b:SetPoint("TOP", 0, -4 - ((i - 1) * 26))
                b:SetFrameLevel(530)
                b:SetText(" ")
                SkinButton(b, nil, false)
                b.icon = b:CreateTexture(nil, "ARTWORK")
                b.icon:SetSize(16, 16)
                b.icon:SetPoint("LEFT", b, "LEFT", 6, 0)
                b.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
                picker.items[i] = b
            end
            b:SetText(e.label)
            b.icon:SetTexture(e.icon or 134400)
            b.icon:SetShown(e.name ~= nil)
            b:SetScript("OnClick", function()
                if e.name then
                    GSI_UI:ToggleSpecSet(specIndex, e.name)
                    OpenPicker(anchor, specIndex)
                else
                    GSI_UI:SetSpecSets(specIndex, nil)
                    picker:Hide()
                end
                if RefreshSetRows then RefreshSetRows() end
            end)
            b:Show()
        end
        for i = #entries + 1, #picker.items do picker.items[i]:Hide() end
        picker:SetSize(220, (#entries * 26) + 8)
        picker:ClearAllPoints()
        picker:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -2)
        picker:Show()
        if picker.Raise then picker:Raise() end
    end

    local numSpecRows = (playerClass == "DRUID") and 4 or 3
    local classData = GSI_ClassicData and GSI_ClassicData.Classes and GSI_ClassicData.Classes[playerClass]
    local prevRow = setDesc
    for i = 1, numSpecRows do
        local specData = classData and classData.specs and classData.specs[i]
        local row = CreateFrame("Frame", nil, scrollChild)
        row:SetHeight(26)
        row:SetPoint("TOPLEFT", prevRow, "BOTTOMLEFT", 0, -6)
        row:SetPoint("RIGHT", scrollChild, "RIGHT", -16, 0)

        row.icon = row:CreateTexture(nil, "ARTWORK")
        row.icon:SetSize(18, 18)
        row.icon:SetPoint("LEFT", row, "LEFT", 4, 0)
        row.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        row.icon:SetTexture((specData and specData.icon) or 134400)

        row.label = self:CreateText(row, "BODY", (specData and specData.name) or ("Spec " .. i))
        row.label:SetPoint("LEFT", row.icon, "RIGHT", 6, 0)
        row.label:SetWidth(130)
        row.label:SetJustifyH("LEFT")

        row.pick = CreateFrame("Button", nil, row, BACKDROP_TEMPLATE)
        row.pick:SetSize(200, 24)
        row.pick:SetPoint("LEFT", row, "LEFT", 164, 0)
        row.pick:SetText(" ")
        SkinButton(row.pick, nil, false)
        local specIdx = i
        row.pick:SetScript("OnClick", function(selfBtn)
            if picker:IsShown() then picker:Hide() return end
            GameTooltip:Hide()
            OpenPicker(selfBtn, specIdx)
        end)
        row.pick:SetScript("OnEnter", function(selfBtn)
            GameTooltip:SetOwner(selfBtn, "ANCHOR_RIGHT")
            GameTooltip:AddLine("Equipment Sets for this spec", 1, 0.82, 0)
            GameTooltip:AddLine("Auto: the sets GSI saved for the spec (\"GSI: Cat ST\", \"GSI: Resto AoE\", ...). Or tick one or more of your own sets. When a spec has several, switching to it asks which one to put on; other specs' tooltip lines compare with the set for their mode, else the first.", 1, 1, 1, true)
            GameTooltip:Show()
        end)
        row.pick:SetScript("OnLeave", function() GameTooltip:Hide() end)

        row.equip = CreateFrame("Button", nil, row, BACKDROP_TEMPLATE)
        row.equip:SetSize(70, 24)
        row.equip:SetPoint("LEFT", row.pick, "RIGHT", 8, 0)
        row.equip:SetText("Equip")
        SkinButton(row.equip, nil, false)
        row.equip:SetScript("OnClick", function()
            if GSI_UI.EquipSpecSet then GSI_UI:EquipSpecSet(specIdx, false, true) end
        end)

        -- Talent group (dual spec) for /gsi go: Auto -> 1 -> 2 -> Auto
        row.group = CreateFrame("Button", nil, row, BACKDROP_TEMPLATE)
        row.group:SetSize(130, 24)
        row.group:SetPoint("LEFT", row.equip, "RIGHT", 8, 0)
        row.group:SetText(" ")
        SkinButton(row.group, nil, false)
        row.group:SetScript("OnClick", function()
            if not GSI_UI.GetSpecTalentGroup then return end
            local cur = GSI_UI:GetSpecTalentGroup(specIdx)
            local nextGroup = (cur == nil and 1) or (cur == 1 and 2) or nil
            GSI_UI:SetSpecTalentGroup(specIdx, nextGroup)
            if RefreshSetRows then RefreshSetRows() end
        end)
        row.group:SetScript("OnEnter", function(selfBtn)
            local SW = GSI_StatWeights
            GameTooltip:SetOwner(selfBtn, "ANCHOR_RIGHT")
            GameTooltip:AddLine("Talent group for this spec", 1, 0.82, 0)
            local n = (SW and SW.GetNumTalentGroups and SW:GetNumTalentGroups()) or 1
            if n < 2 then
                GameTooltip:AddLine("Dual specialization is not learned: /gsi go only puts on the gear.", 1, 1, 1, true)
            else
                local active = SW:GetActiveTalentGroup()
                for g = 1, n do
                    local points, names = SW:GetTalentGroupPoints(g)
                    local lead = SW:GetTalentGroupLeadTree(g)
                    local right = points and table.concat(points, " / ") or "?"
                    local left = "Group " .. g .. ((lead and names and names[lead]) and (": " .. names[lead]) or "")
                    if g == active then left = left .. " (active)" end
                    GameTooltip:AddDoubleLine(left, right, 1, 1, 1, 0.8, 0.8, 0.8)
                end
                GameTooltip:AddLine("Click: Auto, Group 1, Group 2. Auto takes the only group whose most-used tree is this spec's; choose the group when both use the same tree (a Cat and a Bear build).", 0.7, 0.9, 1, true)
            end
            GameTooltip:AddLine("Used by /gsi go <spec>. The 'GSI Dual Spec' macro (/gsi toggle) just switches to the other group and puts on the gear of the spec it plays.", 0.85, 0.85, 0.85, true)
            GameTooltip:Show()
        end)
        row.group:SetScript("OnLeave", function() GameTooltip:Hide() end)

        row.specIndex = i
        setRows[i] = row
        prevRow = row
    end
    lastElem = prevRow

    RefreshSetRows = function()
        local detected = GSI_StatWeights and GSI_StatWeights.DetectCurrentSpec and GSI_StatWeights:DetectCurrentSpec()
        for i, row in ipairs(setRows) do
            local names, isManual = {}, false
            if GSI_UI.GetSpecSets then names, isManual = GSI_UI:GetSpecSets(i) end
            local anyExists = false
            local shown = {}
            for _, n in ipairs(names) do
                local exists = C_EquipmentSet and C_EquipmentSet.GetEquipmentSetID and C_EquipmentSet.GetEquipmentSetID(n)
                if exists then anyExists = true end
                shown[#shown + 1] = exists and n or ("|cffff4444" .. n .. " (missing)|r")
            end
            local text = table.concat(shown, ", ")
            if not isManual then
                text = (#shown > 0) and ("|cff888888Auto:|r " .. text) or "|cff888888Auto: no GSI set yet|r"
            elseif text == "" then
                text = NONE_LABEL
            end
            row.pick:SetText(text)
            row.equip:SetEnabled(anyExists)
            local specData = classData and classData.specs and classData.specs[i]
            local label = (specData and specData.name) or ("Spec " .. i)
            row.label:SetText(i == detected and ("|cff00ff00" .. label .. "|r") or label)

            local SW = GSI_StatWeights
            local numGroups = (SW and SW.GetNumTalentGroups and SW:GetNumTalentGroups()) or 1
            if numGroups < 2 or not GSI_UI.ResolveSpecTalentGroup then
                row.group:SetText("|cff888888Talents: -|r")
            else
                local bound = GSI_UI:GetSpecTalentGroup(i)
                if bound then
                    row.group:SetText("Talents: Group " .. bound)
                else
                    local g = GSI_UI:ResolveSpecTalentGroup(i)
                    row.group:SetText("Talents: Auto |cff888888(" .. (g and tostring(g) or "?") .. ")|r")
                end
            end
        end
        cbSpecAuto:SetChecked(not GSI_StatWeights or not GSI_StatWeights.IsSpecAuto or GSI_StatWeights:IsSpecAuto())
        cbSetAuto:SetChecked(not GSI_UI.IsSpecSetAutoEquip or GSI_UI:IsSpecSetAutoEquip())
        cbCompareSets:SetChecked(not GSI_UI.IsCompareSpecSets or GSI_UI:IsCompareSpecSets())
    end
    GSI_UI.RefreshSpecSetRows = RefreshSetRows

    if CreateFrame then
        local setsWatcher = CreateFrame("Frame")
        pcall(setsWatcher.RegisterEvent, setsWatcher, "EQUIPMENT_SETS_CHANGED")
        pcall(setsWatcher.RegisterEvent, setsWatcher, "PLAYER_EQUIPMENT_CHANGED")
        pcall(setsWatcher.RegisterEvent, setsWatcher, "ACTIVE_TALENT_GROUP_CHANGED")
        pcall(setsWatcher.RegisterEvent, setsWatcher, "PLAYER_TALENT_UPDATE")
        setsWatcher:SetScript("OnEvent", function()
            if parent:IsVisible() then RefreshSetRows() end
        end)
    end

    local function UpdateSettingsLayoutAndSync()
        local hasDE = GSI_UI.HasDisenchantSpell and GSI_UI:HasDisenchantSpell()
        deMacroBtn:SetShown(hasDE and true or false)

        cbDisableChat:SetChecked(GearSetImproverDB and GearSetImproverDB.disableChatOutput == true)
        cbMerchantOverlay:SetChecked(not (GearSetImproverDB and GearSetImproverDB.merchantOverlayEnabled == false))
        for _, cb in ipairs(profileCheckboxes) do
            local checked = false
            if GearSetImproverDB and GearSetImproverDB.tooltipProfiles and GearSetImproverDB.tooltipProfiles[playerClass] then
                checked = (GearSetImproverDB.tooltipProfiles[playerClass][cb.profileKey] == true)
            end
            cb:SetChecked(checked)
        end
        pcall(RefreshSetRows)

        local topY = scrollChild:GetTop()
        local botY = lastElem and lastElem.GetBottom and lastElem:GetBottom()
        local fallbackH = 320 + (#profiles * 36)
        local targetH = fallbackH
        if topY and botY and topY > botY then
            targetH = math.max(fallbackH, math.ceil(topY - botY) + 28)
        end
        scrollChild:SetWidth(math.max(400, (sf:GetWidth() or 710) - 4))
        scrollChild:SetHeight(math.max(540, targetH))
    end

    UpdateSettingsLayoutAndSync()
    parent:HookScript("OnShow", function()
        UpdateSettingsLayoutAndSync()
        if C_Timer and C_Timer.After then
            C_Timer.After(0, UpdateSettingsLayoutAndSync)
        end
    end)
    if C_Timer and C_Timer.After then
        C_Timer.After(0, UpdateSettingsLayoutAndSync)
    end
end

-- ---------------------------------------------------------------
