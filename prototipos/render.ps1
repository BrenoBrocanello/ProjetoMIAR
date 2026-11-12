# Renderiza os protótipos HTML da Etapa 10 como imagens PNG.
# Uso:  powershell -File render.ps1            (renderiza todos)
#       powershell -File render.ps1 01-login   (renderiza um)

param([string]$Only = "")

$root   = Split-Path -Parent $MyInvocation.MyCommand.Path
$out    = Join-Path $root "render"
$chrome = "C:\Program Files\Google\Chrome\Application\chrome.exe"
if (-not (Test-Path $chrome)) { $chrome = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe" }

New-Item -ItemType Directory -Force -Path $out | Out-Null

$files = Get-ChildItem -Path $root -Filter "*.html" | Sort-Object Name
if ($Only -ne "") { $files = $files | Where-Object { $_.BaseName -eq $Only } }

foreach ($f in $files) {
  $png = Join-Path $out ($f.BaseName + ".png")
  $uri = "file:///" + ($f.FullName -replace '\\', '/')
  & $chrome --headless=new --disable-gpu --hide-scrollbars `
            --force-device-scale-factor=2 --window-size=520,1200 `
            --virtual-time-budget=5000 --screenshot="$png" $uri 2>&1 | Out-Null
  if (Test-Path $png) {
    "{0,-28} {1,9:N0} bytes" -f $f.BaseName, (Get-Item $png).Length
  } else {
    "{0,-28} FALHOU" -f $f.BaseName
  }
}
