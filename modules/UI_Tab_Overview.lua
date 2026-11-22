-- ============================================================================
-- GearSetImprover (GSI) -- UI_Tab_Overview.lua (WoW Forever)
-- Premium Design System: "Obsidian Glass & Specular Precision"
-- Hero Character Card, 3D Player Model, 3 KPI Metrics & Stat Weights Chart
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
local function ApplyMicroBorder(f, c, tc) if GSI_UI.ApplyMicroBorder then return GSI_UI:ApplyMicroBorder(f, c, tc) end end
local function FormatWeight(v) return GSI_UI.FormatWeight and GSI_UI:FormatWeight(v) or tostring(v) end
local function FormatStatValue(k, v) return GSI_UI.FormatStatValue and GSI_UI:FormatStatValue(k, v) or tostring(v) end
local STAT_DISPLAY_NAMES = GSI_UI.STAT_DISPLAY_NAMES or {}
local EXTRA_STAT_DISPLAY_NAMES = {
    ArmorPenetration = "Armor Penetration",
    Mana = "Mana",
    Speed = "Movement Speed (%)",
    FlatWeaponDamage = "Weapon Damage (Flat)",
    WeaponSpeed = "Weapon Speed (Sec)",
    HP5 = "Health / 5s (HP5)",
}
local T = GSI_UI.THEME

-- ----------------------------------------------------------------------------
-- TAB 1: OVERVIEW
-- ----------------------------------------------------------------------------
function GSI_UI:DrawOverview(parent)
    local T = self.THEME

    -- 1. HERO CHARACTER CARD (Height: 165px)
    local hero = CreateFrame("Frame", nil, parent, BACKDROP_TEMPLATE)
    hero:SetPoint("TOPLEFT", 16, -16)
    hero:SetPoint("TOPRIGHT", -20, -16)
    hero:SetHeight(165)
    SkinCard(hero, false)
    parent.hero = hero

    -- 3D Character Model inside recessed Obsidian Well
    local modelWell = CreateFrame("PlayerModel", nil, hero)
    modelWell:SetSize(120, 137)
    modelWell:SetPoint("LEFT", 14, 0)
    SkinFrame(modelWell, T.bgInput, false)
    if modelWell.SetUnit then pcall(function() modelWell:SetUnit("player") end) end
    if modelWell.SetPosition then pcall(function() modelWell:SetPosition(0, 0, 0) end) end
    if modelWell.SetRotation then pcall(function() modelWell:SetRotation(0) end) end
    hero.model = modelWell

    -- Character Info Header (Name, Level, Race, Class)
    hero.nameText = CreateText(hero, "TITLE", "", "LEFT")
    hero.nameText:SetPoint("TOPLEFT", modelWell, "TOPRIGHT", 18, -4)
    hero.nameText:SetPoint("TOPRIGHT", hero, "TOPRIGHT", -16, -18)
    hero.nameText:SetWordWrap(false)

    hero.specText = CreateText(hero, "BODY", "", "LEFT")
    hero.specText:SetPoint("TOPLEFT", hero.nameText, "BOTTOMLEFT", 0, -4)
    hero.specText:SetPoint("TOPRIGHT", hero.nameText, "BOTTOMRIGHT", 0, -4)
    hero.specText:SetWordWrap(false)
    hero.specText:SetTextColor(unpack(T.textSecondary))

    -- 3 KPI Metric Cards
    hero.kpiCards = {}
    local kpiDefs = {
        { id = "SCORE",   label = "EQUIPPED SCORE",   defVal = "0.0",   defPill = "OPTIMAL",     variant = "ACCENT" },
        { id = "UPGRADE", label = "BAG UPGRADES",     defVal = "+0.0",  defPill = "UP TO DATE", variant = "SUCCESS" },
        { id = "WEAKEST", label = "WEAKEST SLOT",     defVal = "-",      defPill = "BALANCED",   variant = "WARNING" },
    }

    for i, def in ipairs(kpiDefs) do
        local box = CreateFrame("Frame", nil, hero, BACKDROP_TEMPLATE)
        box:SetSize(166, 76)
        box:SetPoint("BOTTOMLEFT", modelWell, "BOTTOMRIGHT", 18 + ((i - 1) * 176), 0)
        SkinCard(box, true)

        box.lbl = CreateText(box, "SMALL", def.label, "LEFT")
        box.lbl:SetPoint("TOPLEFT", 12, -8)
        box.lbl:SetPoint("TOPRIGHT", -10, -8)
        box.lbl:SetWordWrap(false)

        box.val = CreateText(box, "TITLE", def.defVal, "LEFT")
        box.val:SetPoint("TOPLEFT", box.lbl, "BOTTOMLEFT", 0, -3)
        box.val:SetPoint("TOPRIGHT", box.lbl, "BOTTOMRIGHT", 0, -3)
        box.val:SetWordWrap(false)

        box.pill = CreatePill(box, def.defPill, def.variant)
        box.pill:SetPoint("BOTTOMLEFT", 10, 8)

        box:SetScript("OnMouseUp", function()
            if PlaySound and SOUNDKIT then PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON) end
            if def.id == "UPGRADE" then
                GSI_UI:SelectTab("BIB")
                if GSI_UI.RunOptimization then GSI_UI:RunOptimization() end
            else
                GSI_UI:SelectTab("GEAR")
            end
        end)

        hero.kpiCards[def.id] = box
    end

    -- 2. STAT WEIGHTS SECTION HEADER
    local refreshBtn = CreateFrame("Button", nil, parent, BACKDROP_TEMPLATE)
    refreshBtn:SetSize(100, 24)
    refreshBtn:SetPoint("BOTTOMRIGHT", hero, "BOTTOMRIGHT", 0, -34)
    refreshBtn:SetText("Refresh")
    SkinButton(refreshBtn, "Refresh", "SECONDARY")
    refreshBtn:SetScript("OnClick", function()
        if GSI_ItemScore and GSI_ItemScore.ResetCache then GSI_ItemScore:ResetCache() end
        if GSI_OptimizationEngine and GSI_OptimizationEngine.ResetCache then GSI_OptimizationEngine:ResetCache() end
        GSI_UI:UpdateOverview(parent)
    end)
    parent.refreshBtn = refreshBtn

    local sectionTitle = CreateText(parent, "CARD_TITLE", "STAT WEIGHT SCALING & RELATIVE ATTRIBUTES", "LEFT")
    sectionTitle:SetPoint("TOPLEFT", hero, "BOTTOMLEFT", 2, -18)
    sectionTitle:SetPoint("TOPRIGHT", refreshBtn, "TOPLEFT", -12, -8)
    sectionTitle:SetWordWrap(false)

    local sectionSub = CreateText(parent, "SMALL", "Calculated relative importance for your active spec & gear values:", "LEFT")
    sectionSub:SetPoint("TOPLEFT", sectionTitle, "BOTTOMLEFT", 0, -3)
    sectionSub:SetPoint("TOPRIGHT", sectionTitle, "BOTTOMRIGHT", 0, -3)
    sectionSub:SetWordWrap(false)

    -- 3. SCROLL FRAME FOR STAT WEIGHT CARDS
    local scroll = CreateFrame("ScrollFrame", "GSI_OverviewScroll", parent, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", sectionSub, "BOTTOMLEFT", -2, -12)
    scroll:SetPoint("BOTTOMRIGHT", -24, 12)
    if GSI_UI.SkinScrollBar then
        GSI_UI:SkinScrollBar(scroll)
    end

    local child = CreateFrame("Frame", nil, scroll)
    child:SetSize(700, 500)
    scroll:SetScrollChild(child)
    parent.scrollChild = child
    parent.statRows = {}
end

function GSI_UI:UpdateOverview(parent)
    if not parent or not parent.scrollChild then return end
    local T = self.THEME

    pcall(function() GSI_UI:UpdateTitleScore() end)

    -- 1. Refresh Hero Card Data
    if parent.hero then
        local hero = parent.hero
        local pName = UnitName("player") or "Player"
        local pLevel = UnitLevel("player") or 60
        local pRace = UnitRace("player") or ""
        local pClass = select(1, UnitClass("player")) or ""
        hero.nameText:SetText(string.format("%s — Level %d %s %s", pName, pLevel, pRace, pClass))

        local specIndex = GSI_StatWeights:GetActiveSpecIndex()
        local class = select(2, UnitClass("player")) or "WARRIOR"
        local classData = GSI_ClassicData and GSI_ClassicData.Classes and GSI_ClassicData.Classes[class]
        local specData = classData and classData.specs and classData.specs[specIndex]
        local specName = specData and (specData.name or specData.nameDE) or ("Spec " .. specIndex)

        local role = GSI_StatWeights:GetRole()
        local modeLabel = ""
        if role == "tank" then
            local tMode = (GearSetImproverDB and GearSetImproverDB.tankMode) or "Survival"
            modeLabel = (tMode == "Survival") and "Survival Tank" or "Threat / DPS"
        else
            local wMode = (GearSetImproverDB and GearSetImproverDB.weightMode) or "ST"
            modeLabel = (wMode == "ST") and "Single Target" or "AoE / Trash"
        end
        hero.specText:SetText(string.format("Active Profile: %s (%s)", specName, modeLabel))

        if hero.model and hero.model.SetUnit then
            pcall(function() hero.model:SetUnit("player") end)
        end

        -- Calculate Score & Weakest Slot
        local setup = {}
        pcall(function() setup = GSI_OptimizationEngine:GetCurrentSetup() end)
        local totalScore = 0
        if GSI_OptimizationEngine and GSI_OptimizationEngine.EvaluateSetup then
            local ok, s = pcall(function() return GSI_OptimizationEngine:EvaluateSetup(setup) end)
            if ok and type(s) == "number" then totalScore = s end
        end

        local lowestSlot = "-"
        local lowestScore = nil
        local lowestIsEmpty = false
        local mhObj = setup[INVSLOT_MAINHAND]
        local isTwoHanded = false
        if mhObj and mhObj.link then
            local equipLoc = select(9, GetItemInfo(mhObj.link))
            if not equipLoc or equipLoc == "" then
                equipLoc = select(4, GetItemInfoInstant(mhObj.link))
            end
            if equipLoc == "INVTYPE_2HWEAPON" then
                isTwoHanded = true
            end
        end
        local isFeralDruid = (class == "DRUID" and (specIndex == 2 or specIndex == 3))

        local equipSlots = (GSI_OptimizationEngine and GSI_OptimizationEngine.EQUIP_SLOTS)
            or (GSI_ClassicData and GSI_ClassicData.EQUIP_SLOTS) or {}
        for _, sID in ipairs(equipSlots) do
            if sID ~= (INVSLOT_TRINKET1 or 13) and sID ~= (INVSLOT_TRINKET2 or 14)
                and not (sID == INVSLOT_OFFHAND and (isTwoHanded or isFeralDruid)) then
                local itemObj = setup[sID]
                local link = itemObj and itemObj.link
                if link then
                    local sc = GSI_ItemScore:Calculate(link, nil, nil, nil, sID) or 0
                    if not lowestIsEmpty and (lowestScore == nil or sc < lowestScore) then
                        lowestScore = sc
                        lowestSlot = (GSI_ClassicData and GSI_ClassicData.SlotNames and GSI_ClassicData.SlotNames[sID]) or ("Slot " .. sID)
                    end
                else
                    lowestScore = 0
                    lowestSlot = (GSI_ClassicData and GSI_ClassicData.SlotNames and GSI_ClassicData.SlotNames[sID]) or ("Slot " .. sID)
                    lowestIsEmpty = true
                    break
                end
            end
        end

        -- Update KPI 1: SCORE
        if hero.kpiCards and hero.kpiCards.SCORE then
            hero.kpiCards.SCORE.val:SetText(string.format("%.1f", totalScore))
            hero.kpiCards.SCORE.pill:SetPillStyle("ACTIVE PROFILE", "ACCENT")
        end

        -- Update KPI 2: BAG UPGRADES
        if hero.kpiCards and hero.kpiCards.UPGRADE then
            local lastGain = GSI_UI.lastTotalGain or 0
            local upgrades = GSI_UI.lastUpgrades or {}
            local upCount = 0
            for _ in pairs(upgrades) do upCount = upCount + 1 end

            if upCount > 0 and lastGain > 0.05 then
                hero.kpiCards.UPGRADE.val:SetText(string.format("+%.1f", lastGain))
                hero.kpiCards.UPGRADE.pill:SetPillStyle(string.format("%d READY", upCount), "SUCCESS")
            else
                hero.kpiCards.UPGRADE.val:SetText("+0.0")
                hero.kpiCards.UPGRADE.pill:SetPillStyle("UP TO DATE", "ACCENT")
            end
        end

        -- Update KPI 3: WEAKEST SLOT
        if hero.kpiCards and hero.kpiCards.WEAKEST then
            hero.kpiCards.WEAKEST.val:SetText(lowestSlot)
            if lowestIsEmpty then
                hero.kpiCards.WEAKEST.pill:SetPillStyle("EMPTY SLOT", "DANGER")
            elseif lowestScore == nil then
                hero.kpiCards.WEAKEST.pill:SetPillStyle("NONE", "NEUTRAL")
            else
                hero.kpiCards.WEAKEST.pill:SetPillStyle(string.format("%.0f", lowestScore), "WARNING")
            end
        end
    end

    -- 2. Refresh Stat Weights Chart
    local scrollChild = parent.scrollChild
    local weights = {}
    pcall(function() weights = GSI_StatWeights:GetWeights() end)
    local setup = {}
    pcall(function() setup = GSI_OptimizationEngine:GetCurrentSetup() end)
    local currentStats = {}
    pcall(function() currentStats = GSI_OptimizationEngine:CalculateStats(setup) end)

    local sorted = {}
    local maxWeight = 0.001
    for statKey, w in pairs(weights or {}) do
        if w and w > 0 then
            table.insert(sorted, { stat = statKey, weight = w })
            if w > maxWeight then maxWeight = w end
        end
    end
    table.sort(sorted, function(a, b) return (a.weight or 0) > (b.weight or 0) end)

    if not parent.statRows then parent.statRows = {} end
    for _, r in ipairs(parent.statRows) do r:Hide() end

    local yOff = 0
    for i, entry in ipairs(sorted) do
        local row = parent.statRows[i]
        if not row then
            row = CreateFrame("Frame", nil, scrollChild, BACKDROP_TEMPLATE)
            row:SetSize(696, 32)
            SkinCard(row, true)

            -- Stat Label
            row.label = CreateText(row, "BODY", "", "LEFT")
            row.label:SetPoint("LEFT", 14, 0)
            row.label:SetWidth(170)
            row.label:SetWordWrap(false)

            -- Recessed Bar Track
            local barTrack = CreateFrame("Frame", nil, row, BACKDROP_TEMPLATE)
            barTrack:SetPoint("LEFT", row.label, "RIGHT", 8, 0)
            barTrack:SetSize(280, 10)
            SkinFrame(barTrack, T.bgInput, false)
            row.barTrack = barTrack

            -- Active Fill Bar (Dynamic Class Color)
            row.bar = barTrack:CreateTexture(nil, "ARTWORK")
            row.bar:SetPoint("TOPLEFT", barTrack, "TOPLEFT", 1, -1)
            row.bar:SetPoint("BOTTOMLEFT", barTrack, "BOTTOMLEFT", 1, 1)
            row.bar:SetColorTexture(unpack(T.accent))

            -- Current Stat Value Pill (anchored before valStr so valStr stays clear)
            row.currentPill = CreatePill(row, "0", "NEUTRAL")
            row.currentPill:SetPoint("RIGHT", -12, 0)

            -- Weight String (Mono-num)
            row.valStr = CreateText(row, "MONO_NUM", "", "LEFT")
            row.valStr:SetPoint("LEFT", barTrack, "RIGHT", 14, 0)
            row.valStr:SetPoint("RIGHT", row.currentPill, "LEFT", -10, 0)
            row.valStr:SetWordWrap(false)
            row.valStr:SetTextColor(unpack(T.textPrimary))

            row:HookScript("OnEnter", function(selfRow)
                if selfRow.tooltipData then
                    GameTooltip:SetOwner(selfRow, "ANCHOR_RIGHT")
                    GameTooltip:AddLine(selfRow.tooltipData.name, T.accent[1], T.accent[2], T.accent[3])
                    GameTooltip:AddLine(string.format("Weight: %s", selfRow.tooltipData.weight), 1, 1, 1)
                    GameTooltip:AddLine(string.format("Current equipped stat: %s", selfRow.tooltipData.val), T.success[1], T.success[2], T.success[3])
                    GameTooltip:Show()
                end
            end)
            row:HookScript("OnLeave", function()
                GameTooltip:Hide()
            end)

            parent.statRows[i] = row
        end

        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -yOff)
        local displayName = STAT_DISPLAY_NAMES[entry.stat] or EXTRA_STAT_DISPLAY_NAMES[entry.stat] or entry.stat
        local statVal = currentStats[entry.stat] or 0
        local barWidth = math.max(2, 276 * (entry.weight / maxWeight))

        row.label:SetText(displayName)
        row.bar:SetWidth(barWidth)
        row.bar:SetColorTexture(unpack(T.accent))
        row.currentPill:SetPillStyle(FormatStatValue(entry.stat, statVal), "NEUTRAL")
        row.valStr:SetText(FormatWeight(entry.weight))
        row.tooltipData = {
            name = displayName,
            weight = FormatWeight(entry.weight),
            val = FormatStatValue(entry.stat, statVal),
        }
        row:Show()

        yOff = yOff + 36
    end

    scrollChild:SetHeight(math.max(yOff + 10, 10))
end
