#!/usr/bin/env node
// GearSetImprover translation helper (Node.js, no packages).
//
//   node tools/l10n.js template <locale>   new Locales/<locale>/Strings.lua with
//                                          every text and set name, values empty
//   node tools/l10n.js update <locale>     add the texts and set names that are
//                                          not in Locales/<locale>/ yet
//   node tools/l10n.js check <locale>      untranslated, unknown and broken
//                                          entries (format codes, colours,
//                                          textures, line breaks), TOC lines
//
// The texts are every L["..."] in the code plus the data values translated
// where they are shown (spec, slot and stat names, preset descriptions,
// override reasons): those come from the reference language's files (ruRU,
// complete). Keys are compared as written in Lua (escapes included).
'use strict';
const fs = require('fs');
const path = require('path');

const ROOT = path.resolve(__dirname, '..');
const REFERENCE = 'ruRU';
const STR = '"((?:[^"\\\\\\n]|\\\\.)*)"';

function stripComments(src) {
  let out = '';
  let i = 0;
  while (i < src.length) {
    const c = src[i];
    if (c === '"' || c === "'") {
      let j = i + 1;
      while (j < src.length && src[j] !== c && src[j] !== '\n') { if (src[j] === '\\') j++; j++; }
      out += src.slice(i, j + 1);
      i = j + 1;
    } else if (src.startsWith('--[[', i) || src.startsWith('--[=[', i)) {
      const close = src.startsWith('--[[', i) ? ']]' : ']=]';
      const end = src.indexOf(close, i);
      i = end < 0 ? src.length : end + close.length;
    } else if (src.startsWith('--', i)) {
      const end = src.indexOf('\n', i);
      i = end < 0 ? src.length : end;
    } else { out += c; i++; }
  }
  return out;
}

function luaFiles(dir) {
  const out = [];
  for (const e of fs.readdirSync(dir, { withFileTypes: true })) {
    const p = path.join(dir, e.name);
    if (e.isDirectory()) out.push(...luaFiles(p));
    else if (e.name.endsWith('.lua')) out.push(p);
  }
  return out;
}

// Texts used in the code: key -> first file
function codeKeys() {
  const keys = new Map();
  const files = [...luaFiles(path.join(ROOT, 'modules')), path.join(ROOT, 'GearSetImprover.lua')];
  const re = new RegExp('\\bL\\[\\s*' + STR + '\\s*\\]', 'g');
  for (const f of files) {
    const src = stripComments(fs.readFileSync(f, 'utf8'));
    for (const m of src.matchAll(re)) if (!keys.has(m[1])) keys.set(m[1], path.relative(ROOT, f).split(path.sep).join("/"));
  }
  return keys;
}

// The entries of a language: { texts: Map, setNames: Map, files: [] }
function readLocale(locale) {
  const dir = path.join(ROOT, 'Locales', locale);
  const res = { texts: new Map(), setNames: new Map(), files: [], dupes: [] };
  if (!fs.existsSync(dir)) return res;
  const pair = new RegExp('\\[\\s*' + STR + '\\s*\\]\\s*=\\s*' + STR, 'g');
  for (const f of fs.readdirSync(dir).filter(n => n.endsWith('.lua')).sort()) {
    const p = path.join(dir, f);
    res.files.push(p);
    const src = stripComments(fs.readFileSync(p, 'utf8'));
    // Each GSI_AddTranslations / GSI_AddSetNames call and its table
    const callRe = /(GSI_AddTranslations|GSI_AddSetNames)\s*\(\s*"([^"]+)"\s*,\s*\{/g;
    let m;
    while ((m = callRe.exec(src))) {
      let depth = 1, j = callRe.lastIndex;
      for (; j < src.length && depth > 0; j++) {
        const ch = src[j];
        if (ch === '"') { j++; while (j < src.length && src[j] !== '"') { if (src[j] === '\\') j++; j++; } }
        else if (ch === '{') depth++;
        else if (ch === '}') depth--;
      }
      const body = src.slice(callRe.lastIndex, j - 1);
      const target = m[1] === 'GSI_AddSetNames' ? res.setNames : res.texts;
      for (const e of body.matchAll(pair)) {
        if (target.has(e[1]) && target.get(e[1]) !== e[2]) res.dupes.push(e[1]);
        target.set(e[1], e[2]);
      }
    }
  }
  return res;
}

// Set names GSI saves: the presets' names without "GSI: ", and spec names
function setNameKeys(ref) {
  const keys = new Set(ref.setNames.keys());
  const mp = path.join(ROOT, 'modules', 'MacroPresets.lua');
  if (fs.existsSync(mp)) {
    const src = stripComments(fs.readFileSync(mp, 'utf8'));
    for (const m of src.matchAll(/\bname\s*=\s*"GSI: ([^"]+)"/g)) keys.add(m[1]);
  }
  return keys;
}

function allTextKeys() {
  const code = codeKeys();
  const ref = readLocale(REFERENCE);
  const keys = new Map(code);
  for (const k of ref.texts.keys()) if (!keys.has(k)) keys.set(k, '(shown from data)');
  return { keys, code, ref };
}

const q = s => '"' + s + '"';   // keys are kept as written in Lua

function writeBlock(locale, texts, setNames, title) {
  let s = `\n-- ${title}\nGSI_AddTranslations("${locale}", {\n`;
  let lastFile = null;
  for (const [k, file] of texts) {
    if (file !== lastFile) { s += `    -- ${file}\n`; lastFile = file; }
    s += `    [${q(k)}] = "",\n`;
  }
  s += '})\n';
  if (setNames.length) {
    s += `\n-- Names of the Equipment Sets GSI saves: at most 16 letters\nGSI_AddSetNames("${locale}", {\n`;
    for (const k of setNames) s += `    [${q(k)}] = "",\n`;
    s += '})\n';
  }
  return s;
}

function specs(s) {
  const fmt = (s.match(/%(?:\d+\$)?[-+#0]*\d*(?:\.\d+)?[sdifgxXcq%]/g) || []).map(x => x.replace(/^%\d+\$/, '%'));
  const positional = /%\d+\$/.test(s);
  return {
    fmt: positional ? fmt.slice().sort().join(' ') : fmt.join(' '),
    c: (s.match(/\|c[0-9a-fA-F]{8}/g) || []).length,
    r: (s.match(/\|r/g) || []).length,
    t: (s.match(/\|T/g) || []).length,
    n: (s.match(/\\n/g) || []).length,
  };
}

function tocLines(locale) {
  const toc = fs.readFileSync(path.join(ROOT, 'GearSetImprover.toc'), 'utf8');
  const dir = path.join(ROOT, 'Locales', locale);
  const files = fs.existsSync(dir) ? fs.readdirSync(dir).filter(n => n.endsWith('.lua')).sort() : [];
  return files.map(f => `Locales\\${locale}\\${f}`).map(l => ({ line: l, listed: toc.includes(l) }));
}

function main() {
  const [cmd, locale] = process.argv.slice(2);
  if (!cmd || !locale || !/^[a-z]{2}[A-Z]{2}$/.test(locale)) {
    console.log('usage: node tools/l10n.js template|update|check <locale, e.g. deDE>');
    process.exit(2);
  }
  const { keys, code, ref } = allTextKeys();
  const setKeys = [...setNameKeys(ref)];
  const dir = path.join(ROOT, 'Locales', locale);

  if (cmd === 'template' || cmd === 'update') {
    const have = readLocale(locale);
    if (cmd === 'template' && have.files.length) {
      console.log(`Locales/${locale}/ already has files: use "update" to add what is missing.`);
      process.exit(1);
    }
    const texts = [...keys].filter(([k]) => !have.texts.has(k));
    const names = setKeys.filter(k => !have.setNames.has(k));
    if (!texts.length && !names.length) { console.log('Nothing missing.'); return; }
    fs.mkdirSync(dir, { recursive: true });
    const file = path.join(dir, 'Strings.lua');
    let out = fs.existsSync(file) ? fs.readFileSync(file, 'utf8') : `-- GearSetImprover: ${locale} texts. Fill in the empty values; an empty one\n-- stays English. Keep every %s / %d / %.1f, |cff...|r colour, |T...|t\n-- texture and \\n exactly as in the English text.\n`;
    out = out.replace(/\n*$/, '\n') + writeBlock(locale, texts, names,
      cmd === 'template' ? 'Texts' : 'Added ' + new Date().toISOString().slice(0, 10));
    fs.writeFileSync(file, out.replace(/\r/g, ''));
    console.log(`${path.relative(ROOT, file).split(path.sep).join("/")}: ${texts.length} texts, ${names.length} set names to translate.`);
    for (const t of tocLines(locale)) if (!t.listed) console.log(`Add to GearSetImprover.toc after Locales\\Locales.lua:  ${t.line}`);
    return;
  }

  if (cmd === 'check') {
    const have = readLocale(locale);
    if (!have.files.length) { console.log(`No files in Locales/${locale}/.`); process.exit(1); }
    let problems = 0;
    const untranslated = [...keys.keys()].filter(k => !have.texts.get(k));
    for (const [k, v] of have.texts) {
      if (!keys.has(k)) { console.log(`UNKNOWN   ${k.slice(0, 120)}`); problems++; continue; }
      if (!v) continue;
      const a = specs(k), b = specs(v), bad = [];
      if (a.fmt !== b.fmt) bad.push(`format [${a.fmt}] vs [${b.fmt}]`);
      for (const x of ['c', 'r', 't', 'n']) if (a[x] !== b[x]) bad.push(`${x === 'n' ? '\\n' : '|' + x} ${a[x]} vs ${b[x]}`);
      if (bad.length) { console.log(`BROKEN    ${k.slice(0, 100)}: ${bad.join('; ')}`); problems++; }
    }
    for (const [k, v] of have.setNames) {
      if (v && [...v].length > 16) { console.log(`TOO LONG  set name ${k} = ${v} (${[...v].length} letters, at most 16)`); problems++; }
    }
    for (const k of have.dupes) { console.log(`TWICE     ${k.slice(0, 120)} (different translations)`); problems++; }
    for (const t of tocLines(locale)) if (!t.listed) { console.log(`TOC       ${t.line} is not listed in GearSetImprover.toc`); problems++; }
    const names = setKeys.filter(k => !have.setNames.get(k));
    console.log(`${keys.size - untranslated.length}/${keys.size} texts translated, ${setKeys.length - names.length}/${setKeys.length} set names, ${problems} problem(s).`);
    if (untranslated.length) console.log(`Untranslated texts show in English; "node tools/l10n.js update ${locale}" adds them to Strings.lua.`);
    process.exit(problems ? 1 : 0);
  }
  console.log('unknown command ' + cmd);
  process.exit(2);
}

main();
