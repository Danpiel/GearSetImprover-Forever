-- ============================================================
-- GearSetImprover - JunkTab.lua (WoW Forever)
-- Lists bag gear that is weaker than currently equipped items.
-- Supports quick selling at merchants and disenchanting.
-- ============================================================

-- Static Popup for confirmation
StaticPopupDialogs["GSI_CONFIRM_SELL_ALL"] = {
    text = "Are you sure you want to sell all listed obsolete gear items to the merchant?\n\n|cff88ff88Note:|r Equipment sets and locked items are safe and will not be sold.",
    button1 = "Sell Obsolete Gear",
    button2 = "Cancel",
    OnAccept = function()
        GSI_UI:ExecuteSellAll()
    end,
    timeout = 0,
    whileDead = true,
    hideOnCursor = true,
}

GSI_UI = GSI_UI or {}

local GetItemInfo = (C_Item and C_Item.GetItemInfo) or _G.GetItemInfo or function() return nil end
local GetItemInfoInstant = (C_Item and C_Item.GetItemInfoInstant) or _G.GetItemInfoInstant or function() return nil end
local GetItemIcon = _G.GSI_GetItemIcon or function() return "Interface\\Icons\\INV_Misc_QuestionMark" end

local print = function(...)
    if GSI_Print then
        GSI_Print(...)
    elseif not (GearSetImproverDB and (GearSetImproverDB.disableChatOutput or GearSetImproverDB.disableChat)) then
        _G.print(...)
    end
end

local _BackdropTemplateMixin = _G.BackdropTemplateMixin
local _BACKDROP_TEMPLATE = _BackdropTemplateMixin and "BackdropTemplate" or nil

local function SafeGetNumBagSlots(bag)
    if C_Container and C_Container.GetContainerNumSlots then
        return C_Container.GetContainerNumSlots(bag) or 0
    elseif GetContainerNumSlots then
        return GetContainerNumSlots(bag) or 0
    end
    return 0
end

local function SafeGetBagItemLink(bag, slot)
    if C_Container and C_Container.GetContainerItemLink then
        return C_Container.GetContainerItemLink(bag, slot)
    elseif GetContainerItemLink then
        return GetContainerItemLink(bag, slot)
    end
    return nil
end

local function SafeUseBagItem(bag, slot)
    if C_Container and C_Container.UseContainerItem then
        C_Container.UseContainerItem(bag, slot)
    elseif UseContainerItem then
        UseContainerItem(bag, slot)
    end
end

-- Automatic refresh on bag updates or merchant interactions
local _junkEventFrame = CreateFrame("Frame")
local function SafeRegister(evt)
    pcall(function() _junkEventFrame:RegisterEvent(evt) end)
end
SafeRegister("BAG_UPDATE_DELAYED")
SafeRegister("MERCHANT_SHOW")
SafeRegister("MERCHANT_CLOSED")
SafeRegister("MERCHANT_UPDATE")
SafeRegister("PLAYER_REGEN_ENABLED")
SafeRegister("SPELLS_CHANGED")
SafeRegister("SKILL_LINES_CHANGED")

_junkEventFrame:SetScript("OnEvent", function(self, event, ...)
    if GSI_UI.activeTab == "JUNK" and GSI_UI.mainFrame and GSI_UI.mainFrame:IsShown() then
        local frame = GSI_UI.mainFrame.tabFrames and GSI_UI.mainFrame.tabFrames["JUNK"]
        if frame then
            if event == "PLAYER_REGEN_ENABLED" or not (InCombatLockdown and InCombatLockdown()) then
                GSI_UI:UpdateJunkList(frame)
            end
        end
    end
end)

local function _SkinFrame(frame, style, hasTop)
    if GSI_UI and GSI_UI.SkinFrame then
        return GSI_UI:SkinFrame(frame, style, hasTop)
    end
end

local function _SkinButton(btn, isRed, isPrimary)
    if GSI_UI and GSI_UI.SkinButton then
        return GSI_UI:SkinButton(btn, isRed, isPrimary)
    end
end

GSI_Config.JunkThreshold = (GearSetImproverDB and GearSetImproverDB.junkThreshold) or GSI_Config.JunkThreshold or 5

local JUNK_EQUIPLOC = {
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
    INVTYPE_TRINKET        = { INVSLOT_TRINKET1, INVSLOT_TRINKET2 },
    INVTYPE_WEAPON         = { INVSLOT_MAINHAND, INVSLOT_OFFHAND },
    INVTYPE_WEAPONMAINHAND = { INVSLOT_MAINHAND },
    INVTYPE_2HWEAPON       = { INVSLOT_MAINHAND },
    INVTYPE_WEAPONOFFHAND  = { INVSLOT_OFFHAND },
    INVTYPE_HOLDABLE       = { INVSLOT_OFFHAND },
    INVTYPE_SHIELD         = { INVSLOT_OFFHAND },
    INVTYPE_RANGED         = { INVSLOT_RANGED },
    INVTYPE_RANGEDRIGHT    = { INVSLOT_RANGED },
    INVTYPE_THROWN         = { INVSLOT_RANGED },
    INVTYPE_RELIC          = { INVSLOT_RANGED },
}

local function HasDisenchantSpell()
    local spellID = 13262 -- Disenchant

    if C_SpellBook and C_SpellBook.IsSpellKnown then
        local ok, known = pcall(C_SpellBook.IsSpellKnown, spellID)
        if ok and known then return true end
    end
    if C_Spell and C_Spell.IsSpellKnown then
        local ok, known = pcall(C_Spell.IsSpellKnown, spellID)
        if ok and known then return true end
    end
    if IsSpellKnown then
        local ok, known = pcall(IsSpellKnown, spellID)
        if ok and known then return true end
    end
    if IsPlayerSpell then
        local ok, known = pcall(IsPlayerSpell, spellID)
        if ok and known then return true end
    end
    if FindSpellBookSlotBySpellID then
        local ok, slot = pcall(FindSpellBookSlotBySpellID, spellID)
        if ok and slot and slot > 0 then return true end
    end

    local targetName = (C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName(spellID))
                    or (GetSpellInfo and GetSpellInfo(spellID))
    if GetNumSpellTabs then
        local numTabs = GetNumSpellTabs() or 0
        for tab = 1, numTabs do
            local _, _, offset, numSpells = GetSpellTabInfo(tab)
            if offset and numSpells then
                for s = offset + 1, offset + numSpells do
                    if GetSpellBookItemInfo then
                        local sType, id = GetSpellBookItemInfo(s, BOOKTYPE_SPELL or "spell")
                        if sType == "SPELL" and id == spellID then
                            return true
                        end
                    end
                    if targetName and GetSpellBookItemName then
                        local sName = GetSpellBookItemName(s, BOOKTYPE_SPELL or "spell")
                        if sName and sName == targetName then
                            return true
                        end
                    end
                end
            end
        end
    end

    if GetNumSkillLines and GetSkillLineInfo then
        local enchSpellName = (C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName(7411))
                           or (GetSpellInfo and GetSpellInfo(7411))
        local numSkills = GetNumSkillLines() or 0
        for i = 1, numSkills do
            local skillName, isHeader = GetSkillLineInfo(i)
            if not isHeader and skillName then
                if (enchSpellName and skillName == enchSpellName)
                   or skillName == "Enchanting"
                   or skillName == "Verzauberkunst" then
                    return true
                end
            end
        end
    end

    if GetProfessions and GetProfessionInfo then
        local prof1, prof2 = GetProfessions()
        for _, p in ipairs({prof1, prof2}) do
            if p then
                local pName, _, _, _, _, _, skillLine = GetProfessionInfo(p)
                if skillLine == 333 or pName == "Enchanting" or pName == "Verzauberkunst" then
                    return true
                end
            end
        end
    end

    return false
end

local function GetEquippedScore(slotID)
    local link = GetInventoryItemLink("player", slotID)
    if not link then return 0 end
    return GSI_ItemScore:Calculate(link, nil, nil, nil, slotID) or 0
end

local ARMOR_SLOTS = {
    INVTYPE_HEAD     = true,
    INVTYPE_SHOULDER = true,
    INVTYPE_CHEST    = true,
    INVTYPE_ROBE     = true,
    INVTYPE_WRIST    = true,
    INVTYPE_HAND     = true,
    INVTYPE_WAIST    = true,
    INVTYPE_LEGS     = true,
    INVTYPE_FEET     = true,
}

local GSI_CLASS_ALLOWED_WEAPONS = {
    WARRIOR = { [0]=true, [1]=true, [2]=true, [3]=true, [4]=true, [5]=true, [6]=true, [7]=true, [8]=true, [10]=true, [13]=true, [14]=true, [15]=true, [16]=true, [18]=true, [20]=true },
    PALADIN = { [0]=true, [1]=true, [4]=true, [5]=true, [6]=true, [7]=true, [8]=true, [14]=true, [20]=true },
    HUNTER  = { [0]=true, [1]=true, [2]=true, [3]=true, [6]=true, [7]=true, [8]=true, [10]=true, [13]=true, [14]=true, [15]=true, [16]=true, [18]=true, [20]=true },
    ROGUE   = { [2]=true, [3]=true, [4]=true, [7]=true, [13]=true, [14]=true, [15]=true, [16]=true, [18]=true, [20]=true },
    PRIEST  = { [4]=true, [10]=true, [14]=true, [15]=true, [19]=true, [20]=true },
    SHAMAN  = { [0]=true, [1]=true, [4]=true, [5]=true, [10]=true, [13]=true, [14]=true, [15]=true, [20]=true },
    MAGE    = { [7]=true, [10]=true, [14]=true, [15]=true, [19]=true, [20]=true },
    WARLOCK = { [7]=true, [10]=true, [14]=true, [15]=true, [19]=true, [20]=true },
    DRUID   = { [4]=true, [5]=true, [6]=true, [10]=true, [13]=true, [14]=true, [15]=true, [20]=true },
}

local GSI_CLASS_MAX_ARMOR = {
    MAGE    = 1, -- Cloth
    PRIEST  = 1, -- Cloth
    WARLOCK = 1, -- Cloth
    ROGUE   = 2, -- Leather
    DRUID   = 2, -- Leather
    HUNTER  = 3, -- Mail
    SHAMAN  = 3, -- Mail
    WARRIOR = 4, -- Plate
    PALADIN = 4, -- Plate
}

local function IsItemUnusableForPlayer(link, bagID, slotID)
    if not link then return false end
    local _, _, _, ilvl, reqLevel, itemType, itemSubType, _, equipLoc, _, _, classID, subClassID = GetItemInfo(link)
    if not classID and (C_Item and C_Item.GetItemInfoInstant or GetItemInfoInstant) then
        local _, _, _, eLoc, _, cID, scID = (C_Item and C_Item.GetItemInfoInstant or GetItemInfoInstant)(link)
        equipLoc = equipLoc or eLoc
        classID = classID or cID
        subClassID = subClassID or scID
    end
    if not equipLoc or equipLoc == "" or equipLoc == "INVTYPE_NON_EQUIP" then return false end

    local playerClass = select(2, UnitClass("player")) or "WARRIOR"
    local playerLevel = UnitLevel("player") or 60

    -- 1. Weapons (classID == 2)
    if classID == 2 then
        if (not subClassID or subClassID == 0) and itemSubType then
            local s = string.lower(itemSubType)
            if s:find("gun") or s:find("schuss") then subClassID = 3
            elseif s:find("crossbow") or s:find("armbrust") then subClassID = 18
            elseif s:find("bow") or s:find("bogen") then subClassID = 2
            elseif s:find("wand") or s:find("zauberstab") then subClassID = 19
            elseif s:find("dagger") or s:find("dolch") then subClassID = 15
            elseif s:find("polearm") or s:find("stange") then subClassID = 6
            elseif s:find("staff") or s:find("staebe") or s:find("stab") then subClassID = 10
            elseif s:find("thrown") or s:find("wurf") then subClassID = 16
            elseif s:find("fist") or s:find("faust") then subClassID = 13
            elseif s:find("fishing") or s:find("angel") then subClassID = 20
            elseif s:find("sword") or s:find("schwert") then
                subClassID = (equipLoc == "INVTYPE_2HWEAPON") and 8 or 7
            elseif s:find("axe") or s:find("axt") then
                subClassID = (equipLoc == "INVTYPE_2HWEAPON") and 1 or 0
            elseif s:find("mace") or s:find("kolben") then
                subClassID = (equipLoc == "INVTYPE_2HWEAPON") and 5 or 4
            end
        end

        local allowed = GSI_CLASS_ALLOWED_WEAPONS[playerClass]
        if allowed and subClassID and not allowed[subClassID] then
            return true, "Weapon"
        end
        if equipLoc == "INVTYPE_WEAPONOFFHAND" then
            if GSI_ClassicData and GSI_ClassicData.CanDualWield and not GSI_ClassicData:CanDualWield() then
                return true, "Off-Hand"
            end
        end
    end

    -- 2. Shields (subClassID == 6 or INVTYPE_SHIELD)
    if equipLoc == "INVTYPE_SHIELD" or (classID == 4 and subClassID == 6) then
        if playerClass ~= "WARRIOR" and playerClass ~= "PALADIN" and playerClass ~= "SHAMAN" then
            return true, "Shield"
        end
    end

    -- 3. Armor slots (classID == 4)
    if classID == 4 and ARMOR_SLOTS[equipLoc] then
        if (not subClassID or subClassID == 0) and itemSubType then
            local s = string.lower(itemSubType)
            if s:find("cloth") or s:find("stoff") then subClassID = 1
            elseif s:find("leather") or s:find("leder") then subClassID = 2
            elseif s:find("mail") or s:find("schwere") then subClassID = 3
            elseif s:find("plate") or s:find("platte") then subClassID = 4
            end
        end

        if subClassID and subClassID > 0 then
            local maxArmor = GSI_CLASS_MAX_ARMOR[playerClass] or 4
            if subClassID > maxArmor then
                return true, "Armor"
            end
            if (playerClass == "HUNTER" or playerClass == "SHAMAN") and playerLevel < 40 and subClassID == 3 then
                if not (reqLevel and reqLevel >= 40) then
                    return true, "Armor"
                end
            end
            if (playerClass == "WARRIOR" or playerClass == "PALADIN") and playerLevel < 40 and subClassID == 4 then
                if not (reqLevel and reqLevel >= 40) then
                    return true, "Armor"
                end
            end
        end
    end

    -- 4. Relics (INVTYPE_RELIC)
    if equipLoc == "INVTYPE_RELIC" then
        if subClassID == 7 and playerClass ~= "PALADIN" then return true, "Relic" end
        if subClassID == 8 and playerClass ~= "DRUID" then return true, "Relic" end
        if subClassID == 9 and playerClass ~= "SHAMAN" then return true, "Relic" end
    end

    -- 5. Deep inspection via OptimizationEngine / Tooltip
    if GSI_OptimizationEngine and GSI_OptimizationEngine.IsItemUsableForPlayer then
        if not GSI_OptimizationEngine:IsItemUsableForPlayer(link, bagID, slotID, true) then
            if classID == 2 then return true, "Weapon"
            elseif equipLoc == "INVTYPE_SHIELD" then return true, "Shield"
            elseif classID == 4 and ARMOR_SLOTS[equipLoc] then return true, "Armor"
            elseif equipLoc == "INVTYPE_RELIC" then return true, "Relic"
            else return true, "Class"
            end
        end
    end

    return false
end

local function IsOtherArmorClass(link)
    if not link then return false end
    local _, _, _, ilvl, reqLevel, itemType, itemSubType, _, equipLoc, _, _, classID, subClassID = GetItemInfo(link)
    if not classID and (C_Item and C_Item.GetItemInfoInstant or GetItemInfoInstant) then
        local _, _, _, eLoc, _, cID, scID = (C_Item and C_Item.GetItemInfoInstant or GetItemInfoInstant)(link)
        equipLoc = equipLoc or eLoc
        classID = classID or cID
        subClassID = subClassID or scID
    end
    if not equipLoc or equipLoc == "" or equipLoc == "INVTYPE_NON_EQUIP" then return false end

    local playerClass = select(2, UnitClass("player")) or "WARRIOR"
    local playerLevel = UnitLevel("player") or 60

    if equipLoc == "INVTYPE_SHIELD" then
        if playerClass ~= "WARRIOR" and playerClass ~= "PALADIN" and playerClass ~= "SHAMAN" then
            return true
        end
        return false
    end

    if ARMOR_SLOTS[equipLoc] then
        if (not subClassID or subClassID == 0) and itemSubType then
            local s = string.lower(itemSubType)
            if s:find("cloth") or s:find("stoff") then subClassID = 1
            elseif s:find("leather") or s:find("leder") then subClassID = 2
            elseif s:find("mail") or s:find("schwere") then subClassID = 3
            elseif s:find("plate") or s:find("platte") then subClassID = 4
            end
        end

        if subClassID and subClassID > 0 then
            local myArmorSub
            if playerClass == "WARRIOR" or playerClass == "PALADIN" then
                if playerLevel >= 40 then
                    myArmorSub = 4
                else
                    if subClassID == 4 and (reqLevel and reqLevel >= 40) then
                        return false
                    end
                    myArmorSub = 3
                end
            elseif playerClass == "HUNTER" or playerClass == "SHAMAN" then
                if playerLevel >= 40 then
                    myArmorSub = 3
                else
                    if subClassID == 3 and (reqLevel and reqLevel >= 40) then
                        return false
                    end
                    myArmorSub = 2
                end
            elseif playerClass == "ROGUE" or playerClass == "DRUID" then
                myArmorSub = 2
            else
                myArmorSub = 1
            end

            if subClassID ~= myArmorSub then
                return true
            end
        end
    end

    return false
end

-- Collects all item IDs saved in any player Equipment Set
local function GetAllEquipmentSetItemIDs()
    local setItemIDs = {}

    if C_EquipmentSet and C_EquipmentSet.GetEquipmentSetIDs then
        local ok, setIDs = pcall(C_EquipmentSet.GetEquipmentSetIDs)
        if ok and setIDs then
            for _, setID in ipairs(setIDs) do
                local ok2, itemIDs = pcall(C_EquipmentSet.GetItemIDs, setID)
                if ok2 and itemIDs then
                    for _, id in pairs(itemIDs) do
                        if id and type(id) == "number" and id > 0 then
                            setItemIDs[id] = true
                        end
                    end
                end
                if C_EquipmentSet.GetItemLocations then
                    local ok3, locs = pcall(C_EquipmentSet.GetItemLocations, setID)
                    if ok3 and locs then
                        for _, loc in pairs(locs) do
                            if loc and loc > 0 and C_Item and C_Item.GetItemIDByLocation then
                                local ok4, id = pcall(C_Item.GetItemIDByLocation, loc)
                                if ok4 and id then setItemIDs[id] = true end
                            end
                        end
                    end
                end
            end
        end
    end

    if GetNumEquipmentSets and GetEquipmentSetInfo then
        local ok, numSets = pcall(GetNumEquipmentSets)
        if ok and numSets then
            for i = 1, numSets do
                local ok2, name = pcall(GetEquipmentSetInfo, i)
                if ok2 and name and GetEquipmentSetItemIDs then
                    local ok3, ids = pcall(GetEquipmentSetItemIDs, name)
                    if ok3 and ids then
                        for _, id in pairs(ids) do
                            if id and type(id) == "number" and id > 0 then
                                setItemIDs[id] = true
                            end
                        end
                    end
                end
            end
        end
    end

    return setItemIDs
end

local function ScanBagsForJunk()
    local threshold = (GearSetImproverDB and GearSetImproverDB.junkThreshold) or (GSI_Config and GSI_Config.JunkThreshold) or 5
    local includeOtherArmor = (GearSetImproverDB and GearSetImproverDB.junkIncludeOtherArmor) or false
    local includeWhiteGear = true
    if GearSetImproverDB and GearSetImproverDB.junkIncludeWhiteGear ~= nil then
        includeWhiteGear = GearSetImproverDB.junkIncludeWhiteGear
    elseif GSI_Config and GSI_Config.JunkIncludeWhiteGear ~= nil then
        includeWhiteGear = GSI_Config.JunkIncludeWhiteGear
    end
    local includeUnusableGear = true
    if GearSetImproverDB and GearSetImproverDB.junkIncludeUnusableGear ~= nil then
        includeUnusableGear = GearSetImproverDB.junkIncludeUnusableGear
    elseif GSI_Config and GSI_Config.JunkIncludeUnusableGear ~= nil then
        includeUnusableGear = GSI_Config.JunkIncludeUnusableGear
    end
    local minQuality = includeWhiteGear and 1 or 2
    local junkItems = {}
    local equipSetItems = GetAllEquipmentSetItemIDs()
    local playerClass = UnitClass and select(2, UnitClass("player"))
    local activeSpec = (GSI_StatWeights and GSI_StatWeights.GetActiveSpecIndex and GSI_StatWeights:GetActiveSpecIndex()) or 1
    local isShieldTank = (playerClass == "WARRIOR" and activeSpec == 3) or (playerClass == "PALADIN" and activeSpec == 2)
    local isFeralDruid = (playerClass == "DRUID" and (activeSpec == 2 or activeSpec == 3))

    local maxBags = NUM_BAG_SLOTS or 5
    for bagID = 0, maxBags do
        local numSlots = SafeGetNumBagSlots(bagID)
        for slotID = 1, numSlots do
            local link = SafeGetBagItemLink(bagID, slotID)
            if link then
                local _, _, quality, ilvl, _, _, _, _, equipLoc, _, sellPrice = GetItemInfo(link)
                if equipLoc and equipLoc ~= "" and equipLoc ~= "INVTYPE_NON_EQUIP"
                    and equipLoc ~= "INVTYPE_BODY" and equipLoc ~= "INVTYPE_TABARD" and equipLoc ~= "INVTYPE_BAG"
                    and quality and quality >= minQuality then
                    if quality >= 2 or (sellPrice and sellPrice > 0) then
                        local slots = JUNK_EQUIPLOC[equipLoc]
                        if equipLoc == "INVTYPE_WEAPON" and ((GSI_ClassicData and GSI_ClassicData.CanDualWield and not GSI_ClassicData:CanDualWield()) or isShieldTank) then
                            slots = { INVSLOT_MAINHAND }
                        end
                        if slots then
                            -- 1. Tier set protection
                            local isTierSet = GSI_SetBonus and GSI_SetBonus:GetSetNameFromLink(link)

                            -- 2. Equipment set protection (WoW Gearsets)
                            local itemID = tonumber(link:match("item:(%d+)"))
                            local isInEquipmentSet = itemID and equipSetItems[itemID]

                            -- 3. Locked / ignored items
                            local itemKey = GSI_UI and GSI_UI.GetItemKey and GSI_UI:GetItemKey(link)
                            local isLocked = false
                            if itemID and GearSetImproverDB and GearSetImproverDB.lockedCleanUpItems and GearSetImproverDB.lockedCleanUpItems[itemID] then
                                isLocked = true
                            end
                            if itemKey and GearSetImproverDB and GearSetImproverDB.ignoredItems and GearSetImproverDB.ignoredItems[itemKey] then
                                isLocked = true
                            end

                            if not isTierSet and not isInEquipmentSet and not isLocked then
                                local isUnusable, unusableType = IsItemUnusableForPlayer(link, bagID, slotID)
                                if isUnusable then
                                    if includeUnusableGear then
                                        local bestEquipped = 0
                                        for _, sid in ipairs(slots) do
                                            local eq = GetEquippedScore(sid)
                                            if eq > bestEquipped then bestEquipped = eq end
                                        end
                                        local delta = (bestEquipped > 0 and bestEquipped) or (ilvl and ilvl > 0 and ilvl) or 1
                                        table.insert(junkItems, {
                                            link         = link,
                                            ilvl         = ilvl or 0,
                                            score        = 0,
                                            delta        = delta,
                                            bagID        = bagID,
                                            slotID       = slotID,
                                            quality      = quality,
                                            isUnusable   = true,
                                            unusableType = unusableType or "Unusable",
                                        })
                                    end
                                else
                                    local otherArmor = IsOtherArmorClass(link)
                                    if otherArmor then
                                        if includeOtherArmor then
                                            local bestEquipped = 0
                                            for _, sid in ipairs(slots) do
                                                local eq = GetEquippedScore(sid)
                                                if eq > bestEquipped then bestEquipped = eq end
                                            end
                                            local delta = (bestEquipped > 0 and bestEquipped) or (ilvl and ilvl > 0 and ilvl) or 1
                                            table.insert(junkItems, {
                                                link         = link,
                                                ilvl         = ilvl or 0,
                                                score        = 0,
                                                delta        = delta,
                                                bagID        = bagID,
                                                slotID       = slotID,
                                                quality      = quality,
                                                isOtherArmor = true,
                                            })
                                        end
                                    else
                                        -- Multi-slot comparison: evaluate against each target slot using its slot-specific weight
                                        -- Protect off-spec 2H/DW/Holdable items in Shield-Tank specs (and Holdables in Feral) from Clean-up
                                        local skipOffspecWeapon = (isShieldTank and (equipLoc == "INVTYPE_2HWEAPON" or equipLoc == "INVTYPE_WEAPONOFFHAND" or equipLoc == "INVTYPE_HOLDABLE"))
                                            or (isFeralDruid and equipLoc == "INVTYPE_HOLDABLE")
                                        if not skipOffspecWeapon then
                                            local minDelta = nil
                                            local matchedCandScore = 0
                                            local allSlotsEquipped = true
                                            for _, sid in ipairs(slots) do
                                                local eq = GetEquippedScore(sid)
                                                if eq <= 0 then
                                                    allSlotsEquipped = false
                                                    break
                                                end
                                                local candScore = GSI_ItemScore:Calculate(link, nil, nil, nil, sid) or 0
                                                local slotDelta = eq - candScore
                                                if minDelta == nil or slotDelta < minDelta then
                                                    minDelta = slotDelta
                                                    matchedCandScore = candScore
                                                end
                                            end
                                            if allSlotsEquipped and minDelta and minDelta >= threshold then
                                                table.insert(junkItems, {
                                                    link    = link,
                                                    ilvl    = ilvl or 0,
                                                    score   = matchedCandScore,
                                                    delta   = minDelta,
                                                    bagID   = bagID,
                                                    slotID  = slotID,
                                                    quality = quality,
                                                })
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    table.sort(junkItems, function(a, b) return a.delta > b.delta end)
    return junkItems
end
GSI_UI.ScanBagsForJunk = ScanBagsForJunk

function GSI_UI:ExecuteSellAll()
    local items = ScanBagsForJunk()
    if #items == 0 then return end
    if not (MerchantFrame and MerchantFrame:IsShown()) then
        print("|cffff4444GSI:|r Please open a merchant first!")
        return
    end
    local queue = {}
    for _, item in ipairs(items) do table.insert(queue, item) end
    local soldCount = 0
    local function SellNext()
        if #queue == 0 then
            print(string.format("|cffffcc00GSI:|r %d item(s) sold to merchant.", soldCount))
            if GSI_UI.activeTab == "JUNK" and GSI_UI.mainFrame then
                local frame = GSI_UI.mainFrame.tabFrames and GSI_UI.mainFrame.tabFrames["JUNK"]
                if frame then GSI_UI:UpdateJunkList(frame) end
            end
            if GSI_UI.UpdateMerchantPanel then
                GSI_UI:UpdateMerchantPanel()
            end
            return
        end
        if not (MerchantFrame and MerchantFrame:IsShown()) then
            print(string.format("|cffffcc00GSI:|r Selling stopped (merchant closed). %d sold.", soldCount))
            return
        end
        local item = table.remove(queue, 1)
        local _, _, _, _, _, _, _, _, _, _, sellPrice = GetItemInfo(item.link)
        if sellPrice and sellPrice > 0 then
            SafeUseBagItem(item.bagID, item.slotID)
            soldCount = soldCount + 1
        end
        C_Timer.After(0.08, SellNext)
    end
    SellNext()
end

GSI_UI.HasDisenchantSpell = HasDisenchantSpell

local _sessionSkippedDE = {}
local _lastDEBusyTime = 0

local function GetDisenchantSpellName()
    if C_Spell and C_Spell.GetSpellName then
        local name = C_Spell.GetSpellName(13262)
        if name and name ~= "" then return name end
    end
    if GetSpellInfo then
        local name = GetSpellInfo(13262)
        if name and name ~= "" then return name end
    end
    return "Disenchant"
end

local function GetDisenchantSpellIcon()
    if C_Spell and C_Spell.GetSpellTexture then
        local tex = C_Spell.GetSpellTexture(13262)
        if tex then return tex end
    end
    if GetSpellTexture then
        local tex = GetSpellTexture(13262)
        if tex then return tex end
    end
    return 132853
end

local function IsBagItemDisenchantable(bagID, slotID)
    if C_TooltipInfo and C_TooltipInfo.GetBagItem then
        local ok, data = pcall(C_TooltipInfo.GetBagItem, bagID, slotID)
        if ok and data and data.lines then
            local notDeText = ITEM_DISENCHANT_NOT_DISENCHANTABLE
            for _, line in ipairs(data.lines) do
                local left = line.leftText
                if left then
                    if notDeText and left == notDeText then
                        return false
                    end
                    if left:find("Cannot be disenchanted") or left:find("Kann nicht entzaubert werden") then
                        return false
                    end
                end
            end
        end
    end
    return true
end

function GSI_UI:GetDisenchantableItems()
    local items = ScanBagsForJunk()
    local deList = {}
    for _, item in ipairs(items) do
        if item.quality and item.quality >= 2 and not item.isWhiteGear then
            if not _sessionSkippedDE[item.link] and IsBagItemDisenchantable(item.bagID, item.slotID) then
                table.insert(deList, item)
            end
        end
    end
    return deList
end

local function IsSpellOnCooldown(spellID)
    if C_Spell and C_Spell.GetSpellCooldown then
        local info = C_Spell.GetSpellCooldown(spellID)
        if info and info.startTime and info.duration and info.duration > 0 then
            return true
        end
    elseif GetSpellCooldown then
        local start, duration = GetSpellCooldown(spellID)
        if start and duration and duration > 0 then
            return true
        end
    end
    return false
end

local function ClearDEProxyAttributes(btn)
    if not btn or (InCombatLockdown and InCombatLockdown()) then return end
    btn:SetAttribute("type", nil)
    btn:SetAttribute("spell", nil)
    btn:SetAttribute("target-bag", nil)
    btn:SetAttribute("target-slot", nil)
    btn:SetAttribute("*type1", nil)
    btn:SetAttribute("*spell1", nil)
    btn:SetAttribute("*target-bag1", nil)
    btn:SetAttribute("*target-slot1", nil)
    for i = 1, 5 do
        btn:SetAttribute("type" .. i, nil)
        btn:SetAttribute("spell" .. i, nil)
        btn:SetAttribute("target-bag" .. i, nil)
        btn:SetAttribute("target-slot" .. i, nil)
    end
end

local function SetDEProxyTarget(btn, bagID, slotID)
    btn:SetAttribute("type", "spell")
    btn:SetAttribute("spell", 13262)
    btn:SetAttribute("target-bag", bagID)
    btn:SetAttribute("target-slot", slotID)
    btn:SetAttribute("*type1", "spell")
    btn:SetAttribute("*spell1", 13262)
    btn:SetAttribute("*target-bag1", bagID)
    btn:SetAttribute("*target-slot1", slotID)
    for i = 1, 5 do
        btn:SetAttribute("type" .. i, "spell")
        btn:SetAttribute("spell" .. i, 13262)
        btn:SetAttribute("target-bag" .. i, bagID)
        btn:SetAttribute("target-slot" .. i, slotID)
    end
end

local function DisenchantAction_PreClick(self)
    if InCombatLockdown and InCombatLockdown() then return end
    ClearDEProxyAttributes(self)
    self._activeCandidate = nil

    if not HasDisenchantSpell() then
        print("|cffff4444[GSI]|r You do not know Disenchant.")
        return
    end

    if (UnitCastingInfo and UnitCastingInfo("player")) or (UnitChannelInfo and UnitChannelInfo("player")) then
        return
    end
    if IsCurrentSpell and IsCurrentSpell(13262) then
        return
    end
    if LootFrame and LootFrame:IsShown() then
        return
    end
    if (GetTime() - _lastDEBusyTime) < 0.6 then
        return
    end
    if IsSpellOnCooldown(13262) or IsSpellOnCooldown(61304) then
        return
    end
    if GetUnitSpeed and GetUnitSpeed("player") > 0 then
        print("|cffffcc00[GSI]|r Stand still to disenchant.")
        return
    end
    if (IsMounted and IsMounted()) or (UnitIsDeadOrGhost and UnitIsDeadOrGhost("player")) then
        return
    end

    if SpellIsTargeting and SpellIsTargeting() and SpellStopTargeting then
        SpellStopTargeting()
    end

    local deItems = GSI_UI:GetDisenchantableItems()
    local item = deItems[1]
    if not item then
        print("|cff00ff00[GSI]|r No more disenchantable items in the Clean-up list!")
        return
    end

    local currentLink = SafeGetBagItemLink(item.bagID, item.slotID)
    if not currentLink or currentLink ~= item.link then
        return
    end

    self._activeCandidate = item
    SetDEProxyTarget(self, item.bagID, item.slotID)
    print(string.format("|cff00ff00[GSI]|r Disenchanting %s (%d remaining)...", item.link, #deItems))
end

local function DisenchantAction_PostClick(self)
    local candidate = self._activeCandidate
    self._activeCandidate = nil
    if not (InCombatLockdown and InCombatLockdown()) then
        ClearDEProxyAttributes(self)
    end
    if SpellIsTargeting and SpellIsTargeting() then
        if SpellStopTargeting then SpellStopTargeting() end
        if candidate and candidate.link then
            _sessionSkippedDE[candidate.link] = true
            print(string.format("|cffff4444[GSI]|r Could not disenchant %s (skill too low or not disenchantable) — skipping for this session.", candidate.link))
        end
    end
end

function GSI_UI:BindDisenchantActionButton(btn)
    if not btn then return end
    if btn.RegisterForClicks then btn:RegisterForClicks("AnyUp") end
    if btn.SetAttribute then btn:SetAttribute("useOnKeyDown", false) end
    if btn.SetScript then
        btn:SetScript("PreClick", DisenchantAction_PreClick)
        btn:SetScript("PostClick", DisenchantAction_PostClick)
    end
end

local deProxy = _G["GSI_DisenchantProxy"] or CreateFrame("Button", "GSI_DisenchantProxy", UIParent, "SecureActionButtonTemplate")
deProxy:SetSize(1, 1)
deProxy:SetPoint("TOPLEFT", UIParent, "TOPLEFT", -400, 100)
deProxy:SetAlpha(0)
deProxy:EnableMouse(false)
deProxy:Show()
GSI_UI:BindDisenchantActionButton(deProxy)

local deStateFrame = CreateFrame("Frame")
deStateFrame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
deStateFrame:RegisterEvent("LOOT_OPENED")
deStateFrame:RegisterEvent("LOOT_CLOSED")
deStateFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
deStateFrame:SetScript("OnEvent", function(_, event, unit, _, spellID)
    if event == "UNIT_SPELLCAST_SUCCEEDED" then
        if unit == "player" and spellID == 13262 then
            _lastDEBusyTime = GetTime()
        end
    elseif event == "LOOT_OPENED" or event == "LOOT_CLOSED" then
        _lastDEBusyTime = GetTime()
    elseif event == "PLAYER_ENTERING_WORLD" then
        C_Timer.After(2.0, function()
            if GSI_UI and GSI_UI.SyncExistingDisenchantMacro then
                GSI_UI:SyncExistingDisenchantMacro()
            end
        end)
    end
end)

function GSI_UI:BuildDisenchantMacroBody()
    local spellName = GetDisenchantSpellName()
    return string.format("#showtooltip %s\n/click GSI_DisenchantProxy", spellName)
end

function GSI_UI:SyncExistingDisenchantMacro()
    if InCombatLockdown and InCombatLockdown() then return end
    local macroName = "GSI: DE Clean"
    local existingIdx = self.FindMacro and self:FindMacro(macroName)
    if not existingIdx and GetMacroIndexByName then
        local idx = GetMacroIndexByName(macroName)
        if idx and idx > 0 then existingIdx = idx end
    end
    if existingIdx then
        local macroBody = self:BuildDisenchantMacroBody()
        local macroIcon = GetDisenchantSpellIcon()
        pcall(function()
            EditMacro(existingIdx, macroName, macroIcon, macroBody)
        end)
    end
end

function GSI_UI:EnsureDisenchantMacro()
    if InCombatLockdown and InCombatLockdown() then
        print("|cffff4444[GSI]|r Cannot create macros while in combat!")
        return nil
    end

    local macroName = "GSI: DE Clean"
    local macroBody = self:BuildDisenchantMacroBody()
    local macroIcon = GetDisenchantSpellIcon()

    local existingIdx = self.FindMacro and self:FindMacro(macroName)
    if not existingIdx and GetMacroIndexByName then
        local idx = GetMacroIndexByName(macroName)
        if idx and idx > 0 then existingIdx = idx end
    end

    if existingIdx then
        local ok, err = pcall(function()
            EditMacro(existingIdx, macroName, macroIcon, macroBody)
        end)
        if not ok then
            print("|cffff4444[GSI]|r Error updating Disenchant macro: " .. tostring(err))
        end
        return existingIdx
    else
        local numAccount, numCharacter = GetNumMacros()
        numAccount = numAccount or 0
        numCharacter = numCharacter or 0
        local maxChar = MAX_CHARACTER_MACROS or 18
        local maxAccount = MAX_ACCOUNT_MACROS or 120
        local isChar = 1

        if numCharacter >= maxChar then
            if numAccount < maxAccount then
                isChar = nil
            else
                print("|cffff4444[GSI]|r Cannot create macro: Character and Account macro slots are full!")
                return nil
            end
        end

        local newIdx = nil
        local ok, err = pcall(function()
            newIdx = CreateMacro(macroName, macroIcon, macroBody, isChar)
        end)
        if not ok or not newIdx then
            print("|cffff4444[GSI]|r Failed to create Disenchant macro: " .. tostring(err or "unknown error"))
            return nil
        end
        print(string.format("|cff00ff00[GSI]|r Created macro '|cffffcc00%s|r' (%s)!", macroName, isChar and "Character" or "Account"))
        return newIdx
    end
end

function GSI_UI:PickupDisenchantMacro()
    if InCombatLockdown and InCombatLockdown() then
        print("|cffff4444[GSI]|r Cannot pick up macros while in combat!")
        return
    end

    wipe(_sessionSkippedDE)
    local idx = self:EnsureDisenchantMacro()
    if not idx then return end

    local ok, err = pcall(function()
        PickupMacro(idx)
    end)
    if ok then
        print("|cff00ff00[GSI]|r Disenchant macro attached to cursor! Place it on your Action Bar and press it repeatedly to disenchant items one by one.")
    else
        print("|cffff4444[GSI]|r PickupMacro error: " .. tostring(err))
    end
end

function GSI_UI:OpenLockedCleanUpDialog(parent)
    if self._lockedCleanUpFrame and self._lockedCleanUpFrame:IsShown() then
        self._lockedCleanUpFrame:Hide()
        return
    end

    if not self._lockedCleanUpFrame then
        local f = CreateFrame("Frame", "GSI_LockedCleanUpFrame", parent, _BACKDROP_TEMPLATE)
        f:SetSize(430, 360)
        f:SetPoint("CENTER", parent, "CENTER", 0, 0)
        f:SetFrameStrata("FULLSCREEN_DIALOG")
        f:SetFrameLevel(500)
        _SkinFrame(f)
        f:SetBackdropColor(0.08, 0.08, 0.08, 0.98)
        f:SetBackdropBorderColor(1, 0.82, 0, 1)

        local title = GSI_UI:CreateText(f, "CARD_TITLE", "Locked Items (Clean-up Protection)")
        title:SetPoint("TOPLEFT", 15, -15)

        local desc = GSI_UI:CreateText(f, "SMALL", "These items are excluded from clean-up and will never be automatically sold.")
        desc:SetPoint("TOPLEFT", 15, -34)
        desc:SetPoint("RIGHT", -15, 0)
        desc:SetJustifyH("LEFT")

        local closeBtn = CreateFrame("Button", nil, f, _BACKDROP_TEMPLATE)
        closeBtn:SetSize(80, 22)
        closeBtn:SetPoint("BOTTOMRIGHT", -15, 12)
        closeBtn:SetText("Close")
        _SkinButton(closeBtn)
        closeBtn:SetScript("OnClick", function() f:Hide() end)

        local unlockAllBtn = CreateFrame("Button", nil, f, _BACKDROP_TEMPLATE)
        unlockAllBtn:SetSize(115, 22)
        unlockAllBtn:SetPoint("BOTTOMLEFT", 15, 12)
        unlockAllBtn:SetText("Unlock All")
        _SkinButton(unlockAllBtn)
        unlockAllBtn:SetScript("OnClick", function()
            if GearSetImproverDB then
                GearSetImproverDB.lockedCleanUpItems = {}
            end
            GSI_UI:RefreshLockedCleanUpList(f)
            GSI_UI:UpdateJunkList(parent)
        end)

        local scroll = CreateFrame("ScrollFrame", "GSI_LockedCleanUpScroll", f, "UIPanelScrollFrameTemplate")
        scroll:SetPoint("TOPLEFT", 15, -60)
        scroll:SetPoint("BOTTOMRIGHT", -32, 42)
        if GSI_UI and GSI_UI.SkinScrollBar then
            GSI_UI:SkinScrollBar(scroll)
        end

        local child = CreateFrame("Frame", nil, scroll)
        child:SetSize(370, 250)
        scroll:SetScrollChild(child)
        f._scrollChild = child
        f._rows = {}

        local emptyText = GSI_UI:CreateText(f, "BODY", "No locked items.")
        emptyText:SetPoint("CENTER", f, "CENTER", 0, -10)
        emptyText:SetTextColor(0.5, 0.5, 0.5)
        emptyText:Hide()
        f._emptyText = emptyText

        self._lockedCleanUpFrame = f
    end

    self:RefreshLockedCleanUpList(self._lockedCleanUpFrame)
    self._lockedCleanUpFrame:Show()
end

function GSI_UI:RefreshLockedCleanUpList(f)
    if not f or not f._scrollChild then return end
    local child = f._scrollChild
    local rows = f._rows
    for _, r in ipairs(rows) do r:Hide() end

    local locked = GearSetImproverDB and GearSetImproverDB.lockedCleanUpItems or {}
    local list = {}
    for itemID, info in pairs(locked) do
        table.insert(list, { itemID = itemID, info = info })
    end
    table.sort(list, function(a, b) return tostring(a.info) < tostring(b.info) end)

    local yOff = 0
    for i, item in ipairs(list) do
        local row = rows[i]
        if not row then
            row = CreateFrame("Frame", nil, child, _BACKDROP_TEMPLATE)
            row:SetSize(360, 26)
            _SkinFrame(row)

            row._icon = row:CreateTexture(nil, "OVERLAY")
            row._icon:SetSize(20, 20)
            row._icon:SetPoint("LEFT", 4, 0)
            row._icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

            local unlockBtn = CreateFrame("Button", nil, row, _BACKDROP_TEMPLATE)
            unlockBtn:SetSize(80, 18)
            unlockBtn:SetPoint("RIGHT", -4, 0)
            unlockBtn:SetText("Unlock")
            _SkinButton(unlockBtn)
            row._unlockBtn = unlockBtn

            row._text = GSI_UI:CreateText(row, "SMALL", "")
            row._text:SetPoint("LEFT", row._icon, "RIGHT", 6, 0)
            row._text:SetPoint("RIGHT", unlockBtn, "LEFT", -6, 0)
            row._text:SetJustifyH("LEFT")
            row._text:SetWordWrap(false)

            rows[i] = row
        end

        local itemID = item.itemID
        local itemLink = "item:" .. itemID
        local itemName = GetItemInfo(itemID) or item.info or ("Item " .. itemID)

        row._icon:SetTexture(GetItemIcon(itemID))
        local q = select(3, GetItemInfo(itemID))
        if GSI_UI and GSI_UI.SkinItemIcon then
            GSI_UI:SkinItemIcon(row._icon, row, q)
        end
        row._text:SetText(itemName)
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", child, "TOPLEFT", 0, -yOff)
        row:Show()

        row._unlockBtn:SetScript("OnClick", function()
            if GearSetImproverDB and GearSetImproverDB.lockedCleanUpItems then
                GearSetImproverDB.lockedCleanUpItems[itemID] = nil
            end
            GSI_UI:RefreshLockedCleanUpList(f)
            if GSI_UI.activeTab == "JUNK" and GSI_UI.mainFrame then
                local junkFrame = GSI_UI.mainFrame.tabFrames and GSI_UI.mainFrame.tabFrames["JUNK"]
                if junkFrame then GSI_UI:UpdateJunkList(junkFrame) end
            end
        end)

        row:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetHyperlink(itemLink)
            GameTooltip:Show()
        end)
        row:SetScript("OnLeave", function() GameTooltip:Hide() end)

        yOff = yOff + 28
    end

    if #list == 0 then
        if f._emptyText then f._emptyText:Show() end
    else
        if f._emptyText then f._emptyText:Hide() end
    end
    child:SetHeight(math.max(yOff, 1))
end

function GSI_UI:DrawJunk(parent)
    local title = GSI_UI:CreateText(parent, "TITLE", "Obsolete Gear Clean-up")
    title:SetPoint("TOPLEFT", 15, -15)

    local sub = GSI_UI:CreateText(parent, "SMALL", "Scans bags for obsolete gear. Gray trash is never sold; equipment sets and locked items are safe.")
    sub:SetPoint("TOPLEFT", 15, -38)
    sub:SetPoint("RIGHT", -15, 0)
    sub:SetJustifyH("LEFT")
    sub:SetWordWrap(false)

    local sellAllBtn = CreateFrame("Button", nil, parent, _BACKDROP_TEMPLATE)
    sellAllBtn:SetSize(90, 24)
    sellAllBtn:SetPoint("TOPRIGHT", -15, -12)
    sellAllBtn:SetText("Sell All")
    _SkinButton(sellAllBtn)
    sellAllBtn:SetScript("OnClick", function()
        if not (MerchantFrame and MerchantFrame:IsShown()) then
            print("|cffff4444[GSI]|r Please visit a merchant first!")
            return
        end
        StaticPopup_Show("GSI_CONFIRM_SELL_ALL")
    end)
    parent._sellAllBtn = sellAllBtn

    local refreshBtn = CreateFrame("Button", nil, parent, _BACKDROP_TEMPLATE)
    refreshBtn:SetSize(90, 24)
    refreshBtn:SetPoint("RIGHT", sellAllBtn, "LEFT", -6, 0)
    refreshBtn:SetText("Refresh")
    _SkinButton(refreshBtn)
    refreshBtn:SetScript("OnClick", function() GSI_UI:UpdateJunkList(parent) end)

    local lockedBtn = CreateFrame("Button", nil, parent, _BACKDROP_TEMPLATE)
    lockedBtn:SetSize(100, 24)
    lockedBtn:SetPoint("RIGHT", refreshBtn, "LEFT", -6, 0)
    lockedBtn:SetText("Locked (0)")
    _SkinButton(lockedBtn)
    lockedBtn:SetScript("OnClick", function() GSI_UI:OpenLockedCleanUpDialog(parent) end)
    parent._lockedBtn = lockedBtn

    local deBtnTemplates = "SecureActionButtonTemplate"
    if _BACKDROP_TEMPLATE then deBtnTemplates = deBtnTemplates .. ", " .. _BACKDROP_TEMPLATE end
    local deMacroBtn = CreateFrame("Button", "GSI_CleanUpDisenchantBtn", parent, deBtnTemplates)
    deMacroBtn:SetSize(115, 24)
    deMacroBtn:SetPoint("RIGHT", lockedBtn, "LEFT", -6, 0)
    deMacroBtn:SetText("Disenchant")
    _SkinButton(deMacroBtn)
    GSI_UI:BindDisenchantActionButton(deMacroBtn)
    deMacroBtn:HookScript("OnEnter", function(selfBtn)
        GameTooltip:SetOwner(selfBtn, "ANCHOR_TOP")
        GameTooltip:ClearLines()
        GameTooltip:AddLine("|cffffcc00Disenchant Next Item|r", 1, 1, 1)
        GameTooltip:AddLine("Click repeatedly to disenchant listed obsolete gear items one by one.", 0.9, 0.9, 0.9, true)
        GameTooltip:AddLine("|cff888888Tip: You can also drag out an Action Bar macro in the Settings tab.|r", 0.7, 0.7, 0.7, true)
        GameTooltip:Show()
    end)
    deMacroBtn:HookScript("OnLeave", function() GameTooltip:Hide() end)
    parent._deMacroBtn = deMacroBtn

    local currentThreshold = (GearSetImproverDB and GearSetImproverDB.junkThreshold) or GSI_Config.JunkThreshold or 5
    local sliderLabel = GSI_UI:CreateText(parent, "BODY", string.format("Filter Threshold: Worse by at least %d GSI Score", currentThreshold))
    sliderLabel:SetPoint("TOPLEFT", 15, -58)
    parent._junkSliderLabel = sliderLabel

    local sliderBg = CreateFrame("Frame", nil, parent, _BACKDROP_TEMPLATE)
    sliderBg:SetSize(240, 6)
    sliderBg:SetPoint("TOPLEFT", 15, -80)
    if sliderBg.SetBackdrop then
        sliderBg:SetBackdrop({ bgFile="Interface\\Buttons\\WHITE8x8", edgeFile="Interface\\Buttons\\WHITE8x8", edgeSize=1 })
        sliderBg:SetBackdropColor(0.2, 0.2, 0.2, 1)
        sliderBg:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
    end

    local slider = CreateFrame("Slider", "GSI_JunkSlider", parent)
    slider:SetSize(240, 16)
    slider:SetPoint("TOPLEFT", 15, -76)
    slider:SetMinMaxValues(1, 50)
    slider:SetValue(currentThreshold)
    slider:SetValueStep(1)
    slider:SetOrientation("HORIZONTAL")
    slider:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
    local thumb = slider:GetThumbTexture()
    if thumb and type(thumb) == "table" and thumb.SetSize then
        thumb:SetSize(16, 16)
    end

    slider:SetScript("OnValueChanged", function(self, val)
        local v = math.floor(val)
        GSI_Config.JunkThreshold = v
        if GearSetImproverDB then GearSetImproverDB.junkThreshold = v end
        sliderLabel:SetText(string.format("Filter Threshold: Worse by at least %d GSI Score", v))
        if _G["GSI_SettingsJunkSlider"] and _G["GSI_SettingsJunkSlider"].GetValue and math.floor(_G["GSI_SettingsJunkSlider"]:GetValue()) ~= v then
            _G["GSI_SettingsJunkSlider"]:SetValue(v)
        end
        GSI_UI:UpdateJunkList(parent)
    end)
    parent._junkSlider = slider

    local minLbl = GSI_UI:CreateText(parent, "SMALL", "1")
    minLbl:SetPoint("TOPLEFT", 15, -94)

    local maxLbl = GSI_UI:CreateText(parent, "SMALL", "50")
    maxLbl:SetPoint("TOPLEFT", 235, -94)

    local merchantHeader = GSI_UI:CreateText(parent, "BODY", "Merchant Window:")
    merchantHeader:SetPoint("TOPLEFT", 290, -58)

    local merchantOverlayCheck = CreateFrame("CheckButton", "GSI_JunkMerchantOverlayCheck", parent, "UICheckButtonTemplate")
    merchantOverlayCheck:SetSize(22, 22)
    merchantOverlayCheck:SetPoint("TOPLEFT", 288, -74)
    merchantOverlayCheck.text = GSI_UI:CreateText(merchantOverlayCheck, "BODY", "Show Clean-up sell window at merchant")
    merchantOverlayCheck.text:SetPoint("LEFT", merchantOverlayCheck, "RIGHT", 4, 0)
    merchantOverlayCheck.text:SetWordWrap(false)
    merchantOverlayCheck:SetChecked(not (GearSetImproverDB and GearSetImproverDB.merchantOverlayEnabled == false))
    merchantOverlayCheck:SetScript("OnClick", function(self)
        local isChecked = self:GetChecked() and true or false
        if GSI_UI and GSI_UI.SetMerchantOverlayEnabled then
            GSI_UI:SetMerchantOverlayEnabled(isChecked)
        else
            if not GearSetImproverDB then GearSetImproverDB = {} end
            GearSetImproverDB.merchantOverlayEnabled = isChecked
        end
    end)
    merchantOverlayCheck:SetScript("OnEnter", function(selfBtn)
        GameTooltip:SetOwner(selfBtn, "ANCHOR_RIGHT")
        GameTooltip:AddLine("Show Clean-up sell window at merchant", 1, 0.82, 0)
        GameTooltip:AddLine("Automatically docks a Clean-up sell panel next to the Merchant window with quick 'Sell' and 'Sell All' buttons.", 1, 1, 1, true)
        GameTooltip:Show()
    end)
    merchantOverlayCheck:SetScript("OnLeave", function() GameTooltip:Hide() end)
    GSI_UI.junkMerchantOverlayCheck = merchantOverlayCheck
    parent._merchantOverlayCheck = merchantOverlayCheck

    local armorCheck = CreateFrame("CheckButton", "GSI_JunkArmorCheck", parent, "UICheckButtonTemplate")
    armorCheck:SetSize(22, 22)
    armorCheck:SetPoint("TOPLEFT", 13, -114)
    armorCheck.text = GSI_UI:CreateText(armorCheck, "BODY", "Include other armor classes")
    armorCheck.text:SetPoint("LEFT", armorCheck, "RIGHT", 4, 0)
    armorCheck:SetChecked((GearSetImproverDB and GearSetImproverDB.junkIncludeOtherArmor) or false)
    armorCheck:SetScript("OnClick", function(self)
        local isChecked = self:GetChecked()
        if GearSetImproverDB then GearSetImproverDB.junkIncludeOtherArmor = isChecked end
        if GSI_Config then GSI_Config.JunkIncludeOtherArmor = isChecked end
        local settingsCb = _G["GSI_SettingsArmorCheck"]
        if settingsCb and settingsCb.SetChecked then
            settingsCb:SetChecked(isChecked)
        end
        GSI_UI:UpdateJunkList(parent)
    end)
    parent._armorCheck = armorCheck

    local whiteCheck = CreateFrame("CheckButton", "GSI_JunkWhiteGearCheck", parent, "UICheckButtonTemplate")
    whiteCheck:SetSize(22, 22)
    whiteCheck:SetPoint("TOPLEFT", 225, -114)
    whiteCheck.text = GSI_UI:CreateText(whiteCheck, "BODY", "Include Common (White) gear")
    whiteCheck.text:SetPoint("LEFT", whiteCheck, "RIGHT", 4, 0)
    whiteCheck:SetChecked((GearSetImproverDB and GearSetImproverDB.junkIncludeWhiteGear ~= false))
    whiteCheck:SetScript("OnClick", function(self)
        local isChecked = self:GetChecked()
        if GearSetImproverDB then GearSetImproverDB.junkIncludeWhiteGear = isChecked end
        if GSI_Config then GSI_Config.JunkIncludeWhiteGear = isChecked end
        local settingsCb = _G["GSI_BlizzWhiteGearCheck"]
        if settingsCb and settingsCb.SetChecked then
            settingsCb:SetChecked(isChecked)
        end
        GSI_UI:UpdateJunkList(parent)
    end)
    parent._whiteCheck = whiteCheck

    local unusableCheck = CreateFrame("CheckButton", "GSI_JunkUnusableCheck", parent, "UICheckButtonTemplate")
    unusableCheck:SetSize(22, 22)
    unusableCheck:SetPoint("TOPLEFT", 440, -114)
    unusableCheck.text = GSI_UI:CreateText(unusableCheck, "BODY", "Include unusable gear")
    unusableCheck.text:SetPoint("LEFT", unusableCheck, "RIGHT", 4, 0)
    unusableCheck:SetChecked((GearSetImproverDB and GearSetImproverDB.junkIncludeUnusableGear ~= false))
    unusableCheck:SetScript("OnClick", function(self)
        local isChecked = self:GetChecked()
        if GearSetImproverDB then GearSetImproverDB.junkIncludeUnusableGear = isChecked end
        if GSI_Config then GSI_Config.JunkIncludeUnusableGear = isChecked end
        local settingsCb = _G["GSI_BlizzUnusableGearCheck"]
        if settingsCb and settingsCb.SetChecked then
            settingsCb:SetChecked(isChecked)
        end
        GSI_UI:UpdateJunkList(parent)
    end)
    parent._unusableCheck = unusableCheck

    local status = GSI_UI:CreateText(parent, "SMALL", "")
    status:SetPoint("TOPLEFT", 15, -142)
    parent._junkStatus = status

    local scroll = CreateFrame("ScrollFrame", "GSI_JunkScroll", parent, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 10, -162)
    scroll:SetPoint("BOTTOMRIGHT", -28, 10)
    if GSI_UI and GSI_UI.SkinScrollBar then
        GSI_UI:SkinScrollBar(scroll)
    end

    local scrollChild = CreateFrame("Frame", nil, scroll)
    scrollChild:SetSize(704, 1)
    scroll:SetScrollChild(scrollChild)
    parent._junkScroll = scroll
    parent._junkScrollChild = scrollChild
    parent._junkRows = {}
end

function GSI_UI:UpdateJunkList(parent)
    if not parent or not parent._junkScrollChild then return end
    if InCombatLockdown and InCombatLockdown() then return end

    if parent._armorCheck then
        local isChecked = (GearSetImproverDB and GearSetImproverDB.junkIncludeOtherArmor) or false
        if parent._armorCheck:GetChecked() ~= isChecked then
            parent._armorCheck:SetChecked(isChecked)
        end
    end
    if parent._whiteCheck then
        local isChecked = (GearSetImproverDB and GearSetImproverDB.junkIncludeWhiteGear ~= false)
        if parent._whiteCheck:GetChecked() ~= isChecked then
            parent._whiteCheck:SetChecked(isChecked)
        end
    end
    if parent._unusableCheck then
        local isChecked = (GearSetImproverDB and GearSetImproverDB.junkIncludeUnusableGear ~= false)
        if parent._unusableCheck:GetChecked() ~= isChecked then
            parent._unusableCheck:SetChecked(isChecked)
        end
    end
    if parent._merchantOverlayCheck then
        local isChecked = not (GearSetImproverDB and GearSetImproverDB.merchantOverlayEnabled == false)
        if parent._merchantOverlayCheck:GetChecked() ~= isChecked then
            parent._merchantOverlayCheck:SetChecked(isChecked)
        end
    end

    local countLocked = 0
    if GearSetImproverDB and GearSetImproverDB.lockedCleanUpItems then
        for _ in pairs(GearSetImproverDB.lockedCleanUpItems) do countLocked = countLocked + 1 end
    end
    if parent._lockedBtn then
        parent._lockedBtn:SetText(string.format("Locked (%d)", countLocked))
    end

    local scrollChild = parent._junkScrollChild
    local items = {}
    pcall(function() items = ScanBagsForJunk() end)
    items = items or {}
    local merchantOpen = MerchantFrame and MerchantFrame:IsShown()
    local hasSpell = HasDisenchantSpell()

    if #items == 0 then
        parent._junkStatus:SetText("No obsolete gear found in your bags.")
    else
        local modeText = ""
        if merchantOpen then
            modeText = " |cff00ff00(Merchant open - click item to sell)|r"
        elseif hasSpell then
            modeText = " |cff00ffff(Disenchant ready - click item to disenchant)|r"
        else
            modeText = " |cffff8800(No merchant open)|r"
        end
        parent._junkStatus:SetText(string.format("%d obsolete item(s) found%s", #items, modeText))
    end

    if parent._sellAllBtn then
        if merchantOpen and #items > 0 then
            parent._sellAllBtn:Enable()
            parent._sellAllBtn:SetAlpha(1.0)
        else
            parent._sellAllBtn:Disable()
            parent._sellAllBtn:SetAlpha(0.5)
        end
    end

    if parent._deMacroBtn then
        if hasSpell then
            parent._deMacroBtn:Show()
            local deItems = GSI_UI:GetDisenchantableItems()
            if #deItems > 0 then
                parent._deMacroBtn:Enable()
                parent._deMacroBtn:SetAlpha(1.0)
                parent._deMacroBtn:SetText(string.format("Disenchant (%d)", #deItems))
            else
                parent._deMacroBtn:Disable()
                parent._deMacroBtn:SetAlpha(0.5)
                parent._deMacroBtn:SetText("Disenchant (0)")
            end
            if GSI_UI.SyncExistingDisenchantMacro then
                GSI_UI:SyncExistingDisenchantMacro()
            end
        else
            parent._deMacroBtn:Hide()
        end
    end

    local rows = parent._junkRows
    for _, row in ipairs(rows) do row:Hide() end

    local yOff = 0
    for i, item in ipairs(items) do
        local row = rows[i]
        if not row then
            row = CreateFrame("Button", nil, scrollChild, _BACKDROP_TEMPLATE)
            row:SetSize(700, 28)
            _SkinButton(row)

            row._ilvlText = GSI_UI:CreateText(row, "SMALL", "")
            row._ilvlText:SetPoint("LEFT", 8, 0)
            row._ilvlText:SetWidth(104)
            row._ilvlText:SetJustifyH("LEFT")
            row._ilvlText:SetWordWrap(false)

            row._icon = row:CreateTexture(nil, "OVERLAY")
            row._icon:SetSize(22, 22)
            row._icon:SetPoint("LEFT", row._ilvlText, "RIGHT", 6, 0)
            row._icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

            local lockBtn = CreateFrame("Button", nil, row, _BACKDROP_TEMPLATE)
            lockBtn:SetSize(44, 20)
            lockBtn:SetPoint("RIGHT", -6, 0)
            lockBtn:SetFrameLevel(row:GetFrameLevel() + 5)
            _SkinButton(lockBtn)
            lockBtn:SetText("Lock")
            lockBtn:HookScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:AddLine("Lock Item", 1, 0.82, 0)
                GameTooltip:AddLine("Permanently excludes this item from the clean-up list so it will never be sold.", 0.8, 0.8, 0.8, true)
                GameTooltip:Show()
            end)
            lockBtn:HookScript("OnLeave", function() GameTooltip:Hide() end)
            row._lockBtn = lockBtn

            local sellBtn = CreateFrame("Button", nil, row, _BACKDROP_TEMPLATE)
            sellBtn:SetSize(72, 20)
            sellBtn:SetPoint("RIGHT", lockBtn, "LEFT", -6, 0)
            sellBtn:SetFrameLevel(row:GetFrameLevel() + 5)
            sellBtn:SetText("Sell")
            _SkinButton(sellBtn)
            sellBtn:HookScript("OnEnter", function()
                if row._currentItemLink then
                    GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
                    GameTooltip:SetHyperlink(row._currentItemLink)
                    GameTooltip:Show()
                end
            end)
            sellBtn:HookScript("OnLeave", function() GameTooltip:Hide() end)
            row._sellBtn = sellBtn

            local deTemplates = "SecureActionButtonTemplate"
            if _BACKDROP_TEMPLATE then deTemplates = deTemplates .. ", " .. _BACKDROP_TEMPLATE end
            local deBtn = CreateFrame("Button", nil, row, deTemplates)
            deBtn:SetSize(78, 20)
            deBtn:SetPoint("RIGHT", lockBtn, "LEFT", -6, 0)
            deBtn:SetFrameLevel(row:GetFrameLevel() + 5)
            deBtn:SetText("Disenchant")
            deBtn:RegisterForClicks("AnyUp")
            deBtn:SetAttribute("useOnKeyDown", false)
            _SkinButton(deBtn)
            deBtn:HookScript("OnEnter", function()
                if row._currentItemLink then
                    GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
                    GameTooltip:SetHyperlink(row._currentItemLink)
                    GameTooltip:Show()
                end
            end)
            deBtn:HookScript("OnLeave", function() GameTooltip:Hide() end)
            row._deBtn = deBtn

            row._link = GSI_UI:CreateText(row, "CARD_TITLE", "")
            row._link:SetPoint("LEFT", row._icon, "RIGHT", 8, 0)
            row._link:SetPoint("RIGHT", row, "RIGHT", -142, 0)
            row._link:SetJustifyH("LEFT")
            row._link:SetWordWrap(false)

            rows[i] = row
        end

        row._currentItemLink = item.link

        local qualColor = (ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[item.quality])
                       or (C_Item and C_Item.GetItemQualityColor and C_Item.GetItemQualityColor(item.quality))
        local hex = qualColor and string.format("|cff%02x%02x%02x", qualColor.r*255, qualColor.g*255, qualColor.b*255) or "|cffffffff"

        if item.isUnusable then
            row._ilvlText:SetText(string.format("|cffff4444[%s]|r |cffff4444(-%.0f)|r", item.unusableType or "Unusable", item.delta))
        elseif item.isOtherArmor then
            row._ilvlText:SetText(string.format("|cffffaa00[Armor]|r |cffff4444(-%.0f)|r", item.delta))
        else
            row._ilvlText:SetText(string.format("%s%.0f|r |cffff4444(-%.0f)|r", hex, item.score, item.delta))
        end
        row._link:SetText(item.link)
        row._icon:SetTexture(GetItemIcon(item.link))
        if GSI_UI and GSI_UI.SkinItemIcon then
            GSI_UI:SkinItemIcon(row._icon, row, item.quality)
        end
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -yOff)
        row:Show()

        row:SetScript("OnEnter", function(self)
            self:SetBackdropColor(0.11, 0.11, 0.14, 0.95)
            self:SetBackdropBorderColor(0.24, 0.24, 0.32, 1.0)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetHyperlink(item.link)
            GameTooltip:Show()
        end)
        row:SetScript("OnLeave", function(self)
            self:SetBackdropColor(0.078, 0.078, 0.098, 0.85)
            self:SetBackdropBorderColor(0.11, 0.11, 0.14, 1.0)
            GameTooltip:Hide()
        end)

        local bagID, slotID = item.bagID, item.slotID
        local itemLink = item.link

        row._lockBtn:SetScript("OnClick", function()
            local itemID = tonumber(itemLink:match("item:(%d+)"))
            if itemID then
                GearSetImproverDB.lockedCleanUpItems = GearSetImproverDB.lockedCleanUpItems or {}
                local itemName = GetItemInfo(itemLink) or itemLink
                GearSetImproverDB.lockedCleanUpItems[itemID] = itemName
                print(string.format("|cffffcc00[GSI]|r %s locked. Excluded from clean-up list.", itemLink))
                GSI_UI:UpdateJunkList(parent)
            end
        end)

        if merchantOpen then
            row._deBtn:Hide()
            row._sellBtn:Show()
            row._sellBtn:Enable()
            row._sellBtn:SetText("Sell")
            row._sellBtn:SetScript("OnClick", function()
                SafeUseBagItem(bagID, slotID)
                C_Timer.After(0.15, function()
                    if GSI_UI.activeTab == "JUNK" and GSI_UI.mainFrame and GSI_UI.mainFrame:IsShown() then
                        local frame = GSI_UI.mainFrame.tabFrames and GSI_UI.mainFrame.tabFrames["JUNK"]
                        if frame then GSI_UI:UpdateJunkList(frame) end
                    end
                end)
            end)
        elseif hasSpell and item.quality and item.quality >= 2 then
            row._sellBtn:Hide()
            row._deBtn:Show()
            row._deBtn:Enable()
            row._deBtn:SetText("Disenchant")
            row._deBtn:SetAttribute("type", "spell")
            row._deBtn:SetAttribute("type1", "spell")
            row._deBtn:SetAttribute("*type1", "spell")
            row._deBtn:SetAttribute("spell", 13262)
            row._deBtn:SetAttribute("spell1", 13262)
            row._deBtn:SetAttribute("*spell1", 13262)
            row._deBtn:SetAttribute("target-bag", bagID)
            row._deBtn:SetAttribute("target-bag1", bagID)
            row._deBtn:SetAttribute("*target-bag1", bagID)
            row._deBtn:SetAttribute("target-slot", slotID)
            row._deBtn:SetAttribute("target-slot1", slotID)
            row._deBtn:SetAttribute("*target-slot1", slotID)
        else
            row._deBtn:Hide()
            row._sellBtn:Show()
            row._sellBtn:SetText("---")
            row._sellBtn:Disable()
            row._sellBtn:SetScript("OnClick", nil)
        end

        yOff = yOff + 32
    end

    if #items == 0 then
        if not parent._junkEmptyText then
            parent._junkEmptyText = GSI_UI:CreateText(scrollChild, "BODY", "")
            parent._junkEmptyText:SetPoint("CENTER", parent._junkScroll or scrollChild, "CENTER", 0, 0)
            parent._junkEmptyText:SetTextColor(0.5, 0.5, 0.5)
        end
        parent._junkEmptyText:SetText("No obsolete gear found.")
        parent._junkEmptyText:Show()
    else
        if parent._junkEmptyText then parent._junkEmptyText:Hide() end
    end

    scrollChild:SetHeight(math.max(yOff, 1))
end