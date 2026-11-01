# Asura Hunt

An original Roblox action RPG: choose a path, fight folklore demons, level up, defeat a boss. Built with Rojo so all code is plain files in git, and works well with AI coding tools.

## One-time setup (Mac)

1. **Roblox Studio:** install from roblox.com and sign in.
2. **Rokit** (tool manager): install it following the README at https://github.com/rojo-rbx/rokit (the install command changes over time, so use theirs).
3. **Tools:** in this folder run the following. `rokit.toml` pins Rojo, StyLua, Selene and Lune to the same versions CI uses.
   ```bash
   rokit install
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

## Checks (CI)

`.github/workflows/ci.yml` runs on every pull request and every push to `main`: `stylua --check`, `selene`, `lune run tests/run` and `rojo build`. Fix a red check before merging. It cannot judge how the game looks or feels, so the Studio playtest in `docs/PLAYTEST.md` still matters. It does not publish the game: the map lives in the Studio place, not in git, so publish from Studio (File > Publish to Roblox) after merging.

## Publishing

After merging to `main`, run `./publish.sh`. It closes Roblox Studio first (with your permission), because Roblox rejects an upload while Studio has the place open, then runs the GitHub workflow `publish.yml` and shows Roblox's answer. One-time setup and what an upload replaces are in `docs/PUBLISHING.md`. Publishing from Studio (File > Publish) still works.

## Controls

| Action | PC | Mobile / gamepad |
| --- | --- | --- |
| Attack (3-hit combo) | Left click | On-screen "Slash" button / R2 |
| Path skill | E | "Skill" button / X |
| Dodge (brief invulnerability) | Q | "Dodge" button / B |
| Shop | P | "Shop" button |

On a PC, **B is reserved for a future backpack screen** and the shop is on **P**. Keep new keys away from W, A, S and D, which walk the character.

A "How to play" panel on the right ticks off each control the first time you use it, then fades away (words in `src/shared/Config/Tutorial.luau`). Enemies hunch lower as they are hurt and fall over when they die (tuning in `src/shared/Config/Animations.luau`); sounds are listed in `src/shared/Config/Sounds.luau`.

The panel at top-left shows level, XP, gold and stats. Buttons let you switch path and spend stat points. Your health is a bar with the numbers on it (like `85 / 100`) at the bottom centre, above the E and Q boxes; it replaces Roblox's built-in health bar (look in `src/shared/Config/Effects.luau`, `PLAYER_HEALTH`).

## What works in this skeleton

- Two paths (Yodha melee, Rishi ranged) with a basic combo and one skill each
- Six enemy types including a boss and a ranged witch, with chase/attack/leash/respawn AI
- XP, gold, levelling, stat points (Strength, Vitality)
- Data saving with retries, autosave and save-on-exit
- Placeholder HUD and floating damage numbers

## Known rough edges (expected at this stage)

- **Light playtesting only.** The game has been run in Studio, but only briefly. Paste any red errors from the Output window to your AI tool.
- Enemies are built from simple blocks, balls and cylinders. Reshape them in `src/shared/Config/EnemyLooks.luau`. If they float or sink into the ground, adjust `HipHeight` in `EnemyService.buildModel`.
- No attack animations or effects yet, so combat will feel flat until you add them in Studio.
- Enemy spawns use a default layout. To place them yourself, add Parts to the map, tag them `EnemySpawn` (Tag Editor plugin or the Properties panel) and give each a string attribute `EnemyId` (for example `Vetala`).

## Folder map

```
default.project.json     Rojo mapping
AGENTS.md / CLAUDE.md    Instructions for AI coding tools
docs/GAME_DESIGN.md      Design, theme, roadmap
docs/ROADMAP.md          Plans for each milestone and how to work in parallel
docs/PLAYTEST.md         What has not been run in Studio yet, and what to check
src/shared               Types, Remotes, Config (Enemies, Paths, GameConfig)
src/server               Main + Services (Data, Enemy, Combat)
src/client               Main, Input, HUD
map                      The map as model files (Zone1, Baseplate, SpawnLocation), mapped into Workspace.
tools                    Studio command bar scripts (enemy gallery, zone builder) and extract-map. Not synced.
tests                    Headless checks run with Lune: `lune run tests/run`. Not synced.
```
