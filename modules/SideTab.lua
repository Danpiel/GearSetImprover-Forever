-- ============================================================================
-- GearSetImprover (GSI) -- SideTab.lua (WoW Forever)
-- Attaches a native Side-Tab to CharacterFrame (ModeTabs) to toggle the
-- main GearSetImprover window.
-- Uses WoW Forever's native "LargeSideTabButtonTemplate" (octagonal bronze
-- frame + mask) and automatically chains below existing ModeTabs
-- (including TalentsForeverBookCharacterTab).
-- Also supports ChonkyCharacterSheet (CCS) tab skinning.
-- ============================================================================

GSI_SideTab = GSI_SideTab or {}

local GSI_ICON_TEXTURE = "Interface\\AddOns\\GearSetImprover\\Textures\\icon.png"
local GSI_FALLBACK_ICON = "Interface\\Icons\\INV_Misc_Bag_CoreFelclothBag"
local GSI_TAB_NAME = "CharacterFrameModeTabGSI"
local CCS_MASK_TEX = "Interface\\AddOns\\ChonkyCharacterSheet\\Media\\Textures\\Frame\\buttonmask1.blp"
local CCS_HIGHLIGHT_TEX = "Interface\\AddOns\\ChonkyCharacterSheet\\Media\\Textures\\Frame\\buttonhighlight1.png"

-- Returns the ModeTabs container of CharacterFrame in WoW Forever
local function GetModeTabsContainer()
    if CharacterFrame and CharacterFrame.ModeTabs then
        return CharacterFrame.ModeTabs
    end
    return _G["CharacterFrameModeTabs"]
end

-- Finds the lowest visible ModeTab (including addon tabs like TalentsForeverBookCharacterTab)
-- and resolves its vertical spacing
local function GetLastModeTabAndSpacing()
    local modeTabs = GetModeTabsContainer()
    local lastTab = nil
    local prevTab = nil

    -- 1. Scan standard ModeTabs from CharacterFrame.ModeTabs.Tabs
    if modeTabs and type(modeTabs.Tabs) == "table" then
        for _, t in ipairs(modeTabs.Tabs) do
            if t and t ~= GSI_SideTab.tabButton and t.IsShown and t:IsShown() then
                prevTab = lastTab
                lastTab = t
            end
        end
    end

    -- 2. Fallback via global names CharacterFrameModeTab1..12
    if not lastTab then
        for i = 1, 12 do
            local t = _G["CharacterFrameModeTab" .. i]
            if t and t ~= GSI_SideTab.tabButton and t.IsShown and t:IsShown() then
                prevTab = lastTab
                lastTab = t
            end
        end
    end

    -- 3. Follow any addon tabs (e.g. TalentsForeverBookCharacterTab) anchored below lastTab
    if lastTab then
        local candidates = {}
        local seen = {}
        local function addCandidate(f)
            if f and f ~= GSI_SideTab.tabButton and not seen[f] then
                seen[f] = true
                table.insert(candidates, f)
            end
        end

        addCandidate(_G["TalentsForeverBookCharacterTab"])
        if modeTabs and modeTabs.GetChildren then
            local children = { modeTabs:GetChildren() }
            for _, child in ipairs(children) do
                addCandidate(child)
            end
        end

        local visitedChain = { [lastTab] = true }
        local advanced = true
        local safety = 0
        while advanced and safety < 20 do
            advanced = false
            safety = safety + 1
            for _, cand in ipairs(candidates) do
                if not visitedChain[cand] and cand.IsShown and cand:IsShown() and cand.GetPoint then
                    local _, relTo = cand:GetPoint(1)
                    if relTo == lastTab then
                        prevTab = lastTab
                        lastTab = cand
                        visitedChain[cand] = true
                        advanced = true
                        break
                    end
                end
            end
        end
    end

    -- 4. Determine spacing (WoW Forever default for ModeTabs: 0, -2)
    local point, relPoint = "TOPLEFT", "BOTTOMLEFT"
    local offsetX, offsetY = 0, -2
    if lastTab and prevTab and lastTab.GetPoint then
        local p, _, rp, px, py = lastTab:GetPoint(1)
        if p == "TOPLEFT" and rp == "BOTTOMLEFT" and type(py) == "number" and py <= 0 then
            point, relPoint = p, rp
            offsetX, offsetY = px or 0, py
        end
    end

    return lastTab, point, relPoint, offsetX, offsetY
end

-- Checks if ChonkyCharacterSheet (CCS) tab skinning is active
local function IsCCSSkinActive(sourceTab)
    if sourceTab and sourceTab.CCS_BG and sourceTab.CCS_BG.IsShown and sourceTab.CCS_BG:IsShown() then
        return true
    end
    if CCS and type(CCS.GetCharButtonTextureByName) == "function" then
        local hasSkinOpt = false
        if type(option) == "function" then
            hasSkinOpt = option("skinchartabs")
        elseif CCS.option and type(CCS.option) == "function" then
            hasSkinOpt = CCS.option("skinchartabs")
        end
        if hasSkinOpt then return true end
    end
    return false
end

-- Updates active / hover / normal visual state
function GSI_SideTab:SyncState()
    local tab = self.tabButton
    if not tab then return end

    local mainFrame = GSI_UI and GSI_UI.mainFrame
    local isOpen = mainFrame and mainFrame.IsShown and mainFrame:IsShown() or false

    -- 1. ChonkyCharacterSheet (CCS) Theme-Styling Status
    if tab.isCCSSkinned and tab.CCS_BG and tab.CCS_BG:IsShown() then
        if tab.SetChecked then
            tab:SetChecked(isOpen)
        end
        if isOpen then
            tab.CCS_BG:SetVertexColor(1, 1, 1, 1)
            if tab.CCS_Highlight then
                tab.CCS_Highlight:Show()
            end
        else
            if tab.CCS_Highlight then
                tab.CCS_Highlight:Hide()
            end
            if tab.isHovered then
                local c = (CCS and CCS.StyleColor and CCS.StyleColor.normal) or { 0.49, 0.196, 0.659, 1 }
                tab.CCS_BG:SetVertexColor(c[1], c[2], c[3], c[4] or 1)
            else
                local c = (CCS and CCS.StyleColor and CCS.StyleColor.border) or { 0.3, 0.1, 0.4, 1 }
                tab.CCS_BG:SetVertexColor(c[1], c[2], c[3], c[4] or 1)
            end
        end
        return
    end

    -- 2. WoW Forever Native LargeSideTabButtonTemplate
    if tab.isLargeSideTab then
        if tab.SetChecked then
            tab:SetChecked(isOpen)
        end
        if tab.SelectedTexture and tab.SelectedTexture.SetShown then
            tab.SelectedTexture:SetShown(isOpen)
        end
        -- SetChecked() in LargeSideTabButtonMixin may overwrite the icon atlas,
        -- so restore our addon icon right afterwards.
        if tab.Icon then
            local okTex, res = pcall(tab.Icon.SetTexture, tab.Icon, GSI_ICON_TEXTURE)
            if not okTex or res == false then
                tab.Icon:SetTexture(GSI_FALLBACK_ICON)
            end
            if tab.Icon.SetTexCoord then
                tab.Icon:SetTexCoord(0.14, 0.86, 0.14, 0.86)
            end
            tab.Icon:Show()
        end
        return
    end

    -- 3. Fallback CheckButton
    if tab.SetChecked then
        tab:SetChecked(isOpen)
    end
end

-- Applies appropriate styling (CCS Skin vs. WoW Forever LargeSideTabButtonTemplate vs. Fallback)
function GSI_SideTab:ApplyStyle()
    local tab = self.tabButton
    if not tab then return end

    local sourceTab = GetLastModeTabAndSpacing()

    if IsCCSSkinActive(sourceTab) then
        -- ================================================================
        -- MODE A: ChonkyCharacterSheet (CCS) Skinning
        -- ================================================================
        tab.isCCSSkinned = true
        tab:SetSize(48, 48)

        -- Hide native textures
        if tab.Background then tab.Background:Hide() end
        if tab.Icon then tab.Icon:Hide() end
        if tab.SelectedTexture then tab.SelectedTexture:Hide() end
        if tab.TabGlow then tab.TabGlow:Hide() end
        if tab.HighlightTexture then tab.HighlightTexture:Hide() end
        if tab.GetHighlightTexture and tab:GetHighlightTexture() then
            tab:GetHighlightTexture():SetAlpha(0)
        end
        if tab.GetCheckedTexture and tab:GetCheckedTexture() then
            tab:GetCheckedTexture():SetAlpha(0)
        end

        -- 1. CCS Background Texture (Frame / Bevel)
        if not tab.CCS_BG then
            tab.CCS_BG = tab:CreateTexture(nil, "BACKGROUND", nil, -8)
        end

        local bgTex, mapLeft, mapRight, mapTop, mapBottom
        if sourceTab and sourceTab.CCS_BG and sourceTab.CCS_BG.GetTexture then
            bgTex = sourceTab.CCS_BG:GetTexture()
            if sourceTab.CCS_BG.GetTexCoord then
                local ulx, uly, _, _, urx, _, _, lry = sourceTab.CCS_BG:GetTexCoord()
                if urx and lry then
                    mapLeft, mapRight, mapTop, mapBottom = ulx, urx, uly, lry
                end
            end
        end

        if not bgTex and CCS and CCS.GetCharButtonTextureByName then
            local optName = (type(option) == "function" and option("tabtex")) or "Steel Beam"
            local bgInfo = CCS:GetCharButtonTextureByName(optName) or (CCS.charbutton and CCS.charbutton[6])
            if bgInfo then
                bgTex = bgInfo.texture
                if bgInfo.map then
                    mapLeft, mapRight, mapTop, mapBottom = bgInfo.map[3], bgInfo.map[4], bgInfo.map[5], bgInfo.map[6]
                end
            end
        end

        if not bgTex then
            bgTex = "Interface\\AddOns\\ChonkyCharacterSheet\\Media\\Textures\\Frame\\charbuttons1.png"
            mapLeft, mapRight, mapTop, mapBottom = 0.347043701799486, 0.652956298200514, 0.494208494208494, 0.942084942084942
        end

        tab.CCS_BG:SetTexture(bgTex)
        if mapLeft and mapRight and mapTop and mapBottom then
            tab.CCS_BG:SetTexCoord(mapLeft, mapRight, mapTop, mapBottom)
        end
        tab.CCS_BG:ClearAllPoints()
        tab.CCS_BG:SetAllPoints(tab)
        tab.CCS_BG:Show()

        -- 2. CCS Icon & Mask (42x42 centered with rounded mask)
        if not tab.CCS_Icon then
            tab.CCS_Icon = tab:CreateTexture(nil, "ARTWORK")
        end
        tab.CCS_Icon:ClearAllPoints()
        tab.CCS_Icon:SetPoint("CENTER", tab, "CENTER")
        tab.CCS_Icon:SetSize(42, 42)
        tab.CCS_Icon:SetTexture(GSI_ICON_TEXTURE)
        tab.CCS_Icon:SetTexCoord(0.14, 0.86, 0.14, 0.86)

        if tab.CreateMaskTexture and not tab.CCS_mask then
            tab.CCS_mask = tab:CreateMaskTexture()
            tab.CCS_mask:SetTexture(CCS_MASK_TEX)
            tab.CCS_mask:SetAllPoints(tab)
            tab.CCS_Icon:AddMaskTexture(tab.CCS_mask)
        end
        tab.CCS_Icon:Show()
        if tab.CCS_mask then
            tab.CCS_mask:Show()
        end

        -- 3. CCS Highlight Overlay (38x38 centered with yellow glow)
        if not tab.CCS_Highlight then
            tab.CCS_Highlight = tab:CreateTexture(nil, "OVERLAY", nil, 7)
            tab.CCS_Highlight:SetTexture(CCS_HIGHLIGHT_TEX)
            tab.CCS_Highlight:SetPoint("CENTER", tab, "CENTER")
            tab.CCS_Highlight:SetSize(38, 38)
            tab.CCS_Highlight:SetVertexColor(1, 1, 0, 1)
        end

    elseif tab.isLargeSideTab then
        -- ================================================================
        -- MODE B1: WoW Forever Native "LargeSideTabButtonTemplate"
        -- ================================================================
        tab.isCCSSkinned = false

        -- Hide CCS textures if previously active
        if tab.CCS_BG then tab.CCS_BG:Hide() end
        if tab.CCS_Icon then tab.CCS_Icon:Hide() end
        if tab.CCS_mask then tab.CCS_mask:Hide() end
        if tab.CCS_Highlight then tab.CCS_Highlight:Hide() end

        if tab.Background then
            tab.Background:Show()
        end
        if tab.Mask then
            tab.Mask:Show()
        end

        -- Fill the octagonal interior (50x50) with our addon icon (icon.png)
        if tab.Icon then
            local okTex, res = pcall(tab.Icon.SetTexture, tab.Icon, GSI_ICON_TEXTURE)
            if not okTex or res == false then
                tab.Icon:SetTexture(GSI_FALLBACK_ICON)
            end
            if tab.SetFillToInterior then
                tab:SetFillToInterior(true, 50)
            else
                tab.fillToInterior = true
                tab.Icon:SetSize(50, 50)
            end
            if tab.Icon.SetTexCoord then
                tab.Icon:SetTexCoord(0.14, 0.86, 0.14, 0.86)
            end
            tab.Icon:Show()
        end

    else
        -- ================================================================
        -- MODE B2: Fallback when LargeSideTabButtonTemplate is unavailable
        -- ================================================================
        tab.isCCSSkinned = false

        if tab.CCS_BG then tab.CCS_BG:Hide() end
        if tab.CCS_Icon then tab.CCS_Icon:Hide() end
        if tab.CCS_mask then tab.CCS_mask:Hide() end
        if tab.CCS_Highlight then tab.CCS_Highlight:Hide() end

        local width, height = 43, 55
        if sourceTab and sourceTab.GetSize then
            local sw, sh = sourceTab:GetSize()
            if sw and sw > 10 and sh and sh > 10 then
                width, height = sw, sh
            end
        end
        tab:SetSize(width, height)

        if not tab.Background then
            tab.Background = tab:CreateTexture(nil, "BACKGROUND")
        end
        tab.Background:ClearAllPoints()
        tab.Background:SetAllPoints(tab)
        tab.Background:Show()

        if not tab.Icon then
            tab.Icon = tab:CreateTexture(nil, "ARTWORK")
        end
        tab.Icon:ClearAllPoints()
        tab.Icon:SetSize(width - 8, width - 8)
        tab.Icon:SetPoint("CENTER", tab, "CENTER")
        tab.Icon:SetTexture(GSI_ICON_TEXTURE)
        tab.Icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        tab.Icon:Show()
    end

    self:SyncState()
end

-- Coalesces multiple re-anchor / re-style triggers within the same frame into one pass
function GSI_SideTab:ScheduleRefresh(withStyle)
    if withStyle then
        self._pendingStyleRefresh = true
    end
    if not (C_Timer and C_Timer.After) then
        self:HookExternalTabs()
        if self._pendingStyleRefresh then
            self._pendingStyleRefresh = false
            self:ApplyStyle()
        end
        self:UpdateTabAnchor()
        return
    end
    if self._refreshScheduled then return end
    self._refreshScheduled = true
    C_Timer.After(0, function()
        self._refreshScheduled = false
        local doStyle = self._pendingStyleRefresh
        self._pendingStyleRefresh = false
        self:HookExternalTabs()
        if doStyle then
            self:ApplyStyle()
        end
        self:UpdateTabAnchor()
    end)
end

-- Hooks dynamically created third-party tabs (e.g. TalentsForeverBookCharacterTab)
-- so our tab immediately re-chains when they move, show, or hide
function GSI_SideTab:HookExternalTabs()
    local tfbTab = _G["TalentsForeverBookCharacterTab"]
    if tfbTab and not self.hookedTFBTab then
        self.hookedTFBTab = true
        if hooksecurefunc and tfbTab.SetPoint then
            hooksecurefunc(tfbTab, "SetPoint", function()
                if not self.isUpdatingAnchor then
                    self:ScheduleRefresh(false)
                end
            end)
        end
        if tfbTab.HookScript then
            tfbTab:HookScript("OnShow", function()
                if not self.isUpdatingAnchor then
                    self:ScheduleRefresh(false)
                end
            end)
            tfbTab:HookScript("OnHide", function()
                if not self.isUpdatingAnchor then
                    self:ScheduleRefresh(false)
                end
            end)
        end
    end
end

local function SetTabPointIfNeeded(tab, targetParent, targetLevel, point, relTo, relPoint, offsetX, offsetY)
    if targetParent and tab:GetParent() ~= targetParent then
        tab:SetParent(targetParent)
    end
    if targetLevel and tab.GetFrameLevel and tab:GetFrameLevel() ~= targetLevel then
        tab:SetFrameLevel(targetLevel)
    end
    local needsPoint = true
    if tab.GetNumPoints and tab:GetNumPoints() == 1 and tab.GetPoint then
        local curP, curRel, curRP, curX, curY = tab:GetPoint(1)
        if curP == point and curRel == relTo and curRP == relPoint
            and math.abs((curX or 0) - (offsetX or 0)) < 0.5
            and math.abs((curY or 0) - (offsetY or 0)) < 0.5 then
            needsPoint = false
        end
    end
    if needsPoint then
        tab:ClearAllPoints()
        tab:SetPoint(point, relTo, relPoint, offsetX, offsetY)
    end
    if tab.IsShown and not tab:IsShown() then
        tab:Show()
    end
end

-- Anchors our tab cleanly below the last visible ModeTab
function GSI_SideTab:UpdateTabAnchor()
    local tab = self.tabButton
    if not tab or not CharacterFrame or self.isUpdatingAnchor then return end

    self.isUpdatingAnchor = true

    local lastTab, point, relPoint, offsetX, offsetY = GetLastModeTabAndSpacing()
    local modeTabsContainer = GetModeTabsContainer()

    -- Case A: WoW Forever ModeTabs present
    if lastTab then
        local targetParent = modeTabsContainer or lastTab:GetParent() or CharacterFrame
        local targetLevel = lastTab.GetFrameLevel and lastTab:GetFrameLevel() or nil
        SetTabPointIfNeeded(tab, targetParent, targetLevel, point, lastTab, relPoint, offsetX, offsetY)
        self.isUpdatingAnchor = false
        return
    elseif modeTabsContainer then
        SetTabPointIfNeeded(tab, modeTabsContainer, nil, "TOPLEFT", modeTabsContainer, "TOPLEFT", 0, 0)
        self.isUpdatingAnchor = false
        return
    end

    -- Case B: Fallback directly on the right side of CharacterFrame
    local ccsRightAnchor = _G["CCS_StatsFrame"] or _G["ChonkyCharacterSheetFrame"] or CharacterFrame
    if ccsRightAnchor and ccsRightAnchor.IsShown and not ccsRightAnchor:IsShown() then
        ccsRightAnchor = CharacterFrame
    end
    local fallbackLevel = CharacterFrame.GetFrameLevel and (CharacterFrame:GetFrameLevel() + 10) or nil
    SetTabPointIfNeeded(tab, CharacterFrame, fallbackLevel, "TOPLEFT", ccsRightAnchor, "TOPRIGHT", 2, -40)
    self.isUpdatingAnchor = false
end

function GSI_SideTab:Initialize()
    if self.tabButton or not CharacterFrame then return end

    local parentFrame = GetModeTabsContainer() or CharacterFrame

    -- Try native WoW Forever "LargeSideTabButtonTemplate" first
    local ok, tab = pcall(CreateFrame, "Frame", GSI_TAB_NAME, parentFrame, "LargeSideTabButtonTemplate")
    if ok and tab then
        tab.isLargeSideTab = true
    else
        tab = CreateFrame("CheckButton", GSI_TAB_NAME, parentFrame)
        tab.isLargeSideTab = false
    end
    self.tabButton = tab

    -- Initial styling and anchoring
    self:HookExternalTabs()
    self:ApplyStyle()
    self:UpdateTabAnchor()

    -- Click handler: toggle main GSI window
    local function OnTabClick()
        if PlaySound then
            local soundID = (SOUNDKIT and SOUNDKIT.IG_CHARACTER_INFO_TAB) or 841
            pcall(PlaySound, soundID)
        end
        if GSI_UI and GSI_UI.Toggle then
            GSI_UI:Toggle()
        elseif GSI_UI and GSI_UI.mainFrame then
            if GSI_UI.mainFrame:IsShown() then
                GSI_UI.mainFrame:Hide()
            else
                GSI_UI.mainFrame:Show()
            end
        end
        self:SyncState()
    end

    local hasCustomMouseUp = false
    if tab.SetCustomOnMouseUpHandler then
        tab:SetCustomOnMouseUpHandler(function(_, button, upInside)
            if button == "LeftButton" and upInside then
                OnTabClick()
            end
        end)
        hasCustomMouseUp = true
    end
    if tab.RegisterForClicks then
        tab:RegisterForClicks("LeftButtonUp")
    end
    if tab.HasScript and tab:HasScript("OnClick") then
        tab:SetScript("OnClick", OnTabClick)
    elseif not hasCustomMouseUp then
        -- Fallback for basic frames that support OnMouseUp
        tab:EnableMouse(true)
        tab:SetScript("OnMouseUp", function(_, button)
            if button == "LeftButton" then
                OnTabClick()
            end
        end)
    end

    -- Tooltip with GearScore preview & hover highlight (English)
    local function OnTabEnter(selfBtn)
        tab.isHovered = true
        if tab.HighlightTexture and not tab.isCCSSkinned then
            tab.HighlightTexture:Show()
        end
        self:SyncState()

        if GameTooltip then
            GameTooltip:SetOwner(selfBtn, "ANCHOR_RIGHT")
            GameTooltip:ClearLines()
            GameTooltip:AddLine("|cffffcc00GearSetImprover Forever|r", 1, 1, 1)
            GameTooltip:AddLine("Gear optimization & Best Available Gear.", 0.9, 0.9, 0.9, true)

            if GSI_OptimizationEngine and GSI_OptimizationEngine.EvaluateSetup then
                local okScore, score = pcall(function()
                    local setup = GSI_OptimizationEngine:GetCurrentSetup()
                    return GSI_OptimizationEngine:EvaluateSetup(setup)
                end)
                if okScore and type(score) == "number" and score > 0 then
                    GameTooltip:AddLine(string.format("Gear Score: |cffffffff%.1f|r", score), 0.2, 1, 0.2)
                end
            end

            GameTooltip:AddLine("|cff00ff00Left-Click:|r Toggle Addon window", 0.6, 0.6, 0.6)
            GameTooltip:Show()
        end
    end

    local function OnTabLeave()
        tab.isHovered = false
        if tab.HighlightTexture then
            tab.HighlightTexture:Hide()
        end
        self:SyncState()

        if GameTooltip then
            GameTooltip:Hide()
        end
    end

    if tab:GetScript("OnEnter") and tab.HookScript then
        tab:HookScript("OnEnter", OnTabEnter)
    else
        tab:SetScript("OnEnter", OnTabEnter)
    end

    if tab:GetScript("OnLeave") and tab.HookScript then
        tab:HookScript("OnLeave", OnTabLeave)
    else
        tab:SetScript("OnLeave", OnTabLeave)
    end

    -- Hooks on main GSI window: sync active state
    if GSI_UI and GSI_UI.mainFrame then
        GSI_UI.mainFrame:HookScript("OnShow", function() self:SyncState() end)
        GSI_UI.mainFrame:HookScript("OnHide", function() self:SyncState() end)
    end

    -- Consolidated CharacterFrame & external addon hooks for re-anchoring and re-skinning
    if CharacterFrame then
        if hooksecurefunc and type(CharacterFrame.UpdateTabLayout) == "function" then
            hooksecurefunc(CharacterFrame, "UpdateTabLayout", function()
                self:ScheduleRefresh(false)
            end)
        end
        if CharacterFrame.HookScript then
            CharacterFrame:HookScript("OnShow", function()
                self:HookExternalTabs()
                self:ApplyStyle()
                self:UpdateTabAnchor()
                self:ScheduleRefresh(true)
            end)
            CharacterFrame:HookScript("OnSizeChanged", function()
                self:ScheduleRefresh(false)
            end)
        end
    end

    -- Delayed check after PLAYER_LOGIN for TalentsForeverBook (creates its tab via C_Timer.After(1, MakeCharacterTab))
    if C_Timer and C_Timer.After then
        C_Timer.After(1.1, function()
            self:HookExternalTabs()
            self:ApplyStyle()
            self:UpdateTabAnchor()
            if not self.hookedTFBTab then
                C_Timer.After(1.1, function()
                    self:HookExternalTabs()
                    if self.hookedTFBTab then
                        self:ApplyStyle()
                        self:UpdateTabAnchor()
                    end
                end)
            end
        end)
    end

    -- ChonkyCharacterSheet (CCS) skinning hooks
    if CCS then
        if type(CCS.SkinCharacterButtons) == "function" then
            hooksecurefunc(CCS, "SkinCharacterButtons", function()
                self:ScheduleRefresh(true)
            end)
        end
        if type(CCS.CharacterButtonsRevert) == "function" then
            hooksecurefunc(CCS, "CharacterButtonsRevert", function()
                self:ScheduleRefresh(true)
            end)
        end
    end
end

-- Auto-start on PLAYER_LOGIN
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        GSI_SideTab:Initialize()
    end
end)
