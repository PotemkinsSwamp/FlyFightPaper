# Playtest 2026-10-21: the Hangar Tour (lesson 3)

Alan played the first build of the Hangar Tour from the Training board, then the Hangar after its fixes. What he
said and what changed. Plan: [tutorial plan](../plan/TUTORIAL-PLAN.md) "Lesson 3". System: [tutorial](../systems/tutorial.md).
Decision: [try on, then Select](../decisions/2026-10-21-hangar-try-on-select.md).

## First play
1. Step 4 named the stats without saying what they are. **Done:** one row at a time, kid words (1/6 ... 6/6). ✅
2. Step 11 lit the whole bottom of the page and described a red X that wasn't there. **Done:** pages for the Weight
   boxes, the click line, and a red X only when a card really has one (the Hangar swaps gear to fit, so it's rare). ✅
3. "Hit 3 targets" finished on one target hit three times. **Done:** 3 different targets. ✅
4. Alan: Claude should play it through too. **Done:** played three times in Studio; also fixed the note covering the
   gear cards, the name needing Ctrl+A to replace, Mount/spot words, skipping step 13 leaving the Hangar open. ✅

## Second play
5. The Range showed for a split second before the Hangar. **Done:** cork cover until the Hangar is open (1 frame in
   408 measured). ✅
6. Ding 20% quieter in the tour, and it came ~1.5 s after the click. **Done:** `softDing`, rings on the click. ✅
7. The Hangar lost its exact numbers. **Done:** number after each row. ✅
8. Changes compared to the saved build, not to what was last picked. **Done:** try on, then Select. Not yet seen by
   Alan.

## Third play (Customize)
9. Customize floated above the shelf. **Done:** it stands on the top board like the My builds tab.
10. Select broke gear ("you click on the number and then you press the gear"). **Done:** gear you own goes straight on;
    the tour's gear step no longer asks for Select.
11. A rename flashed back to "Preset 1" for a couple of seconds after Enter. **Done:** the typed name shows while it saves.
12. Customize still sat behind the shelf (the shelf was drawn over the page). **Done:** the page draws in front of it.
13. The three boosters didn't say how they differ. **Done:** each card says "+35% speed for 4 seconds" etc.

## Combat School (same sitting)
14. Mouse held still, the nose dot never reached the aim circle. Cause: the circle is drawn from the camera (above and
    behind), the nose flew the same direction from lower down. **Done:** the plane steers at the circle's spot at the
    dot's range ([flight](../systems/flight.md)).
15. Step 8's shooting Pal appeared ahead again. Likely cause: step 7's Pal came back (4 s) ahead of you before step 8
    began, and step 8 left a flying Pal where it was. **Done:** step 8 always places it afresh behind you, and the note
    says "An enemy is behind you, shooting!" while it is there.
16. While a note froze you, targets and their lead rings kept moving. **Done:** a target's sweep clock stops while held.
17. "Are all erasers slowed?" No: only the enemy's (80%, slower after each hit). Yours looked dodged because the Pal
    turned away from you every few seconds. **Done:** Pals keep their own heading (below).
18. Step 8 must always hit you from behind, then the Pal must be easy to kill (it circled you, a minute to kill).
    **Done:** fake shots from just behind you until half Health; every Pal runs nearly straight, 70% speed while you're
    far, 95% near.

## 2026-10-22
19. A lesson's end card couldn't be clicked: the plane kept flying with the mouse. **Done:** finishing freezes everything.
20. Combat School's end should offer the Hangar Tour. **Done:** "Next: Hangar Tour".
21. Step 8's Pal died too fast, no chase ("a little too dumb"; Health unchanged, half). **Done:** 85% far / 100% near,
    banks 25-50 degrees every 2.5-4 s.
22. INCOMING in step 8 (it shouldn't have an eraser). Cause: a Pal kept from another step kept its eraser. **Done:**
    refolded with the right weapon.
23. The Hangar Tour's last card needs dismissing. **Done:** click it or Space (the 7 s stays).
24. Step 8: no shots before you turned round (twice). Cause: they waited ~2-3 s after the note, and the "behind you"
    note came first, so you turned at once. **Done:** shots from 0.5 s after the note, from the Pal's side while it's out
    of view; the note names it only after a hit. Checked in Play: Health 120 to 70 in ~5 s while it sat behind.
25. INCOMING! in step 8 again. Cause: the ambush's pellets were given the player as a target, and a shot with a target
    steers and warns like an eraser (that steering was also why they hit). **Done:** only erasers keep a target; placed
    pellets are led instead. Checked in Play: no warning, Health 120 to 60 in ~4 s.
26. Esc in the Hangar Tour showed the Range instead of the Hangar. **Done:** the clipboard menu opens over the Hangar;
    Keep flying goes back to it. Checked in Play.
27. Should an eraser lock stay on after firing? Kept as is (it stays while the target stays in the circle; the next
    eraser fires when reloaded): Claude's recommendation, Alan to confirm.
28. A figure appeared with every Paper Pal. It was the seated pilot avatar every plane gets at its desk. **Done:** lesson
    planes (Pals, practice targets) get none. Checked in Play: only your own avatar is in the room.

Back to [playtests](README.md)
