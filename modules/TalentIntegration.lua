-- ============================================================
-- GearSetImprover - TalentIntegration.lua (WoW Forever 1.60.1)
-- Reads invested talents and computes dynamic stat modifiers.
-- Uses localized EN/DE patterns with tab/row/column fallback.
-- ============================================================

GSI_TalentIntegration = {}

local function ResolvePlayerClass()
    if GSI_ClassicData and GSI_ClassicData.GetPlayerClass then
        return GSI_ClassicData:GetPlayerClass()
    end
    local locClass, engClass = UnitClass("player")
    return engClass or locClass or "WARRIOR"
end

-- Verified Forever 1.60.1 talent metadata (EN/DE patterns + Data.lua coordinates)
local TALENT_DEFINITIONS = {
    -- Hit talents
    PRECISION_MAGE = {
        patterns = { "precision", "präzision" },
        exact = true,
        tab = 3, tier = 1, col = 3, -- Frost Row 1 Col 3 (max 3: +2/4/6% all spells)
    },
    PRECISION_PALADIN = {
        patterns = { "precision", "präzision" },
        exact = true,
        tab = 2, tier = 2, col = 1, -- Protection Row 2 Col 1 (max 3: +1/2/3% all hit)
    },
    PRECISION_ROGUE = {
        patterns = { "precision", "präzision" },
        exact = true,
        tab = 2, tier = 2, col = 3, -- Combat Row 2 Col 3 (max 3: +1/2/3% hit)
    },
    HOLY_PRECISION = {
        patterns = { "holy precision", "heilige präzision" },
        tab = 1, tier = 2, col = 2, -- Priest Discipline Row 2 Col 2 (max 3: +6/12/18% Holy hit)
    },
    DIVINE_PRECISION = {
        patterns = { "divine precision", "göttliche präzision" },
        tab = 1, tier = 4, col = 1, -- Paladin Holy Row 4 Col 1 (max 2: +4/8% Holy hit)
    },
    SHADOW_FOCUS = {
        patterns = { "shadow focus", "schattenfokus" },
        tab = 3, tier = 1, col = 1, -- Priest Shadow Row 1 Col 1 (max 5: +1..5% Shadow hit)
    },
    SUPPRESSION = {
        patterns = { "suppression", "unterdrückung" },
        tab = 1, tier = 1, col = 2, -- Warlock Affliction Row 1 Col 2 (max 5: +1..5% hit)
    },
    SUREFOOTED = {
        patterns = { "surefooted", "sicherer stand" },
        tab = 3, tier = 3, col = 2, -- Hunter Survival Row 3 Col 2 (max 3: +1/2/3% hit)
    },
    TIDAL_FOCUS = {
        patterns = { "tidal focus", "gezeitenfokus" },
        tab = 3, tier = 1, col = 3, -- Shaman Restoration Row 1 Col 3 (max 5: +1..5% hit)
    },
    NATURES_REACH = {
        patterns = { "nature's reach", "reichweite der natur" },
        tab = 1, tier = 2, col = 4, -- Druid Balance Row 2 Col 4 (max 2: +2/4% hit)
    },

    -- Scaling & specialty talents
    MENTAL_DEXTERITY = {
        patterns = { "mental dexterity", "geistige gewandtheit", "mentale gewandtheit" },
        tab = 2, tier = 2, col = 2, -- Shaman Enhancement Row 2 Col 2 (max 3: 33/66/100% INT -> AP)
    },
    MENTAL_QUICKNESS = {
        patterns = { "mental quickness", "geistige schnelligkeit", "mentale schnelligkeit" },
        tab = 2, tier = 5, col = 2, -- Shaman Enhancement Row 5 Col 2 (max 2: 15/30% INT -> SP/Heal)
    },
    CAREFUL_AIM = {
        patterns = { "careful aim", "sorgfältiges zielen" },
        tab = 2, tier = 2, col = 3, -- Hunter Marksmanship Row 2 Col 3 (max 5: 20..100% INT -> AP)
    },
    REVERENCE = {
        patterns = { "reverence", "ehrfurcht" },
        tab = 1, tier = 2, col = 2, -- Paladin Holy Row 2 Col 2 (max 2: 15/30% FSR mana regen)
    },
    CHAMPION_OF_THE_LIGHT = {
        patterns = { "champion of the light", "champion des lichts" },
        tab = 3, tier = 6, col = 3, -- Paladin Retribution Row 6 Col 3 (max 5: 12..60% INT -> SP)
    },
    ARCANE_BLAST = {
        patterns = { "arcane blast", "arkanschlag" },
        tab = 1, tier = 3, col = 4, -- Mage Arcane Row 3 Col 4 (max 1)
    },
    ARCANE_WRATH = {
        patterns = { "arcane wrath", "arkaner zorn" },
        tab = 1, tier = 4, col = 4, -- Mage Arcane Row 4 Col 4 (max 1)
    },
    MENTAL_STRENGTH = {
        patterns = { "mental strength", "geistige stärke" },
        tab = 1, tier = 2, col = 3, -- Priest Discipline Row 2 Col 3 (max 5: +2..10% INT)
    },
    NATURAL_INSTINCT = {
        patterns = { "natural instinct", "natürlicher instinkt" },
        tab = 2, tier = 5, col = 4, -- Druid Feral Row 5 Col 4 (max 2: +10/20% crit dmg, +12/25% INT->Heal)
    },
    WEAPON_EXPERTISE = {
        patterns = { "weapon expertise", "waffenexperte", "waffen-experte" },
        tab = 2, tier = 4, col = 3, -- Rogue Combat Row 4 Col 3 (max 2: -1/-2% target Dodge/Parry)
    },
}

-- Pattern alias map so external callers (e.g. TooltipHook.lua) work seamlessly on EN and DE clients
local PATTERN_ALIASES = {}
for _, def in pairs(TALENT_DEFINITIONS) do
    for _, pat in ipairs(def.patterns) do
        PATTERN_ALIASES[pat] = def
    end
end

-- General talent modifier rules for WoW Forever 1.60.1
-- Patterns support bilingual matching while preserving exact Forever talent behavior.
GSI_TalentIntegration.TalentModifierRules = {
    -- Critical Strike
    { patterns = { "grausamkeit", "cruelty" },                       stat = "Crit",         mod = 1.05 },
    { patterns = { "tödlichkeit", "lethality" },                     stat = "Crit",         mod = 1.06 },
    { patterns = { "verheeren", "ruin" },                            stat = "Crit",         mod = 1.06 },
    { patterns = { "verbrennung", "combustion" },                    stat = "Crit",         mod = 1.06 },
    { patterns = { "pandemie", "pandemic" },                         stat = "Crit",         mod = 1.08 },
    { patterns = { "durchbohren", "impale" },                        stat = "Crit",         mod = 1.06 },
    { patterns = { "tödliche schüsse", "mortal shots" },             stat = "Crit",         mod = 1.06 },
    { patterns = { "raubtierschärfe", "predator's edge" },           stat = "Crit",         mod = 1.06 },
    { patterns = { "eissplitter", "ice shards" },                    stat = "Crit",         mod = 1.06 },
    { patterns = { "elementarfuror", "elemental fury" },             stat = "Crit",         mod = 1.06 },
    { patterns = { "rache", "vengeance" },                           stat = "Crit",         mod = 1.06 },

    -- Hit (exact match prevents Holy Precision / Divine Precision leaking into general Hit)
    { patterns = { "präzision", "precision" },                       stat = "Hit",          mod = 1.08, exact = true },

    -- Haste / Attack Speed
    { patterns = { "schlaghagel", "flurry" },                        stat = "Haste",        mod = 1.08 },

    -- Primary Stats & Stamina / Intellect
    { patterns = { "herz der wildnis", "heart of the wild" },        stat = "Intellect",    mod = 1.08 },
    { patterns = { "herz der wildnis", "heart of the wild" },        stat = "Stamina",      mod = 1.06 },
    { patterns = { "dämonische umarmung", "demonic embrace" },       stat = "Stamina",      mod = 1.08 },
    { patterns = { "überlebenskünstler", "survivalist" },            stat = "Stamina",      mod = 1.06 },
    { patterns = { "arkaner geist", "arcane mind" },                 stat = "Intellect",    mod = 1.08 },

    -- Defense & Protection
    { patterns = { "dickes fell", "thick hide" },                    stat = "Armor",        mod = 1.06 },
    { patterns = { "antizipation", "anticipation" },                 stat = "Defense",      mod = 1.08 },
    { patterns = { "zähigkeit", "toughness" },                       stat = "Armor",        mod = 1.06 },
    { patterns = { "schild-spezialisierung", "schildspezialisierung", "shield specialization" }, stat = "Block", mod = 1.08 },

    -- Spell Damage & Healing
    { patterns = { "schattenmacht", "shadow power" },                stat = "SpellPower",       mod = 1.06 },
    { patterns = { "schattenmacht", "shadow power" },                stat = "ShadowSpellPower", mod = 1.06 },
    { patterns = { "arkan-macht", "arkanmacht", "arcane power" },    stat = "SpellPower",       mod = 1.08 },
    { patterns = { "arkan-macht", "arkanmacht", "arcane power" },    stat = "ArcaneSpellPower", mod = 1.08 },
    { patterns = { "dunkelheit", "darkness" },                       stat = "SpellPower",       mod = 1.05 },
    { patterns = { "dunkelheit", "darkness" },                       stat = "ShadowSpellPower", mod = 1.05 },
    { patterns = { "feuermacht", "fire power" },                     stat = "SpellPower",       mod = 1.06 },
    { patterns = { "feuermacht", "fire power" },                     stat = "FireSpellPower",   mod = 1.06 },
    { patterns = { "schattenbeherrschung", "shadow mastery" },       stat = "SpellPower",       mod = 1.10 },
    { patterns = { "schattenbeherrschung", "shadow mastery" },       stat = "ShadowSpellPower", mod = 1.10 },
    { patterns = { "spirituelle heilung", "spiritual healing" },     stat = "HealingPower", mod = 1.08 },
    { patterns = { "meditation" },                                   stat = "Spirit",       mod = 1.08 },
    { patterns = { "dunkle inspiration", "dark inspiration" },       stat = "Spirit",       mod = 1.15 },

    -- Weapon & Physical
    { patterns = { "waffenschaden", "weapon damage", "zweihandwaffen-spezialisierung", "two-handed weapon specialization" }, stat = "WeaponDamage", mod = 1.05 },
    { patterns = { "blitzartige reflexe", "lightning reflexes" },    stat = "Dodge",        mod = 1.06 },
}

-- Performance cache
GSI_TalentIntegration._cache = nil
GSI_TalentIntegration._cacheDirty = true

function GSI_TalentIntegration:Invalidate()
    self._cache = nil
    self._cacheDirty = true
end

local function MatchesAnyPattern(nameLower, patterns, exactOnly)
    if type(patterns) == "string" then
        patterns = { patterns }
    end
    for _, pat in ipairs(patterns) do
        local patLower = pat:lower()
        if exactOnly then
            if nameLower == patLower then
                return true
            end
        else
            if nameLower:find(patLower, 1, true) then
                return true
            end
        end
    end
    return false
end

-- Reads talent rank using localized EN/DE patterns with optional (tab, tier, col) coordinate fallback
function GSI_TalentIntegration:GetTalentRank(patterns, fallbackTab, fallbackTier, fallbackCol, exactOnly)
    if type(GetNumTalentTabs) ~= "function" or type(GetNumTalents) ~= "function" or type(GetTalentInfo) ~= "function" then
        return nil
    end

    local foundRank = nil
    local fallbackRank = nil

    pcall(function()
        local numTabs = GetNumTalentTabs() or 0
        if numTabs <= 0 then
            return
        end

        for tab = 1, numTabs do
            local numTalents = GetNumTalents(tab) or 0
            for idx = 1, numTalents do
                local name, _, tier, column, currentRank = GetTalentInfo(tab, idx)
                if name and patterns and MatchesAnyPattern(name:lower(), patterns, exactOnly) then
                    foundRank = currentRank or 0
                    return
                end
                if fallbackTab and fallbackTier and fallbackCol
                   and tab == fallbackTab and tier == fallbackTier and column == fallbackCol then
                    fallbackRank = currentRank or 0
                end
            end
        end
    end)

    if foundRank ~= nil then
        return foundRank
    end
    return fallbackRank
end

function GSI_TalentIntegration:GetTalentRankByDef(def)
    if not def then return nil end
    return self:GetTalentRank(def.patterns, def.tab, def.tier, def.col, def.exact)
end

-- Scans invested talents via the WoW Talent API
function GSI_TalentIntegration:GetStatModifiers()
    if self._cache and not self._cacheDirty then
        return self._cache
    end

    local mods = {}
    if type(GetNumTalentTabs) == "function" and type(GetNumTalents) == "function" and type(GetTalentInfo) == "function" then
        pcall(function()
            local numTabs = GetNumTalentTabs() or 0
            for tab = 1, numTabs do
                local numTalents = GetNumTalents(tab) or 0
                for idx = 1, numTalents do
                    local name, _, _, _, currentRank, maxRank = GetTalentInfo(tab, idx)
                    if name and currentRank and currentRank > 0 then
                        local nameLower = name:lower()
                        local denom = (maxRank and maxRank > 0) and maxRank or 5.0
                        local ratio = math.min(1.0, currentRank / denom)

                        for _, rule in ipairs(self.TalentModifierRules) do
                            if MatchesAnyPattern(nameLower, rule.patterns, rule.exact) then
                                if not mods[rule.stat] then
                                    mods[rule.stat] = 1.0
                                end
                                -- Rank-proportional scaling up to a 1.25x combined cap
                                local rankScale = 1.0 + ((rule.mod - 1.0) * ratio)
                                mods[rule.stat] = math.min(mods[rule.stat] * rankScale, 1.25)
                            end
                        end
                    end
                end
            end
        end)
    end

    self._cache = mods
    self._cacheDirty = false
    return mods
end

-- Backward-compatible pattern helper with automatic EN/DE alias and coordinate resolution
function GSI_TalentIntegration:GetTalentRankByPattern(pattern, fallbackTab, fallbackTier, fallbackCol, exactOnly)
    if not pattern then return nil end
    local patLower = pattern:lower()
    local def = PATTERN_ALIASES[patLower]
    if def then
        return self:GetTalentRank(
            def.patterns,
            fallbackTab or def.tab,
            fallbackTier or def.tier,
            fallbackCol or def.col,
            (exactOnly ~= nil) and exactOnly or def.exact
        )
    end
    return self:GetTalentRank(pattern, fallbackTab, fallbackTier, fallbackCol, exactOnly)
end

-- Forever 1.60.1 Shaman Enhancement Intellect Weight:
-- Mental Dexterity (3 ranks): 33/66/100% INT -> AP
-- Mental Quickness (2 ranks): 15/30% INT -> Spell Damage & Healing
-- Scales from 0.20 baseline to 0.90 EP at 3/3 MD + 2/2 MQ (matches Profiles_v2_2.lua)
function GSI_TalentIntegration:GetShamanEnhancementIntWeight()
    local rankMD = self:GetTalentRankByDef(TALENT_DEFINITIONS.MENTAL_DEXTERITY)
    local rankMQ = self:GetTalentRankByDef(TALENT_DEFINITIONS.MENTAL_QUICKNESS)

    if rankMD == nil and rankMQ == nil then
        return nil -- Talents unreadable / unavailable
    end

    local rMD = math.min(3, math.max(0, rankMD or 0))
    local rMQ = math.min(2, math.max(0, rankMQ or 0))

    local weight = 0.20 + (rMD * 0.17) + (rMQ * 0.095)
    return math.min(0.90, math.max(0.20, math.floor(weight * 100 + 0.5) / 100))
end

-- Hunter Marksmanship Intellect Weight (Careful Aim 5 ranks: 20/40/60/80/100% INT -> AP)
-- Formula: 0.15 + (rankCA * 0.082) => up to 0.56 at 5/5
function GSI_TalentIntegration:GetHunterMMIntWeight()
    local rankCA = self:GetTalentRankByDef(TALENT_DEFINITIONS.CAREFUL_AIM)
    if rankCA == nil then
        return nil
    end

    local r = math.min(5, math.max(0, rankCA))
    local weight = 0.15 + (r * 0.082)
    return math.min(0.56, math.max(0.15, math.floor(weight * 100 + 0.5) / 100))
end

-- Hunter Survival Intellect Weight (Careful Aim 5 ranks with melee/AP scaling)
-- Formula: 0.20 + (rankCA * 0.10) => up to 0.70 at 5/5
function GSI_TalentIntegration:GetHunterSurvivalIntWeight()
    local rankCA = self:GetTalentRankByDef(TALENT_DEFINITIONS.CAREFUL_AIM)
    if rankCA == nil then
        return nil
    end

    local r = math.min(5, math.max(0, rankCA))
    local weight = 0.20 + (r * 0.10)
    return math.min(0.70, math.max(0.20, math.floor(weight * 100 + 0.5) / 100))
end

-- Paladin Holy Spirit Weight (Reverence 2 ranks: 15/30% Spirit mana regen while casting)
-- Formula: 0.15 + (0.225 * rank) => 0.60 at 2/2
function GSI_TalentIntegration:GetPaladinHolySpiritWeight()
    local rankRev = self:GetTalentRankByDef(TALENT_DEFINITIONS.REVERENCE)
    if rankRev == nil then
        return nil
    end

    local r = math.min(2, math.max(0, rankRev))
    local weight = 0.15 + (r * 0.225)
    return math.min(0.60, math.max(0.15, math.floor(weight * 100 + 0.5) / 100))
end

-- Forever 1.60.1 Paladin Retribution Intellect Weight (Champion of the Light 5 ranks)
-- Grants 12/24/36/48/60% of Intellect as Spell Damage => up to 0.39 EP at 5/5
function GSI_TalentIntegration:GetPaladinRetIntWeight()
    local rankCotL = self:GetTalentRankByDef(TALENT_DEFINITIONS.CHAMPION_OF_THE_LIGHT)
    if rankCotL == nil then
        return nil
    end

    local r = math.min(5, math.max(0, rankCotL))
    local weight = 0.11 + (r * 0.056)
    return math.min(0.39, math.max(0.11, math.floor(weight * 100 + 0.5) / 100))
end

-- Forever 1.60.1 Mage Arcane Intellect & Mana Weight
-- Arcane Blast: INT scaling spell damage bonus; Arcane Wrath: SP from 5% Max Mana
function GSI_TalentIntegration:GetMageArcaneIntWeight()
    local rankAB = self:GetTalentRankByDef(TALENT_DEFINITIONS.ARCANE_BLAST)
    local rankAW = self:GetTalentRankByDef(TALENT_DEFINITIONS.ARCANE_WRATH)
    if rankAB == nil and rankAW == nil then
        return nil
    end
    local abBonus = (rankAB and rankAB > 0) and 0.54 or 0.0
    local awBonus = (rankAW and rankAW > 0) and 0.21 or 0.0
    local weight = 0.60 + abBonus + awBonus
    return math.min(1.45, math.max(0.45, math.floor(weight * 100 + 0.5) / 100))
end

function GSI_TalentIntegration:GetMageArcaneManaWeight()
    local rankAW = self:GetTalentRankByDef(TALENT_DEFINITIONS.ARCANE_WRATH)
    if rankAW == nil then
        return nil
    end
    if rankAW > 0 then
        return 0.032
    end
    return 0.015
end

-- Forever 1.60.1 Priest Mental Strength (Discipline Row 2 Col 3, 5 ranks: +2/4/6/8/10% INT)
function GSI_TalentIntegration:GetPriestMentalStrengthBonus()
    local rankMS = self:GetTalentRankByDef(TALENT_DEFINITIONS.MENTAL_STRENGTH)
    if not rankMS or rankMS <= 0 then return 0 end
    return math.min(5, rankMS) * 0.02
end

-- Forever 1.60.1 Druid Natural Instinct (Feral Row 5 Col 4, 2 ranks):
-- Rank 1: +10% melee ability crit dmg, +12% INT to Healing
-- Rank 2: +20% melee ability crit dmg, +25% INT to Healing
function GSI_TalentIntegration:GetDruidRestoIntBonus()
    local rankNI = self:GetTalentRankByDef(TALENT_DEFINITIONS.NATURAL_INSTINCT)
    if not rankNI or rankNI <= 0 then return 0 end
    if rankNI == 1 then return 0.12 end
    return 0.25
end

function GSI_TalentIntegration:GetDruidNaturalInstinctFeralCritMod()
    local rankNI = self:GetTalentRankByDef(TALENT_DEFINITIONS.NATURAL_INSTINCT)
    if not rankNI or rankNI <= 0 then return 1.0 end
    return 1.0 + (math.min(2, rankNI) * 0.04) -- 1.04 at 1/2, 1.08 at 2/2
end

-- Rogue Weapon Expertise (Combat Row 4 Col 3, 2 ranks): reduces target Dodge/Parry by 1% / 2%
function GSI_TalentIntegration:GetRogueWeaponExpertiseReduction()
    local rankWE = self:GetTalentRankByDef(TALENT_DEFINITIONS.WEAPON_EXPERTISE)
    if not rankWE or rankWE <= 0 then return 0 end
    return math.min(2.0, rankWE * 1.0)
end

-- School-restricted hit talent bonuses (never leak Holy-only hit into general Hit or Shadow/Melee)
function GSI_TalentIntegration:GetSchoolHitTalentBonus(class, specIndex, school)
    class = class or ResolvePlayerClass()
    if not school then return 0 end

    if class == "PRIEST" then
        if school == "Holy" then
            local r = self:GetTalentRankByDef(TALENT_DEFINITIONS.HOLY_PRECISION)
            if r and r > 0 then
                return math.min(18.0, r * 6.0)
            end
        elseif school == "Shadow" then
            local r = self:GetTalentRankByDef(TALENT_DEFINITIONS.SHADOW_FOCUS)
            if r and r > 0 then
                return math.min(5.0, r * 1.0)
            end
        end
    elseif class == "PALADIN" then
        if school == "Holy" then
            local r = self:GetTalentRankByDef(TALENT_DEFINITIONS.DIVINE_PRECISION)
            if r and r > 0 then
                return math.min(8.0, r * 4.0)
            end
        end
    end

    return 0
end

-- Forever 1.60.1 general Hit talent bonus (percentage, e.g. 6.0 for 6% Hit)
function GSI_TalentIntegration:GetClassHitTalentBonus(class, specIndex)
    class = class or ResolvePlayerClass()
    local bonus = 0

    if class == "WARLOCK" then
        local r = self:GetTalentRankByDef(TALENT_DEFINITIONS.SUPPRESSION)
        if r and r > 0 then bonus = bonus + math.min(5.0, r * 1.0) end

    elseif class == "ROGUE" then
        -- Combat Precision has max 3 ranks in Forever (+1/2/3% Hit)
        local r = self:GetTalentRankByDef(TALENT_DEFINITIONS.PRECISION_ROGUE)
        if r and r > 0 then bonus = bonus + math.min(3.0, r * 1.0) end

    elseif class == "HUNTER" then
        local r = self:GetTalentRankByDef(TALENT_DEFINITIONS.SUREFOOTED)
        if r and r > 0 then bonus = bonus + math.min(3.0, r * 1.0) end

    elseif class == "SHAMAN" then
        -- Tidal Focus (Restoration Row 1 Col 3): +1/2/3/4/5% Hit
        local r = self:GetTalentRankByDef(TALENT_DEFINITIONS.TIDAL_FOCUS)
        if r and r > 0 then bonus = bonus + math.min(5.0, r * 1.0) end

    elseif class == "MAGE" then
        -- Forever 1.60.1: Arcane Focus removed; Frost Row 1 Precision gives +2/4/6% Hit to ALL spells
        local r = self:GetTalentRankByDef(TALENT_DEFINITIONS.PRECISION_MAGE)
        if r and r > 0 then bonus = bonus + math.min(6.0, r * 2.0) end

    elseif class == "PRIEST" then
        -- Shadow Focus applies to Shadow; Holy Precision (+6/12/18%) is Holy-only and excluded from general/Shadow Hit
        if specIndex == 3 then
            local r = self:GetTalentRankByDef(TALENT_DEFINITIONS.SHADOW_FOCUS)
            if r and r > 0 then bonus = bonus + math.min(5.0, r * 1.0) end
        end

    elseif class == "PALADIN" then
        -- Protection Row 2 Precision (+1/2/3% All Hit); Divine Precision (+4/8%) is Holy-only and excluded from general/melee Hit
        local rPrec = self:GetTalentRankByDef(TALENT_DEFINITIONS.PRECISION_PALADIN)
        if rPrec and rPrec > 0 then bonus = bonus + math.min(3.0, rPrec * 1.0) end

    elseif class == "DRUID" and specIndex == 1 then
        -- Balance Nature's Reach (Row 2 Col 4): +2/4% Spell Hit
        local r = self:GetTalentRankByDef(TALENT_DEFINITIONS.NATURES_REACH)
        if r and r > 0 then bonus = bonus + math.min(4.0, r * 2.0) end
    end

    return bonus
end
