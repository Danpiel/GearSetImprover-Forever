-- ============================================================
-- GearSetImprover - EllesmereUI.lua (WoW Forever)
-- GearSetImprover's settings as a section of the EllesmereUI options panel
-- (EllesmereUI's plugin API, PLUGINS_API.md in the EllesmereUI folder):
--   General       General / Upgrade Toasts / Clean-up
--   Specs & Sets  Options, then a page per spec of the class: its tooltip
--                 lines, its Equipment Sets with the weights each one turns
--                 on, and its talent group.
-- Without EllesmereUI nothing here runs; the game's Options > AddOns page
-- (UI_BlizzardOptions.lua) has the settings either way.
-- ============================================================

GSI_EllesmereUI = GSI_EllesmereUI or {}
local L = GSI_L

local PLUGIN_ID = "GearSetImprover"
-- Page names (plain text, unique): shown in the panel, compared in buildPage
local PAGE_GENERAL = L["General"]
local PAGE_TOASTS = L["Upgrade Toasts"]
local PAGE_CLEANUP = L["Clean-up"]
local PAGE_OPTIONS = L["Options"]
local registered = false

local function DB()
    if not GearSetImproverDB then GearSetImproverDB = {} end
    return GearSetImproverDB
end

-- A setting that is on unless set to false (or off unless set to true)
local function Flag(key, default)
    local v = GearSetImproverDB and GearSetImproverDB[key]
    if v == nil then return default end
    return v == true
end

local function PlayerClass()
    return (GSI_ClassicData and GSI_ClassicData.GetPlayerClass and GSI_ClassicData:GetPlayerClass())
        or select(2, UnitClass("player")) or "WARRIOR"
end

local function ClassSpecs()
    local class = PlayerClass()
    local cd = GSI_ClassicData and GSI_ClassicData.Classes and GSI_ClassicData.Classes[class]
    local list = {}
    local num = (class == "DRUID") and 4 or 3
    for i = 1, num do
        local sd = cd and cd.specs and cd.specs[i]
        list[i] = (sd and sd.name) and L[sd.name] or string.format(L["Spec %d"], i)
    end
    return list
end

local function RefreshTooltips()
    if GSI_TooltipHook and GSI_TooltipHook.RefreshShownTooltips then
        pcall(GSI_TooltipHook.RefreshShownTooltips, GSI_TooltipHook)
    end
end

local function ResetScores()
    if GSI_ItemScore and GSI_ItemScore.ResetCache then pcall(GSI_ItemScore.ResetCache, GSI_ItemScore) end
    if GSI_OptimizationEngine and GSI_OptimizationEngine.ResetCache then
        pcall(GSI_OptimizationEngine.ResetCache, GSI_OptimizationEngine)
    end
    RefreshTooltips()
    if GSI_UI and GSI_UI.RefreshPanel and GSI_UI.mainFrame and GSI_UI.mainFrame:IsShown() then
        pcall(GSI_UI.RefreshPanel, GSI_UI, true)
    end
end

-- The Clean-up tab of the GSI window follows a change made here
local function SyncJunkTab()
    local jf = GSI_UI and GSI_UI.mainFrame and GSI_UI.mainFrame.tabFrames and GSI_UI.mainFrame.tabFrames["JUNK"]
    if not jf then return end
    local db = GearSetImproverDB or {}
    if jf._junkSlider and db.junkThreshold and math.floor(jf._junkSlider:GetValue()) ~= db.junkThreshold then
        jf._junkSlider:SetValue(db.junkThreshold)
    end
    if jf._armorCheck and jf._armorCheck.SetChecked then jf._armorCheck:SetChecked(db.junkIncludeOtherArmor == true) end
    if jf._whiteCheck and jf._whiteCheck.SetChecked then jf._whiteCheck:SetChecked(db.junkIncludeWhiteGear ~= false) end
    if jf._unusableCheck and jf._unusableCheck.SetChecked then jf._unusableCheck:SetChecked(db.junkIncludeUnusableGear ~= false) end
    if GSI_UI.activeTab == "JUNK" and GSI_UI.mainFrame:IsShown() and GSI_UI.UpdateJunkList then
        pcall(GSI_UI.UpdateJunkList, GSI_UI, jf)
    end
end

-- Rebuilds a module's page when it is on screen, else drops its cached pages
local rebuildQueued = {}
local function Rebuild(moduleKey)
    if not (EllesmereUI and EllesmereUI.GetPluginModuleKey) then return end
    local full = EllesmereUI.GetPluginModuleKey(PLUGIN_ID, moduleKey)
    if not full or rebuildQueued[full] then return end
    rebuildQueued[full] = true
    -- Never from inside a widget's own handler: the page is torn down
    C_Timer.After(0, function()
        rebuildQueued[full] = nil
        if EllesmereUI.GetActiveModule and EllesmereUI:GetActiveModule() == full then
            EllesmereUI:RefreshPage(true)
        elseif EllesmereUI.InvalidateModulePageCache then
            EllesmereUI:InvalidateModulePageCache(full)
        end
    end)
end

-- ------------------------------------------------------------
-- General
-- ------------------------------------------------------------

local function BuildGeneral(pageName, parent, yOffset)
    local W = EllesmereUI.Widgets
    local y = yOffset
    local _, h

    if pageName == PAGE_GENERAL then
        _, h = W:SectionHeader(parent, "GEARSETIMPROVER", y); y = y - h
        _, h = W:Toggle(parent, L["Enable GearSetImprover"], y,
            function() return Flag("enabled", true) end,
            function(v) DB().enabled = v and true or false; RefreshTooltips() end,
            L["Scores in tooltips, upgrade toasts and the GSI window."]); y = y - h
        _, h = W:Button(parent, L["Open GearSetImprover"], y, function()
            if GSI_UI and GSI_UI.mainFrame and not GSI_UI.mainFrame:IsShown() and GSI_UI.Toggle then GSI_UI:Toggle() end
        end); y = y - h
        _, h = W:Toggle(parent, L["Show the minimap button"], y,
            function() return Flag("showMinimap", true) end,
            function(v)
                DB().showMinimap = v and true or false
                if GSI_MinimapButton and GSI_MinimapButton.Toggle then GSI_MinimapButton:Toggle(v) end
            end); y = y - h
        _, h = W:Toggle(parent, L["Silent mode (no chat output)"], y,
            function() return Flag("disableChatOutput", false) end,
            function(v) DB().disableChatOutput = v and true or false end); y = y - h

        _, h = W:SectionHeader(parent, L["SCORING"], y); y = y - h
        _, h = W:Toggle(parent, L["Ignore item enchants"], y,
            function() return Flag("ignoreEnchants", true) end,
            function(v)
                DB().ignoreEnchants = v and true or false
                if GSI_Config then GSI_Config.IgnoreEnchants = v and true or false end
                ResetScores()
            end,
            L["Scores and comparisons leave enchants out, so an item is judged by itself."]); y = y - h
        _, h = W:Toggle(parent, L["Include situational effects"], y,
            function() return Flag("includeSituational", true) end,
            function(v) DB().includeSituational = v and true or false; ResetScores() end,
            L["Effects such as bonuses against Undead or Dragonkin count in the score."]); y = y - h
        _, h = W:Toggle(parent, L["Save Equipment Sets when GSI equips gear"], y,
            function() return Flag("autoSaveEquipmentSet", true) end,
            function(v) DB().autoSaveEquipmentSet = v and true or false end,
            L["/gsi equip saves what it put on as the spec's set (\"Cat ST\", \"Resto AoE\", ...)."]); y = y - h
        _, h = W:Toggle(parent, L["Debug: stat weights in tooltips"], y,
            function() return Flag("debug", false) end,
            function(v) DB().debug = v and true or false; RefreshTooltips() end); y = y - h

    elseif pageName == PAGE_TOASTS then
        _, h = W:SectionHeader(parent, L["UPGRADE TOASTS"], y); y = y - h
        _, h = W:Toggle(parent, L["Show upgrade toasts"], y,
            function() return Flag("enableUpgradeToast", true) end,
            function(v) DB().enableUpgradeToast = v and true or false end,
            L["A toast when an item you pick up is an upgrade, with a button that puts it on. After a spec change toasts wait until the spec's set is on."]); y = y - h
        _, h = W:Toggle(parent, L["Pulsing glow"], y,
            function() return Flag("toastBlink", true) end,
            function(v) DB().toastBlink = v and true or false end); y = y - h
        _, h = W:Toggle(parent, L["Alert sound"], y,
            function() return Flag("toastPlaySound", true) end,
            function(v) DB().toastPlaySound = v and true or false end); y = y - h
        _, h = W:Slider(parent, L["Display duration (seconds)"], y, 10, 120, 5,
            function() return (GearSetImproverDB and GearSetImproverDB.toastDuration) or 60 end,
            function(v) DB().toastDuration = math.floor(v + 0.5) end); y = y - h
        _, h = W:Button(parent, L["Test toast"], y, function()
            if GSI_UpgradeToast and GSI_UpgradeToast.TestToast then GSI_UpgradeToast:TestToast() end
        end); y = y - h

        _, h = W:SectionHeader(parent, L["POSITION"], y); y = y - h
        _, h = W:Button(parent, L["Move the toast"], y, function()
            if GSI_UpgradeToast and GSI_UpgradeToast.ToggleAnchor then
                GSI_UpgradeToast:ToggleAnchor(not GSI_UpgradeToast:IsAnchorShown())
            end
        end); y = y - h
        _, h = W:Button(parent, L["Reset position"], y, function()
            if GSI_UpgradeToast and GSI_UpgradeToast.ResetAnchor then GSI_UpgradeToast:ResetAnchor() end
        end); y = y - h

    elseif pageName == PAGE_CLEANUP then
        _, h = W:SectionHeader(parent, L["OUTDATED GEAR"], y,
            L["The Clean-up tab lists gear in your bags that is worse than what you wear. Gray trash is never sold; Equipment Sets are protected."]); y = y - h
        _, h = W:Slider(parent, L["Worse by at least (GSI Score)"], y, 1, 50, 1,
            function() return (GearSetImproverDB and GearSetImproverDB.junkThreshold) or 5 end,
            function(v)
                v = math.floor(v + 0.5)
                DB().junkThreshold = v
                if GSI_Config then GSI_Config.JunkThreshold = v end
                SyncJunkTab()
            end); y = y - h
        _, h = W:Toggle(parent, L["Include other armor classes"], y,
            function() return Flag("junkIncludeOtherArmor", false) end,
            function(v)
                DB().junkIncludeOtherArmor = v and true or false
                if GSI_Config then GSI_Config.JunkIncludeOtherArmor = v and true or false end
                SyncJunkTab()
            end, L["For example Leather or Mail on a Mage."]); y = y - h
        _, h = W:Toggle(parent, L["Include common (white) gear"], y,
            function() return Flag("junkIncludeWhiteGear", true) end,
            function(v)
                DB().junkIncludeWhiteGear = v and true or false
                if GSI_Config then GSI_Config.JunkIncludeWhiteGear = v and true or false end
                SyncJunkTab()
            end); y = y - h
        _, h = W:Toggle(parent, L["Include gear you cannot use"], y,
            function() return Flag("junkIncludeUnusableGear", true) end,
            function(v)
                DB().junkIncludeUnusableGear = v and true or false
                if GSI_Config then GSI_Config.JunkIncludeUnusableGear = v and true or false end
                SyncJunkTab()
            end); y = y - h
        _, h = W:Toggle(parent, L["Sell window at the merchant"], y,
            function() return Flag("merchantOverlayEnabled", true) end,
            function(v)
                if GSI_UI and GSI_UI.SetMerchantOverlayEnabled then
                    GSI_UI:SetMerchantOverlayEnabled(v and true or false)
                else
                    DB().merchantOverlayEnabled = v and true or false
                end
                SyncJunkTab()
            end, L["A window docked to the merchant with the Clean-up list and 'Sell All'."]); y = y - h
    end
    return math.abs(y)
end

-- ------------------------------------------------------------
-- Specs & Sets
-- ------------------------------------------------------------

local function SetsChanged()
    Rebuild("Specs")
    if GSI_UI and GSI_UI.RefreshSpecSetRows then pcall(GSI_UI.RefreshSpecSetRows) end
    RefreshTooltips()
end

local function BuildSpecOptions(parent, y)
    local W = EllesmereUI.Widgets
    local _, h
    _, h = W:SectionHeader(parent, L["SPEC AND GEAR"], y); y = y - h
    _, h = W:Toggle(parent, L["Detect the spec from your talents"], y,
        function() return not GSI_StatWeights or not GSI_StatWeights.IsSpecAuto or GSI_StatWeights:IsSpecAuto() end,
        function(v)
            if GSI_StatWeights and GSI_StatWeights.SetSpecAuto then GSI_StatWeights:SetSpecAuto(v and true or false) end
            Rebuild("Specs")
        end,
        L["Follows respecs and dual spec. Picking a spec in the GSI window's header pins it and turns this off. Feral druids: your last Cat or Bear pick decides."]); y = y - h
    _, h = W:Toggle(parent, L["Equip the spec's set when your spec changes"], y,
        function() return not GSI_UI.IsSpecSetAutoEquip or GSI_UI:IsSpecSetAutoEquip() end,
        function(v) DB().specSetAutoEquip = v and true or false end,
        L["After a spec change the spec's set goes on (after combat if you are fighting); with several sets you pick one. Its weights go on with it."]); y = y - h
    _, h = W:Toggle(parent, L["A set you put on turns its spec and weights on"], y,
        function() return not GSI_UI.IsSetChangesWeights or GSI_UI:IsSetChangesWeights() end,
        function(v) DB().setChangesWeights = v and true or false end,
        L["Putting on one of the sets on the spec pages (with the Equipment Manager, another addon or GSI) makes its spec the one scored and turns its weights on. The spec your talents play goes back to Auto."]); y = y - h
    _, h = W:Toggle(parent, L["Weights picked in GSI put on their set"], y,
        function() return not GSI_UI.IsWeightsEquipSet or GSI_UI:IsWeightsEquipSet() end,
        function(v) DB().weightsEquipSet = v and true or false end,
        L["Picking a mode or a spec in the GSI window's header (or /gsi mode, /gsi spec) puts on that spec's set for those weights, after combat if you are fighting. A spec without a set for them: its only set, or you choose one."]); y = y - h
    _, h = W:Toggle(parent, L["Tooltips: a line for every set of every spec"], y,
        function() return not GSI_UI.IsCompareSpecSets or GSI_UI:IsCompareSpecSets() end,
        function(v) DB().compareSpecSets = v and true or false; RefreshTooltips() end,
        L["Every spec gets a tooltip line per set on its page, scored with the set's weights. Off: only the ticked lines, against the gear you wear."]); y = y - h
    return y
end

local function BuildSpecPage(specIndex, parent, y)
    local W = EllesmereUI.Widgets
    local _, h
    local class = PlayerClass()

    -- Tooltip lines against the gear worn, one per mode
    local ticks = {}
    for _, p in ipairs((GSI_UI.GetClassProfiles and GSI_UI:GetClassProfiles(class)) or {}) do
        if p.specIndex == specIndex then
            local key = p.key
            ticks[#ticks + 1] = {
                type = "toggle",
                text = string.format(L["Line: %s"], p.modeLabel or p.mode),
                getValue = function()
                    local t = GearSetImproverDB and GearSetImproverDB.tooltipProfiles
                    return (t and t[class] and t[class][key]) == true
                end,
                setValue = function(v)
                    local db = DB()
                    db.tooltipProfiles = db.tooltipProfiles or {}
                    db.tooltipProfiles[class] = db.tooltipProfiles[class] or {}
                    db.tooltipProfiles[class][key] = v and true or false
                    if GSI_TooltipCache and GSI_TooltipCache.Invalidate then GSI_TooltipCache:Invalidate() end
                    RefreshTooltips()
                    if GSI_UI.RefreshSpecSetRows then pcall(GSI_UI.RefreshSpecSetRows) end
                end,
            }
        end
    end
    _, h = W:SectionHeader(parent, L["TOOLTIP VS WORN GEAR"], y,
        L["Tooltip lines scored with these weights against the gear you wear. A spec you are not playing that has sets compares with its sets instead."]); y = y - h
    if #ticks > 0 then
        _, h = W:DualRow(parent, y, ticks[1], ticks[2]); y = y - h
    end

    -- The spec's sets, each with the weights it turns on
    local modeNow = GSI_UI.GetCurrentModeFor and GSI_UI:GetCurrentModeFor(specIndex)
    local names, isManual = GSI_UI:GetSpecSets(specIndex, modeNow)
    _, h = W:SectionHeader(parent, isManual and L["EQUIPMENT SETS"] or L["EQUIPMENT SETS (AUTO)"], y,
        isManual and L["Your own list of sets for this spec."]
        or L["Auto: the sets GSI saved for the spec (\"Cat ST\", \"Resto AoE\", ...), also those it saves later. Adding or removing one makes the list your own."]); y = y - h

    local modes = GSI_UI:GetSpecModes(specIndex)
    for _, setName in ipairs(names) do
        local exists = C_EquipmentSet and C_EquipmentSet.GetEquipmentSetID and C_EquipmentSet.GetEquipmentSetID(setName)
        local label = setName
        if not exists then
            label = string.format(L["%s (missing)"], setName)
        else
            local okI, _, _, _, isEquipped = pcall(C_EquipmentSet.GetEquipmentSetInfo, exists)
            if okI and isEquipped then label = string.format(L["%s (on)"], setName) end
        end
        local values = {
            [modes[1]] = GSI_UI:GetModeLabel(modes[1]),
            [modes[2]] = GSI_UI:GetModeLabel(modes[2]),
            keep = L["Keep the weights"],
            remove = L["Remove from this spec"],
            _noLoc = true,
        }
        _, h = W:Dropdown(parent, label, y, values,
            function() return GSI_UI:GetSetMode(specIndex, setName) or "keep" end,
            function(v)
                if v == "remove" then
                    GSI_UI:ToggleSpecSet(specIndex, setName)
                    SetsChanged()
                    return
                end
                GSI_UI:SetSetMode(specIndex, setName, (v ~= "keep") and v or nil)
                if GSI_UI.RefreshSpecSetRows then pcall(GSI_UI.RefreshSpecSetRows) end
            end,
            { modes[1], modes[2], "keep", "remove" },
            L["The weights this set turns on when it goes on while you play this spec (the \"which set?\" prompt, /gsi go, the dual spec macro or the Equipment Manager). Its tooltip line is scored with them."]); y = y - h
    end

    -- Add one of the character's other sets
    local have = {}
    for _, n in ipairs(names) do have[n] = true end
    local addValues, addOrder = { none = L["Choose a set"], _noLoc = true }, { "none" }
    for _, s in ipairs(GSI_UI:GetEquipmentSetList()) do
        if not have[s.name] then
            addValues[s.name] = s.name
            addOrder[#addOrder + 1] = s.name
        end
    end
    if #addOrder > 1 then
        _, h = W:Dropdown(parent, L["Add a set"], y, addValues,
            function() return "none" end,
            function(v)
                if v == "none" then return end
                GSI_UI:ToggleSpecSet(specIndex, v)
                SetsChanged()
            end,
            addOrder, L["With several sets, switching to the spec asks which one to put on."]); y = y - h
    end
    if isManual then
        _, h = W:Button(parent, L["Back to Auto"], y, function()
            GSI_UI:SetSpecSets(specIndex, nil)
            SetsChanged()
        end); y = y - h
    end
    if #names > 0 then
        _, h = W:Button(parent, L["Equip a set of this spec"], y, function()
            if GSI_UI.EquipSpecSet then GSI_UI:EquipSpecSet(specIndex, false, true) end
        end); y = y - h
    end

    -- Talent group (dual spec) for /gsi go
    _, h = W:SectionHeader(parent, L["DUAL SPEC"], y,
        L["The talent group /gsi go switches to for this spec. Auto takes the only group whose most-used tree is the spec's; choose one when both groups use the same tree (a Cat and a Bear build)."]); y = y - h
    local autoGroup = GSI_UI.ResolveSpecTalentGroup and select(1, GSI_UI:ResolveSpecTalentGroup(specIndex))
    local groupValues = {
        auto = autoGroup and string.format(L["Auto (group %s)"], tostring(autoGroup)) or L["Auto"],
        g1 = L["Group 1"],
        g2 = L["Group 2"],
        _noLoc = true,
    }
    _, h = W:Dropdown(parent, L["Talent group"], y, groupValues,
        function()
            local g = GSI_UI:GetSpecTalentGroup(specIndex)
            return g and ("g" .. g) or "auto"
        end,
        function(v)
            GSI_UI:SetSpecTalentGroup(specIndex, (v == "g1" and 1) or (v == "g2" and 2) or nil)
            if GSI_UI.RefreshSpecSetRows then pcall(GSI_UI.RefreshSpecSetRows) end
        end,
        { "auto", "g1", "g2" }); y = y - h
    return y
end

local specPageIndex = {}

local function BuildSpecs(pageName, parent, yOffset)
    local y = yOffset
    if pageName == PAGE_OPTIONS then
        y = BuildSpecOptions(parent, y)
    elseif specPageIndex[pageName] then
        y = BuildSpecPage(specPageIndex[pageName], parent, y)
    end
    return math.abs(y)
end

-- ------------------------------------------------------------
-- Registration
-- ------------------------------------------------------------

local function Register()
    if registered or not (EllesmereUI and EllesmereUI.RegisterPlugin) then return end
    local specPages = { PAGE_OPTIONS }
    for i, name in ipairs(ClassSpecs()) do
        if not specPageIndex[name] and name ~= PAGE_OPTIONS then
            specPageIndex[name] = i
            specPages[#specPages + 1] = name
        end
    end
    registered = EllesmereUI.RegisterPlugin(PLUGIN_ID, {
        label = "GearSetImprover",
        modules = {
            {
                key = "General",
                title = L["General"],
                description = L["Gear scores in tooltips, upgrade toasts and the Clean-up list."],
                pages = { PAGE_GENERAL, PAGE_TOASTS, PAGE_CLEANUP },
                buildPage = BuildGeneral,
            },
            {
                key = "Specs",
                title = L["Specs & Sets"],
                description = L["Each spec's Equipment Sets, the weights each set turns on, its tooltip lines and its talent group."],
                pages = specPages,
                buildPage = BuildSpecs,
                -- Sets and specs change outside the panel: always built fresh
                onPageCacheRestore = function() Rebuild("Specs") end,
            },
        },
    }) and true or false

    if registered then
        -- Sets put on, saved or removed, and spec changes: the open page follows
        local watcher = CreateFrame("Frame")
        for _, ev in ipairs({ "EQUIPMENT_SETS_CHANGED", "EQUIPMENT_SWAP_FINISHED",
                              "ACTIVE_TALENT_GROUP_CHANGED", "PLAYER_TALENT_UPDATE" }) do
            pcall(watcher.RegisterEvent, watcher, ev)
        end
        watcher:SetScript("OnEvent", function() Rebuild("Specs") end)
    end
end

function GSI_EllesmereUI:IsRegistered()
    return registered
end

-- Opens GearSetImprover's section of the EllesmereUI panel; false without it.
function GSI_EllesmereUI:Open(moduleKey, pageName)
    if not (registered and EllesmereUI and EllesmereUI.OpenPlugin) then return false end
    if SettingsPanel and SettingsPanel:IsShown() and HideUIPanel then HideUIPanel(SettingsPanel) end
    return EllesmereUI.OpenPlugin(PLUGIN_ID, moduleKey, pageName) and true or false
end

-- The page of the spec played, in Specs & Sets
function GSI_EllesmereUI:OpenSpecs()
    local SW = GSI_StatWeights
    local spec = SW and SW.GetActiveSpecIndex and SW:GetActiveSpecIndex()
    local name = spec and ClassSpecs()[spec]
    return self:Open("Specs", (name and specPageIndex[name]) and name or PAGE_OPTIONS)
end

local loader = CreateFrame("Frame")
loader:RegisterEvent("PLAYER_LOGIN")
loader:SetScript("OnEvent", function(self)
    self:UnregisterEvent("PLAYER_LOGIN")
    local ok, err = pcall(Register)
    if not ok and GSI_Print then GSI_Print("|cffff4444[GearSetImprover]|r EllesmereUI: " .. tostring(err)) end
end)
