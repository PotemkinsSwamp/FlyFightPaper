"""Read exact shapes off an AI model sheet, build plates from them, and score a model's outline against the sheet.
Part of the concept-to-blender skill. Plain Python (numpy; PIL and scipy only for the commands), so `plate()` and
`spine()` also import inside Blender.

    python sheet_tools.py grid SHEET x0 y0 x1 y1 OUT [zoom] [step]   zoomed crop with a labelled pixel grid, for reading points
    python sheet_tools.py map MAP.json [BUILD_SPEC.json]             numbered piece map of every view; counts vs the build
    python sheet_tools.py pieces SPEC.json                           plates and spines in model units + a check picture
    python sheet_tools.py score SHEET RENDER OUT nx ny L [upto clip] how well a render's outline matches the sheet's view
    python sheet_tools.py test                                       self-check

Model units: nose tip 0 -> tail tip 1 along x; y across; z up (the same as tools/art/sheet_model.py).
A view's frame is [nose_x, nose_y, L]: the nose tip's pixel and the whole length in pixels. Side view: x = (px - nose_x)
/ L, z = (nose_y - py) / L. Top view: x as side, y = (py - nose_y) / L.

SPEC for `pieces`: sheet, out (folder), frames {view: [nose_x, nose_y, L]}, crop [x0, y0, x1, y1] (check picture),
  plates [{name, map, view, points [[px, py], ...], other {view, base [px, py], tip [px, py]}}]: round the drawn
    outline, base first; `tip` = index of the tip point; `map` = its piece number on the piece map. Trace each plate in
    the view that sees it flattest (crest blades: the side) and click its base and tip in a second view (`other`,
    usually the top), which sets where it points.
  spines [{name, side [[px, py], ...], top [[px, py], ...], width [px, ...], joints [fraction, ...]}]: a horn's or
    spine's centre line, base to tip, in both views; `width` = its drawn thickness at each side point. The two views
    must agree on where along x it runs: the command prints their difference (AI sheets: about 3%).
Writes OUT/pieces.json ({plates: {name: {view, outline, tip}}, spines: {name: {spine, radius}}}; a spine is ready for
sheet_model.py's tube parts) and OUT/pieces-check.png (every traced line over the sheet, zoomed).
"""
import json, math, os, sys
import numpy as np


def _arc(p):
    """Cumulative length along a polyline, 0..1."""
    d = np.r_[0, np.cumsum(np.linalg.norm(np.diff(p, axis=0), axis=1))]
    return d / d[-1]


def resample(p, n):
    """n points spread evenly along a polyline."""
    p = np.asarray(p, float); t = _arc(p); s = np.linspace(0, 1, n)
    return np.stack([np.interp(s, t, p[:, k]) for k in range(p.shape[1])], 1)


def smooth_closed(p, n=48):
    """A smooth closed curve through the points (Catmull-Rom), n points: clicked corners -> the drawn leaf curve."""
    p = np.asarray(p, float); k = len(p); out = []
    for i in range(k):
        a, b, c, d = p[(i - 1) % k], p[i], p[(i + 1) % k], p[(i + 2) % k]
        for t in np.linspace(0, 1, max(2, n // k), endpoint=False):
            out.append(0.5 * (2 * b + (c - a) * t + (2 * a - 5 * b + 4 * c - d) * t * t + (3 * b - a - 3 * c + d) * t ** 3))
    return np.array(out)


def to_model(view, px, frame):
    nx, ny, L = frame; px = np.asarray(px, float)
    if view == "side": return np.stack([(px[:, 0] - nx) / L, (ny - px[:, 1]) / L], 1)     # (x, z)
    if view == "top": return np.stack([(px[:, 0] - nx) / L, (px[:, 1] - ny) / L], 1)      # (x, y)
    raise ValueError("trace plates in the side or top view")


def edges_of(curve, tip, n):
    """Split a closed outline (base first) at its tip into its two edges, both base to tip, n points each."""
    c = np.asarray(curve, float)
    return resample(c[:tip + 1], n), resample(np.vstack([c[tip:], c[:1]])[::-1], n)


def snap(points, img, r=4):
    """Move each clicked point onto the strongest colour edge within r pixels (a magnetic lasso): points read off a
    zoomed grid by eye land 3-6 px off on a 30 px blade, which is the whole difference between a leaf and a dagger."""
    a = np.asarray(img, float); k = np.ones(3) / 3
    a = np.apply_along_axis(lambda v: np.convolve(v, k, "same"), 0, np.apply_along_axis(lambda v: np.convolve(v, k, "same"), 1, a))
    gy, gx = np.gradient(a, axis=(0, 1)); g = np.abs(gx).sum(-1) + np.abs(gy).sum(-1); out = []
    for x, y in np.asarray(points, float):
        xi, yi = int(round(x)), int(round(y)); w = g[yi - r:yi + r + 1, xi - r:xi + r + 1]
        dy, dx = np.unravel_index(np.argmax(w), w.shape); out.append((xi - r + dx, yi - r + dy))
    return np.array(out, float)


def midline(curve, tip, n=12):
    """Centre line and width of a traced outline (horn, spine, tail): halfway between its two edges."""
    e1, e2 = edges_of(curve, tip, n); return (e1 + e2) / 2, np.linalg.norm(e1 - e2, axis=1)


def spine(side, top, side_w, top_w, frames, joints=(), n=12):
    """3D centre line of a horn or spine from its side-view line (x, z) and top-view line (x, y), in sheet pixels
    with the drawn width at each point. Matched by x: both views' x runs are first stretched onto one shared run
    (their average start and end; the gap is the AI sheet's disagreement). Lines must run steadily backwards (x
    growing); a horn that curls forward again needs two spines. Radius [across, up] from the top and side widths.
    Each joint is a small step (one segment ends narrower, the next starts full width), like the sheet's segmented
    horns. Returns (points [[x, y, z]], radius [[across, up]], x_disagreement as a share of the length)."""
    s = to_model("side", side, frames["side"]); t = to_model("top", top, frames["top"])
    assert (np.diff(s[:, 0]) > 0).all() and (np.diff(t[:, 0]) > 0).all(), "x must grow from base to tip in both views"
    gap = float(max(abs(s[0, 0] - t[0, 0]), abs(s[-1, 0] - t[-1, 0])))
    a, b = (s[0, 0] + t[0, 0]) / 2, (s[-1, 0] + t[-1, 0]) / 2
    on = lambda q: a + (q[:, 0] - q[0, 0]) * (b - a) / (q[-1, 0] - q[0, 0])        # each view's x onto the shared run
    f = np.linspace(0, 1, n); X = a + f * (b - a)
    r = np.stack([np.interp(X, on(t), np.asarray(top_w, float) / frames["top"][2]),
                  np.interp(X, on(s), np.asarray(side_w, float) / frames["side"][2])], 1) / 2
    pts = np.stack([X, np.interp(X, on(t), t[:, 1]), np.interp(X, on(s), s[:, 1])], 1)
    for j in sorted(joints, reverse=True):          # insert the step: 0.8 x radius just before, full radius at the joint
        i = int(np.searchsorted(f, j)); q = np.array([np.interp(j, f, pts[:, k]) for k in range(3)])
        qb = np.array([np.interp(j - 0.02, f, pts[:, k]) for k in range(3)]); rj = np.array([np.interp(j, f, r[:, k]) for k in range(2)])
        pts = np.insert(pts, i, [qb, q], 0); r = np.insert(r, i, [rj * 0.8, rj], 0); f = np.insert(f, i, [j - 0.02, j])
    return pts, r, gap


def plate(V, F, outline, tip, view="side", offset=0.0, thick=0.004, ridge=0.35, tilt=0.0, n=7, mirror=True):
    """A faceted plate (crest blade, cheek guard, fin) with exactly the drawn outline: a ridge from base to tip splits
    each face into a lit and a dark facet, like the sheet's gold plates, and the rim has real thickness.
    outline: model-unit points of the view's plane (side: (x, z), top: (x, y)), base first, `tip` its index.
    offset: the plate's place out of that plane (side: y, top: z): one number, or [at the base, at the tip] read from
    a second view, so the plate points the way the sheet draws it there (crest blades fan outwards seen from above).
    tilt: degrees it turns about the base-tip line away from facing the view (its face angle, from the front view);
    the drawn outline is widened so the view still shows exactly the drawn shape.
    Appends vertices (tuples) to V and faces (index tuples, outward) to F, as sheet_model.py does; returns new faces."""
    o = np.asarray(outline, float); o0, o1 = (offset, offset) if np.isscalar(offset) else offset
    d2 = o[tip] - o[0]; f = np.clip((o - o[0]) @ d2 / (d2 @ d2), 0, 1); off = o0 + (o1 - o0) * f   # along base -> tip
    lift = lambda q: (np.c_[q[:, 0], off, q[:, 1]] if view == "side" else np.c_[q[:, 0], q[:, 1], off])
    nrm = np.array((0, -1.0, 0)) if view == "side" else np.array((0, 0, 1.0))        # towards that view's camera
    P = lift(o); B, T = P[0], P[tip]; ax = (T - B) / np.linalg.norm(T - B); e1, e2 = edges_of(P, tip, n)
    nrm = nrm - ax * (nrm @ ax); nrm /= np.linalg.norm(nrm)            # faces the view as squarely as its direction allows
    half = np.linalg.norm(e1 - e2, axis=1) / 2; mid = (e1 + e2) / 2
    up = lambda h: np.outer(h, nrm)
    rim = np.minimum(thick / 2, half * 0.5)
    rings = [[e1[i] + up(rim)[i], mid[i] + up(half * ridge + rim)[i], e2[i] + up(rim)[i],
              e2[i] - up(rim)[i], mid[i] - up(half * ridge * 0.4 + rim)[i], e1[i] - up(rim)[i]] for i in range(1, n - 1)]
    cos = math.cos(math.radians(min(abs(tilt), 70)))
    def place(q):                                    # widen across (keeps the view's outline), then turn about base-tip
        q = np.asarray(q, float) - B; a = np.outer(q @ ax, ax); c = q - a
        side_dir = c - np.outer(c @ nrm, nrm); out_dir = np.outer(c @ nrm, nrm)
        c = side_dir / cos + out_dir; th = math.radians(tilt)
        rot = c * math.cos(th) + np.cross(ax, c) * math.sin(th) + np.outer(c @ ax, ax) * (1 - math.cos(th))
        return B + a + rot
    added = []
    for sgn in ((1, -1) if mirror else (1,)):
        def add(q):
            q = place(q) * (1, sgn, 1); V.extend(map(tuple, q.tolist())); return list(range(len(V) - len(q), len(V)))
        b, t = add([B])[0], add([T])[0]; R = [add(r) for r in rings]; m = len(R[0]); new = []
        for j in range(m): new.append((b, R[0][(j + 1) % m], R[0][j]))
        for r0, r1 in zip(R, R[1:]):
            for j in range(m): new.append((r0[j], r0[(j + 1) % m], r1[(j + 1) % m], r1[j]))
        for j in range(m): new.append((t, R[-1][j], R[-1][(j + 1) % m]))
        if _volume(V, new) < 0: new = [f[::-1] for f in new]       # outward, whichever way the outline was drawn
        F.extend(new); added += new
    return added


def _volume(V, faces):
    v = np.asarray(V, float); s = 0.0
    for f in faces:
        for k in range(1, len(f) - 1): s += np.dot(v[f[0]], np.cross(v[f[k]], v[f[k + 1]]))
    return s / 6


# ---------------------------------------------------------------- commands (need PIL; score and the masks need scipy)
def _font(n):
    from PIL import ImageFont
    try: return ImageFont.truetype("C:/Windows/Fonts/segoeui.ttf", n)
    except OSError: return ImageFont.load_default()


def grid(sheet, x0, y0, x1, y1, out, zoom=4, step=10):
    from PIL import Image, ImageDraw
    im = Image.open(sheet).convert("RGB").crop((x0, y0, x1, y1)); im = im.resize((im.width * zoom, im.height * zoom), Image.LANCZOS)
    d = ImageDraw.Draw(im); f = _font(13)
    for x in range((x0 // step + 1) * step, x1, step):
        X = (x - x0) * zoom; big = x % (step * 5) == 0
        d.line([(X, 0), (X, im.height)], fill=(255, 0, 255) if big else (255, 120, 255), width=2 if big else 1)
        if big: d.text((X + 2, 2), str(x), font=f, fill=(0, 0, 0))
    for y in range((y0 // step + 1) * step, y1, step):
        Y = (y - y0) * zoom; big = y % (step * 5) == 0
        d.line([(0, Y), (im.width, Y)], fill=(0, 160, 255) if big else (120, 200, 255), width=2 if big else 1)
        if big: d.text((2, Y + 2), str(y), font=f, fill=(0, 0, 0))
    im.save(out); print(out, im.size)


def pieces(spec_path):
    from PIL import Image, ImageDraw
    spec = json.load(open(spec_path, encoding="utf-8")); fr = spec["frames"]; out = spec["out"]; os.makedirs(out, exist_ok=True)
    sheet = Image.open(spec["sheet"]).convert("RGB"); R = spec.get("snap", 4); Z = spec.get("zoom", 4)
    pics = {}
    for v, (x0, y0, x1, y1) in spec["crops"].items():
        im = sheet.crop((x0, y0, x1, y1)); pics[v] = im.resize((im.width * Z, im.height * Z), Image.LANCZOS)
    draw = {v: ImageDraw.Draw(im) for v, im in pics.items()}
    P = lambda v, q: [((a - spec["crops"][v][0]) * Z, (b - spec["crops"][v][1]) * Z) for a, b in q]

    def trace(view, pts, tip, col):
        """Clicked points -> snapped -> smooth closed curve starting at the base; drawn on the check picture."""
        pts = snap(pts, sheet, R) if R else np.asarray(pts, float); c = smooth_closed(pts)
        c = np.roll(c, -int(np.argmin(np.linalg.norm(c - pts[0], axis=1))), 0); t = int(np.argmin(np.linalg.norm(c - pts[tip], axis=1)))
        if view in draw:
            draw[view].line(P(view, c.tolist() + [c[0].tolist()]), fill=col, width=3)
            for q in P(view, pts.tolist()): draw[view].ellipse([q[0] - 5, q[1] - 5, q[0] + 5, q[1] + 5], outline=(0, 0, 0), width=2)
        return c, t

    res = {"plates": {}, "spines": {}}
    for p in spec.get("plates", []):
        c, t = trace(p["view"], p["points"], p["tip"], (255, 0, 200))
        res["plates"][p["name"]] = {"view": p["view"], "outline": to_model(p["view"], c, fr[p["view"]]).round(5).tolist(), "tip": t}
        if "other" in p:                 # base and tip clicked in a second view: the plate's direction out of its plane
            ov = p["other"]["view"]; bt = to_model(ov, [p["other"]["base"], p["other"]["tip"]], fr[ov])[:, 1]
            res["plates"][p["name"]]["offset"] = bt.round(5).tolist()
            if ov in draw: draw[ov].line(P(ov, [p["other"]["base"], p["other"]["tip"]]), fill=(255, 0, 200), width=4)
    for s in spec.get("spines", []):
        lines = {}
        for v in ("side", "top"):
            c, t = trace(v, s[v], s[v + "_tip"], (0, 90, 255)); lines[v] = midline(c, t)
            if v in draw: draw[v].line(P(v, lines[v][0].tolist()), fill=(255, 255, 255), width=2)
        pts, r, gap = spine(lines["side"][0], lines["top"][0], lines["side"][1], lines["top"][1], fr, s.get("joints", ()))
        res["spines"][s["name"]] = {"spine": pts.round(5).tolist(), "radius": r.round(5).tolist()}
        print("spine %s: side and top views differ by %.1f%% of the length along x" % (s["name"], gap * 100))
    json.dump(res, open(os.path.join(out, "pieces.json"), "w"), indent=1)
    W = max(im.width for im in pics.values()); sheetpic = Image.new("RGB", (W, sum(im.height for im in pics.values())), (238, 233, 221)); y = 0
    for im in pics.values(): sheetpic.paste(im, (0, y)); y += im.height
    sheetpic.save(os.path.join(out, "pieces-check.png")); print(os.path.join(out, "pieces-check.png"))


def piece_map(spec_path, build_path=None):
    """The sheet broken into numbered pieces, each one marked in every view where it shows (the same number in every
    view; a far-side copy seen through or over the body gets an ' mark), with the count per piece. Counts come from a
    view where left and right don't overlap (top or front): in the side view the near and far pieces stack, which is
    how a Dragon with 3 pieces a side got built with 6. With a build spec (sheet_model.py parts carrying "map": id),
    it also checks the build has exactly the map's pieces and counts."""
    from PIL import Image, ImageDraw
    spec = json.load(open(spec_path, encoding="utf-8")); out = spec["out"]; os.makedirs(out, exist_ok=True)
    sheet = Image.open(spec["sheet"]).convert("RGB"); Z = spec.get("zoom", 3); problems = []
    pics = []
    for v, (x0, y0, x1, y1) in spec["crops"].items():
        im = sheet.crop((x0, y0, x1, y1)).resize(((x1 - x0) * Z, (y1 - y0) * Z), Image.LANCZOS); d = ImageDraw.Draw(im)
        d.text((10, 6), v, font=_font(30), fill=(0, 0, 0))
        for p in spec["pieces"]:
            for m in p["marks"].get(v, []):
                X, Y = (m[0] - x0) * Z, (m[1] - y0) * Z; far = len(m) > 2; tag = str(p["id"]) + ("'" if far else "")
                d.ellipse([X - 17, Y - 17, X + 17, Y + 17], fill=None if far else (255, 255, 255), outline=(200, 0, 120), width=4)
                d.text((X, Y), tag, font=_font(24), fill=(0, 0, 0) if not far else (200, 0, 120), anchor="mm")
        pics.append(im)
    for p in spec["pieces"]:
        for v in p.get("count_in", spec.get("count_in", ["top"])):
            near = [m for m in p["marks"].get(v, []) if len(m) < 3]
            if v in p["marks"] and len(near) != p["count"]:
                problems.append("piece %s (%s): %d marked in the %s view, count says %d" % (p["id"], p["name"], len(near), v, p["count"]))
        for v in spec["crops"]:
            if v not in p["marks"]: problems.append("piece %s (%s): not placed in the %s view (mark it, or list it as hidden: [])" % (p["id"], p["name"], v))
    if build_path: problems += count_check(spec["pieces"], json.load(open(build_path, encoding="utf-8")).get("parts", []))
    rows = ["%s  %s  (%s, %s)%s" % (p["id"], p["name"], p["kind"], "x%d" % p["count"], ("  - " + p["note"]) if p.get("note") else "")
            for p in spec["pieces"]] + [""] + ["Question: " + q for q in spec.get("questions", [])] + ["Check: " + q for q in problems]
    import textwrap
    W = max(max(im.width for im in pics), 1400); rows = [w for r in rows for w in (textwrap.wrap(r, W // 14) or [""])]
    H = sum(im.height + 10 for im in pics) + 40 * len(rows) + 30
    page = Image.new("RGB", (W, H), (238, 233, 221)); y = 0
    for im in pics: page.paste(im, (0, y)); y += im.height + 10
    d = ImageDraw.Draw(page)
    for r in rows: d.text((20, y + 10), r, font=_font(26), fill=(170, 30, 30) if r.startswith("Check") else (30, 30, 34)); y += 40
    page.save(os.path.join(out, "piece-map.png")); print(os.path.join(out, "piece-map.png")); print("\n".join(problems) or "map and build agree")
    return problems


def count_check(pieces, parts):
    """Every built part names its map piece ("map": id); each piece is built exactly its counted number of times
    (a mirrored part counts 2). Returns the problems."""
    built, problems = {}, []
    for part in parts:
        if "map" not in part: problems.append("built part %s is not on the piece map" % part["name"]); continue
        built[part["map"]] = built.get(part["map"], 0) + (2 if part.get("mirror", True) else 1)
    for p in pieces:
        if p.get("kind") != "body" and built.get(p["id"], 0) != p["count"]:
            problems.append("piece %s (%s): built %d, the map says %d" % (p["id"], p["name"], built.get(p["id"], 0), p["count"]))
    return problems


def _mask(im, halo=0):
    """Drawn-object pixels: anything unlike the corner colour, holes filled (cream and white sit close to the grey)."""
    from scipy import ndimage as nd
    a = np.asarray(im.convert("RGB"), float); bg = np.median(np.r_[a[:8, :8].reshape(-1, 3), a[-8:, -8:].reshape(-1, 3)], 0)
    m = nd.binary_fill_holes(np.abs(a - bg).sum(-1) > 30)
    return nd.binary_erosion(m, iterations=halo) if halo else m


def score(sheet, render, out, nx, ny, L, upto=1.0, clip=None):
    """Lay the render's outline on the sheet's (side or top view: nose tip on nose tip, render scaled so its own nose-
    to-end span is `upto` of the length: the model's furthest point back, horns included) and report IoU (shared
    area / combined area, 1 = identical) plus the biggest misses. Only the first `clip` of the length is compared
    (a head test: where the head ends; the sheet goes on into the neck). Render the model alone, flat, from straight
    on, on a plain background."""
    from PIL import Image
    from scipy import ndimage as nd
    S = Image.open(sheet); R = Image.open(render); mr = _mask(R)
    ys, xs = np.nonzero(mr); rx0, rx1 = xs.min(), xs.max(); ry = ys[xs <= rx0 + 1].mean()
    k = L * upto / (rx1 - rx0)                                         # render pixels -> sheet pixels
    W, H = int(L * upto) + 1, int(mr.shape[0] * k) + 1; top = int(ny - ry * k)
    mr = np.asarray(Image.fromarray(mr).resize((int(mr.shape[1] * k), int(mr.shape[0] * k)), Image.NEAREST))
    mr = mr[:, int(rx0 * k):int(rx0 * k) + W]
    ms = _mask(S.crop((int(nx), top, int(nx) + mr.shape[1], top + mr.shape[0])), halo=2)
    h, w = min(ms.shape[0], mr.shape[0]), min(ms.shape[1], mr.shape[1], int(L * (clip or upto)) + 1); ms, mr = ms[:h, :w], mr[:h, :w]
    iou = (ms & mr).sum() / max((ms | mr).sum(), 1)
    pic = np.full((h, w, 3), 245, np.uint8); pic[ms & mr] = (150, 150, 150); pic[ms & ~mr] = (220, 40, 40); pic[mr & ~ms] = (40, 90, 230)
    Image.fromarray(pic).resize((w * 3, h * 3), Image.NEAREST).save(out)
    print("IoU %.3f   (red: sheet only = model too small there; blue: model only = too big)" % iou)
    for name, m in (("sheet only", ms & ~mr), ("model only", mr & ~ms)):
        lab, n = nd.label(nd.binary_opening(m)); sizes = nd.sum(m, lab, range(1, n + 1))
        for i in np.argsort(sizes)[::-1][:3]:
            cy, cx = nd.center_of_mass(lab == i + 1)
            print("  %s: %d px around x=%.3f of the length" % (name, sizes[i], cx / L))
    return iou


def test():
    leaf = np.array([[0, 0], [0.03, 0.012], [0.07, 0.02], [0.1, 0.03], [0.06, 0.004], [0.02, -0.004]])   # base, tip=3
    for tilt in (0, 35):
        V, F = [], []; plate(V, F, leaf, 3, "side", offset=0.01, tilt=tilt, mirror=False)
        edges = {}
        for f in F:
            for a, b in zip(f, f[1:] + f[:1]): edges[(a, b)] = edges.get((a, b), 0) + 1
        assert all(c == 1 and (b, a) in edges for (a, b), c in edges.items()), "plate is not closed and outward"
        assert _volume(V, F) > 0
        v = np.asarray(V); span = v[:, [0, 2]].max(0) - v[:, [0, 2]].min(0)     # the side view still shows the drawing
        assert np.allclose(span, leaf.max(0) - leaf.min(0), atol=0.004), span
    V, F = [], []; plate(V, F, leaf, 3, "side", offset=(0.01, 0.04), mirror=False)    # fans out: base y 0.01, tip y 0.04
    v = np.asarray(V); assert abs(v[0, 1] - 0.01) < 1e-9 and abs(v[1, 1] - 0.04) < 1e-9, v[:2]
    span = v[:, [0, 2]].max(0) - v[:, [0, 2]].min(0); assert np.allclose(span, leaf.max(0) - leaf.min(0), atol=0.004)
    pts, r, gap = spine([[0, 0], [10, -10], [30, -15]], [[0, 0], [10, 5], [31, 8]], [6, 4, 1], [8, 5, 1],
                        {"side": [0, 0, 100], "top": [0, 0, 100]}, joints=[0.5])
    assert np.allclose(pts[0], 0) and np.allclose(pts[-1], (0.305, 0.08, 0.15)) and len(pts) == len(r) == 14
    assert abs(gap - 0.01) < 1e-9 and np.allclose(r[0], (0.04, 0.03))
    m, w = midline([[0, 0], [5, 2], [10, 0], [5, -2]], 2, 3)                       # a diamond: middle line, width 4
    assert np.allclose(m, [[0, 0], [5, 0], [10, 0]]) and np.allclose(w, [0, 4, 0])
    img = np.zeros((20, 20, 3)); img[:, 10:] = 255                                  # an edge at x = 9.5
    assert snap([[7, 10]], img, 4)[0][0] in (9, 10)
    pcs = [{"id": 1, "name": "blade", "kind": "plate", "count": 2}, {"id": 3, "name": "horn", "kind": "tube", "count": 2}]
    assert count_check(pcs, [{"name": "a", "map": 1}, {"name": "h", "map": 3}]) == []
    assert len(count_check(pcs, [{"name": "a", "map": 1}, {"name": "b", "map": 1}, {"name": "c"}])) == 3   # 4 blades, a stray, no horn
    print("ok: plate closed, outward, keeps its drawn outline (tilt 0 and 35, fanned out); spine joins both views; count check catches extra and missing pieces")


if __name__ == "__main__":
    cmd, a = sys.argv[1], sys.argv[2:]
    if cmd == "grid": grid(a[0], *map(int, a[1:5]), a[5], *map(int, a[6:8]))
    elif cmd == "map": piece_map(a[0], a[1] if len(a) > 1 else None)
    elif cmd == "pieces": pieces(a[0])
    elif cmd == "score": score(a[0], a[1], a[2], *map(float, a[3:8]))
    elif cmd == "test": test()
