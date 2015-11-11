@echo off
(NET FILE||(powershell -command Start-Process '%0' -Verb runAs -ArgumentList '%* '&EXIT /B))>NUL 2>&1
pushd "%~dp0" && cd %~dp0
Echo.
Echo Pressing enter will start the renaming process.
Echo.
Echo Current Directory: "%CD%"
Echo.
pause>nul
Powershell -executionPolicy Bypass -File ".\bin\renameisos_cli.ps1" %*