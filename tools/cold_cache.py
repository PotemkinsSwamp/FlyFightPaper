"""Cold-load tests on the PC: make Roblox download everything again, like a fresh phone (Alan 2026-10-25).

    python tools/cold_cache.py aside   # Studio and Roblox closed: move Roblox's download cache to a backup folder
    python tools/cold_cache.py open    # open the cloud place in Studio (then Play; read LoadLog.recent())
    python tools/cold_cache.py push FILE...  # write Luau (to %TEMP%/cold_push.lua, for studio_cli execute_luau in Edit) that puts
                                             # these src/ files into the open Studio: a reopened Studio has no Rojo link

The cache is only downloaded copies; Roblox rebuilds it. Each `aside` keeps the moved copy in
%LOCALAPPDATA%\\Roblox-cache-aside\\<time> (move one back to restore it).
"""
import os, shutil, subprocess, sys, time
from pathlib import Path

ROBLOX = Path(os.environ["LOCALAPPDATA"]) / "Roblox"
ASIDE = Path(os.environ["LOCALAPPDATA"]) / "Roblox-cache-aside"
CACHE = ("rbx-storage", "rbx-storage-sc", "rbx-storage.db", "rbx-storage.db-shm", "rbx-storage.db-wal")
PLACE, UNIVERSE = "132768925825316", "10771424231"


def running():
    out = subprocess.run(["tasklist"], capture_output=True, text=True).stdout
    return [n for n in ("RobloxStudioBeta.exe", "RobloxPlayerBeta.exe") if n in out]


def aside():
    if busy := running():
        raise SystemExit(f"close first: {', '.join(busy)} still running")
    target = ASIDE / time.strftime("%Y%m%d-%H%M%S")
    target.mkdir(parents=True)
    moved = [n for n in CACHE if (ROBLOX / n).exists()]
    for name in moved:
        shutil.move(str(ROBLOX / name), str(target / name))   # same drive: a rename, instant
    print("moved", moved, "to", target)


def open_studio():
    exe = max(ROBLOX.glob("Versions/*/RobloxStudioBeta.exe"), key=lambda p: p.stat().st_mtime)
    subprocess.Popen([str(exe), "-task", "EditPlace", "-placeId", PLACE, "-universeId", UNIVERSE])
    print("opening", exe.parent.name)


ROOTS = {"src/first": "game.ReplicatedFirst.FlyFightPaper", "src/client": "game.StarterPlayer.StarterPlayerScripts.FlyFightPaper",
         "src/server": "game.ServerScriptService.FlyFightPaper", "src/shared": "game.ReplicatedStorage.FlyFightPaper.Shared"}


def push(*files):
    lines = []
    for f in files:
        f = Path(f).as_posix()
        folder, name = f.rsplit("/", 1)
        name = name.removesuffix(".luau").removesuffix(".client").removesuffix(".server")
        text = Path(f).read_text(encoding="utf-8")
        eq = "=" * next(n for n in range(1, 20) if f"]{'=' * n}]" not in text)
        lines.append(f"{ROOTS[folder]}:FindFirstChild('{name}').Source = [{eq}[{text}]{eq}]")
    out = Path(os.environ["TEMP"]) / "cold_push.lua"
    out.write_text("\n".join(lines) + f"\nreturn 'pushed {len(files)}'\n", encoding="utf-8")
    print(out)


if __name__ == "__main__":
    {"aside": aside, "open": open_studio, "push": lambda: push(*sys.argv[2:])}[sys.argv[1]]()
