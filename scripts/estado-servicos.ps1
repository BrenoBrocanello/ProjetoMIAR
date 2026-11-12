function Get-MiarSupervisor {
    param([string]$ProjectRoot)
    $stateFile = Join-Path $ProjectRoot '.runtime/supervisor.json'
    if (-not (Test-Path -LiteralPath $stateFile)) { return $null }
    try {
        $state = Get-Content -LiteralPath $stateFile -Encoding UTF8 -Raw | ConvertFrom-Json
        $expected = Join-Path $ProjectRoot 'scripts/servicos.py'
        $process = Get-CimInstance Win32_Process -Filter ('ProcessId=' + [int]$state.pid) -ErrorAction Stop
        if ($process -and $process.CommandLine -and
            $process.CommandLine.IndexOf($expected, [StringComparison]::OrdinalIgnoreCase) -ge 0 -and
            [IO.Path]::GetFullPath([string]$state.projeto) -eq [IO.Path]::GetFullPath($ProjectRoot)) {
            return $process
        }
    } catch { }
    return $null
}

function Test-MiarApi {
    try {
        $response = Invoke-WebRequest -Uri 'http://127.0.0.1:3000/ocorrencias' -UseBasicParsing -TimeoutSec 3
        return $false
    } catch {
        return ($_.Exception.Response -and [int]$_.Exception.Response.StatusCode -eq 401)
    }
}

function Clear-MiarStaleState {
    param([string]$ProjectRoot)
    # Somente marcadores deste projeto; dados, credenciais e processos são preservados.
    foreach ($name in @('pronto.json','supervisor.json')) {
        $file = Join-Path $ProjectRoot ('.runtime/' + $name)
        if (Test-Path -LiteralPath $file) { Remove-Item -LiteralPath $file -Force }
    }
}
