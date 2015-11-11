@echo off
(NET FILE||(powershell -command Start-Process '%0' -Verb runAs -ArgumentList '%* '&EXIT /B))>NUL 2>&1
pushd "%~dp0" && cd %~dp0
Powershell -executionPolicy Bypass -File ".\bin\ESDDecrypter.ps1" %*