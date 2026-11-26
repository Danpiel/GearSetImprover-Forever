-- ============================================================
-- GearSetImprover - Profiles_v2_2.lua (WoW Forever v2.2)
-- Source: Theorycrafting Review v2.2 (2026-11-03 / Client 1.60.1.70707 Official Launch)
-- ============================================================

GSI_Config = GSI_Config or {}

GSI_Config.Version_v2_2 = "2.2"
GSI_Config.Version = "2.2"
GSI_Config.Stand_v2_2 = "2026-11-19"
GSI_Config.Stand = "2026-11-26"

GSI_Config.Rules_v2_2 = {
    ["merged_hit_crit"] = true,
    ["heal_to_damage"] = {
        ["factor"] = 0.3333333333333333,
        ["applies_to"] = "all non-healer profiles: HEAL_weight = SPELL_DMG_weight / 3",
    },
    ["healer_spell_damage_weight"] = 0,
    ["wand_spell_damage"] = false,
    ["slot_rules"] = {
        "Compare within matching equipment slots only",
        "Feral Cat/Bear: Shields and Held In Off-Hand items = Score 0",
        "Feral: Auto-attack DPS in Cat/Bear uses equipped weapon DPS (normalized to 1.0s Cat / 2.5s Bear)"
    },
    ["hit_cap_note"] = "Hit/Crit on Forever items are flat percentage values. Raid boss caps (Level 63): Yellow Hit 9%, Dual-Wield White Cap 24.6-27%, Spell Hit 16%.",
    ["spell_power_item_line"] = "Caster items use 'Increases spell power': maps 1:1 to SPELL_DMG for DPS and HealingPower for healers.",
    ["avoid_red"] = {
        ["unit"] = "flat percent",
        ["note"] = "Boss dodge = 5.6% (Level 63 vs. 300 Weapon Skill). Parry only applies from the front.",
        ["dps_cap_pct"] = 5.6,
    },
    ["release_status"] = "WoW Forever Post-Launch Hotfix Audit (Client 1.60.1.70755, Stand 2026-11-19)",
}
GSI_Config.Rules_v2_1 = GSI_Config.Rules_v2_2

GSI_Config.Profiles_v2_2 = GSI_Config.Profiles_v2_2 or {}

GSI_Config.SpecModeToProfileID_v2_2 = {
    ["WARRIOR:1:ST"] = "krieger_waffen",
    ["WARRIOR:1:AOE"] = "krieger_waffen_aoe",
    ["WARRIOR:2:ST"] = "krieger_furor",
    ["WARRIOR:2:AOE"] = "krieger_furor_aoe",
    ["WARRIOR:3:Survival"] = "krieger_schutz",
    ["WARRIOR:3:Threat"] = "krieger_schutz_threat",
    ["WARRIOR:3:DMG"] = "krieger_schutz_threat",
    ["PALADIN:1:ST"] = "paladin_heilig",
    ["PALADIN:1:AOE"] = "paladin_heilig_aoe",
    ["PALADIN:2:Survival"] = "paladin_schutz",
    ["PALADIN:2:Threat"] = "paladin_schutz_threat",
    ["PALADIN:2:DMG"] = "paladin_schutz_threat",
    ["PALADIN:3:ST"] = "paladin_vergeltung",
    ["PALADIN:3:AOE"] = "paladin_vergeltung_aoe",
    ["HUNTER:1:ST"] = "j_ger_tierherrschaft",
    ["HUNTER:1:AOE"] = "j_ger_tierherrschaft_aoe",
    ["HUNTER:2:ST"] = "j_ger_treffsicherheit",
    ["HUNTER:2:AOE"] = "j_ger_treffsicherheit_aoe",
    ["HUNTER:3:ST"] = "j_ger_ueberleben",
    ["HUNTER:3:AOE"] = "j_ger_ueberleben_aoe",
    ["ROGUE:1:ST"] = "schurke_meucheln",
    ["ROGUE:1:AOE"] = "schurke_meucheln_aoe",
    ["ROGUE:2:ST"] = "schurke_kampf",
    ["ROGUE:2:AOE"] = "schurke_kampf_aoe",
    ["ROGUE:3:ST"] = "schurke_taeuschung",
    ["ROGUE:3:AOE"] = "schurke_taeuschung_aoe",
    ["PRIEST:1:ST"] = "priester_disziplin",
    ["PRIEST:1:AOE"] = "priester_disziplin_aoe",
    ["PRIEST:2:ST"] = "priester_heilig",
    ["PRIEST:2:AOE"] = "priester_heilig_aoe",
    ["PRIEST:3:ST"] = "priester_schatten",
    ["PRIEST:3:AOE"] = "priester_schatten_aoe",
    ["SHAMAN:1:ST"] = "schamane_elementar",
    ["SHAMAN:1:AOE"] = "schamane_elementar_aoe",
    ["SHAMAN:2:ST"] = "schamane_verstaerker",
    ["SHAMAN:2:AOE"] = "schamane_verstaerker_aoe",
    ["SHAMAN:3:ST"] = "schamane_wiederherstellung",
    ["SHAMAN:3:AOE"] = "schamane_wiederherstellung_aoe",
    ["MAGE:1:ST"] = "magier_arkan",
    ["MAGE:1:AOE"] = "magier_arkan_aoe",
    ["MAGE:2:ST"] = "magier_feuer",
    ["MAGE:2:AOE"] = "magier_feuer_aoe",
    ["MAGE:3:ST"] = "magier_frost",
    ["MAGE:3:AOE"] = "magier_frost_aoe",
    ["WARLOCK:1:ST"] = "hexenmeister_gebrechen",
    ["WARLOCK:1:AOE"] = "hexenmeister_gebrechen_aoe",
    ["WARLOCK:2:ST"] = "hexenmeister_daemonologie",
    ["WARLOCK:2:AOE"] = "hexenmeister_daemonologie_aoe",
    ["WARLOCK:3:ST"] = "hexenmeister_zerstoerung",
    ["WARLOCK:3:AOE"] = "hexenmeister_zerstoerung_aoe",
    ["DRUID:1:ST"] = "druide_gleichgewicht",
    ["DRUID:1:AOE"] = "druide_gleichgewicht_aoe",
    ["DRUID:2:Survival"] = "druide_baer",
    ["DRUID:2:Threat"] = "druide_baer_threat",
    ["DRUID:2:DMG"] = "druide_baer_threat",
    ["DRUID:3:ST"] = "druide_katze",
    ["DRUID:3:AOE"] = "druide_katze_aoe",
    ["DRUID:4:ST"] = "druide_wiederherstellung",
    ["DRUID:4:AOE"] = "druide_wiederherstellung_aoe",
}
GSI_Config.SpecModeToProfileID = GSI_Config.SpecModeToProfileID_v2_2

function GSI_Config:GetProfileV22(class, specIndex, mode)
    if not class then
        class = (GSI_ClassicData and GSI_ClassicData.GetPlayerClass and GSI_ClassicData:GetPlayerClass())
            or select(2, UnitClass("player")) or "WARRIOR"
    end
    if not specIndex then
        specIndex = (GSI_StatWeights and GSI_StatWeights.GetActiveSpecIndex and GSI_StatWeights:GetActiveSpecIndex()) or 1
    end
    local modeKey = mode or "ST"
    if modeKey == "default" then modeKey = "ST" end

    local mapping = GSI_Config.SpecModeToProfileID_v2_2 or GSI_Config.SpecModeToProfileID or {}
    local lookupKey = class .. ":" .. specIndex .. ":" .. modeKey
    local profID = mapping[lookupKey]
    if not profID then
        lookupKey = class .. ":" .. specIndex .. ":ST"
        profID = mapping[lookupKey]
    end
    if not profID then
        lookupKey = class .. ":" .. specIndex .. ":Survival"
        profID = mapping[lookupKey]
    end
    if profID and GSI_Config.Profiles_v2_2 and GSI_Config.Profiles_v2_2[profID] then
        return GSI_Config.Profiles_v2_2[profID]
    end
    return nil
end

-- Universal alias: Prefer v2.2 profiles
GSI_Config.GetProfile = GSI_Config.GetProfileV22

-- Backward-compatibility redirect for legacy v2.1 callers
function GSI_Config:GetProfileV21(class, specIndex, mode)
    return self:GetProfileV22(class, specIndex, mode)
end

-- ============================================================
-- Stat Normalization & GetProfileWeights (ItemScore / StatWeights API)
-- ============================================================
local PROFILE_STAT_MAP = {
    STR = "Strength",
    AGI = "Agility",
    STA = "Stamina",
    INT = "Intellect",
    SPI = "Spirit",
    SPIRIT = "Spirit",
    MANA = "Mana",
    SPEED = "Speed",
    ARMOR = "Armor",
    ARP = "ArmorPenetration",
    ARMOR_PEN = "ArmorPenetration",
    ARMOR_PENETRATION = "ArmorPenetration",
    DEFENSE = "Defense",
    DODGE = "Dodge",
    PARRY = "Parry",
    BLOCK = "Block",
    BLOCK_CHANCE = "Block",
    BLOCK_VALUE = "BlockValue",
    AP = "AttackPower",
    FERAL_AP = "FeralAttackPower",
    RAP = "RangedAttackPower",
    SPELL_DMG = "SpellPower",
    SPELL_POWER = "SpellPower",
    HEAL = "HealingPower",
    HIT = "Hit",
    SPELL_HIT = "Hit",
    CRIT = "Crit",
    SPELL_CRIT = "Crit",
    HASTE = "Haste",
    SPELL_HASTE = "Haste",
    MP5 = "MP5",
    HP5 = "HP5",
    WEAPON_DPS = "WeaponDamage",
    WEAPON_DPS_MH = "WeaponDamage",
    WEAPON_DPS_OH = "WeaponDamageOH",
    WEAPON_DPS_RANGED = "RangedDPS",
    RANGED_DPS = "RangedDPS",
    WEAPON_SPEED = "WeaponSpeed",
    WEAPON_SKILL = "WeaponSkill",
    AVOID_RED = "AvoidanceReduction",
    SPELL_PEN = "SpellPenetration",
    HOLY = "HolySpellPower",
    HOLY_SP = "HolySpellPower",
    FIRE = "FireSpellPower",
    FIRE_DMG = "FireSpellPower",
    FROST = "FrostSpellPower",
    FROST_DMG = "FrostSpellPower",
    FROST_SPELL_DMG = "FrostSpellPower",
    SHADOW = "ShadowSpellPower",
    SHADOW_DMG = "ShadowSpellPower",
    ARCANE = "ArcaneSpellPower",
    ARCANE_DMG = "ArcaneSpellPower",
    NATURE = "NatureSpellPower",
    NATURE_DMG = "NatureSpellPower",
}

function GSI_Config:NormalizeProfileWeights(rawWeights)
    if not rawWeights then return nil end
    local normalized = {}
    for k, v in pairs(rawWeights) do
        local mappedKey = PROFILE_STAT_MAP[k] or k
        normalized[mappedKey] = v
    end
    return normalized
end

GSI_Config._normalizedProfileWeightsCache = GSI_Config._normalizedProfileWeightsCache or {}

function GSI_Config:GetProfileWeights(class, specIndex, mode)
    local prof = self:GetProfile(class, specIndex, mode)
    if prof and prof.weights then
        local cacheKey = prof.id
        if cacheKey and self._normalizedProfileWeightsCache[cacheKey] then
            return self._normalizedProfileWeightsCache[cacheKey]
        end
        local norm = self:NormalizeProfileWeights(prof.weights)
        if cacheKey and norm then
            self._normalizedProfileWeightsCache[cacheKey] = norm
        end
        return norm
    end
    return nil
end
