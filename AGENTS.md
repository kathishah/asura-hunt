# Asura Hunt: instructions for AI coding agents

Read this file before changing anything. It applies to Codex, Claude Code, Cursor, Windsurf and any other agent.

## What this project is

A Roblox action RPG built by a parent and child. Players pick a path (Yodha warrior or Rishi caster), fight enemies inspired by Indian folklore, level up, spend stat points and take on a boss. The world and characters are original. Do not copy characters, names or assets from other games or anime.

Working title: **Asura Hunt** (can be renamed). Full design and roadmap: `docs/GAME_DESIGN.md`.

## How the project is built

- Language: **Luau** with `--!strict` at the top of every file.
- Code lives in plain `.luau` files and is synced into Roblox Studio with **Rojo** (`default.project.json`).
- The 3D world (map, models, lighting, UI layout) is built by hand in Studio. Rojo only syncs scripts, so never try to generate map geometry as code unless asked.

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
rojo sourcemap default.project.json -o sourcemap.json   # for luau-lsp
```

## Definition of done

Before saying a task is finished:

1. `stylua src` and `selene src` run clean.
2. `rojo build -o build/AsuraHunt.rbxl` succeeds.
3. You listed what must be playtested in Studio. If you could run the game yourself, say what you checked; if you could not, say plainly what is untested. Either way, name what the human should check by hand.
