"""Captura as telas da aplicação real e seus metadados para o apêndice da MASTER."""
from pathlib import Path
import hashlib,json,os,subprocess,sys,time

ROOT=Path(__file__).resolve().parent.parent
OUT=ROOT/'evidencias/auditoria-2026-11-11'
capture_dir=OUT/'catalogo-visual'
if capture_dir.exists() and any(capture_dir.iterdir()):
    archived=OUT/f'catalogo-visual-anterior-{int(time.time())}'
    assert capture_dir.resolve().parent==OUT.resolve() and archived.resolve().parent==OUT.resolve()
    capture_dir.rename(archived)
capture_dir.mkdir(exist_ok=True)
ADB=Path(os.environ['LOCALAPPDATA'])/'Android/Sdk/platform-tools/adb.exe'
for _ in range(60):
    boot=subprocess.run([str(ADB),'-s','emulator-5560','shell','getprop','sys.boot_completed'],capture_output=True,timeout=8)
    if boot.stdout.decode().strip()=='1':break
    time.sleep(1)
else:raise SystemExit('Emulador nao concluiu inicializacao.')
avd=subprocess.run([str(ADB),'-s','emulator-5560','emu','avd','name'],capture_output=True).stdout.decode().splitlines()
if not avd or avd[0].strip() not in {'MIAR_API35','MIAR_API26'}:
    raise SystemExit('Catálogo restrito ao emulador de auditoria.')
base=Path(os.environ['LOCALAPPDATA'])/'MiarDev'
staging=base/hashlib.sha256(str(ROOT).encode()).hexdigest()[:10]/'app'
env={**os.environ,'MIAR_EVIDENCIAS':str(OUT/'catalogo-visual'),'PYTHONUTF8':'1'}
cmd=[str(base/'flutter-3.38.9/bin/flutter.bat'),'drive','--driver=test_driver/integration_test.dart',
     '--target=integration_test/catalogo_visual_test.dart','--no-pub','-d','emulator-5560',
     '--dart-define=API_URL=http://10.0.2.2:3301']
with (OUT/'catalogo-visual.txt').open('wb') as log:
    p=subprocess.Popen(cmd,cwd=staging,env=env,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,creationflags=subprocess.CREATE_NO_WINDOW)
    for line in iter(p.stdout.readline,b''):
        log.write(line);log.flush()
        text=line.decode('utf-8',errors='replace')
        if 'MIAR_CATALOGO_META=' in text:
            data=json.loads(text.split('MIAR_CATALOGO_META=',1)[1].strip())
            name=data.pop('nome')
            assert '/' not in name and '\\' not in name
            (capture_dir/(name+'.json')).write_text(json.dumps(data,ensure_ascii=False,indent=2),encoding='utf-8')
    code=p.wait()
metadata={'exit_code':code,'avd':avd[0].strip(),
          'capturas':len(list((OUT/'catalogo-visual').glob('*.png'))),
          'master_requisitos_sha256':json.loads((ROOT/'docs/MASTER.json').read_text(encoding='utf-8')).get('original_sha256')
            or json.loads((ROOT/'docs/MASTER.json').read_text(encoding='utf-8'))['sha256']}
(OUT/'catalogo-visual.json').write_text(json.dumps(metadata,indent=2),encoding='utf-8')
raise SystemExit(code)
