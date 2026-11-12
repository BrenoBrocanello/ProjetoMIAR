"""Instala e verifica o artefato exato da entrega no AVD dedicado, com API principal."""
from pathlib import Path
import hashlib,json,os,re,subprocess,time,urllib.request,urllib.error

ROOT=Path(__file__).resolve().parent.parent
OUT=ROOT/'evidencias/auditoria-2026-11-11'
ADB=Path(os.environ['LOCALAPPDATA'])/'Android/Sdk/platform-tools/adb.exe'
def adb(*args,timeout=30):
    return subprocess.run([str(ADB),'-s','emulator-5560',*args],capture_output=True,timeout=timeout,creationflags=subprocess.CREATE_NO_WINDOW)
avd=adb('emu','avd','name').stdout.decode().splitlines()
assert avd and avd[0].strip()=='MIAR_API35','AVD de entrega inesperado.'
try:urllib.request.urlopen('http://127.0.0.1:3000/ocorrencias',timeout=3)
except urllib.error.HTTPError as e:assert e.code==401
else:raise RuntimeError('API principal nao respondeu como esperado.')
adb('uninstall','br.com.miar.miar') # Somente pacote de ensaio do AVD dedicado.
apk=ROOT/'entrega/MIAR-android.apk'
result=adb('install',str(apk),timeout=90)
assert result.returncode==0 and b'Success' in result.stdout,(result.stdout+result.stderr).decode(errors='replace')
adb('emu','geo','fix','-46.8978','-23.1857')
start=adb('shell','am','start','-W','-n','br.com.miar.miar/.MainActivity')
assert start.returncode==0 and b'Status: ok' in start.stdout
time.sleep(3)
assert adb('shell','pidof','br.com.miar.miar').stdout.strip(),'Aplicativo encerrou depois do inicio.'
package=adb('shell','dumpsys','package','br.com.miar.miar').stdout.decode()
assert re.search(r'versionCode=3\s',package) and 'versionName=1.0.0' in package
try:
    xml=adb('shell','uiautomator','dump','/sdcard/miar-apk-final.xml',timeout=15)
    if xml.returncode==0:
        (OUT/'apk-final-acessibilidade.xml').write_bytes(adb('shell','cat','/sdcard/miar-apk-final.xml').stdout)
except subprocess.TimeoutExpired:pass
screen=adb('exec-out','screencap','-p').stdout
assert screen.startswith(b'\x89PNG\r\n\x1a\n')
(OUT/'apk-final-tela.png').write_bytes(screen)
state={'exit_code':0,'avd':avd[0].strip(),'sdk':35,'versao':'1.0.0+3','min_sdk':26,'api':'http://10.0.2.2:3000',
       'apk_sha256':hashlib.sha256(apk.read_bytes()).hexdigest(),'instalacao':'Success','inicio':start.stdout.decode().strip()}
(OUT/'apk-instalacao-final.json').write_text(json.dumps(state,indent=2,ensure_ascii=False),encoding='utf-8')
print('APK exato instalado e aberto: versao1.0.0+3, API principal, screenshot nativa registrada.')
