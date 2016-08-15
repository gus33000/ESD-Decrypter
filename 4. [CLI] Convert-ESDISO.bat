@echo off
(NET FILE||(powershell -command Start-Process '%0' -Verb runAs -ArgumentList '%* '&EXIT /B))>NUL 2>&1
pushd "%~dp0" && cd %~dp0
IF [%1] EQU [/nochkup] goto :noup
IF [%1] EQU [-nochkup] goto :noup
goto update

:noup
shift
goto :continue

:update
call Updater.bat
goto :continue

:continue
IF "%1"=="" goto :help
IF [%1] EQU [/?] goto :help
IF [%1] EQU [-?] goto :help
IF [%1] EQU [-help] goto :help
IF [%1] EQU [/help] goto :help
goto :execute

:help
Powershell -executionPolicy Bypass -command Get-Help ".\bin\Convert-ESDISO.ps1" %2
exit /b

:execute
Powershell -executionPolicy Bypass -File ".\bin\Convert-ESDISO.ps1" %*
exit /b