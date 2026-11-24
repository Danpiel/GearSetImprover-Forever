-- ============================================================
-- GearSetImprover - ItemScore.lua (WoW Forever)
-- Core equipment scoring engine for WoW Forever.
-- Implements equivalency-point formulas and tiered caps (v2.2).
-- ============================================================

GSI_ItemScore = {}

local INVSLOT_MAINHAND = _G.INVSLOT_MAINHAND or 16
local INVSLOT_OFFHAND  = _G.INVSLOT_OFFHAND or 17
local INVSLOT_RANGED   = _G.INVSLOT_RANGED or 18

local function IsShieldTankSpec(class, specIndex)
    return (class == "WARRIOR" and specIndex == 3) or (class == "PALADIN" and specIndex == 2)
end

local GetItemInfo = (C_Item and C_Item.GetItemInfo) or _G.GetItemInfo or function() return nil end
local GetItemInfoInstant = (C_Item and C_Item.GetItemInfoInstant) or _G.GetItemInfoInstant or function() return nil end
local GetItemStatsFn = (C_Item and C_Item.GetItemStats) or _G.GetItemStats

local EQUIP_SLOTS_ALL = { 1, 2, 3, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18 }
local RESIST_MAP = {
    Fire = "FireResist",
    Nature = "NatureResist",
    Frost = "FrostResist",
    Shadow = "ShadowResist",
    Arcane = "ArcaneResist",
}
local SPELL_SCHOOL_STATS = {
    SpellPower = true,
    ArcaneSpellPower = true,
    FireSpellPower = true,
    FrostSpellPower = true,
    ShadowSpellPower = true,
    NatureSpellPower = true,
    HolySpellPower = true,
}
local WEAPON_SKILL_SUBCLASS = {
    AXE      = { [0] = true, [1] = true },
    BOW      = { [2] = true },
    GUN      = { [3] = true },
    MACE     = { [4] = true, [5] = true },
    POLEARM  = { [6] = true },
    SWORD    = { [7] = true, [8] = true },
    STAFF    = { [10] = true },
    FIST     = { [13] = true },
    DAGGER   = { [15] = true },
    THROWN   = { [16] = true },
    CROSSBOW = { [18] = true },
    WAND     = { [19] = true },
}
local RANGED_WEAPON_SKILL_TYPES = {
    BOW = true,
    GUN = true,
    CROSSBOW = true,
    THROWN = true,
    WAND = true,
}

-- WoW Forever returns internal Level-60 rating values from GetItemStats() while tooltips
-- display flat percentages/skills; prefer tooltip parsing and use these divisors as fallback.
local RATING_API_KEYS = {
    ITEM_MOD_CRIT_RATING_SHORT          = { stat = "Crit",               divisor = 14.0 },
    ITEM_MOD_CRIT_RATING                = { stat = "Crit",               divisor = 14.0 },
    ITEM_MOD_CRIT_MELEE_RATING_SHORT    = { stat = "Crit",               divisor = 14.0 },
    ITEM_MOD_CRIT_MELEE_RATING          = { stat = "Crit",               divisor = 14.0 },
    ITEM_MOD_CRIT_RANGED_RATING_SHORT   = { stat = "Crit",               divisor = 14.0 },
    ITEM_MOD_CRIT_RANGED_RATING         = { stat = "Crit",               divisor = 14.0 },
    ITEM_MOD_CRIT_SPELL_RATING_SHORT    = { stat = "Crit",               divisor = 14.0 },
    ITEM_MOD_CRIT_SPELL_RATING          = { stat = "Crit",               divisor = 14.0 },
    ITEM_MOD_HIT_RATING_SHORT           = { stat = "Hit",                divisor = 10.0 },
    ITEM_MOD_HIT_RATING                 = { stat = "Hit",                divisor = 10.0 },
    ITEM_MOD_HIT_MELEE_RATING_SHORT     = { stat = "Hit",                divisor = 10.0 },
    ITEM_MOD_HIT_MELEE_RATING           = { stat = "Hit",                divisor = 10.0 },
    ITEM_MOD_HIT_RANGED_RATING_SHORT    = { stat = "Hit",                divisor = 10.0 },
    ITEM_MOD_HIT_RANGED_RATING          = { stat = "Hit",                divisor = 10.0 },
    ITEM_MOD_HIT_SPELL_RATING_SHORT     = { stat = "Hit",                divisor = 10.0 },
    ITEM_MOD_HIT_SPELL_RATING           = { stat = "Hit",                divisor = 10.0 },
    ITEM_MOD_HASTE_RATING_SHORT         = { stat = "Haste",              divisor = 10.0 },
    ITEM_MOD_HASTE_RATING               = { stat = "Haste",              divisor = 10.0 },
    ITEM_MOD_HASTE_MELEE_RATING_SHORT   = { stat = "Haste",              divisor = 10.0 },
    ITEM_MOD_HASTE_MELEE_RATING         = { stat = "Haste",              divisor = 10.0 },
    ITEM_MOD_HASTE_RANGED_RATING_SHORT  = { stat = "Haste",              divisor = 10.0 },
    ITEM_MOD_HASTE_RANGED_RATING        = { stat = "Haste",              divisor = 10.0 },
    ITEM_MOD_HASTE_SPELL_RATING_SHORT   = { stat = "Haste",              divisor = 10.0 },
    ITEM_MOD_HASTE_SPELL_RATING         = { stat = "Haste",              divisor = 10.0 },
    ITEM_MOD_DODGE_RATING_SHORT         = { stat = "Dodge",              divisor = 12.0 },
    ITEM_MOD_DODGE_RATING               = { stat = "Dodge",              divisor = 12.0 },
    ITEM_MOD_PARRY_RATING_SHORT         = { stat = "Parry",              divisor = 15.0 },
    ITEM_MOD_PARRY_RATING               = { stat = "Parry",              divisor = 15.0 },
    ITEM_MOD_BLOCK_RATING_SHORT         = { stat = "Block",              divisor = 5.0 },
    ITEM_MOD_BLOCK_RATING               = { stat = "Block",              divisor = 5.0 },
    ITEM_MOD_DEFENSE_SKILL_RATING_SHORT = { stat = "Defense",            divisor = 1.5 },
    ITEM_MOD_DEFENSE_SKILL_RATING       = { stat = "Defense",            divisor = 1.5 },
    ITEM_MOD_EXPERTISE_RATING_SHORT     = { stat = "AvoidanceReduction", divisor = 10.0 },
    ITEM_MOD_EXPERTISE_RATING           = { stat = "AvoidanceReduction", divisor = 10.0 },
}

local ParsedStatsCache = {}
local ParsedStatsMetaCache = {}
local ScoreCache = {}
local WeaponInfoCache = {}
local ItemIDCache = {}
local PlayerTotalsCache = {}
local _scanTooltip = nil
local _scanTooltipLeft = {}

local function EnsureScanTooltip()
    if not _scanTooltip then
        _scanTooltip = CreateFrame("GameTooltip", "GSI_ScanTooltip", nil, "GameTooltipTemplate")
        _scanTooltip:SetOwner(WorldFrame or UIParent, "ANCHOR_NONE")
    end
end

local function SetScanTooltipHyperlink(itemLink)
    _scanTooltip:SetHyperlink(itemLink)
end

local function GetTooltipLine(tip, idx)
    local left = _scanTooltipLeft[idx]
    if left == nil then
        left = _G[tip:GetName() .. "TextLeft" .. idx] or false
        _scanTooltipLeft[idx] = left
    end
    return left and left:GetText() or nil
end

local function ExtractItemID(itemLink)
    if type(itemLink) ~= "string" then return nil end
    local cached = ItemIDCache[itemLink]
    if cached ~= nil then
        return cached ~= false and cached or nil
    end
    local id = itemLink:match("item:(%d+)")
    ItemIDCache[itemLink] = id or false
    return id
end

local function CleanNumber(str)
    if not str then return 0 end
    str = str:gsub("%%", ""):gsub("%s+", "")
    str = str:gsub("%.$", "") -- Strip trailing sentence period (e.g. "by 5.")
    if str:find(",") and not str:find("%.") then
        str = str:gsub(",", "%.")
    else
        str = str:gsub(",", "")
    end
    return tonumber(str) or 0
end

-- string.lower only folds ASCII. Fold Cyrillic (UTF-8 D0 90..D0 AF, Ё) and the
-- German capital umlauts too, so localized tooltip lines can be matched in lower case.
local UTF8_LOWER = {}
do
    local char = string.char
    for i = 0, 31 do
        local upper = char(0xD0, 0x90 + i)
        UTF8_LOWER[upper] = (i < 16) and char(0xD0, 0xB0 + i) or char(0xD1, 0x80 + i - 16)
    end
    UTF8_LOWER[char(0xD0, 0x81)] = char(0xD1, 0x91) -- Ё
    UTF8_LOWER[char(0xC3, 0x84)] = char(0xC3, 0xA4) -- Ä
    UTF8_LOWER[char(0xC3, 0x96)] = char(0xC3, 0xB6) -- Ö
    UTF8_LOWER[char(0xC3, 0x9C)] = char(0xC3, 0xBC) -- Ü
end

local function LowerUTF8(s)
    s = s:lower()
    s = s:gsub("\208[\129\144-\175]", UTF8_LOWER)
    s = s:gsub("\195[\132\150\156]", UTF8_LOWER)
    return s
end
GSI_ItemScore.LowerUTF8 = LowerUTF8

-- ------------------------------------------------------------
-- Russian tooltip lines (ruRU). The EN/DE scraper below never matches them,
-- so on a Russian client everything GetItemStats leaves out was lost.
-- Wording as on the Forever ruRU client, e.g.
--   "Броня: 85", "+10 к ловкости", "Если на персонаже: +16 к силе атаки.",
--   "Если на персонаже: повышает вероятность критического удара на 0.5%.",
--   "Если на персонаже: усиливает творимое исцеление максимум на 11 ед., а урон
--    от магических эффектов и заклинаний – максимум на 4 ед.",
--   "Если на персонаже: восстанавливает 4 ед. маны раз в 5 сек."
-- l is the line folded with LowerUTF8. As in the EN/DE scraper, a stat the
-- API already reported is not added again. Returns found, universalSpellPower.
-- ------------------------------------------------------------
local RU_NUM = "([%d%.,]+)"
local RU_RESIST = {
    { "огню", "FireResist" },
    { "силам природы", "NatureResist" }, { "природ", "NatureResist" },
    { "магии льда", "FrostResist" }, { "льду", "FrostResist" }, { "холод", "FrostResist" },
    { "темной магии", "ShadowResist" }, { "тёмной магии", "ShadowResist" }, { "тьме", "ShadowResist" },
    { "тайной магии", "ArcaneResist" }, { "тайн", "ArcaneResist" },
}
local RU_SCHOOL = {
    { "огн", "FireSpellPower" }, { "льд", "FrostSpellPower" }, { "холод", "FrostSpellPower" },
    { "темн", "ShadowSpellPower" }, { "тёмн", "ShadowSpellPower" }, { "тьм", "ShadowSpellPower" },
    { "природ", "NatureSpellPower" }, { "тайн", "ArcaneSpellPower" }, { "свет", "HolySpellPower" },
}

local function ParseRussianLine(l, stats, apiFound)
    -- Requirements, durability, set bonuses, on-use effects and procs are not item stats
    if l:find("требуется") or l:find("прочность") or l:find("классы:") or l:find("^%(%d+%)")
       or l:find("^комплект") or l:find("использование:") or l:find("при попадании")
       or l:find("цена продажи") then
        return false, false
    end

    local found, universal = false, false
    local function Add(stat, str)
        if not str then return end
        if not apiFound[stat] then
            stats[stat] = (stats[stat] or 0) + CleanNumber(str)
        end
        found = true
    end

    -- Armor (base armor line or bonus armor; largest value wins as in EN/DE)
    local arm = l:match("^броня:?%s*" .. RU_NUM) or l:match("%+" .. RU_NUM .. " к броне")
    if arm then
        local v = CleanNumber(arm)
        if v > (stats.Armor or 0) then stats.Armor = v end
        found = true
    end

    -- Primary stats ("к силе атаки" is attack power, not strength)
    Add("Stamina", l:match("%+" .. RU_NUM .. " к выносливости"))
    Add("Agility", l:match("%+" .. RU_NUM .. " к ловкости"))
    Add("Intellect", l:match("%+" .. RU_NUM .. " к интеллекту"))
    Add("Spirit", l:match("%+" .. RU_NUM .. " к духу"))
    for num, rest in l:gmatch("%+" .. RU_NUM .. " к силе(%S*%s*%S*)") do
        if not rest:find("^%s*атаки") then Add("Strength", num) end
    end
    local all = l:match("%+" .. RU_NUM .. " ко всем характеристикам")
    if all then
        for _, k in ipairs({ "Stamina", "Agility", "Strength", "Intellect", "Spirit" }) do Add(k, all) end
    end

    -- Attack power: ranged, feral forms, plain (versus creature types are situational)
    if l:find("силе атаки") or l:find("силу атаки") or l:find("сила атаки") then
        local num = l:match("%+" .. RU_NUM .. " к силе атаки") or l:match("сил%S* атаки.-на " .. RU_NUM)
        if l:find("дальнего боя") then
            Add("RangedAttackPower", num)
        elseif l:find("в облике") then
            Add("FeralAttackPower", num)
        elseif not l:find("против") then
            Add("AttackPower", num)
        end
    end

    -- Percent combat stats
    if l:find("%%") then
        if l:find("снижает") and (l:find("уклон") or l:find("парир")) then
            -- Expertise: "снижает вероятность того, что ваши атаки будут парированы / от них уклонятся"
            Add("AvoidanceReduction", l:match("на " .. RU_NUM .. "%%"))
        elseif l:find("критическ") then
            Add("Crit", l:match("критическ.-на " .. RU_NUM .. "%%") or l:match("%+" .. RU_NUM .. "%% к критическ"))
        elseif l:find("попадани") or l:find("меткост") then
            Add("Hit", l:match("на " .. RU_NUM .. "%%") or l:match("%+" .. RU_NUM .. "%% к меткости"))
        elseif l:find("уклон") then
            Add("Dodge", l:match("на " .. RU_NUM .. "%%"))
        elseif l:find("парир") then
            Add("Parry", l:match("на " .. RU_NUM .. "%%"))
        elseif l:find("блок") and not l:find("показател") then
            Add("Block", l:match("на " .. RU_NUM .. "%%"))
        elseif l:find("скорость") and not l:find("передвиж") and not l:find("бега") and not l:find("сек") then
            Add("Haste", l:match("скорость.-на " .. RU_NUM .. "%%"))
        end
    end

    -- Defense skill, block value, weapon skill
    Add("Defense", l:match("навык%S* защиты.-на " .. RU_NUM) or l:match("%+" .. RU_NUM .. " к защите"))
    Add("BlockValue", l:match("показател%S* блокировани.-на " .. RU_NUM)
        or l:match("%+" .. RU_NUM .. " к показателю блокирования") or l:match("^блок:?%s*" .. RU_NUM))
    local ws = l:match("навык%S* владения.-на " .. RU_NUM)
    if ws then
        Add("WeaponSkill", ws)
        if l:find("топор") then stats.WeaponSkillType = "AXE"
        elseif l:find("меч") then stats.WeaponSkillType = "SWORD"
        elseif l:find("кинжал") then stats.WeaponSkillType = "DAGGER"
        elseif l:find("дробящ") or l:find("булав") then stats.WeaponSkillType = "MACE"
        else stats.WeaponSkillType = "ALL" end
    end

    -- Spell power family
    local sp = l:match("урон и силу исцеления.-максимум на " .. RU_NUM)
    if sp then
        Add("SpellPower", sp)
        universal = true
    else
        Add("HealingPower", l:match("исцеление максимум на " .. RU_NUM) or l:match("%+" .. RU_NUM .. " к силе исцеления"))
        local dmg = l:match("урон от магических эффектов и заклинаний.-максимум на " .. RU_NUM)
            or l:match("%+" .. RU_NUM .. " к силе заклинаний")
        if dmg then
            Add("SpellPower", dmg)
        elseif l:find("урон") and l:find("максимум на") and not l:find("исцелен") then
            local v = l:match("максимум на " .. RU_NUM)
            for _, s in ipairs(RU_SCHOOL) do
                if l:find(s[1]) then
                    stats[s[2]] = (stats[s[2]] or 0) + CleanNumber(v)
                    found = true
                    break
                end
            end
        end
    end
    Add("SpellPenetration", l:match("сопротивлени.-целей.-на " .. RU_NUM))

    -- Regeneration
    Add("MP5", l:match(RU_NUM .. " ед%. маны раз в 5 сек") or l:match(RU_NUM .. " маны в 5 сек"))
    Add("HP5", l:match(RU_NUM .. " ед%. здоровья раз в 5 сек") or l:match(RU_NUM .. " здоровья в 5 сек"))

    -- Resistances
    local rv, rest = l:match("%+" .. RU_NUM .. " к сопротивлению (.*)")
    if not rv then rest, rv = l:match("сопротивлени%S* (.-) на " .. RU_NUM) end
    if rv and rest then
        if rest:find("всем") then
            for _, k in ipairs({ "FireResist", "NatureResist", "FrostResist", "ShadowResist", "ArcaneResist" }) do Add(k, rv) end
        else
            for _, r in ipairs(RU_RESIST) do
                if rest:find(r[1]) then Add(r[2], rv) break end
            end
        end
    end

    return found, universal
end
GSI_ItemScore.ParseRussianLine = ParseRussianLine
-- Checks if an item is currently equipped by the player (prevents cap double-addition)
local function IsItemCurrentlyEquipped(itemLink, targetSlotID)
    local itemID = ExtractItemID(itemLink)
    if not itemID then return false, nil end

    if targetSlotID then
        local eqLink = GetInventoryItemLink("player", targetSlotID)
        if eqLink and ExtractItemID(eqLink) == itemID then
            return true, targetSlotID
        end
        return false, nil
    end

    local slots = (GSI_ClassicData and GSI_ClassicData.EQUIP_SLOTS) or EQUIP_SLOTS_ALL
    for _, slotID in ipairs(slots) do
        local eqLink = GetInventoryItemLink("player", slotID)
        if eqLink and ExtractItemID(eqLink) == itemID then
            return true, slotID
        end
    end
    return false, nil
end

-- Checks if an equipLoc represents a melee weapon or ranged slot
function GSI_ItemScore:IsWeapon(equipLoc)
    return equipLoc == "INVTYPE_WEAPON"
        or equipLoc == "INVTYPE_2HWEAPON"
        or equipLoc == "INVTYPE_WEAPONMAINHAND"
        or equipLoc == "INVTYPE_WEAPONOFFHAND"
end

function GSI_ItemScore:IsRanged(equipLoc)
    return equipLoc == "INVTYPE_RANGED"
        or equipLoc == "INVTYPE_RANGEDRIGHT"
        or equipLoc == "INVTYPE_THROWN"
end

-- Extracts weapon DPS and attack speed from the item tooltip
function GSI_ItemScore:GetWeaponInfo(itemLink)
    if WeaponInfoCache[itemLink] then return WeaponInfoCache[itemLink] end

    EnsureScanTooltip()
    _scanTooltip:ClearLines()
    local ok = pcall(SetScanTooltipHyperlink, itemLink)
    if not ok then return { dps = 0, speed = 2.0 } end

    local dps = 0
    local speed = 2.0

    -- DPS straight from the API (locale-independent); the tooltip is the fallback
    local apiStats = GetItemStatsFn and GetItemStatsFn(itemLink)
    local apiDps = apiStats and (apiStats.ITEM_MOD_DAMAGE_PER_SECOND_SHORT or apiStats.ITEM_MOD_DAMAGE_PER_SECOND)
    if type(apiDps) == "number" and apiDps > 0 then
        dps = apiDps
    end

    -- The speed sits in the right-hand text of the damage line ("Speed 3.60",
    -- ruRU "Скорость 3,60"), which the left-only scan never saw: read both.
    local tipName = _scanTooltip:GetName()
    for i = 1, _scanTooltip:NumLines() do
        local left = GetTooltipLine(_scanTooltip, i)
        local rightObj = _G[tipName .. "TextRight" .. i]
        local right = rightObj and rightObj:IsShown() and rightObj:GetText() or nil
        for _, line in ipairs({ left or "", right or "" }) do
            if line:find("%d") then
                local dpsStr = line:match("%(([%d,%.]+)%s*[Ss]chaden pro [Ss]ekunde%)")
                            or line:match("%(([%d,%.]+)%s*damage per second%)")
                            or line:match("%(([%d,%.]+)%s*ед%.%s*урона в секунду%)")
                            or line:match("%(([%d,%.]+)%s*[Dd][Pp][Ss]%)")
                            or line:match("([%d,%.]+)%s*[Dd][Pp][Ss]")
                if dpsStr and dps == 0 then
                    dps = CleanNumber(dpsStr)
                end

                local spdStr = line:match("[Gg]eschwindigkeit%s+([%d,%.]+)")
                            or line:match("[Tt]empo%s+([%d,%.]+)")
                            or line:match("[Ss]peed%s+([%d,%.]+)")
                            or line:match("Скорость%s+([%d,%.]+)")
                            or line:match("скорость%s+([%d,%.]+)")
                if spdStr then
                    speed = CleanNumber(spdStr)
                end
            end
        end
    end

    local info = { dps = dps, speed = speed }
    if _scanTooltip:NumLines() >= 2 then
        WeaponInfoCache[itemLink] = info
    end
    return info
end

-- Parses all item stats from client API and tooltip text (bilingual DE & EN)
function GSI_ItemScore:GetParsedStats(itemLink)
    if not itemLink then return {} end
    if ParsedStatsCache[itemLink] then return ParsedStatsCache[itemLink] end

    local stats = {
        Strength = 0, Agility = 0, Stamina = 0, Intellect = 0, Spirit = 0,
        AttackPower = 0, RangedAttackPower = 0, FeralAttackPower = 0,
        SpellPower = 0, HealingPower = 0,
        ArcaneSpellPower = 0, FireSpellPower = 0, FrostSpellPower = 0,
        ShadowSpellPower = 0, NatureSpellPower = 0, HolySpellPower = 0,
        SpellPenetration = 0,
        Hit = 0, Crit = 0, Haste = 0, ArmorPenetration = 0,
        Mana = 0, MP5 = 0, HP5 = 0, Armor = 0,
        Defense = 0, Dodge = 0, Parry = 0, Block = 0, BlockValue = 0,
        WeaponSkill = 0, WeaponSkillType = nil, AvoidanceReduction = 0,
        FlatWeaponDamage = 0,
        FireResist = 0, NatureResist = 0, FrostResist = 0, ShadowResist = 0, ArcaneResist = 0
    }

    local foundAnyStat = false
    local hasUniversalSP = false
    local apiFoundStats = {}
    local apiRatingFallback = {}

    -- 1. Base stats from WoW API (when supported by client)
    -- Rating keys (Crit, Hit, Haste, Dodge, Parry, Block, Defense, Expertise) return internal
    -- Level-60 ratings rather than tooltip flat percentages, so defer them as converted fallback
    -- and let the tooltip parser read the authoritative flat values first.
    local apiStats = GetItemStatsFn and GetItemStatsFn(itemLink)
    if apiStats then
        for apiKey, value in pairs(apiStats) do
            if value and value > 0 then
                local ratingCfg = RATING_API_KEYS[apiKey]
                if ratingCfg then
                    apiRatingFallback[ratingCfg.stat] = (apiRatingFallback[ratingCfg.stat] or 0) + (value / ratingCfg.divisor)
                else
                    local mapped = GSI_Config.StatMap[apiKey]
                    if mapped and stats[mapped] ~= nil then
                        stats[mapped] = stats[mapped] + value
                        apiFoundStats[mapped] = true
                        foundAnyStat = true
                        if apiKey == "ITEM_MOD_SPELL_POWER" or apiKey == "ITEM_MOD_SPELL_POWER_SHORT" then
                            hasUniversalSP = true
                        end
                    end
                end
            end
        end
    end

    -- 2. Tooltip scraper for base stats, equip effects, and custom Forever lines
    EnsureScanTooltip()
    _scanTooltip:ClearLines()
    local ok = pcall(SetScanTooltipHyperlink, itemLink)
    local numLines = ok and _scanTooltip:NumLines() or 0

    if ok and numLines >= 2 then
        for i = 1, numLines do
            local line = GetTooltipLine(_scanTooltip, i)
            -- Skip digit-free lines immediately to cut regex work
            if line and line:find("%d") and line:find("[\208\209]") then
                -- Cyrillic line: Russian client
                local found, universal = ParseRussianLine(LowerUTF8(line), stats, apiFoundStats)
                if found then foundAnyStat = true end
                if universal then hasUniversalSP = true end
            elseif line and line:find("%d") then
                local l = line:lower():gsub("Ä", "ä"):gsub("Ö", "ö"):gsub("Ü", "ü")
                if not l:find("haltbarkeit") and not l:find("durability")
                   and not l:match("^%(%d+%)%s*set:") and not l:match("^set:")
                   and not l:match("^verzaubert:") and not l:match("^enchanted:")
                then
                    -- Armor vs Armor Penetration (never parse "ignore X armor" into defensive Armor)
                    if not l:find("ignor") and not l:find("penetration") and not l:find("durchschlag")
                       and not l:find("pierc") and not l:find("verringert") and not l:find("reduces")
                    then
                        local armStr = l:match("([%d%.,]+)%s+rüstung")
                                    or l:match("rüstung:?%s*([%d%.,]+)")
                                    or l:match("([%d%.,]+)%s+armor")
                                    or l:match("armor:?%s*([%d%.,]+)")
                        if armStr then
                            local armVal = CleanNumber(armStr)
                            if armVal > stats.Armor then stats.Armor = armVal end
                            foundAnyStat = true
                        end
                    elseif not l:find("chance") and not l:find("for %d+ sec") and not l:find("%d+ sek")
                           and not l:find("^use:") and not l:find("^benutzen:") and not l:find("%%")
                    then
                        local arpStr = l:match("attacks ignore%s+([%d%.,]+)%s+of your opponent.*armor")
                                    or l:match("ignore%s+([%d%.,]+)%s+.*armor")
                                    or l:match("armor penetration.*by%s+([%d%.,]+)")
                                    or l:match("%+?%s*([%d%.,]+)%s+armor penetration")
                                    or l:match("ignorier[etn]*%s+([%d%.,]+)%s+.*rüstung")
                                    or l:match("([%d%.,]+)%s+rüstung.*ignorier")
                                    or l:match("rüstungsdurchschlag.*um%s+([%d%.,]+)")
                                    or l:match("%+?%s*([%d%.,]+)%s+rüstungsdurchschlag")
                                    or l:match("rüstungsverringerung.*um%s+([%d%.,]+)")
                        if arpStr then
                            local v = CleanNumber(arpStr)
                            if not apiFoundStats.ArmorPenetration then
                                stats.ArmorPenetration = stats.ArmorPenetration + v
                            end
                            foundAnyStat = true
                        end
                    end

                    -- Stamina
                    local staStr = l:match("%+?%s*([%d%.,]+)%s+ausdauer")
                                or l:match("ausdauer.*um%s+([%d%.,]+)")
                                or l:match("%+?%s*([%d%.,]+)%s+stamina")
                                or l:match("stamina.*by%s+([%d%.,]+)")
                    if staStr then
                        local v = CleanNumber(staStr)
                        if not apiFoundStats.Stamina then
                            stats.Stamina = stats.Stamina + v
                        end
                        foundAnyStat = true
                    end

                    -- Agility
                    local agiStr = l:match("%+?%s*([%d%.,]+)%s+beweglichkeit")
                                or l:match("beweglichkeit.*um%s+([%d%.,]+)")
                                or l:match("%+?%s*([%d%.,]+)%s+agility")
                                or l:match("agility.*by%s+([%d%.,]+)")
                    if agiStr then
                        local v = CleanNumber(agiStr)
                        if not apiFoundStats.Agility then
                            stats.Agility = stats.Agility + v
                        end
                        foundAnyStat = true
                    end

                    -- Strength
                    local strStr = l:match("%+?%s*([%d%.,]+)%s+stärke")
                                or l:match("stärke.*um%s+([%d%.,]+)")
                                or l:match("%+?%s*([%d%.,]+)%s+strength")
                                or l:match("strength.*by%s+([%d%.,]+)")
                    if strStr then
                        local v = CleanNumber(strStr)
                        if not apiFoundStats.Strength then
                            stats.Strength = stats.Strength + v
                        end
                        foundAnyStat = true
                    end

                    -- Intellect
                    local intStr = l:match("%+?%s*([%d%.,]+)%s+intelligenz")
                                or l:match("intelligenz.*um%s+([%d%.,]+)")
                                or l:match("%+?%s*([%d%.,]+)%s+intellect")
                                or l:match("intellect.*by%s+([%d%.,]+)")
                    if intStr then
                        local v = CleanNumber(intStr)
                        if not apiFoundStats.Intellect then
                            stats.Intellect = stats.Intellect + v
                        end
                        foundAnyStat = true
                    end

                    -- Spirit
                    local spiStr = l:match("%+?%s*([%d%.,]+)%s+willenskraft")
                                or l:match("willenskraft.*um%s+([%d%.,]+)")
                                or l:match("%+?%s*([%d%.,]+)%s+spirit")
                                or l:match("spirit.*by%s+([%d%.,]+)")
                    if spiStr then
                        local v = CleanNumber(spiStr)
                        if not apiFoundStats.Spirit then
                            stats.Spirit = stats.Spirit + v
                        end
                        foundAnyStat = true
                    end

                    -- All Stats
                    local allVal = l:match("%+?%s*([%d%.,]+)%s+.*alle werte")
                                or l:match("alle werte.*%+?([%d%.,]+)")
                                or l:match("%+?%s*([%d%.,]+)%s+all stats")
                    if allVal then
                        local av = CleanNumber(allVal)
                        if not apiFoundStats.Stamina then stats.Stamina = stats.Stamina + av end
                        if not apiFoundStats.Agility then stats.Agility = stats.Agility + av end
                        if not apiFoundStats.Strength then stats.Strength = stats.Strength + av end
                        if not apiFoundStats.Intellect then stats.Intellect = stats.Intellect + av end
                        if not apiFoundStats.Spirit then stats.Spirit = stats.Spirit + av end
                        foundAnyStat = true
                    end

                    -- Defense
                    local defStr = l:match("verteidigung.*um%s+([%d%.,]+)")
                                or l:match("verteidigung%s*%+%s*([%d%.,]+)")
                                or l:match("%+?%s*([%d%.,]+)%s+verteidigung")
                                or l:match("defense.*by%s+([%d%.,]+)")
                                or l:match("defense%s*%+%s*([%d%.,]+)")
                                or l:match("%+?%s*([%d%.,]+)%s+defense")
                    if defStr then
                        local v = CleanNumber(defStr)
                        if not apiFoundStats.Defense then
                            stats.Defense = stats.Defense + v
                        end
                        foundAnyStat = true
                    end

                    -- Dodge (exclude offensive "reduces the chance ... dodged/ausgewichen")
                    if not l:find("verringert") and not l:find("reduces")
                       and not l:find("dodged") and not l:find("ausgewichen") and not l:find("parried")
                    then
                        local dgeStr = l:match("auszuweichen.*um%s+([%d%.,]+)%%")
                                    or l:match("ausweichen.*um%s+([%d%.,]+)%%")
                                    or l:match("ausweich.*um%s+([%d%.,]+)%%")
                                    or l:match("%+?%s*([%d%.,]+)%%%s+ausweichen")
                                    or l:match("dodge.*by%s+([%d%.,]+)%%")
                                    or l:match("%+?%s*([%d%.,]+)%%%s+dodge")
                        if dgeStr then
                            local v = CleanNumber(dgeStr)
                            if not apiFoundStats.Dodge then
                                stats.Dodge = stats.Dodge + v
                            end
                            foundAnyStat = true
                        end
                    end

                    -- Parry (exclude offensive "reduces the chance ... parried/pariert")
                    if not l:find("verringert") and not l:find("reduces")
                       and not l:find("parried") and not l:find("pariert")
                    then
                        local parStr = l:match("parieren.*um%s+([%d%.,]+)%%")
                                    or l:match("parier.*um%s+([%d%.,]+)%%")
                                    or l:match("%+?%s*([%d%.,]+)%%%s+parieren")
                                    or l:match("parry.*by%s+([%d%.,]+)%%")
                                    or l:match("%+?%s*([%d%.,]+)%%%s+parry")
                        if parStr then
                            local v = CleanNumber(parStr)
                            if not apiFoundStats.Parry then
                                stats.Parry = stats.Parry + v
                            end
                            foundAnyStat = true
                        end
                    end

                    -- Block
                    if not l:find("blockwert") and not l:find("block value") then
                        local blkStr = l:match("block.*um%s+([%d%.,]+)%%")
                                    or l:match("%+?%s*([%d%.,]+)%%%s+block")
                                    or l:match("block.*by%s+([%d%.,]+)%%")
                        if blkStr then
                            local v = CleanNumber(blkStr)
                            if not apiFoundStats.Block then
                                stats.Block = stats.Block + v
                            end
                            foundAnyStat = true
                        end
                    end

                    -- Block Value
                    local bvStr = l:match("blockwert.*um%s+([%d%.,]+)")
                               or l:match("%+?%s*([%d%.,]+)%s+blockwert")
                               or l:match("block value.*by%s+([%d%.,]+)")
                               or l:match("([%d%.,]+)%s+blocken$")
                               or l:match("([%d%.,]+)%s+block$")
                               or l:match("^([%d%.,]+)%s+block%s*$")
                               or l:match("^([%d%.,]+)%s+blocken%s*$")
                    if bvStr then
                        local v = CleanNumber(bvStr)
                        if not apiFoundStats.BlockValue then
                            stats.BlockValue = stats.BlockValue + v
                        end
                        foundAnyStat = true
                    end

                    -- Crit (Melee & Spell)
                    local critStr = l:match("kritisch.*um%s+([%d%.,]+)%%")
                                 or l:match("%+?%s*([%d%.,]+)%%%s+kritisch")
                                 or l:match("critical.*by%s+([%d%.,]+)%%")
                                 or l:match("%+?%s*([%d%.,]+)%%%s+crit")
                    if critStr then
                        local v = CleanNumber(critStr)
                        if not apiFoundStats.Crit then
                            stats.Crit = stats.Crit + v
                        end
                        foundAnyStat = true
                    end

                    -- Hit (guard against German "kritischen Treffer" matching "treffer.*um")
                    if not l:find("kritisch") and not l:find("critical") and not l:find("crit") then
                        local hitStr = l:match("treffe[rn]?.*um%s+([%d%.,]+)%%")
                                    or l:match("%+?%s*([%d%.,]+)%%%s+treffer")
                                    or l:match("hit.*by%s+([%d%.,]+)%%")
                                    or l:match("%+?%s*([%d%.,]+)%%%s+hit")
                        if hitStr then
                            local v = CleanNumber(hitStr)
                            if not apiFoundStats.Hit then
                                stats.Hit = stats.Hit + v
                            end
                            foundAnyStat = true
                        end
                    end

                    -- Haste (flat % attack/casting speed; exclude procs, durations, movement speed, raw weapon speed)
                    if not l:find("chance") and not l:find("for %d+ sec") and not l:find("%d+ sek")
                       and not l:find("^use:") and not l:find("^benutzen:")
                       and not l:find("movement") and not l:find("run speed") and not l:find("mount") and not l:find("swim")
                       and not l:find("bewegungs") and not l:find("lauftempo") and not l:find("reit")
                    then
                        local hasteStr = l:match("attack and casting speed.*by%s+([%d%.,]+)%%")
                                      or l:match("attack speed.*by%s+([%d%.,]+)%%")
                                      or l:match("spell casting speed.*by%s+([%d%.,]+)%%")
                                      or l:match("casting speed.*by%s+([%d%.,]+)%%")
                                      or l:match("haste.*by%s+([%d%.,]+)%%")
                                      or l:match("%+?%s*([%d%.,]+)%%%s+haste")
                                      or l:match("angriffs%-? und zaubertempo.*um%s+([%d%.,]+)%%")
                                      or l:match("angriffstempo.*um%s+([%d%.,]+)%%")
                                      or l:match("zaubertempo.*um%s+([%d%.,]+)%%")
                                      or l:match("tempo.*um%s+([%d%.,]+)%%")
                                      or l:match("%+?%s*([%d%.,]+)%%%s+tempo")
                        if hasteStr then
                            local v = CleanNumber(hasteStr)
                            if not apiFoundStats.Haste then
                                stats.Haste = stats.Haste + v
                            end
                            foundAnyStat = true
                        end
                    end

                    -- Attack Power (exclude Ranged AP)
                    if not l:find("distanz") and not l:find("ranged") then
                        local apStr = l:match("angriffskraft.*um%s+([%d%.,]+)")
                                   or l:match("%+?%s*([%d%.,]+)%s+angriffskraft")
                                   or l:match("attack power.*by%s+([%d%.,]+)")
                                   or l:match("%+?%s*([%d%.,]+)%s+attack power")
                        if apStr then
                            local v = CleanNumber(apStr)
                            if not apiFoundStats.AttackPower then
                                stats.AttackPower = stats.AttackPower + v
                            end
                            foundAnyStat = true
                        end
                    end

                    -- Ranged Attack Power
                    local rapStr = l:match("distanzangriffskraft.*um%s+([%d%.,]+)")
                                or l:match("%+?%s*([%d%.,]+)%s+distanzangriffskraft")
                                or l:match("ranged attack power.*by%s+([%d%.,]+)")
                                or l:match("%+?%s*([%d%.,]+)%s+ranged attack power")
                    if rapStr then
                        local v = CleanNumber(rapStr)
                        if not apiFoundStats.RangedAttackPower then
                            stats.RangedAttackPower = stats.RangedAttackPower + v
                        end
                        foundAnyStat = true
                    end

                    -- Feral Attack Power
                    local fapStr = l:match("angriffskraft in katzen.*um%s+([%d%.,]+)")
                                or l:match("%+?%s*([%d%.,]+)%s+angriffskraft in katzen")
                                or l:match("angriffskraft in bären.*um%s+([%d%.,]+)")
                                or l:match("attack power in cat.*by%s+([%d%.,]+)")
                                or l:match("%+?%s*([%d%.,]+)%s+attack power in cat")
                    if fapStr then
                        if not apiFoundStats.FeralAttackPower then
                            stats.FeralAttackPower = stats.FeralAttackPower + CleanNumber(fapStr)
                        end
                        foundAnyStat = true
                    end

                    -- Avoidance Reduction (% Expertise / reduces enemy dodge or parry chance)
                    local arStr = l:match("verringert die chance.*auszuweichen.*um%s+([%d%.,]+)%%")
                               or l:match("verringert die chance.*ausgewichen.*um%s+([%d%.,]+)%%")
                               or l:match("verringert die chance.*pariert.*um%s+([%d%.,]+)%%")
                               or l:match("reduces the chance.*to dodge.*by%s+([%d%.,]+)%%")
                               or l:match("reduces the chance.*dodged.*by%s+([%d%.,]+)%%")
                               or l:match("reduces the chance.*parried.*by%s+([%d%.,]+)%%")
                               or l:match("waffenkunde.*um%s+([%d%.,]+)%%")
                               or l:match("%+?%s*([%d%.,]+)%%%s+waffenkunde")
                               or l:match("expertise.*by%s+([%d%.,]+)%%")
                               or l:match("%+?%s*([%d%.,]+)%%%s+expertise")
                    if arStr then
                        local v = CleanNumber(arStr)
                        if not apiFoundStats.AvoidanceReduction then
                            stats.AvoidanceReduction = stats.AvoidanceReduction + v
                        end
                        foundAnyStat = true
                    end

                    -- Weapon Skill (flat skill only, never % expertise or profession/level requirements)
                    if not l:find("%%") and not l:find("requires") and not l:find("benötigt") and not l:find("erfordert")
                       and not l:find("riding") and not l:find("reiten") and not l:find("fishing") and not l:find("angeln")
                       and not l:find("defense") and not l:find("verteidigung")
                       and not l:find("skinning") and not l:find("kürschner") and not l:find("mining") and not l:find("bergbau")
                       and not l:find("herbalism") and not l:find("kräuterkunde") and not l:find("engineering") and not l:find("ingenieurs")
                       and not l:find("lockpicking") and not l:find("schlossknacken") and not l:find("blacksmith") and not l:find("schmiede")
                       and not l:find("alchemy") and not l:find("alchimie") and not l:find("enchanting") and not l:find("verzauber")
                       and not l:find("tailoring") and not l:find("schneider") and not l:find("leatherwork") and not l:find("leder")
                       and not l:find("cooking") and not l:find("koch") and not l:find("first aid") and not l:find("erste hilfe")
                       and not l:find("stealth") and not l:find("verstohlenheit") and not l:find("disarm") and not l:find("entwaffn")
                    then
                        local wsStr = l:match("waffenfertigkeit.*um%s+([%d%.,]+)")
                                   or l:match("%+?%s*([%d%.,]+)%s+waffenfertigkeit")
                                   or l:match("fertigkeit mit .*um%s+([%d%.,]+)")
                                   or l:match("[a-zäöüß]+fertigkeit.*um%s+([%d%.,]+)")
                                   or l:match("%+?%s*([%d%.,]+)%s+[a-zäöüß]+fertigkeit")
                                   or l:match("waffenkunde.*um%s+([%d%.,]+)")
                                   or l:match("weapon skill.*by%s+([%d%.,]+)")
                                   or l:match("%+?%s*([%d%.,]+)%s+weapon skill")
                                   or l:match("skill with .*by%s+([%d%.,]+)")
                                   or l:match("%+?%s*([%d%.,]+)%s+[a-z]+%s+skill")
                                   or l:match("expertise.*by%s+([%d%.,]+)")
                        if not wsStr and (l:find("increased ") or l:find("erhöht ")) then
                            if l:find("crossbow") or l:find("bow") or l:find("gun") or l:find("thrown") or l:find("wand")
                               or l:find("fist") or l:find("polearm") or l:find("staff") or l:find("staves")
                               or l:find("axe") or l:find("sword") or l:find("dagger") or l:find("mace")
                               or l:find("armbrust") or l:find("armbrüste") or l:find("bogen") or l:find("bögen")
                               or l:find("schusswaffe") or l:find("gewehr") or l:find("wurfwaffe")
                               or l:find("zauberstab") or l:find("zauberstäbe")
                               or l:find("faustwaffe") or l:find("stangenwaffe") or l:find("stab") or l:find("stäbe")
                               or l:find("axt") or l:find("äxte") or l:find("schwert") or l:find("dolch")
                               or l:find("streitkolben") or l:find("kolben")
                            then
                                wsStr = l:match("increased%s+[a-z%-%s]+%+%s*([%d%.,]+)")
                                     or l:match("erhöht%s+[a-zäöüß%-%s]+%+%s*([%d%.,]+)")
                            end
                        end
                        if wsStr then
                            local v = CleanNumber(wsStr)
                            if not apiFoundStats.WeaponSkill then
                                stats.WeaponSkill = stats.WeaponSkill + v
                            end
                            -- Specific weapon types MUST be checked before general "waffenfertigkeit"
                            -- (e.g. "schusswaffenfertigkeit" / "faustwaffenfertigkeit" contain "waffenfertigkeit")
                            if l:find("armbrust") or l:find("armbrüste") or l:find("crossbow") then
                                stats.WeaponSkillType = "CROSSBOW"
                            elseif l:find("bogen") or l:find("bögen") or l:find("bow") then
                                stats.WeaponSkillType = "BOW"
                            elseif l:find("schusswaffe") or l:find("gewehr") or l:find("gun") then
                                stats.WeaponSkillType = "GUN"
                            elseif l:find("wurfwaffe") or l:find("thrown") then
                                stats.WeaponSkillType = "THROWN"
                            elseif l:find("zauberstab") or l:find("zauberstäbe") or l:find("wand") then
                                stats.WeaponSkillType = "WAND"
                            elseif l:find("faustwaffe") or l:find("fist") then
                                stats.WeaponSkillType = "FIST"
                            elseif l:find("stangenwaffe") or l:find("polearm") then
                                stats.WeaponSkillType = "POLEARM"
                            elseif l:find("stab") or l:find("stäbe") or l:find("staff") or l:find("staves") then
                                stats.WeaponSkillType = "STAFF"
                            elseif l:find("axt") or l:find("äxte") or l:find("axe") then
                                stats.WeaponSkillType = "AXE"
                            elseif l:find("schwert") or l:find("schwerter") or l:find("sword") then
                                stats.WeaponSkillType = "SWORD"
                            elseif l:find("dolch") or l:find("dolche") or l:find("dagger") then
                                stats.WeaponSkillType = "DAGGER"
                            elseif l:find("streitkolben") or l:find("kolben") or l:find("mace") then
                                stats.WeaponSkillType = "MACE"
                            elseif l:find("waffenfertigkeit") or l:find("weapon skill")
                                or l:find("waffenkunde") or l:find("expertise")
                                or l:find("alle waffen") or l:find("all weapon")
                            then
                                stats.WeaponSkillType = "ALL"
                            else
                                stats.WeaponSkillType = "UNKNOWN"
                            end
                            foundAnyStat = true
                        end
                    end

                    -- Flat Weapon Damage (e.g. reworked Edgemaster's Handguards "+1 Weapon Damage")
                    local fwdStr = l:match("waffenschaden.*um%s+([%d%.,]+)")
                                or l:match("%+?%s*([%d%.,]+)%s+waffenschaden")
                                or l:match("weapon damage.*by%s+([%d%.,]+)")
                                or l:match("%+?%s*([%d%.,]+)%s+weapon damage")
                    if fwdStr and not l:find("dps") and not l:find("schaden pro sekunde") then
                        local v = CleanNumber(fwdStr)
                        if not apiFoundStats.FlatWeaponDamage then
                            stats.FlatWeaponDamage = stats.FlatWeaponDamage + v
                        end
                        foundAnyStat = true
                    end

                    -- Spell Penetration / Spell Piercing
                    local spenStr = l:match("increases spell piercing by%s+([%d%.,]+)")
                                 or l:match("spells pierce%s+([%d%.,]+)%s+magical resistance")
                                 or l:match("%+?%s*([%d%.,]+)%s+spell piercing")
                                 or l:match("%+?%s*([%d%.,]+)%s+spell pierce")
                                 or l:match("erhöht die zauberdurchdringung um%s+([%d%.,]+)")
                                 or l:match("zauber durchdringen%s+([%d%.,]+)%s+magiewiderstand")
                                 or l:match("%+?%s*([%d%.,]+)%s+zauberdurchdringung")
                                 or l:match("increases spell penetration by%s+([%d%.,]+)")
                                 or l:match("%+?%s*([%d%.,]+)%s+spell penetration")
                                 or l:match("decreases the magical resistances.*by%s+([%d%.,]+)")
                                 or l:match("erhöht den zauberdurchschlag um%s+([%d%.,]+)")
                                 or l:match("%+?%s*([%d%.,]+)%s+zauberdurchschlag")
                                 or l:match("zauber ignorieren%s+([%d%.,]+)%s+punkte der magiewiderstände")
                    if spenStr then
                        local v = CleanNumber(spenStr)
                        if not apiFoundStats.SpellPenetration then
                            stats.SpellPenetration = stats.SpellPenetration + v
                        end
                        foundAnyStat = true
                    end

                    -- Spell Power & Healing Power (handle dual-value lines first, then universal SP, pure SP, pure Heal)
                    local matchedDualSPHeal = false
                    local dualHealStr, dualDmgStr = l:match("heilung[^%d]*um bis zu%s+([%d%.,]+).-schaden[^%d]*um bis zu%s+([%d%.,]+)")
                    if not dualHealStr then
                        dualDmgStr, dualHealStr = l:match("schaden[^%d]*um bis zu%s+([%d%.,]+).-heilung[^%d]*um bis zu%s+([%d%.,]+)")
                    end
                    if not dualHealStr then
                        dualHealStr, dualDmgStr = l:match("healing done[^%d]*by up to%s+([%d%.,]+).-damage done[^%d]*by up to%s+([%d%.,]+)")
                    end
                    if not dualHealStr then
                        dualDmgStr, dualHealStr = l:match("damage done[^%d]*by up to%s+([%d%.,]+).-healing done[^%d]*by up to%s+([%d%.,]+)")
                    end
                    if not dualHealStr then
                        dualHealStr, dualDmgStr = l:match("increases healing[^%d]*by up to%s+([%d%.,]+).-damage[^%d]*by up to%s+([%d%.,]+)")
                    end
                    if not dualHealStr then
                        dualDmgStr, dualHealStr = l:match("increases damage[^%d]*by up to%s+([%d%.,]+).-healing[^%d]*by up to%s+([%d%.,]+)")
                    end

                    if dualHealStr and dualDmgStr then
                        local hv = CleanNumber(dualHealStr)
                        local dv = CleanNumber(dualDmgStr)
                        if not apiFoundStats.HealingPower then
                            stats.HealingPower = stats.HealingPower + hv
                        end
                        if not apiFoundStats.SpellPower then
                            stats.SpellPower = stats.SpellPower + dv
                        end
                        if dv > 0 and dv == hv then
                            hasUniversalSP = true
                        end
                        matchedDualSPHeal = true
                        foundAnyStat = true
                    end

                    if not matchedDualSPHeal then
                        -- Universal Spell Power ("Increases spell power" / "damage and healing") OR pure spell damage.
                        -- Pure German healing lines without "schaden" must NEVER parse into SpellPower or set hasUniversalSP.
                        local isUniversalLine = false
                        local spStr = l:match("schaden und [^%d]*heilung um bis zu%s+([%d%.,]+)")
                                   or l:match("heilung und [^%d]*schaden um bis zu%s+([%d%.,]+)")
                                   or l:match("zauberschaden und heilung um bis zu%s+([%d%.,]+)")
                                   or l:match("zaubermacht.*um%s+([%d%.,]+)")
                                   or l:match("%+?%s*([%d%.,]+)%s+zaubermacht")
                                   or l:match("damage and healing done by magical spells.*by up to%s+([%d%.,]+)")
                                   or l:match("increases spell power by%s+([%d%.,]+)")
                                   or l:match("spell power.*by%s+([%d%.,]+)")
                                   or l:match("%+?%s*([%d%.,]+)%s+spell power")
                        if spStr then
                            isUniversalLine = true
                        else
                            spStr = l:match("magische zauber und effekte.*schaden.*um bis zu%s+([%d%.,]+)")
                                 or l:match("zauber und magische effekte.*schaden.*um bis zu%s+([%d%.,]+)")
                                 or l:match("^zauberschaden um bis zu%s+([%d%.,]+)")
                                 or l:match("[^a-zäöüß]zauberschaden um bis zu%s+([%d%.,]+)")
                                 or l:match("damage done by magical spells.*by up to%s+([%d%.,]+)")
                                 or l:match("damage done by up to%s+([%d%.,]+).*magical spells")
                        end
                        if spStr then
                            local v = CleanNumber(spStr)
                            if not apiFoundStats.SpellPower then
                                stats.SpellPower = stats.SpellPower + v
                            end
                            if isUniversalLine then
                                hasUniversalSP = true
                            end
                            foundAnyStat = true
                        end

                        -- Pure Healing Power (exclude universal "damage and healing" / "spell power" lines)
                        if not isUniversalLine and not l:find("damage and healing") and not l:find("schaden und heilung")
                           and not l:find("heilung und schaden") and not l:find("spell power") and not l:find("zaubermacht")
                        then
                            local healStr = l:match("heilzauber erzielte heilung um bis zu%s+([%d%.,]+)")
                                         or l:match("erzielte heilung um bis zu%s+([%d%.,]+)")
                                         or l:match("verursachte heilung um bis zu%s+([%d%.,]+)")
                                         or l:match("gewirkte heilung um bis zu%s+([%d%.,]+)")
                                         or (not l:find("schaden") and l:match("heilung[^%d]*um bis zu%s+([%d%.,]+)"))
                                         or l:match("%+?%s*([%d%.,]+)%s+heilung")
                                         or l:match("healing done by spells[^%d]*by up to%s+([%d%.,]+)")
                                         or l:match("healing done by up to%s+([%d%.,]+)")
                                         or l:match("increases healing[^%d]*by up to%s+([%d%.,]+)")
                                         or l:match("increases healing[^%d]*by%s+([%d%.,]+)")
                                         or l:match("%+?%s*([%d%.,]+)%s+healing spells")
                            if healStr then
                                local v = CleanNumber(healStr)
                                if not apiFoundStats.HealingPower then
                                    stats.HealingPower = stats.HealingPower + v
                                end
                                foundAnyStat = true
                            end
                        end
                    end

                    -- MP5 (Mana per 5 seconds)
                    local mp5Str = l:match("alle 5 sek%.?%s+([%d%.,]+)%s+mana")
                                or l:match("([%d%.,]+)%s+mana alle 5 sek")
                                or l:match("([%d%.,]+)%s+mana per 5 sec")
                                or l:match("([%d%.,]+)%s+mana every 5 sec")
                    if mp5Str then
                        local v = CleanNumber(mp5Str)
                        if not apiFoundStats.MP5 then
                            stats.MP5 = stats.MP5 + v
                        end
                        foundAnyStat = true
                    elseif not l:find("sek") and not l:find("sec") then
                        -- Flat Mana (+X Mana)
                        local manaStr = l:match("%+?%s*([%d%.,]+)%s+mana")
                                     or l:match("mana.*um%s+([%d%.,]+)")
                        if manaStr then
                            local v = CleanNumber(manaStr)
                            if not apiFoundStats.Mana then
                                stats.Mana = stats.Mana + v
                            end
                            foundAnyStat = true
                        end
                    end

                    -- HP5 (Health per 5 seconds)
                    local hp5Str = l:match("alle 5 sek%.?%s+([%d%.,]+)%s+gesundheit")
                                or l:match("gesundheit.*alle 5 sek%.?%s+([%d%.,]+)")
                                or l:match("([%d%.,]+)%s+gesundheit alle 5 sek")
                                or l:match("([%d%.,]+)%s+health per 5 sec")
                                or l:match("([%d%.,]+)%s+health every 5 sec")
                                or l:match("health.*per 5 sec.*([%d%.,]+)")
                                or l:match("restores ([%d%.,]+)%s+health")
                                or l:match("([%d%.,]+)%s+hp.*5%s*s")
                    if hp5Str then
                        local v = CleanNumber(hp5Str)
                        if not apiFoundStats.HP5 then
                            stats.HP5 = stats.HP5 + v
                        end
                        foundAnyStat = true
                    end

                    -- Arcane Spell Power
                    local arcStr = l:match("arkanzauber.*um bis zu%s+([%d%.,]+)")
                                or l:match("arcane spells.*by up to%s+([%d%.,]+)")
                                or l:match("%+?%s*([%d%.,]+)%s+arkanzauberschaden")
                                or l:match("%+?%s*([%d%.,]+)%s+arcane spell damage")
                                or l:match("%+?%s*([%d%.,]+)%s+arcane spell power")
                                or l:match("%+?%s*([%d%.,]+)%s+arcane damage")
                    if arcStr then
                        stats.ArcaneSpellPower = stats.ArcaneSpellPower + CleanNumber(arcStr)
                        foundAnyStat = true
                    end

                    -- Fire Spell Power
                    local fireStr = l:match("feuerzauber.*um bis zu%s+([%d%.,]+)")
                                 or l:match("fire spells.*by up to%s+([%d%.,]+)")
                                 or l:match("%+?%s*([%d%.,]+)%s+feuerzauberschaden")
                                 or l:match("%+?%s*([%d%.,]+)%s+feuermacht")
                                 or l:match("%+?%s*([%d%.,]+)%s+fire spell damage")
                                 or l:match("%+?%s*([%d%.,]+)%s+fire spell power")
                                 or l:match("%+?%s*([%d%.,]+)%s+fire damage")
                    if fireStr then
                        stats.FireSpellPower = stats.FireSpellPower + CleanNumber(fireStr)
                        foundAnyStat = true
                    end

                    -- Frost Spell Power
                    local frostStr = l:match("frostzauber.*um bis zu%s+([%d%.,]+)")
                                  or l:match("frost spells.*by up to%s+([%d%.,]+)")
                                  or l:match("%+?%s*([%d%.,]+)%s+frostzauberschaden")
                                  or l:match("%+?%s*([%d%.,]+)%s+frostmacht")
                                  or l:match("%+?%s*([%d%.,]+)%s+frost spell damage")
                                  or l:match("%+?%s*([%d%.,]+)%s+frost spell power")
                                  or l:match("%+?%s*([%d%.,]+)%s+frost damage")
                    if frostStr then
                        stats.FrostSpellPower = stats.FrostSpellPower + CleanNumber(frostStr)
                        foundAnyStat = true
                    end

                    -- Shadow Spell Power
                    local shadowStr = l:match("schattenzauber.*um bis zu%s+([%d%.,]+)")
                                   or l:match("shadow spells.*by up to%s+([%d%.,]+)")
                                   or l:match("%+?%s*([%d%.,]+)%s+schattenzauberschaden")
                                   or l:match("%+?%s*([%d%.,]+)%s+schattenmacht")
                                   or l:match("%+?%s*([%d%.,]+)%s+shadow spell damage")
                                   or l:match("%+?%s*([%d%.,]+)%s+shadow spell power")
                                   or l:match("%+?%s*([%d%.,]+)%s+shadow damage")
                    if shadowStr then
                        stats.ShadowSpellPower = stats.ShadowSpellPower + CleanNumber(shadowStr)
                        foundAnyStat = true
                    end

                    -- Nature Spell Power
                    local natStr = l:match("naturzauber.*um bis zu%s+([%d%.,]+)")
                                or l:match("nature spells.*by up to%s+([%d%.,]+)")
                                or l:match("%+?%s*([%d%.,]+)%s+naturzauberschaden")
                                or l:match("%+?%s*([%d%.,]+)%s+nature spell damage")
                                or l:match("%+?%s*([%d%.,]+)%s+nature spell power")
                                or l:match("%+?%s*([%d%.,]+)%s+nature damage")
                    if natStr then
                        stats.NatureSpellPower = stats.NatureSpellPower + CleanNumber(natStr)
                        foundAnyStat = true
                    end

                    -- Holy Spell Power
                    local holyStr = l:match("heiligzauber.*um bis zu%s+([%d%.,]+)")
                                 or l:match("holy spells.*by up to%s+([%d%.,]+)")
                                 or l:match("%+?%s*([%d%.,]+)%s+heiligzauberschaden")
                                 or l:match("%+?%s*([%d%.,]+)%s+holy spell damage")
                                 or l:match("%+?%s*([%d%.,]+)%s+holy spell power")
                                 or l:match("%+?%s*([%d%.,]+)%s+holy damage")
                    if holyStr then
                        stats.HolySpellPower = stats.HolySpellPower + CleanNumber(holyStr)
                        foundAnyStat = true
                    end

                    -- Resistances
                    local fr = l:match("%+?%s*([%d%.,]+)%s+feuerwiderstand") or l:match("%+?%s*([%d%.,]+)%s+fire resistance")
                    if fr then if not apiFoundStats.FireResist then stats.FireResist = stats.FireResist + CleanNumber(fr) end; foundAnyStat = true end

                    local nr = l:match("%+?%s*([%d%.,]+)%s+naturwiderstand") or l:match("%+?%s*([%d%.,]+)%s+nature resistance")
                    if nr then if not apiFoundStats.NatureResist then stats.NatureResist = stats.NatureResist + CleanNumber(nr) end; foundAnyStat = true end

                    local frost = l:match("%+?%s*([%d%.,]+)%s+frostwiderstand") or l:match("%+?%s*([%d%.,]+)%s+frost resistance")
                    if frost then if not apiFoundStats.FrostResist then stats.FrostResist = stats.FrostResist + CleanNumber(frost) end; foundAnyStat = true end

                    local sr = l:match("%+?%s*([%d%.,]+)%s+schattenwiderstand") or l:match("%+?%s*([%d%.,]+)%s+shadow resistance")
                    if sr then if not apiFoundStats.ShadowResist then stats.ShadowResist = stats.ShadowResist + CleanNumber(sr) end; foundAnyStat = true end

                    local ar = l:match("%+?%s*([%d%.,]+)%s+arkanwiderstand") or l:match("%+?%s*([%d%.,]+)%s+arcane resistance")
                    if ar then if not apiFoundStats.ArcaneResist then stats.ArcaneResist = stats.ArcaneResist + CleanNumber(ar) end; foundAnyStat = true end
                end
            end
        end
    end

    -- Apply converted rating API fallback only when tooltip parsing did not already find the stat
    for statKey, convertedVal in pairs(apiRatingFallback) do
        if (stats[statKey] or 0) == 0 and convertedVal > 0 then
            stats[statKey] = math.floor(convertedVal * 100 + 0.5) / 100
            foundAnyStat = true
        end
    end

    -- Cache guard: only cache when tooltip actually loaded lines OR API returned stats
    if numLines >= 2 or foundAnyStat then
        ParsedStatsCache[itemLink] = stats
        ParsedStatsMetaCache[itemLink] = { universalSP = hasUniversalSP }
    end
    return stats
end

function GSI_ItemScore:IsUniversalSpellPower(itemLink)
    if not itemLink then return false end
    if not ParsedStatsMetaCache[itemLink] then
        self:GetParsedStats(itemLink)
    end
    local meta = ParsedStatsMetaCache[itemLink]
    return (meta and meta.universalSP) == true
end

function GSI_ItemScore:ResetCache()
    ParsedStatsCache = {}
    ParsedStatsMetaCache = {}
    ScoreCache = {}
    WeaponInfoCache = {}
    ItemIDCache = {}
    PlayerTotalsCache = {}
    if GSI_TooltipCache and GSI_TooltipCache.Invalidate then
        GSI_TooltipCache:Invalidate()
    end
end

-- ============================================================
-- Safe Number Probe for Modern WoW Secret Values (11.0+, 12.0+)
-- Protects against secret numbers returned by protected combat APIs
-- ============================================================
local function probeArithmetic(val)
    return val + 0
end

local function GetSafeNumber(val, fallback)
    if type(val) ~= "number" then
        return fallback or 0
    end
    if type(issecretvalue) == "function" and issecretvalue(val) then
        return fallback or 0
    end
    local ok, result = pcall(probeArithmetic, val)
    if ok then
        return result
    end
    return fallback or 0
end

-- Sums equipped item & set bonus totals once per cache invalidation cycle
function GSI_ItemScore:GetEquippedGearTotals()
    if PlayerTotalsCache.gearTotals then
        return PlayerTotalsCache.gearTotals
    end

    local totals = { Hit = 0, Defense = 0, AvoidanceReduction = 0, WeaponSkill = 0 }
    if GetInventoryItemLink then
        for _, slotId in ipairs(EQUIP_SLOTS_ALL) do
            local link = GetInventoryItemLink("player", slotId)
            if link then
                local s = self:GetParsedStats(link)
                if s then
                    if type(s.Hit) == "number" then totals.Hit = totals.Hit + s.Hit end
                    if type(s.Defense) == "number" then totals.Defense = totals.Defense + s.Defense end
                    if type(s.AvoidanceReduction) == "number" then totals.AvoidanceReduction = totals.AvoidanceReduction + s.AvoidanceReduction end
                    if type(s.WeaponSkill) == "number" and s.WeaponSkillType ~= "UNKNOWN" then totals.WeaponSkill = totals.WeaponSkill + s.WeaponSkill end
                end
            end
        end
    end

    if GSI_SetBonus and GSI_SetBonus.GetActiveSetBonusStats then
        local ok, setStats = pcall(GSI_SetBonus.GetActiveSetBonusStats, GSI_SetBonus)
        if ok and type(setStats) == "table" then
            if type(setStats.Hit) == "number" then totals.Hit = totals.Hit + setStats.Hit end
            if type(setStats.Defense) == "number" then totals.Defense = totals.Defense + setStats.Defense end
            if type(setStats.AvoidanceReduction) == "number" then totals.AvoidanceReduction = totals.AvoidanceReduction + setStats.AvoidanceReduction end
            if type(setStats.WeaponSkill) == "number" then totals.WeaponSkill = totals.WeaponSkill + setStats.WeaponSkill end
        end
    end

    PlayerTotalsCache.gearTotals = totals
    return totals
end

function GSI_ItemScore:GetEquippedHit(role)
    return self:GetEquippedGearTotals().Hit or 0
end

-- Safely queries player defense skill (Forever 1.60.1 UnitDefenseSkill -> UnitDefense -> gear fallback)
function GSI_ItemScore:GetCurrentDefense()
    if PlayerTotalsCache.defense ~= nil then
        return PlayerTotalsCache.defense
    end

    local defVal = nil
    if type(UnitDefenseSkill) == "function" then
        local ok, bDef, aDef = pcall(UnitDefenseSkill, "player")
        if ok then
            local safeB = GetSafeNumber(bDef, nil)
            if safeB then
                defVal = safeB + GetSafeNumber(aDef, 0)
            end
        end
    end
    if not defVal and type(UnitDefense) == "function" then
        local ok, bDef, aDef = pcall(UnitDefense, "player")
        if ok then
            local safeB = GetSafeNumber(bDef, nil)
            if safeB then
                defVal = safeB + GetSafeNumber(aDef, 0)
            end
        end
    end
    if not defVal then
        defVal = 300 + (self:GetEquippedGearTotals().Defense or 0)
    end

    PlayerTotalsCache.defense = defVal
    return defVal
end

-- Safely queries player expertise / avoidance reduction % (Forever GetExpertisePercent -> GetExpertise -> gear fallback)
function GSI_ItemScore:GetCurrentAvoidanceReduction()
    if PlayerTotalsCache.avoidRed ~= nil then
        return PlayerTotalsCache.avoidRed, PlayerTotalsCache.avoidFromApi
    end

    local apiAvoid = nil
    if type(GetExpertisePercent) == "function" then
        local ok, expPct = pcall(GetExpertisePercent)
        if ok then
            local safePct = GetSafeNumber(expPct, nil)
            if safePct and safePct >= 0 and safePct <= 100 then
                apiAvoid = safePct
            end
        end
    end
    if apiAvoid == nil and type(GetExpertise) == "function" then
        local ok, mhExp = pcall(GetExpertise)
        if ok then
            local safeExp = GetSafeNumber(mhExp, nil)
            if safeExp and safeExp >= 0 and safeExp <= 100 then
                apiAvoid = safeExp
            end
        end
    end

    local gearAvoid = self:GetEquippedGearTotals().AvoidanceReduction or 0
    local avoidFromApi = (apiAvoid ~= nil)
    local val = avoidFromApi and apiAvoid or gearAvoid

    PlayerTotalsCache.avoidRed = val
    PlayerTotalsCache.avoidFromApi = avoidFromApi
    return val, avoidFromApi
end

-- Resolves current player Hit % safely without double-counting passive or wrong-school talents
local function GetEffectiveCurrentHit(self, class, specIndex, role, usesSpellHit)
    local specMeta = GSI_ClassicData and GSI_ClassicData.Classes and GSI_ClassicData.Classes[class]
        and GSI_ClassicData.Classes[class].specs and GSI_ClassicData.Classes[class].specs[specIndex]
    local isRangedSpec = (specMeta and specMeta.ranged == true)
        or (class == "HUNTER" and (specIndex == 1 or specIndex == 2))

    local apiHit = nil
    if usesSpellHit then
        if type(GetSpellHitModifier) == "function" then
            local ok, rawSpellHit = pcall(GetSpellHitModifier)
            if ok then
                apiHit = GetSafeNumber(rawSpellHit, nil)
            end
        end
        if apiHit ~= nil and CR_HIT_SPELL and type(GetCombatRatingBonus) == "function" then
            local ok, crBonus = pcall(GetCombatRatingBonus, CR_HIT_SPELL)
            if ok then
                apiHit = apiHit + GetSafeNumber(crBonus, 0)
            end
        end
    elseif isRangedSpec then
        if type(GetRangedHitModifier) == "function" then
            local ok, rawRangedHit = pcall(GetRangedHitModifier)
            if ok then
                apiHit = GetSafeNumber(rawRangedHit, nil)
            end
        end
        if apiHit == nil and type(GetHitModifier) == "function" then
            local ok, rawHit = pcall(GetHitModifier)
            if ok then
                apiHit = GetSafeNumber(rawHit, nil)
            end
        end
        if apiHit ~= nil and CR_HIT_RANGED and type(GetCombatRatingBonus) == "function" then
            local ok, crBonus = pcall(GetCombatRatingBonus, CR_HIT_RANGED)
            if ok then
                apiHit = apiHit + GetSafeNumber(crBonus, 0)
            end
        end
    else
        if type(GetHitModifier) == "function" then
            local ok, rawHit = pcall(GetHitModifier)
            if ok then
                apiHit = GetSafeNumber(rawHit, nil)
            end
        end
        if apiHit ~= nil and CR_HIT_MELEE and type(GetCombatRatingBonus) == "function" then
            local ok, crBonus = pcall(GetCombatRatingBonus, CR_HIT_MELEE)
            if ok then
                apiHit = apiHit + GetSafeNumber(crBonus, 0)
            end
        end
    end

    local equippedGearHit = self:GetEquippedHit(role) or 0
    local usedApiHit = (apiHit ~= nil)
    local baseHit = usedApiHit and apiHit or equippedGearHit

    local racialHit = 0
    if GSI_RaceBonus and GSI_RaceBonus.GetRacialHitBonus then
        racialHit = GetSafeNumber(GSI_RaceBonus:GetRacialHitBonus(), 0)
    end

    -- Separate passive universal Hit talents (reflected in GetHitModifier) from school-specific spell Hit talents
    local universalTalentHit = 0
    local schoolTalentHit = 0
    if GSI_TalentIntegration then
        if GSI_TalentIntegration.GetClassHitTalentBonus then
            local tHit = GetSafeNumber(GSI_TalentIntegration:GetClassHitTalentBonus(class, specIndex), 0)
            if tHit > 0 then
                if class == "SHAMAN" then
                    -- Tidal Focus grants universal Hit for both Melee (Enhancement) and Spell (Elemental/Resto)
                    universalTalentHit = tHit
                elseif class == "ROGUE" or class == "HUNTER" or class == "PALADIN" then
                    if not usesSpellHit then
                        universalTalentHit = tHit
                    end
                elseif usesSpellHit then
                    schoolTalentHit = tHit
                end
            end
            -- Holy Precision / Divine Precision apply strictly to Holy caster/healer evaluations, never Melee or Shadow
            if usesSpellHit and GSI_TalentIntegration.GetSchoolHitTalentBonus then
                if (class == "PALADIN" and specIndex == 1) or (class == "PRIEST" and specIndex ~= 3) then
                    local holyHit = GetSafeNumber(GSI_TalentIntegration:GetSchoolHitTalentBonus(class, specIndex, "Holy"), 0)
                    schoolTalentHit = schoolTalentHit + holyHit
                end
            end
        elseif GSI_TalentIntegration.GetTalentRankByPattern then
            if class == "ROGUE" and not usesSpellHit then
                local r = GSI_TalentIntegration:GetTalentRankByPattern("präzision") or GSI_TalentIntegration:GetTalentRankByPattern("precision") or 0
                universalTalentHit = math.min(r, 3) * 1.0
            elseif class == "HUNTER" and not usesSpellHit then
                local r = GSI_TalentIntegration:GetTalentRankByPattern("sicherer stand") or GSI_TalentIntegration:GetTalentRankByPattern("surefooted") or 0
                universalTalentHit = math.min(r, 3) * 1.0
            elseif class == "PALADIN" then
                if not usesSpellHit then
                    local rPrec = GSI_TalentIntegration:GetTalentRankByPattern("präzision") or GSI_TalentIntegration:GetTalentRankByPattern("precision") or 0
                    universalTalentHit = math.min(rPrec, 3) * 1.0
                elseif specIndex == 1 then
                    local rDiv = GSI_TalentIntegration:GetTalentRankByPattern("göttliche präzision") or GSI_TalentIntegration:GetTalentRankByPattern("divine precision") or 0
                    schoolTalentHit = math.min(rDiv, 2) * 4.0
                end
            elseif class == "WARLOCK" and usesSpellHit then
                local r = GSI_TalentIntegration:GetTalentRankByPattern("unterdrückung") or GSI_TalentIntegration:GetTalentRankByPattern("suppression") or 0
                schoolTalentHit = math.min(r, 5) * 1.0
            elseif class == "MAGE" and usesSpellHit then
                local r = GSI_TalentIntegration:GetTalentRankByPattern("präzision") or GSI_TalentIntegration:GetTalentRankByPattern("precision") or 0
                schoolTalentHit = math.min(r, 3) * 2.0
            elseif class == "PRIEST" and usesSpellHit then
                if specIndex == 3 then
                    local r = GSI_TalentIntegration:GetTalentRankByPattern("schattenfokus") or GSI_TalentIntegration:GetTalentRankByPattern("shadow focus") or 0
                    schoolTalentHit = math.min(r, 5) * 1.0
                else
                    local r = GSI_TalentIntegration:GetTalentRankByPattern("heilige präzision") or GSI_TalentIntegration:GetTalentRankByPattern("holy precision") or 0
                    schoolTalentHit = math.min(r, 3) * 6.0
                end
            elseif class == "SHAMAN" then
                local r = GSI_TalentIntegration:GetTalentRankByPattern("gezeitenfokus") or GSI_TalentIntegration:GetTalentRankByPattern("tidal focus") or 0
                universalTalentHit = math.min(r, 5) * 1.0
            elseif class == "DRUID" and specIndex == 1 and usesSpellHit then
                local r = GSI_TalentIntegration:GetTalentRankByPattern("reichweite der natur") or GSI_TalentIntegration:GetTalentRankByPattern("nature's reach") or 0
                schoolTalentHit = math.min(r, 2) * 2.0
            end
        end
    end

    local apiPassiveBonus = usedApiHit and math.max(0, baseHit - equippedGearHit) or 0
    local extraUniversal = usedApiHit and math.max(0, (universalTalentHit + racialHit) - apiPassiveBonus) or (universalTalentHit + racialHit)
    local remainingApiPassive = usedApiHit and math.max(0, apiPassiveBonus - (universalTalentHit + racialHit)) or 0
    local extraSchool = (usedApiHit and schoolTalentHit > 0 and remainingApiPassive >= schoolTalentHit) and 0 or schoolTalentHit

    return baseHit + extraUniversal + extraSchool
end

-- Non-recursive linear base score helper used only to choose which multi-slot (e.g. Ring 1 vs Ring 2) an unequipped bag item replaces
local function EstimateLinearSlotScore(self, itemLink, slotID, class, specIndex, role, weights)
    if not itemLink then return 0 end
    local _, _, _, _, _, _, _, _, equipLoc = GetItemInfo(itemLink)
    local sc = 0
    if equipLoc and self:IsWeapon(equipLoc) then
        local wInfo = self:GetWeaponInfo(itemLink)
        local dps = wInfo and wInfo.dps or 0
        if class == "DRUID" and (specIndex == 2 or specIndex == 3) then
            sc = sc + dps * (weights.WeaponDamage or (specIndex == 3 and 8.30 or 1.35))
        else
            local dpsWeight = weights.WeaponDamage or GSI_Config.WeaponDPSWeight or 14.0
            if (equipLoc == "INVTYPE_WEAPONOFFHAND" or slotID == INVSLOT_OFFHAND) and weights.WeaponDamageOH then
                dpsWeight = weights.WeaponDamageOH
            end
            sc = sc + dps * dpsWeight
        end
    end
    local st = self:GetParsedStats(itemLink)
    if st then
        local healToDmgFactor = (GSI_Config and GSI_Config.Rules_v2_2 and GSI_Config.Rules_v2_2.heal_to_damage and GSI_Config.Rules_v2_2.heal_to_damage.factor)
            or (GSI_Config and GSI_Config.Rules and GSI_Config.Rules.HealToDamageFactor)
            or (1 / 3)
        local healerDmgWeight = (GSI_Config and GSI_Config.Rules_v2_2 and GSI_Config.Rules_v2_2.healer_spell_damage_weight)
            or (GSI_Config and GSI_Config.Rules and GSI_Config.Rules.HealerSpellDamageWeight)
            or 0
        for stat, val in pairs(st) do
            if stat ~= "WeaponSkillType" and type(val) == "number" and val > 0 then
                local w = weights[stat] or 0
                if stat == "HealingPower" and role ~= "healer" then
                    if (st.SpellPower or 0) > 0 then
                        w = 0
                    elseif weights.HealingPower == nil and (weights.SpellPower or 0) > 0 then
                        w = (weights.SpellPower or 0) * healToDmgFactor
                    end
                elseif stat == "SpellPower" and role == "healer" then
                    local meta = ParsedStatsMetaCache[itemLink]
                    if meta and meta.universalSP and (st.HealingPower or 0) == 0 then
                        w = weights.HealingPower or weights.HEAL or 1.0
                    else
                        w = healerDmgWeight
                    end
                end
                sc = sc + (val * w)
            end
        end
    end
    return sc
end

-- Returns the Hit, Defense, AvoidanceReduction, and WeaponSkill currently contributed by the equipped slot(s) being replaced
local function GetReplacedCapStats(self, itemLink, equipLoc, targetSlotID, isEquipped, stats, class, specIndex, role, weights)
    if isEquipped then
        return stats.Hit or 0, stats.Defense or 0, stats.AvoidanceReduction or 0, stats.WeaponSkill or 0
    end

    if not GetInventoryItemLink then
        return 0, 0, 0, 0
    end

    local resolvedSlot = targetSlotID
    if not resolvedSlot then
        local slots = (GSI_ClassicData and GSI_ClassicData.GetEquipSlots and GSI_ClassicData:GetEquipSlots(equipLoc))
            or (GSI_ClassicData and GSI_ClassicData.EquipLocToSlots and GSI_ClassicData.EquipLocToSlots[equipLoc])
        if slots and #slots == 1 then
            resolvedSlot = slots[1]
        elseif slots and #slots > 1 then
            local bestSlot = slots[1]
            local bestScore = nil
            for _, sID in ipairs(slots) do
                local eqLink = GetInventoryItemLink("player", sID)
                if not eqLink then
                    bestSlot = sID
                    break
                end
                local eqSc = EstimateLinearSlotScore(self, eqLink, sID, class, specIndex, role, weights)
                if bestScore == nil or eqSc < bestScore then
                    bestScore = eqSc
                    bestSlot = sID
                end
            end
            resolvedSlot = bestSlot
        end
    end

    local repHit, repDef, repAvoid, repWpn = 0, 0, 0, 0
    if resolvedSlot then
        local eqLink = GetInventoryItemLink("player", resolvedSlot)
        if eqLink then
            local eqStats = self:GetParsedStats(eqLink)
            if eqStats then
                repHit = eqStats.Hit or 0
                repDef = eqStats.Defense or 0
                repAvoid = eqStats.AvoidanceReduction or 0
                repWpn = eqStats.WeaponSkill or 0
            end
        end
        -- Equipping a 2H weapon in Main Hand also unequips Off Hand
        if equipLoc == "INVTYPE_2HWEAPON" and resolvedSlot == INVSLOT_MAINHAND then
            local ohLink = GetInventoryItemLink("player", INVSLOT_OFFHAND)
            if ohLink then
                local ohStats = self:GetParsedStats(ohLink)
                if ohStats then
                    repHit = repHit + (ohStats.Hit or 0)
                    repDef = repDef + (ohStats.Defense or 0)
                    repAvoid = repAvoid + (ohStats.AvoidanceReduction or 0)
                    repWpn = repWpn + (ohStats.WeaponSkill or 0)
                end
            end
        end
    end

    return repHit, repDef, repAvoid, repWpn
end

-- ============================================================
-- MAIN SCORING FUNCTION (Score for 1 item)
-- ItemScore = Sum(Stat * Weight) with Marginal Cap Tiers
-- ============================================================
function GSI_ItemScore:Calculate(itemLink, overrideSpecIndex, overrideWeights, overrideMode, targetSlotID)
    if not itemLink or itemLink == "" then return 0 end

    local class = (GSI_ClassicData and GSI_ClassicData.GetPlayerClass and GSI_ClassicData:GetPlayerClass())
        or select(2, UnitClass("player")) or "WARRIOR"
    local activeSpec = GSI_StatWeights and GSI_StatWeights.GetActiveSpecIndex and GSI_StatWeights:GetActiveSpecIndex() or 1
    local specIndex = overrideSpecIndex or activeSpec

    local isTankSpec = (class == "WARRIOR" and specIndex == 3)
                    or (class == "PALADIN" and specIndex == 2)
                    or (class == "DRUID" and specIndex == 2)
    local modeKey = overrideMode
    if modeKey == "default" then modeKey = nil end
    if isTankSpec then
        if not modeKey or (modeKey ~= "Survival" and modeKey ~= "DMG" and modeKey ~= "Threat") then
            modeKey = (GearSetImproverDB and GearSetImproverDB.tankMode) or (GSI_Config and GSI_Config.TankMode) or "Survival"
        end
        if modeKey == "Threat" then modeKey = "DMG" end
    else
        modeKey = modeKey or (GearSetImproverDB and GearSetImproverDB.weightMode) or (GSI_Config and GSI_Config.WeightMode) or "ST"
    end

    local slotKey = targetSlotID or 0
    local cacheKey = itemLink .. ":" .. tostring(specIndex) .. ":" .. tostring(modeKey) .. ":" .. tostring(slotKey)
    if not overrideWeights and ScoreCache[cacheKey] then
        return ScoreCache[cacheKey]
    end

    -- 0. Only evaluate equippable gear
    local isEquip = (C_Item and C_Item.IsEquippableItem and C_Item.IsEquippableItem(itemLink))
    if isEquip == nil then
        isEquip = (_G.IsEquippableItem and _G.IsEquippableItem(itemLink))
    end
    if isEquip == false then
        if not overrideWeights then ScoreCache[cacheKey] = 0 end
        return 0
    end

    local itemName, _, _, itemLevel, _, _, itemSubType, _, equipLoc, _, _, wClassID, wSubClassID = GetItemInfo(itemLink)
    if not equipLoc or equipLoc == "" or type(equipLoc) ~= "string" then
        local _, _, _, instEquipLoc, _, instClassID, instSubClassID = GetItemInfoInstant(itemLink)
        equipLoc = instEquipLoc
        wClassID = wClassID or instClassID
        wSubClassID = wSubClassID or instSubClassID
    end

    if not itemName and (not equipLoc or equipLoc == "") then
        -- Warm tooltip cache while item metadata loads asynchronously
        EnsureScanTooltip()
        _scanTooltip:ClearLines()
        pcall(SetScanTooltipHyperlink, itemLink)
        return nil
    end

    if not equipLoc or type(equipLoc) ~= "string" or equipLoc == "" or equipLoc == "INVTYPE_NON_EQUIP" then
        if not overrideWeights then ScoreCache[cacheKey] = 0 end
        return 0
    end
    if not GSI_ClassicData or not GSI_ClassicData.EquipLocToSlot or not GSI_ClassicData.EquipLocToSlot[equipLoc] then
        if not overrideWeights then ScoreCache[cacheKey] = 0 end
        return 0
    end

    -- 1. Trinkets are excluded from item scoring
    if equipLoc == "INVTYPE_TRINKET" then
        if not overrideWeights then ScoreCache[cacheKey] = 0 end
        return 0
    end

    local weights = overrideWeights or GSI_StatWeights:GetWeights(specIndex, overrideMode)
    local role = GSI_StatWeights:GetRole(specIndex, overrideMode)
    local score = 0

    -- Special rule Cat / Bear (Forever v2): Shields and Off-Hand items = Score 0
    if class == "DRUID" and (specIndex == 2 or specIndex == 3) then
        if equipLoc == "INVTYPE_SHIELD" or equipLoc == "INVTYPE_HOLDABLE" or equipLoc == "INVTYPE_WEAPONOFFHAND" or targetSlotID == INVSLOT_OFFHAND then
            if not overrideWeights then ScoreCache[cacheKey] = 0 end
            return 0
        end
    end

    -- Special rule Shield-Tank specs (Protection Warrior / Protection Paladin): 1H + Shield only
    if IsShieldTankSpec(class, specIndex) then
        if equipLoc == "INVTYPE_2HWEAPON" or equipLoc == "INVTYPE_WEAPONOFFHAND" or equipLoc == "INVTYPE_HOLDABLE"
            or (targetSlotID == INVSLOT_OFFHAND and equipLoc ~= "INVTYPE_SHIELD") then
            if not overrideWeights then ScoreCache[cacheKey] = 0 end
            return 0
        end
    end

    -- 2. Weapons & Ranged (Druid Cat/Bear receive normalized weapon DPS)
    local isWand = false
    if equipLoc == "INVTYPE_RANGED" or equipLoc == "INVTYPE_RANGEDRIGHT" then
        if itemSubType then
            local subLower = itemSubType:lower()
            if subLower:find("wand") or subLower:find("zauberstab") then
                isWand = true
            end
        end
    end

    local specMeta = GSI_ClassicData and GSI_ClassicData.Classes and GSI_ClassicData.Classes[class]
        and GSI_ClassicData.Classes[class].specs and GSI_ClassicData.Classes[class].specs[specIndex]
    local isCasterDPS = (role == "healer")
        or (specMeta and specMeta.caster == true)
        or (class == "MAGE" or class == "WARLOCK")
        or (class == "PRIEST" and specIndex == 3)
        or (class == "SHAMAN" and specIndex == 1)
        or (class == "DRUID" and specIndex == 1)

    if self:IsWeapon(equipLoc) then
        local wInfo = self:GetWeaponInfo(itemLink)
        local dps = wInfo.dps or 0
        local isOffHand = (equipLoc == "INVTYPE_WEAPONOFFHAND" or targetSlotID == INVSLOT_OFFHAND)

        if class == "DRUID" and (specIndex == 2 or specIndex == 3) then
            local dpsWeight = weights.WeaponDamage or (specIndex == 3 and 8.30 or 1.35)
            score = score + (dps * dpsWeight)
        else
            local wSpeed = wInfo and wInfo.speed
            local wSpeedWeight = weights.WeaponSpeed or 0
            if wSpeed and wSpeedWeight ~= 0 and not isOffHand then
                score = score + (wSpeed * wSpeedWeight)
            end

            if isCasterDPS then
                -- Casters and healers use melee weapons primarily as stat sticks
                score = score + (dps * 0.5)
            elseif class == "HUNTER" and (specIndex == 1 or specIndex == 2) then
                -- BM/MM Hunters use melee weapons primarily as stat sticks
                local dpsWeight = weights.WeaponDamage or 0.5
                score = score + (dps * dpsWeight)
            else
                -- Physical melee specs (Warrior, Rogue, Enhancement, Retribution, Survival Hunter)
                local speed = wInfo.speed or 2.0
                local speedMultiplier = 1.0
                if not isOffHand and not IsShieldTankSpec(class, specIndex) then
                    if speed >= 3.3 then speedMultiplier = 1.15
                    elseif speed >= 2.6 then speedMultiplier = 1.08
                    elseif speed <= 1.8 and not (class == "ROGUE" and (specIndex == 1 or specIndex == 3)) then speedMultiplier = 0.95 end
                end

                local dpsWeight = weights.WeaponDamage or GSI_Config.WeaponDPSWeight
                -- Supports dedicated Off-Hand weapons and 1H weapons evaluated in Off-Hand (Slot 17)
                if isOffHand then
                    if weights.WeaponDamageOH and weights.WeaponDamageOH > 0 then
                        dpsWeight = weights.WeaponDamageOH
                    elseif GSI_ClassicData and GSI_ClassicData.CanDualWield and GSI_ClassicData:CanDualWield() then
                        dpsWeight = dpsWeight * 0.5
                    end
                end
                score = score + (dps * dpsWeight * speedMultiplier)
            end
        end

        -- v2.2: Racial weapon crit bonus (if supported by RaceBonus module)
        if wClassID == 2 and GSI_RaceBonus and GSI_RaceBonus.GetWeaponCritBonus then
            local raceCritBonus = GSI_RaceBonus:GetWeaponCritBonus(wSubClassID)
            if raceCritBonus and raceCritBonus > 0 then
                local critWeight = weights.Crit or 0
                score = score + (raceCritBonus * critWeight)
            end
        end
    elseif self:IsRanged(equipLoc) then
        local wInfo = self:GetWeaponInfo(itemLink)
        local dps = wInfo.dps or 0
        local wSpeed = wInfo and wInfo.speed
        local wSpeedWeight = weights.WeaponSpeed or 0
        if wSpeed and wSpeedWeight ~= 0 then
            score = score + (wSpeed * wSpeedWeight)
        end
        if class == "HUNTER" then
            local rWeight = weights.RangedDPS or weights.WeaponDamage or GSI_Config.RangedDPSWeight
            score = score + (dps * rWeight)
        elseif weights.RangedDPS and weights.RangedDPS > 0 then
            score = score + (dps * weights.RangedDPS)
        end
    end

    -- 3. Base stats: Linear sum + marginal cap tier calculation
    local stats = self:GetParsedStats(itemLink)
    local spMeta = ParsedStatsMetaCache[itemLink]
    local isUniversalSP = spMeta and spMeta.universalSP == true
    local healerDmgWeight = (GSI_Config and GSI_Config.Rules_v2_2 and GSI_Config.Rules_v2_2.healer_spell_damage_weight)
        or (GSI_Config and GSI_Config.Rules and GSI_Config.Rules.HealerSpellDamageWeight)
        or 0
    local healToDmgFactor = (GSI_Config and GSI_Config.Rules_v2_2 and GSI_Config.Rules_v2_2.heal_to_damage and GSI_Config.Rules_v2_2.heal_to_damage.factor)
        or (GSI_Config and GSI_Config.Rules and GSI_Config.Rules.HealToDamageFactor)
        or (1 / 3)

    local hasAnyStat = false
    local isEquipped = IsItemCurrentlyEquipped(itemLink, targetSlotID)

    -- Fetch v2.2 profile for marginal cap tiers (HIT, DEFENSE, AVOID_RED, WEAPON_SKILL)
    local v22Profile = (GSI_Config and GSI_Config.GetProfileV22 and GSI_Config:GetProfileV22(class, specIndex, modeKey))
                    or (GSI_Config and GSI_Config.GetProfile and GSI_Config:GetProfile(class, specIndex, modeKey))
    local caps = v22Profile and v22Profile.caps

    local usesSpellHit = isCasterDPS or (caps and caps.SPELL_HIT ~= nil and caps.HIT == nil)
    local currentHit = nil
    local repHit, repDef, repAvoid, repWpn = nil, nil, nil, nil

    for stat, val in pairs(stats) do
        if stat ~= "WeaponSkillType" and type(val) == "number" and val > 0 then
            hasAnyStat = true
            local w = weights[stat] or 0

            -- Special rule: Heal-to-Damage (1/3) for non-healers vs Healer Spell Power routing
            if stat == "HealingPower" and role ~= "healer" then
                if (stats.SpellPower or 0) > 0 then
                    -- Never double-count HealingPower on items that already carry SpellPower
                    -- (covers both universal SP==Heal and Forever dual-heal items like +16 Heal / +6 Dmg)
                    w = 0
                elseif weights.HealingPower == nil and (weights.SpellPower or 0) > 0 then
                    w = (weights.SpellPower or 0) * healToDmgFactor
                end
            elseif stat == "SpellPower" and role == "healer" then
                if isUniversalSP and (stats.HealingPower or 0) == 0 then
                    -- Route universal "Increases spell power" cleanly to HealingPower
                    w = weights.HealingPower or weights.HEAL or 1.0
                else
                    -- Pure spell damage or dual-stat item already carrying HealingPower uses healer_spell_damage_weight (0)
                    w = healerDmgWeight
                end
            end

            -- Feral Attack Power fallback to AttackPower
            if stat == "FeralAttackPower" and w == 0 then
                if class == "DRUID" and (specIndex == 2 or specIndex == 3) then
                    w = weights.AttackPower or 0.5
                end
            end

            -- Weapon Skill matching against evaluated weapon itself or currently equipped weapon subclass (Ranged for ranged skills, MH/OH for melee)
            if stat == "WeaponSkill" and stats.WeaponSkillType and stats.WeaponSkillType ~= "ALL" then
                local subMap = WEAPON_SKILL_SUBCLASS[stats.WeaponSkillType]
                local matchesWpn = false
                if subMap then
                    if wClassID == 2 and wSubClassID and subMap[wSubClassID] then
                        matchesWpn = true
                    elseif RANGED_WEAPON_SKILL_TYPES[stats.WeaponSkillType] then
                        local rLink = GetInventoryItemLink("player", INVSLOT_RANGED)
                        if rLink then
                            local _, _, _, _, _, _, _, _, _, _, _, rClassID, rSubClassID = GetItemInfo(rLink)
                            if not rClassID then
                                _, _, _, _, _, rClassID, rSubClassID = GetItemInfoInstant(rLink)
                            end
                            if rClassID == 2 and subMap[rSubClassID] then
                                matchesWpn = true
                            end
                        elseif class == "HUNTER" then
                            matchesWpn = true
                        end
                    else
                        local mhLink = GetInventoryItemLink("player", INVSLOT_MAINHAND)
                        local ohLink = GetInventoryItemLink("player", INVSLOT_OFFHAND)
                        if mhLink or ohLink then
                            if mhLink then
                                local _, _, _, _, _, _, _, _, _, _, _, mhClassID, mhSubClassID = GetItemInfo(mhLink)
                                if not mhClassID then
                                    _, _, _, _, _, mhClassID, mhSubClassID = GetItemInfoInstant(mhLink)
                                end
                                if mhClassID == 2 and subMap[mhSubClassID] then
                                    matchesWpn = true
                                end
                            end
                            if not matchesWpn and ohLink then
                                local _, _, _, _, _, _, _, _, _, _, _, ohClassID, ohSubClassID = GetItemInfo(ohLink)
                                if not ohClassID then
                                    _, _, _, _, _, ohClassID, ohSubClassID = GetItemInfoInstant(ohLink)
                                end
                                if ohClassID == 2 and subMap[ohSubClassID] then
                                    matchesWpn = true
                                end
                            end
                        else
                            matchesWpn = true
                        end
                    end
                end
                if not matchesWpn then
                    w = 0
                end
            end

            -- Compute replaced slot contributions lazily only when evaluating a capped stat
            if (stat == "Hit" or stat == "Defense" or stat == "AvoidanceReduction" or stat == "WeaponSkill") and repHit == nil then
                repHit, repDef, repAvoid, repWpn = GetReplacedCapStats(
                    self, itemLink, equipLoc, targetSlotID, isEquipped, stats, class, specIndex, role, weights
                )
            end

            -- Flat Weapon Damage (e.g. Edgemaster's Handguards +1 Weapon Damage)
            if stat == "FlatWeaponDamage" then
                local mhDPSWeight = weights.WeaponDamage or 7.0
                local fScore = (val / 2.6) * mhDPSWeight
                if weights.WeaponDamageOH and weights.WeaponDamageOH > 0 then
                    fScore = fScore + ((val / 1.8) * weights.WeaponDamageOH * 0.5)
                end
                score = score + fScore

            -- Marginal Weapon Skill calculation (Soft-Cap 305/308; skip when w == 0 for non-matching weapon types)
            elseif stat == "WeaponSkill" and w > 0 and caps and caps.WEAPON_SKILL then
                local wpnCap = caps.WEAPON_SKILL.cap_total_pct or caps.WEAPON_SKILL.cap_total or 308
                local raceSkill = 0
                if GSI_RaceBonus and GSI_RaceBonus.GetWeaponSkillBonus then
                    raceSkill = GetSafeNumber(GSI_RaceBonus:GetWeaponSkillBonus(stats.WeaponSkillType), 0)
                end
                local gearSkill = self:GetEquippedGearTotals().WeaponSkill or 0
                local startSkill = 300 + raceSkill + math.max(0, gearSkill - (repWpn or 0))
                local endSkill = startSkill + val
                local wpnScore = 0

                if caps.WEAPON_SKILL.tiers and #caps.WEAPON_SKILL.tiers > 0 then
                    local maxTierTo = 0
                    for _, tier in ipairs(caps.WEAPON_SKILL.tiers) do
                        local tFrom = tier.from_pct or 300
                        local tTo = tier.to_pct or 308
                        local tWeight = tier.w or w
                        if tTo > maxTierTo and tTo < 900 then maxTierTo = tTo end
                        if endSkill > tFrom and startSkill < tTo then
                            local segStart = math.max(startSkill, tFrom)
                            local segEnd = math.min(endSkill, tTo)
                            if segEnd > segStart then
                                wpnScore = wpnScore + (segEnd - segStart) * tWeight
                            end
                        end
                    end
                    if endSkill > maxTierTo and maxTierTo > 0 then
                        local rem = endSkill - math.max(startSkill, maxTierTo)
                        local aboveW = caps.WEAPON_SKILL.above_w or 0.5
                        wpnScore = wpnScore + rem * aboveW
                    end
                else
                    local chunkUnder = math.max(0, math.min(endSkill, wpnCap) - startSkill)
                    local aboveW = caps.WEAPON_SKILL.above_w or 0.5
                    local chunkAbove = math.max(0, endSkill - math.max(startSkill, wpnCap))
                    wpnScore = (chunkUnder * w) + (chunkAbove * aboveW)
                end
                score = score + wpnScore

            -- Marginal Tiered Hit calculation (Melee, Ranged & Caster Spell Hit without clobbering 10% AoE caps)
            elseif stat == "Hit" and caps and (caps.HIT or caps.SPELL_HIT) then
                if currentHit == nil then
                    currentHit = GetEffectiveCurrentHit(self, class, specIndex, role, usesSpellHit)
                end
                local hitCapCfg = caps.HIT or caps.SPELL_HIT
                local isAoEProfile = (v22Profile and v22Profile.isAoEProfile) or (modeKey == "AOE")
                local capThreshold = hitCapCfg.cap_total_pct or hitCapCfg.cap_total
                if not capThreshold then
                    capThreshold = usesSpellHit and ((GSI_Config and GSI_Config.Caps and GSI_Config.Caps.SpellHitCap) or 16)
                        or ((GSI_Config and GSI_Config.Caps and GSI_Config.Caps.MeleeHitCap) or 9)
                elseif usesSpellHit and not isAoEProfile and capThreshold >= 16 and GSI_Config and GSI_Config.Caps and GSI_Config.Caps.SpellHitCap then
                    capThreshold = GSI_Config.Caps.SpellHitCap
                end

                local startPct = math.max(0, currentHit - (repHit or 0))
                local endPct = startPct + val
                local tierScore = 0

                if hitCapCfg.tiers and #hitCapCfg.tiers > 0 then
                    local maxTierTo = 0
                    for _, tier in ipairs(hitCapCfg.tiers) do
                        local tFrom = tier.from_pct or 0
                        local tTo = tier.to_pct or 999
                        local tWeight = tier.w or 0
                        if tTo > maxTierTo and tTo < 900 then maxTierTo = tTo end
                        if endPct > tFrom and startPct < tTo then
                            local segStart = math.max(startPct, tFrom)
                            local segEnd = math.min(endPct, tTo)
                            if segEnd > segStart then
                                tierScore = tierScore + (segEnd - segStart) * tWeight
                            end
                        end
                    end
                    if endPct > maxTierTo and maxTierTo > 0 then
                        local rem = endPct - math.max(startPct, maxTierTo)
                        local aboveW = hitCapCfg.above_w or 0
                        tierScore = tierScore + rem * aboveW
                    end
                else
                    if startPct < capThreshold then
                        local chunkUnder = math.min(endPct, capThreshold) - startPct
                        tierScore = tierScore + chunkUnder * w
                    end
                    if endPct > capThreshold then
                        local currentStart = math.max(startPct, capThreshold)
                        local remaining = endPct - currentStart
                        local aboveW = hitCapCfg.above_w or 0
                        tierScore = tierScore + remaining * aboveW
                    end
                end
                score = score + tierScore

            -- Marginal Tiered Defense calculation (440 Crit Immunity Cap)
            elseif stat == "Defense" and caps and caps.DEFENSE then
                local baseDef = self:GetCurrentDefense()
                local startDef = math.max(300, baseDef - (repDef or 0))
                local endDef = startDef + val
                local defScore = 0

                if caps.DEFENSE.tiers and #caps.DEFENSE.tiers > 0 then
                    local maxDefTo = 0
                    for _, tier in ipairs(caps.DEFENSE.tiers) do
                        local tFrom = tier.from_pct or 300
                        local tTo = tier.to_pct or 440
                        local tWeight = tier.w or w
                        if tTo > maxDefTo and tTo < 900 then maxDefTo = tTo end
                        if endDef > tFrom and startDef < tTo then
                            local segStart = math.max(startDef, tFrom)
                            local segEnd = math.min(endDef, tTo)
                            if segEnd > segStart then
                                defScore = defScore + (segEnd - segStart) * tWeight
                            end
                        end
                    end
                    if endDef > maxDefTo and maxDefTo > 0 then
                        local rem = endDef - math.max(startDef, maxDefTo)
                        local aboveW = caps.DEFENSE.above_w or 0.5
                        defScore = defScore + rem * aboveW
                    end
                else
                    local capVal = caps.DEFENSE.cap_total_pct or caps.DEFENSE.cap_total
                        or (GSI_Config and GSI_Config.Caps and GSI_Config.Caps.TankDefenseCap) or 440
                    local chunkUnder = math.max(0, math.min(endDef, capVal) - startDef)
                    local aboveW = caps.DEFENSE.above_w or 0.5
                    local chunkAbove = math.max(0, endDef - math.max(startDef, capVal))
                    defScore = (chunkUnder * w) + (chunkAbove * aboveW)
                end
                score = score + defScore

            -- Marginal Avoidance Reduction calculation (Boss Dodge 5.6% Cap)
            elseif stat == "AvoidanceReduction" and caps and caps.AVOID_RED then
                local avoidCap = caps.AVOID_RED.cap_total_pct or caps.AVOID_RED.cap_total
                    or (GSI_Config and GSI_Config.Caps and GSI_Config.Caps.AvoidanceReductionCap) or 5.6
                local rogueTalentAvoid = 0
                if class == "ROGUE" and GSI_TalentIntegration and GSI_TalentIntegration.GetRogueWeaponExpertiseReduction then
                    rogueTalentAvoid = GetSafeNumber(GSI_TalentIntegration:GetRogueWeaponExpertiseReduction(), 0)
                end

                local currentAvoid = nil
                local avoidFromApi = false
                local usedSwNoTalents = false
                if GSI_StatWeights and GSI_StatWeights.GetCurrentAvoidanceReduction then
                    local ok, swAvoid = pcall(GSI_StatWeights.GetCurrentAvoidanceReduction, GSI_StatWeights, false)
                    if ok then
                        currentAvoid = GetSafeNumber(swAvoid, nil)
                        if currentAvoid ~= nil then
                            avoidFromApi = true
                            usedSwNoTalents = true
                        end
                    end
                end
                if currentAvoid == nil then
                    currentAvoid, avoidFromApi = self:GetCurrentAvoidanceReduction()
                end

                local extraTalentAvoid = rogueTalentAvoid
                if not usedSwNoTalents and avoidFromApi and rogueTalentAvoid > 0 then
                    local gearAvoid = self:GetEquippedGearTotals().AvoidanceReduction or 0
                    local apiNonGearAvoid = math.max(0, currentAvoid - gearAvoid)
                    extraTalentAvoid = math.max(0, rogueTalentAvoid - apiNonGearAvoid)
                end

                local effectiveCap = math.max(0, avoidCap - extraTalentAvoid)
                local startAvoid = math.max(0, (currentAvoid or 0) - (repAvoid or 0))
                local endAvoid = startAvoid + val
                local chunkUnder = math.max(0, math.min(endAvoid, effectiveCap) - startAvoid)
                local aboveW = caps.AVOID_RED.above_w or 0
                local chunkAbove = math.max(0, endAvoid - math.max(startAvoid, effectiveCap))
                score = score + (chunkUnder * w) + (chunkAbove * aboveW)
            else
                score = score + (val * w)
            end
        end
    end

    -- Statless armor fallback (only if item has Armor and is not Weapon/Ranged/Holdable)
    if not hasAnyStat and not self:IsWeapon(equipLoc) and not self:IsRanged(equipLoc) and equipLoc ~= "INVTYPE_HOLDABLE" and (stats.Armor and stats.Armor > 0) then
        score = (itemLevel or 1) * (GSI_Config.IlvlScoreFactor or 0.5)
    end

    -- 4. Enchants, Sockets, and Set Bonuses
    local ignoreEnchants = GearSetImproverDB and GearSetImproverDB.ignoreEnchants
    if ignoreEnchants == nil then
        ignoreEnchants = (GSI_Config and GSI_Config.IgnoreEnchants ~= false)
    end
    if not ignoreEnchants then
        score = score + (GSI_EnchantBonus:GetEnchantScore(itemLink, specIndex, overrideMode) or 0)
    end
    score = score + (GSI_SocketBonus:GetSocketScore(itemLink) or 0)
    score = score + (GSI_SetBonus:GetSetBonusScore(itemLink, weights, role) or 0)

    -- 5. Overrides (Procs, On-Use & Situational effects; guard against flat-stat double counting)
    if GSI_Overrides and GSI_Overrides.GetOverride then
        local overrideScore, overrideReason, _, isSituational, _, isFlatStat = GSI_Overrides:GetOverride(itemLink, class, nil, not hasAnyStat, specIndex)
        if overrideScore and overrideScore > 0 then
            local skipFlat = isFlatStat or (hasAnyStat and not isSituational and type(overrideReason) == "string" and overrideReason:sub(1, 6) == "Equip:")
            if not skipFlat then
                score = score + overrideScore
            end
        end
    end

    -- 6. Active Resistance Priorities
    local reqResists = GearSetImproverDB and GearSetImproverDB.requiredResists
    if reqResists then
        local resistPriorityWeight = (GearSetImproverDB and GearSetImproverDB.resistPriorityWeight) or 5.0
        for elem, sKey in pairs(RESIST_MAP) do
            if reqResists[elem] and stats[sKey] and stats[sKey] > 0 then
                local baseW = weights[sKey] or 0
                local effectiveW = math.max(baseW, resistPriorityWeight)
                local extraW = effectiveW - baseW
                if extraW > 0 then
                    score = score + (stats[sKey] * extraW)
                end
            end
        end
    end

    -- Round to 2 decimals for clean score comparisons
    local finalScore = math.floor(score * 100 + 0.5) / 100

    -- Only cache once itemName or tooltip lines are available
    EnsureScanTooltip()
    if not overrideWeights and (itemName or (_scanTooltip:NumLines() >= 2)) then
        ScoreCache[cacheKey] = finalScore
    end
    return finalScore
end

-- Backward compatibility alias
GSI_ItemScore.CalculateItemScore = GSI_ItemScore.Calculate
