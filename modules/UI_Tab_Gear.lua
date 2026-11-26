-- ============================================================================
-- GearSetImprover (GSI) -- UI_Tab_Gear.lua (WoW Forever)
-- Borderless 2-Column Character-Window Layout (17 Equipment Slots)
-- ============================================================================

GSI_UI = GSI_UI or {}

local L = GSI_L

local GetItemInfo = (C_Item and C_Item.GetItemInfo) or _G.GetItemInfo or function() return nil end
local GetItemInfoInstant = (C_Item and C_Item.GetItemInfoInstant) or _G.GetItemInfoInstant or function() return nil end
local GetItemIcon = _G.GSI_GetItemIcon or _G.GetItemIcon or function() return "Interface\\Icons\\INV_Misc_QuestionMark" end

local function CreateText(p, s, t, j) if GSI_UI.CreateText then return GSI_UI:CreateText(p, s, t, j) end end
local function CreatePill(p, t, v) if GSI_UI.CreatePill then return GSI_UI:CreatePill(p, t, v) end end
local function ApplyMicroBorder(f, c, tc) if GSI_UI.ApplyMicroBorder then return GSI_UI:ApplyMicroBorder(f, c, tc) end end
local function PP(pixels) return (GSI_UI.PP and GSI_UI:PP(pixels)) or (pixels or 1) end

-- Character-window slot order: Left (6), Right (8), Bottom Weapons (3)
local GEAR_LAYOUT = {
    -- Left column (PaperDoll left side)
    { slotID = 1,  token = "HeadSlot",          label = "Head",      x = 16,  y = -62,  fallbackTex = "Interface\\PaperDoll\\UI-PaperDoll-Slot-Head" },
    { slotID = 2,  token = "NeckSlot",          label = "Neck",      x = 16,  y = -106, fallbackTex = "Interface\\PaperDoll\\UI-PaperDoll-Slot-Neck" },
    { slotID = 3,  token = "ShoulderSlot",      label = "Shoulders", x = 16,  y = -150, fallbackTex = "Interface\\PaperDoll\\UI-PaperDoll-Slot-Shoulder" },
    { slotID = 15, token = "BackSlot",          label = "Back",      x = 16,  y = -194, fallbackTex = "Interface\\PaperDoll\\UI-PaperDoll-Slot-Chest" },
    { slotID = 5,  token = "ChestSlot",         label = "Chest",     x = 16,  y = -238, fallbackTex = "Interface\\PaperDoll\\UI-PaperDoll-Slot-Chest" },
    { slotID = 9,  token = "WristSlot",         label = "Wrists",    x = 16,  y = -282, fallbackTex = "Interface\\PaperDoll\\UI-PaperDoll-Slot-Wrists" },

    -- Right column (PaperDoll right side)
    { slotID = 10, token = "HandsSlot",         label = "Hands",     x = 386, y = -62,  fallbackTex = "Interface\\PaperDoll\\UI-PaperDoll-Slot-Hands" },
    { slotID = 6,  token = "WaistSlot",         label = "Waist",     x = 386, y = -106, fallbackTex = "Interface\\PaperDoll\\UI-PaperDoll-Slot-Waist" },
    { slotID = 7,  token = "LegsSlot",          label = "Legs",      x = 386, y = -150, fallbackTex = "Interface\\PaperDoll\\UI-PaperDoll-Slot-Legs" },
    { slotID = 8,  token = "FeetSlot",          label = "Feet",      x = 386, y = -194, fallbackTex = "Interface\\PaperDoll\\UI-PaperDoll-Slot-Feet" },
    { slotID = 11, token = "Finger0Slot",       label = "Finger 1",  x = 386, y = -238, fallbackTex = "Interface\\PaperDoll\\UI-PaperDoll-Slot-Finger" },
    { slotID = 12, token = "Finger1Slot",       label = "Finger 2",  x = 386, y = -282, fallbackTex = "Interface\\PaperDoll\\UI-PaperDoll-Slot-Finger" },
    { slotID = 13, token = "Trinket0Slot",      label = "Trinket 1", x = 386, y = -326, isTrinket = true, fallbackTex = "Interface\\PaperDoll\\UI-PaperDoll-Slot-Trinket" },
    { slotID = 14, token = "Trinket1Slot",      label = "Trinket 2", x = 386, y = -370, isTrinket = true, fallbackTex = "Interface\\PaperDoll\\UI-PaperDoll-Slot-Trinket" },

    -- Bottom weapon bar (PaperDoll bottom)
    { slotID = 16, token = "MainHandSlot",      label = "Main Hand", x = 16,  y = -426, fallbackTex = "Interface\\PaperDoll\\UI-PaperDoll-Slot-MainHand" },
    { slotID = 17, token = "SecondaryHandSlot", label = "Off Hand",  x = 386, y = -426, fallbackTex = "Interface\\PaperDoll\\UI-PaperDoll-Slot-SecondaryHand" },
    { slotID = 18, token = "RangedSlot",        label = "Ranged",    x = 201, y = -472, fallbackTex = "Interface\\PaperDoll\\UI-PaperDoll-Slot-Ranged" },
}

local function ResolveEmptySlotTexture(token, fallbackTex)
    if token and type(GetInventorySlotInfo) == "function" then
        local ok, _, tex = pcall(GetInventorySlotInfo, token)
        if ok and tex and tex ~= "" then return tex end
    end
    return fallbackTex or "Interface\\PaperDoll\\UI-Backpack-EmptySlot"
end

-- ----------------------------------------------------------------------------
-- TAB 2: GEAR SLOTS
-- ----------------------------------------------------------------------------
function GSI_UI:DrawGear(parent)
    local T = self.THEME

    local title = CreateText(parent, "TITLE", L["EQUIPPED GEAR (17 EQUIPMENT SLOTS)"], "LEFT")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetPoint("TOPRIGHT", -16, -16)
    title:SetWordWrap(false)

    local sub = CreateText(parent, "SMALL", L["Character-window layout with item quality borders, EP scores & bag upgrade status:"], "LEFT")
    sub:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -3)
    sub:SetPoint("TOPRIGHT", title, "BOTTOMRIGHT", 0, -3)
    sub:SetWordWrap(false)

    parent.slotRows = {}

    for _, def in ipairs(GEAR_LAYOUT) do
        local row = CreateFrame("Frame", nil, parent)
        row:SetSize(346, 42)
        row:SetPoint("TOPLEFT", parent, "TOPLEFT", def.x, def.y)
        row:EnableMouse(true)
        row.slotDef = def
        row.emptyTexture = ResolveEmptySlotTexture(def.token, def.fallbackTex)

        -- 1px subtle bottom divider (no card background or box border)
        local div = row:CreateTexture(nil, "ARTWORK")
        div:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 4, 0)
        div:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", -4, 0)
        div:SetHeight(PP(1))
        div:SetColorTexture(1, 1, 1, 0.07)
        row.divider = div

        -- Zoomed / Cropped Icon with Quality Micro-Border
        row.iconFrame = CreateFrame("Frame", nil, row)
        row.iconFrame:SetSize(30, 30)
        row.iconFrame:SetPoint("LEFT", row, "LEFT", 4, 0)
        ApplyMicroBorder(row.iconFrame, T.borderSpecular)

        row.icon = row.iconFrame:CreateTexture(nil, "ARTWORK")
        row.icon:SetAllPoints()
        row.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        row.icon:SetTexture(row.emptyTexture)
        row.icon:SetVertexColor(0.52, 0.55, 0.62, 0.85)
        if row.iconFrame.SetBorderColor then
            row.iconFrame:SetBorderColor(0.2, 0.2, 0.2, 0.5)
        end

        -- Delta / Upgrade Status Pill
        row.pill = CreatePill(row, L["EMPTY"], def.isTrinket and "NEUTRAL" or "DANGER")
        row.pill:SetPoint("RIGHT", row, "RIGHT", -4, 0)

        -- Score (Mono-num)
        row.scoreText = CreateText(row, "MONO_NUM", "-", "RIGHT")
        row.scoreText:SetPoint("RIGHT", row.pill, "LEFT", -8, 0)
        row.scoreText:SetWidth(46)
        row.scoreText:SetWordWrap(false)
        row.scoreText:SetTextColor(unpack(T.textPrimary))

        -- Top line: Item Link / Name
        row.itemText = CreateText(row, "CARD_TITLE", L["|cff555562Empty|r"], "LEFT")
        row.itemText:SetPoint("TOPLEFT", row.iconFrame, "TOPRIGHT", 8, -2)
        row.itemText:SetPoint("RIGHT", row.scoreText, "LEFT", -6, 0)
        row.itemText:SetWordWrap(false)

        -- Bottom line: Slot Name
        row.slotLabel = CreateText(row, "SMALL", string.upper(def.label), "LEFT")
        row.slotLabel:SetPoint("BOTTOMLEFT", row.iconFrame, "BOTTOMRIGHT", 8, 2)
        row.slotLabel:SetPoint("RIGHT", row.scoreText, "LEFT", -6, 0)
        row.slotLabel:SetWordWrap(false)

        row:SetScript("OnEnter", function(selfRow)
            if selfRow.divider then
                selfRow.divider:SetColorTexture(1, 1, 1, 0.18)
            end
            if selfRow.itemLink then
                GameTooltip:SetOwner(selfRow, "ANCHOR_RIGHT")
                if selfRow.slotDef and selfRow.slotDef.slotID then
                    local ok = pcall(GameTooltip.SetInventoryItem, GameTooltip, "player", selfRow.slotDef.slotID)
                    if not ok then
                        GameTooltip:SetHyperlink(selfRow.itemLink)
                    end
                else
                    GameTooltip:SetHyperlink(selfRow.itemLink)
                end
                GameTooltip:Show()
            end
        end)
        row:SetScript("OnLeave", function(selfRow)
            if selfRow.divider then
                selfRow.divider:SetColorTexture(1, 1, 1, 0.07)
            end
            GameTooltip:Hide()
        end)

        parent.slotRows[def.slotID] = row
    end
end

function GSI_UI:UpdateGear(parent)
    if not parent or not parent.slotRows then return end
    local T = self.THEME

    pcall(function() GSI_UI:UpdateTitleScore() end)
    local setup = {}
    pcall(function() setup = GSI_OptimizationEngine:GetCurrentSetup() end)

    local upgrades = GSI_UI.lastUpgrades or {}

    -- Detect if a 2H weapon is equipped in Main Hand
    local mhLink = (setup[16] and setup[16].link) or (GetInventoryItemLink and GetInventoryItemLink("player", 16))
    local isTwoHanded = false
    if mhLink then
        local equipLoc = select(9, GetItemInfo(mhLink))
        if not equipLoc or equipLoc == "" then
            equipLoc = select(4, GetItemInfoInstant(mhLink))
        end
        isTwoHanded = (equipLoc == "INVTYPE_2HWEAPON")
    end

    for _, def in ipairs(GEAR_LAYOUT) do
        local slotID = def.slotID
        local row = parent.slotRows[slotID]
        if row then
            local itemObj = setup[slotID]
            local link = (itemObj and itemObj.link) or (GetInventoryItemLink and GetInventoryItemLink("player", slotID))

            if link then
                row:SetAlpha(1.0)
                local itemName, _, itemQuality, _, _, _, _, _, _, itemTexture = GetItemInfo(link)

                row.itemLink = link
                row.icon:SetTexture(itemTexture or GetItemIcon(link) or row.emptyTexture)
                row.icon:SetVertexColor(1, 1, 1, 1)

                local qCol = T.quality[itemQuality or 1] or T.borderSpecular
                if row.iconFrame and row.iconFrame.SetBorderColor then
                    row.iconFrame:SetBorderColor(qCol[1], qCol[2], qCol[3], 1.0)
                end

                local displayLink = (GSI_UI.ResolveItemDisplayText and GSI_UI:ResolveItemDisplayText(link, slotID)) or link
                row.itemText:SetText(displayLink)

                if def.isTrinket then
                    row.scoreText:SetText("-")
                    row.pill:SetPillStyle(L["EQUIPPED"], "NEUTRAL")
                else
                    local okCalc, calcScore = pcall(function()
                        return GSI_ItemScore:Calculate(link, nil, nil, nil, slotID)
                    end)
                    if okCalc and type(calcScore) == "number" then
                        row.scoreText:SetText(string.format("%.1f", calcScore))
                    else
                        row.scoreText:SetText("...")
                    end

                    local up = upgrades[slotID]
                    if up and up.delta and up.delta > 0.1 then
                        row.pill:SetPillStyle(string.format("+%.1f", up.delta), "SUCCESS")
                    else
                        row.pill:SetPillStyle(L["OPTIMAL"], "NEUTRAL")
                    end
                end
            else
                row.itemLink = nil
                row.icon:SetTexture(row.emptyTexture)
                row.icon:SetVertexColor(0.52, 0.55, 0.62, 0.85)
                if row.iconFrame and row.iconFrame.SetBorderColor then
                    row.iconFrame:SetBorderColor(0.2, 0.2, 0.2, 0.5)
                end
                row.scoreText:SetText("-")

                if slotID == 17 and isTwoHanded then
                    row:SetAlpha(0.5)
                    row.itemText:SetText(L["|cff666e80(2H Equipped)|r"])
                    row.pill:SetPillStyle(L["2H ACTIVE"], "NEUTRAL")
                else
                    row:SetAlpha(1.0)
                    row.itemText:SetText(L["|cff555562Empty|r"])
                    row.pill:SetPillStyle(L["EMPTY"], def.isTrinket and "NEUTRAL" or "DANGER")
                end
            end
        end
    end
end
