# Glossary

Plain-English meanings for words used in these docs. Add a word the first time a page needs it.

## Game words
- **Fold:** the game's word for a kill. **Fold assist:** helping a fold by doing at least 10% of the victim's health in the last 10 seconds.
- **Lift:** your plane's staying-up power. Flying drains it; at zero you glide down but can still steer. Fans refill it.
- **Paper:** the in-game money. **XP:** experience points that raise your level.
- **Refold:** paying Paper at your desk to rebuild your plane fully and keep your streak. A free **fresh plane** ends the streak.
- **Protection:** up to 120 seconds per life when parked at a desk during which you can't be hurt (or shoot).
- **Mount:** a spot on a plane where a weapon goes (light, medium or heavy). **Capacity:** how much weight of weapons a body carries.
- **Airspace Control:** the team mode where you hold a moving zone. **FFA:** free-for-all. **TDM:** team deathmatch.
- **Paper targets:** hidden kid-drawn signs on rooftops you can shoot for points.
- **Rookie / regular / veteran:** bot skill levels. New players face rookies until they **graduate** (five qualifying matches).
- **Stage / gate (★):** a step in the [plan](plan/MILESTONES.md). A gate is a point where Alan must play it and approve before later stages start.

## Roblox and tool words
- **Studio:** Roblox's editor, where the game is built and tested. **Play:** running the game inside Studio.
- **Place file:** the saved game world (`FlyFightPaper-WORKING.rbxlx`). There is exactly one.
- **Rojo:** a tool that copies the code files from this repo into Studio as you edit them.
- **Luau:** the programming language Roblox games are written in.
- **Server / client:** the server is the one computer running the match and making final decisions (hits, points); each
  player's computer is a client and only draws and sends input. The server never trusts a client's claim of a hit.
- **Network ownership:** letting a player's own computer move their plane so it feels instant, while the server checks it.
- **Lag compensation:** checking a hit against where the target was on the shooter's screen, so shots that looked like hits count.
- **MeshPart / mesh:** a 3D model shape. **Texture:** the picture painted on it. **Texture pack:** Studio's bundled copy of a model's pictures.
- **Collision / hitbox:** the invisible shape that decides what you bump into or hit. **Exact collision** follows the real shape and is
  slow to compute, so it is computed once and saved.
- **StreamingEnabled:** Roblox loading the world in pieces by distance instead of all at once.
- **Creator Store:** Roblox's library of free models and sounds.
- **Open Cloud:** Roblox's official upload service (used with the `ROBLOX_API` key).
- **ProfileStore:** a standard library for saving player data safely.
- **FPS:** frames per second; how smooth the game looks. The target is a steady 60.
- **Config:** the JSON files in `config/` that hold the tuning numbers (damage, prices, sizes).

## Art words
- **Meshy:** a paid service that turns a picture into a 3D model (uses credits).
- **Blender:** free 3D modelling software. Codex writes Blender scripts to build simple models.
- **Concept / reference picture:** a drawing of what something should look like before it is modelled.
- **Hero building:** a big landmark model made with extra care.
- **Contact sheet:** one picture showing many textures side by side, for checking before upload.

## Who's who
- **Claude:** talks to Alan, tests in Studio, fits pieces together, reviews everything, commits.
- **Codex:** OpenAI's coding agent; does well-defined jobs (pure logic with tests, Blender scripts, pictures, saving). See [AGENTS.md](../AGENTS.md).

Back to [HOME](HOME.md)
