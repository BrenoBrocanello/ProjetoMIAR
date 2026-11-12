# Gera as imagens das telas sem o rótulo de rastreabilidade, para o documento Word.
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$out  = Join-Path $root "render\doc"
$chrome = "C:\Program Files\Google\Chrome\Application\chrome.exe"
New-Item -ItemType Directory -Force -Path $out | Out-Null

foreach ($f in (Get-ChildItem -Path $root -Filter "*.html" | Sort-Object Name)) {
  $png = Join-Path $out ($f.BaseName + ".png")
  $uri = "file:///" + $f.FullName.Replace("\", "/")
  & $chrome --headless=new --disable-gpu --hide-scrollbars `
            --force-device-scale-factor=2 --window-size=500,1016 `
            --virtual-time-budget=5000 --screenshot="$png" $uri 2>&1 | Out-Null
  "{0,-26} {1,9:N0}" -f $f.BaseName, (Get-Item $png).Length
}
