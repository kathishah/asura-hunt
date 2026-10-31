# Roadmap: how to build M1 to M6

Short plans for each milestone, then how to run them in parallel with separate branches and agents. The one-line goals are in `docs/GAME_DESIGN.md`. Read `AGENTS.md` first: server authority, tuning in `src/shared/Config`, one feature per change.

## The milestones

### M1: Combat feel
**Goal:** fights feel good. Hits have weight, enemies warn before they strike.

- **Enemy telegraphs:** add `attackWindup` (seconds) to `EnemyDef` and `Enemies.luau`. In `EnemyService`, an enemy first winds up (glowing eyes or a red ground ring), and damage lands only at the end if you are still in range. Dodging in the window works.
- **Hit effects:** the server tells clients "a hit landed" (new remote `HitEffect`). The client shows a spark, flashes the enemy and gives a small screen shake. Floating damage numbers already exist.
- **Animations:** the demons are welded parts with no rig, so animate them in code by tweening each part's `Weld.C0` (walk sway, attack lunge, death collapse). Player attack animations need Animation assets: ids go in a new `Config/Animations.luau`.
- **Sounds:** a new `Config/Sounds.luau` holds the sound ids (hit, swing, dodge, level up, enemy windup).

**Touches:** `EnemyService`, `CombatService`, `Remotes`, `Types` (`EnemyDef`), `Config/Enemies`, new `src/client/UI/Effects.luau`, new `Config/Sounds`, `Config/Animations`.
**Needs from you:** pick sounds from the Creator Store (check the licence), upload or pick player animations.
**Built so far (branch `m1-combat-feel`):** enemy telegraphs. Each enemy has `attackWindup` in `Config/Enemies.luau`. When it is in reach and its attack is ready it stands still and glows red (a Roblox `Highlight`, which has not been checked in Studio), then strikes. If you step out of reach or die during the windup, the attack is cancelled. The timing is in `Services/AttackTiming.luau` and is tested with `lune run tests/run`. **Still to do:** hit effects, animations and sounds, which need your choices and assets.
**Done when:** a Hungry Ghoul visibly winds up, a dodge in the window avoids the hit, and every hit has a sound and a flash.

### M2: First zone (in progress)
**Goal:** a map worth fighting in. See `docs/ZONE1_PLAN.md`. The map is hand-built in Studio, so it is mostly yours to polish. Done when the playtest checklist there passes.

### M3: Boss fight
**Goal:** the Rage King is a real fight, with phases and a reward.

- **Attack patterns:** a new `Config/Bosses.luau` lists attacks (ground slam ring, charge, summon Hungry Ghouls) and phases (at 66% and 33% health). A new `BossService` runs them. Each attack uses the M1 telegraph.
- **Boss health bar:** a new remote `BossState`, drawn by a new `src/client/UI/BossBar.luau`.
- **Rewards:** a burst of gold and XP, and a guaranteed item once M4 items exist.
- **Arena:** the boss stays in the inner court and resets if you leave or die.

**Touches:** new `BossService`, `Config/Bosses`, `EnemyService` (a hook for boss behaviour), `Remotes`, `Types`, new client `BossBar`.
**Needs from you:** what the three attacks look like, and the boss's phase speech or sounds.
**Depends on:** M1 (telegraphs). The item reward depends on M4.
**Done when:** a player who dodges the slams beats the King, and the health bar and phase changes show.

### M4: Shop and equipment
**Goal:** gold buys things, and things change your stats.

- **Items:** new `Config/Items.luau` with weapons (sword, bow, staff, chakram) and armour. Each has a price and stats (damage multiplier, health, range).
- **Player data:** `inventory` and `equipped` already exist in `PlayerData` (Wave 0). Use them; add any new fields with a version bump and migration (AGENTS.md rule 8).
- **Server logic:** a new `ShopService` buys items (server checks gold and the item id) and an `EquipmentService` applies stats. `CombatService` reads the equipped weapon when it works out damage.
- **Shop screen:** a new `src/client/UI/Shop.luau`, opened by walking up to a shopkeeper in the map. The shopkeeper is placed by hand in Studio.

**Touches:** `Types` (`PlayerData`, new `ItemDef`), `DataService`, `CombatService`, `GameConfig`, `Remotes`, new services, new client `Shop`.
**Needs from you:** which weapons are cool, names and prices, where the shop stands.
**Done when:** you can buy a sword with gold, equip it, see your damage go up, quit, rejoin and still have it.

### M5: Second zone and new enemies
**Goal:** more to explore, and more kinds of fight.

- **Zones as data:** a new `Config/Zones.luau` (id, name, level needed, spawn list, entry point). `EnemyService` takes its spawns from the zone, not one fixed list. A new `ZoneService` moves you between zones through tagged portal parts.
- **Progress:** use the existing `unlockedZones` in `PlayerData` (zone 1 starts unlocked).
- **New enemies:** two or three, each with a stats entry in `Config/Enemies.luau` and a look in `Config/EnemyLooks.luau`. Pick folklore creatures with your son (for example a Kuttichathan, the mischievous imp of Kerala folklore). Check each against AGENTS.md rule 10: no gods, semi-divine beings or sacred symbols.
- **Map:** zone 2 is hand-built in Studio, like zone 1.

**Touches:** `Types`, `Config/Enemies`, `Config/EnemyLooks`, `EnemyService`, `DataService`, new `Config/Zones`, new `ZoneService`.
**Needs from you:** the zone 2 theme (forest, cave or river), the new creatures.
**Depends on:** M2 done. Unlocking zone 2 reads naturally off the M3 boss kill.
**Done when:** beating the Rage King opens a portal to zone 2, and its enemies spawn there, not in zone 1.

### M6: Polish and publish
A tutorial, settings, a privacy and safety review, and a Roblox policy check. Plan it after M3 to M5 land.

Wave 0 and the first parts of M1 and M4 are built but not yet playtested. What to check is in `docs/PLAYTEST.md`.

## Can they run in parallel?
Mostly yes, but a few shared files will cause merge conflicts. These are the hotspots:

| File | M1 | M3 | M4 | M5 |
| --- | :-: | :-: | :-: | :-: |
| `EnemyService.luau` | x | x | | x |
| `Types.luau` | x | x | x | x |
| `Remotes.luau` (one list) | x | x | x | x |
| `HUD.luau` (and new client files) | x | x | x | |
| `DataService.luau` / `PlayerData` | | | x | x |
| `Config/Enemies.luau` | x | x | | x |
| Studio map (not in git) | | | shopkeeper | zone 2 |

Dependencies: M3 needs M1's telegraphs. M3's item reward and M5's unlock both want the data and item changes. The Studio map is one place file, so only one person edits it at a time.

### Plan: prep, then waves
**Wave 0: one small prep change** (do it first and alone). Done, but not yet playtested in Studio:
- Enemy attacks now live in `src/server/Services/EnemyBehaviors.luau` (melee, projectile). A new attack style, such as a boss pattern, is a new function there plus `behavior = "name"` on the enemy. `EnemyService` only decides when to attack.
- `HUD.luau` is a small shell that starts every module in `src/client/UI/`. A new screen (shop, boss bar, effects) is a new file there with a `start(screen)` function. Nothing else changes.
- `PlayerData` is now version 2 and already has `inventory`, `equipped` and `unlockedZones`, with the migration. M4 and M5 fill these in and must **not** bump the version again unless the shape changes. A saved record from a newer version is never overwritten by older code, so branches can share a test account safely. Check the migration with `tools/check-data-migration.luau`.

**Wave 1: in parallel**
- M1 combat feel, on branch `m1-combat-feel`
- M4 shop and equipment, on branch `m4-shop`
- M5a new enemies: stats and looks only, no zone wiring, on branch `m5-enemies`
- You: M2 map polish and the shopkeeper spot

**Wave 2: after M1 is merged**
- M3 boss fight (can add item drops once M4 is merged)
- M5b zone data, portals and zone 2 (after M3, so the boss kill can unlock it)

**Wave 3:** M6.

**Merge order:** M1, then M4, then M5a, then M3, then M5b. Small changes merge cleanly, so keep each branch to one feature, and rebase on `main` before opening a pull request.

## How to run it with branches and agents
One agent per branch, each in its own folder (a git worktree), so they never overwrite each other:

```bash
git worktree add ../asura-m1 -b m1-combat-feel
git worktree add ../asura-m4 -b m4-shop
git worktree add ../asura-m5 -b m5-enemies
```

Each agent gets a short brief: "Read AGENTS.md and docs/ROADMAP.md. Implement milestone M1 only. Do not touch files outside the list. Run stylua, selene and rojo build before finishing, and list what the human must playtest." Tell each agent which files are theirs.

**Testing:** agents can lint, build and run `lune run tests/run` (install with `brew install lune`). The tests run the real modules against a fake Roblox, so they check saved data, config and server decisions but not how anything looks or feels. Agents should add a test file in `tests/cases/` for new logic (each feature gets its own file, so branches never edit the same test file). Playtesting needs Studio, and one Studio can only be connected to one `rojo serve` at a time, so you playtest one branch at a time: in that branch's folder run `rojo serve --port 34873` and connect the plugin to that port. Or merge to an integration branch and playtest everything together.

**Rules that keep it safe:**
- Each branch changes only its own files, plus the small shared spots above (a remote name, a type field).
- Never two agents on the Studio map.
- Merge through pull requests into `main`, one at a time, in the order above.
