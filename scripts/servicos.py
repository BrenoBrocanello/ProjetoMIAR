"""Supervisor de desenvolvimento: inicia apenas os serviços do MIAR e preserva os dados."""
import json
import os
import signal
import socket
import subprocess
import sys
import time
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
RUNTIME = ROOT / '.runtime'
RUNTIME.mkdir(exist_ok=True)
children = []
streams = []
exit_code = 0
env = os.environ.copy()
flags = subprocess.CREATE_NO_WINDOW if os.name == 'nt' else 0


def start(name, command, cwd, extra=None):
    log = (RUNTIME / f'{name}.log').open('a', encoding='utf-8')
    streams.append(log)
    proc = subprocess.Popen(command, cwd=cwd, env={**env, **(extra or {})}, stdout=log, stderr=log, creationflags=flags)
    children.append(proc)
    return proc


def wait_for(probe, name, seconds=120):
    for _ in range(seconds * 2):
        if any(p.poll() is not None for p in children):
            raise RuntimeError(f'Um serviço encerrou durante {name}. Consulte .runtime/*.log.')
        try:
            probe()
            return
        except Exception:
            time.sleep(.5)
    raise RuntimeError(f'Tempo excedido durante {name}. Consulte .runtime/*.log.')


def tcp(port):
    with socket.create_connection(('127.0.0.1', port), timeout=1):
        pass


try:
    for port in [3000, 8001, 9000, 55432]:
        try:
            tcp(port)
        except OSError:
            continue
        raise RuntimeError(f'A porta {port} já está em uso. Não foi iniciado outro serviço sobre ela.')
    (RUNTIME / 'supervisor.json').write_text(json.dumps({'pid': os.getpid(), 'projeto': str(ROOT)}), encoding='utf-8')
    for name in ['parar', 'parar-infra', 'pronto.json']:
        (RUNTIME / name).unlink(missing_ok=True)
    start('infra', ['node', 'scripts/infra-local.mjs'], ROOT / 'api')
    wait_for(lambda: tcp(9000), 'inicialização do banco/S3')
    for line in (ROOT / 'api/.env').read_text(encoding='utf-8').splitlines():
        if '=' in line and not line.startswith('#'):
            key, value = line.split('=', 1)
            env[key] = value
    python = ROOT / 'ia/.venv' / ('Scripts/python.exe' if os.name == 'nt' else 'bin/python')
    start('ia', [str(python), '-m', 'uvicorn', 'main:app', '--host', '127.0.0.1', '--port', '8001'], ROOT / 'ia')
    wait_for(lambda: urllib.request.urlopen('http://127.0.0.1:8001/health', timeout=2), 'carregamento do modelo de imagem', 240)
    start('api', ['node', 'dist/main.js'], ROOT / 'api')
    wait_for(lambda: tcp(3000), 'inicialização da API')
    (RUNTIME / 'pronto.json').write_text(json.dumps({'api': 'http://127.0.0.1:3000', 'pid': os.getpid()}), encoding='utf-8')
    print('MIAR disponível. Use parar-miar.ps1 para encerrar sem apagar os dados.', flush=True)
    while not (RUNTIME / 'parar').exists():
        if any(p.poll() is not None for p in children):
            raise RuntimeError('Um serviço encerrou. Consulte os logs em .runtime.')
        time.sleep(1)
except Exception as exc:
    print(str(exc), file=sys.stderr, flush=True)
    exit_code = 1
finally:
    (RUNTIME / 'pronto.json').unlink(missing_ok=True)
    for proc in reversed(children[1:]):
        if proc.poll() is None:
            proc.terminate()
    if children:
        (RUNTIME / 'parar-infra').touch()
        try:
            children[0].wait(timeout=20)
        except subprocess.TimeoutExpired:
            children[0].terminate()
    for stream in streams:
        stream.close()
    (RUNTIME / 'supervisor.json').unlink(missing_ok=True)
sys.exit(exit_code)
