-- ============================================================
-- GearSetImprover - GearSetImprover.lua (WoW Forever)
-- Main entry point. Initializes all modules on PLAYER_LOGIN.
-- ============================================================

local L = GSI_L

local ADDON_NAME = "GearSetImprover"
local VERSION = (C_AddOns and C_AddOns.GetAddOnMetadata and C_AddOns.GetAddOnMetadata(ADDON_NAME, "Version"))
    or (GetAddOnMetadata and GetAddOnMetadata(ADDON_NAME, "Version"))
    or "1.4.1"

local print = function(...)
    if GSI_Print then
        GSI_Print(...)
    elseif not (GearSetImproverDB and (GearSetImproverDB.disableChatOutput or GearSetImproverDB.disableChat)) then
        _G.print(...)
    end
end

local DB_DEFAULTS = {
    enabled                 = true,
    disableChatOutput       = false,      -- Suppress all addon chat messages
    customWeights           = {},
    weightProfiles          = {},         -- Named profiles per specKey: weightProfiles[specKey][profileName] = weights
    activeProfile           = {},         -- Active profile name per specKey: activeProfile[specKey] = "ProfileName"
    debug                   = false,
    weightMode              = "ST",       -- ST or AOE
    tankMode                = "Survival", -- Survival or DMG
    bibThreshold            = 50,         -- Best-in-Bag threshold
    ignoredItems            = {},         -- Legacy ignored items
    lockedCleanUpItems      = {},         -- Items locked/blacklisted from Clean-up
    lockedGearSlots         = {},         -- Slots locked from replacement in Best Available Gear
    tutorialSeen            = false,      -- First-time tutorial seen flag
    selectedSpec            = nil,        -- Manually selected spec (1, 2, 3, or 4)
    showMinimap             = true,       -- Show or hide Minimap button
    minimapPos              = 45,         -- Angle around Minimap (degrees)
    junkThreshold           = 5,          -- Clean-up threshold (Items worse by > 5 Score)
    junkIncludeOtherArmor   = false,      -- Include items of other armor classes in Clean-up
    junkIncludeWhiteGear    = true,       -- Include Common (White) obsolete gear in Clean-up
    junkIncludeUnusableGear = true,       -- Include gear the player's class cannot equip in Clean-up
    autoSaveEquipmentSet    = true,       -- Automatically save equipped gear as Equipment Set in Character Profile
    enableUpgradeToast      = true,       -- Show on-screen toast alert for gear upgrades
    toastDuration           = 60,         -- Toast auto-dismiss duration in seconds
    toastBlink              = true,       -- Pulsing/blinking glow effect on toast
    toastPlaySound          = true,       -- Play alert sound on upgrade detection
    toastMinDelta           = 1.0,        -- Minimum score increase required to trigger toast
    toastAnchor             = { point = "TOP", relPoint = "TOP", x = 0, y = -170 }, -- Screen anchor position
    toastDismissedItems     = {},         -- Items dismissed/equipped via toast notification (never notify again)
    ignoreEnchants          = true,       -- Ignore item enchants in item scores and comparisons by default
    enabledSpellSchools     = {},         -- Checkbox state for magic school spell power per specKey
    merchantOverlayEnabled  = true,       -- Show item score overlays on vendor/merchant icons
}

-- ---------------------------------------------------------------
-- DB INITIALIZATION
-- ---------------------------------------------------------------
local function InitDB()
    if not GearSetImproverDB then
        GearSetImproverDB = {}
    end
    if not GearSetImproverLog then
        GearSetImproverLog = {}
    end
    for k, v in pairs(DB_DEFAULTS) do
        if GearSetImproverDB[k] == nil then
            GearSetImproverDB[k] = v
        end
    end
    if not GearSetImproverDB.weightProfiles then
        GearSetImproverDB.weightProfiles = {}
    end
    if not GearSetImproverDB.activeProfile then
        GearSetImproverDB.activeProfile = {}
    end
    if not GearSetImproverDB.enabledSpellSchools then
        GearSetImproverDB.enabledSpellSchools = {}
    end
    if not GearSetImproverDB.toastDismissedItems then
        GearSetImproverDB.toastDismissedItems = {}
    end
    -- One-time cleanup for items prematurely marked dismissed by prior UseContainerItem false-positive bug
    if not GearSetImproverDB.toastDismissedResetV138 then
        GearSetImproverDB.toastDismissedItems = {}
        GearSetImproverDB.toastDismissedResetV138 = true
    end

    -- Migrate legacy customWeights to weightProfiles
    if GearSetImproverDB.customWeights then
        for sKey, wTable in pairs(GearSetImproverDB.customWeights) do
            if type(wTable) == "table" and next(wTable) ~= nil then
                if not GearSetImproverDB.weightProfiles[sKey] then
                    GearSetImproverDB.weightProfiles[sKey] = {}
                end
                if not GearSetImproverDB.weightProfiles[sKey]["Custom"] then
                    if type(_G.CopyTable) == "function" then
                        GearSetImproverDB.weightProfiles[sKey]["Custom"] = _G.CopyTable(wTable)
                    else
                        local copy = {}
                        for k, v in pairs(wTable) do copy[k] = v end
                        GearSetImproverDB.weightProfiles[sKey]["Custom"] = copy
                    end
                end
                if not GearSetImproverDB.activeProfile[sKey] then
                    GearSetImproverDB.activeProfile[sKey] = "Custom"
                end
            end
        end
    end

    -- Migration for Druid 4-spec split: Move legacy Restoration (3) to (4)
    local playerClass = (GSI_ClassicData and GSI_ClassicData.GetPlayerClass and GSI_ClassicData:GetPlayerClass())
        or select(2, UnitClass("player")) or "WARRIOR"
    if playerClass == "DRUID" and not GearSetImproverDB.druidSpecV2 then
        if GearSetImproverDB.selectedSpec == 3 then
            GearSetImproverDB.selectedSpec = 4
        end
        GearSetImproverDB.druidSpecV2 = true
    end

    if GearSetImproverDB.merchantOverlayEnabled == nil then
        GearSetImproverDB.merchantOverlayEnabled = true
    end

    if GSI_Config then
        GSI_Config.JunkThreshold = GearSetImproverDB.junkThreshold
        GSI_Config.IgnoreEnchants = GearSetImproverDB.ignoreEnchants
        GSI_Config.MerchantOverlayEnabled = (GearSetImproverDB.merchantOverlayEnabled ~= false)
    end
end

-- ---------------------------------------------------------------
-- EVENT FRAME
-- ---------------------------------------------------------------
local talentRefreshPending = false
local equipRefreshPending = false

local function DispatchTalentRefresh()
    talentRefreshPending = false
    if GSI_UI and GSI_UI.UpdateSpecButton then
        pcall(GSI_UI.UpdateSpecButton, GSI_UI)
    end
    -- Talents change the weights: the bag scan result and the tooltips that
    -- are open were built with the old ones.
    if GSI_UI and GSI_UI.MarkScanStale then
        pcall(GSI_UI.MarkScanStale, GSI_UI)
    end
    if GSI_TooltipHook and GSI_TooltipHook.RefreshShownTooltips then
        pcall(GSI_TooltipHook.RefreshShownTooltips, GSI_TooltipHook)
    end
    if GSI_UI and GSI_UI.RefreshPanel then
        pcall(GSI_UI.RefreshPanel, GSI_UI)
    end
end

local function DispatchEquipRefresh()
    equipRefreshPending = false
    if GSI_UI and GSI_UI.isEquippingAll then
        return
    end
    if GSI_UI and GSI_UI.UpdateTitleScore then
        pcall(GSI_UI.UpdateTitleScore, GSI_UI)
    end
    if GSI_UI and GSI_UI.mainFrame and GSI_UI.mainFrame:IsShown() and GSI_UI.RefreshPanel then
        pcall(GSI_UI.RefreshPanel, GSI_UI)
    end
end

local eventFrame = CreateFrame("Frame", "GSIEventFrame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("CHARACTER_POINTS_CHANGED")
eventFrame:RegisterEvent("PLAYER_TALENT_UPDATE")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
pcall(function() eventFrame:RegisterEvent("EQUIPMENT_SWAP_FINISHED") end)
eventFrame:RegisterEvent("BAG_UPDATE_DELAYED")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")

eventFrame:SetScript("OnEvent", function(self, event, arg1)
    -- ===== ADDON_LOADED =====
    if event == "ADDON_LOADED" and (arg1 == ADDON_NAME or arg1 == "GearSetImprover Forever" or arg1 == "GearSetImprover") then
        InitDB()
        return
    end

    -- ===== PLAYER_LOGIN =====
    if event == "PLAYER_LOGIN" then
        if not GearSetImproverDB then InitDB() end

        local modules = {
            { "TalentIntegration", function() GSI_TalentIntegration:Invalidate() end },
            { "SetBonus",          function() GSI_SetBonus:UpdateEquippedSets() end },
            { "TooltipHook",       function() GSI_TooltipHook:Initialize() end },
            { "UI",                function() GSI_UI:Initialize() end },
            { "MinimapButton",     function() if GSI_MinimapButton then GSI_MinimapButton:Initialize() end end },
            { "UpgradeToast",      function() if GSI_UpgradeToast then GSI_UpgradeToast:Initialize() end end },
        }

        for _, m in ipairs(modules) do
            local ok, err = pcall(m[2])
            if not ok then
                print(string.format(L["|cffff4444GearSetImprover|r: Module %s error: %s"], m[1], tostring(err)))
            end
        end

        pcall(function()
            local class = (GSI_ClassicData and GSI_ClassicData.GetPlayerClass and GSI_ClassicData:GetPlayerClass())
                or select(2, UnitClass("player")) or "WARRIOR"
            local specIdx = GSI_StatWeights:GetActiveSpecIndex()
            local classData = GSI_ClassicData.Classes[class]
            local specName = classData and classData.specs and classData.specs[specIdx] and (classData.specs[specIdx].name or classData.specs[specIdx].nameDE) or string.format(L["Spec %s"], tostring(specIdx))
            local className = classData and (classData.name or classData.nameDE) or class
            print(string.format(
                L["|cffffcc00GearSetImprover Forever|r v%s loaded for |cff00ff00%s %s|r - Type |cffffcc00/gsi|r to open the menu"],
                VERSION, L[specName], L[className]
            ))

            if GearSetImproverDB and not GearSetImproverDB.tutorialSeen then
                if C_Timer and C_Timer.After then
                    C_Timer.After(2.0, function()
                        if GSI_UI and GSI_UI.OpenTutorial then
                            GSI_UI:OpenTutorial()
                        end
                    end)
                end
            end
        end)
        return
    end

    -- ===== TALENT UPDATE =====
    if event == "CHARACTER_POINTS_CHANGED" or event == "PLAYER_TALENT_UPDATE" then
        if GSI_ItemScore and GSI_ItemScore.ResetCache then
            pcall(GSI_ItemScore.ResetCache, GSI_ItemScore)
        end
        if GSI_TalentIntegration and GSI_TalentIntegration.Invalidate then
            pcall(GSI_TalentIntegration.Invalidate, GSI_TalentIntegration)
        end
        if C_Timer and C_Timer.After then
            if not talentRefreshPending then
                talentRefreshPending = true
                C_Timer.After(0.05, DispatchTalentRefresh)
            end
        else
            DispatchTalentRefresh()
        end
        return
    end

    -- ===== ENTERING WORLD (Reload / Login) =====
    if event == "PLAYER_ENTERING_WORLD" then
        if GSI_SetBonus and GSI_SetBonus.UpdateEquippedSets then
            pcall(GSI_SetBonus.UpdateEquippedSets, GSI_SetBonus)
        end
        return
    end

    -- ===== EQUIPMENT CHANGED =====
    if event == "PLAYER_EQUIPMENT_CHANGED" or event == "EQUIPMENT_SWAP_FINISHED" then
        if GSI_UpgradeToast and GSI_UpgradeToast.CheckIfCurrentEquipped then
            pcall(GSI_UpgradeToast.CheckIfCurrentEquipped, GSI_UpgradeToast)
        end
        if GSI_ItemScore and GSI_ItemScore.ResetCache then
            GSI_ItemScore:ResetCache()
        end
        if GSI_OptimizationEngine and GSI_OptimizationEngine.ResetCache then
            GSI_OptimizationEngine:ResetCache()
        end
        if GSI_SetBonus and GSI_SetBonus.UpdateEquippedSets then
            pcall(GSI_SetBonus.UpdateEquippedSets, GSI_SetBonus)
        end

        if not (GSI_UI and GSI_UI.isEquippingAll) then
            if C_Timer and C_Timer.After then
                if not equipRefreshPending then
                    equipRefreshPending = true
                    C_Timer.After(0.05, DispatchEquipRefresh)
                end
            else
                DispatchEquipRefresh()
            end
        end

        if InCombatLockdown and InCombatLockdown() then
            if GSI_UI then
                GSI_UI.needsCombatOptimization = true
            end
            return
        end

        if GSI_UI and GSI_UI.isEquippingAll then
            return
        end

        -- Schedule a full optimization pass automatically after gear changes settle
        if GSI_UI and GSI_UI.ScheduleOptimization then
            GSI_UI:ScheduleOptimization(0.15, false)
        elseif GSI_UI and GSI_UI.RunOptimization then
            GSI_UI:RunOptimization()
        end
        return
    end

    -- ===== COMBAT ENDED =====
    if event == "PLAYER_REGEN_ENABLED" then
        if GSI_UI and GSI_UI.needsCombatOptimization then
            GSI_UI.needsCombatOptimization = false
            if GSI_UI.ScheduleOptimization then
                GSI_UI:ScheduleOptimization(0.2, false)
            end
        end
        return
    end

    -- ===== BAGS UPDATED =====
    if event == "BAG_UPDATE_DELAYED" then
        if GSI_UpgradeToast and GSI_UpgradeToast.OnBagUpdate then
            pcall(GSI_UpgradeToast.OnBagUpdate, GSI_UpgradeToast)
        end
        return
    end
end)
