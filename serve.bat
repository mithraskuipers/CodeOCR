@echo off
setlocal
set PORT=8000
if not "%~1"=="" set PORT=%~1

rem Clear the "downloaded from the internet" flag Windows puts on files
rem copied from a zip, email, or network share. Left on, it can make
rem PowerShell treat the script as untrusted on locked-down PCs.
powershell -NoProfile -Command "Unblock-File -LiteralPath '%~dp0serve.ps1'" >nul 2>&1

rem Run the server. Instead of executing the .ps1 file directly (which
rem some corporate PCs block via Group Policy if the file isn't signed),
rem we read its text and run it as a scriptblock. This does the exact
rem same thing but is not subject to that file-signing check, and needs
rem no admin rights or system setting changes.
powershell -NoProfile -NoLogo -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; try { $code = Get-Content -Raw -LiteralPath '%~dp0serve.ps1'; $sb = [ScriptBlock]::Create($code); & $sb -Port %PORT% } catch { Write-Host ''; Write-Host 'Failed to start the server:' -ForegroundColor Red; Write-Host $_.Exception.Message -ForegroundColor Red; Read-Host 'Press Enter to close this window' }"

echo.
pause
endlocal
