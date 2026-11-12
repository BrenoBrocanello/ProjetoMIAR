"""Confere a fonte aprovada sem modificar o PDF."""
from pathlib import Path
import hashlib
import json
import os

ROOT = Path(__file__).resolve().parent.parent
meta = json.loads((ROOT / 'docs/MASTER.json').read_text(encoding='utf-8'))
master = ROOT / meta['arquivo']
assert hashlib.sha256(master.read_bytes()).hexdigest() == meta['sha256'], 'MASTER alterada'
allowed = {master}
if meta.get('editavel'):
    editavel = ROOT / meta['editavel']
    assert hashlib.sha256(editavel.read_bytes()).hexdigest() == meta['editavel_sha256'], 'Word MASTER alterado'
    allowed.add(editavel)
skip = {'node_modules', '.git', '.dart_tool', 'build', '.venv', 'venv'}
others = []
for current, dirs, files in os.walk(ROOT):
    dirs[:] = [name for name in dirs if name not in skip]
    for name in files:
        p = Path(current) / name
        if p.suffix.lower() in {'.pdf', '.docx', '.doc', '.odt'} and p not in allowed:
            others.append(p)
assert not others, f'Outras especificacoes no projeto: {others}'
print(f'MASTER OK: {meta["arquivo"]}; SHA-256 {meta["sha256"]}; Word pareado quando informado; sem documentos concorrentes.')
