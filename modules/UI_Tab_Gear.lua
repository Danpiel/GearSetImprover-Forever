-- ============================================================================
-- GearSetImprover (GSI) -- UI_Tab_Gear.lua (WoW Forever)
-- Premium Design System: "Obsidian Glass & Specular Precision"
-- 17 Equipment Slots, Quality Micro-Borders & Delta Status Pills
-- ============================================================================

GSI_UI = GSI_UI or {}

local GetItemInfo = (C_Item and C_Item.GetItemInfo) or _G.GetItemInfo or function() return nil end
local BackdropTemplateMixin = _G.BackdropTemplateMixin
local BACKDROP_TEMPLATE = BackdropTemplateMixin and "BackdropTemplate" or nil

local function SkinFrame(f, s, t) if GSI_UI.SkinFrame then return GSI_UI:SkinFrame(f, s, t) end end
local function SkinCard(f, i) if GSI_UI.SkinCard then return GSI_UI:SkinCard(f, i) end end
local function SkinButton(b, r, p) if GSI_UI.SkinButton then return GSI_UI:SkinButton(b, r, p) end end
local function CreateText(p, s, t, j) if GSI_UI.CreateText then return GSI_UI:CreateText(p, s, t, j) end end
local function CreatePill(p, t, v) if GSI_UI.CreatePill then return GSI_UI:CreatePill(p, t, v) end end
local function ApplyMicroBorder(f, c, tc) if GSI_UI.ApplyMicroBorder then return GSI_UI:ApplyMicroBorder(f, c, tc) end end
local T = GSI_UI.THEME

-- ----------------------------------------------------------------------------
-- TAB 2: GEAR SLOTS
-- ----------------------------------------------------------------------------
function GSI_UI:DrawGear(parent)
    local T = self.THEME

    local title = CreateText(parent, "TITLE", "EQUIPPED GEAR (17 EQUIPMENT SLOTS)", "LEFT")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetPoint("TOPRIGHT", -16, -16)
    title:SetWordWrap(false)

    local sub = CreateText(parent, "SMALL", "Real-time slot analysis, item quality borders & upgrade availability from your bags:", "LEFT")
    sub:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -3)
    sub:SetPoint("TOPRIGHT", title, "BOTTOMRIGHT", 0, -3)
    sub:SetWordWrap(false)

    local scroll = CreateFrame("ScrollFrame", "GSI_GearScroll", parent, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", sub, "BOTTOMLEFT", -2, -12)
    scroll:SetPoint("BOTTOMRIGHT", -24, 12)
    if GSI_UI.SkinScrollBar then
        GSI_UI:SkinScrollBar(scroll)
    end

    local child = CreateFrame("Frame", nil, scroll)
    child:SetSize(700, 680)
    scroll:SetScrollChild(child)
    parent.scrollChild = child
    parent.slotRows = {}

    local yOff = 0
    for idx, slotID in ipairs(GSI_ClassicData.EQUIP_SLOTS or {}) do
        local row = CreateFrame("Frame", nil, child, BACKDROP_TEMPLATE)
        row:SetSize(696, 36)
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", child, "TOPLEFT", 0, -yOff)
        SkinCard(row, true)

        -- Slot Name Badge (SECTION style, clean uppercase)
        row.slotLabel = CreateText(row, "SECTION", string.upper(GSI_ClassicData.SlotNames[slotID] or ("Slot " .. slotID)), "LEFT")
        row.slotLabel:SetPoint("LEFT", 12, 0)
        row.slotLabel:SetWidth(100)
        row.slotLabel:SetWordWrap(false)

        -- Zoomed / Cropped Icon with Quality Border
        row.iconFrame = CreateFrame("Frame", nil, row)
        row.iconFrame:SetSize(26, 26)
        row.iconFrame:SetPoint("LEFT", row.slotLabel, "RIGHT", 4, 0)
        ApplyMicroBorder(row.iconFrame, T.borderSpecular)

        row.icon = row.iconFrame:CreateTexture(nil, "ARTWORK")
        row.icon:SetAllPoints()
        row.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

        -- Delta / Upgrade Status Pill
        row.pill = CreatePill(row, "OPTIMAL", "NEUTRAL")
        row.pill:SetPoint("RIGHT", -10, 0)

        -- Score (Mono-num, anchored before itemText so itemText cleanly clears scoreText)
        row.scoreText = CreateText(row, "MONO_NUM", "", "RIGHT")
        row.scoreText:SetPoint("RIGHT", -128, 0)
        row.scoreText:SetWordWrap(false)
        row.scoreText:SetTextColor(unpack(T.textPrimary))

        -- Item Link / Name (anchored cleanly between icon and scoreText)
        row.itemText = CreateText(row, "CARD_TITLE", "", "LEFT")
        row.itemText:SetPoint("LEFT", row.iconFrame, "RIGHT", 10, 0)
        row.itemText:SetPoint("RIGHT", row.scoreText, "LEFT", -10, 0)
        row.itemText:SetWordWrap(false)

        row:HookScript("OnEnter", function(selfRow)
            if selfRow.itemLink then
                GameTooltip:SetOwner(selfRow, "ANCHOR_RIGHT")
                GameTooltip:SetHyperlink(selfRow.itemLink)
                GameTooltip:Show()
            end
        end)
        row:HookScript("OnLeave", function()
            GameTooltip:Hide()
        end)

        parent.slotRows[slotID] = row
        yOff = yOff + 40
    end

    child:SetHeight(yOff + 20)
end

function GSI_UI:UpdateGear(parent)
    if not parent or not parent.slotRows then return end
    local T = self.THEME

    pcall(function() GSI_UI:UpdateTitleScore() end)
    local setup = {}
    pcall(function() setup = GSI_OptimizationEngine:GetCurrentSetup() end)

    local upgrades = GSI_UI.lastUpgrades or {}

    for _, slotID in ipairs(GSI_ClassicData.EQUIP_SLOTS or {}) do
        local row = parent.slotRows[slotID]
        if row then
            local itemObj = setup[slotID]
            local link = itemObj and itemObj.link

            if link then
                local score = GSI_ItemScore:Calculate(link, nil, nil, nil, slotID) or 0
                local itemName, _, itemQuality, _, _, _, _, _, _, itemTexture = GetItemInfo(link)

                row.itemLink = link
                row.icon:SetTexture(itemTexture or (GetItemIcon and GetItemIcon(link)) or "Interface\\Icons\\INV_Misc_QuestionMark")

                local qCol = T.quality[itemQuality or 1] or T.borderSpecular
                if row.iconFrame and row.iconFrame.SetBorderColor then
                    row.iconFrame:SetBorderColor(qCol[1], qCol[2], qCol[3], 1.0)
                end

                row.scoreText:SetText(string.format("%.1f", score))
                row.itemText:SetText(link)

                local up = upgrades[slotID]
                if up and up.delta and up.delta > 0.1 then
                    row.pill:SetPillStyle(string.format("+%.1f IN BAGS", up.delta), "SUCCESS")
                else
                    row.pill:SetPillStyle("OPTIMAL", "NEUTRAL")
                end
            else
                row.itemLink = nil
                row.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
                if row.iconFrame and row.iconFrame.SetBorderColor then
                    row.iconFrame:SetBorderColor(0.2, 0.2, 0.2, 0.5)
                end
                row.scoreText:SetText("-")
                row.itemText:SetText("|cff555562(Empty Slot)|r")
                row.pill:SetPillStyle("EMPTY", "DANGER")
            end
        end
    end
end
