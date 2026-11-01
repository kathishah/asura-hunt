# Asura Hunt: instructions for AI coding agents

Read this file before changing anything. It applies to Codex, Claude Code, Cursor, Windsurf and any other agent.

## What this project is

A Roblox action RPG built by a parent and child. Players pick a path (Yodha warrior or Rishi caster), fight enemies inspired by Indian folklore, level up, spend stat points and take on a boss. The world and characters are original. Do not copy characters, names or assets from other games or anime.

Working title: **Asura Hunt** (can be renamed). Full design and roadmap: `docs/GAME_DESIGN.md`.

## How the project is built

- Language: **Luau** with `--!strict` at the top of every file.
- Code lives in plain `.luau` files and is synced into Roblox Studio with **Rojo** (`default.project.json`).
- Lighting and UI layout can be set in `default.project.json` and code. The 3D world (map and models) can be generated as code too, and the human can still change anything by hand in Studio.

### Building the map as code

Rojo does not sync loose parts, so map builders are scripts in `tools/` that you paste into Studio's command bar (edit mode, not Play). `tools/build-zone1.luau` is the pattern to follow.

**The map lives in git** as model files in `map/` (`Zone1.rbxm`, `Baseplate.rbxm`, `SpawnLocation.rbxm`), mapped into Workspace by `default.project.json` (Rojo allows one top-level instance per model file). When Rojo connects it puts these into Studio, and `rojo build` includes them, so a built place has the map. A change made in Studio, by hand or by a builder, is only kept once it is saved back: in Studio use File > Download a Copy, run `lune run tools/extract-map <that .rbxl>`, then commit the changed files in `map/`. A new top-level map piece needs its name added to `MAP_PIECES` in `tools/extract-map.luau` and a line in `default.project.json`.

**Place settings live in `default.project.json` too** (lighting, sky, streaming, respawn time, chat). Publishing through the API uploads the built file and replaces the live place, so a setting that is only in Studio would be reset. `tools/check-place.luau` guards the important ones; see `docs/PUBLISHING.md`.

- **Put it in `tools/`, not `src/`.** It must not run in the game. Keep it as a plain script with no `require`s.
- **Make it re-runnable.** It deletes and rebuilds only its own folder in Workspace (for example `Workspace.Zone1`) and sets `Parent` last, so running it twice never doubles the map. Studio shows a "Dangerous Command" warning because of the delete; Continue is expected.
- **Name things and group them in models** (`OuterWall`, `PillarHall`, ...), so the human can find, move, recolour or delete pieces by hand.
- **Keep the colours and sizes as named constants at the top**, so a restyle is a one-line change.
- **Hand edits are lost when a builder is re-run.** Before re-running one over a map the human has edited, say so and ask. For a small change, apply it to the open map and update the builder to match. Either way, finish by extracting the map into `map/` as described above.
- **The map follows rule 10**, like everything else: no deities, idols, sacred symbols or sacred places as scenery.
- **Spawn points and special spots are plain parts** with tags and attributes (see `EnemyService`), so they can be moved by hand.
- Rojo is told not to delete what a builder makes: `Workspace` and `Lighting` are marked `$ignoreUnknownInstances` in `default.project.json`.

| Folder | Becomes in Studio | Purpose |
| --- | --- | --- |
| `src/shared` | `ReplicatedStorage.Shared` | Types, remotes, config tables. Runs on both sides. |
| `src/server` | `ServerScriptService.Server` | `Main.server.luau` plus `Services/*`. Game logic. |
| `src/client` | `StarterPlayerScripts.Client` | `Main.client.luau`, `Input`, `HUD`. Input and UI only. |

## Rules

1. **The server is the authority.** Damage, cooldowns, XP, gold, stats and saving are decided on the server. The client only sends intent ("I pressed attack") and displays results.
2. **Validate every remote argument.** Check `typeof(...)` and ranges in `OnServerEvent` handlers. Never trust the client.
3. **Tuning lives in data.** Numbers go in `src/shared/Config/*`. Do not hard-code damage, health or cooldowns inside services.
4. **New remotes** are added to `REMOTE_NAMES` in `src/shared/Remotes.luau`, then used via `Remotes.get("Name")`.
5. **New enemies** are added to `src/shared/Config/Enemies.luau` and, if wanted, to the spawn list in `EnemyService`.
6. **Modern APIs only.** Use `task.wait`, `task.spawn`, `task.delay`. Never `wait`, `spawn`, `delay`. Use `Instance.new` then set `Parent` last.
7. **Do not invent Roblox APIs.** If unsure a method or property exists, check https://create.roblox.com/docs/reference/engine before using it, and say when something is unverified.
8. **Saving data:** never save over a player's record if loading failed (see `loadFailed` in `DataService`). Bump `GameConfig.DATA_VERSION` and handle migration when the saved shape changes.
9. **Keep changes small.** One feature per change. Do not refactor unrelated files.
10. **Content:** keep it appropriate for a young audience. Enemies are folklore creatures (Pishacha, Vetala, Chudail, Daayan, Rakshasa). Give each an easy English `displayName` plus the folklore name in `folkloreName`. Do not use deities, semi-divine beings or religious symbols as enemies, loot or jokes, and do not use named characters from the epics.

## Style

- Tabs for indentation, double quotes, 100 column limit (enforced by StyLua).
- `PascalCase` for modules and types, `camelCase` for functions and variables, `UPPER_SNAKE_CASE` for constants.
- Services are modules returning a table with a `start()` function, wired up in `Main.server.luau`.
- Short comments that explain *why*, not *what*.

## Commands

```bash
rojo serve default.project.json                 # live-sync into Studio (connect with the Rojo plugin)
rojo build -o build/AsuraHunt.rbxl              # build a place file
stylua src                                      # format
selene src                                      # lint (run `selene generate-roblox-std` once first)
lune run tests/run                              # headless checks of data, config and enemy behaviours (brew install lune)
rojo sourcemap default.project.json -o sourcemap.json   # for luau-lsp
```

## Definition of done

Before saying a task is finished:

1. `stylua src` and `selene src` run clean, and `lune run tests/run` passes. Add a test file in `tests/cases/` for any logic you can check without Roblox (saved data, config rules, server decisions).
2. `rojo build -o build/AsuraHunt.rbxl` succeeds. CI (`.github/workflows/ci.yml`) runs steps 1 and 2 on every pull request, so keep them in sync if a command changes. Tool versions are pinned in `rokit.toml`.
3. You listed what must be playtested in Studio. If you could run the game yourself, say what you checked; if you could not, say plainly what is untested. Either way, name what the human should check by hand.
