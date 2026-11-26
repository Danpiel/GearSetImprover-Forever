-- ============================================================
-- GearSetImprover - EquipManager.lua (WoW Forever 1.60.1)
-- Shared bag/GUID lookup, bind/trade popup guards, and
-- hardware-safe /equipslot + cursor equip logic for BiB & Toast.
-- ============================================================

GSI_EquipManager = GSI_EquipManager or {}

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

-- Expose shared helpers on GSI_EquipManager
GSI_EquipManager.IsTradeableBindPopupOpen = IsTradeableBindPopupOpen
GSI_EquipManager.IsBindConfirmPopupOpen = IsBindConfirmPopupOpen
GSI_EquipManager.ConfirmPendingBind = ConfirmPendingBind
GSI_EquipManager.CountBagCopiesByID = CountBagCopiesByID
GSI_EquipManager.ResolveUpgradeBagSlot = ResolveUpgradeBagSlot
GSI_EquipManager.IsBagSlotLocked = IsBagSlotLocked
function GSI_EquipManager:EquipUpgradeItem(up, targetSlotID)
    return GSI_UI:EquipUpgradeItem(up, targetSlotID)
end
