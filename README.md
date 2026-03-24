[README.md](https://github.com/user-attachments/files/26162408/README.md)
# PAB – Party Ability Bars v2.0

**Author:** Nidhaus  
**Client:** WotLK 3.3.5a  
**Original concept:** Kollektiv, Vendethiel, Lawz

---

## Features

- Tracks party member ability cooldowns in arena and party
- **Arcane-style** options panel (`/pab`)
- **Custom cooldown timers** – manually set reduced cooldowns for spells affected by talents/glyphs (Hammer of Justice, Thunderstorm, Pain Suppression, Cloak of Shadows, etc.)
- **Auto-Detect** – inspects party members to automatically detect talent/glyph cooldown reductions
- Per-class ability enable/disable with icon preview
- Movable anchors or offset-based positioning
- Arena-only mode, hidden-until-cooldown mode
- Cooldown resetters (Cold Snap, Preparation, Readiness)
- Grouped cooldowns (traps share CD, shocks share CD, etc.)
- Racial and item tracking (PvP trinket, Bauble, racials)

<img width="878" height="796" alt="Image" src="https://github.com/user-attachments/assets/494bb632-55e5-4e15-b958-f83c5ae0f5be" />

## Files

| File | Lines | Purpose |
|------|-------|---------|
| `PAB.lua` | ~745 | Core logic, spell data, inspect, cooldown tracking |
| `PAB_Options.lua` | ~656 | Arcane-style options panel (UI only) |
| `PAB.toc` | 9 | Addon manifest |

## Installation

1. Extract the `PAB` folder into `Interface/AddOns/`
2. Make sure the folder is named exactly `PAB`
3. No libraries needed — everything is self-contained
4. Type `/pab` in-game to open settings

## Slash Commands

| Command | Action |
|---------|--------|
| `/pab` | Open/close the options panel |
| `/pab reset` | Reset all settings and reload UI |

## Tabs

### General
- Scale, icons per line, arena-only, hidden mode
- Movable/lockable anchors with X/Y offset
- **Auto-Detect Cooldown Reductions** toggle – when enabled, PAB inspects party members and adjusts cooldowns based on their talents and glyphs

### Abilities
- Select a class or race from the dropdown
- Enable/disable individual abilities with checkboxes
- Shows current effective cooldown (custom overrides reflected)

### Cooldowns
- Lists all spells that can have their cooldown reduced by talents or glyphs
- **Edit the timer manually** – type a custom cooldown in seconds
- Set to `0` or blank to revert to the default base value
- Shows base → min range and the source of reduction (talent/glyph name)
- Class filter dropdown

## Spells with Customizable Cooldowns

| Spell | Class | Base | Min | Source |
|-------|-------|------|-----|--------|
| Hammer of Justice | Paladin | 60s | 40s | Improved HoJ (Ret) |
| Thunderstorm | Shaman | 45s | 35s | Glyph of Thunder |
| Pain Suppression | Priest | 180s | 144s | Aspiration (Disc) |
| Dispersion | Priest | 120s | 75s | Glyph of Dispersion |
| Psychic Scream | Priest | 30s | 26s | Improved Psychic Scream |
| Cloak of Shadows | Rogue | 90s | 60s | Elusiveness (Sub) |
| Blind | Rogue | 180s | 120s | Elusiveness (Sub) |
| Vanish | Rogue | 180s | 120s | Elusiveness (Sub) |
| Bestial Wrath | Hunter | 120s | 84s | Longevity (BM) |
| Deterrence | Hunter | 90s | 60s | Glyph of Deterrence |
| Blink | Mage | 15s | 12s | Glyph of Blink |
| Death Grip | DK | 35s | 25s | Unholy Command |
| Strangulate | DK | 120s | 100s | Glyph of Strangulate |
| Icebound Fortitude | DK | 120s | 90s | Glyph of IBF |
| Bladestorm | Warrior | 90s | 75s | Glyph of Bladestorm |
| Intercept | Warrior | 30s | 15s | Improved Intercept |

## Bug Fixes (from original)

- **`_iconPaths` undefined** → fixed to `iconPaths`
- **Duplicate spell ID** in Warlock (Fel Domination listed twice) → removed duplicate
- **`SetParent(nim)`** → fixed to `SetParent(nil)`
- **Upgrade path crash** → `enabledCooldowns["Items"]` referenced undefined global → fixed
- **Race abilities not checked per-ability** → `enabled` was the table, not individual boolean → fixed
- **Variable shadowing** in nested loops (`i`, `k`, `v`) → renamed to unique identifiers
- **`inspectData` scope bug** → moved to `PAB.inspectData` as proper table member
- **Hardcoded English spec-swap strings** → now uses spell IDs 63645/63644 via `GetSpellInfo`
- **`FindAbilityIcon` O(60000) loop** → replaced with direct `GetSpellInfo(name)` call
- **LibSimpleOptions dependency** → removed entirely, replaced with custom Arcane UI in separate file
- **Monolithic single file** → split into `PAB.lua` (logic) + `PAB_Options.lua` (UI)
