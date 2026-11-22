-- ============================================================
-- GearSetImprover - Overrides.lua (WoW Forever)
-- Manually maintained numerical values for procs, on-use, and special effects.
-- Mirrors overrides.json at runtime for the WoW sandbox.
-- Formula: Value = Effect x Uptime (proc chance, duration, cooldown).
-- Items marked flatStat = true represent pure flat tooltip stats already
-- parsed by ItemScore and are excluded by default to prevent double-counting.
-- ============================================================

GSI_Overrides = {}

local GetItemInfoInstantFn = (C_Item and C_Item.GetItemInfoInstant) or _G.GetItemInfoInstant

-- Table mirroring overrides.json for runtime execution inside the WoW client
GSI_Overrides.Database = {
    [11815] = {
        name = "Hand of Justice",
        version = "0.9.0",
        meleeHitProc = true,
        reason = "Proc: 2% chance on hit for 1 extra attack (Effect x Uptime = ~22 AP eq)",
        profiles = { WARRIOR = 22.0, ROGUE = 26.0, PALADIN = 18.0, HUNTER = 8.0, DEFAULT = 20.0 }
    },
    [13965] = {
        name = "Blackhand's Breadth",
        version = "0.9.0",
        flatStat = true,
        reason = "+2% Critical Strike Chance (Flat Stat Conversion - parsed from tooltip)",
        profiles = { WARRIOR = 28.0, ROGUE = 28.0, HUNTER = 28.0, DEFAULT = 26.0 }
    },
    [11684] = {
        name = "Ironfoe",
        version = "0.9.0",
        meleeHitProc = true,
        reason = "Proc: Chance on hit to gain 2 extra attacks on next swing (~35 AP eq)",
        profiles = { WARRIOR = 38.0, ROGUE = 35.0, DEFAULT = 30.0 }
    },
    [17112] = {
        name = "Empyrean Demolisher",
        version = "0.9.0",
        meleeHitProc = true,
        reason = "Proc: +20% Melee Attack Speed for 10 sec (PPM 2.8 = ~32 AP eq)",
        profiles = { WARRIOR = 32.0, ROGUE = 34.0, DEFAULT = 28.0 }
    },
    [19019] = {
        name = "Thunderfury, Blessed Blade of the Windseeker",
        version = "0.9.0",
        meleeHitProc = true,
        reason = "Proc: 300 Nature Damage + 20% Attack Speed Slow + AoE Threat (High Tank/Threat Proc)",
        profiles = { WARRIOR = 85.0, ROGUE = 60.0, PALADIN = 75.0, DEFAULT = 70.0 }
    },
    [19289] = {
        name = "Darkmoon Card: Maelstrom",
        version = "0.9.0",
        meleeHitProc = true,
        reason = "Proc: 200-300 Nature Damage on melee hit (~24 AP eq)",
        profiles = { WARRIOR = 24.0, ROGUE = 26.0, PALADIN = 22.0, SHAMAN = 24.0, DEFAULT = 22.0 }
    },
    [19288] = {
        name = "Darkmoon Card: Blue Dragon",
        version = "0.9.0",
        casterOnly = true,
        reason = "Proc: 2% on spell cast for 100% mana regen while casting for 15s (~28 MP5 eq)",
        profiles = { PRIEST = 45.0, DRUID = 40.0, SHAMAN = 38.0, PALADIN = 35.0, MAGE = 30.0, DEFAULT = 30.0 }
    },
    [20130] = {
        name = "Diamond Flask",
        version = "0.9.0",
        physicalOnly = true,
        reason = "On-Use: +75 AP for 60s (360s CD = 12.5 AP avg) + 9 HP/5 sec",
        profiles = { WARRIOR = 22.0, DEFAULT = 15.0 }
    },
    [14551] = {
        name = "Edgemaster's Handguards",
        version = "0.9.0",
        flatStat = true,
        reason = "Equip: +7 Sword/Axe/Dagger Skill (Flat Stat Conversion - parsed from tooltip)",
        profiles = { WARRIOR = 65.0, ROGUE = 50.0, DEFAULT = 45.0 }
    },
    [13143] = {
        name = "Mark of the Chosen",
        version = "0.9.0",
        reason = "Proc: 2% chance when struck to gain +25 to all stats for 60s (Uptime ~60% in combat)",
        profiles = { WARRIOR = 35.0, DRUID = 38.0, PALADIN = 35.0, DEFAULT = 25.0 }
    },
    [19379] = {
        name = "Neltharion's Tear",
        version = "0.9.0",
        flatStat = true,
        reason = "Equip: +44 Spell Damage/Healing and +2% Spell Hit (Flat Stat Conversion - parsed from tooltip)",
        profiles = { MAGE = 74.0, WARLOCK = 76.0, PRIEST = 65.0, DEFAULT = 60.0 }
    },
    [19395] = {
        name = "Rejuvenating Gem",
        version = "0.9.0",
        flatStat = true,
        reason = "Equip: +9 MP5 and +66 Healing Spells (Flat Stat Conversion - parsed from tooltip)",
        profiles = { PRIEST = 72.0, DRUID = 68.0, SHAMAN = 68.0, PALADIN = 65.0, DEFAULT = 60.0 }
    },
    [13209] = {
        name = "Seal of the Dawn",
        version = "0.9.0",
        physicalOnly = true,
        reason = "Equip: +81 Attack Power against Undead",
        situational = true,
        context = "Undead",
        profiles = { WARRIOR = 65.0, ROGUE = 65.0, PALADIN = 65.0, HUNTER = 65.0, DEFAULT = 50.0 }
    },
    [19812] = {
        name = "Rune of the Dawn",
        version = "0.9.0",
        casterOnly = true,
        reason = "Equip: +48 Spell Damage/Healing against Undead",
        situational = true,
        context = "Undead",
        profiles = { MAGE = 48.0, WARLOCK = 48.0, PRIEST = 48.0, DEFAULT = 40.0 }
    },
    [12846] = {
        name = "Argent Dawn Commission",
        version = "0.9.0",
        reason = "Equip: Allows collecting Scourgestones from Undead",
        situational = true,
        context = "Undead",
        profiles = { DEFAULT = 0.0 }
    },
    [18205] = {
        name = "Dragon's Blood Necklace",
        version = "0.9.0",
        physicalOnly = true,
        reason = "Equip: Increases defense and attack power against Dragonkin",
        situational = true,
        context = "Dragonkin",
        profiles = { WARRIOR = 30.0, DEFAULT = 20.0 }
    },
    [12590] = {
        name = "Felstriker",
        version = "1.4.0",
        meleeHitProc = true,
        reason = "Proc: ~3-4% chance on hit for 100% Crit & Dodge/Parry bypass on next 3 attacks",
        profiles = { ROGUE = 42.0, WARRIOR = 36.0, HUNTER = 24.0, DEFAULT = 32.0 }
    },
    [17076] = {
        name = "Bonereaver's Edge",
        version = "1.4.0",
        meleeHitProc = true,
        reason = "Proc: ~11.8% chance on hit for +100 Armor Penetration (stacks 3x, 10s)",
        profiles = { WARRIOR = 55.0, PALADIN = 42.0, SHAMAN = 38.0, DEFAULT = 40.0 }
    },
    [12798] = {
        name = "Annihilator",
        version = "1.4.0",
        meleeHitProc = true,
        reason = "Proc: ~1 PPM reduces target Armor by 200 (stacks 3x = -600 Armor raid debuff)",
        situational = true,
        context = "Raid",
        profiles = { WARRIOR = 36.0, PALADIN = 28.0, SHAMAN = 26.0, DEFAULT = 24.0 }
    },
    [19169] = {
        name = "Nightfall",
        version = "1.4.0",
        meleeHitProc = true,
        reason = "Proc: ~2 PPM Spell Vulnerability (+15% Spell Damage taken by boss for 5s)",
        situational = true,
        context = "Raid",
        profiles = { PALADIN = 35.0, SHAMAN = 38.0, WARRIOR = 32.0, HUNTER = 28.0, DEFAULT = 30.0 }
    },
    [17068] = {
        name = "Deathbringer",
        version = "1.4.0",
        meleeHitProc = true,
        reason = "Proc: ~1 PPM Shadow Bolt for 110-140 Shadow Damage",
        profiles = { WARRIOR = 24.0, ROGUE = 22.0, SHAMAN = 24.0, DEFAULT = 20.0 }
    },
    [17075] = {
        name = "Vis'kag the Bloodletter",
        version = "1.4.0",
        meleeHitProc = true,
        reason = "Proc: ~1 PPM Fatal Wound for 240 Physical Damage",
        profiles = { WARRIOR = 28.0, ROGUE = 28.0, PALADIN = 22.0, DEFAULT = 24.0 }
    },
    [18816] = {
        name = "Perdition's Blade",
        version = "1.4.0",
        meleeHitProc = true,
        reason = "Proc: ~1.5 PPM Firebolt for 40-56 Fire Damage",
        profiles = { ROGUE = 20.0, WARRIOR = 16.0, DEFAULT = 16.0 }
    },
    [871] = {
        name = "Flurry Axe",
        version = "1.4.0",
        meleeHitProc = true,
        reason = "Proc: ~4% chance on hit to gain 1 extra attack",
        profiles = { WARRIOR = 26.0, ROGUE = 24.0, PALADIN = 28.0, SHAMAN = 24.0, DEFAULT = 22.0 }
    },
    [17705] = {
        name = "Thrash Blade",
        version = "1.4.0",
        meleeHitProc = true,
        reason = "Proc: ~2% chance on hit to gain 1 extra attack",
        profiles = { WARRIOR = 18.0, ROGUE = 18.0, PALADIN = 16.0, DEFAULT = 15.0 }
    },
    [13505] = {
        name = "Runeblade of Baron Rivendare",
        version = "1.4.0",
        reason = "Aura: Increases movement speed (+8%) and health regeneration",
        profiles = { WARRIOR = 18.0, PALADIN = 18.0, HUNTER = 12.0, DEFAULT = 15.0 }
    },
    [9449] = {
        name = "Manual Crowd Pummeler",
        version = "1.4.0",
        meleeHitProc = true,
        reason = "On-Use: +50% Attack Speed for 30s (3 charges; peak Feral Bear/Cat burst)",
        profiles = { DRUID = 65.0, WARRIOR = 35.0, PALADIN = 35.0, SHAMAN = 35.0, DEFAULT = 30.0 }
    },
    [12632] = {
        name = "Storm Gauntlets",
        version = "1.4.0",
        meleeHitProc = true,
        reason = "Proc: Adds 3 Lightning damage to melee attacks (scales with Nature SP & Crit)",
        profiles = { SHAMAN = 16.0, PALADIN = 18.0, HUNTER = 10.0, DEFAULT = 12.0 }
    },
    [14554] = {
        name = "Cloudkeeper Legplates",
        version = "1.4.0",
        physicalOnly = true,
        reason = "On-Use: +100 Attack Power for 30s (15m CD; boss burst value ~14 AP eq)",
        profiles = { WARRIOR = 14.0, PALADIN = 14.0, DEFAULT = 10.0 }
    }
}

-- Extracts itemID from either a number or an itemLink string
local function ExtractItemID(itemIdentifier)
    if not itemIdentifier then return nil end
    if type(itemIdentifier) == "number" then return itemIdentifier end
    if type(itemIdentifier) == "string" then
        local id = itemIdentifier:match("item:(%d+)") or itemIdentifier:match("^(%d+)$")
        return id and tonumber(id) or nil
    end
    return nil
end

-- Checks if a situational effect should be active in the current content mode
function GSI_Overrides:IsSituationalActive(context, currentMode)
    currentMode = currentMode or (GearSetImproverDB and GearSetImproverDB.contentMode) or "DUNGEON"
    local includeSituational = (GearSetImproverDB and GearSetImproverDB.includeSituational)

    -- If explicitly toggled off in settings
    if includeSituational == false then return false end
    -- If explicitly toggled on
    if includeSituational == true then return true end

    -- Mode logic: active in RAID or DUNGEON by default
    if currentMode == "RAID" or currentMode == "DUNGEON" then
        return true
    end
    return false
end

-- Retrieves the override score and metadata for an item.
-- Flat-stat overrides return 0 unless includeFlatStat == true so ItemScore
-- never double-counts stats already parsed directly from the item tooltip.
-- Returns: overrideScore, reason, version, isSituational, context, isFlatStat
function GSI_Overrides:GetOverride(itemIdentifier, classOrSpec, currentMode, includeFlatStat, specIndex)
    local itemID = ExtractItemID(itemIdentifier)
    if not itemID then return 0, nil, nil, false, nil, false end

    local entry = self.Database[itemID]
    if not entry then return 0, nil, nil, false, nil, false end

    local isSituational = entry.situational == true
    local isFlatStat = entry.flatStat == true
    local context = entry.context

    if isFlatStat and not includeFlatStat then
        return 0, entry.reason, entry.version, isSituational, context, true
    end

    local playerClass = classOrSpec or select(2, UnitClass("player")) or "WARRIOR"
    local activeSpec = specIndex or (GSI_StatWeights and GSI_StatWeights.GetActiveSpecIndex and GSI_StatWeights:GetActiveSpecIndex()) or 1

    local isCasterOrHealer = (playerClass == "MAGE" or playerClass == "WARLOCK" or playerClass == "PRIEST")
        or (playerClass == "PALADIN" and activeSpec == 1)
        or (playerClass == "SHAMAN" and (activeSpec == 1 or activeSpec == 3))
        or (playerClass == "DRUID" and (activeSpec == 1 or activeSpec == 4))
    local isRangedHunter = (playerClass == "HUNTER" and (activeSpec == 1 or activeSpec == 2))
    local isPurePhysical = (playerClass == "WARRIOR" or playerClass == "ROGUE" or playerClass == "HUNTER"
        or (playerClass == "DRUID" and (activeSpec == 2 or activeSpec == 3)))

    if entry.meleeHitProc and (isCasterOrHealer or isRangedHunter) then
        return 0, entry.reason, entry.version, isSituational, context, isFlatStat
    end
    if entry.physicalOnly and isCasterOrHealer then
        return 0, entry.reason, entry.version, isSituational, context, isFlatStat
    end
    if entry.casterOnly and isPurePhysical then
        return 0, entry.reason, entry.version, isSituational, context, isFlatStat
    end

    local isShieldTank = (playerClass == "WARRIOR" and activeSpec == 3) or (playerClass == "PALADIN" and activeSpec == 2)
    if isShieldTank and GetItemInfoInstantFn then
        local _, _, _, instEquipLoc = GetItemInfoInstantFn(itemID)
        if instEquipLoc == "INVTYPE_2HWEAPON" or instEquipLoc == "INVTYPE_WEAPONOFFHAND" or instEquipLoc == "INVTYPE_HOLDABLE" then
            return 0, entry.reason, entry.version, isSituational, context, isFlatStat
        end
    end

    local score = 0

    if entry.profiles then
        score = entry.profiles[playerClass] or entry.profiles.DEFAULT or 0
    end

    -- If it's a situational effect, check whether the current content mode includes it
    if isSituational then
        local active = self:IsSituationalActive(context, currentMode)
        if not active then
            -- Situational item displays badge only; numerical bonus is not counted
            return 0, entry.reason, entry.version, true, context, isFlatStat
        end
    end

    return score, entry.reason, entry.version, isSituational, context, isFlatStat
end

-- Fast query if an item has a situational tag
function GSI_Overrides:IsSituational(itemIdentifier)
    local itemID = ExtractItemID(itemIdentifier)
    if not itemID then return false, nil end
    local entry = self.Database[itemID]
    if entry and entry.situational then
        return true, entry.context
    end
    return false, nil
end

-- Fast query if an item's override consists solely of flat tooltip stats
function GSI_Overrides:IsFlatStat(itemIdentifier)
    local itemID = ExtractItemID(itemIdentifier)
    if not itemID then return false end
    local entry = self.Database[itemID]
    return (entry and entry.flatStat == true) or false
end
