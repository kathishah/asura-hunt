# Zone 1: the haunted village

A village on the edge of a forest, at dusk, with an old fort at the far end. Players start in the middle, follow the dirt road north-to-south (towards negative Z) and fight tougher creatures the further they go. The Rage King waits in the fort.

No temples, shrines or religious symbols (AGENTS.md rule 10). The fort is a plain stone fort.

## Map sketch

Top of the sketch is far (negative Z). Each unit is about 20 studs.

```
                      Z = -175   [ tower ] [  gate  ] [ tower ]
                                 old fort wall, broken lintel
                      Z = -150          ( ARENA )  Rage King (Krodha)
                      Z = -125          road lanterns
   Chudail grove      Z = -100   (30,-100) dead trees + ruined hut
                      Z =  -66   well, scarecrow
 Banyan tree          Z =  -60   Shroud Walker (0,-60)
 Chudail (-60,-50)    Z =  -50
                                 Night Witch (90,-40)  ruined hut
   Hungry Ghoul (-40,0)  ----- start (0,0) -----  Hungry Ghoul (40,0)
   huts and well                                  huts and well
   Hungry Ghoul (0,40)
   Night Witch (-70,50)   witch corner, purple lanterns
                      Z =  60   Shroud Walker (60,60)  ruined hut
   Tusked Brute (-90,90)  stony hollow
```

Hungry Ghouls are the first fights because they are closest to the start. The road heads towards the fort, past the Shroud Walker and the grove.

## What is built

`tools/build-zone1.luau` builds a starter version of everything below in Workspace > Zone1:

| Landmark | Where | Notes |
| --- | --- | --- |
| Dirt road | from the start down to the fort | Lanterns glow along it |
| Round mud huts | around the start | Stepped thatch roofs, lantern at the door |
| Ruined huts | (68,68), (100,-50), (18,-112) | Just low walls and rubble |
| Wells | (14,-14), (6,-66) | |
| Great banyan tree | (-68,-58) | The Backfoot Hag lives under it |
| Dead tree grove | around (30,-100) | Second Backfoot Hag |
| Witch corner | around (-80,55) | Leaning hut, purple lanterns, herb poles |
| Stony hollow | around (-90,90) | Boulders for the Tusked Brute |
| Scarecrow | (-10,-64) | Near the Shroud Walker |
| Old fort | z = -125 to -175 | Arena floor, walls, towers, broken gate |

The lighting is not in the script. It lives in `default.project.json` (dusk, haze, bloom) and syncs with Rojo.

## Things to decide and build by hand

- A name for the village and the fort
- Better huts: windows, doors, a roof you like more
- A river or a field? Props that tell a story (a cart, broken fences, washing lines)
- Sounds: night crickets, wind, a distant bell (check Roblox's audio rules before publishing)
- A sky you like. The default sky is used for now
- Spawn points you place yourself (tag a Part `EnemySpawn` with an `EnemyId` attribute). Once any exist, the built-in positions are ignored

## Playtest checklist

1. Spawn in the middle and look around: is it too dark to see enemies?
2. Walk the road: can you reach the fort without getting stuck?
3. Does each enemy appear where you expect, not inside a hut or wall?
4. Does the Rage King fight stay inside the arena?
5. Does the frame rate stay smooth with the village and all enemies in view?
