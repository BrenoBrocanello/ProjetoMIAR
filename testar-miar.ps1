# Prepara tudo e abre o MIAR no emulador Android, para quem só quer testar o app.
# Uso: dois cliques em TESTAR-MIAR.cmd. Pode ser executado de novo quantas vezes quiser:
# o que já estiver instalado é reaproveitado.
param(
    [string]$Avd = 'MIAR_Teste',
    [switch]$ReinstalarApp
)
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$raiz = $PSScriptRoot

$Pacote = 'br.com.miar.miar'
$ApkUrl = 'https://github.com/BrenoBrocanello/ProjetoMIAR/releases/download/v1.0.0/MIAR-android.apk'
$ApkSha256 = '422902564c28a3da33139bfb9f3c4af5f2e403c491e942e1afa0b6c222a5e808'
$Imagem = 'system-images;android-35;google_apis;x86_64'
$Etapas = 6

# Mostra os erros de forma legível para quem não programa, em vez do bloco técnico do PowerShell.
trap {
    Write-Host ''
    Write-Host '============================================================' -ForegroundColor Red
    Write-Host '  Não foi possível concluir.' -ForegroundColor Red
    Write-Host '============================================================' -ForegroundColor Red
    Write-Host ('  ' + $_.Exception.Message) -ForegroundColor Red
    Write-Host ''
    Write-Host '  Veja a seção "Problemas comuns" do README. Depois de resolver,'
    Write-Host '  rode o TESTAR-MIAR.cmd de novo: ele continua de onde parou.'
    exit 1
}

function Etapa([int]$n, [string]$texto) { Write-Host ''; Write-Host "[$n/$Etapas] $texto" -ForegroundColor Cyan }
function Ok([string]$t) { Write-Host "      OK: $t" -ForegroundColor Green }
function Info([string]$t) { Write-Host "      $t" }
function Aviso([string]$t) { Write-Host "      ATENÇÃO: $t" -ForegroundColor Yellow }

# Executa um programa sem que mensagens em stderr interrompam o script; devolve o texto produzido.
function Saida-De([string]$exe, [string[]]$argumentos) {
    if (-not (Get-Command $exe -ErrorAction SilentlyContinue)) { return '' }
    $anterior = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try { return (& $exe @argumentos 2>&1 | Out-String) } catch { return '' } finally { $ErrorActionPreference = $anterior }
}

function Atualizar-Path {
    $env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' + [Environment]::GetEnvironmentVariable('Path', 'User')
}

function Instalar-Com-Winget([string]$id, [string]$nome) {
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        throw "$nome não foi encontrado e o winget (Instalador de Aplicativos do Windows) não está disponível. Instale $nome manualmente, conforme o README, e execute novamente."
    }
    Info "Instalando $nome com o winget. O Windows pode pedir sua confirmação..."
    $anterior = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    & winget install --exact --id $id --silent --accept-source-agreements --accept-package-agreements
    $ErrorActionPreference = $anterior
    Atualizar-Path
}

function Baixar([string]$url, [string]$destino) {
    New-Item -ItemType Directory -Path (Split-Path -Parent $destino) -Force | Out-Null
    $parcial = "$destino.part"
    & curl.exe -L --fail --retry 3 -o $parcial $url
    if ($LASTEXITCODE -ne 0) { throw "Falha ao baixar $url. Verifique a conexão com a internet e tente de novo." }
    Move-Item -LiteralPath $parcial -Destination $destino -Force
}

function Tem-Acento([string]$texto) { return $texto -match '[^\x00-\x7F]' }

# ---------------------------------------------------------------- verificações iniciais
Write-Host '============================================================' -ForegroundColor Magenta
Write-Host '  MIAR - preparar e abrir o app no emulador Android' -ForegroundColor Magenta
Write-Host '============================================================' -ForegroundColor Magenta
Info 'Na primeira vez, isto baixa vários gigabytes e pode levar de 20 a 40 minutos.'
Info 'Nas próximas vezes, leva só alguns minutos. Não feche esta janela.'

if ($env:PROCESSOR_ARCHITECTURE -eq 'ARM64') {
    throw 'Este computador usa processador ARM. O emulador Android usado aqui exige processador Intel ou AMD (x64).'
}
$disco = Get-PSDrive -Name ($env:LOCALAPPDATA.Substring(0, 1)) -ErrorAction SilentlyContinue
if ($disco -and $disco.Free -lt 12GB) {
    Aviso ('Há apenas {0:N1} GB livres no disco. Recomenda-se pelo menos 12 GB na primeira execução.' -f ($disco.Free / 1GB))
}
Atualizar-Path

# ---------------------------------------------------------------- 1. Node.js
Etapa 1 'Node.js (servidor)'
function Versao-Node {
    $texto = Saida-De 'node' @('--version')
    if ($texto -match 'v(\d+)\.') { return [int]$Matches[1] } else { return 0 }
}
if ((Versao-Node) -lt 20) {
    Instalar-Com-Winget 'OpenJS.NodeJS.LTS' 'Node.js LTS'
    if (Test-Path 'C:\Program Files\nodejs\node.exe') { $env:Path = 'C:\Program Files\nodejs;' + $env:Path }
}
$versaoNode = Versao-Node
if ($versaoNode -lt 20) { throw 'Node.js 20 ou mais novo não foi encontrado. Instale a versão LTS em https://nodejs.org e execute novamente.' }
Ok "Node.js v$versaoNode"

# ---------------------------------------------------------------- 2. Python
Etapa 2 'Python (análise de imagens)'
function Achar-Python {
    $candidatos = New-Object System.Collections.Generic.List[string]
    foreach ($v in '3.12', '3.13', '3.11') {
        $p = Saida-De 'py' @("-$v", '-c', 'import sys;print(sys.executable)')
        if ($p -match '(?m)^([A-Za-z]:\\[^\r\n]*python\.exe)\s*$') { $candidatos.Add($Matches[1]) }
    }
    foreach ($d in '312', '313', '311') {
        $candidatos.Add((Join-Path $env:LOCALAPPDATA "Programs\Python\Python$d\python.exe"))
        $candidatos.Add("C:\Program Files\Python$d\python.exe")
    }
    $cmd = Get-Command python -ErrorAction SilentlyContinue
    if ($cmd) { $candidatos.Add($cmd.Source) }
    foreach ($c in $candidatos) {
        if ($c -and $c -notmatch 'WindowsApps' -and (Test-Path -LiteralPath $c)) {
            # Sem aspas internas: o PowerShell 5.1 as remove ao chamar programas externos.
            $v = (Saida-De $c @('-c', 'import sys;print(sys.version_info[0]*100+sys.version_info[1])')).Trim()
            if ($v -in @('311', '312', '313')) { return $c }
        }
    }
    return $null
}
$python = Achar-Python
if (-not $python) {
    Instalar-Com-Winget 'Python.Python.3.12' 'Python 3.12'
    $python = Achar-Python
}
if (-not $python) { throw 'Python 3.12 não foi encontrado. Instale em https://www.python.org/downloads/ marcando "Add python.exe to PATH" e execute novamente.' }
# Garante que os scripts do projeto usem este Python, e não o atalho da Microsoft Store.
$pastaPython = Split-Path -Parent $python
$env:Path = "$pastaPython;$(Join-Path $pastaPython 'Scripts');$env:Path"
Ok ("Python " + (Saida-De $python @('--version')).Trim().Replace('Python ', ''))

# ---------------------------------------------------------------- 3. Android SDK e emulador
Etapa 3 'Ferramentas do Android e emulador'
$sdk = $null
foreach ($c in @($env:ANDROID_HOME, $env:ANDROID_SDK_ROOT, (Join-Path $env:LOCALAPPDATA 'Android\Sdk'))) {
    if ($c -and (Test-Path -LiteralPath $c)) { $sdk = $c; break }
}
if (-not $sdk) {
    # O emulador falha em caminhos com acentos; nesse caso usa uma pasta neutra.
    if (Tem-Acento $env:LOCALAPPDATA) { $sdk = 'C:\MiarAndroid\Sdk' } else { $sdk = Join-Path $env:LOCALAPPDATA 'Android\Sdk' }
}
if ((Tem-Acento $env:USERPROFILE) -and -not $env:ANDROID_AVD_HOME) {
    $env:ANDROID_USER_HOME = 'C:\MiarAndroid\.android'
    $env:ANDROID_AVD_HOME = 'C:\MiarAndroid\.android\avd'
}
$env:ANDROID_HOME = $sdk
$env:ANDROID_SDK_ROOT = $sdk
$adb = Join-Path $sdk 'platform-tools\adb.exe'
$emulador = Join-Path $sdk 'emulator\emulator.exe'
$imagemDir = Join-Path $sdk 'system-images\android-35\google_apis\x86_64'
$sdkmanager = Join-Path $sdk 'cmdline-tools\latest\bin\sdkmanager.bat'
$avdmanager = Join-Path $sdk 'cmdline-tools\latest\bin\avdmanager.bat'
if ($env:ANDROID_AVD_HOME) { $avdHome = $env:ANDROID_AVD_HOME } else { $avdHome = Join-Path $env:USERPROFILE '.android\avd' }

$faltando = @()
if (-not (Test-Path -LiteralPath $adb)) { $faltando += 'platform-tools' }
if (-not (Test-Path -LiteralPath $emulador)) { $faltando += 'emulator' }
if (-not (Test-Path -LiteralPath (Join-Path $imagemDir 'system.img'))) { $faltando += $Imagem }
$precisaAvd = -not (Test-Path -LiteralPath (Join-Path $avdHome "$Avd.ini"))

if ($faltando.Count -gt 0 -or $precisaAvd) {
    # sdkmanager e avdmanager exigem Java 17 ou mais novo.
    function Achar-Java {
        $casas = New-Object System.Collections.Generic.List[string]
        if ($env:JAVA_HOME) { $casas.Add($env:JAVA_HOME) }
        $casas.Add('C:\Program Files\Android\Android Studio\jbr')
        Get-ChildItem 'C:\Program Files\Microsoft', 'C:\Program Files\Eclipse Adoptium', 'C:\Program Files\Java' -Directory -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -match 'jdk' } | Sort-Object Name -Descending | ForEach-Object { $casas.Add($_.FullName) }
        $cmd = Get-Command java -ErrorAction SilentlyContinue
        if ($cmd) { $casas.Add((Split-Path -Parent (Split-Path -Parent $cmd.Source))) }
        foreach ($casa in $casas) {
            $java = Join-Path $casa 'bin\java.exe'
            if (Test-Path -LiteralPath $java) {
                if ((Saida-De $java @('-version')) -match 'version "(\d+)') { if ([int]$Matches[1] -ge 17) { return $casa.TrimEnd('\') } }
            }
        }
        return $null
    }
    $javaHome = Achar-Java
    if (-not $javaHome) {
        Instalar-Com-Winget 'Microsoft.OpenJDK.21' 'Java (OpenJDK 21)'
        $javaHome = Achar-Java
    }
    if (-not $javaHome) { throw 'Java 17 ou mais novo não foi encontrado. Instale o Android Studio ou o OpenJDK 21 e execute novamente.' }
    $env:JAVA_HOME = $javaHome
    $env:Path = (Join-Path $javaHome 'bin') + ';' + $env:Path

    if (-not (Test-Path -LiteralPath $sdkmanager)) {
        Info 'Baixando as ferramentas de linha de comando do Android...'
        $catalogo = (Invoke-WebRequest -UseBasicParsing 'https://dl.google.com/android/repository/repository2-3.xml').Content
        $bloco = [regex]::Match($catalogo, '(?s)<remotePackage path="cmdline-tools;latest">.*?</remotePackage>').Value
        $arquivo = [regex]::Match($bloco, '(?s)<checksum type="sha1">(\w+)</checksum>\s*<url>(commandlinetools-win-\d+_latest\.zip)</url>')
        if (-not $arquivo.Success) { throw 'Não foi possível localizar as ferramentas do Android no catálogo do Google.' }
        $zip = Join-Path $env:TEMP $arquivo.Groups[2].Value
        Baixar ('https://dl.google.com/android/repository/' + $arquivo.Groups[2].Value) $zip
        if ((Get-FileHash -LiteralPath $zip -Algorithm SHA1).Hash -ne $arquivo.Groups[1].Value.ToUpperInvariant()) {
            Remove-Item -LiteralPath $zip -Force
            throw 'O arquivo das ferramentas do Android chegou corrompido. Execute novamente.'
        }
        $extraido = Join-Path $env:TEMP 'miar-cmdline-tools'
        if (Test-Path -LiteralPath $extraido) { Remove-Item -LiteralPath $extraido -Recurse -Force }
        Expand-Archive -LiteralPath $zip -DestinationPath $extraido
        New-Item -ItemType Directory -Path (Join-Path $sdk 'cmdline-tools') -Force | Out-Null
        Move-Item -LiteralPath (Join-Path $extraido 'cmdline-tools') -Destination (Join-Path $sdk 'cmdline-tools\latest')
        Remove-Item -LiteralPath $zip, $extraido -Recurse -Force
    }

    if ($faltando.Count -gt 0) {
        Write-Host ''
        Info 'Serão instalados componentes do Android SDK do Google:'
        $faltando | ForEach-Object { Info "  - $_" }
        Info 'Para isso é preciso aceitar as licenças do Android SDK:'
        Info 'https://developer.android.com/studio/terms'
        $resposta = Read-Host '      Digite S e tecle Enter para aceitar e continuar'
        if ($resposta -notmatch '^[sSyY]') { throw 'Instalação cancelada: as licenças do Android SDK não foram aceitas.' }
        $anterior = $ErrorActionPreference
        $ErrorActionPreference = 'Continue'
        (('y' + [Environment]::NewLine) * 40) | & $sdkmanager "--sdk_root=$sdk" --licenses | Out-Null
        Info 'Baixando (a imagem do Android tem cerca de 1,5 GB)...'
        & $sdkmanager "--sdk_root=$sdk" --install @faltando
        $ErrorActionPreference = $anterior
        if (-not (Test-Path -LiteralPath $adb) -or -not (Test-Path -LiteralPath $emulador) -or -not (Test-Path -LiteralPath (Join-Path $imagemDir 'system.img'))) {
            throw 'A instalação dos componentes do Android não terminou. Verifique a internet e execute novamente.'
        }
    }

    if ($precisaAvd) {
        Info "Criando o celular virtual '$Avd'..."
        New-Item -ItemType Directory -Path $avdHome -Force | Out-Null
        $anterior = $ErrorActionPreference
        $ErrorActionPreference = 'Continue'
        'no' | & $avdmanager create avd --name $Avd --package $Imagem --device pixel_7 --force | Out-Null
        $ErrorActionPreference = $anterior
        $config = Join-Path $avdHome "$Avd.avd\config.ini"
        if (-not (Test-Path -LiteralPath $config)) { throw "Não foi possível criar o celular virtual '$Avd'." }
        $ajustes = [ordered]@{
            'hw.keyboard' = 'yes'; 'hw.gpu.enabled' = 'yes'; 'hw.gpu.mode' = 'auto'
            'hw.ramSize' = '2048'; 'disk.dataPartition.size' = '6G'; 'showDeviceFrame' = 'yes'
        }
        $linhas = @(Get-Content -LiteralPath $config) | Where-Object { $_ -notmatch ('^(' + (($ajustes.Keys | ForEach-Object { [regex]::Escape($_) }) -join '|') + ')\s*=') }
        $linhas = @($linhas) + @($ajustes.Keys | ForEach-Object { "$_=$($ajustes[$_])" })
        Set-Content -LiteralPath $config -Value $linhas -Encoding ASCII
    }
}

$aceleracao = Saida-De $emulador @('-accel-check')
if ($aceleracao -notmatch 'usable') {
    Write-Host $aceleracao
    throw ('A aceleração de hardware não está disponível, e o emulador não consegue iniciar sem ela. ' +
        'Ative a "Plataforma do Hipervisor do Windows" em "Ativar ou desativar recursos do Windows", ' +
        'confira se a virtualização (VT-x/AMD-V/SVM) está ligada na BIOS e reinicie o computador.')
}
Ok "Android SDK em $sdk"

# ---------------------------------------------------------------- 4. emulador (liga em paralelo com o servidor)
Etapa 4 'Ligando o emulador'
$anterior = $ErrorActionPreference
$ErrorActionPreference = 'Continue'
& $adb start-server 2>&1 | Out-Null
$ErrorActionPreference = $anterior
function Emulador-Conectado {
    $linha = (Saida-De $adb @('devices')) -split "`r?`n" | Where-Object { $_ -match '^(emulator-\d+)\s+device\s*$' } | Select-Object -First 1
    if ($linha -and $linha -match '^(emulator-\d+)') { return $Matches[1] } else { return $null }
}
$processoEmulador = $null
if (Emulador-Conectado) {
    Ok 'Já existe um emulador ligado; ele será usado.'
} else {
    $processoEmulador = Start-Process -FilePath $emulador -ArgumentList @('-avd', $Avd, '-netdelay', 'none', '-netspeed', 'full') -PassThru
    Info 'A janela do celular virtual vai abrir. O Android termina de ligar enquanto o servidor inicia.'
}

# ---------------------------------------------------------------- 5. servidor
Etapa 5 'Servidor do MIAR (banco, fotos, IA e API)'
Info 'Na primeira vez, instala as dependências e baixa o PyTorch (download grande).'
& (Join-Path $raiz 'iniciar-miar.ps1')
Ok 'Servidor em http://localhost:3000'

# ---------------------------------------------------------------- 6. app
Etapa 6 'Instalando e abrindo o app'
$serial = $null
for ($i = 0; $i -lt 180; $i++) {
    $serial = Emulador-Conectado
    if ($serial -and (Saida-De $adb @('-s', $serial, 'shell', 'getprop', 'sys.boot_completed')).Trim() -eq '1') { break }
    if ($processoEmulador -and $processoEmulador.HasExited) { throw 'O emulador fechou durante a inicialização. Feche outros emuladores ou máquinas virtuais e tente de novo.' }
    $serial = $null
    Start-Sleep -Seconds 2
}
if (-not $serial) { throw 'O emulador não terminou de ligar em 6 minutos. Execute TESTAR-MIAR.cmd novamente.' }
Ok "Emulador pronto ($serial)"

$apk = Join-Path $raiz 'entrega\MIAR-android.apk'
if (-not (Test-Path -LiteralPath $apk)) {
    $apk = Join-Path $env:LOCALAPPDATA 'MiarDev\MIAR-android.apk'
    $valido = (Test-Path -LiteralPath $apk) -and ((Get-FileHash -LiteralPath $apk -Algorithm SHA256).Hash -eq $ApkSha256.ToUpperInvariant())
    if (-not $valido) {
        Info 'Baixando o app (cerca de 220 MB)...'
        Baixar $ApkUrl $apk
        if ((Get-FileHash -LiteralPath $apk -Algorithm SHA256).Hash -ne $ApkSha256.ToUpperInvariant()) {
            Remove-Item -LiteralPath $apk -Force
            throw 'O APK baixado não confere com a versão publicada. Execute novamente.'
        }
    }
}
$hashApk = (Get-FileHash -LiteralPath $apk -Algorithm SHA256).Hash
$marcador = Join-Path $env:LOCALAPPDATA "MiarDev\apk-instalado-$Avd.txt"
$instalado = (Saida-De $adb @('-s', $serial, 'shell', 'pm', 'path', $Pacote)) -match 'package:'
$mesmaVersao = (Test-Path -LiteralPath $marcador) -and ((Get-Content -LiteralPath $marcador -Raw).Trim() -eq $hashApk)
if ($ReinstalarApp -or -not $instalado -or -not $mesmaVersao) {
    Info 'Instalando o app no emulador...'
    $resultado = Saida-De $adb @('-s', $serial, 'install', '-r', $apk)
    if ($resultado -notmatch 'Success') { Write-Host $resultado; throw 'Falha ao instalar o app no emulador.' }
    New-Item -ItemType Directory -Path (Split-Path -Parent $marcador) -Force | Out-Null
    Set-Content -LiteralPath $marcador -Value $hashApk -Encoding ASCII
}
Saida-De $adb @('-s', $serial, 'shell', 'monkey', '-p', $Pacote, '-c', 'android.intent.category.LAUNCHER', '1') | Out-Null
Ok 'MIAR aberto no emulador'

Write-Host ''
Write-Host '============================================================' -ForegroundColor Green
Write-Host '  Pronto! O MIAR está aberto no celular virtual.' -ForegroundColor Green
Write-Host '============================================================' -ForegroundColor Green
Info 'Toque em "Criar conta" para começar. O roteiro de teste está no README.'
Info 'Ao terminar: feche o emulador e dê dois cliques em PARAR-MIAR.cmd.'
Info 'Seus dados ficam salvos para a próxima vez.'
