-- ============================================================
-- GearSetImprover - UpgradeToast.lua (WoW Forever)
-- Compact animated Toaster HUD notification for gear upgrades:
--  - Compact 348x68 slate glass card with quality rail & emerald score pill
--  - Direction-aware cubic ease-out slide + fade toaster entrance & exit
--  - Smooth bottom duration progress bar & hover pause
--  - Tradeable/refundable dungeon item safe (never suppresses EQUIP_BIND_TRADEABLE)
--  - WoW 12.1 (TOC 16001) InsecureActionButtonTemplate hardware-click equipping
-- ============================================================

GSI_UpgradeToast = {}
local GSI_UpgradeToast = GSI_UpgradeToast

local TEXTURE_FILE = "Interface\\AddOns\\GearSetImprover\\Textures\\LootUI.png"
local ICON_BORDER_FILE = "Interface\\AddOns\\GearSetImprover\\Textures\\IconBorder-Square.png"
local ICON_OVERLAY_FILE = "Interface\\AddOns\\GearSetImprover\\Textures\\IconOverlay.png"
local FONT_FILE = (GSI_UI and GSI_UI.FONT_PATH) or "Interface\\AddOns\\GearSetImprover\\Fonts\\Expressway.ttf"

local TOAST_WIDTH = 348
local TOAST_HEIGHT = 68
local TOAST_DEFAULT_Y = -110
local ENTER_DURATION = 0.26
local EXIT_DURATION = 0.22
local SLIDE_DISTANCE = 20

local print = function(...)
    if GSI_Print then
        GSI_Print(...)
    elseif not (GearSetImproverDB and (GearSetImproverDB.disableChatOutput or GearSetImproverDB.disableChat)) then
        _G.print(...)
    end
end

local BACKDROP_BORDERLESS = {
    bgFile = "Interface\\Buttons\\WHITE8x8",
    tile = false,
    insets = { left = 0, right = 0, top = 0, bottom = 0 }
}

local toastFrame = nil
local anchorFrame = nil
local toastQueue = {}
local currentToast = nil
local isPaused = false
local isDismissing = false
local remainingTime = 60
local totalDuration = 60
local animState = "idle" -- "idle" | "entering" | "active" | "exiting"
local animStateElapsed = 0
local slideStartX, slideStartY = 0, 18
local slideExitX, slideExitY = 0, 14
local animStartAlpha = 1.0
local activeTradeableConfirmUntil = 0
local bagSnapshot = {}
local equippedSnapshot = { guids = {}, slotGuids = {}, slotIds = {} }
local recentlyUnequipped = { guids = {}, ids = {} }
local pendingCacheQueue = {}
local recentNotified = {}
local isInitialized = false
local pendingCombatToast = nil
local verifyGeneration = 0

-- ------------------------------------------------------------
-- CONTAINER, ITEM GUID & EQUIPMENT HELPERS (WoW Forever 12.1 / 16001)
-- Note: Never use C_Container.UseContainerItem for equipping gear in 12.1;
-- it is protected (ADDON_ACTION_FORBIDDEN) and silently returns nil without Lua error.
-- ------------------------------------------------------------
local function GetMaxBagIndex()
    return NUM_BAG_SLOTS or 5
end

local function GetNumBagSlots(bag)
    if C_Container and C_Container.GetContainerNumSlots then
        return C_Container.GetContainerNumSlots(bag) or 0
    elseif GetContainerNumSlots then
        return GetContainerNumSlots(bag) or 0
    end
    return 0
end

local function GetBagItemLink(bag, slot)
    if bag == nil or slot == nil then return nil end
    if C_Container and C_Container.GetContainerItemLink then
        return C_Container.GetContainerItemLink(bag, slot)
    elseif GetContainerItemLink then
        return GetContainerItemLink(bag, slot)
    end
    return nil
end

local function GetBagSlotItemID(bag, slot)
    if bag == nil or slot == nil then return nil end
    if C_Container and C_Container.GetContainerItemID then
        local id = C_Container.GetContainerItemID(bag, slot)
        if id and id > 0 then return id end
    end
    if C_Container and C_Container.GetContainerItemInfo then
        local info = C_Container.GetContainerItemInfo(bag, slot)
        if info and info.itemID and info.itemID > 0 then return info.itemID end
    end
    local link = GetBagItemLink(bag, slot)
    return link and tonumber(link:match("item:(%d+)")) or nil
end

local function GetBagSlotGUID(bag, slot)
    if bag == nil or slot == nil then return nil end
    if C_Container and C_Container.GetContainerItemInfo then
        local info = C_Container.GetContainerItemInfo(bag, slot)
        if info and info.itemGUID then
            return info.itemGUID
        end
    end
    if ItemLocation and ItemLocation.CreateFromBagAndSlot and C_Item and C_Item.DoesItemExist and C_Item.GetItemGUID then
        local ok, guid = pcall(function()
            local loc = ItemLocation:CreateFromBagAndSlot(bag, slot)
            if loc and C_Item.DoesItemExist(loc) then
                return C_Item.GetItemGUID(loc)
            end
            return nil
        end)
        if ok and guid then return guid end
    end
    return nil
end

local function GetEquippedSlotGUID(slotID)
    if not slotID then return nil end
    if ItemLocation and ItemLocation.CreateFromEquipmentSlot and C_Item and C_Item.DoesItemExist and C_Item.GetItemGUID then
        local ok, guid = pcall(function()
            local loc = ItemLocation:CreateFromEquipmentSlot(slotID)
            if loc and C_Item.DoesItemExist(loc) then
                return C_Item.GetItemGUID(loc)
            end
            return nil
        end)
        if ok and guid then return guid end
    end
    return nil
end

local function GetEquippedSlotItemID(slotID)
    if not slotID then return nil end
    if GetInventoryItemID then
        local id = GetInventoryItemID("player", slotID)
        if id and id > 0 then return id end
    end
    local eqLink = GetInventoryItemLink and GetInventoryItemLink("player", slotID)
    return eqLink and tonumber(eqLink:match("item:(%d+)")) or nil
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

local function PickupBagItem(bag, slot)
    if C_Container and C_Container.PickupContainerItem then
        C_Container.PickupContainerItem(bag, slot)
    elseif PickupContainerItem then
        PickupContainerItem(bag, slot)
    end
end

local function PlayEquipSuccessSound()
    pcall(function()
        if SOUNDKIT and SOUNDKIT.IG_CHARACTER_INFO_TAB then
            PlaySound(SOUNDKIT.IG_CHARACTER_INFO_TAB)
        elseif PlaySound then
            PlaySound(841)
        end
    end)
end

local function IsInCombat()
    return (InCombatLockdown and InCombatLockdown()) or (UnitAffectingCombat and UnitAffectingCombat("player")) or false
end

local function IsMultiTargetSlot(slotID)
    return (slotID == 11 or slotID == 12
         or slotID == 13 or slotID == 14
         or slotID == 16 or slotID == 17)
end

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

-- Checks specifically if a dungeon-tradeable or vendor-refundable prompt is active
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

-- Checks if ANY bind or dungeon-tradeable/refundable confirmation popup is currently open
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

-- Scoped BoE listener: confirms regular BoE prompts ONLY during a GSI toast equip click,
-- and NEVER suppresses or auto-confirms dungeon-tradeable/refundable prompts!
local function ConfirmPendingBind(targetSlotID)
    if IsTradeableBindPopupOpen() then
        return false
    end
    local now = (GetTime and GetTime()) or 0
    if not (GSI_UpgradeToast.isEquippingSlot and now <= (GSI_UpgradeToast._userInitiatedEquipUntil or 0)) then
        return false
    end
    local slotToConfirm = tonumber(targetSlotID) or GSI_UpgradeToast.isEquippingSlot
    if slotToConfirm and _G.EquipPendingItem then
        pcall(function() _G.EquipPendingItem(slotToConfirm) end)
        return true
    end
    return false
end

local toastBindListener = CreateFrame("Frame")
pcall(function() toastBindListener:RegisterEvent("EQUIP_BIND_TRADEABLE_CONFIRM") end)
pcall(function() toastBindListener:RegisterEvent("EQUIP_BIND_CONFIRM") end)
pcall(function() toastBindListener:RegisterEvent("AUTOEQUIP_BIND_CONFIRM") end)
pcall(function() toastBindListener:RegisterEvent("EQUIP_BIND") end)
pcall(function() toastBindListener:RegisterEvent("AUTOEQUIP_BIND") end)
toastBindListener:SetScript("OnEvent", function(self, event, arg1)
    if event == "EQUIP_BIND_TRADEABLE_CONFIRM" then
        activeTradeableConfirmUntil = ((GetTime and GetTime()) or 0) + 2.0
        if currentToast and currentToast._equipClicked then
            currentToast._awaitingBindConfirm = true
            currentToast._equipPendingUntil = ((GetTime and GetTime()) or 0) + 60.0
        end
        return
    end
    local now = (GetTime and GetTime()) or 0
    if not (GSI_UpgradeToast.isEquippingSlot and now <= (GSI_UpgradeToast._userInitiatedEquipUntil or 0)) then
        return
    end
    if IsTradeableBindPopupOpen() then
        if currentToast and currentToast._equipClicked then
            currentToast._awaitingBindConfirm = true
            currentToast._equipPendingUntil = now + 60.0
        end
        return
    end
    local pendingSlot = tonumber(arg1 or _G.arg1) or GSI_UpgradeToast.isEquippingSlot
    if pendingSlot == GSI_UpgradeToast.isEquippingSlot then
        ConfirmPendingBind(pendingSlot)
    end
end)

-- ------------------------------------------------------------
-- BAG LOOKUP & SNAPSHOT HELPERS
-- ------------------------------------------------------------
local function FindBagSlotByGUID(targetGUID)
    if not targetGUID then return nil, nil end
    local maxBags = GetMaxBagIndex()
    for bag = 0, maxBags do
        local numSlots = GetNumBagSlots(bag)
        for slot = 1, numSlots do
            local guid = GetBagSlotGUID(bag, slot)
            if guid and guid == targetGUID then
                return bag, slot
            end
        end
    end
    return nil, nil
end

local function CountItemIDInBags(targetID)
    if not targetID then return 0 end
    local count = 0
    local maxBags = GetMaxBagIndex()
    for bag = 0, maxBags do
        local numSlots = GetNumBagSlots(bag)
        for slot = 1, numSlots do
            if GetBagSlotItemID(bag, slot) == targetID then
                count = count + 1
            end
        end
    end
    return count
end

local function FindItemInBags(targetGUID, targetLink, targetID)
    if targetGUID then
        local gBag, gSlot = FindBagSlotByGUID(targetGUID)
        if gBag ~= nil and gSlot ~= nil then
            return gBag, gSlot
        end
    end

    if not targetLink and not targetID then return nil, nil end
    local targetIDNum = targetID or (targetLink and tonumber(targetLink:match("item:(%d+)")))
    local maxBags = GetMaxBagIndex()

    -- First pass: exact link match
    if targetLink then
        for bag = 0, maxBags do
            local numSlots = GetNumBagSlots(bag)
            for slot = 1, numSlots do
                local link = GetBagItemLink(bag, slot)
                if link and link == targetLink then
                    return bag, slot
                end
            end
        end
    end

    -- Second pass: itemID match (only if targetGUID wasn't pinned to a missing item, or as fallback)
    if targetIDNum then
        for bag = 0, maxBags do
            local numSlots = GetNumBagSlots(bag)
            for slot = 1, numSlots do
                if GetBagSlotItemID(bag, slot) == targetIDNum then
                    return bag, slot
                end
            end
        end
    end

    return nil, nil
end

local function ResolveToastTargetSlot(toastData)
    if not toastData then return nil end
    local targetSlotID = tonumber(toastData.targetSlotID or toastData.bestSlotID)
    if targetSlotID then return targetSlotID end

    local link = toastData.itemLink or toastData.link
    local idNum = toastData.idNum or (link and tonumber(link:match("item:(%d+)")))
    local equipLoc = nil
    if link and GetItemInfo then
        equipLoc = select(9, GetItemInfo(link))
    end
    if (not equipLoc or equipLoc == "") and (link or idNum) then
        local instantFn = (C_Item and C_Item.GetItemInfoInstant) or GetItemInfoInstant
        if instantFn then
            equipLoc = select(4, instantFn(link or idNum))
        end
    end
    if equipLoc and GSI_ClassicData and GSI_ClassicData.EquipLocToSlot then
        targetSlotID = GSI_ClassicData.EquipLocToSlot[equipLoc]
        toastData.targetSlotID = targetSlotID
    end
    return targetSlotID
end

-- Refresh snapshot of currently equipped items so swapped-out gear landing in bags
-- is never mistaken for freshly looted upgrades
local function UpdateEquippedSnapshot(changedSlot)
    local now = (GetTime and GetTime()) or 0
    if changedSlot then
        local prevGuid = equippedSnapshot.slotGuids[changedSlot]
        local prevId = equippedSnapshot.slotIds[changedSlot]
        local curGuid = GetEquippedSlotGUID(changedSlot)
        local curId = GetEquippedSlotItemID(changedSlot)
        if prevGuid and prevGuid ~= curGuid then
            recentlyUnequipped.guids[prevGuid] = now
        end
        if prevId and prevId ~= curId then
            recentlyUnequipped.ids[prevId] = now
        end
    end

    local guids = {}
    local slotGuids = {}
    local slotIds = {}
    for sID = 1, 19 do
        local guid = GetEquippedSlotGUID(sID)
        local id = GetEquippedSlotItemID(sID)
        if guid then
            guids[guid] = true
            slotGuids[sID] = guid
        end
        if id then
            slotIds[sID] = id
        end
    end
    equippedSnapshot.guids = guids
    equippedSnapshot.slotGuids = slotGuids
    equippedSnapshot.slotIds = slotIds
end

local function IsRecentlyUnequipped(guid, idNum)
    local now = (GetTime and GetTime()) or 0
    if guid then
        if equippedSnapshot.guids and equippedSnapshot.guids[guid] then
            return true
        end
        local t = recentlyUnequipped.guids[guid]
        if t and (now - t) < 5.0 then
            return true
        end
    elseif idNum then
        local t = recentlyUnequipped.ids[idNum]
        if t and (now - t) < 3.0 then
            return true
        end
    end
    return false
end

-- ------------------------------------------------------------
-- MODERN FONT HELPER (Expressway with GameFont fallbacks)
-- ------------------------------------------------------------
local function ApplyFont(fontString, size, flags, shadow)
    local fontPath = (GSI_UI and GSI_UI:GetFontPath()) or FONT_FILE or "Interface\\AddOns\\GearSetImprover\\Fonts\\Expressway.ttf"
    local loaded = false
    if fontPath then
        loaded = pcall(function()
            fontString:SetFont(fontPath, size, flags or "OUTLINE")
        end)
    end
    if not loaded or not fontString:GetFont() then
        local base = (size >= 14) and GameFontNormalLarge or ((size >= 12) and GameFontNormal or GameFontNormalSmall)
        local fName, _, fFlags = base:GetFont()
        fontString:SetFont(fName, size, flags or fFlags or "OUTLINE")
    end
    if shadow ~= false then
        fontString:SetShadowOffset(1, -1)
        fontString:SetShadowColor(0, 0, 0, 0.95)
    else
        fontString:SetShadowOffset(0, 0)
    end
end

-- Sound helper
local function PlayAlertSound()
    local db = GearSetImproverDB
    if db and db.toastPlaySound == false then return end
    pcall(function()
        if SOUNDKIT and SOUNDKIT.UI_EPICLOOT_TOAST then
            PlaySound(SOUNDKIT.UI_EPICLOOT_TOAST)
        elseif SOUNDKIT and SOUNDKIT.IG_BONUS_ROLL_LOOT then
            PlaySound(SOUNDKIT.IG_BONUS_ROLL_LOOT)
        else
            PlaySound(SOUNDKIT and SOUNDKIT.IG_QUEST_LOG_OPEN or 624)
        end
    end)
end

-- Position & Slide Direction helpers
local function SavePosition(f)
    if not GearSetImproverDB then GearSetImproverDB = {} end
    local point, _, relPoint, x, y = f:GetPoint()
    GearSetImproverDB.toastAnchor = {
        point = point or "TOP",
        relPoint = relPoint or "TOP",
        x = math.floor(x or 0),
        y = math.floor(y or TOAST_DEFAULT_Y)
    }
end

local function ApplySavedPosition(f)
    local db = GearSetImproverDB and GearSetImproverDB.toastAnchor
    f:ClearAllPoints()
    if db and db.point and db.x and db.y then
        f:SetPoint(db.point, UIParent, db.relPoint or db.point, db.x, db.y)
    else
        f:SetPoint("TOP", UIParent, "TOP", 0, TOAST_DEFAULT_Y)
    end
end

local function ComputeToasterSlideVectors(f)
    local sw = (UIParent and UIParent.GetWidth and UIParent:GetWidth()) or 1920
    local sh = (UIParent and UIParent.GetHeight and UIParent:GetHeight()) or 1080
    local cx, cy = nil, nil
    if f and f.GetCenter then
        cx, cy = f:GetCenter()
    end
    if not cx or not cy then
        return 0, SLIDE_DISTANCE, 0, SLIDE_DISTANCE * 0.75
    end
    -- Bottom region: pop upward like a classic toaster
    if cy < sh * 0.40 then
        return 0, -SLIDE_DISTANCE, 0, -SLIDE_DISTANCE * 0.75
    -- Side edges: glide cleanly inward from the edge
    elseif cx < sw * 0.22 then
        return -SLIDE_DISTANCE * 1.4, 0, -SLIDE_DISTANCE, 0
    elseif cx > sw * 0.78 then
        return SLIDE_DISTANCE * 1.4, 0, SLIDE_DISTANCE, 0
    end
    -- Top/center default: smooth drop-in from top
    return 0, SLIDE_DISTANCE, 0, SLIDE_DISTANCE * 0.75
end

-- ------------------------------------------------------------
-- COMPACT MODERN TOASTER CARD BACKGROUND
-- Slate textured glass with clean 1px border, quality rail & sheen
-- ------------------------------------------------------------
local function BuildPlumberCardBackground(f, width, height)
    f:SetSize(width, height)

    -- Subtle drop shadow rim around card
    local outerShadow = f:CreateTexture(nil, "BACKGROUND", nil, -8)
    outerShadow:SetPoint("TOPLEFT", f, "TOPLEFT", -2, 2)
    outerShadow:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 2, -2)
    outerShadow:SetColorTexture(0, 0, 0, 0.55)
    f.outerShadow = outerShadow

    -- Base Dark Glass Fill
    local baseBackdrop = f:CreateTexture(nil, "BACKGROUND", nil, -7)
    baseBackdrop:SetAllPoints(f)
    baseBackdrop:SetColorTexture(0.045, 0.055, 0.08, 0.94)
    f.baseBackdrop = baseBackdrop

    -- Plumber Slate Grain Overlay
    local bg = f:CreateTexture(nil, "BACKGROUND", nil, -5)
    bg:SetAllPoints(f)
    bg:SetTexture(TEXTURE_FILE)
    local maxBg = 512
    local bgW = width / maxBg
    local bgH = height / maxBg
    if bgW > 1 then bgW = 1 end
    if bgH > 1 then bgH = 1 end
    bg:SetTexCoord(0.5, 0.5 + 0.5 * bgW, 0, 1.0 * bgH)
    bg:SetAlpha(0.65)
    f.slateBg = bg

    -- Crisp 1px inner border
    local borderTop = f:CreateTexture(nil, "BORDER", nil, 0)
    borderTop:SetHeight(1)
    borderTop:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)
    borderTop:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, 0)
    borderTop:SetColorTexture(0.24, 0.28, 0.36, 0.85)

    local borderBottom = f:CreateTexture(nil, "BORDER", nil, 0)
    borderBottom:SetHeight(1)
    borderBottom:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 0, 0)
    borderBottom:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, 0)
    borderBottom:SetColorTexture(0.14, 0.17, 0.24, 0.95)

    local borderRight = f:CreateTexture(nil, "BORDER", nil, 0)
    borderRight:SetWidth(1)
    borderRight:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, 0)
    borderRight:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, 0)
    borderRight:SetColorTexture(0.18, 0.21, 0.29, 0.90)

    -- Quality Accent Left Rail (3px solid + soft bleed glow)
    local leftRail = f:CreateTexture(nil, "BORDER", nil, 2)
    leftRail:SetWidth(3)
    leftRail:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)
    leftRail:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 0, 0)
    leftRail:SetColorTexture(1, 1, 1, 0.95)
    f.leftAccent = leftRail

    local topGlow = f:CreateTexture(nil, "BORDER", nil, 1)
    topGlow:SetHeight(2)
    topGlow:SetPoint("TOPLEFT", f, "TOPLEFT", 3, 0)
    topGlow:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, 0)
    topGlow:SetColorTexture(1, 1, 1, 0.45)
    f.topAccent = topGlow

    -- Brief entrance highlight sheen along top edge
    local enterSheen = f:CreateTexture(nil, "ARTWORK", nil, 1)
    enterSheen:SetHeight(14)
    enterSheen:SetPoint("TOPLEFT", f, "TOPLEFT", 3, -1)
    enterSheen:SetPoint("TOPRIGHT", f, "TOPRIGHT", -1, -1)
    enterSheen:SetColorTexture(1, 1, 1, 0)
    f.enterSheen = enterSheen

    function f:SetQualityColor(r, g, b)
        leftRail:SetColorTexture(r, g, b, 0.96)
        topGlow:SetColorTexture(r, g, b, 0.42)
        if f.enterSheen then
            f.enterSheen._qr, f.enterSheen._qg, f.enterSheen._qb = r, g, b
        end
    end
end

-- ------------------------------------------------------------
-- COMPACT CLOSE BUTTON
-- ------------------------------------------------------------
-- keepToast: hovering does not pause the toast (a button on another prompt)
local function CreatePlumberCloseButton(parent, onClick, keepToast)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetSize(16, 16)
    btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")

    local bg = btn:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(btn)
    bg:SetColorTexture(0.14, 0.16, 0.22, 0.70)
    btn.bg = bg

    local icon = btn:CreateTexture(nil, "ARTWORK")
    icon:SetSize(10, 10)
    icon:SetPoint("CENTER", btn, "CENTER", 0, 0)
    icon:SetTexture(TEXTURE_FILE)
    icon:SetTexCoord(64/1024, 96/1024, 104/512, 136/512)
    icon:SetVertexColor(0.72, 0.76, 0.84, 0.95)
    btn.icon = icon

    btn:SetScript("OnEnter", function()
        bg:SetColorTexture(0.55, 0.16, 0.18, 0.90)
        icon:SetVertexColor(1, 1, 1, 1)
        if not keepToast then GSI_UpgradeToast:Pause() end
    end)
    btn:SetScript("OnLeave", function()
        bg:SetColorTexture(0.14, 0.16, 0.22, 0.70)
        icon:SetVertexColor(0.72, 0.76, 0.84, 0.95)
        if not keepToast then GSI_UpgradeToast:Resume() end
    end)
    btn:SetScript("OnClick", onClick)

    return btn
end

-- ------------------------------------------------------------
-- COMPACT KEYCAP HINT (e.g. [R] Equip, [L] Skip)
-- Visual-only frame underneath actionOverlay
-- ------------------------------------------------------------
local function CreatePlumberKeycap(parent, keyChar, labelText, labelColor)
    local container = CreateFrame("Frame", nil, parent)
    container:SetHeight(14)
    container:EnableMouse(false)

    local capBg = container:CreateTexture(nil, "BACKGROUND")
    capBg:SetSize(13, 13)
    capBg:SetPoint("LEFT", container, "LEFT", 0, 0)
    capBg:SetColorTexture(0.16, 0.19, 0.26, 0.92)
    container.capBg = capBg

    local cap = container:CreateTexture(nil, "ARTWORK")
    cap:SetSize(13, 13)
    cap:SetPoint("CENTER", capBg, "CENTER", 0, 0)
    cap:SetTexture(TEXTURE_FILE)
    cap:SetTexCoord(16/1024, 32/1024, 40/512, 56/512)
    container.cap = cap

    local key = container:CreateFontString(nil, "OVERLAY")
    ApplyFont(key, 8.5, "OUTLINE", false)
    key:SetPoint("CENTER", capBg, "CENTER", 0, 0)
    key:SetText(keyChar)
    key:SetTextColor(0.95, 0.96, 0.98, 1)
    container.key = key

    local lbl = container:CreateFontString(nil, "OVERLAY")
    ApplyFont(lbl, 9.5, "OUTLINE", true)
    lbl:SetPoint("LEFT", capBg, "RIGHT", 4, 0)
    lbl:SetText(labelText)
    lbl:SetWordWrap(false)
    if labelColor then
        lbl:SetTextColor(labelColor[1], labelColor[2], labelColor[3])
    else
        lbl:SetTextColor(0.82, 0.85, 0.90)
    end
    container.lbl = lbl

    local textW = lbl:GetStringWidth()
    if not textW or textW <= 0 then
        textW = string.len(labelText) * 6.5
    end
    container:SetWidth(13 + 4 + textW + 2)

    return container
end

-- The toast's look for GSI's other prompts (the Equipment Set chooser)
GSI_UpgradeToast.Style = {
    BuildCardBackground = BuildPlumberCardBackground,
    ApplyFont = ApplyFont,
    CreateCloseButton = function(parent, onClick)
        return CreatePlumberCloseButton(parent, onClick, true)
    end,
    TEXTURE_FILE = TEXTURE_FILE,
    ICON_BORDER_FILE = ICON_BORDER_FILE,
    ICON_OVERLAY_FILE = ICON_OVERLAY_FILE,
    WIDTH = TOAST_WIDTH,
    HEIGHT = TOAST_HEIGHT,
    DEFAULT_Y = TOAST_DEFAULT_Y,
}

-- ------------------------------------------------------------
-- TOAST ANCHOR FRAME (Matches Compact 348x68 Toast Footprint)
-- ------------------------------------------------------------
local function CreateAnchorFrame()
    if anchorFrame then return anchorFrame end

    local f = CreateFrame("Frame", "GSI_UpgradeToastAnchorFrame", UIParent, "BackdropTemplate")
    f:SetSize(TOAST_WIDTH, TOAST_HEIGHT)
    ApplySavedPosition(f)
    f:SetFrameStrata("DIALOG")
    f:SetFrameLevel(60)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetClampedToScreen(true)

    BuildPlumberCardBackground(f, TOAST_WIDTH, TOAST_HEIGHT)
    f:SetQualityColor(0.2, 0.85, 1.0)

    local iconFrame = CreateFrame("Frame", nil, f)
    iconFrame:SetSize(38, 38)
    iconFrame:SetPoint("LEFT", f, "LEFT", 11, 0)

    local iconBorder = iconFrame:CreateTexture(nil, "OVERLAY")
    iconBorder:SetAllPoints(iconFrame)
    iconBorder:SetTexture(ICON_BORDER_FILE)
    iconBorder:SetVertexColor(0.2, 0.85, 1.0)

    local iconTex = iconFrame:CreateTexture(nil, "ARTWORK")
    iconTex:SetAllPoints(iconFrame)
    iconTex:SetTexture("Interface\\Icons\\inv_sword_04")
    iconTex:SetTexCoord(0.07, 0.93, 0.07, 0.93)

    local lockBtn = CreateFrame("Button", nil, f, (GSI_UI and GSI_UI.BACKDROP_TEMPLATE) or "UIPanelButtonTemplate")
    lockBtn:SetSize(84, 20)
    lockBtn:SetPoint("RIGHT", f, "RIGHT", -10, 0)
    lockBtn:SetText("Lock Anchor")
    if GSI_UI and GSI_UI.SkinButton then
        GSI_UI:SkinButton(lockBtn, "Lock Anchor", "PRIMARY")
    else
        ApplyFont(lockBtn:GetFontString(), 10, "")
    end
    lockBtn:SetScript("OnClick", function()
        GSI_UpgradeToast:ToggleAnchor(false)
    end)

    local title = f:CreateFontString(nil, "OVERLAY")
    ApplyFont(title, 12, "OUTLINE")
    title:SetPoint("TOPLEFT", f, "TOPLEFT", 58, -14)
    title:SetPoint("RIGHT", lockBtn, "LEFT", -8, 0)
    title:SetJustifyH("LEFT")
    title:SetWordWrap(false)
    title:SetText("|cff33ccffUpgrade Toast Anchor|r")

    local desc = f:CreateFontString(nil, "OVERLAY")
    ApplyFont(desc, 10, "OUTLINE")
    desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4)
    desc:SetPoint("RIGHT", lockBtn, "LEFT", -8, 0)
    desc:SetJustifyH("LEFT")
    desc:SetWordWrap(false)
    desc:SetText("|cff9ca3afDrag to move · Compact 348x68|r")

    f:SetScript("OnDragStart", function(self)
        self:StartMoving()
    end)

    f:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        SavePosition(self)
        if toastFrame then
            ApplySavedPosition(toastFrame)
        end
        print("|cffffcc00[GearSetImprover]|r Toast anchor position saved.")
    end)

    f:Hide()
    anchorFrame = f
    return f
end

function GSI_UpgradeToast:IsAnchorShown()
    return (anchorFrame and anchorFrame:IsShown()) and true or false
end

function GSI_UpgradeToast:ToggleAnchor(show)
    local f = CreateAnchorFrame()
    if show == nil then
        show = not f:IsShown()
    end
    if show then
        ApplySavedPosition(f)
        f:Show()
        print("|cffffcc00[GearSetImprover]|r Toast Anchor visible. Drag to move, then click 'Lock Anchor'.")
    else
        SavePosition(f)
        f:Hide()
        if toastFrame then
            ApplySavedPosition(toastFrame)
        end
        print("|cffffcc00[GearSetImprover]|r Toast Anchor locked & saved.")
    end
    if GSI_UpgradeToast.OnAnchorToggled then
        pcall(GSI_UpgradeToast.OnAnchorToggled, f:IsShown())
    end
end

function GSI_UpgradeToast:ResetAnchor()
    if not GearSetImproverDB then GearSetImproverDB = {} end
    GearSetImproverDB.toastAnchor = { point = "TOP", relPoint = "TOP", x = 0, y = TOAST_DEFAULT_Y }
    if anchorFrame then ApplySavedPosition(anchorFrame) end
    if toastFrame then ApplySavedPosition(toastFrame) end
    print("|cffffcc00[GearSetImprover]|r Toast position reset to default.")
    if GSI_UpgradeToast.OnAnchorPositionReset then
        pcall(GSI_UpgradeToast.OnAnchorPositionReset)
    end
end

-- ------------------------------------------------------------
-- EQUIPPED CHECK & DISMISSAL TRACKING (ItemGUID + Slot ID)
-- ------------------------------------------------------------
local function IsToastItemEquipped(toastData)
    if not toastData then return false end
    local targetLink = toastData.itemLink or toastData.link
    local targetID = toastData.idNum or (targetLink and tonumber(targetLink:match("item:(%d+)")))
    local targetGUID = toastData.itemGUID

    if not targetGUID and not targetLink and not targetID then
        return false
    end

    local slotToCheck = ResolveToastTargetSlot(toastData)

    -- 1. Primary WoW 12.1 Check: Exact ItemGUID match on equipped slots.
    -- Immune to WoW 12.1 hyperlink mutations (e.g. creator GUID added on equip)
    -- AND immune to duplicate itemIDs (e.g. wearing Ring X in Slot 11 while looting a second Ring X).
    if targetGUID then
        if slotToCheck and GetEquippedSlotGUID(slotToCheck) == targetGUID then
            return true
        end
        for sID = 1, 19 do
            if GetEquippedSlotGUID(sID) == targetGUID then
                return true
            end
        end
        -- If this exact itemGUID is still sitting in a bag slot, it is definitely NOT equipped yet!
        local guidBag, guidSlot = FindBagSlotByGUID(targetGUID)
        if guidBag ~= nil and guidSlot ~= nil then
            return false
        end
    end

    -- For TestToast demo items without a bag GUID, only match if actually worn
    if toastData.isTestToast and not targetGUID then
        if targetID and slotToCheck and GetEquippedSlotItemID(slotToCheck) == targetID then
            return true
        end
        return false
    end

    -- 2. Fallback Check (when itemGUID is unavailable or no longer in bags):
    -- Verify via GetInventoryItemID and GetInventoryItemLink across target slot and 1..19.
    if slotToCheck then
        if targetID and GetEquippedSlotItemID(slotToCheck) == targetID then
            return true
        end
        local eqLink = GetInventoryItemLink and GetInventoryItemLink("player", slotToCheck)
        if eqLink and (eqLink == targetLink or (targetID and tonumber(eqLink:match("item:(%d+)")) == targetID)) then
            return true
        end
    end

    for sID = 1, 19 do
        if targetID and GetEquippedSlotItemID(sID) == targetID then
            return true
        end
        local eqLink = GetInventoryItemLink and GetInventoryItemLink("player", sID)
        if eqLink and (eqLink == targetLink or (targetID and tonumber(eqLink:match("item:(%d+)")) == targetID)) then
            return true
        end
    end

    return false
end

function GSI_UpgradeToast:MarkItemDismissed(itemLink, idNum, itemGUID)
    if not itemLink and not idNum and not itemGUID then return end
    local db = GearSetImproverDB
    if not db then return end
    if not db.toastDismissedItems then
        db.toastDismissedItems = {}
    end
    -- Prefer persistent ItemGUID & full itemLink so second copies of rings or better random-suffix
    -- items sharing a base itemID can still trigger future upgrade toasts!
    if itemGUID then
        db.toastDismissedItems[itemGUID] = true
    end
    if itemLink then
        db.toastDismissedItems[itemLink] = true
    end
    if not itemGUID and not itemLink and idNum then
        db.toastDismissedItems[idNum] = true
    end
end

local function IsItemMarkedDismissed(itemLink, idNum, itemGUID)
    local db = GearSetImproverDB
    if not db or not db.toastDismissedItems then return false end
    if itemGUID and db.toastDismissedItems[itemGUID] then return true end
    if itemLink and db.toastDismissedItems[itemLink] then return true end
    if not itemGUID and idNum and db.toastDismissedItems[idNum] then return true end
    return false
end

-- ------------------------------------------------------------
-- DIRECT CURSOR SWAP & HARDWARE MACRO EQUIP HELPERS
-- ------------------------------------------------------------
local function DirectCursorEquip(bag, slot, targetSlotID, idNum)
    if bag == nil or slot == nil or not targetSlotID or not EquipCursorItem then
        return false
    end
    if IsBindConfirmPopupOpen() or IsTradeableBindPopupOpen() or IsBagSlotLocked(bag, slot) or (IsInventoryItemLocked and IsInventoryItemLocked(targetSlotID)) then
        return false
    end

    local ok = pcall(function()
        GSI_UpgradeToast._userInitiatedEquipUntil = ((GetTime and GetTime()) or 0) + 0.6
        if ClearCursor then ClearCursor() end
        PickupBagItem(bag, slot)
        if CursorHasItem and CursorHasItem() then
            EquipCursorItem(targetSlotID)

            if IsTradeableBindPopupOpen() then
                if currentToast and currentToast._equipClicked then
                    currentToast._awaitingBindConfirm = true
                    currentToast._equipPendingUntil = ((GetTime and GetTime()) or 0) + 60.0
                end
                return
            end

            if IsBindConfirmPopupOpen() then
                ConfirmPendingBind(targetSlotID)
                if IsBindConfirmPopupOpen() then
                    return
                end
            end

            -- If an item remains on the cursor, ONLY put it back into (bag, slot) if it is the
            -- OLD displaced item (cItemID ~= idNum). Never call ClearCursor() synchronously when
            -- cItemID == idNum, because on empty slots WoW 16001 keeps the new item on cursor until frame end!
            if not IsBindConfirmPopupOpen() and not IsTradeableBindPopupOpen() and CursorHasItem and CursorHasItem() then
                local cType, cItemID = nil, nil
                if GetCursorInfo then
                    cType, cItemID = GetCursorInfo()
                end
                if cType == "item" and idNum and cItemID ~= idNum then
                    PickupBagItem(bag, slot)
                    if CursorHasItem and CursorHasItem() and ClearCursor then
                        ClearCursor()
                    end
                elseif C_Timer and C_Timer.After then
                    local savedBag, savedSlot, savedId = bag, slot, idNum
                    C_Timer.After(0.12, function()
                        local now = (GetTime and GetTime()) or 0
                        if IsBindConfirmPopupOpen() or IsTradeableBindPopupOpen() or now < activeTradeableConfirmUntil then
                            return
                        end
                        if CursorHasItem and CursorHasItem() then
                            local t2, id2 = nil, nil
                            if GetCursorInfo then t2, id2 = GetCursorInfo() end
                            if t2 == "item" and savedId and id2 ~= savedId then
                                PickupBagItem(savedBag, savedSlot)
                            end
                            if CursorHasItem and CursorHasItem() and ClearCursor then
                                ClearCursor()
                            end
                        end
                    end)
                end
            end
        end
    end)

    return ok and true or false
end

local function BuildToastEquipMacro(toastData)
    if not toastData then return "" end
    if IsToastItemEquipped(toastData) then return "" end

    local link = toastData.itemLink or toastData.link
    local idNum = toastData.idNum or (link and tonumber(link:match("item:(%d+)")))
    local targetSlotID = ResolveToastTargetSlot(toastData)

    local bag, slot = FindItemInBags(toastData.itemGUID, link, idNum)
    if bag ~= nil and slot ~= nil then
        toastData.bag = bag
        toastData.slot = slot
        if not toastData.itemGUID then
            toastData.itemGUID = GetBagSlotGUID(bag, slot)
        end
    elseif toastData.isTestToast then
        return ""
    end

    -- Multi-slots (Rings 11/12, Trinkets 13/14, Weapons 16/17) or duplicate bag items with same itemID
    -- are handled via exact (bag, slot) -> targetSlotID cursor placement in PreClick so Ring 11 vs 12 is respected.
    local bagCopies = idNum and CountItemIDInBags(idNum) or 0
    if IsMultiTargetSlot(targetSlotID) or bagCopies > 1 then
        return ""
    end

    if targetSlotID and idNum then
        return string.format("/equipslot %d item:%d", targetSlotID, idNum)
    elseif idNum then
        return string.format("/equip item:%d", idNum)
    end
    return ""
end

local function RefreshOverlaySecureAttributes()
    if not toastFrame or not toastFrame.actionOverlay then return end
    if IsInCombat() then return end
    local overlay = toastFrame.actionOverlay
    if not overlay.SetAttribute then return end

    if not currentToast then
        if not overlay._hasSecureAttrs then return end
        overlay:SetAttribute("type1", nil)
        overlay:SetAttribute("type2", nil)
        overlay:SetAttribute("macrotext", nil)
        overlay:SetAttribute("macrotext1", nil)
        overlay:SetAttribute("macrotext2", nil)
        overlay._hasSecureAttrs = false
        return
    end

    local macroText = BuildToastEquipMacro(currentToast)
    overlay:SetAttribute("type1", nil)
    overlay:SetAttribute("macrotext1", nil)
    if macroText ~= "" then
        overlay:SetAttribute("type2", "macro")
        overlay:SetAttribute("macrotext2", macroText)
        overlay:SetAttribute("macrotext", macroText)
        overlay._hasSecureAttrs = true
    else
        overlay:SetAttribute("type2", nil)
        overlay:SetAttribute("macrotext2", nil)
        overlay:SetAttribute("macrotext", nil)
        overlay._hasSecureAttrs = false
    end
end

local function HandleCombatEquipDefer(toastData)
    if not toastData then return end
    local label = toastData.itemLink or toastData.itemName or "Item"
    print("|cffffcc00[GearSetImprover]|r In combat! " .. label .. " will be equipped automatically when combat ends.")
    if UIErrorsFrame and UIErrorsFrame.AddMessage then
        UIErrorsFrame:AddMessage("In combat - will equip after combat ends", 1.0, 0.82, 0.0, 1.0)
    end
    pendingCombatToast = toastData
end

local function HandleTestToastEquipSuccess(toastData)
    local label = (toastData and (toastData.itemLink or toastData.itemName)) or "Item"
    print("|cff00ff88[GearSetImprover]|r Test toast right-click succeeded! (Demo item: " .. label .. ")")
    if UIErrorsFrame and UIErrorsFrame.AddMessage then
        UIErrorsFrame:AddMessage("GSI Test Toast: Right-click equip succeeded!", 0.0, 1.0, 0.53, 1.0)
    end
    PlayEquipSuccessSound()
    GSI_UpgradeToast:Dismiss(true)
end

-- Asynchronous verification loop after clicking Equip:
-- Never dismisses or blacklists the toast until the item is confirmed equipped!
local function ScheduleEquipVerification(watchedToast)
    if not watchedToast then return end
    verifyGeneration = verifyGeneration + 1
    local myGen = verifyGeneration

    local delays = { 0.06, 0.18, 0.38, 0.65, 1.10 }
    local timerFn = (C_Timer and C_Timer.After)
    if not timerFn then
        GSI_UpgradeToast:CheckIfCurrentEquipped()
        return
    end

    for stepIndex, delaySec in ipairs(delays) do
        timerFn(delaySec, function()
            if myGen ~= verifyGeneration then return end
            if currentToast ~= watchedToast then return end

            -- 1. Check if item is now equipped!
            if GSI_UpgradeToast:CheckIfCurrentEquipped() then
                GSI_UpgradeToast.isEquippingSlot = nil
                if GSI_UI then GSI_UI.activeEquipTargetSlot = nil end
                return
            end

            local now = (GetTime and GetTime()) or 0
            local targetSlotID = ResolveToastTargetSlot(watchedToast)

            -- 2. Never retry swaps or clear cursor while a tradeable/refundable or BoE bind confirmation
            -- popup is visible; let the user click the Blizzard dialog uninterrupted!
            if IsTradeableBindPopupOpen() or watchedToast._awaitingBindConfirm or now < activeTradeableConfirmUntil then
                watchedToast._awaitingBindConfirm = true
                watchedToast._equipPendingUntil = now + 60.0
                verifyGeneration = verifyGeneration + 1
                return
            end

            if IsBindConfirmPopupOpen() then
                ConfirmPendingBind(targetSlotID)
                if IsBindConfirmPopupOpen() or IsTradeableBindPopupOpen() then
                    watchedToast._awaitingBindConfirm = true
                    watchedToast._equipPendingUntil = now + 60.0
                    verifyGeneration = verifyGeneration + 1
                end
                return
            end

            if IsInCombat() then
                pendingCombatToast = watchedToast
                return
            end

            local link = watchedToast.itemLink
            local idNum = watchedToast.idNum or (link and tonumber(link:match("item:(%d+)")))
            local bag, slot = FindItemInBags(watchedToast.itemGUID, link, idNum)
            local slotLocked = targetSlotID and IsInventoryItemLocked and IsInventoryItemLocked(targetSlotID)

            -- 3. Active Fallback Attempts on intermediate ticks if initial hardware macro/cursor was locked or skipped
            if stepIndex == 2 or stepIndex == 3 then
                if bag ~= nil and slot ~= nil and not IsBagSlotLocked(bag, slot) and not slotLocked then
                    local bagCopies = idNum and CountItemIDInBags(idNum) or 1
                    if stepIndex == 2 and not IsMultiTargetSlot(targetSlotID) and bagCopies <= 1 then
                        local equipFn = (C_Item and C_Item.EquipItemByName) or EquipItemByName
                        if equipFn and (idNum or link) then
                            GSI_UpgradeToast._userInitiatedEquipUntil = now + 0.6
                            pcall(function() equipFn(idNum and ("item:" .. idNum) or link, targetSlotID) end)
                            if IsTradeableBindPopupOpen() then
                                watchedToast._awaitingBindConfirm = true
                                watchedToast._equipPendingUntil = now + 60.0
                                verifyGeneration = verifyGeneration + 1
                                return
                            elseif IsBindConfirmPopupOpen() then
                                ConfirmPendingBind(targetSlotID)
                                if IsBindConfirmPopupOpen() then
                                    watchedToast._awaitingBindConfirm = true
                                    watchedToast._equipPendingUntil = now + 60.0
                                    verifyGeneration = verifyGeneration + 1
                                end
                                return
                            end
                        end
                    end
                    if not IsBagSlotLocked(bag, slot) and not IsBindConfirmPopupOpen() and not IsTradeableBindPopupOpen() and not IsToastItemEquipped(watchedToast) then
                        DirectCursorEquip(bag, slot, targetSlotID, idNum)
                    end
                end
            elseif stepIndex == #delays then
                if IsBindConfirmPopupOpen() or IsTradeableBindPopupOpen() or watchedToast._awaitingBindConfirm then
                    watchedToast._equipPendingUntil = now + 60.0
                    return
                end

                -- Final check: clean up state and report reason if still unequipped in bags
                GSI_UpgradeToast.isEquippingSlot = nil
                if GSI_UI then GSI_UI.activeEquipTargetSlot = nil end
                watchedToast._equipPendingUntil = nil
                watchedToast._equipClicked = nil

                if GSI_UpgradeToast:CheckIfCurrentEquipped(true) then
                    return
                end

                local playerLevel = (UnitLevel and UnitLevel("player")) or 60
                local minLevel = watchedToast.minLevel
                if not minLevel and link and GetItemInfo then
                    minLevel = select(5, GetItemInfo(link))
                end
                if minLevel and minLevel > playerLevel then
                    if UIErrorsFrame and UIErrorsFrame.AddMessage then
                        UIErrorsFrame:AddMessage(string.format("GSI: Requires level %d to equip", minLevel), 1.0, 0.82, 0.0, 1.0)
                    end
                elseif (bag ~= nil and slot ~= nil and IsBagSlotLocked(bag, slot)) or slotLocked then
                    if UIErrorsFrame and UIErrorsFrame.AddMessage then
                        UIErrorsFrame:AddMessage("GSI: Item temporarily locked - please confirm any prompt or right-click again", 1.0, 0.5, 0.0, 1.0)
                    end
                elseif UIErrorsFrame and UIErrorsFrame.AddMessage then
                    UIErrorsFrame:AddMessage("GSI: Could not equip item", 1.0, 0.4, 0.1, 1.0)
                end
                RefreshOverlaySecureAttributes()
            end
        end)
    end
end

-- ------------------------------------------------------------
-- TOAST NOTIFICATION FRAME (Compact Animated Toaster HUD)
-- ------------------------------------------------------------
local function EaseOutCubic(t)
    if t <= 0 then return 0 end
    if t >= 1 then return 1 end
    local inv = 1 - t
    return 1 - (inv * inv * inv)
end

local function EaseInQuad(t)
    if t <= 0 then return 0 end
    if t >= 1 then return 1 end
    return t * t
end

local function CreateToastFrame()
    if toastFrame then return toastFrame end

    local f = CreateFrame("Frame", "GSI_UpgradeToastFrame", UIParent, "BackdropTemplate")
    f:SetSize(TOAST_WIDTH, TOAST_HEIGHT)
    ApplySavedPosition(f)
    -- Stay on HIGH strata below DIALOG so Blizzard trade/bind popups are always clickable above the toast
    f:SetFrameStrata("HIGH")
    f:SetFrameLevel(50)
    if f.SetToplevel then f:SetToplevel(false) end
    f:SetMovable(true)
    f:SetClampedToScreen(true)

    -- Animated visual child container: sliding this keeps the parent + InsecureActionOverlay static & taint-free
    local card = CreateFrame("Frame", nil, f)
    card:SetSize(TOAST_WIDTH, TOAST_HEIGHT)
    card:SetPoint("CENTER", f, "CENTER", 0, 0)
    card:SetFrameLevel(f:GetFrameLevel())
    card:EnableMouse(false)
    BuildPlumberCardBackground(card, TOAST_WIDTH, TOAST_HEIGHT)
    f.card = card
    f.enterSheen = card.enterSheen
    function f:SetQualityColor(r, g, b)
        card:SetQualityColor(r, g, b)
    end

    -- Hover Highlight Texture (Plumber LootUI.png button highlight slice)
    local hoverHl = card:CreateTexture(nil, "ARTWORK", nil, -2)
    hoverHl:SetTexture(TEXTURE_FILE)
    hoverHl:SetTexCoord(136/1024, 264/1024, 72/512, 104/512)
    hoverHl:SetPoint("TOPLEFT", card, "TOPLEFT", 3, -2)
    hoverHl:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT", -2, 3)
    hoverHl:SetAlpha(0)
    f.hoverHl = hoverHl

    -- ICON AREA (Compact 38x38 Square Icon + Ambient Radial Glow)
    local iconContainer = CreateFrame("Frame", nil, card)
    iconContainer:SetSize(38, 38)
    iconContainer:SetPoint("LEFT", card, "LEFT", 11, 1)
    iconContainer:EnableMouse(false)
    f.iconContainer = iconContainer

    local iconGlow = iconContainer:CreateTexture(nil, "BACKGROUND", nil, -1)
    iconGlow:SetSize(54, 54)
    iconGlow:SetPoint("CENTER", iconContainer, "CENTER", 0, 0)
    iconGlow:SetTexture(ICON_OVERLAY_FILE)
    iconGlow:SetBlendMode("ADD")
    iconGlow:SetAlpha(0.32)
    f.iconGlow = iconGlow

    local icon = iconContainer:CreateTexture(nil, "ARTWORK")
    icon:SetAllPoints(iconContainer)
    icon:SetTexCoord(0.0625, 0.9375, 0.0625, 0.9375)
    f.icon = icon

    local iconBorder = iconContainer:CreateTexture(nil, "OVERLAY")
    iconBorder:SetAllPoints(iconContainer)
    iconBorder:SetTexture(ICON_BORDER_FILE)
    f.iconBorder = iconBorder

    -- ROW 1 RIGHT: Compact Emerald Score Pill (placed strictly left of 16x16 closeBtn)
    local deltaBadge = CreateFrame("Frame", nil, card)
    deltaBadge:SetHeight(16)
    deltaBadge:SetWidth(58)
    deltaBadge:SetPoint("TOPRIGHT", card, "TOPRIGHT", -26, -7)
    local deltaBg = deltaBadge:CreateTexture(nil, "BACKGROUND")
    deltaBg:SetAllPoints(deltaBadge)
    deltaBg:SetColorTexture(0.04, 0.24, 0.14, 0.90)
    local deltaTopRim = deltaBadge:CreateTexture(nil, "BORDER")
    deltaTopRim:SetHeight(1)
    deltaTopRim:SetPoint("TOPLEFT", deltaBadge, "TOPLEFT", 0, 0)
    deltaTopRim:SetPoint("TOPRIGHT", deltaBadge, "TOPRIGHT", 0, 0)
    deltaTopRim:SetColorTexture(0.0, 0.85, 0.45, 0.45)
    local deltaBotRim = deltaBadge:CreateTexture(nil, "BORDER")
    deltaBotRim:SetHeight(1)
    deltaBotRim:SetPoint("BOTTOMLEFT", deltaBadge, "BOTTOMLEFT", 0, 0)
    deltaBotRim:SetPoint("BOTTOMRIGHT", deltaBadge, "BOTTOMRIGHT", 0, 0)
    deltaBotRim:SetColorTexture(0.0, 0.85, 0.45, 0.45)

    local delta = deltaBadge:CreateFontString(nil, "OVERLAY")
    ApplyFont(delta, 10, "OUTLINE", true)
    delta:SetPoint("CENTER", deltaBadge, "CENTER", 0, 0)
    delta:SetJustifyH("CENTER")
    delta:SetWordWrap(false)
    delta:SetTextColor(0.25, 1.0, 0.62, 1)
    delta:SetText("+0.0 GSI")
    f.deltaBadge = deltaBadge
    f.delta = delta

    -- ROW 1 LEFT: Slot Header Tag (strictly left of deltaBadge)
    local headerTag = card:CreateFontString(nil, "OVERLAY")
    ApplyFont(headerTag, 9, "OUTLINE", true)
    headerTag:SetPoint("TOPLEFT", card, "TOPLEFT", 57, -9)
    headerTag:SetPoint("RIGHT", deltaBadge, "LEFT", -6, 0)
    headerTag:SetJustifyH("LEFT")
    headerTag:SetJustifyV("MIDDLE")
    headerTag:SetWordWrap(false)
    headerTag:SetTextColor(0.68, 0.72, 0.80, 1)
    headerTag:SetText("GEAR UPGRADE")
    f.headerTag = headerTag

    -- ROW 2: Crisp Item Name (clears closeBtn below y=-23)
    local itemName = card:CreateFontString(nil, "OVERLAY")
    ApplyFont(itemName, 12.5, "OUTLINE", false)
    itemName:SetPoint("TOPLEFT", card, "TOPLEFT", 57, -25)
    itemName:SetPoint("TOPRIGHT", card, "TOPRIGHT", -10, -25)
    itemName:SetJustifyH("LEFT")
    itemName:SetWordWrap(false)
    f.itemName = itemName

    -- ROW 3 RIGHT: Compact Keycap Action Hints ([L] Skip · [R] Equip)
    local keyEquip = CreatePlumberKeycap(card, "R", "Equip", {0.20, 1.0, 0.58})
    keyEquip:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT", -9, 7)
    f.keyEquip = keyEquip

    local dotSep = card:CreateFontString(nil, "OVERLAY")
    ApplyFont(dotSep, 9.5, "OUTLINE", true)
    dotSep:SetPoint("RIGHT", keyEquip, "LEFT", -5, 0)
    dotSep:SetTextColor(0.42, 0.46, 0.54, 1)
    dotSep:SetText("·")
    f.dotSep = dotSep

    local keyDismiss = CreatePlumberKeycap(card, "L", "Skip", {0.72, 0.76, 0.84})
    keyDismiss:SetPoint("RIGHT", dotSep, "LEFT", -5, 0)
    f.keyDismiss = keyDismiss

    -- ROW 3 LEFT: Replaced Item / Score Comparison Subtitle (strictly left of keyDismiss)
    local itemSub = card:CreateFontString(nil, "OVERLAY")
    ApplyFont(itemSub, 10, "OUTLINE", true)
    itemSub:SetPoint("LEFT", card, "BOTTOMLEFT", 57, 14)
    itemSub:SetPoint("RIGHT", keyDismiss, "LEFT", -8, 0)
    itemSub:SetJustifyH("LEFT")
    itemSub:SetWordWrap(false)
    itemSub:SetTextColor(0.66, 0.86, 0.76, 1)
    f.itemSub = itemSub

    -- BOTTOM DURATION PROGRESS BAR (2px smooth countdown strip)
    local progressTrack = CreateFrame("Frame", nil, card)
    progressTrack:SetHeight(2)
    progressTrack:SetPoint("BOTTOMLEFT", card, "BOTTOMLEFT", 3, 1)
    progressTrack:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT", -1, 1)
    local progressTrackBg = progressTrack:CreateTexture(nil, "BACKGROUND")
    progressTrackBg:SetAllPoints(progressTrack)
    progressTrackBg:SetColorTexture(0.10, 0.12, 0.18, 0.85)
    local progressFill = progressTrack:CreateTexture(nil, "ARTWORK")
    progressFill:SetPoint("TOPLEFT", progressTrack, "TOPLEFT", 0, 0)
    progressFill:SetPoint("BOTTOMLEFT", progressTrack, "BOTTOMLEFT", 0, 0)
    progressFill:SetWidth(TOAST_WIDTH - 4)
    progressFill:SetColorTexture(0.0, 0.90, 0.50, 0.88)
    f.progressTrack = progressTrack
    f.progressFill = progressFill

    -- HARDWARE ACTION OVERLAY (WoW 12.1 InsecureActionButtonTemplate)
    -- Executes /equipslot natively on Right-Click anywhere on the card OR Left-Click on [R] Equip,
    -- without tainting or blocking Show/Hide/Alpha during combat!
    local okOverlay, overlay = pcall(CreateFrame, "Button", "GSI_UpgradeToastActionOverlay", f, "InsecureActionButtonTemplate")
    if not okOverlay or not overlay then
        overlay = CreateFrame("Button", "GSI_UpgradeToastActionOverlay", f)
        overlay._isPlainButton = true
    end
    overlay:SetAllPoints(f)
    overlay:SetFrameLevel(f:GetFrameLevel() + 10)
    overlay:EnableMouse(true)
    if overlay.SetAttribute then
        overlay:SetAttribute("useOnKeyDown", false)
    end
    overlay:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    overlay:RegisterForDrag("LeftButton")
    f.actionOverlay = overlay

    -- Compact Close Button (Top-Right, sits ABOVE actionOverlay so [X] always closes cleanly)
    local closeBtn = CreatePlumberCloseButton(f, function(_, button)
        if button == "RightButton" then
            GSI_UpgradeToast:EquipPendingItem()
            return
        end
        if currentToast then
            GSI_UpgradeToast:MarkItemDismissed(currentToast.itemLink, currentToast.idNum, currentToast.itemGUID)
        end
        GSI_UpgradeToast:Dismiss()
    end)
    closeBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", -6, -6)
    closeBtn:SetFrameLevel(overlay:GetFrameLevel() + 5)
    f.closeBtn = closeBtn

    -- Shift-Drag repositioning on overlay
    overlay:SetScript("OnDragStart", function()
        if IsShiftKeyDown() then
            f:StartMoving()
        end
    end)
    overlay:SetScript("OnDragStop", function()
        f:StopMovingOrSizing()
        SavePosition(f)
        if anchorFrame then
            ApplySavedPosition(anchorFrame)
        end
        print("|cffffcc00[GearSetImprover]|r Toast position saved.")
    end)

    -- Hover Tooltip & Pause on overlay
    overlay:SetScript("OnEnter", function()
        GSI_UpgradeToast:Pause()
        f.hoverHl:SetAlpha(0.65)
        if currentToast and currentToast.itemLink then
            GameTooltip:SetOwner(f, "ANCHOR_RIGHT")
            GameTooltip:SetHyperlink(currentToast.itemLink)
            GameTooltip:Show()
        end
    end)

    overlay:SetScript("OnLeave", function()
        GSI_UpgradeToast:Resume()
        f.hoverHl:SetAlpha(0)
        GameTooltip:Hide()
    end)

    -- PreClick: Prepares hardware-event /equipslot macro OR exact-slot cursor swap before OnClick runs
    overlay:SetScript("PreClick", function(self, button, down)
        if down then return end
        self._blockedByBindPopup = nil
        if not currentToast then
            if not IsInCombat() and self.SetAttribute then
                self:SetAttribute("type1", nil)
                self:SetAttribute("type2", nil)
                self:SetAttribute("macrotext", nil)
                self:SetAttribute("macrotext1", nil)
                self:SetAttribute("macrotext2", nil)
            end
            return
        end

        local overEquipBadge = (f.keyEquip and f.keyEquip:IsShown() and f.keyEquip:IsMouseOver()) and true or false
        local isEquipClick = (button == "RightButton") or (button == "LeftButton" and overEquipBadge)
        self._lastClickWasEquip = isEquipClick
        self._handledInPreClick = false

        if IsInCombat() then
            return
        end

        if not isEquipClick then
            if self.SetAttribute then
                self:SetAttribute("type1", nil)
                self:SetAttribute("macrotext1", nil)
                self:SetAttribute("macrotext", nil)
            end
            return
        end

        local now = (GetTime and GetTime()) or 0
        if IsBindConfirmPopupOpen() or IsTradeableBindPopupOpen() or now < activeTradeableConfirmUntil then
            self._blockedByBindPopup = true
            if self.SetAttribute then
                self:SetAttribute("type1", nil)
                self:SetAttribute("type2", nil)
                self:SetAttribute("macrotext", nil)
                self:SetAttribute("macrotext1", nil)
                self:SetAttribute("macrotext2", nil)
            end
            return
        end

        currentToast._equipClicked = true
        currentToast._awaitingBindConfirm = nil
        currentToast._equipPendingUntil = now + 1.5
        GSI_UpgradeToast._userInitiatedEquipUntil = now + 0.6

        local targetSlotID = ResolveToastTargetSlot(currentToast)
        GSI_UpgradeToast.isEquippingSlot = targetSlotID
        if GSI_UI then GSI_UI.activeEquipTargetSlot = targetSlotID end

        local link = currentToast.itemLink
        local idNum = currentToast.idNum or (link and tonumber(link:match("item:(%d+)")))
        local bag, slot = FindItemInBags(currentToast.itemGUID, link, idNum)
        if bag ~= nil and slot ~= nil then
            currentToast.bag = bag
            currentToast.slot = slot
            if not currentToast.itemGUID then
                currentToast.itemGUID = GetBagSlotGUID(bag, slot)
            end
        end

        local macroText = ""
        if not IsToastItemEquipped(currentToast) and not (currentToast.isTestToast and bag == nil) then
            local bagCopies = idNum and CountItemIDInBags(idNum) or 0
            if (IsMultiTargetSlot(targetSlotID) or bagCopies > 1) and bag ~= nil and slot ~= nil and targetSlotID then
                -- Exact bag-slot -> targetSlotID swap (preserves Finger 1 vs Finger 2 and exact ItemGUID)
                DirectCursorEquip(bag, slot, targetSlotID, idNum)
                self._handledInPreClick = true
                macroText = ""
            else
                macroText = BuildToastEquipMacro(currentToast)
            end
        end

        if self.SetAttribute then
            if button == "RightButton" then
                self:SetAttribute("type2", macroText ~= "" and "macro" or nil)
                self:SetAttribute("macrotext2", macroText ~= "" and macroText or nil)
                self:SetAttribute("macrotext", macroText ~= "" and macroText or nil)
            else
                self:SetAttribute("type1", macroText ~= "" and "macro" or nil)
                self:SetAttribute("macrotext1", macroText ~= "" and macroText or nil)
                self:SetAttribute("macrotext", macroText ~= "" and macroText or nil)
            end
            self._hasSecureAttrs = (macroText ~= "") or self._hasSecureAttrs
        end
    end)

    if overlay._isPlainButton then
        overlay:SetScript("OnClick", function(self, button)
            if self._lastClickWasEquip and not self._blockedByBindPopup then
                GSI_UpgradeToast:EquipPendingItem()
            end
        end)
    end

    -- PostClick: Handles Left-Click Dismiss / Modified Clicks, Combat Deferral, TestToast, and Equip Verification
    overlay:SetScript("PostClick", function(self, button, down)
        if down then return end
        if not currentToast then return end

        local wasBlockedByPopup = self._blockedByBindPopup
        self._blockedByBindPopup = nil
        local isEquipClick = self._lastClickWasEquip
        self._lastClickWasEquip = nil

        if not IsInCombat() and self.SetAttribute then
            self:SetAttribute("type1", nil)
            self:SetAttribute("macrotext1", nil)
        end

        if not isEquipClick then
            if button == "LeftButton" then
                if IsModifiedClick and IsModifiedClick("CHATLINK") and currentToast.itemLink and ChatEdit_InsertLink then
                    if ChatEdit_InsertLink(currentToast.itemLink) then return end
                elseif IsModifiedClick and IsModifiedClick("DRESSUP") and currentToast.itemLink and DressUpLink then
                    DressUpLink(currentToast.itemLink)
                    return
                end
                GSI_UpgradeToast:MarkItemDismissed(currentToast.itemLink, currentToast.idNum, currentToast.itemGUID)
                GSI_UpgradeToast:Dismiss()
            end
            return
        end

        if wasBlockedByPopup then
            if UIErrorsFrame and UIErrorsFrame.AddMessage then
                UIErrorsFrame:AddMessage("GSI: Confirm or cancel the open bind/trade dialog first", 1.0, 0.82, 0.0, 1.0)
            end
            return
        end

        -- 1. If already equipped, close immediately
        if GSI_UpgradeToast:CheckIfCurrentEquipped() then
            return
        end

        -- 2. In combat: queue for automatic equip on PLAYER_REGEN_ENABLED
        if IsInCombat() then
            HandleCombatEquipDefer(currentToast)
            return
        end

        -- 3. Demo TestToast (/gsi testtoast) when Thunderfury is not in player's bags
        local bag, slot = FindItemInBags(currentToast.itemGUID, currentToast.itemLink, currentToast.idNum)
        if currentToast.isTestToast and (bag == nil or slot == nil) then
            HandleTestToastEquipSuccess(currentToast)
            return
        end

        -- 4. Attempt BoE confirmation only for non-tradeable popups; let tradeable prompts stay visible
        local now = (GetTime and GetTime()) or 0
        if IsTradeableBindPopupOpen() or now < activeTradeableConfirmUntil then
            currentToast._awaitingBindConfirm = true
            currentToast._equipPendingUntil = now + 60.0
            return
        elseif IsBindConfirmPopupOpen() then
            ConfirmPendingBind(ResolveToastTargetSlot(currentToast))
            if IsBindConfirmPopupOpen() or IsTradeableBindPopupOpen() then
                currentToast._awaitingBindConfirm = true
                currentToast._equipPendingUntil = now + 60.0
                return
            end
        end

        -- 5. Schedule asynchronous verification (and fallback if needed) before dismissing!
        ScheduleEquipVerification(currentToast)
    end)

    -- Unified Toaster State Machine & Glow OnUpdate (runs ONLY while toastFrame is shown)
    local animElapsed = 0
    f._glowThrottle = 0
    f:SetScript("OnUpdate", function(self, elapsed)
        local dt = math.min(elapsed or 0, 0.05)

        if animState == "entering" then
            animStateElapsed = animStateElapsed + dt
            local p = (ENTER_DURATION > 0) and (animStateElapsed / ENTER_DURATION) or 1
            if p >= 1 then
                p = 1
                animState = "active"
            end
            local ease = EaseOutCubic(p)
            local ox = slideStartX * (1 - ease)
            local oy = slideStartY * (1 - ease)
            if f.card then
                f.card:ClearAllPoints()
                f.card:SetPoint("CENTER", f, "CENTER", ox, oy)
            end
            f:SetAlpha(ease)
            if f.enterSheen then
                f.enterSheen:SetAlpha(1 - ease)
            end
        elseif animState == "exiting" then
            animStateElapsed = animStateElapsed + dt
            local p = (EXIT_DURATION > 0) and (animStateElapsed / EXIT_DURATION) or 1
            if p >= 1 then
                animState = "idle"
                isDismissing = false
                if f.card then
                    f.card:ClearAllPoints()
                    f.card:SetPoint("CENTER", f, "CENTER", 0, 0)
                end
                f:SetAlpha(1.0)
                f:Hide()
                return
            end
            local ease = EaseInQuad(p)
            local ox = slideExitX * ease
            local oy = slideExitY * ease
            if f.card then
                f.card:ClearAllPoints()
                f.card:SetPoint("CENTER", f, "CENTER", ox, oy)
            end
            f:SetAlpha(animStartAlpha * (1 - ease))
            return
        end

        if currentToast and animState == "active" and not isPaused and not isDismissing then
            remainingTime = remainingTime - (elapsed or 0)
            if remainingTime <= 0 then
                if f.progressFill then
                    f.progressFill:SetWidth(0.01)
                end
                GSI_UpgradeToast:Dismiss()
                return
            end
            if f.progressFill then
                local ratio = (totalDuration > 0) and math.max(0.001, math.min(1, remainingTime / totalDuration)) or 0.001
                f.progressFill:SetWidth((TOAST_WIDTH - 4) * ratio)
                if ratio <= 0.20 then
                    f.progressFill:SetColorTexture(1.0, 0.62, 0.14, 0.92)
                else
                    f.progressFill:SetColorTexture(0.0, 0.90, 0.50, 0.88)
                end
            end
        end

        local db = GearSetImproverDB
        if db and db.toastBlink == false then
            if f.iconGlow and f._glowThrottle >= 0 then
                f.iconGlow:SetAlpha(0.28)
                f._glowThrottle = -1
            end
            return
        end

        animElapsed = animElapsed + (elapsed or 0)
        f._glowThrottle = (f._glowThrottle < 0 and 0 or f._glowThrottle) + (elapsed or 0)
        if f._glowThrottle >= 0.033 then
            f._glowThrottle = 0
            local wave = (math.sin(animElapsed * 2.8) + 1) * 0.5
            local glowAlpha = 0.18 + (wave * 0.22)
            if f.iconGlow then
                f.iconGlow:SetAlpha(glowAlpha)
            end
        end
    end)

    f:SetScript("OnHide", function(self)
        animState = "idle"
        animStateElapsed = 0
        isDismissing = false
        currentToast = nil
        if self.card then
            self.card:ClearAllPoints()
            self.card:SetPoint("CENTER", self, "CENTER", 0, 0)
        end
        RefreshOverlaySecureAttributes()
        if #toastQueue > 0 then
            local timerFn = (C_Timer and C_Timer.After) or function(d, fn) fn() end
            timerFn(0.05, function()
                GSI_UpgradeToast:ProcessQueue()
            end)
        end
    end)

    f:Hide()
    toastFrame = f
    return f
end

-- ------------------------------------------------------------
-- DISPLAY TOAST LOGIC
-- ------------------------------------------------------------
function GSI_UpgradeToast:DisplayToast(data)
    if not data then return end

    local itemLink = data.itemLink or data.link
    local idNum = data.idNum or (itemLink and tonumber(itemLink:match("item:(%d+)")))
    data.idNum = idNum
    if not data.itemGUID and data.bag ~= nil and data.slot ~= nil then
        data.itemGUID = GetBagSlotGUID(data.bag, data.slot)
    end
    if not data.itemGUID and not data.isTestToast then
        local b, s = FindItemInBags(nil, itemLink, idNum)
        if b ~= nil and s ~= nil then
            data.bag = b
            data.slot = s
            data.itemGUID = GetBagSlotGUID(b, s)
        end
    end

    -- Never display a toast for an item the player has already manually equipped!
    if not data.isTestToast and IsToastItemEquipped(data) then
        self:MarkItemDismissed(itemLink, idNum, data.itemGUID)
        self:ProcessQueue()
        return
    end

    currentToast = data

    local f = CreateToastFrame()
    ApplySavedPosition(f)

    local itemName = data.itemName or "Upgraded Gear"
    local quality = data.quality or 2
    local itemTexture = data.texture or data.itemTexture or "Interface\\Icons\\inv_misc_questionmark"
    local scoreGain = data.scoreGain or data.scoreDelta or 0
    local slotName = data.slotName or data.slot or "Gear"
    local oldItemName = data.oldItemName

    local qr, qg, qb = 1.0, 1.0, 1.0
    if GetItemQualityColor then
        local r, g, b = GetItemQualityColor(quality)
        if r and g and b then qr, qg, qb = r, g, b end
    end

    -- Quality accent rail, sheen & icon border
    f:SetQualityColor(qr, qg, qb)
    f.iconBorder:SetVertexColor(qr, qg, qb, 1.0)
    f.iconGlow:SetVertexColor(qr, qg, qb, 0.36)
    f.icon:SetTexture(itemTexture)

    -- Header tag & score pill (re-anchor keyDismiss dynamically when level is too high)
    if data.isLevelTooHigh and data.minLevel then
        f.headerTag:SetText(string.upper(slotName) .. " UPGRADE (REQ " .. data.minLevel .. ")")
        if f.keyEquip then f.keyEquip:Hide() end
        if f.dotSep then f.dotSep:Hide() end
        if f.keyDismiss then
            f.keyDismiss:ClearAllPoints()
            f.keyDismiss:SetPoint("BOTTOMRIGHT", f.card, "BOTTOMRIGHT", -9, 7)
        end
    else
        f.headerTag:SetText(string.upper(slotName) .. " UPGRADE")
        if f.keyEquip then f.keyEquip:Show() end
        if f.dotSep then f.dotSep:Show() end
        if f.keyDismiss and f.dotSep then
            f.keyDismiss:ClearAllPoints()
            f.keyDismiss:SetPoint("RIGHT", f.dotSep, "LEFT", -5, 0)
        end
    end

    f.delta:SetText(string.format("+%.1f GSI", scoreGain))
    if f.deltaBadge then
        local pillW = math.max(50, (f.delta:GetStringWidth() or 42) + 12)
        f.deltaBadge:SetWidth(pillW)
    end

    f.itemName:SetText(itemName)
    f.itemName:SetTextColor(qr, qg, qb, 1)

    if oldItemName and oldItemName ~= "" then
        f.itemSub:SetText(string.format("Replaces %s", oldItemName))
    else
        f.itemSub:SetText("Score upgrade over equipped gear")
    end

    -- Timer & smooth toaster entrance animation setup
    local db = GearSetImproverDB
    local duration = tonumber(db and db.toastDuration) or 60
    if duration < 3 then duration = 3 end
    totalDuration = duration
    remainingTime = duration
    isPaused = false
    isDismissing = false

    slideStartX, slideStartY, slideExitX, slideExitY = ComputeToasterSlideVectors(f)
    animState = "entering"
    animStateElapsed = 0

    if f.card then
        f.card:ClearAllPoints()
        f.card:SetPoint("CENTER", f, "CENTER", slideStartX, slideStartY)
    end
    if f.enterSheen then
        f.enterSheen:SetColorTexture(f.enterSheen._qr or qr, f.enterSheen._qg or qg, f.enterSheen._qb or qb, 0.16)
        f.enterSheen:SetAlpha(1.0)
    end
    if f.progressFill then
        f.progressFill:SetWidth(TOAST_WIDTH - 4)
        f.progressFill:SetColorTexture(0.0, 0.90, 0.50, 0.88)
    end

    RefreshOverlaySecureAttributes()
    PlayAlertSound()

    f._glowThrottle = 0
    f:SetAlpha(0)
    f:Show()
end

-- Checks whether the active or queued toast item has been equipped (manually or via click)
-- and optionally cleans up items removed from bags (sold, banked, destroyed, disenchanted).
function GSI_UpgradeToast:CheckIfCurrentEquipped(checkMissingFromBags)
    local now = (GetTime and GetTime()) or 0
    local cursorBusy = (CursorHasItem and CursorHasItem()) and true or false

    -- 1. Clean up queued toasts whose items have already been equipped (or removed from bags)
    if #toastQueue > 0 then
        for i = #toastQueue, 1, -1 do
            local qItem = toastQueue[i]
            if IsToastItemEquipped(qItem) then
                self:MarkItemDismissed(qItem.itemLink, qItem.idNum, qItem.itemGUID)
                table.remove(toastQueue, i)
            elseif checkMissingFromBags and not qItem.isTestToast and not cursorBusy then
                local b = FindItemInBags(qItem.itemGUID, qItem.itemLink, qItem.idNum)
                if b == nil then
                    table.remove(toastQueue, i)
                end
            end
        end
    end

    -- 2. If the currently displayed toast item is now equipped, close toast immediately!
    if currentToast and IsToastItemEquipped(currentToast) then
        local wasClickEquip = currentToast._equipClicked
        local label = currentToast.itemLink or currentToast.itemName or "Item"
        currentToast._equipClicked = nil
        currentToast._awaitingBindConfirm = nil
        currentToast._equipPendingUntil = nil
        verifyGeneration = verifyGeneration + 1

        if wasClickEquip then
            print("|cff00ff88[GearSetImprover]|r Equipped: " .. label)
            PlayEquipSuccessSound()
        end

        self:MarkItemDismissed(currentToast.itemLink, currentToast.idNum, currentToast.itemGUID)
        self:Dismiss(true)
        return true
    end

    -- 3. If the item is no longer in bags AND not equipped (e.g. sold, banked, destroyed), dismiss ghost toast
    if checkMissingFromBags and currentToast and not currentToast.isTestToast and not cursorBusy then
        local pendingUntil = currentToast._equipPendingUntil or 0
        if now >= pendingUntil and not currentToast._awaitingBindConfirm and not IsBindConfirmPopupOpen() and not IsTradeableBindPopupOpen() then
            local b = FindItemInBags(currentToast.itemGUID, currentToast.itemLink, currentToast.idNum)
            if b == nil then
                self:Dismiss(true)
                return true
            end
        end
    end

    return false
end

-- Programmatic equip entrypoint (used after combat ends via PLAYER_REGEN_ENABLED or closeBtn right-click)
function GSI_UpgradeToast:EquipPendingItem()
    if not currentToast then return end

    if self:CheckIfCurrentEquipped() then
        return
    end

    local now = (GetTime and GetTime()) or 0
    if IsBindConfirmPopupOpen() or IsTradeableBindPopupOpen() or now < activeTradeableConfirmUntil then
        currentToast._awaitingBindConfirm = true
        currentToast._equipPendingUntil = now + 60.0
        if UIErrorsFrame and UIErrorsFrame.AddMessage then
            UIErrorsFrame:AddMessage("GSI: Confirm or cancel the open bind/trade dialog first", 1.0, 0.82, 0.0, 1.0)
        end
        return
    end

    local link = currentToast.itemLink
    local idNum = currentToast.idNum or (link and tonumber(link:match("item:(%d+)")))
    local targetSlotID = ResolveToastTargetSlot(currentToast)

    if IsInCombat() then
        HandleCombatEquipDefer(currentToast)
        return
    end

    local bag, slot = FindItemInBags(currentToast.itemGUID, link, idNum)
    if currentToast.isTestToast and (bag == nil or slot == nil) then
        HandleTestToastEquipSuccess(currentToast)
        return
    end

    currentToast._equipClicked = true
    currentToast._awaitingBindConfirm = nil
    currentToast._equipPendingUntil = now + 1.5
    GSI_UpgradeToast._userInitiatedEquipUntil = now + 0.6
    GSI_UpgradeToast.isEquippingSlot = targetSlotID
    if GSI_UI then GSI_UI.activeEquipTargetSlot = targetSlotID end

    local bagCopies = idNum and CountItemIDInBags(idNum) or 1
    if not IsMultiTargetSlot(targetSlotID) and bagCopies <= 1 then
        local equipFn = (C_Item and C_Item.EquipItemByName) or EquipItemByName
        if equipFn and (idNum or link) then
            pcall(function() equipFn(idNum and ("item:" .. idNum) or link, targetSlotID) end)
            if IsTradeableBindPopupOpen() then
                currentToast._awaitingBindConfirm = true
                currentToast._equipPendingUntil = now + 60.0
                return
            elseif IsBindConfirmPopupOpen() then
                ConfirmPendingBind(targetSlotID)
                if IsBindConfirmPopupOpen() then
                    currentToast._awaitingBindConfirm = true
                    currentToast._equipPendingUntil = now + 60.0
                    return
                end
            end
        end
    end

    if bag ~= nil and slot ~= nil and not IsBagSlotLocked(bag, slot)
        and not (IsInventoryItemLocked and IsInventoryItemLocked(targetSlotID))
        and not IsBindConfirmPopupOpen() and not IsTradeableBindPopupOpen()
        and not IsToastItemEquipped(currentToast) then
        DirectCursorEquip(bag, slot, targetSlotID, idNum)
    end

    ScheduleEquipVerification(currentToast)
end
GSI_UpgradeToast.EquipCurrent = GSI_UpgradeToast.EquipPendingItem

function GSI_UpgradeToast:Dismiss(instant)
    if isDismissing and not instant then return end
    isDismissing = true

    if not toastFrame or not toastFrame:IsShown() or instant then
        animState = "idle"
        animStateElapsed = 0
        if toastFrame then
            if toastFrame.card then
                toastFrame.card:ClearAllPoints()
                toastFrame.card:SetPoint("CENTER", toastFrame, "CENTER", 0, 0)
            end
            toastFrame:Hide()
            toastFrame:SetAlpha(1.0)
        end
        isDismissing = false
        currentToast = nil
        RefreshOverlaySecureAttributes()
        self:ProcessQueue()
        return
    end

    slideStartX, slideStartY, slideExitX, slideExitY = ComputeToasterSlideVectors(toastFrame)
    animStartAlpha = toastFrame:GetAlpha()
    if animStartAlpha <= 0 then animStartAlpha = 1.0 end
    animState = "exiting"
    animStateElapsed = 0
end

function GSI_UpgradeToast:Pause()
    isPaused = true
end

function GSI_UpgradeToast:Resume()
    isPaused = false
end

function GSI_UpgradeToast:ShowToast(upgradeData)
    local db = GearSetImproverDB
    if db and (db.enableUpgradeToast == false or db.toastAlertsEnabled == false) then return end
    if not upgradeData or not upgradeData.itemLink then return end

    local itemID = upgradeData.itemLink:match("item:(%d+)")
    local idNum = upgradeData.idNum or (itemID and tonumber(itemID))
    upgradeData.idNum = idNum

    if not upgradeData.itemGUID and upgradeData.bag ~= nil and upgradeData.slot ~= nil then
        upgradeData.itemGUID = GetBagSlotGUID(upgradeData.bag, upgradeData.slot)
    end

    if not upgradeData.isTestToast then
        if IsItemMarkedDismissed(upgradeData.itemLink, idNum, upgradeData.itemGUID) then
            return
        end
        if IsToastItemEquipped(upgradeData) then
            return
        end
    end

    -- Avoid queueing duplicates if already visible or queued (match by ItemGUID or itemLink)
    local function IsSameToastItem(a, b)
        if not a or not b then return false end
        if a.itemGUID and b.itemGUID then
            return a.itemGUID == b.itemGUID
        end
        return a.itemLink == b.itemLink
    end

    if currentToast and IsSameToastItem(currentToast, upgradeData) then return end
    for _, item in ipairs(toastQueue) do
        if IsSameToastItem(item, upgradeData) then return end
    end

    if not currentToast and not isDismissing and not (toastFrame and toastFrame:IsShown()) then
        self:DisplayToast(upgradeData)
    else
        table.insert(toastQueue, upgradeData)
    end
end

function GSI_UpgradeToast:ProcessQueue()
    if isDismissing then return end
    while #toastQueue > 0 do
        local nextItem = table.remove(toastQueue, 1)
        if nextItem.isTestToast or not IsToastItemEquipped(nextItem) then
            self:DisplayToast(nextItem)
            return
        else
            self:MarkItemDismissed(nextItem.itemLink, nextItem.idNum, nextItem.itemGUID)
        end
    end
end

-- The toast on screen and the queued ones were scored with the weights of the
-- moment the item came in. After a spec change score them again: those that
-- are no longer upgrades go away, the others come back with the new gain.
-- (Talents cannot change in combat; the toast's secure button cannot be
-- hidden there either, so nothing happens in combat.)
function GSI_UpgradeToast:ReevaluatePending()
    if IsInCombat() then return end
    local items = {}
    if currentToast and not currentToast.isTestToast then
        items[#items + 1] = currentToast
    end
    local keep = {}
    for _, t in ipairs(toastQueue) do
        if t.isTestToast then keep[#keep + 1] = t else items[#items + 1] = t end
    end
    if #items == 0 then return end
    for i = #toastQueue, 1, -1 do toastQueue[i] = nil end
    for i, t in ipairs(keep) do toastQueue[i] = t end
    if currentToast and not currentToast.isTestToast then
        self:Dismiss(true)
    end
    for _, t in ipairs(items) do
        if t.itemGUID then recentNotified[t.itemGUID] = nil end
        if t.itemLink then recentNotified[t.itemLink] = nil end
        local bag, slot = FindItemInBags(t.itemGUID, t.itemLink, t.idNum)
        if bag ~= nil and slot ~= nil then
            self:EvaluateNewItem(t.itemLink, bag, slot, t.itemGUID)
        end
    end
end

-- ------------------------------------------------------------
-- ASYNCHRONOUS ITEM CACHE HOOK
-- ------------------------------------------------------------
local cacheListener = CreateFrame("Frame")
cacheListener:RegisterEvent("GET_ITEM_INFO_RECEIVED")
cacheListener:SetScript("OnEvent", function(self, event, itemID, success)
    if not success then return end
    local idNum = tonumber(itemID)
    if not idNum then return end

    -- 1. Check if there is an item pending evaluation waiting for item cache data
    if pendingCacheQueue[idNum] then
        local pending = pendingCacheQueue[idNum]
        pendingCacheQueue[idNum] = nil
        GSI_UpgradeToast:EvaluateNewItem(pending.link, pending.bag, pending.slot, pending.guid)
    end

    -- 2. If an active toast is currently displayed, refresh its visual details
    if currentToast and toastFrame and toastFrame:IsShown() then
        local link = currentToast.itemLink
        if link then
            local activeID = tonumber(link:match("item:(%d+)"))
            if activeID and activeID == idNum then
                local name, _, quality, _, _, _, _, _, _, texture = GetItemInfo(idNum)
                if name and name ~= "" then
                    currentToast.itemName = name
                    currentToast.quality = quality or currentToast.quality
                    currentToast.texture = texture or currentToast.texture

                    local qr, qg, qb = 1.0, 1.0, 1.0
                    if GetItemQualityColor then
                        local r, g, b = GetItemQualityColor(currentToast.quality)
                        if r and g and b then qr, qg, qb = r, g, b end
                    end

                    toastFrame:SetQualityColor(qr, qg, qb)
                    toastFrame.iconBorder:SetVertexColor(qr, qg, qb, 1.0)
                    toastFrame.iconGlow:SetVertexColor(qr, qg, qb, 0.40)
                    toastFrame.icon:SetTexture(currentToast.texture)
                    toastFrame.itemName:SetText(name)
                    toastFrame.itemName:SetTextColor(qr, qg, qb, 1)
                    RefreshOverlaySecureAttributes()
                end
            end
        end
    end
end)

-- ------------------------------------------------------------
-- TEST TOAST (Slash command /gsi toast or /gsi testtoast)
-- Prioritizes any real upgrade currently in bags so the player can test real
-- equipping & manual-equip dismissal immediately; falls back to Thunderfury demo.
-- ------------------------------------------------------------
function GSI_UpgradeToast:TestToast()
    toastQueue = {}
    self:Dismiss(true)

    -- 1. Check if there is an actual upgrade item sitting in the player's bags right now
    local bestRealToast = nil
    local maxBags = GetMaxBagIndex()
    for bag = 0, maxBags do
        local numSlots = GetNumBagSlots(bag)
        for slot = 1, numSlots do
            local link = GetBagItemLink(bag, slot)
            if link then
                local name, _, quality, _, reqLevel, _, _, _, equipLoc, texture = GetItemInfo(link)
                if equipLoc and equipLoc ~= "" and equipLoc ~= "INVTYPE_NON_EQUIP" and equipLoc ~= "INVTYPE_TRINKET"
                    and GSI_ClassicData and GSI_ClassicData.EquipLocToSlot and GSI_ClassicData.EquipLocToSlot[equipLoc] then
                    local usable = true
                    if GSI_OptimizationEngine and GSI_OptimizationEngine.IsItemUsableForPlayer then
                        usable = GSI_OptimizationEngine:IsItemUsableForPlayer(link, bag, slot, true)
                    end
                    if usable and GSI_CompareEngine and GSI_CompareEngine.Compare then
                        local bestEquippedLink, _, newScore, delta, isUpgrade, bestSlotID, isLevelTooHigh, minLevel = GSI_CompareEngine:Compare(link)
                        if newScore and isUpgrade and delta and delta > 0 and (not bestRealToast or delta > bestRealToast.scoreGain) then
                            local slotName = (bestSlotID and GSI_ClassicData.SlotNames and GSI_ClassicData.SlotNames[bestSlotID]) or equipLoc
                            if equipLoc == "INVTYPE_FINGER" and bestSlotID then
                                slotName = (bestSlotID == 12) and "Finger 2" or "Finger 1"
                            end
                            local replacedName = bestEquippedLink and GetItemInfo(bestEquippedLink) or nil
                            bestRealToast = {
                                itemName = name or "Upgraded Item",
                                itemLink = link,
                                idNum = tonumber(link:match("item:(%d+)")),
                                itemGUID = GetBagSlotGUID(bag, slot),
                                quality = quality or 2,
                                texture = texture or "Interface\\Icons\\inv_misc_questionmark",
                                scoreGain = delta,
                                slotName = slotName,
                                oldItemName = replacedName,
                                bag = bag,
                                slot = slot,
                                targetSlotID = bestSlotID,
                                bestSlotID = bestSlotID,
                                isLevelTooHigh = isLevelTooHigh,
                                minLevel = minLevel or reqLevel or 0,
                                isTestToast = false,
                            }
                        end
                    end
                end
            end
        end
    end

    if bestRealToast then
        -- Un-dismiss this item if it was previously dismissed so the user can test it freely
        if GearSetImproverDB and GearSetImproverDB.toastDismissedItems then
            if bestRealToast.itemGUID then GearSetImproverDB.toastDismissedItems[bestRealToast.itemGUID] = nil end
            if bestRealToast.itemLink then GearSetImproverDB.toastDismissedItems[bestRealToast.itemLink] = nil end
            if bestRealToast.idNum then GearSetImproverDB.toastDismissedItems[bestRealToast.idNum] = nil end
        end
        print("|cffffcc00[GearSetImprover]|r Showing real bag upgrade in toast: " .. (bestRealToast.itemLink or bestRealToast.itemName))
        self:DisplayToast(bestRealToast)
        return
    end

    -- 2. Fallback: Classic Thunderfury Demo Toast
    local demoItemLink = "|cffa335ee|Hitem:19019::::::::60:::::|h[Thunderfury, Blessed Blade of the Windseeker]|h|r"
    local demoItemName = "Thunderfury, Blessed Blade of the Windseeker"
    local demoTexture = 135274
    local demoQuality = 5

    if GetItemInfo then
        local n, _, q, _, _, _, _, _, _, tex = GetItemInfo(19019)
        if n and n ~= "" then
            demoItemName = n
            demoTexture = tex or demoTexture
            demoQuality = q or demoQuality
        end
    end

    local demoData = {
        itemName = demoItemName,
        itemLink = demoItemLink,
        idNum = 19019,
        quality = demoQuality,
        texture = demoTexture,
        scoreGain = 18.5,
        slotName = "One-Hand",
        oldItemName = "Krol Blade",
        bag = nil,
        slot = nil,
        targetSlotID = 16,
        bestSlotID = 16,
        isLevelTooHigh = false,
        minLevel = 60,
        isTestToast = true,
    }

    print("|cffffcc00[GearSetImprover]|r Triggering Plumber HUD Test Toast...")
    self:DisplayToast(demoData)
end

-- ------------------------------------------------------------
-- BAG SCAN & LOOT HOOKS (ItemGUID & ItemID Snapshot)
-- ------------------------------------------------------------
local function TakeBagSnapshot()
    local snap = {
        guids = {},
        idCounts = {},
        linkCounts = {},
        entries = {},
    }
    local numBags = GetMaxBagIndex()
    for bag = 0, numBags do
        local numSlots = GetNumBagSlots(bag)
        for slot = 1, numSlots do
            local idNum = GetBagSlotItemID(bag, slot)
            local link = GetBagItemLink(bag, slot)
            local guid = GetBagSlotGUID(bag, slot)
            if idNum or link or guid then
                if guid then
                    snap.guids[guid] = true
                end
                if idNum then
                    snap.idCounts[idNum] = (snap.idCounts[idNum] or 0) + 1
                end
                if link then
                    snap.linkCounts[link] = (snap.linkCounts[link] or 0) + 1
                end
                table.insert(snap.entries, {
                    bag = bag,
                    slot = slot,
                    idNum = idNum,
                    link = link,
                    guid = guid,
                })
            end
        end
    end
    return snap
end

function GSI_UpgradeToast:ScanForNewUpgrades()
    local db = GearSetImproverDB
    if db and (db.enableUpgradeToast == false or db.toastAlertsEnabled == false) then return end

    local currentSnap = TakeBagSnapshot()
    local prevGuids = bagSnapshot.guids or {}
    local prevIdCounts = bagSnapshot.idCounts or {}
    local evaluatedIdsWithoutGuid = {}

    for _, entry in ipairs(currentSnap.entries) do
        local isNewLoot = false
        if entry.guid then
            if not prevGuids[entry.guid] and not IsRecentlyUnequipped(entry.guid, entry.idNum) then
                isNewLoot = true
            end
        elseif entry.idNum and not evaluatedIdsWithoutGuid[entry.idNum] then
            local curCount = currentSnap.idCounts[entry.idNum] or 0
            local prevCount = prevIdCounts[entry.idNum] or 0
            if curCount > prevCount and not IsRecentlyUnequipped(nil, entry.idNum) then
                evaluatedIdsWithoutGuid[entry.idNum] = true
                isNewLoot = true
            end
        end

        if isNewLoot then
            local link = entry.link or GetBagItemLink(entry.bag, entry.slot)
            if link then
                self:EvaluateNewItem(link, entry.bag, entry.slot, entry.guid)
            elseif entry.idNum then
                pendingCacheQueue[entry.idNum] = {
                    link = "item:" .. tostring(entry.idNum),
                    bag = entry.bag,
                    slot = entry.slot,
                    guid = entry.guid,
                }
                if C_Item and C_Item.RequestLoadItemDataByID then
                    pcall(function() C_Item.RequestLoadItemDataByID(entry.idNum) end)
                end
            end
        end
    end

    bagSnapshot = currentSnap
    RefreshOverlaySecureAttributes()
end

function GSI_UpgradeToast:EvaluateNewItem(itemLink, bag, slot, itemGUID)
    if not itemLink then return end
    local db = GearSetImproverDB
    if db and (db.enableUpgradeToast == false or db.toastAlertsEnabled == false) then return end

    local itemID = itemLink:match("item:(%d+)")
    if not itemID then return end
    local idNum = tonumber(itemID)

    -- Refresh link from bag slot if only "item:ID" placeholder was queued earlier
    if bag ~= nil and slot ~= nil then
        local freshLink = GetBagItemLink(bag, slot)
        if freshLink and tonumber(freshLink:match("item:(%d+)")) == idNum then
            itemLink = freshLink
        end
        if not itemGUID then
            itemGUID = GetBagSlotGUID(bag, slot)
        end
    end

    -- Ignore items previously dismissed/equipped via Toast or already equipped
    if IsItemMarkedDismissed(itemLink, idNum, itemGUID) then
        return
    end
    if IsToastItemEquipped({ itemLink = itemLink, idNum = idNum, itemGUID = itemGUID }) then
        return
    end

    local name, _, quality, iLevel, reqLevel, classType, subType, _, equipLoc, texture = GetItemInfo(itemLink)
    if not equipLoc or equipLoc == "" or not name then
        pendingCacheQueue[idNum] = { link = itemLink, bag = bag, slot = slot, guid = itemGUID }
        if C_Item and C_Item.RequestLoadItemDataByID then
            pcall(function() C_Item.RequestLoadItemDataByID(idNum) end)
        end
        return
    end

    -- Non-equippable items and trinkets are ignored
    if equipLoc == "INVTYPE_NON_EQUIP" or equipLoc == "INVTYPE_TRINKET" then
        return
    end

    if not GSI_ClassicData or not GSI_ClassicData.EquipLocToSlot or not GSI_ClassicData.EquipLocToSlot[equipLoc] then
        return
    end

    -- Check if player's class can wear this weapon / armor
    if GSI_OptimizationEngine and GSI_OptimizationEngine.IsItemUsableForPlayer then
        if not GSI_OptimizationEngine:IsItemUsableForPlayer(itemLink, bag, slot, true) then
            return
        end
    end

    local bestEquippedLink = nil
    local bestEquippedScore = 0
    local newScore = 0
    local delta = 0
    local isUpgrade = false
    local bestSlotID = nil
    local isLevelTooHigh = false
    local minLevel = reqLevel or 0

    if GSI_CompareEngine and GSI_CompareEngine.Compare then
        bestEquippedLink, bestEquippedScore, newScore, delta, isUpgrade, bestSlotID, isLevelTooHigh, minLevel = GSI_CompareEngine:Compare(itemLink)
        if newScore == nil then
            pendingCacheQueue[idNum] = { link = itemLink, bag = bag, slot = slot, guid = itemGUID }
            return
        end
    else
        newScore = GSI_ItemScore and GSI_ItemScore:Calculate(itemLink)
        if not newScore or newScore <= 0 then return end

        local slotIDs = (GSI_ClassicData and GSI_ClassicData.GetEquipSlots and GSI_ClassicData:GetEquipSlots(equipLoc))
            or (GSI_ClassicData and GSI_ClassicData.EquipLocToSlots and GSI_ClassicData.EquipLocToSlots[equipLoc])
        if not slotIDs or #slotIDs == 0 then
            local singleSlot = GSI_ClassicData and GSI_ClassicData.EquipLocToSlot and GSI_ClassicData.EquipLocToSlot[equipLoc]
            if singleSlot then slotIDs = { singleSlot } else return end
        end

        local bestGain = -999999
        for _, sID in ipairs(slotIDs) do
            local eqLink = GetInventoryItemLink("player", sID)
            local eqScore = eqLink and GSI_ItemScore:Calculate(eqLink) or 0
            local d = newScore - eqScore
            if d > bestGain then
                bestGain = d
                delta = d
                bestSlotID = sID
                bestEquippedLink = eqLink
                bestEquippedScore = eqScore
            end
        end
        isUpgrade = (delta > 0)
        local playerLevel = UnitLevel("player") or 60
        minLevel = reqLevel or (select(5, GetItemInfo(itemLink))) or 0
        isLevelTooHigh = (minLevel > playerLevel)
    end

    if not isUpgrade or not delta then return end

    local threshold = (db and db.toastMinDelta) or (db and db.toastThreshold) or 1.0
    if delta < threshold then return end

    local playerLevel = UnitLevel("player") or 60
    if isLevelTooHigh and minLevel and (minLevel - playerLevel) > 3 then
        return
    end

    local now = GetTime and GetTime() or 0
    local dedupeKey = itemGUID or itemLink
    local lastTime = recentNotified[dedupeKey]
    if lastTime and (now - lastTime) < 8 then
        return
    end
    recentNotified[dedupeKey] = now

    local slotName = (bestSlotID and GSI_ClassicData.SlotNames and GSI_ClassicData.SlotNames[bestSlotID]) or equipLoc
    if equipLoc == "INVTYPE_FINGER" and bestSlotID then
        slotName = (bestSlotID == 12) and "Finger 2" or "Finger 1"
    end
    local replacedItemName = nil
    if bestEquippedLink then
        replacedItemName = GetItemInfo(bestEquippedLink)
    end

    self:ShowToast({
        itemName = name or "Upgraded Item",
        itemLink = itemLink,
        idNum = idNum,
        itemGUID = itemGUID,
        quality = quality or 2,
        texture = texture or "Interface\\Icons\\inv_misc_questionmark",
        scoreGain = delta,
        slotName = slotName,
        oldItemName = replacedItemName,
        bag = bag,
        slot = slot,
        targetSlotID = bestSlotID,
        bestSlotID = bestSlotID,
        isLevelTooHigh = isLevelTooHigh,
        minLevel = minLevel,
    })
end

function GSI_UpgradeToast:OnBagUpdate()
    self:CheckIfCurrentEquipped()
end

-- ------------------------------------------------------------
-- INITIALIZATION
-- ------------------------------------------------------------
function GSI_UpgradeToast:Initialize()
    if isInitialized then return end
    isInitialized = true

    UpdateEquippedSnapshot()
    bagSnapshot = TakeBagSnapshot()
    -- Pre-create the Toast Frame & ActionOverlay cleanly at login (out of combat)
    if not IsInCombat() then
        CreateToastFrame()
    end

    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("BAG_UPDATE")
    pcall(function() eventFrame:RegisterEvent("BAG_UPDATE_DELAYED") end)
    eventFrame:RegisterEvent("CHAT_MSG_LOOT")
    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
    pcall(function() eventFrame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED") end)
    pcall(function() eventFrame:RegisterEvent("EQUIPMENT_SWAP_FINISHED") end)
    pcall(function() eventFrame:RegisterEvent("UNIT_INVENTORY_CHANGED") end)

    local updateThrottled = false
    local equipFollowupGen = 0
    local function ScheduleEquipFollowupChecks(includeMissingScan)
        if not (C_Timer and C_Timer.After) then return end
        equipFollowupGen = equipFollowupGen + 1
        local myGen = equipFollowupGen
        C_Timer.After(0.15, function()
            if myGen ~= equipFollowupGen then return end
            UpdateEquippedSnapshot()
            if currentToast or #toastQueue > 0 then
                GSI_UpgradeToast:CheckIfCurrentEquipped()
            end
        end)
        if includeMissingScan then
            C_Timer.After(0.40, function()
                if myGen ~= equipFollowupGen then return end
                if currentToast or #toastQueue > 0 then
                    GSI_UpgradeToast:CheckIfCurrentEquipped(true)
                end
            end)
        end
    end

    eventFrame:SetScript("OnEvent", function(self, event, arg1)
        if event == "PLAYER_ENTERING_WORLD" then
            UpdateEquippedSnapshot()
            bagSnapshot = TakeBagSnapshot()
            if currentToast or #toastQueue > 0 then
                GSI_UpgradeToast:CheckIfCurrentEquipped()
            end
            RefreshOverlaySecureAttributes()
        elseif event == "PLAYER_EQUIPMENT_CHANGED" then
            UpdateEquippedSnapshot(tonumber(arg1))
            if currentToast or #toastQueue > 0 then
                GSI_UpgradeToast:CheckIfCurrentEquipped()
            end
            ScheduleEquipFollowupChecks(true)
        elseif event == "EQUIPMENT_SWAP_FINISHED" or (event == "UNIT_INVENTORY_CHANGED" and (not arg1 or arg1 == "player")) then
            UpdateEquippedSnapshot()
            if currentToast or #toastQueue > 0 then
                GSI_UpgradeToast:CheckIfCurrentEquipped()
            end
            ScheduleEquipFollowupChecks(false)
        elseif event == "PLAYER_REGEN_ENABLED" then
            RefreshOverlaySecureAttributes()
            if pendingCombatToast then
                local saved = pendingCombatToast
                pendingCombatToast = nil
                if currentToast == saved or not currentToast then
                    currentToast = saved
                    GSI_UpgradeToast:EquipPendingItem()
                end
            end
        elseif event == "BAG_UPDATE" or event == "BAG_UPDATE_DELAYED" or event == "CHAT_MSG_LOOT" then
            if currentToast or #toastQueue > 0 then
                GSI_UpgradeToast:CheckIfCurrentEquipped(event == "BAG_UPDATE_DELAYED")
            end
            if not updateThrottled then
                updateThrottled = true
                local timerFn = (C_Timer and C_Timer.After) or function(d, fn) fn() end
                timerFn(0.35, function()
                    updateThrottled = false
                    if currentToast or #toastQueue > 0 then
                        GSI_UpgradeToast:CheckIfCurrentEquipped(true)
                    end
                    GSI_UpgradeToast:ScanForNewUpgrades()
                end)
            end
        end
    end)
end

local loader = CreateFrame("Frame")
loader:RegisterEvent("PLAYER_LOGIN")
loader:SetScript("OnEvent", function(self)
    GSI_UpgradeToast:Initialize()
end)
