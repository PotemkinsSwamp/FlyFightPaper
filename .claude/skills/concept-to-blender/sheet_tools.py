"""Read exact shapes off an AI model sheet, build plates from them, and score a model's outline against the sheet.
Part of the concept-to-blender skill. Plain Python (numpy; PIL and scipy only for the commands), so `plate()` and
`spine()` also import inside Blender.

    python sheet_tools.py grid SHEET x0 y0 x1 y1 OUT [zoom] [step]   zoomed crop with a labelled pixel grid, for reading points
    python sheet_tools.py map MAP.json [BUILD_SPEC.json]             numbered piece map of every view; counts vs the build
    python sheet_tools.py pieces SPEC.json                           plates and spines in model units + a check picture
    python sheet_tools.py score SHEET RENDER OUT nx ny L [upto clip [MAP.json VIEW]]   how well a render's outline
                                                                     matches the sheet's view (the map's exceptions left out)
    python sheet_tools.py views MESH.npz OUT                         piece-coloured and silhouette renders of a build
    python sheet_tools.py numbers MAP.json MESH.npz                  every built piece's size, thickness and attachment
                                                                     against its card on the map
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
MAP.json for `map` and `numbers` (and match_views.py, which documents `cameras` and `modules`): sheet, out, zoom,
  crops {view: [x0, y0, x1, y1]}, count_in [views], questions [text],
  exceptions [{view, box [x0, y0, x1, y1], why, governs}]: a place where one view draws something that cannot be true
    in 3D (a fin laid flat so its pattern shows). `governs` names the view that is right. The map draws them, `score`
    leaves them out, and the reviewer is told not to mark the build down there.
  pieces [{id, name, kind, count, marks {view: [[px, py] or [px, py, "far"], ...]}, note, count_in, and its card:
    size [long, wide, thick] (sheet pixels, biggest first, one copy), parent (the id it is sized against; default the
    body), of_parent (its length as a share of the parent's), min_thick (pixels), free (true: not attached to anything)}]
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
        for i, e in enumerate(spec.get("exceptions", [])):
            if e["view"] == v:
                b = [(e["box"][0] - x0) * Z, (e["box"][1] - y0) * Z, (e["box"][2] - x0) * Z, (e["box"][3] - y0) * Z]
                d.rectangle(b, outline=(230, 120, 0), width=4); d.text((b[0] + 6, b[1] + 4), "X%d" % (i + 1), font=_font(24), fill=(230, 120, 0))
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
    if build_path:
        build = json.load(open(build_path, encoding="utf-8")); only = build.get("only")     # a module built alone
        problems += count_check([p for p in spec["pieces"] if not only or p["id"] in only],
                                [q for q in build.get("parts", []) if not only or q.get("map") in only])
    rows = ["%s  %s  (%s, %s)%s" % (p["id"], p["name"], p["kind"], "x%d" % p["count"], ("  - " + p["note"]) if p.get("note") else "")
            for p in spec["pieces"]] + [""] + ["Question: " + q for q in spec.get("questions", [])] + [
               "Exception X%d (%s view): %s The %s view is right here." % (i + 1, e["view"], e["why"], e["governs"])
               for i, e in enumerate(spec.get("exceptions", []))] + ["Check: " + q for q in problems]
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
        if p.get("kind") not in ("body", "paint", "later") and built.get(p["id"], 0) != p["count"]:   # painted / not in this build
            problems.append("piece %s (%s): built %d, the map says %d" % (p["id"], p["name"], built.get(p["id"], 0), p["count"]))
    return problems


def _mask(im, halo=0):
    """Drawn-object pixels: anything unlike the corner colour, holes filled (cream and white sit close to the grey)."""
    from scipy import ndimage as nd
    a = np.asarray(im.convert("RGB"), float); bg = np.median(np.r_[a[:8, :8].reshape(-1, 3), a[-8:, -8:].reshape(-1, 3)], 0)
    m = nd.binary_fill_holes(np.abs(a - bg).sum(-1) > 30)
    return nd.binary_erosion(m, iterations=halo) if halo else m


def score(sheet, render, out, nx, ny, L, upto=1.0, clip=None, skip=()):
    """Lay the render's outline on the sheet's (side or top view: nose tip on nose tip, render scaled so its own nose-
    to-end span is `upto` of the length: the model's furthest point back, horns included) and report IoU (shared
    area / combined area, 1 = identical) plus the biggest misses. Only the first `clip` of the length is compared
    (a head test: where the head ends; the sheet goes on into the neck). `skip`: boxes in sheet pixels left out of the
    comparison (the map's exceptions for this view: places the view draws wrongly). Render the model alone, flat, from
    straight on, on a plain background."""
    from PIL import Image
    from scipy import ndimage as nd
    S = Image.open(sheet); R = Image.open(render); mr = _mask(R)
    ys, xs = np.nonzero(mr); rx0, rx1 = xs.min(), xs.max(); ry = ys[xs <= rx0 + 1].mean()
    k = L * upto / (rx1 - rx0)                                         # render pixels -> sheet pixels
    W, H = int(L * upto) + 1, int(mr.shape[0] * k) + 1; top = int(ny - ry * k)
    mr = np.asarray(Image.fromarray(mr).resize((int(mr.shape[1] * k), int(mr.shape[0] * k)), Image.NEAREST))
    mr = mr[:, int(rx0 * k):int(rx0 * k) + W]
    ms = _mask(S, halo=2)[top:top + mr.shape[0], int(nx):int(nx) + mr.shape[1]]   # whole sheet: a crop's corner can sit on the model
    h, w = min(ms.shape[0], mr.shape[0]), min(ms.shape[1], mr.shape[1], int(L * (clip or upto)) + 1); ms, mr = ms[:h, :w], mr[:h, :w]
    keep = np.ones((h, w), bool)
    for x0, y0, x1, y1 in skip: keep[max(int(y0 - top), 0):max(int(y1 - top), 0), max(int(x0 - nx), 0):max(int(x1 - nx), 0)] = False
    ms, mr = ms & keep, mr & keep
    iou = (ms & mr).sum() / max((ms | mr).sum(), 1)
    pic = np.full((h, w, 3), 245, np.uint8); pic[ms & mr] = (150, 150, 150); pic[ms & ~mr] = (220, 40, 40); pic[mr & ~ms] = (40, 90, 230)
    pic[~keep] = (250, 225, 150)                                       # an exception: not judged
    Image.fromarray(pic).resize((w * 3, h * 3), Image.NEAREST).save(out)
    print("IoU %.3f   (red: sheet only = model too small there; blue: model only = too big)" % iou)
    for name, m in (("sheet only", ms & ~mr), ("model only", mr & ~ms)):
        lab, n = nd.label(nd.binary_opening(m)); sizes = nd.sum(m, lab, range(1, n + 1))
        for i in np.argsort(sizes)[::-1][:3]:
            cy, cx = nd.center_of_mass(lab == i + 1)
            print("  %s: %d px around x=%.3f of the length" % (name, sizes[i], cx / L))
    return iou


def views(mesh, out, px=1000):
    """Check renders straight from the built mesh (sheet_model.py writes OUT/mesh.npz): each map piece in its own flat
    colour from the top, side and front (pieces-*.png; the body grey), and black silhouettes on white for `score`
    (sil-side.png, sil-top.png). Orthographic, nose to the left, px pixels per model unit length."""
    from PIL import Image
    m = np.load(mesh); V, T, part, mp = m["V"], m["T"], m["part"], m["map"]
    pal = [(150, 150, 150)] + [tuple(int(c) for c in np.random.RandomState(k).randint(40, 230, 3)) for k in range(1, 40)]
    cams = {"side": (V[:, 0], -V[:, 2], -V[:, 1]), "top": (V[:, 0], V[:, 1], V[:, 2]), "front": (V[:, 1], -V[:, 2], -V[:, 0])}
    for v, (sx, sy, D) in cams.items():                        # screen right, screen down, nearer the camera = bigger
        x0, y0 = sx.min(), sy.min(); W, H = int((sx.max() - x0) * px) + 4, int((sy.max() - y0) * px) + 4
        X, Y = (sx - x0) * px + 2, (sy - y0) * px + 2
        zb = np.full((H, W), -1e9); img = np.full((H, W, 3), 255, np.uint8)
        for t, pt in zip(T, part):
            a = np.c_[X[t], Y[t]]; xa, ya = np.floor(a.min(0)).astype(int); xb, yb = np.ceil(a.max(0)).astype(int) + 1
            xs, ys = np.meshgrid(np.arange(xa, xb) + 0.5, np.arange(ya, yb) + 0.5)
            (p0, p1, p2) = a; den = (p1[1] - p2[1]) * (p0[0] - p2[0]) + (p2[0] - p1[0]) * (p0[1] - p2[1])
            if abs(den) < 1e-12: continue
            l0 = ((p1[1] - p2[1]) * (xs - p2[0]) + (p2[0] - p1[0]) * (ys - p2[1])) / den
            l1 = ((p2[1] - p0[1]) * (xs - p2[0]) + (p0[0] - p2[0]) * (ys - p2[1])) / den; l2 = 1 - l0 - l1
            k = (l0 >= 0) & (l1 >= 0) & (l2 >= 0); d = l0 * D[t[0]] + l1 * D[t[1]] + l2 * D[t[2]]
            yy, xx = (ys[k] - 0.5).astype(int), (xs[k] - 0.5).astype(int); nearer = d[k] > zb[yy, xx]
            zb[yy[nearer], xx[nearer]] = d[k][nearer]; img[yy[nearer], xx[nearer]] = pal[int(mp[pt])]
        Image.fromarray(img).save(os.path.join(out, "pieces-%s.png" % v))
        if v != "front":
            sil = np.where((zb > -1e9)[..., None], 0, 255).astype(np.uint8).repeat(3, 2); Image.fromarray(sil).save(os.path.join(out, "sil-%s.png" % v))
    print("pieces-side/top/front.png, sil-side/top.png in", out)


def _shells(T, n):
    """Shell number per vertex: pieces are closed shells that share no vertices."""
    from scipy.sparse import coo_matrix
    from scipy.sparse.csgraph import connected_components
    e = np.r_[T[:, [0, 1]], T[:, [1, 2]]]
    return connected_components(coo_matrix((np.ones(len(e)), (e[:, 0], e[:, 1])), (n, n)), directed=False)[1]


def _inside(P, V, T):
    """Which points lie inside the closed shell (V, T): a ray from the point crosses its surface an odd number of times."""
    d = np.array([0.0113, 0.0071, 1.0]); a, e1, e2 = V[T[:, 0]], V[T[:, 1]] - V[T[:, 0]], V[T[:, 2]] - V[T[:, 0]]
    h = np.cross(d, e2); det = (e1 * h).sum(1); ok = np.abs(det) > 1e-14; det = np.where(ok, det, 1.0)
    sv = P[:, None, :] - a[None]; u = (sv * h).sum(-1) / det; q = np.cross(sv, e1[None])
    v = (q @ d) / det; t = (q * e2[None]).sum(-1) / det
    return (ok & (u >= 0) & (v >= 0) & (u + v <= 1) & (t > 1e-9)).sum(1) % 2 == 1


def numbers(map_path, mesh, tol=0.2):
    """The build's own numbers against the map's cards, piece by piece (sheet_model.py writes the mesh.npz): length,
    width and thickness of one copy in sheet pixels (measured along the piece's own axes, so a slanted blade is not
    overstated), its length as a share of its parent's, and whether it is sunk into the body or another piece. Problems:
    a size more than `tol` off its card, thinner than min_thick (2 px), not attached, or a piece with no size on its
    card. Sizes need no eye: this is the check for 'too small', 'too thin' and 'floating'."""
    spec = json.load(open(map_path, encoding="utf-8")); m = np.load(mesh); V, T, part, mp = m["V"], m["T"], m["part"], m["map"]
    cams = spec.get("cameras", {}); L = float(next(iter(cams.values()))["px"]) if cams else float(spec.get("length_px", 1000))
    shell = _shells(T, len(V)); tmap = np.where(part == 0, -1, mp[part]); body = T[part == 0]; kinds = {p["id"]: p for p in spec["pieces"]}

    def extents(P):
        c = P - P.mean(0); return np.sort(np.ptp(c @ np.linalg.svd(c, full_matrices=False)[2].T, 0))[::-1] * L

    def tris(pid): return body if pid is None or kinds[pid].get("kind") == "body" else T[tmap == pid]

    each = {k: T[shell[T[:, 0]] == k] for k in np.unique(shell[T[:, 0]])}          # every shell's own triangles

    size = {None: extents(V[np.unique(body)])}; problems = []
    for p in spec["pieces"]:
        tr = tris(p["id"])
        if len(tr): size[p["id"]] = np.median([extents(V[shell == k]) for k in np.unique(shell[tr[:, 0]])], 0)
    print("%-4s %-40s %6s %6s %6s %9s  %s" % ("id", "piece (one copy, sheet px)", "long", "wide", "thick", "of parent", "attached"))
    for p in spec["pieces"]:
        tr = tris(p["id"]); tag = "piece %s (%s)" % (p["id"], p["name"][:40])
        if not len(tr) or p.get("kind") == "body": continue
        E = size[p["id"]]; par = p.get("parent"); share = E[0] / size.get(par, size[None])[0]; loose = 0
        ks = np.unique(shell[tr[:, 0]]) if not p.get("free") else []
        for k in ks:                                                  # attached = some of it is inside another shell
            P = V[shell == k][:: max(1, (shell == k).sum() // 150)]
            loose += not any(_inside(P, V, t).any() for j, t in each.items() if j != k)
        if loose: problems.append("%s: %d of %d copies float: no part is inside the body or another piece (sink the root in)" % (tag, loose, len(ks)))
        print("%-4s %-40s %6.1f %6.1f %6.1f %8.0f%%  %s" % (p["id"], p["name"][:40], *E, share * 100, "free" if p.get("free") else "no: %d loose" % loose if loose else "yes"))
        if "size" not in p: problems.append("%s: no size on its card (long, wide, thick in sheet pixels)" % tag)
        for name, got, want in zip(("long", "wide", "thick"), E, p.get("size", [])):
            if abs(got / want - 1) > tol: problems.append("%s: %s %.1f px, its card says %.1f (%+d%%)" % (tag, name, got, want, round((got / want - 1) * 100)))
        if "of_parent" in p and abs(share / p["of_parent"] - 1) > tol:
            problems.append("%s: %.0f%% of its parent's length, its card says %.0f%%" % (tag, share * 100, p["of_parent"] * 100))
        if E[2] < p.get("min_thick", spec.get("min_thick", 2)): problems.append("%s: paper-thin (%.1f px)" % (tag, E[2]))
    print("\n".join(problems) or "every piece matches its card and is attached"); return problems


def _box(lo, hi, V, T, part, k):
    """A closed box for the self-check (appended to V, T; its triangles belong to part k)."""
    i0 = len(V); (a, b, c), (d, e, f) = lo, hi
    V.extend([(a, b, c), (d, b, c), (d, e, c), (a, e, c), (a, b, f), (d, b, f), (d, e, f), (a, e, f)])
    for q in ((0, 3, 2, 1), (4, 5, 6, 7), (0, 1, 5, 4), (1, 2, 6, 5), (2, 3, 7, 6), (3, 0, 4, 7)):
        T.extend([(i0 + q[0], i0 + q[1], i0 + q[2]), (i0 + q[0], i0 + q[2], i0 + q[3])]); part.extend([k, k])


def test():
    import tempfile
    V, T, part = [], [], []
    _box((0, -.1, -.1), (1, .1, .1), V, T, part, 0)                                  # body
    _box((.4, -.02, .08), (.5, .02, .2), V, T, part, 1)                              # fin sunk into the back
    _box((.7, -.02, .15), (.8, .02, .25), V, T, part, 2)                             # fin floating above it
    _box((.1, -.05, .09), (.3, .05, .0905), V, T, part, 3)                           # a paper-thin plate
    with tempfile.TemporaryDirectory() as td:
        np.savez(td + "/m.npz", V=np.array(V, float), T=np.array(T), part=np.array(part), names=np.array(list("bfgp")), map=np.array([0, 1, 2, 3]))
        pc = lambda i, **k: dict(id=i, name="p%d" % i, kind="plate", count=1, marks={}, **k)
        json.dump({"length_px": 100, "pieces": [pc(1, size=[12, 10, 4]), pc(2, size=[10, 10, 4]), pc(3, size=[20, 10, 0.05], of_parent=0.2)]}, open(td + "/map.json", "w"))
        got = numbers(td + "/map.json", td + "/m.npz")
    assert len(got) == 2 and "float" in got[0] and "paper-thin" in got[1], got
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
    print("ok: plate closed, outward, keeps its drawn outline (tilt 0 and 35, fanned out); spine joins both views; count check catches extra and missing pieces; numbers catches a floating and a paper-thin piece")


if __name__ == "__main__":
    cmd, a = sys.argv[1], sys.argv[2:]
    if cmd == "grid": grid(a[0], *map(int, a[1:5]), a[5], *map(int, a[6:8]))
    elif cmd == "map": piece_map(a[0], a[1] if len(a) > 1 else None)
    elif cmd == "pieces": pieces(a[0])
    elif cmd == "score":
        skip = [e["box"] for e in json.load(open(a[8], encoding="utf-8")).get("exceptions", []) if e["view"] == a[9]] if len(a) > 9 else ()
        score(a[0], a[1], a[2], *map(float, a[3:8]), skip=skip)
    elif cmd == "numbers": numbers(a[0], a[1])
    elif cmd == "views": views(a[0], a[1])
    elif cmd == "test": test()
