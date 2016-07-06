[CmdletBinding()]
param (
    [ValidateScript({(Test-Path $_)})] 
	[parameter(Mandatory=$false,HelpMessage="The complete path to the Setup directory to rebuild.")]
	[String] $SourcePath,
 
    [ValidateScript({(Test-Path $_)})] 
	[parameter(Mandatory=$false,HelpMessage="The place where the final ISO file will be stored")]
	[System.IO.DirectoryInfo] $Destination = '.\'
)

if (Test-Path "$($SourcePath)\MediaMeta.xml") {
	Write-Host "MediaMeta file has been detected, please move this file elsewhere or delete it if you don't want to back it up. Exiting..."
	return
}

function Get-ScriptDirectory {
  return Split-Path -Parent $PSCommandPath
}

$ScriptDir = Get-ScriptDirectory

Write-host $ScriptDir

#Is this a Wow64 powershell host
function Test-Wow64 {
  return (Test-Win32) -and (Test-Path env:\PROCESSOR_ARCHITEW6432)
}

#Is this a 64 bit process
function Test-Win64 {
  return [intptr]::size -eq 8
}

#Is this a 32 bit process
function Test-Win32 {
  return [intptr]::size -eq 4
}

if (Test-Wow64) {
  $wimlib = "$($ScriptDir)\wimlib-imagex.exe"
} elseif (Test-Win64) {
  $wimlib = "$($ScriptDir)\bin64\wimlib-imagex.exe"
} elseif (Test-Win32) {
  $wimlib = "$($ScriptDir)\wimlib-imagex.exe"
} else {
  return
}

function Get-InfosFromSetupPath (
  [Parameter(Mandatory = $true,HelpMessage = "The complete path to the ISO Path.")]
  [string]$PATH
)
{
  $WIM = $PATH + "\sources\install.wim"
  $wiminformations = @()
  $result = "" | select MajorVersion,MinorVersion,BuildNumber,DeltaVersion,BranchName,CompileDate,Architecture,BuildType,Type,Sku,Editions,Licensing,LanguageCode,VolumeLabel,FileName,timestamp,BuildString,SetupPath

  $editions = @()
  $counter = 0

  $WIMInfo = New-Object System.Collections.ArrayList
  $WIMInfo = @{}

  $header = @{}
  $OutputVariable = (& $wimlib info "$($WIM)" --header)
  foreach ($Item in $OutputVariable) {
    $CurrentItem = ($Item -replace '\s+',' ').split('=')
    $CurrentItemName = $CurrentItem[0] -replace ' ',''
    if (($CurrentItem[1] -replace ' ','') -ne '') {
      $header[$CurrentItemName] = $CurrentItem[1].Substring(1)
    }
  }

  for ($i = 1; $i -le $header.ImageCount; $i++) {
    $counter++
    $WIMInfo[$counter] = @{}
    $OutputVariable = (& $wimlib info "$($WIM)" $i)
    foreach ($Item in $OutputVariable) {
      $CurrentItem = ($Item -replace '\s+',' ').split(':')
      $CurrentItemName = $CurrentItem[0] -replace ' ',''
      if (($CurrentItem[1] -replace ' ','') -ne '') {
        $WIMInfo[$counter][$CurrentItemName] = $CurrentItem[1].Substring(1)
        if ($CurrentItemName -eq 'EditionID') {
          $lastedition = $CurrentItem[1].Substring(1)
          $editions += $CurrentItem[1].Substring(1)
        }
      }
    }
  }

  $WIMInfo["header"] = @{}
  $WIMInfo["header"]["ImageCount"] = ($counter.ToString())

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
  & 'reg' load HKLM\ISORebuilder .\config\SOFTWARE | Out-Null
  $output = (& 'reg' query "HKLM\ISORebuilder\Microsoft\Windows NT\CurrentVersion" /v "BuildLab")
  if (($output[2] -ne $null) -and (-not ($output[2].split(' ')[-1].split('.')[-1]) -eq '')) {
    $result.CompileDate = $output[2].split(' ')[-1].split('.')[-1]
    $result.BranchName = $output[2].split(' ')[-1].split('.')[-2]
    $output_ = (& 'reg' query "HKLM\ISORebuilder\Microsoft\Windows NT\CurrentVersion" /v "BuildLabEx")
    if (($output_[2] -ne $null) -and (-not ($output_[2].split(' ')[-1].split('.')[-1]) -eq '')) {
      if ($output_[2].split(' ')[-1] -like '*.*.*.*.*') {
        $result.BuildNumber = $output_[2].split(' ')[-1].split('.')[0]
        $result.DeltaVersion = $output_[2].split(' ')[-1].split('.')[1]
      }
    }
  } else {
    Write-Host 'Registry check for buildstring was unsuccessful. Aborting and continuing with critical system files build string...'
  }
  $output = (& 'reg' query "HKLM\ISORebuilder\Microsoft\Windows NT\CurrentVersion\DefaultProductKey" /v "ProductId")
  if ($output[2] -ne $null) {
	$var = $output[2].split(' ')[-1].Substring($output[2].split(' ')[-1].Length - 3, 3)
	if ($var.toUpper() -eq "OEM") {
		$result.Licensing = "oem"
	}
  }
  & 'reg' unload HKLM\ISORebuilder | Out-Null
  Remove-Item .\config\ -Recurse -Force

  # Defining if server or client thanks to Microsoft including 'server' in the server sku names
  if (($WIMInfo.header.ImageCount -gt 1) -and (($WIMInfo[1].EditionID) -eq $null)) {
    $result.Type = 'client'
    $result.Sku = $null
  } elseif (($WIMInfo[1].EditionID) -eq $null) {
    $result.Type = 'client'
    $result.Sku = 'unstaged'
  } elseif (($WIMInfo[1].EditionID.toLower()) -like '*server*') {
    $result.Type = 'server'
    $result.Sku = $WIMInfo[1].EditionID.toLower() -replace 'server',''
  } else {
    $result.Type = 'client'
    $result.Sku = $WIMInfo[1].EditionID.toLower()
  }
  
  if (Test-Path "$($PATH)\sources\ei.cfg") {
    $content = @()
    Get-Content ("$($PATH)\sources\ei.cfg") | ForEach-Object -Process {
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

  Get-Content ("$($PATH)\sources\lang.ini") | ForEach-Object -Begin { $h = @() } -Process { $k = [regex]::split($_,'`r`n'); if (($k[0].CompareTo("") -ne 0)) { $h += $k[0] } }
  $result.LanguageCode = ($h[((0..($h.Count - 1) | Where { $h[$_] -eq '[Available UI Languages]' }) + 1)]).split('=')[0].Trim()

  $tag = 'ir3'
  $DVD = 'DV9'

  if ($WIMInfo[1].Architecture -eq 'x86') {
    $arch = 'x86'
  }

  if ($WIMInfo[1].Architecture -eq 'x86_64') {
    $arch = 'x64'
  }

  if ($WIMInfo[1].ServicePackBuild -eq '17056') {
    $tag = 'ir4'
  }
  if ($WIMInfo[1].ServicePackBuild -eq '17415') {
    $tag = 'ir5'
  }
  if ($WIMInfo[1].ServicePackBuild -gt '17415') {
    $tag = 'ir6'
  }

  if ([int]$WIMInfo[1].Build -gt '9600') {
    $tag = 'JM1'
    $DVD = 'DV5'
  }
  if ([int]$WIMInfo[1].Build -ge '9896') {
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
  
  function Get-DirectoryStats {
	  param($directory, $recurse, $format)

	  Write-Progress -Activity "$($ScriptDir)\Get-DirStats.ps1" -Status "Reading '$($directory.FullName)'"
	  $files = $directory | Get-ChildItem -Force -Recurse:$recurse | Where-Object { -not $_.PSIsContainer }
	  if ($files) {
		Write-Progress -Activity "$($ScriptDir)\Get-DirStats.ps1" -Status "Calculating '$($directory.FullName)'"
		$output = $files | Measure-Object -Sum -Property Length | Select-Object @{Name="Path"; Expression={$directory.FullName}},@{Name="Files"; Expression={$_.Count; $script:totalcount += $_.Count}},@{Name="Size"; Expression={$_.Sum; $script:totalbytes += $_.Sum}}
	  } else {
		$output = "" | Select-Object @{Name="Path"; Expression={$directory.FullName}},@{Name="Files"; Expression={0}},@{Name="Size"; Expression={0}}
	  }
	  if ( -not $format ) { $output } else { $output | Format-Output }
	}
	
	$DVDSize = ((Get-DirectoryStats $PATH).Size / 1GB)
	
	if ($DVDSize -le 15.90) {
		$DVD = "DV18"
	}
	
	if ($DVDSize -le 12.33) {
		$DVD = "DV14"
	}
	
	if ($DVDSize -lt 8.75) {
		$DVD = "DV10"
	}
	
	if ($DVDSize -lt 7.95) {
		$DVD = "DV9"
	}
	
	if ($DVDSize -lt 4.95) {
		$DVD = "DV4"
	}
	
	if ($DVDSize -lt 4.37) {
		$DVD = "DV5"
	}
	
	if ($DVDSize -lt 2.72) {
		$DVD = "DV3"
	}
	
	if ($DVDSize -lt 2.47) {
		$DVD = "DV2"
	}
	
	if ($DVDSize -lt 1.36) {
		$DVD = "DV1"
	}

  $DVDLabel = ($tag + '_CCSA_' + $arch + $ltag + $WIMInfo[1].DefaultLanguage + '_' + $DVD).ToUpper()
  if ($WIMInfo.header.ImageCount -eq 1) {
    if ($WIMInfo[1].EditionID -eq 'Core') { $DVDLabel = ($tag + '_CCRA_' + $arch + $ltag + $WIMInfo[1].DefaultLanguage + '_' + $DVD).ToUpper() }
    if ($WIMInfo[1].EditionID -eq 'CoreConnected') { $DVDLabel = ($tag + '_CCONA_' + $arch + $ltag + $WIMInfo[1].DefaultLanguage + '_' + $DVD).ToUpper() }
    if ($WIMInfo[1].EditionID -eq 'CoreConnectedCountrySpecific') { $DVDLabel = ($tag + '_CCCHA_' + $arch + $ltag + $WIMInfo[1].DefaultLanguage + '_' + $DVD).ToUpper() }
    if ($WIMInfo[1].EditionID -eq 'CoreConnectedN') { $DVDLabel = ($tag + '_CCONNA_' + $arch + $ltag + $WIMInfo[1].DefaultLanguage + '_' + $DVD).ToUpper() }
    if ($WIMInfo[1].EditionID -eq 'CoreConnectedSingleLanguage') { $DVDLabel = ($tag + '_CCSLA_' + $arch + $ltag + $WIMInfo[1].DefaultLanguage + '_' + $DVD).ToUpper() }
    if ($WIMInfo[1].EditionID -eq 'CoreCountrySpecific') { $DVDLabel = ($tag + '_CCHA_' + $arch + $ltag + $WIMInfo[1].DefaultLanguage + '_' + $DVD).ToUpper() }
    if ($WIMInfo[1].EditionID -eq 'CoreN') { $DVDLabel = ($tag + '_CCRNA_' + $arch + $ltag + $WIMInfo[1].DefaultLanguage + '_' + $DVD).ToUpper() }
    if ($WIMInfo[1].EditionID -eq 'CoreSingleLanguage') { $DVDLabel = ($tag + '_CSLA_' + $arch + $ltag + $WIMInfo[1].DefaultLanguage + '_' + $DVD).ToUpper() }
    if ($WIMInfo[1].EditionID -eq 'Professional') { $DVDLabel = ($tag + '_CPRA_' + $arch + $ltag + $WIMInfo[1].DefaultLanguage + '_' + $DVD).ToUpper() }
    if ($WIMInfo[1].EditionID -eq 'ProfessionalN') { $DVDLabel = ($tag + '_CPRNA_' + $arch + $ltag + $WIMInfo[1].DefaultLanguage + '_' + $DVD).ToUpper() }
    if ($WIMInfo[1].EditionID -eq 'ProfessionalStudent') { $DVDLabel = ($tag + '_CPRSA_' + $arch + $ltag + $WIMInfo[1].DefaultLanguage + '_' + $DVD).ToUpper() }
    if ($WIMInfo[1].EditionID -eq 'ProfessionalStudentN') { $DVDLabel = ($tag + '_CPRSNA_' + $arch + $ltag + $WIMInfo[1].DefaultLanguage + '_' + $DVD).ToUpper() }
    if ($WIMInfo[1].EditionID -eq 'ProfessionalWMC') { $DVDLabel = ($tag + '_CPWMCA_' + $arch + $ltag + $WIMInfo[1].DefaultLanguage + '_' + $DVD).ToUpper() }
    if ($WIMInfo[1].EditionID -eq 'Education') { $DVDLabel = ($tag + '_CEDA_' + $arch + $ltag + $WIMInfo[1].DefaultLanguage + '_' + $DVD).ToUpper() }
    if ($WIMInfo[1].EditionID -eq 'EducationN') { $DVDLabel = ($tag + '_CEDNA_' + $arch + $ltag + $WIMInfo[1].DefaultLanguage + '_' + $DVD).ToUpper() }
    if ($WIMInfo[1].EditionID -eq 'Enterprise') { $DVDLabel = ($tag + '_CENA_' + $arch + $ltag + $WIMInfo[1].DefaultLanguage + '_' + $DVD).ToUpper() }
    if ($WIMInfo[1].EditionID -eq 'EnterpriseN') { $DVDLabel = ($tag + '_CENNA_' + $arch + $ltag + $WIMInfo[1].DefaultLanguage + '_' + $DVD).ToUpper() }
    if ($WIMInfo[1].EditionID -eq 'EnterpriseS') { $DVDLabel = ($tag + '_CES_' + $arch + $ltag + $WIMInfo[1].DefaultLanguage + '_' + $DVD).ToUpper() }
    if ($WIMInfo[1].EditionID -eq 'EnterpriseSN') { $DVDLabel = ($tag + '_CESN_' + $arch + $ltag + $WIMInfo[1].DefaultLanguage + '_' + $DVD).ToUpper() }
	if ($WIMInfo[1].EditionID -eq 'PPIPro') { $DVDLabel = ($tag + '_CPPIA_' + $arch + $ltag + $WIMInfo[1].DefaultLanguage + '_' + $DVD).ToUpper() }
  }

  $result.VolumeLabel = $DVDLabel
  $result.BuildString = ($result.MajorVersion + '.' + $result.MinorVersion + '.' + $result.BuildNumber + '.' + $result.DeltaVersion + '.' + $result.BranchName + '.' + $result.CompileDate)
  $result.SetupPath = $PATH
  $wiminformations += $result

  $archs = @()
  ($wiminformations | select Architecture).Architecture | % {
    if (-not ($archs -contains $_.toLower())) {
      $archs += $_.toLower()
    }
  }
  $filename = $null
  foreach ($arch in $archs) {
    $currentesds1 = ($wiminformations | Where-Object { $_.Architecture.toLower() -eq $arch })
    $buildtypes = @()
    ($currentesds1 | select BuildType).BuildType | % {
      if (-not ($buildtypes -contains $_.toLower())) {
        $buildtypes += $_.toLower()
      }
    }
    foreach ($buildtype in $buildtypes) {
      $currentesds2 = ($currentesds1 | Where-Object { $_.BuildType.toLower() -eq $buildtype })
      $builds = @()
      ($currentesds2 | select BuildString).BuildString | % {
        if (-not ($builds -contains $_.toLower())) {
          $builds += $_.toLower()
        }
      }
      foreach ($build in $builds) {
        $currentesds3 = ($currentesds2 | Where-Object { $_.BuildString.toLower() -eq $build })
        $languages = @()
        ($currentesds3 | select LanguageCode).LanguageCode | % {
          if (-not ($languages -contains $_.toLower())) {
            $languages += $_.toLower()
          }
        }
        foreach ($language in $languages) {
          $currentesds4 = ($currentesds3 | Where-Object { $_.LanguageCode -eq $language })
          $Edition = $null
          $Licensing = $null
          ($currentesds4 | select Editions).Editions | % {
            if ($_ -is [System.Array]) {
              foreach ($item in $_) {
                if ($Edition -eq $null) {
                  $Edition_ = $item
                  if ($item -eq 'Core') { $Edition_ = 'CORE' }
                  if ($item -eq 'CoreN') { $Edition_ = 'COREN' }
                  if ($item -eq 'CoreSingleLanguage') { $Edition_ = 'SINGLELANGUAGE' }
                  if ($item -eq 'CoreCountrySpecific') { $Edition_ = 'CHINA' }
                  if ($item -eq 'Professional') { $Edition_ = 'PRO' }
                  if ($item -eq 'ProfessionalN') { $Edition_ = 'PRON' }
                  if ($item -eq 'ProfessionalWMC') { $Edition_ = 'PROWMC' }
                  if ($item -eq 'CoreConnected') { $Edition_ = 'CORECONNECTED' }
                  if ($item -eq 'CoreConnectedN') { $Edition_ = 'CORECONNECTEDN' }
                  if ($item -eq 'CoreConnectedSingleLanguage') { $Edition_ = 'CORECONNECTEDSINGLELANGUAGE' }
                  if ($item -eq 'CoreConnectedCountrySpecific') { $Edition_ = 'CORECONNECTEDCHINA' }
                  if ($item -eq 'ProfessionalStudent') { $Edition_ = 'PROSTUDENT' }
                  if ($item -eq 'ProfessionalStudentN') { $Edition_ = 'PROSTUDENTN' }
                  if ($item -eq 'Enterprise') { $Edition_ = 'ENTERPRISE' }
                  $Edition = $Edition_
                } else {
                  $Edition_ = $item_
                  if ($item -eq 'Core') { $Edition_ = 'CORE' }
                  if ($item -eq 'CoreN') { $Edition_ = 'COREN' }
                  if ($item -eq 'CoreSingleLanguage') { $Edition_ = 'SINGLELANGUAGE' }
                  if ($item -eq 'CoreCountrySpecific') { $Edition_ = 'CHINA' }
                  if ($item -eq 'Professional') { $Edition_ = 'PRO' }
                  if ($item -eq 'ProfessionalN') { $Edition_ = 'PRON' }
                  if ($item -eq 'ProfessionalWMC') { $Edition_ = 'PROWMC' }
                  if ($item -eq 'CoreConnected') { $Edition_ = 'CORECONNECTED' }
                  if ($item -eq 'CoreConnectedN') { $Edition_ = 'CORECONNECTEDN' }
                  if ($item -eq 'CoreConnectedSingleLanguage') { $Edition_ = 'CORECONNECTEDSINGLELANGUAGE' }
                  if ($item -eq 'CoreConnectedCountrySpecific') { $Edition_ = 'CORECONNECTEDCHINA' }
                  if ($item -eq 'ProfessionalStudent') { $Edition_ = 'PROSTUDENT' }
                  if ($item -eq 'ProfessionalStudentN') { $Edition_ = 'PROSTUDENTN' }
                  if ($item -eq 'Enterprise') { $Edition_ = 'ENTERPRISE' }
                  $Edition = $Edition + '-' + $Edition_
                }
              }
            } else {
              if ($Edition -eq $null) {
                $Edition_ = $_
                if ($_ -eq 'Core') { $Edition_ = 'CORE' }
                if ($_ -eq 'CoreN') { $Edition_ = 'COREN' }
                if ($_ -eq 'CoreSingleLanguage') { $Edition_ = 'SINGLELANGUAGE' }
                if ($_ -eq 'CoreCountrySpecific') { $Edition_ = 'CHINA' }
                if ($_ -eq 'Professional') { $Edition_ = 'PRO' }
                if ($_ -eq 'ProfessionalN') { $Edition_ = 'PRON' }
                if ($_ -eq 'ProfessionalWMC') { $Edition_ = 'PROWMC' }
                if ($_ -eq 'CoreConnected') { $Edition_ = 'CORECONNECTED' }
                if ($_ -eq 'CoreConnectedN') { $Edition_ = 'CORECONNECTEDN' }
                if ($_ -eq 'CoreConnectedSingleLanguage') { $Edition_ = 'CORECONNECTEDSINGLELANGUAGE' }
                if ($_ -eq 'CoreConnectedCountrySpecific') { $Edition_ = 'CORECONNECTEDCHINA' }
                if ($_ -eq 'ProfessionalStudent') { $Edition_ = 'PROSTUDENT' }
                if ($_ -eq 'ProfessionalStudentN') { $Edition_ = 'PROSTUDENTN' }
                if ($_ -eq 'Enterprise') { $Edition_ = 'ENTERPRISE' }
                $Edition = $Edition_
              } else {
                $Edition_ = $_
                if ($_ -eq 'Core') { $Edition_ = 'CORE' }
                if ($_ -eq 'CoreN') { $Edition_ = 'COREN' }
                if ($_ -eq 'CoreSingleLanguage') { $Edition_ = 'SINGLELANGUAGE' }
                if ($_ -eq 'CoreCountrySpecific') { $Edition_ = 'CHINA' }
                if ($_ -eq 'Professional') { $Edition_ = 'PRO' }
                if ($_ -eq 'ProfessionalN') { $Edition_ = 'PRON' }
                if ($_ -eq 'ProfessionalWMC') { $Edition_ = 'PROWMC' }
                if ($_ -eq 'CoreConnected') { $Edition_ = 'CORECONNECTED' }
                if ($_ -eq 'CoreConnectedN') { $Edition_ = 'CORECONNECTEDN' }
                if ($_ -eq 'CoreConnectedSingleLanguage') { $Edition_ = 'CORECONNECTEDSINGLELANGUAGE' }
                if ($_ -eq 'CoreConnectedCountrySpecific') { $Edition_ = 'CORECONNECTEDCHINA' }
                if ($_ -eq 'ProfessionalStudent') { $Edition_ = 'PROSTUDENT' }
                if ($_ -eq 'ProfessionalStudentN') { $Edition_ = 'PROSTUDENTN' }
                if ($_ -eq 'Enterprise') { $Edition_ = 'ENTERPRISE' }
                $Edition = $Edition + '-' + $Edition_
              }
            }
          }
          ($currentesds4 | select Licensing).Licensing | % {
            if ($Licensing -eq $null) {
              $Licensing = $_
            } else {
              if (-not ($Licensing -contains $_)) {
                $Licensing = $Licensing + $_
              }
            }
          }
          $Edition = $Edition.ToUpper() -replace 'SERVERHYPER','SERVERHYPERCORE' -replace 'SERVER',''
          $Licensing = $Licensing.ToUpper() -replace 'VOLUME','VOL' -replace 'RETAIL','RET'
          if ($Edition -eq 'PRO-CORE') {
            $Licensing = 'OEMRET'
          }
          if ($Edition.toLower() -eq 'unstaged') {
            $Edition = ''
          }
          $arch_ = $arch -replace 'amd64','x64'
          if ($currentesds4 -is [System.Array]) {
            $FILENAME_ = ($currentesds4[0].BuildNumber + '.' + $currentesds4[0].DeltaVersion + '.' + $currentesds4[0].CompileDate + '.' + $currentesds4[0].BranchName)
          } else {
            $FILENAME_ = ($currentesds4.BuildNumber + '.' + $currentesds4.DeltaVersion + '.' + $currentesds4.CompileDate + '.' + $currentesds4.BranchName)
          }
          $FILENAME_ = ($FILENAME_ + '_CLIENT' + $Edition + '_' + $Licensing + '_' + $arch_ + $buildtype + '_' + $language).ToUpper()
          if ($filename -eq $null) {
            $filename = $FILENAME_
          } else {
            $filename = $filename + '-' + $FILENAME_
          }
          $parts += 1
        }
      }
    }
  }

  $tag = 'ir3'
  $DVD = 'DV9'
  if ($wiminformations[0].Architecture -eq 'x86') {
    $arch = 'x86'
  }
  if ($wiminformations[0].Architecture -eq 'x86_64') {
    $arch = 'x64'
  }
  if ([int]$wiminformations[0].DeltaVersion -eq '17056') {
    $tag = 'ir4'
  }
  if ([int]$wiminformations[0].DeltaVersion -eq '17415') {
    $tag = 'ir5'
  }
  if ([int]$wiminformations[0].DeltaVersion -gt '17415') {
    $tag = 'ir6'
  }
  if ([int]$wiminformations[0].BuildNumber -gt '9600') {
    $tag = 'JM1'
    $DVD = 'DV5'
  }
  if ([int]$wiminformations[0].BuildNumber -ge '9896') {
    $tag = 'J'
    $DVD = 'DV5'
  }
  if ($wiminformations[0].Licensing.toLower() -eq 'volume') {
    $ltag = 'FREV_'
  } elseif ($wiminformations[0].Licensing.toLower() -eq 'oem') {
    $ltag = 'FREO_'
  } else {
    $ltag = 'FRE_'
  }

  $result.filename = ($filename + '.ISO').ToUpper()

  if ($wiminformations.Count -eq 1) {
    $DVDLabel = $wiminformations[0].VolumeLabel
  } elseif ($wiminformations.Count -eq 2 -and $wiminformations[0].Editions -eq "Professional" -and $wiminformations[1].Editions -eq "Core" -and $parts -eq 1) {
    $DVDLabel = ($tag + '_CCSA_' + $arch + $ltag + $wiminformations[0].LanguageCode + '_' + $DVD).ToUpper()
  } else {
    $DVDLabel = "ESD-ISO"
  }
  
  $result.VolumeLabel = $DVDLabel
  
  Write-Host 'Gathering Timestamp information from the Setup Media...'
  $result.timestamp = (Get-ChildItem $Path\setup.exe | % {[System.TimeZoneInfo]::ConvertTimeToUtc($_.LastWriteTime).ToString("MM/dd/yyyy,HH:mm:ss")})

  return $wiminformations
}

$results = Get-InfosFromSetupPath $SourcePath

$results

$title = "Does everything checks out?"
$message = "Answering Yes will start building the iso, no will quit the script."
$yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", "Yes"
$no = New-Object System.Management.Automation.Host.ChoiceDescription "&No", "No"
$options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)
$choice=$host.ui.PromptForChoice($title, $message, $options, 1)

if ($choice -eq 0) {
	Write-Host 'Generating ISO...'
	$BootData="2#p0,e,b$($SourcePath)\boot\etfsboot.com#pEF,e,b$($SourcePath)\efi\Microsoft\boot\efisys.bin"
	& "cmd" "/c" "$($ScriptDir)\cdimage.exe" "-bootdata:$BootData" "-o" "-h" "-m" "-u2" "-udfver102" "-t$($results.timestamp)" "-l$($results.VolumeLabel)" "$($SourcePath)\" """$($Destination)\$($results.FileName)"""
}