param([switch]$Preparar)
$ErrorActionPreference='Stop'
$raiz=$PSScriptRoot
Set-Location -LiteralPath $raiz
$runtime=Join-Path $raiz '.runtime'
New-Item -ItemType Directory -Path $runtime -Force | Out-Null
. (Join-Path $raiz 'scripts/estado-servicos.ps1')
$ownedSupervisor = Get-MiarSupervisor -ProjectRoot $raiz
if ($ownedSupervisor -and (Test-MiarApi)) {
    Write-Host 'Os serviços do MIAR já estão iniciados. API: http://localhost:3000'
    exit 0
}
if ($ownedSupervisor) { throw 'O supervisor do MIAR está ativo, mas a API ainda não responde. Aguarde a inicialização ou use PARAR-MIAR.cmd e tente novamente.' }
Clear-MiarStaleState -ProjectRoot $raiz
if ($Preparar -or -not (Test-Path -LiteralPath 'api/node_modules')) {
    Push-Location api
    try { & npm.cmd ci; if ($LASTEXITCODE -ne 0) { throw 'Falha ao instalar dependências da API.' } } finally { Pop-Location }
}
if ($Preparar -or -not (Test-Path -LiteralPath 'ia/.venv/Scripts/python.exe')) {
    & python -m venv ia/.venv
    & ia/.venv/Scripts/python.exe -m pip install torch torchvision --index-url https://download.pytorch.org/whl/cpu
    if ($LASTEXITCODE -ne 0) { throw 'Falha ao instalar o modelo de imagem.' }
    & ia/.venv/Scripts/python.exe -m pip install -r ia/requirements.txt
    if ($LASTEXITCODE -ne 0) { throw 'Falha ao instalar dependências Python.' }
}
Push-Location api
try { & npm.cmd run build; if ($LASTEXITCODE -ne 0) { throw 'Falha ao compilar a API.' } } finally { Pop-Location }
$python=(Get-Command python).Source
$supervisor=Join-Path $raiz 'scripts/servicos.py'
Start-Process -FilePath $python -ArgumentList @('-u', ('"{0}"' -f $supervisor)) -WorkingDirectory $raiz -WindowStyle Hidden -RedirectStandardOutput (Join-Path $runtime 'servicos.log') -RedirectStandardError (Join-Path $runtime 'servicos-erro.log')
Write-Host 'Iniciando PostgreSQL, armazenamento, análise de imagens e API...'
for ($tentativa=0; $tentativa -lt 300; $tentativa++) {
    if ((Test-Path -LiteralPath (Join-Path $runtime 'pronto.json')) -and (Test-MiarApi)) {
        Write-Host 'MIAR iniciado. API: http://localhost:3000'
        Write-Host 'Para o app no emulador: .\executar-app.ps1'
        Write-Host 'Para encerrar os serviços: .\parar-miar.ps1'
        exit 0
    }
    $erro=Join-Path $runtime 'servicos-erro.log'
    if ((Test-Path -LiteralPath $erro) -and (Get-Item -LiteralPath $erro).Length -gt 0) { Get-Content -LiteralPath $erro; throw 'Os serviços não iniciaram. Consulte .runtime.' }
    Start-Sleep -Seconds 1
}
throw 'Tempo excedido ao iniciar serviços. Consulte .runtime/*.log.'
