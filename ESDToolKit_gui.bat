@echo off
(NET FILE||(powershell -windowstyle hidden -command Start-Process '%0' -Verb runAs -ArgumentList '%* '&EXIT /B))>NUL 2>&1
pushd "%~dp0" && cd %~dp0
Powershell -windowstyle hidden -executionPolicy Bypass -File ".\bin\main.ps1" %*