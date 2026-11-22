-- ============================================================================
-- GearSetImprover (GSI) -- UI.lua (WoW Forever)
-- Premium Design System: "Obsidian Glass & Specular Precision"
-- Main Application Shell: Header, Spec/Mode Selectors, Score Pill, Sidebar & Routing
-- ============================================================================

GSI_UI = GSI_UI or {}

local GetItemInfo = (C_Item and C_Item.GetItemInfo) or _G.GetItemInfo or function() return nil end
local GetItemInfoInstant = (C_Item and C_Item.GetItemInfoInstant) or _G.GetItemInfoInstant or function() return nil end
local BackdropTemplateMixin = _G.BackdropTemplateMixin
local BACKDROP_TEMPLATE = BackdropTemplateMixin and "BackdropTemplate" or nil

local function SkinFrame(f, s, t) if GSI_UI.SkinFrame then return GSI_UI:SkinFrame(f, s, t) end end
local function SkinCard(f, i) if GSI_UI.SkinCard then return GSI_UI:SkinCard(f, i) end end
local function SkinButton(b, r, p) if GSI_UI.SkinButton then return GSI_UI:SkinButton(b, r, p) end end
local function CreateText(p, s, t, j) if GSI_UI.CreateText then return GSI_UI:CreateText(p, s, t, j) end end
local function CreatePill(p, t, v) if GSI_UI.CreatePill then return GSI_UI:CreatePill(p, t, v) end end
local function CreateBadge(p, t, c) if GSI_UI.CreateBadge then return GSI_UI:CreateBadge(p, t, c) end end
local function ApplyMicroBorder(f, c, tc) if GSI_UI.ApplyMicroBorder then return GSI_UI:ApplyMicroBorder(f, c, tc) end end
local function PP(pixels) return GSI_UI.PP and GSI_UI:PP(pixels) or (pixels or 1) end

local print = function(...)
    if GSI_Print then
        GSI_Print(...)
    elseif not (GearSetImproverDB and (GearSetImproverDB.disableChatOutput or GearSetImproverDB.disableChat)) then
        _G.print(...)
    end
end

local function ParseSpecAndModeTokens(tokens)
    if GSI_UI.ParseSpecAndModeTokens then
        return GSI_UI.ParseSpecAndModeTokens(tokens)
    end
    if _G.GSI_ParseSpecAndModeTokens then
        return _G.GSI_ParseSpecAndModeTokens(tokens)
    end
    return nil, nil
end

local T = GSI_UI.THEME

-- ----------------------------------------------------------------------------
-- 1. HAUPTFENSTER (Main Application Shell - 940 x 660 Obsidian Canvas)
-- ----------------------------------------------------------------------------
local mainFrame = CreateFrame("Frame", "GSI_MainFrame", UIParent, BACKDROP_TEMPLATE)
GSI_UI.mainFrame = mainFrame
mainFrame:SetSize(940, 660)
mainFrame:SetPoint("CENTER")
mainFrame:SetMovable(true)
mainFrame:EnableMouse(true)
mainFrame:SetClampedToScreen(true)
mainFrame:SetFrameStrata("HIGH")
mainFrame:SetFrameLevel(100)
if mainFrame.SetToplevel then mainFrame:SetToplevel(true) end
mainFrame:Hide()

-- Obsidian Glass Surface & Specular Lighting
SkinFrame(mainFrame, T.bgCanvas, true)

-- Ambient Outer Depth Shadow
mainFrame.ambientGlow = mainFrame:CreateTexture(nil, "BACKGROUND", nil, -2)
mainFrame.ambientGlow:SetPoint("TOPLEFT", -3, 3)
mainFrame.ambientGlow:SetPoint("BOTTOMRIGHT", 3, -3)
mainFrame.ambientGlow:SetColorTexture(0, 0, 0, 0.55)

-- Dynamic Class Accent Top Laser Line (2px)
local topAccent = mainFrame:CreateTexture(nil, "OVERLAY", nil, 5)
topAccent:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 1, -1)
topAccent:SetPoint("TOPRIGHT", mainFrame, "TOPRIGHT", -1, -1)
topAccent:SetHeight(PP(2))
topAccent:SetColorTexture(unpack(T.accent))
mainFrame.topAccent = topAccent

mainFrame.tabFrames = {}
GSI_UI.activeTab = "OVERVIEW"

-- ----------------------------------------------------------------------------
-- 2. HEADER BAR (Height: 52px)
-- ----------------------------------------------------------------------------
mainFrame.header = CreateFrame("Frame", nil, mainFrame, BACKDROP_TEMPLATE)
mainFrame.header:SetPoint("TOPLEFT", 1, -1)
mainFrame.header:SetPoint("TOPRIGHT", -1, -1)
mainFrame.header:SetHeight(52)
mainFrame.header:SetFrameStrata("HIGH")
mainFrame.header:SetFrameLevel(105)
mainFrame.header:EnableMouse(true)
mainFrame.header:RegisterForDrag("LeftButton")
mainFrame.header:SetScript("OnDragStart", function() mainFrame:StartMoving() end)
mainFrame.header:SetScript("OnDragStop", function() mainFrame:StopMovingOrSizing() end)
SkinFrame(mainFrame.header, T.bgHeader, false)

-- Bottom 1px header separator
local hDivider = mainFrame.header:CreateTexture(nil, "OVERLAY")
hDivider:SetPoint("BOTTOMLEFT", mainFrame.header, "BOTTOMLEFT", 0, 0)
hDivider:SetPoint("BOTTOMRIGHT", mainFrame.header, "BOTTOMRIGHT", 0, 0)
hDivider:SetHeight(PP(1))
hDivider:SetColorTexture(unpack(T.borderSubtle))

-- Brand Logo (Zoomed / Cropped 24x24)
mainFrame.iconFrame = CreateFrame("Frame", nil, mainFrame.header)
mainFrame.iconFrame:SetSize(26, 26)
mainFrame.iconFrame:SetPoint("LEFT", 14, 0)
ApplyMicroBorder(mainFrame.iconFrame, T.borderSpecular)

mainFrame.icon = mainFrame.iconFrame:CreateTexture(nil, "ARTWORK")
mainFrame.icon:SetAllPoints()
mainFrame.icon:SetTexture("Interface\\AddOns\\GearSetImprover\\Textures\\icon.png")
mainFrame.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

-- Brand Typography
mainFrame.title = CreateText(mainFrame.header, "TITLE", "GEARSET IMPROVER", "LEFT")
mainFrame.title:SetPoint("LEFT", mainFrame.iconFrame, "RIGHT", 10, 5)

mainFrame.subtitle = CreateText(mainFrame.header, "SMALL", "WOW FOREVER", "LEFT")
mainFrame.subtitle:SetPoint("TOPLEFT", mainFrame.title, "BOTTOMLEFT", 0, -1)
mainFrame.subtitle:SetTextColor(unpack(T.accentBright))

-- Schließen-Button (Clean Minimalist X)
mainFrame.close = CreateFrame("Button", nil, mainFrame.header, BACKDROP_TEMPLATE)
mainFrame.close:SetSize(26, 26)
mainFrame.close:SetPoint("RIGHT", mainFrame.header, "RIGHT", -12, 0)
mainFrame.close:SetFrameStrata("HIGH")
mainFrame.close:SetFrameLevel(120)
mainFrame.close:EnableMouse(true)
mainFrame.close:RegisterForClicks("LeftButtonUp", "RightButtonUp")
mainFrame.close:SetText("X")
SkinButton(mainFrame.close, "X", "SECONDARY")
mainFrame.close:SetScript("OnClick", function() mainFrame:Hide() end)

-- Settings-Button (Header Cog Icon)
mainFrame.settingsBtn = CreateFrame("Button", nil, mainFrame.header, BACKDROP_TEMPLATE)
mainFrame.settingsBtn:SetSize(26, 26)
mainFrame.settingsBtn:SetPoint("RIGHT", mainFrame.close, "LEFT", -6, 0)
mainFrame.settingsBtn:SetFrameStrata("HIGH")
mainFrame.settingsBtn:SetFrameLevel(120)
mainFrame.settingsBtn:EnableMouse(true)
mainFrame.settingsBtn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
SkinButton(mainFrame.settingsBtn, nil, "SECONDARY")

mainFrame.settingsBtn.icon = mainFrame.settingsBtn:CreateTexture(nil, "ARTWORK")
mainFrame.settingsBtn.icon:SetSize(16, 16)
mainFrame.settingsBtn.icon:SetPoint("CENTER")
mainFrame.settingsBtn.icon:SetTexture("Interface\\WorldMap\\Gear_64")
mainFrame.settingsBtn.icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
mainFrame.settingsBtn.icon:SetVertexColor(unpack(T.textSecondary))

mainFrame.settingsBtn:SetScript("OnEnter", function(selfBtn)
    selfBtn.icon:SetVertexColor(unpack(T.textPrimary))
    GameTooltip:SetOwner(selfBtn, "ANCHOR_BOTTOMRIGHT")
    GameTooltip:AddLine("Settings", 1, 0.82, 0)
    GameTooltip:AddLine("Opens GearSetImprover settings and options.", 1, 1, 1, true)
    GameTooltip:AddLine("|cff00ff00Left-Click:|r Open addon options", 0.7, 0.7, 0.7)
    GameTooltip:Show()
end)
mainFrame.settingsBtn:SetScript("OnLeave", function(selfBtn)
    selfBtn.icon:SetVertexColor(unpack(T.textSecondary))
    GameTooltip:Hide()
end)
mainFrame.settingsBtn:SetScript("OnClick", function()
    GSI_UI:OpenSettings()
end)

-- Live Score Widget (Header Right - SaaS Metrics Style)
local scoreWidget = CreateFrame("Frame", nil, mainFrame.header, BACKDROP_TEMPLATE)
scoreWidget:SetSize(244, 34)
scoreWidget:SetPoint("RIGHT", mainFrame.settingsBtn, "LEFT", -12, 0)
SkinCard(scoreWidget, false)
mainFrame.scoreWidget = scoreWidget

scoreWidget.lbl = CreateText(scoreWidget, "SMALL", "GEAR SCORE", "LEFT")
scoreWidget.lbl:SetPoint("LEFT", 10, 0)
if scoreWidget.lbl.SetWordWrap then scoreWidget.lbl:SetWordWrap(false) end

scoreWidget.val = CreateText(scoreWidget, "MONO_NUM", "0.0", "LEFT")
scoreWidget.val:SetPoint("LEFT", scoreWidget.lbl, "RIGHT", 8, 0)
scoreWidget.val:SetTextColor(unpack(T.textPrimary))
if scoreWidget.val.SetWordWrap then scoreWidget.val:SetWordWrap(false) end

scoreWidget.deltaPill = CreatePill(scoreWidget, "OPTIMAL", "ACCENT")
scoreWidget.deltaPill:SetPoint("RIGHT", -6, 0)
scoreWidget.val:SetPoint("RIGHT", scoreWidget.deltaPill, "LEFT", -8, 0)

function GSI_UI:UpdateTitleScore()
    if not mainFrame or not mainFrame.scoreWidget then return end
    local score = 0
    if GSI_OptimizationEngine and GSI_OptimizationEngine.EvaluateSetup then
        local ok, s = pcall(function()
            local setup = GSI_OptimizationEngine:GetCurrentSetup()
            return GSI_OptimizationEngine:EvaluateSetup(setup)
        end)
        if ok and type(s) == "number" then
            score = s
        end
    end

    mainFrame.scoreWidget.val:SetText(string.format("%.1f", score))

    local lastGain = GSI_UI.lastTotalGain or 0
    if lastGain and lastGain > 0.05 then
        mainFrame.scoreWidget.deltaPill:SetPillStyle(string.format("+%.1f", lastGain), "SUCCESS")
    else
        mainFrame.scoreWidget.deltaPill:SetPillStyle("OPTIMAL", "ACCENT")
    end
end

-- ----------------------------------------------------------------------------
-- 3. DROPDOWNS: SPECIALIZATION & MODE
-- ----------------------------------------------------------------------------

local function GetPlayerClassKey()
    if GSI_ClassicData and GSI_ClassicData.GetPlayerClass then
        return GSI_ClassicData:GetPlayerClass()
    end
    local _, engClass = UnitClass("player")
    if engClass and engClass ~= "" then
        return string.upper(engClass)
    end
    return "WARRIOR"
end

local function LayoutSingleLineButtonText(btn, leftRel, leftPoint, leftX, rightRel, rightPoint, rightX)
    local fs = btn and btn.GetFontString and btn:GetFontString()
    if not fs then return end
    fs:ClearAllPoints()
    fs:SetPoint("LEFT", leftRel, leftPoint, leftX, 0)
    fs:SetPoint("RIGHT", rightRel, rightPoint, rightX, 0)
    fs:SetJustifyH("LEFT")
    if fs.SetJustifyV then fs:SetJustifyV("MIDDLE") end
    if fs.SetWordWrap then fs:SetWordWrap(false) end
end

-- Spec Button
mainFrame.specBtn = CreateFrame("Button", nil, mainFrame.header, BACKDROP_TEMPLATE)
mainFrame.specBtn:SetSize(168, 26)
mainFrame.specBtn:SetPoint("RIGHT", mainFrame.scoreWidget, "LEFT", -10, 0)
mainFrame.specBtn:SetFrameStrata("HIGH")
mainFrame.specBtn:SetFrameLevel(120)
mainFrame.specBtn:EnableMouse(true)
mainFrame.specBtn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
SkinButton(mainFrame.specBtn, "Specialization", "SECONDARY")

mainFrame.specBtn.icon = mainFrame.specBtn:CreateTexture(nil, "ARTWORK")
mainFrame.specBtn.icon:SetSize(16, 16)
mainFrame.specBtn.icon:SetPoint("LEFT", mainFrame.specBtn, "LEFT", 6, 0)
mainFrame.specBtn.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

mainFrame.specBtn.arrow = mainFrame.specBtn:CreateTexture(nil, "ARTWORK")
mainFrame.specBtn.arrow:SetSize(14, 14)
mainFrame.specBtn.arrow:SetPoint("RIGHT", mainFrame.specBtn, "RIGHT", -4, 0)
mainFrame.specBtn.arrow:SetTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Up")

mainFrame.specBtn:SetText("Specialization")
LayoutSingleLineButtonText(mainFrame.specBtn, mainFrame.specBtn.icon, "RIGHT", 5, mainFrame.specBtn.arrow, "LEFT", -3)

-- Mode Button (Single Target / AoE / Survival / Threat)
mainFrame.modeBtn = CreateFrame("Button", nil, mainFrame.header, BACKDROP_TEMPLATE)
mainFrame.modeBtn:SetSize(140, 26)
mainFrame.modeBtn:SetPoint("RIGHT", mainFrame.specBtn, "LEFT", -8, 0)
mainFrame.modeBtn:SetFrameStrata("HIGH")
mainFrame.modeBtn:SetFrameLevel(120)
mainFrame.modeBtn:EnableMouse(true)
mainFrame.modeBtn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
SkinButton(mainFrame.modeBtn, "Mode", "SECONDARY")

mainFrame.modeBtn.arrow = mainFrame.modeBtn:CreateTexture(nil, "ARTWORK")
mainFrame.modeBtn.arrow:SetSize(14, 14)
mainFrame.modeBtn.arrow:SetPoint("RIGHT", mainFrame.modeBtn, "RIGHT", -4, 0)
mainFrame.modeBtn.arrow:SetTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Up")

mainFrame.modeBtn:SetText("Mode")
LayoutSingleLineButtonText(mainFrame.modeBtn, mainFrame.modeBtn, "LEFT", 8, mainFrame.modeBtn.arrow, "LEFT", -3)

-- Click backdrop to close open dropdowns
local closeMenuFrame = CreateFrame("Button", "GSI_DropdownBackdrop", UIParent)
closeMenuFrame:SetFrameStrata("FULLSCREEN_DIALOG")
closeMenuFrame:SetFrameLevel(450)
closeMenuFrame:SetAllPoints(UIParent)
closeMenuFrame:EnableMouse(true)
closeMenuFrame:RegisterForClicks("LeftButtonUp", "RightButtonUp")
closeMenuFrame:SetScript("OnClick", function()
    if specMenu then specMenu:Hide() end
    if modeMenu then modeMenu:Hide() end
    closeMenuFrame:Hide()
end)
closeMenuFrame:Hide()

-- Spec Dropdown Menu Frame
local specMenu = CreateFrame("Frame", "GSI_SpecDropdownMenu", UIParent, BACKDROP_TEMPLATE)
specMenu:SetSize(180, 116)
specMenu:SetFrameStrata("FULLSCREEN_DIALOG")
specMenu:SetFrameLevel(500)
specMenu:SetClampedToScreen(true)
specMenu:EnableMouse(true)
specMenu:Hide()
SkinFrame(specMenu, T.bgCardBottom, true)

specMenu:HookScript("OnHide", function()
    if not (modeMenu and modeMenu:IsShown()) then
        closeMenuFrame:Hide()
    end
end)

local specMenuItems = {}

-- Top row: follow the spec the character plays (talent detection)
local specAutoItem = CreateFrame("Button", nil, specMenu, BACKDROP_TEMPLATE)
specAutoItem:SetSize(172, 25)
specAutoItem:SetPoint("TOP", 0, -4)
specAutoItem:SetFrameLevel(510)
specAutoItem:EnableMouse(true)
specAutoItem:RegisterForClicks("LeftButtonUp", "RightButtonUp")
SkinButton(specAutoItem, "Auto", "SECONDARY")
specAutoItem.icon = specAutoItem:CreateTexture(nil, "ARTWORK")
specAutoItem.icon:SetSize(16, 16)
specAutoItem.icon:SetPoint("LEFT", specAutoItem, "LEFT", 6, 0)
specAutoItem.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
specAutoItem.icon:SetTexture(136243) -- Trade_Engineering (gear)
LayoutSingleLineButtonText(specAutoItem, specAutoItem.icon, "RIGHT", 6, specAutoItem, "RIGHT", -6)
specAutoItem:SetScript("OnClick", function()
    specMenu:Hide()
    closeMenuFrame:Hide()
    if GSI_StatWeights and GSI_StatWeights.SetSpecAuto then
        GSI_StatWeights:SetSpecAuto(true)
    end
    GSI_UI:UpdateSpecButton()
    GSI_UI:UpdateModeUI()
    pcall(function() GSI_UI:UpdateTitleScore() end)
    GSI_UI:RefreshPanel(true)
end)
specAutoItem:SetScript("OnEnter", function(selfBtn)
    GameTooltip:SetOwner(selfBtn, "ANCHOR_LEFT")
    GameTooltip:AddLine("Auto: current specialization", 1, 0.82, 0)
    GameTooltip:AddLine("Scores follow the talent tree you have the most points in and switch by themselves when you respec. Picking a spec below pins it instead.", 1, 1, 1, true)
    GameTooltip:AddLine("Feral druids: Cat or Bear below sets your feral role and stays on Auto.", 0.7, 0.9, 1, true)
    GameTooltip:Show()
end)
specAutoItem:SetScript("OnLeave", function() GameTooltip:Hide() end)

for i = 1, 4 do
    local btn = CreateFrame("Button", nil, specMenu, BACKDROP_TEMPLATE)
    btn:SetSize(172, 25)
    btn:SetPoint("TOP", 0, -4 - (i*27))
    btn:SetFrameLevel(510)
    btn:EnableMouse(true)
    btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    SkinButton(btn, "Spec " .. i, "SECONDARY")

    local icon = btn:CreateTexture(nil, "ARTWORK")
    icon:SetSize(16, 16)
    icon:SetPoint("LEFT", btn, "LEFT", 6, 0)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    btn.icon = icon

    LayoutSingleLineButtonText(btn, icon, "RIGHT", 6, btn, "RIGHT", -6)

    btn.specIndex = i
    local specIdx = i
    btn:SetScript("OnClick", function(selfBtn)
        local targetSpec = (selfBtn and selfBtn.specIndex) or specIdx
        if GSI_StatWeights and GSI_StatWeights.ChooseSpec then
            GSI_StatWeights:ChooseSpec(targetSpec)
        elseif GearSetImproverDB then
            GearSetImproverDB.selectedSpec = targetSpec
        end
        specMenu:Hide()
        closeMenuFrame:Hide()
        GSI_UI:UpdateSpecButton()
        GSI_UI:UpdateModeUI()
        if GSI_ItemScore and GSI_ItemScore.ResetCache then GSI_ItemScore:ResetCache() end
        if GSI_OptimizationEngine and GSI_OptimizationEngine.ResetCache then GSI_OptimizationEngine:ResetCache() end
        pcall(function() GSI_UI:UpdateTitleScore() end)
        GSI_UI:RefreshPanel(true)
    end)
    specMenuItems[i] = btn
end

function GSI_UI:UpdateSpecButton()
    if not mainFrame or not mainFrame.specBtn then return end
    pcall(function()
        local class = GetPlayerClassKey()
        local specIndex = GSI_StatWeights:GetActiveSpecIndex()
        local classData = GSI_ClassicData and GSI_ClassicData.Classes and GSI_ClassicData.Classes[class]
        local specData = classData and classData.specs and classData.specs[specIndex]
        local specName = (specData and specData.name) or ("Spec " .. tostring(specIndex))
        local iconID = specData and specData.icon
        if not iconID or iconID == 0 then
            local fallbackIcons = {
                WARRIOR = 132341, PALADIN = 135920, HUNTER = 132212, ROGUE = 132292,
                PRIEST = 135940, SHAMAN = 136048, MAGE = 135846, WARLOCK = 136145, DRUID = 132276
            }
            iconID = fallbackIcons[class] or 134400
        end

        local isAuto = GSI_StatWeights.IsSpecAuto and GSI_StatWeights:IsSpecAuto()
        mainFrame.specBtn:SetText(isAuto and ("Auto: " .. specName) or specName)
        LayoutSingleLineButtonText(mainFrame.specBtn, mainFrame.specBtn.icon, "RIGHT", 5, mainFrame.specBtn.arrow, "LEFT", -3)
        if mainFrame.specBtn.icon then
            mainFrame.specBtn.icon:SetTexture(iconID)
        end
    end)
end

-- Mode Dropdown Menu Frame
local modeMenu = CreateFrame("Frame", "GSI_ModeDropdownMenu", UIParent, BACKDROP_TEMPLATE)
modeMenu:SetSize(148, 64)
modeMenu:SetFrameStrata("FULLSCREEN_DIALOG")
modeMenu:SetFrameLevel(500)
modeMenu:SetClampedToScreen(true)
modeMenu:EnableMouse(true)
modeMenu:Hide()
SkinFrame(modeMenu, T.bgCardBottom, true)

modeMenu:HookScript("OnHide", function()
    if not (specMenu and specMenu:IsShown()) then
        closeMenuFrame:Hide()
    end
end)

local modeMenuItems = {}
for i = 1, 2 do
    local btn = CreateFrame("Button", nil, modeMenu, BACKDROP_TEMPLATE)
    btn:SetSize(140, 25)
    btn:SetPoint("TOP", 0, -4 - ((i-1)*27))
    btn:SetFrameLevel(510)
    btn:EnableMouse(true)
    btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    SkinButton(btn, "Mode " .. i, "SECONDARY")
    LayoutSingleLineButtonText(btn, btn, "LEFT", 8, btn, "RIGHT", -6)
    modeMenuItems[i] = btn
end

function GSI_UI:UpdateModeUI()
    if not mainFrame or not mainFrame.modeBtn then return end
    pcall(function()
        local role = GSI_StatWeights:GetRole()
        local label = ""
        if role == "tank" then
            local tMode = (GearSetImproverDB and GearSetImproverDB.tankMode) or "Survival"
            label = (tMode == "Survival") and "Survival" or "Threat / DPS"
        else
            local wMode = (GearSetImproverDB and GearSetImproverDB.weightMode) or "ST"
            label = (wMode == "ST") and "Single Target" or "AoE / Trash"
        end
        mainFrame.modeBtn:SetText(label)
        LayoutSingleLineButtonText(mainFrame.modeBtn, mainFrame.modeBtn, "LEFT", 8, mainFrame.modeBtn.arrow, "LEFT", -3)
    end)
end

mainFrame.specBtn:SetScript("OnClick", function()
    local ok, err = pcall(function()
        if specMenu:IsShown() then
            specMenu:Hide()
            closeMenuFrame:Hide()
            return
        end
        if modeMenu then modeMenu:Hide() end
        local class = GetPlayerClassKey()
        local classData = GSI_ClassicData and GSI_ClassicData.Classes and GSI_ClassicData.Classes[class]
        local numSpecs = (class == "DRUID") and 4 or 3
        specMenu:SetHeight(((numSpecs + 1) * 27) + 8)

        local currentSpec = GSI_StatWeights:GetActiveSpecIndex()
        local isAuto = GSI_StatWeights.IsSpecAuto and GSI_StatWeights:IsSpecAuto()
        local detected = GSI_StatWeights.DetectCurrentSpec and GSI_StatWeights:DetectCurrentSpec() or currentSpec
        local detData = classData and classData.specs and classData.specs[detected]
        local autoLabel = "Auto: " .. ((detData and detData.name) or ("Spec " .. tostring(detected)))
        specAutoItem:SetText(isAuto and string.format("|cff00ff00%s|r", autoLabel) or autoLabel)
        LayoutSingleLineButtonText(specAutoItem, specAutoItem.icon, "RIGHT", 6, specAutoItem, "RIGHT", -6)
        for i = 1, 4 do
            if i <= numSpecs then
                local specData = classData and classData.specs and classData.specs[i]
                local name = (specData and specData.name) or ("Spec " .. i)
                local icon = specData and specData.icon or 134400
                if i == currentSpec and not isAuto then
                    specMenuItems[i]:SetText(string.format("|cff00ff00%s|r", name))
                else
                    specMenuItems[i]:SetText(name)
                end
                LayoutSingleLineButtonText(specMenuItems[i], specMenuItems[i].icon, "RIGHT", 6, specMenuItems[i], "RIGHT", -6)
                if specMenuItems[i].icon then
                    specMenuItems[i].icon:SetTexture(icon)
                end
                specMenuItems[i]:Show()
            else
                specMenuItems[i]:Hide()
            end
        end
        specMenu:ClearAllPoints()
        specMenu:SetPoint("TOPRIGHT", mainFrame.specBtn, "BOTTOMRIGHT", 0, -2)
        closeMenuFrame:Show()
        specMenu:Show()
        if specMenu.Raise then specMenu:Raise() end
    end)
    if not ok then
        print("|cffff0000[GSI ERROR]|r Spec dropdown error: " .. tostring(err))
    end
end)

local function ConfigureModeMenuItem(btn, label, isSelected, onApply)
    if isSelected then
        btn:SetText(string.format("|cff00ff00%s|r", label))
    else
        btn:SetText(label)
    end
    LayoutSingleLineButtonText(btn, btn, "LEFT", 8, btn, "RIGHT", -6)
    btn:SetScript("OnClick", function()
        onApply()
        modeMenu:Hide()
        closeMenuFrame:Hide()
        GSI_UI:UpdateModeUI()
        if GSI_ItemScore and GSI_ItemScore.ResetCache then GSI_ItemScore:ResetCache() end
        if GSI_OptimizationEngine and GSI_OptimizationEngine.ResetCache then GSI_OptimizationEngine:ResetCache() end
        pcall(function() GSI_UI:UpdateTitleScore() end)
        GSI_UI:RefreshPanel(true)
    end)
    btn:Show()
end

mainFrame.modeBtn:SetScript("OnClick", function()
    local ok, err = pcall(function()
        if modeMenu:IsShown() then
            modeMenu:Hide()
            closeMenuFrame:Hide()
            return
        end
        if specMenu then specMenu:Hide() end

        local role = GSI_StatWeights:GetRole()
        if role == "tank" then
            local currentTankMode = (GearSetImproverDB and GearSetImproverDB.tankMode) or "Survival"
            ConfigureModeMenuItem(modeMenuItems[1], "Survival", currentTankMode == "Survival", function()
                if GearSetImproverDB then GearSetImproverDB.tankMode = "Survival" end
            end)
            ConfigureModeMenuItem(modeMenuItems[2], "Threat / DPS", currentTankMode ~= "Survival", function()
                if GearSetImproverDB then GearSetImproverDB.tankMode = "DMG" end
            end)
        else
            local currentWeightMode = (GearSetImproverDB and GearSetImproverDB.weightMode) or "ST"
            ConfigureModeMenuItem(modeMenuItems[1], "Single Target", currentWeightMode == "ST", function()
                if GearSetImproverDB then GearSetImproverDB.weightMode = "ST" end
            end)
            ConfigureModeMenuItem(modeMenuItems[2], "AoE / Trash", currentWeightMode ~= "ST", function()
                if GearSetImproverDB then GearSetImproverDB.weightMode = "AOE" end
            end)
        end

        modeMenu:ClearAllPoints()
        modeMenu:SetPoint("TOPRIGHT", mainFrame.modeBtn, "BOTTOMRIGHT", 0, -2)
        closeMenuFrame:Show()
        modeMenu:Show()
        if modeMenu.Raise then modeMenu:Raise() end
    end)
    if not ok then
        print("|cffff0000[GSI ERROR]|r Mode dropdown error: " .. tostring(err))
    end
end)

closeMenuFrame:SetScript("OnClick", function()
    if specMenu then specMenu:Hide() end
    if modeMenu then modeMenu:Hide() end
    closeMenuFrame:Hide()
end)

mainFrame:HookScript("OnHide", function()
    if specMenu then specMenu:Hide() end
    if modeMenu then modeMenu:Hide() end
    if closeMenuFrame then closeMenuFrame:Hide() end
end)

mainFrame:HookScript("OnDragStart", function()
    if specMenu then specMenu:Hide() end
    if modeMenu then modeMenu:Hide() end
    if closeMenuFrame then closeMenuFrame:Hide() end
end)

-- ----------------------------------------------------------------------------
-- ESCAPE-CONTROLLER & PROXY (UISpecialFrames Integration)
-- Ermöglicht das Schließen des Addons per ESC-Taste.
-- Bei geöffneten Dropdowns oder Unterdialogen (Modals) schließt ESC gestaffelt
-- (LIFO: 1. ESC schließt Dropdown/Modal, 2. ESC schließt Hauptfenster).
-- ----------------------------------------------------------------------------
local escProxy = CreateFrame("Frame", "GSI_EscProxy", UIParent)
escProxy:Hide()
GSI_UI.escProxy = escProxy

local function GetActiveModalFrame()
    if specMenu and specMenu:IsShown() then return specMenu end
    if modeMenu and modeMenu:IsShown() then return modeMenu end
    if _G.GSI_ProfileDropdownMenu and _G.GSI_ProfileDropdownMenu:IsShown() then return _G.GSI_ProfileDropdownMenu end
    if _G.GSI_WeightsIOFrame and _G.GSI_WeightsIOFrame:IsShown() then return _G.GSI_WeightsIOFrame end
    if _G.GSI_ProfilePromptModal and _G.GSI_ProfilePromptModal:IsShown() then return _G.GSI_ProfilePromptModal end
    if _G.GSI_ImportProfileChoiceDialog and _G.GSI_ImportProfileChoiceDialog:IsShown() then return _G.GSI_ImportProfileChoiceDialog end
    if GSI_UI.creditsFrame and GSI_UI.creditsFrame:IsShown() then return GSI_UI.creditsFrame end
    if GSI_UI.tutorialFrame and GSI_UI.tutorialFrame:IsShown() then return GSI_UI.tutorialFrame end
    if GSI_UI.changelogFrame and GSI_UI.changelogFrame:IsShown() then return GSI_UI.changelogFrame end
    if _G.GSI_LogExportFrame and _G.GSI_LogExportFrame:IsShown() then return _G.GSI_LogExportFrame end
    return nil
end

function GSI_UI:HasOpenModals()
    return GetActiveModalFrame() ~= nil
end

function GSI_UI:RegisterModalForEscape(modalFrame)
    if not modalFrame then return end
    modalFrame:HookScript("OnShow", function()
        if GSI_UI.escProxy then GSI_UI.escProxy:Show() end
    end)
    modalFrame:HookScript("OnHide", function()
        if GSI_UI.escProxy and not (mainFrame and mainFrame:IsShown()) and not GSI_UI:HasOpenModals() then
            GSI_UI.escProxy:Hide()
        end
    end)
end

-- Proxy ist aktiv, solange das Hauptfenster oder ein Modal geöffnet ist
mainFrame:HookScript("OnShow", function()
    escProxy:Show()
end)

mainFrame:HookScript("OnHide", function()
    if not GSI_UI:HasOpenModals() then
        escProxy:Hide()
    end
end)

escProxy:SetScript("OnHide", function(self)
    -- Falls das Hauptfenster bereits regulär (z.B. X-Button) geschlossen wurde und keine Modals offen sind: abbrechen
    if not (mainFrame and mainFrame:IsShown()) and not GSI_UI:HasOpenModals() then
        return
    end

    local activeModal = GetActiveModalFrame()
    if activeModal then
        -- 1. ESC: Schließt das oberste Modal oder Dropdown-Menü
        activeModal:Hide()
        if closeMenuFrame and closeMenuFrame:IsShown() then
            closeMenuFrame:Hide()
        end
        -- Proxy sofort reaktivieren, falls das Hauptfenster oder ein weiteres Modal noch offen ist
        if (mainFrame and mainFrame:IsShown()) or GSI_UI:HasOpenModals() then
            if C_Timer and C_Timer.After then
                C_Timer.After(0, function()
                    if (mainFrame and mainFrame:IsShown()) or GSI_UI:HasOpenModals() then
                        self:Show()
                    end
                end)
            else
                self:Show()
            end
        end
    elseif mainFrame and mainFrame:IsShown() then
        -- 2. ESC: Hauptfenster schließen
        mainFrame:Hide()
    end
end)

-- Registrierung in UISpecialFrames für sauberes, Taint-freies Schließen per ESC
if _G.UISpecialFrames then
    local registered = false
    for _, name in ipairs(_G.UISpecialFrames) do
        if name == "GSI_EscProxy" then
            registered = true
            break
        end
    end
    if not registered then
        table.insert(_G.UISpecialFrames, "GSI_EscProxy")
    end
end

-- ----------------------------------------------------------------------------
-- 4. SIDEBAR NAVIGATION (Width: 190px Obsidian Surface)
-- ----------------------------------------------------------------------------
mainFrame.sidebar = CreateFrame("Frame", nil, mainFrame, BACKDROP_TEMPLATE)
mainFrame.sidebar:SetPoint("TOPLEFT", 1, -53)
mainFrame.sidebar:SetPoint("BOTTOMLEFT", 1, 1)
mainFrame.sidebar:SetWidth(190)
mainFrame.sidebar:SetFrameStrata("HIGH")
mainFrame.sidebar:SetFrameLevel(105)
SkinFrame(mainFrame.sidebar, T.bgSidebar, false)

-- Right 1px micro-border separator
local sDivider = mainFrame.sidebar:CreateTexture(nil, "OVERLAY")
sDivider:SetPoint("TOPRIGHT", mainFrame.sidebar, "TOPRIGHT", 0, 0)
sDivider:SetPoint("BOTTOMRIGHT", mainFrame.sidebar, "BOTTOMRIGHT", 0, 0)
sDivider:SetWidth(PP(1))
sDivider:SetColorTexture(unpack(T.borderSubtle))

local navHeader = CreateText(mainFrame.sidebar, "SECTION", "WORKSPACE", "LEFT")
navHeader:SetPoint("TOPLEFT", 14, -14)

local TAB_DEFINITIONS = {
    { id = "OVERVIEW", label = "Overview",     sub = "Hero & KPI Analytics", icon = "Interface\\Icons\\INV_Misc_Gem_01" },
    { id = "GEAR",     label = "Gear Slots",   sub = "17-Slot Delta Engine", icon = "Interface\\Icons\\INV_Chest_Chain_03" },
    { id = "BIB",      label = "Best Available", sub = "Instant Upgrades",    icon = "Interface\\Icons\\INV_Misc_Bag_CoreFelclothBag" },
    { id = "WEIGHTS",  label = "Stat Weights", sub = "Scaling & Pawn Values", icon = "Interface\\Icons\\Spell_Holy_MindVision" },
    { id = "MACROS",   label = "Macros & Sets",sub = "1-Click Equip & Sync",  icon = "Interface\\Icons\\Trade_Engineering" },
    { id = "JUNK",     label = "Clean-up",     sub = "Outdated & Disenchant", icon = "Interface\\Icons\\INV_Enchant_Disenchant" },
    { id = "SETTINGS", label = "Settings",     sub = "Addon Configuration",   icon = "Interface\\Icons\\INV_Misc_Gear_01" },
}

local tabButtons = {}
for i, tab in ipairs(TAB_DEFINITIONS) do
    local btn = CreateFrame("Button", nil, mainFrame.sidebar)
    btn:SetSize(176, 46)
    btn:SetPoint("TOPLEFT", 7, -36 - ((i - 1) * 52))

    btn.bg = btn:CreateTexture(nil, "BACKGROUND")
    btn.bg:SetAllPoints()
    btn.bg:SetColorTexture(1, 1, 1, 1)
    btn.bg:SetVertexColor(0, 0, 0, 0)

    -- Left 3px Active Indicator Pill in Class Accent Color
    btn.activePill = btn:CreateTexture(nil, "OVERLAY", nil, 4)
    btn.activePill:SetSize(PP(3), 26)
    btn.activePill:SetPoint("LEFT", 0, 0)
    btn.activePill:SetColorTexture(unpack(T.accent))
    btn.activePill:Hide()

    -- Clean Cropped Icon Frame
    btn.iconFrame = CreateFrame("Frame", nil, btn)
    btn.iconFrame:SetSize(26, 26)
    btn.iconFrame:SetPoint("LEFT", 10, 0)
    ApplyMicroBorder(btn.iconFrame, T.borderSpecular)

    btn.icon = btn.iconFrame:CreateTexture(nil, "ARTWORK")
    btn.icon:SetAllPoints()
    btn.icon:SetTexture(tab.icon)
    btn.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    btn.title = CreateText(btn, "CARD_TITLE", tab.label, "LEFT")
    btn.title:SetPoint("TOPLEFT", btn.iconFrame, "TOPRIGHT", 10, -1)
    btn.title:SetPoint("RIGHT", btn, "RIGHT", -8, 0)
    if btn.title.SetWordWrap then btn.title:SetWordWrap(false) end

    btn.sub = CreateText(btn, "SMALL", tab.sub, "LEFT")
    btn.sub:SetPoint("BOTTOMLEFT", btn.iconFrame, "BOTTOMRIGHT", 10, 1)
    btn.sub:SetPoint("RIGHT", btn, "RIGHT", -8, 0)
    if btn.sub.SetWordWrap then btn.sub:SetWordWrap(false) end

    btn:SetScript("OnEnter", function(selfBtn)
        if GSI_UI.activeTab ~= tab.id then
            selfBtn.bg:SetVertexColor(1, 1, 1, 0.04)
            selfBtn.title:SetTextColor(unpack(T.textPrimary))
        end
    end)
    btn:SetScript("OnLeave", function(selfBtn)
        if GSI_UI.activeTab ~= tab.id then
            selfBtn.bg:SetVertexColor(0, 0, 0, 0)
            selfBtn.title:SetTextColor(unpack(T.textSecondary))
        end
    end)
    btn:SetScript("OnClick", function()
        GSI_UI:SelectTab(tab.id)
    end)

    tabButtons[tab.id] = btn
end

-- Quick Action Button at bottom of sidebar (Optimize Gear)
local scanBtn = CreateFrame("Button", nil, mainFrame.sidebar, BACKDROP_TEMPLATE)
scanBtn:SetSize(174, 32)
scanBtn:SetPoint("BOTTOM", mainFrame.sidebar, "BOTTOM", 0, 14)
scanBtn:SetText("OPTIMIZE GEAR")
SkinButton(scanBtn, "OPTIMIZE GEAR", "PRIMARY")
scanBtn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
scanBtn:SetScript("OnClick", function(_, mouseBtn)
    pcall(function()
        if PlaySound then
            PlaySound(SOUNDKIT and SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON or 856)
        end
    end)
    if mouseBtn == "RightButton" then
        if GSI_UI.EquipBestInBag then
            GSI_UI:EquipBestInBag()
        end
        return
    end
    GSI_UI.lastScanned = false
    if mainFrame.tabFrames and mainFrame.tabFrames["BIB"] then
        mainFrame.tabFrames["BIB"].scanned = false
    end
    GSI_UI:SelectTab("BIB")
    if GSI_UI.RunOptimization then
        GSI_UI:RunOptimization()
    end
end)
scanBtn:SetScript("OnEnter", function(selfBtn)
    GameTooltip:SetOwner(selfBtn, "ANCHOR_RIGHT")
    GameTooltip:AddLine("Optimize Gear (Scan Bags)", 1, 0.82, 0)
    GameTooltip:AddLine("|cff00ff00Left-Click:|r Scan bags & open Best Available", 1, 1, 1)
    GameTooltip:AddLine("|cff00ff00Right-Click:|r Immediately equip all upgrades", 1, 1, 1)
    GameTooltip:Show()
end)
scanBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
mainFrame.scanBtn = scanBtn

local function UpdateTabButtonsVisual(activeId)
    for id, btn in pairs(tabButtons) do
        local isActive = (id == activeId)
        if isActive then
            btn.bg:SetVertexColor(unpack(T.accentSurface))
            btn.activePill:Show()
            btn.title:SetTextColor(unpack(T.textPrimary))
            btn.sub:SetTextColor(unpack(T.accentBright))
            btn.icon:SetVertexColor(1, 1, 1, 1)
        else
            btn.bg:SetVertexColor(0, 0, 0, 0)
            btn.activePill:Hide()
            btn.title:SetTextColor(unpack(T.textSecondary))
            btn.sub:SetTextColor(unpack(T.textMuted))
            btn.icon:SetVertexColor(0.65, 0.65, 0.65, 1)
        end
    end
end

function GSI_UI:SelectTab(tabId)
    if not mainFrame:IsShown() then
        mainFrame:Show()
    end
    GSI_UI.activeTab = tabId
    UpdateTabButtonsVisual(tabId)
    GSI_UI:RefreshPanel()
end

-- ----------------------------------------------------------------------------
-- 5. CONTENT AREA & ROUTING
-- ----------------------------------------------------------------------------
mainFrame.content = CreateFrame("Frame", nil, mainFrame)
mainFrame.content:SetPoint("TOPLEFT", mainFrame.sidebar, "TOPRIGHT", 0, 0)
mainFrame.content:SetPoint("BOTTOMRIGHT", -1, 1)
mainFrame.content:SetFrameStrata("HIGH")
mainFrame.content:SetFrameLevel(105)

mainFrame:HookScript("OnShow", function()
    UpdateTabButtonsVisual(GSI_UI.activeTab or "OVERVIEW")
    pcall(function() GSI_UI:UpdateTitleScore() end)
    pcall(function() GSI_UI:UpdateSpecButton() end)
    pcall(function() GSI_UI:UpdateModeUI() end)
    pcall(function() GSI_UI:RefreshPanel() end)

    -- Automatic optimization check on open
    if GSI_UI.ScheduleOptimization then
        GSI_UI:ScheduleOptimization(0.05, true)
    elseif GSI_UI.RunOptimization then
        GSI_UI:RunOptimization()
    end
end)

function GSI_UI:RefreshPanel(forceUpdate)
    if not mainFrame:IsShown() then return end

    for id, frame in pairs(mainFrame.tabFrames) do
        frame:Hide()
    end

    local validTabs = { OVERVIEW = true, GEAR = true, BIB = true, WEIGHTS = true, MACROS = true, JUNK = true, SETTINGS = true, DEBUG = true }
    if not validTabs[GSI_UI.activeTab] then
        GSI_UI.activeTab = "OVERVIEW"
    end
    local active = GSI_UI.activeTab
    local frame = mainFrame.tabFrames[active]
    if not frame then
        frame = CreateFrame("Frame", nil, mainFrame.content)
        frame:SetAllPoints()
        mainFrame.tabFrames[active] = frame

        if active == "OVERVIEW" then self:DrawOverview(frame)
        elseif active == "GEAR" then self:DrawGear(frame)
        elseif active == "BIB" then self:DrawBiB(frame)
        elseif active == "WEIGHTS" then self:DrawWeights(frame)
        elseif active == "MACROS" then self:DrawMacros(frame)
        elseif active == "JUNK" then
            if self.DrawJunk then
                self:DrawJunk(frame)
            end
        elseif active == "SETTINGS" then self:DrawSettings(frame)
        elseif active == "CREDITS" then
            if self.DrawCredits then
                self:DrawCredits(frame)
            end
        elseif active == "DEBUG" then self:DrawDebug(frame) end
    end

    frame:Show()

    if active == "OVERVIEW" then pcall(function() self:UpdateOverview(frame) end)
    elseif active == "GEAR" then pcall(function() self:UpdateGear(frame) end)
    elseif active == "BIB" then pcall(function() self:UpdateBiBList(frame) end)
    elseif active == "WEIGHTS" then pcall(function() self:UpdateWeights(frame) end)
    elseif active == "MACROS" then pcall(function() self:UpdateMacros(frame) end)
    elseif active == "JUNK" then
        if self.UpdateJunkList then
            pcall(function() self:UpdateJunkList(frame) end)
        end
    elseif active == "CREDITS" then
        if self.UpdateCredits then
            pcall(function() self:UpdateCredits(frame) end)
        end
    end
end

function GSI_UI:Toggle()
    if mainFrame:IsShown() then
        mainFrame:Hide()
    else
        mainFrame:Show()
    end
end

-- ----------------------------------------------------------------------------
-- 6. DEBUG LOG EXPORT
-- ----------------------------------------------------------------------------
function GSI_UI:DrawDebug(parent)
    local title = CreateText(parent, "TITLE", "Debug & Optimization Log", "LEFT")
    title:SetPoint("TOPLEFT", 18, -18)

    local btn = CreateFrame("Button", nil, parent, BACKDROP_TEMPLATE)
    btn:SetSize(160, 26)
    btn:SetPoint("TOPLEFT", 18, -50)
    SkinButton(btn, "Export / Copy Log", "SECONDARY")
    btn:SetScript("OnClick", function()
        if GSI_Logger and GSI_Logger.ShowExportWindow then
            GSI_Logger:ShowExportWindow()
        end
    end)
end

function GSI_UI:OpenSettings()
    if InCombatLockdown and InCombatLockdown() then
        if not (GearSetImproverDB and GearSetImproverDB.disableChatOutput) then
            print("|cff00ff00[GearSetImprover]|r |cffff8800Interface settings cannot be opened during combat.|r")
        end
        return
    end

    local ok = false
    if Settings and Settings.OpenToCategory then
        local catID = self.blizzardCategory and self.blizzardCategory.GetID and self.blizzardCategory:GetID()
        if catID then
            ok = pcall(Settings.OpenToCategory, catID)
        end
        if not ok then
            ok = pcall(Settings.OpenToCategory, "GearSetImprover")
        end
    end

    if not ok and InterfaceOptionsFrame_OpenToCategory and self.blizzOptionsPanel then
        pcall(InterfaceOptionsFrame_OpenToCategory, self.blizzOptionsPanel)
        pcall(InterfaceOptionsFrame_OpenToCategory, self.blizzOptionsPanel)
    end
end

function GSI_UI:HandleSlashCommand(msg)
    local tokens = {}
    for word in (msg or ""):gmatch("%S+") do
        table.insert(tokens, word:lower())
    end

    if #tokens == 0 then
        self:Toggle()
        return
    end

    local cmd = tokens[1]
    table.remove(tokens, 1)

    if cmd == "help" or cmd == "?" then
        self:PrintSlashHelp()
        return
    end

    if cmd == "macro" or cmd == "macros" then
        self:SelectTab("MACROS")
        return
    end

    if cmd == "gear" or cmd == "best" then
        self:SelectTab("BIB")
        return
    end

    if cmd == "cleanup" or cmd == "aussortieren" or cmd == "junk" then
        self:SelectTab("JUNK")
        return
    end

    if cmd == "weights" or cmd == "stats" then
        self:SelectTab("WEIGHTS")
        return
    end

    if cmd == "tutorial" then
        self:OpenTutorial()
        return
    end

    if cmd == "changelog" or cmd == "changelogs" then
        self:OpenChangelog()
        return
    end

    if cmd == "credits" or cmd == "danksagung" then
        self:OpenCreditsModal()
        return
    end

    if cmd == "options" or cmd == "settings" or cmd == "config" then
        self:OpenSettings()
        return
    end

    if cmd == "log" or cmd == "debug" or cmd == "export" then
        if GSI_Logger and GSI_Logger.ShowExportWindow then
            GSI_Logger:ShowExportWindow()
        end
        return
    end

    if cmd == "toast" or cmd == "testtoast" then
        if GSI_UpgradeToast and GSI_UpgradeToast.TestToast then
            GSI_UpgradeToast:TestToast()
        end
        return
    end

    if cmd == "anchor" or cmd == "toastanchor" then
        if GSI_UpgradeToast and GSI_UpgradeToast.ToggleAnchor then
            GSI_UpgradeToast:ToggleAnchor()
        end
        return
    end

    if cmd == "equip" or cmd == "bib" or cmd == "optimize" then
        local targetSpec, targetMode = ParseSpecAndModeTokens(tokens)
        self:EquipBestInBag(targetSpec, targetMode)
        return
    end

    if cmd == "spec" and (tokens[1] == "auto" or tokens[1] == "a") then
        GSI_StatWeights:SetSpecAuto(true)
        local spec = GSI_StatWeights:GetActiveSpecIndex()
        local cd = GSI_ClassicData and GSI_ClassicData.Classes and GSI_ClassicData.Classes[GetPlayerClassKey()]
        local sd = cd and cd.specs and cd.specs[spec]
        print(string.format("|cffffcc00[GearSetImprover]|r Specialization: |cff00ff00Auto|r (now |cff00ff00%s|r, follows your talents).", (sd and sd.name) or ("Spec " .. spec)))
        return
    end

    if cmd == "set" then
        if GSI_UI.EquipSpecSet then
            GSI_UI:EquipSpecSet(GSI_StatWeights:GetActiveSpecIndex(), false, true)
        end
        return
    end

    if cmd == "dump" then
        self:DebugDump(tokens[1])
        return
    end

    if cmd == "spec" then
        local targetSpec = ParseSpecAndModeTokens(tokens)
        if targetSpec then
            GSI_StatWeights:ChooseSpec(targetSpec)
            if GSI_ItemScore and GSI_ItemScore.ResetCache then GSI_ItemScore:ResetCache() end
            if GSI_OptimizationEngine and GSI_OptimizationEngine.ResetCache then GSI_OptimizationEngine:ResetCache() end
            pcall(function() GSI_UI:UpdateSpecButton() end)
            pcall(function() GSI_UI:UpdateModeUI() end)
            pcall(function() GSI_UI:UpdateTitleScore() end)
            if mainFrame and mainFrame:IsShown() then GSI_UI:RefreshPanel(true) end
            local class = GetPlayerClassKey()
            local classData = GSI_ClassicData and GSI_ClassicData.Classes and GSI_ClassicData.Classes[class]
            local specData = classData and classData.specs and classData.specs[targetSpec]
            local specName = (specData and specData.name) or ("Spec " .. targetSpec)
            print(string.format("|cffffcc00[GearSetImprover]|r Specialization set to |cff00ff00%s|r. Type |cffffcc00/gsi equip|r to equip Best Available Gear.", specName))
        else
            print("|cffffcc00[GearSetImprover]|r Specify a valid spec: 1-3 (or 1-4 for Druids) or spec name, or |cffffcc00auto|r. Example: |cffffcc00/gsi spec bear|r, |cffffcc00/gsi spec auto|r")
        end
        return
    end

    if cmd == "mode" then
        local _, targetMode = ParseSpecAndModeTokens(tokens)
        if targetMode then
            if targetMode.type == "tank" then
                GearSetImproverDB.tankMode = targetMode.value
            else
                GearSetImproverDB.weightMode = targetMode.value
            end
            if GSI_ItemScore and GSI_ItemScore.ResetCache then GSI_ItemScore:ResetCache() end
            if GSI_OptimizationEngine and GSI_OptimizationEngine.ResetCache then GSI_OptimizationEngine:ResetCache() end
            pcall(function() GSI_UI:UpdateModeUI() end)
            pcall(function() GSI_UI:UpdateTitleScore() end)
            if mainFrame and mainFrame:IsShown() then GSI_UI:RefreshPanel(true) end
            print(string.format("|cffffcc00[GearSetImprover]|r Mode set to |cff00ff00%s|r. Type |cffffcc00/gsi equip|r to equip Best Available Gear.", targetMode.value))
        else
            print("|cffffcc00[GearSetImprover]|r Specify a valid mode: |cff00ff00survival|r, |cff00ff00threat|r, |cff00ff00st|r, or |cff00ff00aoe|r.")
        end
        return
    end

    local targetSpec, targetMode = ParseSpecAndModeTokens({ cmd, unpack(tokens) })
    if targetSpec or targetMode then
        self:EquipBestInBag(targetSpec, targetMode)
        return
    end

    self:Toggle()
end

-- ----------------------------------------------------------------------------
-- /gsi dump: diagnostics for localized clients. Writes what the client
-- reports for each equipped and bag item (GetItemStats, tooltip lines, what
-- the parser made of them), the localized stat format strings, the talent /
-- specialization APIs and the Equipment Manager sets into
-- GearSetImproverDB._dump, which reaches SavedVariables on /reload or logout.
-- "/gsi dump clear" removes it again.
-- ----------------------------------------------------------------------------
function GSI_UI:DebugDump(arg)
    if not GearSetImproverDB then return end
    if arg == "clear" then
        GearSetImproverDB._dump = nil
        print("|cffffcc00[GearSetImprover]|r Diagnostics dump removed.")
        return
    end

    local d = { time = date and date("%Y-%m-%d %H:%M:%S") or "?" }
    d.locale = GetLocale and GetLocale() or "?"
    if GetBuildInfo then d.build = { GetBuildInfo() } end
    d.addonVersion = (C_AddOns and C_AddOns.GetAddOnMetadata and C_AddOns.GetAddOnMetadata("GearSetImprover", "Version")) or "?"

    -- Localized strings the tooltip lines are built from
    d.globals = {}
    local wanted = {
        ARMOR_TEMPLATE = true, DPS_TEMPLATE = true, DAMAGE_TEMPLATE = true, SHIELD_BLOCK_TEMPLATE = true,
        ITEM_SET_BONUS = true, ITEM_SET_BONUS_GRAY = true, ITEM_RESIST_SINGLE = true, ITEM_RESIST_ALL = true,
        ITEM_SOCKET_BONUS = true, ITEM_MIN_LEVEL = true, ITEM_REQ_SKILL = true, DURABILITY_TEMPLATE = true,
    }
    pcall(function()
        for k, v in pairs(_G) do
            if type(k) == "string" and type(v) == "string"
               and (wanted[k] or k:find("^ITEM_MOD_") or k:find("^ITEM_SPELL_TRIGGER")) then
                d.globals[k] = v
            end
        end
    end)

    local function CopyStats(link)
        local fn = (C_Item and C_Item.GetItemStats) or _G.GetItemStats
        local out = {}
        if fn then
            local ok, t = pcall(fn, link)
            if ok and type(t) == "table" then
                for k, v in pairs(t) do out[tostring(k)] = v end
            end
        end
        return out
    end

    local function TooltipLines(link)
        local lines = {}
        if C_TooltipInfo and C_TooltipInfo.GetHyperlink then
            local ok, data = pcall(C_TooltipInfo.GetHyperlink, link)
            if ok and type(data) == "table" and type(data.lines) == "table" then
                for _, l in ipairs(data.lines) do
                    local left = l.leftText
                    if type(left) == "string" then
                        if l.rightText and l.rightText ~= "" then left = left .. "  ||  " .. l.rightText end
                        lines[#lines + 1] = left
                    end
                end
            end
        end
        return lines
    end

    local function Parsed(link)
        local out = {}
        if GSI_ItemScore and GSI_ItemScore.GetParsedStats then
            local ok, s = pcall(GSI_ItemScore.GetParsedStats, GSI_ItemScore, link)
            if ok and type(s) == "table" then
                for k, v in pairs(s) do
                    if type(v) == "number" and v ~= 0 then out[k] = v
                    elseif type(v) == "string" then out[k] = v end
                end
            end
        end
        return out
    end

    local function AddItem(list, where, link)
        list[#list + 1] = { where = where, link = link, stats = CopyStats(link), lines = TooltipLines(link), parsed = Parsed(link) }
    end

    d.items = {}
    for slot = 1, 19 do
        local link = GetInventoryItemLink("player", slot)
        if link then AddItem(d.items, "slot" .. slot, link) end
    end
    local getNumSlots = (C_Container and C_Container.GetContainerNumSlots) or _G.GetContainerNumSlots
    local getLink = (C_Container and C_Container.GetContainerItemLink) or _G.GetContainerItemLink
    local isEquippable = (C_Item and C_Item.IsEquippableItem) or _G.IsEquippableItem
    local bagCount = 0
    if getNumSlots and getLink then
        for bag = 0, (NUM_BAG_SLOTS or 4) do
            local ok, n = pcall(getNumSlots, bag)
            for s = 1, ((ok and type(n) == "number") and n or 0) do
                local link = getLink(bag, s)
                if link and bagCount < 40 and (not isEquippable or isEquippable(link)) then
                    bagCount = bagCount + 1
                    AddItem(d.items, "bag" .. bag .. ":" .. s, link)
                end
            end
        end
    end

    -- Talent / specialization APIs
    local sp = { apis = {} }
    for _, name in ipairs({ "GetNumTalentTabs", "GetTalentTabInfo", "GetNumTalents", "GetTalentInfo",
                            "GetSpecialization", "GetSpecializationInfo", "GetNumSpecializations",
                            "GetActiveTalentGroup", "GetShapeshiftFormID" }) do
        sp.apis[name] = type(_G[name])
    end
    sp.apis.C_SpecializationInfo = type(C_SpecializationInfo)
    sp.apis.C_ClassTalents = type(C_ClassTalents)
    sp.apis.C_Traits = type(C_Traits)
    sp.class = select(2, UnitClass("player"))
    sp.level = UnitLevel("player")
    if type(GetNumTalentTabs) == "function" then
        local ok, n = pcall(GetNumTalentTabs)
        sp.numTabs = ok and n or "error"
        sp.tabs = {}
        for tab = 1, ((ok and type(n) == "number") and n or 0) do
            local entry = { tabInfo = {} }
            if type(GetTalentTabInfo) == "function" then
                local r = { pcall(GetTalentTabInfo, tab) }
                for i = 2, math.min(#r, 9) do entry.tabInfo[i - 1] = tostring(r[i]) end
            end
            local okN, cnt = false, nil
            if type(GetNumTalents) == "function" then okN, cnt = pcall(GetNumTalents, tab) end
            entry.numTalents = okN and cnt or "error"
            entry.ranks = {}
            for i = 1, ((okN and type(cnt) == "number") and cnt or 0) do
                local t = { pcall(GetTalentInfo, tab, i) }
                if t[1] then
                    entry.ranks[#entry.ranks + 1] = string.format("%s r=%s/%s (t%s c%s)",
                        tostring(t[2]), tostring(t[6]), tostring(t[7]), tostring(t[4]), tostring(t[5]))
                end
            end
            sp.tabs[tab] = entry
        end
    end
    if type(GetSpecialization) == "function" then
        local ok, s = pcall(GetSpecialization)
        sp.specialization = ok and tostring(s) or "error"
        if ok and s and type(GetSpecializationInfo) == "function" then
            local r = { pcall(GetSpecializationInfo, s) }
            sp.specializationInfo = {}
            for i = 2, math.min(#r, 8) do sp.specializationInfo[i - 1] = tostring(r[i]) end
        end
    end
    if type(GetShapeshiftFormID) == "function" then
        local ok, f = pcall(GetShapeshiftFormID)
        sp.shapeshiftFormID = ok and tostring(f) or "error"
    end
    if GSI_StatWeights then
        sp.gsiActiveSpec = GSI_StatWeights:GetActiveSpecIndex()
        if GSI_StatWeights.DetectCurrentSpec then
            local s, fromTalents = GSI_StatWeights:DetectCurrentSpec()
            sp.gsiDetectedSpec = s
            sp.gsiDetectedFromTalents = fromTalents and true or false
        end
        sp.gsiAuto = GSI_StatWeights.IsSpecAuto and GSI_StatWeights:IsSpecAuto() and true or false
    end
    d.spec = sp

    -- Equipment Manager sets
    d.sets = {}
    if GSI_UI.GetEquipmentSetList then
        for _, s in ipairs(GSI_UI:GetEquipmentSetList()) do
            d.sets[#d.sets + 1] = { id = s.id, name = s.name, icon = s.icon, equipped = s.equipped }
        end
    end

    GearSetImproverDB._dump = d
    print(string.format("|cffffcc00[GearSetImprover]|r Diagnostics saved (%d items, locale %s). Type |cffffcc00/reload|r to write them to disk.", #d.items, d.locale))
end

function GSI_UI:Initialize()
    pcall(function() self:RegisterBlizzardOptions() end)

    SLASH_GEARSETIMPROVER1 = "/gsi"
    SLASH_GEARSETIMPROVER2 = "/gearsetimprover"
    SlashCmdList["GEARSETIMPROVER"] = function(msg)
        GSI_UI:HandleSlashCommand(msg)
    end

    SLASH_GSI_EQUIP1 = "/gsiequip"
    SLASH_GSI_EQUIP2 = "/gsibib"
    SlashCmdList["GSI_EQUIP"] = function(msg)
        local tokens = {}
        for word in (msg or ""):gmatch("%S+") do
            table.insert(tokens, word:lower())
        end
        local targetSpec, targetMode = ParseSpecAndModeTokens(tokens)
        GSI_UI:EquipBestInBag(targetSpec, targetMode)
    end

    SLASH_GSI_MACROS1 = "/gsimacro"
    SLASH_GSI_MACROS2 = "/gsimacros"
    SlashCmdList["GSI_MACROS"] = function()
        GSI_UI:SelectTab("MACROS")
    end
end
