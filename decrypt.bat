@setlocal enableextensions enabledelayedexpansion
@echo off
set "params=%*"
if not "!params!"=="" set "params=%params:"=""%"
pushd "%cd%" && cd /d "%~dp0" && ( if exist "%temp%\getadmin.vbs" del "%temp%\getadmin.vbs" ) && fsutil dirty query %systemdrive% >nul || if %errorlevel%==0 (  echo Set UAC = CreateObject^("Shell.Application"^) : UAC.ShellExecute "cmd.exe", "/k cd ""%~sdp0"" && %~s0 %params%", "", "runas", 1 >> "%temp%\getadmin.vbs" && "%temp%\getadmin.vbs" && exit /B )
set ESD=
set MODE=
set OUT=
set wimlib=
set KEY=
title ESD to ISO Converter / Decrypter
echo.
echo ESD Decrypter / Converter to ISO - Based on the script by abbodi1406
echo Made with love by gus33000 - Copyright 2015 (c) gus33000 - Version 1.0
echo.
if "%~1"=="/help" goto help
:: UPDATE SYSTEM
set "FILE=%~0"
set "FILEN=%~nx0"
set curver=1018
call :updatesystem %*
if "%~1"=="/noupdate" shift
:: UPDATE SYSTEM
if "%~1"=="/Mode:1" set CHOICE=WIM
if "%~1"=="/Mode:1" goto :PARSE
if "%~1"=="/Mode:2" set CHOICE=ESD
if "%~1"=="/Mode:2" goto :PARSE
if exist "%~s1" goto AUTO
if exist "*.esd" (for /f "delims=:" %%i in ('dir /b "*.esd"') do (call set /a _esd+=1))
if !_esd! gtr 1 goto askesd
if !_esd! equ 1 goto SINGLE
goto help
exit /b

:AUTO
echo.
echo What do you want to do ?
echo ออออออออออออออออออออออออ
echo.
echo [1] Create Full ISO with Standard install.wim
echo [2] Create Full ISO with Compressed install.esd
echo [0] Exit Script
echo.
choice /N /C 012 /M "Your choice : "
if %ERRORLEVEL% equ 2 call :ESD2ISO WIM "%~1" .\ YES NO 1 
if %ERRORLEVEL% equ 3 call :ESD2ISO ESD "%~1" .\ YES NO 1 
exit /b

:SINGLE
for /f "delims=:" %%i in ('dir /b "*.esd"') do set "esd=%%i"
echo.
echo [Info] Selected ESD : 
echo.
echo "%esd%"
echo.
call :AUTO "%esd%"
exit /b

:askesd
echo.
echo What ESD do you want to process ?
echo อออออออออออออออออออออออออออออออออ
echo.
set nb=0
for /f "delims=" %%f in ('dir /b *.esd') do (
	set /a nb+=1
	set var=!var!!nb!
	echo [!nb!] %%f
	set "esd!nb!=%%f"
)
echo.
choice /N /C %var% /M "Your choice : "
set CHOICE=%ERRORLEVEL%
call :AUTO "!esd%CHOICE%!"
exit /b

:PARSE
IF NOT "%1"=="" (
	if "%1"=="/File" (
		set "ESD=%~2"
		shift
	)
	if "%1"=="/Key" (
		set "KEY=%~2"
		shift
	)
	if "%1"=="/Output" (
		set "OUT=%~2"
		shift
	)
	if "%1"=="/Scheme" (
		set "SCHEME=%~2"
		shift
	)
	if "%1"=="/NoBackup" (
		set BACKUP=NO
	)
	if "%1"=="/DeleteESD" (
		set DeleteESD=YES
	)
	shift
	goto :PARSE
)
if not "%DeleteESD%"=="YES" set DeleteESD=NO
if not "%BACKUP%"=="NO" set BACKUP=YES
if "%OUT%"=="" goto help
if "!ESD!"=="" goto help
if "%SCHEME%"=="" set SCHEME=1
call :ESD2ISO %CHOICE% "!ESD!" "%OUT%" %BACKUP% %DeleteESD% %SCHEME% %KEY%
exit /b

:ESD2ISO <MODE(WIM|ESD)> <ESD> <Output> <Backup(YES|NO)> <DeleteESD(YES|NO)> <FilenameType> {key}
call :StartTimer
Echo Process Started at %StartTime%
Echo.
set "MODE=%~1"
set "ESD=%~2"
set "OUT=%~3"
if [%OUT:~-1%]==[\] set "OUT=%OUT:~0,-1%"
set "KEY=%7"
chcp 437 >nul
set "wimlib=%~dps0bin\wimlib-imagex.exe"
if %PROCESSOR_ARCHITECTURE%==AMD64 set "wimlib=%~dps0bin\bin64\wimlib-imagex.exe"
if not exist "%wimlib%" (
	echo [Critical] %PROCESSOR_ARCHITECTURE% wimlib-imagex.exe not found
	goto error
)

"%wimlib%" info "%ESD%" 4 1>nul 2>nul
IF %ERRORLEVEL% EQU 74 call :Decrypt "%ESD%" %key%
IF %ERRORLEVEL% NEQ 0 (
	echo [Critical] The filename is missing or damaged.
	echo [Critical] Error code : %ERRORLEVEL%
	goto error
	exit /b
)
set ERRORTEMP=
if %6 EQU 0 call :GETESDINFO "%ESD%" 1
if %6 GTR 3 call :GETESDINFO "%ESD%" 1
if not %6 GTR 3 call :GETESDINFO "%ESD%" %6
echo [Info] Creating Setup Media Layout...
IF EXIST ISOFOLDER\ rmdir /s /q ISOFOLDER\
mkdir ISOFOLDER
echo.
"%wimlib%" apply "%ESD%" 1 ISOFOLDER\
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
"%wimlib%" export "%ESD%" 2 ISOFOLDER\sources\boot.wim --compress=maximum
SET ERRORTEMP=%ERRORLEVEL%
IF %ERRORTEMP% NEQ 0 (
	echo [Critical] Errors were reported during export.
	goto error
	exit /b
)
echo.
"%wimlib%" export "%ESD%" 3 ISOFOLDER\sources\boot.wim --boot
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
	"%wimlib%" export "%ESD%" 4 ISOFOLDER\sources\install.wim --compress=maximum
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
	"%wimlib%" export "%ESD%" 4 ISOFOLDER\sources\install.esd
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
	if %MODE%==WIM "%wimlib%" update ISOFOLDER\sources\install.wim 1 <bin\wim-update.txt 1>nul 2>nul
	if %MODE%==ESD "%wimlib%" update ISOFOLDER\sources\install.esd 1 <bin\wim-update.txt 1>nul 2>nul
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
if "%~4"=="YES" (
	IF EXIST "!ESD!.bak" (
		del /f /q "!ESD!" >nul 2>&1
		ren "!ESD!.bak" "!ESD!"
	)
)
if "%~5"=="YES" (
	del /f /q "!ESD!" >nul 2>&1
)
echo.
call :StopTimer
call :DisplayTimerResult
exit /b

:Decrypt <ESD> <Backup(YES|NO)> {key}
set "ESD2=%~1"
if "%~2"=="YES" (
	if not exist "!ESD2!.bak" (
		echo [Info] Backing up original esd file...
		echo.
		copy "!ESD2!" "!ESD2!.bak" /z
		echo.
	)
)
echo [Info] Running Decryption program...
bin\esddecrypt.exe "%ESD2%" 2>"%temp%\esddecrypt.log"&&exit /b
bin\esddecrypt.exe "%ESD2%" %2 &&exit /b
type "%temp%\esddecrypt.log"
echo [Critical] Errors were reported during ESD decryption.
goto error
exit /b

:GETESDINFO
"%wimlib%">nul extract "%~1" 1 sources\idwbinfo.txt
for /f "tokens=2 delims==" %%a in ('find "BuildBranch=" "idwbinfo.txt"') do @set BuildBranch=%%a
for /f "tokens=2 delims==" %%a in ('find "BuildType=" "idwbinfo.txt"') do @set BuildType=%%a
del>nul idwbinfo.txt
"%wimlib%">nul extract "%~1" 1 setup.exe
for /f "tokens=2 delims=:()%BuildBranch%" %%a in ('powershell -Command "[System.Diagnostics.FileVersionInfo]::GetVersionInfo('setup.exe').FileVersion"') do set CompileDate=%%a
del>nul setup.exe
set CompileDate=%CompileDate:.=%

:: LIST OF STUFF
:: =============
:: Index
:: Name
:: Description
:: DisplayName
:: DisplayDescription
:: DirectoryCount
:: FileCount
:: TotalBytes
:: HardLinkBytes
:: CreationTime
:: LastModificationTime
:: Architecture
:: ProductName
:: EditionID
:: InstallationType
:: HAL
:: ProductType
:: ProductSuite
:: Languages
:: DefaultLanguage
:: SystemRoot
:: MajorVersion
:: MinorVersion
:: Build
:: ServicePackBuild
:: ServicePackLevel
:: Flags
:: WIMBootcompatible
::
for /f "skip=2 delims=" %%f in ('%wimlib% info "%~1" 4') do (
	for /f "tokens=1 delims=:" %%a in ('echo %%f') do set value=%%a
	for /f "tokens=2* delims=:" %%a in ('echo %%f') do (
		for /f "tokens=*" %%i in ('echo %%a') do set "var=%%i"
	)
	set !value: =!=!var!
	REM echo !value: =! ^=^> !var!
)

set LanguageID=!DefaultLanguage!
for %%b in (A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z) do set LanguageID=!LanguageID:%%b=%%b!
set tag=IR3&set tag2=ir3
if %ServicePackBuild% EQU 17056 set tag=IR4&set tag2=ir4
if %ServicePackBuild% EQU 17415 set tag=IR5&set tag2=ir5
if %ServicePackBuild% GTR 17415 set tag=IR6&set tag2=ir6
if /i %Architecture%==x86 set arch=x86&archl=X86
if /i %Architecture%==x86_64 set arch=x64&set archl=X64

Echo [Info] Detailed ESD Information :
Echo.
echo [Info] ออออออออออออออออออออออออออออออออออออออออออออออ
echo [Info] Build : %Build%.%ServicePackBuild%.%CompileDate%
echo [Info] Build Branch : %BuildBranch%
echo [Info] Build Type : %BuildType%
echo [Info] Architecture : %arch%
echo [Info] Edition : %EditionID%
echo [Info] Language : %LanguageID%
echo [Info] ออออออออออออออออออออออออออออออออออออออออออออออ
echo.

set DVDLABEL=%tag%_CCSA_%archl%FRER_%LanguageID%_DV9
if /i %EditionID%==Core set DVDLABEL=%tag%_CCRA_%archl%FRER_%LanguageID%_DV9
if /i %EditionID%==CoreN set DVDLABEL=%tag%_CCRNA_%archl%FRER_%LanguageID%_DV9
if /i %EditionID%==CoreSingleLanguage set DVDLABEL=%tag%_CSLA_%archl%FRER_%LanguageID%_DV9
if /i %EditionID%==CoreCountrySpecific set DVDLABEL=%tag%_CCHA_%archl%FRER_%LanguageID%_DV9
if /i %EditionID%==Professional set DVDLABEL=%tag%_CPRA_%archl%FRER_%LanguageID%_DV9
if /i %EditionID%==ProfessionalN set DVDLABEL=%tag%_CPRNA_%archl%FRER_%LanguageID%_DV9
if /i %EditionID%==ProfessionalWMC set DVDLABEL=%tag%_CPWMCA_%archl%FRER_%LanguageID%_DV9
if /i %EditionID%==CoreConnected set DVDLABEL=%tag%_CCONA_%archl%FRER_%LanguageID%_DV9
if /i %EditionID%==CoreConnectedN set DVDLABEL=%tag%_CCONNA_%archl%FRER_%LanguageID%_DV9
if /i %EditionID%==CoreConnectedSingleLanguage set DVDLABEL=%tag%_CCSLA_%archl%FRER_%LanguageID%_DV9
if /i %EditionID%==CoreConnectedCountrySpecific set DVDLABEL=%tag%_CCCHA_%archl%FRER_%LanguageID%_DV9
if /i %EditionID%==ProfessionalStudent set DVDLABEL=%tag%_CPRSA_%archl%FRER_%LanguageID%_DV9
if /i %EditionID%==ProfessionalStudentN set DVDLABEL=%tag%_CPRSNA_%archl%FRER_%LanguageID%_DV9

if %Build% GTR 9600 (
	set DVDLABEL=JM1_CCSA_%archl%FRE_%LanguageID%_DV5
	if /i %EditionID%==Core set DVDLABEL=JM1_CCRA_%archl%FRER_%LanguageID%_DV5
	if /i %EditionID%==CoreSingleLanguage set DVDLABEL=JM1_CSLA_%archl%FRER_%LanguageID%_DV5
	if /i %EditionID%==CoreCountrySpecific set DVDLABEL=JM1_CCHA_%archl%FRER_%LanguageID%_DV5
	if /i %EditionID%==Professional set DVDLABEL=JM1_CPRA_%archl%FRER_%LanguageID%_DV5
	if /i %EditionID%==Enterprise set DVDLABEL=JM1_CENA_%archl%FREV_%LanguageID%_DV5
)

if %Build% GEQ 9896 (
	set DVDLABEL=J_CCSA_%archl%FRE_%LanguageID%_DV5
	if /i %EditionID%==Core set DVDLABEL=J_CCRA_%archl%FRE_%LanguageID%_DV5
	if /i %EditionID%==CoreSingleLanguage set DVDLABEL=J_CSLA_%archl%FRER_%LanguageID%_DV5
	if /i %EditionID%==CoreCountrySpecific set DVDLABEL=J_CCHA_%archl%FRER_%LanguageID%_DV5
	if /i %EditionID%==Professional set DVDLABEL=J_CPRA_%archl%FRE_%LanguageID%_DV5
	if /i %EditionID%==Enterprise set DVDLABEL=J_CENA_%archl%FREV_%LanguageID%_DV5
)

if %Build% GTR 10066 (
	set DVDLABEL=J_CCSA_%archl%FRE_%LanguageID%_DV5
	if /i %EditionID%==Core set DVDLABEL=J_CCRA_%archl%FRE_%LanguageID%_DV5
	if /i %EditionID%==CoreSingleLanguage set DVDLABEL=J_CSLA_%archl%FRER_%LanguageID%_DV5
	if /i %EditionID%==CoreCountrySpecific set DVDLABEL=J_CCHA_%archl%FRER_%LanguageID%_DV5
	if /i %EditionID%==Professional set DVDLABEL=J_CPRA_%archl%FRE_%LanguageID%_DV5
	if /i %EditionID%==Enterprise set DVDLABEL=J_CENA_%archl%FREV_%LanguageID%_DV5
)

if %Build% GEQ 10100 (
	if %Build% LSS 10104 (
		set DVDLABEL=J_CCSA_%archl%FRE_%LanguageID%_DV5
		if /i %EditionID%==Core set DVDLABEL=J_CCRA_%archl%FRE_%LanguageID%_DV5
		if /i %EditionID%==CoreSingleLanguage set DVDLABEL=J_CSLA_%archl%FRER_%LanguageID%_DV5
		if /i %EditionID%==CoreCountrySpecific set DVDLABEL=J_CCHA_%archl%FRER_%LanguageID%_DV5
		if /i %EditionID%==Professional set DVDLABEL=J_CPRA_%archl%FRE_%LanguageID%_DV5
		if /i %EditionID%==Enterprise set DVDLABEL=J_CENA_%archl%FREV_%LanguageID%_DV5
	)
)
call :GENISONAME%~2 "%~1"
exit /b

:GENISONAME1
set LanguageID=!DefaultLanguage!
set lang=%LanguageID:~0,2%
set tag=IR3&set tag2=ir3
if %ServicePackBuild% EQU 17056 set tag=IR4&set tag2=ir4
if %ServicePackBuild% EQU 17415 set tag=IR5&set tag2=ir5
if %ServicePackBuild% GTR 17415 set tag=IR6&set tag2=ir6
if /i %Architecture%==x86_64 set arch=x64
if /i %Architecture%==x86 set arch=x86
if /i %LanguageID%==en-gb set lang=en-gb
if /i %LanguageID%==es-mx set lang=es-mx
if /i %LanguageID%==fr-ca set lang=fr-ca
if /i %LanguageID%==pt-pt set lang=pp
if /i %LanguageID%==sr-latn-rs set lang=sr-latn
if /i %LanguageID%==zh-cn set lang=cn
if /i %LanguageID%==zh-tw set lang=tw
if /i %LanguageID%==zh-hk set lang=hk
for %%b in (A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z) do set LanguageID=!LanguageID:%%b=%%b!
set DVDISO=%lang%_windows_8.1_%tag2%_%arch%_dvd.iso
if /i %EditionID%==Core set DVDISO=%lang%_windows_8.1_%tag2%_%arch%_dvd.iso
if /i %EditionID%==CoreN set DVDISO=%lang%_windows_8.1_n_%tag2%_%arch%_dvd.iso
if /i %EditionID%==CoreSingleLanguage set DVDISO=%lang%_windows_8.1_singlelanguage_%tag2%_%arch%_dvd.iso
if /i %EditionID%==CoreCountrySpecific set DVDISO=%lang%_windows_8.1_china_%tag2%_%arch%_dvd.iso
if /i %EditionID%==Professional set DVDISO=%lang%_windows_8.1_pro_%tag2%_%arch%_dvd.iso
if /i %EditionID%==ProfessionalN set DVDISO=%lang%_windows_8.1_pro_n_%tag2%_%arch%_dvd.iso
if /i %EditionID%==ProfessionalWMC set DVDISO=%lang%_windows_8.1_pro_wmc_%tag2%_%arch%_dvd.iso
if /i %EditionID%==CoreConnected set DVDISO=%lang%_windows_8.1_with_bing_%tag2%_%arch%_dvd.iso
if /i %EditionID%==CoreConnectedN set DVDISO=%lang%_windows_8.1_n_with_bing_%tag2%_%arch%_dvd.iso
if /i %EditionID%==CoreConnectedSingleLanguage set DVDISO=%lang%_windows_8.1_singlelanguage_with_bing_%tag2%_%arch%_dvd.iso
if /i %EditionID%==CoreConnectedCountrySpecific set DVDISO=%lang%_windows_8.1_china_with_bing_%tag2%_%arch%_dvd.iso
if /i %EditionID%==ProfessionalStudent set DVDISO=%lang%_windows_8.1_pro_student_%tag2%_%arch%_dvd.iso
if /i %EditionID%==ProfessionalStudentN set DVDISO=%lang%_windows_8.1_pro_student_n_%tag2%_%arch%_dvd.iso

if %Build% GTR 9600 (
	set DVDISO=%lang%_windows_10_%Build%_%arch%_dvd.iso
	if /i %EditionID%==Core set DVDISO=%lang%_windows_10_core_%Build%_%arch%_dvd.iso
	if /i %EditionID%==CoreSingleLanguage set DVDISO=%lang%_windows_10_singlelanguage_%Build%_%arch%_dvd.iso
	if /i %EditionID%==CoreCountrySpecific set DVDISO=%lang%_windows_10_china_%Build%_%arch%_dvd.iso
	if /i %EditionID%==Professional set DVDISO=%lang%_windows_10_pro_%Build%_%arch%_dvd.iso
	if /i %EditionID%==Enterprise set DVDISO=%lang%_windows_10_enterprise_%Build%_%arch%_dvd.iso
)

if %Build% GEQ 9896 (
	set DVDISO=%lang%_windows_10_technical_preview_%Build%_%arch%_dvd.iso
	if /i %EditionID%==Core set DVDISO=%lang%_windows_10_core_technical_preview_%Build%_%arch%_dvd.iso
	if /i %EditionID%==CoreSingleLanguage set DVDISO=%lang%_windows_10_singlelanguage_technical_preview_%Build%_%arch%_dvd.iso
	if /i %EditionID%==CoreCountrySpecific set DVDISO=%lang%_windows_10_china_technical_preview_%Build%_%arch%_dvd.iso
	if /i %EditionID%==Professional set DVDISO=%lang%_windows_10_pro_technical_preview_%Build%_%arch%_dvd.iso
	if /i %EditionID%==Enterprise set DVDISO=%lang%_windows_10_enterprise_technical_preview_%Build%_%arch%_dvd.iso
)

if %Build% GTR 10066 (
	set DVDISO=Windows10_InsiderPreview_%arch%_%lang%_%Build%.iso
	if /i %EditionID%==Core set DVDISO=Windows10_Core_InsiderPreview_%arch%_%lang%_%Build%.iso
	if /i %EditionID%==CoreSingleLanguage set DVDISO=Windows10_SingleLanguage_InsiderPreview_%arch%_%lang%_%Build%.iso
	if /i %EditionID%==CoreCountrySpecific set DVDISO=Windows10_China_InsiderPreview_%arch%_%lang%_%Build%.iso
	if /i %EditionID%==Professional set DVDISO=Windows10_Pro_InsiderPreview_%arch%_%lang%_%Build%.iso
	if /i %EditionID%==Enterprise set DVDISO=Windows10_Enterprise_InsiderPreview_%arch%_%lang%_%Build%.iso
)

if %Build% GEQ 10100 (
	if %Build% LSS 10104 (
		set DVDISO=%lang%_windows_10_technical_preview_%Build%_%arch%_dvd.iso
		if /i %EditionID%==Core set DVDISO=%lang%_windows_10_core_technical_preview_%Build%_%arch%_dvd.iso
		if /i %EditionID%==CoreSingleLanguage set DVDISO=%lang%_windows_10_singlelanguage_technical_preview_%Build%_%arch%_dvd.iso
		if /i %EditionID%==CoreCountrySpecific set DVDISO=%lang%_windows_10_china_technical_preview_%Build%_%arch%_dvd.iso
		if /i %EditionID%==Professional set DVDISO=%lang%_windows_10_pro_technical_preview_%Build%_%arch%_dvd.iso
		if /i %EditionID%==Enterprise set DVDISO=%lang%_windows_10_enterprise_technical_preview_%Build%_%arch%_dvd.iso
	)
)
exit /b

:GENISONAME2
if /i %Architecture%==x86_64 set arch=x64
if /i %Architecture%==x86 set arch=x86
if /i %EditionID%==Core set EditionID=CLIENTCORE_RET
if /i %EditionID%==CoreSingleLanguage set EditionID=CLIENTSINGLELANGUAGE_RET
if /i %EditionID%==CoreCountrySpecific set EditionID=CLIENTCHINA_RET
if /i %EditionID%==Professional set EditionID=CLIENTPRO_RET
if /i %EditionID%==Enterprise set EditionID=CLIENTENTERPRISE_VOL
set FILENAME=%Build%.%ServicePackBuild%.%CompileDate%.%BuildBranch%_%EditionID%_%arch%%BuildType%_%DefaultLanguage%.iso
call :UCase FILENAME DVDISO
exit /b

:GENISONAME3
set LanguageID=!DefaultLanguage!
set lang=%LanguageID:~0,2%
if /i %Architecture%==x86_64 set arch=x64
if /i %Architecture%==x86 set arch=x86
if /i %LanguageID%==en-gb set lang=en-gb
if /i %LanguageID%==es-mx set lang=es-mx
if /i %LanguageID%==fr-ca set lang=fr-ca
if /i %LanguageID%==pt-pt set lang=pp
if /i %LanguageID%==sr-latn-rs set lang=sr-latn
if /i %LanguageID%==zh-cn set lang=cn
if /i %LanguageID%==zh-tw set lang=tw
if /i %LanguageID%==zh-hk set lang=hk
call :LCase EditionID edition
call :LCase LanguageID LanguageID
call :LCase lang lang
set DVDISO=%lang%_%Build%.%ServicePackBuild%.%CompileDate%_%arch%%BuildType%_%edition%_%LanguageID%_%EditionID%-
if "%edition%"=="enterprise" set DVDISO=%lang%_%Build%.%ServicePackBuild%.%CompileDate%_%arch%%BuildType%_%edition%_%LanguageID%_VL_%EditionID%-
if "%edition%"=="enterprisen" set DVDISO=%lang%_%Build%.%ServicePackBuild%.%CompileDate%_%arch%%BuildType%_%edition%_%LanguageID%_VL_%EditionID%-
set DVDISO=%DVDISO%%DVDLABEL%.iso
exit /b

:LCase
:UCase
SET _UCase=A B C D E F G H I J K L M N O P Q R S T U V W X Y Z
SET _LCase=a b c d e f g h i j k l m n o p q r s t u v w x y z
SET _Lib_UCase_Tmp=!%1!
IF /I "%0"==":UCase" SET _Abet=%_UCase%
IF /I "%0"==":LCase" SET _Abet=%_LCase%
FOR %%Z IN (%_Abet%) DO SET _Lib_UCase_Tmp=!_Lib_UCase_Tmp:%%Z=%%Z!
SET %2=%_Lib_UCase_Tmp%
exit /b

:StartTimer
set StartTIME=%TIME%
for /f "usebackq tokens=1-4 delims=:., " %%f in (`echo %StartTIME: =0%`) do set /a Start100S=1%%f*360000+1%%g*6000+1%%h*100+1%%i-36610100
exit /b

:StopTimer
set StopTIME=%TIME%
for /f "usebackq tokens=1-4 delims=:., " %%f in (`echo %StopTIME: =0%`) do set /a Stop100S=1%%f*360000+1%%g*6000+1%%h*100+1%%i-36610100
if %Stop100S% LSS %Start100S% set /a Stop100S+=8640000
set /a TookTime=%Stop100S%-%Start100S%
set TookTimePadded=0%TookTime%
exit /b

:DisplayTimerResult
echo Started: %StartTime%
echo Stopped: %StopTime%
echo Elapsed: %TookTime:~0,-2%.%TookTimePadded:~-2% seconds
exit /b

:error
if exist ISOFOLDER\nul rmdir /s /q ISOFOLDER\
IF EXIST "!ESD!.bak" (
	del /f /q "!ESD!" >nul 2>&1
	ren "!ESD!.bak" "!ESD!"
)
exit /b

:: UPDATE SYSTEM
:updatesystem
if exist "%~1\%~nx0" (
	CD /D "%~1"
)
if not "%~1"=="/noupdate" (
	PING -n 3 gus33000.github.io >NUL
	IF ERRORLEVEL 1 echo [Info] No Internet Connection found, couldn't check for updates
	IF NOT ERRORLEVEL 1 call :autoupdate %*
)
exit /b

:autoupdate
set updateserver=http://gus33000.github.io/ESD-Decrypter/update
Echo [Info] Script Current Build Number : %curver%
Echo [Info] Checking for Updates...
set "url=%updateserver%/version.txt"
if not exist "%temp%\ESD-Decrypter\version.txt" mkdir "%temp%\ESD-Decrypter"
if exist "%temp%\ESD-Decrypter\version.txt" del "%temp%\ESD-Decrypter\version.txt"
for /f "tokens=3 delims=:. " %%f in ('bitsadmin.exe /CREATE /DOWNLOAD "ESD-Decrypter Update Services" ^| findstr "Created job"') do set GUID=%%f
bitsadmin>nul /transfer %GUID% /download /priority foreground %url% "%temp%\ESD-Decrypter\version.txt"
for /f %%f in ('type %temp%\ESD-Decrypter\version.txt') do if %curver% GEQ %%f (
	echo [Info] You are using the latest version of ESD-Decrypter !
	rmdir /S /Q "%temp%\ESD-Decrypter"
	exit /b
)
for /f %%f in ('type %temp%\ESD-Decrypter\version.txt') do set NewVersion=%%f
echo [Info] Found a new update for you : version %NewVersion%
if "%FILE%"=="%CD%\%~nx0" (
	xcopy "%FILE%" "%temp%\ESD-Decrypter\" /cherikyq
	start /D "%CD%" %temp%\ESD-Decrypter\%FILEN% "%CD%" %*
	exit 101
)
echo [Info] Downloading version %NewVersion%...
set "url=%updateserver%/%NewVersion%.zip"
for /f "tokens=3 delims=:. " %%f in ('bitsadmin.exe /CREATE /DOWNLOAD "ESD-Decrypter Update Services" ^| findstr "Created job"') do set GUID=%%f
bitsadmin>nul /transfer %GUID% /download /priority foreground %url% "%temp%\ESD-Decrypter\%NewVersion%.zip"
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
echo         /NoBackup        Flag to prevent the script from backing up the file
echo         /DeleteESD       Flag to tell the script to delete the esd files after finishing         
echo         /Scheme ^<SchemeNumber^> 1 for common filenames
echo                                2 for Windows Build Lab styled filenames
echo                                3 for Windows 7 Styled filenames
echo      Scheme samples :
echo.
echo         1. en-gb_windows_10_enterprise_technical_preview_10061_x64_dvd.iso
echo         2. 10061.0.150410-2039.FBL_IMPRESSIVE_CLIENTENTERPRISE_VOL_X64FRE_EN-GB.ISO
echo         3. en-gb_10061.0.150410-2039_x64fre_enterprise_en-gb_VL_Enterprise-J_CENA_X64FREV_EN-GB_DV5.iso
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
echo      Additional Stuff :
echo.
echo      Place this switch at the beginning of each commands to not check for
echo      updates : /noupdate
echo.
echo      To display help run the following command : /help
exit /b