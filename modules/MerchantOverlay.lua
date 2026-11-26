-- ============================================================
-- GearSetImprover -- MerchantOverlay.lua (WoW Forever)
-- Docks a compact Clean-up panel to the MerchantFrame, listing
-- obsolete bag gear based on current GSI settings with quick
-- single-sell, Sell All, and Disenchant actions.
-- ============================================================

GSI_UI = GSI_UI or {}

local GetItemInfo = (C_Item and C_Item.GetItemInfo) or _G.GetItemInfo or function() return nil end
local GetItemIcon = _G.GSI_GetItemIcon or function() return "Interface\\Icons\\INV_Misc_QuestionMark" end

local function SafeUseBagItem(bag, slot)
    if C_Container and C_Container.UseContainerItem then
        C_Container.UseContainerItem(bag, slot)
    elseif UseContainerItem then
        UseContainerItem(bag, slot)
    end
end

local function FormatMoneyString(copper)
    if not copper or copper <= 0 then return "0c" end
    local gold = math.floor(copper / 10000)
    local silver = math.floor((copper % 10000) / 100)
    local c = copper % 100
    if gold > 0 then
        return string.format("%d|cffffd700g|r %d|cffc7c7cfs|r %d|cffeda55fc|r", gold, silver, c)
    elseif silver > 0 then
        return string.format("%d|cffc7c7cfs|r %d|cffeda55fc|r", silver, c)
    else
        return string.format("%d|cffeda55fc|r", c)
    end
end

local function SyncMerchantCheckboxes(isEnabled)
    if GSI_UI.cbMerchantOverlay and GSI_UI.cbMerchantOverlay.SetChecked then
        GSI_UI.cbMerchantOverlay:SetChecked(isEnabled)
    end
    if GSI_UI.blizzOptionsPanel and GSI_UI.blizzOptionsPanel.cbMerchantOverlay and GSI_UI.blizzOptionsPanel.cbMerchantOverlay.SetChecked then
        GSI_UI.blizzOptionsPanel.cbMerchantOverlay:SetChecked(isEnabled)
    end
    if _G["GSI_BlizzMerchantOverlayCheck"] and _G["GSI_BlizzMerchantOverlayCheck"].SetChecked then
        _G["GSI_BlizzMerchantOverlayCheck"]:SetChecked(isEnabled)
    end
    if GSI_UI.junkMerchantOverlayCheck and GSI_UI.junkMerchantOverlayCheck.SetChecked then
        GSI_UI.junkMerchantOverlayCheck:SetChecked(isEnabled)
    end
    if _G["GSI_JunkMerchantOverlayCheck"] and _G["GSI_JunkMerchantOverlayCheck"].SetChecked then
        _G["GSI_JunkMerchantOverlayCheck"]:SetChecked(isEnabled)
    end
end

local function UpdateMerchantFooterState(overlay)
    if not overlay then return end

    if overlay.deMacroBtn then
        local hasSpell = GSI_UI.HasDisenchantSpell and GSI_UI:HasDisenchantSpell()
        if not (InCombatLockdown and InCombatLockdown()) then
            if hasSpell then
                overlay.deMacroBtn:Show()
                local deItems = GSI_UI.GetDisenchantableItems and GSI_UI:GetDisenchantableItems() or {}
                if #deItems > 0 then
                    overlay.deMacroBtn:Enable()
                    overlay.deMacroBtn:SetAlpha(1.0)
                    overlay.deMacroBtn:SetText(string.format("DE (%d)", #deItems))
                else
                    overlay.deMacroBtn:Disable()
                    overlay.deMacroBtn:SetAlpha(0.5)
                    overlay.deMacroBtn:SetText("DE (0)")
                end
                if GSI_UI.SyncExistingDisenchantMacro then
                    GSI_UI:SyncExistingDisenchantMacro()
                end
            else
                overlay.deMacroBtn:Hide()
            end
        end
    end

    if overlay.totalGoldLabel then
        overlay.totalGoldLabel:ClearAllPoints()
        overlay.totalGoldLabel:SetPoint("LEFT", 12, 0)
        if overlay.deMacroBtn and overlay.deMacroBtn:IsShown() then
            overlay.totalGoldLabel:SetPoint("RIGHT", overlay.deMacroBtn, "LEFT", -8, 0)
        elseif overlay.sellAllBtn then
            overlay.totalGoldLabel:SetPoint("RIGHT", overlay.sellAllBtn, "LEFT", -8, 0)
        end
    end
end

function GSI_UI:CreateMerchantOverlay()
    if self.merchantOverlay then return self.merchantOverlay end

    local overlay = CreateFrame("Frame", "GSI_MerchantOverlay", UIParent, self.BACKDROP_TEMPLATE)
    overlay:SetSize(340, 424)
    overlay:SetFrameStrata("HIGH")
    overlay:SetFrameLevel(MerchantFrame and (MerchantFrame:GetFrameLevel() + 2) or 50)
    overlay:EnableMouse(true)
    overlay:SetClampedToScreen(true)

    if self.SkinFrame then
        self:SkinFrame(overlay, "dialog", true)
    end

    -- Header Bar
    local header = CreateFrame("Frame", nil, overlay)
    header:SetHeight(32)
    header:SetPoint("TOPLEFT", 0, 0)
    header:SetPoint("TOPRIGHT", 0, 0)
    if self.SkinFrame then
        self:SkinFrame(header, "header")
    end

    -- Close Button (Flat GSI X)
    local closeBtn = CreateFrame("Button", nil, header, self.BACKDROP_TEMPLATE)
    closeBtn:SetSize(20, 20)
    closeBtn:SetPoint("RIGHT", -8, 0)
    closeBtn:SetText("X")
    if self.SkinButton then
        self:SkinButton(closeBtn, true)
    end
    closeBtn:SetScript("OnClick", function()
        overlay:Hide()
        overlay._userClosed = true
        if GSI_MerchantToggleBtn then
            local isEnabled = not (GearSetImproverDB and GearSetImproverDB.merchantOverlayEnabled == false)
            GSI_MerchantToggleBtn:SetShown(isEnabled)
        end
    end)

    local title = self:CreateText(header, "CARD_TITLE", "|cffffcc00GSI|r Clean-up")
    title:SetPoint("LEFT", 12, 0)

    local countLabel = self:CreateText(header, "SMALL", "")
    countLabel:SetPoint("LEFT", title, "RIGHT", 6, 0)
    countLabel:SetPoint("RIGHT", closeBtn, "LEFT", -6, 0)
    countLabel:SetJustifyH("LEFT")
    countLabel:SetWordWrap(false)
    overlay.countLabel = countLabel

    -- Flat Safety Notice Strip (1px bottom hairline, no box border)
    local noticeCard = CreateFrame("Frame", nil, overlay)
    noticeCard:SetPoint("TOPLEFT", 10, -38)
    noticeCard:SetPoint("TOPRIGHT", -10, -38)
    noticeCard:SetHeight(46)

    local ncDiv = noticeCard:CreateTexture(nil, "ARTWORK")
    ncDiv:SetPoint("BOTTOMLEFT", noticeCard, "BOTTOMLEFT", 0, 0)
    ncDiv:SetPoint("BOTTOMRIGHT", noticeCard, "BOTTOMRIGHT", 0, 0)
    ncDiv:SetHeight(1)
    ncDiv:SetColorTexture(1, 1, 1, 0.08)

    local checkIcon = noticeCard:CreateTexture(nil, "ARTWORK")
    checkIcon:SetSize(16, 16)
    checkIcon:SetPoint("TOPLEFT", 8, -8)
    checkIcon:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready")

    local noticeText = self:CreateText(noticeCard, "SMALL", "")
    noticeText:SetPoint("TOPLEFT", checkIcon, "TOPRIGHT", 6, 2)
    noticeText:SetPoint("BOTTOMRIGHT", -8, 6)
    noticeText:SetJustifyH("LEFT")
    noticeText:SetJustifyV("TOP")
    noticeText:SetWordWrap(true)
    noticeText:SetText("|cff88ff88Safe to sell:|r These items are weaker than currently equipped gear based on your GSI settings.")

    -- Scroll Area (340 - 10 - 26 = 304px viewport)
    local scrollFrame = CreateFrame("ScrollFrame", "GSIMerchantScrollFrame", overlay, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", noticeCard, "BOTTOMLEFT", 0, -8)
    scrollFrame:SetPoint("BOTTOMRIGHT", overlay, "BOTTOMRIGHT", -26, 44)

    if self.SkinScrollBar then
        self:SkinScrollBar(scrollFrame)
    end

    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetSize(304, 1)
    scrollFrame:SetScrollChild(scrollChild)
    overlay.scrollChild = scrollChild
    overlay.rows = {}

    -- Empty State Message
    local emptyLabel = self:CreateText(scrollChild, "SMALL", "No obsolete gear in bags.")
    emptyLabel:SetPoint("CENTER", scrollFrame, "CENTER", 0, 0)
    emptyLabel:SetWidth(280)
    emptyLabel:SetJustifyH("CENTER")
    overlay.emptyLabel = emptyLabel

    -- Bottom Bar
    local bottomBar = CreateFrame("Frame", nil, overlay)
    bottomBar:SetHeight(38)
    bottomBar:SetPoint("BOTTOMLEFT", 0, 0)
    bottomBar:SetPoint("BOTTOMRIGHT", 0, 0)

    local bbDiv = bottomBar:CreateTexture(nil, "ARTWORK")
    bbDiv:SetPoint("TOPLEFT", bottomBar, "TOPLEFT", 8, 0)
    bbDiv:SetPoint("TOPRIGHT", bottomBar, "TOPRIGHT", -8, 0)
    bbDiv:SetHeight(1)
    bbDiv:SetColorTexture(1, 1, 1, 0.08)

    local sellAllBtn = CreateFrame("Button", nil, bottomBar, self.BACKDROP_TEMPLATE)
    sellAllBtn:SetSize(84, 24)
    sellAllBtn:SetPoint("RIGHT", -10, 0)
    sellAllBtn:SetText("Sell All")
    if self.SkinButton then
        self:SkinButton(sellAllBtn, "Sell All", true)
    end
    sellAllBtn:SetScript("OnClick", function()
        if StaticPopup_Show then
            StaticPopup_Show("GSI_CONFIRM_SELL_ALL")
        else
            GSI_UI:ExecuteSellAll()
        end
    end)
    overlay.sellAllBtn = sellAllBtn

    local deBtnTemplates = "SecureActionButtonTemplate"
    if self.BACKDROP_TEMPLATE then deBtnTemplates = deBtnTemplates .. ", " .. self.BACKDROP_TEMPLATE end
    local deMacroBtn = CreateFrame("Button", "GSI_MerchantDisenchantBtn", bottomBar, deBtnTemplates)
    deMacroBtn:SetSize(78, 24)
    deMacroBtn:SetPoint("RIGHT", sellAllBtn, "LEFT", -6, 0)
    deMacroBtn:SetText("DE (0)")
    if self.SkinButton then
        self:SkinButton(deMacroBtn, "DE (0)", false)
    end
    if self.BindDisenchantActionButton then
        self:BindDisenchantActionButton(deMacroBtn)
    end
    deMacroBtn:HookScript("OnEnter", function(selfBtn)
        GameTooltip:SetOwner(selfBtn, "ANCHOR_TOP")
        GameTooltip:ClearLines()
        GameTooltip:AddLine("|cffffcc00Disenchant Next Item|r", 1, 1, 1)
        GameTooltip:AddLine("Click repeatedly to disenchant listed obsolete gear items one by one.", 0.9, 0.9, 0.9, true)
        GameTooltip:AddLine("|cff888888Tip: You can also drag out an Action Bar macro in the Settings tab.|r", 0.7, 0.7, 0.7, true)
        GameTooltip:Show()
    end)
    deMacroBtn:HookScript("OnLeave", function() GameTooltip:Hide() end)
    overlay.deMacroBtn = deMacroBtn

    local totalGoldLabel = self:CreateText(bottomBar, "BODY", "")
    totalGoldLabel:SetPoint("LEFT", 12, 0)
    totalGoldLabel:SetPoint("RIGHT", deMacroBtn, "LEFT", -8, 0)
    totalGoldLabel:SetJustifyH("LEFT")
    totalGoldLabel:SetWordWrap(false)
    overlay.totalGoldLabel = totalGoldLabel

    overlay:HookScript("OnHide", function()
        if _G["GSI_MerchantToggleBtn"] and GearSetImproverDB and GearSetImproverDB.merchantOverlayEnabled == false then
            _G["GSI_MerchantToggleBtn"]:Hide()
        end
    end)

    self.merchantOverlay = overlay
    return overlay
end

local function CreateOrUpdateMerchantToggleBtn()
    if not MerchantFrame then return end
    local isEnabled = not (GearSetImproverDB and GearSetImproverDB.merchantOverlayEnabled == false)
    if not _G["GSI_MerchantToggleBtn"] then
        if not isEnabled then return end
        local btn = CreateFrame("Button", "GSI_MerchantToggleBtn", MerchantFrame, GSI_UI.BACKDROP_TEMPLATE)
        btn:SetSize(90, 20)
        btn:SetPoint("TOPRIGHT", MerchantFrame, "TOPRIGHT", -36, -3)
        btn:SetFrameLevel((MerchantFrame:GetFrameLevel() or 10) + 10)
        btn:SetText("GSI Clean-up")
        if GSI_UI.SkinButton then
            GSI_UI:SkinButton(btn, "GSI Clean-up", false)
        end
        btn:SetScript("OnClick", function()
            if GSI_UI.merchantOverlay and GSI_UI.merchantOverlay:IsShown() then
                GSI_UI.merchantOverlay:Hide()
                GSI_UI.merchantOverlay._userClosed = true
            else
                if GSI_UI.merchantOverlay then
                    GSI_UI.merchantOverlay._userClosed = false
                end
                GSI_UI:UpdateMerchantPanel()
            end
        end)
        btn:SetScript("OnEnter", function(selfBtn)
            GameTooltip:SetOwner(selfBtn, "ANCHOR_TOP")
            GameTooltip:ClearLines()
            GameTooltip:AddLine("|cffffcc00GSI Clean-up|r", 1, 1, 1)
            GameTooltip:AddLine("Click to toggle the Clean-up gear panel.", 0.9, 0.9, 0.9, true)
            GameTooltip:Show()
        end)
        btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    end
    if _G["GSI_MerchantToggleBtn"] then
        _G["GSI_MerchantToggleBtn"]:SetShown(isEnabled)
    end
end

function GSI_UI:SetMerchantOverlayEnabled(enabled)
    local isEnabled = (enabled == true or enabled == 1)
    if not GearSetImproverDB then GearSetImproverDB = {} end
    GearSetImproverDB.merchantOverlayEnabled = isEnabled

    SyncMerchantCheckboxes(isEnabled)
    CreateOrUpdateMerchantToggleBtn()

    if not isEnabled then
        if self.merchantOverlay then
            self.merchantOverlay._userClosed = false
            self.merchantOverlay:Hide()
        end
        if _G["GSI_MerchantOverlay"] then
            _G["GSI_MerchantOverlay"]:Hide()
        end
    else
        if self.merchantOverlay then
            self.merchantOverlay._userClosed = false
        end
        if MerchantFrame and MerchantFrame:IsShown() then
            self:UpdateMerchantPanel()
        end
    end
end

function GSI_UI:UpdateMerchantPanel()
    local isEnabled = not (GearSetImproverDB and GearSetImproverDB.merchantOverlayEnabled == false)
    SyncMerchantCheckboxes(isEnabled)

    if not (MerchantFrame and MerchantFrame:IsShown()) then
        if self.merchantOverlay then self.merchantOverlay:Hide() end
        return
    end

    CreateOrUpdateMerchantToggleBtn()

    if not isEnabled then
        if self.merchantOverlay then self.merchantOverlay:Hide() end
        return
    end

    local overlay = self:CreateMerchantOverlay()
    if overlay._userClosed then
        return
    end

    -- Anchor smoothly to the right side of MerchantFrame
    overlay:ClearAllPoints()
    overlay:SetPoint("TOPLEFT", MerchantFrame, "TOPRIGHT", 4, 0)
    overlay:SetHeight(MerchantFrame:GetHeight() or 424)
    overlay:Show()

    local items = (self.ScanBagsForJunk and self:ScanBagsForJunk()) or {}
    local rows = overlay.rows
    local scrollChild = overlay.scrollChild
    local yOff = 0
    local totalSellPrice = 0

    overlay.countLabel:SetText(string.format("(%d)", #items))

    if #items == 0 then
        overlay.emptyLabel:Show()
        overlay.sellAllBtn:Disable()
        overlay.totalGoldLabel:SetText("")
        for _, row in pairs(rows) do row:Hide() end
        scrollChild:SetHeight(1)
        UpdateMerchantFooterState(overlay)
        return
    else
        overlay.emptyLabel:Hide()
        overlay.sellAllBtn:Enable()
    end

    for i, item in ipairs(items) do
        local row = rows[i]
        if not row then
            row = CreateFrame("Frame", nil, scrollChild)
            row:SetSize(304, 30)
            row:EnableMouse(true)

            local div = row:CreateTexture(nil, "ARTWORK")
            div:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 2, 0)
            div:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", -2, 0)
            div:SetHeight(1)
            div:SetColorTexture(1, 1, 1, 0.08)
            row.divider = div

            local icon = row:CreateTexture(nil, "ARTWORK")
            icon:SetSize(22, 22)
            icon:SetPoint("LEFT", 4, 0)
            row.icon = icon

            local singleSellBtn = CreateFrame("Button", nil, row, self.BACKDROP_TEMPLATE)
            singleSellBtn:SetSize(48, 20)
            singleSellBtn:SetPoint("RIGHT", -4, 0)
            singleSellBtn:SetText("Sell")
            if self.SkinButton then
                self:SkinButton(singleSellBtn, "Sell", false)
            end
            row.singleSellBtn = singleSellBtn

            local linkText = self:CreateText(row, "SMALL", "")
            linkText:SetPoint("LEFT", icon, "RIGHT", 6, 0)
            linkText:SetPoint("RIGHT", singleSellBtn, "LEFT", -6, 0)
            linkText:SetJustifyH("LEFT")
            linkText:SetWordWrap(false)
            row.linkText = linkText

            rows[i] = row
        end

        row.item = item
        row.linkText:SetText((self.ResolveItemDisplayText and self:ResolveItemDisplayText(item.link, nil, item.bagID, item.slotID)) or item.link or "Item")
        row.icon:SetTexture(GetItemIcon(item.link))
        if self.SkinItemIcon then
            self:SkinItemIcon(row.icon, row, item.quality)
        end

        local _, _, _, _, _, _, _, _, _, _, sellPrice = GetItemInfo(item.link)
        if sellPrice and sellPrice > 0 then
            totalSellPrice = totalSellPrice + sellPrice
        end

        row.singleSellBtn:SetScript("OnClick", function()
            SafeUseBagItem(item.bagID, item.slotID)
            C_Timer.After(0.12, function()
                if GSI_UI.UpdateMerchantPanel then
                    GSI_UI:UpdateMerchantPanel()
                end
                if GSI_UI.activeTab == "JUNK" and GSI_UI.mainFrame and GSI_UI.mainFrame:IsShown() then
                    local frame = GSI_UI.mainFrame.tabFrames and GSI_UI.mainFrame.tabFrames["JUNK"]
                    if frame and GSI_UI.UpdateJunkList then GSI_UI:UpdateJunkList(frame) end
                end
            end)
        end)

        row:SetScript("OnEnter", function(selfRow)
            if selfRow.divider then selfRow.divider:SetColorTexture(1, 1, 1, 0.20) end
            GameTooltip:SetOwner(selfRow, "ANCHOR_RIGHT")
            GameTooltip:SetHyperlink(item.link)
            GameTooltip:Show()
        end)
        row:SetScript("OnLeave", function(selfRow)
            if selfRow.divider then selfRow.divider:SetColorTexture(1, 1, 1, 0.08) end
            GameTooltip:Hide()
        end)

        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -yOff)
        row:Show()
        yOff = yOff + 33
    end

    -- Hide surplus rows
    for j = #items + 1, #rows do
        rows[j]:Hide()
    end

    scrollChild:SetHeight(math.max(yOff, 1))

    if totalSellPrice > 0 then
        overlay.totalGoldLabel:SetText(FormatMoneyString(totalSellPrice))
    else
        overlay.totalGoldLabel:SetText("")
    end

    UpdateMerchantFooterState(overlay)
end

-- ============================================================
-- Merchant Events & Reopen Button on MerchantFrame
-- ============================================================
local merchantWatcher = CreateFrame("Frame")
merchantWatcher:RegisterEvent("MERCHANT_SHOW")
merchantWatcher:RegisterEvent("MERCHANT_CLOSED")
merchantWatcher:RegisterEvent("BAG_UPDATE_DELAYED")

local function OnMerchantShow()
    if GSI_UI.merchantOverlay then
        GSI_UI.merchantOverlay._userClosed = false
    end
    CreateOrUpdateMerchantToggleBtn()
    GSI_UI:UpdateMerchantPanel()
end

merchantWatcher:SetScript("OnEvent", function(self, event)
    if event == "MERCHANT_SHOW" then
        OnMerchantShow()
    elseif event == "MERCHANT_CLOSED" then
        if GSI_UI.merchantOverlay then
            GSI_UI.merchantOverlay:Hide()
            GSI_UI.merchantOverlay._userClosed = false
        end
    elseif event == "BAG_UPDATE_DELAYED" then
        if MerchantFrame and MerchantFrame:IsShown() and not (GearSetImproverDB and GearSetImproverDB.merchantOverlayEnabled == false) then
            GSI_UI:UpdateMerchantPanel()
        end
    end
end)

-- Additional hook on MerchantFrame:HookScript("OnShow") in case MERCHANT_SHOW fires before MerchantFrame:IsShown() is true
if MerchantFrame and MerchantFrame.HookScript then
    MerchantFrame:HookScript("OnShow", function()
        OnMerchantShow()
    end)
    MerchantFrame:HookScript("OnHide", function()
        if GSI_UI.merchantOverlay then
            GSI_UI.merchantOverlay:Hide()
            GSI_UI.merchantOverlay._userClosed = false
        end
    end)
end
