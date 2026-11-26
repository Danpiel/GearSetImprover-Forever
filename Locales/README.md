# Translations

GearSetImprover shows its texts in the client's language when a translation
for it is here, and in English otherwise. Every language works the same way;
Russian (`ruRU`) is complete and is the reference.

## How it works

- `Locales.lua` loads first. `L["English text"]` in the code gives the text
  in the client's language, or the English text when there is none.
- A language is a folder `Locales/<locale>/` (`deDE`, `frFR`, `esES`, `ptBR`,
  `itIT`, `zhCN`, `zhTW`, `koKR`, ...). Its files call:
  - `GSI_AddTranslations("<locale>", { ["English text"] = "translation", })`
    for the texts;
  - `GSI_AddSetNames("<locale>", { ["Cat ST"] = "...", })` for the names of the
    Equipment Sets GSI saves, at most 16 letters (the preset names without
    `GSI: `, and spec names for specs saved without a preset).
- The files are listed in `GearSetImprover.toc` right after
  `Locales\Locales.lua`. Every language's files load on every client; a table
  for another language is skipped.
- `esMX` uses the `esES` texts, `ptPT` the `ptBR` ones, `enGB` English
  (`GSI_LOCALE_FALLBACK` in `Locales.lua`); a language's own texts win.
- Fonts and capitals follow the letters a language is written in
  (`GSI_LOCALE_SCRIPT`): Cyrillic uses GSI's Expressway (it has them), Chinese
  and Korean the client's font. With EllesmereUI, its font is used. Capitals
  (`GSI_Upper`) handle accented Latin and Cyrillic letters.

## Adding a language

Needs Node.js, no packages.

1. `node tools/l10n.js template deDE` writes `Locales/deDE/Strings.lua` with
   every text and set name, all values empty, grouped by the file that shows
   them, and prints the line to add to `GearSetImprover.toc`.
2. Fill in the values. An empty value stays English, so a partial translation
   works. Keep exactly:
   - every `%s`, `%d`, `%.1f`, `%%` in the same order (`%2$s %1$s` positional
     codes are allowed when the word order must change: then for all of them);
   - colour codes `|cffxxxxxx ... |r`, textures `|T...|t`, `\n`, and spaces at
     the start or end;
   - `[GearSetImprover]`, `/gsi ...` commands and macro names (`GSI: Cat ST`,
     `GSI Dual Spec`) as they are.
3. Add the TOC line, `/reload` (a new file needs a client restart).
4. `node tools/l10n.js check deDE` reports what is untranslated, texts that
   no longer exist, broken format codes or colours, set names over 16 letters
   and files missing from the TOC.

After an update of the addon, `node tools/l10n.js update deDE` adds the new
texts (empty) to `Strings.lua`, and `check` shows what is left.

For languages written in other letters, add the locale to
`GSI_LOCALE_SCRIPT` in `Locales.lua` (`cyrillic`, `cjk`) so a font with its
letters is picked.

## Notes for code

- Wrap what players see, never identifiers: `btn:SetText(L["Equip"])`,
  `string.format(L["Equipped set '%s'."], name)`. Keys are plain double-quoted
  literals so the tool can find them.
- Data that is also used as a key (spec, slot and stat names, preset
  descriptions, override reasons) stays English and is wrapped where it is
  shown: `L[specData.name]`. Its translations are in the language files like
  any other text.
- `tools/` is for development and is not part of the release zip.
