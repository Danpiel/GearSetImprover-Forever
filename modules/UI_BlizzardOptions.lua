-- ============================================================
-- GearSetImprover -- UI_BlizzardOptions.lua (WoW Forever)
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

-- BLIZZARD INTERFACE OPTIONS
-- ---------------------------------------------------------------
function GSI_UI:RegisterBlizzardOptions()
    if self.blizzOptionsPanel then return end

    local panel = CreateFrame("Frame", "GSI_BlizzardOptionsPanel", UIParent)
    panel.name = "GearSetImprover"
    self.blizzOptionsPanel = panel

    -- ScrollFrame to contain all options and prevent window overflow
    local scrollFrame = CreateFrame("ScrollFrame", "GSI_BlizzOptionsScrollFrame", panel, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 10, -10)
    scrollFrame:SetPoint("BOTTOMRIGHT", -26, 10)

    local content = CreateFrame("Frame", "GSI_BlizzOptionsContent", scrollFrame)
    content:SetSize(580, 1100)
    scrollFrame:SetScrollChild(content)

    local function AnchorBlizzLine(fs, justifyH, wrap)
        if not fs then return end
        fs:SetPoint("RIGHT", content, "RIGHT", -16, 0)
        fs:SetJustifyH(justifyH or "LEFT")
        if fs.SetWordWrap then fs:SetWordWrap(wrap ~= false) end
    end

    local function AnchorBlizzCheckLabel(cb, text)
        if not cb or not cb.text then return end
        cb.text:ClearAllPoints()
        cb.text:SetPoint("LEFT", cb, "RIGHT", 5, 0)
        cb.text:SetPoint("RIGHT", content, "RIGHT", -16, 0)
        cb.text:SetJustifyH("LEFT")
        if cb.text.SetWordWrap then cb.text:SetWordWrap(true) end
        if text then cb.text:SetText(text) end
    end

    -- Enable smooth mouse wheel scrolling anywhere over the panel
    if scrollFrame.EnableMouseWheel then
        scrollFrame:EnableMouseWheel(true)
        scrollFrame:SetScript("OnMouseWheel", function(self, delta)
            local sb = _G[self:GetName() .. "ScrollBar"]
            if sb then
                local cur = sb:GetValue()
                local minVal, maxVal = sb:GetMinMaxValues()
                local step = 35
                if delta < 0 then
                    sb:SetValue(math.min(maxVal, cur + step))
                else
                    sb:SetValue(math.max(minVal, cur - step))
                end
            end
        end)
    end

    local version = (C_AddOns and C_AddOns.GetAddOnMetadata and C_AddOns.GetAddOnMetadata("GearSetImprover", "Version")) or (GetAddOnMetadata and GetAddOnMetadata("GearSetImprover", "Version")) or "1.4.1"
    local title = content:CreateFontString(nil, "ARTWORK")
    title:SetPoint("TOPLEFT", 16, -16)
    GSI_UI:ApplyFont(title, "TITLE")
    AnchorBlizzLine(title, "LEFT", false)
    title:SetText(string.format("GearSetImprover Forever (GSI) |cff888888v%s|r", version))

    local subText = content:CreateFontString(nil, "ARTWORK")
    subText:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
    GSI_UI:ApplyFont(subText, "SMALL")
    AnchorBlizzLine(subText, "LEFT", true)
    subText:SetText("Gear scoring & Best Available Gear optimizer built specifically for WoW Forever.\nConfigure addon settings below or access guides and tools.")

    -- Action Buttons (Row 1)
    local function SkinBlizzBtn(btn, isPrimary)
        if not btn then return end
        if GSI_UI and GSI_UI.SkinButton then
            GSI_UI:SkinButton(btn, btn:GetText(), isPrimary and "PRIMARY" or "SECONDARY")
        end
        local fs = btn:GetFontString()
        if fs and GSI_UI and GSI_UI.ApplyFont then
            GSI_UI:ApplyFont(fs, "BODY")
        end
    end

    local openBtn = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    openBtn:SetSize(150, 24)
    openBtn:SetPoint("TOPLEFT", subText, "BOTTOMLEFT", 0, -12)
    openBtn:SetText("Open Main Window")
    SkinBlizzBtn(openBtn, true)
    openBtn:SetScript("OnClick", function()
        if Settings and Settings.Close then
            Settings.Close()
        elseif InterfaceOptionsFrame then
            InterfaceOptionsFrame:Hide()
        end
        GSI_UI:Toggle()
    end)

    local tutBtn = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    tutBtn:SetSize(100, 24)
    tutBtn:SetPoint("LEFT", openBtn, "RIGHT", 8, 0)
    tutBtn:SetText("Tutorial")
    SkinBlizzBtn(tutBtn, false)
    tutBtn:SetScript("OnClick", function()
        GSI_UI:OpenTutorial()
    end)

    local clBtn = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    clBtn:SetSize(110, 24)
    clBtn:SetPoint("LEFT", tutBtn, "RIGHT", 8, 0)
    clBtn:SetText("Changelog")
    SkinBlizzBtn(clBtn, false)
    clBtn:SetScript("OnClick", function()
        GSI_UI:OpenChangelog()
    end)

    -- Action Buttons (Row 2)
    local logBtn = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    logBtn:SetSize(110, 24)
    logBtn:SetPoint("TOPLEFT", openBtn, "BOTTOMLEFT", 0, -6)
    logBtn:SetText("Log Export")
    SkinBlizzBtn(logBtn, false)
    logBtn:SetScript("OnClick", function()
        if GSI_Logger and GSI_Logger.ShowExportWindow then
            GSI_Logger:ShowExportWindow()
        end
    end)

    local creditsBtn = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    creditsBtn:SetSize(100, 24)
    creditsBtn:SetPoint("LEFT", logBtn, "RIGHT", 8, 0)
    creditsBtn:SetText("Credits")
    SkinBlizzBtn(creditsBtn, false)
    creditsBtn:SetScript("OnClick", function()
        GSI_UI:OpenCreditsModal()
    end)

    local lockedBtn = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    lockedBtn:SetSize(160, 24)
    lockedBtn:SetPoint("LEFT", creditsBtn, "RIGHT", 8, 0)
    lockedBtn:SetText("Manage Locked Items...")
    SkinBlizzBtn(lockedBtn, false)
    lockedBtn:SetScript("OnClick", function()
        if GSI_UI.OpenLockedCleanUpDialog then
            GSI_UI:OpenLockedCleanUpDialog(panel)
        end
    end)

    local blizzDeMacroBtn = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    blizzDeMacroBtn:SetSize(135, 24)
    blizzDeMacroBtn:SetPoint("LEFT", lockedBtn, "RIGHT", 8, 0)
    blizzDeMacroBtn:SetText("Pickup DE Macro")
    SkinBlizzBtn(blizzDeMacroBtn, false)
    blizzDeMacroBtn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    blizzDeMacroBtn:RegisterForDrag("LeftButton")
    blizzDeMacroBtn:SetScript("OnDragStart", function()
        if GSI_UI.PickupDisenchantMacro then
            GSI_UI:PickupDisenchantMacro()
        end
    end)
    blizzDeMacroBtn:SetScript("OnClick", function()
        if GSI_UI.PickupDisenchantMacro then
            GSI_UI:PickupDisenchantMacro()
        end
    end)
    blizzDeMacroBtn:SetScript("OnEnter", function(selfBtn)
        GameTooltip:SetOwner(selfBtn, "ANCHOR_TOP")
        GameTooltip:ClearLines()
        GameTooltip:AddLine("|cffffcc00Disenchant Clean-up Macro|r", 1, 1, 1)
        GameTooltip:AddLine("Click or drag to place a macro ('GSI: DE Clean') on your Action Bar that disenchants obsolete gear items from the Clean-up list one by one.", 0.9, 0.9, 0.9, true)
        GameTooltip:AddLine("|cff00ff00Click / Drag:|r Attach macro to cursor", 0, 1, 0)
        GameTooltip:Show()
    end)
    blizzDeMacroBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    local function UpdateBlizzDEMacroVisibility()
        local hasDE = GSI_UI.HasDisenchantSpell and GSI_UI:HasDisenchantSpell()
        blizzDeMacroBtn:SetShown(hasDE and true or false)
    end
    UpdateBlizzDEMacroVisibility()

    -- Section: General Options
    local function AddBlizzCheck(label, key, parentFrame, relativeTo, yOffset, callback, defaultVal)
        local cb = CreateFrame("CheckButton", nil, parentFrame or content, "UICheckButtonTemplate")
        cb:SetPoint("TOPLEFT", relativeTo, "BOTTOMLEFT", 0, yOffset or -6)
        cb.text = cb:CreateFontString(nil, "OVERLAY")
        GSI_UI:ApplyFont(cb.text, "BODY")
        AnchorBlizzCheckLabel(cb, label)
        local isChecked = false
        if GearSetImproverDB and GearSetImproverDB[key] ~= nil then
            isChecked = (GearSetImproverDB[key] == true)
        elseif defaultVal ~= nil then
            isChecked = (defaultVal == true)
        else
            isChecked = (GearSetImproverDB and GearSetImproverDB[key] ~= false)
        end
        cb:SetChecked(isChecked)
        cb:SetScript("OnClick", function(selfBtn)
            if not GearSetImproverDB then GearSetImproverDB = {} end
            GearSetImproverDB[key] = selfBtn:GetChecked() and true or false
            if callback then callback(GearSetImproverDB[key]) end
        end)
        return cb
    end

    local cbEnabled = AddBlizzCheck("Enable Addon", "enabled", content, logBtn, -16)
    local cbMinimap = AddBlizzCheck("Show Minimap Button", "showMinimap", content, cbEnabled, -6, function(val)
        if GSI_MinimapButton then GSI_MinimapButton:Toggle(val) end
    end)
    local cbDisableChat = AddBlizzCheck("Disable Chat Output (Silent Mode)", "disableChatOutput", content, cbMinimap, -6, function(val)
        if GSI_UI and GSI_UI.cbDisableChat then
            GSI_UI.cbDisableChat:SetChecked(val)
        end
    end, false)
    panel.cbDisableChat = cbDisableChat

    local cbDebug = AddBlizzCheck("Show Debug Stat Weights in Tooltips", "debug", content, cbDisableChat, -6, nil, false)
    local cbAutoSave = AddBlizzCheck("Auto-save Equipment Sets to Character Profile", "autoSaveEquipmentSet", content, cbDebug, -6)
    local cbSituational = AddBlizzCheck("Include situational effects in GSI Score (e.g. vs Undead / Dragons)", "includeSituational", content, cbAutoSave, -6, function(val)
        GSI_ItemScore:ResetCache()
    end)
    local cbIgnoreEnchants = AddBlizzCheck("Ignore item enchants in score and comparisons (Default: Enabled)", "ignoreEnchants", content, cbSituational, -6, function(val)
        if GSI_Config then GSI_Config.IgnoreEnchants = val end
        GSI_ItemScore:ResetCache()
        if GSI_UI and GSI_UI.RefreshPanel then GSI_UI:RefreshPanel(true) end
    end)

    -- Section: Tooltip Orientations (Multi-Profile Scores)
    local tooltipSpecHeader = content:CreateFontString(nil, "OVERLAY")
    tooltipSpecHeader:SetPoint("TOPLEFT", cbIgnoreEnchants, "BOTTOMLEFT", 0, -14)
    GSI_UI:ApplyFont(tooltipSpecHeader, "CARD_TITLE")
    AnchorBlizzLine(tooltipSpecHeader, "LEFT", true)
    tooltipSpecHeader:SetText("Tooltip Orientations & Specs (ST, AoE, Tank):")

    local tooltipSpecSub = content:CreateFontString(nil, "OVERLAY")
    tooltipSpecSub:SetPoint("TOPLEFT", tooltipSpecHeader, "BOTTOMLEFT", 0, -4)
    GSI_UI:ApplyFont(tooltipSpecSub, "SMALL")
    AnchorBlizzLine(tooltipSpecSub, "LEFT", true)
    tooltipSpecSub:SetText("Choose which orientations and specs display a GSI Score in item tooltips:")

    local playerClass = (GSI_ClassicData and GSI_ClassicData.GetPlayerClass and GSI_ClassicData:GetPlayerClass())
        or select(2, UnitClass("player")) or "WARRIOR"
    local profiles = self:GetClassProfiles(playerClass)
    local profileCheckboxes = {}

    local lastSpecElem = tooltipSpecSub
    for idx, pInfo in ipairs(profiles) do
        local cbSpec = CreateFrame("CheckButton", "GSI_BlizzTooltipProfileCheck_" .. idx, content, "UICheckButtonTemplate")
        cbSpec:SetPoint("TOPLEFT", lastSpecElem, "BOTTOMLEFT", 0, -4)
        cbSpec.text = cbSpec:CreateFontString(nil, "OVERLAY")
        GSI_UI:ApplyFont(cbSpec.text, "BODY")
        AnchorBlizzCheckLabel(cbSpec, pInfo.label)
        cbSpec.profileKey = pInfo.key

        local curChecked = false
        if GearSetImproverDB and GearSetImproverDB.tooltipProfiles and GearSetImproverDB.tooltipProfiles[playerClass] then
            curChecked = (GearSetImproverDB.tooltipProfiles[playerClass][pInfo.key] == true)
        end
        cbSpec:SetChecked(curChecked)

        cbSpec:SetScript("OnClick", function(selfBtn)
            if not GearSetImproverDB then GearSetImproverDB = {} end
            if not GearSetImproverDB.tooltipProfiles then GearSetImproverDB.tooltipProfiles = {} end
            if not GearSetImproverDB.tooltipProfiles[playerClass] then GearSetImproverDB.tooltipProfiles[playerClass] = {} end
            GearSetImproverDB.tooltipProfiles[playerClass][selfBtn.profileKey] = selfBtn:GetChecked() and true or false
            if GSI_TooltipCache and GSI_TooltipCache.Invalidate then
                GSI_TooltipCache:Invalidate()
            end
        end)

        profileCheckboxes[pInfo.key] = cbSpec
        lastSpecElem = cbSpec
    end

    -- Section: Clean-up Filter Settings
    local junkHeader = content:CreateFontString(nil, "OVERLAY")
    junkHeader:SetPoint("TOPLEFT", lastSpecElem, "BOTTOMLEFT", 0, -14)
    GSI_UI:ApplyFont(junkHeader, "CARD_TITLE")
    AnchorBlizzLine(junkHeader, "LEFT", true)
    junkHeader:SetText("Clean-up (Outdated Gear) Settings:")

    local junkSub = content:CreateFontString(nil, "OVERLAY")
    junkSub:SetPoint("TOPLEFT", junkHeader, "BOTTOMLEFT", 0, -4)
    GSI_UI:ApplyFont(junkSub, "SMALL")
    AnchorBlizzLine(junkSub, "LEFT", true)
    junkSub:SetText("Identifies obsolete gear in bags. Gray trash items are never sold; Equipment Sets are protected.")

    local curJunkVal = (GearSetImproverDB and GearSetImproverDB.junkThreshold) or 5
    local junkValLabel = content:CreateFontString(nil, "OVERLAY")
    junkValLabel:SetPoint("TOPLEFT", junkSub, "BOTTOMLEFT", 0, -10)
    GSI_UI:ApplyFont(junkValLabel, "SMALL")
    AnchorBlizzLine(junkValLabel, "LEFT", true)
    junkValLabel:SetText(string.format("Threshold: |cffffffff%d GSI Score|r (Default: 5)", curJunkVal))

    local sliderBg = CreateFrame("Frame", nil, content, BACKDROP_TEMPLATE)
    sliderBg:SetPoint("TOPLEFT", junkValLabel, "BOTTOMLEFT", 0, -12)

    local junkSlider = CreateFrame("Slider", "GSI_BlizzJunkSlider", content)
    junkSlider:SetPoint("TOPLEFT", junkValLabel, "BOTTOMLEFT", 0, -8)
    SkinSlider(junkSlider, sliderBg, 240, 8)
    junkSlider:SetMinMaxValues(1, 50)
    junkSlider:SetValue(curJunkVal)
    junkSlider:SetValueStep(1)

    local minLbl = content:CreateFontString(nil, "OVERLAY")
    minLbl:SetPoint("TOPLEFT", junkSlider, "BOTTOMLEFT", 0, -2)
    GSI_UI:ApplyFont(minLbl, "SMALL")
    minLbl:SetText("1")

    local maxLbl = content:CreateFontString(nil, "OVERLAY")
    maxLbl:SetPoint("TOPRIGHT", junkSlider, "BOTTOMRIGHT", 0, -2)
    GSI_UI:ApplyFont(maxLbl, "SMALL")
    maxLbl:SetText("50")

    local defaultBtn = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    defaultBtn:SetSize(85, 20)
    defaultBtn:SetPoint("LEFT", junkSlider, "RIGHT", 15, 0)
    defaultBtn:SetText("Reset (5)")
    SkinBlizzBtn(defaultBtn, false)
    defaultBtn:SetScript("OnClick", function()
        junkSlider:SetValue(5)
    end)

    junkSlider:SetScript("OnValueChanged", function(self, val)
        local v = math.floor(val)
        if GearSetImproverDB then GearSetImproverDB.junkThreshold = v end
        if GSI_Config then GSI_Config.JunkThreshold = v end
        junkValLabel:SetText(string.format("Threshold: |cffffffff%d GSI Score|r (Default: 5)", v))
        local junkFrame = GSI_UI.mainFrame and GSI_UI.mainFrame.tabFrames and GSI_UI.mainFrame.tabFrames["JUNK"]
        if junkFrame then
            if junkFrame._junkSlider and math.floor(junkFrame._junkSlider:GetValue()) ~= v then
                junkFrame._junkSlider:SetValue(v)
            end
            if junkFrame._junkSliderLabel then
                junkFrame._junkSliderLabel:SetText(string.format("Filter Threshold: Worse by at least %d GSI Score", v))
            end
            if GSI_UI.activeTab == "JUNK" and GSI_UI.mainFrame:IsShown() then
                GSI_UI:UpdateJunkList(junkFrame)
            end
        end
    end)

    local curOtherArmor = (GearSetImproverDB and GearSetImproverDB.junkIncludeOtherArmor) or false
    local armorCheck = CreateFrame("CheckButton", "GSI_BlizzArmorCheck", content, "UICheckButtonTemplate")
    armorCheck:SetPoint("TOPLEFT", minLbl, "BOTTOMLEFT", 0, -10)
    armorCheck.text = armorCheck:CreateFontString(nil, "OVERLAY")
    GSI_UI:ApplyFont(armorCheck.text, "BODY")
    AnchorBlizzCheckLabel(armorCheck, "Include other armor classes (e.g. Leather/Mail on Mage)")
    armorCheck:SetChecked(curOtherArmor)
    armorCheck:SetScript("OnClick", function(selfBtn)
        local isChecked = selfBtn:GetChecked() and true or false
        if GearSetImproverDB then GearSetImproverDB.junkIncludeOtherArmor = isChecked end
        if GSI_Config then GSI_Config.JunkIncludeOtherArmor = isChecked end
        local junkFrame = GSI_UI.mainFrame and GSI_UI.mainFrame.tabFrames and GSI_UI.mainFrame.tabFrames["JUNK"]
        if junkFrame then
            if junkFrame._armorCheck and junkFrame._armorCheck.SetChecked then
                junkFrame._armorCheck:SetChecked(isChecked)
            end
            if GSI_UI.activeTab == "JUNK" and GSI_UI.mainFrame:IsShown() then
                GSI_UI:UpdateJunkList(junkFrame)
            end
        end
    end)

    local curWhiteGear = (GearSetImproverDB and GearSetImproverDB.junkIncludeWhiteGear ~= false)
    local whiteGearCheck = CreateFrame("CheckButton", "GSI_BlizzWhiteGearCheck", content, "UICheckButtonTemplate")
    whiteGearCheck:SetPoint("TOPLEFT", armorCheck, "BOTTOMLEFT", 0, -4)
    whiteGearCheck.text = whiteGearCheck:CreateFontString(nil, "OVERLAY")
    GSI_UI:ApplyFont(whiteGearCheck.text, "BODY")
    AnchorBlizzCheckLabel(whiteGearCheck, "Include Common (White) obsolete gear")
    whiteGearCheck:SetChecked(curWhiteGear)
    whiteGearCheck:SetScript("OnClick", function(selfBtn)
        local isChecked = selfBtn:GetChecked() and true or false
        if GearSetImproverDB then GearSetImproverDB.junkIncludeWhiteGear = isChecked end
        if GSI_Config then GSI_Config.JunkIncludeWhiteGear = isChecked end
        local junkFrame = GSI_UI.mainFrame and GSI_UI.mainFrame.tabFrames and GSI_UI.mainFrame.tabFrames["JUNK"]
        if junkFrame then
            if junkFrame._whiteCheck and junkFrame._whiteCheck.SetChecked then
                junkFrame._whiteCheck:SetChecked(isChecked)
            end
            if GSI_UI.activeTab == "JUNK" and GSI_UI.mainFrame:IsShown() then
                GSI_UI:UpdateJunkList(junkFrame)
            end
        end
    end)

    local curUnusableGear = (GearSetImproverDB and GearSetImproverDB.junkIncludeUnusableGear ~= false)
    local unusableGearCheck = CreateFrame("CheckButton", "GSI_BlizzUnusableGearCheck", content, "UICheckButtonTemplate")
    unusableGearCheck:SetPoint("TOPLEFT", whiteGearCheck, "BOTTOMLEFT", 0, -4)
    unusableGearCheck.text = unusableGearCheck:CreateFontString(nil, "OVERLAY")
    GSI_UI:ApplyFont(unusableGearCheck.text, "BODY")
    AnchorBlizzCheckLabel(unusableGearCheck, "Include unusable gear (weapons/armor class cannot equip)")
    unusableGearCheck:SetChecked(curUnusableGear)
    unusableGearCheck:SetScript("OnClick", function(selfBtn)
        local isChecked = selfBtn:GetChecked() and true or false
        if GearSetImproverDB then GearSetImproverDB.junkIncludeUnusableGear = isChecked end
        if GSI_Config then GSI_Config.JunkIncludeUnusableGear = isChecked end
        local junkFrame = GSI_UI.mainFrame and GSI_UI.mainFrame.tabFrames and GSI_UI.mainFrame.tabFrames["JUNK"]
        if junkFrame then
            if junkFrame._unusableCheck and junkFrame._unusableCheck.SetChecked then
                junkFrame._unusableCheck:SetChecked(isChecked)
            end
            if GSI_UI.activeTab == "JUNK" and GSI_UI.mainFrame:IsShown() then
                GSI_UI:UpdateJunkList(junkFrame)
            end
        end
    end)

    local curMerchantOverlay = (GearSetImproverDB and GearSetImproverDB.merchantOverlayEnabled ~= false)
    local merchantOverlayCheck = CreateFrame("CheckButton", "GSI_BlizzMerchantOverlayCheck", content, "UICheckButtonTemplate")
    merchantOverlayCheck:SetPoint("TOPLEFT", unusableGearCheck, "BOTTOMLEFT", 0, -4)
    merchantOverlayCheck.text = merchantOverlayCheck:CreateFontString(nil, "OVERLAY")
    GSI_UI:ApplyFont(merchantOverlayCheck.text, "BODY")
    AnchorBlizzCheckLabel(merchantOverlayCheck, "Show Clean-up sell window at merchant (docked window with 'Sell All')")
    merchantOverlayCheck:SetChecked(curMerchantOverlay)
    merchantOverlayCheck:SetScript("OnClick", function(selfBtn)
        local isChecked = selfBtn:GetChecked() and true or false
        if GSI_UI and GSI_UI.SetMerchantOverlayEnabled then
            GSI_UI:SetMerchantOverlayEnabled(isChecked)
        else
            if not GearSetImproverDB then GearSetImproverDB = {} end
            GearSetImproverDB.merchantOverlayEnabled = isChecked
            if GSI_UI and GSI_UI.cbMerchantOverlay and GSI_UI.cbMerchantOverlay.SetChecked then
                GSI_UI.cbMerchantOverlay:SetChecked(isChecked)
            end
            if GSI_UI and GSI_UI.UpdateMerchantPanel then
                GSI_UI:UpdateMerchantPanel()
            elseif not isChecked then
                if GSI_UI and GSI_UI.merchantOverlay then GSI_UI.merchantOverlay:Hide() end
                if _G["GSI_MerchantOverlay"] then _G["GSI_MerchantOverlay"]:Hide() end
                if _G["GSI_MerchantToggleBtn"] then _G["GSI_MerchantToggleBtn"]:Hide() end
            end
        end
        local junkFrame = GSI_UI and GSI_UI.mainFrame and GSI_UI.mainFrame.tabFrames and GSI_UI.mainFrame.tabFrames["JUNK"]
        if junkFrame and GSI_UI.UpdateJunkList then
            pcall(function() GSI_UI:UpdateJunkList(junkFrame) end)
        end
    end)
    panel.cbMerchantOverlay = merchantOverlayCheck

    -- Section: Upgrade Toast Notifications
    local toastHeader = content:CreateFontString(nil, "OVERLAY")
    toastHeader:SetPoint("TOPLEFT", merchantOverlayCheck, "BOTTOMLEFT", 0, -14)
    GSI_UI:ApplyFont(toastHeader, "CARD_TITLE")
    AnchorBlizzLine(toastHeader, "LEFT", true)
    toastHeader:SetText("Upgrade Toast Notifications:")

    local cbToastEnabled = AddBlizzCheck("Enable on-screen Upgrade Toast alerts", "enableUpgradeToast", content, toastHeader, -6)
    local cbToastBlink = AddBlizzCheck("Pulsing / Blinking glow animation", "toastBlink", content, cbToastEnabled, -4)
    local cbToastSound = AddBlizzCheck("Play alert sound when an upgrade is found", "toastPlaySound", content, cbToastBlink, -4)

    local curDuration = (GearSetImproverDB and GearSetImproverDB.toastDuration) or 60
    local toastDurationLabel = content:CreateFontString(nil, "OVERLAY")
    toastDurationLabel:SetPoint("TOPLEFT", cbToastSound, "BOTTOMLEFT", 0, -8)
    GSI_UI:ApplyFont(toastDurationLabel, "SMALL")
    AnchorBlizzLine(toastDurationLabel, "LEFT", true)
    toastDurationLabel:SetText(string.format("Display Duration: |cffffffff%d seconds|r (Default: 60s)", curDuration))

    local toastSliderBg = CreateFrame("Frame", nil, content, BACKDROP_TEMPLATE)
    toastSliderBg:SetPoint("TOPLEFT", toastDurationLabel, "BOTTOMLEFT", 0, -12)

    local toastDurationSlider = CreateFrame("Slider", "GSI_BlizzToastDurationSlider", content)
    toastDurationSlider:SetPoint("TOPLEFT", toastDurationLabel, "BOTTOMLEFT", 0, -8)
    SkinSlider(toastDurationSlider, toastSliderBg, 240, 8)
    toastDurationSlider:SetMinMaxValues(10, 120)
    toastDurationSlider:SetValue(curDuration)
    toastDurationSlider:SetValueStep(5)

    local dMinLbl = content:CreateFontString(nil, "OVERLAY")
    dMinLbl:SetPoint("TOPLEFT", toastDurationSlider, "BOTTOMLEFT", 0, -2)
    GSI_UI:ApplyFont(dMinLbl, "SMALL")
    dMinLbl:SetText("10s")

    local dMaxLbl = content:CreateFontString(nil, "OVERLAY")
    dMaxLbl:SetPoint("TOPRIGHT", toastDurationSlider, "BOTTOMRIGHT", 0, -2)
    GSI_UI:ApplyFont(dMaxLbl, "SMALL")
    dMaxLbl:SetText("120s")

    local testToastBtn = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    testToastBtn:SetSize(125, 22)
    testToastBtn:SetPoint("LEFT", toastDurationSlider, "RIGHT", 25, 0)
    testToastBtn:SetText("Test Toast Alert")
    SkinBlizzBtn(testToastBtn, true)
    testToastBtn:SetScript("OnClick", function()
        if GSI_UpgradeToast and GSI_UpgradeToast.TestToast then
            GSI_UpgradeToast:TestToast()
        end
    end)

    toastDurationSlider:SetScript("OnValueChanged", function(self, val)
        local v = math.floor(val + 0.5)
        if GearSetImproverDB then GearSetImproverDB.toastDuration = v end
        toastDurationLabel:SetText(string.format("Display Duration: |cffffffff%d seconds|r (Default: 60s)", v))
    end)

    -- Anchor Mode Section
    local anchorHeader = content:CreateFontString(nil, "OVERLAY")
    anchorHeader:SetPoint("TOPLEFT", dMinLbl, "BOTTOMLEFT", 0, -14)
    GSI_UI:ApplyFont(anchorHeader, "CARD_TITLE")
    AnchorBlizzLine(anchorHeader, "LEFT", true)
    anchorHeader:SetText("Toast Notification Position & Anchor:")

    -- Anchor Mode Checkbox
    local cbAnchorMode = CreateFrame("CheckButton", "GSI_BlizzAnchorModeCheck", content, "UICheckButtonTemplate")
    cbAnchorMode:SetPoint("TOPLEFT", anchorHeader, "BOTTOMLEFT", 0, -4)
    cbAnchorMode.text = cbAnchorMode:CreateFontString(nil, "OVERLAY")
    GSI_UI:ApplyFont(cbAnchorMode.text, "BODY")
    AnchorBlizzCheckLabel(cbAnchorMode, "Show movable Anchor on screen (Unlock to reposition)")

    -- Buttons row under checkbox
    local toggleAnchorBtn = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    toggleAnchorBtn:SetSize(125, 22)
    toggleAnchorBtn:SetPoint("TOPLEFT", cbAnchorMode, "BOTTOMLEFT", 4, -6)
    toggleAnchorBtn:SetText("Unlock Anchor")
    SkinBlizzBtn(toggleAnchorBtn, false)

    local resetAnchorBtn = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    resetAnchorBtn:SetSize(110, 22)
    resetAnchorBtn:SetPoint("LEFT", toggleAnchorBtn, "RIGHT", 8, 0)
    resetAnchorBtn:SetText("Reset Position")
    SkinBlizzBtn(resetAnchorBtn, false)

    local anchorStatusLbl = content:CreateFontString(nil, "OVERLAY")
    anchorStatusLbl:SetPoint("LEFT", resetAnchorBtn, "RIGHT", 12, 0)
    anchorStatusLbl:SetPoint("RIGHT", content, "RIGHT", -16, 0)
    anchorStatusLbl:SetJustifyH("LEFT")
    if anchorStatusLbl.SetWordWrap then anchorStatusLbl:SetWordWrap(true) end
    GSI_UI:ApplyFont(anchorStatusLbl, "SMALL")
    anchorStatusLbl:SetText("|cff888888Status: Locked in place|r")

    local function UpdateContentHeight()
        local topY = content:GetTop()
        local toggleBot = toggleAnchorBtn and toggleAnchorBtn:GetBottom()
        local statusBot = anchorStatusLbl and anchorStatusLbl:GetBottom()
        local bottomY = nil
        if toggleBot and statusBot then
            bottomY = math.min(toggleBot, statusBot)
        else
            bottomY = toggleBot or statusBot
        end
        local estimatedMin = 920 + (#profiles * 30)
        if topY and bottomY and topY > bottomY then
            content:SetHeight(math.max(estimatedMin, math.ceil(topY - bottomY) + 32))
        else
            content:SetHeight(estimatedMin)
        end
    end

    local function UpdateAnchorUI(isShown)
        cbAnchorMode:SetChecked(isShown == true)
        if isShown then
            toggleAnchorBtn:SetText("|cffff5555Lock Anchor|r")
            anchorStatusLbl:SetText("|cff00ff00Movable Mode Active – Drag box on screen, then click Lock.|r")
        else
            toggleAnchorBtn:SetText("Unlock Anchor")
            anchorStatusLbl:SetText("|cff888888Status: Locked in place|r")
        end
        UpdateContentHeight()
    end

    cbAnchorMode:SetScript("OnClick", function(self)
        local shouldShow = self:GetChecked()
        if GSI_UpgradeToast and GSI_UpgradeToast.ToggleAnchor then
            GSI_UpgradeToast:ToggleAnchor(shouldShow)
        end
    end)

    toggleAnchorBtn:SetScript("OnClick", function()
        if GSI_UpgradeToast and GSI_UpgradeToast.ToggleAnchor then
            local nowShown = GSI_UpgradeToast:IsAnchorShown()
            GSI_UpgradeToast:ToggleAnchor(not nowShown)
        end
    end)

    resetAnchorBtn:SetScript("OnClick", function()
        if GSI_UpgradeToast and GSI_UpgradeToast.ResetAnchor then
            GSI_UpgradeToast:ResetAnchor()
        end
    end)

    if GSI_UpgradeToast then
        GSI_UpgradeToast.OnAnchorToggled = function(isShown)
            UpdateAnchorUI(isShown)
        end
    end

    panel.refresh = function()
        if GearSetImproverDB then
            cbEnabled:SetChecked(GearSetImproverDB.enabled ~= false)
            cbMinimap:SetChecked(GearSetImproverDB.showMinimap ~= false)
            cbDisableChat:SetChecked(GearSetImproverDB.disableChatOutput == true)
            cbDebug:SetChecked(GearSetImproverDB.debug == true)
            cbAutoSave:SetChecked(GearSetImproverDB.autoSaveEquipmentSet ~= false)
            cbSituational:SetChecked(GearSetImproverDB.includeSituational == true)
            cbIgnoreEnchants:SetChecked(GearSetImproverDB.ignoreEnchants ~= false)

            for pKey, cbObj in pairs(profileCheckboxes) do
                local checked = false
                if GearSetImproverDB.tooltipProfiles and GearSetImproverDB.tooltipProfiles[playerClass] then
                    checked = (GearSetImproverDB.tooltipProfiles[playerClass][pKey] == true)
                end
                cbObj:SetChecked(checked)
            end

            local jv = GearSetImproverDB.junkThreshold or 5
            junkSlider:SetValue(jv)
            junkValLabel:SetText(string.format("Threshold: |cffffffff%d GSI Score|r (Default: 5)", jv))
            armorCheck:SetChecked(GearSetImproverDB.junkIncludeOtherArmor == true)
            whiteGearCheck:SetChecked(GearSetImproverDB.junkIncludeWhiteGear ~= false)
            unusableGearCheck:SetChecked(GearSetImproverDB.junkIncludeUnusableGear ~= false)
            merchantOverlayCheck:SetChecked(GearSetImproverDB.merchantOverlayEnabled ~= false)

            cbToastEnabled:SetChecked(GearSetImproverDB.enableUpgradeToast ~= false)
            cbToastBlink:SetChecked(GearSetImproverDB.toastBlink ~= false)
            cbToastSound:SetChecked(GearSetImproverDB.toastPlaySound ~= false)
            local td = GearSetImproverDB.toastDuration or 60
            toastDurationSlider:SetValue(td)
            toastDurationLabel:SetText(string.format("Display Duration: |cffffffff%d seconds|r (Default: 60s)", td))

            if GSI_UpgradeToast and GSI_UpgradeToast.IsAnchorShown then
                UpdateAnchorUI(GSI_UpgradeToast:IsAnchorShown())
            end
        end
        UpdateBlizzDEMacroVisibility()
        UpdateContentHeight()
    end

    UpdateContentHeight()
    panel:HookScript("OnShow", function()
        if panel.refresh then panel.refresh() end
        if C_Timer and C_Timer.After then
            C_Timer.After(0, UpdateContentHeight)
        end
    end)

    if Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory then
        local category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
        Settings.RegisterAddOnCategory(category)
        self.blizzardCategory = category
    elseif InterfaceOptions_AddCategory then
        InterfaceOptions_AddCategory(panel)
    end
end

