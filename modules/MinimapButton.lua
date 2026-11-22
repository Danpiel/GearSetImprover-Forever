-- ============================================================
-- GearSetImprover – MinimapButton.lua
-- Draggable Minimap icon with quick actions and tooltip info
-- ============================================================

GSI_MinimapButton = {}
local GSI_MinimapButton = GSI_MinimapButton

local button = CreateFrame("Button", "GSI_MinimapButtonFrame", Minimap)
button:SetSize(32, 32)
button:SetFrameStrata("MEDIUM")
button:SetFrameLevel(8)
button:EnableMouse(true)
button:SetMovable(true)
button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
button:RegisterForDrag("LeftButton", "RightButton")

-- Background circle texture
local bg = button:CreateTexture(nil, "BACKGROUND")
bg:SetSize(20, 20)
bg:SetPoint("CENTER", 0, 0)
bg:SetTexture("Interface\\Minimap\\UI-Minimap-Background")

-- Addon Icon
local icon = button:CreateTexture(nil, "ARTWORK")
icon:SetSize(20, 20)
icon:SetPoint("CENTER", 0, 0)
icon:SetTexture("Interface\\AddOns\\GearSetImprover\\Textures\\icon.png")
icon:SetTexCoord(0, 1, 0, 1)
button.icon = icon

-- Circular Tracking Border Overlay
local border = button:CreateTexture(nil, "OVERLAY")
border:SetSize(52, 52)
border:SetPoint("TOPLEFT", 0, 0)
border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")

-- Highlight
local highlight = button:CreateTexture(nil, "HIGHLIGHT")
highlight:SetSize(24, 24)
highlight:SetPoint("CENTER", 0, 0)
highlight:SetTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
highlight:SetBlendMode("ADD")

function GSI_MinimapButton:UpdatePosition()
    if not Minimap then return end
    local miniW = Minimap:GetWidth()
    if not miniW or miniW <= 0 then return end
    local angle = (GearSetImproverDB and GearSetImproverDB.minimapPos) or 45
    local rad = math.rad(angle)
    local radius = (miniW / 2) + 8
    local x = math.cos(rad) * radius
    local y = math.sin(rad) * radius
    button:ClearAllPoints()
    button:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

function GSI_MinimapButton:Toggle(show)
    if show == nil then
        show = not button:IsShown()
    end
    if GearSetImproverDB then
        GearSetImproverDB.showMinimap = show
    end
    if show then
        button:Show()
        self:UpdatePosition()
    else
        button:Hide()
    end
end

-- Dragging around circular minimap (throttled OnUpdate)
local isDragging = false
local dragElapsed = 0
local lastCursorX, lastCursorY = nil, nil

button:SetScript("OnDragStart", function(self)
    isDragging = true
    dragElapsed = 0
    lastCursorX, lastCursorY = nil, nil
    self:LockHighlight()
    self:SetScript("OnUpdate", function(_, elapsed)
        dragElapsed = dragElapsed + (elapsed or 0)
        if dragElapsed < 0.02 then return end
        dragElapsed = 0

        local cursorX, cursorY = GetCursorPosition()
        if cursorX == lastCursorX and cursorY == lastCursorY then return end
        lastCursorX, lastCursorY = cursorX, cursorY

        local scale = UIParent:GetEffectiveScale()
        if not scale or scale <= 0 then scale = 1 end
        cursorX = cursorX / scale
        cursorY = cursorY / scale

        local miniX, miniY = Minimap:GetCenter()
        if not miniX or not miniY then return end

        local dX = cursorX - miniX
        local dY = cursorY - miniY
        local angle = math.deg(math.atan2(dY, dX))
        if angle < 0 then angle = angle + 360 end

        if GearSetImproverDB then
            GearSetImproverDB.minimapPos = angle
        end
        GSI_MinimapButton:UpdatePosition()
    end)
end)

button:SetScript("OnDragStop", function(self)
    isDragging = false
    dragElapsed = 0
    lastCursorX, lastCursorY = nil, nil
    self:SetScript("OnUpdate", nil)
    self:UnlockHighlight()
end)

button:SetScript("OnClick", function(self, btn)
    if btn == "LeftButton" then
        if IsShiftKeyDown() then
            if GSI_UI and GSI_UI.EquipBestInBag then
                GSI_UI:EquipBestInBag()
            end
        else
            if GSI_UI and GSI_UI.mainFrame then
                if GSI_UI.mainFrame:IsShown() then
                    GSI_UI.mainFrame:Hide()
                else
                    GSI_UI.mainFrame:Show()
                end
            end
        end
    elseif btn == "RightButton" then
        if GSI_UI and GSI_UI.EquipBestInBag then
            GSI_UI:EquipBestInBag()
        end
    end
end)

button:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:ClearLines()
    GameTooltip:AddLine("|cffffcc00GearSetImprover Forever|r", 1, 1, 1)

    local class = (GSI_ClassicData and GSI_ClassicData.GetPlayerClass and GSI_ClassicData:GetPlayerClass())
        or select(2, UnitClass("player")) or "WARRIOR"
    local specIndex = (GSI_StatWeights and GSI_StatWeights.GetActiveSpecIndex and GSI_StatWeights:GetActiveSpecIndex()) or 1
    local classData = GSI_ClassicData and GSI_ClassicData.Classes and GSI_ClassicData.Classes[class]
    local specData = classData and classData.specs and classData.specs[specIndex]
    local specName = specData and (specData.name or specData.nameDE) or ("Spec " .. tostring(specIndex))

    local role = GSI_StatWeights and GSI_StatWeights.GetRole and GSI_StatWeights:GetRole(specIndex)
    local activeModeArg, modeLabel
    if role == "tank" then
        local tMode = (GearSetImproverDB and GearSetImproverDB.tankMode)
            or (GSI_Config and GSI_Config.TankMode) or "Survival"
        if tMode == "Threat" then tMode = "DMG" end
        activeModeArg = tMode
        modeLabel = (tMode == "Survival") and "Survival" or "Threat / DPS"
    else
        local wMode = (GearSetImproverDB and GearSetImproverDB.weightMode) or "ST"
        activeModeArg = wMode
        modeLabel = (wMode == "ST") and "Single Target" or "AoE / Trash"
    end

    local score = nil
    if GSI_OptimizationEngine and GSI_OptimizationEngine.EvaluateSetup then
        pcall(function()
            local setup = GSI_OptimizationEngine:GetCurrentSetup()
            score = GSI_OptimizationEngine:EvaluateSetup(setup, specIndex, activeModeArg)
        end)
    end

    local specKey = class .. "-" .. tostring(specIndex)
    local customProfile = (GSI_StatWeights and GSI_StatWeights.GetActiveProfileName and GSI_StatWeights:GetActiveProfileName(specKey, activeModeArg))
        or (GearSetImproverDB and GearSetImproverDB.activeProfile and GearSetImproverDB.activeProfile[specKey])
    if customProfile and customProfile ~= "" then
        GameTooltip:AddLine(string.format("Profile: |cff00ff00%s|r (%s)", specName, customProfile), 0.9, 0.9, 0.9)
    else
        GameTooltip:AddLine(string.format("Profile: |cff00ff00%s|r (%s)", specName, modeLabel), 0.9, 0.9, 0.9)
    end
    if score and type(score) == "number" then
        GameTooltip:AddLine(string.format("Current GSI Score: |cff00ff00%.1f|r (%s)", score, modeLabel), 1, 1, 1)
    end

    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("|cff00ff00Left-Click:|r Open / Close Menu", 0.8, 0.8, 0.8)
    GameTooltip:AddLine("|cff00ff00Right-Click:|r Equip Best Available Gear", 0.8, 0.8, 0.8)
    GameTooltip:AddLine("|cff00ff00Shift + Left-Click:|r Equip Best Available Gear", 0.8, 0.8, 0.8)
    GameTooltip:AddLine("|cff00ff00Drag:|r Move Minimap Icon", 0.8, 0.8, 0.8)
    GameTooltip:Show()
end)

button:SetScript("OnLeave", function()
    GameTooltip:Hide()
end)

-- Addon Compartment integration (WoW 10.0+ / modern client)
function _G.GearSetImprover_OnAddonCompartmentClick(addonName, buttonName)
    if buttonName == "RightButton" then
        if GSI_UI and GSI_UI.EquipBestInBag then
            GSI_UI:EquipBestInBag()
        end
    else
        if GSI_UI and GSI_UI.mainFrame then
            if GSI_UI.mainFrame:IsShown() then
                GSI_UI.mainFrame:Hide()
            else
                GSI_UI.mainFrame:Show()
            end
        end
    end
end

function GSI_MinimapButton:Initialize()
    local show = true
    if GearSetImproverDB and GearSetImproverDB.showMinimap ~= nil then
        show = GearSetImproverDB.showMinimap
    else
        show = true
        if GearSetImproverDB then GearSetImproverDB.showMinimap = true end
    end
    self:Toggle(show)
    self:UpdatePosition()
end
