param([string]$CaminhoLibreOffice)
$ErrorActionPreference='Stop'
$stage=Join-Path $env:LOCALAPPDATA 'MiarDev/376eb84567/documentacao'
if(-not $CaminhoLibreOffice){$CaminhoLibreOffice=Join-Path $stage 'lo/program/soffice.com'}
if(-not (Test-Path -LiteralPath $CaminhoLibreOffice)){throw 'Informe -CaminhoLibreOffice com o caminho do soffice.com.'}
$profile='-env:UserInstallation='+([uri](Join-Path $stage 'lo-profile')).AbsoluteUri
& $CaminhoLibreOffice $profile --headless --convert-to pdf --outdir $stage (Join-Path $stage 'LabES_SistemaMIAR_MASTER.docx')
if($LASTEXITCODE -ne 0){throw 'Falha na exportacao do PDF.'}
