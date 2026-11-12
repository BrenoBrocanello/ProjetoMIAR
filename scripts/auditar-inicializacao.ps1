param([switch]$Reiniciar)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot 'estado-servicos.ps1')
$sampleRoot = Join-Path $projectRoot '.runtime/auditoria-inicializacao'
$sampleRuntime = Join-Path $sampleRoot '.runtime'
New-Item -ItemType Directory -Path $sampleRuntime -Force | Out-Null
@{pid=$PID; projeto=$sampleRoot} | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $sampleRuntime 'supervisor.json') -Encoding UTF8
'{}' | Set-Content -LiteralPath (Join-Path $sampleRuntime 'pronto.json') -Encoding UTF8
'preservar' | Set-Content -LiteralPath (Join-Path $sampleRuntime 'dados-preservados.txt') -Encoding UTF8
if (Get-MiarSupervisor -ProjectRoot $sampleRoot) { throw 'PID de outro processo aceito como supervisor.' }
Clear-MiarStaleState -ProjectRoot $sampleRoot
if ((Test-Path -LiteralPath (Join-Path $sampleRuntime 'supervisor.json')) -or
    (Test-Path -LiteralPath (Join-Path $sampleRuntime 'pronto.json'))) { throw 'Marcadores antigos nao removidos.' }
if ((Get-Content -LiteralPath (Join-Path $sampleRuntime 'dados-preservados.txt')).Trim() -ne 'preservar') { throw 'Arquivo de dados alterado.' }
if (-not (Get-Process -Id $PID -ErrorAction SilentlyContinue)) { throw 'Processo alheio encerrado.' }
$before = Get-MiarSupervisor -ProjectRoot $projectRoot
if (-not $before -or -not (Test-MiarApi)) { throw 'Inicie o MIAR antes do ensaio.' }
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $projectRoot 'iniciar-miar.ps1')
if ($LASTEXITCODE -ne 0) { throw 'Segundo inicio falhou.' }
$after = Get-MiarSupervisor -ProjectRoot $projectRoot
if ($after.ProcessId -ne $before.ProcessId) { throw 'Segundo inicio duplicou supervisor.' }
if ($Reiniciar) {
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $projectRoot 'parar-miar.ps1')
    if ($LASTEXITCODE -ne 0 -or (Get-MiarSupervisor -ProjectRoot $projectRoot)) { throw 'Encerramento falhou.' }
    # Reproduz marcadores de uma sessao antiga com PID reutilizado.
    @{pid=$PID; projeto=$projectRoot} | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $projectRoot '.runtime/supervisor.json') -Encoding UTF8
    '{}' | Set-Content -LiteralPath (Join-Path $projectRoot '.runtime/pronto.json') -Encoding UTF8
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $projectRoot 'iniciar-miar.ps1')
    if ($LASTEXITCODE -ne 0 -or -not (Test-MiarApi)) { throw 'Reinicio com marcador antigo falhou.' }
    $after = Get-MiarSupervisor -ProjectRoot $projectRoot
    if (-not $after -or $after.ProcessId -eq $before.ProcessId) { throw 'Reinicio nao criou o supervisor correto.' }
}
@{marcadores_obsoletos=$true;pid_alheio_preservado=$true;dados_preservados=$true;
    inicio_idempotente=$true;reinicio_com_marcadores_obsoletos=[bool]$Reiniciar;
    supervisor_antes=$before.ProcessId;supervisor_depois=$after.ProcessId} |
    ConvertTo-Json | Set-Content -LiteralPath (Join-Path $projectRoot 'evidencias/auditoria-2026-11-11/inicializacao.json') -Encoding UTF8
Write-Host 'Inicializacao e preservacao: OK.'
