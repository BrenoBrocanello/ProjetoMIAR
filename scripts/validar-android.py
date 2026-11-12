"""Executa a instrumentação Android e preserva o código de saída real do Flutter."""
from pathlib import Path
import json
import os
import subprocess
import sys
import threading
import re
import xml.etree.ElementTree as ET

sys.stdout.reconfigure(encoding='utf-8')

ROOT = Path(__file__).resolve().parent.parent
kind = sys.argv[1] if len(sys.argv) > 1 else 'fluxo'
if kind not in {'fluxo', 'dispositivo'}:
    raise SystemExit('Use fluxo ou dispositivo.')
base = Path(os.environ['LOCALAPPDATA'])
flutter = base / 'MiarDev/flutter-3.38.9/bin/flutter.bat'
import hashlib
key = hashlib.sha256(str(ROOT).encode()).hexdigest()[:10]
staging = base / 'MiarDev' / key / 'app'
if not staging.is_dir():
    raise SystemExit('Prepare a cópia de compilação com GERAR-APK.cmd.')
adb = base / 'Android/Sdk/platform-tools/adb.exe'
avd_check = subprocess.run([str(adb), '-s', 'emulator-5560', 'emu', 'avd', 'name'], capture_output=True)
avd = avd_check.stdout.decode().splitlines()[0].strip()
if avd not in {'MIAR_API35', 'MIAR_API26'}:
    raise SystemExit('Instrumentacao restrita aos AVDs de auditoria do MIAR.')
env = {**os.environ, 'MIAR_EVIDENCIAS': str(ROOT / 'evidencias/android')}
target = 'fluxo_real_test.dart' if kind == 'fluxo' else 'dispositivo_test.dart'
report_root = Path(os.environ.get('MIAR_AUDIT_DIR', str(ROOT / 'evidencias')))
env['MIAR_EVIDENCIAS'] = str(report_root / 'android-janelas')
report = report_root / ('android-integracao.txt' if kind == 'fluxo' else 'android-dispositivo.txt')
report.parent.mkdir(exist_ok=True, parents=True)
flags = subprocess.CREATE_NO_WINDOW if os.name == 'nt' else 0
cmd = [str(flutter), 'drive', '--driver=test_driver/integration_test.dart',
       '--target=integration_test/' + target, '--no-pub', '-d', 'emulator-5560',
       '--dart-define=API_URL=http://10.0.2.2:3301']
p = subprocess.Popen(cmd, cwd=staging, env=env, stdout=subprocess.PIPE,
                     stderr=subprocess.STDOUT, creationflags=flags)
stop = threading.Event()
notification_allowed = False
notification_requested = False
sdk_level = subprocess.run([str(adb), '-s', 'emulator-5560', 'shell', 'getprop', 'ro.build.version.sdk'], capture_output=True).stdout.decode().strip()


def android_command(*args):
    return subprocess.run([str(adb), '-s', 'emulator-5560', *args], capture_output=True, creationflags=flags)


def notification_settings(enabled):
    android_command('shell', 'am', 'start', '-a', 'android.settings.APP_NOTIFICATION_SETTINGS',
                    '--es', 'android.provider.extra.APP_PACKAGE', 'br.com.miar.miar')
    for _ in range(5):
        android_command('shell', 'uiautomator', 'dump', '/sdcard/miar-notificacoes.xml')
        raw = android_command('shell', 'cat', '/sdcard/miar-notificacoes.xml').stdout
        (report_root / 'notificacoes-permissao.xml').write_bytes(raw)
        try:
            switches = [n for n in ET.fromstring(raw).iter('node')
                        if n.get('class') == 'android.widget.Switch']
            if switches:
                n = switches[0]
                if (n.get('checked') == 'true') != enabled:
                    x1,y1,x2,y2=map(int,re.findall(r'\d+',n.get('bounds')))
                    android_command('shell','input','tap',str((x1+x2)//2),str((y1+y2)//2))
                android_command('shell','input','keyevent','4')
                return True
        except (ET.ParseError,ValueError):
            pass
    android_command('shell','input','keyevent','4')
    return False


def grant_native_permissions():
    settings_state = None
    while not stop.wait(1):
        check = subprocess.run([str(adb), '-s', 'emulator-5560', 'shell', 'pidof', 'br.com.miar.miar'],
                               capture_output=True, creationflags=flags)
        if not check.stdout.strip():
            continue
        for permission in ['ACCESS_COARSE_LOCATION', 'ACCESS_FINE_LOCATION'] + (['POST_NOTIFICATIONS'] if notification_allowed else []):
            subprocess.run([str(adb), '-s', 'emulator-5560', 'shell', 'pm', 'grant',
                            'br.com.miar.miar', 'android.permission.' + permission],
                           capture_output=True, creationflags=flags)
        if sdk_level == '26' and notification_requested and settings_state != notification_allowed:
            desired = notification_allowed
            if notification_settings(desired):
                settings_state = desired
        subprocess.run([str(adb), '-s', 'emulator-5560', 'emu', 'geo', 'fix', '-46.8978', '-23.1857'],
                       capture_output=True, creationflags=flags)


thread = None
if kind == 'dispositivo':
    thread = threading.Thread(target=grant_native_permissions, daemon=True)
    thread.start()
with report.open('w', encoding='utf-8') as log:
    for line in iter(p.stdout.readline, b''):
        text = line.decode('utf-8', errors='replace')
        log.write(text)
        log.flush()
        if 'MIAR_NOTIF_NEGAR' in text:
            notification_allowed = False
            notification_requested = True
        elif 'MIAR_NOTIF_PERMITIR' in text:
            notification_allowed = True
        elif 'MIAR_NOTIF_AGENDAMENTO' in text:
            job = subprocess.run([str(adb), '-s', 'emulator-5560', 'shell', 'dumpsys', 'jobscheduler'], capture_output=True, creationflags=flags)
            (report_root / 'notificacoes-agendamento.txt').write_bytes(job.stdout)
        # Gradle/adb permanecem no relatório; o terminal mostra progresso útil.
        if any(word in text for word in ['Running Gradle', 'Built build', 'Installing build', 'All tests', 'Exception', 'ERROR', '00:', 'MIAR_NOTIF']):
            print(text, end='', flush=True)
code = p.wait()
stop.set()
if thread:
    thread.join(timeout=5)
(report.with_suffix('.json')).write_text(json.dumps({
    'teste': kind, 'exit_code': code, 'avd': avd,
    'android_sdk': subprocess.run([str(adb), '-s', 'emulator-5560', 'shell', 'getprop', 'ro.build.version.sdk'], capture_output=True).stdout.decode().strip(),
    'master_sha256': json.loads((ROOT / 'docs/MASTER.json').read_text())['sha256'],
    'relatorio': str(report.relative_to(ROOT)),
}, indent=2), encoding='utf-8')
print('Flutter exit code:', code, flush=True)
raise SystemExit(code)
