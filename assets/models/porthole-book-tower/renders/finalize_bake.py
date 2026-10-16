"""Sequential UV gap filling, packed-map refresh and saved-scene inspection."""
import subprocess
import sys
from pathlib import Path

folder = Path(sys.argv[1]).resolve()
helpers = Path(__file__).resolve().parent
blender = 'D:/Blender/blender.exe'
with (folder / 'renders' / 'fill-gaps-uv.log').open('w') as log:
    subprocess.run([sys.executable, 'tools/art/fill_gaps.py', str(folder / 'parts'),
                    '--uv', '--all', '--blender', blender],
                   stdout=log, stderr=subprocess.STDOUT, check=True)
with (folder / 'renders' / 'final-check.log').open('w') as log:
    subprocess.run([blender, '-b', str(folder / 'hero.blend'), '--python-exit-code', '1',
                    '--python', str(helpers / 'refresh_maps.py'),
                    '--python', 'tools/art/closeups.py',
                    '--python', str(helpers / 'inspect_bake.py'), '--', str(folder)],
                   stdout=log, stderr=subprocess.STDOUT, check=True)
subprocess.run([sys.executable, str(helpers / 'contact_sheets.py'), str(folder)], check=True)
print('Final saved-scene checks complete:', folder.name, flush=True)
