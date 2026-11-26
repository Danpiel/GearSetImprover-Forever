-- ============================================================
-- GearSetImprover - Config.lua (WoW Forever)
-- Default stat weights and configuration for WoW Forever.
-- Includes optimized equivalency-point defaults synced with v2.2 profiles.
-- ============================================================

-- Texts: Locales\Locales.lua normally defines GSI_L before this file. A
-- client started before that file existed sees only the files that were
-- there at its start (/reload does not add new ones): then the English texts
-- show instead of errors until the game is restarted.
if not GSI_L then
    GSI_LOCALE = GSI_LOCALE or (GetLocale and GetLocale()) or "enUS"
    GSI_L = setmetatable({}, {
        __index = function(_, key) return key end,
        __call = function(t, key) return t[key] end,
    })
    GSI_AddTranslations = GSI_AddTranslations or function() end
end
GSI_SET_NAMES = GSI_SET_NAMES or {}

-- ============================================================
-- Client API Compatibility Layer (Modern Engine)
-- ============================================================
if not _G.GetItemInfo and C_Item and C_Item.GetItemInfo then
    pcall(function() _G.GetItemInfo = C_Item.GetItemInfo end)
end
if not _G.GetItemInfoInstant and C_Item and C_Item.GetItemInfoInstant then
    pcall(function() _G.GetItemInfoInstant = C_Item.GetItemInfoInstant end)
end
local function GSI_SafeGetItemIcon(item)
    if not item then return "Interface\\Icons\\INV_Misc_QuestionMark" end
    if type(item) == "table" and C_Item and C_Item.GetItemIcon then
        local ok, icon = pcall(C_Item.GetItemIcon, item)
        if ok and icon then return icon end
    end
    if C_Item and C_Item.GetItemIconByID then
        local ok, icon = pcall(C_Item.GetItemIconByID, item)
        if ok and icon then return icon end
    end
    local instantFn = (C_Item and C_Item.GetItemInfoInstant) or _G.GetItemInfoInstant
    if instantFn then
        local ok, _, _, _, _, icon = pcall(instantFn, item)
        if ok and icon then return icon end
    end
    local infoFn = (C_Item and C_Item.GetItemInfo) or _G.GetItemInfo
    if infoFn then
        local ok, _, _, _, _, _, _, _, _, _, icon = pcall(infoFn, item)
        if ok and icon then return icon end
    end
    if type(item) == "string" then
        local itemID = tonumber(item:match("item:(%d+)"))
        if itemID then
            if C_Item and C_Item.GetItemIconByID then
                local ok, icon = pcall(C_Item.GetItemIconByID, itemID)
                if ok and icon then return icon end
            end
            if instantFn then
                local ok, _, _, _, _, icon = pcall(instantFn, itemID)
                if ok and icon then return icon end
            end
        end
    end
    return "Interface\\Icons\\INV_Misc_QuestionMark"
end
_G.GSI_GetItemIcon = GSI_SafeGetItemIcon
_G.GetItemIcon = GSI_SafeGetItemIcon

if not _G.GetItemCount and C_Item and C_Item.GetItemCount then
    pcall(function() _G.GetItemCount = C_Item.GetItemCount end)
end
if not _G.GetItemQualityColor and C_Item and C_Item.GetItemQualityColor then
    pcall(function() _G.GetItemQualityColor = C_Item.GetItemQualityColor end)
end

GSI_Config = {}

-- Central Chat Output Helper (respects disableChatOutput setting)
function GSI_Print(...)
    if GearSetImproverDB and (GearSetImproverDB.disableChatOutput == true or GearSetImproverDB.disableChat == true) then
        return
    end
    print(...)
end
_G.GSI_Print = GSI_Print


-- Stat weighting mode (ST = Single Target, AOE = Area of Effect / Dungeon)
GSI_Config.WeightMode = "ST"

-- Tank mode (Survival = Maximum Mitigation/HP, DMG = Threat/Attack Power)
GSI_Config.TankMode = "Survival"

-- General weapon DPS weights
GSI_Config.WeaponDPSWeight = 14.0
GSI_Config.RangedDPSWeight = 16.0

-- Threshold for Best-in-Bag suggestions
GSI_Config.BiBThreshold = 50

-- Default Clean-up threshold (score difference vs. equipped item)
GSI_Config.JunkThreshold = 5
GSI_Config.JunkIncludeOtherArmor = false
GSI_Config.JunkIncludeWhiteGear = true
GSI_Config.JunkIncludeUnusableGear = true

-- Default settings for Upgrade Toast notifications and overlays
GSI_Config.EnableUpgradeToast = true
GSI_Config.ToastDuration = 60
GSI_Config.ToastBlink = true
GSI_Config.ToastPlaySound = true
GSI_Config.ToastMinDelta = 1.0
GSI_Config.IgnoreEnchants = true
GSI_Config.MerchantOverlayEnabled = true

-- Central scoring rules for tooltips & optimization
-- Keep set bonuses & sockets out of the linear stat sum to avoid skewing raw item scores
GSI_Config.SetPieceValue = 0.0         -- 0 = Pure linear stat sum
GSI_Config.SocketValue = 0.0           -- 0 by default
GSI_Config.IlvlScoreFactor = 0.5       -- Fallback score per item level (only if no stats are present)

-- Mapping of WoW API stat tokens to GSI stat keys (WoW Forever)
GSI_Config.StatMap = {
    ITEM_MOD_CRIT_RATING_SHORT             = "Crit",
    ITEM_MOD_CRIT_RATING                   = "Crit",
    ITEM_MOD_HIT_RATING_SHORT              = "Hit",
    ITEM_MOD_HIT_RATING                    = "Hit",
    ITEM_MOD_HASTE_RATING_SHORT            = "Haste",
    ITEM_MOD_HASTE_RATING                  = "Haste",
    ITEM_MOD_ARMOR_PENETRATION_RATING_SHORT = "ArmorPenetration",
    ITEM_MOD_ARMOR_PENETRATION_RATING       = "ArmorPenetration",
    ITEM_MOD_ARMOR_PENETRATION_SHORT        = "ArmorPenetration",
    ITEM_MOD_ARMOR_PENETRATION              = "ArmorPenetration",
    ARMOR_PENETRATION                       = "ArmorPenetration",
    ITEM_MOD_ATTACK_POWER_SHORT            = "AttackPower",
    ITEM_MOD_ATTACK_POWER                  = "AttackPower",
    ITEM_MOD_RANGED_ATTACK_POWER_SHORT     = "RangedAttackPower",
    ITEM_MOD_RANGED_ATTACK_POWER           = "RangedAttackPower",
    ITEM_MOD_SPELL_POWER_SHORT             = "SpellPower",
    ITEM_MOD_SPELL_POWER                   = "SpellPower",
    ITEM_MOD_SPELL_DAMAGE_DONE_SHORT       = "SpellPower",
    ITEM_MOD_SPELL_DAMAGE_DONE             = "SpellPower",
    ITEM_MOD_SPELL_HEALING_DONE_SHORT      = "HealingPower",
    ITEM_MOD_SPELL_HEALING_DONE            = "HealingPower",
    ITEM_MOD_MANA_REGENERATION_SHORT       = "MP5",
    ITEM_MOD_MANA_REGENERATION             = "MP5",
    ITEM_MOD_POWER_REGEN0_SHORT            = "MP5",
    ITEM_MOD_POWER_REGEN0                  = "MP5",
    ITEM_MOD_MANA_SHORT                    = "Mana",
    ITEM_MOD_MANA                          = "Mana",
    MANA                                   = "Mana",
    ITEM_MOD_HEALTH_REGEN_SHORT            = "HP5",
    ITEM_MOD_HEALTH_REGENERATION_SHORT     = "HP5",
    ITEM_MOD_HEALTH_REGEN                  = "HP5",
    ITEM_MOD_HEALTH_REGENERATION           = "HP5",
    ITEM_MOD_AGILITY_SHORT                 = "Agility",
    ITEM_MOD_AGILITY                       = "Agility",
    ITEM_MOD_STRENGTH_SHORT                = "Strength",
    ITEM_MOD_STRENGTH                      = "Strength",
    ITEM_MOD_INTELLECT_SHORT               = "Intellect",
    ITEM_MOD_INTELLECT                     = "Intellect",
    ITEM_MOD_STAMINA_SHORT                 = "Stamina",
    ITEM_MOD_STAMINA                       = "Stamina",
    ITEM_MOD_SPIRIT_SHORT                  = "Spirit",
    ITEM_MOD_SPIRIT                        = "Spirit",
    ITEM_MOD_ARMOR_SHORT                   = "Armor",
    -- GetItemStats reports armor and resistances as RESISTANCEn_NAME
    -- (0 armor, 1 holy, 2 fire, 3 nature, 4 frost, 5 shadow, 6 arcane)
    RESISTANCE0_NAME                       = "Armor",
    RESISTANCE2_NAME                       = "FireResist",
    RESISTANCE3_NAME                       = "NatureResist",
    RESISTANCE4_NAME                       = "FrostResist",
    RESISTANCE5_NAME                       = "ShadowResist",
    RESISTANCE6_NAME                       = "ArcaneResist",
    ITEM_MOD_FERAL_ATTACK_POWER_SHORT      = "FeralAttackPower",
    ITEM_MOD_FERAL_ATTACK_POWER            = "FeralAttackPower",
    ITEM_MOD_ARMOR                         = "Armor",
    ITEM_MOD_DEFENSE_SKILL_RATING_SHORT    = "Defense",
    ITEM_MOD_DEFENSE_SKILL_RATING          = "Defense",
    ITEM_MOD_DODGE_RATING_SHORT            = "Dodge",
    ITEM_MOD_DODGE_RATING                  = "Dodge",
    ITEM_MOD_PARRY_RATING_SHORT            = "Parry",
    ITEM_MOD_PARRY_RATING                  = "Parry",
    ITEM_MOD_BLOCK_RATING_SHORT            = "Block",
    ITEM_MOD_BLOCK_RATING                  = "Block",
    ITEM_MOD_EXPERTISE_RATING_SHORT        = "AvoidanceReduction",
    ITEM_MOD_EXPERTISE_RATING              = "AvoidanceReduction",
    ITEM_MOD_BLOCK_VALUE_SHORT             = "BlockValue",
    ITEM_MOD_BLOCK_VALUE                   = "BlockValue",
    ITEM_MOD_SPELL_PENETRATION_SHORT       = "SpellPenetration",
    ITEM_MOD_SPELL_PENETRATION             = "SpellPenetration",
    WEAPON_SPEED                           = "WeaponSpeed",
    ITEM_MOD_WEAPON_SPEED                  = "WeaponSpeed",
    SPEED                                  = "Speed",
    ITEM_MOD_SPEED_SHORT                   = "Speed",
    ITEM_MOD_SPEED                         = "Speed",
    FLAT_WEAPON_DMG                        = "FlatWeaponDamage",
}

-- Secondary/Tertiary fallback weights (WoW Forever)
GSI_Config.TertiaryWeights = {
    Stamina            = 0.5,
    Spirit             = 0.0,
    Mana               = 0.0,
    Speed              = 0.0,
    HP5                = 0.0,
    ArmorPenetration   = 0.0,
    WeaponSpeed        = 0.0,
    FlatWeaponDamage   = 0.0,
    SpellPenetration   = 0.0,
    ArcaneSpellPower   = 0.0,
    FireSpellPower     = 0.0,
    FrostSpellPower    = 0.0,
    ShadowSpellPower   = 0.0,
    NatureSpellPower   = 0.0,
    HolySpellPower     = 0.0,
}

-- Default resistance weight when a resistance mode is enabled
GSI_Config.DefaultResistWeight = 5.0

-- ============================================================
-- Default Stat Weights for all 9 Classes / 28 Specializations
-- Synced with Profiles_v2_2 baseline weights and Forever mechanics.
-- Stat keys: Strength, Agility, Stamina, Intellect, Spirit, Mana, Speed,
--            AttackPower, RangedAttackPower, SpellPower, HealingPower,
--            Hit, Crit, Haste, ArmorPenetration, MP5, Armor, Defense,
--            Dodge, Parry, Block, BlockValue, WeaponDamage, WeaponDamageOH,
--            RangedDPS, WeaponSkill, AvoidanceReduction
-- ============================================================
GSI_Config.DefaultWeights = {
    ["DRUID"] = {
        [1] = { -- Balance
            Stamina = 0.20,
            Intellect = 0.44,
            Spirit = 0.32,
            Armor = 0.01,
            Hit = 15.60,
            Crit = 13.65,
            Haste = 13.15,
            SpellPower = 1.00,
            HealingPower = 0.10,
            SpellPenetration = 1.60,
            MP5 = 0.52,
            Mana = 0.015,
            ArcaneSpellPower = 0.99,
            NatureSpellPower = 1.00,
        },
        [2] = { -- Feral Bear (Tank)
            ["Survival"] = {
                Strength = 0.35,
                Agility = 0.95,
                Stamina = 1.00,
                Intellect = 0.05,
                Spirit = 0.05,
                Armor = 0.18,
                Defense = 1.55,
                Dodge = 13.50,
                AttackPower = 0.12,
                FeralAttackPower = 0.12,
                Hit = 8.00,
                Crit = 5.50,
                Haste = 4.80,
                WeaponDamage = 1.35,
                WeaponSkill = 1.60,
                AvoidanceReduction = 8.00,
                ArmorPenetration = 0.04,
                SpellPower = 0.00,
                NatureSpellPower = 0.00,
                HealingPower = 0.00,
            },
            ["DMG"] = {
                Strength = 1.00,
                Agility = 1.00,
                Stamina = 0.55,
                Intellect = 0.05,
                Spirit = 0.05,
                Armor = 0.09,
                Defense = 0.65,
                Dodge = 7.50,
                AttackPower = 0.45,
                FeralAttackPower = 0.45,
                Hit = 14.00,
                Crit = 12.00,
                Haste = 11.50,
                WeaponDamage = 5.50,
                WeaponSkill = 2.80,
                AvoidanceReduction = 13.50,
                ArmorPenetration = 0.12,
                SpellPower = 0.00,
                NatureSpellPower = 0.00,
                HealingPower = 0.00,
            },
        },
        [3] = { -- Feral Cat (Melee DPS)
            Strength = 1.00,
            Agility = 1.12,
            Stamina = 0.15,
            Intellect = 0.00,
            Spirit = 0.00,
            Armor = 0.01,
            AttackPower = 0.45,
            FeralAttackPower = 0.45,
            Hit = 13.20,
            Crit = 13.20,
            Haste = 8.40,
            WeaponDamage = 8.30,
            WeaponDamageOH = 0.00,
            WeaponSkill = 3.10,
            AvoidanceReduction = 12.80,
            ArmorPenetration = 0.15,
            MP5 = 0.15,
        },
        [4] = { -- Restoration (Healer)
            Stamina = 0.20,
            Intellect = 0.60,
            Spirit = 0.65,
            Armor = 0.01,
            Crit = 9.80,
            Haste = 11.50,
            SpellPower = 0.00,
            HealingPower = 1.00,
            MP5 = 1.35,
        },
    },
    ["WARRIOR"] = {
        [1] = { -- Arms
            Strength = 1.00,
            Agility = 0.75,
            Stamina = 0.20,
            Spirit = 0.00,
            Armor = 0.01,
            AttackPower = 0.48,
            Hit = 14.80,
            Crit = 13.60,
            Haste = 10.50,
            WeaponDamage = 12.20,
            WeaponDamageOH = 0.00,
            WeaponSkill = 3.20,
            AvoidanceReduction = 11.40,
            ArmorPenetration = 0.15,
        },
        [2] = { -- Fury
            Strength = 1.00,
            Agility = 0.75,
            Stamina = 0.18,
            Spirit = 0.00,
            Armor = 0.01,
            AttackPower = 0.48,
            Hit = 14.50,
            Crit = 13.80,
            Haste = 11.40,
            WeaponDamage = 8.80,
            WeaponDamageOH = 4.40,
            WeaponSkill = 3.50,
            AvoidanceReduction = 12.80,
            ArmorPenetration = 0.15,
        },
        [3] = { -- Protection (Tank)
            ["Survival"] = {
                Strength = 0.40,
                Agility = 0.50,
                Stamina = 1.00,
                Spirit = 0.00,
                Armor = 0.025,
                Defense = 1.45,
                Dodge = 12.50,
                Parry = 12.50,
                Block = 7.80,
                BlockValue = 0.95,
                AttackPower = 0.12,
                Hit = 8.50,
                Crit = 5.00,
                Haste = 4.50,
                WeaponDamage = 1.15,
                WeaponSkill = 1.80,
                AvoidanceReduction = 8.50,
                ArmorPenetration = 0.04,
            },
            ["DMG"] = {
                Strength = 1.00,
                Agility = 0.85,
                Stamina = 0.55,
                Spirit = 0.00,
                Armor = 0.06,
                Defense = 0.75,
                Dodge = 7.20,
                Parry = 8.20,
                Block = 5.50,
                BlockValue = 1.05,
                AttackPower = 0.45,
                Hit = 14.50,
                Crit = 11.50,
                Haste = 11.40,
                WeaponDamage = 4.20,
                WeaponDamageOH = 0.00,
                WeaponSkill = 3.20,
                AvoidanceReduction = 13.50,
                ArmorPenetration = 0.12,
            },
        },
    },
    ["PALADIN"] = {
        [1] = { -- Holy (Healer)
            Stamina = 0.20,
            Intellect = 0.80,
            Spirit = 0.35,
            Armor = 0.01,
            Crit = 12.20,
            Haste = 10.80,
            SpellPower = 0.00,
            HealingPower = 1.00,
            MP5 = 2.30,
            HolySpellPower = 0.00,
        },
        [2] = { -- Protection (Tank)
            ["Survival"] = {
                Strength = 0.55,
                Agility = 0.50,
                Stamina = 1.00,
                Intellect = 0.22,
                Spirit = 0.05,
                Armor = 0.045,
                Defense = 1.45,
                Dodge = 12.00,
                Parry = 12.00,
                Block = 9.50,
                BlockValue = 1.25,
                AttackPower = 0.08,
                Hit = 7.50,
                Crit = 4.50,
                Haste = 4.20,
                WeaponDamage = 1.05,
                WeaponSkill = 1.50,
                AvoidanceReduction = 7.50,
                ArmorPenetration = 0.04,
                SpellPower = 0.95,
                HealingPower = 0.32,
                SpellPenetration = 0.15,
                MP5 = 0.45,
                HolySpellPower = 0.95,
            },
            ["DMG"] = {
                Strength = 1.00,
                Agility = 0.60,
                Stamina = 0.55,
                Intellect = 0.35,
                Spirit = 0.05,
                Armor = 0.035,
                Defense = 0.70,
                Dodge = 6.00,
                Parry = 6.50,
                Block = 5.50,
                BlockValue = 0.95,
                AttackPower = 0.38,
                Hit = 14.50,
                Crit = 10.85,
                Haste = 10.20,
                WeaponDamage = 4.00,
                WeaponSkill = 2.40,
                AvoidanceReduction = 11.00,
                ArmorPenetration = 0.10,
                SpellPower = 1.42,
                HealingPower = 0.45,
                SpellPenetration = 0.65,
                MP5 = 0.45,
                HolySpellPower = 1.42,
            },
        },
        [3] = { -- Retribution
            Strength = 1.00,
            Agility = 0.74,
            Stamina = 0.15,
            Intellect = 0.32,
            Spirit = 0.05,
            Armor = 0.01,
            AttackPower = 0.48,
            Hit = 14.60,
            Crit = 13.65,
            Haste = 10.20,
            WeaponDamage = 11.80,
            WeaponDamageOH = 0.00,
            WeaponSkill = 2.80,
            AvoidanceReduction = 13.20,
            ArmorPenetration = 0.14,
            SpellPower = 0.55,
            HealingPower = 0.16,
            SpellPenetration = 0.40,
            MP5 = 0.40,
            HolySpellPower = 0.55,
        },
    },
    ["HUNTER"] = {
        [1] = { -- Beast Mastery
            Strength = 0.10,
            Agility = 1.00,
            Stamina = 0.25,
            Intellect = 0.16,
            Spirit = 0.05,
            Armor = 0.01,
            AttackPower = 0.44,
            RangedAttackPower = 0.44,
            Hit = 14.10,
            Crit = 12.65,
            Haste = 11.80,
            RangedDPS = 7.40,
            WeaponDamage = 0.50,
            WeaponDamageOH = 0.50,
            WeaponSkill = 2.40,
            ArmorPenetration = 0.12,
            SpellPower = 0.00,
            HealingPower = 0.00,
            MP5 = 0.48,
            ArcaneSpellPower = 0.00,
            NatureSpellPower = 0.00,
        },
        [2] = { -- Marksmanship
            Strength = 0.08,
            Agility = 1.00,
            Stamina = 0.15,
            Intellect = 0.35,
            Spirit = 0.02,
            Armor = 0.01,
            AttackPower = 0.38,
            RangedAttackPower = 0.38,
            Hit = 15.40,
            Crit = 14.50,
            Haste = 12.40,
            RangedDPS = 8.60,
            WeaponDamage = 0.40,
            WeaponDamageOH = 0.40,
            WeaponSkill = 2.60,
            ArmorPenetration = 0.12,
            SpellPower = 0.00,
            HealingPower = 0.00,
            MP5 = 0.58,
            ArcaneSpellPower = 0.00,
        },
        [3] = { -- Survival (Dual-Wield Melee)
            Strength = 0.52,
            Agility = 1.00,
            Stamina = 0.22,
            Intellect = 0.35,
            Spirit = 0.05,
            Armor = 0.01,
            AttackPower = 0.48,
            RangedAttackPower = 0.25,
            Hit = 13.90,
            Crit = 13.85,
            Haste = 10.60,
            RangedDPS = 0.50,
            WeaponDamage = 8.50,
            WeaponDamageOH = 4.65,
            WeaponSkill = 2.50,
            AvoidanceReduction = 12.90,
            ArmorPenetration = 0.15,
            SpellPower = 0.00,
            HealingPower = 0.00,
            MP5 = 0.30,
            FireSpellPower = 0.00,
            NatureSpellPower = 0.00,
        },
    },
    ["ROGUE"] = {
        [1] = { -- Assassination
            Strength = 0.60,
            Agility = 1.00,
            Stamina = 0.15,
            Spirit = 0.00,
            Armor = 0.01,
            AttackPower = 0.54,
            Hit = 14.20,
            Crit = 13.90,
            Haste = 12.20,
            WeaponDamage = 9.10,
            WeaponDamageOH = 5.40,
            WeaponSkill = 3.10,
            AvoidanceReduction = 13.40,
            ArmorPenetration = 0.15,
        },
        [2] = { -- Combat
            Strength = 0.60,
            Agility = 1.00,
            Stamina = 0.15,
            Spirit = 0.00,
            Armor = 0.01,
            AttackPower = 0.54,
            Hit = 14.40,
            Crit = 12.40,
            Haste = 12.80,
            WeaponDamage = 9.40,
            WeaponDamageOH = 4.50,
            WeaponSkill = 3.40,
            AvoidanceReduction = 13.80,
            ArmorPenetration = 0.15,
        },
        [3] = { -- Subtlety
            Strength = 0.58,
            Agility = 1.00,
            Stamina = 0.18,
            Spirit = 0.00,
            Armor = 0.01,
            AttackPower = 0.54,
            Hit = 13.80,
            Crit = 12.90,
            Haste = 11.50,
            WeaponDamage = 8.60,
            WeaponDamageOH = 3.80,
            WeaponSkill = 2.90,
            AvoidanceReduction = 13.10,
            ArmorPenetration = 0.15,
        },
    },
    ["PRIEST"] = {
        [1] = { -- Discipline
            Stamina = 0.22,
            Intellect = 0.85,
            Spirit = 0.50,
            Armor = 0.01,
            Crit = 10.50,
            Haste = 12.50,
            SpellPower = 0.00,
            HealingPower = 1.00,
            MP5 = 1.20,
            ShadowSpellPower = 0.00,
            HolySpellPower = 0.00,
        },
        [2] = { -- Holy
            Stamina = 0.20,
            Intellect = 0.85,
            Spirit = 0.65,
            Armor = 0.01,
            Crit = 11.20,
            Haste = 10.50,
            SpellPower = 0.00,
            HealingPower = 1.00,
            MP5 = 1.30,
            HolySpellPower = 0.00,
        },
        [3] = { -- Shadow
            Stamina = 0.20,
            Intellect = 0.32,
            Spirit = 0.26,
            Armor = 0.01,
            Hit = 14.90,
            Crit = 11.10,
            Haste = 12.80,
            SpellPower = 1.00,
            HealingPower = 0.33,
            SpellPenetration = 1.58,
            MP5 = 0.52,
            ShadowSpellPower = 0.98,
        },
    },
    ["SHAMAN"] = {
        [1] = { -- Elemental
            Stamina = 0.20,
            Intellect = 0.38,
            Spirit = 0.18,
            Armor = 0.01,
            Hit = 14.50,
            Crit = 13.60,
            Haste = 14.10,
            SpellPower = 1.00,
            HealingPower = 0.33,
            SpellPenetration = 1.64,
            MP5 = 0.58,
            FireSpellPower = 0.25,
            FrostSpellPower = 0.20,
            NatureSpellPower = 1.12,
        },
        [2] = { -- Enhancement (2H Melee; no Dual Wield in Forever)
            Strength = 1.00,
            Agility = 0.76,
            Stamina = 0.20,
            Intellect = 0.90,
            Spirit = 0.05,
            Armor = 0.01,
            AttackPower = 0.48,
            Hit = 14.70,
            Crit = 13.90,
            Haste = 11.80,
            WeaponDamage = 11.40,
            WeaponDamageOH = 0.00,
            WeaponSkill = 2.90,
            AvoidanceReduction = 13.60,
            ArmorPenetration = 0.14,
            SpellPower = 0.48,
            HealingPower = 0.16,
            SpellPenetration = 0.45,
            MP5 = 0.35,
            FireSpellPower = 0.35,
            FrostSpellPower = 0.25,
            NatureSpellPower = 0.52,
        },
        [3] = { -- Restoration
            Stamina = 0.20,
            Intellect = 0.82,
            Spirit = 0.32,
            Armor = 0.01,
            Crit = 11.00,
            Haste = 11.60,
            SpellPower = 0.00,
            HealingPower = 1.00,
            MP5 = 1.42,
        },
    },
    ["MAGE"] = {
        [1] = { -- Arcane
            Stamina = 0.18,
            Intellect = 0.60,
            Spirit = 0.28,
            Armor = 0.01,
            Hit = 14.20,
            Crit = 11.40,
            Haste = 13.60,
            SpellPower = 1.00,
            HealingPower = 0.33,
            SpellPenetration = 1.48,
            MP5 = 0.68,
            ArcaneSpellPower = 0.98,
            FireSpellPower = 0.02,
            FrostSpellPower = 0.02,
        },
        [2] = { -- Fire
            Stamina = 0.18,
            Intellect = 0.34,
            Spirit = 0.22,
            Armor = 0.01,
            Hit = 14.60,
            Crit = 14.50,
            Haste = 12.70,
            SpellPower = 1.00,
            HealingPower = 0.33,
            SpellPenetration = 1.52,
            MP5 = 0.48,
            ArcaneSpellPower = 0.02,
            FireSpellPower = 0.98,
            FrostSpellPower = 0.15,
        },
        [3] = { -- Frost
            Stamina = 0.18,
            Intellect = 0.30,
            Spirit = 0.20,
            Armor = 0.01,
            Hit = 14.10,
            Crit = 12.60,
            Haste = 13.40,
            SpellPower = 1.00,
            HealingPower = 0.33,
            SpellPenetration = 1.50,
            MP5 = 0.42,
            ArcaneSpellPower = 0.02,
            FireSpellPower = 0.02,
            FrostSpellPower = 0.98,
        },
    },
    ["WARLOCK"] = {
        [1] = { -- Affliction
            Stamina = 0.28,
            Intellect = 0.26,
            Spirit = 0.15,
            Armor = 0.01,
            Hit = 14.30,
            Crit = 12.40,
            Haste = 12.90,
            SpellPower = 1.00,
            HealingPower = 0.33,
            SpellPenetration = 1.54,
            MP5 = 0.25,
            FireSpellPower = 0.35,
            ShadowSpellPower = 1.05,
        },
        [2] = { -- Demonology
            Stamina = 0.38,
            Intellect = 0.30,
            Spirit = 0.15,
            Armor = 0.01,
            Hit = 13.60,
            Crit = 11.20,
            Haste = 11.50,
            SpellPower = 1.00,
            HealingPower = 0.33,
            SpellPenetration = 1.28,
            MP5 = 0.30,
            FireSpellPower = 0.85,
            ShadowSpellPower = 0.90,
        },
        [3] = { -- Destruction
            Stamina = 0.25,
            Intellect = 0.27,
            Spirit = 0.18,
            Armor = 0.01,
            Hit = 14.70,
            Crit = 12.85,
            Haste = 13.20,
            SpellPower = 1.00,
            HealingPower = 0.33,
            SpellPenetration = 1.55,
            MP5 = 0.24,
            FireSpellPower = 1.02,
            ShadowSpellPower = 0.75,
        },
    },
}
GSI_Config.Rules = {
    MergedHitCrit           = true,
    HealToDamageFactor      = 1 / 3, -- For non-healers: Healing Power counts as 1/3 Spell Damage
    HealerSpellDamageWeight = 0,     -- For healers: pure Spell Damage = 0
    WandSpellDamage         = false, -- Wands do not benefit from Spell Power / DPS
    SlotRules = {
        DruidFeralNoOffhand = true,  -- Cat/Bear: Shields and Off-Hand items = Score 0
        DruidFeralNoWpnDPS  = false, -- v2.2: Weapon DPS scales Cat and Bear
    }
}

GSI_Config.Caps = {
    MeleeHitCap           = 9.0,   -- Yellow hit cap vs. raid bosses (9% base miss)
    SpellHitCap           = 16.0,  -- Caster hit cap vs. raid bosses (16% base miss)
    AvoidanceReductionCap = 5.6,   -- v2.2: Boss dodge/parry avoidance reduction cap (5.6% flat)
    TankDefenseCap        = 440,   -- Crit immunity defense skill cap for tanks
}
