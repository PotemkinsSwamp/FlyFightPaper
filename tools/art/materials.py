"""Separate toy-town materials using the baked sRGB colour atlases.

    python tools/art/materials.py assets/models/notebook-tower --render
    python tools/art/materials.py --selftest

Requires numpy and Pillow. Only --render launches Blender. Original normal and
roughness PNGs are kept byte-for-byte as *-base.png and never overwritten.
Colour is a heuristic: blue plastic can look like glass, and dark warm kraft
can look like wood. Cream trim stays dielectric. No transparency is invented.
"""

import argparse
import json
import math
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import zlib

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont


TARGETS = {   # stronger contrast (Alan picked "stronger", 2026-10-10): glossy plastic and glass, matte paper/card
    "plastic": 0.15,
    "cardboard": 0.92,
    "paper": 0.75,
    "wood": 0.60,
    "metal": 0.22,
    "glass": 0.05,
    "dark": 0.50,
}
BUMP = 2.2  # multiplies every class's micro-normal strength
SEED = 20261010
MASK_BLUR = 1.25
BASE_VARIATION = 0.15
BLENDER = Path("D:/Blender/blender.exe")


def smoothstep(low, high, value):
    t = np.clip((value - low) / (high - low), 0.0, 1.0)
    return t * t * (3.0 - 2.0 * t)


def band(value, low, inner_low, inner_high, high):
    return smoothstep(low, inner_low, value) * (1 - smoothstep(inner_high, high, value))


def rgb_hsv(rgb):
    """Float HSV from sRGB bytes; hue is in degrees, S and V are 0..1."""
    rgb = np.asarray(rgb, dtype=np.float32) / 255.0
    r, g, b = np.moveaxis(rgb, -1, 0)
    v, low = rgb.max(axis=-1), rgb.min(axis=-1)
    delta = v - low
    safe_delta = np.maximum(delta, 1e-8)
    hue = np.where(v == r, (g - b) / safe_delta,
                   np.where(v == g, 2 + (b - r) / safe_delta, 4 + (r - g) / safe_delta))
    hue = np.where(delta > 1e-8, (hue * 60) % 360, 0)
    return hue, delta / np.maximum(v, 1e-8), v


def classify(rgb):
    """Soft, ordered masks tuned against the eight supplied building families.

    Each interval has smooth transition shoulders, rather than an RGB cutoff.
    Dark: V .10-.23. Glass: H 185-245, S .35-.55, V .16-.30.
    Paper/cream/tape: S below .22-.38 and V above .70-.82.
    Metal: S below .10-.22, V .22-.34 through .72-.82.
    Wood: H 16-44, S above .52-.64, V below .70-.82.
    Kraft: H 20-55, S .20-.34 through .66-.80, V .22-.35
    through .82-.94. Remaining saturated colours are plastic. A neutral
    fallback is paper, so desaturated paint is not mistaken for more metal.

    The darker, more saturated wood selection avoids putting grain on the
    main tan cardboard walls. These materials genuinely overlap in colour.
    """
    h, s, v = rgb_hsv(rgb)
    raw = {
        "dark": 1 - smoothstep(.10, .23, v),
        "glass": band(h, 185, 198, 232, 245) * smoothstep(.35, .55, s)
                 * smoothstep(.16, .30, v),
        "paper": (1 - smoothstep(.22, .38, s)) * smoothstep(.70, .82, v),
        "metal": (1 - smoothstep(.10, .22, s)) * band(v, .22, .34, .72, .82),
        "wood": band(h, 16, 24, 38, 44) * smoothstep(.52, .64, s)
                * band(v, .20, .32, .70, .82),
        "cardboard": band(h, 20, 28, 47, 55) * band(s, .20, .34, .66, .80)
                    * band(v, .22, .35, .82, .94),
    }
    remaining = np.ones(v.shape, dtype=np.float32)
    masks = {}
    for name, score in raw.items():
        masks[name] = remaining * score
        remaining *= 1 - score
    masks["plastic"] = remaining * smoothstep(.25, .50, s)
    masks["paper"] += remaining - masks["plastic"]
    # Pillow's Gaussian is fast, and 8-bit precision is adequate for weights.
    for name, mask in masks.items():
        im = Image.fromarray(np.rint(mask * 255).astype(np.uint8))
        masks[name] = np.asarray(im.filter(ImageFilter.GaussianBlur(MASK_BLUR)),
                                 dtype=np.float32) / 255.0
    total = np.maximum(sum(masks.values()), 1e-8)
    return {name: mask / total for name, mask in masks.items()}


def blur_float(field, sigma_y, sigma_x):
    """Small separable Gaussian for float heights, with no extra dependencies."""
    result = field
    for axis, sigma in enumerate((sigma_y, sigma_x)):
        radius = math.ceil(3 * sigma)
        offsets = np.arange(-radius, radius + 1, dtype=np.float32)
        weights = np.exp(-.5 * (offsets / sigma) ** 2)
        weights /= weights.sum()
        pads = [(0, 0), (0, 0)]
        pads[axis] = (radius, radius)
        padded = np.pad(result, pads, mode="reflect")
        result = np.zeros_like(field)
        for i, weight in enumerate(weights):
            slices = [slice(None), slice(None)]
            slices[axis] = slice(i, i + field.shape[axis])
            result += weight * padded[tuple(slices)]
    return result


def height_slopes(height, strength):
    dy, dx = np.gradient(height)
    xy = np.stack((-dx, dy), axis=-1)
    # Image rows run downward. Positive green is positive UV V (OpenGL),
    # hence +dy here, while red is -dx. Strength is RMS tangent slope.
    rms = np.sqrt(np.mean(np.sum(xy * xy, axis=-1)))
    xy *= strength / max(float(rms), 1e-8)
    return np.clip(xy, -strength * 3, strength * 3)


def normalize(normals):
    return normals / np.maximum(np.linalg.norm(normals, axis=-1, keepdims=True), 1e-8)


def make_maps(rgb, base_roughness, base_normal, seed=SEED):
    """Return float roughness, metalness, unit normals and material masks."""
    rgb = np.asarray(rgb)
    base_roughness = np.asarray(base_roughness, dtype=np.float32)
    base_normal = np.asarray(base_normal, dtype=np.float32)
    shape = rgb.shape[:2]
    if (rgb.ndim != 3 or rgb.shape[2] != 3 or min(shape) < 2
            or base_roughness.shape != shape or base_normal.shape != (*shape, 3)):
        raise ValueError("Colour, roughness and normal dimensions must match (at least 2x2)")
    if not np.isfinite(base_roughness).all() or not np.isfinite(base_normal).all():
        raise ValueError("Base maps contain non-finite values")
    masks = classify(rgb)
    # Keep 25% of variation around each class's original mean, rather than
    # pulling glossy glass toward Meshy's near-constant .46 baseline. Ignore
    # unused black atlas background when finding those means.
    used = rgb.max(axis=-1) > 20
    roughness = np.zeros(shape, dtype=np.float32)
    for name, mask in masks.items():
        weights = mask * used
        total = float(weights.sum())
        center = float((weights * base_roughness).sum() / total) if total > 1e-6 else .46
        material_roughness = TARGETS[name] + BASE_VARIATION * (base_roughness - center)
        if name == "glass":
            # Some real window texels have a .15 base amid .50 blue bricks.
            # Keep the variation, but avoid turning their negative deviation
            # into a near-zero mirror that magnifies Meshy's bake imperfections.
            material_roughness = np.clip(material_roughness, .04, .10)
        roughness += mask * material_roughness
    roughness = np.clip(roughness, .025, .98)
    metalness = .85 * masks["metal"]

    rng = np.random.default_rng(seed)
    detail_xy = np.zeros((*shape, 2), dtype=np.float32)
    # A height field per class; weight slopes, not heights. Differentiating a
    # mask-weighted height would add an unwanted ridge along every colour seam.
    for name, sy, sx, strength in (
        ("cardboard", .50, .65, .045),
        ("paper", .45, .45, .012),
        ("wood", .55, 7.0, .035),
        ("metal", .50, 14.0, .009),
        ("plastic", .65, .65, .0025),
        ("dark", .65, .65, .004),
    ):
        noise = rng.standard_normal(shape).astype(np.float32)
        height = blur_float(noise, sy, sx)
        strength *= BUMP
        slopes = height_slopes(height, strength)
        if name == "cardboard":
            fibres = (rng.random(shape) < .009) * rng.uniform(-1, 1, shape)
            fibres = blur_float(fibres.astype(np.float32), .50, 3.0)
            slopes = .8 * slopes + height_slopes(fibres, strength * .20)
        detail_xy += masks[name][..., None] * slopes
    # Glass deliberately contributes no micro detail. UDN combination preserves
    # the base Z and adds the tiny tangent XY detail, then renormalises.
    normals = base_normal * 2 - 1
    invalid = ((base_normal.max(axis=-1) == 0)
               | (np.linalg.norm(normals, axis=-1) < 1e-6))
    normals[invalid] = (0, 0, 1)
    normals = normalize(normals)
    detail = normalize(np.concatenate((detail_xy, np.ones((*shape, 1), dtype=np.float32)), axis=-1))
    normals[..., :2] += detail[..., :2]
    normals = normalize(normals)
    return roughness, metalness, normals, masks


def save_image(path, pixels):
    """Replace a PNG only after its complete new version has been saved."""
    with tempfile.NamedTemporaryFile(dir=path.parent, suffix=".png", delete=False) as handle:
        temporary = Path(handle.name)
    try:
        Image.fromarray(pixels).save(temporary, format="PNG")
        temporary.replace(path)
    finally:
        temporary.unlink(missing_ok=True)


def preserve_base(path):
    base = path.with_name(path.stem + "-base.png")
    if not base.exists():
        shutil.copyfile(path, base)
    return base


def process_piece(color_path):
    prefix = color_path.name[:-len("-color.png")]
    folder = color_path.parent
    normal_path = folder / (prefix + "-normal.png")
    roughness_path = folder / (prefix + "-roughness.png")
    record_path = folder / (prefix + ".upload.json")
    record = None
    if record_path.exists():
        record = json.loads(record_path.read_text(encoding="utf-8-sig"))
        if not isinstance(record, dict):
            raise ValueError(str(record_path) + " must contain a JSON object")
    # Validate source files before keeping baselines or changing anything.
    normal_base = normal_path.with_name(normal_path.stem + "-base.png")
    roughness_base = roughness_path.with_name(roughness_path.stem + "-base.png")
    with Image.open(color_path) as im:
        rgb = np.asarray(im.convert("RGB"))
    with Image.open(normal_base if normal_base.exists() else normal_path) as im:
        normal = np.asarray(im.convert("RGB"), dtype=np.float32) / 255.0
    with Image.open(roughness_base if roughness_base.exists() else roughness_path) as im:
        roughness = np.asarray(im.convert("L"), dtype=np.float32) / 255.0
    seed = SEED ^ zlib.crc32(prefix.encode("utf-8"))
    roughness, metalness, normals, masks = make_maps(rgb, roughness, normal, seed)
    preserve_base(normal_path)
    preserve_base(roughness_path)
    save_image(roughness_path, np.rint(roughness * 255).astype(np.uint8))
    save_image(folder / (prefix + "-metalness.png"), np.rint(metalness * 255).astype(np.uint8))
    save_image(normal_path, np.rint(np.clip(normals * .5 + .5, 0, 1) * 255).astype(np.uint8))
    if record is not None and any(key in record for key in ("normal", "roughness", "metalness")):
        for key in ("normal", "roughness", "metalness"):
            record.pop(key, None)
        with tempfile.NamedTemporaryFile(mode="w", encoding="utf-8", dir=folder,
                                         suffix=".json", delete=False) as handle:
            temporary = Path(handle.name)
            json.dump(record, handle, indent=2)
            handle.write("\n")
        try:
            temporary.replace(record_path)
        finally:
            temporary.unlink(missing_ok=True)
    used = rgb.max(axis=-1) > 20
    return {name: float(mask[used].mean()) if used.any() else 0 for name, mask in masks.items()}


BLENDER_HELPER = r'''
import bpy
import math
import sys
from pathlib import Path
from mathutils import Vector

folder, output = (Path(value) for value in sys.argv[sys.argv.index("--") + 1:])
parts = folder / "parts"
prefixes = {p.name[:-len("-color.png")] for p in parts.glob("*-color.png")}
scene = bpy.context.scene
pieces = []
seen = set()
for obj in scene.objects:
    if obj.type != "MESH":
        continue
    matched = []
    for mat in obj.data.materials:
        if not mat or not mat.use_nodes:
            continue
        for node in mat.node_tree.nodes:
            if node.type != "TEX_IMAGE" or not node.image:
                continue
            for name in (node.image.name, Path(node.image.filepath).name):
                name = name.removesuffix(".png")
                if name.endswith("-color") and name[:-6] in prefixes:
                    matched.append((mat, name[:-6]))
                    break
    if not matched:
        obj.hide_render = True
        continue
    for mat, prefix in matched:
        pieces.append((obj, mat, prefix))
        seen.add(prefix)
    obj.hide_render = False
    obj.hide_set(False)
if seen != prefixes:
    raise RuntimeError("Baked mesh/image matching failed for: " + ", ".join(sorted(prefixes - seen)))
if len(pieces) != len(prefixes):
    raise RuntimeError("Expected exactly one baked material per piece")

images = {}
def image(path, color=False):
    key = str(path)
    if key not in images:
        im = bpy.data.images.load(key, check_existing=False)
        im.colorspace_settings.name = "sRGB" if color else "Non-Color"
        images[key] = im
    return images[key]

def swap(after):
    for obj, mat, prefix in pieces:
        nodes, links = mat.node_tree.nodes, mat.node_tree.links
        bsdf = next(n for n in nodes if n.type == "BSDF_PRINCIPLED")
        for channel, socket in (("color", "Base Color"), ("roughness", "Roughness"), ("normal", "Normal")):
            tex = nodes.get(channel)
            if tex is None or tex.type != "TEX_IMAGE":
                tex = nodes.new("ShaderNodeTexImage")
                tex.name = channel
            suffix = "-base" if not after and channel != "color" else ""
            tex.image = image(parts / (prefix + "-" + channel + suffix + ".png"), channel == "color")
            tex.interpolation = "Linear"
            tex.extension = "EXTEND"
            if channel == "normal":
                normal = next((n for n in nodes if n.type == "NORMAL_MAP"), None)
                if normal is None:
                    normal = nodes.new("ShaderNodeNormalMap")
                normal.space = "TANGENT"
                normal.uv_map = obj.data.uv_layers.active.name
                normal.inputs["Strength"].default_value = 1.0
                links.new(tex.outputs["Color"], normal.inputs["Color"])
                links.new(normal.outputs["Normal"], bsdf.inputs["Normal"])
            else:
                links.new(tex.outputs["Color"], bsdf.inputs[socket])
        for link in list(bsdf.inputs["Metallic"].links):
            links.remove(link)
        bsdf.inputs["Metallic"].default_value = 0.0
        if after:
            tex = nodes.get("metalness") or nodes.new("ShaderNodeTexImage")
            tex.name = "metalness"
            tex.image = image(parts / (prefix + "-metalness.png"))
            links.new(tex.outputs["Color"], bsdf.inputs["Metallic"])

scene.render.engine = "BLENDER_EEVEE"
scene.render.resolution_x, scene.render.resolution_y = 1000, 800
scene.render.resolution_percentage = 100
scene.render.image_settings.file_format = "PNG"
scene.render.image_settings.color_mode = "RGBA"
scene.render.image_settings.color_depth = "8"
scene.render.film_transparent = True
scene.render.use_compositing = False
scene.render.use_sequencer = False
scene.eevee.taa_render_samples = 128
scene.eevee.use_raytracing = True
scene.eevee.ray_tracing_method = "SCREEN"
scene.view_settings.view_transform = "AgX"
scene.view_settings.look = "None"
scene.view_settings.exposure = 0
scene.view_settings.gamma = 1

objects = list({obj for obj, mat, prefix in pieces})
corners = [obj.matrix_world @ Vector(corner) for obj in objects for corner in obj.bound_box]
lo = Vector(tuple(min(c[i] for c in corners) for i in range(3)))
hi = Vector(tuple(max(c[i] for c in corners) for i in range(3)))
center, extent = (lo + hi) / 2, max(hi - lo)
for obj in list(scene.objects):
    if obj.type in {"LIGHT", "CAMERA", "LIGHT_PROBE"}:
        bpy.data.objects.remove(obj, do_unlink=True)

world = bpy.data.worlds.new("Material comparison daylight")
world.use_nodes = True
scene.world = world
sky = world.node_tree.nodes.new("ShaderNodeTexSky")
sky.sky_type = "MULTIPLE_SCATTERING"
sky.sun_elevation = math.radians(32)
sky.sun_rotation = math.radians(232)
sky.sun_disc = True
world.node_tree.nodes["Background"].inputs["Strength"].default_value = .30
world.node_tree.links.new(sky.outputs["Color"], world.node_tree.nodes["Background"].inputs["Color"])

bpy.ops.object.light_add(type="SUN")
sun = bpy.context.object
sun.data.energy = 2.0
sun.data.angle = math.radians(6)
sun.rotation_euler = Vector((.62, .80, -.62)).to_track_quat("-Z", "Y").to_euler()

# A large window-shaped fill gives glossy planes a readable soft highlight.
# The same sun, sky, fill, floor and camera are used for both passes.
bpy.ops.object.light_add(type="AREA", location=center + Vector((-.8, -1.4, -.1)) * extent)
fill = bpy.context.object
fill.data.energy = 20 * extent * extent
fill.data.shape = "RECTANGLE"
fill.data.size, fill.data.size_y = extent * 1.5, extent * 2.0
fill.rotation_euler = (center - fill.location).to_track_quat("-Z", "Y").to_euler()

bpy.ops.mesh.primitive_plane_add(size=extent * 12, location=(center.x, center.y, lo.z - extent * .002))
floor = bpy.context.object
floor.name = "Comparison floor (temporary)"
mat = bpy.data.materials.new("Comparison matte floor")
mat.use_nodes = True
mat.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (.32, .34, .37, 1)
mat.node_tree.nodes["Principled BSDF"].inputs["Roughness"].default_value = .8
floor.data.materials.append(mat)

bpy.ops.object.camera_add()
camera = bpy.context.object
scene.camera = camera
direction = Vector((.62, -1, .32)).normalized()
rotation = (-direction).to_track_quat("-Z", "Y")
right, up = rotation @ Vector((1, 0, 0)), rotation @ Vector((0, 1, 0))
x, y = [c.dot(right) for c in corners], [c.dot(up) for c in corners]
center += right * ((max(x) + min(x)) / 2 - center.dot(right))
center += up * ((max(y) + min(y)) / 2 - center.dot(up))
camera.location = center + direction * extent * 4
camera.rotation_euler = rotation.to_euler()
camera.data.type = "ORTHO"
camera.data.ortho_scale = max(max(x) - min(x), (max(y) - min(y)) * 1.25) * 1.10
camera.data.clip_start = extent * .001
camera.data.clip_end = extent * 30
for after, label in ((False, "before"), (True, "after")):
    swap(after)
    scene.render.filepath = str(output / (label + ".png"))
    bpy.ops.render.render(write_still=True)
print("MATERIAL_COMPARE rendered " + str(len(pieces)) + " baked pieces in both passes", flush=True)
'''


def render_compare(folder):
    """Render without modifying hero.blend; helper, frames and log are temporary."""
    with tempfile.TemporaryDirectory(prefix="flyfight-materials-") as directory:
        work = Path(directory)
        helper = work / "compare.py"
        helper.write_text(BLENDER_HELPER, encoding="utf-8")
        env = os.environ.copy()
        # Keep Blender's startup/cache writes inside the temporary directory.
        env["BLENDER_USER_CONFIG"] = str(work / "config")
        env["BLENDER_USER_EXTENSIONS"] = str(work / "extensions")
        command = [str(BLENDER), "--factory-startup", "-b", str(folder / "hero.blend"),
                   "--python-exit-code", "1", "--python", str(helper), "--", str(folder), str(work)]
        print("Rendering BEFORE/AFTER for " + folder.name + ".", flush=True)
        with (work / "blender.log").open("w", encoding="utf-8") as log:
            result = subprocess.run(command, stdout=log, stderr=subprocess.STDOUT,
                                    env=env, timeout=600,
                                    creationflags=subprocess.CREATE_NO_WINDOW if os.name == "nt" else 0)
        if result.returncode:
            tail = (work / "blender.log").read_text(encoding="utf-8", errors="replace").splitlines()[-16:]
            raise RuntimeError("Blender comparison failed:\n" + "\n".join(tail))
        canvas = Image.new("RGB", (2000, 800), (231, 235, 239))
        for x, label in ((0, "before"), (1000, "after")):
            with Image.open(work / (label + ".png")) as frame:
                if frame.size != (1000, 800):
                    raise RuntimeError("Unexpected comparison frame size")
                canvas.paste(frame.convert("RGB"), (x, 0), frame.getchannel("A"))
        draw = ImageDraw.Draw(canvas)
        draw.rectangle((0, 0, 2000, 35), fill=(245, 245, 245))
        font = ImageFont.load_default(size=22)
        draw.text((16, 5), "BEFORE | original base maps", fill=(25, 25, 25), font=font)
        draw.text((1016, 5), "AFTER | material maps", fill=(25, 25, 25), font=font)
        draw.line((1000, 0, 1000, 800), fill=(90, 90, 90), width=2)
        output = folder / "renders" / "material-compare.png"
        output.parent.mkdir(exist_ok=True)
        save_image(output, np.asarray(canvas))
    print("Comparison: " + str(output), flush=True)


def selftest():
    rgb = np.empty((64, 64, 3), dtype=np.uint8)
    rgb[:32, :32] = (230, 20, 20)       # plastic
    rgb[:32, 32:] = (180, 139, 91)      # kraft
    rgb[32:, :32] = (128, 128, 128)     # metal
    rgb[32:, 32:] = (20, 98, 185)       # glass
    base_r = np.full((64, 64), .46, dtype=np.float32)
    base_n = np.empty((64, 64, 3), dtype=np.float32)
    base_n[:] = (.5, .5, 1)
    roughness, metalness, normals, masks = make_maps(rgb, base_r, base_n)
    centers = {"plastic": (16, 16), "cardboard": (16, 48), "metal": (48, 16), "glass": (48, 48)}
    for name, (y, x) in centers.items():
        assert masks[name][y, x] > .95, (name, "wrong class", masks[name][y, x])
        assert abs(float(roughness[y, x]) - TARGETS[name]) < .025, (name, roughness[y, x])
        expected = .85 if name == "metal" else 0
        assert abs(float(metalness[y, x]) - expected) < .02, (name, metalness[y, x])
    np.testing.assert_allclose(np.linalg.norm(normals, axis=-1), 1, atol=2e-6)
    encoded = np.rint((normals * .5 + .5) * 255).astype(np.uint8)
    decoded = encoded.astype(np.float32) / 255 * 2 - 1
    np.testing.assert_allclose(np.linalg.norm(decoded, axis=-1), 1, atol=.007)
    assert np.max(np.abs(normals[40:56, 40:56, :2])) < 1e-6, "Glass gained micro detail"
    second = make_maps(rgb, base_r, base_n)
    for first, again in zip((roughness, metalness, normals), second[:3]):
        np.testing.assert_array_equal(first, again)
    # Preserve ordinary source variation at 25%, but bound extreme glass dips.
    plastic_rgb = np.empty_like(rgb)
    plastic_rgb[:] = (230, 20, 20)
    varied_r = np.broadcast_to(np.linspace(.36, .56, 64, dtype=np.float32), (64, 64))
    varied = make_maps(plastic_rgb, varied_r, base_n)[0]
    np.testing.assert_allclose(varied, TARGETS["plastic"] + BASE_VARIATION * (varied_r - .46), atol=1e-6)
    plastic_rgb[:] = (20, 98, 185)
    extreme_r = np.broadcast_to(np.linspace(.15, .65, 64, dtype=np.float32), (64, 64))
    glass = make_maps(plastic_rgb, extreme_r, base_n)[0]
    assert float(glass.min()) >= .04 - 1e-6 and float(glass.max()) <= .10 + 1e-6
    # File-level checks prove reruns read baselines and preserve uploader IDs.
    with tempfile.TemporaryDirectory(prefix="flyfight-material-test-") as directory:
        parts = Path(directory)
        prefix = "1-test"
        Image.fromarray(rgb).save(parts / (prefix + "-color.png"))
        Image.fromarray(np.full((64, 64), 117, dtype=np.uint8)).save(parts / (prefix + "-roughness.png"))
        Image.fromarray(np.rint(base_n * 255).astype(np.uint8)).save(parts / (prefix + "-normal.png"))
        record = {"model": "keep-model", "mesh": "keep-mesh", "color": "keep-color",
                  "initial": [1, 2, 3], "colour": "also-keep", "normal": "old",
                  "roughness": "old", "metalness": "old"}
        upload = parts / (prefix + ".upload.json")
        upload.write_text(json.dumps(record), encoding="utf-8")
        original = {p.name: p.read_bytes() for p in parts.glob("*.png")}
        process_piece(parts / (prefix + "-color.png"))
        after = {p.name: p.read_bytes() for p in parts.iterdir()}
        process_piece(parts / (prefix + "-color.png"))
        assert after == {p.name: p.read_bytes() for p in parts.iterdir()}, "Rerun stacked changes"
        for channel in ("normal", "roughness"):
            assert original[prefix + "-" + channel + ".png"] == after[prefix + "-" + channel + "-base.png"]
        assert original[prefix + "-color.png"] == after[prefix + "-color.png"]
        assert json.loads(upload.read_text()) == {k: v for k, v in record.items()
                                                 if k not in ("normal", "roughness", "metalness")}
    print("SELFTEST PASS: class ranges, metalness, unit normals, deterministic reruns, original maps and upload IDs")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("folder", type=Path)
    parser.add_argument("--render", action="store_true", help="Render a Blender BEFORE/AFTER comparison")
    args = parser.parse_args()
    folder = args.folder.resolve()
    colors = sorted((folder / "parts").glob("*-color.png"))
    if not colors:
        parser.error("No *-color.png pieces found in " + str(folder / "parts"))
    if args.render and (not BLENDER.is_file() or not (folder / "hero.blend").is_file()):
        parser.error("--render needs D:/Blender/blender.exe and FOLDER/hero.blend")
    for color in colors:
        fractions = process_piece(color)
        summary = ", ".join(name + " " + str(round(value * 100)) + "%"
                            for name, value in fractions.items() if value >= .03)
        print(color.stem.removesuffix("-color") + ": " + summary, flush=True)
    print("Updated " + str(len(colors)) + " pieces; original maps preserved.", flush=True)
    if args.render:
        render_compare(folder)


if __name__ == "__main__":
    if "--selftest" in sys.argv:
        selftest()
    else:
        main()
