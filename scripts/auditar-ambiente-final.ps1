$ErrorActionPreference='Stop'
$projectRoot=Split-Path -Parent $PSScriptRoot
Set-Location -LiteralPath $projectRoot
$catalog=Get-Content -LiteralPath 'evidencias/auditoria-2026-11-11/catalogo-visual.json' -Raw -Encoding UTF8 | ConvertFrom-Json
if ($null -eq $catalog.exit_code -or $catalog.exit_code -ne 0 -or $catalog.capturas -lt 57) { throw 'A coleta completa ainda nao terminou.' }
$owned=Get-Content -LiteralPath '.runtime/auditoria-processos.json' -Raw -Encoding UTF8 | ConvertFrom-Json
$parent=Get-CimInstance Win32_Process -Filter ('ProcessId='+[int]$owned.api_teste_pid) -ErrorAction SilentlyContinue
if ($parent -and $parent.CommandLine -like '*scripts/servidor-teste.mjs*') {
    $children=Get-CimInstance Win32_Process -Filter ('ParentProcessId='+[int]$parent.ProcessId)
    foreach($child in $children) {
        if ($child.Name -eq 'node.exe' -and $child.CommandLine -match 'dist[/\\]main\.js') {
            Stop-Process -Id $child.ProcessId -ErrorAction Stop
        }
    }
    $still=Get-CimInstance Win32_Process -Filter ('ProcessId='+[int]$parent.ProcessId) -ErrorAction SilentlyContinue
    if ($still -and $still.CommandLine -like '*scripts/servidor-teste.mjs*') { Stop-Process -Id $still.ProcessId }
}
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $projectRoot 'scripts/auditar-inicializacao.ps1') -Reiniciar
if ($LASTEXITCODE -ne 0) { throw 'Falha no ensaio final de inicializacao.' }
Push-Location api
try { & node scripts/verificar-preservacao.mjs; if ($LASTEXITCODE -ne 0) { throw 'Preservacao nao confirmada.' } }
finally { Pop-Location }
Write-Output 'Ambiente principal reiniciado e dados preservados; API de teste propria encerrada.'
