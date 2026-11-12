param([string]$ApiUrl='http://10.0.2.2:3000',[string]$Dispositivo='', [switch]$GerarApk)
$ErrorActionPreference='Stop'
$sdk=Join-Path $env:LOCALAPPDATA 'MiarDev/flutter-3.38.9/bin/flutter.bat'
if (-not (Test-Path -LiteralPath $sdk)) { throw 'Instale Flutter 3.38.9 via FVM (app/.fvmrc) ou no caminho LOCALAPPDATA/MiarDev/flutter-3.38.9. Consulte README.md.' }
$nome=[System.BitConverter]::ToString([System.Security.Cryptography.SHA256]::Create().ComputeHash([System.Text.Encoding]::UTF8.GetBytes($PSScriptRoot))).Replace('-','').Substring(0,10).ToLowerInvariant()
$copia=Join-Path $env:LOCALAPPDATA "MiarDev/$nome/app"
# O compilador de shaders Flutter falha em caminhos Windows com acentos.
# Compila uma cópia; o código editável continua integralmente na pasta do projeto.
& robocopy.exe (Join-Path $PSScriptRoot 'app') $copia /E /XD build .dart_tool .git .gradle /XF local.properties /NFL /NDL /NJH /NJS /NP | Out-Null
if ($LASTEXITCODE -ge 8) { throw 'Falha ao preparar a cópia de compilação.' }
$jdk=Split-Path -Parent (Split-Path -Parent (Get-Command java).Source)
$gradle=Join-Path $copia 'android/gradle.properties'
Add-Content -LiteralPath $gradle -Value ('org.gradle.java.home='+$jdk.Replace('\','/'))
Push-Location $copia
try {
    & $sdk pub get
    if ($LASTEXITCODE -ne 0) { throw 'Falha nas dependências Flutter.' }
    if ($GerarApk) {
        & $sdk build apk --debug "--dart-define=API_URL=$ApiUrl"
        if ($LASTEXITCODE -eq 0) {
            New-Item -ItemType Directory -Path (Join-Path $PSScriptRoot 'entrega') -Force | Out-Null
            Copy-Item -LiteralPath (Join-Path $copia 'build/app/outputs/flutter-apk/app-debug.apk') -Destination (Join-Path $PSScriptRoot 'entrega/MIAR-android.apk') -Force
        }
    }
    elseif ($Dispositivo) { & $sdk run -d $Dispositivo "--dart-define=API_URL=$ApiUrl" }
    else { & $sdk run "--dart-define=API_URL=$ApiUrl" }
    if ($LASTEXITCODE -ne 0) { throw 'Falha ao executar/compilar o aplicativo.' }
} finally { Pop-Location }
