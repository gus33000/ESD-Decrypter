@echo off
fsutil dirty query %systemdrive% >nul
if %errorlevel%==0 goto gotAdmin
echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"
set "params=%*" 
set params=%params:"=" ^& chr(34) ^& "%
if "%~1"=="" set params=
echo UAC.ShellExecute "cmd.exe", "/K " ^& chr^(34^) ^& chr^(34^) ^& "%~s0" ^& chr^(34^) ^& " %params%" ^& chr^(34^), "", "runas", 1 >> "%temp%\getadmin.vbs"
"%temp%\getadmin.vbs"
del "%temp%\getadmin.vbs"
exit /B

:gotAdmin
pushd "%CD%"
CD /D "%~dp0"
setlocal EnableDelayedExpansion
:: UPDATE SYSTEM
if exist "%~1\%~nx0" (
	CD /D "%~1"
)
:: UPDATE SYSTEM
set curver=1010
set ESD=
set MODE=
set OUT=
set wimlib=
set KEY=
:: UPDATE SYSTEM
set "FILE=%~0"
set "FILEN=%~nx0"
:: UPDATE SYSTEM
title ESD to ISO Converter / Decrypter
echo.
echo ESD Decrypter / Converter to ISO - Based on the script by abbodi1406
echo Made with love by gus33000 - Copyright 2015 (c) gus33000 - Version 1.0
echo.
:: UPDATE SYSTEM
if not "%~1"=="/noupdate" (
	PING -n 3 gus33000.github.io >NUL
	IF ERRORLEVEL 1 echo [Info] No Internet Connection found, couldn't check for updates
	IF NOT ERRORLEVEL 1 call :autoupdate %*
)
if "%~1"=="/noupdate" shift
:: UPDATE SYSTEM
if exist "%~s1" goto AUTO
if "%1"=="/?" goto help
if "%1"=="/Mode:1" goto :PARSE1
if "%1"=="/Mode:2" goto :PARSE2
goto help
exit /b

:AUTO
echo.
echo What do you want to do ?
echo 様様様様様様様様様様様様
echo.
echo [1] Create Full ISO with Standard install.wim
echo [2] Create Full ISO with Compressed install.esd
echo [0] Exit Script
echo.
choice /N /C 012 /M "Your choice : "
if %ERRORLEVEL% equ 2 call :ESD2ISO WIM "%~1" .\
if %ERRORLEVEL% equ 3 call :ESD2ISO ESD "%~1" .\
exit /b

:PARSE1
shift
if "%1"=="/File" (
	set "ESD=%~2"
	shift & shift
)
if "%1"=="/Key" (
	set "KEY=%~2"
	shift & shift
)
if "%1"=="/Output" (
	set "OUT=%~2"
	shift & shift
)
if not "%1"=="" goto :PARSE1
if "%OUT%"=="" goto help
if "!ESD!"=="" goto help
call :ESD2ISO WIM "!ESD!" "%OUT%" %KEY%
exit /b

:PARSE2
shift
if "%1"=="/File" (
	set "ESD=%~2"
	shift & shift
)
if "%1"=="/Key" (
	set "KEY=%~2"
	shift & shift
)
if "%1"=="/Output" (
	set "OUT=%~2"
	shift & shift
)
if not "%1"=="" goto :PARSE1
if "%OUT%"=="" goto help
if "!ESD!"=="" goto help
call :ESD2ISO ESD "!ESD!" "%OUT%" %KEY%
exit /b

:ESD2ISO <MODE(WIM|ESD)> <ESD> <Output> {key}
echo.
set "MODE=%~1"
set "ESD=%~2"
set "OUT=%~3"
if [%OUT:~-1%]==[\] set "OUT=%OUT:~0,-1%"
set "KEY=%4"
chcp 437 >nul
set wimlib=%~dp0bin\wimlib-imagex.exe
if %PROCESSOR_ARCHITECTURE%==AMD64 set wimlib=%~dp0bin\bin64\wimlib-imagex.exe
if not exist "%wimlib%" (
	echo [Critical] %PROCESSOR_ARCHITECTURE% wimlib-imagex.exe not found
	goto error
)

%wimlib% info "!ESD!" 4 1>nul 2>nul
IF %ERRORLEVEL% EQU 74 call :Decrypt "!ESD!" %key%
IF %ERRORLEVEL% NEQ 0 (
	echo [Critical] The filename is missing or damaged.
	echo [Critical] Error code : %ERRORLEVEL%
	goto error
	exit /b
)
set ERRORTEMP=
call :PREPARE "!ESD!"
echo [Info] Creating Setup Media Layout...
IF EXIST ISOFOLDER\ rmdir /s /q ISOFOLDER\
mkdir ISOFOLDER
echo.
"%wimlib%" apply "!ESD!" 1 ISOFOLDER\
SET ERRORTEMP=%ERRORLEVEL%
IF %ERRORTEMP% NEQ 0 (
	echo [Critical] Errors were reported during apply.
	goto error
	exit /b
)
del ISOFOLDER\MediaMeta.xml 1>nul 2>nul
Echo.
echo [Info] Creating boot.wim file...
Echo.
"%wimlib%" export "!ESD!" 2 ISOFOLDER\sources\boot.wim --compress=maximum
SET ERRORTEMP=%ERRORLEVEL%
IF %ERRORTEMP% NEQ 0 (
	echo [Critical] Errors were reported during export.
	goto error
	exit /b
)
echo.
"%wimlib%" export "!ESD!" 3 ISOFOLDER\sources\boot.wim --boot
SET ERRORTEMP=%ERRORLEVEL%
IF %ERRORTEMP% NEQ 0 (
	echo [Critical] Errors were reported during export.
	goto error
	exit /b
)
if "%MODE%"=="WIM" (
	Echo.
	echo [Info] Creating install.wim file...
	Echo.
	"%wimlib%" export "!ESD!" 4 ISOFOLDER\sources\install.wim --compress=maximum
	SET ERRORTEMP=%ERRORLEVEL%
	IF %ERRORTEMP% NEQ 0 (
		echo [Critical] Errors were reported during export.
		goto error
		exit /b
	)
)
if "%MODE%"=="ESD" (
	Echo.
	echo [Info] Creating install.esd file...
	Echo.
	"%wimlib%" export "!ESD!" 4 ISOFOLDER\sources\install.esd
	SET ERRORTEMP=%ERRORLEVEL%
	IF %ERRORTEMP% NEQ 0 (
		echo [Critical] Errors were reported during export.
		goto error
		exit /b
	)
)
if /i %editionid%==ProfessionalWMC (
	Echo.
	echo [Info] Integrating Generic WMC Tokens
	Echo.
	if %MODE%==WIM %wimlib% update ISOFOLDER\sources\install.wim 1 <bin\wim-update.txt 1>nul 2>nul
	if %MODE%==ESD %wimlib% update ISOFOLDER\sources\install.wim 1 <bin\wim-update.txt 1>nul 2>nul
)
Echo.
echo [Info] Creating ISO file...
reg copy "HKCU\Control Panel\International" "HKCU\Control Panel\International-Temp" /f >nul
reg add "HKCU\Control Panel\International" /v sShortDate /d "yyyy-MM-dd" /f >nul
reg add "HKCU\Control Panel\International" /v sTimeFormat /d "HH:mm:ss" /f >nul
for %%a in (ISOFOLDER\sources\setup.exe) do set date=%%~ta
set dd=%date:~8,2%
set mm=%date:~5,2%
set yyyy=%date:~0,4%
set time=%date:~11,5%
reg copy "HKCU\Control Panel\International-Temp" "HKCU\Control Panel\International" /f >nul
if not exist %OUT%\nul mkdir %OUT%
bin\cdimage.exe -bootdata:2#p0,e,b"ISOFOLDER\boot\etfsboot.com"#pEF,e,b"ISOFOLDER\efi\Microsoft\boot\efisys.bin" -o -h -m -u2 -udfver102 -t%mm%/%dd%/%yyyy%,%time%:00 -g -l%DVDLABEL% ISOFOLDER %OUT%\%DVDISO%
SET ERRORTEMP=%ERRORLEVEL%
IF %ERRORTEMP% NEQ 0 (
	echo [Critical] Errors were reported during ISO creation.
	goto error
	exit /b
)
rmdir /s /q ISOFOLDER\
IF EXIST "!ESD!.bak" (
	del /f /q "!ESD!" >nul 2>&1
	for /f "delims=" %%f in ("!ESD!") do ren "!ESD!.bak" %%~nf.esd
)
echo.
echo Press any key to exit.
pause >nul
exit /b

:Decrypt <ESD> {key}
set "ESD2=%~1"
if not exist "!ESD!.bak" (
	echo [Info] Backing up original esd file...
	echo.
	copy "!ESD!" "!ESD!.bak" /z
	echo.
)
echo [Info] Running Decryption program...
bin\esddecrypt.exe "!ESD!" 2>"%temp%\esddecrypt.log"&&exit /b
bin\esddecrypt.exe "!ESD!" %2 &&exit /b
type "%temp%\esddecrypt.log"
echo [Critical] Errors were reported during ESD decryption.
goto error
exit /b

:PREPARE <ESD>
for /f "tokens=2 delims=: " %%i in ('%wimlib% info "%~1" 4 ^| find /i "Architecture"') do set arch=%%i
for /f "tokens=3 delims=: " %%i in ('%wimlib% info "%~1" 4 ^| find /i "Edition"') do set editionid=%%i
for /f "tokens=3 delims=: " %%i in ('%wimlib% info "%~1" 4 ^| find /i "Default"') do set langid=%%i
for /f "tokens=2 delims=: " %%i in ('%wimlib% info "%~1" 4 ^| findstr /b "Build"') do set build=%%i
for /f "tokens=4 delims=: " %%i in ('%wimlib% info "%~1" 4 ^| find /i "Service Pack Build"') do set svcbuild=%%i

echo [Info] ESD Technical Details :
echo.
echo [Info] 様様様様様様様様様様様様様様様様様様様様様様様
echo [Info] Build : %build%
echo [Info] Service Pack Build : %svcbuild%
echo [Info] Architecture : %arch%
echo [Info] Edition : %editionid%
echo [Info] Language : %langid%
echo [Info] 様様様様様様様様様様様様様様様様様様様様様様様
echo.
 
set lang=%langid:~0,2%
if /i %langid%==en-gb set lang=en-gb
if /i %langid%==es-mx set lang=es-mx
if /i %langid%==fr-ca set lang=fr-ca
if /i %langid%==pt-pt set lang=pp
if /i %langid%==sr-latn-rs set lang=sr-latn
if /i %langid%==zh-cn set lang=cn
if /i %langid%==zh-tw set lang=tw
if /i %langid%==zh-hk set lang=hk
for %%b in (A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z) do set langid=!langid:%%b=%%b!

set tag=IR3&set tag2=ir3
if %svcbuild% EQU 17056 set tag=IR4&set tag2=ir4
if %svcbuild% EQU 17415 set tag=IR5&set tag2=ir5
if %svcbuild% GTR 17415 set tag=IR6&set tag2=ir6
if /i %arch%==x86 set archl=X86
if /i %arch%==x86_64 set arch=x64&set archl=X64

set DVDLABEL=%tag%_CCSA_%archl%FRER_%langid%_DV9&set DVDISO=%lang%_windows_8.1_%tag2%_%arch%_dvd.iso
if /i %editionid%==Core set DVDLABEL=%tag%_CCRA_%archl%FRER_%langid%_DV9&set DVDISO=%lang%_windows_8.1_%tag2%_%arch%_dvd.iso
if /i %editionid%==CoreN set DVDLABEL=%tag%_CCRNA_%archl%FRER_%langid%_DV9&set DVDISO=%lang%_windows_8.1_n_%tag2%_%arch%_dvd.iso
if /i %editionid%==CoreSingleLanguage set DVDLABEL=%tag%_CSLA_%archl%FRER_%langid%_DV9&set DVDISO=%lang%_windows_8.1_singlelanguage_%tag2%_%arch%_dvd.iso
if /i %editionid%==CoreCountrySpecific set DVDLABEL=%tag%_CCHA_%archl%FRER_%langid%_DV9&set DVDISO=%lang%_windows_8.1_china_%tag2%_%arch%_dvd.iso
if /i %editionid%==Professional set DVDLABEL=%tag%_CPRA_%archl%FRER_%langid%_DV9&set DVDISO=%lang%_windows_8.1_pro_%tag2%_%arch%_dvd.iso
if /i %editionid%==ProfessionalN set DVDLABEL=%tag%_CPRNA_%archl%FRER_%langid%_DV9&set DVDISO=%lang%_windows_8.1_pro_n_%tag2%_%arch%_dvd.iso
if /i %editionid%==ProfessionalWMC set DVDLABEL=%tag%_CPWMCA_%archl%FRER_%langid%_DV9&set DVDISO=%lang%_windows_8.1_pro_wmc_%tag2%_%arch%_dvd.iso
if /i %editionid%==CoreConnected set DVDLABEL=%tag%_CCONA_%archl%FRER_%langid%_DV9&set DVDISO=%lang%_windows_8.1_with_bing_%tag2%_%arch%_dvd.iso
if /i %editionid%==CoreConnectedN set DVDLABEL=%tag%_CCONNA_%archl%FRER_%langid%_DV9&set DVDISO=%lang%_windows_8.1_n_with_bing_%tag2%_%arch%_dvd.iso
if /i %editionid%==CoreConnectedSingleLanguage set DVDLABEL=%tag%_CCSLA_%archl%FRER_%langid%_DV9&set DVDISO=%lang%_windows_8.1_singlelanguage_with_bing_%tag2%_%arch%_dvd.iso
if /i %editionid%==CoreConnectedCountrySpecific set DVDLABEL=%tag%_CCCHA_%archl%FRER_%langid%_DV9&set DVDISO=%lang%_windows_8.1_china_with_bing_%tag2%_%arch%_dvd.iso
if /i %editionid%==ProfessionalStudent set DVDLABEL=%tag%_CPRSA_%archl%FRER_%langid%_DV9&set DVDISO=%lang%_windows_8.1_pro_student_%tag2%_%arch%_dvd.iso
if /i %editionid%==ProfessionalStudentN set DVDLABEL=%tag%_CPRSNA_%archl%FRER_%langid%_DV9&set DVDISO=%lang%_windows_8.1_pro_student_n_%tag2%_%arch%_dvd.iso

if %build% GTR 9600 (
	set DVDLABEL=JM1_CCSA_%archl%FRE_%langid%_DV5&set DVDISO=%lang%_windows_10_%build%_%arch%_dvd.iso
	if /i %editionid%==Core set DVDLABEL=JM1_CCRA_%archl%FRER_%langid%_DV5&set DVDISO=%lang%_windows_10_core_%build%_%arch%_dvd.iso
	if /i %editionid%==CoreSingleLanguage set DVDLABEL=JM1_CSLA_%archl%FRER_%langid%_DV5&set DVDISO=%lang%_windows_10_singlelanguage_%build%_%arch%_dvd.iso
	if /i %editionid%==CoreCountrySpecific set DVDLABEL=JM1_CCHA_%archl%FRER_%langid%_DV5&set DVDISO=%lang%_windows_10_china_%build%_%arch%_dvd.iso
	if /i %editionid%==Professional set DVDLABEL=JM1_CPRA_%archl%FRER_%langid%_DV5&set DVDISO=%lang%_windows_10_pro_%build%_%arch%_dvd.iso
	if /i %editionid%==Enterprise set DVDLABEL=JM1_CENA_%archl%FREV_%langid%_DV5&set DVDISO=%lang%_windows_10_enterprise_%build%_%arch%_dvd.iso
)

if %build% GEQ 9896 (
	set DVDLABEL=J_CCSA_%archl%FRE_%langid%_DV5&set DVDISO=%lang%_windows_10_technical_preview_%build%_%arch%_dvd.iso
	if /i %editionid%==Core set DVDLABEL=J_CCRA_%archl%FRE_%langid%_DV5&set DVDISO=%lang%_windows_10_core_technical_preview_%build%_%arch%_dvd.iso
	if /i %editionid%==CoreSingleLanguage set DVDLABEL=J_CSLA_%archl%FRER_%langid%_DV5&set DVDISO=%lang%_windows_10_singlelanguage_technical_preview_%build%_%arch%_dvd.iso
	if /i %editionid%==CoreCountrySpecific set DVDLABEL=J_CCHA_%archl%FRER_%langid%_DV5&set DVDISO=%lang%_windows_10_china_technical_preview_%build%_%arch%_dvd.iso
	if /i %editionid%==Professional set DVDLABEL=J_CPRA_%archl%FRE_%langid%_DV5&set DVDISO=%lang%_windows_10_pro_technical_preview_%build%_%arch%_dvd.iso
	if /i %editionid%==Enterprise set DVDLABEL=J_CENA_%archl%FREV_%langid%_DV5&set DVDISO=%lang%_windows_10_enterprise_technical_preview_%build%_%arch%_dvd.iso
)
exit /b

:error
if exist ISOFOLDER\nul rmdir /s /q ISOFOLDER\
IF EXIST "!ESD!.bak" (
	del /f /q "!ESD!" >nul 2>&1
	for /f "delims=" %%f in (!ESD!) do ren "!ESD!.bak" %%~nf.esd
)
exit /b

:: UPDATE SYSTEM
:autoupdate
set updateserver=http://gus33000.github.io/ESD-Decrypter/update
Echo [Info] Script Current Build Number : %curver%
Echo [Info] Checking for Updates...
set "url=%updateserver%/version.txt"
if not exist "%temp%\ESD-Decrypter\version.txt" mkdir "%temp%\ESD-Decrypter"
if exist "%temp%\ESD-Decrypter\version.txt" del "%temp%\ESD-Decrypter\version.txt"
for /f "tokens=3 delims=:. " %%f in ('bitsadmin.exe /CREATE /DOWNLOAD "ESD-Decrypter Update Services" ^| findstr "Created job"') do set GUID=%%f
bitsadmin.exe>nul /ADDFILE %GUID% %url% "%temp%\ESD-Decrypter\version.txt"
bitsadmin.exe>nul /SETNOTIFYCMDLINE %GUID% "%CD%\bin\nircmd.exe" "%CD%\bin\nircmd.exe exec hide %SystemRoot%\system32\bitsadmin.exe /COMPLETE %GUID%"
bitsadmin.exe>nul /RESUME %GUID%
:check
bitsadmin /list | find "%GUID%" >nul 2>&1 && goto :check
for /f %%f in ('type %temp%\ESD-Decrypter\version.txt') do if %curver% GEQ %%f goto :uptodate
for /f %%f in ('type %temp%\ESD-Decrypter\version.txt') do set NewVersion=%%f
echo [Info] Found a new update for you : version %NewVersion%
if "%FILE%"=="%CD%\%~nx0" (
	echo F | xcopy "%FILE%" "%temp%\ESD-Decrypter\%FILEN%" /cherikyq
	start /D "%CD%" %temp%\ESD-Decrypter\%FILEN% "%CD%" %*
	exit 101
)
echo [Info] Downloading version %NewVersion%...
set "url=%updateserver%/%NewVersion%.zip"
for /f "tokens=3 delims=:. " %%f in ('bitsadmin.exe /CREATE /DOWNLOAD "ESD-Decrypter Update Services" ^| findstr "Created job"') do set GUID=%%f
bitsadmin.exe>nul /ADDFILE %GUID% %url% "%temp%\ESD-Decrypter\%NewVersion%.zip"
bitsadmin.exe>nul /SETNOTIFYCMDLINE %GUID% "%CD%\bin\nircmd.exe" "%CD%\bin\nircmd.exe exec hide %SystemRoot%\system32\bitsadmin.exe /COMPLETE %GUID%"
bitsadmin.exe>nul /RESUME %GUID%
:check2
bitsadmin /list | find "%GUID%" >nul 2>&1 && goto :check2
echo [Info] Extracting version %NewVersion%...
call :UnZipFile "%temp%\ESD-Decrypter\%NewVersion%" "%temp%\ESD-Decrypter\%NewVersion%.zip"
echo [Info] Applying update...
xcopy "%temp%\ESD-Decrypter\%NewVersion%" "%CD%" /cherikyq
echo [Info] Deleting temporary files...
rmdir /S /Q "%temp%\ESD-Decrypter\%NewVersion%"
echo [Info] Update Applied : You are now up to date.
ping 1.1.1.1 -n 1 -w 2000 > nul
shift
:ARGPARSE
set "ARGS=%ARGS% %1"
shift
if not "%~1"=="" goto :ARGPARSE
start /D "%CD%" %CD%\%FILEN% %ARGS%
exit
:uptodate
echo [Info] You are using the latest version of ESD-Decrypter !
rmdir /S /Q "%temp%\ESD-Decrypter"
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
:: UPDATE SYSTEM

:help
echo.
echo Usage: 
echo %~n0 
echo      /Mode:^<Mode^> ^<Options^>
echo.
echo      Available modes :
echo.
echo         1 - Convert and decrypt ESD to an ISO with an Install.wim file
echo         2 - Convert and decrypt ESD to an ISO with an Install.esd file
echo.
echo      Available options :
echo.
echo         /File ^<ESD^>      where ESD is the path to the ESD file to process (*)
echo         /Key ^<Key^>       where Key is the complete Cryptographic RSA key used
echo                          to decrypt the ESD file
echo         /Output ^<Folder^> where Folder is the folder which will contain
echo                          the resulted ISO file (*)
echo.
echo      Options marked with (*) are required
echo.
echo      ^<ESD^> ^<KEY^>
echo.
echo      where ESD is the path to the ESD file to process (*)
echo      where Key is the complete Cryptographic RSA key used to decrypt the
echo      ESD file
echo.
echo      Options marked with (*) are required
echo.
echo      Aditional Stuff :
echo.
echo      Place this switch at the beginning of each commands to not check for
echo      updates : /noupdate
exit /b