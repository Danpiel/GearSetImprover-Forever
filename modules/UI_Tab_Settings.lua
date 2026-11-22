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
