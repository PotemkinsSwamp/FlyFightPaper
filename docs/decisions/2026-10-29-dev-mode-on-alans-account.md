# Dev mode on Alan's own account in the published game

**Decided:** 2026-10-29 (Alan)  
**Status:** in force (built 2026-10-29: server marks the game owner's account `Dev`; checked in Studio)

## Decision
Alan's own Roblox account gets the Studio test controls (end the match, modes, endings, the results card, the other
dev buttons) in live published servers, so he can test round ends and screens on his phone without waiting a whole
match. Only his account: every other player sees nothing, and the server refuses dev requests from anyone else.

## Why
Alan's phone run (2026-10-29): checking the results card and match tips on a real phone meant waiting ~10 minutes
per match, and his account has seen every match tip so it can't show them.

## Where it lives
Today the dev tools are Studio-only (`RunService:IsStudio()` in `src/client/DevTools.luau` and server gates).
The check must be on the server (the player's UserId), never trusted from the client. Playtest:
[2026-10-29](../playtests/2026-10-29-phone-run-published-fixes.md).

All decisions: [decisions](README.md)
