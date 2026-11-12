"""Executa a verificacao nativa fora do terminal interativo, preservando os resultados."""
from pathlib import Path
import json, os, subprocess, sys

ROOT = Path(__file__).resolve().parent.parent
OUT = Path(os.environ['MIAR_AUDIT_DIR'])
OUT.mkdir(parents=True, exist_ok=True)
steps = []
with (OUT/'orquestracao.txt').open('w', encoding='utf-8') as log:
    for script, args in [('validar-android.py', ['dispositivo']), ('ensaiar-app.py', [])]:
        p = subprocess.run([sys.executable, str(ROOT/'scripts'/script), *args], cwd=ROOT,
                           stdout=log, stderr=subprocess.STDOUT, creationflags=subprocess.CREATE_NO_WINDOW)
        steps.append({'script': script, 'argumentos': args, 'exit_code': p.returncode})
        (OUT/'orquestracao.json').write_text(json.dumps(steps, indent=2), encoding='utf-8')
        if p.returncode:
            raise SystemExit(p.returncode)
