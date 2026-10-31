# Playtest checklist: what has not been run in Studio yet

These changes pass lint, build and `lune run tests/run`, but nobody has played them in Studio. Work through them in order. Tick the box when it works, and write a note when it does not.

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

Your hand-built map (Workspace > Zone1) is kept: the project file tells Rojo not to delete it.

Only one Studio can follow one Rojo server, so test one branch at a time. To test M1 and M4 together, merge them into a local test branch first (they merge without conflicts).

## 1. `main`: refactors, data version 2, zone and enemies

These changes touch every fight, so check them first.

- [ ] **Starts clean.** Play starts with no red errors in Output (the DataStore warning about an unpublished place is expected).
- [ ] **HUD still works.** The top-left panel shows level, XP, gold, stats and the path buttons. Buttons for Strength and Vitality show when you have points. *(HUD was split into `src/client/UI/` modules.)*
- [ ] **Damage numbers.** Hitting an enemy still shows floating yellow numbers.
- [ ] **Melee enemies still hit you.** Hungry Ghouls, Backfoot Hags, Shroud Walkers and Tusked Brutes chase you and take health. *(Attacks moved into `EnemyBehaviors`.)*
- [ ] **The Night Witch still shoots.** She stays about 30 studs away and throws a purple bolt. Moving sideways or dodging (Q) avoids it.
- [ ] **Dodge works.** Q gives a short dash and no damage during the dodge.
- [ ] **Attacks and skills.** Left click does a 3-hit combo (the third hit is stronger). E uses the path skill. Switching path changes the attack range (Yodha short, Rishi long).
- [ ] **Levelling.** Killing enemies gives XP and gold, a level-up gives 3 stat points, and Strength raises damage.
- [ ] **Enemy placement.** Each enemy spawns where `docs/ZONE1_PLAN.md` says, not inside a wall, pillar or hut: Ghouls south, Hags west, Shroud Walkers in the east pillar hall, Witches north, Brutes before the inner gates, the Rage King in the inner court.
- [ ] **The road.** Walk from the start through all three gates to the inner court. You can get through every gate, and nothing blocks the way.
- [ ] **The boss arena.** The Rage King stays in the inner court and you can fight him.
- [ ] **Light and look.** It is dusk with stars. Is it too dark to see enemies? Is the pillar hall too orange? (Tell Claude and it can adjust.)
- [ ] **Frame rate.** Smooth with the walls, towers and enemies in view.
- [ ] **Data upgrade (no Play needed).** Paste `tools/check-data-migration.luau` into the command bar and compare the printed lines with the expected output in the file.

Known and expected: the HUD panel can overlap Roblox's chat, enemies glide with no walking animation, and saving does not work until the place is published.

## 2. `m1-combat-feel`: enemy telegraphs

- [ ] **Enemies wind up.** When a Ghoul reaches you it stops, glows red, and strikes about half a second later.
- [ ] **The glow appears.** If you see no red glow, the `Highlight` is the likely cause (it has not been checked against the Roblox docs). Check Output for errors.
- [ ] **The telegraph can be dodged.** Dodging (Q) or stepping away during the glow means no damage.
- [ ] **Stepping back cancels the attack.** Moving clearly out of reach during the glow cancels the strike, and the glow disappears.
- [ ] **Longer windups for tougher enemies.** The Tusked Brute (0.7s) and the Rage King (0.9s) wind up longer than a Ghoul (0.4s).
- [ ] **The Night Witch** glows for a moment, then casts.
- [ ] **No stuck glow.** After you die, run away or kill an enemy, no red glow stays on anything.
- [ ] **Fights are still winnable.** Is the pause long enough to read but short enough to stay fun? Note any enemy that feels too easy or too hard.

## 3. `m4-shop`: shop and equipment

- [ ] **Shop opens.** The "Shop [B]" button at bottom-left and the B key both open and close the shop window.
- [ ] **Buying.** With enough gold, Buy takes the gold and the button becomes Equip. Without enough gold the button is grey and does nothing.
- [ ] **Equipping a weapon.** Equip the Iron Sword as Yodha. Your hits do about 15% more damage (check the damage numbers). The button becomes Unequip, and unequipping removes the bonus.
- [ ] **Wrong path.** As Yodha, the staffs show a grey Equip button. Switching path to Rishi then lets you equip a staff.
- [ ] **Armour.** Equipping the Leather Vest raises max health by 30 and the Bronze Mail by 80.
- [ ] **Items stay equipped.** After you die and respawn, the weapon and armour bonuses are still applied.
- [ ] **Saving (needs a published place).** Publish the place and turn on Studio access to API services. Buy something, leave, rejoin: it is still there. Only then does the saved-data upgrade really get exercised.
- [ ] **Prices feel right.** Is 40 gold for the first item about right for how fast you earn it? Note what to change in `Config/Items.luau`.

## After testing

Tell Claude what failed and it will fix it. When a branch is good, merge it into `main` and push.

## For Claude when it has computer use

Do this in order, once, to keep the time needing full-screen control short:

1. Ask for full-screen control only for steps the background tools cannot do (Studio's modal dialogs, for example "Dangerous Command"). Playtesting itself does not show those.
2. Start with section 1 on `main`, then switch to M1, then M4.
3. For each checkbox, run the check in Play, watch Output for errors, and screenshot the result when it is a visual check.
4. Write the results (pass or fail, plus what was seen) back into this file and into the next message to the user.
