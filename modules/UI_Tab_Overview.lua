-- ============================================================================
-- GearSetImprover (GSI) -- UI_Tab_Overview.lua (WoW Forever)
-- Premium Design System: "Obsidian Glass & Specular Precision"
-- Hero Character Card, 3D Player Model, 3 KPI Metrics & Stat Weights Chart
-- ============================================================================

GSI_UI = GSI_UI or {}

local L = GSI_L

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
    ArmorPenetration = L["Armor Penetration"],
    Mana = L["Mana"],
    Speed = L["Movement Speed (%)"],
    FlatWeaponDamage = L["Weapon Damage (Flat)"],
    WeaponSpeed = L["Weapon Speed (Sec)"],
    HP5 = L["Health / 5s (HP5)"],
}
local T = GSI_UI.THEME

-- ----------------------------------------------------------------------------
-- TAB 1: OVERVIEW
-- ----------------------------------------------------------------------------
function GSI_UI:DrawOverview(parent)
    local T = self.THEME

    local cr, cg, cb = GSI_UI:GetClassColor()
    local pp1 = (GSI_UI.PP and GSI_UI:PP(1)) or 1
    local pp2 = (GSI_UI.PP and GSI_UI:PP(2)) or 2

    -- 1. FRAMELESS HERO SECTION (Height: 148px, bottom hairline + class glow)
    local hero = CreateFrame("Frame", nil, parent)
    hero:SetPoint("TOPLEFT", 16, -14)
    hero:SetPoint("TOPRIGHT", -20, -14)
    hero:SetHeight(148)
    parent.hero = hero

    hero.bottomLine = hero:CreateTexture(nil, "ARTWORK")
    hero.bottomLine:SetPoint("BOTTOMLEFT", hero, "BOTTOMLEFT", 0, 0)
    hero.bottomLine:SetPoint("BOTTOMRIGHT", hero, "BOTTOMRIGHT", 0, 0)
    hero.bottomLine:SetHeight(pp1)
    hero.bottomLine:SetColorTexture(1, 1, 1, 0.08)

    hero.bottomGlow = hero:CreateTexture(nil, "OVERLAY")
    hero.bottomGlow:SetPoint("BOTTOMLEFT", hero, "BOTTOMLEFT", 0, 0)
    hero.bottomGlow:SetSize(220, pp2)
    hero.bottomGlow:SetTexture("Interface\\Buttons\\WHITE8x8")
    GSI_UI:SetGradient(hero.bottomGlow, "HORIZONTAL", cr, cg, cb, 0.65, cr, cg, cb, 0.0)

    -- Frameless Floating 3D Character Portrait with subtle class aura
    local modelWell = CreateFrame("PlayerModel", nil, hero)
    modelWell:SetSize(112, 134)
    modelWell:SetPoint("BOTTOMLEFT", hero, "BOTTOMLEFT", 4, 4)
    if modelWell.SetUnit then pcall(function() modelWell:SetUnit("player") end) end
    if modelWell.SetPosition then pcall(function() modelWell:SetPosition(0, 0, 0) end) end
    if modelWell.SetRotation then pcall(function() modelWell:SetRotation(0) end) end
    modelWell._rot = 0
    modelWell:EnableMouse(true)
    modelWell:SetScript("OnMouseDown", function(selfM, btn)
        if btn == "LeftButton" then
            selfM._dragging = true
            selfM._lastX = GetCursorPosition and select(1, GetCursorPosition()) or 0
        end
    end)
    modelWell:SetScript("OnMouseUp", function(selfM)
        selfM._dragging = false
    end)
    modelWell:SetScript("OnUpdate", function(selfM)
        if selfM._dragging and GetCursorPosition and selfM.SetRotation then
            local x = select(1, GetCursorPosition())
            local dx = x - (selfM._lastX or x)
            selfM._lastX = x
            selfM._rot = (selfM._rot or 0) + dx * 0.015
            pcall(selfM.SetRotation, selfM, selfM._rot)
        end
    end)
    hero.model = modelWell

    hero.modelGlow = hero:CreateTexture(nil, "BACKGROUND")
    hero.modelGlow:SetSize(104, 58)
    hero.modelGlow:SetPoint("BOTTOM", modelWell, "BOTTOM", 0, 2)
    hero.modelGlow:SetTexture("Interface\\Buttons\\WHITE8x8")
    GSI_UI:SetGradient(hero.modelGlow, "VERTICAL", cr, cg, cb, 0.16, cr, cg, cb, 0.0)

    hero.modelBase = hero:CreateTexture(nil, "ARTWORK")
    hero.modelBase:SetSize(72, pp2)
    hero.modelBase:SetPoint("BOTTOM", modelWell, "BOTTOM", 0, 0)
    hero.modelBase:SetColorTexture(cr, cg, cb, 0.55)

    -- Character Info Header (Name, Level, Race, Class)
    hero.nameText = CreateText(hero, "LARGE", "", "LEFT")
    hero.nameText:SetPoint("TOPLEFT", modelWell, "TOPRIGHT", 22, -4)
    hero.nameText:SetPoint("TOPRIGHT", hero, "TOPRIGHT", -8, -4)
    hero.nameText:SetWordWrap(false)

    hero.specIcon = hero:CreateTexture(nil, "ARTWORK")
    hero.specIcon:SetSize(14, 14)
    hero.specIcon:SetPoint("TOPLEFT", hero.nameText, "BOTTOMLEFT", 0, -5)
    hero.specIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    hero.specText = CreateText(hero, "BODY", "", "LEFT")
    hero.specText:SetPoint("LEFT", hero.specIcon, "RIGHT", 6, 0)
    hero.specText:SetPoint("RIGHT", hero, "RIGHT", -8, 0)
    hero.specText:SetWordWrap(false)
    hero.specText:SetTextColor(unpack(T.textSecondary))

    -- 3 Flat Borderless KPI Columns separated by 1px vertical hairlines
    hero.kpiCards = {}
    local kpiDefs = {
        { id = "SCORE",   label = L["EQUIPPED SCORE"], defVal = "0.0",  defPill = "ACTIVE PROFILE", variant = "ACCENT",  tip = "Total Equivalency Point (EP) score of your equipped gear." },
        { id = "UPGRADE", label = L["BAG UPGRADES"],   defVal = "+0.0", defPill = L["UP TO DATE"],     variant = "SUCCESS", tip = "Click to open Best Available and scan your bags." },
        { id = "WEAKEST", label = L["WEAKEST SLOT"],   defVal = "-",    defPill = L["BALANCED"],       variant = "WARNING", tip = "Click to inspect all 17 equipment slots." },
    }

    for i, def in ipairs(kpiDefs) do
        local box = CreateFrame("Frame", nil, hero)
        box:SetSize(172, 68)
        box:SetPoint("BOTTOMLEFT", modelWell, "BOTTOMRIGHT", 22 + ((i - 1) * 186), 8)
        box:EnableMouse(true)

        if i > 1 then
            local vDiv = box:CreateTexture(nil, "ARTWORK")
            vDiv:SetSize(pp1, 46)
            vDiv:SetPoint("LEFT", box, "LEFT", -10, 0)
            vDiv:SetColorTexture(1, 1, 1, 0.08)
        end

        box.lbl = CreateText(box, "SMALL", def.label, "LEFT")
        box.lbl:SetPoint("TOPLEFT", 0, -2)
        box.lbl:SetPoint("TOPRIGHT", 0, -2)
        box.lbl:SetWordWrap(false)

        box.val = CreateText(box, "LARGE", def.defVal, "LEFT")
        box.val:SetPoint("TOPLEFT", box.lbl, "BOTTOMLEFT", 0, -4)
        box.val:SetPoint("TOPRIGHT", box.lbl, "BOTTOMRIGHT", 0, -4)
        box.val:SetWordWrap(false)

        box.dot = box:CreateTexture(nil, "ARTWORK")
        box.dot:SetSize(5, 5)
        box.dot:SetPoint("TOPLEFT", box.val, "BOTTOMLEFT", 0, -7)

        box.statusText = CreateText(box, "SMALL", def.defPill, "LEFT")
        box.statusText:SetPoint("LEFT", box.dot, "RIGHT", 6, 0)
        box.statusText:SetPoint("RIGHT", box, "RIGHT", 0, 0)
        box.statusText:SetWordWrap(false)

        box.accentLine = box:CreateTexture(nil, "ARTWORK")
        box.accentLine:SetPoint("BOTTOMLEFT", box, "BOTTOMLEFT", 0, 0)
        box.accentLine:SetSize(30, pp2)

        function box:SetMetricStyle(statusLabel, variant)
            local r, g, b = T.textMuted[1], T.textMuted[2], T.textMuted[3]
            if variant == "ACCENT" then
                local acr, acg, acb = GSI_UI:GetClassColor()
                r, g, b = math.min(1, acr + 0.18), math.min(1, acg + 0.18), math.min(1, acb + 0.18)
            elseif variant == "SUCCESS" then
                r, g, b = T.success[1], T.success[2], T.success[3]
            elseif variant == "WARNING" then
                r, g, b = T.warning[1], T.warning[2], T.warning[3]
            elseif variant == "DANGER" then
                r, g, b = T.danger[1], T.danger[2], T.danger[3]
            end
            self.dot:SetColorTexture(r, g, b, 1.0)
            self.statusText:SetText(statusLabel or "")
            self.statusText:SetTextColor(r, g, b, 1.0)
            self.accentLine:SetColorTexture(r, g, b, self._hovered and 1.0 or 0.55)
            self._accentRGB = { r, g, b }
        end

        box:SetMetricStyle(def.defPill, def.variant)

        box:SetScript("OnEnter", function(selfBox)
            selfBox._hovered = true
            selfBox.accentLine:SetWidth(156)
            if selfBox._accentRGB then
                selfBox.accentLine:SetColorTexture(selfBox._accentRGB[1], selfBox._accentRGB[2], selfBox._accentRGB[3], 1.0)
            end
            GameTooltip:SetOwner(selfBox, "ANCHOR_TOP")
            GameTooltip:AddLine(def.label, 1, 0.82, 0)
            GameTooltip:AddLine(def.tip, 1, 1, 1, true)
            GameTooltip:Show()
        end)
        box:SetScript("OnLeave", function(selfBox)
            selfBox._hovered = false
            selfBox.accentLine:SetWidth(30)
            if selfBox._accentRGB then
                selfBox.accentLine:SetColorTexture(selfBox._accentRGB[1], selfBox._accentRGB[2], selfBox._accentRGB[3], 0.55)
            end
            GameTooltip:Hide()
        end)
        box:SetScript("OnMouseUp", function()
            if PlaySound and SOUNDKIT then PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON) end
            if def.id == "UPGRADE" then
                GSI_UI:SelectTab("BIB")
                GSI_UI._scanRequestedByUser = true
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
    refreshBtn:SetText(L["Refresh"])
    SkinButton(refreshBtn, L["Refresh"], "SECONDARY")
    refreshBtn:SetScript("OnClick", function()
        if GSI_ItemScore and GSI_ItemScore.ResetCache then GSI_ItemScore:ResetCache() end
        if GSI_OptimizationEngine and GSI_OptimizationEngine.ResetCache then GSI_OptimizationEngine:ResetCache() end
        GSI_UI._triggerOverviewFill = true
        GSI_UI:UpdateOverview(parent)
    end)
    parent.refreshBtn = refreshBtn

    local sectionTitle = CreateText(parent, "CARD_TITLE", L["STAT WEIGHT SCALING & RELATIVE ATTRIBUTES"], "LEFT")
    sectionTitle:SetPoint("TOPLEFT", hero, "BOTTOMLEFT", 2, -18)
    sectionTitle:SetPoint("TOPRIGHT", refreshBtn, "TOPLEFT", -12, -8)
    sectionTitle:SetWordWrap(false)

    local sectionSub = CreateText(parent, "SMALL", L["Calculated relative importance for your active spec & gear values:"], "LEFT")
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

    -- 1. Refresh Hero Header Data
    if parent.hero then
        local hero = parent.hero
        local firstName, surname = UnitName("player")
        local pName = (surname and surname ~= "") and (firstName .. " " .. surname) or (firstName or "Player")
        local pLevel = UnitLevel("player") or 60
        local pRace = UnitRace("player") or ""
        local pClass = select(1, UnitClass("player")) or ""
        local cr, cg, cb, classHex = GSI_UI:GetClassColor()
        hero.nameText:SetText(string.format(L["|cff%s%s|r  |cff8a93a6Level %d %s %s|r"], classHex, pName, pLevel, pRace, pClass))

        GSI_UI:SetGradient(hero.bottomGlow, "HORIZONTAL", cr, cg, cb, 0.65, cr, cg, cb, 0.0)
        GSI_UI:SetGradient(hero.modelGlow, "VERTICAL", cr, cg, cb, 0.16, cr, cg, cb, 0.0)
        hero.modelBase:SetColorTexture(cr, cg, cb, 0.55)

        local specIndex = GSI_StatWeights:GetActiveSpecIndex()
        local class = (GSI_ClassicData and GSI_ClassicData.GetPlayerClass and GSI_ClassicData:GetPlayerClass()) or select(2, UnitClass("player")) or "WARRIOR"
        local classData = GSI_ClassicData and GSI_ClassicData.Classes and GSI_ClassicData.Classes[class]
        local specData = classData and classData.specs and classData.specs[specIndex]
        local specName = specData and (specData.name or specData.nameDE) or ("Spec " .. specIndex)
        if hero.specIcon and specData and specData.icon then
            hero.specIcon:SetTexture(specData.icon)
        end

        local role = GSI_StatWeights:GetRole()
        local modeLabel = ""
        if role == "tank" then
            local tMode = (GearSetImproverDB and GearSetImproverDB.tankMode) or "Survival"
            modeLabel = (tMode == "Survival") and L["Survival Tank"] or L["Threat / DPS"]
        else
            local wMode = (GearSetImproverDB and GearSetImproverDB.weightMode) or "ST"
            modeLabel = (wMode == "ST") and L["Single Target"] or L["AoE / Trash"]
        end
        hero.specText:SetText(string.format(L["Active Profile: %s (%s)"], L[specName], modeLabel))

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
                        lowestSlot = (GSI_ClassicData and GSI_ClassicData.SlotNames and L[GSI_ClassicData.SlotNames[sID]]) or ("Slot " .. sID)
                    end
                else
                    lowestScore = 0
                    lowestSlot = (GSI_ClassicData and GSI_ClassicData.SlotNames and L[GSI_ClassicData.SlotNames[sID]]) or ("Slot " .. sID)
                    lowestIsEmpty = true
                    break
                end
            end
        end

        -- Update KPI 1: SCORE
        if hero.kpiCards and hero.kpiCards.SCORE then
            hero.kpiCards.SCORE.val:SetText(string.format("%.1f", totalScore))
            hero.kpiCards.SCORE:SetMetricStyle(L["ACTIVE PROFILE"], "ACCENT")
        end

        -- Update KPI 2: BAG UPGRADES
        if hero.kpiCards and hero.kpiCards.UPGRADE then
            local lastGain = GSI_UI.lastTotalGain or 0
            local upgrades = GSI_UI.lastUpgrades or {}
            local upCount = 0
            for _ in pairs(upgrades) do upCount = upCount + 1 end

            if upCount > 0 and lastGain > 0.05 then
                hero.kpiCards.UPGRADE.val:SetText(string.format("+%.1f", lastGain))
                hero.kpiCards.UPGRADE.val:SetTextColor(unpack(T.success))
                hero.kpiCards.UPGRADE:SetMetricStyle(string.format(L["%d READY"], upCount), "SUCCESS")
            else
                hero.kpiCards.UPGRADE.val:SetText("+0.0")
                hero.kpiCards.UPGRADE.val:SetTextColor(unpack(T.textPrimary))
                hero.kpiCards.UPGRADE:SetMetricStyle(L["UP TO DATE"], "ACCENT")
            end
        end

        -- Update KPI 3: WEAKEST SLOT
        if hero.kpiCards and hero.kpiCards.WEAKEST then
            hero.kpiCards.WEAKEST.val:SetText(lowestSlot)
            if lowestIsEmpty then
                hero.kpiCards.WEAKEST:SetMetricStyle(L["EMPTY SLOT"], "DANGER")
            elseif lowestScore == nil then
                hero.kpiCards.WEAKEST:SetMetricStyle(L["NONE"], "NEUTRAL")
            else
                hero.kpiCards.WEAKEST:SetMetricStyle(string.format(L["Score: %.0f EP"], lowestScore), "WARNING")
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
    for _, r in ipairs(parent.statRows) do
        r.active = false
        r:Hide()
    end

    local BAR_MAX_WIDTH = 363
    local cr, cg, cb = GSI_UI:GetClassColor()
    local crestR = math.min(1, cr * 1.20 + 0.16)
    local crestG = math.min(1, cg * 1.20 + 0.16)
    local crestB = math.min(1, cb * 1.20 + 0.16)

    local triggerFill = (GSI_UI._triggerOverviewFill == true) or (parent._fillStartTime == nil)
    if triggerFill then
        GSI_UI._triggerOverviewFill = false
        parent._fillStartTime = (GetTime and GetTime()) or 0
    end

    local yOff = 0
    for i, entry in ipairs(sorted) do
        local row = parent.statRows[i]
        if not row then
            row = CreateFrame("Frame", nil, scrollChild)
            row:SetSize(696, 30)
            row:EnableMouse(true)

            -- Stat Label
            row.label = CreateText(row, "BODY", "", "LEFT")
            row.label:SetPoint("LEFT", 12, 0)
            row.label:SetWidth(168)
            row.label:SetWordWrap(false)

            -- Recessed Bar Track (Wider 365x14)
            local barTrack = CreateFrame("Frame", nil, row, BACKDROP_TEMPLATE)
            barTrack:SetPoint("LEFT", row.label, "RIGHT", 10, 0)
            barTrack:SetSize(365, 14)
            SkinFrame(barTrack, T.bgInput, false)
            row.barTrack = barTrack

            -- Clipped Liquid Fill Container
            local fillClip = CreateFrame("Frame", nil, barTrack)
            fillClip:SetPoint("TOPLEFT", barTrack, "TOPLEFT", 1, -1)
            fillClip:SetPoint("BOTTOMLEFT", barTrack, "BOTTOMLEFT", 1, 1)
            fillClip:SetWidth(1)
            if fillClip.SetClipsChildren then
                pcall(fillClip.SetClipsChildren, fillClip, true)
            end
            row.fillClip = fillClip

            -- Base Class-Colored Liquid Gradient
            local barBase = fillClip:CreateTexture(nil, "ARTWORK", nil, 0)
            barBase:SetAllPoints(fillClip)
            barBase:SetTexture("Interface\\Buttons\\WHITE8x8")
            row.barBase = barBase

            -- Subtle Top Glass Highlight
            local barGloss = fillClip:CreateTexture(nil, "ARTWORK", nil, 1)
            barGloss:SetPoint("TOPLEFT", fillClip, "TOPLEFT", 0, 0)
            barGloss:SetPoint("TOPRIGHT", fillClip, "TOPRIGHT", 0, 0)
            barGloss:SetHeight(5)
            barGloss:SetTexture("Interface\\Buttons\\WHITE8x8")
            GSI_UI:SetGradient(barGloss, "VERTICAL", 1, 1, 1, 0.02, 1, 1, 1, 0.22)
            row.barGloss = barGloss

            -- Flowing Liquid Wave 1 (96px soft crest)
            local wave1L = fillClip:CreateTexture(nil, "OVERLAY", nil, 2)
            wave1L:SetSize(48, 12)
            wave1L:SetPoint("LEFT", fillClip, "LEFT", -96, 0)
            wave1L:SetTexture("Interface\\Buttons\\WHITE8x8")
            wave1L:SetBlendMode("ADD")
            row.wave1L = wave1L

            local wave1R = fillClip:CreateTexture(nil, "OVERLAY", nil, 2)
            wave1R:SetSize(48, 12)
            wave1R:SetPoint("LEFT", wave1L, "RIGHT", 0, 0)
            wave1R:SetTexture("Interface\\Buttons\\WHITE8x8")
            wave1R:SetBlendMode("ADD")
            row.wave1R = wave1R

            -- Flowing Liquid Wave 2 (68px secondary ripple)
            local wave2L = fillClip:CreateTexture(nil, "OVERLAY", nil, 2)
            wave2L:SetSize(34, 12)
            wave2L:SetPoint("LEFT", fillClip, "LEFT", -68, 0)
            wave2L:SetTexture("Interface\\Buttons\\WHITE8x8")
            wave2L:SetBlendMode("ADD")
            row.wave2L = wave2L

            local wave2R = fillClip:CreateTexture(nil, "OVERLAY", nil, 2)
            wave2R:SetSize(34, 12)
            wave2R:SetPoint("LEFT", wave2L, "RIGHT", 0, 0)
            wave2R:SetTexture("Interface\\Buttons\\WHITE8x8")
            wave2R:SetBlendMode("ADD")
            row.wave2R = wave2R

            -- Bright Leading Meniscus Edge
            local meniscus = fillClip:CreateTexture(nil, "OVERLAY", nil, 3)
            meniscus:SetPoint("TOPRIGHT", fillClip, "TOPRIGHT", 0, 0)
            meniscus:SetPoint("BOTTOMRIGHT", fillClip, "BOTTOMRIGHT", 0, 0)
            meniscus:SetWidth(2.5)
            meniscus:SetTexture("Interface\\Buttons\\WHITE8x8")
            meniscus:SetBlendMode("ADD")
            row.meniscus = meniscus

            -- Current Stat Value Pill (anchored before valStr so valStr stays clear)
            row.currentPill = CreatePill(row, "0", "NEUTRAL")
            row.currentPill:SetPoint("RIGHT", -12, 0)

            -- Weight String (Mono-num)
            row.valStr = CreateText(row, "MONO_NUM", "", "LEFT")
            row.valStr:SetPoint("LEFT", barTrack, "RIGHT", 12, 0)
            row.valStr:SetPoint("RIGHT", row.currentPill, "LEFT", -10, 0)
            row.valStr:SetWordWrap(false)
            row.valStr:SetTextColor(unpack(T.textPrimary))

            row:SetScript("OnEnter", function(selfRow)
                if selfRow.tooltipData then
                    GameTooltip:SetOwner(selfRow, "ANCHOR_RIGHT")
                    GameTooltip:AddLine(selfRow.tooltipData.name, T.accent[1], T.accent[2], T.accent[3])
                    GameTooltip:AddLine(string.format(L["Weight: %s"], selfRow.tooltipData.weight), 1, 1, 1)
                    GameTooltip:AddLine(string.format(L["Current equipped stat: %s"], selfRow.tooltipData.val), T.success[1], T.success[2], T.success[3])
                    GameTooltip:Show()
                end
            end)
            row:SetScript("OnLeave", function()
                GameTooltip:Hide()
            end)

            parent.statRows[i] = row
        end

        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -yOff)
        local displayName = STAT_DISPLAY_NAMES[entry.stat] or EXTRA_STAT_DISPLAY_NAMES[entry.stat] or entry.stat
        local statVal = currentStats[entry.stat] or 0
        local targetW = math.max(3, BAR_MAX_WIDTH * (entry.weight / maxWeight))

        -- Apply live class-color liquid gradients
        GSI_UI:SetGradient(row.barBase, "HORIZONTAL", cr * 0.52, cg * 0.52, cb * 0.52, 0.95, cr, cg, cb, 1.0)
        GSI_UI:SetGradient(row.wave1L, "HORIZONTAL", crestR, crestG, crestB, 0.0, crestR, crestG, crestB, 0.38)
        GSI_UI:SetGradient(row.wave1R, "HORIZONTAL", crestR, crestG, crestB, 0.38, crestR, crestG, crestB, 0.0)
        GSI_UI:SetGradient(row.wave2L, "HORIZONTAL", crestR, crestG, crestB, 0.0, crestR, crestG, crestB, 0.24)
        GSI_UI:SetGradient(row.wave2R, "HORIZONTAL", crestR, crestG, crestB, 0.24, crestR, crestG, crestB, 0.0)
        row.meniscus:SetVertexColor(crestR, crestG, crestB, 0.65)

        row.active = true
        row.rowIndex = i
        row.targetWidth = targetW
        if triggerFill then
            row.curWidth = 1
            row.fillClip:SetWidth(1)
        elseif not row.curWidth then
            row.curWidth = targetW
            row.fillClip:SetWidth(targetW)
        end

        row.label:SetText(displayName)
        row.currentPill:SetPillStyle(FormatStatValue(entry.stat, statVal), "NEUTRAL")
        row.valStr:SetText(FormatWeight(entry.weight))
        row.tooltipData = {
            name = displayName,
            weight = FormatWeight(entry.weight),
            val = FormatStatValue(entry.stat, statVal),
        }
        row:Show()

        yOff = yOff + 32
    end

    if not parent._liquidDriverHooked then
        parent._liquidDriverHooked = true
        parent:SetScript("OnUpdate", function(selfFrame, elapsed)
            local rows = selfFrame.statRows
            if not rows then return end
            local now = (GetTime and GetTime()) or 0
            local elapsedFill = now - (selfFrame._fillStartTime or 0)

            for _, row in ipairs(rows) do
                if row.active and row.fillClip then
                    local idx = row.rowIndex or 1
                    local targetW = row.targetWidth or 3
                    local curW = row.curWidth or targetW

                    if elapsedFill < 1.0 then
                        local delay = math.min(0.16, (idx - 1) * 0.018)
                        local dur = 1.0 - delay
                        local p = math.max(0, math.min(1, (elapsedFill - delay) / dur))
                        local ease = 1 - ((1 - p) * (1 - p) * (1 - p))
                        curW = math.max(1, targetW * ease)
                    elseif math.abs(targetW - curW) > 0.2 then
                        curW = curW + (targetW - curW) * math.min(1, (elapsed or 0.016) * 10)
                    else
                        curW = targetW
                    end

                    row.curWidth = curW
                    row.fillClip:SetWidth(curW)

                    -- Continuous liquid wave motion
                    local span1 = curW + 96
                    local x1 = ((now * 110 + idx * 37) % span1) - 96
                    row.wave1L:ClearAllPoints()
                    row.wave1L:SetPoint("LEFT", row.fillClip, "LEFT", x1, 0)

                    local span2 = curW + 68
                    local x2 = ((now * 68 + idx * 53 + 24) % span2) - 68
                    row.wave2L:ClearAllPoints()
                    row.wave2L:SetPoint("LEFT", row.fillClip, "LEFT", x2, 0)

                    local meniscusAlpha = (elapsedFill < 1.0) and 0.90 or (0.45 + 0.25 * math.sin(now * 4.5 + idx * 0.6))
                    row.meniscus:SetAlpha(meniscusAlpha)
                end
            end
        end)
    end

    scrollChild:SetHeight(math.max(yOff + 10, 10))
end
