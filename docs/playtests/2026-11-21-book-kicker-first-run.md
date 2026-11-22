# Book Kicker: Alan's notes on the first run

**When:** 2026-11-21, Alan on Claude's muted Play recording of the first build (`.planning/emotes/book-kicker-first-run-cut.mp4`; the winner in it was a bot's avatar, a short girl). How the build works: [emote making](../workshop/emote-making.md).

## What he said, and what changes
The landing, the name plates and the pages were built the same day (second build: [emote making](../workshop/emote-making.md)); nobody has seen them move yet. Sound waits for the look.

| Alan | What changes |
|---|---|
| "her being shorter than the book stack is not really that much of a problem ... I don't mind that" | Nothing. The books keep their size. |
| "Her landing outside the spotlight, that is a problem, and she should be landing closer to the book ... so when she kicks it ... you can't see the tip of her foot because it's behind the box. Right now, it looks like she's kicking the air and the books are just flying." | The landing moves in: inside the spotlight's beam and close enough that the kicking foot's tip goes behind the stack as seen from the camera. Today she lands 0.65 winner heights to the side and 0.3 back (`KICK_SIDE`, `KICK_BACK` in `tools/emote_clips.lua`). |
| "The nameplates can't stay on top of the book when the book covers it. That's a big problem." | The three name plates go away while the book is on the lens. |
| "The open book being plain, that's a problem. We can fill it with fake scribbles to make it look like it's filled with stuff, but nothing actually legible." | The open book's pages get scribbled lines that look like writing and say nothing. |
| "The other 5 books, that's fine, them being only on screen for a couple seconds." | Nothing. |
| "We do need sound, and I think you can take sound from the Gemini video ... the kicking and the books flying ... And the books hitting the ground? And then maybe add a smack sound as well. Or maybe you could try to get Gemini to add audio to it ... But first you have to make the video good. And then we can have Gemini add audio to it." | Sound comes after the look is right. Then: Gemini adds audio to a recording of the finished emote (a paid call: his go, with its price), or the kick, the books and a smack are taken from a Gemini video's sound. Any sound used in the game is an upload to Roblox (his go). |

## Not said
- Whether the dismount now reads as a jump, and whether the kick itself (leg, timing) is right once the foot meets the stack: ask at his next look.
