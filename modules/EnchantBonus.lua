-- ============================================================
-- GearSetImprover - EnchantBonus.lua (WoW Forever)
-- Evaluates permanent Classic / Forever weapon, armor, and ZG/Libram
-- enchantments by SpellItemEnchantment ID (ItemLink enchantID field).
-- Cross-checked against ForeverEnchant/Data/Recipes.lua and Classic DBC IDs.
-- ============================================================

GSI_EnchantBonus = {}

-- Known SpellItemEnchantment IDs -> stat contributions
GSI_EnchantBonus.KnownEnchants = {
    -- Weapons & Scopes
    [1900] = { Strength = 25 },                    -- Crusader (+100 Str proc, ~25% uptime)
    [2564] = { Agility = 15 },                     -- Weapon - Agility (+15 Agility)
    [2646] = { Agility = 25 },                     -- 2H Weapon - Agility (+25 Agility)
    [2563] = { Strength = 15 },                    -- Weapon - Strength (+15 Strength)
    [2504] = { SpellPower = 30 },                  -- Weapon - Spell Power (+30 Spell Damage & Healing)
    [2505] = { HealingPower = 55 },                -- Weapon - Healing Power (+55 Healing)
    [2567] = { Spirit = 20 },                      -- Weapon - Mighty Spirit (+20 Spirit)
    [2568] = { Intellect = 22 },                   -- Weapon - Mighty Intellect (+22 Intellect)
    [1896] = { WeaponDamage = 2.6 },                -- 2H Weapon - Superior Impact (+9 flat Damage -> ~2.6 DPS eq)
    [1897] = { WeaponDamage = 2.0 },                -- Weapon - Superior Striking (+5 flat Damage -> ~2.0 DPS eq)
    [963]  = { WeaponDamage = 2.0 },                -- 2H Weapon - Greater Impact (+7 flat Damage -> ~2.0 DPS eq)
    [943]  = { WeaponDamage = 1.6 },                -- Weapon - Greater Striking (+4 flat Damage -> ~1.6 DPS eq)
    [805]  = { WeaponDamage = 1.2 },                -- Weapon - Striking (+3 flat Damage -> ~1.2 DPS eq)
    [1903] = { Spirit = 9 },                       -- 2H Weapon - Greater Spirit (+9 Spirit)
    [1904] = { Intellect = 9 },                    -- 2H Weapon - Greater Intellect (+9 Intellect)
    [803]  = { AttackPower = 20 },                 -- Weapon - Fiery Weapon (Proc fire dmg, ~20 AP eq)
    [1898] = { AttackPower = 20, Stamina = 5 },    -- Weapon - Lifestealing (Proc life drain eq)
    [1899] = { AttackPower = 15 },                 -- Weapon - Unholy Weapon (Proc curse eq)
    [1894] = { AttackPower = 10 },                 -- Weapon - Icy Chill (Proc chill eq)
    [2523] = { Hit = 3 },                          -- Biznicks 247x128 Accurascope (+3% Hit)
    [663]  = { RangedDPS = 1.8 },                  -- Deadly Scope (+5 Ranged Damage -> ~1.8 Ranged DPS eq)
    [664]  = { RangedDPS = 2.5 },                  -- Sniper Scope (+7 Ranged Damage -> ~2.5 Ranged DPS eq)
    [34]   = { Haste = 3 },                        -- Iron Counterweight (+3% Attack Speed)

    -- Chest
    [1891] = { Strength = 4, Agility = 4, Stamina = 4, Intellect = 4, Spirit = 4 }, -- Chest - Greater Stats (+4 All Stats)
    [928]  = { Strength = 3, Agility = 3, Stamina = 3, Intellect = 3, Spirit = 3 }, -- Chest - Stats (+3 All Stats)
    [847]  = { Strength = 1, Agility = 1, Stamina = 1, Intellect = 1, Spirit = 1 }, -- Chest - Minor Stats (+1 All Stats)
    [1892] = { Stamina = 10 },                     -- Chest - Major Health (+100 Health -> 10 Stam eq)
    [908]  = { Stamina = 5 },                      -- Chest - Greater Health (+50 Health -> 5 Stam eq)
    [1893] = { Mana = 100, Intellect = 6.7 },      -- Chest - Major Mana (+100 Mana)

    -- Bracers
    [1883] = { Intellect = 7 },                    -- Bracer - Greater Intellect (+7 Intellect)
    [1884] = { Spirit = 9 },                       -- Bracer / Shield - Superior Spirit (+9 Spirit)
    [1885] = { Strength = 9 },                     -- Bracer - Superior Strength (+9 Strength)
    [1886] = { Stamina = 9 },                      -- Bracer - Superior Stamina (+9 Stamina)
    [2565] = { MP5 = 4 },                          -- Bracer - Mana Regeneration (+4 MP5)
    [2566] = { HealingPower = 24 },                -- Bracer - Healing Power (+24 Healing)
    [927]  = { Strength = 7 },                     -- Bracer / Gloves - Greater Strength (+7 Strength)
    [925]  = { Defense = 3 },                      -- Bracer - Deflection (+3 Defense)
    [923]  = { Defense = 5 },                      -- Bracer / Shield - Defense (+5 Defense)
    [856]  = { Strength = 5 },                     -- Bracer / Gloves - Strength (+5 Strength)
    [852]  = { Stamina = 5 },                      -- Bracer / Boots / Shield - Stamina (+5 Stamina)
    [905]  = { Intellect = 5 },                    -- Bracer - Intellect (+5 Intellect)
    [823]  = { Strength = 3 },                     -- Bracer - Lesser Strength (+3 Strength)
    [723]  = { Intellect = 3 },                    -- Bracer - Lesser Intellect (+3 Intellect)
    [724]  = { Stamina = 3 },                      -- Chest / Bracer / Shield - Lesser Stamina (+3 Stamina)

    -- Gloves
    [2618] = { Agility = 15 },                     -- Gloves - Superior Agility (+15 Agility)
    [2617] = { HealingPower = 30 },                -- Gloves - Healing Power (+30 Healing)
    [2614] = { ShadowSpellPower = 20 },            -- Gloves - Shadow Power (+20 Shadow Spell Damage)
    [2615] = { FrostSpellPower = 20 },             -- Gloves - Frost Power (+20 Frost Spell Damage)
    [2616] = { FireSpellPower = 20 },              -- Gloves - Fire Power (+20 Fire Spell Damage)
    [2501] = { ShadowSpellPower = 20 },            -- Legacy/Forever Alias: Gloves - Shadow Power (+20 Shadow)
    [2502] = { FrostSpellPower = 20 },             -- Legacy/Forever Alias: Gloves - Frost Power (+20 Frost)
    [2503] = { FireSpellPower = 20 },              -- Legacy/Forever Alias: Gloves - Fire Power (+20 Fire)
    [2613] = { Threat = 2 },                       -- Gloves - Threat (+2% Threat)
    [1887] = { Agility = 7 },                      -- Gloves / Boots - Greater Agility (+7 Agility)
    [931]  = { Haste = 1 },                        -- Gloves - Minor Haste (+1% Attack Speed)
    [930]  = { Speed = 2 },                        -- Gloves - Riding Skill (+2% Mount Speed)
    [904]  = { Agility = 5 },                      -- Gloves / Boots - Agility (+5 Agility)

    -- Boots & Shield
    [464]  = { Speed = 4 },                        -- Mithril Spurs (+4% Mount Speed)
    [911]  = { Speed = 8 },                        -- Boots - Minor Speed (+8% Run Speed)
    [929]  = { Stamina = 7 },                      -- Boots / Shield - Greater Stamina (+7 Stamina)
    [851]  = { Spirit = 5 },                       -- Boots - Spirit (+5 Spirit)
    [926]  = { FrostResist = 8 },                  -- Shield - Frost Resistance (+8 Frost Res)
    [1890] = { Spirit = 9 },                       -- Shield - Superior Spirit (+9 Spirit)
    [2653] = { Defense = 5 },                      -- Shield - Defense (+5 Defense)
    [2654] = { Intellect = 12 },                   -- Shield / Off-Hand - Intellect (+12 Intellect)
    [2655] = { BlockValue = 18 },                  -- Shield - Block Value (+18 Block Value)

    -- Cloak
    [2622] = { Dodge = 1 },                        -- Cloak - Dodge (+1% Dodge)
    [2621] = { Threat = -2 },                      -- Cloak - Subtlety (-2% Threat)
    [1888] = { FireResist = 5, NatureResist = 5, FrostResist = 5, ShadowResist = 5, ArcaneResist = 5 }, -- Cloak - Greater Resistance (+5 All Res)
    [2619] = { FireResist = 15 },                  -- Cloak - Greater Fire Resistance (+15 Fire Res)
    [2620] = { NatureResist = 15 },                -- Cloak - Greater Nature Resistance (+15 Nature Res)
    [1889] = { Armor = 70 },                       -- Cloak - Superior Defense (+70 Armor)
    [884]  = { Armor = 50 },                       -- Cloak - Greater Defense (+50 Armor)
    [849]  = { Agility = 3 },                      -- Cloak - Lesser Agility (+3 Agility)

    -- Head & Legs (Libram Arcanums & Zul'Gurub Idols)
    [2543] = { Haste = 1 },                        -- Arcanum of Rapidity (+1% Haste)
    [2544] = { SpellPower = 8 },                   -- Arcanum of Focus (+8 Spell Damage & Healing)
    [2545] = { Dodge = 1 },                        -- Arcanum of Protection (+1% Dodge)
    [1503] = { Stamina = 10 },                     -- Lesser Arcanum of Constitution (+100 HP -> 10 Stam eq)
    [1504] = { Armor = 125 },                      -- Lesser Arcanum of Tenacity (+125 Armor)
    [1505] = { FireResist = 20 },                  -- Lesser Arcanum of Resilience (+20 Fire Resistance)
    [1506] = { Strength = 8 },                     -- Lesser Arcanum of Voracity (+8 Strength)
    [1507] = { Stamina = 8 },                      -- Lesser Arcanum of Voracity (+8 Stamina)
    [1508] = { Agility = 8 },                      -- Lesser Arcanum of Voracity (+8 Agility)
    [1509] = { Intellect = 8 },                    -- Lesser Arcanum of Voracity (+8 Intellect)
    [1510] = { Spirit = 8 },                       -- Lesser Arcanum of Voracity (+8 Spirit)
    [2583] = { Stamina = 10, Defense = 7, BlockValue = 15 },               -- Presence of Might (Warrior)
    [2584] = { Stamina = 10, Defense = 7, HealingPower = 24 },             -- Syncretist's Sigil (Paladin)
    [2585] = { AttackPower = 28, Dodge = 1 },                              -- Death's Embrace (Rogue)
    [2586] = { RangedAttackPower = 24, Stamina = 10, Hit = 1 },            -- Falcon's Call (Hunter)
    [2587] = { Intellect = 15, SpellPower = 13 },                          -- Vodouisant's Vigilant Embrace (Shaman)
    [2588] = { SpellPower = 18, Hit = 1 },                                 -- Presence of Sight (Mage)
    [2589] = { SpellPower = 18, Stamina = 10 },                            -- Hoodoo Hex (Warlock)
    [2590] = { Stamina = 10, MP5 = 4, HealingPower = 24 },                 -- Prophetic Aura (Priest)
    [2591] = { Stamina = 10, Intellect = 10, HealingPower = 24 },          -- Animist's Caress (Druid)

    -- Shoulders (Zul'Gurub, Naxxramas Scourge & Argent Dawn)
    [2604] = { HealingPower = 33 },                -- Zandalar Signet of Serenity (+33 Healing)
    [2605] = { SpellPower = 18 },                  -- Zandalar Signet of Mojo (+18 Spell Power)
    [2606] = { AttackPower = 30 },                 -- Zandalar Signet of Might (+30 Attack Power)
    [2715] = { HealingPower = 31, MP5 = 5 },       -- Resilience of the Scourge (+31 Healing, +5 MP5)
    [2716] = { Stamina = 16, Armor = 100 },        -- Fortitude of the Scourge (+16 Stamina, +100 Armor)
    [2717] = { AttackPower = 26, Crit = 1 },       -- Might of the Scourge (+26 Attack Power, +1% Crit)
    [2721] = { SpellPower = 15, Crit = 1 },        -- Power of the Scourge (+15 Spell Power, +1% Spell Crit)
    [2483] = { FireResist = 5 },                   -- Flame Mantle of the Dawn (+5 Fire Resistance)
    [2484] = { FrostResist = 5 },                  -- Frost Mantle of the Dawn (+5 Frost Resistance)
    [2485] = { ArcaneResist = 5 },                 -- Arcane Mantle of the Dawn (+5 Arcane Resistance)
    [2488] = { FireResist = 5, NatureResist = 5, FrostResist = 5, ShadowResist = 5, ArcaneResist = 5 }, -- Chromatic Mantle of the Dawn (+5 All Res)
}

-- Universal "+Spell Power" enchants that grant both Spell Damage & Healing and route to HealingPower for healers
GSI_EnchantBonus.UniversalSPEnchants = {
    [2504] = true, -- Weapon - Spell Power (+30 Spell Damage & Healing)
    [2544] = true, -- Arcanum of Focus (+8 Spell Damage & Healing)
    [2587] = true, -- Vodouisant's Vigilant Embrace (+13 Spell Damage & Healing)
    [2588] = true, -- Presence of Sight (+18 Spell Damage & Healing)
    [2589] = true, -- Hoodoo Hex (+18 Spell Damage & Healing)
    [2605] = true, -- Zandalar Signet of Mojo (+18 Spell Damage & Healing)
    [2721] = true, -- Power of the Scourge (+15 Spell Damage & Healing)
}

-- Extracts the enchantID from an ItemLink (|Hitem:itemID:enchantID:...)
function GSI_EnchantBonus:GetEnchantIDFromLink(itemLink)
    if not itemLink then return nil end
    local enchantID = itemLink:match("|Hitem:%d+:(%d+):")
    return enchantID and tonumber(enchantID) or nil
end

-- Calculates the score contribution of the item's enchant for the given spec and mode
function GSI_EnchantBonus:GetEnchantScore(itemLink, overrideSpecIndex, overrideMode)
    local enchantID = self:GetEnchantIDFromLink(itemLink)
    if not enchantID or enchantID == 0 then return 0 end

    local enchantStats = self.KnownEnchants[enchantID]
    if not enchantStats then
        return 0
    end

    local weights = GSI_StatWeights and GSI_StatWeights:GetWeights(overrideSpecIndex, overrideMode) or {}
    local score = 0

    for stat, value in pairs(enchantStats) do
        -- Chest +100 Mana: only use Mana if Mana isn't already weighted alongside Intellect fallback
        if enchantID == 1893 and stat == "Intellect" and (weights.Mana or 0) > 0 then
            -- Skip Intellect proxy when Mana itself has an explicit weight (e.g. Arcane Mage)
        else
            local w = weights[stat]
            -- Universal "+Spell Power" enchants (2504, 2544, 2587, 2588, 2589, 2605, 2721) benefit healers via HealingPower
            if stat == "SpellPower" and self.UniversalSPEnchants[enchantID]
               and GSI_StatWeights and GSI_StatWeights.GetRole
               and GSI_StatWeights:GetRole(overrideSpecIndex, overrideMode) == "healer" then
                w = weights.HealingPower or 1.0
            end
            if w == nil then
                w = (GSI_Config and GSI_Config.TertiaryWeights and GSI_Config.TertiaryWeights[stat]) or 0
            end
            score = score + (value * w)
        end
    end

    return score
end
