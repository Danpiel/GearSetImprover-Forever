-- ============================================================
-- GearSetImprover -- UI_Tab_Macros.lua (WoW Forever)
-- The Macros tab, /gsi command parsing and help, and the Equipment Sets
-- GSI saves for presets (names: SpecSets.lua, GSI_SpecSets).
-- ============================================================

GSI_UI = GSI_UI or {}

local L = GSI_L

local GetItemInfo = (C_Item and C_Item.GetItemInfo) or _G.GetItemInfo or function() return nil end
local GetItemInfoInstant = (C_Item and C_Item.GetItemInfoInstant) or _G.GetItemInfoInstant or function() return nil end
local BackdropTemplateMixin = _G.BackdropTemplateMixin
local BACKDROP_TEMPLATE = BackdropTemplateMixin and 'BackdropTemplate' or nil

local function SkinFrame(f, s, t) if GSI_UI.SkinFrame then return GSI_UI:SkinFrame(f, s, t) end end
local function SkinButton(b, r, p) if GSI_UI.SkinButton then return GSI_UI:SkinButton(b, r, p) end end
local function SkinSlider(s, bg, w, h) if GSI_UI.SkinSlider then return GSI_UI:SkinSlider(s, bg, w, h) end end
local function FormatWeight(v) return GSI_UI.FormatWeight and GSI_UI:FormatWeight(v) or tostring(v) end
local function FormatStatValue(k, v) return GSI_UI.FormatStatValue and GSI_UI:FormatStatValue(k, v) or tostring(v) end
local STAT_DISPLAY_NAMES = GSI_UI.STAT_DISPLAY_NAMES or {}
local T = GSI_UI.THEME

local print = function(...)
    if GSI_Print then
        GSI_Print(...)
    elseif not (GearSetImproverDB and (GearSetImproverDB.disableChatOutput or GearSetImproverDB.disableChat)) then
        _G.print(...)
    end
end

function GSI_UI:DrawMacros(parent)
    local createAllBtn = CreateFrame("Button", nil, parent, BACKDROP_TEMPLATE)
    createAllBtn:SetSize(145, 24)
    createAllBtn:SetPoint("TOPRIGHT", -25, -16)
    createAllBtn:SetText(L["Create All Macros"])
    SkinButton(createAllBtn, nil, true)
    createAllBtn:SetScript("OnClick", function()
        GSI_UI:CreateAllMacros()
    end)
    createAllBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine(L["Create All Macros"], 1, 0.82, 0)
        GameTooltip:AddLine(L["Automatically creates all recommended Best Available macros for your class."], 1, 1, 1, true)
        GameTooltip:Show()
    end)
    createAllBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    local refreshBtn = CreateFrame("Button", nil, parent, BACKDROP_TEMPLATE)
    refreshBtn:SetSize(145, 22)
    refreshBtn:SetPoint("TOPRIGHT", -25, -44)
    refreshBtn:SetText(L["Refresh Status"])
    SkinButton(refreshBtn)
    refreshBtn:SetScript("OnClick", function()
        GSI_UI:UpdateMacros(parent)
    end)

    local title = self:CreateText(parent, "TITLE", L["Best Available - Macro Manager"])
    title:SetPoint("TOPLEFT", 15, -15)
    title:SetPoint("TOPRIGHT", createAllBtn, "TOPLEFT", -12, 1)
    title:SetJustifyH("LEFT")
    title:SetWordWrap(false)

    local desc = self:CreateText(parent, "BODY", L["Click or drag any macro card directly into an Action Bar slot!"])
    desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4)
    desc:SetPoint("TOPRIGHT", title, "BOTTOMRIGHT", 0, -4)
    desc:SetJustifyH("LEFT")
    desc:SetWordWrap(false)

    local slotInfo = self:CreateText(parent, "SMALL", L["Macro Capacity: Loading..."])
    slotInfo:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", 0, -4)
    slotInfo:SetPoint("TOPRIGHT", desc, "BOTTOMRIGHT", 0, -4)
    slotInfo:SetJustifyH("LEFT")
    slotInfo:SetWordWrap(false)
    parent.slotInfoText = slotInfo

    local scroll = CreateFrame("ScrollFrame", "GSI_MacrosScroll", parent, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 10, -78)
    scroll:SetPoint("BOTTOMRIGHT", -26, 12)
    if GSI_UI and GSI_UI.SkinScrollBar then
        GSI_UI:SkinScrollBar(scroll)
    end

    local child = CreateFrame("Frame", nil, scroll)
    child:SetSize(696, 500)
    scroll:SetScrollChild(child)
    parent.scrollChild = child
    parent.rows = {}
end

function GSI_UI:UpdateMacros(parent)
    if not parent or not parent.scrollChild then return end

    local numAccount, numCharacter = GetNumMacros()
    numAccount = numAccount or 0
    numCharacter = numCharacter or 0
    local maxAccount = MAX_ACCOUNT_MACROS or 120
    local maxCharacter = MAX_CHARACTER_MACROS or 18

    if parent.slotInfoText then
        parent.slotInfoText:SetText(string.format(L["Macro Capacity: |cffffffffCharacter:|r |cff00ff00%d/%d|r  |  |cffffffffAccount:|r |cff00ff00%d/%d|r"], numCharacter, maxCharacter, numAccount, maxAccount))
    end

    local playerClass = (GSI_ClassicData and GSI_ClassicData.GetPlayerClass and GSI_ClassicData:GetPlayerClass()) or select(2, UnitClass("player")) or "WARRIOR"
    local presets = self:GetClassMacroPresets(playerClass)

    for _, r in ipairs(parent.rows or {}) do r:Hide() end

    local yOff = 0
    for i, def in ipairs(presets) do
        local row = parent.rows[i]
        if not row then
            row = CreateFrame("Frame", nil, parent.scrollChild)
            row:SetSize(696, 50)
            row:EnableMouse(true)
            local div = row:CreateTexture(nil, "ARTWORK")
            div:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 4, 0)
            div:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", -4, 0)
            div:SetHeight((GSI_UI.PP and GSI_UI:PP(1)) or 1)
            div:SetColorTexture(1, 1, 1, 0.08)
            row.divider = div

            row:SetScript("OnEnter", function(self)
                if self.divider then
                    self.divider:SetColorTexture(1, 1, 1, 0.20)
                end
                if self.def then
                    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                    GameTooltip:AddLine(GSI_UI:GetPresetTitle(self.def), 1, 0.82, 0)
                    GameTooltip:AddLine(self.def.command, 0.4, 0.8, 1)
                    if self.def.desc then
                        GameTooltip:AddLine(L[self.def.desc], 0.85, 0.85, 0.85, true)
                    end
                    GameTooltip:Show()
                end
            end)
            row:SetScript("OnLeave", function(self)
                if self.divider then
                    self.divider:SetColorTexture(1, 1, 1, 0.08)
                end
                GameTooltip:Hide()
            end)

            local btn = CreateFrame("Button", nil, row, BACKDROP_TEMPLATE)
            btn:SetSize(36, 36)
            btn:SetPoint("LEFT", 8, 0)
            SkinFrame(btn)
            btn:SetBackdropColor(0.08, 0.08, 0.10, 1)
            btn:SetBackdropBorderColor(0.22, 0.22, 0.28, 1)

            local icon = btn:CreateTexture(nil, "ARTWORK")
            icon:SetSize(32, 32)
            icon:SetPoint("CENTER")
            icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
            btn.icon = icon

            btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
            btn:RegisterForDrag("LeftButton")

            local hl = btn:CreateTexture(nil, "HIGHLIGHT")
            hl:SetAllPoints(icon)
            hl:SetColorTexture(1, 1, 1, 0.25)

            btn:SetScript("OnEnter", function(self)
                if self.def then
                    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                    GameTooltip:AddLine(GSI_UI:GetPresetTitle(self.def), 1, 0.82, 0)
                    GameTooltip:AddLine(L["Left-Click or Drag to place on Action Bar"], 0, 1, 0)
                    GameTooltip:AddLine(self.def.command, 0.4, 0.8, 1)
                    GameTooltip:AddLine(L[self.def.desc], 0.8, 0.8, 0.8, true)
                    GameTooltip:Show()
                end
            end)
            btn:SetScript("OnLeave", function() GameTooltip:Hide() end)

            btn:SetScript("OnDragStart", function(self)
                if self.def then
                    GSI_UI:PickupMacroDef(self.def)
                end
            end)
            btn:SetScript("OnClick", function(self)
                if self.def then
                    GSI_UI:PickupMacroDef(self.def)
                end
            end)
            row.macroBtn = btn

            local createBtn = CreateFrame("Button", nil, row, BACKDROP_TEMPLATE)
            createBtn:SetSize(64, 24)
            createBtn:SetPoint("RIGHT", -8, 0)
            createBtn:SetText(L["Create"])
            SkinButton(createBtn)
            createBtn:SetScript("OnClick", function(self)
                if self.def then
                    GSI_UI:EnsureMacro(self.def)
                    GSI_UI:UpdateMacros(parent)
                end
            end)
            row.createBtn = createBtn

            local dragBtn = CreateFrame("Button", nil, row, BACKDROP_TEMPLATE)
            dragBtn:SetSize(80, 24)
            dragBtn:SetPoint("RIGHT", createBtn, "LEFT", -6, 0)
            dragBtn:SetText(L["Drag to Bar"])
            SkinButton(dragBtn)
            dragBtn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
            dragBtn:RegisterForDrag("LeftButton")

            dragBtn:SetScript("OnDragStart", function(self)
                if self.def then
                    GSI_UI:PickupMacroDef(self.def)
                end
            end)
            dragBtn:SetScript("OnClick", function(self)
                if self.def then
                    GSI_UI:PickupMacroDef(self.def)
                end
            end)
            dragBtn:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:AddLine(L["Drag to Action Bar"], 1, 0.82, 0)
                GameTooltip:AddLine(L["Picks up this macro onto your mouse cursor so you can drop it into any Action Bar slot."], 1, 1, 1, true)
                GameTooltip:Show()
            end)
            dragBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
            row.dragBtn = dragBtn

            local equipBtn = CreateFrame("Button", nil, row, BACKDROP_TEMPLATE)
            equipBtn:SetSize(64, 24)
            equipBtn:SetPoint("RIGHT", dragBtn, "LEFT", -6, 0)
            equipBtn:SetText(L["Equip"])
            SkinButton(equipBtn)
            equipBtn:SetScript("OnClick", function(self)
                if self.def then
                    GSI_UI:EquipPreset(self.def)
                end
            end)
            equipBtn:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:AddLine(L["Equip Preset"], 1, 0.82, 0)
                GameTooltip:AddLine(L["Equips Best Available for this preset and saves it as an Equipment Set in your Character Profile."], 1, 1, 1, true)
                GameTooltip:Show()
            end)
            equipBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
            row.equipBtn = equipBtn

            row.nameText = GSI_UI:CreateText(row, "CARD_TITLE", "")
            row.nameText:SetJustifyH("LEFT")
            row.nameText:SetWordWrap(false)

            row.statusBadge = GSI_UI:CreateText(row, "SMALL", "")
            row.statusBadge:SetJustifyH("RIGHT")
            row.statusBadge:SetWordWrap(false)

            row.cmdText = GSI_UI:CreateText(row, "BODY", "")
            row.cmdText:SetJustifyH("LEFT")
            row.cmdText:SetWordWrap(false)

            parent.rows[i] = row
        end

        row.def = def
        row.macroBtn.def = def
        row.dragBtn.def = def
        row.createBtn.def = def
        row.equipBtn.def = def

        row:SetSize(696, 50)

        -- A macro without a set of its own (dual spec) has no Equip button
        local textEdge = row.equipBtn
        if def.noSet then
            row.equipBtn:Hide()
            textEdge = row.dragBtn
        else
            row.equipBtn:Show()
        end

        -- Position text elements cleanly without vertical distortion or button overlap
        row.statusBadge:ClearAllPoints()
        row.statusBadge:SetPoint("RIGHT", textEdge, "LEFT", -8, 9)

        row.nameText:ClearAllPoints()
        row.nameText:SetPoint("LEFT", row.macroBtn, "RIGHT", 10, 9)
        row.nameText:SetPoint("RIGHT", row.statusBadge, "LEFT", -8, 0)

        row.cmdText:ClearAllPoints()
        row.cmdText:SetPoint("LEFT", row.macroBtn, "RIGHT", 10, -9)
        row.cmdText:SetPoint("RIGHT", textEdge, "LEFT", -8, -9)

        local macroIdx = GSI_UI:FindMacro(def.name)
        if macroIdx then
            local _, _, _, isLocal = GetMacroInfo(macroIdx)
            local locStr = isLocal and L["Char"] or L["Account"]
            row.statusBadge:SetText(string.format(L["|cff00ff00[Ready]|r |cff888888(%s)|r"], locStr))
            row.createBtn:SetText(L["Update"])
            row.macroBtn:SetBackdropBorderColor(0, 0.8, 0, 1)
        else
            row.statusBadge:SetText(L["|cff888888[Not Created]|r"])
            row.createBtn:SetText(L["|cff00ff00Create|r"])
            row.macroBtn:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
        end

        row.macroBtn.icon:SetTexture(def.icon or 134400)
        row.nameText:SetText(GSI_UI:GetPresetTitle(def))
        row.cmdText:SetText(string.format("|cffffcc00%s|r  |cffaaaaaa- %s|r", def.command, L[def.desc]))

        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", parent.scrollChild, "TOPLEFT", 0, -yOff)
        row:Show()

        yOff = yOff + 50
    end

    parent.scrollChild:SetHeight(math.max(yOff + 10, 10))
end

-- ===============================================================
-- SLASH COMMANDS & MACRO SUPPORT: BEST AVAILABLE
-- ===============================================================

local CLASS_SPEC_ALIASES = {
    WARRIOR = {
        [1] = { "arms", "waffen" },
        [2] = { "fury", "furor" },
        [3] = { "protection", "prot", "schutz", "tank" },
    },
    PALADIN = {
        [1] = { "holy", "heilig", "heal", "healer" },
        [2] = { "protection", "prot", "schutz", "tank" },
        [3] = { "retribution", "ret", "vergeltung", "dps" },
    },
    HUNTER = {
        [1] = { "beast mastery", "beastmastery", "bm", "beast", "tierherrschaft" },
        [2] = { "marksmanship", "mm", "marks", "treffsicherheit" },
        [3] = { "survival", "surv", "überleben", "ueberleben", "melee" },
    },
    ROGUE = {
        [1] = { "assassination", "assa", "meucheln", "dagger" },
        [2] = { "combat", "kampf", "sword", "mace" },
        [3] = { "subtlety", "sub", "täuschung", "taeuschung" },
    },
    PRIEST = {
        [1] = { "discipline", "disc", "disziplin" },
        [2] = { "holy", "heilig", "heal", "healer" },
        [3] = { "shadow", "schatten", "spriest", "dps" },
    },
    SHAMAN = {
        [1] = { "elemental", "ele", "elementar", "caster" },
        [2] = { "enhancement", "enh", "verstärkung", "verstaerkung", "melee" },
        [3] = { "restoration", "resto", "wiederherstellung", "heal", "healer" },
    },
    MAGE = {
        [1] = { "arcane", "arkan" },
        [2] = { "fire", "feuer" },
        [3] = { "frost" },
    },
    WARLOCK = {
        [1] = { "affliction", "affli", "aff", "gebrechen", "dot" },
        [2] = { "demonology", "demo", "dämonologie", "daemonologie", "pet" },
        [3] = { "destruction", "destro", "zerstörung", "zerstoerung", "burst" },
    },
    DRUID = {
        [1] = { "balance", "moonkin", "boomkin", "gleichgewicht", "owl" },
        [2] = { "feral bear", "bear", "baer", "bär", "tank", "feral tank", "guardian", "feral" },
        [3] = { "feral cat", "cat", "katze", "kitty", "feral dps", "dps" },
        [4] = { "restoration", "resto", "wiederherstellung", "heal", "healer", "tree" },
    },
}

local TANK_MODE_ALIASES = {
    survival      = "Survival",
    surv          = "Survival",
    def           = "Survival",
    defense       = "Survival",
    mitigation    = "Survival",
    ehp           = "Survival",
    ["überleben"] = "Survival",
    ueberleben    = "Survival",
    threat        = "DMG",
    aggro         = "DMG",
    dmg           = "DMG",
    dps           = "DMG",
    offtank       = "DMG",
    ot            = "DMG",
}

local DPS_MODE_ALIASES = {
    st            = "ST",
    single        = "ST",
    singletarget  = "ST",
    boss          = "ST",
    aoe           = "AOE",
    trash         = "AOE",
    multi         = "AOE",
    multitarget   = "AOE",
    cleave        = "AOE",
    swipe         = "AOE",
}

local function ParseSpecAndModeTokens(tokens)
    local targetSpec = nil
    local targetMode = nil
    local playerClass = (GSI_ClassicData and GSI_ClassicData.GetPlayerClass and GSI_ClassicData:GetPlayerClass()) or select(2, UnitClass("player")) or "WARRIOR"

    -- Combine multi-word spec and mode phrases before single-token parsing
    local normalized = {}
    local idx = 1
    while idx <= #tokens do
        local t1 = tostring(tokens[idx]):lower()
        local t2 = tokens[idx + 1] and tostring(tokens[idx + 1]):lower()
        local pair = t2 and (t1 .. " " .. t2)
        if pair and (pair == "feral bear" or pair == "feral tank" or pair == "feral cat" or pair == "feral dps"
            or pair == "beast mastery" or pair == "single target" or pair == "multi target") then
            table.insert(normalized, pair)
            idx = idx + 2
        else
            table.insert(normalized, t1)
            idx = idx + 1
        end
    end

    for _, token in ipairs(normalized) do
        if token == "1" or token == "2" or token == "3" or token == "4" then
            targetSpec = tonumber(token)
        elseif token == "single target" then
            targetMode = { type = "dps", value = "ST" }
        elseif token == "multi target" then
            targetMode = { type = "dps", value = "AOE" }
        elseif playerClass == "DRUID" and (token == "bear" or token == "baer" or token == "bär" or token == "feral bear" or token == "feral tank" or token == "guardian") then
            targetSpec = 2
            if not targetMode or targetMode.type ~= "tank" then
                targetMode = { type = "tank", value = "Survival" }
            end
        elseif playerClass == "DRUID" and (token == "cat" or token == "katze" or token == "kitty" or token == "feral cat" or token == "feral dps") then
            targetSpec = 3
            if not targetMode or targetMode.type ~= "dps" then
                targetMode = { type = "dps", value = "ST" }
            end
        elseif playerClass == "DRUID" and (token == "resto" or token == "restoration" or token == "wiederherstellung" or token == "tree" or token == "heal") then
            targetSpec = 4
            if targetMode and targetMode.type == "tank" then
                targetMode = nil
            end
        elseif playerClass == "DRUID" and (token == "balance" or token == "moonkin" or token == "boomkin" or token == "gleichgewicht" or token == "owl") then
            targetSpec = 1
            if targetMode and targetMode.type == "tank" then
                targetMode = nil
            end
        elseif playerClass == "DRUID" and token == "feral" then
            if not targetSpec then
                targetSpec = 2
                if not targetMode then
                    targetMode = { type = "tank", value = "Survival" }
                end
            end
        else
            local matchedSpec = false
            local classSpecs = CLASS_SPEC_ALIASES[playerClass]
            if classSpecs then
                for sIdx, aliasList in pairs(classSpecs) do
                    for _, alias in ipairs(aliasList) do
                        if token == alias then
                            targetSpec = sIdx
                            matchedSpec = true
                            break
                        end
                    end
                    if matchedSpec then break end
                end
            end

            if not matchedSpec then
                if TANK_MODE_ALIASES[token] then
                    targetMode = { type = "tank", value = TANK_MODE_ALIASES[token] }
                elseif DPS_MODE_ALIASES[token] then
                    targetMode = { type = "dps", value = DPS_MODE_ALIASES[token] }
                end
            end
        end
    end

    return targetSpec, targetMode
end
GSI_UI.ParseSpecAndModeTokens = ParseSpecAndModeTokens
_G.GSI_ParseSpecAndModeTokens = ParseSpecAndModeTokens

function GSI_UI:PrintSlashHelp()
    print(L["|cffffcc00[GearSetImprover]|r Commands & Help:"])
    print(L["  |cff00ff00/gsi|r - Open / close main window"])
    print(L["  |cff00ff00/gsi gear|r (or |cff00ff00/gsi bib|r) - Open 'Best Available Gear'"])
    print(L["  |cff00ff00/gsi cleanup|r (or |cff00ff00/gsi junk|r) - Open 'Clean-up'"])
    print(L["  |cff00ff00/gsi weights|r - Open 'Stat Weights'"])
    print(L["  |cff00ff00/gsi options|r (or |cff00ff00/gsi settings|r) - Open Addon Settings"])
    print(L["  |cff00ff00/gsi tutorial|r - Open interactive tutorial"])
    print(L["  |cff00ff00/gsi changelog|r - Show release notes (Changelog)"])
    print(L["  |cff00ff00/gsi credits|r - View credits & acknowledgments"])
    print(L["  |cff00ff00/gsi log|r - Open Log Export window"])
    print(L["  |cff00ff00/gsi equip|r (or |cff00ff00/gsiequip|r) - Equip Best Available Gear"])
    print(L["  |cff00ff00/gsi equip <spec> [mode]|r - Equip Best Available Gear for a specific profile"])
    print(L["    |cffffffaaExamples:|r"])
    print(L["      |cffffff00/gsi equip arms|r or |cffffff00/gsi equip fury aoe|r"])
    print(L["      |cffffff00/gsi equip prot survival|r or |cffffff00/gsi equip prot threat|r"])
    print(L["      |cffffff00/gsiequip bear survival|r or |cffffff00/gsiequip cat st|r (Druid)"])
    print(L["  |cff00ff00/gsi macros|r - Macro Manager for 1-click Action Bar macros"])
    print(L["  |cff00ff00/gsi spec <1-3|name>|r - Pin a specialization (scores stop following your talents)"])
    print(L["  |cff00ff00/gsi spec auto|r - Follow your current talent specialization (default)"])
    print(L["  |cff00ff00/gsi set|r - Equip the current spec's Equipment Set (asks which one when there are several)"])
    print(L["  |cff00ff00/gsi toggle|r - Dual spec: switch to the other talent group, then put on that spec's set (the 'GSI Dual Spec' macro)"])
    print(L["  |cff00ff00/gsi go <spec> [mode]|r - Switch to the spec's talent group (dual spec) and put on its set, e.g. |cffffff00/gsi go bear|r"])
    print(L["  |cff00ff00/gsi dump|r - Save item/tooltip/spec diagnostics to SavedVariables (then /reload)"])
    print(L["  |cff00ff00/gsi mode <survival|threat|st|aoe>|r - Switch active mode"])
    print(L["  |cff00ff00/gsi toast|r (or |cff00ff00/gsi testtoast|r) - Test on-screen upgrade toast alert"])
    print(L["  |cff00ff00/gsi anchor|r - Toggle movable screen anchor for upgrade toasts"])
    print(L["  |cff00ff00/gsi help|r - Show this command list"])
end

function GSI_UI:GetEquipmentSetNameAndIcon(specIndex, targetMode, explicitPreset)
    if explicitPreset and explicitPreset.name and not explicitPreset.noSet then
        return GSI_SpecSets.PresetSetName(explicitPreset), explicitPreset.icon or 134400
    end

    local playerClass = (GSI_ClassicData and GSI_ClassicData.GetPlayerClass and GSI_ClassicData:GetPlayerClass()) or select(2, UnitClass("player")) or "WARRIOR"
    local activeSpec = tonumber(specIndex) or GSI_StatWeights:GetActiveSpecIndex()
    local role = GSI_StatWeights:GetRole()
    local modeVal = nil

    if targetMode then
        modeVal = type(targetMode) == "table" and targetMode.value or targetMode
    else
        if role == "tank" then
            modeVal = (GearSetImproverDB and GearSetImproverDB.tankMode) or "Survival"
        else
            modeVal = (GearSetImproverDB and GearSetImproverDB.weightMode) or "ST"
        end
    end

    local presets = GSI_MACRO_PRESETS[playerClass]
    if presets then
        -- 1. Try exact match on both spec and mode
        for _, p in ipairs(presets) do
            if p.specIndex == activeSpec and p.mode and modeVal and (p.mode:upper() == modeVal:upper()) then
                return GSI_SpecSets.PresetSetName(p), p.icon or 134400
            end
        end

        -- 2. Try match on specIndex where preset has no specific mode restriction
        for _, p in ipairs(presets) do
            if p.specIndex == activeSpec and not p.mode then
                return GSI_SpecSets.PresetSetName(p), p.icon or 134400
            end
        end

        -- 3. Try match on mode only (e.g. AoE presets)
        for _, p in ipairs(presets) do
            if not p.specIndex and p.mode and modeVal and (p.mode:upper() == modeVal:upper()) then
                return GSI_SpecSets.PresetSetName(p), p.icon or 134400
            end
        end
    end

    -- Fallback: Use class spec data
    local classData = GSI_ClassicData and GSI_ClassicData.Classes and GSI_ClassicData.Classes[playerClass]
    local specData = classData and classData.specs and classData.specs[activeSpec]
    local rawSpec = specData and (specData.name or specData.nameDE) or ("Spec " .. tostring(activeSpec))
    local icon = specData and specData.icon or 134400
    return GSI_SpecSets.SpecSetNameNow(rawSpec), icon
end

function GSI_UI:SaveEquipmentSetForProfile(specIndex, targetMode, explicitPreset)
    if InCombatLockdown and InCombatLockdown() then
        return false, "in_combat"
    end

    if GearSetImproverDB and GearSetImproverDB.autoSaveEquipmentSet == false then
        return false, "disabled"
    end

    if not C_EquipmentSet then
        return false, "no_api"
    end

    local setName, icon = self:GetEquipmentSetNameAndIcon(specIndex, targetMode, explicitPreset)
    if not setName or string.len(setName) == 0 then
        return false, "invalid_name"
    end
    setName = GSI_SpecSets.Trim16(setName)
    icon = icon or 134400

    local ok, res = pcall(function()
        local setID = C_EquipmentSet.GetEquipmentSetID and C_EquipmentSet.GetEquipmentSetID(setName)

        if setID ~= nil then
            -- Set already exists: clear ignored slots and update
            if C_EquipmentSet.ClearIgnoredSlotsForSave then
                pcall(C_EquipmentSet.ClearIgnoredSlotsForSave)
            end
            local saveOk = pcall(C_EquipmentSet.SaveEquipmentSet, setID, icon)
            if not saveOk then
                pcall(C_EquipmentSet.SaveEquipmentSet, setID)
            end
            if C_EquipmentSet.ModifyEquipmentSet then
                pcall(C_EquipmentSet.ModifyEquipmentSet, setID, setName, icon)
            end
            return true, "updated", setID
        else
            -- Set does not exist yet: check capacity limit
            local maxSets = MAX_EQUIPMENT_SETS_PER_PLAYER or 10
            local numSets = (C_EquipmentSet.GetNumEquipmentSets and C_EquipmentSet.GetNumEquipmentSets()) or 0
            if numSets >= maxSets then
                print(string.format(L["|cffff0000[GearSetImprover]|r Cannot save Equipment Set: maximum limit of %d sets reached! Please delete an unused set in your Character Profile."], maxSets))
                return false, "full"
            end

            if C_EquipmentSet.CreateEquipmentSet then
                local newID = C_EquipmentSet.CreateEquipmentSet(setName, icon)
                if newID == nil and C_EquipmentSet.GetEquipmentSetID then
                    newID = C_EquipmentSet.GetEquipmentSetID(setName)
                end
                if newID ~= nil and C_EquipmentSet.SaveEquipmentSet then
                    if C_EquipmentSet.ClearIgnoredSlotsForSave then
                        pcall(C_EquipmentSet.ClearIgnoredSlotsForSave)
                    end
                    local saveOk = pcall(C_EquipmentSet.SaveEquipmentSet, newID, icon)
                    if not saveOk then
                        pcall(C_EquipmentSet.SaveEquipmentSet, newID)
                    end
                end
                return true, "created", newID
            end
        end
        return false, "unsupported"
    end)

    if ok and res then
        print(string.format(L["|cff00ff00[GearSetImprover]|r Saved Equipment Set '|cffffcc00%s|r' in Character Profile."], setName))
        if PaperDollEquipmentManagerPane_Update then
            pcall(PaperDollEquipmentManagerPane_Update)
        end
        if GearManagerDialog_Update then
            pcall(GearManagerDialog_Update)
        end
        return true, setName
    elseif not ok then
        print(string.format(L["|cffff0000[GearSetImprover]|r Error saving equipment set: %s"], tostring(res)))
        return false, tostring(res)
    end

    return false
end

function GSI_UI:EquipPreset(macroDef)
    if not macroDef or macroDef.noSet then return end
    if InCombatLockdown and InCombatLockdown() then
        print(L["|cffff0000[GearSetImprover]|r Cannot equip gear while in combat!"])
        return
    end

    local tokens = {}
    for word in (macroDef.command or ""):gmatch("%S+") do
        table.insert(tokens, word:lower())
    end
    if tokens[1] == "/gsi" then table.remove(tokens, 1) end
    if tokens[1] == "equip" or tokens[1] == "bib" then table.remove(tokens, 1) end

    local targetSpec, targetMode = ParseSpecAndModeTokens(tokens)
    if macroDef.specIndex then targetSpec = macroDef.specIndex end
    if macroDef.mode then
        local role = GSI_StatWeights:GetRole(macroDef.specIndex)
        if role == "tank" or (macroDef.mode == "Survival" or macroDef.mode == "Threat" or macroDef.mode == "DMG") then
            targetMode = { type = "tank", value = (macroDef.mode == "Threat" and "DMG" or macroDef.mode) }
        else
            targetMode = { type = "dps", value = macroDef.mode }
        end
    end

    self:EquipBestInBag(targetSpec, targetMode, nil, macroDef)
end
