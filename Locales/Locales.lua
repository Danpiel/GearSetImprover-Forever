-- ============================================================
-- GearSetImprover - Locales.lua (WoW Forever)
-- Translations for any client language.
--
-- L["English text"] is the text in the client's language, or the English
-- text itself when there is no translation. The modules wrap what players
-- see (labels, tooltips, chat lines) and never identifiers: set and macro
-- names, slash commands, saved settings, tooltip patterns.
--
-- A language lives in Locales\<locale>\*.lua (ruRU, deDE, frFR, ...), each
-- file calling GSI_AddTranslations("<locale>", { ["English"] = "...", })
-- and, for the names of the Equipment Sets GSI saves,
-- GSI_AddSetNames("<locale>", { ["Cat ST"] = "...", }). The files are listed
-- in GearSetImprover.toc after this one; a file for another language costs
-- nothing (its table is skipped). Locales\README.md: adding a language,
-- tools\l10n.js: a template with every text and a check.
-- ============================================================

GSI_LOCALE = (GetLocale and GetLocale()) or "enUS"

-- A language without translations of its own takes these (esMX the esES
-- ones, ptPT the ptBR ones). Texts translated for the language itself win.
GSI_LOCALE_FALLBACK = {
    enGB = "enUS",
    esMX = "esES",
    ptPT = "ptBR",
}

-- The letters a language is written in: picks a font that has them
-- (UI_Shared.lua) and the way text is put in capitals (GSI_Upper).
GSI_LOCALE_SCRIPT = {
    ruRU = "cyrillic",
    zhCN = "cjk",
    zhTW = "cjk",
    koKR = "cjk",
}

function GSI_LocaleScript(locale)
    return GSI_LOCALE_SCRIPT[locale or GSI_LOCALE] or "latin"
end

GSI_L = setmetatable({}, {
    __index = function(_, key) return key end,
    __call = function(t, key) return t[key] end,
})

-- Names of the Equipment Sets GSI saves, English short name -> name in the
-- client's language, at most 16 characters ("Cat ST" -> "Кошка").
GSI_SET_NAMES = {}

-- Which of the client's language or its fallback a table is for: 2 for the
-- language itself, 1 for its fallback, nil for any other.
local function Rank(locale)
    if locale == GSI_LOCALE then return 2 end
    if GSI_LOCALE_FALLBACK[GSI_LOCALE] == locale then return 1 end
    return nil
end

local textRank, setNameRank = {}, {}

function GSI_AddTranslations(locale, entries)
    local rank = Rank(locale)
    if not rank or type(entries) ~= "table" then return end
    for key, text in pairs(entries) do
        if type(key) == "string" and type(text) == "string" and text ~= ""
            and (textRank[key] or 0) <= rank then
            rawset(GSI_L, key, text)
            textRank[key] = rank
        end
    end
end

function GSI_AddSetNames(locale, names)
    local rank = Rank(locale)
    if not rank or type(names) ~= "table" then return end
    for short, name in pairs(names) do
        if type(short) == "string" and type(name) == "string" and name ~= ""
            and (setNameRank[short] or 0) <= rank then
            GSI_SET_NAMES[short] = name
            setNameRank[short] = rank
        end
    end
end

-- Capitals for any of the languages: string.upper changes only a-z, so the
-- accented Latin letters (à-þ) and Cyrillic (а-я, ё, ѐ-џ) are mapped by
-- their UTF-8 bytes. Other letters (CJK) have no capitals and stay.
function GSI_Upper(s)
    if type(s) ~= "string" then return s end
    s = string.upper(s)
    -- U+00E0-U+00FE (but not U+00F7) -> U+00C0-U+00DE
    s = s:gsub("\195([\160-\190])", function(c)
        local b = c:byte()
        if b == 183 then return "\195" .. c end
        return "\195" .. string.char(b - 32)
    end)
    -- U+0430-U+043F -> U+0410-U+041F
    s = s:gsub("\208([\176-\191])", function(c) return "\208" .. string.char(c:byte() - 32) end)
    -- U+0440-U+044F -> U+0420-U+042F, U+0450-U+045F -> U+0400-U+040F
    s = s:gsub("\209([\128-\159])", function(c)
        local b = c:byte()
        if b <= 143 then return "\208" .. string.char(b + 32) end
        return "\208" .. string.char(b - 16)
    end)
    return s
end
