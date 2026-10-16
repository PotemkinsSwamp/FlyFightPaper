# Core: start-up and shared plumbing

## What the player sees
Nothing directly. This is the code that starts every other system when a server or a player's game opens, and the
small shared helpers they all use.

## Where it stands (2026-10-15)
Works. On start, the server moves unused saved art into `ServerStorage.DormantArt` so it isn't sent to players.

## Rules
- The server makes every final decision (hits, points, purchases); clients only draw and send input. See
  [Glossary](../GLOSSARY.md) ("Server / client").
- Every value from a client is checked before use (finite numbers, valid vectors).

## Code
| File | What it does |
|---|---|
| `src/server/Bootstrap.server.luau` | Server start: tidies the workspace, creates every service, wires flight, combat and rounds together |
| `src/client/Bootstrap.client.luau` | Player start: loading screen, starts every client module, attaches your plane, HUD, camera and combat |
| `src/shared/MathUtil.luau` | Strict number and vector checks used to reject bad input |

## Tuning numbers
`config/server.json` `round`, `match_limits`.

## Related
- [Studio and Rojo](../workshop/studio-and-rojo.md) (where each code folder ends up in Studio)
- [Performance](performance.md) · [Saving](saving.md)

Back to [HOME](../HOME.md)
