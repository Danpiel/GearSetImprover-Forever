-- ============================================================
-- GearSetImprover - ItemScore.lua (WoW Forever 1.60.1)
-- Item EP scoring engine (uses GSI_TooltipScanner & GSI_CapMath).
-- ============================================================

GSI_ItemScore = GSI_ItemScore or {}

local INVSLOT_MAINHAND = _G.INVSLOT_MAINHAND or 16
local INVSLOT_OFFHAND  = _G.INVSLOT_OFFHAND or 17
local INVSLOT_RANGED   = _G.INVSLOT_RANGED or 18

local GetItemInfo = (C_Item and C_Item.GetItemInfo) or _G.GetItemInfo or function() return nil end
local GetItemInfoInstant = (C_Item and C_Item.GetItemInfoInstant) or _G.GetItemInfoInstant or function() return nil end

local EQUIP_SLOTS_ALL = { 1, 2, 3, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18 }
local RESIST_MAP = {
    Fire = "FireResist",
    Nature = "NatureResist",
    Frost = "FrostResist",
    Shadow = "ShadowResist",
    Arcane = "ArcaneResist",
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

local function IsShieldTankSpec(class, specIndex)
    return (class == "WARRIOR" and specIndex == 3) or (class == "PALADIN" and specIndex == 2)
end

local ScoreCache = {}
local PlayerTotalsCache = {}

local function IsItemCurrentlyEquipped(itemLink, targetSlotID)
    if GSI_TooltipScanner and GSI_TooltipScanner.IsItemCurrentlyEquipped then
        return GSI_TooltipScanner.IsItemCurrentlyEquipped(itemLink, targetSlotID)
    end
    return false
end

function GSI_ItemScore:ResetCache()
    ScoreCache = {}
    PlayerTotalsCache = {}
    if GSI_TooltipScanner and GSI_TooltipScanner.ResetCache then
        GSI_TooltipScanner:ResetCache()
    end
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
                    if self:IsUniversalSpellPower(itemLink) and (st.HealingPower or 0) == 0 then
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
    local itemName, _, _, itemLevel, _, _, itemSubType, _, equipLoc, _, _, wClassID, wSubClassID = GetItemInfo(itemLink)
    if not equipLoc or equipLoc == "" or type(equipLoc) ~= "string" then
        local _, _, _, instEquipLoc, _, instClassID, instSubClassID = GetItemInfoInstant(itemLink)
        equipLoc = instEquipLoc
        wClassID = wClassID or instClassID
        wSubClassID = wSubClassID or instSubClassID
    end

    if not itemName then
        -- Warm item data & tooltip cache while item metadata loads asynchronously (never cache 0!)
        local itemID = tonumber(itemLink:match("item:(%d+)")) or select(1, GetItemInfoInstant(itemLink))
        if itemID and C_Item and C_Item.RequestLoadItemDataByID then
            pcall(C_Item.RequestLoadItemDataByID, itemID)
        end
        if GSI_TooltipScanner and GSI_TooltipScanner.WarmTooltip then
            GSI_TooltipScanner:WarmTooltip(itemLink)
        end
        return nil
    end

    if not equipLoc or type(equipLoc) ~= "string" or equipLoc == "" then
        local isEquip = (C_Item and C_Item.IsEquippableItem and C_Item.IsEquippableItem(itemLink))
        if isEquip == nil then
            isEquip = (_G.IsEquippableItem and _G.IsEquippableItem(itemLink))
        end
        if isEquip == false then
            if not overrideWeights then ScoreCache[cacheKey] = 0 end
            return 0
        end
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

    local weights = overrideWeights or GSI_StatWeights:GetWeightsReadOnly(specIndex, overrideMode)
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
    local isUniversalSP = self:IsUniversalSpellPower(itemLink)
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
    if not ignoreEnchants and GSI_EnchantBonus and GSI_EnchantBonus.GetEnchantScore then
        score = score + (GSI_EnchantBonus:GetEnchantScore(itemLink, specIndex, overrideMode) or 0)
    end
    if GSI_SocketBonus and GSI_SocketBonus.GetSocketScore then
        score = score + (GSI_SocketBonus:GetSocketScore(itemLink) or 0)
    end
    if GSI_SetBonus and GSI_SetBonus.GetSetBonusScore then
        score = score + (GSI_SetBonus:GetSetBonusScore(itemLink, weights, role) or 0)
    end

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
    if not overrideWeights and (itemName or (GSI_TooltipScanner and GSI_TooltipScanner.HasTooltipLines and GSI_TooltipScanner:HasTooltipLines())) then
        ScoreCache[cacheKey] = finalScore
    end
    return finalScore
end

-- Backward compatibility alias
GSI_ItemScore.CalculateItemScore = GSI_ItemScore.Calculate
