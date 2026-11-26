-- ============================================================================
-- GearSetImprover (GSI) -- UI_Shared.lua (WoW Forever)
-- Premium Design System: "Obsidian Glass & Specular Precision"
-- Inspiriert von moderner SaaS-Ästhetik (Linear, Raycast, Vercel)
-- ============================================================================

GSI_UI = GSI_UI or {}

local GetItemInfo = (C_Item and C_Item.GetItemInfo) or _G.GetItemInfo or function() return nil end
local GetItemInfoInstant = (C_Item and C_Item.GetItemInfoInstant) or _G.GetItemInfoInstant or function() return nil end
local BackdropTemplateMixin = _G.BackdropTemplateMixin
local BACKDROP_TEMPLATE = BackdropTemplateMixin and "BackdropTemplate" or nil
GSI_UI.BACKDROP_TEMPLATE = BACKDROP_TEMPLATE

local function SafeGetItemIcon(item)
    if _G.GSI_GetItemIcon then return _G.GSI_GetItemIcon(item) end
    if not item then return "Interface\\Icons\\INV_Misc_QuestionMark" end
    if type(item) == "table" and C_Item and C_Item.GetItemIcon then
        local ok, icon = pcall(C_Item.GetItemIcon, item)
        if ok and icon then return icon end
    end
    if C_Item and C_Item.GetItemIconByID then
        local ok, icon = pcall(C_Item.GetItemIconByID, item)
        if ok and icon then return icon end
    end
    local instantFn = (C_Item and C_Item.GetItemInfoInstant) or _G.GetItemInfoInstant
    if instantFn then
        local ok, _, _, _, _, icon = pcall(instantFn, item)
        if ok and icon then return icon end
    end
    local infoFn = (C_Item and C_Item.GetItemInfo) or _G.GetItemInfo
    if infoFn then
        local ok, _, _, _, _, _, _, _, _, _, icon = pcall(infoFn, item)
        if ok and icon then return icon end
    end
    return "Interface\\Icons\\INV_Misc_QuestionMark"
end

-- ----------------------------------------------------------------------------
-- 1. PIXEL-PERFECT ENGINE & GRADIENT COMPATIBILITY
-- ----------------------------------------------------------------------------
function GSI_UI:GetPixelScale()
    local screenHeight = select(2, GetPhysicalScreenSize())
    if not screenHeight or screenHeight == 0 then screenHeight = 1080 end
    local uiScale = (UIParent and UIParent.GetEffectiveScale and UIParent:GetEffectiveScale()) or 1.0
    return (768.0 / screenHeight) / math.max(0.01, uiScale)
end

function GSI_UI:PP(pixels)
    if self ~= GSI_UI then pixels = self; self = GSI_UI end
    return (pixels or 1) * self:GetPixelScale()
end

function GSI_UI:SetGradient(texture, orientation, r1, g1, b1, a1, r2, g2, b2, a2)
    if self ~= GSI_UI then
        texture, orientation, r1, g1, b1, a1, r2, g2, b2, a2 = self, texture, orientation, r1, g1, b1, a1, r2, g2, b2
        self = GSI_UI
    end
    if not texture then return end
    a1 = a1 or 1.0
    a2 = a2 or 1.0
    if texture.SetGradient and CreateColor then
        pcall(function()
            texture:SetGradient(orientation, CreateColor(r1, g1, b1, a1), CreateColor(r2, g2, b2, a2))
        end)
    elseif texture.SetGradientAlpha then
        pcall(function()
            texture:SetGradientAlpha(orientation, r1, g1, b1, a1, r2, g2, b2, a2)
        end)
    else
        texture:SetVertexColor(r1, g1, b1, a1)
    end
end

-- ----------------------------------------------------------------------------
-- 2. DYNAMIC CLASS COLOR HELPER
-- ----------------------------------------------------------------------------
function GSI_UI:GetClassColor()
    local class = select(2, UnitClass("player")) or "WARRIOR"
    local c = (CUSTOM_CLASS_COLORS and CUSTOM_CLASS_COLORS[class]) or (RAID_CLASS_COLORS and RAID_CLASS_COLORS[class])
    local r = c and c.r or 1.00
    local g = c and c.g or 0.78
    local b = c and c.b or 0.20
    local hex = string.format("%02x%02x%02x", math.floor(r * 255 + 0.5), math.floor(g * 255 + 0.5), math.floor(b * 255 + 0.5))
    return r, g, b, hex
end

-- ----------------------------------------------------------------------------
-- 3. DESIGN TOKENS (GSI_UI.THEME)
-- ----------------------------------------------------------------------------
local cr, cg, cb = GSI_UI:GetClassColor()

GSI_UI.THEME = {
    -- Obsidian Surface Hierarchy (Level 0 bis 3)
    bgCanvas        = { 0.031, 0.035, 0.051, 0.96 }, -- #08090D Deep Canvas
    bgSidebar       = { 0.047, 0.055, 0.078, 0.98 }, -- #0C0E14 Sidebar Recessed
    bgHeader        = { 0.055, 0.063, 0.090, 0.98 }, -- #0E1017 Header Recessed
    bgCardTop       = { 0.082, 0.094, 0.137, 1.00 }, -- #151823 Elevated Top
    bgCardBottom    = { 0.063, 0.071, 0.106, 1.00 }, -- #10121B Elevated Bottom
    bgCardHoverTop  = { 0.110, 0.125, 0.180, 1.00 }, -- #1C202E Hover Top
    bgCardHoverBot  = { 0.082, 0.094, 0.137, 1.00 }, -- #151823 Hover Bottom
    bgInput         = { 0.035, 0.040, 0.058, 1.00 }, -- #090A0F Recessed Well

    -- Micro-Borders & Specular Top Lighting
    borderSubtle    = { 1.000, 1.000, 1.000, 0.06 }, -- 6% White
    borderSpecular  = { 1.000, 1.000, 1.000, 0.15 }, -- 15% White (Top light edge)
    borderHover     = { 1.000, 1.000, 1.000, 0.22 }, -- 22% White

    -- Dynamic Class Accents
    accent          = { cr, cg, cb, 1.00 },
    accentBright    = { math.min(1, cr + 0.18), math.min(1, cg + 0.18), math.min(1, cb + 0.18), 1.00 },
    accentGlow      = { cr, cg, cb, 0.40 },
    accentSurface   = { cr, cg, cb, 0.14 },
    accentMuted     = { cr, cg, cb, 0.07 },

    -- Semantic Status Colors (FinTech Emerald, Amber & Crimson)
    success         = { 0.063, 0.725, 0.506, 1.00 }, -- #10B981 (Emerald)
    successSurface  = { 0.063, 0.725, 0.506, 0.14 },
    successBorder   = { 0.063, 0.725, 0.506, 0.35 },
    warning         = { 0.961, 0.620, 0.043, 1.00 }, -- #F59E0B (Amber)
    warningSurface  = { 0.961, 0.620, 0.043, 0.14 },
    danger          = { 0.937, 0.267, 0.267, 1.00 }, -- #EF4444 (Rose Crimson)
    dangerSurface   = { 0.937, 0.267, 0.267, 0.14 },

    -- Typography Hierarchy Colors
    textPrimary     = { 0.949, 0.957, 0.973, 1.00 }, -- #F2F4F8 (Off-White)
    textSecondary   = { 0.631, 0.663, 0.729, 1.00 }, -- #A1A9BA (Cool Slate)
    textMuted       = { 0.400, 0.431, 0.502, 1.00 }, -- #666E80 (Muted Graphite)
    textHighlight   = { 1.000, 1.000, 1.000, 1.00 },

    -- Quality Colors
    quality = {
        [0] = { 0.62, 0.62, 0.62, 1.0 },
        [1] = { 1.00, 1.00, 1.00, 1.0 },
        [2] = { 0.12, 1.00, 0.00, 1.0 },
        [3] = { 0.00, 0.44, 0.87, 1.0 },
        [4] = { 0.64, 0.21, 0.93, 1.0 },
        [5] = { 1.00, 0.50, 0.00, 1.0 },
    }
}

-- ----------------------------------------------------------------------------
-- 4. TYPOGRAPHY ENGINE (Expressway Font Resolution & Multi-Tier Text Styles)
-- ----------------------------------------------------------------------------
local probeFont = nil
local function IsValidFont(fontPath)
    if not fontPath or fontPath == "" or type(fontPath) ~= "string" then return false end
    if not probeFont then
        probeFont = _G.GSI_ProbeFont or CreateFont("GSI_ProbeFont")
    end
    if not probeFont then return true end
    local ok = pcall(function()
        return probeFont:SetFont(fontPath, 12, "")
    end)
    if not ok then return false end
    local actual = probeFont:GetFont()
    return actual ~= nil and actual ~= ""
end

local function ResolveExpresswayFont()
    -- 1. Check LibSharedMedia-3.0 if available
    if LibStub then
        local LSM = LibStub("LibSharedMedia-3.0", true)
        if LSM then
            pcall(function()
                LSM:Register("font", "Expressway", "Interface\\AddOns\\GearSetImprover\\Fonts\\Expressway.ttf")
            end)
            local lsmFont = LSM:Fetch("font", "Expressway")
            if lsmFont and lsmFont ~= "" and IsValidFont(lsmFont) then
                return lsmFont
            end
            local lsmEn = LSM:Fetch("font", "Expressway (en)")
            if lsmEn and lsmEn ~= "" and IsValidFont(lsmEn) then
                return lsmEn
            end
        end
    end

    -- 2. Multi-tier candidate paths in WoW Forever (Bundled -> Known Addons -> Root)
    local candidatePaths = {
        "Interface\\AddOns\\GearSetImprover\\Fonts\\Expressway.ttf",
        "Interface\\AddOns\\ElvUI\\Game\\Shared\\Media\\Fonts\\Expressway.ttf",
        "Interface\\AddOns\\EllesmereUI\\media\\fonts\\Expressway.TTF",
        "Interface\\AddOns\\EllesmereUI\\media\\fonts\\Expressway Bold.ttf",
        "Interface\\AddOns\\Details\\fonts\\Expressway.TTF",
        "Interface\\AddOns\\ChonkyCharacterSheet\\Media\\Fonts\\Expressway.ttf",
        "Interface\\AddOns\\FontMagic\\Popular\\Expressway.ttf",
        "Interface\\AddOns\\EUIStandaloneAuraBuffReminders\\media\\fonts\\Expressway.TTF",
        "Fonts\\Expressway.ttf",
        "Fonts\\Expressway.TTF",
    }

    for _, path in ipairs(candidatePaths) do
        if IsValidFont(path) then
            return path
        end
    end

    -- 3. Failsafe client fallback if no Expressway font file is accessible
    local standardFallback = STANDARD_TEXT_FONT
    if standardFallback and IsValidFont(standardFallback) then
        return standardFallback
    end

    if GameFontNormal and GameFontNormal.GetFont then
        local gf = GameFontNormal:GetFont()
        if gf and IsValidFont(gf) then
            return gf
        end
    end

    return "Interface\\AddOns\\GearSetImprover\\Fonts\\Expressway.ttf"
end

local FONT_PATH = ResolveExpresswayFont()
GSI_UI.FONT_PATH = FONT_PATH

function GSI_UI:GetFontPath()
    if not self.FONT_PATH or self.FONT_PATH == "" then
        self.FONT_PATH = ResolveExpresswayFont()
    end
    return self.FONT_PATH
end

function GSI_UI:GetExpresswayFont()
    return self:GetFontPath()
end

-- Shared Expressway FontObjects
local GSI_FontNormal = _G.GSI_FontNormal or CreateFont("GSI_FontNormal")
GSI_FontNormal:SetFont(FONT_PATH, 11, "")
GSI_FontNormal:SetTextColor(unpack(GSI_UI.THEME.textSecondary))
GSI_FontNormal:SetShadowOffset(1, -1)
GSI_FontNormal:SetShadowColor(0, 0, 0, 0.7)

local GSI_FontHighlight = _G.GSI_FontHighlight or CreateFont("GSI_FontHighlight")
GSI_FontHighlight:SetFont(FONT_PATH, 11, "")
GSI_FontHighlight:SetTextColor(unpack(GSI_UI.THEME.textPrimary))
GSI_FontHighlight:SetShadowOffset(1, -1)
GSI_FontHighlight:SetShadowColor(0, 0, 0, 0.8)

local GSI_FontDisabled = _G.GSI_FontDisabled or CreateFont("GSI_FontDisabled")
GSI_FontDisabled:SetFont(FONT_PATH, 11, "")
GSI_FontDisabled:SetTextColor(unpack(GSI_UI.THEME.textMuted))
GSI_FontDisabled:SetShadowOffset(0, 0)

local GSI_FontTitle = _G.GSI_FontTitle or CreateFont("GSI_FontTitle")
GSI_FontTitle:SetFont(FONT_PATH, 14, "")
GSI_FontTitle:SetTextColor(unpack(GSI_UI.THEME.textPrimary))
GSI_FontTitle:SetShadowOffset(1, -1)
GSI_FontTitle:SetShadowColor(0, 0, 0, 0.8)

local GSI_FontLarge = _G.GSI_FontLarge or CreateFont("GSI_FontLarge")
GSI_FontLarge:SetFont(FONT_PATH, 15, "")
GSI_FontLarge:SetTextColor(unpack(GSI_UI.THEME.textPrimary))
GSI_FontLarge:SetShadowOffset(1, -1)
GSI_FontLarge:SetShadowColor(0, 0, 0, 0.8)

local GSI_FontSmall = _G.GSI_FontSmall or CreateFont("GSI_FontSmall")
GSI_FontSmall:SetFont(FONT_PATH, 10, "")
GSI_FontSmall:SetTextColor(unpack(GSI_UI.THEME.textMuted))
GSI_FontSmall:SetShadowOffset(1, -1)
GSI_FontSmall:SetShadowColor(0, 0, 0, 0.7)

GSI_UI.FontNormal = GSI_FontNormal
GSI_UI.FontHighlight = GSI_FontHighlight
GSI_UI.FontDisabled = GSI_FontDisabled
GSI_UI.FontTitle = GSI_FontTitle
GSI_UI.FontLarge = GSI_FontLarge
GSI_UI.FontSmall = GSI_FontSmall

-- Dynamic LibSharedMedia registration listener
if LibStub then
    local LSM = LibStub("LibSharedMedia-3.0", true)
    if LSM and LSM.RegisterCallback then
        LSM.RegisterCallback(GSI_UI, "LibSharedMedia_Registered", function(_, mediaType, key)
            if mediaType == "font" and (key == "Expressway" or key == "Expressway (en)") then
                local resolved = ResolveExpresswayFont()
                if resolved and resolved ~= GSI_UI.FONT_PATH then
                    GSI_UI.FONT_PATH = resolved
                    if GSI_FontNormal then GSI_FontNormal:SetFont(resolved, 11, "") end
                    if GSI_FontHighlight then GSI_FontHighlight:SetFont(resolved, 11, "") end
                    if GSI_FontDisabled then GSI_FontDisabled:SetFont(resolved, 11, "") end
                    if GSI_FontTitle then GSI_FontTitle:SetFont(resolved, 14, "") end
                    if GSI_FontLarge then GSI_FontLarge:SetFont(resolved, 15, "") end
                    if GSI_FontSmall then GSI_FontSmall:SetFont(resolved, 10, "") end
                end
            end
        end)
    end
end

function GSI_UI:CreateText(parent, style, text, justifyH)
    if self ~= GSI_UI then
        parent, style, text, justifyH = self, parent, style, text
        self = GSI_UI
    end
    local fs = parent:CreateFontString(nil, "OVERLAY")
    local T = self.THEME
    local font = self:GetFontPath()

    local s = type(style) == "string" and string.upper(style) or style

    if s == "HERO_SCORE" then
        fs:SetFont(font, 24, "OUTLINE")
        fs:SetTextColor(unpack(T.textPrimary))
        fs:SetShadowOffset(1, -1)
        fs:SetShadowColor(0, 0, 0, 0.95)
    elseif s == "TITLE" then
        fs:SetFont(font, 14, "")
        fs:SetShadowOffset(1, -1)
        fs:SetShadowColor(0, 0, 0, 0.8)
        fs:SetTextColor(unpack(T.textPrimary))
    elseif s == "LARGE" or s == "TITLE_LARGE" then
        fs:SetFont(font, 15, "")
        fs:SetShadowOffset(1, -1)
        fs:SetShadowColor(0, 0, 0, 0.8)
        fs:SetTextColor(unpack(T.textPrimary))
    elseif s == "CARD_TITLE" then
        fs:SetFont(font, 12, "")
        fs:SetShadowOffset(1, -1)
        fs:SetShadowColor(0, 0, 0, 0.7)
        fs:SetTextColor(unpack(T.textPrimary))
    elseif s == "SECTION" then
        fs:SetFont(font, 11, "")
        fs:SetShadowOffset(1, -1)
        fs:SetShadowColor(0, 0, 0, 0.6)
        fs:SetTextColor(unpack(T.textMuted))
    elseif s == "BODY" then
        fs:SetFont(font, 11, "")
        fs:SetShadowOffset(1, -1)
        fs:SetShadowColor(0, 0, 0, 0.7)
        fs:SetTextColor(unpack(T.textSecondary))
    elseif s == "VALUE" then
        fs:SetFont(font, 12, "")
        fs:SetShadowOffset(1, -1)
        fs:SetShadowColor(0, 0, 0, 0.7)
        fs:SetTextColor(unpack(T.textPrimary))
    elseif s == "STAT_LABEL" then
        fs:SetFont(font, 11, "")
        fs:SetShadowOffset(1, -1)
        fs:SetShadowColor(0, 0, 0, 0.7)
        fs:SetTextColor(unpack(T.textSecondary))
    elseif s == "MONO_NUM" then
        fs:SetFont(font, 12, "")
        fs:SetShadowOffset(1, -1)
        fs:SetShadowColor(0, 0, 0, 0.8)
        fs:SetTextColor(unpack(T.textPrimary))
    elseif s == "SMALL" then
        fs:SetFont(font, 10, "")
        fs:SetShadowOffset(1, -1)
        fs:SetShadowColor(0, 0, 0, 0.7)
        fs:SetTextColor(unpack(T.textMuted))
    elseif s == "BADGE" or s == "PILL" then
        fs:SetFont(font, 10, "")
        fs:SetShadowOffset(1, -1)
        fs:SetShadowColor(0, 0, 0, 0.8)
        fs:SetTextColor(unpack(T.textPrimary))
    elseif type(style) == "number" then
        fs:SetFont(font, style, "")
        fs:SetShadowOffset(1, -1)
        fs:SetShadowColor(0, 0, 0, 0.7)
        fs:SetTextColor(unpack(T.textPrimary))
    else
        fs:SetFont(font, 10, "")
        fs:SetShadowOffset(1, -1)
        fs:SetShadowColor(0, 0, 0, 0.7)
        fs:SetTextColor(unpack(T.textMuted))
    end

    fs:SetJustifyH(justifyH or "LEFT")
    if text then fs:SetText(text) end
    return fs
end

function GSI_UI:ApplyFont(fontString, styleOrSize, flags, color)
    if self ~= GSI_UI then
        fontString, styleOrSize, flags, color = self, fontString, styleOrSize, flags
        self = GSI_UI
    end
    if not fontString or not fontString.SetFont then return end
    local font = self:GetFontPath()
    local T = self.THEME

    local s = type(styleOrSize) == "string" and string.upper(styleOrSize) or styleOrSize

    if type(s) == "number" then
        fontString:SetFont(font, s, flags or "")
        fontString:SetShadowOffset(1, -1)
        fontString:SetShadowColor(0, 0, 0, 0.7)
        if color and type(color) == "table" then
            fontString:SetTextColor(unpack(color))
        end
    elseif s == "HERO_SCORE" then
        fontString:SetFont(font, 24, flags or "OUTLINE")
        fontString:SetTextColor(unpack(color or T.textPrimary))
        fontString:SetShadowOffset(1, -1)
        fontString:SetShadowColor(0, 0, 0, 0.95)
    elseif s == "TITLE" then
        fontString:SetFont(font, 14, flags or "")
        fontString:SetShadowOffset(1, -1)
        fontString:SetShadowColor(0, 0, 0, 0.8)
        fontString:SetTextColor(unpack(color or T.textPrimary))
    elseif s == "LARGE" or s == "TITLE_LARGE" or s == "GAMEFONTHIGHLIGHTLARGE" or s == "GAMEFONTNORMALLARGE" then
        fontString:SetFont(font, 15, flags or "")
        fontString:SetShadowOffset(1, -1)
        fontString:SetShadowColor(0, 0, 0, 0.8)
        fontString:SetTextColor(unpack(color or T.textPrimary))
    elseif s == "CARD_TITLE" or s == "GAMEFONTHIGHLIGHTMEDIUM" or s == "GAMEFONTNORMALMEDIUM" then
        fontString:SetFont(font, 12, flags or "")
        fontString:SetShadowOffset(1, -1)
        fontString:SetShadowColor(0, 0, 0, 0.7)
        fontString:SetTextColor(unpack(color or T.textPrimary))
    elseif s == "SECTION" then
        fontString:SetFont(font, 11, flags or "")
        fontString:SetShadowOffset(1, -1)
        fontString:SetShadowColor(0, 0, 0, 0.6)
        fontString:SetTextColor(unpack(color or T.textMuted))
    elseif s == "BODY" or s == "GAMEFONTHIGHLIGHT" or s == "GAMEFONTNORMAL" or s == "GAMEFONTWHITE" then
        fontString:SetFont(font, 11, flags or "")
        fontString:SetShadowOffset(1, -1)
        fontString:SetShadowColor(0, 0, 0, 0.7)
        fontString:SetTextColor(unpack(color or (s == "GAMEFONTWHITE" and T.textHighlight) or T.textSecondary))
    elseif s == "VALUE" then
        fontString:SetFont(font, 12, flags or "")
        fontString:SetShadowOffset(1, -1)
        fontString:SetShadowColor(0, 0, 0, 0.7)
        fontString:SetTextColor(unpack(color or T.textPrimary))
    elseif s == "STAT_LABEL" then
        fontString:SetFont(font, 11, flags or "")
        fontString:SetShadowOffset(1, -1)
        fontString:SetShadowColor(0, 0, 0, 0.7)
        fontString:SetTextColor(unpack(color or T.textSecondary))
    elseif s == "MONO_NUM" then
        fontString:SetFont(font, 12, flags or "")
        fontString:SetShadowOffset(1, -1)
        fontString:SetShadowColor(0, 0, 0, 0.8)
        fontString:SetTextColor(unpack(color or T.textPrimary))
    elseif s == "SMALL" or s == "GAMEFONTHIGHLIGHTSMALL" or s == "GAMEFONTNORMALSMALL" or s == "GAMEFONTDISABLESMALL" then
        fontString:SetFont(font, 10, flags or "")
        fontString:SetShadowOffset(1, -1)
        fontString:SetShadowColor(0, 0, 0, 0.7)
        if s == "GAMEFONTDISABLESMALL" then
            fontString:SetTextColor(unpack(color or T.textMuted))
        else
            fontString:SetTextColor(unpack(color or T.textSecondary))
        end
    else
        fontString:SetFont(font, 11, flags or "")
        fontString:SetShadowOffset(1, -1)
        fontString:SetShadowColor(0, 0, 0, 0.7)
        if color and type(color) == "table" then
            fontString:SetTextColor(unpack(color))
        end
    end
end

-- ----------------------------------------------------------------------------
-- 5. MICRO-BORDER & SURFACE SYSTEM
-- ----------------------------------------------------------------------------
function GSI_UI:ApplyMicroBorder(frame, color, topSpecularColor)
    if self ~= GSI_UI then
        frame, color, topSpecularColor = self, frame, color
        self = GSI_UI
    end
    if not frame or type(frame) ~= "table" or not frame.CreateTexture then return end
    local onePx = math.max(1, math.floor(self:PP(1) + 0.5))
    local c = color or self.THEME.borderSubtle
    local topC = topSpecularColor or c

    if not frame.borders then
        frame.borders = {}
        for _, side in ipairs({ "TOP", "BOTTOM", "LEFT", "RIGHT" }) do
            local tex = frame:CreateTexture(nil, "BORDER", nil, 2)
            tex:SetColorTexture(1, 1, 1, 1)
            frame.borders[side] = tex
        end
    end

    local b = frame.borders
    b.TOP:ClearAllPoints()
    b.TOP:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    b.TOP:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
    b.TOP:SetHeight(onePx)
    b.TOP:SetVertexColor(unpack(topC))

    b.BOTTOM:ClearAllPoints()
    b.BOTTOM:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
    b.BOTTOM:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
    b.BOTTOM:SetHeight(onePx)
    b.BOTTOM:SetVertexColor(unpack(c))

    b.LEFT:ClearAllPoints()
    b.LEFT:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -onePx)
    b.LEFT:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, onePx)
    b.LEFT:SetWidth(onePx)
    b.LEFT:SetVertexColor(unpack(c))

    b.RIGHT:ClearAllPoints()
    b.RIGHT:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, -onePx)
    b.RIGHT:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, onePx)
    b.RIGHT:SetWidth(onePx)
    b.RIGHT:SetVertexColor(unpack(c))

    function frame:SetBorderColor(r, g, bCol, a, topR, topG, topB, topA)
        b.BOTTOM:SetVertexColor(r, g, bCol, a or 1.0)
        b.LEFT:SetVertexColor(r, g, bCol, a or 1.0)
        b.RIGHT:SetVertexColor(r, g, bCol, a or 1.0)
        b.TOP:SetVertexColor(topR or r, topG or g, topB or bCol, topA or a or 1.0)
    end

    function frame:SetBackdropBorderColor(r, g, bCol, a)
        if self.SetBorderColor then
            self:SetBorderColor(r, g, bCol, a)
        end
    end
end

-- Basis-Flächen (MainFrame, Header, Sidebar, Cards)
function GSI_UI:SkinFrame(frame, style, hasSpecularTop)
    if self ~= GSI_UI then
        frame, style, hasSpecularTop = self, frame, style
        self = GSI_UI
    end
    if not frame or type(frame) ~= "table" or not frame.CreateTexture then return end
    local T = self.THEME
    local col = T.bgCanvas
    local isTopSpecular = hasSpecularTop

    if style == "header" then
        col = T.bgHeader
    elseif style == "sidebar" then
        col = T.bgSidebar
    elseif style == "card" or style == "row" then
        return self:SkinCard(frame, true)
    elseif style == "well" or style == "input" then
        col = T.bgInput
    elseif style == "dialog" then
        col = T.bgCanvas
        isTopSpecular = true
    elseif type(style) == "table" then
        col = style
    end

    if not frame.bg then
        frame.bg = frame:CreateTexture(nil, "BACKGROUND", nil, 0)
        frame.bg:SetAllPoints()
        frame.bg:SetColorTexture(1, 1, 1, 1)
    end
    frame.bg:SetVertexColor(unpack(col))

    function frame:SetBackdropColor(r, g, bCol, a)
        if self.bg then
            self.bg:SetVertexColor(r, g, bCol, a or 1.0)
        end
    end

    self:ApplyMicroBorder(
        frame,
        T.borderSubtle,
        isTopSpecular and T.borderSpecular or T.borderSubtle
    )
    return frame
end

-- Luxus-Card (Gradient-Fläche + Specular Top Light + Interaktiver Hover-Glow)
function GSI_UI:SkinCard(frame, isInteractive)
    if self ~= GSI_UI then
        frame, isInteractive = self, frame
        self = GSI_UI
    end
    if not frame or type(frame) ~= "table" or not frame.CreateTexture then return end
    local T = self.THEME

    if not frame.bg then
        frame.bg = frame:CreateTexture(nil, "BACKGROUND", nil, 1)
        frame.bg:SetAllPoints()
        frame.bg:SetColorTexture(1, 1, 1, 1)
    end

    function frame:SetBackdropColor(r, g, bCol, a)
        if self.bg then
            self.bg:SetVertexColor(r, g, bCol, a or 1.0)
        end
    end

    local function SetNormalState()
        GSI_UI:SetGradient(
            frame.bg, "VERTICAL",
            T.bgCardBottom[1], T.bgCardBottom[2], T.bgCardBottom[3], T.bgCardBottom[4],
            T.bgCardTop[1], T.bgCardTop[2], T.bgCardTop[3], T.bgCardTop[4]
        )
        if frame.SetBorderColor then
            frame:SetBorderColor(
                T.borderSubtle[1], T.borderSubtle[2], T.borderSubtle[3], T.borderSubtle[4],
                T.borderSpecular[1], T.borderSpecular[2], T.borderSpecular[3], T.borderSpecular[4]
            )
        end
    end

    self:ApplyMicroBorder(frame, T.borderSubtle, T.borderSpecular)
    SetNormalState()

    if isInteractive then
        frame:EnableMouse(true)
        frame:HookScript("OnEnter", function(selfFrame)
            GSI_UI:SetGradient(
                selfFrame.bg, "VERTICAL",
                T.bgCardHoverBot[1], T.bgCardHoverBot[2], T.bgCardHoverBot[3], T.bgCardHoverBot[4],
                T.bgCardHoverTop[1], T.bgCardHoverTop[2], T.bgCardHoverTop[3], T.bgCardHoverTop[4]
            )
            if selfFrame.SetBorderColor then
                selfFrame:SetBorderColor(
                    T.borderHover[1], T.borderHover[2], T.borderHover[3], T.borderHover[4],
                    T.accent[1], T.accent[2], T.accent[3], 0.65
                )
            end
        end)
        frame:HookScript("OnLeave", function()
            SetNormalState()
        end)
    end

    return frame
end

-- ----------------------------------------------------------------------------
-- 6. MODERNE BUTTON-FACTORY (Primary Class-Accent, Secondary Obsidian, Red Danger)
-- ----------------------------------------------------------------------------
function GSI_UI:SkinButton(btn, isRedOrLabel, isPrimaryOrVariant)
    if self ~= GSI_UI then
        btn, isRedOrLabel, isPrimaryOrVariant = self, btn, isRedOrLabel
        self = GSI_UI
    end
    if not btn or type(btn) ~= "table" or not btn.CreateTexture then return end
    local T = self.THEME

    local isRed = false
    local isPrimary = false
    local label = nil

    if type(isRedOrLabel) == "string" then
        label = isRedOrLabel
    elseif type(isRedOrLabel) == "boolean" then
        isRed = isRedOrLabel
    end

    if isPrimaryOrVariant == true or isPrimaryOrVariant == "PRIMARY" then
        isPrimary = true
    elseif isPrimaryOrVariant == "DANGER" or isPrimaryOrVariant == "RED" then
        isRed = true
    end

    local existingText = (btn.GetText and btn:GetText()) or nil

    if btn.Left then btn.Left:Hide() end
    if btn.Middle then btn.Middle:Hide() end
    if btn.Right then btn.Right:Hide() end
    if btn.SetNormalTexture then btn:SetNormalTexture("") end
    if btn.SetHighlightTexture then btn:SetHighlightTexture("") end
    if btn.SetPushedTexture then btn:SetPushedTexture("") end

    if not btn.bg then
        btn.bg = btn:CreateTexture(nil, "BACKGROUND", nil, 1)
        btn.bg:SetAllPoints()
        btn.bg:SetColorTexture(1, 1, 1, 1)
    end

    function btn:SetBackdropColor(r, g, bCol, a)
        if self.bg then
            self.bg:SetVertexColor(r, g, bCol, a or 1.0)
        end
    end

    self:ApplyMicroBorder(btn, T.borderSubtle, T.borderSpecular)

    if btn.EnableMouse then
        btn:EnableMouse(true)
    end
    if btn.RegisterForClicks then
        btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    end

    if btn.SetNormalFontObject then btn:SetNormalFontObject(GSI_FontHighlight) end
    if btn.SetHighlightFontObject then btn:SetHighlightFontObject(GSI_FontHighlight) end
    if btn.SetDisabledFontObject then btn:SetDisabledFontObject(GSI_FontDisabled) end

    local fontPath = self:GetFontPath()
    local function ApplyButtonFont(fStr)
        if fStr and fStr.SetFont then
            fStr:SetFont(fontPath, 11, "")
            fStr:SetShadowOffset(1, -1)
            fStr:SetShadowColor(0, 0, 0, 0.7)
            if fStr.SetWordWrap then fStr:SetWordWrap(false) end
        end
    end

    local finalLabel = label or existingText
    if finalLabel and finalLabel ~= "" then
        btn:SetText("")
        btn:SetText(finalLabel)
    end

    ApplyButtonFont(btn.GetFontString and btn:GetFontString())

    if btn.SetText and not btn._gsiFontHooked then
        local rawSetText = btn.SetText
        btn.SetText = function(sBtn, txt)
            rawSetText(sBtn, txt)
            ApplyButtonFont(sBtn:GetFontString())
        end
        btn._gsiFontHooked = true
    end

    local function ApplyVisual(state)
        if btn.IsEnabled and not btn:IsEnabled() then
            btn.bg:SetVertexColor(0.04, 0.04, 0.05, 0.7)
            if btn.SetBorderColor then btn:SetBorderColor(0.1, 0.1, 0.12, 0.5) end
            local fStr = btn.GetFontString and btn:GetFontString()
            if fStr then fStr:SetTextColor(0.35, 0.35, 0.40) end
            return
        end

        local fStr = btn.GetFontString and btn:GetFontString()
        if isRed then
            if state == "HOVER" then
                btn.bg:SetVertexColor(0.20, 0.08, 0.08, 1.0)
                if btn.SetBorderColor then btn:SetBorderColor(T.danger[1], T.danger[2], T.danger[3], 0.8) end
                if fStr then fStr:SetTextColor(1, 0.5, 0.5) end
            elseif state == "PUSHED" then
                btn.bg:SetVertexColor(0.10, 0.04, 0.04, 1.0)
            else
                btn.bg:SetVertexColor(0.12, 0.06, 0.06, 0.95)
                if btn.SetBorderColor then btn:SetBorderColor(T.danger[1]*0.6, T.danger[2]*0.6, T.danger[3]*0.6, 0.5) end
                if fStr then fStr:SetTextColor(0.9, 0.45, 0.45) end
            end
        elseif isPrimary then
            if state == "HOVER" then
                GSI_UI:SetGradient(btn.bg, "VERTICAL", T.accent[1]*0.8, T.accent[2]*0.8, T.accent[3]*0.8, 1, T.accentBright[1], T.accentBright[2], T.accentBright[3], 1)
                if btn.SetBorderColor then btn:SetBorderColor(T.accentBright[1], T.accentBright[2], T.accentBright[3], 0.9, 1, 1, 1, 0.45) end
                if fStr then fStr:SetTextColor(1, 1, 1) end
            elseif state == "PUSHED" then
                btn.bg:SetVertexColor(T.accent[1]*0.6, T.accent[2]*0.6, T.accent[3]*0.6, 1)
            else
                GSI_UI:SetGradient(btn.bg, "VERTICAL", T.accent[1]*0.6, T.accent[2]*0.6, T.accent[3]*0.6, 1, T.accent[1], T.accent[2], T.accent[3], 1)
                if btn.SetBorderColor then btn:SetBorderColor(T.accent[1], T.accent[2], T.accent[3], 0.6, 1, 1, 1, 0.3) end
                if fStr then fStr:SetTextColor(1, 1, 1) end
            end
        else
            if state == "HOVER" then
                btn.bg:SetVertexColor(unpack(T.bgCardHoverTop))
                if btn.SetBorderColor then btn:SetBorderColor(T.accent[1], T.accent[2], T.accent[3], 0.5, T.accentBright[1], T.accentBright[2], T.accentBright[3], 0.7) end
                if fStr then fStr:SetTextColor(unpack(T.textPrimary)) end
            elseif state == "PUSHED" then
                btn.bg:SetVertexColor(unpack(T.bgInput))
            else
                btn.bg:SetVertexColor(unpack(T.bgCardTop))
                if btn.SetBorderColor then
                    btn:SetBorderColor(T.borderSubtle[1], T.borderSubtle[2], T.borderSubtle[3], T.borderSubtle[4], T.borderSpecular[1], T.borderSpecular[2], T.borderSpecular[3], T.borderSpecular[4])
                end
                if fStr then fStr:SetTextColor(unpack(T.textSecondary)) end
            end
        end
    end

    ApplyVisual("NORMAL")
    btn:HookScript("OnEnter", function() ApplyVisual("HOVER") end)
    btn:HookScript("OnLeave", function() ApplyVisual("NORMAL") end)
    btn:HookScript("OnMouseDown", function() ApplyVisual("PUSHED") end)
    btn:HookScript("OnMouseUp", function() ApplyVisual("HOVER") end)
    if btn.HookScript then
        pcall(function()
            btn:HookScript("OnEnable", function() ApplyVisual("NORMAL") end)
            btn:HookScript("OnDisable", function() ApplyVisual("NORMAL") end)
        end)
    end

    return btn
end

-- ----------------------------------------------------------------------------
-- 7. PILLS & BADGES (Score-Pills, Mode-Badges, Delta-Indicators)
-- ----------------------------------------------------------------------------
function GSI_UI:CreatePill(parent, text, variant)
    if self ~= GSI_UI then
        parent, text, variant = self, parent, text
        self = GSI_UI
    end
    local T = self.THEME
    local pill = CreateFrame("Frame", nil, parent)
    pill:SetHeight(18)

    pill.bg = pill:CreateTexture(nil, "BACKGROUND")
    pill.bg:SetAllPoints()
    pill.bg:SetColorTexture(1, 1, 1, 1)

    pill.label = self:CreateText(pill, "SMALL", text, "CENTER")
    pill.label:SetPoint("CENTER", 0, 0)
    if pill.label.SetWordWrap then pill.label:SetWordWrap(false) end

    function pill:SetPillStyle(newText, newVariant)
        local v = newVariant or variant or "NEUTRAL"
        if newText then self.label:SetText(newText) end

        local bgCol, textCol
        if v == "ACCENT" then
            bgCol, textCol = T.accentSurface, T.accentBright
        elseif v == "SUCCESS" then
            bgCol, textCol = T.successSurface, T.success
        elseif v == "WARNING" then
            bgCol, textCol = T.warningSurface, T.warning
        elseif v == "DANGER" then
            bgCol, textCol = T.dangerSurface, T.danger
        else
            bgCol, textCol = { 1, 1, 1, 0.06 }, T.textSecondary
        end

        self.bg:SetVertexColor(unpack(bgCol))
        self.label:SetTextColor(unpack(textCol))

        local textWidth = math.ceil(self.label:GetStringWidth() or 30)
        self:SetWidth(math.max(34, textWidth + 14))
    end

    pill:SetPillStyle(text, variant)
    return pill
end

function GSI_UI:CreateBadge(parent, text, dotColor)
    if self ~= GSI_UI then
        parent, text, dotColor = self, parent, text
        self = GSI_UI
    end
    local T = self.THEME
    local badge = CreateFrame("Frame", nil, parent)
    badge:SetHeight(22)
    self:SkinFrame(badge, T.bgCardBottom, true)

    badge.dot = badge:CreateTexture(nil, "OVERLAY")
    badge.dot:SetSize(6, 6)
    badge.dot:SetPoint("LEFT", 8, 0)
    badge.dot:SetColorTexture(1, 1, 1, 1)
    badge.dot:SetVertexColor(unpack(dotColor or T.accent))

    badge.label = self:CreateText(badge, "SMALL", text, "LEFT")
    badge.label:SetPoint("LEFT", badge.dot, "RIGHT", 6, 0)
    badge.label:SetTextColor(unpack(T.textPrimary))
    if badge.label.SetWordWrap then badge.label:SetWordWrap(false) end

    function badge:UpdateText(newText)
        self.label:SetText(newText)
        local textWidth = math.ceil(self.label:GetStringWidth() or 20)
        self:SetWidth(math.max(36, textWidth + 26))
    end

    badge:UpdateText(text)
    return badge
end

-- ----------------------------------------------------------------------------
-- 8. SLIDERS (Modern Recessed Track, Dynamic Fill & Micro Thumb)
-- ----------------------------------------------------------------------------
function GSI_UI:SkinSlider(slider, sliderBg, width, height)
    if self ~= GSI_UI then
        slider, sliderBg, width, height = self, slider, sliderBg, width
        self = GSI_UI
    end
    if not slider then return end
    width = width or 380
    height = height or 6
    local T = self.THEME

    if sliderBg then
        sliderBg:SetSize(width, height)
        self:SkinFrame(sliderBg, T.bgInput, false)
    end

    slider:SetSize(width, 18)
    slider:SetOrientation("HORIZONTAL")
    slider:SetThumbTexture("Interface\\Buttons\\WHITE8x8")

    local thumb = slider:GetThumbTexture()
    if thumb and type(thumb) == "table" then
        thumb:SetSize(10, 16)
        thumb:SetVertexColor(unpack(T.accent))

        slider:HookScript("OnEnter", function(selfSlider)
            if selfSlider:IsEnabled() then
                thumb:SetVertexColor(unpack(T.accentBright))
                if sliderBg and sliderBg.SetBorderColor then
                    sliderBg:SetBorderColor(T.accent[1], T.accent[2], T.accent[3], 0.7)
                end
            end
        end)
        slider:HookScript("OnLeave", function(selfSlider)
            if selfSlider:IsEnabled() then
                thumb:SetVertexColor(unpack(T.accent))
                if sliderBg and sliderBg.SetBorderColor then
                    sliderBg:SetBorderColor(T.borderSubtle[1], T.borderSubtle[2], T.borderSubtle[3], T.borderSubtle[4])
                end
            else
                thumb:SetVertexColor(0.35, 0.35, 0.35, 0.5)
            end
        end)
    end
end

-- ----------------------------------------------------------------------------
-- 9. SCROLLBAR & ICON FRAME & EDITBOX SKINNING
-- ----------------------------------------------------------------------------
function GSI_UI:SkinScrollBar(scrollFrame)
    if self ~= GSI_UI then
        scrollFrame = self
        self = GSI_UI
    end
    if not scrollFrame then return end
    local name = scrollFrame:GetName()
    local scrollBar = (name and _G[name .. "ScrollBar"]) or scrollFrame.ScrollBar or (scrollFrame.GetScrollBar and scrollFrame:GetScrollBar())
    if not scrollBar then return end
    local T = self.THEME

    local upBtn = (name and _G[name .. "ScrollBarScrollUpButton"]) or scrollBar.ScrollUpButton or scrollBar.UpButton
    local downBtn = (name and _G[name .. "ScrollBarScrollDownButton"]) or scrollBar.ScrollDownButton or scrollBar.DownButton
    if upBtn then upBtn:SetAlpha(0); upBtn:EnableMouse(false); upBtn:SetSize(0.1, 0.1) end
    if downBtn then downBtn:SetAlpha(0); downBtn:EnableMouse(false); downBtn:SetSize(0.1, 0.1) end

    scrollBar:SetWidth(5)

    if not scrollBar._bg then
        local bg = scrollBar:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints(scrollBar)
        bg:SetColorTexture(unpack(T.bgInput))
        scrollBar._bg = bg
    end

    local thumb = scrollBar:GetThumbTexture()
    if thumb then
        thumb:SetTexture("Interface\\Buttons\\WHITE8x8")
        thumb:SetSize(5, 24)
        thumb:SetVertexColor(0.24, 0.24, 0.30, 1.0)

        scrollBar:HookScript("OnEnter", function()
            thumb:SetVertexColor(unpack(T.accent))
        end)
        scrollBar:HookScript("OnLeave", function()
            thumb:SetVertexColor(0.24, 0.24, 0.30, 1.0)
        end)
    end
end

function GSI_UI:SkinItemIcon(iconTexture, parentFrame, quality)
    if self ~= GSI_UI then
        iconTexture, parentFrame, quality = self, iconTexture, parentFrame
        self = GSI_UI
    end
    if not iconTexture then return end
    iconTexture:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    if not parentFrame then return end
    if not parentFrame._iconBorder then
        local b = CreateFrame("Frame", nil, parentFrame)
        b:SetPoint("TOPLEFT", iconTexture, "TOPLEFT", -1, 1)
        b:SetPoint("BOTTOMRIGHT", iconTexture, "BOTTOMRIGHT", 1, -1)
        b:SetFrameLevel(parentFrame:GetFrameLevel() + 2)
        GSI_UI:ApplyMicroBorder(b)
        parentFrame._iconBorder = b
    end

    local border = parentFrame._iconBorder
    if border and border.SetBorderColor then
        local qualColor = quality and ((ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[quality])
                       or (C_Item and C_Item.GetItemQualityColor and C_Item.GetItemQualityColor(quality)))
        if qualColor then
            border:SetBorderColor(qualColor.r, qualColor.g, qualColor.b, 1.0)
        else
            border:SetBorderColor(0.18, 0.18, 0.22, 1.0)
        end
        border:Show()
    end
end

function GSI_UI:SkinEditBox(eb)
    if self ~= GSI_UI then
        eb = self
        self = GSI_UI
    end
    if not eb then return end
    local T = self.THEME
    self:SkinFrame(eb, T.bgInput, false)
    if eb.SetFont then
        eb:SetFont(self:GetFontPath(), 11, "")
    end
    if eb.SetShadowOffset then
        eb:SetShadowOffset(1, -1)
        eb:SetShadowColor(0, 0, 0, 0.7)
    end
    if eb.SetTextColor then
        eb:SetTextColor(unpack(T.textPrimary))
    end
    eb:HookScript("OnEditFocusGained", function(selfEb)
        if selfEb.SetBorderColor then
            selfEb:SetBorderColor(T.accent[1], T.accent[2], T.accent[3], 0.9)
        end
    end)
    eb:HookScript("OnEditFocusLost", function(selfEb)
        if selfEb.SetBorderColor then
            selfEb:SetBorderColor(T.borderSubtle[1], T.borderSubtle[2], T.borderSubtle[3], T.borderSubtle[4])
        end
    end)
end

-- ----------------------------------------------------------------------------
-- 10. FORMATIERUNG & UTILITIES
-- ----------------------------------------------------------------------------
function GSI_UI:GetItemKey(link)
    if self ~= GSI_UI then link = self; self = GSI_UI end
    if not link then return nil end
    local s = link:match("item:([^|h]+)")
    if not s then return link end
    local parts = { strsplit(":", s) }
    if parts[9] then parts[9] = "0" end
    return table.concat(parts, ":")
end

function GSI_UI:IsSameItemLink(link1, link2)
    if self ~= GSI_UI then link1, link2 = self, link1; self = GSI_UI end
    if link1 == link2 then return true end
    if not link1 or not link2 then return false end
    return self:GetItemKey(link1) == self:GetItemKey(link2)
end

local STAT_DISPLAY_NAMES = {
    Strength           = "Strength",
    Agility            = "Agility",
    Stamina            = "Stamina",
    Intellect          = "Intellect",
    Spirit             = "Spirit",
    Armor              = "Armor",
    Defense            = "Defense",
    Dodge              = "Dodge",
    Parry              = "Parry",
    Block              = "Block Chance",
    BlockValue         = "Block Value",
    AttackPower        = "Attack Power (AP)",
    FeralAttackPower   = "Feral Attack Power (FAP)",
    RangedAttackPower  = "Ranged AP (RAP)",
    SpellPower         = "Spell Power (SP)",
    HealingPower       = "Healing Power",
    ArcaneSpellPower   = "Arcane Spell Power",
    FireSpellPower     = "Fire Spell Power",
    FrostSpellPower    = "Frost Spell Power",
    ShadowSpellPower   = "Shadow Spell Power",
    NatureSpellPower   = "Nature Spell Power",
    HolySpellPower     = "Holy Spell Power",
    Hit                = "Hit Chance (% Hit)",
    Crit               = "Critical Strike (% Crit)",
    Haste              = "Haste",
    WeaponDamage       = "Weapon Damage (DPS)",
    WeaponDamageOH     = "Off-Hand DPS (OH)",
    FlatWeaponDamage   = "Weapon Damage (Flat)",
    RangedDPS          = "Ranged Weapon DPS",
    WeaponSpeed        = "Weapon Speed",
    WeaponSkill        = "Weapon Skill",
    AvoidanceReduction = "Avoidance Reduction",
    ArmorPenetration   = "Armor Penetration",
    SpellPenetration   = "Spell Penetration",
    MP5                = "Mana per 5 sec (MP5)",
    HP5                = "Health per 5 sec (HP5)",
    Mana               = "Max Mana",
    Speed              = "Movement Speed",
    FireResist         = "Fire Resistance",
    NatureResist       = "Nature Resistance",
    FrostResist        = "Frost Resistance",
    ShadowResist       = "Shadow Resistance",
    ArcaneResist       = "Arcane Resistance",
}
GSI_UI.STAT_DISPLAY_NAMES = STAT_DISPLAY_NAMES

local function FormatWeight(val)
    if not val or val == 0 then return "0" end
    local s = string.format("%.3f", val)
    s = s:gsub("(%..-)0+$", "%1"):gsub("%.$", "")
    return s
end

local function FormatStatValue(statKey, val)
    if not val or val == 0 then return "0" end
    if statKey == "Dodge" or statKey == "Parry" or statKey == "Block" or statKey == "Hit" or statKey == "Crit" or statKey == "Haste" or statKey == "AvoidanceReduction" or statKey == "Speed" then
        return string.format("%.1f%%", val)
    elseif statKey == "WeaponSpeed" then
        return string.format("%.2fs", val)
    else
        return tostring(math.floor(val + 0.5))
    end
end

function GSI_UI:FormatWeight(v)
    if self ~= GSI_UI then v = self; self = GSI_UI end
    return FormatWeight(v)
end
function GSI_UI:FormatStatValue(k, v)
    if self ~= GSI_UI then k, v = self, k; self = GSI_UI end
    return FormatStatValue(k, v)
end


-- ----------------------------------------------------------------------------
-- 8. FLAT MATERIAL-DESIGN CHEVRON (UP / DOWN)
-- ----------------------------------------------------------------------------
function GSI_UI:CreateChevron(parentBtn, size)
    if self ~= GSI_UI then
        size = parentBtn
        parentBtn = self
        self = GSI_UI
    end
    size = size or 14
    local T = self.THEME
    local holder = CreateFrame("Frame", nil, parentBtn)
    holder:SetSize(size, size)
    holder:EnableMouse(false)
    holder._dir = -1 -- -1 = down (closed), +1 = up (expanded)
    holder._targetDir = -1
    holder._expanded = false
    holder._hovered = false

    local hasLine = type(holder.CreateLine) == "function"
    local leftLine, rightLine, fallbackText

    if hasLine then
        local okL, l1 = pcall(holder.CreateLine, holder, nil, "OVERLAY", nil, 2)
        local okR, l2 = pcall(holder.CreateLine, holder, nil, "OVERLAY", nil, 2)
        if okL and okR and l1 and l2 then
            leftLine, rightLine = l1, l2
            leftLine:SetThickness(1.75)
            rightLine:SetThickness(1.75)
        end
    end

    if not leftLine or not rightLine then
        fallbackText = self:CreateText(holder, "SMALL", "v", "CENTER")
        fallbackText:SetAllPoints()
    end

    local function UpdateColor()
        local r, g, b = T.textSecondary[1], T.textSecondary[2], T.textSecondary[3]
        if holder._expanded then
            local cr, cg, cb = self:GetClassColor()
            r = math.min(1, cr + 0.18)
            g = math.min(1, cg + 0.18)
            b = math.min(1, cb + 0.18)
        elseif holder._hovered then
            r, g, b = T.textPrimary[1], T.textPrimary[2], T.textPrimary[3]
        end
        if leftLine and rightLine then
            leftLine:SetColorTexture(r, g, b, 1.0)
            rightLine:SetColorTexture(r, g, b, 1.0)
        elseif fallbackText then
            fallbackText:SetTextColor(r, g, b, 1.0)
        end
    end

    local function ApplyGeometry(dir)
        if leftLine and rightLine then
            leftLine:SetStartPoint("CENTER", holder, -4.0, -2.1 * dir)
            leftLine:SetEndPoint("CENTER", holder, 0.58, 2.48 * dir)
            rightLine:SetStartPoint("CENTER", holder, 4.0, -2.1 * dir)
            rightLine:SetEndPoint("CENTER", holder, -0.58, 2.48 * dir)
        elseif fallbackText then
            fallbackText:SetText(dir >= 0 and "^" or "v")
        end
    end

    ApplyGeometry(-1)
    UpdateColor()

    if parentBtn and parentBtn.HookScript then
        parentBtn:HookScript("OnEnter", function()
            holder._hovered = true
            UpdateColor()
        end)
        parentBtn:HookScript("OnLeave", function()
            holder._hovered = false
            UpdateColor()
        end)
    end

    function holder:SetExpanded(expanded, instant)
        self._expanded = (expanded == true)
        self._targetDir = self._expanded and 1 or -1
        UpdateColor()
        if instant then
            self._dir = self._targetDir
            ApplyGeometry(self._dir)
            self:SetScript("OnUpdate", nil)
            return
        end
        self:SetScript("OnUpdate", function(f, elapsed)
            local step = ((elapsed or 0.016) / 0.11) * 2.0
            if f._dir < f._targetDir then
                f._dir = math.min(f._targetDir, f._dir + step)
            elseif f._dir > f._targetDir then
                f._dir = math.max(f._targetDir, f._dir - step)
            end
            ApplyGeometry(f._dir)
            if math.abs(f._dir - f._targetDir) < 0.001 then
                f._dir = f._targetDir
                ApplyGeometry(f._dir)
                f:SetScript("OnUpdate", nil)
            end
        end)
    end

    return holder
end


-- ----------------------------------------------------------------------------
-- 9. FLAT MATERIAL-DESIGN CHECKBOX (Vector Checkmark)
-- ----------------------------------------------------------------------------
function GSI_UI:SkinCheckbox(cb)
    if self ~= GSI_UI then
        cb = self
        self = GSI_UI
    end
    if not cb or cb._gsiSkinned then return cb end
    cb._gsiSkinned = true

    local T = self.THEME

    local function StripBlizzTex(tex)
        if not tex then return end
        if tex.SetTexture then pcall(tex.SetTexture, tex, nil) end
        if tex.SetAtlas then pcall(tex.SetAtlas, tex, nil) end
        if tex.SetAlpha then tex:SetAlpha(0) end
        if tex.Hide then tex:Hide() end
        if hooksecurefunc and tex.Show and not tex._gsiHiddenHook then
            tex._gsiHiddenHook = true
            hooksecurefunc(tex, "Show", function(t)
                t:SetAlpha(0)
                t:Hide()
            end)
        end
    end

    if cb.SetNormalTexture then pcall(cb.SetNormalTexture, cb, "") end
    if cb.SetPushedTexture then pcall(cb.SetPushedTexture, cb, "") end
    if cb.SetHighlightTexture then pcall(cb.SetHighlightTexture, cb, "") end
    if cb.SetCheckedTexture then pcall(cb.SetCheckedTexture, cb, "") end
    if cb.SetDisabledCheckedTexture then pcall(cb.SetDisabledCheckedTexture, cb, "") end

    StripBlizzTex(cb.GetNormalTexture and cb:GetNormalTexture())
    StripBlizzTex(cb.GetPushedTexture and cb:GetPushedTexture())
    StripBlizzTex(cb.GetHighlightTexture and cb:GetHighlightTexture())
    StripBlizzTex(cb.GetCheckedTexture and cb:GetCheckedTexture())
    StripBlizzTex(cb.GetDisabledCheckedTexture and cb:GetDisabledCheckedTexture())

    local numRegions = cb.GetNumRegions and cb:GetNumRegions() or 0
    for i = 1, numRegions do
        local reg = select(i, cb:GetRegions())
        if reg and reg.GetObjectType and reg:GetObjectType() == "Texture" then
            StripBlizzTex(reg)
        end
    end
    if cb.Left then StripBlizzTex(cb.Left) end
    if cb.Right then StripBlizzTex(cb.Right) end
    if cb.Middle then StripBlizzTex(cb.Middle) end
    if cb.bg then StripBlizzTex(cb.bg) end

    local w = cb.GetWidth and cb:GetWidth() or 32
    if w > 24 then
        cb:SetSize(22, 22)
    end

    local box = CreateFrame("Frame", nil, cb)
    box:SetSize(16, 16)
    box:SetPoint("CENTER", cb, "CENTER", 0, 0)
    box:EnableMouse(false)
    self:SkinFrame(box, T.bgInput, false)
    cb._gsiBox = box

    local fill = box:CreateTexture(nil, "ARTWORK", nil, 0)
    fill:SetPoint("TOPLEFT", box, "TOPLEFT", 1, -1)
    fill:SetPoint("BOTTOMRIGHT", box, "BOTTOMRIGHT", -1, 1)
    fill:SetTexture("Interface\\Buttons\\WHITE8x8")
    fill:Hide()
    box.fill = fill

    local l1, l2, fallbackMark
    if type(box.CreateLine) == "function" then
        local ok1, a = pcall(box.CreateLine, box, nil, "OVERLAY", nil, 2)
        local ok2, b = pcall(box.CreateLine, box, nil, "OVERLAY", nil, 2)
        if ok1 and ok2 and a and b then
            l1, l2 = a, b
            l1:SetThickness(1.8)
            l2:SetThickness(1.8)
            l1:SetStartPoint("CENTER", box, -3.6, -0.2)
            l1:SetEndPoint("CENTER", box, -0.8, -3.0)
            l2:SetStartPoint("CENTER", box, -1.1, -3.0)
            l2:SetEndPoint("CENTER", box, 3.8, 2.6)
            l1:SetColorTexture(1, 1, 1, 1)
            l2:SetColorTexture(1, 1, 1, 1)
            l1:Hide()
            l2:Hide()
        end
    end
    if not l1 or not l2 then
        fallbackMark = self:CreateText(box, "SMALL", "x", "CENTER")
        fallbackMark:SetAllPoints()
        fallbackMark:SetTextColor(1, 1, 1, 1)
        fallbackMark:Hide()
    end

    local function SyncVisual()
        local checked = cb.GetChecked and cb:GetChecked() and true or false
        local cr, cg, cbCol = GSI_UI:GetClassColor()
        if checked then
            fill:SetVertexColor(cr, cg, cbCol, 1.0)
            fill:Show()
            if l1 and l2 then l1:Show(); l2:Show() end
            if fallbackMark then fallbackMark:Show() end
            if box.SetBorderColor then
                box:SetBorderColor(cr, cg, cbCol, 1.0)
            end
        else
            fill:Hide()
            if l1 and l2 then l1:Hide(); l2:Hide() end
            if fallbackMark then fallbackMark:Hide() end
            if box.SetBorderColor then
                if cb._gsiHovered then
                    box:SetBorderColor(T.borderHover[1], T.borderHover[2], T.borderHover[3], 0.8)
                else
                    box:SetBorderColor(T.borderSubtle[1], T.borderSubtle[2], T.borderSubtle[3], 0.6)
                end
            end
        end
    end

    if hooksecurefunc and cb.SetChecked then
        hooksecurefunc(cb, "SetChecked", SyncVisual)
    end
    if cb.HookScript then
        cb:HookScript("PostClick", SyncVisual)
        cb:HookScript("OnEnter", function() cb._gsiHovered = true; SyncVisual() end)
        cb:HookScript("OnLeave", function() cb._gsiHovered = false; SyncVisual() end)
    end
    SyncVisual()
    return cb
end

-- ----------------------------------------------------------------------------
-- 10. ITEM NAME RESOLUTION & ASYNC CACHE REFRESH
-- ----------------------------------------------------------------------------
local _uiNameScanTip = nil
local function GetUINameScanTooltip()
    if not _uiNameScanTip then
        _uiNameScanTip = CreateFrame("GameTooltip", "GSI_UINameScanTooltip", nil, "GameTooltipTemplate")
        _uiNameScanTip:SetOwner(WorldFrame or UIParent, "ANCHOR_NONE")
    end
    return _uiNameScanTip
end

local _itemInfoRefreshPending = false
local function EnsureItemInfoListener()
    if GSI_UI._itemInfoListener then return end
    local f = CreateFrame("Frame")
    pcall(f.RegisterEvent, f, "GET_ITEM_INFO_RECEIVED")
    f:SetScript("OnEvent", function()
        if _itemInfoRefreshPending then return end
        _itemInfoRefreshPending = true
        local function DoRefresh()
            _itemInfoRefreshPending = false
            if GSI_ItemScore and GSI_ItemScore.ResetCache then
                GSI_ItemScore:ResetCache()
            end
            if GSI_OptimizationEngine and GSI_OptimizationEngine.ResetCache then
                GSI_OptimizationEngine:ResetCache()
            end
            if GSI_UI.mainFrame and GSI_UI.mainFrame:IsShown() and GSI_UI.RefreshPanel then
                pcall(GSI_UI.RefreshPanel, GSI_UI)
            end
            if GSI_UI.merchantOverlay and GSI_UI.merchantOverlay:IsShown() and GSI_UI.UpdateMerchantPanel then
                pcall(GSI_UI.UpdateMerchantPanel, GSI_UI)
            end
        end
        if C_Timer and C_Timer.After then
            C_Timer.After(0.08, DoRefresh)
        else
            DoRefresh()
        end
    end)
    GSI_UI._itemInfoListener = f
end

function GSI_UI:ResolveItemDisplayText(link, invSlotID, bagID, bagSlot)
    if self ~= GSI_UI then
        link, invSlotID, bagID, bagSlot = self, link, invSlotID, bagID
        self = GSI_UI
    end
    if not link or link == "" then return "" end

    local existing = link:match("|h%[([^%]]+)%]|h")
    if existing and existing ~= "" then
        return link
    end

    EnsureItemInfoListener()

    local itemName, fullLink = GetItemInfo(link)
    if fullLink then
        local fullExisting = fullLink:match("|h%[([^%]]+)%]|h")
        if fullExisting and fullExisting ~= "" then
            return fullLink
        end
    end
    if itemName and itemName ~= "" then
        return (link:gsub("|h%[%]|h", "|h[" .. itemName .. "]|h"))
    end

    -- Fallback: query hidden GameTooltip for equipped/bag/hyperlink item name
    local tip = GetUINameScanTooltip()
    tip:ClearLines()
    local ok = false
    if invSlotID then
        ok = pcall(tip.SetInventoryItem, tip, "player", invSlotID)
    elseif bagID and bagSlot then
        ok = pcall(tip.SetBagItem, tip, bagID, bagSlot)
    else
        ok = pcall(tip.SetHyperlink, tip, link)
    end
    if ok and (tip:NumLines() or 0) > 0 then
        local fs = _G["GSI_UINameScanTooltipTextLeft1"]
        local rawName = fs and fs:GetText()
        if rawName and rawName ~= "" then
            local clean = rawName:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
            local lower = clean:lower()
            if clean ~= "" and not lower:find("retrieving item") and not lower:find("gegenstandsinformationen") then
                return (link:gsub("|h%[%]|h", "|h[" .. clean .. "]|h"))
            end
        end
    end

    local itemID = tonumber(link:match("item:(%d+)")) or select(1, GetItemInfoInstant(link))
    if itemID and C_Item and C_Item.RequestLoadItemDataByID then
        pcall(C_Item.RequestLoadItemDataByID, itemID)
    end

    return "|cff888894Loading...|r"
end
