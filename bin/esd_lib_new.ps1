#Dependencies: . '.\bin\utils.ps1'

New-Enum iso.filenametype Partner Consumer Windows7
New-Enum wim.extensiontype WIM ESD

function Select-Menu ($displayoptions, $arrayofoptions) {
	Do {
		$counter = 0
        if ($displayoptions.Count -ne 1) {
            foreach ($item in $displayoptions) {
                $counter++
                $padding = ' ' * ((([string]$displayoptions.Length).Length) - (([string]$counter).Length))
                Write-host -ForeGroundColor White ('['+$counter+']'+$padding+' '+$item)
            }
            Write-Host ''
            $choice = read-host -prompt "Select number and press enter"
        } else {
            $counter++
            $choice = 1
        }
	} until ([int]$choice -gt 0 -and [int]$choice -le $counter)
	$choice = $choice - 1
	return $arrayofoptions[$choice]
}

function Get-ScriptDirectory {
    Split-Path -parent $PSCommandPath
}

#Is this a Wow64 powershell host
function Test-Wow64 {
	return (Test-Win32) -and (test-path env:\PROCESSOR_ARCHITEW6432)
}

#Is this a 64 bit process
function Test-Win64 {
	return [IntPtr]::size -eq 8
}

#Is this a 32 bit process
function Test-Win32 {
	return [IntPtr]::size -eq 4
}

if (Test-Wow64) {
	$wimlib = '.\bin\wimlib-imagex.exe'
} elseif (Test-Win64) {
	$wimlib = '.\bin\bin64\wimlib-imagex.exe'
} elseif (Test-Win32) {
	$wimlib = '.\bin\wimlib-imagex.exe'
} else {
	return
}

function Copy-File {
	param(
		[string]$from,
		[string]$to
	)
	$ffile = [io.file]::OpenRead($from)
	$tofile = [io.file]::OpenWrite($to)
	try {
		$sw = [System.Diagnostics.Stopwatch]::StartNew()
		[byte[]]$buff = new-object byte[] (4096*1024)
		[long]$total = [long]$count = 0
		do {
			$count = $ffile.Read($buff, 0, $buff.Length)
			$tofile.Write($buff, 0, $count)
			$total += $count
			[int]$pctcomp = ([int]($total/$ffile.Length* 100))
			[int]$secselapsed = [int]($sw.elapsedmilliseconds.ToString())/1000
			if ($secselapsed -ne 0) {
				[single]$xferrate = (($total/$secselapsed)/1mb)
			} else {
				[single]$xferrate = 0.0
			}
			if ($total % 1mb -eq 0) {
				if($pctcomp -gt 0) {
					[int]$secsleft = ((($secselapsed/$pctcomp)* 100)-$secselapsed)
				} else {
					[int]$secsleft = 0
				}
				if ($pastpct -ne $pctcomp) {
					Write-Progress `
						-Activity ($pctcomp.ToString() + "% Copying file @ " + "{0:n2}" -f $xferrate + " MB/s")`
						-status ($from.Split("\")|select -last 1) `
						-PercentComplete $pctcomp `
						-SecondsRemaining $secsleft;
				}
				$pastpct = $pctcomp
			}
		} while ($count -gt 0)
		$sw.Stop();
		$sw.Reset();
	}
	finally {
		Write-Progress -Activity ($pctcomp.ToString() + "% Copying file @ " + "{0:n2}" -f $xferrate + " MB/s") -Complete
		Write-Host (($from.Split("\")|select -last 1) + `
		" copied in " + $secselapsed + " seconds at " + `
		"{0:n2}" -f [int](($ffile.length/$secselapsed)/1mb) + " MB/s.");
		$ffile.Close();
		$tofile.Close();
	}
}

function Convert-ESDs (
	[parameter(Mandatory=$true)]
	[Boolean] $Backup,
	[ValidateNotNullOrEmpty()]
    [ValidateScript({(Test-Path $_) -and ((Get-Item $_).Extension -eq ".esd")})]
	[parameter(Mandatory=$true)]
	[Array] $ESD,
	[parameter(Mandatory=$false)]
	[Array] $RSAKey
)
{
	[Array]$ESDs = @()
	[Array]$BackedUpESDs = @()
	foreach ($esdfile in $ESD) {
		& $wimlib info "$($esdfile)" > $null
		if ($LASTEXITCODE -eq 74) {
			$tempesd = $esdfile
			if ($Backup) {
				$BackedUpESDs += ($esdfile+'.mod')
				Copy-File $esdfile ($esdfile+'.mod')
				$tempesd = ($esdfile+'.mod')
			}
			$ESDs += $tempesd
			if ($RSAKey -eq $null) {
				& ".\bin\DecryptESD.exe" "-f" "$($tempesd)"
			} else {
				& ".\bin\DecryptESD.exe" "-f" "$($tempesd)" "-k" "$($RSAKey)"
			}
			if ($LASTEXITCODE -ne 0) {
				if ($Backup) {
					foreach ($bakesd in $BackedUpESDs) {
						remove-item $bakesd -force
					}
				}
				return $LASTEXITCODE
			}
		} elseif ($LASTEXITCODE -eq 18) {
			if ($Backup) {
				foreach ($bakesd in $BackedUpESDs) {
					remove-item $bakesd -force
				}
			}
			return 18
		} else {
			$ESDs += $esdfile
		}
	}
	return $ESDs, $BackedUpESDs
}

function New-x64x86Media {
	Copy-Item .\Media\x86\boot\ .\Media\ -recurse
	Copy-Item .\Media\x86\efi\ .\Media\ -recurse
	Copy-Item .\Media\x86\bootmgr .\Media\
	Copy-Item .\Media\x86\bootmgr.efi .\Media\
	Copy-Item .\Media\x86\autorun.inf .\Media\
	Copy-Item .\Media\x86\setup.exe .\Media\
	Copy-Item .\Media\x64\efi\boot\bootx64.efi .\Media\efi\boot\
	$x64guid = bcdedit /store .\Media\boot\bcd /v `
	  | Select-String "path" -Context 2,0 `
	  | % { $_.Context.PreContext[0] -replace '^identifier +' } `
	  | ? { $_ -ne "{default}" }
	bcdedit /store .\Media\boot\bcd /set "{default}" description "Windows 10 Setup (64-bit)"
	bcdedit /store .\Media\boot\bcd /set "{default}" device ramdisk=[boot]\x64\sources\boot.wim,$x64guid
	bcdedit /store .\Media\boot\bcd /set "{default}" osdevice ramdisk=[boot]\x64\sources\boot.wim,$x64guid
	bcdedit /store .\Media\boot\bcd /copy "{default}" /d "Windows 10 Setup (32-bit)"
	$x86guid = bcdedit /store .\Media\boot\bcd /v `
	  | Select-String "path" -Context 2,0 `
	  | % { $_.Context.PreContext[0] -replace '^identifier +' } `
	  | ? { $_ -ne "$x64guid" }
	bcdedit /store .\Media\boot\bcd /set "$($x86guid)" device ramdisk=[boot]\x86\sources\boot.wim,$x64guid
	bcdedit /store .\Media\boot\bcd /set "$($x86guid)" osdevice ramdisk=[boot]\x86\sources\boot.wim,$x64guid
	Remove-item .\Media\boot\bcd.LOG -force
	Remove-item .\Media\boot\bcd.LOG1 -force
	Remove-item .\Media\boot\bcd.LOG2 -force
}

function CleanTM (
	[parameter(Mandatory=$true)]
	$BackedUpESDs
)
{
	if (Test-Path '.\Media\') {
		Remove-Item -recurse .\Media -force
	}
	if ($bakesd -ne $null) {
		foreach ($bakesd in $BackedUpESDs) {
			remove-item $bakesd -force
		}
	}
}

function Get-InfosFromESD (
	[parameter(Mandatory=$true,HelpMessage="The complete path to the ESD file to convert.")]
	[Array] $ESD
)
{
	$esdinformations = @()
	foreach ($esdfile in $ESD) {
		$result = "" | select MajorVersion, MinorVersion, BuildNumber, DeltaVersion, BranchName, CompileDate, Architecture, BuildType, Type, Sku, Editions, Licensing, LanguageCode, VolumeLabel, BuildString, ESDs
		
		$editions = @()
		$counter = 0
		
		$WIMInfo = New-Object System.Collections.ArrayList
		$WIMInfo=@{}
		
		for ($i=1; $i -le 3; $i++){
			$counter++
			$WIMInfo[$counter] = @{}
			$OutputVariable = ( & $wimlib info "$($esdfile)" $i)
			ForEach ($Item in $OutputVariable) {
				$CurrentItem = ($Item -replace '\s+', ' ').split(':')
				$CurrentItemName = $CurrentItem[0] -replace ' ', ''
				if (($CurrentItem[1] -replace ' ', '') -ne '') {
					$WIMInfo[$counter][$CurrentItemName] = $CurrentItem[1].Substring(1)
				}
			}
		}
		
		$header = @{}
		$OutputVariable = ( & $wimlib info "$($esdfile)" --header)
		ForEach ($Item in $OutputVariable) {
			$CurrentItem = ($Item -replace '\s+', ' ').split('=')
			$CurrentItemName = $CurrentItem[0] -replace ' ', ''
			if (($CurrentItem[1] -replace ' ', '') -ne '') {
				$header[$CurrentItemName] = $CurrentItem[1].Substring(1)
			}
		}
			
		for ($i=4; $i -le $header.ImageCount; $i++){
			$counter++
			$WIMInfo[$counter] = @{}
			$OutputVariable = ( & $wimlib info "$($esdfile)" $i)
			ForEach ($Item in $OutputVariable) {
				$CurrentItem = ($Item -replace '\s+', ' ').split(':')
				$CurrentItemName = $CurrentItem[0] -replace ' ', ''
				if (($CurrentItem[1] -replace ' ', '') -ne '') {
					$WIMInfo[$counter][$CurrentItemName] = $CurrentItem[1].Substring(1)
					if ($CurrentItemName -eq 'EditionID') {
						$lastedition = $CurrentItem[1].Substring(1)
						$editions += $CurrentItem[1].Substring(1)
					}
				}
			}
		}
		
		$WIMInfo["header"] = @{}
		$WIMInfo["header"]["ImageCount"] = ($counter.toString())
		
		$result.Editions = $editions
			
		# Converting standards architecture names to friendly ones, if we didn't found any, we put the standard one instead * cough * arm / ia64,
		# Yes, IA64 is still a thing for server these days...
		if ($WIMInfo[4].Architecture -eq 'x86') {
			$result.Architecture = 'x86'
		} elseif ($WIMInfo[4].Architecture -eq 'x86_64') {
			$result.Architecture = 'amd64'
		} else {
			$result.Architecture = $WIMInfo[4].Architecture
		}
			
		# Gathering Compiledate and the buildbranch from the ntoskrnl executable.
		Write-Host 'Checking critical system files for a build string and build type information...'
		& $wimlib extract $esdfile 4 windows\system32\ntkrnlmp.exe windows\system32\ntoskrnl.exe --nullglob --no-acls | out-null
		if (Test-Path .\ntkrnlmp.exe) {
			$result.CompileDate = (Get-item .\ntkrnlmp.exe).VersionInfo.FileVersion.split(' ')[1].split('.')[1].replace(')', '')
			$result.BranchName = (Get-item .\ntkrnlmp.exe).VersionInfo.FileVersion.split(' ')[1].split('.')[0].Substring(1)
			if ((Get-item .\ntkrnlmp.exe).VersionInfo.IsDebug) {
				$result.BuildType = 'chk'
			} else {
				$result.BuildType = 'fre'
			}
			$ProductVersion = (Get-item .\ntkrnlmp.exe).VersionInfo.ProductVersion
			remove-item .\ntkrnlmp.exe -force
		} elseif (Test-Path .\ntoskrnl.exe) {
			$result.CompileDate = (Get-item .\ntoskrnl.exe).VersionInfo.FileVersion.split(' ')[1].split('.')[1].replace(')', '')
			$result.BranchName = (Get-item .\ntoskrnl.exe).VersionInfo.FileVersion.split(' ')[1].split('.')[0].Substring(1)
			if ((Get-item .\ntoskrnl.exe).VersionInfo.IsDebug) {
				$result.BuildType = 'chk'
			} else {
				$result.BuildType = 'fre'
			}
			$ProductVersion = (Get-item .\ntoskrnl.exe).VersionInfo.ProductVersion
			remove-item .\ntoskrnl.exe -force
		}
			
		$result.MajorVersion = $ProductVersion.split('.')[0]
		$result.MinorVersion = $ProductVersion.split('.')[1]
		$result.BuildNumber = $ProductVersion.split('.')[2]
		$result.DeltaVersion = $ProductVersion.split('.')[3]
			
		# Gathering Compiledate and the buildbranch from the build registry.
		Write-Host 'Checking registry for a more accurate build string...'
		& $wimlib extract $esdfile 4 windows\system32\config\ --no-acls | out-null
		& 'reg' load HKLM\RenameISOs .\config\SOFTWARE | out-null
		$output = ( & 'reg' query "HKLM\RenameISOs\Microsoft\Windows NT\CurrentVersion" /v "BuildLab")
		if (($output[2] -ne $null) -and (-not ($output[2].Split(' ')[-1].Split('.')[-1]) -eq '')) {
			$result.CompileDate = $output[2].Split(' ')[-1].Split('.')[-1]
			$result.BranchName = $output[2].Split(' ')[-1].Split('.')[-2]
			$output_ = ( & 'reg' query "HKLM\RenameISOs\Microsoft\Windows NT\CurrentVersion" /v "BuildLabEx")
			if (($output_[2] -ne $null) -and (-not ($output_[2].Split(' ')[-1].Split('.')[-1]) -eq '')) {
				if ($output_[2].Split(' ')[-1] -like '*.*.*.*.*') {
					$result.BuildNumber = $output_[2].Split(' ')[-1].Split('.')[0]
					$result.DeltaVersion = $output_[2].Split(' ')[-1].Split('.')[1]
				}
			}
		} else {
			Write-Host 'Registry check was unsuccessful. Aborting and continuing with critical system files build string...'
		}
		& 'reg' unload HKLM\RenameISOs | out-null
		remove-item .\config\ -recurse -force
			
		# Defining if server or client thanks to Microsoft including 'server' in the server sku names
		if (($WIMInfo.header.ImageCount -gt 4) -and (($WIMInfo[4].EditionID) -eq $null)) {
			$result.Type = 'client'
			$result.Sku = $null
		} elseif (($WIMInfo[4].EditionID) -eq $null) {
			$result.Type = 'client'
			$result.Sku = 'unstaged'
		} elseif (($WIMInfo[4].EditionID.toLower()) -like '*server*') {
			$result.Type = 'server'
			$result.Sku = $WIMInfo[4].EditionID.toLower() -replace 'server', ''
		} else {
			$result.Type = 'client'
			$result.Sku = $WIMInfo[4].EditionID.toLower()
		}
			
		$result.Licensing = 'Retail'
		
		& $wimlib extract $esdfile 1 sources\ei.cfg --nullglob --no-acls | out-null
		if (Test-Path ".\ei.cfg") {
			$content = @()
			Get-Content (".\ei.cfg") | foreach-object -process { 
				$content += $_ 
			}
			$counter = 0
			foreach ($item in $content) {
				$counter++
				if ($item -eq '[EditionID]') {
					$result.Sku = $content[$counter]
				}
			}
			$counter = 0
			foreach ($item in $content) {
				$counter++
				if ($item -eq '[Channel]') {
					$result.Licensing = $content[$counter]
				}
			}
			Remove-Item ".\ei.cfg" -force
		}
			
		if (($WIMInfo.header.ImageCount -eq 7) -and ($result.Type -eq 'server')) {
			$result.Sku = $null
		}
			
		& $wimlib extract $esdfile 1 sources\lang.ini --nullglob --no-acls | out-null
		Get-Content ('lang.ini') | foreach-object -begin {$h=@()} -process { $k = [regex]::split($_,'`r`n'); if(($k[0].CompareTo("") -ne 0)) { $h += $k[0] } }
		$result.LanguageCode = ($h[((0..($h.Count - 1) | Where { $h[$_] -eq '[Available UI Languages]' }) + 1)]).split('=')[0].Trim()
		remove-item lang.ini -force
		
		$tag = 'ir3'
		$DVD = 'DV9'
			
		if ($WIMInfo[4].Architecture -eq 'x86') {
			$arch = 'x86'
		}
		
		if ($WIMInfo[4].Architecture -eq 'x86_64') {
			$arch = 'x64'
		}
		
		if ($WIMInfo[4].ServicePackBuild -eq '17056') {
			$tag = 'ir4'
		}
		if ($WIMInfo[4].ServicePackBuild -eq '17415') {
			$tag = 'ir5'
		}
		if ($WIMInfo[4].ServicePackBuild -gt '17415') {
			$tag = 'ir6'
		}
		
		if ([int] $WIMInfo[4].Build -gt '9600') {
			$tag = 'JM1'
			$DVD = 'DV5'
		}
		if ([int] $WIMInfo[4].Build -ge '9896') {
			$tag = 'J'
			$DVD = 'DV5'
		}
		
		if ($result.Licensing.toLower() -eq 'volume') {
			$ltag = 'FREV_'
		} elseif ($result.Licensing.toLower() -eq 'oem') {
			$ltag = 'FREO_'
		} else {
			$ltag = 'FRE_'
		}
				
		$DVDLabel = ($tag+'_CCSA_'+$arch+$ltag+$WIMInfo[4].DefaultLanguage+'_'+$DVD).ToUpper()
		if ($WIMInfo.header.ImageCount -eq 4) {
			if ($WIMInfo[4].EditionID -eq 'Core') {$DVDLabel = ($tag+'_CCRA_'+$arch+$ltag+$WIMInfo[4].DefaultLanguage+'_'+$DVD).ToUpper()}
			if ($WIMInfo[4].EditionID -eq 'CoreConnected') {$DVDLabel = ($tag+'_CCONA_'+$arch+$ltag+$WIMInfo[4].DefaultLanguage+'_'+$DVD).ToUpper()}
			if ($WIMInfo[4].EditionID -eq 'CoreConnectedCountrySpecific') {$DVDLabel = ($tag+'_CCCHA_'+$arch+$ltag+$WIMInfo[4].DefaultLanguage+'_'+$DVD).ToUpper()}
			if ($WIMInfo[4].EditionID -eq 'CoreConnectedN') {$DVDLabel = ($tag+'_CCONNA_'+$arch+$ltag+$WIMInfo[4].DefaultLanguage+'_'+$DVD).ToUpper()}
			if ($WIMInfo[4].EditionID -eq 'CoreConnectedSingleLanguage') {$DVDLabel = ($tag+'_CCSLA_'+$arch+$ltag+$WIMInfo[4].DefaultLanguage+'_'+$DVD).ToUpper()}
			if ($WIMInfo[4].EditionID -eq 'CoreCountrySpecific') {$DVDLabel = ($tag+'_CCHA_'+$arch+$ltag+$WIMInfo[4].DefaultLanguage+'_'+$DVD).ToUpper()}
			if ($WIMInfo[4].EditionID -eq 'CoreN') {$DVDLabel = ($tag+'_CCRNA_'+$arch+$ltag+$WIMInfo[4].DefaultLanguage+'_'+$DVD).ToUpper()}
			if ($WIMInfo[4].EditionID -eq 'CoreSingleLanguage') {$DVDLabel = ($tag+'_CSLA_'+$arch+$ltag+$WIMInfo[4].DefaultLanguage+'_'+$DVD).ToUpper()}
			if ($WIMInfo[4].EditionID -eq 'Professional') {$DVDLabel = ($tag+'_CPRA_'+$arch+$ltag+$WIMInfo[4].DefaultLanguage+'_'+$DVD).ToUpper()}
			if ($WIMInfo[4].EditionID -eq 'ProfessionalN') {$DVDLabel = ($tag+'_CPRNA_'+$arch+$ltag+$WIMInfo[4].DefaultLanguage+'_'+$DVD).ToUpper()}
			if ($WIMInfo[4].EditionID -eq 'ProfessionalStudent') {$DVDLabel = ($tag+'_CPRSA_'+$arch+$ltag+$WIMInfo[4].DefaultLanguage+'_'+$DVD).ToUpper()}
			if ($WIMInfo[4].EditionID -eq 'ProfessionalStudentN') {$DVDLabel = ($tag+'_CPRSNA_'+$arch+$ltag+$WIMInfo[4].DefaultLanguage+'_'+$DVD).ToUpper()}
			if ($WIMInfo[4].EditionID -eq 'ProfessionalWMC') {$DVDLabel = ($tag+'_CPWMCA_'+$arch+$ltag+$WIMInfo[4].DefaultLanguage+'_'+$DVD).ToUpper()}
			if ($WIMInfo[4].EditionID -eq 'Education') {$DVDLabel = ($tag+'_CEDA_'+$arch+$ltag+$WIMInfo[4].DefaultLanguage+'_'+$DVD).ToUpper()}
			if ($WIMInfo[4].EditionID -eq 'EducationN') {$DVDLabel = ($tag+'_CEDNA_'+$arch+$ltag+$WIMInfo[4].DefaultLanguage+'_'+$DVD).ToUpper()}
			if ($WIMInfo[4].EditionID -eq 'Enterprise') {$DVDLabel = ($tag+'_CENA_'+$arch+$ltag+$WIMInfo[4].DefaultLanguage+'_'+$DVD).ToUpper()}
			if ($WIMInfo[4].EditionID -eq 'EnterpriseN') {$DVDLabel = ($tag+'_CENNA_'+$arch+$ltag+$WIMInfo[4].DefaultLanguage+'_'+$DVD).ToUpper()}
			if ($WIMInfo[4].EditionID -eq 'EnterpriseS') {$DVDLabel = ($tag+'_CES_'+$arch+$ltag+$WIMInfo[4].DefaultLanguage+'_'+$DVD).ToUpper()}
			if ($WIMInfo[4].EditionID -eq 'EnterpriseSN') {$DVDLabel = ($tag+'_CESN_'+$arch+$ltag+$WIMInfo[4].DefaultLanguage+'_'+$DVD).ToUpper()}
			if ($WIMInfo[4].EditionID -eq 'PPIPro') {$DVDLabel = ($tag+'_CPPIA_'+$arch+$ltag+$WIMInfo[4].DefaultLanguage+'_'+$DVD).ToUpper()}
		}
		
		$result.VolumeLabel = $DVDLabel
		$result.BuildString = ($result.MajorVersion+'.'+$result.MinorVersion+'.'+$result.BuildNumber+'.'+$result.DeltaVersion+'.'+$result.BranchName+'.'+$result.CompileDate)
		$result.ESDs = [array]$esdfile
		$esdinformations += $result
	}
	$archs = @()
	($esdinformations | select Architecture).Architecture | % {
		if (-not ($archs -contains $_.toLower())) {
			$archs += $_.toLower()
		}
	}
	$filename = $null
	foreach ($arch in $archs) {
		$currentesds1 = ($esdinformations | Where-Object { $_.architecture.toLower() -eq $arch })
		$buildtypes = @()
		($currentesds1 | select BuildType).BuildType | % {
			if (-not ($buildtypes -contains $_.toLower())) {
				$buildtypes += $_.toLower()
			}
		}
		foreach ($buildtype in $buildtypes) {
			$currentesds2 = ($currentesds1 | Where-Object { $_.buildtype.toLower() -eq $buildtype })
			$builds = @()
			($currentesds2 | select BuildString).BuildString | % {
				if (-not ($builds -contains $_.toLower())) {
					$builds += $_.toLower()
				}
			}
			foreach ($build in $builds) {
				$currentesds3 = ($currentesds2 | Where-Object {$_.BuildString.toLower() -eq $build })
				$languages = @()
				($currentesds3 | select LanguageCode).LanguageCode | % {
					if (-not ($languages -contains $_.toLower())) {
						$languages += $_.toLower()
					}
				}
				foreach ($language in $languages) {
					$currentesds4 = ($currentesds3 | Where-Object {$_.LanguageCode -eq $language })
					$Edition = $null
					$Licensing = $null
					($currentesds4 | select Editions).Editions | % {
						if ($_ -is [System.Array]) {
							foreach ($item in $_) {
								if ($Edition -eq $null) {
									$Edition_ = $item
									if ($item -eq 'Core') {$Edition_ = 'CORE'}
									if ($item -eq 'CoreN') {$Edition_ = 'COREN'}
									if ($item -eq 'CoreSingleLanguage') {$Edition_ = 'SINGLELANGUAGE'}
									if ($item -eq 'CoreCountrySpecific') {$Edition_ = 'CHINA'}
									if ($item -eq 'Professional') {$Edition_ = 'PRO'}
									if ($item -eq 'ProfessionalN') {$Edition_ = 'PRON'}
									if ($item -eq 'ProfessionalWMC') {$Edition_ = 'PROWMC'}
									if ($item -eq 'CoreConnected') {$Edition_ = 'CORECONNECTED'}
									if ($item -eq 'CoreConnectedN') {$Edition_ = 'CORECONNECTEDN'}
									if ($item -eq 'CoreConnectedSingleLanguage') {$Edition_ = 'CORECONNECTEDSINGLELANGUAGE'}
									if ($item -eq 'CoreConnectedCountrySpecific') {$Edition_ = 'CORECONNECTEDCHINA'}
									if ($item -eq 'ProfessionalStudent') {$Edition_ = 'PROSTUDENT'}
									if ($item -eq 'ProfessionalStudentN') {$Edition_ = 'PROSTUDENTN'}
									if ($item -eq 'Enterprise') {$Edition_ = 'ENTERPRISE'}
									$Edition = $Edition_
								} else {
									$Edition_ = $item_
									if ($item -eq 'Core') {$Edition_ = 'CORE'}
									if ($item -eq 'CoreN') {$Edition_ = 'COREN'}
									if ($item -eq 'CoreSingleLanguage') {$Edition_ = 'SINGLELANGUAGE'}
									if ($item -eq 'CoreCountrySpecific') {$Edition_ = 'CHINA'}
									if ($item -eq 'Professional') {$Edition_ = 'PRO'}
									if ($item -eq 'ProfessionalN') {$Edition_ = 'PRON'}
									if ($item -eq 'ProfessionalWMC') {$Edition_ = 'PROWMC'}
									if ($item -eq 'CoreConnected') {$Edition_ = 'CORECONNECTED'}
									if ($item -eq 'CoreConnectedN') {$Edition_ = 'CORECONNECTEDN'}
									if ($item -eq 'CoreConnectedSingleLanguage') {$Edition_ = 'CORECONNECTEDSINGLELANGUAGE'}
									if ($item -eq 'CoreConnectedCountrySpecific') {$Edition_ = 'CORECONNECTEDCHINA'}
									if ($item -eq 'ProfessionalStudent') {$Edition_ = 'PROSTUDENT'}
									if ($item -eq 'ProfessionalStudentN') {$Edition_ = 'PROSTUDENTN'}
									if ($item -eq 'Enterprise') {$Edition_ = 'ENTERPRISE'}
									$Edition = $Edition+'-'+$Edition_
								}
							}
						} else {
							if ($Edition -eq $null) {
								$Edition_ = $_
								if ($_ -eq 'Core') {$Edition_ = 'CORE'}
								if ($_ -eq 'CoreN') {$Edition_ = 'COREN'}
								if ($_ -eq 'CoreSingleLanguage') {$Edition_ = 'SINGLELANGUAGE'}
								if ($_ -eq 'CoreCountrySpecific') {$Edition_ = 'CHINA'}
								if ($_ -eq 'Professional') {$Edition_ = 'PRO'}
								if ($_ -eq 'ProfessionalN') {$Edition_ = 'PRON'}
								if ($_ -eq 'ProfessionalWMC') {$Edition_ = 'PROWMC'}
								if ($_ -eq 'CoreConnected') {$Edition_ = 'CORECONNECTED'}
								if ($_ -eq 'CoreConnectedN') {$Edition_ = 'CORECONNECTEDN'}
								if ($_ -eq 'CoreConnectedSingleLanguage') {$Edition_ = 'CORECONNECTEDSINGLELANGUAGE'}
								if ($_ -eq 'CoreConnectedCountrySpecific') {$Edition_ = 'CORECONNECTEDCHINA'}
								if ($_ -eq 'ProfessionalStudent') {$Edition_ = 'PROSTUDENT'}
								if ($_ -eq 'ProfessionalStudentN') {$Edition_ = 'PROSTUDENTN'}
								if ($_ -eq 'Enterprise') {$Edition_ = 'ENTERPRISE'}
								$Edition = $Edition_
							} else {
								$Edition_ = $_
								if ($_ -eq 'Core') {$Edition_ = 'CORE'}
								if ($_ -eq 'CoreN') {$Edition_ = 'COREN'}
								if ($_ -eq 'CoreSingleLanguage') {$Edition_ = 'SINGLELANGUAGE'}
								if ($_ -eq 'CoreCountrySpecific') {$Edition_ = 'CHINA'}
								if ($_ -eq 'Professional') {$Edition_ = 'PRO'}
								if ($_ -eq 'ProfessionalN') {$Edition_ = 'PRON'}
								if ($_ -eq 'ProfessionalWMC') {$Edition_ = 'PROWMC'}
								if ($_ -eq 'CoreConnected') {$Edition_ = 'CORECONNECTED'}
								if ($_ -eq 'CoreConnectedN') {$Edition_ = 'CORECONNECTEDN'}
								if ($_ -eq 'CoreConnectedSingleLanguage') {$Edition_ = 'CORECONNECTEDSINGLELANGUAGE'}
								if ($_ -eq 'CoreConnectedCountrySpecific') {$Edition_ = 'CORECONNECTEDCHINA'}
								if ($_ -eq 'ProfessionalStudent') {$Edition_ = 'PROSTUDENT'}
								if ($_ -eq 'ProfessionalStudentN') {$Edition_ = 'PROSTUDENTN'}
								if ($_ -eq 'Enterprise') {$Edition_ = 'ENTERPRISE'}
								$Edition = $Edition+'-'+$Edition_
							}
						}
					}
					($currentesds4 | select Licensing).Licensing | % {
						if ($Licensing -eq $null) {
							$Licensing = $_
						} else {
							if (-not ($Licensing -contains $_)) {
								$Licensing = $Licensing+$_
							}
						}
					}
					$Edition = $Edition.toUpper() -replace 'SERVERHYPER', 'SERVERHYPERCORE' -replace 'SERVER', ''
					$Licensing = $Licensing.toUpper() -replace 'VOLUME', 'VOL' -replace 'RETAIL', 'RET'
					if ($Edition -eq 'PRO-CORE') {
						$Licensing = 'OEMRET'
					}
					if ($Edition.toLower() -eq 'unstaged') {
						$Edition = ''
					}
					$arch_ = $arch -replace 'amd64', 'x64'
					if ($currentesds4 -is [System.Array]) {
						$FILENAME_ = ($currentesds4[0].BuildNumber+'.'+$currentesds4[0].DeltaVersion+'.'+$currentesds4[0].CompileDate+'.'+$currentesds4[0].BranchName)
					} else {
						$FILENAME_ = ($currentesds4.BuildNumber+'.'+$currentesds4.DeltaVersion+'.'+$currentesds4.CompileDate+'.'+$currentesds4.BranchName)
					}
					$FILENAME_ = ($FILENAME_+'_CLIENT'+$Edition+'_'+$Licensing+'_'+$arch_+$buildtype+'_'+$language).toUpper()
					if ($filename -eq $null) {
						$filename = $FILENAME_
					} else {
						$filename = $filename+'-'+$FILENAME_
					}
					$parts += 1
				}
			}
		}
	}
	
	$tag = 'ir3'
	$DVD = 'DV9'				
	if ($esdinformations[0].Architecture -eq 'x86') {
		$arch = 'x86'
	}			
	if ($esdinformations[0].Architecture -eq 'x86_64') {
		$arch = 'x64'
	}			
	if ([int] $esdinformations[0].DeltaVersion -eq '17056') {
		$tag = 'ir4'
	}
	if ([int] $esdinformations[0].DeltaVersion -eq '17415') {
		$tag = 'ir5'
	}
	if ([int] $esdinformations[0].DeltaVersion -gt '17415') {
		$tag = 'ir6'
	}			
	if ([int] $esdinformations[0].BuildNumber -gt '9600') {
		$tag = 'JM1'
		$DVD = 'DV5'
	}
	if ([int] $esdinformations[0].BuildNumber -ge '9896') {
		$tag = 'J'
		$DVD = 'DV5'
	}
	if ($esdinformations[0].Licensing.toLower() -eq 'volume') {
		$ltag = 'FREV_'
	} elseif ($esdinformations[0].Licensing.toLower() -eq 'oem') {
		$ltag = 'FREO_'
	} else {
		$ltag = 'FRE_'
	}
	
	$filename = ($filename+'.ISO').toUpper()
	
	if ($esdinformations.count -eq 1) {
		$DVDLabel = $esdinformations[0].VolumeLabel
	} elseif ($esdinformations.count -eq 2 -and $esdinformations[0].Editions -eq "Professional" -and $esdinformations[1].Editions -eq "Core" -and $parts -eq 1) {
		$DVDLabel = ($tag+'_CCSA_'+$arch+$ltag+$esdinformations[0].LanguageCode+'_'+$DVD).ToUpper()
	} else {
		$DVDLabel = "ESD-ISO"
	}
	
	Write-Host Filename: $filename
	Write-Host Volume Label: $DVDLabel
	
	return $filename, $DVDLabel, $esdinformations
}
	
function prepforconvert (
	[ValidateNotNullOrEmpty()]
    [ValidateScript({(Test-Path $_) -and ((Get-Item $_).Extension -eq ".esd")})]
	[parameter(Mandatory=$true,HelpMessage="The complete path to the ESD file to convert.")]
	[Array] $esdfiles,
	[parameter(Mandatory=$false,HelpMessage="The crypto key that will be used to decrypt the ESD file.")]
	$CryptoKey
)
{

		if ($CryptoKey -ne $null) {
			$result = (Convert-ESDs -Backup $true -ESD $esdfiles -RSAKey $CryptoKey)
		} else {
			$result = (Convert-ESDs -Backup $true -ESD $esdfiles)
		}
		[array]$esdinfos = @()
		if ($result -is [system.array]) {
			$results = Get-InfosFromESD -ESD $result[0]
			$esdinfos = $results[2]
			$volumelabel = $results[1]
			$filename = $results[0]
		}
		return $result, $esdinfos, $filename, $volumelabel
}

function Convert-ESD (
	[ValidateNotNullOrEmpty()]
    [ValidateScript({(Test-Path $_) -and ((Get-Item $_).Extension -eq ".esd")})]
	[parameter(Mandatory=$true,HelpMessage="The complete path to the ESD file to convert.")]
	[Array] $esdfiles,
	[ValidateNotNullOrEmpty()]
	[parameter(Mandatory=$true,HelpMessage="The place where the final ISO file will be stored")]
	[System.IO.DirectoryInfo] $Destination,
	[ValidateNotNullOrEmpty()]
	[parameter(Mandatory=$false,HelpMessage="The crypto key that will be used to decrypt the ESD file.")]
	$CryptoKey,
	[parameter(Mandatory=$true,HelpMessage="The type of extension used for the Windows Image (WIM or ESD)")]
	[wim.extensiontype] $extensiontype
)
{
	$Results = prepforconvert -ESDFiles $esdfiles -CryptoKey $CryptoKey
    $filename = $Results[2]
    $label = $Results[3]
	$result = $Results[0]
	[array]$esdinfos = $Results[1]
	if ($result -is [System.Array]) {
	
	} elseif ($result -eq 18) {
		#NotOriginal
		CleanTM($result[1])
		return
	} else {
		#Damaged
		CleanTM($result[1])
		return
	}
	$items = @{}
	$archs = @()
	foreach ($architecture in $esdinfos.Architecture) {
		$items[$architecture] = @{}
		$items[$architecture]["SetupESDs"] = @()
		foreach ($esd in ($esdinfos | ? {$_.Architecture -eq $architecture})) {
			$items[$architecture]["SetupESDs"] += $esd | ? { -not (($items.$architecture.SetupESDs | ? {$_.LanguageCode -eq $esd.LanguageCode}).BuildString -contains $esd.BuildString) }
		}
		$items[$architecture]["WinREESDs"] = @()
		foreach ($esd in ($esdinfos | ? {$_.Architecture -eq $architecture})) {
			$items[$architecture]["WinREESDs"] += $esd | ? { -not (($items.$architecture.WinREESDs | ? {$_.LanguageCode -eq $esd.LanguageCode}).BuildString -contains $esd.BuildString) }
		}
		$items[$architecture]["InstallESDs"] = @()
		$items[$architecture]["InstallESDs"] += ($esdinfos | ? {$_.Architecture -eq $architecture})
		$archs += $architecture | ? { -not ($archs -contains $architecture) }
	}
	if ($items.Count -gt 1) {
		function SelectESD($Global:var) {
            
            $choicesx86 = @()
            foreach ($item in $Global:var[0]) {
				$displayitem = [string]($item.BuildString+' - '+$item.Architecture+$item.BuildType+' - '+$item.LanguageCode)
				$choicesx86 += $displayitem
			}
            $peitemsx86 = $Global:var[0]
            Write-host "
Select your i386 Windows Preinstallation environement source
============================================================
            "
            $Global:WinPEESD_x86 = (Select-Menu $choicesx86 $peitemsx86)
            $reitemsx86 = $GLobal:var[0]
            Write-host "
Select your i386 Windows Recovery environement source
=====================================================
            "
            $Global:WinREESD_x86 = (Select-Menu $choicesx86 $reitemsx86)
            
            $choicesx64 = @()
            foreach ($item in $Global:var[1]) {
				$displayitem = [string]($item.BuildString+' - '+$item.Architecture+$item.BuildType+' - '+$item.LanguageCode)
				$choicesx64 += $displayitem
			}
            $peitemsx64 = $Global:var[1]
            Write-host "
Select your amd64 Windows Preinstallation environement source
=============================================================
            "
            $Global:WinPEESD_x64 = (Select-Menu $choicesx64 $peitemsx64)
            $reitemsx64 = $GLobal:var[1]
            Write-host "
Select your amd64 Windows Recovery environement source
======================================================
            "
            $Global:WinREESD_x64 = (Select-Menu $choicesx64 $reitemsx64)
			
			return $Global:WinPEESD_x86, $Global:WinREESD_x86, $Global:WinPEESD_x64, $Global:WinREESD_x64
		}
		#2 archs
		foreach ($architecture in $archs) {
			if ($architecture -eq 'amd64') {
				$global:builds_x64 = @()
				if ($items.$architecture.SetupESDs -is [system.array]) {
					#more than 1 choice for setup
					foreach ($item in $items.$architecture.SetupESDs) {
						[array]$global:builds_x64 += $item
					}
				} else {
					$item = $items.$architecture.SetupESDs
					[array]$global:builds_x64 += $item
				}
			} else {
				$global:builds_x86 = @()
				if ($items.$architecture.SetupESDs -is [system.array]) {
					#more than 1 choice for setup
					foreach ($item in $items.$architecture.SetupESDs) {
						[array]$global:builds_x86 += $item
					}
				} else {
					$item = $items.$architecture.SetupESDs
					[array]$global:builds_x86 += $item
				}
			}
		}
		$Results = SelectESD($global:builds_x86, $global:builds_x64)
		$items["x86"]["WinREESD"] = @()
		$items["x86"]["WinREESD"] = $Results[0]
		$items["x86"]["SetupESD"] = $Results[1]
		$items["amd64"]["WinREESD"] = @()
		$items["amd64"]["WinREESD"] = $Results[0]
		$items["amd64"]["SetupESD"] = $Results[1]
		$items.x86.WinREESD.ESDs[0]
		$items.x86.SetupESD.ESDs[0]
		$items.amd64.WinREESD.ESDs[0]
		$items.amd64.SetupESD.ESDs[0]
		function New-ISO (
			$archs,
			$items,
			$clean,
			$extensiontype,
			$isoname,
			$label
		)
		{
			Begin {
				function Export-InstallWIM (
						[parameter(Mandatory=$true)]
						[ValidateScript({(Test-Path $_)})]
						[Array] $ESD,
						[parameter(Mandatory=$true)]
						[Int] $Index,
						[parameter(Mandatory=$true)]
						[ValidateScript({(Test-Path $_\)})]
						[String] $Output,
						[parameter(Mandatory=$true)]
						[String] $ExtensionType
					)
					{
						$operationname = $null
						$sw = [System.Diagnostics.Stopwatch]::StartNew();
						if ($extensiontype -eq 'ESD') {
							$indexcount = 1
							if (Test-Path $Output\sources\install.esd) {
								$header = @{}
								$OutputVariable = (& $wimlib info "$($Output)\sources\install.esd" --header)
								ForEach ($Item in $OutputVariable) {
									$CurrentItem = ($Item -replace '\s+', ' ').split('=')
									$CurrentItemName = $CurrentItem[0] -replace ' ', ''
									if (($CurrentItem[1] -replace ' ', '') -ne '') {
										$header[$CurrentItemName] = $CurrentItem[1].Substring(1)
									}
								}
								$indexcount = $header.ImageCount + 1
							}
							& $wimlib export "$($esdfile)" $Index $Output\sources\install.esd --compress=LZMS --solid | ForEach-Object -Process {
								if ($operationname -eq $null) {
									$operationname = $_
								}
								$global:lastprogress = $progress
								$global:progress = [regex]::match($_,'\(([^\)]+)\%').Groups[1].Value
								if ($progress -match "[0-9]") {
									$total = $_.split(' ')[0]
									$totalsize = $_.split(' ')[3]
									[long]$pctcomp = ([long]($total/$totalsize* 100));
									[long]$secselapsed = [long]($sw.elapsedmilliseconds.ToString())/1000;
									if ($pctcomp -ne 0) {
										[long]$secsleft = ((($secselapsed/$pctcomp)* 100)-$secselapsed)
									} else {
										[long]$secsleft = 0
									}
									#Write-host Exporting to install.esd... $progress% - $operationname - Time remaining: $secsleft - $_
                                    Write-Progress -Activity ('Exporting Windows Installation...') -status ($operationname) -PercentComplete ($progress) -SecondsRemaining $secsleft -CurrentOperation $_
									if ($lastprogress -ne $progress) {
										#Update-Window ConvertProgress Value $progress
									}
								}
								if ($WIMInfo.$indexcounter.EditionID -eq 'ProfessionalWMC') {
									cmd /c ($wimlib + ' update "$($Output)\sources\install.esd" $($indexcount) <bin\wim-update.txt')
								}
							}
						} else {
							$indexcount = 1
							if (Test-Path $Output\sources\install.wim) {
								$header = @{}
								$OutputVariable = (& $wimlib info "$($Output)\sources\install.wim" --header)
								ForEach ($Item in $OutputVariable) {
									$CurrentItem = ($Item -replace '\s+', ' ').split('=')
									$CurrentItemName = $CurrentItem[0] -replace ' ', ''
									if (($CurrentItem[1] -replace ' ', '') -ne '') {
										$header[$CurrentItemName] = $CurrentItem[1].Substring(1)
									}
								}
								$indexcount = $header.ImageCount + 1
							}
							& $wimlib export "$($esdfile)" $Index $Output\sources\install.wim --compress=maximum | ForEach-Object -Process {
								if ($operationname -eq $null) {
									$operationname = $_
								}
								$global:lastprogress = $progress
								$global:progress = [regex]::match($_,'\(([^\)]+)\%').Groups[1].Value
								if ($progress -match "[0-9]") {
									$total = $_.split(' ')[0]
									$totalsize = $_.split(' ')[3]
									[long]$pctcomp = ([long]($total/$totalsize* 100));
									[long]$secselapsed = [long]($sw.elapsedmilliseconds.ToString())/1000;
									if ($pctcomp -ne 0) {
										[long]$secsleft = ((($secselapsed/$pctcomp)* 100)-$secselapsed)
									} else {
										[long]$secsleft = 0
									}
									#Write-host Exporting to install.wim... $progress% - $operationname - Time remaining: $secsleft - $_
                                    Write-Progress -Activity ('Exporting Windows Installation...') -status ($operationname) -PercentComplete ($progress) -SecondsRemaining $secsleft -CurrentOperation $_
									if ($lastprogress -ne $progress) {
										#Update-Window ConvertProgress Value $progress
									}
								}
								if ($WIMInfo.$indexcounter.EditionID -eq 'ProfessionalWMC') {
									cmd /c ($wimlib + ' update "$($Output)\sources\install.wim" $($indexcount) <bin\wim-update.txt')
								}
							}
						}
					}
				function New-SetupMedia (
					[parameter(Mandatory=$true)]
					[ValidateScript({(Test-Path $_)})]
					[String] $SetupESD,
					[parameter(Mandatory=$true)]
					[ValidateScript({(Test-Path $_)})]
					[String] $WinREESD,
					[parameter(Mandatory=$true)]
					[ValidateScript({(Test-Path $_\)})]
					[String] $Output
				) {
					if (Test-Path $Output\sources\boot.wim) {
						return 1
					}
					Write-Host "Expanding Setup files - In Progress"
                    $name = $null
					& $wimlib apply "$($SetupESD)" 1 $Output | ForEach-Object -Process {
                        if ($name -eq $null) {
                            $name = $_
                        }
                        $progress = [regex]::match($_,'\(([^\)]+)\%').Groups[1].Value
                        if ($progress -match "[0-9]") {
                            Write-Progress -Activity ('Expanding Setup files...') -status ($name) -PercentComplete $progress -CurrentOperation $_
                        }
                    }
                    Write-Progress -Activity ('Expanding Setup files...') -Complete
					Remove-Item $Output\MediaMeta.xml
					Write-Host "Expanding Setup files - Done"
					Write-Host "Exporting Windows Recovery environement - In Progress"
					$sw = [System.Diagnostics.Stopwatch]::StartNew();
					$operationname = $null
					& $wimlib export "$($WinREESD)" 2 $Output\sources\boot.wim --compress=maximum | ForEach-Object -Process {
						if ($operationname -eq $null) {
							$operationname = $_
						}
						$global:lastprogress = $progress
						$global:progress = [regex]::match($_,'\(([^\)]+)\%').Groups[1].Value
						if ($global:progress -match "[0-9]") {
							$total = $_.split(' ')[0]
							$totalsize = $_.split(' ')[3]
							[long]$pctcomp = ([long]($total/$totalsize* 100));
							[long]$secselapsed = [long]($sw.elapsedmilliseconds.ToString())/1000;
							if ($pctcomp -ne 0) {
								[long]$secsleft = ((($secselapsed/$pctcomp)* 100)-$secselapsed)
							} else {
								[long]$secsleft = 0
							}
                            Write-Progress -Activity ('Exporting Windows Recovery environement...') -status ($operationname) -PercentComplete ($global:progress) -SecondsRemaining $secsleft -CurrentOperation $_
							#Write-host Creating Windows Recovery environement... $progress% - $operationname - Time remaining: $secsleft - $_
							if ($lastprogress -ne $progress) {
								#Update-Window ConvertProgress Value $progress
							}
						}
					}
					$sw.Stop();
					$sw.Reset();
					Write-Host "Exporting Windows Recovery environement - Done"
                    Write-Progress -Activity ('Exporting Windows Recovery environement...') -Complete
					Write-Host "Exporting Windows Preinstallation environement - In Progress"
					$sw = [System.Diagnostics.Stopwatch]::StartNew();
					$operationname = $null
					& $wimlib export "$($SetupESD)" 3 $Output\sources\boot.wim --boot | ForEach-Object -Process {
						if ($operationname -eq $null) {
							$operationname = $_
						}
						$global:lastprogress = $progress
						$global:progress = [regex]::match($_,'\(([^\)]+)\%').Groups[1].Value
						if ($global:progress -match "[0-9]") {
							$total = $_.split(' ')[0]
							$totalsize = $_.split(' ')[3]
							[long]$pctcomp = ([long]($total/$totalsize* 100));
							[long]$secselapsed = [long]($sw.elapsedmilliseconds.ToString())/1000;
							if ($pctcomp -ne 0) {
								[long]$secsleft = ((($secselapsed/$pctcomp)* 100)-$secselapsed)
							} else {
								[long]$secsleft = 0
							}
							#Write-host Creating Windows PE Setup... $progress% - $operationname - Time remaining: $secsleft - $_
                            Write-Progress -Activity ('Exporting Windows Preinstallation environement...') -status ($operationname) -PercentComplete ($global:progress) -SecondsRemaining $secsleft -CurrentOperation $_
							if ($lastprogress -ne $progress) {
								#Update-Window ConvertProgress Value $progress
							}
						}
					}
					$sw.Stop();
					$sw.Reset();
					Write-Host "Exporting Windows Preinstallation environement - Done"
                    Write-Progress -Activity ('Exporting Windows Preinstallation environement...') -Complete
				}
			}
			Process {
				mkdir .\Media\ | Out-Null
				foreach ($architecture in $archs) {
					if ($architecture -eq 'amd64') {
						$arch = "x64"
					} else {
						$arch = "x86"
					}
					Write-Host WinREESD: $items.$architecture.WinREESD.ESDs[0]
					Write-Host SetupESD: $items.$architecture.SetupESD.ESDs[0]
					mkdir .\Media\$arch\ | Out-Null
					New-SetupMedia -SetupESD $items.$architecture.SetupESD.ESDs[0] -WinREESD $items.$architecture.WinREESD.ESDs[0] -Output .\Media\$arch\
					Write-Host "Exporting Windows Installation - In Progress"
					foreach ($esd in $items.$architecture.InstallESDs) {
						$esdfile = $esd.ESDs[0]
						Write-Host $esdfile
						$header = @{}
						$OutputVariable = (& $wimlib info "$($esdfile)" --header)
						ForEach ($Item in $OutputVariable) {
							$CurrentItem = ($Item -replace '\s+', ' ').split('=')
							$CurrentItemName = $CurrentItem[0] -replace ' ', ''
							if (($CurrentItem[1] -replace ' ', '') -ne '') {
								$header[$CurrentItemName] = $CurrentItem[1].Substring(1)
							}
						}
						for ($i=4; $i -le $header.ImageCount; $i++) {
							Write-Host Index: $i
							Export-InstallWIM -ESD $esdfile -Index $i -Output .\Media\$arch\ -ExtensionType $extensiontype
						}
					}
				}
				Write-Host "Exporting Windows Installation - Done"
                Write-Progress -Activity ('Exporting Windows Installation...') -Complete
			    Write-Host "Creating ISO File - In Progress"
				New-x64x86Media
				Write-Host 'Gathering Timestamp information from the Setup Media...'
				$timestamp = (Get-ChildItem .\Media\setup.exe | % {[System.TimeZoneInfo]::ConvertTimeToUtc($_.creationtime).ToString("MM/dd/yyyy,HH:mm:ss")})
				Write-Host 'Generating ISO...'
				$BootData='2#p0,e,bMedia\boot\etfsboot.com#pEF,e,bMedia\efi\Microsoft\boot\efisys.bin'
				& "cmd" "/c" ".\bin\cdimage.exe" "-bootdata:$BootData" "-o" "-h" "-m" "-u2" "-udfver102" "-t$timestamp" "-l$($label)" ".\Media" """$($Destination)\$($isoname)"""
                Write-Host "Creating ISO File - Done"
				CleanTM($clean)
			}
		}
		New-ISO -Items $items -Archs $archs -Clean $result[1] -extensiontype $extensiontype -isoname $filename -label $label
	} else {
		function SelectSingleESD($Global:var) {
            $choices = @()
            foreach ($item in $Global:var) {
				$displayitem = [string]($item.BuildString+' - '+$item.Architecture+$item.BuildType+' - '+$item.LanguageCode)
				$choices += $displayitem
			}
            $peitems = $Global:var
            Write-host "
Select your Windows Preinstallation environement source
=======================================================
            "
            $Global:WinPEESD = (Select-Menu $choices $peitems)
            $reitems = $GLobal:var
            Write-host "
Select your Windows Recovery environement source
================================================
            "
            $Global:WinREESD = (Select-Menu $choices $reitems)
            
            return $Global:WinPEESD, $Global:WinREESD
		}
		#1 arch
		$global:builds = @()
		foreach ($architecture in $archs) {
			if ($items.$architecture.SetupESDs -is [system.array]) {
				#more than 1 choice for setup
				foreach ($item in $items.$architecture.SetupESDs) {
					[array]$global:builds += $item
				}
			} else {
				$item = $items.$architecture.SetupESDs
				[array]$global:builds += $item
			}
			$Results = SelectSingleESD($global:builds)
			$SetupESD = $Results[0]
			$WinREESD = $Results[1]
			Write-Host SetupESD: $SetupESD.ESDs
			Write-Host WinREESD: $WinREESD.ESDs
			function Convert-ISO (
				$SetupESD,
				$WinREESD,
				$clean,
				$extensiontype,
				$isoname,
				$label
			)
			{
				Begin {
					function Export-InstallWIM (
						[parameter(Mandatory=$true)]
						[ValidateScript({(Test-Path $_)})]
						[Array] $ESD,
						[parameter(Mandatory=$true)]
						[Int] $Index,
						[parameter(Mandatory=$true)]
						[ValidateScript({(Test-Path $_\)})]
						[String] $Output,
						[parameter(Mandatory=$true)]
						[String] $ExtensionType
					)
					{
						$operationname = $null
						$sw = [System.Diagnostics.Stopwatch]::StartNew();
						if ($extensiontype -eq 'ESD') {
							$indexcount = 1
							if (Test-Path $Output\sources\install.esd) {
								$header = @{}
								$OutputVariable = (& $wimlib info "$($Output)\sources\install.esd" --header)
								ForEach ($Item in $OutputVariable) {
									$CurrentItem = ($Item -replace '\s+', ' ').split('=')
									$CurrentItemName = $CurrentItem[0] -replace ' ', ''
									if (($CurrentItem[1] -replace ' ', '') -ne '') {
										$header[$CurrentItemName] = $CurrentItem[1].Substring(1)
									}
								}
								$indexcount = $header.ImageCount + 1
							}
							& $wimlib export "$($esdfile)" $Index $Output\sources\install.esd --compress=LZMS --solid | ForEach-Object -Process {
								if ($operationname -eq $null) {
									$operationname = $_
								}
								$global:lastprogress = $progress
								$global:progress = [regex]::match($_,'\(([^\)]+)\%').Groups[1].Value
								if ($progress -match "[0-9]") {
									$total = $_.split(' ')[0]
									$totalsize = $_.split(' ')[3]
									[long]$pctcomp = ([long]($total/$totalsize* 100));
									[long]$secselapsed = [long]($sw.elapsedmilliseconds.ToString())/1000;
									if ($pctcomp -ne 0) {
										[long]$secsleft = ((($secselapsed/$pctcomp)* 100)-$secselapsed)
									} else {
										[long]$secsleft = 0
									}
									#Write-host Exporting to install.esd... $progress% - $operationname - Time remaining: $secsleft - $_
                                    Write-Progress -Activity ('Exporting Windows Installation...') -status ($operationname) -PercentComplete ($progress) -SecondsRemaining $secsleft -CurrentOperation $_
									if ($lastprogress -ne $progress) {
										#Update-Window ConvertProgress Value $progress
									}
								}
								if ($WIMInfo.$indexcounter.EditionID -eq 'ProfessionalWMC') {
									cmd /c ($wimlib + ' update "$($Output)\sources\install.esd" $($indexcount) <bin\wim-update.txt')
								}
							}
						} else {
							$indexcount = 1
							if (Test-Path $Output\sources\install.wim) {
								$header = @{}
								$OutputVariable = (& $wimlib info "$($Output)\sources\install.wim" --header)
								ForEach ($Item in $OutputVariable) {
									$CurrentItem = ($Item -replace '\s+', ' ').split('=')
									$CurrentItemName = $CurrentItem[0] -replace ' ', ''
									if (($CurrentItem[1] -replace ' ', '') -ne '') {
										$header[$CurrentItemName] = $CurrentItem[1].Substring(1)
									}
								}
								$indexcount = $header.ImageCount + 1
							}
							& $wimlib export "$($esdfile)" $Index $Output\sources\install.wim --compress=maximum | ForEach-Object -Process {
								if ($operationname -eq $null) {
									$operationname = $_
								}
								$global:lastprogress = $progress
								$global:progress = [regex]::match($_,'\(([^\)]+)\%').Groups[1].Value
								if ($progress -match "[0-9]") {
									$total = $_.split(' ')[0]
									$totalsize = $_.split(' ')[3]
									[long]$pctcomp = ([long]($total/$totalsize* 100));
									[long]$secselapsed = [long]($sw.elapsedmilliseconds.ToString())/1000;
									if ($pctcomp -ne 0) {
										[long]$secsleft = ((($secselapsed/$pctcomp)* 100)-$secselapsed)
									} else {
										[long]$secsleft = 0
									}
									#Write-host Exporting to install.wim... $progress% - $operationname - Time remaining: $secsleft - $_
                                    Write-Progress -Activity ('Exporting Windows Installation...') -status ($operationname) -PercentComplete ($progress) -SecondsRemaining $secsleft -CurrentOperation $_
									if ($lastprogress -ne $progress) {
										#Update-Window ConvertProgress Value $progress
									}
								}
								if ($WIMInfo.$indexcounter.EditionID -eq 'ProfessionalWMC') {
									cmd /c ($wimlib + ' update "$($Output)\sources\install.wim" $($indexcount) <bin\wim-update.txt')
								}
							}
						}
					}
					function New-SetupMedia (
						[parameter(Mandatory=$true)]
						[ValidateScript({(Test-Path $_)})]
						[String] $SetupESD,
						[parameter(Mandatory=$true)]
						[ValidateScript({(Test-Path $_)})]
						[String] $WinREESD,
						[parameter(Mandatory=$true)]
						[ValidateScript({(Test-Path $_\)})]
						[String] $Output
					) {
						if (Test-Path $Output\sources\boot.wim) {
							return 1
						}
						Write-Host "Expanding Setup files - In Progress"
						$name = $null
                        & $wimlib apply "$($SetupESD)" 1 $Output | ForEach-Object -Process {
                            if ($name -eq $null) {
                                $name = $_
                            }
                            $progress = [regex]::match($_,'\(([^\)]+)\%').Groups[1].Value
                            if ($progress -match "[0-9]") {
                                Write-Progress -Activity ('Expanding Setup files...') -status ($name) -PercentComplete $progress -CurrentOperation $_
                            }
                        }
                        Write-Progress -Activity ('Expanding Setup files...') -Complete
						Remove-Item $Output\MediaMeta.xml
						Write-Host "Expanding Setup files - Done"
						Write-Host "Exporting Windows Recovery environement - In Progress"
						$sw = [System.Diagnostics.Stopwatch]::StartNew();
						$operationname = $null
						& $wimlib export "$($WinREESD)" 2 $Output\sources\boot.wim --compress=maximum | ForEach-Object -Process {
							if ($operationname -eq $null) {
								$operationname = $_
							}
							$global:lastprogress = $progress
							$global:progress = [regex]::match($_,'\(([^\)]+)\%').Groups[1].Value
							if ($global:progress -match "[0-9]") {
								$total = $_.split(' ')[0]
								$totalsize = $_.split(' ')[3]
								[long]$pctcomp = ([long]($total/$totalsize* 100));
								[long]$secselapsed = [long]($sw.elapsedmilliseconds.ToString())/1000;
								if ($pctcomp -ne 0) {
									[long]$secsleft = ((($secselapsed/$pctcomp)* 100)-$secselapsed)
								} else {
									[long]$secsleft = 0
								}
								#Write-host Creating Windows Recovery environement... $progress% - $operationname - Time remaining: $secsleft - $_
                                Write-Progress -Activity ('Exporting Windows Recovery environement...') -status ($operationname) -PercentComplete ($global:progress) -SecondsRemaining $secsleft -CurrentOperation $_
								if ($lastprogress -ne $progress) {
									#Update-Window ConvertProgress Value $progress
								}
							}
						}
						$sw.Stop();
						$sw.Reset();
						Write-Host "Exporting Windows Recovery environement - Done"
                        Write-Progress -Activity ('Exporting Windows Recovery environement...') -Complete
						Write-Host "Exporting Windows Preinstallation environement - In Progress"
						$sw = [System.Diagnostics.Stopwatch]::StartNew();
						$operationname = $null
						& $wimlib export "$($SetupESD)" 3 $Output\sources\boot.wim --boot | ForEach-Object -Process {
							if ($operationname -eq $null) {
								$operationname = $_
							}
							$global:lastprogress = $progress
							$global:progress = [regex]::match($_,'\(([^\)]+)\%').Groups[1].Value
							if ($global:progress -match "[0-9]") {
								$total = $_.split(' ')[0]
								$totalsize = $_.split(' ')[3]
								[long]$pctcomp = ([long]($total/$totalsize* 100));
								[long]$secselapsed = [long]($sw.elapsedmilliseconds.ToString())/1000;
								if ($pctcomp -ne 0) {
									[long]$secsleft = ((($secselapsed/$pctcomp)* 100)-$secselapsed)
								} else {
									[long]$secsleft = 0
								}
								#Write-host Creating Windows PE Setup... $progress% - $operationname - Time remaining: $secsleft - $_
                                Write-Progress -Activity ('Exporting Windows Preinstallation environement...') -status ($operationname) -PercentComplete ($global:progress) -SecondsRemaining $secsleft -CurrentOperation $_
								if ($lastprogress -ne $progress) {
									#Update-Window ConvertProgress Value $progress
								}
							}
						}
						$sw.Stop();
						$sw.Reset();
						Write-Host "Exporting Windows Preinstallation environement - Done"
                        Write-Progress -Activity ('Exporting Windows Preinstallation environement...') -Complete
					}
				}
				Process {
					mkdir .\Media\ | Out-Null
					New-SetupMedia -SetupESD $SetupESD.ESDs[0] -WinREESD $WinREESD.ESDs[0] -Output .\Media\
					Write-Host "Exporting Windows Installation - In Progress"
					foreach ($esd in $items.$architecture.InstallESDs) {
						$esdfile = $esd.ESDs[0]
						Write-Host $esdfile
						$header = @{}
						$OutputVariable = (& $wimlib info "$($esdfile)" --header)
						ForEach ($Item in $OutputVariable) {
							$CurrentItem = ($Item -replace '\s+', ' ').split('=')
							$CurrentItemName = $CurrentItem[0] -replace ' ', ''
							if (($CurrentItem[1] -replace ' ', '') -ne '') {
								$header[$CurrentItemName] = $CurrentItem[1].Substring(1)
							}
						}
						for ($i=4; $i -le $header.ImageCount; $i++) {
							Write-Host Index: $i
							Export-InstallWIM -ESD $esdfile -Index $i -Output .\Media\ -ExtensionType $extensiontype
						}
					}
					Write-Host "Exporting Windows Installation - Done"
                    Write-Progress -Activity ('Exporting Windows Installation...') -Complete
					Write-Host "Creating ISO File - In Progress"
					Write-Host 'Gathering Timestamp information from the Setup Media...'
					$timestamp = (Get-ChildItem .\Media\setup.exe | % {[System.TimeZoneInfo]::ConvertTimeToUtc($_.creationtime).ToString("MM/dd/yyyy,HH:mm:ss")})
					Write-Host 'Generating ISO...'
					$BootData='2#p0,e,bMedia\boot\etfsboot.com#pEF,e,bMedia\efi\Microsoft\boot\efisys.bin'
					& "cmd" "/c" ".\bin\cdimage.exe" "-bootdata:$BootData" "-o" "-h" "-m" "-u2" "-udfver102" "-t$timestamp" "-l$($label)" ".\Media" """$($Destination)\$($isoname)"""
                    Write-Host "Creating ISO File - Done"
					CleanTM($clean)
				}
			}
			Convert-ISO -SetupESD $SetupESD -WinREESD $WinREESD -Clean $result[1] -extensiontype $extensiontype -isoname $filename -label $label
		}
	}
}

function New-Wizard-Decrypt() {

	$Title = "What type of Image format do you want for the ISO file ?"
	
	$message = "ESD Decrypter needs to know in which format the Windows Installation Image should be. Please choose one option below."

	$WIM = New-Object System.Management.Automation.Host.ChoiceDescription "&WIM Format", `
	    "This is the most used Windows Image format. If you want to recreate an original ISO, please choose this option."
	
	$ESD = New-Object System.Management.Automation.Host.ChoiceDescription "&ESD Format", `
	    "This format is not commonly used by MS but it provides the best compression available for storing Windows Images."
	
	$options = [System.Management.Automation.Host.ChoiceDescription[]]($WIM, $ESD)
	
	$result = $host.ui.PromptForChoice($title, $message, $options, 0) 
	
	switch ($result)
  	{
		0 {$extensiontype = ([wim.extensiontype] "WIM")}
		1 {$extensiontype = ([wim.extensiontype] "ESD")}
    }
	
	#$Title = "What type of filename do you want for your ISO file ?"
	
	#$message = "ESD Decrypter needs to know which type of filename your final iso will have (according to your preferences)."

	#$CONSUMER = New-Object System.Management.Automation.Host.ChoiceDescription "&Consumer Format", `
	#    "Example: Windows10_SingleLanguage_InsiderPreview_x32_EN-US_10074.iso"
	
	#$PARTNER = New-Object System.Management.Automation.Host.ChoiceDescription "&Partner/Internal Format", `
	#    "Example: 10074.0.150424-1350.FBL_IMPRESSIVE_CLIENTSINGLELANGUAGE_RET_X86FRE_EN-US.ISO"
	
	#$W7 = New-Object System.Management.Automation.Host.ChoiceDescription "&Windows 7 and earlier Format", `
	#    "Example: en_10074.0.150424-1350_x86fre_singlelanguage_en-us_CoreSingleLanguage-J_CSLA_X86FRER_EN-US_DV5.iso"
		
	#$options = [System.Management.Automation.Host.ChoiceDescription[]]($CONSUMER, $PARTNER, $W7)
	
	#$result = $host.ui.PromptForChoice($title, $message, $options, 0) 
	
	#switch ($result)
  	#{
	#	0 {$scheme = 0}
	#	1 {$scheme = 1}
	#	2 {$scheme = 2}
    #}
	
	$Title = "Do you want to use a custom Cryptographic key ?"
	
	$message = "You can specify a custom Crypto Key if the embedded ones can't decrypt your esd file."

	$NO = New-Object System.Management.Automation.Host.ChoiceDescription "&No", `
	    "No, continue with the included Crypto keys."
	
	$YES = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", `
	    "Yes, I want to specify a custom key, but I'll try to decrypt the esd file with your custom key and the embedded ones."
		
	$options = [System.Management.Automation.Host.ChoiceDescription[]]($NO, $YES)
	
	$result = $host.ui.PromptForChoice($title, $message, $options, 0) 
	
	switch ($result)
  	{
		0 {$CustomKey = $false}
		1 {$CustomKey = $true}
    }
	if ($CustomKey -eq $true) {
		$key = Read-Host 'Please enter a complete Cryptographic Key'
	}
	
	$Title = "Do you want to use a custom Destination Path ?"
	
	$message = "You can specify a custom Destination Path for your ISO file."

	$NO = New-Object System.Management.Automation.Host.ChoiceDescription "&No", `
	    "No, place the ISO file in the current folder."
	
	$YES = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", `
	    "Yes, I want to specify a custom destination path."
		
	$options = [System.Management.Automation.Host.ChoiceDescription[]]($NO, $YES)
	
	$result = $host.ui.PromptForChoice($title, $message, $options, 0) 
	
	switch ($result)
  	{
		0 {$CustomPath = '.'}
		1 {$CustomPath = Read-Host 'Please enter a custom destination path'}
    }
	
	foreach ($item in (get-item *.esd)) {
		if ($esdnames -eq $null) {
			$esdnames = @()
			$esdpaths = @()
		}
		$esdnames += $item.Name
		$esdpaths += $item.FullName
	}
	
	if ($esdnames -ne $null) {
		$esdnames += 'None of these (You will be prompt for one or multiple esd files path names later)'
		$esdpaths += 'None'
		Write-Host '
Please Select which ESD you want to Convert
===========================================
'
		$selected = Menu-Select $esdnames $esdpaths
		
		if ($selected -eq 'None') {
			Write-Host
			Write-Host -ForeGroundColor Yellow "You will be asked for ESD[...], you will need to enter a full esd file path, you will be asked again for ESD[...], if you want to combine multiple esd files, enter another full esd file path, otherwise press [ENTER] on your keyboard."
			if ($CustomKey -eq $true) {
				Convert-ESD -CryptoKey $key -extensiontype $extensiontype -Destination $CustomPath
			} else {
                Convert-ESD -extensiontype $extensiontype -Destination $CustomPath
			}
		} else {
			if ($CustomKey -eq $true) {
				Convert-ESD -CryptoKey $key -extensiontype $extensiontype -Destination $CustomPath -esdfiles $selected
			} else {
				Convert-ESD -extensiontype $extensiontype -Destination $CustomPath -esdfiles $selected
			}
		}
	} else {
		Write-Host
		Write-Host -ForeGroundColor Yellow "You will be asked for ESD[...], you will need to enter a full esd file path, you will be asked again for ESD[...], if you want to combine multiple esd files, enter another full esd file path, otherwise press [ENTER] on your keyboard."
		if ($CustomKey -eq $true) {
			Convert-ESD -CryptoKey $key -extensiontype $extensiontype -Destination $CustomPath
		} else {
			Convert-ESD -extensiontype $extensiontype -Destination $CustomPath
		}
	}
}

if ($ESD -ne $null) {
	if ($CryptoKey -eq $null) {
		Convert-ESD -esdfiles $ESD -Destination $Destination -extensiontype $extensiontype
	} else {
		Convert-ESD -esdfiles $ESD -Destination $Destination -extensiontype $extensiontype -CryptoKey $CryptoKey
	}
	return
}

New-Wizard-Decrypt