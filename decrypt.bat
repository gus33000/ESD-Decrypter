@setlocal enableextensions enabledelayedexpansion
@echo off
set "params=%*"
if not "!params!"=="" set "params=%params:"=""%"
pushd "%cd%" && cd /d "%~dp0" && ( if exist "%temp%\getadmin.vbs" del "%temp%\getadmin.vbs" ) && fsutil dirty query %systemdrive% >nul || if ERRORLEVEL==0 (  echo Set UAC = CreateObject^("Shell.Application"^) : UAC.ShellExecute "cmd.exe", "/k cd ""%~sdp0"" && ""%~s0"" %params%", "", "runas", 1 >> "%temp%\getadmin.vbs" && "%temp%\getadmin.vbs" && exit /B )
echo.
echo ESD Decrypter / Converter to ISO - Based on the script by abbodi1406
echo Made with love by gus33000 - Copyright 2015 (c) gus33000 - Version 1.0
echo.
Rem cursorpos and colorshow created by Antonio Perez Ayala
Rem http://www.dostips.com/forum/viewtopic.php?f=3&t=3428
call :heredoc cursorpos >cursorpos.hex && goto endCursorpos
4D5A900003[3]04[3]FFFF[2]B8[7]40[35]B0[3]0E1FBA0E00B409CD21B8014CCD21546869732070726F6772616D2063616E6E6F74
2062652072756E20696E20444F53206D6F64652E0D0D0A24[7]55B5B8FD11D4D6AE11D4D6AE11D4D6AE9FCBC5AE18D4D6AEED
F4C4AE13D4D6AE5269636811D4D6AE[8]5045[2]4C010200EB84E24F[8]E0000F010B01050C0002[3]02[7]10[3]10[3]20[4]40[2]10
[3]02[2]04[7]04[8]30[3]02[6]03[5]10[2]10[4]10[2]10[6]10[11]1C20[2]28[84]20[2]1C[27]2E74657874[3]4201[3]10[3]02[3]02[14]20[2]60
2E7264617461[2]F6[4]20[3]02[3]04[14]40[2]40[8]E806[3]50E81301[2]558BEC83C4E06AF5E81201[2]8945FC8D45E650FF75FCE8
FD[3]668B45EC668945E4E8BC[3]E8DB[3]803E0075058B45EAEB5C803E3D750646E8C6[3]668B4DEAE84A[3]8945EAE8B5[3]803E
007418803E2C750646E8A5[3]668B4DE4E829[3]668945EC8B5DEA53FF75FCE8AE[3]8D45E650536A018D45E350FF75FCE895[3]0F
B645E3C9C333C032DB33D28A164680FA2B740880FA2D750980CB0280CB018A164680FA30720F80FA39770A80EA306BC00A03
C2EBE9F6C301740BF6C302740366F7D86603C14EC3CCCCCCCCCCCCCCCCCCCCCCCCCCE847[3]8BF08A06463C2275098A06463C
2275F9EB0C8A06463C20740484C075F54EC38A06463C2074F94EC3CCFF2514204000FF2500204000FF2504204000FF250820
4000FF250C204000FF25102040[191]6E20[2]8C20[2]9C20[2]BA20[2]D620[2]6020[6]4420[10]E820[3]20[22]6E20[2]8C20[2]9C20[2]BA
20[2]D620[2]6020[6]9B004578697450726F6365737300F500476574436F6E736F6C6553637265656E427566666572496E666F
[2]6A0147657453746448616E646C65[2]380252656164436F6E736F6C654F757470757443686172616374657241006D025365
74436F6E736F6C65437572736F72506F736974696F6E[2]E600476574436F6D6D616E644C696E6541006B65726E656C33322E
646C6C[268]
:endCursorpos

call :heredoc hexchar >hexchar.vbs && goto endHexchar
Rem Hex digits to Ascii Characters conversion
Rem Antonio Perez Ayala - Apr/14/2012

Dim line,index,count
line = WScript.StdIn.ReadLine()
While line <> ""
   index = 1
   While index < len(line)
      If Mid(line,index,1) = "[" Then
         index = index+1
         count = 0
         While Mid(line,index+count,1) <> "]"
            count = count+1
         WEnd
         For i=1 To Int(Mid(line,index,count))
            WScript.StdOut.Write Chr(0)
         Next
         index = index+count+1
      Else
         WScript.StdOut.Write Chr(CByte("&H"&Mid(line,index,2)))
         index = index+2
      End If
   WEnd
   line = WScript.StdIn.ReadLine()
WEnd
:endHexchar

cscript /nologo /B /E:VBS HexChar.vbs < "cursorpos.hex" > "cursorpos.exe"
del cursorpos.hex
del hexchar.vbs

:Main
if "%~1"=="/help" goto help
:: UPDATE SYSTEM
set "FILE=%~0"
set "FILEN=%~nx0"
set curver=1020
call :updatesystem %*
if "%~1"=="/noupdate" shift
:: UPDATE SYSTEM
if "%~1"=="/Mode:1" set CHOICE=WIM
if "%~1"=="/Mode:1" goto :PARSE
if "%~1"=="/Mode:2" set CHOICE=ESD
if "%~1"=="/Mode:2" goto :PARSE
if "%~1"=="/Mode:3" goto :PARSE3
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

:PARSE3
echo.
shift
if not exist "%~1" (
	echo [Critical] The filename is missing.
	exit /b
)
call :ISO2ESD "%~1"
exit /b

:ISO2ESD <ISO>
set "wimlib=%~dps0bin\wimlib-imagex.exe"
if %PROCESSOR_ARCHITECTURE%==AMD64 set "wimlib=%~dps0bin\bin64\wimlib-imagex.exe"
if not exist "%wimlib%" (
	echo [Critical] %PROCESSOR_ARCHITECTURE% wimlib-imagex.exe not found
	exit /b
)
echo [Info] Extracting Image files...
bin\7z>nul x -y -o.\WIMExtract "%~1" -ir@bin\exclude.txt
echo [Info] Extracting "Windows Setup Media"...
bin\7z>nul x -y -o.\ISOExtract "%~1" -xr@bin\exclude.txt
for /f "tokens=2 delims==" %%a in ('find "BuildBranch=" ".\ISOExtract\sources\idwbinfo.txt"') do @set BuildBranch=%%a
for /f "tokens=2 delims==" %%a in ('find "BuildType=" ".\ISOExtract\sources\idwbinfo.txt"') do @set BuildType=%%a
for /f "tokens=6 delims=:.()" %%a in ('powershell -Command "[System.Diagnostics.FileVersionInfo]::GetVersionInfo('.\ISOExtract\setup.exe').FileVersion"') do set CompileDate=%%a
for /f "tokens=4 delims=: " %%i in ('%wimlib% info ".\WIMExtract\sources\install.wim" --header ^| find /i "Image Count"') do set count=%%i
for /l %%n in (1 1 %count%) do (
	for /f "skip=2 delims=" %%f in ('%wimlib% info ".\WIMExtract\sources\install.wim" %%n') do (
		for /f "tokens=1 delims=:" %%a in ('echo %%f') do set value=%%a
		for /f "tokens=2* delims=:" %%a in ('echo %%f') do (
			for /f "tokens=*" %%i in ('echo %%a') do set "var=%%i"
		)
		set param=!value: =!
		set "!param![%%n]=!var!"
	)
	set "choice=!choice!%%n"
)
if not "%count%"=="1" (
	echo.
	echo Please Select which Index do you want to export to the ESD Image
	echo ออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออ
	echo.
	for /l %%n in (1 1 %count%) do (
		if /i !Architecture[%%n]!==x86 set arch=x86&archl=X86
		if /i !Architecture[%%n]!==x86_64 set arch=x64&set archl=X64
		if "!DisplayName[%%n]!"=="" (
			echo [%%n] Name        : !Name[%%n]!
			echo     Description : !Description[%%n]!
			echo     Architecture: !arch!
		)
		if not "!DisplayName[%%n]!"=="" (
			echo [%%n] Name        : !DisplayName[%%n]!
			echo     Description : !DisplayDescription[%%n]!
			echo     Architecture: !arch!
		)
	)
	echo.
	choice /N /C !choice! /M "Your choice : "
	set CHOICE=!ERRORLEVEL!
	echo.
)
if "%count%"=="1" set CHOICE=1
if /i !EditionID[%CHOICE%]!==Core set Edition=CORE
if /i !EditionID[%CHOICE%]!==CoreSingleLanguage set Edition=SINGLELANGUAGE
if /i !EditionID[%CHOICE%]!==CoreCountrySpecific set Edition=CHINA
if /i !EditionID[%CHOICE%]!==Professional set Edition=PRO
if /i !EditionID[%CHOICE%]!==Enterprise set Edition=ENTERPRISE
if /i !EditionID[%CHOICE%]!==Core set Licensing=RET
if /i !EditionID[%CHOICE%]!==CoreSingleLanguage set Licensing=RET
if /i !EditionID[%CHOICE%]!==CoreCountrySpecific set Licensing=RET
if /i !EditionID[%CHOICE%]!==Professional set Licensing=RET
if /i !EditionID[%CHOICE%]!==Enterprise set Licensing=VOL
if /i !Architecture[%CHOICE%]!==x86_64 set arch=x64
if /i !Architecture[%CHOICE%]!==x86 set arch=x86
set FILENAME=!Build[%CHOICE%]!.!ServicePackBuild[%CHOICE%]!.!CompileDate!.!BuildBranch!_CLIENT!Edition!_!Licensing!_!arch!!BuildType!_!DefaultLanguage[%CHOICE%]!.esd
call :LCase FILENAME DVDESD
echo [Info] Capturing "Windows Setup Media"...
echo.
%wimlib% capture .\ISOExtract !DVDESD! "Windows Setup Media" "Windows Setup Media" --compress=LZMS --solid
echo.
rmdir /Q /S .\ISOExtract
echo [Info] Exporting "Microsoft Windows PE"...
echo.
%wimlib% export .\WIMExtract\sources\boot.wim 1 !DVDESD! --compress=LZMS --solid
echo.
%wimlib% export .\WIMExtract\sources\boot.wim 2 !DVDESD! --compress=LZMS --solid
echo.
echo [Info] Exporting "Microsoft Windows Image"...
echo.
%wimlib% export .\WIMExtract\sources\install.wim !CHOICE! !DVDESD! --compress=LZMS --solid
echo.
rmdir /Q /S .\WIMExtract
exit /b

:ESD2ISO <MODE(WIM|ESD)> <ESD> <Output> <Backup(YES|NO)> <DeleteESD(YES|NO)> <Scheme> {key}

echo.
cursorpos
call :GetCoords OCols OLines
call :Progress 0
echo.
echo.

set "MODE=%~1"
set "ESD=%~2"
set "Output=%~3"
set "Backup=%~4"
set "DeleteESD=%~5"
set "Scheme=%~6"
set "Key=%~7"
if [%Output:~-1%]==[\] set "OUT=%Output:~0,-1%"

set counter=0
echo>%temp%\getfiles.vbs Set objFS=CreateObject("Scripting.FileSystemObject")
echo>>%temp%\getfiles.vbs Set objArgs = WScript.Arguments
echo>>%temp%\getfiles.vbs strInput = objArgs(0)
echo>>%temp%\getfiles.vbs s = Split(strInput,"*")
echo>>%temp%\getfiles.vbs For Each i In s
echo>>%temp%\getfiles.vbs  WScript.Echo i
echo>>%temp%\getfiles.vbs Next
for /f "delims=*" %%f in ('cscript //nologo %temp%\getfiles.vbs "%ESD%"') do (
	set /a counter+=1
	set "ESD[!counter!]=%%f"
)
del>nul %temp%\getfiles.vbs

if not "!MODE!"=="WIM" if not "!MODE!"=="ESD" call :Exception MODE
for /f "tokens=2 delims==" %%f in ('set ESD[') do (
	if not exist "!ESD!" call :Exception ESD_Not_Found
)
if not exist "!Output!" mkdir "!Output!"
if not exist "!Output!"  call :Exception Output_Not_Valid

set "wimlib=%~dps0bin\wimlib-imagex.exe"
if %PROCESSOR_ARCHITECTURE%==AMD64 set "wimlib=%~dps0bin\bin64\wimlib-imagex.exe"
if not exist "!wimlib!" (
	call :Exception WIMLIB_Notfound
)

for /f "tokens=2 delims==" %%f in ('set ESD[') do (
	Echo [Info] ESD Being processed currently :
	Echo.
	Echo %%~nxf
	Echo.
	Echo [Info] Checking the current state of the provided ESD File...
	"!wimlib!" info "%%f" 4 1>nul 2>nul
	IF !ERRORLEVEL! EQU 74 call :DecryptManager "%%f" "!Backup!" "!Key!"
	IF !ERRORLEVEL! NEQ 0 call :Exception ESD_Damaged
	call :IsValid "%%f"
)
Echo [Info] Getting Informations from the provided ESD File...
call :GETESDINFO "!ESD!" !Scheme!
Echo [Info] The ISO will be saved with the following specifications :
Echo.
Echo [Info] Filename: !DVDISO!
Echo [Info] Label: !DVDLABEL!
Echo.
echo [Info] Creating Setup Media Layout...

IF EXIST ISOFOLDER\ rmdir /s /q ISOFOLDER\
mkdir ISOFOLDER
echo.
"!wimlib!" apply "!ESD[1]!" 1 ISOFOLDER\
IF NOT ERRORLEVEL 0 call :Exception Apply
Echo.
del ISOFOLDER\MediaMeta.xml 1>nul 2>nul
call :progress 40
echo [Info] Creating boot.wim file...
Echo.
"!wimlib!" export "!ESD[1]!" 2 ISOFOLDER\sources\boot.wim --compress=maximum
IF NOT ERRORLEVEL 0 call :Exception Export
Echo.
call :progress 50
echo.
"!wimlib!" export "!ESD[1]!" 3 ISOFOLDER\sources\boot.wim --boot
IF NOT ERRORLEVEL 0 call :Exception Export
echo.
call :progress 60
if "!MODE!"=="WIM" (
	echo [Info] Creating install.wim file...
	for /f "tokens=2 delims==" %%f in ('set ESD[') do (
		Echo.
		"!wimlib!" export "%%f" 4 ISOFOLDER\sources\install.wim --compress=maximum
		IF NOT ERRORLEVEL 0 call :Exception Export
		Echo.
	)
)
if "!MODE!"=="ESD" (
	echo [Info] Creating install.esd file...
	Echo.
	for /f "tokens=2 delims==" %%f in ('set ESD[') do (
		"!wimlib!" export "%%f" 4 ISOFOLDER\sources\install.esd
		IF NOT ERRORLEVEL 0 call :Exception Export
		Echo.
	)
)
for /l %%n in (1 1 %counter%) do (
	if /i !EditionID[%%n]!==ProfessionalWMC (
		echo [Info] Integrating Generic WMC Tokens
		Echo.
		if %MODE%==WIM "!wimlib!" update ISOFOLDER\sources\install.wim %%n <bin\wim-update.txt 1>nul 2>nul
		if %MODE%==ESD "!wimlib!" update ISOFOLDER\sources\install.esd %%n <bin\wim-update.txt 1>nul 2>nul
		Echo.
	)
)
call :progress 80
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
bin\cdimage.exe -bootdata:2#p0,e,b"ISOFOLDER\boot\etfsboot.com"#pEF,e,b"ISOFOLDER\efi\Microsoft\boot\efisys.bin" -o -h -m -u2 -udfver102 -t%mm%/%dd%/%yyyy%,%time%:00 -l%DVDLABEL% ISOFOLDER %Output%\%DVDISO%
IF NOT ERRORLEVEL 0 call :Exception ISO
call :progress 90
rmdir /s /q ISOFOLDER\
if "!Backup!"=="YES" (
	for /f "tokens=2 delims==" %%f in ('set ESD[') do (
		IF EXIST "%%f.bak" (
			del /f /q "%%f" >nul 2>&1
			ren "%%~f.bak" "%%~f"
		)
	)
)
if "!DeleteESD!"=="YES" (
	for /f "tokens=2 delims==" %%f in ('set ESD[') do (
		del /f /q "%%f" >nul 2>&1
	)
)
call :progress 100
exit /b

:DecryptManager <ESD> <Backup(YES|NO)> {key}
set "ESD_=%~1"
set "Backup_=%~2"
set "Key_=%~3"
if "!Backup_!"=="YES" (
	if not exist "!ESD_!.bak" (
		echo [Info] Backing up original esd file...
		echo.
		copy "!ESD_!" "!ESD_!.bak" /z
		echo.
	)
)
echo [Info] Running Decryption program...
bin\esddecrypt.exe "!ESD_!" 2>"%temp%\esddecrypt.log"&&exit /b
bin\esddecrypt.exe "!ESD_!" "!Key_!" &&exit /b
call :Exception ESD_Decrypt
exit /b

:IsValid <ESD>
set "ESD_=%~1"
Echo [Info] Checking Validity of the Provided ESD File...
for /f "delims=" %%f in ('!wimlib! info "!ESD_!" --header') do (
	for /f "tokens=1 delims=:=" %%a in ('echo %%f') do set value=%%a
	for /f "tokens=2* delims=:=" %%a in ('echo %%f') do (
		for /f "tokens=*" %%i in ('echo %%a') do set "var=%%i"
	)
	set param=!value: =!
	set "!param!=!var!"
)
if not "!ImageCount!"=="4" call :Exception ESD_Damaged
exit /b

:GETESDINFO <ESD>
set "ESD_=%~1"
set counter2=0
echo>%temp%\getfiles.vbs Set objFS=CreateObject("Scripting.FileSystemObject")
echo>>%temp%\getfiles.vbs Set objArgs = WScript.Arguments
echo>>%temp%\getfiles.vbs strInput = objArgs(0)
echo>>%temp%\getfiles.vbs s = Split(strInput,"*")
echo>>%temp%\getfiles.vbs For Each i In s
echo>>%temp%\getfiles.vbs  WScript.Echo i
echo>>%temp%\getfiles.vbs Next
for /f "delims=" %%f in ('cscript //nologo %temp%\getfiles.vbs "%ESD_%"') do (
	set /a counter2+=1
	set "ESD2[!counter2!]=%%f"
)
for /l %%n in (1 1 %counter2%) do (
	"!wimlib!">nul extract "!ESD2[%%n]!" 1 sources\idwbinfo.txt
	for /f "tokens=2 delims==" %%a in ('find "BuildBranch=" "idwbinfo.txt"') do @set BuildBranch[%%n]=%%a
	for /f "tokens=2 delims==" %%a in ('find "BuildType=" "idwbinfo.txt"') do @set BuildType[%%n]=%%a
	del>nul idwbinfo.txt
	"!wimlib!">nul extract "!ESD2[%%n]!" 1 setup.exe
	for /f "tokens=6 delims=:.()" %%a in ('powershell -Command "[System.Diagnostics.FileVersionInfo]::GetVersionInfo('setup.exe').FileVersion"') do set CompileDate[%%n]=%%a
	del>nul setup.exe
	for /f "skip=2 delims=" %%f in ('!wimlib! info "!ESD2[%%n]!" 4') do (
		for /f "tokens=1 delims=:" %%a in ('echo %%f') do set value=%%a
		for /f "tokens=2* delims=:" %%a in ('echo %%f') do (
			for /f "tokens=*" %%i in ('echo %%a') do set "var=%%i"
		)
		set param=!value: =!
		set "!param![%%n]=!var!"
	)
)

for /l %%n in (1 1 %counter2%) do (
	Echo [Info] Detailed ESD Information for :
	echo.
	for /f "delims=" %%f in ('echo !ESD2[%%n]!') do echo %%~xnf
	if /i !Architecture[%%n]!==x86 set arch=x86&archl=X86
	if /i !Architecture[%%n]!==x86_64 set arch=x64&set archl=X64
	Echo.
	echo [Info] ออออออออออออออออออออออออออออออออออออออออออออออ
	echo [Info] Build : !Build[%%n]!.!ServicePackBuild[%%n]!.!CompileDate[%%n]!
	echo [Info] Build Branch : !BuildBranch[%%n]!
	echo [Info] Build Type : !BuildType[%%n]!
	echo [Info] Architecture : !arch!
	echo [Info] Edition : !EditionID[%%n]!
	echo [Info] Language : !DefaultLanguage[%%n]!
	echo [Info] ออออออออออออออออออออออออออออออออออออออออออออออ
	echo.
)

set LanguageID=!DefaultLanguage[1]!
for %%b in (A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z) do set LanguageID=!LanguageID:%%b=%%b!
set tag=IR3&set tag2=ir3
if %ServicePackBuild[1]% EQU 17056 set tag=IR4&set tag2=ir4
if %ServicePackBuild[1]% EQU 17415 set tag=IR5&set tag2=ir5
if %ServicePackBuild[1]% GTR 17415 set tag=IR6&set tag2=ir6
if /i %Architecture[1]%==x86 set arch=x86&archl=X86
if /i %Architecture[1]%==x86_64 set arch=x64&set archl=X64

if not "%counter2%"=="1" (
	set DVDLABEL=%tag%_CCSA_%archl%FRER_%LanguageID%_DV9
	if %Build[1]% GTR 9600 set DVDLABEL=JM1_CCSA_%archl%FRE_%LanguageID%_DV5
	if %Build[1]% GEQ 9896 set DVDLABEL=J_CCSA_%archl%FRE_%LanguageID%_DV5
	if %Build[1]% GTR 10066 set DVDLABEL=J_CCSA_%archl%FRE_%LanguageID%_DV5
	if %Build[1]% GEQ 10100 if %Build[1]% LSS 10104 set DVDLABEL=J_CCSA_%archl%FRE_%LanguageID%_DV5
	call :GENISONAME%~2 "%~1"
	exit /b
)
set DVDLABEL=%tag%_CCSA_%archl%FRER_%LanguageID%_DV9
if /i %EditionID[1]%==Core set DVDLABEL=%tag%_CCRA_%archl%FRER_%LanguageID%_DV9
if /i %EditionID[1]%==CoreN set DVDLABEL=%tag%_CCRNA_%archl%FRER_%LanguageID%_DV9
if /i %EditionID[1]%==CoreSingleLanguage set DVDLABEL=%tag%_CSLA_%archl%FRER_%LanguageID%_DV9
if /i %EditionID[1]%==CoreCountrySpecific set DVDLABEL=%tag%_CCHA_%archl%FRER_%LanguageID%_DV9
if /i %EditionID[1]%==Professional set DVDLABEL=%tag%_CPRA_%archl%FRER_%LanguageID%_DV9
if /i %EditionID[1]%==ProfessionalN set DVDLABEL=%tag%_CPRNA_%archl%FRER_%LanguageID%_DV9
if /i %EditionID[1]%==ProfessionalWMC set DVDLABEL=%tag%_CPWMCA_%archl%FRER_%LanguageID%_DV9
if /i %EditionID[1]%==CoreConnected set DVDLABEL=%tag%_CCONA_%archl%FRER_%LanguageID%_DV9
if /i %EditionID[1]%==CoreConnectedN set DVDLABEL=%tag%_CCONNA_%archl%FRER_%LanguageID%_DV9
if /i %EditionID[1]%==CoreConnectedSingleLanguage set DVDLABEL=%tag%_CCSLA_%archl%FRER_%LanguageID%_DV9
if /i %EditionID[1]%==CoreConnectedCountrySpecific set DVDLABEL=%tag%_CCCHA_%archl%FRER_%LanguageID%_DV9
if /i %EditionID[1]%==ProfessionalStudent set DVDLABEL=%tag%_CPRSA_%archl%FRER_%LanguageID%_DV9
if /i %EditionID[1]%==ProfessionalStudentN set DVDLABEL=%tag%_CPRSNA_%archl%FRER_%LanguageID%_DV9

if %Build[1]% GTR 9600 (
	set DVDLABEL=JM1_CCSA_%archl%FRE_%LanguageID%_DV5
	if /i %EditionID[1]%==Core set DVDLABEL=JM1_CCRA_%archl%FRER_%LanguageID%_DV5
	if /i %EditionID[1]%==CoreSingleLanguage set DVDLABEL=JM1_CSLA_%archl%FRER_%LanguageID%_DV5
	if /i %EditionID[1]%==CoreCountrySpecific set DVDLABEL=JM1_CCHA_%archl%FRER_%LanguageID%_DV5
	if /i %EditionID[1]%==Professional set DVDLABEL=JM1_CPRA_%archl%FRER_%LanguageID%_DV5
	if /i %EditionID[1]%==Enterprise set DVDLABEL=JM1_CENA_%archl%FREV_%LanguageID%_DV5
)

if %Build[1]% GEQ 9896 (
	set DVDLABEL=J_CCSA_%archl%FRE_%LanguageID%_DV5
	if /i %EditionID[1]%==Core set DVDLABEL=J_CCRA_%archl%FRE_%LanguageID%_DV5
	if /i %EditionID[1]%==CoreSingleLanguage set DVDLABEL=J_CSLA_%archl%FRER_%LanguageID%_DV5
	if /i %EditionID[1]%==CoreCountrySpecific set DVDLABEL=J_CCHA_%archl%FRER_%LanguageID%_DV5
	if /i %EditionID[1]%==Professional set DVDLABEL=J_CPRA_%archl%FRE_%LanguageID%_DV5
	if /i %EditionID[1]%==Enterprise set DVDLABEL=J_CENA_%archl%FREV_%LanguageID%_DV5
)

if %Build[1]% GTR 10066 (
	set DVDLABEL=J_CCSA_%archl%FRE_%LanguageID%_DV5
	if /i %EditionID[1]%==Core set DVDLABEL=J_CCRA_%archl%FRE_%LanguageID%_DV5
	if /i %EditionID[1]%==CoreSingleLanguage set DVDLABEL=J_CSLA_%archl%FRER_%LanguageID%_DV5
	if /i %EditionID[1]%==CoreCountrySpecific set DVDLABEL=J_CCHA_%archl%FRER_%LanguageID%_DV5
	if /i %EditionID[1]%==Professional set DVDLABEL=J_CPRA_%archl%FRE_%LanguageID%_DV5
	if /i %EditionID[1]%==Enterprise set DVDLABEL=J_CENA_%archl%FREV_%LanguageID%_DV5
)

if %Build[1]% GEQ 10100 (
	if %Build[1]% LSS 10104 (
		set DVDLABEL=J_CCSA_%archl%FRE_%LanguageID%_DV5
		if /i %EditionID[1]%==Core set DVDLABEL=J_CCRA_%archl%FRE_%LanguageID%_DV5
		if /i %EditionID[1]%==CoreSingleLanguage set DVDLABEL=J_CSLA_%archl%FRER_%LanguageID%_DV5
		if /i %EditionID[1]%==CoreCountrySpecific set DVDLABEL=J_CCHA_%archl%FRER_%LanguageID%_DV5
		if /i %EditionID[1]%==Professional set DVDLABEL=J_CPRA_%archl%FRE_%LanguageID%_DV5
		if /i %EditionID[1]%==Enterprise set DVDLABEL=J_CENA_%archl%FREV_%LanguageID%_DV5
	)
)
call :GENISONAME%~2 "%~1"
exit /b

:GENISONAME1
set LanguageID=!DefaultLanguage[1]!
set lang=%LanguageID:~0,2%
set tag=IR3&set tag2=ir3
if %ServicePackBuild[1]% EQU 17056 set tag=IR4&set tag2=ir4
if %ServicePackBuild[1]% EQU 17415 set tag=IR5&set tag2=ir5
if %ServicePackBuild[1]% GTR 17415 set tag=IR6&set tag2=ir6
if /i %Architecture[1]%==x86_64 set arch=x64
if /i %Architecture[1]%==x86 set arch=x86
if /i %LanguageID%==en-gb set lang=en-gb
if /i %LanguageID%==es-mx set lang=es-mx
if /i %LanguageID%==fr-ca set lang=fr-ca
if /i %LanguageID%==pt-pt set lang=pp
if /i %LanguageID%==sr-latn-rs set lang=sr-latn
if /i %LanguageID%==zh-cn set lang=cn
if /i %LanguageID%==zh-tw set lang=tw
if /i %LanguageID%==zh-hk set lang=hk
for %%b in (A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z) do set LanguageID=!LanguageID:%%b=%%b!

if not "%counter2%"=="1" (
	set DVDISO=%lang%_windows_8.1_%tag2%_%arch%_dvd.iso
	if %Build[1]% GTR 9600 set DVDISO=%lang%_windows_10_%Build[1]%_%arch%_dvd.iso
	if %Build[1]% GEQ 9896 set DVDISO=%lang%_windows_10_technical_preview_%Build[1]%_%arch%_dvd.iso
	if %Build[1]% GTR 10066 set DVDISO=Windows10_InsiderPreview_%arch%_%lang%_%Build[1]%.iso
	if %Build[1]% GEQ 10100 if %Build[1]% LSS 10104 set DVDISO=%lang%_windows_10_technical_preview_%Build[1]%_%arch%_dvd.iso
	exit /b
)

set DVDISO=%lang%_windows_8.1_%tag2%_%arch%_dvd.iso
if /i %EditionID[1]%==Core set DVDISO=%lang%_windows_8.1_%tag2%_%arch%_dvd.iso
if /i %EditionID[1]%==CoreN set DVDISO=%lang%_windows_8.1_n_%tag2%_%arch%_dvd.iso
if /i %EditionID[1]%==CoreSingleLanguage set DVDISO=%lang%_windows_8.1_singlelanguage_%tag2%_%arch%_dvd.iso
if /i %EditionID[1]%==CoreCountrySpecific set DVDISO=%lang%_windows_8.1_china_%tag2%_%arch%_dvd.iso
if /i %EditionID[1]%==Professional set DVDISO=%lang%_windows_8.1_pro_%tag2%_%arch%_dvd.iso
if /i %EditionID[1]%==ProfessionalN set DVDISO=%lang%_windows_8.1_pro_n_%tag2%_%arch%_dvd.iso
if /i %EditionID[1]%==ProfessionalWMC set DVDISO=%lang%_windows_8.1_pro_wmc_%tag2%_%arch%_dvd.iso
if /i %EditionID[1]%==CoreConnected set DVDISO=%lang%_windows_8.1_with_bing_%tag2%_%arch%_dvd.iso
if /i %EditionID[1]%==CoreConnectedN set DVDISO=%lang%_windows_8.1_n_with_bing_%tag2%_%arch%_dvd.iso
if /i %EditionID[1]%==CoreConnectedSingleLanguage set DVDISO=%lang%_windows_8.1_singlelanguage_with_bing_%tag2%_%arch%_dvd.iso
if /i %EditionID[1]%==CoreConnectedCountrySpecific set DVDISO=%lang%_windows_8.1_china_with_bing_%tag2%_%arch%_dvd.iso
if /i %EditionID[1]%==ProfessionalStudent set DVDISO=%lang%_windows_8.1_pro_student_%tag2%_%arch%_dvd.iso
if /i %EditionID[1]%==ProfessionalStudentN set DVDISO=%lang%_windows_8.1_pro_student_n_%tag2%_%arch%_dvd.iso

if %Build[1]% GTR 9600 (
	set DVDISO=%lang%_windows_10_%Build[1]%_%arch%_dvd.iso
	if /i %EditionID[1]%==Core set DVDISO=%lang%_windows_10_core_%Build[1]%_%arch%_dvd.iso
	if /i %EditionID[1]%==CoreSingleLanguage set DVDISO=%lang%_windows_10_singlelanguage_%Build[1]%_%arch%_dvd.iso
	if /i %EditionID[1]%==CoreCountrySpecific set DVDISO=%lang%_windows_10_china_%Build[1]%_%arch%_dvd.iso
	if /i %EditionID[1]%==Professional set DVDISO=%lang%_windows_10_pro_%Build[1]%_%arch%_dvd.iso
	if /i %EditionID[1]%==Enterprise set DVDISO=%lang%_windows_10_enterprise_%Build[1]%_%arch%_dvd.iso
)

if %Build[1]% GEQ 9896 (
	set DVDISO=%lang%_windows_10_technical_preview_%Build[1]%_%arch%_dvd.iso
	if /i %EditionID[1]%==Core set DVDISO=%lang%_windows_10_core_technical_preview_%Build[1]%_%arch%_dvd.iso
	if /i %EditionID[1]%==CoreSingleLanguage set DVDISO=%lang%_windows_10_singlelanguage_technical_preview_%Build[1]%_%arch%_dvd.iso
	if /i %EditionID[1]%==CoreCountrySpecific set DVDISO=%lang%_windows_10_china_technical_preview_%Build[1]%_%arch%_dvd.iso
	if /i %EditionID[1]%==Professional set DVDISO=%lang%_windows_10_pro_technical_preview_%Build[1]%_%arch%_dvd.iso
	if /i %EditionID[1]%==Enterprise set DVDISO=%lang%_windows_10_enterprise_technical_preview_%Build[1]%_%arch%_dvd.iso
)

if %Build[1]% GTR 10066 (
	set DVDISO=Windows10_InsiderPreview_%arch%_%lang%_%Build[1]%.iso
	if /i %EditionID[1]%==Core set DVDISO=Windows10_Core_InsiderPreview_%arch%_%lang%_%Build[1]%.iso
	if /i %EditionID[1]%==CoreSingleLanguage set DVDISO=Windows10_SingleLanguage_InsiderPreview_%arch%_%lang%_%Build[1]%.iso
	if /i %EditionID[1]%==CoreCountrySpecific set DVDISO=Windows10_China_InsiderPreview_%arch%_%lang%_%Build[1]%.iso
	if /i %EditionID[1]%==Professional set DVDISO=Windows10_Pro_InsiderPreview_%arch%_%lang%_%Build[1]%.iso
	if /i %EditionID[1]%==Enterprise set DVDISO=Windows10_Enterprise_InsiderPreview_%arch%_%lang%_%Build[1]%.iso
)

if %Build[1]% GEQ 10100 (
	if %Build[1]% LSS 10104 (
		set DVDISO=%lang%_windows_10_technical_preview_%Build[1]%_%arch%_dvd.iso
		if /i %EditionID[1]%==Core set DVDISO=%lang%_windows_10_core_technical_preview_%Build[1]%_%arch%_dvd.iso
		if /i %EditionID[1]%==CoreSingleLanguage set DVDISO=%lang%_windows_10_singlelanguage_technical_preview_%Build[1]%_%arch%_dvd.iso
		if /i %EditionID[1]%==CoreCountrySpecific set DVDISO=%lang%_windows_10_china_technical_preview_%Build[1]%_%arch%_dvd.iso
		if /i %EditionID[1]%==Professional set DVDISO=%lang%_windows_10_pro_technical_preview_%Build[1]%_%arch%_dvd.iso
		if /i %EditionID[1]%==Enterprise set DVDISO=%lang%_windows_10_enterprise_technical_preview_%Build[1]%_%arch%_dvd.iso
	)
)
exit /b

:GENISONAME2
if not "%counter2%"=="1" (
	for /l %%n in (1 1 %counter2%) do (
		if "!Edition!"=="" (
			if /i !EditionID[%%n]!==Core set Edition=CORE
			if /i !EditionID[%%n]!==CoreSingleLanguage set Edition=SINGLELANGUAGE
			if /i !EditionID[%%n]!==CoreCountrySpecific set Edition=CHINA
			if /i !EditionID[%%n]!==Professional set Edition=PRO
			if /i !EditionID[%%n]!==Enterprise set Edition=ENTERPRISE
			if /i !EditionID[%%n]!==Core set Licensing=RET
			if /i !EditionID[%%n]!==CoreSingleLanguage set Licensing=RET
			if /i !EditionID[%%n]!==CoreCountrySpecific set Licensing=RET
			if /i !EditionID[%%n]!==Professional set Licensing=RET
			if /i !EditionID[%%n]!==Enterprise set Licensing=VOL
		) else (
			if /i !EditionID[%%n]!==Core set Edition=!Edition!-CORE
			if /i !EditionID[%%n]!==CoreSingleLanguage set Edition=!Edition!-SINGLELANGUAGE
			if /i !EditionID[%%n]!==CoreCountrySpecific set Edition=!Edition!-CHINA
			if /i !EditionID[%%n]!==Professional set Edition=!Edition!-PRO
			if /i !EditionID[%%n]!==Enterprise set Edition=!Edition!-ENTERPRISE
			if /i !EditionID[%%n]!==Core set Licensing=!Licensing!-RET
			if /i !EditionID[%%n]!==CoreSingleLanguage set Licensing=!Licensing!-RET
			if /i !EditionID[%%n]!==CoreCountrySpecific set Licensing=!Licensing!-RET
			if /i !EditionID[%%n]!==Professional set Licensing=!Licensing!-RET
			if /i !EditionID[%%n]!==Enterprise set Licensing=!Licensing!-VOL
		)
	)
) else (
	if /i %EditionID[1]%==Core set Edition=CORE
	if /i %EditionID[1]%==CoreSingleLanguage set Edition=SINGLELANGUAGE
	if /i %EditionID[1]%==CoreCountrySpecific set Edition=CHINA
	if /i %EditionID[1]%==Professional set Edition=PRO
	if /i %EditionID[1]%==Enterprise set Edition=ENTERPRISE
	if /i !EditionID[1]!==Core set Licensing=RET
	if /i !EditionID[1]!==CoreSingleLanguage set Licensing=RET
	if /i !EditionID[1]!==CoreCountrySpecific set Licensing=RET
	if /i !EditionID[1]!==Professional set Licensing=RET
	if /i !EditionID[1]!==Enterprise set Licensing=VOL
)
if /i %Architecture[1]%==x86_64 set arch=x64
if /i %Architecture[1]%==x86 set arch=x86
set FILENAME=%Build[1]%.%ServicePackBuild[1]%.%CompileDate[1]%.%BuildBranch[1]%_CLIENT!Edition!_!Licensing!_%arch%%BuildType[1]%_%DefaultLanguage[1]%.iso
call :UCase FILENAME DVDISO
exit /b

:GENISONAME3
set LanguageID=!DefaultLanguage[1]!
set lang=!LanguageID:~0,2!
if /i %LanguageID%==en-gb set lang=en-gb
if /i %LanguageID%==es-mx set lang=es-mx
if /i %LanguageID%==fr-ca set lang=fr-ca
if /i %LanguageID%==pt-pt set lang=pp
if /i %LanguageID%==sr-latn-rs set lang=sr-latn
if /i %LanguageID%==zh-cn set lang=cn
if /i %LanguageID%==zh-tw set lang=tw
if /i %LanguageID%==zh-hk set lang=hk
if /i %Architecture[1]%==x86_64 set arch=x64
if /i %Architecture[1]%==x86 set arch=x86
set EditionID=
for /l %%n in (1 1 %counter2%) do (
	if not "!EditionID!"=="" set EditionID=!EditionID!-!EditionID[%%n]!
	if "!EditionID!"=="" set EditionID=!EditionID[%%n]!
)
call :LCase EditionID edition
call :LCase LanguageID Language
call :LCase lang lang
set DVDISO=%lang%_%Build[1]%.%ServicePackBuild[1]%.%CompileDate[1]%_%arch%%BuildType[1]%_%edition%_%Language%_%EditionID%-
if "%edition%"=="enterprise" set DVDISO=%lang%_%Build[1]%.%ServicePackBuild[1]%.%CompileDate[1]%_%arch%!BuildType[1]!_%edition%_%Language%_VL_%EditionID%-
if "%edition%"=="enterprisen" set DVDISO=%lang%_%Build[1]%.%ServicePackBuild[1]%.%CompileDate[1]%_%arch%!BuildType[1]!_%edition%_%Language%_VL_%EditionID%-
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

:Exception <Exception>
Echo.
Echo ESD-Decrypter has stopped working with an Exception.
Echo.
if %~1==MODE (
	Echo The specified Operation Mode is invalid.
	Echo Please correct this error with the help of the help documentation by running :
	Echo.
	Echo %~nx0 /help
)
if %~1==ESD_Not_Found (
	Echo The specified ESD File has not been found on your system.
	Echo Please correct this error.
)
if %~1==Output_Not_Valid (
	Echo The specified Output Directory is invalid.
	Echo Please correct your path to be a valid Windows Batch Path.
)
if %~1==ESD_Decrypt (
	Echo The following Errors were reported during ESD decryption :
	Echo.
	type "%temp%\esddecrypt.log"
)
if %~1==ESD_Damaged Echo The specified ESD File is damaged or not a Valid ESD File.
if %~1==WIMLIB_Notfound Echo %PROCESSOR_ARCHITECTURE% wimlib-imagex.exe not found
if %~1==Apply Echo Critical Errors were found after apply.
if %~1==Export Echo Critical Errors were found after export.
if %~1==ISO Echo Critical Errors were found during ISO creation.
Echo.
goto exit

:exit
:: Clean up tasks here
exit /b

:GetCoords Cols= Lines=
set /A "%1=%ERRORLEVEL%&0xFFFF, %2=(%ERRORLEVEL%>>16)&0xFFFF"
exit /B

:heredoc <uniqueIDX>
setlocal enabledelayedexpansion
set go=
for /f "delims=" %%A in ('findstr /n "^" "%~f0"') do (
    set "line=%%A" && set "line=!line:*:=!"
    if defined go (if #!line:~1!==#!go::=! (goto :EOF) else echo(!line!)
    if "!line:~0,13!"=="call :heredoc" (
        for /f "tokens=3 delims=>^ " %%i in ("!line!") do (
            if #%%i==#%1 (
                for /f "tokens=2 delims=&" %%I in ("!line!") do (
                    for /f "tokens=2" %%x in ("%%I") do set "go=%%x"
                )
            )
        )
    )
)
goto :EOF

:progress
SETLOCAL ENABLEDELAYEDEXPANSION
cursorpos
call :GetCoords Cols Lines
SET ProgressPercent=%1
SET /A NumBars=%ProgressPercent%/2
SET /A NumSpaces=50-%NumBars%
SET Meter=
FOR /L %%A IN (%NumBars%,-1,1) DO SET Meter=!Meter!=
FOR /L %%A IN (%NumSpaces%,-1,1) DO SET Meter=!Meter! 
cursorpos 0 !OLines!
echo Progress:  [%Meter%]
cursorpos 35 !OLines!
echo %ProgressPercent%%%
cursorpos !Cols! !Lines!
ENDLOCAL
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
echo      /Mode:3 ^<ISO^> (*) - Converts a correct Windows ISO to an ESD Image.
echo.
echo      where ISO is the path to the Windows ISO to be converted to ESD
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