-- ============================================================
-- GearSetImprover -- UI_Tab_Settings.lua (WoW Forever)
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

-- Helper: Returns list of available profiles/orientations for a class
-- ---------------------------------------------------------------
function GSI_UI:GetClassProfiles(playerClass)
    local classData = GSI_ClassicData and GSI_ClassicData.Classes and GSI_ClassicData.Classes[playerClass]
    local numSpecs = (playerClass == "DRUID") and 4 or 3
    local list = {}

    for i = 1, numSpecs do
        local specInfo = classData and classData.specs and classData.specs[i]
        local sName = (specInfo and specInfo.name) and L[specInfo.name] or string.format(L["Spec %d"], i)
        local role = specInfo and specInfo.role

        -- Check if spec has tank modes (Survival vs Threat)
        local hasTankModes = false
        if playerClass == "WARRIOR" and i == 3 then hasTankModes = true end
        if playerClass == "DRUID" and i == 2 then hasTankModes = true end
        if playerClass == "PALADIN" and i == 2 then hasTankModes = true end

        if hasTankModes then
            table.insert(list, {
                key = i .. ":Survival",
                specIndex = i,
                mode = "Survival",
                modeLabel = L["Survival"],
                label = string.format(L["%s (Survival)"], sName)
            })
            table.insert(list, {
                key = i .. ":Threat",
                specIndex = i,
                mode = "Threat",
                modeLabel = L["Threat"],
                label = string.format(L["%s (Threat / DMG)"], sName)
            })
        elseif role == "healer" then
            table.insert(list, {
                key = i .. ":ST",
                specIndex = i,
                mode = "ST",
                modeLabel = L["Single"],
                label = string.format(L["%s (Single Target / Direct)"], sName)
            })
            table.insert(list, {
                key = i .. ":AOE",
                specIndex = i,
                mode = "AOE",
                modeLabel = L["AoE / Raid"],
                label = string.format(L["%s (AoE / Raid)"], sName)
            })
        else
            -- Standard DPS specs
            table.insert(list, {
                key = i .. ":ST",
                specIndex = i,
                mode = "ST",
                modeLabel = L["ST"],
                label = string.format(L["%s (Single Target)"], sName)
            })
            table.insert(list, {
                key = i .. ":AOE",
                specIndex = i,
                mode = "AOE",
                modeLabel = L["AoE"],
                label = string.format(L["%s (AoE / Trash)"], sName)
            })
        end
    end

    return list
end

-- ---------------------------------------------------------------
-- ---------------------------------------------------------------
-- TAB 5: SETTINGS
-- ---------------------------------------------------------------
function GSI_UI:DrawSettings(parent)
    local title = self:CreateText(parent, "TITLE", L["Addon Settings"])
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetPoint("RIGHT", parent, "RIGHT", -16, 0)
    if title.SetWordWrap then title:SetWordWrap(false) end

    local sf = CreateFrame("ScrollFrame", "GSI_SettingsScroll", parent, "UIPanelScrollFrameTemplate")
    sf:SetPoint("TOPLEFT", 0, -46)
    sf:SetPoint("BOTTOMRIGHT", -28, 12)
    if self.SkinScrollBar then
        self:SkinScrollBar(sf)
    end

    local scrollChild = CreateFrame("Frame", nil, sf)
    scrollChild:SetSize(math.max(400, (sf:GetWidth() or 710) - 4), 560)
    sf:SetScrollChild(scrollChild)

    sf:HookScript("OnSizeChanged", function(selfSf, width)
        if width and width > 100 then
            scrollChild:SetWidth(math.max(400, width - 4))
        end
    end)

    local desc = self:CreateText(scrollChild, "BODY", L["All addon settings are in the WoW Interface Options, and with EllesmereUI in its options panel (GearSetImprover section)."])
    desc:SetPoint("TOPLEFT", 16, -4)
    desc:SetPoint("RIGHT", scrollChild, "RIGHT", -16, 0)
    desc:SetJustifyH("LEFT")
    if desc.SetWordWrap then desc:SetWordWrap(true) end

    local openBtn = CreateFrame("Button", nil, scrollChild, BACKDROP_TEMPLATE)
    openBtn:SetSize(200, 28)
    openBtn:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", 0, -14)
    openBtn:SetText(L["Open Settings"])
    SkinButton(openBtn, nil, true)
    openBtn:SetScript("OnClick", function()
        if GSI_UI.OpenSettings then
            GSI_UI:OpenSettings()
        end
    end)

    local deMacroBtn = CreateFrame("Button", nil, scrollChild, BACKDROP_TEMPLATE)
    deMacroBtn:SetSize(160, 28)
    deMacroBtn:SetPoint("LEFT", openBtn, "RIGHT", 10, 0)
    deMacroBtn:SetText(L["Pickup DE Macro"])
    SkinButton(deMacroBtn, nil, false)
    deMacroBtn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    deMacroBtn:RegisterForDrag("LeftButton")
    deMacroBtn:SetScript("OnDragStart", function()
        if GSI_UI.PickupDisenchantMacro then
            GSI_UI:PickupDisenchantMacro()
        end
    end)
    deMacroBtn:SetScript("OnClick", function()
        if GSI_UI.PickupDisenchantMacro then
            GSI_UI:PickupDisenchantMacro()
        end
    end)
    deMacroBtn:SetScript("OnEnter", function(selfBtn)
        GameTooltip:SetOwner(selfBtn, "ANCHOR_TOP")
        GameTooltip:ClearLines()
        GameTooltip:AddLine(L["|cffffcc00Disenchant Clean-up Macro|r"], 1, 1, 1)
        GameTooltip:AddLine(L["Click or drag to place a macro ('GSI: DE Clean') on your Action Bar that disenchants obsolete gear items from the Clean-up list one by one."], 0.9, 0.9, 0.9, true)
        GameTooltip:AddLine(L["|cff00ff00Click / Drag:|r Attach macro to cursor"], 0, 1, 0)
        GameTooltip:Show()
    end)
    deMacroBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    -- General Settings
    local generalHeader = self:CreateText(scrollChild, "CARD_TITLE", L["General Options"])
    generalHeader:SetPoint("TOPLEFT", openBtn, "BOTTOMLEFT", 0, -20)
    generalHeader:SetPoint("RIGHT", scrollChild, "RIGHT", -16, 0)
    if generalHeader.SetWordWrap then generalHeader:SetWordWrap(false) end

    local cbDisableChat = CreateFrame("CheckButton", nil, scrollChild, "UICheckButtonTemplate")
    cbDisableChat:SetPoint("TOPLEFT", generalHeader, "BOTTOMLEFT", 0, -8)
    cbDisableChat.text = self:CreateText(cbDisableChat, "BODY", L["Disable Chat Output (Silent Mode)"])
    cbDisableChat.text:SetPoint("LEFT", cbDisableChat, "RIGHT", 6, 0)
    cbDisableChat.text:SetPoint("RIGHT", scrollChild, "RIGHT", -16, 0)
    cbDisableChat.text:SetJustifyH("LEFT")
    if cbDisableChat.text.SetWordWrap then cbDisableChat.text:SetWordWrap(true) end
    cbDisableChat:SetChecked(GearSetImproverDB and GearSetImproverDB.disableChatOutput == true)
    cbDisableChat:SetScript("OnClick", function(selfBtn)
        if not GearSetImproverDB then GearSetImproverDB = {} end
        GearSetImproverDB.disableChatOutput = selfBtn:GetChecked() and true or false
        if GSI_UI.blizzOptionsPanel and GSI_UI.blizzOptionsPanel.cbDisableChat then
            GSI_UI.blizzOptionsPanel.cbDisableChat:SetChecked(GearSetImproverDB.disableChatOutput)
        end
    end)
    cbDisableChat:SetScript("OnEnter", function(selfBtn)
        GameTooltip:SetOwner(selfBtn, "ANCHOR_RIGHT")
        GameTooltip:AddLine(L["Disable Chat Output (Silent Mode)"], 1, 0.82, 0)
        GameTooltip:AddLine(L["Disables all chat messages from the addon (e.g. login greeting, gear notifications, profile confirmations)."], 1, 1, 1, true)
        GameTooltip:Show()
    end)
    cbDisableChat:SetScript("OnLeave", function() GameTooltip:Hide() end)
    GSI_UI.cbDisableChat = cbDisableChat

    local cbMerchantOverlay = CreateFrame("CheckButton", nil, scrollChild, "UICheckButtonTemplate")
    cbMerchantOverlay:SetPoint("TOPLEFT", cbDisableChat, "BOTTOMLEFT", 0, -6)
    cbMerchantOverlay.text = self:CreateText(cbMerchantOverlay, "BODY", L["Show Clean-up sell window at merchant"])
    cbMerchantOverlay.text:SetPoint("LEFT", cbMerchantOverlay, "RIGHT", 6, 0)
    cbMerchantOverlay.text:SetPoint("RIGHT", scrollChild, "RIGHT", -16, 0)
    cbMerchantOverlay.text:SetJustifyH("LEFT")
    if cbMerchantOverlay.text.SetWordWrap then cbMerchantOverlay.text:SetWordWrap(true) end
    cbMerchantOverlay:SetChecked(not (GearSetImproverDB and GearSetImproverDB.merchantOverlayEnabled == false))
    cbMerchantOverlay:SetScript("OnClick", function(selfBtn)
        local val = selfBtn:GetChecked() and true or false
        if GSI_UI.SetMerchantOverlayEnabled then
            GSI_UI:SetMerchantOverlayEnabled(val)
        else
            if not GearSetImproverDB then GearSetImproverDB = {} end
            GearSetImproverDB.merchantOverlayEnabled = val
            if GSI_UI.UpdateMerchantPanel then
                GSI_UI:UpdateMerchantPanel()
            elseif not val then
                if GSI_UI.merchantOverlay then GSI_UI.merchantOverlay:Hide() end
                if _G["GSI_MerchantOverlay"] then _G["GSI_MerchantOverlay"]:Hide() end
                if _G["GSI_MerchantToggleBtn"] then _G["GSI_MerchantToggleBtn"]:Hide() end
            end
        end
        if GSI_UI.blizzOptionsPanel and GSI_UI.blizzOptionsPanel.cbMerchantOverlay then
            GSI_UI.blizzOptionsPanel.cbMerchantOverlay:SetChecked(val)
        end
        local junkFrame = GSI_UI.mainFrame and GSI_UI.mainFrame.tabFrames and GSI_UI.mainFrame.tabFrames["JUNK"]
        if junkFrame and GSI_UI.UpdateJunkList then
            pcall(function() GSI_UI:UpdateJunkList(junkFrame) end)
        end
    end)
    cbMerchantOverlay:SetScript("OnEnter", function(selfBtn)
        GameTooltip:SetOwner(selfBtn, "ANCHOR_RIGHT")
        GameTooltip:AddLine(L["Show Clean-up sell window at merchant"], 1, 0.82, 0)
        GameTooltip:AddLine(L["Automatically docks the Clean-up sell panel next to the merchant window with a 'Sell All' button."], 1, 1, 1, true)
        GameTooltip:Show()
    end)
    cbMerchantOverlay:SetScript("OnLeave", function() GameTooltip:Hide() end)
    GSI_UI.cbMerchantOverlay = cbMerchantOverlay

    -- Specs, Equipment Sets & Weights: one card per spec holds everything
    -- tied to it: the tooltip lines scored against the gear you wear (the
    -- "orientations"), the spec's Equipment Sets with the weights each one
    -- turns on, and its talent group (dual spec).
    local playerClass = (GSI_ClassicData and GSI_ClassicData.GetPlayerClass and GSI_ClassicData:GetPlayerClass())
        or select(2, UnitClass("player")) or "WARRIOR"
    local profiles = self:GetClassProfiles(playerClass)
    local profileCheckboxes = {}
    local lastElem
    local UpdateSettingsLayoutAndSync

    local setHeader = self:CreateText(scrollChild, "CARD_TITLE", L["Specs, Equipment Sets & Weights"])
    setHeader:SetPoint("TOPLEFT", cbMerchantOverlay, "BOTTOMLEFT", 0, -20)
    setHeader:SetPoint("RIGHT", scrollChild, "RIGHT", -16, 0)
    if setHeader.SetWordWrap then setHeader:SetWordWrap(true) end

    local cbSpecAuto = CreateFrame("CheckButton", nil, scrollChild, "UICheckButtonTemplate")
    cbSpecAuto:SetPoint("TOPLEFT", setHeader, "BOTTOMLEFT", 0, -8)
    cbSpecAuto.text = self:CreateText(cbSpecAuto, "BODY", L["Detect the specialization from your talents (follows respecs)"])
    cbSpecAuto.text:SetPoint("LEFT", cbSpecAuto, "RIGHT", 6, 0)
    cbSpecAuto.text:SetPoint("RIGHT", scrollChild, "RIGHT", -16, 0)
    cbSpecAuto.text:SetJustifyH("LEFT")
    cbSpecAuto:SetScript("OnClick", function(selfBtn)
        if GSI_StatWeights and GSI_StatWeights.SetSpecAuto then
            GSI_StatWeights:SetSpecAuto(selfBtn:GetChecked() and true or false)
        end
    end)
    cbSpecAuto:SetScript("OnEnter", function(selfBtn)
        GameTooltip:SetOwner(selfBtn, "ANCHOR_RIGHT")
        GameTooltip:AddLine(L["Auto-detect specialization"], 1, 0.82, 0)
        GameTooltip:AddLine(L["Uses the talent tree with the most points. Picking a spec in the header dropdown (or /gsi spec <name>) pins it and turns this off; /gsi spec auto turns it back on."], 1, 1, 1, true)
        GameTooltip:AddLine(L["Feral druids: talents cannot tell Cat from Bear, so your last Cat/Bear pick decides."], 0.7, 0.9, 1, true)
        GameTooltip:Show()
    end)
    cbSpecAuto:SetScript("OnLeave", function() GameTooltip:Hide() end)

    local cbSetAuto = CreateFrame("CheckButton", nil, scrollChild, "UICheckButtonTemplate")
    cbSetAuto:SetPoint("TOPLEFT", cbSpecAuto, "BOTTOMLEFT", 0, -6)
    cbSetAuto.text = self:CreateText(cbSetAuto, "BODY", L["Equip the spec's set when your spec changes"])
    cbSetAuto.text:SetPoint("LEFT", cbSetAuto, "RIGHT", 6, 0)
    cbSetAuto.text:SetPoint("RIGHT", scrollChild, "RIGHT", -16, 0)
    cbSetAuto.text:SetJustifyH("LEFT")
    cbSetAuto:SetScript("OnClick", function(selfBtn)
        if not GearSetImproverDB then GearSetImproverDB = {} end
        GearSetImproverDB.specSetAutoEquip = selfBtn:GetChecked() and true or false
    end)
    cbSetAuto:SetScript("OnEnter", function(selfBtn)
        GameTooltip:SetOwner(selfBtn, "ANCHOR_RIGHT")
        GameTooltip:AddLine(L["Equip set on spec change"], 1, 0.82, 0)
        GameTooltip:AddLine(L["When the talent-detected spec changes, the new spec's set (its card below) is put on, after combat if you are fighting; with several sets you choose one. Its weights go on with it."], 1, 1, 1, true)
        GameTooltip:Show()
    end)
    cbSetAuto:SetScript("OnLeave", function() GameTooltip:Hide() end)

    local cbCompareSets = CreateFrame("CheckButton", nil, scrollChild, "UICheckButtonTemplate")
    cbCompareSets:SetPoint("TOPLEFT", cbSetAuto, "BOTTOMLEFT", 0, -6)
    cbCompareSets.text = self:CreateText(cbCompareSets, "BODY", L["Tooltips: a line for every Equipment Set of every spec"])
    cbCompareSets.text:SetPoint("LEFT", cbCompareSets, "RIGHT", 6, 0)
    cbCompareSets.text:SetPoint("RIGHT", scrollChild, "RIGHT", -16, 0)
    cbCompareSets.text:SetJustifyH("LEFT")
    cbCompareSets:SetScript("OnClick", function(selfBtn)
        if not GearSetImproverDB then GearSetImproverDB = {} end
        GearSetImproverDB.compareSpecSets = selfBtn:GetChecked() and true or false
        if GSI_TooltipHook and GSI_TooltipHook.RefreshShownTooltips then GSI_TooltipHook:RefreshShownTooltips() end
    end)
    cbCompareSets:SetScript("OnEnter", function(selfBtn)
        GameTooltip:SetOwner(selfBtn, "ANCHOR_RIGHT")
        GameTooltip:AddLine(L["Compare with every spec's sets"], 1, 0.82, 0)
        GameTooltip:AddLine(L["Every spec of your class gets one tooltip line per set on its card, scored with the set's weights (a set that keeps the weights: the spec's ticked or current mode)."], 1, 1, 1, true)
        GameTooltip:AddLine(L["Your active spec keeps its lines against the gear you wear and adds its sets that are not on now. Off: only the ticked lines, all against the gear you wear."], 0.7, 0.9, 1, true)
        GameTooltip:Show()
    end)
    cbCompareSets:SetScript("OnLeave", function() GameTooltip:Hide() end)

    local setDesc = self:CreateText(scrollChild, "BODY", L["Each card: the tooltip lines scored against the gear you wear, the spec's Equipment Sets with the weights each one turns on when it goes on, and its talent group. Sets and groups belong to this character."])
    setDesc:SetPoint("TOPLEFT", cbCompareSets, "BOTTOMLEFT", 0, -8)
    setDesc:SetPoint("RIGHT", scrollChild, "RIGHT", -16, 0)
    setDesc:SetJustifyH("LEFT")
    if setDesc.SetWordWrap then setDesc:SetWordWrap(true) end

    -- Set picker popup (one shared list, re-filled on open)
    local picker = GSI_UI.specSetPicker
    if not picker then
        picker = CreateFrame("Frame", "GSI_SpecSetPicker", UIParent, BACKDROP_TEMPLATE)
        picker:SetFrameStrata("FULLSCREEN_DIALOG")
        picker:SetFrameLevel(520)
        picker:SetClampedToScreen(true)
        picker:EnableMouse(true)
        picker:Hide()
        SkinFrame(picker, GSI_UI.THEME and GSI_UI.THEME.bgCardBottom, true)
        picker.items = {}
        local catcher = CreateFrame("Button", nil, UIParent)
        catcher:SetFrameStrata("FULLSCREEN_DIALOG")
        catcher:SetFrameLevel(515)
        catcher:SetAllPoints(UIParent)
        catcher:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        catcher:SetScript("OnClick", function() picker:Hide() end)
        catcher:Hide()
        picker.catcher = catcher
        picker:SetScript("OnShow", function() catcher:Show() end)
        picker:SetScript("OnHide", function() catcher:Hide() end)
        GSI_UI.specSetPicker = picker
    end

    local cards = {}
    local RefreshSetRows

    -- Sets, modes or the list changed: cards, their heights, open tooltips
    local function SpecSetsChanged()
        if UpdateSettingsLayoutAndSync then
            UpdateSettingsLayoutAndSync()
            if C_Timer and C_Timer.After then C_Timer.After(0, UpdateSettingsLayoutAndSync) end
        elseif RefreshSetRows then
            RefreshSetRows()
        end
        if GSI_TooltipHook and GSI_TooltipHook.RefreshShownTooltips then
            pcall(GSI_TooltipHook.RefreshShownTooltips, GSI_TooltipHook)
        end
    end

    -- "+ Add set": the character's sets that are not on the card yet
    local function OpenAddPicker(anchor, specIndex)
        local sets = GSI_UI.GetEquipmentSetList and GSI_UI:GetEquipmentSetList() or {}
        local have = {}
        if GSI_UI.GetSpecSets then
            for _, n in ipairs((GSI_UI:GetSpecSets(specIndex))) do have[n] = true end
        end
        local entries = {}
        for _, s in ipairs(sets) do
            if not have[s.name] then
                entries[#entries + 1] = { name = s.name, label = s.name, icon = s.icon }
            end
        end
        if #entries == 0 then
            entries[1] = { label = L["|cff888888No other Equipment Sets|r"] }
        end
        for i, e in ipairs(entries) do
            local b = picker.items[i]
            if not b then
                b = CreateFrame("Button", nil, picker, BACKDROP_TEMPLATE)
                b:SetSize(212, 24)
                b:SetPoint("TOP", 0, -4 - ((i - 1) * 26))
                b:SetFrameLevel(530)
                b:SetText(" ")
                SkinButton(b, nil, false)
                b.icon = b:CreateTexture(nil, "ARTWORK")
                b.icon:SetSize(16, 16)
                b.icon:SetPoint("LEFT", b, "LEFT", 6, 0)
                b.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
                picker.items[i] = b
            end
            b:SetText(e.label)
            b.icon:SetTexture(e.icon or 134400)
            b.icon:SetShown(e.name ~= nil)
            b:SetScript("OnClick", function()
                picker:Hide()
                if e.name and GSI_UI.ToggleSpecSet then
                    GSI_UI:ToggleSpecSet(specIndex, e.name)
                    SpecSetsChanged()
                end
            end)
            b:Show()
        end
        for i = #entries + 1, #picker.items do picker.items[i]:Hide() end
        picker:SetSize(220, (#entries * 26) + 8)
        picker:ClearAllPoints()
        picker:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -2)
        picker:Show()
        if picker.Raise then picker:Raise() end
    end

    local function ModeButtonText(mode)
        if not mode then return L["|cff888888Weights: keep|r"] end
        return string.format(L["Weights: %s"], (GSI_UI.GetModeLabel and GSI_UI:GetModeLabel(mode)) or mode)
    end

    local function CreateSetRow(card)
        local r = CreateFrame("Frame", nil, card)
        r:SetHeight(22)

        r.icon = r:CreateTexture(nil, "ARTWORK")
        r.icon:SetSize(16, 16)
        r.icon:SetPoint("LEFT", r, "LEFT", 0, 0)
        r.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

        r.remove = CreateFrame("Button", nil, r, BACKDROP_TEMPLATE)
        r.remove:SetSize(64, 20)
        r.remove:SetPoint("RIGHT", r, "RIGHT", 0, 0)
        r.remove:SetText(L["Remove"])
        SkinButton(r.remove, nil, false)

        r.equip = CreateFrame("Button", nil, r, BACKDROP_TEMPLATE)
        r.equip:SetSize(58, 20)
        r.equip:SetPoint("RIGHT", r.remove, "LEFT", -4, 0)
        r.equip:SetText(L["Equip"])
        SkinButton(r.equip, nil, false)

        r.mode = CreateFrame("Button", nil, r, BACKDROP_TEMPLATE)
        r.mode:SetSize(170, 20)
        r.mode:SetPoint("RIGHT", r.equip, "LEFT", -8, 0)
        r.mode:SetText(" ")
        SkinButton(r.mode, nil, false)
        r.mode:SetScript("OnLeave", function() GameTooltip:Hide() end)

        r.name = GSI_UI:CreateText(r, "BODY", "")
        r.name:SetPoint("LEFT", r.icon, "RIGHT", 6, 0)
        r.name:SetPoint("RIGHT", r.mode, "LEFT", -8, 0)
        r.name:SetJustifyH("LEFT")
        if r.name.SetWordWrap then r.name:SetWordWrap(false) end
        return r
    end

    local numSpecRows = (playerClass == "DRUID") and 4 or 3
    local classData = GSI_ClassicData and GSI_ClassicData.Classes and GSI_ClassicData.Classes[playerClass]
    local prevElem = setDesc
    for i = 1, numSpecRows do
        local specData = classData and classData.specs and classData.specs[i]
        local specIdx = i
        local card = CreateFrame("Frame", nil, scrollChild, BACKDROP_TEMPLATE)
        card:SetPoint("TOPLEFT", prevElem, "BOTTOMLEFT", 0, (i == 1) and -10 or -8)
        card:SetPoint("RIGHT", scrollChild, "RIGHT", -16, 0)
        card:SetHeight(120)
        SkinFrame(card, "well")
        card.specIndex = i
        card.rows = {}

        card.icon = card:CreateTexture(nil, "ARTWORK")
        card.icon:SetSize(20, 20)
        card.icon:SetPoint("TOPLEFT", card, "TOPLEFT", 10, -8)
        card.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        card.icon:SetTexture((specData and specData.icon) or 134400)

        card.title = self:CreateText(card, "CARD_TITLE", (specData and specData.name) and L[specData.name] or string.format(L["Spec %d"], i))
        card.title:SetPoint("LEFT", card.icon, "RIGHT", 8, 0)

        card.playing = self:CreateText(card, "SMALL", "")
        card.playing:SetPoint("LEFT", card.title, "RIGHT", 8, 0)

        -- Talent group (dual spec) for /gsi go: Auto -> 1 -> 2 -> Auto
        card.group = CreateFrame("Button", nil, card, BACKDROP_TEMPLATE)
        card.group:SetSize(150, 22)
        card.group:SetPoint("TOPRIGHT", card, "TOPRIGHT", -10, -7)
        card.group:SetText(" ")
        SkinButton(card.group, nil, false)
        card.group:SetScript("OnClick", function()
            if not GSI_UI.GetSpecTalentGroup then return end
            local cur = GSI_UI:GetSpecTalentGroup(specIdx)
            local nextGroup = (cur == nil and 1) or (cur == 1 and 2) or nil
            GSI_UI:SetSpecTalentGroup(specIdx, nextGroup)
            if RefreshSetRows then RefreshSetRows() end
        end)
        card.group:SetScript("OnEnter", function(selfBtn)
            local SW = GSI_StatWeights
            GameTooltip:SetOwner(selfBtn, "ANCHOR_RIGHT")
            GameTooltip:AddLine(L["Talent group for this spec"], 1, 0.82, 0)
            local n = (SW and SW.GetNumTalentGroups and SW:GetNumTalentGroups()) or 1
            if n < 2 then
                GameTooltip:AddLine(L["Dual specialization is not learned: /gsi go only puts on the gear."], 1, 1, 1, true)
            else
                local active = SW:GetActiveTalentGroup()
                for g = 1, n do
                    local points, names = SW:GetTalentGroupPoints(g)
                    local lead = SW:GetTalentGroupLeadTree(g)
                    local right = points and table.concat(points, " / ") or "?"
                    local left = string.format(L["Group %d"], g) .. ((lead and names and names[lead]) and (": " .. L[names[lead]]) or "")
                    if g == active then left = string.format(L["%s (active)"], left) end
                    GameTooltip:AddDoubleLine(left, right, 1, 1, 1, 0.8, 0.8, 0.8)
                end
                GameTooltip:AddLine(L["Click: Auto, Group 1, Group 2. Auto takes the only group whose most-used tree is this spec's; choose the group when both use the same tree (a Cat and a Bear build)."], 0.7, 0.9, 1, true)
            end
            GameTooltip:AddLine(L["Used by /gsi go <spec>. The 'GSI Dual Spec' macro (/gsi toggle) just switches to the other group and puts on the gear of the spec it plays."], 0.85, 0.85, 0.85, true)
            GameTooltip:Show()
        end)
        card.group:SetScript("OnLeave", function() GameTooltip:Hide() end)

        -- Tooltip lines against the gear worn, one tick per mode
        card.tipLabel = self:CreateText(card, "SMALL", L["Tooltip vs worn gear:"])
        card.tipLabel:SetPoint("TOPLEFT", card, "TOPLEFT", 38, -40)
        local prevTick = card.tipLabel
        for _, pInfo in ipairs(profiles) do
            if pInfo.specIndex == i then
                local cb = CreateFrame("CheckButton", nil, card, "UICheckButtonTemplate")
                cb:SetSize(22, 22)
                cb:SetPoint("LEFT", prevTick, "RIGHT", (prevTick == card.tipLabel) and 6 or 8, 0)
                cb.text = self:CreateText(cb, "BODY", pInfo.modeLabel or pInfo.mode)
                cb.text:SetPoint("LEFT", cb, "RIGHT", 2, 0)
                cb.profileKey = pInfo.key
                cb:SetScript("OnClick", function(selfBtn)
                    if not GearSetImproverDB then GearSetImproverDB = {} end
                    if not GearSetImproverDB.tooltipProfiles then GearSetImproverDB.tooltipProfiles = {} end
                    if not GearSetImproverDB.tooltipProfiles[playerClass] then GearSetImproverDB.tooltipProfiles[playerClass] = {} end
                    GearSetImproverDB.tooltipProfiles[playerClass][selfBtn.profileKey] = selfBtn:GetChecked() and true or false
                    if GSI_TooltipCache and GSI_TooltipCache.Invalidate then
                        GSI_TooltipCache:Invalidate()
                    end
                    if GSI_UI.blizzOptionsPanel and GSI_UI.blizzOptionsPanel.refresh then
                        GSI_UI.blizzOptionsPanel.refresh()
                    end
                end)
                cb:SetScript("OnEnter", function(selfBtn)
                    GameTooltip:SetOwner(selfBtn, "ANCHOR_RIGHT")
                    GameTooltip:AddLine(pInfo.label or "", 1, 0.82, 0)
                    GameTooltip:AddLine(L["A tooltip line scored with these weights against the gear you wear. A spec you are not playing that has sets compares with its sets instead."], 1, 1, 1, true)
                    GameTooltip:Show()
                end)
                cb:SetScript("OnLeave", function() GameTooltip:Hide() end)
                profileCheckboxes[#profileCheckboxes + 1] = cb
                prevTick = cb.text
            end
        end

        card.empty = self:CreateText(card, "SMALL", "")
        card.empty:SetJustifyH("LEFT")
        if card.empty.SetWordWrap then card.empty:SetWordWrap(true) end

        card.add = CreateFrame("Button", nil, card, BACKDROP_TEMPLATE)
        card.add:SetSize(110, 20)
        card.add:SetText(L["+ Add set"])
        SkinButton(card.add, nil, false)
        card.add:SetScript("OnClick", function(selfBtn)
            if picker:IsShown() then picker:Hide() return end
            GameTooltip:Hide()
            OpenAddPicker(selfBtn, specIdx)
        end)
        card.add:SetScript("OnEnter", function(selfBtn)
            GameTooltip:SetOwner(selfBtn, "ANCHOR_RIGHT")
            GameTooltip:AddLine(L["Add an Equipment Set to this spec"], 1, 0.82, 0)
            GameTooltip:AddLine(L["With several sets, switching to the spec asks which one to put on. A set's weights button says which weights it turns on."], 1, 1, 1, true)
            GameTooltip:Show()
        end)
        card.add:SetScript("OnLeave", function() GameTooltip:Hide() end)

        card.auto = CreateFrame("Button", nil, card, BACKDROP_TEMPLATE)
        card.auto:SetSize(120, 20)
        card.auto:SetPoint("LEFT", card.add, "RIGHT", 6, 0)
        card.auto:SetText(L["Back to Auto"])
        SkinButton(card.auto, nil, false)
        card.auto:SetScript("OnClick", function()
            if GSI_UI.SetSpecSets then GSI_UI:SetSpecSets(specIdx, nil) end
            SpecSetsChanged()
        end)
        card.auto:SetScript("OnEnter", function(selfBtn)
            GameTooltip:SetOwner(selfBtn, "ANCHOR_RIGHT")
            GameTooltip:AddLine(L["Back to Auto"], 1, 0.82, 0)
            GameTooltip:AddLine(L["The card lists the sets GSI saves for the spec again (\"GSI: Cat ST\", \"GSI: Resto AoE\", ...), also those it saves later."], 1, 1, 1, true)
            GameTooltip:Show()
        end)
        card.auto:SetScript("OnLeave", function() GameTooltip:Hide() end)

        card.note = self:CreateText(card, "SMALL", "")
        card.note:SetJustifyH("LEFT")

        cards[i] = card
        prevElem = card
    end
    lastElem = prevElem

    local SET_ROW_TOP = -66
    local SET_ROW_STEP = 26

    local function LayoutCard(card, activeSpec)
        local i = card.specIndex
        local names, isManual = {}, false
        if GSI_UI.GetSpecSets then
            local modeNow = GSI_UI.GetCurrentModeFor and GSI_UI:GetCurrentModeFor(i)
            names, isManual = GSI_UI:GetSpecSets(i, modeNow)
        end

        local cardSpecName = (classData and classData.specs and classData.specs[i] and classData.specs[i].name)
        cardSpecName = cardSpecName and L[cardSpecName] or string.format(L["Spec %d"], i)
        card.title:SetText(i == activeSpec and ("|cff40ff9e" .. cardSpecName .. "|r") or cardSpecName)
        card.playing:SetText(i == activeSpec and ("|cff40ff9e" .. L["PLAYING"] .. "|r") or "")

        local y = SET_ROW_TOP
        for idx, n in ipairs(names) do
            local r = card.rows[idx]
            if not r then
                r = CreateSetRow(card)
                card.rows[idx] = r
            end
            r:ClearAllPoints()
            r:SetPoint("TOPLEFT", card, "TOPLEFT", 38, y)
            r:SetPoint("RIGHT", card, "RIGHT", -10, 0)

            local setID = C_EquipmentSet and C_EquipmentSet.GetEquipmentSetID and C_EquipmentSet.GetEquipmentSetID(n)
            local okI, icon, isEquipped = false, nil, false
            if setID then
                local ok, _, ic, _, eq = pcall(C_EquipmentSet.GetEquipmentSetInfo, setID)
                okI, icon, isEquipped = ok, ic, eq
            end
            r.icon:SetTexture((okI and icon) or 134400)
            if not setID then
                r.name:SetText(string.format(L["|cffff4444%s (missing)|r"], n))
            elseif okI and isEquipped then
                r.name:SetText(n .. "  |cff40ff9e" .. L["ON"] .. "|r")
            else
                r.name:SetText(n)
            end

            local setName = n
            local mode = GSI_UI.GetSetMode and GSI_UI:GetSetMode(i, setName)
            r.mode:SetText(ModeButtonText(mode))
            r.mode:SetScript("OnClick", function()
                if GSI_UI.CycleSetMode then GSI_UI:CycleSetMode(i, setName) end
                if RefreshSetRows then RefreshSetRows() end
            end)
            r.mode:SetScript("OnEnter", function(selfBtn)
                local modes = GSI_UI.GetSpecModes and GSI_UI:GetSpecModes(i) or { "ST", "AOE" }
                GameTooltip:SetOwner(selfBtn, "ANCHOR_RIGHT")
                GameTooltip:AddLine(L["Weights this set turns on"], 1, 0.82, 0)
                GameTooltip:AddLine(L["When the set goes on while you play this spec (here, the \"which set?\" prompt, /gsi go, the dual spec macro or the character pane's Equipment Manager), GSI switches to these weights as the mode dropdown in the header does. Tooltip lines for this set are scored with them."], 1, 1, 1, true)
                GameTooltip:AddLine(string.format(L["Click: %s, %s, keep (the set leaves the weights as they are)."],
                    GSI_UI:GetModeLabel(modes[1]) or "?", GSI_UI:GetModeLabel(modes[2]) or "?"), 0.7, 0.9, 1, true)
                GameTooltip:Show()
            end)
            r.equip:SetEnabled(setID ~= nil)
            r.equip:SetScript("OnClick", function()
                if GSI_UI.EquipNamedSet then GSI_UI:EquipNamedSet(setName, i, true) end
            end)
            r.remove:SetScript("OnClick", function()
                if GSI_UI.ToggleSpecSet then GSI_UI:ToggleSpecSet(i, setName) end
                SpecSetsChanged()
            end)
            r:Show()
            y = y - SET_ROW_STEP
        end
        for idx = #names + 1, #card.rows do card.rows[idx]:Hide() end

        if #names == 0 then
            card.empty:SetText(isManual
                and L["No set: switching to this spec puts on the best gear in your bags (/gsi go)."]
                or L["No set yet: GSI saves one when it equips gear for the spec (/gsi equip), or add one of yours."])
            card.empty:ClearAllPoints()
            card.empty:SetPoint("TOPLEFT", card, "TOPLEFT", 38, y - 3)
            card.empty:SetPoint("RIGHT", card, "RIGHT", -10, 0)
            card.empty:Show()
            y = y - 22
        else
            card.empty:Hide()
        end

        card.add:ClearAllPoints()
        card.add:SetPoint("TOPLEFT", card, "TOPLEFT", 38, y - 4)
        card.auto:SetShown(isManual and true or false)
        card.note:ClearAllPoints()
        card.note:SetPoint("LEFT", isManual and card.auto or card.add, "RIGHT", 8, 0)
        card.note:SetText(isManual and L["|cff888888Your own list|r"] or L["|cff888888Auto: the sets GSI saved for the spec|r"])
        card:SetHeight(-(y - 4) + 20 + 10)
    end

    RefreshSetRows = function()
        local SW = GSI_StatWeights
        local activeSpec = SW and SW.GetActiveSpecIndex and SW:GetActiveSpecIndex()
        for _, card in ipairs(cards) do
            LayoutCard(card, activeSpec)

            local i = card.specIndex
            local numGroups = (SW and SW.GetNumTalentGroups and SW:GetNumTalentGroups()) or 1
            if numGroups < 2 or not GSI_UI.ResolveSpecTalentGroup then
                card.group:SetText(L["|cff888888Talents: -|r"])
            else
                local bound = GSI_UI:GetSpecTalentGroup(i)
                if bound then
                    card.group:SetText(string.format(L["Talents: Group %d"], bound))
                else
                    local g = GSI_UI:ResolveSpecTalentGroup(i)
                    card.group:SetText(string.format(L["Talents: Auto |cff888888(%s)|r"], g and tostring(g) or "?"))
                end
            end
        end
        cbSpecAuto:SetChecked(not GSI_StatWeights or not GSI_StatWeights.IsSpecAuto or GSI_StatWeights:IsSpecAuto())
        cbSetAuto:SetChecked(not GSI_UI.IsSpecSetAutoEquip or GSI_UI:IsSpecSetAutoEquip())
        cbCompareSets:SetChecked(not GSI_UI.IsCompareSpecSets or GSI_UI:IsCompareSpecSets())
    end
    GSI_UI.RefreshSpecSetRows = function()
        if UpdateSettingsLayoutAndSync then UpdateSettingsLayoutAndSync() else RefreshSetRows() end
    end

    if CreateFrame then
        local setsWatcher = CreateFrame("Frame")
        pcall(setsWatcher.RegisterEvent, setsWatcher, "EQUIPMENT_SETS_CHANGED")
        pcall(setsWatcher.RegisterEvent, setsWatcher, "PLAYER_EQUIPMENT_CHANGED")
        pcall(setsWatcher.RegisterEvent, setsWatcher, "ACTIVE_TALENT_GROUP_CHANGED")
        pcall(setsWatcher.RegisterEvent, setsWatcher, "PLAYER_TALENT_UPDATE")
        pcall(setsWatcher.RegisterEvent, setsWatcher, "EQUIPMENT_SWAP_FINISHED")
        local queued = false
        setsWatcher:SetScript("OnEvent", function()
            if not parent:IsVisible() or queued then return end
            queued = true
            local function Run()
                queued = false
                if parent:IsVisible() and UpdateSettingsLayoutAndSync then UpdateSettingsLayoutAndSync() end
            end
            if C_Timer and C_Timer.After then C_Timer.After(0.2, Run) else Run() end
        end)
    end

    UpdateSettingsLayoutAndSync = function()
        local hasDE = GSI_UI.HasDisenchantSpell and GSI_UI:HasDisenchantSpell()
        deMacroBtn:SetShown(hasDE and true or false)

        cbDisableChat:SetChecked(GearSetImproverDB and GearSetImproverDB.disableChatOutput == true)
        cbMerchantOverlay:SetChecked(not (GearSetImproverDB and GearSetImproverDB.merchantOverlayEnabled == false))
        for _, cb in ipairs(profileCheckboxes) do
            local checked = false
            if GearSetImproverDB and GearSetImproverDB.tooltipProfiles and GearSetImproverDB.tooltipProfiles[playerClass] then
                checked = (GearSetImproverDB.tooltipProfiles[playerClass][cb.profileKey] == true)
            end
            cb:SetChecked(checked)
        end
        pcall(RefreshSetRows)

        local topY = scrollChild:GetTop()
        local botY = lastElem and lastElem.GetBottom and lastElem:GetBottom()
        local fallbackH = 320 + (#profiles * 36)
        local targetH = fallbackH
        if topY and botY and topY > botY then
            targetH = math.max(fallbackH, math.ceil(topY - botY) + 28)
        end
        scrollChild:SetWidth(math.max(400, (sf:GetWidth() or 710) - 4))
        scrollChild:SetHeight(math.max(540, targetH))
    end

    UpdateSettingsLayoutAndSync()
    parent:HookScript("OnShow", function()
        UpdateSettingsLayoutAndSync()
        if C_Timer and C_Timer.After then
            C_Timer.After(0, UpdateSettingsLayoutAndSync)
        end
    end)
    if C_Timer and C_Timer.After then
        C_Timer.After(0, UpdateSettingsLayoutAndSync)
    end
end

-- ---------------------------------------------------------------
