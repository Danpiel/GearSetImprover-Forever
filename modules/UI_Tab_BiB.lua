-- ============================================================
-- GearSetImprover - UI_Tab_BiB.lua (Best-in-Bag Tab)
-- Uses GSI_EquipManager for safe equipping and popup guards.
-- ============================================================

GSI_UI = GSI_UI or {}

local GetItemInfo = (C_Item and C_Item.GetItemInfo) or _G.GetItemInfo or function() return nil end
local GetItemIcon = _G.GSI_GetItemIcon or _G.GetItemIcon or function() return "Interface\\Icons\\INV_Misc_QuestionMark" end
local BackdropTemplateMixin = _G.BackdropTemplateMixin
local BACKDROP_TEMPLATE = BackdropTemplateMixin and "BackdropTemplate" or nil

local print = function(...)
    if GSI_Print then
        GSI_Print(...)
    elseif not (GearSetImproverDB and (GearSetImproverDB.disableChatOutput or GearSetImproverDB.disableChat)) then
        _G.print(...)
    end
end

local function IsTradeableBindPopupOpen() return GSI_EquipManager and GSI_EquipManager.IsTradeableBindPopupOpen and GSI_EquipManager.IsTradeableBindPopupOpen() end
local function IsBindConfirmPopupOpen() return GSI_EquipManager and GSI_EquipManager.IsBindConfirmPopupOpen and GSI_EquipManager.IsBindConfirmPopupOpen() end
local function ConfirmPendingBind(slotID) if GSI_EquipManager and GSI_EquipManager.ConfirmPendingBind then return GSI_EquipManager.ConfirmPendingBind(slotID) end end
local function CountBagCopiesByID(idNum) return (GSI_EquipManager and GSI_EquipManager.CountBagCopiesByID and GSI_EquipManager.CountBagCopiesByID(idNum)) or 0 end
local function ResolveUpgradeBagSlot(up) if GSI_EquipManager and GSI_EquipManager.ResolveUpgradeBagSlot then return GSI_EquipManager.ResolveUpgradeBagSlot(up) end end
local function IsBagSlotLocked(bag, slot) return GSI_EquipManager and GSI_EquipManager.IsBagSlotLocked and GSI_EquipManager.IsBagSlotLocked(bag, slot) or false end

-- ---------------------------------------------------------------
-- CENTRAL OPTIMIZATION CONTROL (Run & Schedule)
-- ---------------------------------------------------------------
GSI_UI.isEquippingAll = false
GSI_UI.isOptimizing = false
GSI_UI.needsReoptimization = false
GSI_UI.optTimer = nil

function GSI_UI:ScheduleOptimization(delay, force)
    delay = delay or 0.35

    -- Skip intermediate scans while "Equip All" is active unless forced
    if GSI_UI.isEquippingAll and not force then
        return
    end

    if GSI_UI.optTimer then
        if type(GSI_UI.optTimer) == "table" and GSI_UI.optTimer.Cancel then
            pcall(function() GSI_UI.optTimer:Cancel() end)
        end
        GSI_UI.optTimer = nil
    end

    local function DoOptimize()
        GSI_UI.optTimer = nil
        if GSI_UI.isEquippingAll and not force then
            return
        end
        if GSI_UI.RunOptimization then
            GSI_UI:RunOptimization()
        end
    end

    if C_Timer and C_Timer.NewTimer then
        local ok, timerObj = pcall(C_Timer.NewTimer, delay, DoOptimize)
        if ok and timerObj then
            GSI_UI.optTimer = timerObj
            return
        end
    end

    if C_Timer and C_Timer.After then
        local myToken = {}
        GSI_UI._optToken = myToken
        C_Timer.After(delay, function()
            if GSI_UI._optToken == myToken then
                GSI_UI._optToken = nil
                DoOptimize()
            end
        end)
    else
        DoOptimize()
    end
end

-- Scan results were scored with the weights of that moment. After a spec or
-- talent change they are stale: the list hides them and the bags are scanned
-- again while the window is open (a burst of talent events gives one scan, the
-- timer restarts on each); a closed window scans anyway when it opens.
function GSI_UI:MarkScanStale()
    GSI_UI._staleGen = (GSI_UI._staleGen or 0) + 1
    GSI_UI.scanStale = true
    local mf = GSI_UI.mainFrame
    if mf and mf:IsShown() then
        GSI_UI:ScheduleOptimization(0.5, false)
    end
end

function GSI_UI:RunOptimization(onComplete)
    if GSI_UI.isOptimizing then
        GSI_UI.needsReoptimization = true
        return
    end

    local bibFrame = GSI_UI.bibFrame or (GSI_UI.mainFrame and GSI_UI.mainFrame.tabFrames and GSI_UI.mainFrame.tabFrames["BIB"])
    local optBtn = bibFrame and bibFrame.optBtn
    local statusText = bibFrame and bibFrame.statusText

    if optBtn then
        optBtn:Disable()
        optBtn:SetText("Optimizing...")
    end
    if statusText and bibFrame and bibFrame:IsShown() then
        statusText:SetText("|cffffff00Scanning bags...|r")
    end

    GSI_UI.isOptimizing = true
    GSI_UI.needsReoptimization = false

    -- Invalidate caches before scanning so newly equipped items are re-evaluated reliably
    if GSI_ItemScore and GSI_ItemScore.ResetCache then
        GSI_ItemScore:ResetCache()
    end
    if GSI_OptimizationEngine and GSI_OptimizationEngine.ResetCache then
        GSI_OptimizationEngine:ResetCache()
    end

    local staleGen = GSI_UI._staleGen or 0
    local ok, err = pcall(function()
        GSI_OptimizationEngine:OptimizeBagGearAsync(nil, function(bestSetup, bestScore, upgrades, totalGain, scanStats)
            GSI_UI.isOptimizing = false
            GSI_UI.lastScanned = true
            GSI_UI.lastUpgrades = upgrades
            GSI_UI.lastTotalGain = totalGain
            GSI_UI.lastScanStats = scanStats
            -- A scan that started before the last spec / talent change used the
            -- old weights: it stays stale until the rescan MarkScanStale scheduled.
            if (GSI_UI._staleGen or 0) == staleGen then
                GSI_UI.scanStale = false
            end

            if bibFrame then
                bibFrame.scanned = true
                bibFrame.upgrades = upgrades
                bibFrame.totalGain = totalGain
                bibFrame.scanStats = scanStats
                -- The chat line belongs to this scan, printed by the next list update
                bibFrame.announcePending = bibFrame:IsShown() and true or false
                bibFrame.userRequestedScan = GSI_UI._scanRequestedByUser
                GSI_UI._scanRequestedByUser = nil
                if bibFrame:IsShown() then
                    GSI_UI:UpdateBiBList(bibFrame)
                end
            end

            if optBtn then
                optBtn:Enable()
                optBtn:SetText("Optimize Gear")
            end

            pcall(function() GSI_UI:UpdateTitleScore() end)

            -- Immediately refresh active window with fresh scan results
            if GSI_UI.mainFrame and GSI_UI.mainFrame:IsShown() then
                pcall(function() GSI_UI:RefreshPanel() end)
            end

            if onComplete then
                onComplete(bestSetup, bestScore, upgrades, totalGain, scanStats)
            end

            if GSI_UI.needsReoptimization then
                GSI_UI.needsReoptimization = false
                GSI_UI:ScheduleOptimization(0.1, true)
            end
        end)
    end)

    if not ok then
        GSI_UI.isOptimizing = false
        if optBtn then
            optBtn:Enable()
            optBtn:SetText("Optimize Gear")
        end
        if statusText then
            statusText:SetText("|cffff4444Optimization error:|r " .. tostring(err))
        end
        print("|cffff4444[GearSetImprover] Optimization error:|r " .. tostring(err))
    end
end

function GSI_UI:DrawBiB(parent)
    local T = self.THEME

    local optBtn = CreateFrame("Button", nil, parent, BACKDROP_TEMPLATE)
    optBtn:SetSize(130, 26)
    optBtn:SetPoint("TOPRIGHT", -20, -14)
    optBtn:SetText("Optimize Gear")
    self:SkinButton(optBtn, nil, "PRIMARY")
    if optBtn.RegisterForClicks then
        optBtn:RegisterForClicks("AnyUp")
    end
    parent.optBtn = optBtn

    local saveSetBtn = CreateFrame("Button", nil, parent, BACKDROP_TEMPLATE)
    saveSetBtn:SetSize(90, 26)
    saveSetBtn:SetPoint("RIGHT", optBtn, "LEFT", -8, 0)
    saveSetBtn:SetText("Save Set")
    self:SkinButton(saveSetBtn, nil, "SECONDARY")
    if saveSetBtn.RegisterForClicks then
        saveSetBtn:RegisterForClicks("AnyUp")
    end
    parent.saveSetBtn = saveSetBtn
    saveSetBtn:SetScript("OnClick", function()
        local specIndex = GSI_StatWeights:GetActiveSpecIndex()
        local ok = GSI_UI:SaveEquipmentSetForProfile(specIndex)
        if ok then
            pcall(function()
                if PlaySound then PlaySound(SOUNDKIT and SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON or 856) end
            end)
        end
    end)
    saveSetBtn:SetScript("OnEnter", function(selfBtn)
        GameTooltip:SetOwner(selfBtn, "ANCHOR_RIGHT")
        GameTooltip:AddLine("Save Equipment Set to Character Profile", 1, 0.82, 0)
        GameTooltip:AddLine("Saves current equipped gear as an Equipment Set in Blizzard Equipment Manager.", 1, 1, 1, true)
        GameTooltip:Show()
    end)
    saveSetBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    local equipAllBtn = CreateFrame("Button", nil, parent, BACKDROP_TEMPLATE)
    equipAllBtn:SetSize(100, 26)
    equipAllBtn:SetPoint("RIGHT", saveSetBtn, "LEFT", -8, 0)
    equipAllBtn:SetText("Equip All")
    self:SkinButton(equipAllBtn, nil, "PRIMARY")
    if equipAllBtn.RegisterForClicks then
        equipAllBtn:RegisterForClicks("AnyUp")
    end
    equipAllBtn:Hide()
    parent.equipAllBtn = equipAllBtn

    local header = self:CreateText(parent, "TITLE", "BEST AVAILABLE OPTIMIZATION", "LEFT")
    header:SetPoint("TOPLEFT", 16, -16)
    header:SetPoint("TOPRIGHT", equipAllBtn, "TOPLEFT", -10, -2)
    header:SetWordWrap(false)

    local sub = self:CreateText(parent, "SMALL", "Scan your bags for automatic score upgrades & 1-click equip:", "LEFT")
    sub:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -3)
    sub:SetPoint("TOPRIGHT", header, "BOTTOMRIGHT", 0, -3)
    sub:SetWordWrap(false)

    -- Flat Status Strip with 1px bottom hairline + class-colored left accent
    local statusCard = CreateFrame("Frame", nil, parent)
    statusCard:SetPoint("TOPLEFT", sub, "BOTTOMLEFT", -2, -8)
    statusCard:SetPoint("RIGHT", -20, 0)
    statusCard:SetHeight(26)
    parent.statusCard = statusCard

    local scDiv = statusCard:CreateTexture(nil, "ARTWORK")
    scDiv:SetPoint("BOTTOMLEFT", statusCard, "BOTTOMLEFT", 0, 0)
    scDiv:SetPoint("BOTTOMRIGHT", statusCard, "BOTTOMRIGHT", 0, 0)
    scDiv:SetHeight(self:PP(1))
    scDiv:SetColorTexture(1, 1, 1, 0.08)

    local scGlow = statusCard:CreateTexture(nil, "OVERLAY")
    scGlow:SetPoint("BOTTOMLEFT", statusCard, "BOTTOMLEFT", 0, 0)
    scGlow:SetSize(180, self:PP(1))
    scGlow:SetTexture("Interface\\Buttons\\WHITE8x8")
    local cr, cg, cb = self:GetClassColor()
    self:SetGradient(scGlow, "HORIZONTAL", cr, cg, cb, 0.55, cr, cg, cb, 0.0)

    local status = self:CreateText(statusCard, "BODY", "Click 'Optimize Gear' to scan bags for the best available gear.", "LEFT")
    status:SetPoint("LEFT", 2, 0)
    status:SetPoint("RIGHT", statusCard, "RIGHT", -4, 0)
    status:SetWordWrap(false)
    parent.statusText = status

    local scroll = CreateFrame("ScrollFrame", "GSI_BiBScroll", parent, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", statusCard, "BOTTOMLEFT", 0, -10)
    scroll:SetPoint("BOTTOMRIGHT", -24, 12)
    if GSI_UI and GSI_UI.SkinScrollBar then
        GSI_UI:SkinScrollBar(scroll)
    end

    local child = CreateFrame("Frame", nil, scroll)
    child:SetSize(700, 500)
    scroll:SetScrollChild(child)
    parent.scrollChild = child
    parent.rows = {}

    parent.RunOptimization = function(cb) GSI_UI:RunOptimization(cb) end
    GSI_UI.bibFrame = parent

    -- If a scan result already exists (e.g., from background gear changes), restore it
    if GSI_UI.lastScanned then
        parent.scanned = true
        parent.upgrades = GSI_UI.lastUpgrades
        parent.totalGain = GSI_UI.lastTotalGain
        parent.scanStats = GSI_UI.lastScanStats
    end

    optBtn:SetScript("OnClick", function()
        pcall(function()
            if PlaySound then
                PlaySound(SOUNDKIT and SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON or 856)
            end
        end)
        GSI_UI._scanRequestedByUser = true
        GSI_UI:RunOptimization()
    end)

    equipAllBtn:SetScript("OnClick", function()
        local upgrades = parent.upgrades or {}
        local list = {}
        local lockedCount = 0
        for sID, u in pairs(upgrades) do
            u.slotID = u.slotID or tonumber(sID)
            local isLocked = u.isLocked or (GearSetImproverDB and GearSetImproverDB.lockedGearSlots and GearSetImproverDB.lockedGearSlots[sID])
            if isLocked then
                lockedCount = lockedCount + 1
            else
                table.insert(list, { slotID = tonumber(sID), up = u })
            end
        end

        if #list == 0 then
            if lockedCount > 0 then
                print("|cffffcc00[GearSetImprover]|r All available upgrades are on locked slots. Unlock them first to equip.")
            end
            return
        end

        equipAllBtn:Disable()
        equipAllBtn:SetText("Equipping...")
        GSI_UI.isEquippingAll = true

        local idx = 1
        local boeWaitTicks = 0
        local function StepEquip()
            -- Pause Equip All while any BoE or dungeon-tradeable confirmation popup is active
            if IsBindConfirmPopupOpen() then
                boeWaitTicks = boeWaitTicks + 1
                if boeWaitTicks < 240 then -- Wait up to 60s for user confirmation
                    if C_Timer and C_Timer.After then
                        C_Timer.After(0.25, StepEquip)
                        return
                    end
                end
            end
            boeWaitTicks = 0

            if idx > #list then
                GSI_UI.isEquippingAll = false
                equipAllBtn:Enable()
                equipAllBtn:SetText("|cff00ff00Equip All|r")
                print("|cffffcc00[GearSetImprover]|r All available upgrades equipped! Optimizing...")

                local specIndex = GSI_StatWeights:GetActiveSpecIndex()
                local function FinishEquipAll()
                    GSI_UI:SaveEquipmentSetForProfile(specIndex)
                    -- Immediately run Optimize Gear again
                    if GSI_UI.ScheduleOptimization then
                        GSI_UI:ScheduleOptimization(0.15, true)
                    elseif GSI_UI.RunOptimization then
                        GSI_UI:RunOptimization()
                    end
                end

                if C_Timer and C_Timer.After then
                    C_Timer.After(0.25, FinishEquipAll)
                else
                    FinishEquipAll()
                end
                return
            end

            local item = list[idx]
            local b, s = ResolveUpgradeBagSlot(item.up)
            local isBagLocked = (b ~= nil and s ~= nil and IsBagSlotLocked(b, s))
            local isInvLocked = IsInventoryItemLocked and IsInventoryItemLocked(item.slotID)

            if (isBagLocked or isInvLocked) and boeWaitTicks < 20 then
                boeWaitTicks = boeWaitTicks + 1
                if C_Timer and C_Timer.After then
                    C_Timer.After(0.15, StepEquip)
                    return
                end
            end

            idx = idx + 1
            GSI_UI:EquipUpgradeItem(item.up, item.slotID)

            if C_Timer and C_Timer.After then
                C_Timer.After(0.30, StepEquip)
            else
                StepEquip()
            end
        end

        StepEquip()
    end)
end

function GSI_UI:UpdateBiBList(parent)
    if not parent or not parent.scrollChild then return end
    local T = self.THEME or GSI_UI.THEME

    if parent.upgrades then
        parent.scanned = true
    end

    if not parent.scanned then
        if parent.equipAllBtn then parent.equipAllBtn:Hide() end
        parent.statusText:SetText("|cffffffffClick |r|cffffcc00'Optimize Gear'|r|cffffffff to scan bags for the best available gear.|r")
        for _, r in ipairs(parent.rows or {}) do r:Hide() end
        return
    end

    if GSI_UI.scanStale then
        if parent.equipAllBtn then parent.equipAllBtn:Hide() end
        parent.statusText:SetText("|cffffff00Spec / talents changed: rescanning bags with the new weights...|r")
        for _, r in ipairs(parent.rows or {}) do r:Hide() end
        return
    end

    local upgrades = parent.upgrades or {}
    local count = 0
    for _ in pairs(upgrades) do count = count + 1 end

    -- Chat line: once per scan (redraws of this tab, e.g. on every talent
    -- event, used to print the same old result again), and after an automatic
    -- rescan only when the result differs from the last one printed.
    local announce = parent.announcePending
    parent.announcePending = false
    local summary = string.format("%d:%.1f", count, parent.totalGain or 0)
    if announce and not parent.userRequestedScan and summary == GSI_UI._lastAnnouncedScan then
        announce = false
    end
    parent.userRequestedScan = nil
    if announce then GSI_UI._lastAnnouncedScan = summary end

    local timeStr = date and date("%H:%M:%S") or ""
    local scanStats = parent.scanStats
    local statsDetail = ""
    if scanStats and scanStats.equippableFound then
        statsDetail = string.format(" (%d bag items checked)", scanStats.equippableFound)
    end

    if count == 0 then
        if parent.equipAllBtn then parent.equipAllBtn:Hide() end
        parent.statusText:SetText(string.format("|cff00ff00Your current gear is already optimal!|r |cff888888[%s%s]|r", timeStr, statsDetail))
        if announce then
            print(string.format("|cffffcc00[GearSetImprover]|r Gear optimization complete: No upgrades found (gear is optimal)%s.", statsDetail))
        end
    else
        if parent.equipAllBtn then parent.equipAllBtn:Show() end
        parent.statusText:SetText(string.format("|cff00ff00%d Upgrade(s) found!|r Total Gain: |cff00ff00+%.1f GSI Score|r |cff888888[%s%s]|r", count, parent.totalGain or 0, timeStr, statsDetail))
        if announce then
            print(string.format("|cffffcc00[GearSetImprover]|r |cff00ff00%d Upgrade(s)|r found! Total gain: |cff00ff00+%.1f GSI Score|r.", count, parent.totalGain or 0))
        end
    end

    for _, r in ipairs(parent.rows) do r:Hide() end

    local yOff = 0
    local i = 1
    for slotID, up in pairs(upgrades) do
        local row = parent.rows[i]
        if not row then
            row = CreateFrame("Frame", nil, parent.scrollChild)
            row:SetSize(696, 40)
            row:EnableMouse(true)

            local div = row:CreateTexture(nil, "ARTWORK")
            div:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 4, 0)
            div:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", -4, 0)
            div:SetHeight(self:PP(1))
            div:SetColorTexture(1, 1, 1, 0.08)
            row.divider = div

            -- 3px Emerald Left Accent Bar
            row.statusBar = row:CreateTexture(nil, "OVERLAY", nil, 4)
            row.statusBar:SetSize(self:PP(3), 32)
            row.statusBar:SetPoint("LEFT", 0, 0)
            row.statusBar:SetColorTexture(unpack(T.success))

            -- Slot Name Badge
            row.slotLbl = self:CreateText(row, "SECTION", "", "LEFT")
            row.slotLbl:SetPoint("LEFT", 12, 0)
            row.slotLbl:SetWidth(94)
            row.slotLbl:SetWordWrap(false)

            -- Cropped Icon Frame
            row.iconFrame = CreateFrame("Frame", nil, row)
            row.iconFrame:SetSize(26, 26)
            row.iconFrame:SetPoint("LEFT", row.slotLbl, "RIGHT", 4, 0)
            self:ApplyMicroBorder(row.iconFrame, T.borderSpecular)

            row.icon = row.iconFrame:CreateTexture(nil, "ARTWORK")
            row.icon:SetAllPoints()
            row.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

            -- Lock Button
            row.lockBtn = CreateFrame("Button", nil, row, BACKDROP_TEMPLATE)
            row.lockBtn:SetSize(52, 24)
            row.lockBtn:SetPoint("RIGHT", -8, 0)
            self:SkinButton(row.lockBtn, nil, "SECONDARY")
            if row.lockBtn.RegisterForClicks then
                row.lockBtn:RegisterForClicks("AnyUp")
            end

            -- Equip Button (InsecureActionButtonTemplate for WoW 12.1 hardware /equipslot support)
            local eqTemplate = BACKDROP_TEMPLATE and ("InsecureActionButtonTemplate," .. BACKDROP_TEMPLATE) or "InsecureActionButtonTemplate"
            local okBtn, eqBtn = pcall(CreateFrame, "Button", nil, row, eqTemplate)
            if not okBtn or not eqBtn then
                eqBtn = CreateFrame("Button", nil, row, BACKDROP_TEMPLATE)
                eqBtn._isPlainButton = true
            end
            row.equipBtn = eqBtn
            row.equipBtn:SetSize(72, 24)
            row.equipBtn:SetPoint("RIGHT", row.lockBtn, "LEFT", -6, 0)
            row.equipBtn:SetText("Equip")
            self:SkinButton(row.equipBtn, nil, "PRIMARY")
            if row.equipBtn.SetAttribute then
                row.equipBtn:SetAttribute("useOnKeyDown", false)
            end
            if row.equipBtn.RegisterForClicks then
                row.equipBtn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
            end

            -- Delta Gain Pill
            row.deltaPill = self:CreatePill(row, "+0.0", "SUCCESS")
            row.deltaPill:SetPoint("RIGHT", row.equipBtn, "LEFT", -8, 0)

            -- Item Link / Name
            row.linkText = self:CreateText(row, "CARD_TITLE", "", "LEFT")
            row.linkText:SetPoint("LEFT", row.iconFrame, "RIGHT", 8, 0)
            row.linkText:SetPoint("RIGHT", row.deltaPill, "LEFT", -8, 0)
            row.linkText:SetWordWrap(false)

            parent.rows[i] = row
        end

        local isLocked = up.isLocked or (GearSetImproverDB and GearSetImproverDB.lockedGearSlots and GearSetImproverDB.lockedGearSlots[slotID])

        row.slotLbl:SetText(string.upper(GSI_ClassicData.SlotNames[slotID] or ("Slot " .. slotID)))
        pcall(function() row.icon:SetTexture(GetItemIcon(up.itemLink)) end)
        local qual = select(3, GetItemInfo(up.itemLink))
        local qCol = T.quality[qual or 1] or T.borderSpecular
        if row.iconFrame and row.iconFrame.SetBorderColor then
            row.iconFrame:SetBorderColor(qCol[1], qCol[2], qCol[3], 1.0)
        end

        if isLocked then
            row.lockBtn:SetText("Locked")
            if row.lockBtn.SetBorderColor then row.lockBtn:SetBorderColor(T.danger[1], T.danger[2], T.danger[3], 0.8) end
            row.deltaPill:SetPillStyle(string.format("+%.1f (LOCKED)", up.delta), "WARNING")
            row.statusBar:SetColorTexture(unpack(T.warning))
            row.equipBtn:Disable()
            row.equipBtn:SetText("Locked")
        else
            row.lockBtn:SetText("Lock")
            if row.lockBtn.SetBorderColor then row.lockBtn:SetBorderColor(T.borderSubtle[1], T.borderSubtle[2], T.borderSubtle[3], T.borderSubtle[4]) end
            row.deltaPill:SetPillStyle(string.format("+%.1f UPGRADE", up.delta), "SUCCESS")
            row.statusBar:SetColorTexture(unpack(T.success))
            row.equipBtn:Enable()
            row.equipBtn:SetText("Equip")
        end
        row.linkText:SetText((GSI_UI.ResolveItemDisplayText and GSI_UI:ResolveItemDisplayText(up.itemLink, nil, up.bag, up.slot)) or up.itemLink)

        local currentUp = up
        local currentSlotID = tonumber(slotID)
        row.lockBtn:SetScript("OnClick", function()
            if not GearSetImproverDB.lockedGearSlots then
                GearSetImproverDB.lockedGearSlots = {}
            end
            GearSetImproverDB.lockedGearSlots[currentSlotID] = not GearSetImproverDB.lockedGearSlots[currentSlotID]
            local nowLocked = GearSetImproverDB.lockedGearSlots[currentSlotID]
            local slotName = GSI_ClassicData.SlotNames[currentSlotID] or ("Slot " .. currentSlotID)
            if nowLocked then
                print(string.format("|cffffcc00[GearSetImprover]|r Slot |cff00ff00%s|r locked (will not be replaced during optimization).", slotName))
            else
                print(string.format("|cffffcc00[GearSetImprover]|r Slot |cff00ff00%s|r unlocked.", slotName))
            end
            if parent.RunOptimization then
                parent.RunOptimization()
            else
                GSI_UI:UpdateBiBList(parent)
            end
        end)
        row.lockBtn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            if isLocked then
                GameTooltip:AddLine("Slot is Locked", 1, 0.3, 0.3)
                GameTooltip:AddLine("This slot is skipped during 'Equip All'.\nClick to UNLOCK this slot.", 1, 1, 1, true)
            else
                GameTooltip:AddLine("Lock Slot", 1, 0.82, 0)
                GameTooltip:AddLine("Click to LOCK this slot.\nLocked slots will not be automatically replaced, but upgrades will still be shown.", 1, 1, 1, true)
            end
            GameTooltip:Show()
        end)
        row.lockBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

        local function TriggerAfterSingleEquip()
            local specIndex = GSI_StatWeights:GetActiveSpecIndex()
            local function FinishSingleEquip()
                GSI_UI:SaveEquipmentSetForProfile(specIndex)
                if GSI_UI.ScheduleOptimization then
                    GSI_UI:ScheduleOptimization(0.2, true)
                elseif GSI_UI.RunOptimization then
                    GSI_UI:RunOptimization()
                end
            end
            if C_Timer and C_Timer.After then
                C_Timer.After(0.35, FinishSingleEquip)
            else
                FinishSingleEquip()
            end
        end

        if row.equipBtn._isPlainButton then
            row.equipBtn:SetScript("OnClick", function()
                if IsBindConfirmPopupOpen() then
                    if UIErrorsFrame and UIErrorsFrame.AddMessage then
                        UIErrorsFrame:AddMessage("GSI: Confirm or cancel the open bind/trade dialog first", 1.0, 0.82, 0.0, 1.0)
                    end
                    return
                end
                if GSI_UI:EquipUpgradeItem(currentUp, currentSlotID) then
                    TriggerAfterSingleEquip()
                end
            end)
        else
            row.equipBtn:SetScript("PreClick", function(selfBtn, button, down)
                if down then return end
                selfBtn._blockedByBindPopup = nil
                if InCombatLockdown and InCombatLockdown() then return end
                if IsBindConfirmPopupOpen() then
                    selfBtn._blockedByBindPopup = true
                    selfBtn:SetAttribute("type", nil)
                    selfBtn:SetAttribute("macrotext", nil)
                    return
                end
                local idNum = currentUp and currentUp.itemLink and tonumber(currentUp.itemLink:match("item:(%d+)"))
                local isMultiSlot = (currentSlotID == 11 or currentSlotID == 12
                                  or currentSlotID == 13 or currentSlotID == 14
                                  or currentSlotID == 16 or currentSlotID == 17)
                local bagCopies = idNum and CountBagCopiesByID(idNum) or 1
                GSI_UI.activeEquipTargetSlot = currentSlotID
                GSI_UI._userInitiatedEquipUntil = ((GetTime and GetTime()) or 0) + 0.6
                if not isMultiSlot and bagCopies <= 1 and currentSlotID and idNum then
                    local macroText = string.format("/equipslot %d item:%d", currentSlotID, idNum)
                    selfBtn:SetAttribute("type", "macro")
                    selfBtn:SetAttribute("macrotext", macroText)
                else
                    selfBtn:SetAttribute("type", nil)
                    selfBtn:SetAttribute("macrotext", nil)
                end
            end)
            row.equipBtn:SetScript("PostClick", function(selfBtn, button, down)
                if down then return end
                local wasBlocked = selfBtn._blockedByBindPopup
                selfBtn._blockedByBindPopup = nil
                if not (InCombatLockdown and InCombatLockdown()) then
                    selfBtn:SetAttribute("type", nil)
                    selfBtn:SetAttribute("macrotext", nil)
                end
                if wasBlocked then
                    if UIErrorsFrame and UIErrorsFrame.AddMessage then
                        UIErrorsFrame:AddMessage("GSI: Confirm or cancel the open bind/trade dialog first", 1.0, 0.82, 0.0, 1.0)
                    end
                    return
                end
                if IsBindConfirmPopupOpen() then
                    if not IsTradeableBindPopupOpen() then
                        ConfirmPendingBind(currentSlotID)
                    end
                    TriggerAfterSingleEquip()
                    return
                end
                if GSI_UI:EquipUpgradeItem(currentUp, currentSlotID) then
                    TriggerAfterSingleEquip()
                end
            end)
        end

        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", parent.scrollChild, "TOPLEFT", 0, -yOff)
        row:Show()

        row:SetScript("OnEnter", function(self)
            if self.divider then self.divider:SetColorTexture(1, 1, 1, 0.20) end
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetHyperlink(up.itemLink)
            GameTooltip:Show()
        end)
        row:SetScript("OnLeave", function(self)
            if self.divider then self.divider:SetColorTexture(1, 1, 1, 0.08) end
            GameTooltip:Hide()
        end)

        yOff = yOff + 40
        i = i + 1
    end
    parent.scrollChild:SetHeight(math.max(yOff, 10))
end

-- ---------------------------------------------------------------
