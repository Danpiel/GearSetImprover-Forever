-- ============================================================
-- GearSetImprover - CapMath.lua (WoW Forever 1.60.1)
-- Shared piecewise cap evaluation, weapon skill matching,
-- and effective stat weight helpers for ItemScore & OptimizationEngine.
-- ============================================================

GSI_CapMath = GSI_CapMath or {}

local math_max = math.max
local math_min = math.min

function GSI_CapMath:EvaluateCapRange(startVal, endVal, capCfg, baseWeight, overrideCapThreshold, overrideAboveWeight)
    if not capCfg or not baseWeight or baseWeight <= 0 then
        return (endVal - startVal) * (baseWeight or 0)
    end
    local cap = overrideCapThreshold or capCfg.cap or 0
    local softCap = capCfg.softCap
    local softMult = capCfg.softMult or 0.5
    local aboveMult = capCfg.aboveMult or 0
    local aboveWeight = overrideAboveWeight or (baseWeight * aboveMult)

    local s = startVal
    local e = endVal
    if e <= s then return 0 end

    local total = 0
    -- Segment 1: below softCap (or cap if no softCap)
    local firstCap = softCap or cap
    if s < firstCap then
        local segEnd = math_min(e, firstCap)
        total = total + (segEnd - s) * baseWeight
        s = segEnd
    end
    -- Segment 2: between softCap and hard cap
    if softCap and s < cap and s < e then
        local segEnd = math_min(e, cap)
        total = total + (segEnd - s) * (baseWeight * softMult)
        s = segEnd
    end
    -- Segment 3: above hard cap
    if s < e then
        total = total + (e - s) * aboveWeight
    end
    return total
end

function GSI_CapMath:WeaponMatchesSkillType(wsType, classID, subClassID)
    if not wsType or classID ~= 2 then return false end
    if wsType == "Sword"   then return subClassID == 7 or subClassID == 8 end
    if wsType == "Mace"    then return subClassID == 4 or subClassID == 5 end
    if wsType == "Axe"     then return subClassID == 0 or subClassID == 1 end
    if wsType == "Dagger"  then return subClassID == 15 end
    if wsType == "Fist"    then return subClassID == 13 end
    if wsType == "Polearm" then return subClassID == 6 end
    if wsType == "Staff"   then return subClassID == 10 end
    if wsType == "Bow"     then return subClassID == 2 end
    if wsType == "Gun"     then return subClassID == 3 end
    if wsType == "Crossbow"then return subClassID == 18 end
    return false
end

function GSI_CapMath:GetEffectiveStatWeight(stat, weights, role, class, specIndex, isUniversalSP, itemHealingPower, itemSpellPower)
    local w = weights and weights[stat] or 0
    if stat == "SpellPower" and role == "healer" and isUniversalSP then
        local hw = weights and weights.HealingPower or 0
        if hw > w then w = hw end
    elseif stat == "HealingPower" and role ~= "healer" and isUniversalSP then
        local sw = weights and weights.SpellPower or 0
        if sw > w then w = sw end
    end
    return w
end

function GSI_CapMath:ComputeWeaponSpeedMultiplier(speed, isTwoHand, isMainHand, class, specIndex)
    if not speed or speed <= 0 then return 1.0 end
    if isTwoHand then
        return math_min(1.25, math_max(0.80, speed / 3.3))
    elseif isMainHand then
        return math_min(1.20, math_max(0.80, speed / 2.4))
    else
        return math_min(1.15, math_max(0.85, speed / 1.8))
    end
end
