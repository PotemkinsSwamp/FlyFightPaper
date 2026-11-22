# An emote's hands are placed by each body's own shape

**Decided:** 2026-11-21 (Alan: "go" to the plan in words; in Play afterwards: "ok its good")
**Status:** built for Good Game and approved by Alan in Play ([playtest](../playtests/2026-11-21-book-kicker-sound-and-good-game.md)).

## Decision
- Where a hand must be (meeting the other hand, beside the head) is worked out on each avatar from its own chest,
  head, hand and arm sizes, after the clip has posed the arm. The clip keeps the timing, the sway and the feel.
- A plain blocky body, on which the move was approved, is left as it was.
- Very short-armed or otherwise odd bodies stay an accepted loss ([the earlier ruling](2026-11-21-plane-stays-in-the-hand.md)).

## Why
A clip turns joints by fixed angles. On 7 of the 12 bots, all ordinary bodies, Good Game's wave put the hand on the
face or chest and the clap met off to one side for an instant. Which bots place 2nd and 3rd changes every match.

## How it is done
`goodGameArms` in `src/client/WinnersCutscene.luau`; the numbers and the checks: [emote making](../workshop/emote-making.md).
New emotes with a hand pose are measured on every bot's body before Alan sees them ([lesson](../workshop/lessons.md)).
