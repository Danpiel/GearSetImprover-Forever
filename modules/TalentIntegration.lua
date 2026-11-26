-- ============================================================
-- GearSetImprover - TalentIntegration.lua (WoW Forever 1.60.1)
-- Reads invested talents via C_Traits / C_ClassTalents (primary)
-- with GetNumTalentTabs / GetTalentInfo fallback (tests/legacy).
-- Event-cached per configID so GetNodeInfo is never called in hot loops.
-- ============================================================

GSI_TalentIntegration = {}

local pcall = pcall
local pairs = pairs
local ipairs = ipairs
local type = type
local math_min = math.min
local math_max = math.max
local math_floor = math.floor

local function LowerUTF8(str)
    if type(str) ~= "string" then return "" end
    return str:lower():gsub("Ä", "ä"):gsub("Ö", "ö"):gsub("Ü", "ü")
end

local function ResolvePlayerClass()
    if GSI_ClassicData and GSI_ClassicData.GetPlayerClass then
        return GSI_ClassicData:GetPlayerClass()
    end
    if type(UnitClass) == "function" then
        local locClass, engClass = UnitClass("player")
        return engClass or locClass or "WARRIOR"
    end
    return "WARRIOR"
end

-- Verified WoW Forever 1.60.1 C_Traits root treeID per class
local CLASS_TREE_IDS = {
    WARRIOR = 1117,
    PALADIN = 1100,
    HUNTER  = 1091,
    ROGUE   = 1111,
    PRIEST  = 1114,
    SHAMAN  = 1082,
    MAGE    = 1112,
    WARLOCK = 1116,
    DRUID   = 1089,
}

-- Verified Forever 1.60.1 talent metadata (nodeID, spellID, EN/DE patterns, tab/tier/col)
local TALENT_DEFINITIONS = {
    -- Hit talents
    PRECISION_MAGE = {
        class = "MAGE", node = 105778, spell = 29438, max = 3,
        patterns = { "precision", "präzision" }, exact = true,
        tab = 3, tier = 1, col = 3,
    },
    PRECISION_PALADIN = {
        class = "PALADIN", node = 105638, spell = 20189, max = 3,
        patterns = { "precision", "präzision" }, exact = true,
        tab = 2, tier = 2, col = 1,
    },
    PRECISION_ROGUE = {
        class = "ROGUE", node = 105737, spell = 13705, max = 3,
        patterns = { "precision", "präzision" }, exact = true,
        tab = 2, tier = 2, col = 3,
    },
    HOLY_PRECISION = {
        class = "PRIEST", node = 110852, spell = 1309957, max = 3,
        patterns = { "holy precision", "heilige präzision" },
        tab = 1, tier = 2, col = 2,
    },
    DIVINE_PRECISION = {
        class = "PALADIN", node = 105324, spell = 1310904, max = 2,
        patterns = { "divine precision", "göttliche präzision" },
        tab = 1, tier = 4, col = 1,
    },
    SHADOW_FOCUS = {
        class = "PRIEST", node = 110851, spell = 15260, max = 5,
        patterns = { "shadow focus", "schattenfokus" },
        tab = 3, tier = 1, col = 1,
    },
    SUPPRESSION = {
        class = "WARLOCK", node = 105925, spell = 18174, max = 5,
        patterns = { "suppression", "unterdrückung" },
        tab = 1, tier = 1, col = 2,
    },
    SUREFOOTED = {
        class = "HUNTER", node = 104987, spell = 19290, max = 3,
        patterns = { "surefooted", "sicherer stand" },
        tab = 3, tier = 3, col = 2,
    },
    TIDAL_FOCUS = {
        class = "SHAMAN", node = 104729, spell = 16179, max = 5,
        patterns = { "tidal focus", "gezeitenfokus" },
        tab = 3, tier = 1, col = 3,
    },
    NATURES_REACH = {
        class = "DRUID", node = 104929, spell = 16819, max = 2,
        patterns = { "nature's reach", "reichweite der natur" },
        tab = 1, tier = 2, col = 4,
    },

    -- Scaling & specialty talents
    MENTAL_DEXTERITY = {
        class = "SHAMAN", node = 104755, spell = 415140, max = 3,
        patterns = { "mental dexterity", "geistige gewandtheit", "mentale gewandtheit" },
        tab = 2, tier = 2, col = 2,
    },
    MENTAL_QUICKNESS = {
        class = "SHAMAN", node = 104744, spell = 30812, max = 2,
        patterns = { "mental quickness", "geistige schnelligkeit", "mentale schnelligkeit" },
        tab = 2, tier = 5, col = 2,
    },
    CAREFUL_AIM = {
        class = "HUNTER", node = 105008, spell = 1223984, max = 5,
        patterns = { "careful aim", "sorgfältiges zielen" },
        tab = 2, tier = 2, col = 3,
    },
    REVERENCE = {
        class = "PALADIN", node = 110871, spell = 1310899, max = 2,
        patterns = { "reverence", "ehrfurcht" },
        tab = 1, tier = 2, col = 2,
    },
    CHAMPION_OF_THE_LIGHT = {
        class = "PALADIN", node = 110882, spell = 1311084, max = 5,
        patterns = { "champion of the light", "champion des lichts" },
        tab = 3, tier = 6, col = 3,
    },
    ARCANE_BLAST = {
        class = "MAGE", node = 105806, spell = 400574, max = 1,
        patterns = { "arcane blast", "arkanschlag" },
        tab = 1, tier = 3, col = 4,
    },
    ARCANE_WRATH = {
        class = "MAGE", node = 113627, spell = 1326079, max = 1,
        patterns = { "arcane wrath", "arkaner zorn" },
        tab = 1, tier = 4, col = 4,
    },
    MENTAL_STRENGTH = {
        class = "PRIEST", node = 105837, spell = 18551, max = 5,
        patterns = { "mental strength", "geistige stärke" },
        tab = 1, tier = 2, col = 3,
    },
    DARK_INSPIRATION = {
        class = "PRIEST", node = 105823, spell = 1326159, max = 5,
        patterns = { "dark inspiration", "dunkle inspiration" },
        tab = 3, tier = 4, col = 1,
    },
    NATURAL_INSTINCT = {
        class = "DRUID", node = 104950, spell = 1223242, max = 2,
        patterns = { "natural instinct", "natürlicher instinkt" },
        tab = 2, tier = 5, col = 4,
    },
    DREAMSTATE = {
        class = "DRUID", node = 104936, spell = nil, excludeSpell = 16896, max = 5,
        patterns = { "dreamstate", "traumzustand" },
        tab = 1, tier = 6, col = 2,
    },
    WEAPON_EXPERTISE = {
        class = "ROGUE", node = 105726, spell = 30919, max = 2,
        patterns = { "weapon expertise", "waffenexperte", "waffen-experte" },
        tab = 2, tier = 4, col = 3,
    },
}

local PATTERN_ALIASES = {}
for _, def in pairs(TALENT_DEFINITIONS) do
    for _, pat in ipairs(def.patterns) do
        PATTERN_ALIASES[LowerUTF8(pat)] = def
    end
end

-- General talent modifier rules for WoW Forever 1.60.1
GSI_TalentIntegration.TalentModifierRules = {
    -- Critical Strike
    { patterns = { "grausamkeit", "cruelty" },                       nodes = { 105939 }, spells = { 12320 }, stat = "Crit",         mod = 1.05 },
    { patterns = { "tödlichkeit", "lethality" },                     nodes = { 105716 }, spells = { 14128 }, stat = "Crit",         mod = 1.06 },
    { patterns = { "verheeren", "ruin" },                            nodes = { 105883 }, spells = { 17959 }, stat = "Crit",         mod = 1.06 },
    { patterns = { "verbrennung", "combustion" },                    nodes = { 105781 }, spells = { 11129 }, stat = "Crit",         mod = 1.06 },
    { patterns = { "pandemie", "pandemic" },                         nodes = { 105917 }, spells = { 427712 }, stat = "Crit",        mod = 1.08 },
    { patterns = { "durchbohren", "impale" },                        nodes = { 105947 }, spells = { 16493 }, stat = "Crit",         mod = 1.06 },
    { patterns = { "tödliche schüsse", "mortal shots" },             nodes = { 105002 }, spells = { 19485 }, stat = "Crit",         mod = 1.06 },
    { patterns = { "raubtierschärfe", "predator's edge" },           nodes = { 110861 }, spells = { 1310627 }, stat = "Crit",       mod = 1.06 },
    { patterns = { "eissplitter", "ice shards" },                    nodes = { 105777 }, spells = { 11207 }, stat = "Crit",         mod = 1.06 },
    { patterns = { "elementarfuror", "elemental fury" },             nodes = { 104766 }, spells = { 16089 }, stat = "Crit",         mod = 1.06 },
    { patterns = { "rache", "vengeance" },                           nodes = { 105693, 104932 }, spells = { 20049, 16909 }, stat = "Crit", mod = 1.06 },

    -- Hit (exact match prevents Holy Precision / Divine Precision leaking into general Hit)
    { patterns = { "präzision", "precision" },                       nodes = { 105778, 105638, 105737 }, spells = { 29438, 20189, 13705 }, stat = "Hit", mod = 1.08, exact = true },

    -- Haste / Attack Speed
    { patterns = { "schlaghagel", "flurry" },                        nodes = { 105928, 104747 }, spells = { 12319, 16256 }, stat = "Haste", mod = 1.08 },

    -- Primary Stats & Stamina / Intellect
    { patterns = { "herz der wildnis", "heart of the wild" },        nodes = { 104958 }, spells = { 17003 }, stat = "Intellect",    mod = 1.08 },
    { patterns = { "herz der wildnis", "heart of the wild" },        nodes = { 104958 }, spells = { 17003 }, stat = "Stamina",      mod = 1.06 },
    { patterns = { "dämonische umarmung", "demonic embrace" },       nodes = { 105907 }, spells = { 18697 }, stat = "Stamina",      mod = 1.08 },
    { patterns = { "überlebenskünstler", "survivalist" },            nodes = { 104992 }, spells = { 19255 }, stat = "Stamina",      mod = 1.06 },
    { patterns = { "arkaner geist", "arcane mind" },                 nodes = { 105800 }, spells = { 11232 }, stat = "Intellect",    mod = 1.08 },

    -- Defense & Protection
    { patterns = { "dickes fell", "thick hide" },                    nodes = { 104942 }, spells = { 16929 }, stat = "Defense",      mod = 1.08 },
    { patterns = { "natürliche reaktion", "natural reaction" },      nodes = { 104954 }, spells = { 417051 }, stat = "Dodge",       mod = 1.06 },
    { patterns = { "blutraserei", "blood frenzy" },                  nodes = { 104947 }, spells = { 16958 }, stat = "Crit",         mod = 1.05 },
    { patterns = { "antizipation", "anticipation" },                 nodes = { 105975, 105636, 104748 }, spells = { 12297, 20096, 16254 }, stat = "Defense", mod = 1.08 },
    { patterns = { "zähigkeit", "toughness" },                       nodes = { 105630, 104746 }, spells = { 20143, 16252 }, stat = "Armor", mod = 1.06 },
    { patterns = { "schild-spezialisierung", "schildspezialisierung", "shield specialization" }, nodes = { 105976, 110874 }, spells = { 12298, 20150 }, stat = "Block", mod = 1.08 },

    -- Spell Damage & Healing
    { patterns = { "schattenmacht", "shadow power" },                stat = "SpellPower",       mod = 1.06 },
    { patterns = { "schattenmacht", "shadow power" },                stat = "ShadowSpellPower", mod = 1.06 },
    { patterns = { "arkan-macht", "arkanmacht", "arcane power" },    nodes = { 105798 }, spells = { 12042 }, stat = "SpellPower",       mod = 1.08 },
    { patterns = { "arkan-macht", "arkanmacht", "arcane power" },    nodes = { 105798 }, spells = { 12042 }, stat = "ArcaneSpellPower", mod = 1.08 },
    { patterns = { "dunkelheit", "darkness" },                       nodes = { 105818 }, spells = { 15259 }, stat = "SpellPower",       mod = 1.05 },
    { patterns = { "dunkelheit", "darkness" },                       nodes = { 105818 }, spells = { 15259 }, stat = "ShadowSpellPower", mod = 1.05 },
    { patterns = { "feuermacht", "fire power" },                     nodes = { 105782 }, spells = { 11124 }, stat = "SpellPower",       mod = 1.06 },
    { patterns = { "feuermacht", "fire power" },                     nodes = { 105782 }, spells = { 11124 }, stat = "FireSpellPower",   mod = 1.06 },
    { patterns = { "schattenbeherrschung", "shadow mastery" },       nodes = { 105910 }, spells = { 18271 }, stat = "SpellPower",       mod = 1.10 },
    { patterns = { "schattenbeherrschung", "shadow mastery" },       nodes = { 105910 }, spells = { 18271 }, stat = "ShadowSpellPower", mod = 1.10 },
    { patterns = { "spirituelle heilung", "spiritual healing" },     nodes = { 105852 }, spells = { 14898 }, stat = "HealingPower", mod = 1.08 },
    { patterns = { "meditation" },                                   nodes = { 105843 }, spells = { 14521 }, stat = "Spirit",       mod = 1.08 },
    { patterns = { "dunkle inspiration", "dark inspiration" },       nodes = { 105823 }, spells = { 1326159 }, stat = "Spirit",     mod = 1.15 },
    { patterns = { "genesis" },                                      nodes = { 104924 }, spells = { 1223081 }, stat = "SpellPower", mod = 1.06 },
    { patterns = { "genesis" },                                      nodes = { 104924 }, spells = { 1223081 }, stat = "HealingPower", mod = 1.06 },

    -- Weapon & Physical
    { patterns = { "waffenschaden", "weapon damage", "zweihandwaffen-spezialisierung", "two-handed weapon specialization" }, nodes = { 105948, 105697 }, spells = { 12163, 20111 }, stat = "WeaponDamage", mod = 1.05 },
    { patterns = { "blitzartige reflexe", "lightning reflexes" },    nodes = { 110859, 113398 }, spells = { 19168, 13712 }, stat = "Dodge", mod = 1.06 },
}

-- Event-driven cache state
GSI_TalentIntegration._snapshots = {}
GSI_TalentIntegration._modsCache = {}
GSI_TalentIntegration._revision = 1

function GSI_TalentIntegration:GetRevision()
    return self._revision or 1
end

function GSI_TalentIntegration:Invalidate()
    self._snapshots = {}
    self._modsCache = {}
    self._revision = (self._revision or 1) + 1
end

local function MatchesAnyPattern(nameLower, patterns, exactOnly)
    if type(patterns) == "string" then
        patterns = { patterns }
    end
    for _, pat in ipairs(patterns) do
        local patLower = LowerUTF8(pat)
        if exactOnly then
            if nameLower == patLower then return true end
        else
            if nameLower:find(patLower, 1, true) then return true end
        end
    end
    return false
end

local function ConfigHoldsTree(cfg, treeID)
    if not cfg or cfg <= 0 or not C_Traits or not C_Traits.GetConfigInfo then return false end
    local ok, info = pcall(C_Traits.GetConfigInfo, cfg)
    if not ok or not info or not info.treeIDs then return false end
    for _, t in ipairs(info.treeIDs) do
        if t == treeID then return true end
    end
    return false
end

function GSI_TalentIntegration:ResolveConfigID(treeID, explicitConfigID)
    if explicitConfigID and ConfigHoldsTree(explicitConfigID, treeID) then
        return explicitConfigID
    end
    if C_ClassTalents and C_ClassTalents.GetActiveConfigID then
        local ok, cfg = pcall(C_ClassTalents.GetActiveConfigID)
        if ok and ConfigHoldsTree(cfg, treeID) then return cfg end
    end
    if C_Traits and C_Traits.GetConfigIDByTreeID then
        local ok, cfg = pcall(C_Traits.GetConfigIDByTreeID, treeID)
        if ok and ConfigHoldsTree(cfg, treeID) then return cfg end
    end
    if C_Traits and C_Traits.GetConfigIDBySystemID then
        for sys = 1, 40 do
            local ok, cfg = pcall(C_Traits.GetConfigIDBySystemID, sys)
            if ok and ConfigHoldsTree(cfg, treeID) then return cfg end
        end
    end
    return nil
end

function GSI_TalentIntegration:HasTraitsAPI()
    return C_Traits ~= nil and type(C_Traits.GetTreeNodes) == "function" and type(C_Traits.GetNodeInfo) == "function"
end

-- Builds and caches a full tree snapshot once per configID per Invalidate()
function GSI_TalentIntegration:GetSnapshot(explicitConfigID)
    if not self:HasTraitsAPI() then return nil end
    local cls = ResolvePlayerClass()
    local treeID = CLASS_TREE_IDS[cls]
    if not treeID then return nil end

    local cfg = self:ResolveConfigID(treeID, explicitConfigID)
    if not cfg then return nil end

    if self._snapshots[cfg] then
        return self._snapshots[cfg]
    end

    local okNodes, nodeIDs = pcall(C_Traits.GetTreeNodes, treeID)
    if not okNodes or type(nodeIDs) ~= "table" or #nodeIDs == 0 then
        return nil
    end

    local snap = {
        configID = cfg,
        treeID = treeID,
        class = cls,
        byNode = {},
        bySpell = {},
        entries = {},
        pointsByTab = { 0, 0, 0 },
    }

    local minX, maxX = nil, nil
    for _, nodeID in ipairs(nodeIDs) do
        local okN, n = pcall(C_Traits.GetNodeInfo, cfg, nodeID)
        if okN and n then
            local rank = n.activeRank or n.ranksPurchased or n.currentRank or 0
            local maxR = n.maxRanks or 0
            local entryID = (n.activeEntry and n.activeEntry.entryID) or (n.entryIDs and n.entryIDs[1])
            local spellID, spellName
            if entryID and C_Traits.GetEntryInfo and C_Traits.GetDefinitionInfo then
                local okE, e = pcall(C_Traits.GetEntryInfo, cfg, entryID)
                if okE and e and e.definitionID then
                    local okD, d = pcall(C_Traits.GetDefinitionInfo, e.definitionID)
                    if okD and d then
                        spellID = d.spellID or d.overriddenSpellID
                    end
                end
            end
            if spellID and C_Spell and C_Spell.GetSpellName then
                local okS, sName = pcall(C_Spell.GetSpellName, spellID)
                if okS and type(sName) == "string" then spellName = sName end
            elseif spellID and type(GetSpellInfo) == "function" then
                local okS, sName = pcall(GetSpellInfo, spellID)
                if okS and type(sName) == "string" then spellName = sName end
            end

            local rec = {
                node = nodeID,
                rank = rank,
                max = maxR,
                spell = spellID,
                name = spellName,
                nameLower = spellName and LowerUTF8(spellName) or "",
                posX = n.posX,
                posY = n.posY,
            }
            snap.byNode[nodeID] = rec
            if spellID then snap.bySpell[spellID] = rec end
            snap.entries[#snap.entries + 1] = rec

            if n.posX then
                if not minX or n.posX < minX then minX = n.posX end
                if not maxX or n.posX > maxX then maxX = n.posX end
            end
        end
    end

    if minX and maxX and maxX > minX then
        local span = (maxX - minX) / 3
        for _, rec in ipairs(snap.entries) do
            if rec.posX and rec.rank > 0 then
                local tabIdx = math_min(3, math_max(1, math_floor((rec.posX - minX) / span) + 1))
                snap.pointsByTab[tabIdx] = snap.pointsByTab[tabIdx] + rec.rank
            end
        end
    end

    self._snapshots[cfg] = snap
    return snap
end

function GSI_TalentIntegration:GetPointsByTab(explicitConfigID)
    local snap = self:GetSnapshot(explicitConfigID)
    if snap and snap.pointsByTab then
        return snap.pointsByTab
    end
    return nil
end

function GSI_TalentIntegration:GetTalentRankByDef(def, explicitConfigID)
    if not def then return nil end

    -- 1. Primary path: WoW Forever C_Traits snapshot
    local snap = self:GetSnapshot(explicitConfigID)
    if snap then
        if def.spell and snap.bySpell[def.spell] then
            return snap.bySpell[def.spell].rank
        end
        if def.node and snap.byNode[def.node] then
            local rec = snap.byNode[def.node]
            if not def.excludeSpell or rec.spell ~= def.excludeSpell then
                return rec.rank
            end
        end
        if def.patterns then
            for _, rec in ipairs(snap.entries) do
                if rec.nameLower ~= "" and MatchesAnyPattern(rec.nameLower, def.patterns, def.exact) then
                    return rec.rank
                end
            end
        end
        return 0
    end

    -- 2. Legacy fallback: GetNumTalentTabs / GetTalentInfo
    return self:GetTalentRank(def.patterns, def.tab, def.tier, def.col, def.exact)
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
        if numTabs <= 0 then return end

        for tab = 1, numTabs do
            local numTalents = GetNumTalents(tab) or 0
            for idx = 1, numTalents do
                local name, _, tier, column, currentRank = GetTalentInfo(tab, idx)
                if name and patterns and MatchesAnyPattern(LowerUTF8(name), patterns, exactOnly) then
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

local function ApplyModifierRule(mods, rule, rank, maxRank)
    if not rank or rank <= 0 then return end
    local denom = (maxRank and maxRank > 0) and maxRank or 5.0
    local ratio = math_min(1.0, rank / denom)
    if not mods[rule.stat] then
        mods[rule.stat] = 1.0
    end
    local rankScale = 1.0 + ((rule.mod - 1.0) * ratio)
    mods[rule.stat] = math_min(mods[rule.stat] * rankScale, 1.25)
end

-- Scans invested talents via C_Traits (primary) or legacy GetTalentInfo (fallback)
function GSI_TalentIntegration:GetStatModifiers(explicitConfigID)
    local cacheKey = explicitConfigID or "ACTIVE"
    if self._modsCache[cacheKey] then
        return self._modsCache[cacheKey]
    end

    local mods = {}
    local snap = self:GetSnapshot(explicitConfigID)

    if snap then
        for _, rule in ipairs(self.TalentModifierRules) do
            local matchedRec = nil
            if rule.spells then
                for _, sp in ipairs(rule.spells) do
                    if snap.bySpell[sp] then
                        matchedRec = snap.bySpell[sp]
                        break
                    end
                end
            end
            if not matchedRec and rule.nodes then
                for _, nid in ipairs(rule.nodes) do
                    if snap.byNode[nid] then
                        matchedRec = snap.byNode[nid]
                        break
                    end
                end
            end
            if not matchedRec and rule.patterns then
                for _, rec in ipairs(snap.entries) do
                    if rec.rank > 0 and rec.nameLower ~= "" and MatchesAnyPattern(rec.nameLower, rule.patterns, rule.exact) then
                        matchedRec = rec
                        break
                    end
                end
            end
            if matchedRec and matchedRec.rank > 0 then
                ApplyModifierRule(mods, rule, matchedRec.rank, matchedRec.max)
            end
        end
    elseif type(GetNumTalentTabs) == "function" and type(GetNumTalents) == "function" and type(GetTalentInfo) == "function" then
        pcall(function()
            local numTabs = GetNumTalentTabs() or 0
            for tab = 1, numTabs do
                local numTalents = GetNumTalents(tab) or 0
                for idx = 1, numTalents do
                    local name, _, _, _, currentRank, maxRank = GetTalentInfo(tab, idx)
                    if name and currentRank and currentRank > 0 then
                        local nameLower = LowerUTF8(name)
                        for _, rule in ipairs(self.TalentModifierRules) do
                            if MatchesAnyPattern(nameLower, rule.patterns, rule.exact) then
                                ApplyModifierRule(mods, rule, currentRank, maxRank)
                            end
                        end
                    end
                end
            end
        end)
    end

    self._modsCache[cacheKey] = mods
    return mods
end

-- Backward-compatible pattern helper with automatic EN/DE alias and coordinate resolution
function GSI_TalentIntegration:GetTalentRankByPattern(pattern, fallbackTab, fallbackTier, fallbackCol, exactOnly, explicitConfigID)
    if not pattern then return nil end
    local patLower = LowerUTF8(pattern)
    local def = PATTERN_ALIASES[patLower]
    if def then
        return self:GetTalentRankByDef(def, explicitConfigID)
    end
    local snap = self:GetSnapshot(explicitConfigID)
    if snap then
        for _, rec in ipairs(snap.entries) do
            if rec.nameLower ~= "" and MatchesAnyPattern(rec.nameLower, pattern, exactOnly) then
                return rec.rank
            end
        end
        return 0
    end
    return self:GetTalentRank(pattern, fallbackTab, fallbackTier, fallbackCol, exactOnly)
end

-- Forever 1.60.1 Shaman Enhancement Intellect Weight:
function GSI_TalentIntegration:GetShamanEnhancementIntWeight(explicitConfigID)
    local rankMD = self:GetTalentRankByDef(TALENT_DEFINITIONS.MENTAL_DEXTERITY, explicitConfigID)
    local rankMQ = self:GetTalentRankByDef(TALENT_DEFINITIONS.MENTAL_QUICKNESS, explicitConfigID)
    if rankMD == nil and rankMQ == nil then return nil end
    local rMD = math_min(3, math_max(0, rankMD or 0))
    local rMQ = math_min(2, math_max(0, rankMQ or 0))
    local weight = 0.20 + (rMD * 0.17) + (rMQ * 0.095)
    return math_min(0.90, math_max(0.20, math_floor(weight * 100 + 0.5) / 100))
end

-- Hunter Marksmanship Intellect Weight (Careful Aim 5 ranks: 20..100% INT -> AP)
function GSI_TalentIntegration:GetHunterMMIntWeight(explicitConfigID)
    local rankCA = self:GetTalentRankByDef(TALENT_DEFINITIONS.CAREFUL_AIM, explicitConfigID)
    if rankCA == nil then return nil end
    local r = math_min(5, math_max(0, rankCA))
    local weight = 0.15 + (r * 0.082)
    return math_min(0.56, math_max(0.15, math_floor(weight * 100 + 0.5) / 100))
end

-- Hunter Survival Intellect Weight (Careful Aim 5 ranks with melee/AP scaling)
function GSI_TalentIntegration:GetHunterSurvivalIntWeight(explicitConfigID)
    local rankCA = self:GetTalentRankByDef(TALENT_DEFINITIONS.CAREFUL_AIM, explicitConfigID)
    if rankCA == nil then return nil end
    local r = math_min(5, math_max(0, rankCA))
    local weight = 0.20 + (r * 0.10)
    return math_min(0.70, math_max(0.20, math_floor(weight * 100 + 0.5) / 100))
end

-- Paladin Holy Spirit Weight (Reverence 2 ranks: 15/30% FSR mana regen)
function GSI_TalentIntegration:GetPaladinHolySpiritWeight(explicitConfigID)
    local rankRev = self:GetTalentRankByDef(TALENT_DEFINITIONS.REVERENCE, explicitConfigID)
    if rankRev == nil then return nil end
    local r = math_min(2, math_max(0, rankRev))
    local weight = 0.15 + (r * 0.225)
    return math_min(0.60, math_max(0.15, math_floor(weight * 100 + 0.5) / 100))
end

-- Paladin Retribution Intellect Weight (Champion of the Light 5 ranks: 12..60% INT -> SP)
function GSI_TalentIntegration:GetPaladinRetIntWeight(explicitConfigID)
    local rankCotL = self:GetTalentRankByDef(TALENT_DEFINITIONS.CHAMPION_OF_THE_LIGHT, explicitConfigID)
    if rankCotL == nil then return nil end
    local r = math_min(5, math_max(0, rankCotL))
    local weight = 0.11 + (r * 0.056)
    return math_min(0.39, math_max(0.11, math_floor(weight * 100 + 0.5) / 100))
end

-- Mage Arcane Intellect & Mana Weight
function GSI_TalentIntegration:GetMageArcaneIntWeight(explicitConfigID)
    local rankAB = self:GetTalentRankByDef(TALENT_DEFINITIONS.ARCANE_BLAST, explicitConfigID)
    local rankAW = self:GetTalentRankByDef(TALENT_DEFINITIONS.ARCANE_WRATH, explicitConfigID)
    if rankAB == nil and rankAW == nil then return nil end
    local abBonus = (rankAB and rankAB > 0) and 0.54 or 0.0
    local awBonus = (rankAW and rankAW > 0) and 0.21 or 0.0
    local weight = 0.60 + abBonus + awBonus
    return math_min(1.45, math_max(0.45, math_floor(weight * 100 + 0.5) / 100))
end

function GSI_TalentIntegration:GetMageArcaneManaWeight(explicitConfigID)
    local rankAW = self:GetTalentRankByDef(TALENT_DEFINITIONS.ARCANE_WRATH, explicitConfigID)
    if rankAW == nil then return nil end
    return (rankAW > 0) and 0.032 or 0.015
end

-- Priest Mental Strength (Discipline Row 2 Col 3, 5 ranks: +2..10% INT)
function GSI_TalentIntegration:GetPriestMentalStrengthBonus(explicitConfigID)
    local rankMS = self:GetTalentRankByDef(TALENT_DEFINITIONS.MENTAL_STRENGTH, explicitConfigID)
    if not rankMS or rankMS <= 0 then return 0 end
    return math_min(5, rankMS) * 0.02
end

-- Priest Dark Inspiration (Shadow Row 4 Col 1, 5 ranks: Spirit % via Mind Flay, fixed Nov 24)
function GSI_TalentIntegration:GetPriestDarkInspirationSpiritBonus(explicitConfigID)
    local rankDI = self:GetTalentRankByDef(TALENT_DEFINITIONS.DARK_INSPIRATION, explicitConfigID)
    if not rankDI or rankDI <= 0 then return 0 end
    return math_min(5, rankDI) * 0.035
end

-- Druid Balance Dreamstate (Row 6 Col 2, 5 ranks: 20..100% self-Innervate, Nov 25 rework)
function GSI_TalentIntegration:GetDruidBalanceSpiritWeight(explicitConfigID)
    local rankDS = self:GetTalentRankByDef(TALENT_DEFINITIONS.DREAMSTATE, explicitConfigID)
    if rankDS == nil then return nil end
    local r = math_min(5, math_max(0, rankDS))
    return math_floor((0.22 + r * 0.02) * 100 + 0.5) / 100
end

-- Druid Natural Instinct (Feral Row 5 Col 4, 2 ranks)
function GSI_TalentIntegration:GetDruidRestoIntBonus(explicitConfigID)
    local rankNI = self:GetTalentRankByDef(TALENT_DEFINITIONS.NATURAL_INSTINCT, explicitConfigID)
    if not rankNI or rankNI <= 0 then return 0 end
    if rankNI == 1 then return 0.12 end
    return 0.25
end

function GSI_TalentIntegration:GetDruidNaturalInstinctFeralCritMod(explicitConfigID)
    local rankNI = self:GetTalentRankByDef(TALENT_DEFINITIONS.NATURAL_INSTINCT, explicitConfigID)
    if not rankNI or rankNI <= 0 then return 1.0 end
    return 1.0 + (math_min(2, rankNI) * 0.04)
end

-- Rogue Weapon Expertise (Combat Row 4 Col 3, 2 ranks)
function GSI_TalentIntegration:GetRogueWeaponExpertiseReduction(explicitConfigID)
    local rankWE = self:GetTalentRankByDef(TALENT_DEFINITIONS.WEAPON_EXPERTISE, explicitConfigID)
    if not rankWE or rankWE <= 0 then return 0 end
    return math_min(2.0, rankWE * 1.0)
end

-- School-restricted hit talent bonuses
function GSI_TalentIntegration:GetSchoolHitTalentBonus(class, specIndex, school, explicitConfigID)
    class = class or ResolvePlayerClass()
    if not school then return 0 end

    if class == "PRIEST" then
        if school == "Holy" then
            local r = self:GetTalentRankByDef(TALENT_DEFINITIONS.HOLY_PRECISION, explicitConfigID)
            if r and r > 0 then return math_min(18.0, r * 6.0) end
        elseif school == "Shadow" then
            local r = self:GetTalentRankByDef(TALENT_DEFINITIONS.SHADOW_FOCUS, explicitConfigID)
            if r and r > 0 then return math_min(5.0, r * 1.0) end
        end
    elseif class == "PALADIN" and school == "Holy" then
        local r = self:GetTalentRankByDef(TALENT_DEFINITIONS.DIVINE_PRECISION, explicitConfigID)
        if r and r > 0 then return math_min(8.0, r * 4.0) end
    end

    return 0
end

-- Forever 1.60.1 general Hit talent bonus (percentage, e.g. 6.0 for 6% Hit)
function GSI_TalentIntegration:GetClassHitTalentBonus(class, specIndex, explicitConfigID)
    class = class or ResolvePlayerClass()
    local bonus = 0

    if class == "WARLOCK" then
        local r = self:GetTalentRankByDef(TALENT_DEFINITIONS.SUPPRESSION, explicitConfigID)
        if r and r > 0 then bonus = bonus + math_min(5.0, r * 1.0) end
    elseif class == "ROGUE" then
        local r = self:GetTalentRankByDef(TALENT_DEFINITIONS.PRECISION_ROGUE, explicitConfigID)
        if r and r > 0 then bonus = bonus + math_min(3.0, r * 1.0) end
    elseif class == "HUNTER" then
        local r = self:GetTalentRankByDef(TALENT_DEFINITIONS.SUREFOOTED, explicitConfigID)
        if r and r > 0 then bonus = bonus + math_min(3.0, r * 1.0) end
    elseif class == "SHAMAN" then
        local r = self:GetTalentRankByDef(TALENT_DEFINITIONS.TIDAL_FOCUS, explicitConfigID)
        if r and r > 0 then bonus = bonus + math_min(5.0, r * 1.0) end
    elseif class == "MAGE" then
        local r = self:GetTalentRankByDef(TALENT_DEFINITIONS.PRECISION_MAGE, explicitConfigID)
        if r and r > 0 then bonus = bonus + math_min(6.0, r * 2.0) end
    elseif class == "PRIEST" and specIndex == 3 then
        local r = self:GetTalentRankByDef(TALENT_DEFINITIONS.SHADOW_FOCUS, explicitConfigID)
        if r and r > 0 then bonus = bonus + math_min(5.0, r * 1.0) end
    elseif class == "PALADIN" then
        local rPrec = self:GetTalentRankByDef(TALENT_DEFINITIONS.PRECISION_PALADIN, explicitConfigID)
        if rPrec and rPrec > 0 then bonus = bonus + math_min(3.0, rPrec * 1.0) end
    elseif class == "DRUID" and specIndex == 1 then
        local r = self:GetTalentRankByDef(TALENT_DEFINITIONS.NATURES_REACH, explicitConfigID)
        if r and r > 0 then bonus = bonus + math_min(4.0, r * 2.0) end
    end

    return bonus
end
