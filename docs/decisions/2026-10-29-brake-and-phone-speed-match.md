# A brake on PC, automatic speed matching on phones

**Decided:** 2026-10-29 (Alan)  
**Status:** trying out (built for testing 2026-10-29; Alan feels both before they go in the tutorial)

## Decision
- PC: a brake on Space, held like Boost. It must be on brand for paper planes (working name "Flaps": the tag says
  FLAPS UP; a paper-flaps look on the plane comes after the feel is right). Plane speeds stay as they are.
- Phones: no brake button (Boost, FIRE and 2 are already a lot for two thumbs). Instead, like auto-fire, the plane
  matches the speed of the enemy you are tailing by itself, with a setting to turn it off. It must never grab the
  wrong plane: it picks only a plane you are really behind, keeps it while another passes in front, and lets go
  soon after you lose it.
- Tail mode and a target camera: no (too scripted; confusing). Easier weapons: phones already have auto-fire; no more.
- The tutorial teaches the brake only after it has been tested.

## Why
Alan's [playtest note 7](../playtests/2026-10-29-young-testers-tutorial.md): on a phone keeping your aim on a plane is
"like catching a fly with chopsticks", and with one speed you overshoot a slower plane. Research:
[phone aim options](../plan/PHONE-AIM-OPTIONS.md).

## Where it lives
Rules and numbers: [flight](../systems/flight.md) (Brake, Speed match).

All decisions: [decisions](README.md)
