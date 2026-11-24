"""Lays emote sounds under a muted recording: the track is built as a WAV by sample, joined to the picture, then checked.
python tools/emote_lay_sound.py RAW.mp4 OUT.mp4 name@seconds_after_light ...
(name: a file in assets/audio/emotes without .ogg; 1st's light is found by brightness in a 2032 x 800 capture.)"""
import re, subprocess, sys, wave
import numpy as np

raw, out, cues = sys.argv[1], sys.argv[2], sys.argv[3:]
RATE = 48000
ROOT = str(__import__("pathlib").Path(__file__).resolve().parents[1] / "assets" / "audio" / "emotes") + "/"

# 1st's light: the first frame where the box on 1st is bright after the dark
log = subprocess.run(["ffmpeg", "-loglevel", "error", "-i", raw, "-vf",
                      "crop=120:260:968:300,signalstats,metadata=print:key=lavfi.signalstats.YAVG:file=-", "-f", "null", "-"],
                     capture_output=True, text=True).stdout
light, t, dark = None, None, False
for line in log.splitlines():
    m = re.search(r"pts_time:([\d.]+)", line)
    if m: t = float(m.group(1)); continue
    m = re.search(r"YAVG=([\d.]+)", line)
    if m:
        y = float(m.group(1))
        if t > 3 and y < 30: dark = True
        if dark and y > 60: light = t; break
assert light, "1st's light not found"
length = float(subprocess.run(["ffprobe", "-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0", raw],
                              capture_output=True, text=True).stdout)
track = np.zeros(int(length * RATE), dtype=np.float32)
for cue in cues:
    name, at = cue.split("@")
    pcm = subprocess.run(["ffmpeg", "-loglevel", "error", "-i", ROOT + name + ".ogg", "-ac", "1", "-ar", str(RATE), "-f", "f32le", "-"],
                         capture_output=True).stdout
    piece = np.frombuffer(pcm, dtype=np.float32)
    start = int((light + float(at)) * RATE)
    piece = piece[: max(0, len(track) - start)]
    track[start:start + len(piece)] += piece
peak = float(np.abs(track).max())
if peak > 0.98: track *= 0.98 / peak  # overlapping sounds summed past full: the whole track down together
wav = out[:-4] + ".wav"
with wave.open(wav, "wb") as w:
    w.setnchannels(1); w.setsampwidth(2); w.setframerate(RATE)
    w.writeframes((np.clip(track, -1, 1) * 32767).astype(np.int16).tobytes())
subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", raw, "-i", wav, "-map", "0:v:0", "-map", "1:a:0",
                "-c:v", "libx264", "-crf", "20", "-pix_fmt", "yuv420p", "-c:a", "aac", "-b:a", "160k", "-shortest", out], check=True)
probe = subprocess.run(["ffprobe", "-v", "error", "-select_streams", "a:0", "-show_entries", "stream=start_time,duration",
                        "-of", "csv=p=0", out], capture_output=True, text=True).stdout.strip()
decode = subprocess.run(["ffmpeg", "-v", "error", "-i", out, "-f", "null", "-"], capture_output=True, text=True).stderr.strip()
print(f"{out}: light at {light:.3f} s, sound stream start,duration = {probe}, peak before {peak:.3f}, decode errors: {decode or 'none'}")
