-- ============================================================
-- GearSetImprover - Locales.lua (WoW Forever)
-- L["English text"] is the text in the client's language, or the English
-- text itself when there is no translation. The modules wrap what players
-- see (labels, tooltips, chat lines) and never identifiers: set and macro
-- names, slash commands, saved settings, tooltip patterns.
-- Translations: Locales\<locale>_*.lua, GSI_AddTranslations(locale, t),
-- loaded before the modules so tables of labels can be built at load.
-- ============================================================

GSI_LOCALE = (GetLocale and GetLocale()) or "enUS"

GSI_L = setmetatable({}, {
    __index = function(_, key) return key end,
    __call = function(t, key) return t[key] end,
})

function GSI_AddTranslations(locale, entries)
    if locale ~= GSI_LOCALE or type(entries) ~= "table" then return end
    for key, text in pairs(entries) do
        if type(key) == "string" and type(text) == "string" and text ~= "" then
            rawset(GSI_L, key, text)
        end
    end
end
