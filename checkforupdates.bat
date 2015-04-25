@echo off
for /f %%f in ('type version.txt') do set curver=%%f
Echo [Info] Script Current Version : %curver%
Echo [Info] Checking for Updates...
set "url=https://raw.githubusercontent.com/gus33000/ESD-Decrypter/master/version.txt"
if not exist "%temp%\ESD-Decrypter\version.txt" mkdir "%temp%\ESD-Decrypter"
if exist "%temp%\ESD-Decrypter\version.txt" del "%temp%\ESD-Decrypter\version.txt"
for /f "tokens=3 delims=:. " %%f in ('bitsadmin.exe /CREATE /DOWNLOAD "ESD-Decrypter Update Services" ^| findstr "Created job"') do set GUID=%%f
bitsadmin.exe>nul /ADDFILE %GUID% %url% "%temp%\ESD-Decrypter\version.txt"
bitsadmin.exe>nul /SETNOTIFYCMDLINE %GUID% "%SystemRoot%\system32\bitsadmin.exe" "%SystemRoot%\system32\bitsadmin.exe /COMPLETE %GUID%"
bitsadmin.exe>nul /RESUME %GUID%

:check
bitsadmin /list | find "%GUID%" >nul 2>&1 && goto :check
type %temp%\ESD-Decrypter\version.txt | find "%curver%" >nul 2>&1 && goto :uptodate
for /f %%f in ('type %temp%\ESD-Decrypter\version.txt') do set NewVersion=%%f
echo [Info] Found a new update for you : version %NewVersion%
if "%~dp0"=="%CD%\" (
	echo F | xcopy "checkforupdates.bat" "%temp%\ESD-Decrypter\checkforupdates.bat" /cheriky
	start /D "%CD%" %temp%\ESD-Decrypter\checkforupdates.bat
	exit
)
echo [Info] Downloading version %NewVersion%...
set "url=http://gus33000.github.io/ESD-Decrypter/%NewVersion%.zip"
for /f "tokens=3 delims=:. " %%f in ('bitsadmin.exe /CREATE /DOWNLOAD "ESD-Decrypter Update Services" ^| findstr "Created job"') do set GUID=%%f
bitsadmin.exe>nul /ADDFILE %GUID% %url% "%temp%\ESD-Decrypter\%NewVersion%.zip"
bitsadmin.exe>nul /SETNOTIFYCMDLINE %GUID% "%SystemRoot%\system32\bitsadmin.exe" "%SystemRoot%\system32\bitsadmin.exe /COMPLETE %GUID%"
bitsadmin.exe>nul /RESUME %GUID%

:check2
bitsadmin /list | find "%GUID%" >nul 2>&1 && goto :check2
echo [Info] Extracting version %NewVersion%...
Call :UnZipFile "%temp%\ESD-Decrypter\%NewVersion%" "%temp%\ESD-Decrypter\%NewVersion%.zip"
echo [Info] Applying update...
xcopy "%temp%\ESD-Decrypter\%NewVersion%" "%CD%" /cheriky
echo [Info] Deleting temporary files...
rmdir /S /Q "%temp%\ESD-Decrypter"
echo [Info] Update Applied : You are now up to date.
pause
exit


:uptodate
echo [Info] You are using the latest version of ESD-Decrypter !
echo [Info] Running version %curver%
rmdir /S /Q "%temp%\ESD-Decrypter"
pause
exit /b

:UnZipFile <ExtractTo> <newzipfile>
set vbs="%temp%\_.vbs"
if exist %vbs% del /f /q %vbs%
>>%vbs% echo Set fso = CreateObject("Scripting.FileSystemObject")
>>%vbs% echo ZipFile=fso.GetAbsolutePathName("%~2")
>>%vbs% echo ExtractTo=fso.GetAbsolutePathName("%~1")
>>%vbs% echo Set fso = CreateObject("Scripting.FileSystemObject")
>>%vbs% echo If NOT fso.FolderExists(ExtractTo) Then
>>%vbs% echo    fso.CreateFolder(ExtractTo)
>>%vbs% echo End If
>>%vbs% echo set objShell = CreateObject("shell.application")
>>%vbs% echo set FilesInZip=objShell.NameSpace(ZipFile).items
>>%vbs% echo objShell.NameSpace(ExtractTo).CopyHere(FilesInZip)
>>%vbs% echo Set fso = Nothing
>>%vbs% echo Set objShell = Nothing

cscript //nologo %vbs%
if exist %vbs% del /f /q %vbs%
exit /b