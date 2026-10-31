# Enemy look feedback

Use this page to write down what you want changed. Fill in the notes under each enemy, save the file, and tell Claude "read docs/ENEMY_FEEDBACK.md and apply it".

## How to look at each enemy

1. Run `rojo serve` and click **Connect** in the Rojo plugin in Studio.
2. Open **View > Command Bar**, paste the contents of `tools/enemy-gallery.luau` and press **Run**. (Studio asks about a "Dangerous Command"; press **Continue**.)
3. Every enemy stands on its own pedestal, smallest to biggest, with a label. Orbit with right-click drag, zoom with the scroll wheel.
4. To study one enemy, change `local FOCUS = nil` at the top to for example `local FOCUS = "Chudail"` and run it again.
5. **Click any piece** and read its name in the Explorer panel (for example `HairL3`, `Horn2R`, `ArmletL`). Quoting that name tells Claude exactly which piece you mean.
6. After a change, save the file and run the gallery again. It rebuilds from the latest code.

Enemy ids: `Pishacha`, `Vetala`, `Chudail`, `Daayan`, `Rakshasa`, `Krodha`.

## Tips for useful feedback

- Say what you want to *see*, not just what is wrong: "long flowing hair" beats "hair is bad".
- Name a piece (`Hair`, `Horn`, `Eye`) or a part of the body (head, hands, feet).
- Compare to something: "bigger like a bull's horns", "thin like a stick insect".
- Say what to **keep**. It stops Claude changing the parts you like.
- Mention the view: front, side, back, far away or close up.
- A drawing, a photo or a link to a picture of the folklore creature is the best reference of all. Put it in `docs/reference/` and name the file here.

## Claude's own notes (to start the conversation)

- Hair is the common thread: every enemy uses the same "strand" shape for hair (a curved, tapering line). Only the direction changes. That is probably why they feel alike.
  - Pishacha: matted strands drooping from the top of the head
  - Vetala: strands standing up, then falling
  - Chudail: long strands down the back, plus two locks by the face
  - Daayan: long grey strands down the back (like the Chudail's, but grey)
  - Rakshasa (Tusked Brute): strands swept back
  - Krodha (Rage King): no hair, a mane of flame and a crown instead
- Heads are all one rounded blob with the same eye, brow and mouth layout.
- Skin colours: pale grey (Pishacha, Vetala, Chudail), tan (Daayan), blue (Brute) and red (King).
- Brute and King share one body but wear different armor: leather and bronze with a spiked club, versus black iron and gold with a great axe.

## Pishacha ("Hungry Ghoul")

Keep:

Change:

Reference ideas:

## Vetala ("Shroud Walker")

Keep:

Change:

Reference ideas:

## Chudail ("Backfoot Hag")

Keep:

Change:

Reference ideas:

## Daayan ("Night Witch")

Keep:

Change:

Reference ideas:

## Rakshasa ("Tusked Brute")

Keep:

Change:

Reference ideas:

## Krodha ("The Rage King", boss)

Keep:

Change:

Reference ideas:

## Across all enemies

Things to make more different from each other (hair, faces, shapes, colours, size):

Anything missing (animations, glow, particles):
