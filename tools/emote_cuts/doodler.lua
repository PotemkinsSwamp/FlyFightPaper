-- Doodler (docs/workshop/emotes/doodler.md; card OK'd by Alan 2026-11-24, the reference video OK'd the same day; remade
-- after his first look in Play the same day). The body clip is only the seat: generated clip Nap B sitting still
-- (Nap's N.rest, cross-legged, the same seat as Nap and So Close), held. Everything that moves (the chest hunched over
-- the notebook, the look at 1st, sitting up, the head tip) is turned by the scene's module
-- (src/client/emotes/Doodler.luau) every frame, so its timing can follow how long 1st's emote lets the runner-ups be
-- seen (Alan: "if the first place is one that shortens it, then the doodler needs to be shortened as well"), and the
-- arms are bent there onto the notebook and the pencil.
CUTS.Doodler = { length = 1, clips = { nap = N.clip }, pose = function(_t, c) return table.clone(c.nap(N.rest)) end }
