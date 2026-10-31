# Zone 1: the fortress-city

A ruined walled city at dusk, laid out as rectangles inside rectangles, each with a tall gate tower in the middle of every side. A straight road runs from the outer south gate through every gate to the centre, where the Rage King waits in the inner court.

The plan is inspired by the layout of the great South Indian temple cities. It is an original place. It has no shrine, idols, deities or sacred symbols, and it does not copy any real building (AGENTS.md rule 10).

## Map sketch

Top of the sketch is far (negative Z). The centre of the compound is (0, -110).

```
            Z=-210   +---------------- outer wall ---------------+
                     |  N corridor: Night Witches, huts          |
            Z=-182   |  +-------------- middle wall -----------+ |
                     |  |  N inner corridor: Tusked Brute (2nd)  | |
            Z=-150   |  |  +----------- inner wall ---------+  | |
  W corridor         |  |  |                                |  | |  E corridor
  market, banyan,    |  |  |   INNER COURT: Rage King       |  | |  pillar hall,
  Backfoot Hags      |  |  |   (0,-132), water tank (0,-98) |  | |  Shroud Walkers
            Z=-70    |  |  +---------------- gate ----------+  | |
                     |  |  S inner corridor: Tusked Brute (1st)  | |
            Z=-38    |  +---------------- gate ---------------+ |
                     |  S corridor: Hungry Ghouls, wells         |
            Z=-10    +---------------- gate -------------------+
            Z=0                      START (0,0)
```

Gate towers stand in the middle of every wall. Walls: outer x -120..120, middle x -84..84, inner x -50..50.

## Where the enemies live

The positions are `DEFAULT_SPAWNS` in `EnemyService`.

| Place | Enemy | Spawns (x, z) |
| --- | --- | --- |
| South corridor and east end | Hungry Ghoul | (-60,-24), (60,-24), (100,-52) |
| West corridor, under the banyan | Backfoot Hag | (-100,-90), (-100,-150) |
| East corridor, in the pillar hall | Shroud Walker | (97,-115), (97,-165) |
| North corridor, by the huts | Night Witch | (-60,-196), (60,-196) |
| Inner corridors, in front of the inner gates | Tusked Brute | (0,-54), (0,-166) |
| Inner court | Rage King | (0,-132) |

Players meet easy enemies first, then spread out to the side corridors, then face the Brutes at the inner gates before the boss.

## What is built

`tools/build-zone1.luau` builds a starter version of everything below in Workspace > Zone1 (about 1,100 pieces):

- Three nested walls with gaps for gates, capped with a ledge and blocks
- Twelve stepped gate towers with painted bands, window slots and barrel roofs: tall for the outer ring, smaller further in
- A paved axis road from the start to the centre
- A pillared hall (36 pillars with a roof) in the east corridor
- A ruined market and a great banyan tree in the west corridor
- Round mud huts and purple lanterns in the north corridor
- Two wells and lanterns by the entrance
- A raised water tank with green water-lily pads in the inner court, and pillars either side
- Dead trees and rocks outside the walls, and rubble inside

The lighting is not in the script. It lives in `default.project.json` (dusk, haze, bloom) and syncs with Rojo.

## Things to decide and build by hand

- A name for the city and the great gate towers
- Better details: window shapes, carved patterns (keep it free of sacred symbols), banners
- Towers you can climb? A rooftop fight?
- Make the pillar hall a bit less orange (fewer or dimmer lanterns)
- Sounds: night crickets, wind, a distant bell (check Roblox's audio rules before publishing)
- A sky you like. The default sky is used for now
- Spawn points you place yourself (tag a Part `EnemySpawn` with an `EnemyId` attribute). Once any exist, the built-in positions are ignored

## Playtest checklist

1. Spawn at the start and look down the road: can you see the gates in a line?
2. Walk to the centre: do you pass the Brute before the boss?
3. Does each enemy appear where the table above says, not inside a wall or pillar?
4. Is the east pillar hall too orange or too dark to fight in?
5. Does the Rage King fight stay inside the inner court?
6. Does the frame rate stay smooth with the walls, towers and enemies in view?
