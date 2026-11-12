$ErrorActionPreference='Stop'
$runtime=Join-Path $PSScriptRoot '.runtime'
. (Join-Path $PSScriptRoot 'scripts/estado-servicos.ps1')
if (-not (Get-MiarSupervisor -ProjectRoot $PSScriptRoot)) {
    Clear-MiarStaleState -ProjectRoot $PSScriptRoot
    Write-Host 'Nenhum supervisor do MIAR em execução. Marcadores antigos removidos; dados preservados.'
    exit 0
}
New-Item -ItemType File -Path (Join-Path $runtime 'parar') -Force | Out-Null
for ($tentativa=0;$tentativa -lt 30;$tentativa++) {
    if (-not (Test-Path -LiteralPath (Join-Path $runtime 'supervisor.json'))) { Write-Host 'Serviços encerrados. Os dados foram preservados.'; exit 0 }
    Start-Sleep -Seconds 1
}
throw 'O encerramento não terminou. Consulte .runtime/servicos-erro.log.'
