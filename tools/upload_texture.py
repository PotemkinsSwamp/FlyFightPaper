"""Upload a free PNG (or, with --model, an FBX; with --animation, an .rbxm KeyframeSequence) through Roblox's official Assets API. Never prints credentials."""
from pathlib import Path
import argparse
import json
import time
import requests

ROOT = Path(__file__).resolve().parents[1]
BASE = "https://apis.roblox.com/assets/v1/"


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("png", type=Path)
    parser.add_argument("--creator", required=True)
    parser.add_argument("--name", required=True)
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--model", action="store_true", help="upload an FBX as a Model")
    parser.add_argument("--animation", action="store_true", help="upload an .rbxm KeyframeSequence as an Animation")
    args = parser.parse_args()
    if args.output.exists():
        raise SystemExit("Output already exists; inspect the previous upload instead of duplicating it.")
    settings = {}
    for line in (ROOT / ".env").read_text().splitlines():
        key, separator, value = line.partition("=")
        if separator:
            settings[key.strip()] = value.strip().strip('\"').strip("'")
    session = requests.Session()
    session.headers["x-api-key"] = settings["ROBLOX_API"]
    kind, content = ("Animation", "model/x-rbxm") if args.animation else ("Model", "model/fbx") if args.model else ("Image", "image/jpeg" if args.png.suffix.lower() in (".jpg", ".jpeg") else "image/png")
    request = {"assetType": kind, "displayName": args.name,
               "description": "Retained FlyFightPaper classroom art, resized to a shared 1024-pixel atlas.",
               "creationContext": {"creator": {"userId": args.creator}, "expectedPrice": 0}}
    with args.png.open("rb") as image:
        response = session.post(BASE + "assets", data={"request": json.dumps(request)},
                                # Roblox sees a plain file name, never ours (suspected cause of the 2026-10-12 moderation: names like "legs-bottom-back").
        files={"fileContent": ("asset" + args.png.suffix, image, content)}, timeout=60)
    if not response.ok:
        raise SystemExit(f"Upload failed with HTTP {response.status_code}: {response.text[:300]}; no retry was made.")
    operation = response.json()
    args.output.write_text(json.dumps(operation, indent=2))
    path = operation.get("path", "")
    if not path.startswith("operations/"):
        raise SystemExit("Upload response has no operation path; inspect output before retrying.")
    for attempt in range(20):
        response = session.get(BASE + path, timeout=30)
        if not response.ok:
            raise SystemExit(f"Polling failed with HTTP {response.status_code}; operation was saved.")
        operation = response.json()
        args.output.write_text(json.dumps(operation, indent=2))
        if operation.get("done"):
            if "error" in operation:
                raise SystemExit("Roblox rejected this upload; inspect the saved operation.")
            asset = operation["response"]
            print(args.png.name, "uploaded", asset.get("assetId"), asset.get("moderationResult"))
            return
        time.sleep(2)
    raise SystemExit("Upload is still processing; operation was saved. Do not submit again.")


if __name__ == "__main__":
    main()
