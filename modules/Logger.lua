-- ============================================================
-- GearSetImprover - Logger.lua (WoW Forever)
-- Records optimization and scoring decisions for log export.
-- ============================================================

GSI_Logger = {
    logs = {},
    maxLines = 500,
    maxSessionLines = 500,
    maxSessions = 20,
    _sanitizedSavedLogs = false,
}

local _BackdropTemplateMixin = _G.BackdropTemplateMixin
local _BACKDROP_TEMPLATE = _BackdropTemplateMixin and "BackdropTemplate" or nil

local function TrimArrayTail(arr, limit)
    if type(arr) ~= "table" or not limit or limit < 1 then return end
    local n = #arr
    if n <= limit then return end
    local drop = n - limit
    for i = 1, limit do
        arr[i] = arr[i + drop]
    end
    for i = limit + 1, n do
        arr[i] = nil
    end
end

local function CountKeys(tbl)
    if type(tbl) ~= "table" then return 0 end
    local c = 0
    for _ in pairs(tbl) do
        c = c + 1
    end
    return c
end

local function PruneSavedSessions(logTable, maxSessions, maxSessionLines)
    if type(logTable) ~= "table" then return end
    local sessions = {}
    for k, v in pairs(logTable) do
        if type(v) == "table" then
            TrimArrayTail(v, maxSessionLines)
            sessions[#sessions + 1] = k
        else
            logTable[k] = nil
        end
    end
    if #sessions > maxSessions then
        table.sort(sessions)
        local removeCount = #sessions - maxSessions
        for i = 1, removeCount do
            logTable[sessions[i]] = nil
        end
    end
end

local function MakeUniqueSessionID(logTable)
    local base = (date and date("%Y-%m-%d %H:%M:%S")) or "session"
    if type(logTable) ~= "table" or not logTable[base] then
        return base
    end
    local idx = 2
    while logTable[base .. " #" .. idx] do
        idx = idx + 1
    end
    return base .. " #" .. idx
end

function GSI_Logger:EnsureSavedLogsPruned()
    if not GearSetImproverLog then
        GearSetImproverLog = {}
    end
    if not self._sanitizedSavedLogs then
        self._sanitizedSavedLogs = true
        PruneSavedSessions(GearSetImproverLog, self.maxSessions or 20, self.maxSessionLines or 500)
    end
end

function GSI_Logger:Clear(force)
    if force or #self.logs == 0 then
        self.logs = {}
        self:EnsureSavedLogsPruned()
        self.currentSessionID = MakeUniqueSessionID(GearSetImproverLog)
        self:Add("--- OPTIMIZATION STARTED (WoW Forever) ---")
        if self.frame and self.frame:IsShown() and self.RefreshExportWindow then
            self:RefreshExportWindow()
        end
    end
end

function GSI_Logger:Add(msg)
    local timestamp = (date and date("%H:%M:%S")) or "00:00:00"
    local text = tostring(msg or "")
    local fullMsg = string.format("[%s] %s", timestamp, text)

    local maxMemLines = self.maxLines or 500
    self.logs[#self.logs + 1] = fullMsg
    TrimArrayTail(self.logs, maxMemLines)

    self:EnsureSavedLogsPruned()
    if not self.currentSessionID then
        self.currentSessionID = MakeUniqueSessionID(GearSetImproverLog)
    end

    local maxSessLines = self.maxSessionLines or 500
    local maxSessCount = self.maxSessions or 20

    if not GearSetImproverLog[self.currentSessionID] then
        GearSetImproverLog[self.currentSessionID] = {}
        PruneSavedSessions(GearSetImproverLog, maxSessCount, maxSessLines)
    end

    local sessionLog = GearSetImproverLog[self.currentSessionID]
    sessionLog[#sessionLog + 1] = fullMsg
    TrimArrayTail(sessionLog, maxSessLines)
end

function GSI_Logger:GetText()
    return table.concat(self.logs, "\n")
end

local function ResolveSafeFont()
    if GSI_UI and GSI_UI.GetFontPath then
        local p = GSI_UI:GetFontPath()
        if p and p ~= "" then return p end
    end
    if _G.STANDARD_TEXT_FONT and _G.STANDARD_TEXT_FONT ~= "" then
        return _G.STANDARD_TEXT_FONT
    end
    return "Interface\\AddOns\\GearSetImprover\\Fonts\\Expressway.ttf"
end

local function CreateStyledButton(parent, width, height, label, variant, fontPath)
    local btn = CreateFrame("Button", nil, parent, _BACKDROP_TEMPLATE)
    btn:SetSize(width, height)
    if GSI_UI and GSI_UI.SkinButton then
        GSI_UI:SkinButton(btn, label, variant or "SECONDARY")
    else
        if btn.SetNormalFontObject and _G.GameFontHighlight then
            btn:SetNormalFontObject(_G.GameFontHighlight)
        end
        btn:SetText(label)
        local fs = btn.GetFontString and btn:GetFontString()
        if fs and fs.SetFont then
            fs:SetFont(fontPath, 11, "")
            fs:SetTextColor(0.95, 0.96, 0.97, 1)
        end
        if btn.SetBackdrop then
            btn:SetBackdrop({
                bgFile = "Interface\\Buttons\\WHITE8x8",
                edgeFile = "Interface\\Buttons\\WHITE8x8",
                edgeSize = 1,
            })
            if variant == "PRIMARY" then
                btn:SetBackdropColor(0.18, 0.34, 0.56, 1)
                btn:SetBackdropBorderColor(0.35, 0.62, 0.95, 1)
            elseif variant == "DANGER" then
                btn:SetBackdropColor(0.24, 0.08, 0.08, 1)
                btn:SetBackdropBorderColor(0.75, 0.25, 0.25, 1)
            else
                btn:SetBackdropColor(0.16, 0.18, 0.22, 1)
                btn:SetBackdropBorderColor(0.40, 0.42, 0.48, 1)
            end
        end
    end
    return btn
end

function GSI_Logger:RefreshExportWindow()
    local f = self.frame
    if not f or not f.editBox then return end

    local eb = f.editBox
    local sf = f.scrollFrame
    local txt = self:GetText()
    eb:SetText(txt)

    if f.emptyLabel then
        if txt == "" then
            f.emptyLabel:Show()
        else
            f.emptyLabel:Hide()
        end
    end

    local lineCount = #self.logs
    local maxMemLines = self.maxLines or 500
    local sessCount = CountKeys(GearSetImproverLog)
    local maxSessCount = self.maxSessions or 20
    if f.statusText then
        f.statusText:SetText(string.format(
            "Press Ctrl+C to copy  |  Session: %d / %d lines  |  Saved sessions: %d / %d",
            lineCount, maxMemLines, sessCount, maxSessCount
        ))
    end

    local sfWidth = (sf and sf.GetWidth and sf:GetWidth()) or 534
    if sfWidth > 100 then
        eb:SetWidth(sfWidth - 12)
    end

    local visualLines = (eb.GetNumLines and eb:GetNumLines()) or 0
    if visualLines < lineCount then
        visualLines = lineCount
    end
    local h = math.max(320, (visualLines * 14) + 24)
    eb:SetHeight(h)

    if sf and sf.UpdateScrollChildRect then
        sf:UpdateScrollChildRect()
    end
end

function GSI_Logger:ShowExportWindow()
    self:EnsureSavedLogsPruned()

    if not self.frame then
        local fontPath = ResolveSafeFont()

        local f = CreateFrame("Frame", "GSI_LogExportFrame", UIParent, _BACKDROP_TEMPLATE)
        f:SetSize(600, 450)
        f:SetPoint("CENTER")
        f:SetMovable(true)
        f:SetClampedToScreen(true)
        f:EnableMouse(true)
        f:RegisterForDrag("LeftButton")
        f:SetScript("OnDragStart", f.StartMoving)
        f:SetScript("OnDragStop", f.StopMovingOrSizing)
        f:SetFrameStrata("DIALOG")
        f:SetFrameLevel(500)

        if GSI_UI and GSI_UI.SkinFrame then
            GSI_UI:SkinFrame(f, "dialog")
            if GSI_UI.GetClassColor then
                local topAccent = f:CreateTexture(nil, "OVERLAY")
                topAccent:SetPoint("TOPLEFT", f, "TOPLEFT", 1, -1)
                topAccent:SetPoint("TOPRIGHT", f, "TOPRIGHT", -1, -1)
                topAccent:SetHeight(2)
                local cr, cg, cb = GSI_UI:GetClassColor()
                if topAccent.SetColorTexture then
                    topAccent:SetColorTexture(cr, cg, cb, 1)
                else
                    topAccent:SetTexture("Interface\\Buttons\\WHITE8x8")
                    topAccent:SetVertexColor(cr, cg, cb, 1)
                end
            end
        elseif f.SetBackdrop then
            f:SetBackdrop({
                bgFile = "Interface\\Buttons\\WHITE8x8",
                edgeFile = "Interface\\Buttons\\WHITE8x8",
                tile = false, tileSize = 0, edgeSize = 1,
                insets = { left = 0, right = 0, top = 0, bottom = 0 },
            })
            f:SetBackdropColor(0.06, 0.07, 0.10, 0.96)
            f:SetBackdropBorderColor(0.80, 0.65, 0.10, 1)
        end

        local topClose = CreateStyledButton(f, 22, 22, "X", "DANGER", fontPath)
        topClose:SetPoint("TOPRIGHT", f, "TOPRIGHT", -8, -8)
        topClose:SetScript("OnClick", function() f:Hide() end)

        local title
        if GSI_UI and GSI_UI.CreateText then
            title = GSI_UI:CreateText(f, "TITLE", "GearSetImprover - Log Export (WoW Forever)", "LEFT")
        else
            title = f:CreateFontString(nil, "OVERLAY")
            title:SetFont(fontPath, 14, "")
            title:SetTextColor(0.95, 0.96, 0.97, 1)
            title:SetJustifyH("LEFT")
            title:SetText("GearSetImprover - Log Export (WoW Forever)")
        end
        title:SetPoint("TOPLEFT", f, "TOPLEFT", 16, -14)
        title:SetPoint("RIGHT", topClose, "LEFT", -8, 0)
        if title.SetWordWrap then title:SetWordWrap(false) end
        f.TitleText = title

        local statusText
        if GSI_UI and GSI_UI.CreateText then
            statusText = GSI_UI:CreateText(f, "SMALL", "", "LEFT")
        else
            statusText = f:CreateFontString(nil, "OVERLAY")
            statusText:SetFont(fontPath, 10, "")
            statusText:SetTextColor(0.63, 0.66, 0.73, 1)
            statusText:SetJustifyH("LEFT")
        end
        statusText:SetPoint("TOPLEFT", f, "TOPLEFT", 16, -34)
        statusText:SetPoint("RIGHT", topClose, "LEFT", -8, 0)
        if statusText.SetWordWrap then statusText:SetWordWrap(false) end
        f.statusText = statusText

        -- Inset container for scrollable EditBox (568x346 inside 600x450 frame)
        local inputBg = CreateFrame("Frame", "GSI_LogExportInputBg", f, _BACKDROP_TEMPLATE)
        inputBg:SetPoint("TOPLEFT", f, "TOPLEFT", 16, -56)
        inputBg:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -16, 48)
        inputBg:EnableMouse(true)
        if GSI_UI and GSI_UI.SkinFrame then
            GSI_UI:SkinFrame(inputBg, "well")
        elseif inputBg.SetBackdrop then
            inputBg:SetBackdrop({
                bgFile = "Interface\\Buttons\\WHITE8x8",
                edgeFile = "Interface\\Buttons\\WHITE8x8",
                edgeSize = 1,
            })
            inputBg:SetBackdropColor(0.035, 0.04, 0.058, 0.98)
            inputBg:SetBackdropBorderColor(0.28, 0.30, 0.36, 1)
        end
        f.inputBg = inputBg

        local sf = CreateFrame("ScrollFrame", "GSI_LogExportScroll", inputBg, "UIPanelScrollFrameTemplate")
        sf:SetPoint("TOPLEFT", inputBg, "TOPLEFT", 8, -8)
        sf:SetPoint("BOTTOMRIGHT", inputBg, "BOTTOMRIGHT", -26, 8)
        sf:EnableMouse(true)
        if GSI_UI and GSI_UI.SkinScrollBar then
            GSI_UI:SkinScrollBar(sf)
        end
        f.scrollFrame = sf

        local eb = CreateFrame("EditBox", "GSI_LogExportEditBox", sf)
        if eb.SetMultiLine then eb:SetMultiLine(true) end
        if eb.SetMaxLetters then eb:SetMaxLetters(0) end
        eb:SetAutoFocus(false)
        local fontApplied = eb:SetFont(fontPath, 11, "")
        if not fontApplied and _G.STANDARD_TEXT_FONT then
            eb:SetFont(_G.STANDARD_TEXT_FONT, 11, "")
        end
        if eb.SetTextColor then
            eb:SetTextColor(0.95, 0.96, 0.97, 1)
        end
        if eb.SetTextInsets then
            eb:SetTextInsets(4, 4, 4, 4)
        end
        eb:SetWidth(522)
        eb:SetHeight(320)
        eb:SetScript("OnEscapePressed", function() f:Hide() end)
        sf:SetScrollChild(eb)
        f.editBox = eb

        local emptyLabel
        if GSI_UI and GSI_UI.CreateText then
            emptyLabel = GSI_UI:CreateText(inputBg, "BODY", "No log entries recorded in this session yet.\nRun an optimization or gear check to populate the log.", "CENTER")
        else
            emptyLabel = inputBg:CreateFontString(nil, "OVERLAY")
            emptyLabel:SetFont(fontPath, 11, "")
            emptyLabel:SetTextColor(0.55, 0.58, 0.65, 1)
            emptyLabel:SetJustifyH("CENTER")
            emptyLabel:SetText("No log entries recorded in this session yet.\nRun an optimization or gear check to populate the log.")
        end
        emptyLabel:SetPoint("CENTER", sf, "CENTER", 0, 0)
        emptyLabel:SetWidth(460)
        emptyLabel:Hide()
        f.emptyLabel = emptyLabel

        eb:SetScript("OnTextChanged", function(selfEb)
            local lines = (selfEb.GetNumLines and selfEb:GetNumLines()) or 1
            local h = math.max(320, (lines * 14) + 24)
            selfEb:SetHeight(h)
            if sf.UpdateScrollChildRect then
                sf:UpdateScrollChildRect()
            end
        end)

        eb:SetScript("OnCursorChanged", function(_, _, y, _, ch)
            if not y or not sf.GetVerticalScroll then return end
            local curScroll = sf:GetVerticalScroll() or 0
            local viewH = (sf.GetHeight and sf:GetHeight()) or 330
            local cursorTop = -y
            local cursorBottom = cursorTop + (ch or 14)
            if cursorTop < curScroll then
                sf:SetVerticalScroll(math.max(0, cursorTop))
            elseif cursorBottom > (curScroll + viewH) then
                local maxScroll = (sf.GetVerticalScrollRange and sf:GetVerticalScrollRange()) or math.max(0, eb:GetHeight() - viewH)
                sf:SetVerticalScroll(math.min(maxScroll, math.max(0, cursorBottom - viewH)))
            end
        end)

        eb:SetScript("OnEditFocusGained", function()
            if inputBg.SetBorderColor then
                inputBg:SetBorderColor(1, 0.82, 0, 0.9)
            elseif inputBg.SetBackdropBorderColor then
                inputBg:SetBackdropBorderColor(1, 0.82, 0, 1)
            end
        end)

        eb:SetScript("OnEditFocusLost", function()
            if inputBg.SetBorderColor then
                local T = GSI_UI and GSI_UI.THEME
                if T and T.borderSubtle then
                    inputBg:SetBorderColor(unpack(T.borderSubtle))
                else
                    inputBg:SetBorderColor(0.28, 0.30, 0.36, 1)
                end
            elseif inputBg.SetBackdropBorderColor then
                inputBg:SetBackdropBorderColor(0.28, 0.30, 0.36, 1)
            end
        end)

        sf:SetScript("OnSizeChanged", function(selfSf, width)
            if width and width > 100 then
                eb:SetWidth(width - 12)
            end
        end)

        inputBg:SetScript("OnMouseDown", function() eb:SetFocus() end)
        sf:SetScript("OnMouseDown", function() eb:SetFocus() end)

        -- Bottom action buttons: Clear Log + Refresh on left; Select All + Close on right
        local clearBtn = CreateStyledButton(f, 100, 26, "Clear Log", "DANGER", fontPath)
        clearBtn:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 16, 12)
        clearBtn:SetScript("OnClick", function()
            GSI_Logger:Clear(true)
            GSI_Logger:RefreshExportWindow()
        end)

        local refreshBtn = CreateStyledButton(f, 90, 26, "Refresh", "SECONDARY", fontPath)
        refreshBtn:SetPoint("LEFT", clearBtn, "RIGHT", 8, 0)
        refreshBtn:SetScript("OnClick", function()
            GSI_Logger:RefreshExportWindow()
        end)

        local closeBtn = CreateStyledButton(f, 100, 26, "Close", "SECONDARY", fontPath)
        closeBtn:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -16, 12)
        closeBtn:SetScript("OnClick", function() f:Hide() end)

        local selectBtn = CreateStyledButton(f, 105, 26, "Select All", "PRIMARY", fontPath)
        selectBtn:SetPoint("RIGHT", closeBtn, "LEFT", -8, 0)
        selectBtn:SetScript("OnClick", function()
            eb:SetFocus()
            if eb.HighlightText then
                eb:HighlightText()
            end
        end)

        if GSI_UI and GSI_UI.RegisterModalForEscape then
            GSI_UI:RegisterModalForEscape(f)
        elseif _G.UISpecialFrames and table and table.insert then
            table.insert(_G.UISpecialFrames, "GSI_LogExportFrame")
        end

        self.frame = f
    end

    self:RefreshExportWindow()
    self.frame:Show()

    if self:GetText() ~= "" then
        local eb = self.frame.editBox
        if eb.HighlightText then eb:HighlightText() end
        if C_Timer and C_Timer.After then
            C_Timer.After(0.05, function()
                if self.frame and self.frame:IsShown() and eb then
                    eb:SetFocus()
                    if eb.HighlightText then eb:HighlightText() end
                end
            end)
        end
    end
end
