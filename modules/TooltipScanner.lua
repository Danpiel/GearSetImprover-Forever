-- ============================================================
-- GearSetImprover - TooltipScanner.lua (WoW Forever 1.60.1)
-- EN/DE/RU tooltip stat & weapon DPS/speed parser.
-- ============================================================

GSI_TooltipScanner = GSI_TooltipScanner or {}
-- ============================================================
-- GearSetImprover - ItemScore.lua (WoW Forever)
-- Core equipment scoring engine for WoW Forever.
-- Implements equivalency-point formulas and tiered caps (v2.2).
-- ============================================================

GSI_ItemScore = GSI_ItemScore or {}

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
                local l = LowerUTF8(line)
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


-- Expose scanner API on GSI_TooltipScanner
GSI_TooltipScanner.GetWeaponInfo = function(self, itemLink) return GSI_ItemScore:GetWeaponInfo(itemLink) end
GSI_TooltipScanner.GetParsedStats = function(self, itemLink) return GSI_ItemScore:GetParsedStats(itemLink) end
GSI_TooltipScanner.IsUniversalSpellPower = function(self, itemLink) return GSI_ItemScore:IsUniversalSpellPower(itemLink) end
GSI_TooltipScanner.IsItemCurrentlyEquipped = IsItemCurrentlyEquipped

function GSI_TooltipScanner:ResetCache()
    ParsedStatsCache = {}
    ParsedStatsMetaCache = {}
    WeaponInfoCache = {}
    ItemIDCache = {}
end

function GSI_TooltipScanner:WarmTooltip(itemLink)
    EnsureScanTooltip()
    _scanTooltip:ClearLines()
    pcall(SetScanTooltipHyperlink, itemLink)
end

function GSI_TooltipScanner:HasTooltipLines()
    EnsureScanTooltip()
    return (_scanTooltip:NumLines() or 0) >= 2
end
