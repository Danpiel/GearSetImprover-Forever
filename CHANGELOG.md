# GearSetImprover Forever v1.4.6

### Cleaner Tooltip Lines & Active Spec Highlight

* **Tooltip Score Lines (`TooltipHook.lua`, `TooltipCache.lua`):**
  - Score lines name only the spec, the mode and the set: `Restoration AoE vs Resto AoE: 11.19 (+4.05)` instead of `GSI Score (Restoration AoE vs GSI: Resto AoE): 11.19 (+4.05)`.
  - Lines of the spec you play start with its specialization icon and use a slightly larger, outlined font instead of the green `*` marker.
* **Missing Set Lines for the Active Spec (`TooltipHook.lua`):**
  - A fully equipped set of the spec you play no longer hides its line when the set's mode is not ticked in Tooltip Orientations (e.g. Restoration with *Single* ticked and `GSI: Resto AoE` worn now keeps the AoE line), so the tooltip shows the same lines whichever spec you play.

---

# GearSetImprover Forever v1.4.5

### Dual Spec Macro, Equipment Sets per Spec & Set Comparison Tooltips

* **Dual Spec Switching (`UI.lua`, `UI_Tab_Macros.lua`, `StatWeights.lua`):**
  - New **GSI Dual Spec** macro (`/gsi toggle`, also `/gsi go` alone): switches to the other talent group and, once it is active, equips the gear of the spec that group plays.
  - `/gsi go <spec> [mode]` (e.g. `/gsi go bear`, `/gsi go cat aoe`) switches to the talent group of that spec, sets the Feral Cat/Bear role and equips the spec's set (or the best bag gear when it has none).
  - Each spec is tied to a talent group: **Auto** (the group whose most-used tree is the spec's) or chosen in Settings, e.g. separate Cat and Bear builds.
  - The macro icon shows the specialization it switches to and updates after every switch or talent change (outside combat). The Dual Spec row has no Equip button and saves no Equipment Set of its own.
* **Equipment Sets per Spec (`UI_Tab_Settings.lua`, `UI_Tab_Macros.lua`):**
  - By default a spec uses the sets GSI saved for it from the Macros tab (`GSI: Cat ST`, `GSI: Resto AoE`, ...); one or more Equipment Manager sets can be ticked in Settings instead.
  - When a spec has several sets, a window asks which one to put on (Esc keeps the current gear). After a talent group switch the Feral group offers both the Cat and the Bear sets; picking one sets the Feral role.
* **Set Comparison in Tooltips (`TooltipHook.lua`, `CompareEngine.lua`):**
  - **Compare with every spec's sets** (Settings, on by default): every spec of your class gets one tooltip line per Equipment Set it has (`vs <set>`), ticked in Tooltip Orientations or not. A set GSI saved for a mode is scored with that mode's weights. Lines are grouped spec by spec.
  - The active spec keeps its lines against the gear you wear and adds its sets that are not fully equipped.
* **Official Specialization Icons (`ClassicData.lua`, `UI_Tab_Macros.lua`):**
  - All 28 specs use the game's official specialization icons (Rogue Combat takes Outlaw's, Feral Bear and Cat take Guardian's and Feral's). Fixes Feral Cat showing the Travel Form icon.
  - The main macro preset of each spec uses the same icon; press **Update** on an existing macro to refresh it.

---

# GearSetImprover Forever v1.4.4

### Forever Auto-Spec, Per-Spec Equipment Sets, Live Rescoring & Russian (`ruRU`) Client Support

*Thanks to **Danpiel** for the community contributions integrated into this release.*

* **Automatic WoW Forever Spec Detection (`StatWeights.lua`, `UI.lua`, `UI_Tab_Macros.lua`):**
  - Reads active WoW Forever talent trees via `C_ClassTalents` / `C_Traits` trait groups (`C_Traits.GetGroupDisplayInfoByTreeID`, `C_Traits.GetGroupCurrencyInfo`) instead of relying on single-spec `C_SpecializationInfo`, picking the tree with the most points spent.
  - Added **Auto** mode to the header spec dropdown (`Auto: <Spec>`) and `/gsi spec auto` (default), keeping Feral Druid Cat/Bear role selection in Auto mode and guarding against transient login/talent-reload states (`traitTreesSeen`).
* **Equipment Set per Specialization (`UI_Tab_Settings.lua`, `UI_Tab_Macros.lua`, `UI.lua`):**
  - Added a **Specialization & Equipment Set per Spec** section in the Settings tab to bind a Blizzard Equipment Manager set to each specialization (stored per character).
  - Automatically equips the bound set when the detected specialization changes (queued until combat ends if needed, toggleable in Settings), or manually via `/gsi set`.
* **Live Rescoring & Chat-Spam Fix (`GearSetImprover.lua`, `TooltipHook.lua`, `UI_Tab_BiB.lua`, `UI_Tab_Overview.lua`, `UpgradeToast.lua`):**
  - Open item tooltips (`RefreshShownTooltips`), shown/queued upgrade toasts (`ReevaluatePending`), and Best in Bag results (`MarkScanStale`) now rescore automatically on spec and talent changes.
  - Deduplicated `"Upgrade(s) found"` chat output so it prints once per scan, and only when results change after automatic rescans.
* **Weapon DPS/Speed, API Stat Mappings, Russian (`ruRU`) Client Support & Diagnostics (`ItemScore.lua`, `Config.lua`, `SetBonus.lua`, `UI.lua`):**
  - Weapon DPS now reads directly from `GetItemStats` (`ITEM_MOD_DAMAGE_PER_SECOND*`) with tooltip fallback, and weapon speed scans both left and right tooltip columns (`TextRight`) across all locales.
  - Added `RESISTANCE0_NAME` (`Armor`), `RESISTANCE2..6_NAME` (Resistances), `ITEM_MOD_FERAL_ATTACK_POWER*`, and `ITEM_MOD_EXPERTISE_RATING*` (`AvoidanceReduction`) to `GSI_Config.StatMap`, with double-count guards in EN/DE parsing.
  - Added Cyrillic UTF-8 tooltip parsing (`ParseRussianLine` / `LowerUTF8`) and automatic tooltip-based set bonus learning (`GearSetImproverDB.learnedSets`) for clients whose set names are not in the EN/DE table (`ruRU`).
  - Added `/gsi dump` (and `/gsi dump clear`) to save item/tooltip/spec diagnostics to `GearSetImproverDB._dump`.

---

# GearSetImprover Forever v1.4.3

### Cross-Class Rating Fix, Tank & Caster Audit

* **Critical Rating-vs-Percent API Fix (`ItemScore.lua`, `Config.lua`):**
  - Fixed `C_Item.GetItemStats()` returning internal Level-60 combat ratings (e.g., `14` rating per `1%` Crit) for `ITEM_MOD_*_RATING*` stats instead of flat percentages, which previously inflated Crit, Hit, Haste, Dodge, Parry, Block, and Defense scores and broke hit caps across all 9 classes.
  - Tooltip flat percentages now take priority, with Level-60 converted API fallbacks (`Crit /14`, `Hit /10`, `Haste /10`, `Dodge /12`, `Parry /15`, `Block /5`, `Defense /1.5`, `Expertise /10`; Armor Penetration remains flat).
  - Added `ITEM_MOD_POWER_REGEN0_SHORT` MP5 mapping to `GSI_Config.StatMap`.
* **Caster, Hybrid & Healer Scoring & Per-Threshold Set Bonuses (`ItemScore.lua`, `SetBonus.lua`, `OptimizationEngine.lua`, `EnchantBonus.lua`, `Profiles_v2_2.lua`, `Config.lua`):**
  - Fixed +33% / +88% `SpellPower` + `HealingPower` double-counting for non-healers on universal spell power items and Forever dual-stat healing items.
  - Fixed German pure-healing (`Heilung um bis zu X`) and school-damage (`Schattenzauberschaden`) tooltip parsing so pure healing never leaks into `SpellPower` or `hasUniversalSP` and school damage is not double-counted; added symmetric English reversed dual-stat damage/healing patterns.
  - Switched set bonus `SpellPower`/`HealingPower` scoring to per-threshold evaluation in `SetBonus.lua` and `OptimizationEngine.lua`, fixing +100% healer and +33% non-healer set bonus double-counting without breaking multi-threshold sets (e.g., *Soulforge*, *Devout*).
  - Zeroed out Priest healer `HOLY`/`SHADOW` damage weights (`priester_heilig`, `priester_disziplin`, ST & AoE) to match `healer_spell_damage_weight = 0`.
  - Extended healer universal spell power routing in `EnchantBonus.lua` to ZG/Naxxramas enchants (`2587`, `2588`, `2589`, `2605`, `2721`).
* **Cross-Class Weight, Cap & AoE Calibration (`Profiles_v2_2.lua`, `Config.lua`, `TalentIntegration.lua`, `ItemScore.lua`, `OptimizationEngine.lua`):**
  - Closed the `TertiaryWeights.Spirit = 0.2` leak (`Spirit = 0.0` fallback + explicit `SPI` across all 56 profiles and `Config.DefaultWeights`).
  - Calibrated Feral Bear Survival/Threat (`AGI`, `WEAPON_DPS_MH = 1.35 / 5.50`, `SPELL_DMG/NATURE = 0.00`), Protection Warrior (`WEAPON_DPS_MH = 1.15 / 4.20`, `AP/ARP`, corrected Shield Slam / Devastate notes), and Protection Paladin (`WEAPON_DPS_MH = 1.05`, `INT/MP5/AP/WEAPON_SKILL/ARP`) stats and caps (`DEFENSE`, `AVOID_RED`, `WEAPON_SKILL`).
  - Added missing `ARP` weights and missing `WEAPON_SKILL` (`305/308` ST, `305` AoE) and `AVOID_RED` (`5.6%` ST, `4.5%` AoE) caps across all physical ST & AoE profiles, zeroed Cat `INT`/`SPI`, and fixed AoE primary-stat inversions (Rogue, Hunter, Feral Cat, Enhancement Shaman, Retribution Paladin).
  - Updated WoW Forever Feral Druid talent rules (`Thick Hide -> Defense`, `Natural Reaction -> Dodge`, `Blood Frenzy -> Crit`).
* **Tooltip Parser & Engine Parity (`ItemScore.lua`, `OptimizationEngine.lua`):**
  - Excluded `Enchanted:` / `Verzaubert:` lines from base tooltip stat parsing so enchants respect `ignoreEnchants` and never double-count with `EnchantBonus.lua`.
  - Normalized UTF-8 German uppercase umlauts (`Ä/Ö/Ü`) and expanded DE/EN Dodge, Parry, Defense (`Increased Defense +X`), and Weapon Skill parsing (including `WAND`/`Zauberstäbe`, `CROSSBOW`/`Armbrüste`, `THROWN`/`Wurfwaffen`, profession skill exclusion, and self-weapon skill matching such as *Maladath*).
  - Aligned Shaman `Tidal Focus` hit detection in `ItemScore.lua` and `GetBaselineCapStats` (`UnitDefenseSkill`, `GetRangedHitModifier`, `CR_HIT_*`, Caster `SpellHitCap` guard) in `OptimizationEngine.lua`.

---

# GearSetImprover Forever v1.4.2

### TooltipHook Login Error Hotfix

* **Fixed `Module TooltipHook error` on Login (`TooltipHook.lua`):**
  - Guarded legacy `OnTooltipSetItem` script hooking in `HookTip()` with `tip.HasScript and tip:HasScript("OnTooltipSetItem")`.
  - Prevents `bad argument #2 to '?' (Usage: self:HookScript(...))` on the WoW Forever client, which uses `TooltipDataProcessor` and does not expose `OnTooltipSetItem` on `GameTooltip`.
  - Ensures `GSI_TooltipHook:Initialize()` completes cleanly so `SetHyperlink` hooks, profile/equipment/talent cache invalidation hooks, and the tooltip cache event frame are always registered.

---

# GearSetImprover Forever v1.4.1

### Shield-Tank Weapon Rule Fix (Protection Warrior & Protection Paladin)

* **Strict 1H + Shield Enforcement for Shield-Tank Specs:**
  - Fixed an issue reported on CurseForge (`Gray989`) where Two-Handed (`INVTYPE_2HWEAPON`) or Dual-Wield Off-Hand weapons could outscore 1H + Shield setups for Protection Warriors (`WARRIOR` Spec 3) and Protection Paladins (`PALADIN` Spec 2) in both `Survival` and `Threat/DMG` modes.
  - Updated `ItemScore.lua`, `OptimizationEngine.lua`, `CompareEngine.lua`, and `Overrides.lua` to score incompatible off-spec weapons (`INVTYPE_2HWEAPON`, `INVTYPE_WEAPONOFFHAND`, `INVTYPE_HOLDABLE`, and non-shield items evaluated for `INVSLOT_OFFHAND`) as `0`, disable slow-2H `speedMultiplier` scaling for Shield-Tank specs, exclude 2H/DW combinations in bag scans and weapon-pair optimization, and suppress 2H/DW/Holdable proc overrides and upgrade tooltip recommendations in Prot specs.
  - Zeroed out lingering `WEAPON_DPS_OH` / `WeaponDamageOH` (`2.80` -> `0.00`) on Protection Warrior Threat in `Profiles_v2_2.lua` (`krieger_schutz_threat`) and `Config.lua`.
  - Updated **Clean-up (`JunkTab.lua`)** so off-spec 2H weapons, Dual-Wield off-hands, and Holdables in Shield-Tank specs (as well as Holdables in Feral Druid specs) are protected from being flagged as obsolete junk when scoring `0`.

---

# GearSetImprover Forever v1.4.0

### Post-Launch Hotfix Audit (Build 1.60.1.70755 / Stand 2026-11-19), Enchant DPS Fix & Set/Proc Expansion
- **Klassen- & Spec-Feintuning (`Profiles_v2_2.lua`, `Config.lua`, `ItemScore.lua`)**:
  - **Druide**: Feral Cat `WeaponDamage` in `Profiles_v2_2.lua`, `Config.lua` und `ItemScore.lua` einheitlich auf `8.30 EP` synchronisiert (`CRIT: 13.20`) und Notizen an *Primal Bite*, *Shifting Power*, *Blood Frenzy*, *Natural Instinct* sowie +115 % Bären-Bedrohung angepasst (ohne entferntes *Berserk*).
  - **Krieger**: Furor an entferntes *Raging Blows* angepasst (MH-only Wirbelwind, *Reckless Swings*, *Improved Whirlwind*, 3-Rang *Flurry*: `WEAPON_DPS_MH: 8.80` ST / `10.80` AoE, `WEAPON_DPS_OH: 4.40` ST / `4.80` AoE, `HASTE: 11.40`); Waffen `WEAPON_DPS_MH: 12.20` (15s Slam CD); Schutz `BLOCK_VALUE: 0.95` / `1.05` (2-Ladungen Shield Block, 20 % Defiance).
  - **Schurke**: Meucheln `WEAPON_DPS_OH: 5.40` ST / `6.40` AoE und `WEAPON_DPS_MH: 9.10` (*Mutilate* 90 % MH+OH Waffenschaden); Täuschung `STR: 0.58`, `AP: 0.54`, `CRIT: 12.90` (*Death Mark*, *Boot Knife*).
  - **Schamane**: Verstärker `INT: 0.90`, `SPELL_DMG: 0.48`, `NATURE: 0.52`, `HEAL: 0.16` (*Mental Dexterity* 100 % INT->AP, *Maelstrom Weapon* 10 PPM); Elementar `NATURE: 1.12`, `FIRE: 0.25`, `FROST: 0.20`, `SPELL_CRIT: 13.60` (71.4 % SP Blitzschlag/Kettenblitz, 30 % *Lightning Overload*).
  - **Hexenmeister, Paladin, Jäger & Magier**: Gebrechen (`SHADOW: 1.05`, `SPELL_CRIT: 12.40`, `SPELL_HASTE: 12.90` für *Wrack*, *Soul Siphon* 36 %, *Pandemic*), Vergelter (`INT: 0.32`, `WEAPON_DPS_MH: 11.80`), Schutz-Paladin (`SPELL_DMG/HOLY: 0.95`), Heilig-Paladin (`SPI: 0.35`), Treffsicherheit/Überleben (`INT: 0.35`, `CRIT: 13.85`, `WEAPON_DPS_OH: 4.65`, `j_ger_ueberleben_aoe` vervollständigt), Frost-Magier (`SPELL_CRIT: 12.60`), Feuer-Magier (`FROST: 0.15` für *Frostfire Bolt*) und Arkan-Magier (`INT: 0.60`).
- **Talent- & Rassen-Feintuning (`TalentIntegration.lua`, `RaceBonus.lua`)**:
  - `GetShamanEnhancementIntWeight()` auf max. `0.90 EP` kalibriert (`0.20 + rMD * 0.17 + rMQ * 0.095`).
  - Fehlerhafte `Defiance -> Defense` Regel entfernt und durch `Thick Hide -> Armor` sowie 12 neue Crit-/Primärstat-Talentregeln (*Pandemic*, *Impale*, *Mortal Shots*, *Predator's Edge*, *Ice Shards*, *Elemental Fury*, *Vengeance*, *Heart of the Wild*, *Demonic Embrace*, *Survivalist*, *Arcane Mind*) ersetzt.
  - Gnom *Eureka!* um `RangedAttackPower = 1.01` ergänzt.
- **Waffen-/Zielfernrohr-Enchant-Fix & Neue Verzauberungen (`EnchantBonus.lua`)**:
  - Flache Waffenschadens- und Scope-Verzauberungen in korrekte DPS-Äquivalente umgerechnet (verhindert 4x Überbewertung von *Superior Impact* / *Superior Striking* / *Sniper Scope*) und Naxxramas-Schulterverzauberungen (`2715`-`2721`), Schild-Verzauberungen (`926`, `1890`, `2653`-`2655`) sowie Mithrilsporen (`464`) ergänzt.
- **Dungeon Sets 2 (T0.5), Scholomance-Sets & Waffen/Rüstungs-Overrides (`SetBonus.lua`, `Overrides.lua`, `overrides.json`)**:
  - Alle 9 Tier-0.5-Sets (inkl. deutscher Aliase), `"Vestments of the Devout"` Alias, *Dal'Rend's Arms*, *Black Dragonscale* (`maxEquipped = 1`) und 4 Scholomance-Sets ergänzt.
  - 13 bekannte Nicht-Trinket-Procs/On-Use-Items in `Overrides.lua` & `overrides.json` aufgenommen (*Felstriker*, *Bonereaver's Edge*, *Annihilator*, *Nightfall*, *Deathbringer*, *Vis'kag*, *Perdition's Blade*, *Flurry Axe*, *Thrash Blade*, *Runeblade of Baron Rivendare*, *Manual Crowd Pummeler*, *Storm Gauntlets*, *Cloudkeeper Legplates*).
- **Core-Engine, Dual-Wield & Set-Bonus-Optimierungen (`SetBonus.lua`, `Overrides.lua`, `ItemScore.lua`, `OptimizationEngine.lua`, `JunkTab.lua`, `TooltipHook.lua`, `MinimapButton.lua`, `UI_Tab_Overview.lua`)**:
  - Event-basiertes Set-Bonus-Tracking mit Alias-Normalisierung (`GetSetDefinition`) und doppelzählungsfreier Schwellen-Berechnung; `GetSetBonusScore` berücksichtigt nun das aktive `weights`-Profil.
  - Spec-/rollenspezifische Override-Filterung (`meleeHitProc`, `physicalOnly`, `casterOnly`), sodass Caster/Heiler oder Ranged-Hunter keine Nahkampf-Procs mehr angerechnet bekommen.
  - Off-Hand-/Dolch-Waffenparität zwischen `ItemScore.lua` und `OptimizationEngine.lua`, `RangedDPS`-Support für benutzerdefinierte Gewichte sowie vollständige 43-Stat-Aggregation (inkl. passiver Trinket-Stats) in `CalculateStats()`.
  - Slot-spezifischer Dual-Wield-/Multi-Slot-Vergleich und `NUM_BAG_SLOTS`-Unterstützung im Clean-up-Scanner (`JunkTab.lua`).
  - Mode-gescopte Cache-/Profil-Lookups (`CLASS-SPEC:MODE`) in `TooltipHook.lua` und `MinimapButton.lua` sowie korrigierte Weakest-Slot-Erkennung im Overview-Tab.

# GearSetImprover Forever v1.3.9

### Dediziertes AoE-System, Klassen- & Cap-Re-Audit, Caster Spell-Hit-Fix & UI-Harmonisierung
- **25 Dedizierte AoE- & Trash-Profile (`Profiles_v2_2.lua`)**:
  - Vollständige mathematische Entkopplung aller 9 Klassen im `AoE / Trash`-Modus (zuvor spiegelten `:AOE` Aufrufe meist das Single-Target-Profil).
  - Angepasste Trash-Hit-Caps (6.0 % Nah-/Fernkampf, 10.0 % Zauber) und Cleave-Gewichtungen für alle Spezialisierungen (Sweeping Strikes, Blade Flurry, Hurricane, Flamestrike, Rain of Fire, Multi-Dotting, Chain Heal, etc.).
- **Caster Spell-Hit-Cap Bypass behoben (`ItemScore.lua`)**:
  - `ItemScore.lua` prüfte Hit-Caps ausschließlich auf `caps.HIT`. Da Caster-Profile `caps.SPELL_HIT` definieren, wurde Spell-Hit über das 16 % Cap hinaus ungebremst linear weitergewertet. Durch die Prüfung auf `caps.HIT or caps.SPELL_HIT` greift die Deckelung nun für alle Zauberklassen fehlerfrei.
- **Beseitigung der AP/STR-Inversion im AoE (`StatWeights.lua`)**:
  - Im AoE-Modus wird Stärke (`Strength * 1.20`) nun synchron zu Angriffskraft skaliert, um zu verhindern, dass 10 AP mehr Punkte liefern als 5 STR.
  - Schulspezifische Zaubermächte (`FireSpellPower`, `FrostSpellPower`, etc.) werden im generischen AoE-Modus ebenfalls um 20 % skaliert.
  - Dedizierte AoE-Profile (`isAoEProfile`) verhindern Mehrfach-Multiplikationen.
- **Klassen- & Cap-Korrekturen (`Profiles_v2_2.lua`)**:
  - **Krieger**: Fehlende `caps.WEAPON_SKILL` (Soft-Cap 308) in `krieger_waffen`, `krieger_schutz` und `krieger_schutz_threat` ergänzt. `caps.DEFENSE` (Cap 440) in `krieger_schutz_threat` nachgetragen. Furor Offhand-DPS auf 5.20 EP und Haste auf 11.20 EP angepasst.
  - **Paladin**: Rüstungsgewicht in `paladin_schutz` (0.045 EP) und `paladin_schutz_threat` (0.035 EP) nachgetragen. Heilig MP5 auf 2.30 EP aufgewertet (Illumination Nerf auf 50 % Refund).
  - **Schurke**: Täuschung (`schurke_taeuschung`) Hit-Tiers nachgetragen (0–9 % Gelb-Cap mit 13.80 EP, 9–27 % DW-White-Cap mit 4.60 EP).
  - **Hexenmeister**: Zerstörung Feuer-Zaubermacht (`FIRE: 1.02`) über generische Zaubermacht gestellt (`SHADOW: 0.75`), passend zur Incinerate-Mechanik in WoW Forever.
  - **Druide**: Bär Verteidigungswertung auf 1.55 EP und `above_w` auf 0.85 EP angehoben (Thick Hide Rüstungsskalierung über 300 Verteidigung).
- **Talent-Integration (`TalentIntegration.lua`)**:
  - Priester: *Schattenfokus* (+1 % Zaubertrefferchance je Rang bis zu 5 %) integriert.
  - Paladin: *Präzision* (+1 % Hit/Rang bis 3 %) und *Göttliche Präzision* (+4 % Zauber-Hit/Rang bis 8 %) integriert.
  - Schamane: *Geistige Gewandtheit* (Mental Dexterity) Cap auf 0.90 EP angehoben (100 % Int zu AP).
  - Paladin: *Ehrfurcht* auf 2 Ränge (max. 0.60 EP) und *Champion des Lichts* auf 5 Ränge (max. 0.39 EP) korrigiert.
- **GUI-, UX- & Typografie-Optimierungen (`UI_*.lua`, `UI_Shared.lua`)**:
  - **Zweihandwaffen Weakest-Slot Fix (`UI_Tab_Overview.lua`)**: Bei ausgerüsteter 2H-Waffe wird der leere Nebenhand-Slot bei der Schwachstellenanalyse ignoriert (verhindert fälschliche "Weakest Slot: Off Hand" Meldung).
  - **Hover-Highlight Card Skinning Schutz**: Destruktive `SetScript("OnEnter")` Aufrufe in `UI_Tab_Overview.lua` und `UI_Tab_Gear.lua` durch sauberes `HookScript` ersetzt, um Obsidian-Glass Randglühen und Farbverläufe beim Hover zu bewahren.
  - **100 % Font Expressway Konsistenz**: Alle Schaltflächen der Blizzard Interface Options sowie sekundäre Action-Buttons (Toast Anchor Lock, Log Export) wurden mit `SkinButton` und `Expressway.ttf` harmonisiert.
  - **Makro-Presets**: `GSI: Arms AoE`, `GSI: Holy AoE` und `GSI: Ret AoE` hinzugefügt.

# GearSetImprover Forever v1.3.8

### WoW 12.1 (TOC 16001) Hardware-Secure Toast Equip & ItemGUID Auto-Dismiss (UpgradeToast.lua, UI_Tab_BiB.lua, GearSetImprover.lua)
- **Fixed Silent ADDON_ACTION_FORBIDDEN False-Positive in UseContainerItem**:
  - On the WoW Forever 12.1 (Interface: 16001) client engine, calling C_Container.UseContainerItem(bag, slot) from addon Lua to equip gear is protected (ADDON_ACTION_FORBIDDEN), but returns 
il silently without raising a Lua error in pcall(). Previously, if ok and not CursorHasItem() evaluated to 	rue, immediately skipping EquipItemByName and PickupContainerItem + EquipCursorItem, blacklisting the item, and closing the Toast while the item remained in the bag.
  - Removed UseContainerItem completely from all gear-equip paths (UpgradeToast.lua and UI_Tab_BiB.lua).
- **Native InsecureActionButtonTemplate Hardware-Event Overlay (UpgradeToast.lua & UI_Tab_BiB.lua)**:
  - Added GSI_UpgradeToastActionOverlay (InsecureActionButtonTemplate with useOnKeyDown = false) across the Upgrade Toast card: Right-clicking anywhere on the Toast or Left-clicking [R] Equip executes /equipslot <slotID> item:<itemID> natively for single-slots (Neck, Head, Chest, etc.) and exact (bag, slot) cursor placement for multi-slots (Rings 11/12, Weapons 16/17), without combat taint.
  - Added asynchronous equipment verification (ScheduleEquipVerification): Toasts are only marked dismissed and closed **after** WoW confirms the item is actually equipped (IsToastItemEquipped), never prematurely on the click frame.
- **Instant Auto-Dismiss on Manual Equip & ItemGUID Tracking (UpgradeToast.lua)**:
  - Tracks persistent ItemGUID (C_Item.GetItemGUID / C_Container.GetContainerItemInfo) alongside GetInventoryItemID across PLAYER_EQUIPMENT_CHANGED, EQUIPMENT_SWAP_FINISHED, UNIT_INVENTORY_CHANGED, and BAG_UPDATE_DELAYED. Immune to WoW 12.1 hyperlink mutations (creator GUIDs) and duplicate ring/weapon itemIDs.
  - Added equippedSnapshot / recentlyUnequipped swap-back guard so previously worn items moving into bags never trigger false upgrade toasts, and auto-dismisses ghost toasts if an item is sold, banked, or destroyed.
  - /gsi toast (/gsi testtoast) now automatically displays any real upgrade currently in the player's bags before falling back to the Thunderfury demo.
# GearSetImprover Forever v1.3.7

### Single-Slot Empty Slot Equip Fix & Auto-Dismiss on Manual Equip (`UpgradeToast.lua`, `UI_Tab_BiB.lua`)
- **Fixed Equip Failure into Empty Single-Slots (e.g. First Neck / Quest Reward)**:
  - In WoW Forever (`16001`), calling `PickupContainerItem(bag, slot)` + `EquipCursorItem(targetSlotID)` into an **empty** equipment slot (such as the Neck slot when equipping *Angelaufenes Medaillon* for the first time) leaves the item still reported on `GetCursorInfo()` during the same synchronous frame tick (`cItemID == idNum`). Previously, the synchronous check saw `cItemID == idNum` and called `ClearCursor()`, which immediately cancelled the equip action and put the item back into the bag!
  - Single-slots (Neck, Head, Shoulder, Chest, Back, Wrist, Hands, Waist, Legs, Feet, Ranged) now use `UseContainerItem` / `EquipItemByName` first (when no vendor/bank window is open), and `EquipCursorItem` cursor-cleanup no longer calls `ClearCursor()` synchronously when `cItemID == idNum`.
- **Auto-Dismiss Toast When Item Is Equipped Manually (`UpgradeToast.lua`)**:
  - Added `IsToastItemEquipped`, `GSI_UpgradeToast:CheckIfCurrentEquipped()`, and event listeners for `PLAYER_EQUIPMENT_CHANGED` and `UNIT_INVENTORY_CHANGED` (plus bag update checks). Whenever the player manually equips the displayed (or queued) upgrade item from their bags, the Upgrade Toast immediately marks the item as handled and dismisses itself automatically.

# GearSetImprover Forever v1.3.6

### Upgrade Toast Right-Click Equip & BoE Fix (`UpgradeToast.lua`, `UI_Tab_BiB.lua`, `GearSetImprover.lua`)
- **Fixed `EQUIP_BIND` Event Registration Crash in `UI_Tab_BiB.lua`**:
  - Wrapped `EQUIP_BIND_CONFIRM`, `AUTOEQUIP_BIND_CONFIRM`, `EQUIP_BIND`, and `AUTOEQUIP_BIND` registrations in `pcall`. Previously, registering `"EQUIP_BIND"` without `pcall` threw a fatal Lua error on WoW Forever (`Attempt to register unknown event "EQUIP_BIND"`), aborting `UI_Tab_BiB.lua` before `gsi_equipListener` and `GSI_UI:EquipUpgradeItem` could load.
- **Fixed Premature Cursor Cancellation on Right-Click Equip (`UpgradeToast.lua` & `UI_Tab_BiB.lua`)**:
  - When equipping Bind-on-Equip (BoE) or standard items via `PickupBagItem` + `EquipCursorItem(targetSlotID)`, `ConfirmPendingBind(targetSlotID)` now runs **before** any cursor cleanup. Previously, `PickupBagItem(bag, slot)` and `ClearCursor()` ran before `EquipPendingItem(targetSlotID)`, which immediately placed the BoE item back into the bag and cancelled the pending equip while still dismissing and blacklisting the toast!
  - Added `GetCursorInfo()` verification so that if the new item is still on the cursor after `EquipCursorItem`, it cleanly falls back to `UseContainerItem` / `EquipItemByName` for single-slots instead of falsely reporting `equipped = true`.
- **Keycap Badge & Frame Strata Improvements (`UpgradeToast.lua`)**:
  - Right-clicking anywhere on the Toast—including over the `[L] Dismiss` keycap badge—now triggers `EquipPendingItem()`. Clicking `[R] Equip` works with both Left-Click and Right-Click.
  - Elevated `GSI_UpgradeToastFrame` to `FULLSCREEN_DIALOG` strata (`FrameLevel 150`, `SetToplevel(true)`) so custom UI unitframes/actionbars never intercept clicks.
  - Added visual confirmation and sound feedback when right-clicking the `/gsi testtoast` demo notification.
  - Reset stale `toastDismissedItems` entries from v1.3.4/v1.3.5 once (`toastDismissedResetV136`) so previously affected items can trigger toasts again.

# GearSetImprover Forever v1.3.5 (Launch Candidate Audit 1.60.1.70707)

### Vollständiges Theorycrafting-Audit für WoW Forever Release (Launch 4. November 2026)
- **Erforscht & modelliert mit Gemini 4 Argon über die lokale Headless-Bridge**:
  - Alle 9 Klassen, 28 Spezialisierungen und 3 dedizierten Tank-Threat-Profile (31 Profile insgesamt) wurden mathematisch auf den finalen Client-Patchstand 1.60.1.70707 geprüft und nachjustiert.
- **Kritische Klassen- & Mechanik-Korrekturen**:
  - **Jäger (Überleben - Dual-Wield Melee)**: Profil `j_ger_ueberleben` von fehlerhafter Ranged-Klassifizierung auf reinen Dual-Wield Melee-Spek umgestellt (`WEAPON_DPS_MH: 8.50`, `WEAPON_DPS_OH: 4.20`, `AVOID_RED: 12.90`, gelber Hit-Cap 9 %, DW-White-Cap 27 %). Mongoose Bite via Expose Prey, Raptor Strike, Strider Kick und AP-skalierende Fallen voll abgebildet.
  - **Schamane (Verstärker - 2H Melee Bereinigung)**: Profil `schamane_verstaerker` bereinigt: In WoW Forever existiert kein Dual-Wield für Schamanen; `WEAPON_DPS_OH` auf 0.00 gesetzt, `WEAPON_DPS_MH` auf 11.40 erhöht. Intelligenz via Mental Dexterity (Int zu AP) und Mental Quickness (Int zu SP) auf 0.87 EP aufgewertet; Zaubermacht (0.42 EP) via Maelstrom Weapon Sofortzauber-Weaving integriert.
  - **Hexenmeister (Gebrechen - DoT-Crits & Pandemic)**: In WoW Forever können periodische Zauber und Drains kritisch treffen. Mit dem Talent Pandemic skaliert kritischer Schadensbonus massiv; Zauberkrit von 9.80 auf **12.15 EP** korrigiert.
  - **Paladin (Schutz - Shieldsworn & Righteous Fury)**: Integration des 31P Capstones *Shieldsworn* (Holy Strike 6s CD löst gratis Holy Shield & Shield Spec aus mit 6s Zauberblock-Uptime). `BLOCK_CHANCE` auf 9.50 EP und `BLOCK_VALUE` auf 1.20 EP (Survival) bzw. 0.95 EP (Threat) erhöht. Righteous Fury (+90 % Heilig-Bedrohung) hebt `HOLY` auf 1.35 EP und `SPELL_DMG` auf 1.25 EP in Threat-Mode.
  - **Druide (Bär - Lacerate Bleeds & Berserk Baseline)**: Lacerate (Aufschlitzen) als stapelbarer Blutungseffekt löst Single-Target TPS-Probleme; `WEAPON_DPS_MH: 7.25` und AP im Threat-Profil optimiert. Rudelführer gewährt universell +3 % Crit auf alle Angriffe und Zauber.
  - **Magier (Feuer & Arkan)**: Feuer profitiert von *Heating Up* (Crit = 14.50 EP); Arkan skaliert massiv mit Manapool und Tempo durch *Arcane Blast* und *Missile Barrage* (`INT: 0.52`, `HASTE: 13.60`).
  - **Priester & Heiler**: Sühne (Penance) für Disziplin, Gebet der Besserung (Prayer of Mending) für Heilig, Wasserschild & Springflut (Riptide) für Wiederherstellungs-Schamane sowie Bloom & Wildwuchs für Druiden voll mathematisch harmonisiert.

# GearSetImprover Forever v1.3.4

### Dual-Ring Pair Optimization & Explicit Slot Equip Fix (OptimizationEngine.lua, UI_Tab_BiB.lua, UpgradeToast.lua, CompareEngine.lua)
- **Fix Dual Ring Equip & Loop Elimination**:
  - **Replaced EquipItemByName with Deterministic Slot Cursor Swap**: In the WoW client, EquipItemByName ignores the second parameter (slotID) and defaults rings unconditionally to Slot 12. Because previous logic executed EquipItemByName first, equipping a ring targeted for Slot 11 was silently forced into Slot 12, swapping back and forth indefinitely.
  - **Cursor Swap Primary Order**: For all multi-slots (Finger 11/12, Trinket 13/14, Weapon 16/17), the addon now strictly uses PickupContainerItem(bag, slot) + EquipCursorItem(targetSlotID), safely placing the displaced item back into the vacated bag slot. EquipItemByName and UseContainerItem are disabled for multi-slots.
  - **Joint Ring Pair Optimization (OptimizeRingPair)**: Both ring slots are solved jointly. The weaker ring slot is replaced first with the best bag candidate, and if a second bag candidate beats the stronger ring, it is assigned to the other slot. This allows equipping both superior rings simultaneously in one step via 'Equip All' or sequentially.
  - **HUD Upgrade Toast Right-Click Fix**: Fixed unclickable 0-width keycap container and removed blocking level restriction so that right-clicking the upgrade notification reliably equips the upgrade into the weaker slot.

# GearSetImprover Forever v1.3.3

### Weaker Ring Prioritization & BoE Equip Robustness (`CompareEngine.lua`, `TooltipHook.lua`, `OptimizationEngine.lua`, `UI_Tab_BiB.lua`, `UpgradeToast.lua`)
- **Always Compare & Replace the Weaker Ring ("Ringe immer gegen den schlechteren Ring vergleichen")**:
  - **Prioritized Slot Comparison in `CompareEngine.lua`**: In `INVTYPE_FINGER`, the engine now measures both equipped ring scores (`INVSLOT_FINGER1` vs `INVSLOT_FINGER2`) and evaluates the weaker ring first. Upgrades and downgrades strictly prioritize displacing the lower-scored ring, so you never accidentally replace your best ring when obtaining an intermediate upgrade.
  - **Explicit Tooltip Slot Delta Badges (`TooltipHook.lua`)**: Ring tooltips now explicitly display which finger is being compared (`+11.8 vs Finger 1` or `+11.8 vs Finger 2`), making comparison context completely clear alongside the Blizzard comparison shopping tooltips.
  - **Robust BoE Item Binding (`EQUIP_BIND`)**:
    - Eliminated premature cursor cancellation: When equipping Bind-on-Equip rings (e.g. `Ring der Zaubermacht`, `Ring des rasanten Schlags`), the engine no longer attempts a synchronous bag pickup or cursor clear before the bind dialog is accepted.
    - Added `gsi_equipListener` to seamlessly handle `EQUIP_BIND` and safely deposit the replaced item into the vacating bag slot upon `UNIT_INVENTORY_CHANGED`.
  - **Safe Sequential Multi-Ring Equipping in "Equip All"**:
    - `StepEquip` now verifies `IsBagSlotLocked` and `IsInventoryItemLocked` before attempting the next item swap, preventing server packet collisions and item lock rejections when equipping two rings in the same batch.
    - Increased delay between consecutive swaps to 0.30s, allowing the WoW server to confirm each slot before starting the next.
  - **Asynchronous Optimization Refresh on Equip**: Single-item `Equip` button now waits for server-confirmed `UNIT_INVENTORY_CHANGED` before refreshing the BiB list and saving the equipment set, preventing premature re-scans while items are still binding.

# GearSetImprover Forever v1.3.2

### Multi-Slot Equipment Architecture & Ring Pair Optimization (`OptimizationEngine.lua`, `UI_Tab_BiB.lua`, `UpgradeToast.lua`)
- **Resolved Ring Replacement Ping-Pong Loop ("Es wechselt immer nur den einen Ring")**:
  - **Explicit Multi-Slot Targeting (Slots 11, 12, 13, 14, 16, 17)**: Re-architected item equipping so that all multi-slots use dedicated `PickupContainerItem` + `EquipCursorItem(targetSlotID)` instead of relying on `UseContainerItem`. `UseContainerItem` in WoW Classic unconditionally forces rings into Finger 1 (Slot 11) whenever both rings are occupied, making it impossible to equip into Finger 2 and causing two good rings to endlessly overwrite Finger 1.
  - **Preserved `slotID` across Engine & UI**: Added explicit `slotID = slotID` persistence to all upgrade candidate objects in `OptimizationEngine.lua`. Previously, `up.slotID` was undefined, causing the UI to lose target slot context and fall back to `UseContainerItem`.
  - **BoE Confirmation Dialogue Protection (`EQUIP_BIND`)**: Prevented `ClearCursor()` from running immediately after `EquipCursorItem` when a Bind-on-Equip dialog is open. `ClearCursor()` was previously cancelling the pending BoE state, preventing BoE rings (like `Ring des rasanten Schlags`) from being equipped.
  - **Clean Inventory Swapping**: When swapping items via cursor without a BoE prompt, the previous ring from Slot 11/12 is now cleanly placed back into the source bag slot (`PickupContainerItem(bag, slot)`) instead of being reverted by `ClearCursor()`.
  - **Independent Pair Evaluation**: Added `EnsureLowerScoreSlotFirst` for both Rings (`INVSLOT_FINGER1`, `INVSLOT_FINGER2`) and Trinkets (`INVSLOT_TRINKET1`, `INVSLOT_TRINKET2`), ensuring upgrades consistently replace the weaker item first.
  - **Dynamic Bag Slot Resolution (`ResolveUpgradeBagSlot`)**: Dynamically re-verifies bag coordinates before equipping, allowing multiple rings to be equipped in sequence without stale slot coordinates.

# GearSetImprover Forever v1.3.1

### Upgrade Toast Notification & Interaction Fixes (`modules/UpgradeToast.lua`)
- **Resolved Right-Click Failures on HUD Upgrade Toast**:
  - **Multi-Slot Item Targeting**: `targetSlotID` / `bestSlotID` is now explicitly passed from `EvaluateNewItem` to the toast. Secondary equipment slots (Finger 2 / Slot 12, Trinket 2 / Slot 14, Off-Hand / Slot 17) now use `PickupContainerItem` + `EquipCursorItem(targetSlotID)` instead of `UseContainerItem` (which always defaulted to Main Hand and Finger 1, causing unique-equipped conflicts or replacing the wrong item).
  - **Interaction Protection**: When speaking with vendors, bank, mail, trade, or auction NPCs, items are safely equipped via cursor without risking accidental item sale through `UseContainerItem`.
  - **InCombatLockdown Deferral**: Swapping armor in combat is blocked by the WoW engine. Right-clicking a toast while in combat now queues the item (`pendingCombatToast`) and automatically equips it upon leaving combat (`PLAYER_REGEN_ENABLED`) instead of failing silently.
  - **Level Requirement Guard**: Preview upgrades up to 3 levels above character level no longer trigger a failed equip, instant dismissal, and permanent blacklisting. Clicking now clearly warns the player with required level while keeping the item available for future level-ups.
  - **Bag Slot Lock Handling**: Detects transient `isLocked` bag state immediately after looting and automatically retries after 0.25s.
  - **Mouse Propagation & Keycap Wiring**: Mouse clicks and hovers on the item icon and `[R] Equip` / `[L] Dismiss` keycap badges are fully forwarded and interactive, ensuring clicks anywhere on the badge or card reliably trigger the intended action.
  - **Safe Dismissal Timing**: Items are only marked dismissed (`MarkItemDismissed`) on manual left-click dismissal or after successfully initiating the equipment command, never prematurely before validation.

# GearSetImprover Forever v1.3.0

### Theorycrafting Recalibration & Argon 4 Synchronization
- **Complete 28-Spec Mathematical Recalibration (`modules/Profiles_v2_2.lua`, `Config.lua`, `StatWeights.lua`)**:
  - Validated and synchronized exact stat weights across all 9 classes and 28 specs based on Gemini 4 Argon theorycrafting research for WoW Forever (Client 1.60.1).
  - **Feral Druid Weapon Damage Scaling**:
    - Feral auto-attack DPS equals weapon DPS (normalized to 1.0s Cat, 2.5s Bear).
    - Feral Cat WeaponDamage recalibrated to **8.30 EP** (scaling auto-attacks, 225% Shred, and Primal Bite).
    - Feral Bear WeaponDamage set to **1.80 EP** in Survival mode and **7.25 EP** in Threat/DMG mode.
  - **Protection Paladin Spell Power Threat**:
    - Righteous Fury (+60%–90% Holy threat multiplier), Consecration (33% SP), Holy Shield (20% SP/block), Judgement, and Holy Strike.
    - Prot Paladin Threat weights configured to **0.85 EP** SpellPower and **0.95 EP** HolySpellPower.
    - Prot Paladin Survival weights configured to **0.25 EP** SpellPower and **0.30 EP** HolySpellPower.
  - **Spell Piercing (Zauberdurchdringung) for Offensive Casters**:
    - In WoW Forever 1.60.1, Spell Piercing reduces resistances below 0 to generate bonus **Spell Vulnerability** damage.
    - Integrated specific SpellPenetration weights for all offensive casters: Elemental Shaman (**1.65 EP**), Balance Druid (**1.55 EP**), Shadow Priest (**1.50 EP**), Affliction Warlock (**1.45 EP**), Frost Mage (**1.40 EP**), Destruction Warlock (**1.35 EP**), Fire Mage (**1.30 EP**), Demonology Warlock (**1.25 EP**), Arcane Mage (**1.25 EP**).
  - **Dedicated Tank Threat Profiles**:
    - Created distinct Threat/DMG profiles for all tanks: `krieger_schutz_threat`, `paladin_schutz_threat`, and `druide_baer_threat`.
    - Wired `SpecModeToProfileID_v2_2` to dynamically load Threat profiles when Threat/DMG mode is selected.
  - **Full Engine Wiring (`modules/StatWeights.lua`)**:
    - Wired `GSI_StatWeights:GetWeights()` to prioritize `Profiles_v2_2.lua` (`GSI_Config:GetProfileWeights`) with seamless fallback to `Config.lua`.
- **UI Dropdown & Window Architecture Fix (`modules/UI.lua`, `ClassicData.lua`, `StatWeights.lua`)**:
  - Re-architected frame stratas and parenting: Main window set to `HIGH` strata (level 100), header buttons (`specBtn`, `modeBtn`, `settingsBtn`, `close`) set to `HIGH` (level 120), and dropdown menus (`GSI_SpecDropdownMenu`, `GSI_ModeDropdownMenu`) set to `FULLSCREEN_DIALOG` (level 500) over `UIParent`.
  - Fixed issue where the main window canvas captured all mouse clicks and prevented Specialization and Mode dropdown menus from opening.
  - Window dragging is now cleanly anchored to the header bar, avoiding accidental drag triggers when clicking buttons.
  - Added robust multilingual class resolution (`GSI_ClassicData:GetPlayerClass()` and `GetPlayerClassKey()`) so German clients ("Druidin", "Krieger", etc.) cleanly map to the 4 Druid specs and Tank/DPS modes without falling back to default Warrior.

# GearSetImprover Forever v1.2.9

### Features & QoL
- **Attached Merchant Clean-up Panel & "Sell All" (`modules/MerchantOverlay.lua`, `JunkTab.lua`)**:
  - Automatically docks a compact Clean-up Panel directly to the side of the default `MerchantFrame` whenever speaking to any vendor.
  - Displays a clear safety notice: *"Bedenkenlos verkaufbar: Diese Items sind nach deinen aktuellen GSI-Einstellungen schwächer als angelegtes Gear."* (Safe to sell based on your configured GSI thresholds and character gear).
  - Lists all obsolete gear in bags with item icons, quality borders, full tooltips on hover, and individual Sell buttons.
  - Shows total accumulated vendor value across all junk gear and features a prominent **"Sell All"** button protected with a confirmation dialog.
  - Dynamically updates as bags change (`BAG_UPDATE_DELAYED`) or items are sold, and safely hides upon closing the vendor window or pressing the panel's close button.
  - Can be enabled or disabled via Settings / Blizzard Interface Options (`merchantOverlayEnabled`).
- **Disenchant Spam Macro (`DE Macro`)**:
  - Dynamically offered in Clean-up tab and Merchant panel exclusively when the player has learned Enchanting (`HasDisenchantSpell`).
  - Creates and attaches a sequential spam macro to cursor (`GSI: DE Clean`) that casts `/cast Disenchant` and loops through all obsolete green/blue/epic items in bags upon repeated key presses.

# GearSetImprover Forever v1.2.8

### Features & WoW Forever Mechanics
- **Spell Piercing Stat Integration (`modules/ItemScore.lua`, `Config.lua`, `UI_Tab_Weights.lua`)**:
  - Implemented comprehensive detection and scoring for WoW Forever's **Spell Piercing** stat (formerly Spell Penetration).
  - In WoW Forever (Client 1.60.1), Spell Piercing can reduce target resistances below 0 into negative territory, granting bonus **Spell Vulnerability** damage in both PvE and PvP.
  - Added full bilingual pattern parsing for gear and enchants (`Increases spell piercing by X`, `Your spells pierce X Magical Resistance`, `+X Spell Piercing`, `Erhöht die Zauberdurchdringung um X`, `Zauber durchdringen X Magiewiderstand`, etc.) plus classic fallbacks.
  - Configured baseline default weight of **0.85** for all offensive caster specializations (Mage, Warlock, Shadow Priest, Elemental Shaman, Balance Druid).
  - Added dedicated **"Spell Piercing"** stat slider in the Stat Weights configuration tab with full Pawn import/export alias support (`spellpiercing`, `spellpierce`, `spellpenetration`, `spellpen`).

# GearSetImprover Forever v1.2.7

### Bug Fixes & Polish
- **Frame Strata & Layer Elevation (`modules/UI.lua`, `UI_Modals.lua`, `JunkTab.lua`)**:
  - Elevated `GSI_MainFrame` frame strata to `FULLSCREEN_DIALOG` with `FrameLevel 200` and `SetToplevel(true)`.
  - Added dynamic `:Raise()` hook on show to prevent player and target unit frames (e.g. EllesmereUI, ElvUI, custom unitframes) from rendering on top of the GearSetImprover main window.
  - Aligned modal popups (`Credits`, `Tutorial`, `Changelog`, `Locked Items`, `Profile Import/Prompt`) to `FULLSCREEN_DIALOG` with frame levels 500-600.
  - Dropdown menus and menu backdrop elevated to `FULLSCREEN_DIALOG` (levels 450-510) for seamless layering.

# GearSetImprover Forever v1.2.6

### Features & Polish
- **Zero-Allocation LRU Tooltip-Cache (`modules/TooltipCache.lua`)**:
  - Implemented high-performance LRU cache (300-entry capacity) utilizing a doubly linked list with an O(1) hash map.
  - 100% Zero-Garbage-Collection design: pre-allocated node, container, and line pools recycle tables upon eviction or invalidation.
  - Caches formatted score strings and tooltip lines, dropping lookup latency to ~1.4µs per tooltip hover (over 10,000 hits tested).
  - Fast-exit empty container caching for non-equippable items (reagents, potions, quest items), completely eliminating repeated slot and item parsing during bag browsing.
  - Cache key prefixes (`N:` normal vs `S:` shopping) eliminate collisions during shift/alt item comparison.
  - Full automatic state-revision invalidation on equipment changes, talent resets, spec switching, level-ups, or stat weight recalibration.
- **Direct Settings Navigation & Header Button**:
  - **Header Cog Button**: Added a clean 26x26 settings button (`Interface\WorldMap\Gear_64`) to the main application header between the close button and the live score widget. Provides 1-click access to addon configuration.
  - **Sidebar Workspace Tab**: Added the `Settings` tab directly to the main sidebar navigation with icon and sub-title.
  - **Robust Settings Opener (`GSI_UI:OpenSettings`)**: Fully supports modern `Settings.OpenToCategory` as well as classic `InterfaceOptionsFrame_OpenToCategory` with Blizzard Classic category focus workaround.
  - Slash command `/gsi settings`, `/gsi options`, and `/gsi config` routed directly through `GSI_UI:OpenSettings()`.
- **Modern WoW Secret Number Taint Protection (`modules/ItemScore.lua`)**:
  - Fixed hard crash (`attempt to perform arithmetic on local 'currentHit' (a secret number value, while execution tainted by 'GearSetImprover')`) occurring in modern WoW clients (11.0+/12.0+ engine) during bag scans and tooltip comparisons.
  - Implemented safe arithmetic probing (`GetSafeNumber`) via `pcall` and `issecretvalue()` to detect and sanitize opaque `<secret number>` values returned by protected combat APIs (`GetHitModifier`, `GetSpellHitModifier`, `UnitDefense`).
  - Added deterministic fallback engine (`GSI_ItemScore:GetEquippedHit`) that calculates equipped Hit directly by summing parsed gear stats across inventory slots 1..18 when the Blizzard API returns a secret number or nil in tainted execution contexts.
  - Hardened Defense and Weapon Skill calculations against secret value returns.
- **ESC-Key Window Closing & LIFO Dialog Stacking (`modules/UI.lua`)**:
  - Integrated `GSI_EscProxy` with Blizzard's `UISpecialFrames` system, enabling instant, natural closing of the addon window upon pressing ESC.
  - Implemented intelligent LIFO (Last-In, First-Out) stack hierarchy: when drop-downs (Spec, Mode) or modal sub-dialogs (Tutorial, Changelog, Credits, Profile Export/Import) are open, the 1st ESC closes the active dialog/menu, while the 2nd ESC closes the main window.
  - 100% Taint-Free and combat-safe across all WoW versions (Classic, Forever, Retail) without hooking protected keyboard input handlers.
- **Silent Mode / Disable Chat Output (`disableChatOutput`)**:
  - Added "Disable Chat Output (Silent Mode)" checkbox in both the in-window Settings workspace and Blizzard Interface Options.
  - Completely suppresses all chat messages generated by the addon (login welcome message, auto-equip notifications, optimization results, equipment set save confirmations, and macro updates).
  - Explicit manual help requests (`/gsi help`) remain available.
- **WoW Forever CharacterFrame Side-Tab (`modules/SideTab.lua`)**:
  - Seamlessly integrates a native-styled vertical side tab (`CharacterFrameModeTabGSI`) into the character pane (`CharacterFrame.ModeTabs`), using WoW Forever's native `"LargeSideTabButtonTemplate"` (octagonal bronze frame, octagonal `Mask` with `SetFillToInterior(true, 50)`, `SelectedTexture`, and `HighlightTexture`).
  - **Automatic Addon Tab Chaining**: Dynamically detects and chains below third-party side-tabs such as `TalentsForeverBookCharacterTab` (from *TalentsForeverBook*) with native `-2px` spacing and `UpdateTabLayout` / `SetPoint` hooks so tabs never overlap.
  - **ChonkyCharacterSheet (CCS) Compatibility**: Automatically detects active CCS tab skinning (`skinchartabs`) and applies the CCS beveled frame (`charbuttons1.png`) and mask (`buttonmask1.blp`) when CCS is active.
  - Interactive tooltip with real-time gear score preview and one-click toggle for GearSetImprover (`SOUNDKIT.IG_CHARACTER_INFO_TAB`).
  - Bidirectional state synchronization: side-tab automatically reflects active checked state (`SelectedTexture`) when GearSetImprover is opened or closed via slash commands, minimap button, header buttons, or ESC.

# GearSetImprover Forever v1.2.5

### Features & Polish
- **Rebranding to "Best Available"**:
  - Renamed all UI tabs, headers, macros, and tooltips from "Best in Bag" to "Best Available".
- **Automatic Optimization on Open & Equip**:
  - Automatically executes a background gear optimization scan when opening the addon window.
  - Automatically invalidates caches and executes a debounced re-optimization whenever equipment changes (`PLAYER_EQUIPMENT_CHANGED`, `EQUIPMENT_SWAP_FINISHED`).
  - Active panels and KPI cards immediately refresh with real-time score updates and upgrade badges without requiring manual clicks.
- **UI Refinement & Cleaner Scores**:
  - Removed "EP" suffix from gear scores, upgrade pills, and KPI metrics.
  - Removed legacy "Classic", "Pro Engine", and "Phase-Optimized" labels.
  - Fixed Macro Manager button layout and margins to fit comfortably within the window.
- **WoW Forever Patch 1.60.1 Theorycrafting Updates**:
  - **Racial Reworks**: Integrated Tauren *Endurance* (+2% Crit damage/healing), Dwarf *Earth Fury* (+2% Crit damage/healing), Human *Ruthless* (+2% Crit), Orc *Savage* (+1% Crit), Skyborne *Wind Blessed* (+3% Haste), Troll *Regeneration* (+20% HP5).
  - **Class & Talent Updates**: Recalibrated Arcane Mage with *Arcane Blast* 15% Int scaling and Mana weight, Retribution Paladin *Champion of the Light* adjustment, and Priest *Mental Strength* tier scaling.

# GearSetImprover Forever v1.2.4

### Theorycrafting Fusion: Argon 4 All-Spec Research Integration
- **Complete 28-Spec Theorycrafting Synchronization (`Profiles_v2_2.lua`)**:
  - Integrated research from Gemini 4 Argon across all 28 specializations and 9 classes.
  - **Mathematical Normalization**: Fused raw rating outputs into canonical WoW Classic +1% stat budget equivalents (~10–15 EP per +1% Hit/Crit), preserving gear evaluation integrity.
  - **Weapon Damage & Scaling**: Injected precise weapon scaling (Arms Mortal Strike MH-DPS `13.2`, Retribution 2H-DPS `8.4`, Combat Rogue MH-DPS `15.2` and OH-DPS `8.2`, MM Hunter Ranged-DPS `7.0`, Survival Hunter Ranged-DPS `12.5`).
  - **Thresholds & Hard Caps**:
    - **Melee Yellow Hit-Cap**: Enforced 9.0% style cap with reduced white hit scaling up to dual-wield caps (24.6%–27.0%).
    - **Spell Hit-Caps**: Configured 16.0% raid boss caps with talent reduction tiers (Fire/Frost Mage 10%, Shadow Priest 6%, Affliction Warlock 6%, Balance Druid 12%).
    - **Weapon Skill & Avoidance**: Soft cap at 305/308 for glancing blow penalty reduction and 5.6% boss dodge cap (`AVOID_RED`).
    - **Tank Crit Immunity**: 440 Defense cap for level 63 raid bosses with diminished return brackets above 440.
  - **Spec Aliases & Compatibility**: Added backward-compatible aliases for all internal and research identifiers (`jaeger_*`, `schamane_verstaerkung`).

# GearSetImprover Forever v1.2.3

### Automated Optimization & Usability Fixes
- **Automated Re-Scan & Re-Optimization**:
  - Automatically triggers "Optimize Gear" immediately after clicking "Equip All" in the Best-in-Bag panel or when equipping any item manually (`PLAYER_EQUIPMENT_CHANGED`).
  - Implemented debounced execution to keep UI performance smooth and prevent combat lockouts.
- **Multi-Slot Automated Swapping**:
  - Enhanced sequential equipping for multi-slot equipment (Ring 2, Trinket 2, and Off-Hand/Shield) via cursor pickup and slot placement.
- **Shield Usability & Tank Scoring Fix**:
  - Resolved an issue where shields (such as *Soldier's Shield of the Falcon*, etc.) were prematurely rejected by armor subclass checks for Paladins, Warriors, and Shamans, resulting in a score of `0.00 (+0.0)`.
  - Shields now properly receive accurate GSI scores reflecting spec stat weights (Armor, Stamina, Block Chance, Spell Damage).
- **Unusable Item Tooltip Cleanup**:
  - Items that cannot be equipped by the player's class no longer display misleading `0.00 (+0.0)` delta scores on tooltips.

# GearSetImprover Forever v1.2.2

### EllesmereUI Visual Overhaul
- **Dark Obsidian Aesthetics**:
  - Full redesign inspired by **EllesmereUI (EUI)** featuring deep matte obsidian backgrounds (`#0b0b0e`), elevated card elements (`#14141a`), and crisp 1px borders (`#21212a`).
- **Dynamic Class-Color Accents**:
  - Top window frame accent line (2px strip) dynamically colored to the player's class (`RAID_CLASS_COLORS`).
  - Active navigation tab indicator (3px vertical accent bar on the active tab's left edge).
  - Primary action buttons ("Equip All", "Optimize Bags", "Save Weights", "Create All Macros") glow with class-color outlines and smooth hover states.
- **Modern Minimalist Scrollbars**:
  - Replaced bulky Blizzard Classic brass scrollbars across all 8 panels with sleek 6px dark tracks and flat thumbs with class-colored hover highlights.
- **Pixel-Perfect Item Quality Borders**:
  - Square-cropped icons with crisp 1px borders colored by item quality (Common gray `#333`, Uncommon green, Rare blue, Epic purple, Legendary orange).
- **Refined Typography & Micro-Interactions**:
  - Uppercase slate labels (`#808094`), emerald upgrade indicators (`#2ecc71`), and subtle row hover highlights across Gear, Best-in-Bag, Trinkets, Macros, and Clean-up lists.
- **Header & Visual Fixes**:
  - Resolved an issue where 8-character class hex strings resulted in color prefix spillover in the title header (`0aGearSetImprover`).
  - Replaced missing Unicode glyph `✕` with clean ASCII `X` on window close buttons to ensure compatibility across all game client fonts.

# GearSetImprover Forever v1.2.1

### Performance & Engine Refinements
- **Zero-Allocation Compare Engine (`CompareEngine.lua`)**:
  - Replaced repetitive `CopyTable` memory allocations on tooltip hover events with lightweight in-place slot mutations and instant rollback, dramatically reducing garbage collection spikes during rapid item inspection.
- **Cap Evaluation Accuracy for Equipped Items (`ItemScore.lua`)**:
  - Implemented `IsItemCurrentlyEquipped` logic in Hit and Defense marginal threshold calculations. When evaluating an already equipped item, its own stats are subtracted from the character sheet's total before computing tier brackets, preventing equipped gear from self-inflating into diminished return tiers.
- **Context-Aware Slot Scoring (`targetSlotID`)**:
  - One-Handed weapons (`INVTYPE_WEAPON`) evaluated in or tested against the Off-Hand slot (`INVSLOT_OFFHAND`) now correctly use `WeaponDamageOH` weights instead of Main-Hand values.
  - Off-Hand comparisons in tooltips now accurately display `(+X.X vs OH)` with slot-specific item scores.
- **Enchantment Weight Context (`EnchantBonus.lua`)**:
  - `GetEnchantScore` now accepts spec and mode overrides to query the exact active weight set.
  - Corrected Classic weapon Spirit enchant spell ID mapping (`[1896] = { Spirit = 9 }`).
- **Optimization & Clean-up Accuracy (`OptimizationEngine.lua`, `JunkTab.lua`)**:
  - `OptimizeBagGearAsync` now passes target slot context for every candidate item and computes accurate gain deltas reflecting set bonuses and caps.
  - `JunkTab` now calculates equipped scores with exact slot context, properly evaluating off-hand items.
- **TOC & Entry Point Cleanup (`GearSetImprover.toc`, `GearSetImprover.lua`)**:
  - Removed obsolete `Profiles_v2_1.lua` from TOC loading order.
  - Dynamically read addon version from TOC metadata with fallback.
  - Automatically invalidate item score cache on `PLAYER_EQUIPMENT_CHANGED`.

# GearSetImprover Forever v1.2.0

### Major Update: WoW Forever v2.2 Theorycrafting & Scaling Engine
- **Stat Profiles v2.2 (Stand: 13.10.2026 / Client Build 1.60.1.70338)**:
  - Fully upgraded all 28 spec stat weight profiles and scoring logic to WoW Forever v2.2 specification.
  - **Fury Warrior**: Off-hand weapon damage (`WEAPON_DPS_OH`) boosted to `5.5` (reflecting *Raging Blows* Whirlwind hitting with both weapons). Multi-tier Hit-Cap implemented (0–9% yellow cap `w=11`, 9–17% dual-wield white cap `w=5.5` with *Dual Wield Specialization*, 17–27% main-hand cap `w=2.8`).
  - **Assassination Rogue**: Off-hand weapon damage (`WEAPON_DPS_OH`) increased to `6.2` (*Mutilate* hits with both weapons and scales with talents). Multi-tier Hit-Cap implemented (0–9% `w=13`, 9–16% poison/spell cap `w=6.5` with *Toxin*, 16–27% dual-wield white cap `w=4.5`).
  - **Holy Paladin**: Fixed Spirit (`SPI`) calculation error from v2.1 to `0.60` based on *Reverence* (30% in-combat mana regeneration).
  - **Retribution Paladin**: Intellect (`INT`) increased to `0.39` reflecting *Champion of the Light* converting 60% Intellect to Spell Damage.
  - **Protection Paladin**: Spell Damage (`SPELL_DMG`) tuned to `0.38` (*Righteous Fury* threat tuning); 2-tier Hit-Cap implemented (0–9% melee cap `w=2.5`, 9–16% spell cap `w=1.2` for Consecration).
  - **Protection Warrior**: Shield Block Chance (`BLOCK_CHANCE`) tuned to `2.33` following Beta patch block value scaling.
  - **Enhancement Shaman**: Intellect (`INT`) upgraded to `0.81` (*Mental Dexterity* + *Mental Quickness*); Spell Damage (`SPELL_DMG`) increased to `0.45` (*Stormstrike* 8s cooldown & *Maelstrom Weapon* instant casts).
  - **Restoration Shaman**: Crit (`CRIT`) adjusted to `5.5` following Water Shield cooldown removal.
  - **Priest**: Discipline mana stats updated (+8% to INT `0.76`, MP5 `3.24`, SPI `0.97` following Penance scaling adjustment); Holy Spirit updated to `1.15`.
  - **Caster Crit Explosion**: Affliction Warlock Crit boosted to `10.5` (*Pandemic* +100% crit damage bonus on DoTs & channels); Arcane Mage Crit boosted to `8.5` (*Arcane Mind*); Frost Mage Crit boosted to `7.5` (*Fingers of Frost* + *Ice Lance* + *Ice Shards*).
  - **Feral Bear Druid**: Defense cap above 440 tuned to `0.9` (*Thick Hide* armor bonus preservation).
- **Multi-Tier Hit & Defense Cap Engine**:
  - Rebuilt marginal scoring loop to smoothly evaluate gear across arbitrary multiple threshold tiers (e.g., 0–9%, 9–17%, 17–27%) without discontinuities.
- **Racial Trait & Weapon Synergy Integration**:
  - **Tauren**: Automatic permanent -1% reduction on all required gear Hit caps (*Endurance* trait).
  - **Weapon Crit Racials**: Humans (+2% Crit with Swords), Orcs (+1% Crit with Axes), and Dwarves (+1% Crit with Maces) now receive their racial Crit bonus directly when evaluating matching weapons.
  - **Skyborne (Himmelsgeborene)**: Integrated passive +1% Haste (*Wind Blessed*).
- **Parser & Scoring Precision**:
  - Added support for `FlatWeaponDamage` (e.g. revised *Edgemaster's Handguards* with `+1 Weapon Damage`) dynamically weighted by weapon swing speed.
  - Weapon skill items (`WEAPON_SKILL`) now strictly require the player to wield the matching weapon type.
  - Enforced clean Spell Power separation: Healer profiles strictly evaluate Spell Power as Healing without double-counting.

# GearSetImprover Forever v1.1.7

### Bug Fixes
- **Shaman Weapon Comparison & Dual Wield Logic Fix:**
  - Resolved an issue where One-Handed weapons (`INVTYPE_WEAPON`, such as *Dolchzahns Dolchzahn*) were tested against the Off-Hand slot for Shamans in WoW Forever, resulting in misleading positive upgrade recommendations (`+105.2`).
  - Corrected `GSI_ClassicData:CanDualWield()` to strictly enforce WoW Forever / Classic class rules: Shamans cannot dual-wield weapons and can only equip Shields (`INVTYPE_SHIELD`) or Off-hand items (`INVTYPE_HOLDABLE`) in the secondary hand.
  - One-Handed weapons on Shamans and other non-dual-wielding classes (Paladin, Druid, Priest, Mage, Warlock) are now strictly compared against the Main Hand (`INVSLOT_MAINHAND`), properly displaying negative score deltas in red when the equipped main-hand weapon has a higher score.
  - Added `GSI_ClassicData:GetEquipSlots(equipLoc)` helper method to ensure slot lookups across all comparison and notification engines respect character dual-wield capabilities.

# GearSetImprover Forever v1.1.0

### New Features & Improvements
- **Multi-Orientation Tooltip Scoring (ST, AoE, Tank Survival & Threat)**:
  - Users can now select and display multiple orientations/specs simultaneously in item tooltips (e.g. Cat ST & AoE, Bear Survival & Threat, Fury ST & AoE).
  - Added granular checkboxes per orientation in both the in-addon **Settings** tab and Blizzard's **Interface Options**.
  - Dynamic AoE mode stat weight scaling: hit requirement scaling tuned for trash mobs (-45%), burst/cleave AP & SP scaling (+20%), and Crit (+15%).
  - Active specialization is marked with an asterisk `*` in the tooltip display line.

# GearSetImprover Forever v1.0.1

### Bug Fixes
- **Vanity & Off-Hand (Holdable) Item Scoring Fix**:
  - Excluded statless Off-Hand items (`INVTYPE_HOLDABLE`), vanity rewards (e.g. *Bouquet of Scarlet Begonias*), and items lacking Armor from the white/grey item-level fallback score.
  - Cosmetic or decorative off-hands with zero combat stats now consistently evaluate to `0 Score` and will not trigger false upgrade recommendations.

# GearSetImprover Forever v1.0.0 (Official Release)

### Major Highlights & Official Release
- **Official 1.0.0 Release**: Transitioned out of Beta into official full release with finalized stat weights, complete Classic Forever item databases, and rock-solid HUD integration.
- **Two-Handed vs One-Hand + Off-Hand Tooltip Comparison Fix**:
  - Fixed an issue where comparing a 2H weapon only evaluated the difference against the Main-Hand slot instead of taking the replacement of the equipped Off-Hand item into account.
  - Tooltips and upgrade calculations now accurately use the simulated setup delta (`bestDelta`), correctly accounting for both hands when swapping between 2H and MH + OH setups.
- **HUD Upgrade Toast Notification Bugfix**:
  - Resolved root cause where non-existent table references (`EQUIP_LOC_TO_SLOTS` and `SLOT_NAMES`) aborted toast alert evaluations on 100% of looted items.
  - Fully wired `EvaluateNewItem` into `GSI_CompareEngine:Compare` and `GSI_ClassicData.EquipLocToSlots`.
  - Rebuilt bag snapshot tracking (`TakeBagSnapshot`) with `itemCounts` to accurately detect newly looted gear across all bags without false triggers when sorting inventory.
  - Implemented asynchronous cache queue (`pendingCacheQueue`) hooked into `GET_ITEM_INFO_RECEIVED` to seamlessly evaluate newly dropped items that were not yet cached by the game client.
  - Added `BAG_UPDATE_DELAYED` event processing for batched loot updates.
  - Added level requirement awareness: If an item requires 1–3 levels above player level, it displays `"UPGRADE (REQ LVL X)"` and hides the `[R] Equip` button.
- **Unusable Gear Support in Clean-up / Junk Tab (Guns, Unwearable Weapons & Armor)**:
  - Added full support for items that the player's class can never equip (e.g. Guns, Bows, Crossbows, Wands, Swords, Axes, Shields, or Plate/Mail on a Druid):
    - Automatically identifies unwearable weapon classes, armor types exceeding the character's maximum armor tier, shields, and class-restricted gear.
    - Added dedicated toggle checkbox: **"Include unusable gear"** (`junkIncludeUnusableGear`, enabled by default) in both the Junk tab and Blizzard Settings panel.
    - Unusable gear is highlighted with distinct category tags (`[Weapon]`, `[Armor]`, `[Shield]`, `[Relic]`, `[Class]`) in the list.
    - All unusable items are fully available to **Sell** (when visiting a vendor) or **Disenchant** (for uncommon/rare/epic items if an enchanter).
  - Maintained all existing safety protections: locked items, equipment sets, and tier sets remain fully protected.

# GearSetImprover Forever v0.9.15-beta

### Improvements & Fixes
- **Expanded Stat Weights Slider Range (0 to 50)**:
  - Extended all Stat Weights sliders (Standard Stats, Magic Schools, and Resistances) from 0–10 to **0–50** (with Weapon Speed ranging from -50 to +50).
  - Cleanly supports imported Pawn strings with higher stat multipliers (e.g. Weapon Damage, Crit, Hit, Attack Power) without clamping the slider handle to 10.
  - Enhanced numeric precision: `FormatWeight` now preserves up to 3 decimal places without rounding off Pawn fractions (e.g., `Agility=0.663` remains exact).
- **Localization Polish**:
  - Removed remaining German parenthetical terms in `STAT_DISPLAY_NAMES` for pure English interface consistency.

# GearSetImprover Forever v0.9.13-beta

### Improvements & Fixes
- **100% English Localization Enforcement**:
  - Replaced all remaining German user-facing strings, prompts, dialogs, button labels, placeholders, and error messages in the Import/Export modal with professional English text.
  - Enforced strict addon rule: All in-game UI components and notifications must always be in English.

# GearSetImprover Forever v0.9.12-beta

### Improvements & Fixes
- **Stat Weights Import: Profile Target Dialog (Overwrite vs. New Profile)**:
  - Added interactive profile choice dialog (`GSI_ImportProfileChoiceDialog`) when clicking **Import**:
    - **Overwrite Active Profile**: Overwrites the currently selected profile (or saves as custom profile if baseline).
    - **Create as New Profile**: Allows entering a new profile name, saves it, and adds it to the Profile dropdown.
  - **Automatic Pawn/GSI Profile Name Detection**: Parses the profile name directly from Pawn strings (e.g. `( Pawn: v1: "Feral Tank": ... )`) or GSI strings and automatically preselects "Create as New Profile" with the extracted name prefilled.
  - Interactive radio buttons with linked editbox focus, enter-to-confirm, and escape-to-cancel shortcuts.

# GearSetImprover Forever v0.9.11-beta

### Improvements & Fixes
- **Stat Weights Import/Export Modal Redesign & Usability**:
  - **Visible Input Inset Box**: Added a distinct dark inset container frame (`GSI_WeightsIOInputBg`) with a crisp border and glowing gold active-focus state so the text input field is immediately recognizable.
  - **Click-to-Focus Anywhere**: Clicking anywhere inside the inset box or scroll area now immediately focuses the text field with an active blinking cursor.
  - **Placeholder Prompt**: Added informative placeholder text explaining accepted string formats (GSI and Pawn strings) that automatically hides when text is typed or pasted.
  - **Auto-Focus on Import**: Opening the Import modal now automatically focuses the text area and sets the cursor so pressing `Ctrl+V` pastes the string immediately without hunting for a click target.
  - **Dynamic Height**: Auto-expands the EditBox scroll area smoothly based on content lines.

# GearSetImprover Forever v0.9.10-beta

### Improvements & Fixes
- **Clean-up (Aussortierer) Common (White) Gear Support**:
  - Added full support for including obsolete Common (White, Quality 1) equippable gear in the Clean-up scanner (such as leveling boots, chests, weapons outgrown by green items).
  - Built-in safety rules:
    - Only white items with a vendor sell price (`sellPrice > 0`) are scanned; 0-value items like shirts and starter clothes are protected.
    - Shirts (`INVTYPE_BODY`), Tabards (`INVTYPE_TABARD`), and Bags are explicitly excluded.
    - White items never show the Disenchant button (since WoW only permits disenchanting green+ items) and are sold directly when a merchant is open.
  - Added `Include Common (White) gear` toggle checkbox in both the Clean-up tab and the Interface Options panel (enabled by default).

# GearSetImprover Forever v0.9.9-beta

### Improvements & Fixes
- **Stat Weights Export Modal Fix**:
  - Resolved `bad argument #2 to 'insert' (number expected, got string)` in `GetWeightsExportString` (`UI.lua:2213`).
  - Fixed multi-return values from `string.gsub` being passed directly to `table.insert(formatted, ...)`, which caused `table.insert` to interpret the string as a numeric position argument.
  - Exporting stat weights via `GSI_WeightsIOFrame` now functions smoothly without Lua errors.

# GearSetImprover Forever v0.9.8-beta

### Improvements & Fixes
- **Bag Scan & Upgrade Toast Nil Fix**:
  - Resolved `attempt to call a nil value` in `EvaluateNewItem` when evaluating newly looted items (e.g. Hearthstone or items with non-standard equip locations) by correctly calling `GSI_ItemScore:Calculate(...)`.
  - Added backward-compatible alias `GSI_ItemScore.CalculateItemScore = GSI_ItemScore.Calculate`.

# GearSetImprover Forever v0.9.7-beta

### Improvements & Fixes
- **Multi-Toast Lifecycle & Re-Trigger Fixes**:
  - **Fixed Frozen Toast Bug**: Resolved a critical timer issue where the 60-second countdown continuously triggered `Dismiss()` every frame after expiry, keeping `toastFrame:IsShown()` true at alpha 0 and preventing any subsequent toasts from ever displaying.
  - **Isolated Animation Frame**: Moved fade-out logic to an independent `fadeHelper` frame, preventing the card's native breathing pulse `OnUpdate` script from being wiped out.
  - **Re-entrant Dismiss Guard**: Added `isDismissing` state flag to prevent overlapping dismiss requests or race conditions when clicking or timing out.
  - **Instant Reset on TestToast**: `/gsi testtoast` now instantly resets any active or queued toast so the demo alert can be tested repeatedly without delay.
  - **Non-Permanent Bag Loot Notification**: Replaced permanent session item lockouts with an 8-second re-scan throttle (`recentNotified`), allowing repeatedly looted items or bag rearrangements to trigger alerts normally.

# GearSetImprover Forever v0.9.6-beta

### Improvements & Fixes
- **Keycap Layout & Ergonomics Refinement**:
  - **Zero Overlap**: Solved font string bounding measurement timing by directly anchoring the separator dot (`·`) and `[R] Equip` badge to the actual rendered right edge of `[L] Dismiss` (`keyDismiss.lbl`), with fallback string length measurement.
  - **Intuitive Left-to-Right Ordering**:
    - `[L] Dismiss` is now positioned on the **Left** (matching mouse Left-Click).
    - `[R] Equip` is now positioned on the **Right** (matching mouse Right-Click).

# GearSetImprover Forever v0.9.5-beta

### Improvements & Fixes
- **Authentic Plumber HUD Architecture**:
  - Re-engineered the Upgrade Toast alert using Plumber's actual LootUI assets, textures, and typography:
    - Slate textured card background directly using `Textures/LootUI.png`.
    - Plumber's authentic 6px quality accent lines with tapered right and bottom ends (`TopLineEnd`, `LeftLineEnd`) tinted dynamically to the item's quality.
    - Embedded `Fonts/Lato-Bold.ttf` for modern, crisp sans-serif typography across all toast titles, badges, and subtitles.
    - Authentic Plumber keycap action badges (`[R] Equip` in vibrant green, `[L] Dismiss` in soft silver).
    - Authentic Plumber square close button widget with hover states.
    - Ambient radial glow (`IconOverlay.png`) and razor-sharp square icon border (`IconBorder-Square.png`).
    - Smooth card hover highlight slice and breathing quality pulse.
  - Synchronized the on-screen Anchor frame (`/gsi anchor`) with the exact same Plumber slate HUD card design (390×86px).

# GearSetImprover Forever v0.9.3-beta

### Improvements & Fixes
- **Scrollable Interface Options**:
  - Embedded a full `UIPanelScrollFrameTemplate` with smooth mouse wheel scrolling in the Blizzard Options panel (`/gsi config` or Game Menu -> Interface -> AddOns -> GearSetImprover).
  - All controls, sliders, and anchor settings now cleanly stay bounded inside the window without overflowing or spilling over action bars.
  - Dynamically displays the current TOC version in the panel header.
- **Modern Borderless Upgrade Toast**:
  - Completely removed the bulky tooltip border (`UI-Tooltip-Border`) in favor of a sleek, borderless dark obsidian glass HUD design (`BACKDROP_BORDERLESS`).
  - Added 2.5px quality-colored top accent line and 3px left glow strip (vibrant purple for Epic, blue for Rare, green for Uncommon, gold for Legendary).
  - Cleaned up icon styling with 1px quality outline and dropped the old chunky quickslot frame.
  - Smooth breathing pulse effect on the accent lines and score badge instead of flashing borders.
  - Streamlined minimalist close button (`×`).
  - Modernized the on-screen Anchor frame to match the borderless aesthetic.

# GearSetImprover Forever v0.9.2-beta

### Improvements & Fixes
- **Dedicated Anchor Mode in Interface Options**:
  - Added a dedicated "Toast Notification Position & Anchor" section in the official WoW Interface Options panel (`/gsi config` or Game Menu -> Interface -> AddOns -> GearSetImprover).
  - Includes a direct mode checkbox `Show movable Anchor on screen (Unlock to reposition)` and an interactive toggle button `[Unlock Anchor]` / `[Lock Anchor]`.
  - Live two-way synchronization: Locking the anchor from the floating on-screen box (`Lock & Save` button) or via `/gsi anchor` instantly updates the options panel button, checkbox, and status text (`Status: Locked in place`).
  - Added dedicated `[Reset Position]` button to quickly return to the default screen position.

# GearSetImprover Forever v0.9.1-beta

### Improvements & Fixes
- **Refined Upgrade Toast Layout**: Re-engineered on-screen upgrade alert layout with fixed coordinate baselines. Prevents text overlap between Score Gain badges and click instructions.
- **Enhanced Item Previews**: Added robust fallback handlers, color formatting, and authentic texture icons so demo toasts (`/gsi testtoast`) and newly looted items never display placeholder red question marks or raw item strings.
- **Movable Anchor Frame**: Integrated `/gsi anchor` and options panel controls to position and lock the toast anywhere on the screen.
- **Asynchronous Item Cache Hook**: Registered `GET_ITEM_INFO_RECEIVED` to seamlessly update toast labels and textures the moment uncached item info arrives from the server.

# GearSetImprover Forever v0.9.0-beta

### Highlights
- **Rebranded to GearSetImprover Forever**: Tailored specifically for WoW Forever / Classic itemization and stat mechanics.
- **New Addon & Minimap Icon**: Crisp dark medallion with a sword, shield, and upgrade arrow.
- **Dedicated Resistances Category**:
  - Organized under a clean Resistenzen section header in the Stat Weights tab.
  - Individual checkboxes for Fire, Nature, Frost, Shadow, and Arcane.
  - Default weight set to 5.0.
  - Inactive resistances are disabled and grayed out (effective score weight = 0.0).
  - Redundant checkboxes removed from the Best Available Gear tab.
- **Interactive Stat Weight Sliders**: Smooth 0.0 to 10.0 range sliders with live two-way synchronization.
- **Tier Set Thresholds & Limits**: Automatic 2, 3, 4, 5, 6, and 8-piece bonus tracking, plus crafted set limits.
- **Item Effect Overrides**: Proc and on-use ratings (overrides.json) factored into item scores.
- **Animated Upgrade Toast Alerts**: Real-time on-screen toast popup with pulsing/blinking glow when looting gear upgrades. Right-click to equip immediately, left-click to dismiss, 60s auto-dismiss timer, and full Blizzard options panel configuration.
- **Full English Localization**: 100% fluent English interface, options, tooltips, and documentation.

