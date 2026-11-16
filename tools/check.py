#!/usr/bin/env python3
"""Run the headless checks and fail on script errors, not only exit codes."""
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parent.parent
GAME = ROOT / 'game'
GODOT = os.environ.get('GODOT_BIN') or shutil.which('godot')
if not GODOT:
    raise SystemExit('Godot 4.6 is required. Set GODOT_BIN or add godot to PATH.')

# Pack files are plain data: catch broken JSON and missing files before Godot does.
packs = sorted(path for path in (GAME / 'dimensions').iterdir() if (path / 'pack.json').exists())
for folder in packs:
    pack = json.loads((folder / 'pack.json').read_text())
    named = [pack.get('surface_shader'), pack.get('animator'), pack.get('overlay', {}).get('shader'), pack.get('outline', {}).get('shader')]
    named += [role.get('shader') for role in pack.get('roles', {}).values()]
    for name in filter(None, named):
        if not name.startswith('res://') and not (folder / name).exists():
            raise SystemExit(f'FAIL: {folder.name}/pack.json names a missing file: {name}')
if len(packs) < 3:
    raise SystemExit('FAIL: expected at least three dimension packs')
print(f'PASS: {len(packs)} dimension packs are well formed')


def run(extra, tag, marker=None):
    logfile = Path(tempfile.gettempdir()) / f'paper-plastic-pew-check-{tag}.log'
    command = [GODOT, '--headless', '--path', str(GAME), '--log-file', str(logfile), *extra]
    try:
        result = subprocess.run(command, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, timeout=120)
    except subprocess.TimeoutExpired as error:
        output = error.stdout.decode() if isinstance(error.stdout, bytes) else (error.stdout or '')
        print(output)
        raise SystemExit(f'FAIL: {tag} timed out (a script error stops the smoke run)')
    output = result.stdout
    bad = ['ERROR:', 'Parse Error', 'Assertion failed', 'SMOKE FAIL']
    if result.returncode or any(text in output for text in bad) or (marker and marker not in output):
        print(output)
        raise SystemExit(f'FAIL: {tag}; log: {logfile}')
    print('\n'.join(line for line in output.splitlines() if marker and line.startswith(marker)) or f'PASS: {tag}')


run(['--editor', '--import', '--quit'], 'import')
run(['--', '--smoke'], 'smoke', 'SMOKE PASS:')
