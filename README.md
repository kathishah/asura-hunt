# Asura Hunt

An original Roblox action RPG: choose a path, fight folklore demons, level up, defeat a boss. Built with Rojo so all code is plain files in git, and works well with AI coding tools.

## One-time setup (Mac)

1. **Roblox Studio:** install from roblox.com and sign in.
2. **Rokit** (tool manager): install it following the README at https://github.com/rojo-rbx/rokit (the install command changes over time, so use theirs).
3. **Tools:** in this folder run:
   ```bash
   rokit add rojo-rbx/rojo
   rokit add Kampfkarren/selene
   rokit add JohnnyMorganz/StyLua
   selene generate-roblox-std
   ```
4. **Rojo plugin for Studio:** run `rojo plugin install`, or install the Rojo plugin from the Creator Store inside Studio. The plugin and the `rojo` command should be the same major version (7.x).
5. **Editor:** VS Code or Cursor with the "Luau Language Server" extension (optional but helpful).
6. **Git:** `git init && git add -A && git commit -m "Initial skeleton"`.

## Run it

1. In Studio choose **New > Baseplate**, then **File > Publish to Roblox** (needed for saving to work).
2. In Game Settings > Security turn on **Enable Studio Access to API Services**. Without it the game still runs, but progress is not saved (the log will say so).
3. In this folder run `rojo serve`.
4. In Studio open the **Rojo** plugin and click **Connect**.
5. Press **Play** (F5).

Edit a `.luau` file, save, and Studio updates live. Stop and re-press Play to test.

## Controls

| Action | PC | Mobile / gamepad |
| --- | --- | --- |
| Attack (3-hit combo) | Left click | On-screen "Slash" button / R2 |
| Path skill | E | "Skill" button / X |
| Dodge (brief invulnerability) | Q | "Dodge" button / B |

The panel at top-left shows level, XP, gold and stats. Buttons let you switch path and spend stat points.

## What works in this skeleton

- Two paths (Yodha melee, Rishi ranged) with a basic combo and one skill each
- Four enemy types including a boss, with chase/attack/leash/respawn AI
- XP, gold, levelling, stat points (Strength, Vitality)
- Data saving with retries, autosave and save-on-exit
- Placeholder HUD and floating damage numbers

## Known rough edges (expected at this stage)

- **Nothing has been run in Studio yet.** The code was written without the ability to launch Roblox, so expect to fix small things on first play. Paste any red errors from the Output window to your AI tool.
- Enemies are built from simple blocks, balls and cylinders. Reshape them in `src/shared/Config/EnemyLooks.luau`. If they float or sink into the ground, adjust `HipHeight` in `EnemyService.buildModel`.
- No attack animations or effects yet, so combat will feel flat until you add them in Studio.
- Enemy spawns use a default layout. To place them yourself, add Parts to the map, tag them `EnemySpawn` (Tag Editor plugin or the Properties panel) and give each a string attribute `EnemyId` (for example `Vetala`).

## Folder map

```
default.project.json     Rojo mapping
AGENTS.md / CLAUDE.md    Instructions for AI coding tools
docs/GAME_DESIGN.md      Design, theme, roadmap
src/shared               Types, Remotes, Config (Enemies, Paths, GameConfig)
src/server               Main + Services (Data, Enemy, Combat)
src/client               Main, Input, HUD
```
