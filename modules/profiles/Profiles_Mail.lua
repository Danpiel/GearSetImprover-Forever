-- ============================================================
-- GearSetImprover - Profiles_Mail.lua (Hunter, Shaman) (WoW Forever 1.60.1)
-- ============================================================

GSI_Config = GSI_Config or {}
GSI_Config.Profiles_v2_2 = GSI_Config.Profiles_v2_2 or {}

local P = GSI_Config.Profiles_v2_2
local function RegisterProfiles(tbl)
    for k, v in pairs(tbl) do
        P[k] = v
    end
end

RegisterProfiles({
    ["j_ger_tierherrschaft"] = {
        id = "j_ger_tierherrschaft",
        name = "Tierherrschaft",
        ref = "AGI",
        rolle = "Physical-Ranged-DPS",
        weights = {
            ["STR"] = 0.10,
            ["AGI"] = 1.00,
            ["RAP"] = 0.42,
            ["AP"] = 0.42,
            ["STA"] = 0.25,
            ["INT"] = 0.16,
            ["SPI"] = 0.05,
            ["ARMOR"] = 0.01,
            ["HIT"] = 13.80,
            ["CRIT"] = 11.20,
            ["HASTE"] = 11.60,
            ["ARP"] = 0.12,
            ["WEAPON_DPS_RANGED"] = 7.20,
            ["WEAPON_DPS_MH"] = 0.50,
            ["WEAPON_DPS_OH"] = 0.50,
            ["WEAPON_SKILL"] = 2.40,
            ["MP5"] = 0.48,
            ["SPELL_DMG"] = 0.00,
            ["ARCANE"] = 0.00,
            ["NATURE"] = 0.00,
            ["HEAL"] = 0.00,
            AP = 0.44,
            RAP = 0.44,
            HIT = 14.10,
            CRIT = 12.65,
            HASTE = 11.80,
            RANGED_DPS = 7.40,
        },
        confidence = {
            ["AGI"] = "A",
            ["RAP"] = "A",
            ["HIT"] = "A",
            ["CRIT"] = "B",
            ["WEAPON_DPS_RANGED"] = "A",
        },
        caps = {
            ["HIT"] = {
                ["stat"] = "HIT",
                ["cap_total_pct"] = 9.00,
                ["above_w"] = 0.00,
                tiers = {},
                ["note"] = "9 % Hit-Cap.",
            },
            ["WEAPON_SKILL"] = {
                ["stat"] = "WEAPON_SKILL",
                ["cap_total_pct"] = 305,
                ["above_w"] = 0.20,
                tiers = {},
                ["note"] = "Soft-Cap 305 für Distanz-Waffenfertigkeit.",
            },
        },
        notes = {
            "Summon Hawk (16P Milestone) und Hauptbegleiter skalieren stark mit RAP.",
            "Orc Command gewährt +5 % Begleiterschaden.",
            "Frenzy-Uptime skaliert mit Jäger- und Begleiter-Krit.",
        },
    },
    ["j_ger_ueberleben"] = {
        id = "j_ger_ueberleben",
        name = "Überleben",
        ref = "AGI",
        rolle = "Melee-DPS",
        weights = {
            ["AGI"] = 1.00,
            ["STR"] = 0.52,
            ["AP"] = 0.48,
            ["RAP"] = 0.25,
            ["INT"] = 0.35,
            ["SPI"] = 0.05,
            ["STA"] = 0.22,
            ["ARMOR"] = 0.01,
            ["HIT"] = 13.90,
            ["CRIT"] = 13.85,
            ["HASTE"] = 10.60,
            ["AVOID_RED"] = 12.90,
            ["ARP"] = 0.15,
            ["WEAPON_DPS_MH"] = 8.50,
            ["WEAPON_DPS_OH"] = 4.65,
            ["WEAPON_DPS_RANGED"] = 0.50,
            ["WEAPON_SKILL"] = 2.50,
            ["MP5"] = 0.30,
            ["SPELL_DMG"] = 0.00,
            ["FIRE"] = 0.00,
            ["NATURE"] = 0.00,
            ["HEAL"] = 0.00,
        },
        confidence = {
            ["AGI"] = "A",
            ["AP"] = "A",
            ["HIT"] = "A",
            ["CRIT"] = "A",
            ["WEAPON_DPS_MH"] = "A",
            ["WEAPON_DPS_OH"] = "A",
            ["AVOID_RED"] = "A",
        },
        caps = {
            ["HIT"] = {
                ["stat"] = "HIT",
                ["cap_total_pct"] = 27.00,
                ["above_w"] = 0.00,
                tiers = {
                    { from_pct = 0, to_pct = 9, w = 13.90, note = "Gelbes Nahkampf-Hit-Cap für Mongoose Bite und Raptor Strike" },
                    { from_pct = 9, to_pct = 27, w = 4.50, note = "Skaliert White-Hits der Beidhändigkeit" },
                },
                ["note"] = "Dual-Wield Melee: 9 % Gelb-Cap, 27 % White-Cap.",
            },
            ["AVOID_RED"] = {
                ["stat"] = "AVOID_RED",
                ["cap_total_pct"] = 5.60,
                ["above_w"] = 0.00,
                tiers = {},
                ["note"] = "Boss-Ausweich-Reduktion 5.6 %.",
            },
            ["WEAPON_SKILL"] = {
                ["stat"] = "WEAPON_SKILL",
                ["cap_total_pct"] = 308,
                ["above_w"] = 0.40,
                tiers = {},
                ["note"] = "Soft-Cap 308 für Glancing-Reduktion.",
            },
        },
        notes = {
            "In WoW Forever ist Survival ein DUAL-WIELD MELEE-SPEK!",
            "Predator's Edge erhöht den kritischen Schaden von Nahkampffähigkeiten um bis zu 30 % und den Offhand-Waffenschaden um bis zu 50 %.",
            "Lacerating Strikes, Mongoose Bite (via Expose Prey), Raptor Strike und Strider Kick bilden die Kernrotation.",
            "Beide Waffen-DPS-Werte (MH & OH) und Careful Aim (INT -> AP) sind von hoher Bedeutung.",
        },
    },
})
