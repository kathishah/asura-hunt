# Asura Hunt: game design

Working title. Rename it together.

## Pillars

1. **Satisfying combat loop:** fight, get loot and XP, get stronger, fight tougher things.
2. **An original world:** inspired by Indian folklore, with our own characters, places and story.
3. **Built together:** the kid is co-designer and tester, so keep systems simple enough to explain and change.

## Core loop

Grind enemies in a zone, level up, spend stat points, buy better gear (later), beat the zone boss, unlock the next zone.

## Paths

| Path | Style | Basic attack | Skill |
| --- | --- | --- | --- |
| Yodha | Melee warrior | 3-hit combo, short range | Jwala Slash: wide, powerful arc |
| Rishi | Mantra caster | Ranged, weaker damage | Mantra Bolt: long, narrow, strong bolt |

All numbers live in `src/shared/Config/Paths.luau`.

## Enemies (folklore-inspired creature types)

| Name in game | Folklore name | Role | Notes |
| --- | --- | --- | --- |
| Hungry Ghoul | Pishacha | Weak grunt | Teaches basic combat |
| Backfoot Hag | Chudail | Fast ambusher | Ghost of a woman with backwards feet; outruns a walking player |
| Shroud Walker | Vetala | Mid-tier | Faster, hits harder |
| Night Witch | Daayan | Ranged caster | Stops far away and throws a dodgeable curse bolt |
| Tusked Brute | Rakshasa | Elite | Tough zone guardian |
| The Rage King | Krodha | Boss | Original character; huge health pool |

Naming: players see an easy English name with the folklore name in small text beneath it. Code ids stay as the folklore name. Planned later: a female warrior "Ogre Queen" (Rakshasi) so the female enemies are not all hags.

Content guidelines: use creature types from folklore. Do not use gods or goddesses (including forms such as Mohini), semi-divine beings (Yakshini, Naga, Dakini) or named characters from the epics as enemies, and avoid religious symbols as decoration or jokes. Keep it appropriate for a young audience and check Roblox's Community Standards before publishing.

## Progression

- XP curve: `floor(50 * level^1.5)` per level (see `GameConfig.xpToNextLevel`)
- 3 stat points per level: Strength (+5% damage each) and Vitality (+10 max health each)
- Max level 50 for now

## Roadmap

| Milestone | Goal | Status |
| --- | --- | --- |
| M0 | Project skeleton, combat, enemies, saving, HUD | Done (needs first playtest) |
| M1 | Combat feel: animations, hit effects, sounds, enemy attack telegraphs | Next |
| M2 | First zone: build the map in Studio, place spawn points, lighting | In progress: starter village built (see `docs/ZONE1_PLAN.md`) |
| M3 | Boss fight: attack patterns, boss health bar, reward drops | |
| M4 | Gold sink: shop for weapons and armour, equipment stats | |
| M5 | Second zone and new enemy types | |
| M6 | Polish and publish: tutorial, settings, privacy and safety review | |

## Ideas to decide with your son

- A real name for the game and the world
- The story: why are these creatures attacking, and who are the heroes?
- Names and looks for new enemies and bosses
- Which weapons feel cool? (sword, bow, staff, chakram)
- What should the first zone look like? (village, forest, temple ruins, cave)
- What should the next path be?

## Later: before publishing

Roblox has rules around monetization, chat, data collection and child safety. Review the current Roblox Creator documentation before enabling purchases or publishing publicly.
