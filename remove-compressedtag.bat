@echo off
setlocal EnableExtensions
chcp 65001 >nul

:: Use dropped folder, else current folder
if "%~1"=="" (set "TARGET=%cd%") else set "TARGET=%~1"
pushd "%TARGET%" || (echo [ERROR] Can't open "%TARGET%". & pause & exit /b 1)

echo Removing trailing -compressed from files in: "%CD%"
echo.

powershell -NoLogo -NoProfile -ExecutionPolicy Bypass ^
  "$files = Get-ChildItem -File -Filter '*-compressed.*';" ^
  "if(-not $files){ Write-Host 'No matching files found.'; exit }" ^
  "foreach($f in $files){" ^
  "  $newBase = ($f.BaseName -replace '(?i)-compressed$','');" ^
  "  $newName = $newBase + $f.Extension;" ^
  "  if($newName -eq $f.Name){ Write-Host '[SKIP] already OK:' $f.Name; continue }" ^
  "  if(Test-Path -LiteralPath (Join-Path $f.DirectoryName $newName)){" ^
  "     Write-Host '[SKIP] exists:' $newName; continue }" ^
  "  Rename-Item -LiteralPath $f.FullName -NewName $newName;" ^
  "  Write-Host '[REN]' $f.Name '->' $newName" ^
  "}"

popd
echo.
pause
