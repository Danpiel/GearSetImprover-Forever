-- ============================================================
-- GearSetImprover - RaceBonus.lua (WoW Forever 1.60.1 Launch)
-- Modifies base stat weights based on verified racial traits.
-- Cross-checked against TalentsForeverBook/Data.lua (L12555-12810).
-- ============================================================

GSI_RaceBonus = {}

-- Stat weight multipliers per normalized race key (WoW Forever 1.60.1)
GSI_RaceBonus.Modifiers = {
    -- Human:
    -- * Ruthless: +1% Critical Strike chance
    -- * The Human Spirit: +10% Spirit
    Human = {
        Crit   = 1.01,
        Spirit = 1.10,
    },

    -- Dwarf:
    -- * Artisan's Precision: +1% Hit chance with spells and attacks (returned via GetRacialHitBonus())
    Dwarf = {},

    -- Night Elf:
    -- * Quickness: +1% Dodge chance
    -- * Elune's Light: +10% Crit for 15s on 3m cooldown (8.33% uptime = +0.83% average)
    NightElf = {
        Dodge = 1.01,
        Crit  = 1.008,
    },

    -- Gnome:
    -- * Expansive Mind: +5% Maximum Mana / Rage / Energy
    -- * Eureka!: Active cooldown providing small uptime AP/RAP/SP/Healing boost
    Gnome = {
        Mana              = 1.05,
        SpellPower        = 1.01,
        AttackPower       = 1.01,
        RangedAttackPower = 1.01,
        HealingPower      = 1.01,
    },

    -- Orc:
    -- * Blood Fury: +10% Attack Power and Spell Power for 15s on 2m cooldown (12.5% uptime = +1.25%)
    -- * Command: +5% Pet Damage
    Orc = {
        AttackPower       = 1.0125,
        RangedAttackPower = 1.0125,
        SpellPower        = 1.0125,
    },

    -- Undead / Scourge:
    -- * Touch of the Grave + Shadow Resistance: minimal realistic combat & resist modifiers
    Scourge = {
        ShadowResist     = 1.02,
        ShadowSpellPower = 1.005,
        AttackPower      = 1.005,
    },

    -- Tauren:
    -- * Endurance: +5% Total Health
    Tauren = {
        Stamina = 1.05,
    },

    -- Troll:
    -- * Berserking: +10% Haste for 15s on 3m cooldown (8.33% uptime = +0.83% average)
    -- * Regeneration: +20% Health Regeneration
    Troll = {
        Haste = 1.008,
        HP5   = 1.20,
    },

    -- Skyborne (Windshaper / High Order):
    -- * Wind Blessed: +2% Haste
    Skyborne = {
        Haste = 1.02,
    },
}

-- Direct lookup aliases for common non-localized and localized race strings
local RACE_ALIASES = {
    human          = "Human",
    mensch         = "Human",
    dwarf          = "Dwarf",
    zwerg          = "Dwarf",
    nightelf       = "NightElf",
    nachtelf       = "NightElf",
    gnome          = "Gnome",
    gnom           = "Gnome",
    orc            = "Orc",
    ork            = "Orc",
    scourge        = "Scourge",
    undead         = "Scourge",
    untoter        = "Scourge",
    untote         = "Scourge",
    tauren         = "Tauren",
    taure          = "Tauren",
    troll          = "Troll",
    skyborne       = "Skyborne",
    himmelsgeborene = "Skyborne",
    himmelsgeborener = "Skyborne",
}

-- Substring checks for sub-race / variant forms such as Skyborne(Windshaper) or Skyborne (High Order)
local RACE_SUBSTRINGS = {
    { needle = "skyborne",        key = "Skyborne" },
    { needle = "himmelsgeboren",  key = "Skyborne" },
    { needle = "windshaper",      key = "Skyborne" },
    { needle = "windformer",      key = "Skyborne" },
    { needle = "highorder",       key = "Skyborne" },
    { needle = "nightelf",        key = "NightElf" },
    { needle = "nachtelf",        key = "NightElf" },
    { needle = "scourge",         key = "Scourge" },
    { needle = "undead",          key = "Scourge" },
    { needle = "untot",           key = "Scourge" },
    { needle = "human",           key = "Human" },
    { needle = "mensch",          key = "Human" },
    { needle = "dwarf",           key = "Dwarf" },
    { needle = "zwerg",           key = "Dwarf" },
    { needle = "gnome",           key = "Gnome" },
    { needle = "gnom",            key = "Gnome" },
    { needle = "orc",             key = "Orc" },
    { needle = "ork",             key = "Orc" },
    { needle = "tauren",          key = "Tauren" },
    { needle = "troll",           key = "Troll" },
}

local function NormalizeToken(raw)
    if type(raw) ~= "string" or raw == "" then return "" end
    return raw:lower():gsub("[%s%-%_%(%)]", "")
end

-- Normalizes localized and English UnitRace() strings (including Skyborne variants)
function GSI_RaceBonus:GetNormalizedRace(overrideRaceName, overrideRaceFile)
    local raceName, raceFile = overrideRaceName, overrideRaceFile
    if not raceName and type(UnitRace) == "function" then
        raceName, raceFile = UnitRace("player")
    end

    local candidates = { NormalizeToken(raceFile), NormalizeToken(raceName) }
    for _, tok in ipairs(candidates) do
        if tok ~= "" and RACE_ALIASES[tok] then
            return RACE_ALIASES[tok]
        end
    end

    for _, tok in ipairs(candidates) do
        if tok ~= "" then
            for _, entry in ipairs(RACE_SUBSTRINGS) do
                if tok:find(entry.needle, 1, true) then
                    return entry.key
                end
            end
        end
    end

    return nil
end

-- Returns stat weight modifiers for the player's current race
function GSI_RaceBonus:GetStatModifiers()
    local raceKey = self:GetNormalizedRace()
    if raceKey and self.Modifiers[raceKey] then
        return self.Modifiers[raceKey]
    end
    return {}
end

-- Returns racial flat Hit percentage bonus (e.g. 1.0 for Dwarf Artisan's Precision)
function GSI_RaceBonus:GetRacialHitBonus()
    local raceKey = self:GetNormalizedRace()
    if raceKey == "Dwarf" then
        return 1.0
    end
    return 0
end

-- Returns racial weapon crit bonus (%) for a weapon subClassID (none in Forever 1.60.1)
function GSI_RaceBonus:GetWeaponCritBonus(subClassID)
    return 0
end

-- Returns racial weapon skill bonus (none in Forever 1.60.1)
function GSI_RaceBonus:GetWeaponSkillBonus(weaponSkillType)
    return 0
end
