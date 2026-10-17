"""Build Rojo-managed content into the one working place, preserving saved native art."""
from pathlib import Path
import base64
import copy
import json
import re
import os
import shutil
import subprocess
import tempfile
import time
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
PLACE = ROOT / "FlyFightPaper-WORKING.rbxlx"


def name(item):
    return item.findtext('./Properties/string[@name="Name"]')


def child(parent, wanted):
    return next((i for i in parent.findall("Item") if name(i) == wanted), None)


def merge(destination, built, definition):
    for wanted, settings in definition.items():
        if wanted.startswith("$"):
            continue
        source = child(built, wanted)
        if source is None:
            raise ValueError(f"Rojo did not build {wanted}")
        old = child(destination, wanted)
        if "$path" in settings:
            if old is not None:
                destination.remove(old)
            destination.append(copy.deepcopy(source))
        else:
            if old is None:
                old = copy.deepcopy(source)
                destination.append(old)
            for property_name in settings.get("$properties", {}):
                value = source.find(f'./Properties/*[@name="{property_name}"]')
                if value is None:
                    raise ValueError(f"Missing built property {wanted}.{property_name}")
                props = old.find("Properties")
                previous = props.find(f'*[@name="{property_name}"]')
                if previous is not None:
                    props.remove(previous)
                props.append(copy.deepcopy(value))
            merge(old, source, settings)


COLLISION = ("PhysicalConfigData", "UnscaledCofm", "UnscaledVolInertiaDiags", "UnscaledVolInertiaOffDiags", "UnscaledVolume")
PRECISE = "3"  # CollisionFidelity.PreciseConvexDecomposition
PRECISE_HEADER = b"CSGPHS\x08\x00\x00\x00\x03"  # how a saved exact shape starts (Hull has \x01; checked in Studio)


def prop(item, wanted):
    return item.find(f'./Properties/*[@name="{wanted}"]')


def mesh_id(item):
    """Studio saves MeshId/url; Rojo builds write MeshContent/uri."""
    text = item.findtext('./Properties/Content[@name="MeshId"]/url') or item.findtext('./Properties/Content[@name="MeshContent"]/uri')
    return re.sub(r"\D", "", text or "")


def solid(item):
    """Visible and hit by flight (what HitShapes.exactRoom used to give an exact copy)."""
    flag = lambda n: (item.findtext(f'./Properties/bool[@name="{n}"]') or "true") == "true"
    return float(item.findtext('./Properties/float[@name="Transparency"]') or 0) < 1 and (flag("CanCollide") or flag("CanQuery"))


def exact_shapes(old_arena, new_arena, strings):
    """Every visible solid mesh in the room collides by its exact shape. Roblox's exact shapes take minutes to work out,
    so Studio does it once and the place stores the result (PhysicalConfigData); a rebuild writes parts without it.
    Reuse the shape last saved for the same mesh; a mesh never saved exact is marked exact for Studio to work out once
    (then Ctrl+S keeps it)."""
    def is_precise(item):
        data = prop(item, "PhysicalConfigData")
        blob = strings.get(data.text) if data is not None else None
        return blob is not None and base64.b64decode(blob)[:11] == PRECISE_HEADER
    saved = {}
    if old_arena is not None:
        for item in old_arena.iter("Item"):
            if item.get("class") == "MeshPart" and is_precise(item):
                saved.setdefault(mesh_id(item), [prop(item, n) for n in COLLISION])
    reused = marked = 0
    for item in new_arena.iter("Item"):
        if item.get("class") != "MeshPart" or not mesh_id(item) or not solid(item) or is_precise(item):
            continue
        props = item.find("Properties")
        for n in COLLISION + ("CollisionFidelity",):
            if (old := prop(item, n)) is not None:
                props.remove(old)
        if mesh_id(item) in saved:
            props.extend(copy.deepcopy(e) for e in saved[mesh_id(item)] if e is not None); reused += 1
        else:
            ET.SubElement(props, "token", name="CollisionFidelity").text = PRECISE; marked += 1
    print(f"Exact collision: {reused} parts reuse saved shapes, {marked} left for Studio: run tools/exact_collision.lua in Studio, wait, then Ctrl+S")


def main():
    rojo = shutil.which("rojo") or str(Path(os.environ["LOCALAPPDATA"]) / "Rojo/bin/rojo.exe")
    project = json.loads((ROOT / "default.project.json").read_text())
    original = ET.parse(PLACE)
    with tempfile.TemporaryDirectory(prefix="flyfight-build-") as directory:
        compiled = Path(directory) / "synced.rbxlx"
        subprocess.run([rojo, "build", str(ROOT / "default.project.json"), "-o", str(compiled)], check=True)
        generated = ET.parse(compiled).getroot()
        # Referents are local to the compiled document. Give them a disjoint namespace.
        existing = {i.get("referent") for i in original.getroot().iter("Item")}
        prefix = "ROJO_"
        while any((prefix + str(i.get("referent"))) in existing for i in generated.iter("Item")):
            prefix += "R_"
        for item in generated.iter("Item"):
            item.set("referent", prefix + item.get("referent"))
        for reference in generated.iter("Ref"):
            if reference.text and reference.text != "null":
                reference.text = prefix + reference.text
        old_arena = child(child(original.getroot(), "Workspace"), "Arena")
        merge(original.getroot(), generated, project["tree"])
        if "Arena" in project["tree"].get("Workspace", {}):
            workspace = child(original.getroot(), "Workspace")
            for obsolete_name in ("GreyboxRoom", "FlyFightPaperEditorPreview"):
                obsolete = child(workspace, obsolete_name)
                if obsolete is not None:
                    workspace.remove(obsolete)
        strings = generated.find("SharedStrings")
        if strings is not None:
            target = original.getroot().find("SharedStrings")
            if target is None:
                target = ET.SubElement(original.getroot(), "SharedStrings")
            keys = {s.get("md5") for s in target}
            for value in strings:
                if value.get("md5") not in keys:
                    target.append(copy.deepcopy(value))
        strings = {s.get("md5"): s.text for s in original.getroot().find("SharedStrings") or []}
        exact_shapes(old_arena, child(child(original.getroot(), "Workspace"), "Arena"), strings)
        items = list(original.getroot().iter("Item"))
        referents = [i.get("referent") for i in items]
        if len(referents) != len(set(referents)):
            raise ValueError("Duplicate instance reference; place was not replaced")
        pending = Path(directory) / "working.rbxlx"
        original.write(pending, encoding="utf-8", xml_declaration=True)
        ET.parse(pending)
        # Copy to the same volume, then atomically replace the single working file.
        intermediate = PLACE.with_suffix(".tmp")
        try:
            shutil.copyfile(pending, intermediate)
            for attempt in range(4):
                try:
                    os.replace(intermediate, PLACE)
                    break
                except PermissionError:
                    if attempt == 3:
                        raise
                    time.sleep(.25 * 2**attempt)
        finally:
            intermediate.unlink(missing_ok=True)
    print("Working place updated from Rojo; saved native art preserved.")


if __name__ == "__main__":
    main()
