# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

XCOM 2 War of the Chosen mod that displays hit chance percentages on enemy icons during movement preview (Alt key). The mod extends `UITacticalHUD_EnemyPreview` to calculate and display hit chances from the preview tile position, not the soldier's current position.

## Build System

This is an XCOM 2 ModBuddy project using MSBuild:

```bash
# Build the mod (from SDK installation)
cd "C:\Program Files (x86)\Steam\steamapps\common\XCOM 2 War of the Chosen SDK"
.\Binaries\Win64\XComGame.exe make -final_release -mods WOTCEnemyHitPreview
```

Build output location: `XComGame\Mods\WOTCEnemyHitPreview\`

## Architecture

### Core Classes

**EnemyHitPreview.uc** - Main class extending `UITacticalHUD_EnemyPreview`
- Overrides `UpdatePreviewTargets()` to capture preview tile data
- Overrides `UpdateVisuals()` to display hit percentages via UIText labels
- Overrides `Show()` to calculate visible enemies from cursor/preview tile
- `GetHitChanceFromPreviewTile()` - Core hit calculation logic

**EnemyHitPreview_Config.uc** - Configuration class
- Uses `config(EnemyHitPreview)` specifier to read from XComEnemyHitPreview.ini
- `bHideUnrevealedEnemies` - Controls whether unrevealed enemies are shown

### Hit Chance Calculation

The mod manually calculates hit chance to show preview from a different tile position. It includes:

1. Base stats: Shooter Aim - Target Defense
2. Cover bonus (from `VisibilityInfo.TargetCover` at remote location)
3. Range modifier (from weapon's `RangeAccuracy` table)
4. Height advantage (uses `X2TacticalGameRuleset.default.UnitHeightAdvantageBonus/Penalty`)
5. Weapon upgrades (scope, laser sight via `GetMyWeaponUpgradeTemplates()`)
6. Flanking bonus (when target has no cover from preview position)

**Important**: Uses `GetVisibilityInfoFromRemoteLocation()` to get cover/visibility from the preview tile, not current position.

### Known Limitations

The hit calculation may not be 100% accurate in heavily modded environments (LWOTC, Mod Jam) because:
- Some mods add additional bonuses not captured by base stat queries
- Complex ability modifiers and state effects are difficult to replicate
- The calculation is best-effort for preview purposes, not a perfect recreation of the engine's hit calculation

The mod is accurate for vanilla XCOM 2 WOTC and provides approximate values for modded games.

## Configuration

User-configurable via `Config/XComEnemyHitPreview.ini`:
- `bHideUnrevealedEnemies=true` (default) - Only show enemies visible to squad
- `bHideUnrevealedEnemies=false` - Show all enemies including unrevealed

## Key XCOM 2 SDK Concepts

- **UnrealScript** - The scripting language (not C++)
- **GameState classes** - Immutable state objects (`XComGameState_Unit`, `XComGameState_Item`)
- **UIPanel/UIText** - Flash-based UI components
- **Visibility System** - `VisibilityMgr.GetVisibilityInfoFromRemoteLocation()` for preview calculations
- **Config system** - INI files in `Config/` folder, loaded via `config(ConfigName)` class specifier

## Steam Workshop Deployment

After building, upload via Steam Workshop tools. Include both English and Korean descriptions in the workshop page.
