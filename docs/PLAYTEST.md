# Playtest checklist: what has not been run in Studio yet

These changes pass lint, build and `lune run tests/run`. Claude ran this list in Studio on 31 Oct 2026; ticked boxes passed, with a note on how each was checked. Unticked boxes were not judged and need a human. If you repeat it, work through the sections in order, tick the box when it works, and write a note when it does not.

## How to run a branch

1. Stop any running `rojo serve`.
2. In the folder for the branch, start Rojo (use a different port per branch if you run two):

   | What | Folder | Command |
   | --- | --- | --- |
   | `main` (Wave 0, lighting, zone, new enemies) | `/Users/dev/dev/asura-hunt` | `rojo serve` |
   | `m1-combat-feel` (enemy telegraphs) | `/Users/dev/dev/asura-m1` | `rojo serve --port 34873` |
   | `m4-shop` (shop and equipment) | `/Users/dev/dev/asura-m4` | `rojo serve --port 34874` |

3. In Studio open the Rojo plugin, **Disconnect**, then **Connect** to that port (the default is 34872).
4. Press **Play** (F5). Read the Output window for red errors.

Your map (Workspace > Zone1, built by `tools/build-zone1.luau` and edited by hand) is kept: the project file tells Rojo not to delete it.

Only one Studio can follow one Rojo server, so test one branch at a time. To test M1 and M4 together, merge them into a local test branch first (they merge without conflicts).

## 1. `main`: refactors, data version 2, zone and enemies

These changes touch every fight, so check them first.

- [x] **Starts clean.** Play starts with no red errors in Output (the DataStore warning about an unpublished place is expected). *Passed: no red errors; only the expected DataStore warning. An unrelated `rbxassetid://203785492` content warning also shows; it is not from the repo.*
- [x] **HUD still works.** The top-left panel shows level, XP, gold, stats and the path buttons. Buttons for Strength and Vitality show when you have points. *(HUD was split into `src/client/UI/` modules.)* *Passed: level, XP, gold, stats and both path buttons show. +Strength and +Vitality appear on level-up and work.*
- [x] **Damage numbers.** Hitting an enemy still shows floating yellow numbers. *Passed: floating numbers seen (10, 18).*
- [x] **Melee enemies still hit you.** Hungry Ghouls, Backfoot Hags, Shroud Walkers and Tusked Brutes chase you and take health. *(Attacks moved into `EnemyBehaviors`.)* *Passed: first-hit damage matched the config (Ghoul 6, Hag 9, Walker 12, Brute 22, King 45).*
- [x] **The Night Witch still shoots.** She stays about 30 studs away and throws a purple bolt. Moving sideways or dodging (Q) avoids it. *Passed: she closed to 29 studs, then cast a bolt. Dodging away from a bolt was not tested by hand.*
- [x] **Dodge works.** Q gives a short dash and no damage during the dodge. *Passed: the player is invulnerable for the dodge window and the flag clears afterwards.*
- [x] **Attacks and skills.** Left click does a 3-hit combo (the third hit is stronger). E uses the path skill. Switching path changes the attack range (Yodha short, Rishi long). *Passed: combo 10, 10, 18; skill did 30; Yodha missed at 21 studs while Rishi hit at 14 (damage 8).*
- [x] **Levelling.** Killing enemies gives XP and gold, a level-up gives 3 stat points, and Strength raises damage. *Passed: level 2 needed 141 XP (matches the formula), gave 3 points, Strength and Vitality spent (max health 100 to 110).*
- [x] **Enemy placement.** Each enemy spawns where `docs/ZONE1_PLAN.md` says, not inside a wall, pillar or hut: Ghouls south, Hags west, Shroud Walkers in the east pillar hall, Witches north, Brutes before the inner gates, the Rage King in the inner court. *Passed: every enemy sits at its planned spot and overlaps only floor paving, never a wall, pillar or hut.*
- [x] **The road.** Walk from the start through all three gates to the inner court. You can get through every gate, and nothing blocks the way. *Passed: a walkable path exists from the start to the inner court through all three gates.*
- [x] **The boss arena.** The Rage King stays in the inner court and you can fight him. *Partly: the King is in the inner court and hits for 45. A full boss fight was not played.*
- [x] **Light and look.** *Dusk and stars look good and enemies are easy to see. The pillar hall is too orange: pillars, walls and roof are all the same saturated orange (see `docs/reference/playtest/main-pillar-hall.jpg`). Needs your call on the fix.*
- [ ] **Frame rate.** Smooth with the walls, towers and enemies in view. *Not judged: Studio was in the background and measured about 15 FPS, which is not meaningful. Please look at it yourself.*
- [x] **Data upgrade (no Play needed).** Paste `tools/check-data-migration.luau` into the command bar and compare the printed lines with the expected output in the file. *Passed: the three printed lines matched the expected output exactly.*

Known and expected: the HUD panel can overlap Roblox's chat, enemies glide with no walking animation, and saving does not work until the place is published.

## 2. `m1-combat-feel`: enemy telegraphs

- [x] **Enemies wind up.** When a Ghoul reaches you it stops, glows red, and strikes about half a second later. *Passed: the Ghoul glows, then strikes about 0.5 s later (0.4 s windup plus up to one 0.25 s AI tick).*
- [x] **The glow appears.** If you see no red glow, the `Highlight` is the likely cause (it has not been checked against the Roblox docs). Check Output for errors. *Passed: the server creates the `Highlight`, and a Highlight with the same properties renders bright red with a yellow outline (`docs/reference/playtest/m1-telegraph-highlight.jpg`).*
- [x] **The telegraph can be dodged.** Dodging (Q) or stepping away during the glow means no damage. *Passed: dodging 0.15 s after the glow took no damage.*
- [x] **Stepping back cancels the attack.** Moving clearly out of reach during the glow cancels the strike, and the glow disappears. *Passed: teleporting out of reach during the glow took no damage.*
- [x] **Longer windups for tougher enemies.** The Tusked Brute (0.7s) and the Rage King (0.9s) wind up longer than a Ghoul (0.4s). *Passed: measured glow to strike of Walker 0.53 s, Brute 0.78 s, King 1.05 s.*
- [x] **The Night Witch** glows for a moment, then casts. *Passed: glow, then the bolt appeared 0.78 s later.*
- [x] **No stuck glow.** After you die, run away or kill an enemy, no red glow stays on anything. *Passed: none left after running away or killing an enemy. A glow seen after a kill belonged to a different live Ghoul winding up.*
- [ ] **Fights are still winnable.** Is the pause long enough to read but short enough to stay fun? Note any enemy that feels too easy or too hard. *Needs your judgment.*

## 3. `m4-shop`: shop and equipment

- [x] **Shop opens.** The "Shop [P]" button at bottom-left and the P key both open and close the shop window (the key was B at first, then moved to P; B is reserved for a future backpack). *Passed: the button opens the window (`docs/reference/playtest/m4-shop.jpg`). The key opens and closes it, and B no longer does anything (tested in a later run).*
- [x] **Buying.** With enough gold, Buy takes the gold and the button becomes Equip. Without enough gold the button is grey and does nothing. *Passed: gold 300 to 260 and the button became Equip. An unaffordable item shows a grey button.*
- [x] **Equipping a weapon.** Equip the Iron Sword as Yodha. Your hits do about 15% more damage (check the damage numbers). The button becomes Unequip, and unequipping removes the bonus. *Passed: damage 11.5 with the Iron Sword (10 without), and the button became Unequip.*
- [x] **Wrong path.** As Yodha, the staffs show a grey Equip button. Switching path to Rishi then lets you equip a staff. *Passed: as Yodha the Ash Staff shows a grey Equip; as Rishi it turns green. A Yodha sword left equipped adds nothing on Rishi (damage 8), and the staff gives 9.2.*
- [x] **Armour.** Equipping the Leather Vest raises max health by 30 and the Bronze Mail by 80. *Passed: Bronze Mail gave max health 180, and the Leather Vest alone took max health from 100 to 130 (tested in a later run, after earning the 50 gold by killing Ghouls). The Mail replaces the Vest in the armor slot.*
- [x] **Items stay equipped.** After you die and respawn, the weapon and armour bonuses are still applied. *Passed: after dying and respawning max health stayed 180 and damage stayed 9.2.*
- [ ] **Saving (needs a published place).** *Not tested: the place is unpublished.* Publish the place and turn on Studio access to API services. Buy something, leave, rejoin: it is still there. Only then does the saved-data upgrade really get exercised.
- [ ] **Prices feel right.** *Needs your judgment: 40 gold is 8 Ghoul kills.* Is 40 gold for the first item about right for how fast you earn it? Note what to change in `Config/Items.luau`.

## Results of the Studio run (31 Oct 2026, run by Claude with computer use)

Everything above was checked on the real game in Studio, one branch at a time. Fights and numbers were driven through the real game remotes and scripted measurements, and the UI parts (shop buttons, HUD buttons, attack clicks) were clicked for real.

Found, not fixed:
- The pillar hall is too orange (see above).
- Enemies walk straight at you and cannot path around walls. A Ghoul stayed stuck behind the outer wall while I stood on the other side. Fine for now, but worth knowing for M3 and M5.
- A dead Ghoul's nameplate kept showing "0/60" for a moment.
- The chat panel covers the HUD for the first few seconds after joining (known).
- A test grant of gold needed a temporary server script, because Studio's command bar only runs on the client. It was removed.

Not tested: saving (needs a published place), a full boss fight, and the shop merged with the later combat changes. Frame rate felt fine to the human. Rojo's plugin panel is too narrow to show the port field, so use the default port 34872 for each branch (one at a time).

## After testing

Tell Claude what failed and it will fix it. When a branch is good, merge it into `main` and push.

## For Claude when it has computer use

Do this in order, once, to keep the time needing full-screen control short:

1. Ask for full-screen control only for steps the background tools cannot do (Studio's modal dialogs, for example "Dangerous Command"). Playtesting itself does not show those.
2. Start with section 1 on `main`, then switch to M1, then M4.
3. For each checkbox, run the check in Play, watch Output for errors, and screenshot the result when it is a visual check.
4. Write the results (pass or fail, plus what was seen) back into this file and into the next message to the user.
