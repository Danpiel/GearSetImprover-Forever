-- ============================================================
-- GearSetImprover -- UI_Tab_BiB.lua (WoW Forever)
-- ============================================================

GSI_UI = GSI_UI or {}

local GetItemInfo = (C_Item and C_Item.GetItemInfo) or _G.GetItemInfo or function() return nil end
local GetItemInfoInstant = (C_Item and C_Item.GetItemInfoInstant) or _G.GetItemInfoInstant or function() return nil end
local GetItemIcon = _G.GSI_GetItemIcon or _G.GetItemIcon or function() return "Interface\\Icons\\INV_Misc_QuestionMark" end
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

-- TAB 2: BEST AVAILABLE
-- ---------------------------------------------------------------
local function GetBagSlotGUID(bag, slot)
    if bag == nil or slot == nil then return nil end
    if C_Container and C_Container.GetContainerItemInfo then
        local info = C_Container.GetContainerItemInfo(bag, slot)
        if info and info.itemGUID then
            return info.itemGUID
        end
    end
    return nil
end

local function CountBagCopiesByID(targetIDNum)
    if not targetIDNum then return 0 end
    local getSlotsFn = (C_Container and C_Container.GetContainerNumSlots) or GetContainerNumSlots
    local getLinkFn = (C_Container and C_Container.GetContainerItemLink) or GetContainerItemLink
    if not getSlotsFn then return 0 end
    local count = 0
    local maxBags = NUM_BAG_SLOTS or 5
    for b = 0, maxBags do
        local numSlots = getSlotsFn(b) or 0
        for s = 1, numSlots do
            local id = nil
            if C_Container and C_Container.GetContainerItemID then
                id = C_Container.GetContainerItemID(b, s)
            elseif getLinkFn then
                local l = getLinkFn(b, s)
                id = l and tonumber(l:match("item:(%d+)"))
            end
            if id and id == targetIDNum then
                count = count + 1
            end
        end
    end
    return count
end

-- Helper: Checks if the expected item is still at (bag, slot),
-- otherwise searches for it dynamically in bags (important when equipping 2 rings sequentially!)
local function ResolveUpgradeBagSlot(up)
    if not up or not up.itemLink then return up and up.bag, up and up.slot end
    local getLinkFn = (C_Container and C_Container.GetContainerItemLink) or GetContainerItemLink
    local getSlotsFn = (C_Container and C_Container.GetContainerNumSlots) or GetContainerNumSlots
    if not getLinkFn or not getSlotsFn then
        return up.bag, up.slot
    end

    local targetLink = up.itemLink
    local targetID = targetLink and targetLink:match("item:(%d+)")
    local targetGUID = up.itemGUID
    local maxBags = NUM_BAG_SLOTS or 5

    -- 0. Check by unique ItemGUID (if available)
    if targetGUID then
        for b = 0, maxBags do
            local numSlots = getSlotsFn(b) or 0
            for s = 1, numSlots do
                if GetBagSlotGUID(b, s) == targetGUID then
                    return b, s
                end
            end
        end
    end

    -- 1. Check if the item is still at the cached bag/slot
    if up.bag ~= nil and up.slot ~= nil then
        local currentLink = getLinkFn(up.bag, up.slot)
        if currentLink then
            if currentLink == targetLink or (targetID and currentLink:match("item:(%d+)") == targetID) then
                return up.bag, up.slot
            end
        end
    end

    -- 2. Fallback: Search bags by exact item link
    for b = 0, maxBags do
        local numSlots = getSlotsFn(b) or 0
        for s = 1, numSlots do
            local link = getLinkFn(b, s)
            if link and link == targetLink then
                return b, s
            end
        end
    end

    -- 3. Fallback: Search bags by ItemID
    if targetID then
        for b = 0, maxBags do
            local numSlots = getSlotsFn(b) or 0
            for s = 1, numSlots do
                local link = getLinkFn(b, s)
                if link and link:match("item:(%d+)") == targetID then
                    return b, s
                end
            end
        end
    end

    return up.bag, up.slot
end

local activeTradeableConfirmUntil = 0

local function ScanStaticPopupsFor(matchFn)
    local maxDialogs = STATICPOPUP_NUMDIALOGS or 4
    for i = 1, maxDialogs do
        local popup = _G["StaticPopup" .. i]
        if popup and popup:IsShown() and popup.which and matchFn(popup.which) then
            return true
        end
    end
    return false
end

-- Checks specifically if a dungeon-tradeable or vendor-refundable bind popup is open
local function IsTradeableBindPopupOpen()
    local now = (GetTime and GetTime()) or 0
    if now < activeTradeableConfirmUntil then
        return true
    end
    if StaticPopup_Visible then
        if StaticPopup_Visible("EQUIP_BIND_TRADEABLE")
            or StaticPopup_Visible("EQUIP_BIND_REFUNDABLE")
            or StaticPopup_Visible("LOOT_BIND_CONFIRM") then
            return true
        end
    end
    return ScanStaticPopupsFor(function(which)
        return which:find("TRADEABLE", 1, true)
            or which:find("REFUNDABLE", 1, true)
            or which:find("LOOT_BIND", 1, true)
    end)
end

-- Checks if any BoE or tradeable/refundable bind confirmation popup is currently visible
local function IsBindConfirmPopupOpen()
    if IsTradeableBindPopupOpen() then
        return true
    end
    if StaticPopup_Visible then
        if StaticPopup_Visible("EQUIP_BIND")
            or StaticPopup_Visible("AUTOEQUIP_BIND")
            or StaticPopup_Visible("USE_BIND")
            or StaticPopup_Visible("BIND_ENCHANT") then
            return true
        end
    end
    return ScanStaticPopupsFor(function(which)
        return which:find("EQUIP_BIND", 1, true)
            or which:find("AUTOEQUIP_BIND", 1, true)
            or which:find("USE_BIND", 1, true)
    end)
end

local function IsBagSlotLocked(bag, slot)
    if bag == nil or slot == nil then return false end
    if C_Container and C_Container.GetContainerItemInfo then
        local info = C_Container.GetContainerItemInfo(bag, slot)
        return info and info.isLocked or false
    elseif GetContainerItemInfo then
        local _, _, locked = GetContainerItemInfo(bag, slot)
        return locked or false
    end
    return false
end

-- Scoped bind listener: ONLY confirms regular BoE prompts initiated directly by GSI clicks,
-- and NEVER suppresses or auto-confirms tradeable/refundable dungeon loot prompts!
local gsi_equipListener = CreateFrame("Frame")
pcall(function() gsi_equipListener:RegisterEvent("EQUIP_BIND_TRADEABLE_CONFIRM") end)
pcall(function() gsi_equipListener:RegisterEvent("EQUIP_BIND_CONFIRM") end)
pcall(function() gsi_equipListener:RegisterEvent("AUTOEQUIP_BIND_CONFIRM") end)
pcall(function() gsi_equipListener:RegisterEvent("EQUIP_BIND") end)
pcall(function() gsi_equipListener:RegisterEvent("AUTOEQUIP_BIND") end)

local function ConfirmPendingBind(targetSlotID)
    if IsTradeableBindPopupOpen() then
        return false
    end
    local now = (GetTime and GetTime()) or 0
    if not (GSI_UI and GSI_UI.activeEquipTargetSlot and now <= (GSI_UI._userInitiatedEquipUntil or 0)) then
        return false
    end
    local slotToConfirm = tonumber(targetSlotID) or GSI_UI.activeEquipTargetSlot
    if slotToConfirm and _G.EquipPendingItem then
        pcall(function() _G.EquipPendingItem(slotToConfirm) end)
        return true
    end
    return false
end

gsi_equipListener:SetScript("OnEvent", function(self, event, arg1)
    if event == "EQUIP_BIND_TRADEABLE_CONFIRM" then
        activeTradeableConfirmUntil = ((GetTime and GetTime()) or 0) + 2.0
        return
    end
    local now = (GetTime and GetTime()) or 0
    if not (GSI_UI and GSI_UI.activeEquipTargetSlot and now <= (GSI_UI._userInitiatedEquipUntil or 0)) then
        return
    end
    if IsTradeableBindPopupOpen() then
        return
    end
    local pendingSlot = tonumber(arg1 or _G.arg1) or GSI_UI.activeEquipTargetSlot
    if pendingSlot == GSI_UI.activeEquipTargetSlot then
        ConfirmPendingBind(pendingSlot)
    end
end)

-- Note for WoW Forever 12.1 (TOC 16001):
-- C_Container.UseContainerItem is protected against addon Lua for equip actions (ADDON_ACTION_FORBIDDEN)
-- and silently returns nil without throwing a Lua error. Therefore only C_Item.EquipItemByName
-- (with lock/slot verification) and PickupContainerItem + EquipCursorItem are used!
function GSI_UI:EquipUpgradeItem(up, targetSlotID)
    if InCombatLockdown and InCombatLockdown() then
        print("|cffff0000[GearSetImprover]|r Items cannot be swapped in combat!")
        return false
    end

    if not up or not up.itemLink then return false end
    targetSlotID = tonumber(targetSlotID or up.slotID)
    GSI_UI._userInitiatedEquipUntil = ((GetTime and GetTime()) or 0) + 0.6

    local bag, slot = ResolveUpgradeBagSlot(up)
    local link = up.itemLink
    local idNum = tonumber(link:match("item:(%d+)"))

    -- If already equipped (e.g., via hardware macro in PreClick), report success immediately
    if targetSlotID and idNum and GetInventoryItemID and GetInventoryItemID("player", targetSlotID) == idNum then
        return true
    end
    if IsBindConfirmPopupOpen() then
        return true
    end
    if bag ~= nil and slot ~= nil and IsBagSlotLocked(bag, slot) then
        return true
    end

    -- Pre-check: Can the player actually equip this item?
    if GSI_OptimizationEngine and GSI_OptimizationEngine.IsItemUsableForPlayer and not GSI_OptimizationEngine:IsItemUsableForPlayer(link, bag, slot) then
        print(string.format("|cffff0000[GearSetImprover]|r Skipped %s: requirements not met for your character!", link or "item"))
        return false
    end

    local equipped = false
    local isMultiSlot = (targetSlotID == 11 or targetSlotID == 12
                      or targetSlotID == 13 or targetSlotID == 14
                      or targetSlotID == 16 or targetSlotID == 17)
    local bagCopies = idNum and CountBagCopiesByID(idNum) or 1

    -- METHOD 1: For unique single slots (Head, Neck, Shoulders, Chest, Back, etc.) without duplicate bag copies:
    -- Use C_Item.EquipItemByName and then verify that the swap actually started!
    if not isMultiSlot and bagCopies <= 1 and (link or idNum) then
        local equipFn = (C_Item and C_Item.EquipItemByName) or EquipItemByName
        if equipFn then
            GSI_UI.activeEquipTargetSlot = targetSlotID
            local ok = pcall(function() equipFn(idNum and ("item:" .. idNum) or link, targetSlotID) end)
            if ok then
                if IsBindConfirmPopupOpen() and not IsTradeableBindPopupOpen() then
                    ConfirmPendingBind(targetSlotID)
                end
                if IsBindConfirmPopupOpen()
                    or (bag ~= nil and slot ~= nil and IsBagSlotLocked(bag, slot))
                    or (targetSlotID and idNum and GetInventoryItemID and GetInventoryItemID("player", targetSlotID) == idNum) then
                    equipped = true
                end
            end
        end
    end

    -- METHOD 2: Direct, slot-accurate cursor swap (primary for multi-slots 11/12, 13/14, 16/17 or immediate fallback)
    if not equipped and not IsBindConfirmPopupOpen() and bag ~= nil and slot ~= nil and targetSlotID then
        local pickupFn = (C_Container and C_Container.PickupContainerItem) or PickupContainerItem
        if pickupFn and EquipCursorItem then
            if ClearCursor then ClearCursor() end
            pickupFn(bag, slot)
            if CursorHasItem and CursorHasItem() then
                GSI_UI.activeEquipTargetSlot = targetSlotID
                EquipCursorItem(targetSlotID)

                if IsBindConfirmPopupOpen() then
                    if not IsTradeableBindPopupOpen() then
                        ConfirmPendingBind(targetSlotID)
                    end
                    equipped = true
                end

                if not IsBindConfirmPopupOpen() and CursorHasItem and CursorHasItem() then
                    local cType, cItemID = nil, nil
                    if GetCursorInfo then
                        cType, cItemID = GetCursorInfo()
                    end
                    if cType == "item" and idNum and cItemID ~= idNum then
                        pickupFn(bag, slot)
                        if not IsBindConfirmPopupOpen() and CursorHasItem and CursorHasItem() and ClearCursor then
                            ClearCursor()
                        end
                    elseif C_Timer and C_Timer.After then
                        local savedBag, savedSlot, savedId = bag, slot, idNum
                        C_Timer.After(0.12, function()
                            if IsBindConfirmPopupOpen() then return end
                            if CursorHasItem and CursorHasItem() then
                                local t2, id2 = nil, nil
                                if GetCursorInfo then t2, id2 = GetCursorInfo() end
                                if t2 == "item" and savedId and id2 ~= savedId then
                                    pickupFn(savedBag, savedSlot)
                                end
                                if not IsBindConfirmPopupOpen() and CursorHasItem and CursorHasItem() and ClearCursor then
                                    ClearCursor()
                                end
                            end
                        end)
                    end
                end
                equipped = true
            end
        end
    end

    if C_Timer and C_Timer.After then
        C_Timer.After(0.25, function()
            GSI_UI.activeEquipTargetSlot = nil
        end)
    else
        GSI_UI.activeEquipTargetSlot = nil
    end

    if equipped then
        pcall(function()
            if PlaySound then
                PlaySound(SOUNDKIT and SOUNDKIT.IG_CHARACTER_INFO_TAB or 841)
            end
        end)
        print(string.format("|cffffcc00[GearSetImprover]|r Equipped: %s (Slot %d)", link, targetSlotID or 0))
        return true
    end

    return false
end

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

    local ok, err = pcall(function()
        GSI_OptimizationEngine:OptimizeBagGearAsync(nil, function(bestSetup, bestScore, upgrades, totalGain, scanStats)
            GSI_UI.isOptimizing = false
            GSI_UI.lastScanned = true
            GSI_UI.lastUpgrades = upgrades
            GSI_UI.lastTotalGain = totalGain
            GSI_UI.lastScanStats = scanStats

            if bibFrame then
                bibFrame.scanned = true
                bibFrame.upgrades = upgrades
                bibFrame.totalGain = totalGain
                bibFrame.scanStats = scanStats
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

    -- Status Bar Card
    local statusCard = CreateFrame("Frame", nil, parent, BACKDROP_TEMPLATE)
    statusCard:SetPoint("TOPLEFT", sub, "BOTTOMLEFT", -2, -8)
    statusCard:SetPoint("RIGHT", -20, 0)
    statusCard:SetHeight(28)
    self:SkinCard(statusCard, false)
    parent.statusCard = statusCard

    local status = self:CreateText(statusCard, "BODY", "Click 'Optimize Gear' to scan bags for the best available gear.", "LEFT")
    status:SetPoint("LEFT", 12, 0)
    status:SetPoint("RIGHT", statusCard, "RIGHT", -12, 0)
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

    local upgrades = parent.upgrades or {}
    local count = 0
    for _ in pairs(upgrades) do count = count + 1 end

    local timeStr = date and date("%H:%M:%S") or ""
    local scanStats = parent.scanStats
    local statsDetail = ""
    if scanStats and scanStats.equippableFound then
        statsDetail = string.format(" (%d bag items checked)", scanStats.equippableFound)
    end

    if count == 0 then
        if parent.equipAllBtn then parent.equipAllBtn:Hide() end
        parent.statusText:SetText(string.format("|cff00ff00Your current gear is already optimal!|r |cff888888[%s%s]|r", timeStr, statsDetail))
        print(string.format("|cffffcc00[GearSetImprover]|r Gear optimization complete: No upgrades found (gear is optimal)%s.", statsDetail))
    else
        if parent.equipAllBtn then parent.equipAllBtn:Show() end
        parent.statusText:SetText(string.format("|cff00ff00%d Upgrade(s) found!|r Total Gain: |cff00ff00+%.1f GSI Score|r |cff888888[%s%s]|r", count, parent.totalGain or 0, timeStr, statsDetail))
        print(string.format("|cffffcc00[GearSetImprover]|r |cff00ff00%d Upgrade(s)|r found! Total gain: |cff00ff00+%.1f GSI Score|r.", count, parent.totalGain or 0))
    end

    for _, r in ipairs(parent.rows) do r:Hide() end

    local yOff = 0
    local i = 1
    for slotID, up in pairs(upgrades) do
        local row = parent.rows[i]
        if not row then
            row = CreateFrame("Frame", nil, parent.scrollChild, BACKDROP_TEMPLATE)
            row:SetSize(696, 40)
            self:SkinCard(row, true)

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
        row.linkText:SetText(up.itemLink)

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
            self:SetBackdropColor(0.11, 0.11, 0.14, 0.95)
            self:SetBackdropBorderColor(0.24, 0.24, 0.32, 1.0)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetHyperlink(up.itemLink)
            GameTooltip:Show()
        end)
        row:SetScript("OnLeave", function(self)
            self:SetBackdropColor(0.078, 0.078, 0.098, 0.85)
            self:SetBackdropBorderColor(0.11, 0.11, 0.14, 1.0)
            GameTooltip:Hide()
        end)

        yOff = yOff + 40
        i = i + 1
    end
    parent.scrollChild:SetHeight(math.max(yOff, 10))
end

-- ---------------------------------------------------------------
