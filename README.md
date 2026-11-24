# GearSetImprover Forever

**GearSetImprover Forever** is a gear scoring and Best-in-Bag optimizer built exclusively for **WoW Forever (Client 1.60.1 / Interface 16001)**.

> **Fork** of [GearSetImprover Forever](https://www.curseforge.com/wow/addons/gearsetimprover) by Yakilo. Yakilo's v1.4.4 took in part of these changes; this repository is merged with v1.4.4 and is the source of the CurseForge releases from v1.4.5 on. Changes:
>
> - Item stats: combat ratings from `GetItemStats` are converted to percent (crit 14, hit/haste/expertise 10, dodge 12, parry 15, block 5 rating per 1%), armor/resistances/weapon DPS come from the API, weapon speed is read on every client, and Russian tooltips are parsed.
> - Set bonuses on clients whose set names are not in the English/German table (ruRU) are learned from the item tooltips and kept in SavedVariables.
> - Spec: follows the talent tree with the most points by default (on Forever the three trees are trait groups of one talent tree); the header dropdown has an **Auto** entry, `/gsi spec auto` returns to it. Feral druids pick Cat or Bear once.
> - On a spec or talent change, open item tooltips, upgrade toasts and the Best in Bag list are scored again with the new weights; the "Upgrade(s) found" chat line is printed once per scan instead of on every talent event.
> - Equipment Sets per spec: by default the sets GSI saved for the spec ("GSI: Cat ST", "GSI: Resto AoE", ...), or one or more sets ticked in the Settings tab. Put on when the spec changes; with several sets a window asks which one. `/gsi set` does it by hand.
> - In tooltips every spec of the class gets one line per set it has ("vs <set>"), ticked in Tooltip Orientations or not; a set GSI saved for a mode is scored with that mode's weights. The active spec keeps its lines against the gear worn and adds its sets that are not on (Settings, on by default).
> - Dual spec: the "GSI Dual Spec" macro (`/gsi toggle`) switches to the other talent group and, once it is active, puts on the gear of the spec it plays; its icon is the spec it switches to. `/gsi go <spec> [mode]` goes to a given spec's group (Auto from the group builds, or chosen in Settings).
> - Login error "Module TooltipHook error: bad argument #2" fixed.
> - `/gsi dump` writes item/tooltip/spec diagnostics to SavedVariables.

---

### Why this addon?

If you play on **WoW Forever**, standard stat weight addons like Pawn don't give you accurate numbers. WoW Forever has custom class mechanics and formulas—such as 1/3 bonus healing converting to spell damage for hybrid specs, dedicated Feral AP scaling, Avoidance Reduction, and progressive Dungeon Set bonuses.

On top of that, raw stat calculators fail on items with strong procs or on-use effects (like *Hand of Justice*, *Ironfoe*, or *Darkmoon Cards*).

**GearSetImprover Forever** was made to fix this. It uses the official WoW Forever v2 stat weights, factors in procs and set bonuses, and lets you optimize and equip your best gear from your bags with one click.

---

### What it does

* **Tooltip Item Scores (GSI Score):**
  Hover over any equippable item to see its calculated score for your current class and talent spec. If it's in your bags, you'll see the exact upgrade delta (e.g. `+14.2 GSI Score`) compared to what you're currently wearing.

* **Best Available Gear (BiB Optimizer):**
  Click **"Optimize Gear"** in the Best Available tab to scan your inventory. The addon calculates the highest-scoring combination across all 17 gear slots and equips upgrades sequentially outside of combat.

* **Slot Locking:**
  Have a specific weapon, trinket, or pair of run-speed boots you never want swapped out? Click the **[Lock]** button on that slot. The addon will still show you potential upgrades, but will never replace a locked item when you hit "Equip All".

* **Proc & Special Effect Overrides:**
  Items with procs, on-use effects, or special bonuses (Hand of Justice, Ironfoe, Darkmoon Card: Maelstrom, Blackhand's Breadth, etc.) are scored using calculated uptime values (Effect x Uptime). Tooltips display `[GSI Override: +X.X]` with the explanation. Situational bonuses (like extra damage vs Undead) are clearly flagged.

* **Dungeon & Tier Set Bonuses:**
  Tracks set pieces dynamically (2, 3, 4, 5, 6, and 8-piece thresholds for Dungeon Sets). Tooltips tell you your active piece count and the score gain for reaching the next threshold. GSI also enforces the 1-piece limit on crafted tier sets.

* **Dedicated Resistances Section:**
  In the **Stat Weights** tab, there is a dedicated **"Resistenzen"** category with individual checkboxes for **Fire**, **Nature**, **Frost**, **Shadow**, and **Arcane**.
  - When checked, resistances default to **5.0**, ensuring resistance pieces are strongly prioritized for encounters like Molten Core (Fire) or AQ40 (Nature).
  - When unchecked, resistances are grayed out with **0.0** weight, so they won't interfere with your normal DPS or Tank gear.

* **Bag Clean-up (Aussortieren):**
  Finds obsolete gear sitting in your bags that is strictly worse than what you currently have equipped.
  - **Does NOT vendor gray trash loot** (this is an equipment evaluator, not a junk seller).
  - Items saved in any Blizzard Equipment Set are completely protected.
  - You can permanently lock specific items so they never appear on the sell list.

* **Custom Stat Weights & Pawn String Support:**
  Fine-tune any stat weight using smooth sliders (0.0 to 10.0, step 0.1). You can export and import custom strings, fully compatible with standard Pawn strings.

* **1-Click Action Bar Macros:**
  The Macros tab generates ready-to-use equip macros for your class (e.g. Tank Survival vs Threat, DPS Single-Target vs AoE) that you can drag straight onto your action bars.

* **Blizzard Options Integration:**
  Access addon settings anytime in the game menu under `Options -> AddOns -> GearSetImprover`.

---

### Slash Commands

* `/gsi` – Open or close the main window
* `/gsi equip` (or `/gsibib`) – Optimize and equip best available gear
* `/gsi options` (or `/gsi settings`) – Open settings in the Blizzard interface menu
* `/gsi macros` – Open the Macro Manager
* `/gsi help` – Display available commands in chat

**Role shortcuts for macros:**
* **Warriors & Paladins:** `/gsi equip prot survival` or `/gsi equip prot threat`
* **Druids:** `/gsi equip bear` or `/gsi equip cat`
* **DPS:** `/gsi equip fury st` or `/gsi equip fury aoe`

---

### Versioning & Release Status

* **Current Version:** `1.4.1` (Official Release - Shield-Tank 1H+Shield Enforcement Hotfix)
* GearSetImprover Forever is in official release with full support for WoW Forever (Client 1.60.1 / Interface 16001). Includes audited theorycrafting values across all 28 specs (Build 70755 post-launch hotfix audit) and strict 1H + Shield enforcement for Protection Warriors and Protection Paladins.

---

### Credits & Special Thanks

* Special thanks to **stroke1611** ([https://www.twitch.tv/stroke1611](https://www.twitch.tv/stroke1611)) and **followpawl** ([https://www.twitch.tv/followpawl](https://www.twitch.tv/followpawl)) for testing, community feedback, and support!
* Thanks to the entire WoW Forever theorycrafting and testing community.

---

### Installation

1. Download the latest release zip (`GearSetImprover.zip`).
2. Extract the folder into your World of Warcraft directory:
   `World of Warcraft\_classic_\Interface\AddOns\`
3. Ensure the folder name is `GearSetImprover` (containing `GearSetImprover.toc` directly inside).
4. Launch the game and type `/gsi` in chat.
