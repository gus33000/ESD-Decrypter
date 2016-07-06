# Workaround, because of Powershell bug present in old builds.
function Write-Host ($message,$nonewline,$backgroundcolor,$foregroundcolor) { $Message | Out-Host }

New-Enum iso.filenametype Universal Partner Consumer Windows7

if (-not (Get-Command Mount-DiskImage -ErrorAction SilentlyContinue))
{
  Write-Host '
	Sorry, but your system does not have the ability to mount ISO files.
	This is maybe because you are running an older version of Windows than 6.2
	
	Error: Cannot find Mount-DiskImage
	'
  return
}

function get-i386infos ($letter,$type,$label) {

  $result = "" | select MajorVersion,MinorVersion,BuildNumber,DeltaVersion,BranchName,CompileDate,Tag,Architecture,BuildType,Type,Sku,Editions,Licensing,LanguageCode,VolumeLabel

  $result.VolumeLabel = $label

  # Gathering Compiledate and the buildbranch from the main setup.exe executable.
  $NoExtended = $false

  if (Test-Path ($letter + '\' + $type + '\ntoskrnl.ex_')) {
    & 'bin\7z' e $letter\$type\ntoskrnl.ex_ *.exe -r | Out-Null
    if (((Get-Item .\ntoskrnl.exe).VersionInfo.FileVersion) -like '*built by:*') {
      $result.CompileDate = (Get-Item .\ntoskrnl.exe).VersionInfo.FileVersion.split(':')[-1].replace(' ','')
      $result.BranchName = (Get-Item .\ntoskrnl.exe).VersionInfo.FileVersion.split(':')[-2].replace(' at','').replace(' ','')
    } elseif (((Get-Item .\ntoskrnl.exe).VersionInfo.FileVersion) -like '*.*.*.*(*)*') {
      $result.CompileDate = (Get-Item .\ntoskrnl.exe).VersionInfo.FileVersion.split(' ')[1].split('.')[1].replace(')','')
      $result.BranchName = (Get-Item .\ntoskrnl.exe).VersionInfo.FileVersion.split(' ')[1].split('.')[0].Substring(1)
    } else {
      $NoExtended = $true
    }

    if ((Get-Item .\ntoskrnl.exe).VersionInfo.IsDebug) {
      $result.BuildType = 'chk'
    } else {
      $result.BuildType = 'fre'
    }
    $result.Architecture = (Test-Arch '.\ntoskrnl.exe').FileType

    if ($NoExtended) {
      $buildno = (Get-Item .\ntoskrnl.exe).VersionInfo.FileVersion
    } else {
      $buildno = (Get-Item .\ntoskrnl.exe).VersionInfo.ProductVersion
    }

    if (-not ($buildno -like '*.*.*.*')) {
      & 'bin\7z' e .\ntoskrnl.exe .rsrc\version.txt | Out-Null
      $buildno = Remove-InvalidFileNameChars (Get-Content '.\version.txt' -First 1).split(' ')[-1].replace(',','.')
      Remove-Item '.\version.txt' -Force
    }

    Remove-Item '.\ntoskrnl.exe' -Force
  } elseif (Test-Path ($letter + '\' + $type + '\ntoskrnl.exe')) {
    if (((Get-Item $letter\$type\ntoskrnl.exe).VersionInfo.FileVersion) -like '*built by:*') {
      $result.CompileDate = (Get-Item $letter\$type\ntoskrnl.exe).VersionInfo.FileVersion.split(':')[-1].replace(' ','')
      $result.BranchName = (Get-Item $letter\$type\ntoskrnl.exe).VersionInfo.FileVersion.split(':')[-2].replace(' at','').replace(' ','')
    } elseif (((Get-Item $letter\$type\ntoskrnl.exe).VersionInfo.FileVersion) -like '*.*.*.*(*)*') {
      $result.CompileDate = (Get-Item $letter\$type\ntoskrnl.exe).VersionInfo.FileVersion.split(' ')[1].split('.')[1].replace(')','')
      $result.BranchName = (Get-Item $letter\$type\ntoskrnl.exe).VersionInfo.FileVersion.split(' ')[1].split('.')[0].Substring(1)
    } else {
      $NoExtended = $true
    }

    if ((Get-Item $letter\$type\ntoskrnl.exe).VersionInfo.IsDebug) {
      $result.BuildType = 'chk'
    } else {
      $result.BuildType = 'fre'
    }
    $result.Architecture = (Test-Arch ($letter + '\' + $type + '\NTKRNLMP.EXE')).FileType

    if ($NoExtended) {
      $buildno = (Get-Item $letter\$type\ntoskrnl.exe).VersionInfo.FileVersion
    } else {
      $buildno = (Get-Item $letter\$type\ntoskrnl.exe).VersionInfo.ProductVersion
    }

    if (-not ($buildno -like '*.*.*.*')) {
      & 'bin\7z' e $letter\$type\ntoskrnl.exe .rsrc\version.txt | Out-Null
      $buildno = Remove-InvalidFileNameChars (Get-Content '.\version.txt' -First 1).split(' ')[-1].replace(',','.')
      Remove-Item '.\version.txt' -Force
    }
  } elseif (Test-Path ($letter + '\' + $type + '\NTKRNLMP.EX_')) {
    & 'bin\7z' e $letter\$type\NTKRNLMP.EX_ *.exe -r | Out-Null
    if (((Get-Item .\NTKRNLMP.exe).VersionInfo.FileVersion) -like '*built by:*') {
      $result.CompileDate = (Get-Item .\NTKRNLMP.EXE).VersionInfo.FileVersion.split(':')[-1].replace(' ','')
      $result.BranchName = (Get-Item .\NTKRNLMP.EXE).VersionInfo.FileVersion.split(':')[-2].replace(' at','').replace(' ','')
    } elseif (((Get-Item .\NTKRNLMP.exe).VersionInfo.FileVersion) -like '*.*.*.*(*)*') {
      $result.CompileDate = (Get-Item .\NTKRNLMP.EXE).VersionInfo.FileVersion.split(' ')[1].split('.')[1].replace(')','')
      $result.BranchName = (Get-Item .\NTKRNLMP.EXE).VersionInfo.FileVersion.split(' ')[1].split('.')[0].Substring(1)
    } else {
      $NoExtended = $true
    }

    if ((Get-Item .\NTKRNLMP.EXE).VersionInfo.IsDebug) {
      $result.BuildType = 'chk'
    } else {
      $result.BuildType = 'fre'
    }
    $result.Architecture = (Test-Arch '.\NTKRNLMP.EXE').FileType

    if ($NoExtended) {
      $buildno = (Get-Item .\NTKRNLMP.EXE).VersionInfo.FileVersion
    } else {
      $buildno = (Get-Item .\NTKRNLMP.EXE).VersionInfo.ProductVersion
    }

    if (-not ($buildno -like '*.*.*.*')) {
      & 'bin\7z' e .\NTKRNLMP.EXE .rsrc\version.txt | Out-Null
      $buildno = Remove-InvalidFileNameChars (Get-Content '.\version.txt' -First 1).split(' ')[-1].replace(',','.')
      Remove-Item '.\version.txt' -Force
    }

    Remove-Item '.\NTKRNLMP.EXE' -Force
  } else {
    if (((Get-Item $letter\$type\NTKRNLMP.EXE).VersionInfo.FileVersion) -like '*built by:*') {
      $result.CompileDate = (Get-Item $letter\$type\NTKRNLMP.EXE).VersionInfo.FileVersion.split(':')[-1].replace(' ','')
      $result.BranchName = (Get-Item $letter\$type\NTKRNLMP.EXE).VersionInfo.FileVersion.split(':')[-2].replace(' at','').replace(' ','')
    } elseif (((Get-Item $letter\$type\NTKRNLMP.EXE).VersionInfo.FileVersion) -like '*.*.*.*(*)*') {
      $result.CompileDate = (Get-Item $letter\$type\NTKRNLMP.EXE).VersionInfo.FileVersion.split(' ')[1].split('.')[1].replace(')','')
      $result.BranchName = (Get-Item $letter\$type\NTKRNLMP.EXE).VersionInfo.FileVersion.split(' ')[1].split('.')[0].Substring(1)
    } else {
      $NoExtended = $true
    }

    if ((Get-Item $letter\$type\NTKRNLMP.EXE).VersionInfo.IsDebug) {
      $result.BuildType = 'chk'
    } else {
      $result.BuildType = 'fre'
    }
    $result.Architecture = (Test-Arch ($letter + '\' + $type + '\NTKRNLMP.EXE')).FileType
    if ($type.toLower() -eq 'alpha') {
      $result.Architecture = 'AXP'
    }

    if ($NoExtended) {
      $buildno = (Get-Item $letter\$type\NTKRNLMP.EXE).VersionInfo.FileVersion
    } else {
      $buildno = (Get-Item $letter\$type\NTKRNLMP.EXE).VersionInfo.ProductVersion
    }

    if (-not ($buildno -like '*.*.*.*')) {
      & 'bin\7z' e $letter\$type\NTKRNLMP.EXE .rsrc\version.txt | Out-Null
      $buildno = Remove-InvalidFileNameChars (Get-Content '.\version.txt' -First 1).split(' ')[-1].replace(',','.')
      Remove-Item '.\version.txt' -Force
    }
  }

  $result.MajorVersion = $buildno.split('.')[0]
  $result.MinorVersion = $buildno.split('.')[1]
  $result.BuildNumber = $buildno.split('.')[2]
  $result.DeltaVersion = $buildno.split('.')[3]

  $cdtag = (get-inicontent $letter\$type\txtsetup.sif)["SourceDisksNames"]["_x"].split(',')[1]
  if ($cdtag -eq '%cdtagfile%') {
    $editionletter = (get-inicontent $letter\$type\txtsetup.sif)["Strings"]["cdtagfile"].toLower().replace('"','')
  } else {
    $editionletter = $cdtag.toLower().replace('"','')
  }

  $editionletter = $editionletter.replace('cdrom.','')
  $editionletter_ = $editionletter.split('.')[0][-2]
  $editionletter = $editionletter.split('.')[0][-1]

  if ($editionletter -eq 'p') {
    $result.Sku = 'Professional'
    $result.Type = 'client'
  } elseif ($editionletter -eq 'c') {
    $result.Sku = 'Home'
    $result.Type = 'client'
  } elseif ($editionletter -eq 'w') {
    $result.Sku = 'Workstation'
    $result.Type = 'client'
  } elseif ($editionletter -eq 'b') {
    $result.Sku = 'Web'
    $result.Type = 'server'
  } elseif ($editionletter -eq 's') {
    $result.Sku = 'Standard'
    if ($editionletter_ -eq 't') {
      $result.Sku = 'Terminal'
    }
    $result.Type = 'server'
  } elseif ($editionletter -eq 'a') {
    if ($buildno.split('.')[2] -le 2202) {
      $result.Sku = 'Advanced'
    } else {
      $result.Sku = 'Enterprise'
    }
    $result.Type = 'server'
  } elseif ($editionletter -eq 'l') {
    $result.Sku = 'Smallbusiness'
    $result.Type = 'server'
  } elseif ($editionletter -eq 'd') {
    $result.Sku = 'Datacenter'
    $result.Type = 'server'
  } else {
    $result.Sku = $editionletter
    $result.Type = 'unknown'
  }

  $result.Editions = $result.Sku

  $langid = '0x' + (get-inicontent $letter\$type\TXTSETUP.SIF)["nls"]["DefaultLayout"]

  $langid = $langid.replace('E001','')

  $result.LanguageCode = [System.Globalization.Cultureinfo]::GetCultureInfo([int32]$langid).Name

  Write-Host "Dismounting $($isofile)..."
  Get-DiskImage -ImagePath $isofile.fullname | Dismount-DiskImage

  $result.Licensing = 'Retail'

  return $result
}

function ISO-identify ($isofile) {

  $langcodes = @{}
  [globalization.cultureinfo]::GetCultures("allCultures") | select name,DisplayName | ForEach-Object {
    $langcodes[$_.DisplayName] = $_.Name
  }
  $langcodes['Spanish (Spain, Traditional Sort)'] = 'es-ES_tradnl'
  $langcodes['Chinese (Simplified, China)'] = 'zh-CHS'
  $langcodes['Norwegian Bokm�l (Norway)'] = 'nb-NO'

  $result = "" | select MajorVersion,MinorVersion,BuildNumber,DeltaVersion,BranchName,CompileDate,Tag,Architecture,BuildType,Type,Sku,Editions,Licensing,LanguageCode,VolumeLabel,BuildString,SetupPath

  # We mount the ISO File
  Write-Host "Mounting $($isofile)..."
  Mount-DiskImage -ImagePath $isofile.fullname

  # We get the mounted drive letter
  $letter = (Get-DiskImage -ImagePath $isofile.fullname | Get-Volume).driveletter + ":"
  $result.VolumeLabel = (Get-DiskImage -ImagePath $isofile.fullname | Get-Volume).FileSystemLabel

  Write-Host "Mounted $($isofile) as drive $($letter)"

  if ((Test-Path ($letter + "\sources\install.wim")) -and (Test-Path ($letter + "\sources\lang.ini")) -and (Test-Path ($letter + "\sources\boot.wim"))) {

    $WIM = $letter + "\sources\install.wim"
	
	# Gathering all infos we can find from install wim to $WIMInfo including the WIM Header
		# This portion of code comes from gus33000's ESDDecrypter Beta.
		# The required notice is displayed below :
		
		# Based on the script by abbodi1406
		# ESD Toolkit - July Tech Preview 2015 - Copyright 2015 (c) gus33000 - Version 3.0
		# For testing purposes only. Build 3.0.10112.0.amd64fre.fbl_release(gus33000).150718-1031
		$WIMInfo = New-Object System.Collections.ArrayList
		$WIMInfo=@{}
		$WIMInfo['header'] = @{}
		$editions = @()
		$OutputVariable = ( & $wimlib info "$($letter)\sources\install.wim" --header)
		ForEach ($isofile_ in $OutputVariable) {
			$CurrentItem = ($isofile_ -replace '\s+', ' ').split('=')
			$CurrentItemName = $CurrentItem[0] -replace ' ', ''
			if (($CurrentItem[1] -replace ' ', '') -ne '') {
				$WIMInfo['header'][$CurrentItemName] = $CurrentItem[1].Substring(1)
			}
		}
		for ($i=1; $i -le $WIMInfo.header.ImageCount; $i++){
			$WIMInfo[$i] = @{}
			$OutputVariable = ( & $wimlib info "$($letter)\sources\install.wim" $i)
			ForEach ($isofile_ in $OutputVariable) {
				$CurrentItem = ($isofile_ -replace '\s+', ' ').split(':')
				$CurrentItemName = $CurrentItem[0] -replace ' ', ''
				if (($CurrentItem[1] -replace ' ', '') -ne '') {
					$WIMInfo[$i][$CurrentItemName] = $CurrentItem[1].Substring(1)
					if ($CurrentItemName -eq 'EditionID') {
						$lastedition = $CurrentItem[1].Substring(1)
						$editions += $CurrentItem[1].Substring(1)
					}
				}
			}
		}
		
		if ($lastedition -eq $null) {
			for ($i=1; $i -le $WIMInfo.header.ImageCount; $i++){
				$OutputVariable = ( & $wimlib info "$($letter)\sources\install.wim" $i)
				ForEach ($isofile_ in $OutputVariable) {
					$CurrentItem = ($isofile_ -replace '\s+', ' ').split(':')
					$CurrentItemName = $CurrentItem[0] -replace ' ', ''
					if (($CurrentItem[1] -replace ' ', '') -ne '') {
						if ($CurrentItemName -eq 'Flags') {
						if ($CurrentItem[1].Substring(1) -ne "Windows Foundation") {
							$WIMInfo[$i]["EditionID"] = $CurrentItem[1].Substring(1)
								$lastedition = $CurrentItem[1].Substring(1)
								$editions += $CurrentItem[1].Substring(1)
							}
						}
					}
				}
			}
		}
		
		$result.Editions = $editions

    # Converting standards architecture names to friendly ones, if we didn't found any, we put the standard one instead * cough * arm / ia64,
    # Yes, IA64 is still a thing for server these days...
    if ($WIMInfo[1].Architecture -eq 'x86') {
      $result.Architecture = 'x86'
    } elseif ($WIMInfo[1].Architecture -eq 'x86_64') {
      $result.Architecture = 'amd64'
    } else {
      $result.Architecture = $WIMInfo[1].Architecture
    }

    # Gathering Compiledate and the buildbranch from the ntoskrnl executable.
    Write-Host 'Checking critical system files for a build string and build type information...'
    & $wimlib extract $WIM 1 windows\system32\ntkrnlmp.exe windows\system32\ntoskrnl.exe --nullglob --no-acls | Out-Null
    if (Test-Path .\ntkrnlmp.exe) {
      $result.CompileDate = (Get-Item .\ntkrnlmp.exe).VersionInfo.FileVersion.split(' ')[1].split('.')[1].replace(')','')
      $result.BranchName = (Get-Item .\ntkrnlmp.exe).VersionInfo.FileVersion.split(' ')[1].split('.')[0].Substring(1)
      if ((Get-Item .\ntkrnlmp.exe).VersionInfo.IsDebug) {
        $result.BuildType = 'chk'
      } else {
        $result.BuildType = 'fre'
      }
      $ProductVersion = (Get-Item .\ntkrnlmp.exe).VersionInfo.ProductVersion
      Remove-Item .\ntkrnlmp.exe -Force
    } elseif (Test-Path .\ntoskrnl.exe) {
      $result.CompileDate = (Get-Item .\ntoskrnl.exe).VersionInfo.FileVersion.split(' ')[1].split('.')[1].replace(')','')
      $result.BranchName = (Get-Item .\ntoskrnl.exe).VersionInfo.FileVersion.split(' ')[1].split('.')[0].Substring(1)
      if ((Get-Item .\ntoskrnl.exe).VersionInfo.IsDebug) {
        $result.BuildType = 'chk'
      } else {
        $result.BuildType = 'fre'
      }
      $ProductVersion = (Get-Item .\ntoskrnl.exe).VersionInfo.ProductVersion
      Remove-Item .\ntoskrnl.exe -Force
    }

    $result.MajorVersion = $ProductVersion.split('.')[0]
    $result.MinorVersion = $ProductVersion.split('.')[1]
    $result.BuildNumber = $ProductVersion.split('.')[2]
    $result.DeltaVersion = $ProductVersion.split('.')[3]

    $result.Licensing = 'Retail'

    # Gathering Compiledate and the buildbranch from the build registry.
    Write-Host 'Checking registry for a more accurate build string and licensing information...'
    & $wimlib extract $WIM 1 windows\system32\config\ --no-acls | Out-Null
    & 'reg' load HKLM\RenameISOs .\config\SOFTWARE | Out-Null
    $output = (& 'reg' query "HKLM\RenameISOs\Microsoft\Windows NT\CurrentVersion" /v "BuildLab")
    if (($output[2] -ne $null) -and (-not ($output[2].split(' ')[-1].split('.')[-1]) -eq '')) {
      $result.CompileDate = $output[2].split(' ')[-1].split('.')[-1]
      $result.BranchName = $output[2].split(' ')[-1].split('.')[-2]
      $output_ = (& 'reg' query "HKLM\RenameISOs\Microsoft\Windows NT\CurrentVersion" /v "BuildLabEx")
      if (($output_[2] -ne $null) -and (-not ($output_[2].split(' ')[-1].split('.')[-1]) -eq '')) {
        if ($output_[2].split(' ')[-1] -like '*.*.*.*.*') {
          $result.BuildNumber = $output_[2].split(' ')[-1].split('.')[0]
          $result.DeltaVersion = $output_[2].split(' ')[-1].split('.')[1]
        }
      }
    } else {
      Write-Host 'Registry check for buildstring was unsuccessful. Aborting and continuing with critical system files build string...'
    }
    $output = (& 'reg' query "HKLM\RenameISOs\Microsoft\Windows NT\CurrentVersion\DefaultProductKey" /v "ProductId")
	if ($output -ne $null) {
		if ($output[2] -ne $null) {
		  $var = $output[2].split(' ')[-1].Substring($output[2].split(' ')[-1].Length - 3,3)
		  if ($var.toUpper() -eq "OEM") {
			$result.Licensing = "oem"
		  }
		}
	}
    
    & 'reg' unload HKLM\RenameISOs | Out-Null
    Remove-Item .\config\ -Recurse -Force

	
	
    # Defining if server or client thanks to Microsoft including 'server' in the server sku names
    if (($WIMInfo[1].EditionID) -eq $null) {
      $result.Type = 'client'
      $result.Sku = 'unstaged'
    } elseif (($WIMInfo[1].EditionID.toLower()) -like '*server*') {
      $result.Type = 'server'
      $result.Sku = $WIMInfo[1].EditionID.toLower() -replace 'server',''
    } else {
      $result.Type = 'client'
      $result.Sku = $WIMInfo[1].EditionID.toLower()
    }
	
	if ($WIMInfo.header.ImageCount -gt 1) {
		if ($WIMInfo[1].EditionID -eq $null) {
		  $result.Type = 'client'
		  $result.Sku = 'unstaged'
		} elseif (($WIMInfo[1].EditionID.toLower()) -like '*server*') {
		  $result.Type = 'server'
		  $result.Sku = $null
		} else {
		  $result.Type = 'client'
		  $result.Sku = $null
		}
	}
	
	if ($result.Sku -eq "unstaged") {
		$server = $false
		$client = $false
		
		$skus = @()
		
		$unstagedskus = (& 'bin\7z' l -i!packages\*sku*\Security-Licensing-SLC-Component-SKU*pl*xrm* $letter\sources\install.wim) | % { if ($_ -like '*Security-Licensing-SLC-Component-SKU*pl*xrm*') { $_.split(' \')[-2].split('-')[-1].split('_')[0] } } | Select -uniq
		if (($unstagedskus -ne $null) -and ($unstagedskus -ne "")) {
				foreach ($sku in $unstagedskus) {
					if ($sku -like '*server*') {
						$server = $true
					} else {
						$client = $true
					}
					$skus+=$sku
				}
				
				$result.Editions = $skus
				
				if ($client) {
					$result.Type = 'client'
					if ($server) {
						$result.Type = 'client-server'
					}
				} elseif ($server) {
					$result.Type = 'server'
				}
		} else {
			$unstagedskus = (& 'bin\7z' l -i!packages\*\update* $letter\sources\install.wim) | % { if ($_ -like '*update.mum*') { $_.split(' \')[-2] } }
			if (($unstagedskus -ne $null) -and ($unstagedskus -ne "")) {
				foreach ($sku in $unstagedskus) {
					if ($sku -like '*server*') {
						$server = $true
					} else {
						$client = $true
					}
					$skus+=$sku
				}
				
				$result.Editions = $skus
				
				if ($client) {
					$result.Type = 'client'
					if ($server) {
						$result.Type = 'client-server'
					}
				} elseif ($server) {
					$result.Type = 'server'
				}
			} else {
				$unstagedskus = (& 'bin\7z' l -i!vlpackages\*\update* $letter\sources\install.wim) | % { if ($_ -like '*update.mum*') { $_.split(' \')[-2] } }
				if (($unstagedskus -ne $null) -and ($unstagedskus -ne "")) {
					foreach ($sku in $unstagedskus) {
						if ($sku -like '*server*') {
							$server = $true
						} else {
							$client = $true
						}
						$skus+=$sku
					}
					
					$result.Editions = $skus
					
					if ($client) {
						$result.Type = 'client'
						if ($server) {
							$result.Type = 'client-server'
						}
					} elseif ($server) {
						$result.Type = 'server'
					}
				}
			}
		}
		
	}

    if (Test-Path "$($letter)\sources\ei.cfg") {
      $content = @()
      Get-Content ("$($letter)\sources\ei.cfg") | ForEach-Object -Process {
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
    }

    if (($WIMInfo.header.ImageCount -eq 4) -and ($result.Type -eq 'server')) {
      $result.Sku = $null
    }

    Get-Content ("$($letter)\sources\lang.ini") | ForEach-Object -Begin { $h = @() } -Process { $k = [regex]::split($_,'`r`n'); if (($k[0].CompareTo("") -ne 0)) { $h += $k[0] } }
    $result.LanguageCode = ($h[((0..($h.Count - 1) | Where { $h[$_] -eq '[Available UI Languages]' }) + 1)]).split('=')[0].Trim()

    $result.BuildString = ($result.MajorVersion + '.' + $result.MinorVersion + '.' + $result.BuildNumber + '.' + $result.DeltaVersion + '.' + $result.BranchName + '.' + $result.CompileDate)
    $result.SetupPath = $letter
	
    Write-Host "Dismounting $($isofile)..."
    Get-DiskImage -ImagePath $isofile.fullname | Dismount-DiskImage

  } elseif ((Test-Path ($letter + '\setup.exe')) -and (Test-Path ($letter + '\sources\setup.exe'))) {

    $buildno = (Get-Item $letter\setup.exe).VersionInfo.ProductVersion

    $result.MajorVersion = $buildno.split('.')[0]
    $result.MinorVersion = $buildno.split('.')[1]
    $result.BuildNumber = $buildno.split('.')[2]
    $result.DeltaVersion = $buildno.split('.')[3]

    # Gathering Compiledate and the buildbranch from the main setup.exe executable.
    $result.CompileDate = (Get-Item $letter\setup.exe).VersionInfo.FileVersion.split(' ')[1].split('.')[1].replace(')','')
    $result.BranchName = (Get-Item $letter\setup.exe).VersionInfo.FileVersion.split(' ')[1].split('.')[0].Substring(1)

    if (Test-Path $letter'\sources\product.ini') {
      $result.Sku = (get-inicontent ($letter + '\sources\product.ini'))["No-Section"]["skuid"].replace(' ','')
      if ($result.Sku -eq 'pro') {
        $result.Sku = 'Professional'
        $result.Type = 'Client'
      }
    } else {
      $files = (Get-ChildItem $letter\* | Where-Object { -not ([System.IO.Path]::hasExtension($_.fullname)) -and -not ($_.PSIsContainer) })
      if ($files -ne $null) {

        $editionletter = $files[-1].Name.toLower()

        $editionletter = $editionletter.replace('cdrom.','')
        $editionletter_ = $editionletter.split('.')[0][-2]
        $editionletter = $editionletter.split('.')[0][-1]

        if ($editionletter -eq 'p') {
          $result.Sku = 'Professional'
          $result.Type = 'client'
        } elseif ($editionletter -eq 'c') {
          $result.Sku = 'Home'
          $result.Type = 'client'
        } elseif ($editionletter -eq 'w') {
          $result.Sku = 'Workstation'
          $result.Type = 'client'
        } elseif ($editionletter -eq 'b') {
          $result.Sku = 'Web'
          $result.Type = 'server'
        } elseif ($editionletter -eq 's') {
          $result.Sku = 'Standard'
          if ($editionletter_ -eq 't') {
            $result.Sku = 'Terminal'
          }
          $result.Type = 'server'
        } elseif ($editionletter -eq 'a') {
          if ($result.BuildNumber.split('.')[2] -le 2202) {
            $result.Sku = 'Advanced'
          } else {
            $result.Sku = 'Enterprise'
          }
          $result.Type = 'server'
        } elseif ($editionletter -eq 'l') {
          $result.Sku = 'Smallbusiness'
          $result.Type = 'server'
        } elseif ($editionletter -eq 'd') {
          $result.Sku = 'Datacenter'
          $result.Type = 'server'
        } else {
          $result.Sku = $editionletter
          $result.Type = 'unknown'
        }
      }
    }

    $result.LanguageCode = $langcodes[(Get-Item $letter'\setup.exe').VersionInfo.Language]

    if ((Get-Item $letter\setup.exe).VersionInfo.IsDebug) {
      $result.BuildType = 'chk'
    } else {
      $result.BuildType = 'fre'
    }
    $result.Architecture = (Test-Arch $letter'\sources\setup.exe').FileType

    $result.Editions = $result.Sku

    (& 'bin\7z' l -i!*\ntldr $letter\sources\install.wim) | % { if ($_ -like '*ntldr*') { $wimindex = $_.split(' \')[-2] } }
	
	if ($wimindex -match "^[-]?[0-9.]+$") {
		# Gathering Compiledate and the buildbranch from the ntoskrnl executable.
		Write-Host 'Checking critical system files for a build string and build type information...'
		& 'bin\7z' x $letter'\sources\install.wim' "$($wimindex)\windows\system32\ntkrnlmp.exe" | Out-Null
		& 'bin\7z' x $letter'\sources\install.wim' "$($wimindex)\windows\system32\ntoskrnl.exe" | Out-Null
		if (Test-Path .\$wimindex\windows\system32\ntkrnlmp.exe) {
		  $result.CompileDate = (Get-Item .\$wimindex\windows\system32\ntkrnlmp.exe).VersionInfo.FileVersion.split(' ')[1].split('.')[1].replace(')','')
		  $result.BranchName = (Get-Item .\$wimindex\windows\system32\ntkrnlmp.exe).VersionInfo.FileVersion.split(' ')[1].split('.')[0].Substring(1)
		  if ((Get-Item .\$wimindex\windows\system32\ntkrnlmp.exe).VersionInfo.IsDebug) {
			$result.BuildType = 'chk'
		  } else {
			$result.BuildType = 'fre'
		  }
		  $ProductVersion = (Get-Item .\$wimindex\windows\system32\ntkrnlmp.exe).VersionInfo.ProductVersion
		  Remove-Item .\$wimindex\windows\system32\ntkrnlmp.exe -Force
		} elseif (Test-Path .\$wimindex\windows\system32\ntoskrnl.exe) {
		  $result.CompileDate = (Get-Item .\$wimindex\windows\system32\ntoskrnl.exe).VersionInfo.FileVersion.split(' ')[1].split('.')[1].replace(')','')
		  $result.BranchName = (Get-Item .\$wimindex\windows\system32\ntoskrnl.exe).VersionInfo.FileVersion.split(' ')[1].split('.')[0].Substring(1)
		  if ((Get-Item .\$wimindex\windows\system32\ntoskrnl.exe).VersionInfo.IsDebug) {
			$result.BuildType = 'chk'
		  } else {
			$result.BuildType = 'fre'
		  }
		  $ProductVersion = (Get-Item .\$wimindex\windows\system32\ntoskrnl.exe).VersionInfo.ProductVersion
		  Remove-Item .\$wimindex\windows\system32\ntoskrnl.exe -Force
		}

		$result.MajorVersion = $ProductVersion.split('.')[0]
		$result.MinorVersion = $ProductVersion.split('.')[1]
		$result.BuildNumber = $ProductVersion.split('.')[2]
		$result.DeltaVersion = $ProductVersion.split('.')[3]

		# Gathering Compiledate and the buildbranch from the build registry.
		Write-Host 'Checking registry for a more accurate build string...'
		& 'bin\7z' x $letter'\sources\install.wim' "$($wimindex)\windows\system32\config\" | Out-Null
		& 'reg' load HKLM\RenameISOs .\$wimindex\windows\system32\config\SOFTWARE | Out-Null
		$output = (& 'reg' query "HKLM\RenameISOs\Microsoft\Windows NT\CurrentVersion" /v "BuildLab")
		if (($output -ne $null) -and ($output[2] -ne $null) -and (-not ($output[2].split(' ')[-1].split('.')[-1]) -eq '')) {
		  $result.CompileDate = $output[2].split(' ')[-1].split('.')[-1]
		  $result.BranchName = $output[2].split(' ')[-1].split('.')[-2]
		  $output_ = (& 'reg' query "HKLM\RenameISOs\Microsoft\Windows NT\CurrentVersion" /v "BuildLabEx")
		  if (($output_[2] -ne $null) -and (-not ($output_[2].split(' ')[-1].split('.')[-1]) -eq '')) {
			if ($output_[2].split(' ')[-1] -like '*.*.*.*.*') {
			  $result.BuildNumber = $output_[2].split(' ')[-1].split('.')[0]
			  $result.DeltaVersion = $output_[2].split(' ')[-1].split('.')[1]
			}
		  }
		} else {
		  Write-Host 'Registry check was unsuccessful. Aborting and continuing with critical system files build string...'
		}
		& 'reg' unload HKLM\RenameISOs | Out-Null

		& 'reg' load HKLM\RenameISOs .\$wimindex\windows\system32\config\SYSTEM | Out-Null
		$ProductSuite = (Get-ItemProperty -Path HKLM:\RenameISOs\ControlSet001\Control\ProductOptions -Name ProductSuite).ProductSuite
		$ProductType = (Get-ItemProperty -Path HKLM:\RenameISOs\ControlSet001\Control\ProductOptions -Name ProductType).ProductType
		
		if ($ProductType -eq 'ServerNT') {
		  $result.Type = 'server'
		} else {
		  $result.Type = 'client'
		}
		
		

		if ($ProductSuite -is [System.Array]) {
		  if ($ProductSuite[0] -ne '') {
			$result.Sku = $ProductSuite[0]
		  } else {
			$result.Sku = 'Professional'
		  }
		} elseif ($ProductSuite -ne '') {
		  $result.Sku = $ProductSuite
		} else {
		  $result.Sku = 'Professional'
		}
		$result.Editions = $result.Sku

		& 'reg' unload HKLM\RenameISOs | Out-Null

		Remove-Item .\$wimindex\windows\system32\config\ -Recurse -Force

		Remove-Item .\$wimindex\ -Recurse -Force
	} else {
		# Gathering Compiledate and the buildbranch from the ntoskrnl executable.
		Write-Host 'Checking critical system files for a build string and build type information...'
		& 'bin\7z' x $letter'\sources\install.wim' "windows\system32\ntkrnlmp.exe" | Out-Null
		& 'bin\7z' x $letter'\sources\install.wim' "windows\system32\ntoskrnl.exe" | Out-Null
		if (Test-Path .\windows\system32\ntkrnlmp.exe) {
		  $result.CompileDate = (Get-Item .\windows\system32\ntkrnlmp.exe).VersionInfo.FileVersion.split(' ')[1].split('.')[1].replace(')','')
		  $result.BranchName = (Get-Item .\windows\system32\ntkrnlmp.exe).VersionInfo.FileVersion.split(' ')[1].split('.')[0].Substring(1)
		  if ((Get-Item .\windows\system32\ntkrnlmp.exe).VersionInfo.IsDebug) {
			$result.BuildType = 'chk'
		  } else {
			$result.BuildType = 'fre'
		  }
		  $ProductVersion = (Get-Item .\windows\system32\ntkrnlmp.exe).VersionInfo.ProductVersion
		  Remove-Item .\windows\system32\ntkrnlmp.exe -Force
		} elseif (Test-Path .\windows\system32\ntoskrnl.exe) {
		  $result.CompileDate = (Get-Item .\windows\system32\ntoskrnl.exe).VersionInfo.FileVersion.split(' ')[1].split('.')[1].replace(')','')
		  $result.BranchName = (Get-Item .\windows\system32\ntoskrnl.exe).VersionInfo.FileVersion.split(' ')[1].split('.')[0].Substring(1)
		  if ((Get-Item .\windows\system32\ntoskrnl.exe).VersionInfo.IsDebug) {
			$result.BuildType = 'chk'
		  } else {
			$result.BuildType = 'fre'
		  }
		  $ProductVersion = (Get-Item .\windows\system32\ntoskrnl.exe).VersionInfo.ProductVersion
		  Remove-Item .\windows\system32\ntoskrnl.exe -Force
		}

		$result.MajorVersion = $ProductVersion.split('.')[0]
		$result.MinorVersion = $ProductVersion.split('.')[1]
		$result.BuildNumber = $ProductVersion.split('.')[2]
		$result.DeltaVersion = $ProductVersion.split('.')[3]

		# Gathering Compiledate and the buildbranch from the build registry.
		Write-Host 'Checking registry for a more accurate build string...'
		& 'bin\7z' x $letter'\sources\install.wim' "windows\system32\config\" | Out-Null
		& 'reg' load HKLM\RenameISOs .\windows\system32\config\SOFTWARE | Out-Null
		$output = (& 'reg' query "HKLM\RenameISOs\Microsoft\Windows NT\CurrentVersion" /v "BuildLab")
		if (($output -ne $null) -and ($output[2] -ne $null) -and (-not ($output[2].split(' ')[-1].split('.')[-1]) -eq '')) {
		  $result.CompileDate = $output[2].split(' ')[-1].split('.')[-1]
		  $result.BranchName = $output[2].split(' ')[-1].split('.')[-2]
		  $output_ = (& 'reg' query "HKLM\RenameISOs\Microsoft\Windows NT\CurrentVersion" /v "BuildLabEx")
		  if (($output_[2] -ne $null) -and (-not ($output_[2].split(' ')[-1].split('.')[-1]) -eq '')) {
			if ($output_[2].split(' ')[-1] -like '*.*.*.*.*') {
			  $result.BuildNumber = $output_[2].split(' ')[-1].split('.')[0]
			  $result.DeltaVersion = $output_[2].split(' ')[-1].split('.')[1]
			}
		  }
		} else {
		  Write-Host 'Registry check was unsuccessful. Aborting and continuing with critical system files build string...'
		}
		& 'reg' unload HKLM\RenameISOs | Out-Null

		& 'reg' load HKLM\RenameISOs .\windows\system32\config\SYSTEM | Out-Null
		$ProductSuite = (Get-ItemProperty -Path HKLM:\RenameISOs\ControlSet001\Control\ProductOptions -Name ProductSuite).ProductSuite
		$ProductType = (Get-ItemProperty -Path HKLM:\RenameISOs\ControlSet001\Control\ProductOptions -Name ProductType).ProductType
		
		if ($ProductType -eq 'ServerNT') {
		  $result.Type = 'server'
		} else {
		  $result.Type = 'client'
		}

		if ($ProductSuite -is [System.Array]) {
		  if ($ProductSuite[0] -ne '') {
			$result.Sku = $ProductSuite[0]
		  } else {
			$result.Sku = 'Professional'
		  }
		} elseif ($ProductSuite -ne '') {
		  $result.Sku = $ProductSuite
		} else {
		  $result.Sku = 'Professional'
		}
		$result.Editions = $result.Sku
		
		$server = $false
		$client = $false
		
		$skus = @()
		
		$unstagedskus = (& 'bin\7z' l -i!packages\*sku*\Security-Licensing-SLC-Component-SKU*pl*xrm* $letter\sources\install.wim) | % { if ($_ -like '*Security-Licensing-SLC-Component-SKU*pl*xrm*') { $_.split(' \')[-2].split('-')[-1].split('_')[0] } } | Select -uniq
		if (($unstagedskus -ne $null) -and ($unstagedskus -ne "")) {
				foreach ($sku in $unstagedskus) {
					if ($sku -like '*server*') {
						$server = $true
					} else {
						$client = $true
					}
					$skus+=$sku
				}
				
				$result.Editions = $skus
				
				if ($client) {
					$result.Type = 'client'
					if ($server) {
						$result.Type = 'client-server'
					}
				} elseif ($server) {
					$result.Type = 'server'
				}
		} else {
			$unstagedskus = (& 'bin\7z' l -i!packages\*\update* $letter\sources\install.wim) | % { if ($_ -like '*update.mum*') { $_.split(' \')[-2] } }
			if (($unstagedskus -ne $null) -and ($unstagedskus -ne "")) {
				foreach ($sku in $unstagedskus) {
					if ($sku -like '*server*') {
						$server = $true
					} else {
						$client = $true
					}
					$skus+=$sku
				}
				
				$result.Editions = $skus
				
				if ($client) {
					$result.Type = 'client'
					if ($server) {
						$result.Type = 'client-server'
					}
				} elseif ($server) {
					$result.Type = 'server'
				}
			} else {
				$unstagedskus = (& 'bin\7z' l -i!vlpackages\*\update* $letter\sources\install.wim) | % { if ($_ -like '*update.mum*') { $_.split(' \')[-2] } }
				if (($unstagedskus -ne $null) -and ($unstagedskus -ne "")) {
					foreach ($sku in $unstagedskus) {
						if ($sku -like '*server*') {
							$server = $true
						} else {
							$client = $true
						}
						$skus+=$sku
					}
					
					$result.Editions = $skus
					
					if ($client) {
						$result.Type = 'client'
						if ($server) {
							$result.Type = 'client-server'
						}
					} elseif ($server) {
						$result.Type = 'server'
					}
				}
			}
		}

		& 'reg' unload HKLM\RenameISOs | Out-Null

		Remove-Item .\windows\system32\config\ -Recurse -Force

		Remove-Item .\windows -Recurse -Force
	}

    Write-Host "Dismounting $($isofile)..."
    Get-DiskImage -ImagePath $isofile.fullname | Dismount-DiskImage

  } elseif ((Test-Path ($letter + '\setup.exe')) -and (Test-Path ($letter + '\ia64\txtsetup.sif'))) {

    $result = get-i386infos $letter 'ia64' $result.VolumeLabel

  } elseif ((Test-Path ($letter + '\setup.exe')) -and (Test-Path ($letter + '\amd64\txtsetup.sif'))) {

    $result = get-i386infos $letter 'amd64' $result.VolumeLabel

  } elseif ((Test-Path ($letter + '\i386\ntoskrnl.ex_')) -and (Test-Path ($letter + '\i386\txtsetup.sif'))) {

    $result = get-i386infos $letter 'i386' $result.VolumeLabel

  } elseif ((Test-Path ($letter + '\i386\ntoskrnl.exe')) -and (Test-Path ($letter + '\i386\txtsetup.sif'))) {

    $result = get-i386infos $letter 'i386' $result.VolumeLabel

  } elseif ((Test-Path ($letter + '\i386\NTKRNLMP.ex_')) -and (Test-Path ($letter + '\i386\txtsetup.sif'))) {

    $result = get-i386infos $letter 'i386' $result.VolumeLabel

  } elseif ((Test-Path ($letter + '\i386\NTKRNLMP.exe')) -and (Test-Path ($letter + '\i386\txtsetup.sif'))) {

    $result = get-i386infos $letter 'i386' $result.VolumeLabel

  } elseif ((Test-Path ($letter + '\alpha\ntoskrnl.exe')) -and (Test-Path ($letter + '\alpha\txtsetup.sif'))) {

    $result = get-i386infos $letter 'alpha' $result.VolumeLabel

  } elseif ((Test-Path ($letter + '\alpha\ntoskrnl.ex_')) -and (Test-Path ($letter + '\alpha\txtsetup.sif'))) {

    $result = get-i386infos $letter 'alpha' $result.VolumeLabel

  } elseif (((Get-ChildItem $letter\*WIN*.CAB -Recurse) | Where-Object { (($_.fullname).split('\').Count) -le 4 }) -ne $null) {
    $cab = ((Get-ChildItem $letter\*WIN*.CAB -Recurse) | Where-Object { (($_.fullname).split('\').Count) -le 4 })[1]
    $result.Type = 'client'
    if ((Get-ChildItem ($cab.directory.fullname + '\USER.EXE') -Recurse) -ne $null) {
      $result.BuildType = 'chk'
    } else {
      $result.BuildType = 'fre'
    }
    & 'bin\7z' e $cab user.exe | Out-Null
    $result.MajorVersion = ((Get-Item .\user.exe).VersionInfo.ProductVersion).split('.')[0]
    $result.MinorVersion = ((Get-Item .\user.exe).VersionInfo.ProductVersion).split('.')[1]
    $result.BuildNumber = ((Get-Item .\user.exe).VersionInfo.ProductVersion).split('.')[2]
    $result.Architecture = 'X86'
    $result.LanguageCode = $langcodes[(Get-Item .\user.exe).VersionInfo.Language]
    Remove-Item -Force .\user.exe


    # Hotfix for a MS derping on the 347 Spanish version of Windows 95, the OS is technically 347, but for some reason, 
    # kernel386, gdi, and user are reporting 346 as the build number. While win32 components, (kernel32, gdi32, user32)
    # reports 347, as it should be. If you have any doubt, you can find this 347 spanish build on the multilang dvd of 347.
    if (($result.LanguageCode -eq 'es-ES_tradnl') -and ($result.BuildNumber -eq '346')) {
      $result.BuildNumber = '347'
    }

    if ($result.BuildNumber -eq '950') {
      & 'bin\7z' e $cab kernel32.dll | Out-Null
      $result.MajorVersion = ((Get-Item .\kernel32.dll).VersionInfo.ProductVersion).split('.')[0]
      $result.MinorVersion = ((Get-Item .\kernel32.dll).VersionInfo.ProductVersion).split('.')[1]
      $result.BuildNumber = ((Get-Item .\kernel32.dll).VersionInfo.ProductVersion).split('.')[2]
      Remove-Item -Force .\kernel32.dll
    }

    $paths = @()
    ((Get-ChildItem $letter\*WIN*.CAB -Recurse) | Where-Object { (($_.fullname).split('\').Count) -le 4 }) | ForEach-Object -Process {
      if (-not ($paths -contains $_.directory.fullname)) {
        $paths += $_.directory.fullname
      }
    }

    if ($paths.Count -gt 1) {
      $result.LanguageCode = 'multi'
    }

    if (Test-Path ($cab.directory.fullname + '.\SETUPPP.INF')) {
      if (((get-inicontent ($cab.directory.fullname + '.\SETUPPP.INF'))["Strings"]) -ne $null) {
        if (((get-inicontent ($cab.directory.fullname + '.\SETUPPP.INF'))["Strings"]["SubVersionString"]) -ne $null) {
          $subver = (get-inicontent ($cab.directory.fullname + '.\SETUPPP.INF'))["Strings"]["SubVersionString"].replace('"','')
          if ($subver -like '*;*') {
            $subver = $subver.split(';')[0]
          }

          $subver = Remove-InvalidFileNameChars ($subver)
          $subver = $subver.split(' ')

          foreach ($item in $subver) {
            if ($item -ne '') {
              if ($item -like '.*') {
                $result.DeltaVersion = $item.Substring(1)
              } elseif (($item.Length -eq 1) -and (-not ($item -match "[0-9]"))) {
                $result.BuildNumber = ($result.BuildNumber + $item)
              } else {
                if ($result.Tag -eq $null) {
                  $result.Tag = $item
                } else {
                  $result.Tag = ($result.Tag + '_' + $item)
                }
              }
            }
          }
        }
      }
    } else {
      & 'bin\7z' e $cab.directory.fullname '\PRECOPY2.CAB' SETUPPP.INF | Out-Null
      if (((get-inicontent '.\SETUPPP.INF')["Strings"]) -ne $null) {
        if (((get-inicontent '.\SETUPPP.INF')["Strings"]["SubVersionString"]) -ne $null) {
          $subver = (get-inicontent '.\SETUPPP.INF')["Strings"]["SubVersionString"].replace('"','')
          if ($subver -like '*;*') {
            $subver = $subver.split(';')[0]
          }

          if ($subver -ne '') {
            $subver = Remove-InvalidFileNameChars ($subver)
            $subver = $subver.split(' ')

            foreach ($item in $subver) {
              if ($item -ne '') {
                if ($item -like '.*') {
                  $result.DeltaVersion = $item.Substring(1)
                } elseif (($item.Length -eq 1) -and (-not ($item -match "[0-9]"))) {
                  $result.BuildNumber = ($result.BuildNumber + $item)
                } else {
                  if ($result.Tag -eq $null) {
                    $result.Tag = $item
                  } else {
                    $result.Tag = ($result.Tag + '_' + $item)
                  }
                }
              }
            }
          }
        }
      }
      Remove-Item -Force '.\SETUPPP.INF'
    }

    Write-Host "Dismounting $($isofile)..."
    Get-DiskImage -ImagePath $isofile.fullname | Dismount-DiskImage
  } elseif ((Get-ChildItem $letter\*CHICO*.CAB -Recurse) -ne $null) {
    $cab = (Get-ChildItem $letter\*CHICO*.CAB -Recurse)[1]
    $result.Type = 'client'
    if ((Get-ChildItem ($cab.directory.fullname + '\USER.EXE') -Recurse) -ne $null) {
      $result.BuildType = 'chk'
    } else {
      $result.BuildType = 'fre'
    }
    & 'bin\7z' e $cab user.exe | Out-Null
    $result.MajorVersion = ((Get-Item .\user.exe).VersionInfo.ProductVersion).split('.')[0]
    $result.MinorVersion = ((Get-Item .\user.exe).VersionInfo.ProductVersion).split('.')[1]
    $result.BuildNumber = ((Get-Item .\user.exe).VersionInfo.ProductVersion).split('.')[2]
    $result.Architecture = 'x86'
    Remove-Item .\user.exe -Force
    & 'bin\7z' e $cab shell32.dll | Out-Null
    & 'bin\7z' e .\shell32.dll .rsrc\version.txt | Out-Null
    (Get-Content .\version.txt) | ForEach-Object -Process {
      $_ = Remove-InvalidFileNameChars ($_)
      if ($_ -like ('*Translation*')) {
        $langdata = $_.split(',')[1].Trim()
        $result.LanguageCode = [System.Globalization.Cultureinfo]::GetCultureInfo([int32]$langdata).Name
      }
    }

    Remove-Item '.\version.txt' -Force
    Remove-Item .\shell32.dll -Force

    $paths = @()
    (Get-ChildItem $letter\*CHICO*.CAB -Recurse) | ForEach-Object -Process {
      if (-not ($paths -contains $_.directory.fullname)) {
        $paths += $_.directory.fullname
      }
    }

    if ($paths.Count -gt 1) {
      $result.LanguageCode = 'multi'
    }

    & 'bin\7z' e $cab.directory.fullname '\PRECOPY2.CAB' SETUPPP.INF | Out-Null
    if (((get-inicontent '.\SETUPPP.INF')["Strings"]) -ne $null) {
      if (((get-inicontent '.\SETUPPP.INF')["Strings"]["SubVersionString"]) -ne $null) {
        $subver = (get-inicontent '.\SETUPPP.INF')["Strings"]["SubVersionString"].replace('"','').replace(' ','').replace('-','')
        if ($subver -like '*;*') {
          $subver = $subver.split(';')[0]
        }
        if ($subver -ne '') {
          $result.BuildNumber = ($result.BuildNumber + '_' + $subver)
        }
      }
    }
    Remove-Item '.\SETUPPP.INF' -Force

    Write-Host "Dismounting $($isofile)..."
    Get-DiskImage -ImagePath $isofile.fullname | Dismount-DiskImage
  } else {
    Write-Host "The ISO is unknown!"
    Write-Host "Dismounting $($isofile)..."
    Get-DiskImage -ImagePath $isofile.fullname | Dismount-DiskImage
    return $null
  }
  if ($result.BuildNumber -eq $null) {
    Write-Host "The ISO is unknown!"
    return $null
  }
  return $result
}

function get-BetterISOFilename ($item) {
  $results = ISO-Identify ($item)
  Write-Host $results
  if ($results -eq $null) {
    return $null
  }

  switch ($scheme) {
    0 {
      if ($results.Sku -eq $null) {
        $identifier = $results.Type
      } else {
        $identifier = $results.Type + '-' + $results.Sku
      }

      if ($results.Licensing -ne $null) {
        $identifier = $identifier + '_' + $results.Licensing
      }

      $filename = $results.MajorVersion + '.' + $results.MinorVersion + '.' + $results.BuildNumber

      if (-not ($results.DeltaVersion -eq $null)) {
        $filename = $filename + '.' + $results.DeltaVersion
      }

      if (-not ($results.BranchName -eq $null)) {
        $filename = $filename + '.' + $results.BranchName
      }

      if (-not ($results.CompileDate -eq $null)) {
        $filename = $filename + '.' + $results.CompileDate
      }

      if (-not ($results.Tag -eq $null)) {
        $filename = $filename + '_' + $results.Tag
      }

      $filename = $filename + '_' + $results.Architecture + $results.BuildType + '_' + $identifier + '_' + $results.LanguageCode
      $filename = $filename.toLower()


      if ($addLabel) {
        $filename = $filename + '-' + $results.VolumeLabel
      }
      $filename = $filename + '.iso'
    }
    1 {
      $Edition = $null
      $Licensing = $null

      foreach ($item_ in $results.Editions) {
        if ($Edition -eq $null) {
          $Licensing = 'RET'
          $Edition_ = $item_
          if ($item_ -eq 'Core') { $Edition_ = 'CORE' }
          if ($item_ -eq 'CoreN') { $Edition_ = 'COREN' }
          if ($item_ -eq 'CoreSingleLanguage') { $Edition_ = 'SINGLELANGUAGE' }
          if ($item_ -eq 'CoreCountrySpecific') { $Edition_ = 'CHINA' }
          if ($item_ -eq 'Professional') { $Edition_ = 'PRO' }
          if ($item_ -eq 'ProfessionalN') { $Edition_ = 'PRON' }
          if ($item_ -eq 'ProfessionalWMC') { $Edition_ = 'PROWMC' }
          if ($item_ -eq 'CoreConnected') { $Edition_ = 'CORECONNECTED' }
          if ($item_ -eq 'CoreConnectedN') { $Edition_ = 'CORECONNECTEDN' }
          if ($item_ -eq 'CoreConnectedSingleLanguage') { $Edition_ = 'CORECONNECTEDSINGLELANGUAGE' }
          if ($item_ -eq 'CoreConnectedCountrySpecific') { $Edition_ = 'CORECONNECTEDCHINA' }
          if ($item_ -eq 'ProfessionalStudent') { $Edition_ = 'PROSTUDENT' }
          if ($item_ -eq 'ProfessionalStudentN') { $Edition_ = 'PROSTUDENTN' }
          if ($item_ -eq 'Enterprise') {
            $Licensing = 'VOL'
            $Edition_ = 'ENTERPRISE'
          }
          $Edition = $Edition_
        } else {
          $Edition_ = $item_
          if ($item_ -eq 'Core') { $Edition_ = 'CORE' }
          if ($item_ -eq 'CoreN') { $Edition_ = 'COREN' }
          if ($item_ -eq 'CoreSingleLanguage') { $Edition_ = 'SINGLELANGUAGE' }
          if ($item_ -eq 'CoreCountrySpecific') { $Edition_ = 'CHINA' }
          if ($item_ -eq 'Professional') { $Edition_ = 'PRO' }
          if ($item_ -eq 'ProfessionalN') { $Edition_ = 'PRON' }
          if ($item_ -eq 'ProfessionalWMC') { $Edition_ = 'PROWMC' }
          if ($item_ -eq 'CoreConnected') { $Edition_ = 'CORECONNECTED' }
          if ($item_ -eq 'CoreConnectedN') { $Edition_ = 'CORECONNECTEDN' }
          if ($item_ -eq 'CoreConnectedSingleLanguage') { $Edition_ = 'CORECONNECTEDSINGLELANGUAGE' }
          if ($item_ -eq 'CoreConnectedCountrySpecific') { $Edition_ = 'CORECONNECTEDCHINA' }
          if ($item_ -eq 'ProfessionalStudent') { $Edition_ = 'PROSTUDENT' }
          if ($item_ -eq 'ProfessionalStudentN') { $Edition_ = 'PROSTUDENTN' }
          if ($item_ -eq 'Enterprise') {
            $Licensing = $Licensing + 'VOL'
            $Edition_ = 'ENTERPRISE'
          }
          $Edition = $Edition + '-' + $Edition_
        }
      }

      if ($results.Type.toLower() -eq 'server') {
        $Edition = $Edition.toUpper() -replace 'SERVERHYPER','SERVERHYPERCORE' -replace 'SERVER',''
      }

      if ($results.Licensing.toLower() -eq 'volume') {
        $Licensing = 'VOL'
      } elseif ($results.Licensing.toLower() -eq 'oem') {
        $Licensing = 'OEM'
      } elseif ($Licensing -eq $null) {
        $Licensing = 'RET'
      }

      if ($Edition -contains 'PRO-CORE') {
        $Licensing = $Licensing -replace 'RET','OEMRET'
      } elseif ($results.Sku -eq $null -and $results.Type.toLower() -eq 'server') {
        $Edition = ''
        if ($results.Licensing.toLower() -eq 'retail') {
          $Licensing = 'OEMRET'
        }
        if ($results.Licensing.toLower() -eq 'retail' -and [int]$results.BuildNumber -lt 9900) {
          $Licensing = 'OEM'
        }
      } elseif ($results.Editions.Count -eq 1 -and $results.Type.toLower() -eq 'server') {
        $Licensing = 'OEM'
      }

      if ([int]$results.BuildNumber -lt 8008) {
        $Edition = $results.Sku
      }

      if ($Edition -eq 'unstaged') {
        $Edition = ''
      }

      $arch = $results.Architecture -replace 'amd64','x64'
      if ($results.BranchName -eq $null) {
        $FILENAME = ($results.BuildNumber + '.' + $results.DeltaVersion)
      } else {
        $FILENAME = ($results.BuildNumber + '.' + $results.DeltaVersion + '.' + $results.CompileDate + '.' + $results.BranchName)
      }

      $FILENAME = ($FILENAME + '_' + $results.Type + $Edition + '_' + $Licensing + '_' + $arch + $results.BuildType + '_' + $results.LanguageCode)

      if ($addLabel) {
        $filename = $filename + '-' + $results.VolumeLabel
      }
      $filename = ($filename + '.iso').toUpper()
    }
    2 {
      if ($results.LanguageCode -eq 'en-gb') {
        $lang = 'en-gb'
      } elseif ($results.LanguageCode -eq 'es-mx') {
        $lang = 'es-mx'
      } elseif ($results.LanguageCode -eq 'fr-ca') {
        $lang = 'fr-ca'
      } elseif ($results.LanguageCode -eq 'pt-pt') {
        $lang = 'pp'
      } elseif ($results.LanguageCode -eq 'sr-latn-rs') {
        $lang = 'sr-latn'
      } elseif ($results.LanguageCode -eq 'zh-cn') {
        $lang = 'cn'
      } elseif ($results.LanguageCode -eq 'zh-tw') {
        $lang = 'tw'
      } elseif ($results.LanguageCode -eq 'zh-hk') {
        $lang = 'hk'
      } else {
        $lang = $results.LanguageCode.split('-')[0]
      }

      $arch = $results.Architecture
      $EditionID = $null

      foreach ($item_ in $results.Editions) {
        if ($EditionID -eq $null) {
          $EditionID = $item_
        } else {
          $EditionID = $EditionID + '-' + $item_
        }
      }

      if ($results.BranchName -ne $null) {
        $filename = ($lang.toLower()) + '_' + $results.BuildNumber + '.' + $results.DeltaVersion + '.' + $results.BranchName + '.' + $results.CompileDate + '_' + $arch + $results.BuildType + '_' + $results.Sku + '_' + ($results.LanguageCode.toLower()) + '_' + $EditionID + '-' + $results.VolumeLabel + '.iso'
        if ($EditionID.toLower() -eq 'enterprise') { $filename = ($lang.toLower()) + '_' + $results.BuildNumber + '.' + $results.DeltaVersion + '.' + $results.BranchName + '.' + $results.CompileDate + '_' + $arch + $results.BuildType + '_' + $results.Sku + '_' + ($results.LanguageCode.toLower()) + '_VL_' + $EditionID + '-' + $results.VolumeLabel + '.iso' }
        if ($EditionID.toLower() -eq 'enterprisen') { $filename = ($lang.toLower()) + '_' + $results.BuildNumber + '.' + $results.DeltaVersion + '.' + $results.BranchName + '.' + $results.CompileDate + '_' + $arch + $results.BuildType + '_' + $results.Sku + '_' + ($results.LanguageCode.toLower()) + '_VL_' + $EditionID + '-' + $results.VolumeLabel + '.iso' }
      } else {
        $filename = ($lang.toLower()) + '_' + $results.BuildNumber + '.' + $results.DeltaVersion + '.' + $results.CompileDate + '_' + $arch + $results.BuildType + '_' + $results.Sku + '_' + ($results.LanguageCode.toLower()) + '_' + $EditionID + '-' + $results.VolumeLabel + '.iso'
        if ($EditionID.toLower() -eq 'enterprise') { $filename = ($lang.toLower()) + '_' + $results.BuildNumber + '.' + $results.DeltaVersion + '_' + $arch + $results.BuildType + '_' + $results.Sku + '_' + ($results.LanguageCode.toLower()) + '_VL_' + $EditionID + '-' + $results.VolumeLabel + '.iso' }
        if ($EditionID.toLower() -eq 'enterprisen') { $filename = ($lang.toLower()) + '_' + $results.BuildNumber + '.' + $results.DeltaVersion + '_' + $arch + $results.BuildType + '_' + $results.Sku + '_' + ($results.LanguageCode.toLower()) + '_VL_' + $EditionID + '-' + $results.VolumeLabel + '.iso' }
      }
    }
  }
  Write-Host "Found: $($filename)"
  return $filename,$results
}

