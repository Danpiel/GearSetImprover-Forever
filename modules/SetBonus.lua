-- ============================================================
-- GearSetImprover – SetBonus.lua (WoW Forever)
-- Evaluates set bonuses, dynamic piece thresholds (2, 3, 4, 5, 6, 8),
-- incremental threshold scoring, and variable crafted tier-set limits.
-- ============================================================

GSI_SetBonus = {}
GSI_SetBonus._equippedSets = {}
GSI_SetBonus._equippedSetLinks = {}
GSI_SetBonus._equippedSetsDirty = true

local GetItemInfo = (C_Item and C_Item.GetItemInfo) or _G.GetItemInfo or function() return nil end
local GetItemInfoInstant = (C_Item and C_Item.GetItemInfoInstant) or _G.GetItemInfoInstant or function() return nil end

local EQUIP_SLOTS = {
    INVSLOT_HEAD or 1, INVSLOT_NECK or 2, INVSLOT_SHOULDER or 3, INVSLOT_BACK or 15, INVSLOT_CHEST or 5,
    INVSLOT_WRIST or 9, INVSLOT_HAND or 10, INVSLOT_WAIST or 6, INVSLOT_LEGS or 7, INVSLOT_FEET or 8,
    INVSLOT_FINGER1 or 11, INVSLOT_FINGER2 or 12,
    INVSLOT_MAINHAND or 16, INVSLOT_OFFHAND or 17, INVSLOT_RANGED or 18
}

local _setScanTooltip = nil
local function EnsureSetScanTooltip()
    if not _setScanTooltip then
        _setScanTooltip = CreateFrame("GameTooltip", "GSI_SetScanTooltip", nil, "GameTooltipTemplate")
        _setScanTooltip:SetOwner(WorldFrame or UIParent, "ANCHOR_NONE")
    end
    return _setScanTooltip
end

-- ============================================================
-- SET DEFINITIONS & THRESHOLDS TABLE
-- Known WoW Forever v2 Dungeon, Raid, and Crafted Sets
-- ============================================================
GSI_SetBonus.Sets = {
    -- --------------------------------------------------------
    -- DUNGEON SETS (T0 / T0.5) - Thresholds: 2, 3, 4, 5, 6, 8 pieces
    -- --------------------------------------------------------
    ["Battlegear of Valor"] = {
        type = "dungeon",
        thresholds = {
            [2] = { Armor = 200 },
            [3] = { AttackPower = 20 },
            [4] = { Strength = 10, Stamina = 10 },
            [5] = { Hit = 1.0 },
            [6] = { AttackPower = 40 },
            [8] = { Crit = 1.0, AttackPower = 20 }
        }
    },
    ["Rüstung des Schlachtfelds"] = { alias = "Battlegear of Valor" },
    ["Bold Armor"] = { alias = "Battlegear of Valor" },

    ["Shadowcraft Armor"] = {
        type = "dungeon",
        thresholds = {
            [2] = { Armor = 200 },
            [3] = { AttackPower = 20 },
            [4] = { Agility = 10, Stamina = 10 },
            [5] = { Hit = 1.0 },
            [6] = { AttackPower = 40 },
            [8] = { Crit = 1.0, AttackPower = 20 }
        }
    },
    ["Schattenschleicher"] = { alias = "Shadowcraft Armor" },

    ["Magister's Regalia"] = {
        type = "dungeon",
        thresholds = {
            [2] = { Armor = 200 },
            [3] = { SpellPower = 15 },
            [4] = { Intellect = 10, Stamina = 10 },
            [5] = { Hit = 1.0 },
            [6] = { SpellPower = 25 },
            [8] = { Crit = 1.0, SpellPower = 15 }
        }
    },
    ["Ornat des Magisters"] = { alias = "Magister's Regalia" },

    ["Wildheart Raiment"] = {
        type = "dungeon",
        thresholds = {
            [2] = { Armor = 200 },
            [3] = { AttackPower = 20, SpellPower = 15, HealingPower = 20 },
            [4] = { Strength = 8, Agility = 8, Intellect = 8, Stamina = 8 },
            [5] = { Hit = 1.0 },
            [6] = { AttackPower = 30, SpellPower = 25 },
            [8] = { Crit = 1.0, AttackPower = 20 }
        }
    },
    ["Gewänder des Wildherzens"] = { alias = "Wildheart Raiment" },

    ["The Elements"] = {
        type = "dungeon",
        thresholds = {
            [2] = { Armor = 200 },
            [3] = { SpellPower = 15, AttackPower = 20 },
            [4] = { Intellect = 10, Stamina = 10 },
            [5] = { Hit = 1.0 },
            [6] = { SpellPower = 25, AttackPower = 30 },
            [8] = { Crit = 1.0, SpellPower = 15 }
        }
    },
    ["Die Elemente"] = { alias = "The Elements" },

    ["Beaststalker Armor"] = {
        type = "dungeon",
        thresholds = {
            [2] = { Armor = 200 },
            [3] = { RangedAttackPower = 20, AttackPower = 20 },
            [4] = { Agility = 10, Stamina = 10 },
            [5] = { Hit = 1.0 },
            [6] = { RangedAttackPower = 40, AttackPower = 40 },
            [8] = { Crit = 1.0, AttackPower = 20 }
        }
    },
    ["Rüstung des Bestienjägers"] = { alias = "Beaststalker Armor" },

    ["Devout Garb"] = {
        type = "dungeon",
        thresholds = {
            [2] = { Armor = 200 },
            [3] = { HealingPower = 25, SpellPower = 15 },
            [4] = { Intellect = 10, Spirit = 10 },
            [5] = { Hit = 1.0 },
            [6] = { HealingPower = 40, SpellPower = 25 },
            [8] = { MP5 = 6, HealingPower = 20 }
        }
    },
    ["Vestments of the Devout"] = { alias = "Devout Garb" },
    ["Gewänder des Tugendhaften"] = { alias = "Devout Garb" },

    ["Lightforge Armor"] = {
        type = "dungeon",
        thresholds = {
            [2] = { Armor = 200 },
            [3] = { AttackPower = 20, HealingPower = 20 },
            [4] = { Strength = 10, Stamina = 10 },
            [5] = { Hit = 1.0 },
            [6] = { AttackPower = 30, HealingPower = 30 },
            [8] = { Crit = 1.0, Defense = 10 }
        }
    },
    ["Esse des Lichts"] = { alias = "Lightforge Armor" },

    ["Dreadmist Raiment"] = {
        type = "dungeon",
        thresholds = {
            [2] = { Armor = 200 },
            [3] = { SpellPower = 15 },
            [4] = { Intellect = 10, Stamina = 10 },
            [5] = { Hit = 1.0 },
            [6] = { SpellPower = 25 },
            [8] = { Crit = 1.0, SpellPower = 15 }
        }
    },
    ["Gewänder des Schreckenszwirns"] = { alias = "Dreadmist Raiment" },

    -- --------------------------------------------------------
    -- CRAFTED TIER SETS - Restricted initially to max 1 piece
    -- --------------------------------------------------------
    ["Devilsaur Armor"] = {
        type = "crafted",
        maxEquipped = 1,
        thresholds = {
            [2] = { Hit = 2.0, AttackPower = 28 }
        }
    },
    ["Teufelssaurierrüstung"] = { alias = "Devilsaur Armor" },

    ["Bloodvine Garb"] = {
        type = "crafted",
        maxEquipped = 1,
        thresholds = {
            [3] = { Hit = 2.0, SpellPower = 20 }
        }
    },
    ["Blutrebengewand"] = { alias = "Bloodvine Garb" },

    ["Ironfeather Armor"] = {
        type = "crafted",
        maxEquipped = 1,
        thresholds = {
            [2] = { SpellPower = 20 }
        }
    },
    ["Eisenfederrüstung"] = { alias = "Ironfeather Armor" },

    ["Stormshroud Armor"] = {
        type = "crafted",
        maxEquipped = 1,
        thresholds = {
            [2] = { AttackPower = 20 },
            [3] = { AttackPower = 15 }, -- Nerfed Nov 2026: 3% chance on melee hit for 18 Energy (was 4%/30 Energy)
            [4] = { AttackPower = 30 }
        }
    },
    ["Sturmschleier"] = { alias = "Stormshroud Armor" },

    ["Volcanic Armor"] = {
        type = "crafted",
        maxEquipped = 1,
        thresholds = {
            [3] = { FireResist = 30 }
        }
    },
    ["Vulkanische Rüstung"] = { alias = "Volcanic Armor" },

    ["Black Dragonscale"] = {
        type = "crafted",
        maxEquipped = 1,
        thresholds = {
            [2] = { Hit = 1.0 },
            [3] = { Crit = 2.0 },
            [4] = { FireResist = 10 }
        }
    },
    ["Schwarzer Drachenschuppenpanzer"] = { alias = "Black Dragonscale" },

    -- --------------------------------------------------------
    -- DUNGEON SETS 2 (T0.5) - Thresholds: 2, 4, 6, 8 pieces
    -- --------------------------------------------------------
    ["Battlegear of Heroism"] = {
        type = "dungeon",
        thresholds = {
            [2] = { FireResist = 8, NatureResist = 8, FrostResist = 8, ShadowResist = 8, ArcaneResist = 8 },
            [4] = { HP5 = 12 },
            [6] = { AttackPower = 40 },
            [8] = { Armor = 200 }
        }
    },
    ["Schlachtrüstung des Heldentums"] = { alias = "Battlegear of Heroism" },

    ["Soulforge Armor"] = {
        type = "dungeon",
        thresholds = {
            [2] = { FireResist = 8, NatureResist = 8, FrostResist = 8, ShadowResist = 8, ArcaneResist = 8 },
            [4] = { SpellPower = 18, HealingPower = 18 },
            [6] = { AttackPower = 40, SpellPower = 23 },
            [8] = { Armor = 200 }
        }
    },
    ["Rüstung der Seelenschmiede"] = { alias = "Soulforge Armor" },

    ["Beastmaster Armor"] = {
        type = "dungeon",
        thresholds = {
            [2] = { FireResist = 8, NatureResist = 8, FrostResist = 8, ShadowResist = 8, ArcaneResist = 8 },
            [4] = { MP5 = 12 },
            [6] = { RangedAttackPower = 40, AttackPower = 40 },
            [8] = { Armor = 200 }
        }
    },
    ["Rüstung des Tierherrn"] = { alias = "Beastmaster Armor" },
    ["Rüstung der Tierherrschaft"] = { alias = "Beastmaster Armor" },

    ["Darkmantle Armor"] = {
        type = "dungeon",
        thresholds = {
            [2] = { FireResist = 8, NatureResist = 8, FrostResist = 8, ShadowResist = 8, ArcaneResist = 8 },
            [4] = { AttackPower = 45, Haste = 1.5 },
            [6] = { AttackPower = 40 },
            [8] = { Armor = 200 }
        }
    },
    ["Rüstung der Finsternis"] = { alias = "Darkmantle Armor" },

    ["Vestments of the Virtuous"] = {
        type = "dungeon",
        thresholds = {
            [2] = { FireResist = 8, NatureResist = 8, FrostResist = 8, ShadowResist = 8, ArcaneResist = 8 },
            [4] = { Stamina = 10 },
            [6] = { HealingPower = 23, SpellPower = 23 },
            [8] = { Armor = 200 }
        }
    },
    ["Gewänder des Rechtschaffenen"] = { alias = "Vestments of the Virtuous" },

    ["The Five Thunders"] = {
        type = "dungeon",
        thresholds = {
            [2] = { FireResist = 8, NatureResist = 8, FrostResist = 8, ShadowResist = 8, ArcaneResist = 8 },
            [4] = { SpellPower = 24, HealingPower = 24 },
            [6] = { SpellPower = 23, HealingPower = 23 },
            [8] = { Armor = 200 }
        }
    },
    ["Die fünf Donner"] = { alias = "The Five Thunders" },

    ["Sorcerer's Regalia"] = {
        type = "dungeon",
        thresholds = {
            [2] = { FireResist = 8, NatureResist = 8, FrostResist = 8, ShadowResist = 8, ArcaneResist = 8 },
            [4] = { Armor = 50 },
            [6] = { SpellPower = 23 },
            [8] = { Armor = 200 }
        }
    },
    ["Ornat des Zauberers"] = { alias = "Sorcerer's Regalia" },
    ["Ornat der Zauberkünste"] = { alias = "Sorcerer's Regalia" },

    ["Deathmist Raiment"] = {
        type = "dungeon",
        thresholds = {
            [2] = { FireResist = 8, NatureResist = 8, FrostResist = 8, ShadowResist = 8, ArcaneResist = 8 },
            [4] = { Armor = 50 },
            [6] = { SpellPower = 23 },
            [8] = { Armor = 200 }
        }
    },
    ["Gewänder des Todesnebels"] = { alias = "Deathmist Raiment" },

    ["Feralheart Raiment"] = {
        type = "dungeon",
        thresholds = {
            [2] = { FireResist = 8, NatureResist = 8, FrostResist = 8, ShadowResist = 8, ArcaneResist = 8 },
            [4] = { MP5 = 10, AttackPower = 30 }, -- Fixed Nov 24, 2026: grants 4 Energy/s for 5s (20 Energy proc)
            [6] = { AttackPower = 26, SpellPower = 15, HealingPower = 15 },
            [8] = { Armor = 200 }
        }
    },
    ["Gewänder des ungezähmten Herzens"] = { alias = "Feralheart Raiment" },
    ["Ungezähmtes Herz"] = { alias = "Feralheart Raiment" },

    -- --------------------------------------------------------
    -- UBRS WEAPON SET & SCHOLOMANCE DUNGEON SETS
    -- --------------------------------------------------------
    ["Dal'Rend's Arms"] = {
        type = "dungeon",
        thresholds = {
            [2] = { AttackPower = 50 }
        }
    },
    ["Dal'Rends Waffen"] = { alias = "Dal'Rend's Arms" },

    ["Cadaverous Garb"] = {
        type = "dungeon",
        thresholds = {
            [2] = { Defense = 3 },
            [4] = { FireResist = 5, NatureResist = 5, FrostResist = 5, ShadowResist = 5, ArcaneResist = 5 },
            [5] = { Hit = 2.0 }
        }
    },
    ["Leichenhaftes Gewand"] = { alias = "Cadaverous Garb" },
    ["Leichenfledderergewand"] = { alias = "Cadaverous Garb" },

    ["Necropile Raiment"] = {
        type = "dungeon",
        thresholds = {
            [2] = { Stamina = 5 },
            [3] = { Intellect = 5 },
            [4] = { FireResist = 5, NatureResist = 5, FrostResist = 5, ShadowResist = 5, ArcaneResist = 5 },
            [5] = { SpellPower = 23, HealingPower = 23 }
        }
    },
    ["Roben des Totenbeschwörers"] = { alias = "Necropile Raiment" },
    ["Robe des Totenbeschwörers"] = { alias = "Necropile Raiment" },

    ["Bloodmail Regalia"] = {
        type = "dungeon",
        thresholds = {
            [2] = { Defense = 3 },
            [3] = { AttackPower = 10 },
            [4] = { FireResist = 15, NatureResist = 15, FrostResist = 15, ShadowResist = 15, ArcaneResist = 15 },
            [5] = { Parry = 1.0 }
        }
    },
    ["Blutkettenornat"] = { alias = "Bloodmail Regalia" },
    ["Blutpanzer-Set"] = { alias = "Bloodmail Regalia" },

    ["Deathbone Guardian"] = {
        type = "dungeon",
        thresholds = {
            [2] = { Defense = 3 },
            [3] = { Armor = 50 },
            [4] = { FireResist = 15, NatureResist = 15, FrostResist = 15, ShadowResist = 15, ArcaneResist = 15 },
            [5] = { Parry = 1.0 }
        }
    },
    ["Wächter der Totengebeine"] = { alias = "Deathbone Guardian" },
    ["Wächter der Todesknochen"] = { alias = "Deathbone Guardian" }
}

local _setNameCache = {}

-- ------------------------------------------------------------
-- Learned sets. The table above is keyed by English and German set names,
-- so on another client (ruRU) no set was ever found and no bonus counted.
-- Bonuses not yet active are shown with their piece count, from the client's
-- own ITEM_SET_BONUS_GRAY ("(%d) Set: %s"; ruRU "Комплект (%d |4предмет:
-- предмета:предметов;): %s"), so scanning a set item learns each such
-- threshold's stats; seen with few pieces on, that is the whole set. They
-- are kept per set name in GearSetImproverDB.learnedSets and used when the
-- table has no definition. Bonus texts go through the Russian line parser
-- (EN/DE sets are in the table already); procs are not learned.
-- ------------------------------------------------------------
GSI_SetBonus._learnedDefs = {}
GSI_SetBonus._learnedLinks = {}

local _grayBonusPattern = nil
local function GrayBonusPattern()
    if _grayBonusPattern ~= nil then return _grayBonusPattern or nil end
    local fmt = _G.ITEM_SET_BONUS_GRAY
    if type(fmt) ~= "string" or not fmt:find("%%d") or not fmt:find("%%s") then
        _grayBonusPattern = false
        return nil
    end
    local p = fmt:gsub("|4[^;]*;", "\001")            -- plural forms
    p = p:gsub("%%d", "\002"):gsub("%%s", "\003")
    p = p:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1")  -- escape the rest
    p = p:gsub("\001", ".-"):gsub("\002", "(%%d+)"):gsub("\003", "(.+)")
    _grayBonusPattern = "^%s*" .. p
    return _grayBonusPattern
end

function GSI_SetBonus:LearnSetBonuses(itemLink, setName)
    if not itemLink or not setName or self.Sets[setName] then return end
    if self._learnedLinks[itemLink] then return end
    self._learnedLinks[itemLink] = true
    local parse = GSI_ItemScore and GSI_ItemScore.ParseRussianLine
    local lower = GSI_ItemScore and GSI_ItemScore.LowerUTF8
    local pattern = GrayBonusPattern()
    if not (parse and lower and pattern and GearSetImproverDB) then return end

    local tip = EnsureSetScanTooltip()
    tip:ClearLines()
    local ok = pcall(function() tip:SetHyperlink(itemLink) end)
    if not ok then return end
    local learned = nil
    for i = 1, tip:NumLines() do
        local fs = _G["GSI_SetScanTooltipTextLeft" .. i]
        local text = fs and fs:GetText()
        if text then
            local k, bonus = text:match(pattern)
            k = tonumber(k)
            if k and bonus and bonus:find("[\208\209]") then
                local stats = {}
                local okP, found = pcall(parse, lower(bonus), stats, {})
                if okP and found and next(stats) then
                    learned = learned or {}
                    learned[k] = stats
                end
            end
        end
    end
    if learned then
        GearSetImproverDB.learnedSets = GearSetImproverDB.learnedSets or {}
        local t = GearSetImproverDB.learnedSets[setName] or {}
        for k, stats in pairs(learned) do t[k] = stats end
        GearSetImproverDB.learnedSets[setName] = t
        self._learnedDefs[setName] = nil
    end
end

-- Resolves alias names to their canonical set definition
function GSI_SetBonus:GetSetDefinition(setName)
    if not setName then return nil end
    local def = self.Sets[setName]
    if def and def.alias then
        return self.Sets[def.alias], def.alias
    end
    if not def then
        def = self._learnedDefs[setName]
        if not def then
            local learned = GearSetImproverDB and GearSetImproverDB.learnedSets and GearSetImproverDB.learnedSets[setName]
            if learned and next(learned) then
                def = { type = "learned", thresholds = learned }
                self._learnedDefs[setName] = def
            end
        end
    end
    return def, setName
end

-- Returns the maximum allowed equipped pieces for this set (e.g. 1 for crafted tier sets)
function GSI_SetBonus:GetMaxEquipped(setName)
    local def = self:GetSetDefinition(setName)
    if def and def.maxEquipped then
        return def.maxEquipped
    end
    return nil -- No artificial limit
end

-- Extracts the set name from an itemLink
function GSI_SetBonus:GetSetNameFromLink(itemLink)
    if not itemLink then return nil end
    if _setNameCache[itemLink] ~= nil then
        return _setNameCache[itemLink] or nil
    end

    local itemName, _, _, _, _, _, _, _, _, _, _, _, _, _, _, itemSetID = GetItemInfo(itemLink)

    -- 1. Native WoW ItemSetID
    if itemSetID and itemSetID > 0 then
        local setName = nil
        if C_Item and C_Item.GetItemSetInfo then
            local setInfo = C_Item.GetItemSetInfo(itemSetID)
            if setInfo and type(setInfo) == "table" and setInfo.name then setName = setInfo.name end
        elseif GetItemSetInfo then
            setName = GetItemSetInfo(itemSetID)
        end
        if setName and setName ~= "" then
            _setNameCache[itemLink] = setName
            self:LearnSetBonuses(itemLink, setName)
            return setName
        end
    end

    if not itemName then return nil end

    -- 2. Tooltip-Scan for WoW Forever / Custom Sets: matches "SetName (0/8)" or "SetName (1/5)"
    local tip = EnsureSetScanTooltip()
    tip:ClearLines()
    local ok = pcall(function() tip:SetHyperlink(itemLink) end)
    if ok and tip:NumLines() >= 2 then
        for i = 1, tip:NumLines() do
            local leftStr = _G["GSI_SetScanTooltipTextLeft" .. i]
            local text = leftStr and leftStr:GetText() or ""
            local plainText = text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
            if plainText ~= "" and plainText:match("%(%d+/%d+%)") then
                local setName = plainText:match("^(.-)%s*%(%d+/%d+%)") or plainText
                setName = setName:gsub("^%s+", ""):gsub("%s+$", "")
                if setName ~= "" then
                    _setNameCache[itemLink] = setName
                    self:LearnSetBonuses(itemLink, setName)
                    return setName
                end
            end
        end
    end

    _setNameCache[itemLink] = false
    return nil
end

-- Tracks equipment changes so _equippedSets stays fresh on demand
local setBonusEventFrame = CreateFrame and CreateFrame("Frame")
if setBonusEventFrame then
    setBonusEventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    pcall(function() setBonusEventFrame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED") end)
    pcall(function() setBonusEventFrame:RegisterEvent("UNIT_INVENTORY_CHANGED") end)
    setBonusEventFrame:SetScript("OnEvent", function(_, event, arg1)
        if event == "UNIT_INVENTORY_CHANGED" and arg1 and arg1 ~= "player" then
            return
        end
        GSI_SetBonus._equippedSetsDirty = true
    end)
end

-- Updates currently equipped set piece counts (normalized to canonical set names)
function GSI_SetBonus:UpdateEquippedSets()
    self._equippedSets = {}
    self._equippedSetLinks = {}
    for _, slot in ipairs(EQUIP_SLOTS) do
        local link = GetInventoryItemLink and GetInventoryItemLink("player", slot)
        if link then
            local rawSetName = self:GetSetNameFromLink(link)
            if rawSetName then
                local _, canonical = self:GetSetDefinition(rawSetName)
                local key = canonical or rawSetName
                self._equippedSets[key] = (self._equippedSets[key] or 0) + 1
                self._equippedSetLinks[slot] = {
                    link = link,
                    setName = key,
                    itemID = tonumber(link:match("item:(%d+)")),
                }
            end
        end
    end
    self._equippedSetsDirty = false
end

function GSI_SetBonus:EnsureEquippedSetsUpdated()
    if self._equippedSetsDirty then
        self:UpdateEquippedSets()
    end
end

-- Returns a list of individual active threshold stat tables given { [setName] = pieceCount }
-- Evaluating per-threshold preserves multi-tier SpellPower/HealingPower semantics
-- (e.g. Soulforge 4pc +18 SP/+18 Heal vs 6pc +23 SP; Devout 3pc/6pc vs 8pc +20 Heal).
function GSI_SetBonus:GetActiveSetBonusThresholds(setCounts)
    local activeThresholds = {}
    if not setCounts then
        self:EnsureEquippedSetsUpdated()
        setCounts = self._equippedSets
    end

    for setName, count in pairs(setCounts) do
        if count and count >= 2 then
            local def = self:GetSetDefinition(setName)
            local maxEq = def and def.maxEquipped
            local effectiveCount = count
            if maxEq and effectiveCount > maxEq then
                effectiveCount = maxEq
            end

            if def and def.thresholds then
                for threshold, stats in pairs(def.thresholds) do
                    if effectiveCount >= threshold then
                        table.insert(activeThresholds, stats)
                    end
                end
            end
        end
    end

    return activeThresholds
end

-- Scores a single set-bonus threshold stat table without SpellPower/HealingPower double-counting
function GSI_SetBonus:ScoreThresholdStats(thStats, weights, role)
    if not thStats then return 0 end
    weights = weights or (GSI_StatWeights and GSI_StatWeights:GetWeights()) or {}
    role = role or (GSI_StatWeights and GSI_StatWeights.GetRole and GSI_StatWeights:GetRole()) or "dps"

    local thSP = thStats.SpellPower or 0
    local thHeal = thStats.HealingPower or 0
    local healToDmgFactor = (GSI_Config and GSI_Config.Rules_v2_2 and GSI_Config.Rules_v2_2.heal_to_damage and GSI_Config.Rules_v2_2.heal_to_damage.factor)
        or (GSI_Config and GSI_Config.Rules and GSI_Config.Rules.HealToDamageFactor)
        or (1 / 3)
    local healerDmgWeight = (GSI_Config and GSI_Config.Rules_v2_2 and GSI_Config.Rules_v2_2.healer_spell_damage_weight)
        or (GSI_Config and GSI_Config.Rules and GSI_Config.Rules.HealerSpellDamageWeight)
        or 0

    local score = 0
    for stat, val in pairs(thStats) do
        if type(val) == "number" and val > 0 then
            local w = weights[stat] or 0
            if stat == "HealingPower" and role ~= "healer" then
                if thSP > 0 then
                    w = 0
                elseif weights.HealingPower == nil and (weights.SpellPower or 0) > 0 then
                    w = (weights.SpellPower or 0) * healToDmgFactor
                end
            elseif stat == "SpellPower" and role == "healer" then
                if thHeal == 0 then
                    w = weights.HealingPower or weights.HEAL or 1.0
                else
                    w = healerDmgWeight
                end
            end
            score = score + (val * w)
        end
    end
    return score
end

-- Returns the active bonus stats given a table of { [setName] = pieceCount }
-- Takes variable limits (maxEquipped) into account
function GSI_SetBonus:GetActiveSetBonusStats(setCounts)
    local totalStats = {}
    local activeThresholds = self:GetActiveSetBonusThresholds(setCounts)
    for _, stats in ipairs(activeThresholds) do
        for stat, val in pairs(stats) do
            totalStats[stat] = (totalStats[stat] or 0) + val
        end
    end

    return totalStats
end

-- Calculates the total GSI Score contribution of all active set bonuses in a setup (per-threshold)
function GSI_SetBonus:GetActiveSetBonusScore(setup, weights, role)
    weights = weights or (GSI_StatWeights and GSI_StatWeights:GetWeights()) or {}
    role = role or (GSI_StatWeights and GSI_StatWeights.GetRole and GSI_StatWeights:GetRole()) or "dps"
    local setCounts = {}

    if setup then
        for _, itemObj in pairs(setup) do
            local link = itemObj and itemObj.link
            if link then
                local rawSetName = self:GetSetNameFromLink(link)
                if rawSetName then
                    local _, canonical = self:GetSetDefinition(rawSetName)
                    local key = canonical or rawSetName
                    setCounts[key] = (setCounts[key] or 0) + 1
                end
            end
        end
    else
        self:EnsureEquippedSetsUpdated()
        setCounts = self._equippedSets
    end

    local activeThresholds = self:GetActiveSetBonusThresholds(setCounts)
    local score = 0
    for _, thStats in ipairs(activeThresholds) do
        score = score + self:ScoreThresholdStats(thStats, weights, role)
    end

    return math.floor(score * 100 + 0.5) / 100
end

-- Returns threshold progression info for an item:
-- count (excluding the inspected item itself), countWithItem, isItemEquipped, maxEquipped, nextThreshold, nextStats, nextScoreDelta
function GSI_SetBonus:GetThresholdProgression(itemLink, currentSetup, weights, role)
    local rawSetName = self:GetSetNameFromLink(itemLink)
    if not rawSetName then return nil end

    weights = weights or (GSI_StatWeights and GSI_StatWeights:GetWeights()) or {}
    role = role or (GSI_StatWeights and GSI_StatWeights.GetRole and GSI_StatWeights:GetRole()) or "dps"
    local def, canonicalName = self:GetSetDefinition(rawSetName)
    local setName = canonicalName or rawSetName
    local maxEq = def and def.maxEquipped

    local itemID = itemLink and tonumber(itemLink:match("item:(%d+)"))
    local totalCount = 0
    local isItemEquipped = false

    if currentSetup then
        for _, obj in pairs(currentSetup) do
            local objLink = obj and obj.link
            if objLink then
                local objRaw = self:GetSetNameFromLink(objLink)
                if objRaw then
                    local _, objCanon = self:GetSetDefinition(objRaw)
                    if (objCanon or objRaw) == setName then
                        totalCount = totalCount + 1
                        if objLink == itemLink or (itemID and tonumber(objLink:match("item:(%d+)")) == itemID) then
                            isItemEquipped = true
                        end
                    end
                end
            end
        end
    else
        self:EnsureEquippedSetsUpdated()
        totalCount = self._equippedSets[setName] or 0
        for _, eqInfo in pairs(self._equippedSetLinks or {}) do
            if eqInfo.setName == setName and (eqInfo.link == itemLink or (itemID and eqInfo.itemID == itemID)) then
                isItemEquipped = true
                break
            end
        end
    end

    local countWithoutItem = isItemEquipped and math.max(0, totalCount - 1) or totalCount
    local countWithItem = countWithoutItem + 1

    local nextThreshold = nil
    local nextStats = nil

    if def and def.thresholds then
        local sortedThresholds = {}
        for th in pairs(def.thresholds) do table.insert(sortedThresholds, th) end
        table.sort(sortedThresholds)

        for _, th in ipairs(sortedThresholds) do
            if th > countWithoutItem and (not maxEq or th <= maxEq) then
                nextThreshold = th
                nextStats = def.thresholds[th]
                break
            end
        end
    elseif countWithoutItem < 6 and (not maxEq or countWithoutItem < maxEq) then
        -- Generic fallback thresholds
        local fallbacks = { 2, 3, 4, 5, 6 }
        for _, th in ipairs(fallbacks) do
            if th > countWithoutItem and (not maxEq or th <= maxEq) then
                nextThreshold = th
                break
            end
        end
    end

    local nextScoreDelta = 0
    if nextStats then
        nextScoreDelta = self:ScoreThresholdStats(nextStats, weights, role)
    end

    return {
        setName = setName,
        count = countWithoutItem,
        countWithItem = countWithItem,
        isItemEquipped = isItemEquipped,
        maxEquipped = maxEq,
        nextThreshold = nextThreshold,
        nextStats = nextStats,
        nextScoreDelta = math.floor(nextScoreDelta * 10 + 0.5) / 10
    }
end

-- Single item set bonus evaluator (preview)
function GSI_SetBonus:GetSetBonusScore(itemLink, weights, role)
    if not itemLink then return 0 end
    local prog = self:GetThresholdProgression(itemLink, nil, weights, role)
    if not prog then return 0 end

    -- If this set has reached its maximum allowed piece limit (e.g. 1 for crafted tier sets)
    if prog.maxEquipped and prog.count >= prog.maxEquipped then
        return 0
    end

    -- If adding 1 piece reaches the next threshold, provide the threshold bonus
    if prog.nextThreshold and (prog.count + 1) == prog.nextThreshold then
        return prog.nextScoreDelta or 0
    end

    return 0
end
