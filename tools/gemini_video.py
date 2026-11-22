"""One paid Gemini video call (model gemini-omni-1.2-flash, Interactions API). Every call is Alan's go.

  python tools/gemini_video.py OUT.mp4 "prompt" [--video=IN.mp4] [--resolution=360p] [--duration=9s] [--edit]

With --video the clip (15 s at most) goes in as the thing to edit; the model always returns a video
with its own sound. Prints the token counts and the price; never prints the key (GEMINI_API in .env).
"""
import base64
import json
import re
import sys
import urllib.error
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
URL = "https://generativelanguage.googleapis.com/v1beta/interactions"
USD_PER_M = {"in": 1.50, "out_video": 12.00, "out_other": 9.00}  # Google's price page, 2026-11-21


def key():
    for line in (ROOT / ".env").read_text(encoding="utf-8").splitlines():
        m = re.match(r"\s*(?:export\s+)?GEMINI_API\s*[=:]\s*(.+)", line)
        if m:
            return m.group(1).strip().strip("\"'")
    sys.exit("GEMINI_API is not in .env")


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    opts = dict(a[2:].split("=", 1) if "=" in a else (a[2:], "1") for a in sys.argv[1:] if a.startswith("--"))
    if len(args) != 2:
        sys.exit(__doc__)
    out, prompt = Path(args[0]), args[1]
    if Path(prompt).is_file():
        prompt = Path(prompt).read_text(encoding="utf-8")

    content = [{"type": "text", "text": prompt}]
    if "video" in opts:
        data = base64.b64encode(Path(opts["video"]).read_bytes()).decode()
        content.insert(0, {"type": "video", "mime_type": "video/mp4", "data": data})
    body = {
        "model": "gemini-omni-1.2-flash",
        "input": [{"type": "user_input", "content": content}],
        "response_format": {
            "type": "video",
            "resolution": opts.get("resolution", "360p"),
            "duration": opts.get("duration", "9s"),
            "aspect_ratio": opts.get("aspect", "16:9"),
        },
    }
    if "edit" in opts:
        body["generation_config"] = {"video_config": {"task": "edit"}}

    req = urllib.request.Request(
        URL, json.dumps(body).encode(), {"x-goog-api-key": key(), "Content-Type": "application/json"}
    )
    try:
        reply = json.load(urllib.request.urlopen(req, timeout=900))
    except urllib.error.HTTPError as e:
        sys.exit(f"HTTP {e.code}: {e.read().decode(errors='replace')[:2000]}")

    video = None
    for step in reply.get("steps", []) + [{"content": reply.get("outputs", [])}]:
        for part in step.get("content") or []:
            if isinstance(part, dict) and part.get("type") == "video" and part.get("data"):
                video = part.pop("data")
    usage = reply.get("usage", {})
    print("usage:", json.dumps(usage))
    if usage:
        cost = usage.get("total_input_tokens", 0) * USD_PER_M["in"] / 1e6
        for m in usage.get("output_tokens_by_modality", []):
            rate = USD_PER_M["out_video"] if m.get("modality") == "video" else USD_PER_M["out_other"]
            cost += m.get("tokens", 0) * rate / 1e6
        print(f"price: about ${cost:.2f}")
    if not video:
        sys.exit("no video in the reply: " + json.dumps(reply)[:2000])
    out.write_bytes(base64.b64decode(video))
    print("saved", out)


if __name__ == "__main__":
    main()
