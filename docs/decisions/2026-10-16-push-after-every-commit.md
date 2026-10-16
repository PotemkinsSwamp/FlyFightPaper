# Push after every commit

**Decided:** 2026-10-16 (Alan)  
**Status:** in force

## Decision
Every commit is pushed to GitHub right away: small, continuous pushes through the session instead of one big push at
the end. GitHub's copy starts from a snapshot of today's files (no older history: the full history is 9.8 GB and one
file is over GitHub's 100 MB limit), on branch `github-snapshot`, pushed to GitHub's `main`; the bell tower's
`hero.blend` goes through Git LFS. The local `main` keeps the full history.

## Why
The first push of the whole project failed (GitHub takes about 2 GB per push) and a snapshot takes about an hour;
Alan doesn't want to wait on pushes. Of the 6.9 GB snapshot only ~0.15 GB (code, config, docs, place and model files,
upload records, FBX meshes) is needed to rebuild the game; Blender working files and review pictures (~2.2 GB) are not.

## Affects
- [AGENTS.md](../../AGENTS.md) (How to work)

All decisions: [decisions](README.md)
