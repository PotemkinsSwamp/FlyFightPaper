"""Temporary source preview only: no UV packing or texture baking."""
import sys
sys.dont_write_bytecode = True
import importlib.util
from pathlib import Path
import bpy

root = Path(__file__).resolve().parents[4]
name = sys.argv[sys.argv.index('--') + 1] if '--' in sys.argv else 'pencil-case-bridge'
assert name in ('pencil-case-bridge', 'egg-carton-market')
folder = root / 'assets/models' / name
height = 140 if name == 'pencil-case-bridge' else 55
spec = importlib.util.spec_from_file_location('preview_recipe',
    folder / 'touchup.py' if name == 'pencil-case-bridge' else root / 'tools/art/hero.py')
recipe = importlib.util.module_from_spec(spec)
spec.loader.exec_module(recipe)
hero = recipe.hero if name == 'pencil-case-bridge' else recipe
bpy.ops.wm.read_factory_settings(use_empty=True)
source, front = hero.import_source(folder, height, '-y')
hero.touch_up(source, folder)
hero.render_views([source], folder / 'renders', height)
print('SOURCE PREVIEW ONLY: complete', flush=True)
