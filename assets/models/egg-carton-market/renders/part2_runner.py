"""Temporary, narrowly scoped Part 2 commands. Remove after the checks finish."""
import ctypes
import ctypes.wintypes as w
import json
import os
from pathlib import Path
import subprocess
import sys
import time

ROOT = Path(__file__).resolve().parents[4]
BLENDER = Path('D:/Blender/blender.exe')
NAMES = ['porthole-book-tower', 'tissue-box-tower', 'tape-roll-tower', 'juice-carton-tower',
         'cereal-box-tower', 'paint-jar-tower', 'pencil-case-bridge', 'egg-carton-market']
os.environ['PYTHONDONTWRITEBYTECODE'] = '1'


def processes():
    kernel = ctypes.WinDLL('kernel32', use_last_error=True)
    native = ctypes.WinDLL('ntdll')
    kernel.OpenProcess.argtypes = [w.DWORD, w.BOOL, w.DWORD]
    kernel.OpenProcess.restype = w.HANDLE
    kernel.CloseHandle.argtypes = [w.HANDLE]
    native.NtQueryInformationProcess.argtypes = [w.HANDLE, w.ULONG, w.LPVOID, w.ULONG, ctypes.POINTER(w.ULONG)]
    class UnicodeString(ctypes.Structure):
        _fields_ = [('Length', w.USHORT), ('MaximumLength', w.USHORT), ('Buffer', w.LPVOID)]
    query = subprocess.run(['powershell', '-NoProfile', '-Command',
                            'Get-Process -Name blender -ErrorAction SilentlyContinue | ForEach-Object Id'],
                           capture_output=True, text=True)
    result = []
    for pid in query.stdout.split():
        handle = kernel.OpenProcess(0x1000, False, int(pid))
        if not handle:
            result.append((int(pid), 'UNKNOWN'))
            continue
        try:
            size = w.ULONG()
            native.NtQueryInformationProcess(handle, 60, None, 0, ctypes.byref(size))
            if not size.value:
                result.append((int(pid), 'UNKNOWN'))
                continue
            buffer = ctypes.create_string_buffer(size.value)
            status = native.NtQueryInformationProcess(handle, 60, buffer, size.value, ctypes.byref(size))
            value = UnicodeString.from_buffer(buffer)
            result.append((int(pid), ctypes.wstring_at(value.Buffer, value.Length // 2) if status == 0 else 'UNKNOWN'))
        finally:
            kernel.CloseHandle(handle)
    return result


def gate(need_six=True):
    missing = [n for n in NAMES[:6] if need_six and not (ROOT / 'assets/models' / n / 'parts.json').is_file()]
    busy = [(pid, cmd) for pid, cmd in processes()
            if cmd == 'UNKNOWN' or 'hero.py' in cmd or 'bake_closed.py' in cmd or 'touchup.py' in cmd]
    if missing or busy:
        raise RuntimeError(f'Waiting for bakes: missing={missing}, active={busy}')


def run_blender(folder, arguments, log, bake=False):
    if bake:
        gate()
    else:
        # Read-only inspection can run while another folder bakes. Never inspect
        # a scene whose own baker is currently replacing its geometry and maps.
        target = str(folder.resolve()).replace('\\', '/').lower()
        busy = [cmd for pid, cmd in processes() if target in cmd.replace('\\', '/').lower()
                and any(name in cmd for name in ('hero.py', 'bake_closed.py', 'touchup.py'))]
        if busy:
            raise RuntimeError('This building is still baking')
    with (folder / log).open('w', encoding='utf-8') as output:
        child = subprocess.Popen([str(BLENDER), '-b', *arguments], cwd=ROOT,
                                 stdout=output, stderr=subprocess.STDOUT)
        while child.poll() is None:
            if bake:
                other = [(pid, cmd) for pid, cmd in processes() if pid != child.pid and '--verify' not in cmd
                         and any(p in cmd for p in ('hero.py', 'bake_closed.py', 'touchup.py'))]
                if other and child.poll() is None:
                    child.terminate()
                    child.wait()
                    raise RuntimeError('Stopped this bake because another hero bake started')
            time.sleep(5)
    print(log, 'exit', child.returncode, flush=True)
    if child.returncode:
        print('\n'.join((folder / log).read_text(errors='replace').splitlines()[-25:]))
        raise SystemExit(child.returncode)


if __name__ == '__main__':
    action = sys.argv[1]
    if action == 'status':
        print(json.dumps({'processes': processes(), 'parts': {n: (ROOT / 'assets/models' / n / 'parts.json').is_file()
                                                            for n in NAMES}}, indent=2))
    else:
        name = sys.argv[2]
        assert name in NAMES
        folder = ROOT / 'assets/models' / name
        if action == 'bake':
            assert name in NAMES[-2:]
            height, splits = ((140, 'ground-floor:xy,upper-walls:xy,roof:xy,topper:xy')
                              if name == 'pencil-case-bridge' else (55, 'ground-floor:xy,upper-walls:y'))
            script = ('assets/models/pencil-case-bridge/touchup.py' if name == 'pencil-case-bridge'
                      else 'assets/models/porthole-book-tower/renders/bake_closed.py')
            run_blender(folder, ['--factory-startup', '-t', '4', '--python-exit-code', '1', '--python',
                        script, '--', str(folder),
                        '--height', str(height), '--front', '-y', '--vertical-splits', splits,
                        '--detail', '2.5', '--min-coverage', '0.33'], 'bake.log', bake=True)
        elif action == 'closeups':
            run_blender(folder, [str(folder / 'hero.blend'), '-t', '4', '--python-exit-code', '1', '--python',
                                'tools/art/closeups.py', '--', str(folder)], 'renders/closeups.log')
            from PIL import Image
            with Image.open(folder / 'renders/closeups.png') as image:
                image.convert('RGB').save(folder / 'renders/closeups.jpg', quality=95)
        elif action == 'textures':
            gate(need_six=name not in NAMES[:3])
            source_files = [folder / 'hero.blend', folder / 'parts.json']
            source_stamp = [(p.stat().st_mtime_ns, p.stat().st_size) for p in source_files]
            import hashlib
            import importlib.util
            import numpy as np
            from PIL import Image
            spec = importlib.util.spec_from_file_location('fill_gaps', ROOT / 'tools/art/fill_gaps.py')
            fill = importlib.util.module_from_spec(spec)
            spec.loader.exec_module(fill)
            report = json.loads((folder / 'parts.json').read_text())
            prefixes = [p['prefix'] for p in report['pieces']]
            uvs = fill.read_uvs(folder / 'parts', prefixes, folder / 'hero.blend', BLENDER)
            before = {}
            masks = {}
            for prefix in prefixes:
                for channel in fill.CHANNELS:
                    path = folder / 'parts' / f'{prefix}-{channel}.png'
                    if not path.is_file():
                        continue
                    with Image.open(path) as image:
                        key = (prefix, image.size)
                        if key not in masks:
                            masks[key] = fill.island_mask(uvs[prefix], image.size, 3)
                        mask = masks[key]
                        before[path.name] = {'protected_sha256': hashlib.sha256(np.asarray(image)[mask].tobytes()).hexdigest(),
                                             'file_sha256': hashlib.sha256(path.read_bytes()).hexdigest(),
                                             'size': list(image.size), 'mode': image.mode,
                                             'protected_texels': int(mask.sum()), 'filled_texels': int((~mask).sum())}
            command = [sys.executable, '-B', str(ROOT / 'tools/art/fill_gaps.py'), str(folder / 'parts'),
                       '--uv', '--all', '--blender', str(BLENDER)]
            gate(need_six=name not in NAMES[:3])
            with (folder / 'renders/fill-gaps-uv.log').open('w', encoding='utf-8') as output:
                subprocess.run(command, cwd=ROOT, stdout=output, stderr=subprocess.STDOUT, check=True)
            gate(need_six=name not in NAMES[:3])
            assert source_stamp == [(p.stat().st_mtime_ns, p.stat().st_size) for p in source_files], 'Bake changed during texture fill'
            for prefix in prefixes:
                for channel in fill.CHANNELS:
                    path = folder / 'parts' / f'{prefix}-{channel}.png'
                    if path.name not in before:
                        continue
                    saved = before[path.name]
                    with Image.open(path) as image:
                        mask = masks[(prefix, image.size)]
                        assert list(image.size) == saved['size'] and image.mode == saved['mode']
                        assert hashlib.sha256(np.asarray(image)[mask].tobytes()).hexdigest() == saved['protected_sha256'], path.name
                    saved['protected_pixels_unchanged'] = True
                    saved['file_changed'] = hashlib.sha256(path.read_bytes()).hexdigest() != saved['file_sha256']
            (folder / 'renders/part2-texture-checks.json').write_text(json.dumps(
                {'mode': 'real UV islands', 'bleed_pixels': 3, 'maps': before}, indent=2) + '\n')
            from PIL import Image, ImageDraw, ImageFont
            font = ImageFont.truetype('C:/Windows/Fonts/arial.ttf', 21)
            for channel, filename in [('color', 'textures.png'), ('normal', 'textures-normal.png'),
                                      ('roughness', 'textures-roughness.png'), ('metalness', 'textures-metalness.png')]:
                paths = [folder / 'parts' / (p + '-' + channel + '.png') for p in prefixes]
                paths = [p for p in paths if p.is_file()]
                if not paths:
                    continue
                columns = 4
                sheet = Image.new('RGB', (columns * 1024, ((len(paths) + columns - 1) // columns) * 1058), 'white')
                draw = ImageDraw.Draw(sheet)
                for i, path in enumerate(paths):
                    x, y = i % columns * 1024, i // columns * 1058
                    draw.text((x + 8, y + 5), path.name, fill='black', font=font)
                    with Image.open(path) as image:
                        assert image.size == (1024, 1024)
                        sheet.paste(image.convert('RGB'), (x, y + 34))
                sheet.save(folder / 'renders' / filename)
            print(name, 'UV-filled and full-resolution sheets rebuilt', flush=True)
        else:
            raise ValueError(action)
