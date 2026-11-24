-- ============================================================
-- GearSetImprover -- UI_Modals.lua (WoW Forever)
-- ============================================================

GSI_UI = GSI_UI or {}

local GetItemInfo = (C_Item and C_Item.GetItemInfo) or _G.GetItemInfo or function() return nil end
local GetItemInfoInstant = (C_Item and C_Item.GetItemInfoInstant) or _G.GetItemInfoInstant or function() return nil end
local BackdropTemplateMixin = _G.BackdropTemplateMixin
local BACKDROP_TEMPLATE = BackdropTemplateMixin and 'BackdropTemplate' or nil

local function SkinFrame(f, s, t) if GSI_UI.SkinFrame then return GSI_UI:SkinFrame(f, s, t) end end
local function SkinButton(b, r, p) if GSI_UI.SkinButton then return GSI_UI:SkinButton(b, r, p) end end
local function SkinSlider(s, bg, w, h) if GSI_UI.SkinSlider then return GSI_UI:SkinSlider(s, bg, w, h) end end
local function FormatWeight(v) return GSI_UI.FormatWeight and GSI_UI:FormatWeight(v) or tostring(v) end
local function FormatStatValue(k, v) return GSI_UI.FormatStatValue and GSI_UI:FormatStatValue(k, v) or tostring(v) end
local STAT_DISPLAY_NAMES = GSI_UI.STAT_DISPLAY_NAMES or {}

local function GetAddonVersion()
    local ver = nil
    if C_AddOns and C_AddOns.GetAddOnMetadata then
        ver = C_AddOns.GetAddOnMetadata("GearSetImprover", "Version")
    elseif GetAddOnMetadata then
        ver = GetAddOnMetadata("GearSetImprover", "Version")
    end
    return (ver and ver ~= "") and ver or "1.4.4"
end

-- CREDITS & ACKNOWLEDGMENTS MODAL
-- ---------------------------------------------------------------
function GSI_UI:OpenCreditsModal()
    if not self.creditsFrame then
        local f = CreateFrame("Frame", "GSI_CreditsFrame", UIParent, BACKDROP_TEMPLATE)
        f:SetSize(560, 485)
        f:SetPoint("CENTER")
        f:SetMovable(true)
        f:EnableMouse(true)
        f:RegisterForDrag("LeftButton")
        f:SetScript("OnDragStart", f.StartMoving)
        f:SetScript("OnDragStop", f.StopMovingOrSizing)
        f:SetFrameStrata("FULLSCREEN_DIALOG")
        f:SetFrameLevel(500)
        SkinFrame(f, "dialog")

        -- EllesmereUI Top Accent
        local topAccent = f:CreateTexture(nil, "OVERLAY")
        topAccent:SetPoint("TOPLEFT", f, "TOPLEFT", 1, -1)
        topAccent:SetPoint("TOPRIGHT", f, "TOPRIGHT", -1, -1)
        topAccent:SetHeight(2)
        local cr, cg, cb = GSI_UI:GetClassColor()
        if topAccent.SetColorTexture then
            topAccent:SetColorTexture(cr, cg, cb, 1)
        else
            topAccent:SetTexture("Interface\\Buttons\\WHITE8x8")
            topAccent:SetVertexColor(cr, cg, cb, 1)
        end

        local topClose = CreateFrame("Button", nil, f, BACKDROP_TEMPLATE)
        topClose:SetSize(22, 22)
        topClose:SetPoint("TOPRIGHT", -8, -8)
        topClose:SetText("X")
        SkinButton(topClose, true)
        topClose:SetScript("OnClick", function() f:Hide() end)

        f.title = GSI_UI:CreateText(f, "TITLE", "|cffffcc00GearSetImprover Forever (GSI)|r – Credits & Acknowledgments")
        f.title:SetPoint("TOPLEFT", 16, -16)
        f.title:SetPoint("RIGHT", topClose, "LEFT", -8, 0)
        if f.title.SetWordWrap then f.title:SetWordWrap(false) end

        local sub = GSI_UI:CreateText(f, "SMALL", "GearSetImprover Forever for WoW Forever")
        sub:SetPoint("TOPLEFT", 16, -42)
        sub:SetPoint("RIGHT", f, "RIGHT", -16, 0)
        if sub.SetWordWrap then sub:SetWordWrap(false) end

        -- Card 1: Community Supporters
        local card1 = CreateFrame("Frame", nil, f, BACKDROP_TEMPLATE)
        card1:SetHeight(145)
        card1:SetPoint("TOPLEFT", 16, -65)
        card1:SetPoint("RIGHT", f, "RIGHT", -16, 0)
        SkinFrame(card1, "card")

        local t1 = GSI_UI:CreateText(card1, "CARD_TITLE", "|cffffcc00Community Supporters & Special Thanks|r")
        t1:SetPoint("TOPLEFT", 12, -10)
        t1:SetPoint("RIGHT", card1, "RIGHT", -12, 0)
        if t1.SetWordWrap then t1.SetWordWrap(false) end

        local d1 = GSI_UI:CreateText(card1, "BODY", "")
        d1:SetPoint("TOPLEFT", 12, -32)
        d1:SetPoint("BOTTOMRIGHT", -12, 10)
        d1:SetJustifyH("LEFT")
        d1:SetJustifyV("TOP")
        if d1.SetWordWrap then d1:SetWordWrap(true) end
        d1:SetText("A huge thank you to everyone testing, submitting bug reports, and providing invaluable feedback!\n\nSpecial thanks to:\n• |cff00ff00stroke1611|r (|cff33ccffhttps://www.twitch.tv/stroke1611|r)\n• |cff00ff00followpawl|r (|cff33ccffhttps://www.twitch.tv/followpawl|r)\n• The entire WoW Forever community for your fantastic support!")

        -- Card 2: Stat Theory
        local card2 = CreateFrame("Frame", nil, f, BACKDROP_TEMPLATE)
        card2:SetHeight(105)
        card2:SetPoint("TOPLEFT", card1, "BOTTOMLEFT", 0, -10)
        card2:SetPoint("RIGHT", f, "RIGHT", -16, 0)
        SkinFrame(card2, "card")

        local t2 = GSI_UI:CreateText(card2, "CARD_TITLE", "|cffffcc00Stat Theory & Calculations|r")
        t2:SetPoint("TOPLEFT", 12, -10)
        t2:SetPoint("RIGHT", card2, "RIGHT", -12, 0)
        if t2.SetWordWrap then t2.SetWordWrap(false) end

        local d2 = GSI_UI:CreateText(card2, "BODY", "")
        d2:SetPoint("TOPLEFT", 12, -32)
        d2:SetPoint("BOTTOMRIGHT", -12, 10)
        d2:SetJustifyH("LEFT")
        d2:SetJustifyV("TOP")
        if d2.SetWordWrap then d2.SetWordWrap(true) end
        f.d2 = d2

        -- Card 3: Feedback
        local card3 = CreateFrame("Frame", nil, f, BACKDROP_TEMPLATE)
        card3:SetHeight(105)
        card3:SetPoint("TOPLEFT", card2, "BOTTOMLEFT", 0, -10)
        card3:SetPoint("RIGHT", f, "RIGHT", -16, 0)
        SkinFrame(card3)
        card3:SetBackdropColor(0.12, 0.12, 0.12, 0.95)

        local t3 = GSI_UI:CreateText(card3, "CARD_TITLE", "|cffffcc00Feedback & Bug Reports|r")
        t3:SetPoint("TOPLEFT", 12, -10)
        t3:SetPoint("RIGHT", card3, "RIGHT", -12, 0)
        if t3.SetWordWrap then t3.SetWordWrap(false) end

        local d3 = GSI_UI:CreateText(card3, "BODY", "")
        d3:SetPoint("TOPLEFT", 12, -32)
        d3:SetPoint("BOTTOMRIGHT", -12, 10)
        d3:SetJustifyH("LEFT")
        d3:SetJustifyV("TOP")
        if d3.SetWordWrap then d3.SetWordWrap(true) end
        f.d3 = d3

        local closeBtn = CreateFrame("Button", nil, f, BACKDROP_TEMPLATE)
        closeBtn:SetSize(100, 24)
        closeBtn:SetPoint("BOTTOMRIGHT", -16, 12)
        closeBtn:SetText("Close")
        SkinButton(closeBtn)
        closeBtn:SetScript("OnClick", function() f:Hide() end)

        if self.RegisterModalForEscape then
            self:RegisterModalForEscape(f)
        end

        self.creditsFrame = f
    end

    local f = self.creditsFrame
    local ruleVer = (GSI_Config and (GSI_Config.Version_v2_2 or GSI_Config.Version)) or "2.2"
    local updatedDate = (GSI_Config and (GSI_Config.Stand_v2_2 or GSI_Config.Stand)) or "Current Release"
    local addonVer = GetAddonVersion()
    f.d2:SetText(string.format(
        "Stat weights and evaluation rules are built for the official WoW Forever v%s patch specifications (Updated: |cffffcc00%s|r) across all 9 classes and 28 talent specializations.\n|cffaaaaaaSupports Single Target, AoE / Trash, Survival, and Threat / DPS optimization modes.|r",
        tostring(ruleVer), tostring(updatedDate)
    ))
    f.d3:SetText(string.format(
        "Have suggestions, found a bug, or want to contribute ideas?\nUse the Log Export button in settings or type |cffffcc00/gsi log|r to copy your logs and share your feedback with the development team.\n\nVersion: |cff00ff00%s (Official Release)|r",
        tostring(addonVer)
    ))
    f:Show()
end

function GSI_UI:DrawCredits(parent)
    self:OpenCreditsModal()
end

-- ---------------------------------------------------------------
-- INTERACTIVE TUTORIAL
-- ---------------------------------------------------------------
function GSI_UI:OpenTutorial()
    if not self.tutorialFrame then
        local f = CreateFrame("Frame", "GSI_TutorialFrame", UIParent, BACKDROP_TEMPLATE)
        f:SetSize(540, 420)
        f:SetPoint("CENTER")
        f:SetMovable(true)
        f:EnableMouse(true)
        f:RegisterForDrag("LeftButton")
        f:SetScript("OnDragStart", f.StartMoving)
        f:SetScript("OnDragStop", f.StopMovingOrSizing)
        f:SetFrameStrata("FULLSCREEN_DIALOG")
        f:SetFrameLevel(500)
        SkinFrame(f, "dialog")

        -- EllesmereUI Top Accent
        local topAccent = f:CreateTexture(nil, "OVERLAY")
        topAccent:SetPoint("TOPLEFT", f, "TOPLEFT", 1, -1)
        topAccent:SetPoint("TOPRIGHT", f, "TOPRIGHT", -1, -1)
        topAccent:SetHeight(2)
        local cr, cg, cb = GSI_UI:GetClassColor()
        if topAccent.SetColorTexture then
            topAccent:SetColorTexture(cr, cg, cb, 1)
        else
            topAccent:SetTexture("Interface\\Buttons\\WHITE8x8")
            topAccent:SetVertexColor(cr, cg, cb, 1)
        end

        local closeBtn = CreateFrame("Button", nil, f, BACKDROP_TEMPLATE)
        closeBtn:SetSize(22, 22)
        closeBtn:SetPoint("TOPRIGHT", -8, -8)
        closeBtn:SetText("X")
        SkinButton(closeBtn, true)
        closeBtn:SetScript("OnClick", function()
            if GearSetImproverDB then GearSetImproverDB.tutorialSeen = true end
            f:Hide()
        end)

        f.title = GSI_UI:CreateText(f, "TITLE", "|cffffcc00GearSetImprover Forever|r – Quick Guide")
        f.title:SetPoint("TOPLEFT", 16, -16)
        f.title:SetPoint("RIGHT", closeBtn, "LEFT", -8, 0)
        if f.title.SetWordWrap then f.title:SetWordWrap(false) end

        f.stepTitle = GSI_UI:CreateText(f, "CARD_TITLE", "")
        f.stepTitle:SetPoint("TOPLEFT", 16, -46)
        f.stepTitle:SetPoint("RIGHT", f, "RIGHT", -16, 0)
        if f.stepTitle.SetWordWrap then f.stepTitle:SetWordWrap(false) end
        f.stepTitle:SetTextColor(0, 1, 0)

        f.content = GSI_UI:CreateText(f, "BODY", "")
        f.content:SetPoint("TOPLEFT", 16, -75)
        f.content:SetPoint("BOTTOMRIGHT", -16, 55)
        f.content:SetJustifyH("LEFT")
        f.content:SetJustifyV("TOP")
        if f.content.SetWordWrap then f.content:SetWordWrap(true) end

        local prevBtn = CreateFrame("Button", nil, f, BACKDROP_TEMPLATE)
        prevBtn:SetSize(90, 24)
        prevBtn:SetPoint("BOTTOMLEFT", 16, 14)
        prevBtn:SetText("< Back")
        SkinButton(prevBtn)
        f.prevBtn = prevBtn

        local nextBtn = CreateFrame("Button", nil, f, BACKDROP_TEMPLATE)
        nextBtn:SetSize(130, 24)
        nextBtn:SetPoint("BOTTOMRIGHT", -16, 14)
        nextBtn:SetText("Next >")
        SkinButton(nextBtn)
        f.nextBtn = nextBtn

        f.curStep = 1
        if self.RegisterModalForEscape then
            self:RegisterModalForEscape(f)
        end
        self.tutorialFrame = f
    end

    local f = self.tutorialFrame
    local steps = {
        {
            title = "Step 1: Specializations & Modes",
            text = "Welcome to |cffffcc00GearSetImprover Forever|r!\n\n" ..
                   "GSI analyzes your equipped gear and bag items using precise stat weights tuned for WoW Forever v2.\n\n" ..
                   "• |cffffcc00Choose Specialization:|r Use the dropdown in the top-right header to switch talent trees (e.g. Fury, Arms, Protection) anytime.\n" ..
                   "• |cffffcc00Select Mode:|r Switch between |cff00ff00Single Target (ST)|r and |cff00ff00AoE / Trash|r (or for Tanks: |cff00ff00Survival|r and |cff00ff00Threat / DPS|r).\n\n" ..
                   "All gear evaluations automatically update to match your active profile!",
        },
        {
            title = "Step 2: Best Available Gear & Slot Locking",
            text = "In the |cffffcc00'Best Available'|r tab, you'll find the optimal gear combination from your inventory:\n\n" ..
                   "• |cffffcc00Optimize Gear:|r Scans your bags and lists genuine upgrades with their exact GSI Score increase.\n" ..
                   "• |cffffcc00Lock Slots [Lock]:|r Want to keep a specific slot (e.g. weapon set or specific ring) and avoid replacing it?\n" ..
                   "  Click the |cff888888Lock|r button on any slot row to toggle it to |cffff4444Locked|r!\n" ..
                   "• |cffffcc00Equip All:|r Equips all available upgrades at once - locked slots remain completely untouched and protected!",
        },
        {
            title = "Step 3: Clean-up Filter (Outdated Gear)",
            text = "Formerly called 'Junk Manager' - this tool helps you identify obsolete gear sitting in your bags:\n\n" ..
                   "• |cffff4444IMPORTANT:|r Gray trash items are NEVER sold! This only checks weak or outdated gear.\n" ..
                   "• |cff00ff00Equipment Set Protection:|r Items saved in any Blizzard Equipment Set are NEVER marked as outdated.\n" ..
                   "• |cffffcc00Lock Items:|r Click |cffff4444Lock|r next to any item in the Clean-up list to permanently exclude it.\n" ..
                   "• Click |cffffcc00'Locked Items...'|r anytime to view and unlock items you previously protected.",
        },
        {
            title = "Step 4: Stat Weights, Export/Import & Macros",
            text = "Full control over your gear theory:\n\n" ..
                   "• |cffffcc00Stat Weights:|r Customize individual stat weights or reset back to Forever v2 defaults.\n" ..
                   "• |cffffcc00Export / Import:|r Share weights with friends or import Pawn strings in seconds!\n" ..
                   "• |cffffcc00Macros:|r Generate 1-click gear swap macros directly onto your Action Bars.\n" ..
                   "• |cffffcc00Settings:|r All addon settings can be found in the game menu under |cffffcc00Options -> AddOns -> GearSetImprover|r.\n\n" ..
                   "Enjoy gearing up and maximizing your character power!",
        },
    }

    local function ShowStep(idx)
        f.curStep = idx
        local data = steps[idx]
        f.stepTitle:SetText(data.title)
        f.content:SetText(data.text)
        if idx == 1 then
            f.prevBtn:Disable()
        else
            f.prevBtn:Enable()
        end
        if idx == #steps then
            f.nextBtn:SetText("Finish Tutorial")
        else
            f.nextBtn:SetText("Next >")
        end
    end

    f.prevBtn:SetScript("OnClick", function()
        if f.curStep > 1 then ShowStep(f.curStep - 1) end
    end)
    f.nextBtn:SetScript("OnClick", function()
        if f.curStep < #steps then
            ShowStep(f.curStep + 1)
        else
            if GearSetImproverDB then GearSetImproverDB.tutorialSeen = true end
            f:Hide()
        end
    end)

    ShowStep(1)
    f:Show()
end

-- ---------------------------------------------------------------
-- CHANGELOG WINDOW
-- ---------------------------------------------------------------
function GSI_UI:OpenChangelog()
    if not self.changelogFrame then
        local f = CreateFrame("Frame", "GSI_ChangelogFrame", UIParent, BACKDROP_TEMPLATE)
        f:SetSize(580, 520)
        f:SetPoint("CENTER")
        f:SetMovable(true)
        f:EnableMouse(true)
        f:RegisterForDrag("LeftButton")
        f:SetScript("OnDragStart", f.StartMoving)
        f:SetScript("OnDragStop", f.StopMovingOrSizing)
        f:SetFrameStrata("FULLSCREEN_DIALOG")
        f:SetFrameLevel(500)
        SkinFrame(f, "dialog")

        -- EllesmereUI Top Accent
        local topAccent = f:CreateTexture(nil, "OVERLAY")
        topAccent:SetPoint("TOPLEFT", f, "TOPLEFT", 1, -1)
        topAccent:SetPoint("TOPRIGHT", f, "TOPRIGHT", -1, -1)
        topAccent:SetHeight(2)
        local cr, cg, cb = GSI_UI:GetClassColor()
        if topAccent.SetColorTexture then
            topAccent:SetColorTexture(cr, cg, cb, 1)
        else
            topAccent:SetTexture("Interface\\Buttons\\WHITE8x8")
            topAccent:SetVertexColor(cr, cg, cb, 1)
        end

        local topClose = CreateFrame("Button", nil, f, BACKDROP_TEMPLATE)
        topClose:SetSize(22, 22)
        topClose:SetPoint("TOPRIGHT", -8, -8)
        topClose:SetText("X")
        SkinButton(topClose, true)
        topClose:SetScript("OnClick", function() f:Hide() end)

        f.title = GSI_UI:CreateText(f, "TITLE", "|cffffcc00GearSetImprover Forever|r – Release Notes (Changelog)")
        f.title:SetPoint("TOPLEFT", 16, -16)
        f.title:SetPoint("RIGHT", topClose, "LEFT", -8, 0)
        if f.title.SetWordWrap then f.title:SetWordWrap(false) end

        local sf = CreateFrame("ScrollFrame", "GSI_ChangelogScroll", f, "UIPanelScrollFrameTemplate")
        sf:SetPoint("TOPLEFT", 16, -45)
        sf:SetPoint("BOTTOMRIGHT", -36, 45)
        if GSI_UI and GSI_UI.SkinScrollBar then
            GSI_UI:SkinScrollBar(sf)
        end

        local child = CreateFrame("Frame", nil, sf)
        child:SetSize(520, 430)
        sf:SetScrollChild(child)
        f.scrollFrame = sf
        f.scrollChild = child

        local text = GSI_UI:CreateText(child, "BODY", "")
        text:SetPoint("TOPLEFT", 0, 0)
        text:SetWidth(516)
        text:SetJustifyH("LEFT")
        text:SetJustifyV("TOP")
        if text.SetWordWrap then text:SetWordWrap(true) end
        f.text = text

        local closeBtn = CreateFrame("Button", nil, f, BACKDROP_TEMPLATE)
        closeBtn:SetSize(100, 24)
        closeBtn:SetPoint("BOTTOMRIGHT", -16, 12)
        closeBtn:SetText("Close")
        SkinButton(closeBtn)
        closeBtn:SetScript("OnClick", function() f:Hide() end)

        if self.RegisterModalForEscape then
            self:RegisterModalForEscape(f)
        end

        self.changelogFrame = f
    end

    local logText = [[
|cffffcc00Version 1.4.4 (Forever Auto-Spec, Per-Spec Gear Sets, Live Rescoring & ruRU Support)|r
--------------------------------------------------
|cff00ff00New:|r Automatic WoW Forever talent-tree spec detection via |cffffffffC_ClassTalents|r / |cffffffffC_Traits|r trait groups, plus |cffffcc00Auto|r mode in the spec dropdown and |cffffffff/gsi spec auto|r (Feral Druid Cat/Bear role keeps Auto enabled; login/talent-reload states guarded). Thanks to |cffffffffDanpiel|r for the community contributions.
|cff00ff00New:|r Added |cffffcc00Specialization & Equipment Set per Spec|r in Settings to bind and auto-equip an Equipment Manager set on spec change (queued out of combat if needed) or equip manually with |cffffffff/gsi set|r.
|cff00ff00Fix:|r Open item tooltips (|cffffffffRefreshShownTooltips|r), upgrade toasts (|cffffffffReevaluatePending|r), and Best in Bag results (|cffffffffMarkScanStale|r) now rescore automatically on spec/talent changes; deduplicated |cffffffffUpgrade(s) found|r chat spam.
|cff00ff00New:|r Weapon DPS now reads from |cffffffffGetItemStats|r with tooltip fallback and weapon speed scans both left and right tooltip columns (|cffffffffTextRight|r). Added |cffffffffRESISTANCE0_NAME|r, |cffffffffRESISTANCE2..6_NAME|r, |cffffffffITEM_MOD_FERAL_ATTACK_POWER|r, and |cffffffffITEM_MOD_EXPERTISE_RATING|r mappings, Cyrillic UTF-8 tooltip parsing (|cffffffffruRU|r), automatic tooltip set-bonus learning, and |cffffffff/gsi dump|r diagnostics.

|cffffcc00Version 1.4.3 (Cross-Class Rating Fix, Tank & Caster Audit)|r
--------------------------------------------------
|cff00ff00Fix:|r Fixed |cffffffffC_Item.GetItemStats()|r returning internal Level-60 combat ratings (e.g., 14 rating per 1% Crit) instead of flat percentages, which previously inflated Crit/Hit/Haste/Dodge/Parry/Block/Defense scores across all 9 classes. Tooltip flat percentages now take priority with converted API fallbacks, plus |cffffffffITEM_MOD_POWER_REGEN0_SHORT|r MP5 mapping.
|cff00ff00Fix:|r Fixed +33% / +88% SpellPower + HealingPower double-counting for non-healers, German pure-healing / school-damage tooltip leaks, and Priest healer Holy/Shadow damage weights (now 0.00). Switched set-bonus SP/Heal scoring to per-threshold evaluation and extended healer universal SP routing to ZG/Naxx enchants.
|cff00ff00Tuned:|r Closed the |cffffffffTertiaryWeights.Spirit = 0.2|r leak across all 56 profiles, calibrated Shield Tank & Feral Bear weapon DPS/stats/caps, added missing |cffffffffARP|r weights and |cffffffffWEAPON_SKILL|r / |cffffffffAVOID_RED|r caps across physical specs, fixed AoE primary-stat inversions, and updated Feral Bear talent rules (|cffffffffThick Hide|r, |cffffffffNatural Reaction|r, |cffffffffBlood Frenzy|r).
|cff00ff00Parity:|r Skipped |cffffffffEnchanted:|r / |cffffffffVerzaubert:|r lines in base parsing, normalized German uppercase umlauts, expanded DE/EN Weapon Skill / Defense parsing (incl. |cffffffffWAND|r, |cffffffffCROSSBOW|r, |cffffffffTHROWN|r, self-weapon matching, and profession skill exclusion), and aligned Shaman |cffffffffTidal Focus|r and |cffffffffGetBaselineCapStats|r parity.

|cffffcc00Version 1.4.2 (TooltipHook Login Error Hotfix)|r
--------------------------------------------------
|cff00ff00Fix:|r Guarded |cffffffffOnTooltipSetItem|r hooking in |cffffffffTooltipHook.lua|r with |cfffffffftip:HasScript("OnTooltipSetItem")|r to prevent a login error on the WoW Forever client where tooltips do not expose that legacy script handler.
|cff00ff00Fix:|r Ensures |cffffffffSetHyperlink|r hooks, profile/equipment/talent cache invalidation hooks, and the tooltip cache event frame initialize reliably on login.

|cffffcc00Version 1.4.1 (Shield-Tank 1H+Shield Hotfix)|r
--------------------------------------------------
|cff00ff00Fix:|r Enforced strict |cffffcc001H + Shield|r weapon rules for Protection Warrior (Spec 3) and Protection Paladin (Spec 2) across both Survival and Threat/DMG modes (CurseForge report by Gray989).
|cff00ff00Fix:|r Prevented 2H weapons, dual-wield off-hands, caster holdables, and 1H off-hand evaluations from scoring or triggering proc/tooltip upgrade recommendations in Prot specs.
|cff00ff00Fix:|r Zeroed out lingering |cffffffffWEAPON_DPS_OH|r / |cffffffffWeaponDamageOH|r (2.80 -> 0.00) on Protection Warrior Threat.
|cff00ff00Safe:|r Protected off-spec 2H/DW/Holdable weapons in Clean-up so they are never flagged as junk while tanking in Prot spec.

|cffffcc00Version 1.4.0 (Build 70755 Post-Launch Hotfix Audit & Database Expansion)|r
--------------------------------------------------
• |cff00ff00Post-Launch Class & Talent Recalibration (Build 70755):|r
  Updated stat weights across Warrior (MH-only Whirlwind, Flurry 3-rank, 15s Slam, 2-charge Shield Block), Druid (Feral Cat 8.30 Weapon DPS sync, Primal Bite / Natural Instinct, 115% Bear Threat), Rogue (Mutilate 90% MH+OH, Death Mark, Boot Knife), Shaman (100% Mental Dexterity INT 0.90 EP, 10 PPM Maelstrom Weapon, 71.4% SP Lightning / 30% Overload), Warlock (Wrack, Soul Siphon 36%, Pandemic), Paladin (Unsealed Wrath, Seal of Fury, Reverence), Hunter (Careful Aim INT, Predator's Edge, Survival AoE), and Mage (Frostfire Bolt, Winter's Chill, Arcane Wrath).
• |cff00ff00Talent & Racial Engine Refinements:|r
  Fixed Defiance/Thick Hide armor mapping, added 12 new Crit/Primary stat talent multipliers (Pandemic, Impale, Mortal Shots, Ice Shards, Elemental Fury, Vengeance, Heart of the Wild, Demonic Embrace, etc.), and added Ranged AP scaling to Gnome Eureka!.
• |cff00ff00Weapon/Scope Enchant Fix & Scourge Enchants:|r
  Converted flat weapon damage and scope enchants from inflated raw integers to true DPS equivalents (+9 dmg -> 2.6 DPS, +5 dmg -> 2.0 DPS, Sniper Scope -> 2.5 Ranged DPS) and added Naxxramas Shoulder enchants, Shield enchants, and Mithril Spurs.
• |cff00ff00Tier 0.5 Sets, Scholomance Sets & Proc Overrides:|r
  Added all 9 Dungeon Set 2 (T0.5) sets, Vestments of the Devout alias, Dal'Rend's Arms, Black Dragonscale, 4 Scholomance sets, and 13 iconic non-trinket proc/on-use item overrides (Felstriker, Bonereaver's Edge, Annihilator, Nightfall, Manual Crowd Pummeler, Cloudkeeper Legplates, etc.).
• |cff00ff00Core Engine, Dual-Wield & Set-Bonus Optimizations:|r
  Added automatic set-bonus tracking with canonical alias resolution and double-count-safe threshold scoring, spec/role-aware filtering for proc overrides (no melee procs for casters/healers/ranged hunters), MH/OH/dagger weapon speed & DPS parity across ItemScore & OptimizationEngine, slot-specific Dual-Wield Clean-up comparison (`NUM_BAG_SLOTS`), full 43-stat Overview aggregation, and mode-scoped tooltip/minimap profile caching.

|cffffcc00Version 1.3.9 (Dedicated AoE System, Cap Re-Audit & UI Polish)|r
--------------------------------------------------
• |cff00ff00Dedicated AoE / Trash Profiles:|r
  Added 25 dedicated AoE profiles across all 9 classes with trash hit caps (6% Melee/Ranged, 10% Spell) and cleave stat weights.
• |cff00ff00Caster Spell-Hit Cap Fix:|r
  Fixed spell hit evaluation so `SPELL_HIT` caps properly apply to all caster profiles instead of scaling linearly past cap.
• |cff00ff00Class, Talent & Weapon Calibration:|r
  Added missing Warrior weapon skill (308 soft-cap) and defense (440) caps, updated Paladin/Rogue/Warlock/Druid caps, and refined Shadow Focus / Precision / Mental Dexterity talent weights.
• |cff00ff00UI & Typography Unification:|r
  Full English localization across all UI screens, Overview 2H off-hand fix, Expressway font consistency, and added `Arms AoE`, `Holy AoE`, and `Ret AoE` macro presets.

|cffffcc00Version 1.3.6 – 1.3.8 (Hardware-Secure Equip & Toast Overhaul)|r
--------------------------------------------------
• |cff00ff00Hardware-Secure Equip Overlay:|r
  Replaced blocked container equip calls with `InsecureActionButtonTemplate` overlays and asynchronous verification before dismissing toasts.
• |cff00ff00ItemGUID Tracking & Auto-Dismiss:|r
  Added persistent ItemGUID tracking and automatic dismissal when upgrades are equipped manually or moved out of bags.

|cffffcc00Version 1.3.3 – 1.3.5 (WoW Forever Launch Audit & Dual-Ring Engine)|r
--------------------------------------------------
• |cff00ff00Full Theorycrafting Audit (Patch 1.60.1):|r
  Audited all 31 profiles across 9 classes and 28 specializations (including Survival Melee Hunter, 2H Enhancement Shaman, Pandemic Affliction Warlock, and Shieldsworn Protection Paladin).
• |cff00ff00Joint Dual-Ring Optimization:|r
  Simultaneously optimizes both ring slots and prioritizes comparing against the weaker equipped ring (`+X vs Finger 1 / Finger 2`).

|cffffcc00Version 1.2.5 (Best Available & Automation)|r
--------------------------------------------------
• |cff00ff00Best Available Rebranding:|r
  Renamed tabs, headers, macros, and tooltips from 'Best in Bag' to 'Best Available'.
• |cff00ff00Automated Background Scanning:|r
  Automatically executes optimization checks on addon open and on equipment changes with instant UI refresh.

|cffffcc00Version 1.2.4 (Theorycrafting Fusion)|r
--------------------------------------------------
• |cff00ff00Mathematical Normalization:|r
  Normalized rating calculations to canonical WoW Forever +1% item budgets (~10-15 Score per +1% Hit/Crit).
• |cff00ff00Weapon Damage & Skill Scaling:|r
  Added spec-tuned MH/OH/Ranged weapon DPS scaling, Weapon Skill 305/308 glancing blow reduction, and multi-tier hit/defense caps.

|cffffcc00Version 1.2.2 – 1.2.3 (Obsidian Glass UI & Core Fixes)|r
--------------------------------------------------
• Dark Obsidian aesthetics, class-color accents, sleek scrollbars, shield usability fix, and auto re-scan after swaps.

|cffffcc00Version 1.0.0 (Official Release)|r
--------------------------------------------------
• Official release of GearSetImprover Forever for WoW Forever v2.2 mechanics, proc overrides, and set bonuses.
]]

    local f = self.changelogFrame
    f.text:SetText(logText)
    local function UpdateChangelogScrollHeight()
        if f.text and f.scrollChild then
            local measured = f.text:GetStringHeight() or 0
            f.scrollChild:SetHeight(math.max(430, math.ceil(measured) + 32))
        end
    end
    UpdateChangelogScrollHeight()
    if f.scrollFrame and f.scrollFrame.SetVerticalScroll then
        f.scrollFrame:SetVerticalScroll(0)
    end
    f:Show()
    if C_Timer and C_Timer.After then
        C_Timer.After(0, UpdateChangelogScrollHeight)
    end
end

-- ---------------------------------------------------------------
