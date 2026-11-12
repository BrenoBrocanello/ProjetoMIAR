"""Ensaio pela interface Flutter + seletores reais de foto/câmera do Android de teste."""
from pathlib import Path
from PIL import Image
import ctypes
import hashlib
import json
import os
import re
import subprocess
import sys
import threading
import time
import xml.etree.ElementTree as ET

sys.stdout.reconfigure(encoding='utf-8')
ROOT = Path(__file__).resolve().parent.parent
KIND = sys.argv[1] if len(sys.argv)>1 else 'completo'
if KIND not in {'completo','fotografia'}:
    raise SystemExit('Use completo ou fotografia.')
PREFIX = 'android-fotografia' if KIND=='fotografia' else 'android-ensaio'
BASE = Path(os.environ['LOCALAPPDATA'])
DEVICE = os.environ.get('MIAR_DEVICE', 'emulator-5560')
ADB = BASE / 'Android/Sdk/platform-tools/adb.exe'
OUT = Path(os.environ.get('MIAR_AUDIT_DIR', str(ROOT / 'evidencias/auditoria-2026-11-11')))
OUT.mkdir(parents=True, exist_ok=True)
STAGING = BASE / 'MiarDev' / hashlib.sha256(str(ROOT).encode()).hexdigest()[:10] / 'app'
FLAGS = subprocess.CREATE_NO_WINDOW


def adb(*args, timeout=12):
    return subprocess.run([str(ADB), '-s', DEVICE, *args], capture_output=True, timeout=timeout, creationflags=FLAGS)


avd = adb('shell', 'getprop', 'ro.boot.qemu.avd_name').stdout.decode().strip()
if avd not in {'MIAR_API35', 'MIAR_API26'}:
    avd = adb('emu', 'avd', 'name').stdout.decode().splitlines()[0].strip()
if avd not in {'MIAR_API35', 'MIAR_API26'}:
    raise SystemExit('Ensaio autorizado somente nos AVDs de teste MIAR_API35/MIAR_API26.')
adb('shell', 'mkdir', '-p', '/sdcard/Pictures/MIAR_AUDITORIA')
adb('push', str(ROOT / 'app/assets/img/hero-cao-gato.jpg'), '/sdcard/Pictures/MIAR_AUDITORIA/MIAR_AUDITORIA.jpg')
adb('shell', 'am', 'broadcast', '-a', 'android.intent.action.MEDIA_SCANNER_SCAN_FILE', '-d', 'file:///sdcard/Pictures/MIAR_AUDITORIA/MIAR_AUDITORIA.jpg')
stop = threading.Event()
state = {'mode': None, 'shutter': False, 'steps': []}


def native_ui():
    last_action = ('', 0)
    while not stop.wait(1):
        try:
            if not adb('shell', 'pidof', 'br.com.miar.miar').stdout.strip():
                continue
            for permission in ['ACCESS_COARSE_LOCATION', 'ACCESS_FINE_LOCATION', 'POST_NOTIFICATIONS']:
                adb('shell', 'pm', 'grant', 'br.com.miar.miar', 'android.permission.' + permission)
            adb('emu', 'geo', 'fix', '-46.8978', '-23.1857')
            mode = state['mode']
            if not mode:
                continue
            adb('shell', 'uiautomator', 'dump', '/sdcard/miar-auditoria.xml', timeout=15)
            raw = adb('shell', 'cat', '/sdcard/miar-auditoria.xml').stdout
            (OUT / 'seletor-nativo-ultima.xml').write_bytes(raw)
            nodes = list(ET.fromstring(raw).iter('node'))
            packages = {n.get('package', '') for n in nodes}
            target = None
            # Permissões do aplicativo de câmera são concedidas pelo próprio diálogo.
            for n in nodes:
                if any(p in n.get('package', '') for p in ['permissioncontroller','packageinstaller']) and any(v in n.get('resource-id', '') for v in ['permission_allow_foreground_only_button', 'permission_allow_button']):
                    target = n
                    break
            if target is None and mode == 'gps':
                target = next((n for n in nodes if n.get('package') == 'com.google.android.gms'
                               and n.get('text', '').strip().lower() in {'ok', 'turn on', 'ativar'}), None)
            if target is None and mode == 'camera' and any('camera' in p for p in packages):
                for n in nodes:
                    text = (n.get('text', '') + ' ' + n.get('content-desc', '')).strip().lower()
                    if n.get('clickable') == 'true' and text in {'next', 'skip', 'not now', 'no thanks', 'got it', 'start'}:
                        target = n
                        break
                for n in nodes:
                    text = (n.get('text', '') + ' ' + n.get('content-desc', '')).strip().lower()
                    rid = n.get('resource-id', '').lower()
                    if target is None and (any(s in rid for s in ['done_button', 'btn_done']) or text in {'done', 'concluído', 'concluir', 'ok'}):
                        target = n
                        break
                if target is None and (not state['shutter'] or time.monotonic() - state.get('shutter_time', 0) > 8):
                    for n in nodes:
                        rid = n.get('resource-id', '').lower()
                        desc = n.get('content-desc', '').lower()
                        if 'shutter' in rid or desc in {'capture', 'shutter', 'take photo', 'capturar', 'tirar foto', 'capture photo'}:
                            target = n
                            state['shutter'] = True
                            state['shutter_time'] = time.monotonic()
                            break
            if target is None and mode == 'galeria' and any(('providers.media' in p or 'documentsui' in p or 'gallery' in p or 'photopicker' in p) for p in packages):
                for n in nodes:
                    text = n.get('text', '').strip().lower()
                    if n.get('enabled') == 'true' and (text.startswith('add (') or text.startswith('adicionar') or text in {'add', 'selecionar', 'open', 'abrir', 'done', 'concluído'}):
                        target = n
                        break
                if target is None:
                    for n in nodes:
                        rid = n.get('resource-id', '').lower()
                        text = (n.get('text', '') + ' ' + n.get('content-desc', '')).lower()
                        if 'miar_auditoria.jpg' in text or 'icon_thumbnail' in rid or 'photo taken' in text or 'foto tirada' in text:
                            target = n
                            break
            if target is None:
                continue
            bounds = re.findall(r'-?\d+', target.get('bounds', ''))
            if len(bounds) != 4:
                continue
            x1, y1, x2, y2 = map(int, bounds)
            action = target.get('resource-id', '') + ' ' + target.get('text', '') + ' ' + target.get('content-desc', '')
            if last_action[0] == action and time.monotonic() - last_action[1] < 3:
                continue
            screenshot = adb('exec-out', 'screencap', '-p').stdout
            shot_name = 'seletor-nativo-' + mode + '-' + str(len(state['steps'])+1).zfill(2) + '.png'
            (OUT / shot_name).write_bytes(screenshot)
            (OUT / ('seletor-nativo-' + mode + '.png')).write_bytes(screenshot)
            adb('shell', 'input', 'tap', str((x1+x2)//2), str((y1+y2)//2))
            last_action = (action, time.monotonic())
            state['steps'].append({'mode': mode, 'action': action, 'screenshot': shot_name})
            print('Android nativo:', mode, action, flush=True)
        except Exception as error:
            # Uma tela em transição pode não produzir XML; a próxima tentativa observa novamente.
            (OUT / 'seletor-nativo-aviso.txt').write_text(str(error), encoding='utf-8')


thread = threading.Thread(target=native_ui, daemon=True)
thread.start()
env = {**os.environ, 'MIAR_EVIDENCIAS': str(OUT / 'android-ensaio')}
flutter = BASE / 'MiarDev/flutter-3.38.9/bin/flutter.bat'
target = 'fotografia_nativa_test.dart' if KIND=='fotografia' else 'apresentacao_test.dart'
command = [str(flutter), 'drive', '--driver=test_driver/integration_test.dart', '--target=integration_test/' + target,
           '--no-pub', '-d', DEVICE, '--dart-define=API_URL=http://10.0.2.2:3301']
proc = subprocess.Popen(command, cwd=STAGING, env=env, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, creationflags=FLAGS)
try:
    with (OUT / (PREFIX+'.txt')).open('w', encoding='utf-8') as log:
        for raw in iter(proc.stdout.readline, b''):
            text = raw.decode('utf-8', errors='replace')
            log.write(text)
            log.flush()
            if 'MIAR_AUDIT_GALERIA' in text:
                state['mode'] = 'galeria'
            elif 'MIAR_AUDIT_CAMERA' in text:
                state['mode'] = 'camera'
                state['shutter'] = False
            elif 'MIAR_AUDIT_GPS_PERMITIR' in text:
                state['mode'] = 'gps'
            elif 'MIAR_AUDIT_ETAPA=OCORRENCIA_' in text:
                state['mode'] = None
            if any(s in text for s in ['Running Gradle', 'Built build', 'Installing build', 'MIAR_AUDIT', 'Exception', 'All tests', '00:']):
                print(text, end='', flush=True)
    code = proc.wait()
finally:
    stop.set()
    thread.join(timeout=20)
    if proc.poll() is None:
        proc.terminate()
        proc.wait(timeout=10)
(OUT / (PREFIX+'.json')).write_text(json.dumps({'exit_code': code, 'avd': avd,
    'android_sdk': adb('shell', 'getprop', 'ro.build.version.sdk').stdout.decode().strip(), 'steps': state['steps'],
    'master_sha256': json.loads((ROOT / 'docs/MASTER.json').read_text())['sha256']}, indent=2, ensure_ascii=False), encoding='utf-8')
print('Ensaio Android exit code:', code)
raise SystemExit(code)
