@echo off
set PORT=8000
if not "%~1"=="" set PORT=%~1
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0serve.ps1" -Port %PORT%
