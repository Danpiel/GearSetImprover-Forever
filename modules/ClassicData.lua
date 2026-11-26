-- ============================================================
-- GearSetImprover - ClassicData.lua (WoW Forever)
-- Metadata for all 9 classes, 28 talent specializations, and equipment slots.
-- ============================================================

GSI_ClassicData = {}

-- Safe slot constants with numeric fallbacks
local INVSLOT_HEAD      = _G.INVSLOT_HEAD or 1
local INVSLOT_NECK      = _G.INVSLOT_NECK or 2
local INVSLOT_SHOULDER  = _G.INVSLOT_SHOULDER or 3
local INVSLOT_CHEST     = _G.INVSLOT_CHEST or 5
local INVSLOT_WAIST     = _G.INVSLOT_WAIST or 6
local INVSLOT_LEGS      = _G.INVSLOT_LEGS or 7
local INVSLOT_FEET      = _G.INVSLOT_FEET or 8
local INVSLOT_WRIST     = _G.INVSLOT_WRIST or 9
local INVSLOT_HAND      = _G.INVSLOT_HAND or 10
local INVSLOT_FINGER1   = _G.INVSLOT_FINGER1 or 11
local INVSLOT_FINGER2   = _G.INVSLOT_FINGER2 or 12
local INVSLOT_TRINKET1  = _G.INVSLOT_TRINKET1 or 13
local INVSLOT_TRINKET2  = _G.INVSLOT_TRINKET2 or 14
local INVSLOT_BACK      = _G.INVSLOT_BACK or 15
local INVSLOT_MAINHAND  = _G.INVSLOT_MAINHAND or 16
local INVSLOT_OFFHAND   = _G.INVSLOT_OFFHAND or 17
local INVSLOT_RANGED    = _G.INVSLOT_RANGED or 18

GSI_ClassicData.SLOT_IDS = {
    HEAD = INVSLOT_HEAD, NECK = INVSLOT_NECK, SHOULDER = INVSLOT_SHOULDER,
    BACK = INVSLOT_BACK, CHEST = INVSLOT_CHEST, WRIST = INVSLOT_WRIST,
    HAND = INVSLOT_HAND, WAIST = INVSLOT_WAIST, LEGS = INVSLOT_LEGS, FEET = INVSLOT_FEET,
    FINGER1 = INVSLOT_FINGER1, FINGER2 = INVSLOT_FINGER2,
    TRINKET1 = INVSLOT_TRINKET1, TRINKET2 = INVSLOT_TRINKET2,
    MAINHAND = INVSLOT_MAINHAND, OFFHAND = INVSLOT_OFFHAND, RANGED = INVSLOT_RANGED
}

-- Definition of all scorable equipment slots in WoW Forever (trinkets disabled)
GSI_ClassicData.EQUIP_SLOTS = {
    INVSLOT_HEAD, INVSLOT_NECK, INVSLOT_SHOULDER, INVSLOT_BACK, INVSLOT_CHEST,
    INVSLOT_WRIST, INVSLOT_HAND, INVSLOT_WAIST, INVSLOT_LEGS, INVSLOT_FEET,
    INVSLOT_FINGER1, INVSLOT_FINGER2,
    -- INVSLOT_TRINKET1, INVSLOT_TRINKET2,  -- Trinkets disabled
    INVSLOT_MAINHAND, INVSLOT_OFFHAND, INVSLOT_RANGED
}

-- Mapping of WoW EquipLoc strings to primary slot IDs
GSI_ClassicData.EquipLocToSlot = {
    INVTYPE_HEAD           = INVSLOT_HEAD,
    INVTYPE_NECK           = INVSLOT_NECK,
    INVTYPE_SHOULDER       = INVSLOT_SHOULDER,
    INVTYPE_CLOAK          = INVSLOT_BACK,
    INVTYPE_CHEST          = INVSLOT_CHEST,
    INVTYPE_ROBE           = INVSLOT_CHEST,
    INVTYPE_WRIST          = INVSLOT_WRIST,
    INVTYPE_HAND           = INVSLOT_HAND,
    INVTYPE_WAIST          = INVSLOT_WAIST,
    INVTYPE_LEGS           = INVSLOT_LEGS,
    INVTYPE_FEET           = INVSLOT_FEET,
    INVTYPE_FINGER         = INVSLOT_FINGER1,
    -- INVTYPE_TRINKET     = INVSLOT_TRINKET1,  -- Trinkets disabled
    INVTYPE_WEAPON         = INVSLOT_MAINHAND,
    INVTYPE_WEAPONMAINHAND = INVSLOT_MAINHAND,
    INVTYPE_2HWEAPON       = INVSLOT_MAINHAND,
    INVTYPE_WEAPONOFFHAND  = INVSLOT_OFFHAND,
    INVTYPE_SHIELD         = INVSLOT_OFFHAND,
    INVTYPE_HOLDABLE       = INVSLOT_OFFHAND,
    INVTYPE_RANGED         = INVSLOT_RANGED,
    INVTYPE_RANGEDRIGHT    = INVSLOT_RANGED,
    INVTYPE_THROWN         = INVSLOT_RANGED,
    INVTYPE_RELIC          = INVSLOT_RANGED,
}

-- Detailed slot list mapping for optimization (multi-slot types e.g. rings/one-hand weapons)
GSI_ClassicData.EquipLocToSlots = {
    INVTYPE_HEAD           = { INVSLOT_HEAD },
    INVTYPE_NECK           = { INVSLOT_NECK },
    INVTYPE_SHOULDER       = { INVSLOT_SHOULDER },
    INVTYPE_CLOAK          = { INVSLOT_BACK },
    INVTYPE_CHEST          = { INVSLOT_CHEST },
    INVTYPE_ROBE           = { INVSLOT_CHEST },
    INVTYPE_WRIST          = { INVSLOT_WRIST },
    INVTYPE_HAND           = { INVSLOT_HAND },
    INVTYPE_WAIST          = { INVSLOT_WAIST },
    INVTYPE_LEGS           = { INVSLOT_LEGS },
    INVTYPE_FEET           = { INVSLOT_FEET },
    INVTYPE_FINGER         = { INVSLOT_FINGER1, INVSLOT_FINGER2 },
    -- INVTYPE_TRINKET     = { INVSLOT_TRINKET1, INVSLOT_TRINKET2 },  -- Trinkets disabled
    INVTYPE_WEAPON         = { INVSLOT_MAINHAND, INVSLOT_OFFHAND },
    INVTYPE_WEAPONMAINHAND = { INVSLOT_MAINHAND },
    INVTYPE_2HWEAPON       = { INVSLOT_MAINHAND },
    INVTYPE_WEAPONOFFHAND  = { INVSLOT_OFFHAND },
    INVTYPE_SHIELD         = { INVSLOT_OFFHAND },
    INVTYPE_HOLDABLE       = { INVSLOT_OFFHAND },
    INVTYPE_RANGED         = { INVSLOT_RANGED },
    INVTYPE_RANGEDRIGHT    = { INVSLOT_RANGED },
    INVTYPE_THROWN         = { INVSLOT_RANGED },
    INVTYPE_RELIC          = { INVSLOT_RANGED },
}

-- Resolves player's English class key robustly across English & localized clients (e.g. German "Druidin" -> "DRUID")
function GSI_ClassicData:GetPlayerClass()
    local locClass, engClass = UnitClass("player")
    local class = engClass or locClass or "WARRIOR"
    if class then class = string.upper(class) end
    if class == "KRIEGER" then return "WARRIOR"
    elseif class == "PALADIN" then return "PALADIN"
    elseif class == "JÄGER" or class == "JAEGER" or class == "JAGER" then return "HUNTER"
    elseif class == "SCHURKE" or class == "SCHURKIN" then return "ROGUE"
    elseif class == "PRIESTER" or class == "PRIESTERIN" then return "PRIEST"
    elseif class == "SCHAMANE" or class == "SCHAMANIN" then return "SHAMAN"
    elseif class == "MAGIER" or class == "MAGIERIN" then return "MAGE"
    elseif class == "HEXENMEISTER" or class == "HEXENMEISTERIN" then return "WARLOCK"
    elseif class == "DRUIDE" or class == "DRUIDIN" then return "DRUID"
    end
    if self.Classes and self.Classes[class] then return class end
    return engClass or "WARRIOR"
end

-- Checks if the player's class, level, and trained skills allow Dual Wielding
function GSI_ClassicData:CanDualWield()
    local playerClass = self:GetPlayerClass()

    -- Classes that can NEVER dual wield in WoW Forever (Shaman, Paladin, Druid, Priest, Mage, Warlock)
    if playerClass ~= "WARRIOR" and playerClass ~= "ROGUE" and playerClass ~= "HUNTER" then
        return false
    end

    -- Rogue: Dual Wield is standard (level 10+ or passive)
    if playerClass == "ROGUE" then
        local lvl = UnitLevel("player") or 1
        if lvl >= 10 then return true end
        if IsSpellKnown and IsSpellKnown(674) then return true end
        if IsPlayerSpell and IsPlayerSpell(674) then return true end
        if C_SpellBook and C_SpellBook.IsSpellKnown and C_SpellBook.IsSpellKnown(674) then return true end
        return true
    end

    -- Warrior & Hunter: Requires Level 20 + trained skill (Spell 674)
    local playerLevel = UnitLevel("player") or 1
    if playerLevel > 0 and playerLevel < 20 then
        return false
    end

    if IsSpellKnown and IsSpellKnown(674) then return true end
    if IsPlayerSpell and IsPlayerSpell(674) then return true end
    if C_SpellBook and C_SpellBook.IsSpellKnown and C_SpellBook.IsSpellKnown(674) then return true end

    return playerLevel >= 20
end

-- Returns the valid equipment slots for a given equipLoc, respecting Dual Wield capabilities
function GSI_ClassicData:GetEquipSlots(equipLoc)
    if equipLoc == "INVTYPE_WEAPON" then
        if self:CanDualWield() then
            return { INVSLOT_MAINHAND, INVSLOT_OFFHAND }
        else
            return { INVSLOT_MAINHAND }
        end
    elseif equipLoc == "INVTYPE_WEAPONOFFHAND" then
        if self:CanDualWield() then
            return { INVSLOT_OFFHAND }
        else
            return {}
        end
    end
    return self.EquipLocToSlots and self.EquipLocToSlots[equipLoc] or {}
end


-- Slot display names (English)
GSI_ClassicData.SlotNames = {
    [INVSLOT_HEAD]     = "Head",
    [INVSLOT_NECK]     = "Neck",
    [INVSLOT_SHOULDER] = "Shoulders",
    [INVSLOT_BACK]     = "Back",
    [INVSLOT_CHEST]    = "Chest",
    [INVSLOT_WRIST]    = "Wrists",
    [INVSLOT_HAND]     = "Hands",
    [INVSLOT_WAIST]    = "Waist",
    [INVSLOT_LEGS]     = "Legs",
    [INVSLOT_FEET]     = "Feet",
    [INVSLOT_FINGER1]  = "Finger 1",
    [INVSLOT_FINGER2]  = "Finger 2",
    [INVSLOT_TRINKET1] = "Trinket 1",
    [INVSLOT_TRINKET2] = "Trinket 2",
    [INVSLOT_MAINHAND] = "Main Hand",
    [INVSLOT_OFFHAND]  = "Off Hand",
    [INVSLOT_RANGED]   = "Ranged / Relic",
}
GSI_ClassicData.SlotNamesDE = GSI_ClassicData.SlotNames

-- Metadata for all 9 classes and 28 talent specializations.
-- icon: the specialization's official game icon (GetSpecializationInfo); Rogue
-- Combat takes Outlaw's, Feral Bear and Cat take Guardian's and Feral's.
GSI_ClassicData.Classes = {
    ["WARRIOR"] = {
        name = "Warrior",
        nameDE = "Warrior",
        armor = 4,
        specs = {
            [1] = { name = "Arms", nameDE = "Arms", role = "dps", melee = true, icon = 132355 },
            [2] = { name = "Fury", nameDE = "Fury", role = "dps", melee = true, icon = 132347 },
            [3] = { name = "Protection", nameDE = "Protection", role = "tank", melee = true, icon = 132341 },
        }
    },
    ["PALADIN"] = {
        name = "Paladin",
        nameDE = "Paladin",
        armor = 4,
        specs = {
            [1] = { name = "Holy", nameDE = "Holy", role = "healer", icon = 135920 },
            [2] = { name = "Protection", nameDE = "Protection", role = "tank", melee = true, icon = 236264 },
            [3] = { name = "Retribution", nameDE = "Retribution", role = "dps", melee = true, icon = 135873 },
        }
    },
    ["HUNTER"] = {
        name = "Hunter",
        nameDE = "Hunter",
        armor = 3, -- Mail at level 40+, Leather before
        specs = {
            [1] = { name = "Beast Mastery", nameDE = "Beast Mastery", role = "dps", ranged = true, icon = 461112 },
            [2] = { name = "Marksmanship", nameDE = "Marksmanship", role = "dps", ranged = true, icon = 236179 },
            [3] = { name = "Survival", nameDE = "Survival", role = "dps", hybrid = true, icon = 461113 },
        }
    },
    ["ROGUE"] = {
        name = "Rogue",
        nameDE = "Rogue",
        armor = 2, -- Leather
        specs = {
            [1] = { name = "Assassination", nameDE = "Assassination", role = "dps", melee = true, icon = 236270 },
            [2] = { name = "Combat", nameDE = "Combat", role = "dps", melee = true, icon = 236286 },
            [3] = { name = "Subtlety", nameDE = "Subtlety", role = "dps", melee = true, icon = 132320 },
        }
    },
    ["PRIEST"] = {
        name = "Priest",
        nameDE = "Priest",
        armor = 1, -- Cloth
        specs = {
            [1] = { name = "Discipline", nameDE = "Discipline", role = "healer", icon = 135940 },
            [2] = { name = "Holy", nameDE = "Holy", role = "healer", icon = 237542 },
            [3] = { name = "Shadow", nameDE = "Shadow", role = "dps", caster = true, icon = 136207 },
        }
    },
    ["SHAMAN"] = {
        name = "Shaman",
        nameDE = "Shaman",
        armor = 3,
        specs = {
            [1] = { name = "Elemental", nameDE = "Elemental", role = "dps", caster = true, icon = 136048 },
            [2] = { name = "Enhancement", nameDE = "Enhancement", role = "dps", melee = true, icon = 237581 },
            [3] = { name = "Restoration", nameDE = "Restoration", role = "healer", icon = 136052 },
        }
    },
    ["MAGE"] = {
        name = "Mage",
        nameDE = "Mage",
        armor = 1,
        specs = {
            [1] = { name = "Arcane", nameDE = "Arcane", role = "dps", caster = true, icon = 135932 },
            [2] = { name = "Fire", nameDE = "Fire", role = "dps", caster = true, icon = 135810 },
            [3] = { name = "Frost", nameDE = "Frost", role = "dps", caster = true, icon = 135846 },
        }
    },
    ["WARLOCK"] = {
        name = "Warlock",
        nameDE = "Warlock",
        armor = 1,
        specs = {
            [1] = { name = "Affliction", nameDE = "Affliction", role = "dps", caster = true, icon = 136145 },
            [2] = { name = "Demonology", nameDE = "Demonology", role = "dps", caster = true, icon = 136172 },
            [3] = { name = "Destruction", nameDE = "Destruction", role = "dps", caster = true, icon = 136186 },
        }
    },
    ["DRUID"] = {
        name = "Druid",
        nameDE = "Druid",
        armor = 2,
        specs = {
            [1] = { name = "Balance", nameDE = "Balance", role = "dps", caster = true, icon = 136096 },
            [2] = { name = "Feral Bear", nameDE = "Feral Bear", role = "tank", melee = true, icon = 132276 },
            [3] = { name = "Feral Cat", nameDE = "Feral Cat", role = "dps", melee = true, icon = 132115 },
            [4] = { name = "Restoration", nameDE = "Restoration", role = "healer", icon = 136041 },
        }
    },
}

-- ============================================================
-- Canonical Class Usability Tables & Helpers (WoW Forever 1.60.1)
-- ============================================================
GSI_ClassicData._cachedPlayerClass = nil

function GSI_ClassicData:GetPlayerClass()
    if self._cachedPlayerClass then
        return self._cachedPlayerClass
    end
    if type(UnitClass) == "function" then
        local _, engClass = UnitClass("player")
        if type(engClass) == "string" and engClass ~= "" then
            local upper = string.upper(engClass)
            if self.Classes[upper] then
                self._cachedPlayerClass = upper
                return upper
            end
        end
    end
    return "WARRIOR"
end

GSI_ClassicData.ClassMaxArmor = {
    WARRIOR = 4, -- Plate
    PALADIN = 4, -- Plate
    HUNTER  = 3, -- Mail
    SHAMAN  = 3, -- Mail
    ROGUE   = 2, -- Leather
    DRUID   = 2, -- Leather
    PRIEST  = 1, -- Cloth
    MAGE    = 1, -- Cloth
    WARLOCK = 1, -- Cloth
}

GSI_ClassicData.ArmorSlots = {
    INVTYPE_HEAD     = true,
    INVTYPE_SHOULDER = true,
    INVTYPE_CHEST    = true,
    INVTYPE_ROBE     = true,
    INVTYPE_WAIST    = true,
    INVTYPE_LEGS     = true,
    INVTYPE_FEET     = true,
    INVTYPE_WRIST    = true,
    INVTYPE_HAND     = true,
}

GSI_ClassicData.ClassAllowedWeapons = {
    WARRIOR = { [0]=true, [1]=true, [2]=true, [3]=true, [4]=true, [5]=true, [6]=true, [7]=true, [8]=true, [10]=true, [13]=true, [15]=true, [16]=true, [18]=true },
    PALADIN = { [0]=true, [1]=true, [4]=true, [5]=true, [6]=true, [7]=true, [8]=true },
    HUNTER  = { [0]=true, [1]=true, [2]=true, [3]=true, [6]=true, [7]=true, [8]=true, [10]=true, [13]=true, [15]=true, [16]=true, [18]=true },
    ROGUE   = { [0]=true, [2]=true, [3]=true, [4]=true, [7]=true, [13]=true, [15]=true, [16]=true, [18]=true }, -- includes [0] 1H Axes
    PRIEST  = { [4]=true, [10]=true, [15]=true, [19]=true },
    SHAMAN  = { [0]=true, [1]=true, [4]=true, [5]=true, [10]=true, [13]=true, [15]=true },
    MAGE    = { [7]=true, [10]=true, [15]=true, [19]=true },
    WARLOCK = { [7]=true, [10]=true, [15]=true, [19]=true },
    DRUID   = { [4]=true, [5]=true, [6]=true, [10]=true, [13]=true, [15]=true },
}

local SHIELD_USERS = { WARRIOR = true, PALADIN = true, SHAMAN = true }
local RELIC_USERS  = { [7] = "PALADIN", [8] = "DRUID", [9] = "SHAMAN" }

function GSI_ClassicData:IsWeaponUsable(classKey, subClassID)
    local allowed = self.ClassAllowedWeapons[classKey]
    if not allowed then return true end
    return allowed[subClassID] == true
end

function GSI_ClassicData:IsArmorUsable(classKey, equipLoc, subClassID, strictArmorType)
    if equipLoc == "INVTYPE_CLOAK" then
        return true
    end
    if equipLoc == "INVTYPE_SHIELD" or subClassID == 6 then
        return SHIELD_USERS[classKey] == true
    end
    if equipLoc == "INVTYPE_RELIC" or RELIC_USERS[subClassID] then
        return RELIC_USERS[subClassID] == classKey
    end
    if equipLoc == "INVTYPE_HOLDABLE" or subClassID == 0 then
        return true
    end
    if not self.ArmorSlots[equipLoc] then
        return true
    end
    local maxArmor = self.ClassMaxArmor[classKey]
    if not maxArmor or not subClassID or subClassID < 1 or subClassID > 4 then
        return true
    end
    if strictArmorType then
        return subClassID == maxArmor
    end
    return subClassID <= maxArmor
end
