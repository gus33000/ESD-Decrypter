<#
	Location of the required binaries for this script
#>
$Global:toolpath = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
$Global:cdimage253 = "$($toolpath)\cdimage\2.53\cdimage.exe"
$Global:decryptesd = "$($toolpath)\decryptesd\decryptesd.exe"
$Global:7z = "$($toolpath)\7z\7z.exe"

$langcodes = @{}
[globalization.cultureinfo]::GetCultures("allCultures") | select name,DisplayName | ForEach-Object {
	$langcodes[$_.DisplayName] = $_.Name
}
$langcodes['Spanish (Spain, Traditional Sort)'] = 'es-ES_tradnl'
$langcodes['Chinese (Simplified, China)'] = 'zh-CHS'
$langcodes['Norwegian Bokm�l (Norway)'] = 'nb-NO'

function Test-Arch ($FilePath) {
  [int32]$MACHINE_OFFSET = 4
  [int32]$PE_POINTER_OFFSET = 60

  [byte[]]$data = New-Object -TypeName System.Byte[] -ArgumentList 4096
  $stream = New-Object -TypeName System.IO.FileStream -ArgumentList ($FilePath,'Open','Read')
  $stream.Read($data,0,4096) | Out-Null

  [int32]$PE_HEADER_ADDR = [System.BitConverter]::ToInt32($data,$PE_POINTER_OFFSET)
  [int32]$machineUint = [System.BitConverter]::ToUInt16($data,$PE_HEADER_ADDR + $MACHINE_OFFSET)

  $result = "" | select FilePath,FileType
  $result.FilePath = $FilePath

  $stream.Close()

  switch ($machineUint)
  {
    0 { $result.FileType = 'native' }
    0x1d3 { $result.FileType = 'am33' }
    0x8664 { $result.FileType = 'amd64' }
    0x1c0 { $result.FileType = 'arm' }
    0xaa64 { $result.FileType = 'arm64' }
    0x1c4 { $result.FileType = 'armnt' }
    0xebc { $result.FileType = 'ebc' }
    0x14c { $result.FileType = 'x86' }
    0x200 { $result.FileType = 'ia64' }
    0x9041 { $result.FileType = 'm32r' }
    0x266 { $result.FileType = 'mips16' }
    0x366 { $result.FileType = 'mipsfpu' }
    0x466 { $result.FileType = 'mipsfpu16' }
    0x1f0 { $result.FileType = 'powerpc' }
    0x1f1 { $result.FileType = 'powerpcfp' }
    0x166 { $result.FileType = 'r4000' }
    0x1a2 { $result.FileType = 'sh3' }
    0x1a3 { $result.FileType = 'sh3dsp' }
    0x1a6 { $result.FileType = 'sh4' }
    0x1a8 { $result.FileType = 'sh5' }
    0x1c2 { $result.FileType = 'thumb' }
    0x169 { $result.FileType = 'wcemipsv2' }
  }

  $result
}

function get-inicontent {
  <#  
    .Synopsis  
        Gets the content of an INI file  
          
    .Description  
        Gets the content of an INI file and returns it as a hashtable  
          
    .Notes  
        Author        : Oliver Lipkau <oliver@lipkau.net>  
        Blog        : http://oliver.lipkau.net/blog/  
        Source        : https://github.com/lipkau/PsIni 
                      http://gallery.technet.microsoft.com/scriptcenter/ea40c1ef-c856-434b-b8fb-ebd7a76e8d91 
        Version        : 1.0 - 2010/03/12 - Initial release  
                      1.1 - 2014/12/11 - Typo (Thx SLDR) 
                                         Typo (Thx Dave Stiff) 
          
        #Requires -Version 2.0  
          
    .Inputs  
        System.String  
          
    .Outputs  
        System.Collections.Hashtable  
          
    .Parameter FilePath  
        Specifies the path to the input file.  
          
    .Example  
        $FileContent = Get-IniContent "C:\myinifile.ini"  
        -----------  
        Description  
        Saves the content of the c:\myinifile.ini in a hashtable called $FileContent  
      
    .Example  
        $inifilepath | $FileContent = Get-IniContent  
        -----------  
        Description  
        Gets the content of the ini file passed through the pipe into a hashtable called $FileContent  
      
    .Example  
        C:\PS>$FileContent = Get-IniContent "c:\settings.ini"  
        C:\PS>$FileContent["Section"]["Key"]  
        -----------  
        Description  
        Returns the key "Key" of the section "Section" from the C:\settings.ini file  
          
    .Link  
        Out-IniFile  
    #>

  [CmdletBinding()]
  param(
    [ValidateNotNullOrEmpty()]
    [ValidateScript({ (Test-Path $_) })]
    [Parameter(ValueFromPipeline = $True,Mandatory = $True)]
    [string]$FilePath
  )

  begin
  { Write-Verbose "$($MyInvocation.MyCommand.Name):: Function started" }

  process
  {
    Write-Verbose "$($MyInvocation.MyCommand.Name):: Processing file: $Filepath"

    $ini = @{}
    switch -regex -File $FilePath
    {
      "^\[(.+)\]$" # Section  
      {
        $section = $matches[1]
        if ($ini[$section] -eq $null) {
          $ini[$section] = @{}
        }
        $CommentCount = 0
      }
      "^(;.*)$" # Comment  
      {
        if (!($section))
        {
          $section = "No-Section"
          if ($ini[$section] -eq $null) {
            $ini[$section] = @{}
          }
        }
        $value = $matches[1]
        $CommentCount = $CommentCount + 1
        $name = "Comment" + $CommentCount
        $ini[$section][$name] = $value
      }
      "(.+?)\s*=\s*(.*)" # Key  
      {
        if (!($section))
        {
          $section = "No-Section"
          $ini[$section] = @{}
        }
        $name,$value = $matches[1..2]
        $ini[$section][$name] = $value
      }
    }
    Write-Verbose "$($MyInvocation.MyCommand.Name):: Finished Processing file: $FilePath"
    return $ini
  }

  end
  { Write-Verbose "$($MyInvocation.MyCommand.Name):: Function ended" }
}

function Remove-InvalidFileNameChars {
  param(
    [Parameter(Mandatory = $true,
      Position = 0,
      ValueFromPipeline = $true,
      ValueFromPipelineByPropertyName = $true)]
    [string]$Name
  )

  $invalidChars = [IO.Path]::GetInvalidFileNameChars() -join ''
  $re = "[{0}]" -f [regex]::Escape($invalidChars)
  return ($Name -replace $re)
}

function Test-Wow64 {
  return (Test-Win32) -and (Test-Path env:\PROCESSOR_ARCHITEW6432)
}

function Test-Win64 {
  return [intptr]::size -eq 8
}

function Test-Win32 {
  return [intptr]::size -eq 4
}

if (Test-Wow64) {
  $Global:wimlib = "$($toolpath)\wimlib\bin86\wimlib-imagex.exe"
} elseif (Test-Win64) {
  $Global:wimlib = "$($toolpath)\wimlib\bin64\wimlib-imagex.exe"
} elseif (Test-Win32) {
  $Global:wimlib = "$($toolpath)\wimlib\bin86\wimlib-imagex.exe"
} else {
  Write-Host -ForegroundColor red "[$((Get-Date).ToString('MM/dd/yyyy hh:mm:ss tt'))] [Error] Current processor architecture is unsupported. This cmdlet only supports x86 and x64 processor architectures."
  return $false
}

function ValidateEnv () {
  if (-not (Test-Path $cdimage253)) {
    Write-Host -ForegroundColor red "[$((Get-Date).ToString('MM/dd/yyyy hh:mm:ss tt'))] [Error] We couldn't find the cdimage 2.53 utility under the tool path. Aborting execution."
    return $false
  }

  if (-not (Test-Path $decryptesd)) {
    Write-Host -ForegroundColor red "[$((Get-Date).ToString('MM/dd/yyyy hh:mm:ss tt'))] [Error] We couldn't find the decryptesd utility under the tool path. Aborting execution."
    return $false
  }

  if (-not (Test-Path $7z)) {
    Write-Host -ForegroundColor red "[$((Get-Date).ToString('MM/dd/yyyy hh:mm:ss tt'))] [Error] We couldn't find the 7-Zip utility under the tool path. Aborting execution."
    return $false
  }

  if (-not (Test-Path $wimlib)) {
    Write-Host -ForegroundColor red "[$((Get-Date).ToString('MM/dd/yyyy hh:mm:ss tt'))] [Error] We couldn't find the wimlib imagex utility under the tool path. Aborting execution."
    return $false
  }
  return $true
}
if (-not (Test-Path "$(Split-Path -Parent -Path $MyInvocation.MyCommand.Definition)\tmp\")) {
    New-Item -Path "$(Split-Path -Parent -Path $MyInvocation.MyCommand.Definition)\tmp\" -ItemType "directory" | Out-Null
}
$TempDirectory = "$(Split-Path -Parent -Path $MyInvocation.MyCommand.Definition)\tmp\"

if (-not (ValidateEnv)) {
  return $false
}

$IdentifyResult = "" | select `
    MajorVersion, `
    MinorVersion, `
    BuildNumber, `
    DeltaVersion, `
    BranchName, `
    CompileDate, `
    Tag, `
    Architecture, `
    BuildType, `
    Type, `
    Sku, `
    Editions, `
    Licensing, `
    LanguageCode, `
    VolumeLabel, `
    BuildString, `
    SetupPath

function Identify-CabinetEarly1994($SetupPath) {
    $IdentifyResult = "" | select `
        MajorVersion, `
        MinorVersion, `
        BuildNumber, `
        DeltaVersion, `
        BranchName, `
        CompileDate, `
        Tag, `
        Architecture, `
        BuildType, `
        Type, `
        Sku, `
        Editions, `
        Licensing, `
        LanguageCode, `
        VolumeLabel, `
        BuildString, `
        SetupPath

    $tmpResult = $IdentifyResult
    $cab = (Get-ChildItem $SetupPath\*CHICO*.CAB)[1]

    $tmpresult.Type = @('Client')
    if ((Get-ChildItem ($cab.directory.fullname + '\USER.EXE') -Recurse) -ne $null) {
      $tmpresult.BuildType = 'chk'
    } else {
      $tmpresult.BuildType = 'fre'
    }
    & $7z e $cab user.exe | Out-Null
    $tmpresult.MajorVersion = ((Get-Item .\user.exe).VersionInfo.ProductVersion).split('.')[0]
    $tmpresult.MinorVersion = ((Get-Item .\user.exe).VersionInfo.ProductVersion).split('.')[1]
    $tmpresult.BuildNumber = ((Get-Item .\user.exe).VersionInfo.ProductVersion).split('.')[2]
    # !!!!!!!! HARD CODED - Todo: fix this properly with an automatic detection !!!!!!!
    $tmpresult.Architecture = 'x86'
    $tmpresult.LanguageCode = $langcodes[(Get-Item .\user.exe).VersionInfo.Language]
    Remove-Item -Force .\user.exe


    # Hotfix for a MS derping on the 347 Spanish version of Windows 95, the OS is technically 347, but for some reason, 
    # kernel386, gdi, and user are reporting 346 as the build number. While win32 components, (kernel32, gdi32, user32)
    # reports 347, as it should be. If you have any doubt, you can find this 347 spanish build on the multilang dvd of 347.
    if (($tmpresult.LanguageCode -eq 'es-ES_tradnl') -and ($tmpresult.BuildNumber -eq '346')) {
      $tmpresult.BuildNumber = '347'
    }

    if ($tmpresult.BuildNumber -eq '950') {
      & $7z e $cab kernel32.dll | Out-Null
      $tmpresult.MajorVersion = ((Get-Item .\kernel32.dll).VersionInfo.ProductVersion).split('.')[0]
      $tmpresult.MinorVersion = ((Get-Item .\kernel32.dll).VersionInfo.ProductVersion).split('.')[1]
      $tmpresult.BuildNumber = ((Get-Item .\kernel32.dll).VersionInfo.ProductVersion).split('.')[2]
      Remove-Item -Force .\kernel32.dll
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
                $tmpresult.DeltaVersion = $item.Substring(1)
              } elseif (($item.Length -eq 1) -and (-not ($item -match "[0-9]"))) {
                $tmpresult.BuildNumber = ($tmpresult.BuildNumber + $item)
              } else {
                if ($tmpresult.Tag -eq $null) {
                  $tmpresult.Tag = $item
                } else {
                  $tmpresult.Tag = ($tmpresult.Tag + '_' + $item)
                }
              }
            }
          }
        }
      }
    } else {
        if (Test-Path ($cab.directory.fullname+'\PRECOPY.CAB')) {
            & $7z e ($cab.directory.fullname+'\PRECOPY.CAB') SETUPPP.INF | Out-Null
        } else {
            & $7z e ($cab.directory.fullname+'\PRECOPY1.CAB') SETUPPP.INF | Out-Null
        }
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
                  $tmpresult.DeltaVersion = $item.Substring(1)
                } elseif (($item.Length -eq 1) -and (-not ($item -match "[0-9]"))) {
                  $tmpresult.BuildNumber = ($tmpresult.BuildNumber + $item)
                } else {
                  if ($tmpresult.Tag -eq $null) {
                    $tmpresult.Tag = $item
                  } else {
                    $tmpresult.Tag = ($tmpresult.Tag + '_' + $item)
                  }
                }
              }
            }
          }
        }
      }
      Remove-Item -Force '.\SETUPPP.INF'
    }

    return $tmpResult
}

function Identify-CabinetFall1994($SetupPath) {
    $IdentifyResult = "" | select `
        MajorVersion, `
        MinorVersion, `
        BuildNumber, `
        DeltaVersion, `
        BranchName, `
        CompileDate, `
        Tag, `
        Architecture, `
        BuildType, `
        Type, `
        Sku, `
        Editions, `
        Licensing, `
        LanguageCode, `
        VolumeLabel, `
        BuildString, `
        SetupPath

    $tmpResult = $IdentifyResult
    $cab = (Get-ChildItem $SetupPath\*WIN*.CAB)[1]

    $tmpresult.Type = @('Client')
    if ((Get-ChildItem ($cab.directory.fullname + '\USER.EXE') -Recurse) -ne $null) {
      $tmpresult.BuildType = 'chk'
    } else {
      $tmpresult.BuildType = 'fre'
    }
    & $7z e $cab user.exe | Out-Null
    $tmpresult.MajorVersion = ((Get-Item .\user.exe).VersionInfo.ProductVersion).split('.')[0]
    $tmpresult.MinorVersion = ((Get-Item .\user.exe).VersionInfo.ProductVersion).split('.')[1]
    $tmpresult.BuildNumber = ((Get-Item .\user.exe).VersionInfo.ProductVersion).split('.')[2]
    # !!!!!!!! HARD CODED - Todo: fix this properly with an automatic detection !!!!!!!
    $tmpresult.Architecture = 'x86'
    $tmpresult.LanguageCode = $langcodes[(Get-Item .\user.exe).VersionInfo.Language]
    Remove-Item -Force .\user.exe


    # Hotfix for a MS derping on the 347 Spanish version of Windows 95, the OS is technically 347, but for some reason, 
    # kernel386, gdi, and user are reporting 346 as the build number. While win32 components, (kernel32, gdi32, user32)
    # reports 347, as it should be. If you have any doubt, you can find this 347 spanish build on the multilang dvd of 347.
    if (($tmpresult.LanguageCode -eq 'es-ES_tradnl') -and ($tmpresult.BuildNumber -eq '346')) {
      $tmpresult.BuildNumber = '347'
    }

    if ($tmpresult.BuildNumber -eq '950') {
      & $7z e $cab kernel32.dll | Out-Null
      $tmpresult.MajorVersion = ((Get-Item .\kernel32.dll).VersionInfo.ProductVersion).split('.')[0]
      $tmpresult.MinorVersion = ((Get-Item .\kernel32.dll).VersionInfo.ProductVersion).split('.')[1]
      $tmpresult.BuildNumber = ((Get-Item .\kernel32.dll).VersionInfo.ProductVersion).split('.')[2]
      Remove-Item -Force .\kernel32.dll
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
                $tmpresult.DeltaVersion = $item.Substring(1)
              } elseif (($item.Length -eq 1) -and (-not ($item -match "[0-9]"))) {
                $tmpresult.BuildNumber = ($tmpresult.BuildNumber + $item)
              } else {
                if ($tmpresult.Tag -eq $null) {
                  $tmpresult.Tag = $item
                } else {
                  $tmpresult.Tag = ($tmpresult.Tag + '_' + $item)
                }
              }
            }
          }
        }
      }
    } else {
      if (Test-Path ($cab.directory.fullname+'\PRECOPY.CAB')) {
            & $7z e ($cab.directory.fullname+'\PRECOPY.CAB') SETUPPP.INF | Out-Null
        } else {
            & $7z e ($cab.directory.fullname+'\PRECOPY1.CAB') SETUPPP.INF | Out-Null
        }
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
                  $tmpresult.DeltaVersion = $item.Substring(1)
                } elseif (($item.Length -eq 1) -and (-not ($item -match "[0-9]"))) {
                  $tmpresult.BuildNumber = ($tmpresult.BuildNumber + $item)
                } else {
                  if ($tmpresult.Tag -eq $null) {
                    $tmpresult.Tag = $item
                  } else {
                    $tmpresult.Tag = ($tmpresult.Tag + '_' + $item)
                  }
                }
              }
            }
          }
        }
      }
      Remove-Item -Force '.\SETUPPP.INF'
    }

    return $tmpResult
}

function Identify-TextSetup($SetupPath, $Variant) {
    $IdentifyResult = "" | select `
        MajorVersion, `
        MinorVersion, `
        BuildNumber, `
        DeltaVersion, `
        BranchName, `
        CompileDate, `
        Tag, `
        Architecture, `
        BuildType, `
        Type, `
        Sku, `
        Editions, `
        Licensing, `
        LanguageCode, `
        VolumeLabel, `
        BuildString, `
        SetupPath

    $tmpResult = $IdentifyResult

    # Gathering Compiledate and the buildbranch from the main setup.exe executable.
    $NoExtended = $false

    if (Test-Path $SetupPath\$Variant\ntoskrnl.ex_) {
        & $7z e $SetupPath\$Variant\ntoskrnl.ex_ *.exe -r | Out-Null
        if (((Get-Item .\ntoskrnl.exe).VersionInfo.FileVersion) -like '*built by:*') {
            $tmpresult.CompileDate = (Get-Item .\ntoskrnl.exe).VersionInfo.FileVersion.split(':')[-1].replace(' ','')
            $tmpresult.BranchName = (Get-Item .\ntoskrnl.exe).VersionInfo.FileVersion.split(':')[-2].replace(' at','').replace(' ','')
        } elseif (((Get-Item .\ntoskrnl.exe).VersionInfo.FileVersion) -like '*.*.*.*(*)*') {
            $tmpresult.CompileDate = (Get-Item .\ntoskrnl.exe).VersionInfo.FileVersion.split(' ')[1].split('.')[1].replace(')','')
            $tmpresult.BranchName = (Get-Item .\ntoskrnl.exe).VersionInfo.FileVersion.split(' ')[1].split('.')[0].Substring(1)
        } else {
            $NoExtended = $true
        }

        if ((Get-Item .\ntoskrnl.exe).VersionInfo.IsDebug) {
            $tmpresult.BuildType = 'chk'
        } else {
            $tmpresult.BuildType = 'fre'
        }
        $tmpresult.Architecture = (Test-Arch '.\ntoskrnl.exe').FileType
        if ($Variant.toLower() -eq 'alpha') {
            $tmpresult.Architecture = 'axp'
        }

        if ($NoExtended) {
            $buildno = (Get-Item .\ntoskrnl.exe).VersionInfo.FileVersion
        } else {
            $buildno = (Get-Item .\ntoskrnl.exe).VersionInfo.ProductVersion
        }

        if (-not ($buildno -like '*.*.*.*')) {
            & $7z e .\ntoskrnl.exe .rsrc\version.txt | Out-Null
            $buildno = Remove-InvalidFileNameChars (Get-Content '.\version.txt' -First 1).split(' ')[-1].replace(',','.')
            Remove-Item '.\version.txt' -Force
        }

        Remove-Item '.\ntoskrnl.exe' -Force
    } elseif (Test-Path $SetupPath\$Variant\ntoskrnl.exe) {
        if (((Get-Item $SetupPath\$Variant\ntoskrnl.exe).VersionInfo.FileVersion) -like '*built by:*') {
            $tmpresult.CompileDate = (Get-Item $SetupPath\$Variant\ntoskrnl.exe).VersionInfo.FileVersion.split(':')[-1].replace(' ','')
            $tmpresult.BranchName = (Get-Item $SetupPath\$Variant\ntoskrnl.exe).VersionInfo.FileVersion.split(':')[-2].replace(' at','').replace(' ','')
        } elseif (((Get-Item $SetupPath\$Variant\ntoskrnl.exe).VersionInfo.FileVersion) -like '*.*.*.*(*)*') {
            $tmpresult.CompileDate = (Get-Item $SetupPath\$Variant\ntoskrnl.exe).VersionInfo.FileVersion.split(' ')[1].split('.')[1].replace(')','')
            $tmpresult.BranchName = (Get-Item $SetupPath\$Variant\ntoskrnl.exe).VersionInfo.FileVersion.split(' ')[1].split('.')[0].Substring(1)
        } else {
            $NoExtended = $true
        }

        if ((Get-Item $SetupPath\$Variant\ntoskrnl.exe).VersionInfo.IsDebug) {
            $tmpresult.BuildType = 'chk'
        } else {
            $tmpresult.BuildType = 'fre'
        }
        $tmpresult.Architecture = (Test-Arch $SetupPath\$Variant\NTKRNLMP.EXE).FileType
        if ($Variant.toLower() -eq 'alpha') {
            $tmpresult.Architecture = 'axp'
        }

        if ($NoExtended) {
            $buildno = (Get-Item $SetupPath\$Variant\ntoskrnl.exe).VersionInfo.FileVersion
        } else {
            $buildno = (Get-Item $SetupPath\$Variant\ntoskrnl.exe).VersionInfo.ProductVersion
        }

        if (-not ($buildno -like '*.*.*.*')) {
            & $7z e $SetupPath\$Variant\ntoskrnl.exe .rsrc\version.txt | Out-Null
            $buildno = Remove-InvalidFileNameChars (Get-Content '.\version.txt' -First 1).split(' ')[-1].replace(',','.')
            Remove-Item '.\version.txt' -Force
        }
    } elseif (Test-Path $SetupPath\$Variant\NTKRNLMP.EX_) {
        & $7z e $SetupPath\$Variant\NTKRNLMP.EX_ *.exe -r | Out-Null
        if (((Get-Item .\NTKRNLMP.exe).VersionInfo.FileVersion) -like '*built by:*') {
            $tmpresult.CompileDate = (Get-Item .\NTKRNLMP.EXE).VersionInfo.FileVersion.split(':')[-1].replace(' ','')
            $tmpresult.BranchName = (Get-Item .\NTKRNLMP.EXE).VersionInfo.FileVersion.split(':')[-2].replace(' at','').replace(' ','')
        } elseif (((Get-Item .\NTKRNLMP.exe).VersionInfo.FileVersion) -like '*.*.*.*(*)*') {
            $tmpresult.CompileDate = (Get-Item .\NTKRNLMP.EXE).VersionInfo.FileVersion.split(' ')[1].split('.')[1].replace(')','')
            $tmpresult.BranchName = (Get-Item .\NTKRNLMP.EXE).VersionInfo.FileVersion.split(' ')[1].split('.')[0].Substring(1)
        } else {
            $NoExtended = $true
        }

        if ((Get-Item .\NTKRNLMP.EXE).VersionInfo.IsDebug) {
            $tmpresult.BuildType = 'chk'
        } else {
            $tmpresult.BuildType = 'fre'
        }
        $tmpresult.Architecture = (Test-Arch '.\NTKRNLMP.EXE').FileType
        if ($Variant.toLower() -eq 'alpha') {
            $tmpresult.Architecture = 'axp'
        }

        if ($NoExtended) {
            $buildno = (Get-Item .\NTKRNLMP.EXE).VersionInfo.FileVersion
        } else {
            $buildno = (Get-Item .\NTKRNLMP.EXE).VersionInfo.ProductVersion
        }

        if (-not ($buildno -like '*.*.*.*')) {
            & $7z e .\NTKRNLMP.EXE .rsrc\version.txt | Out-Null
            $buildno = Remove-InvalidFileNameChars (Get-Content '.\version.txt' -First 1).split(' ')[-1].replace(',','.')
            Remove-Item '.\version.txt' -Force
        }

        Remove-Item '.\NTKRNLMP.EXE' -Force
    } else {
        if (((Get-Item $SetupPath\$Variant\NTKRNLMP.EXE).VersionInfo.FileVersion) -like '*built by:*') {
            $tmpresult.CompileDate = (Get-Item $SetupPath\$Variant\NTKRNLMP.EXE).VersionInfo.FileVersion.split(':')[-1].replace(' ','')
            $tmpresult.BranchName = (Get-Item $SetupPath\$Variant\NTKRNLMP.EXE).VersionInfo.FileVersion.split(':')[-2].replace(' at','').replace(' ','')
        } elseif (((Get-Item $SetupPath\$Variant\NTKRNLMP.EXE).VersionInfo.FileVersion) -like '*.*.*.*(*)*') {
            $tmpresult.CompileDate = (Get-Item $SetupPath\$Variant\NTKRNLMP.EXE).VersionInfo.FileVersion.split(' ')[1].split('.')[1].replace(')','')
            $tmpresult.BranchName = (Get-Item $SetupPath\$Variant\NTKRNLMP.EXE).VersionInfo.FileVersion.split(' ')[1].split('.')[0].Substring(1)
        } else {
            $NoExtended = $true
        }

        if ((Get-Item $SetupPath\$Variant\NTKRNLMP.EXE).VersionInfo.IsDebug) {
            $tmpresult.BuildType = 'chk'
        } else {
            $tmpresult.BuildType = 'fre'
        }
        $tmpresult.Architecture = (Test-Arch $SetupPath\$Variant\NTKRNLMP.EXE).FileType
        if ($Variant.toLower() -eq 'alpha') {
            $tmpresult.Architecture = 'axp'
        }

        if ($NoExtended) {
            $buildno = (Get-Item $SetupPath\$Variant\NTKRNLMP.EXE).VersionInfo.FileVersion
        } else {
            $buildno = (Get-Item $SetupPath\$Variant\NTKRNLMP.EXE).VersionInfo.ProductVersion
        }

        if (-not ($buildno -like '*.*.*.*')) {
            & $7z e $SetupPath\$Variant\NTKRNLMP.EXE .rsrc\version.txt | Out-Null
            $buildno = Remove-InvalidFileNameChars (Get-Content '.\version.txt' -First 1).split(' ')[-1].replace(',','.')
            Remove-Item '.\version.txt' -Force
        }
    }

    $tmpresult.MajorVersion = $buildno.split('.')[0]
    $tmpresult.MinorVersion = $buildno.split('.')[1]
    $tmpresult.BuildNumber = $buildno.split('.')[2]
    $tmpresult.DeltaVersion = $buildno.split('.')[3]

    $cdtag = (get-inicontent $SetupPath\$Variant\txtsetup.sif)["SourceDisksNames"]["_x"].split(',')[1]
    if ($cdtag -eq '%cdtagfile%') {
        $editionletter = (get-inicontent $SetupPath\$Variant\txtsetup.sif)["Strings"]["cdtagfile"].toLower().replace('"','')
    } else {
        $editionletter = $cdtag.toLower().replace('"','')
    }

    $editionletter = $editionletter.replace('cdrom.','')
    $editionletter_ = $editionletter.split('.')[0][-2]
    $editionletter = $editionletter.split('.')[0][-1]

    if ($editionletter -eq 'p') {
        $tmpresult.Sku = 'Professional'
    } elseif ($editionletter -eq 'c') {
        $tmpresult.Sku = 'Home'
    } elseif ($editionletter -eq 'w') {
        $tmpresult.Sku = 'Workstation'
    } elseif ($editionletter -eq 'b') {
        $tmpresult.Sku = 'WebServer'
    } elseif ($editionletter -eq 's') {
        $tmpresult.Sku = 'StandardServer'
        if ($editionletter_ -eq 't') {
            $tmpresult.Sku = 'TerminalServer'
        }
    } elseif ($editionletter -eq 'a') {
        if ($buildno.split('.')[2] -le 2202) {
            $tmpresult.Sku = 'AdvancedServer'
        } else {
            $tmpresult.Sku = 'EnterpriseServer'
        }
    } elseif ($editionletter -eq 'l') {
        $tmpresult.Sku = 'SmallbusinessServer'
    } elseif ($editionletter -eq 'd') {
        $tmpresult.Sku = 'DatacenterServer'
    }

    if ($tmpResult.Sku -ne $null) {
        $tmpResult.Editions = @($tmpResult.Sku)
    }

    $typename = @()
    foreach ($sku in $tmpResult.Editions) {
        if ($sku -is [Array]) {
            foreach ($edition in $sku) {
                if (($edition.toLower() -like '*server*v') -and ($edition.toLower() -notlike '*server*hyperv')) {
                    if ($typename -notcontains "ServerV") {
                        $typename += "ServerV"
                    }
                } elseif ($edition.toLower() -like '*server*') {
                    if ($typename -notcontains "Server") {
                        $typename += "Server"
                    }
                } else {
                    if ($typename -notcontains "Client") {
                        $typename += "Client"
                    }
                }
            }
        } else {
            if (($sku.toLower() -like '*server*v') -and ($sku.toLower() -notlike '*server*hyperv')) {
                if ($typename -notcontains "ServerV") {
                    $typename += "ServerV"
                }
            } elseif ($sku.toLower() -like '*server*') {
                if ($typename -notcontains "Server") {
                    $typename += "Server"
                }
            } else {
                if ($typename -notcontains "Client") {
                    $typename += "Client"
                }
            }
        }
    }

    $counter = -1
    foreach ($item in $tmpResult.Editions) {
        $counter++
        if ($tmpResult.Editions[$counter] -eq 'ads') {
            $tmpResult.Editions[$counter] = "AdvancedServer"
        } elseif ($tmpResult.Editions[$counter] -eq 'pro') {
            $tmpResult.Editions[$counter] = "Professional"
        }
    }
    if ($tmpResult.sku -eq 'ads') {
        $tmpResult.sku = "AdvancedServer"
    } elseif ($tmpResult.sku -eq 'pro') {
        $tmpResult.sku = "Professional"
    }

    $tmpResult.Type += $typename

    $langid = '0x' + (get-inicontent $SetupPath\$Variant\TXTSETUP.SIF)["nls"]["DefaultLayout"]

    $langid = $langid.replace('E001','')

    $tmpresult.LanguageCode = [System.Globalization.Cultureinfo]::GetCultureInfo([int32]$langid).Name

    $tmpresult.Licensing = 'Retail'

    if (($tmpresult.BranchName -eq '') -or ($tmpresult.BranchName -eq $null)) {
        $tmpResult.BuildString = ($tmpResult.MajorVersion + '.' + $tmpResult.MinorVersion + '.' + $tmpResult.BuildNumber + '.' + $tmpResult.DeltaVersion)
    } else {
        $tmpResult.BuildString = ($tmpResult.MajorVersion + '.' + $tmpResult.MinorVersion + '.' + $tmpResult.BuildNumber + '.' + $tmpResult.DeltaVersion + '.' + $tmpResult.BranchName + '.' + $tmpResult.CompileDate)
    }

    $tmpResult.SetupPath = $SetupPath

    return $tmpResult
}

function Identify-WIMLate2002($SetupPath) {
    $IdentifyResult = "" | select `
        MajorVersion, `
        MinorVersion, `
        BuildNumber, `
        DeltaVersion, `
        BranchName, `
        CompileDate, `
        Tag, `
        Architecture, `
        BuildType, `
        Type, `
        Sku, `
        Editions, `
        Licensing, `
        LanguageCode, `
        VolumeLabel, `
        BuildString, `
        SetupPath
    
    $tmpResult = $IdentifyResult

    $buildno = (Get-Item $setuppath\setup.exe).VersionInfo.ProductVersion

    $tmpResult.MajorVersion = $buildno.split('.')[0]
    $tmpResult.MinorVersion = $buildno.split('.')[1]
    $tmpResult.BuildNumber = $buildno.split('.')[2]
    $tmpResult.DeltaVersion = $buildno.split('.')[3]

    $tmpResult.CompileDate = (Get-Item $SetupPath\setup.exe).VersionInfo.FileVersion.split(' ')[1].split('.')[1].replace(')','')
    $tmpResult.BranchName = (Get-Item $SetupPath\setup.exe).VersionInfo.FileVersion.split(' ')[1].split('.')[0].Substring(1)

    $files = (Get-ChildItem $setuppath\* | Where-Object { -not ([System.IO.Path]::hasExtension($_.fullname)) -and -not ($_.PSIsContainer) })
    if ($files -ne $null) {
        if ($files.Count -eq '2') {
            $editionletter = $files[-1].Name.toLower()
        } else {
            $editionletter = $files[1].Name.toLower()
        }
        $editionletter = $editionletter.replace('cdrom.','')
        $editionletter_ = $editionletter.split('.')[0][-2]
        $editionletter = $editionletter.split('.')[0][-1]
        if ($editionletter -eq 'p') {
            $Edition = 'Professional'
        } elseif ($editionletter -eq 'c') {
            $Edition = 'Home'
        } elseif ($editionletter -eq 'w') {
            $Edition = 'Workstation'
        } elseif ($editionletter -eq 'b') {
            $Edition = 'WebServer'
        } elseif ($editionletter -eq 's') {
            $Edition = 'StandardServer'
            if ($editionletter_ -eq 't') {
                $Edition = 'TerminalServer'
            }
        } elseif ($editionletter -eq 'a') {
            if ($tmpResult.BuildNumber -le 2202) {
                $Edition = 'AdvancedServer'
            } else {
                $Edition = 'EnterpriseServer'
            }
        } elseif ($editionletter -eq 'l') {
            $Edition = 'SmallBusinessServer'
        } elseif ($editionletter -eq 'd') {
            $Edition = 'DatacenterServer'
        }
    }
    $tmpResult.Sku = $Edition
    $tmpResult.Editions = @($tmpResult.Sku)
    $tmpResult.LanguageCode = $langcodes[(Get-Item $setuppath'\setup.exe').VersionInfo.Language]

    if ((Get-Item $setuppath\setup.exe).VersionInfo.IsDebug) {
        $tmpResult.BuildType = 'chk'
    } else {
        $tmpResult.BuildType = 'fre'
    }
    $tmpResult.Architecture = (Test-Arch $setuppath'\sources\setup.exe').FileType

    $typename = @()
    foreach ($sku in $tmpResult.Editions) {
        if ($sku -is [Array]) {
            foreach ($edition in $sku) {
                if (($edition.toLower() -like '*server*v') -and ($edition.toLower() -notlike '*server*hyperv')) {
                    if ($typename -notcontains "ServerV") {
                        $typename += "ServerV"
                    }
                } elseif ($edition.toLower() -like '*server*') {
                    if ($typename -notcontains "Server") {
                        $typename += "Server"
                    }
                } else {
                    if ($typename -notcontains "Client") {
                        $typename += "Client"
                    }
                }
            }
        } else {
            if (($sku.toLower() -like '*server*v') -and ($sku.toLower() -notlike '*server*hyperv')) {
                if ($typename -notcontains "ServerV") {
                    $typename += "ServerV"
                }
            } elseif ($sku.toLower() -like '*server*') {
                if ($typename -notcontains "Server") {
                    $typename += "Server"
                }
            } else {
                if ($typename -notcontains "Client") {
                    $typename += "Client"
                }
            }
        }
    }

    $counter = -1
    foreach ($item in $tmpResult.Editions) {
        $counter++
        if ($tmpResult.Editions[$counter] -eq 'ads') {
            $tmpResult.Editions[$counter] = "AdvancedServer"
        } elseif ($tmpResult.Editions[$counter] -eq 'pro') {
            $tmpResult.Editions[$counter] = "Professional"
        }
    }
    if ($tmpResult.sku -eq 'ads') {
        $tmpResult.sku = "AdvancedServer"
    } elseif ($tmpResult.sku -eq 'pro') {
        $tmpResult.sku = "Professional"
    }

    $tmpResult.Type += $typename

    $tmpResult.BuildString = ($tmpResult.MajorVersion + '.' + $tmpResult.MinorVersion + '.' + $tmpResult.BuildNumber + '.' + $tmpResult.DeltaVersion + '.' + $tmpResult.BranchName + '.' + $tmpResult.CompileDate)
    $tmpResult.SetupPath = $SetupPath

    return $tmpResult
}

function Identify-WIMFall2003($SetupPath) {
    $IdentifyResult = "" | select `
        MajorVersion, `
        MinorVersion, `
        BuildNumber, `
        DeltaVersion, `
        BranchName, `
        CompileDate, `
        Tag, `
        Architecture, `
        BuildType, `
        Type, `
        Sku, `
        Editions, `
        Licensing, `
        LanguageCode, `
        VolumeLabel, `
        BuildString, `
        SetupPath
    
    $tmpResult = $IdentifyResult

	(& $7z l -i!*\ntldr $SetupPath\sources\install.wim) | % { if ($_ -like '*ntldr*') { $wimindex = $_.split(' \')[-2] } }

    $buildno = (Get-Item $setuppath\setup.exe).VersionInfo.ProductVersion

    $tmpResult.MajorVersion = $buildno.split('.')[0]
    $tmpResult.MinorVersion = $buildno.split('.')[1]
    $tmpResult.BuildNumber = $buildno.split('.')[2]
    $tmpResult.DeltaVersion = $buildno.split('.')[3]

    $tmpResult.CompileDate = (Get-Item $SetupPath\setup.exe).VersionInfo.FileVersion.split(' ')[1].split('.')[1].replace(')','')
    $tmpResult.BranchName = (Get-Item $SetupPath\setup.exe).VersionInfo.FileVersion.split(' ')[1].split('.')[0].Substring(1)

    if ($wimindex -notmatch "^[-]?[0-9.]+$") {
        Write-Host -ForegroundColor Red "[$((Get-Date).ToString('MM/dd/yyyy hh:mm:ss tt'))] [Error] We detected a single with this setup. This is unsupported at that time since no such iso has been found, please contact gus33000 to help resolve this issue!"
    } else {

        $skus = @()
                
        $unstagedskus = (& $7z l -i!$wimindex\packages\*sku*\Security-Licensing-SLC-Component-SKU*pl*xrm* $SetupPath\sources\install.wim) | % { if ($_ -like '*Security-Licensing-SLC-Component-SKU*pl*xrm*') { $_.split(' \')[-2].split('-')[-1].split('_')[0] } } | Select -uniq
        if (($unstagedskus -ne $null) -and ($unstagedskus -ne "")) {
                foreach ($sku in $unstagedskus) {
                    $skus+=$sku
                }
                $tmpResult.Editions += $skus
        } else {
            $unstagedskus = (& $7z l -i!$wimindex\packages\*\update* $SetupPath\sources\install.wim) | % { if ($_ -like '*update.mum*') { $_.split(' \')[-2] } }
            if (($unstagedskus -ne $null) -and ($unstagedskus -ne "")) {
                    foreach ($sku in $unstagedskus) {
                        $skus+=$sku
                    }
                    
                    $tmpResult.Editions += $skus
                } else {
                    $unstagedskus = (& $7z l -i!$wimindex\vlpackages\*\update* $setuppath\sources\install.wim) | % { if ($_ -like '*update.mum*') { $_.split(' \')[-2] } }
                    if (($unstagedskus -ne $null) -and ($unstagedskus -ne "")) {
                        foreach ($sku in $unstagedskus) {
                            $skus+=$sku
                        }
                        
                        $tmpResult.Editions += $skus
                    } else {
                        $unstagedskus = (& $7z l -i!$wimindex\packages\*\shellbrd*dll $SetupPath\sources\install.wim) | % { if ($_ -like '*shellbrd*dll') { if ($_.split(' \')[-2].split('-')[-1].split('_')[0] -eq 'edition') { $_.split(' \')[-2].split('-')[-2] } else { $_.split(' \')[-2].split('-')[-1].split('_')[0] } } } | Select -uniq
                        if (($unstagedskus -ne $null) -and ($unstagedskus -ne "")) {
                            foreach ($sku in $unstagedskus) {
                                $skus+=$sku
                            }
                            
                            $tmpResult.Editions += $skus
                        }
                    }
                }
            }

        if (($tmpResult.Editions -eq '') -or ($tmpResult.Editions -eq $null)) {
            if (Test-Path $setuppath'\sources\product.ini') {
                $Edition = (get-inicontent ($setuppath + '\sources\product.ini'))["No-Section"]["skuid"].replace(' ','')
                if ($Edition -eq 'pro') {
                    $Edition = 'Professional'
                }
            } else {
                $files = (Get-ChildItem $setuppath\* | Where-Object { -not ([System.IO.Path]::hasExtension($_.fullname)) -and -not ($_.PSIsContainer) })
                if ($files -ne $null) {

                    if ($files.Count -eq '2') {
                        $editionletter = $files[-1].Name.toLower()
                    } else {
                        $editionletter = $files[1].Name.toLower()
                    }

                    $editionletter = $editionletter.replace('cdrom.','')
                    $editionletter_ = $editionletter.split('.')[0][-2]
                    $editionletter = $editionletter.split('.')[0][-1]

                    if ($editionletter -eq 'p') {
                        $Edition = 'Professional'
                    } elseif ($editionletter -eq 'c') {
                        $Edition = 'Home'
                    } elseif ($editionletter -eq 'w') {
                        $Edition = 'Workstation'
                    } elseif ($editionletter -eq 'b') {
                        $Edition = 'WebServer'
                    } elseif ($editionletter -eq 's') {
                        $Edition = 'StandardServer'
                        if ($editionletter_ -eq 't') {
                            $Edition = 'TerminalServer'
                        }
                    } elseif ($editionletter -eq 'a') {
                        if ($tmpResult.BuildNumber -le 2202) {
                            $Edition = 'AdvancedServer'
                        } else {
                            $Edition = 'EnterpriseServer'
                        }
                    } elseif ($editionletter -eq 'l') {
                        $Edition = 'SmallBusinessServer'
                    } elseif ($editionletter -eq 'd') {
                        $Edition = 'DatacenterServer'
                    }
                }
            }
            $tmpResult.Sku = $Edition
            $tmpResult.Editions = @($tmpResult.Sku)
        }
        $tmpResult.LanguageCode = $langcodes[(Get-Item $setuppath'\setup.exe').VersionInfo.Language]

        if ((Get-Item $setuppath\setup.exe).VersionInfo.IsDebug) {
            $tmpResult.BuildType = 'chk'
        } else {
            $tmpResult.BuildType = 'fre'
        }
        $tmpResult.Architecture = (Test-Arch $setuppath'\sources\setup.exe').FileType

        Write-Host "[$((Get-Date).ToString('MM/dd/yyyy hh:mm:ss tt'))] [Info] Checking critical system files for a build string and build type information..."
        & $7z x $setuppath'\sources\install.wim' "$wimindex\windows\system32\ntkrnlmp.exe" | Out-Null
        & $7z x $setuppath'\sources\install.wim' "$wimindex\windows\system32\ntoskrnl.exe" | Out-Null
        if (Test-Path .\$wimindex\windows\system32\ntkrnlmp.exe) {
            $tmpResult.CompileDate = (Get-Item .\$wimindex\windows\system32\ntkrnlmp.exe).VersionInfo.FileVersion.split(' ')[1].split('.')[1].replace(')','')
            $tmpResult.BranchName = (Get-Item .\$wimindex\windows\system32\ntkrnlmp.exe).VersionInfo.FileVersion.split(' ')[1].split('.')[0].Substring(1)
            if ((Get-Item .\$wimindex\windows\system32\ntkrnlmp.exe).VersionInfo.IsDebug) {
                $tmpResult.BuildType = 'chk'
            } else {
                $tmpResult.BuildType = 'fre'
            }
            $ProductVersion = (Get-Item .\$wimindex\windows\system32\ntkrnlmp.exe).VersionInfo.ProductVersion
            Remove-Item .\$wimindex\windows\system32\ntkrnlmp.exe -Force
        } elseif (Test-Path .\$wimindex\windows\system32\ntoskrnl.exe) {
            $tmpResult.CompileDate = (Get-Item .\$wimindex\windows\system32\ntoskrnl.exe).VersionInfo.FileVersion.split(' ')[1].split('.')[1].replace(')','')
            $tmpResult.BranchName = (Get-Item .\$wimindex\windows\system32\ntoskrnl.exe).VersionInfo.FileVersion.split(' ')[1].split('.')[0].Substring(1)
            if ((Get-Item .\$wimindex\windows\system32\ntoskrnl.exe).VersionInfo.IsDebug) {
                $tmpResult.BuildType = 'chk'
            } else {
                $tmpResult.BuildType = 'fre'
            }
            $ProductVersion = (Get-Item .\$wimindex\windows\system32\ntoskrnl.exe).VersionInfo.ProductVersion
            Remove-Item .\$wimindex\windows\system32\ntoskrnl.exe -Force
        }

        $tmpResult.MajorVersion = $ProductVersion.split('.')[0]
        $tmpResult.MinorVersion = $ProductVersion.split('.')[1]
        $tmpResult.BuildNumber = $ProductVersion.split('.')[2]
        $tmpResult.DeltaVersion = $ProductVersion.split('.')[3]

        Write-Host "[$((Get-Date).ToString('MM/dd/yyyy hh:mm:ss tt'))] [Info] Checking registry for a more accurate build string..."
        & $7z x $setuppath'\sources\install.wim' "$wimindex\windows\system32\config\" | Out-Null
        & 'reg' load HKLM\RenameISOs .\$wimindex\windows\system32\config\SOFTWARE | Out-Null
        $output = (& 'reg' query "HKLM\RenameISOs\Microsoft\Windows NT\CurrentVersion" /v "BuildLab")
        if (($output -ne $null) -and ($output[2] -ne $null) -and (-not ($output[2].split(' ')[-1].split('.')[-1]) -eq '')) {
            $tmpResult.CompileDate = $output[2].split(' ')[-1].split('.')[-1]
            $tmpResult.BranchName = $output[2].split(' ')[-1].split('.')[-2]
            $output_ = (& 'reg' query "HKLM\RenameISOs\Microsoft\Windows NT\CurrentVersion" /v "BuildLabEx")
            if (($output_[2] -ne $null) -and (-not ($output_[2].split(' ')[-1].split('.')[-1]) -eq '')) {
                if ($output_[2].split(' ')[-1] -like '*.*.*.*.*') {
                    $tmpResult.BuildNumber = $output_[2].split(' ')[-1].split('.')[0]
                    $tmpResult.DeltaVersion = $output_[2].split(' ')[-1].split('.')[1]
                }
            }
        } else {
            Write-Host "[$((Get-Date).ToString('MM/dd/yyyy hh:mm:ss tt'))] [Info] Registry check was unsuccessful. Aborting and continuing with critical system files build string..."
        }

        $tmpResult.Licensing = 'Retail'
        $output = (& 'reg' query "HKLM\RenameISOs\Microsoft\Windows NT\CurrentVersion\DefaultProductKey" /v "ProductId")
        if ($output -ne $null) {
            if ($output[2] -ne $null) {
                $var = $output[2].split(' ')[-1].Substring($output[2].split(' ')[-1].Length - 3,3)
                if ($var.toUpper() -eq "OEM") {
                    $tmpResult.Licensing = "OEM"
                }
            }
        }

        & 'reg' unload HKLM\RenameISOs | Out-Null
        & 'reg' load HKLM\RenameISOs .\$wimindex\windows\system32\config\SYSTEM | Out-Null
        $ProductSuite = (Get-ItemProperty -Path HKLM:\RenameISOs\ControlSet001\Control\ProductOptions -Name ProductSuite).ProductSuite
        
        & 'reg' unload HKLM\RenameISOs | Out-Null
        Remove-Item .\$wimindex\windows\system32\config\ -Recurse -Force
        Remove-Item .\$wimindex -Recurse -Force
        
        if (($tmpResult.Editions -eq '') -or ($tmpResult.Editions -eq $null)) {
            if (($ProductSuite -ne $null) -and ($ProductSuite -ne '')) {
                if ($ProductSuite -is [System.Array]) {
                    if ($ProductSuite[0] -ne '') {
                        $tmpResult.Sku = $ProductSuite[0]
                    }
                }
                $tmpResult.Editions = @($tmpResult.Sku)
            }
        }

        $typename = @()
        foreach ($sku in $tmpResult.Editions) {
            if ($sku -is [Array]) {
                foreach ($edition in $sku) {
                    if (($edition.toLower() -like '*server*v') -and ($edition.toLower() -notlike '*server*hyperv')) {
                        if ($typename -notcontains "ServerV") {
                            $typename += "ServerV"
                        }
                    } elseif ($edition.toLower() -like '*server*') {
                        if ($typename -notcontains "Server") {
                            $typename += "Server"
                        }
                    } else {
                        if ($typename -notcontains "Client") {
                            $typename += "Client"
                        }
                    }
                }
            } else {
                if (($sku.toLower() -like '*server*v') -and ($sku.toLower() -notlike '*server*hyperv')) {
                    if ($typename -notcontains "ServerV") {
                        $typename += "ServerV"
                    }
                } elseif ($sku.toLower() -like '*server*') {
                    if ($typename -notcontains "Server") {
                        $typename += "Server"
                    }
                } else {
                    if ($typename -notcontains "Client") {
                        $typename += "Client"
                    }
                }
            }
        }

        $counter = -1
        foreach ($item in $tmpResult.Editions) {
            $counter++
            if ($tmpResult.Editions[$counter] -eq 'ads') {
                $tmpResult.Editions[$counter] = "AdvancedServer"
            } elseif ($tmpResult.Editions[$counter] -eq 'pro') {
                $tmpResult.Editions[$counter] = "Professional"
            }
        }
        if ($tmpResult.sku -eq 'ads') {
            $tmpResult.sku = "AdvancedServer"
        } elseif ($tmpResult.sku -eq 'pro') {
            $tmpResult.sku = "Professional"
        }

        $tmpResult.Type += $typename

        $tmpResult.BuildString = ($tmpResult.MajorVersion + '.' + $tmpResult.MinorVersion + '.' + $tmpResult.BuildNumber + '.' + $tmpResult.DeltaVersion + '.' + $tmpResult.BranchName + '.' + $tmpResult.CompileDate)
        $tmpResult.SetupPath = $SetupPath
    }
    return $tmpResult
}

function Identify-WIMFall2005($SetupPath) {
    $IdentifyResult = "" | select `
        MajorVersion, `
        MinorVersion, `
        BuildNumber, `
        DeltaVersion, `
        BranchName, `
        CompileDate, `
        Tag, `
        Architecture, `
        BuildType, `
        Type, `
        Sku, `
        Editions, `
        Licensing, `
        LanguageCode, `
        VolumeLabel, `
        BuildString, `
        SetupPath
    
    $tmpResult = $IdentifyResult

    (& $7z l -i!*\ntldr $SetupPath\sources\install.wim) | % { if ($_ -like '*ntldr*') { $wimindex = $_.split(' \')[-2] } }

    if ($wimindex -match "^[-]?[0-9.]+$") {
        Write-Host -ForegroundColor Red "[$((Get-Date).ToString('MM/dd/yyyy hh:mm:ss tt'))] [Error] We detected multiple indexes with this setup. This is unsupported at that time since no such iso has been found, please contact gus33000 to help resolve this issue!"
    } else {
        $buildno = (Get-Item $setuppath\setup.exe).VersionInfo.ProductVersion

        $tmpResult.MajorVersion = $buildno.split('.')[0]
        $tmpResult.MinorVersion = $buildno.split('.')[1]
        $tmpResult.BuildNumber = $buildno.split('.')[2]
        $tmpResult.DeltaVersion = $buildno.split('.')[3]

        $tmpResult.CompileDate = (Get-Item $SetupPath\setup.exe).VersionInfo.FileVersion.split(' ')[1].split('.')[1].replace(')','')
        $tmpResult.BranchName = (Get-Item $SetupPath\setup.exe).VersionInfo.FileVersion.split(' ')[1].split('.')[0].Substring(1)

        $skus = @()
                
        $unstagedskus = (& $7z l -i!packages\*sku*\Security-Licensing-SLC-Component-SKU*pl*xrm* $SetupPath\sources\install.wim) | % { if ($_ -like '*Security-Licensing-SLC-Component-SKU*pl*xrm*') { $_.split(' \')[-2].split('-')[-1].split('_')[0] } } | Select -uniq
        if (($unstagedskus -ne $null) -and ($unstagedskus -ne "")) {
                foreach ($sku in $unstagedskus) {
                    $skus+=$sku
                }
                $tmpResult.Editions += $skus
        } else {
            $unstagedskus = (& $7z l -i!packages\*\update* $SetupPath\sources\install.wim) | % { if ($_ -like '*update.mum*') { $_.split(' \')[-2] } }
            if (($unstagedskus -ne $null) -and ($unstagedskus -ne "")) {
                    foreach ($sku in $unstagedskus) {
                        $skus+=$sku
                    }
                    
                    $tmpResult.Editions += $skus
                } else {
                    $unstagedskus = (& $7z l -i!vlpackages\*\update* $setuppath\sources\install.wim) | % { if ($_ -like '*update.mum*') { $_.split(' \')[-2] } }
                    if (($unstagedskus -ne $null) -and ($unstagedskus -ne "")) {
                        foreach ($sku in $unstagedskus) {
                            $skus+=$sku
                        }
                        
                        $tmpResult.Editions += $skus
                    } else {
                        $unstagedskus = (& $7z l -i!packages\*\shellbrd*dll $SetupPath\sources\install.wim) | % { if ($_ -like '*shellbrd*dll') { if ($_.split(' \')[-2].split('-')[-1].split('_')[0] -eq 'edition') { $_.split(' \')[-2].split('-')[-2] } else { $_.split(' \')[-2].split('-')[-1].split('_')[0] } } } | Select -uniq
                        if (($unstagedskus -ne $null) -and ($unstagedskus -ne "")) {
                            foreach ($sku in $unstagedskus) {
                                $skus+=$sku
                            }
                            
                            $tmpResult.Editions += $skus
                        }
                    }
                }
            }

        if (($tmpResult.Editions -eq '') -or ($tmpResult.Editions -eq $null)) {
            if (Test-Path $setuppath'\sources\product.ini') {
                $Edition = (get-inicontent ($setuppath + '\sources\product.ini'))["No-Section"]["skuid"].replace(' ','')
                if ($Edition -eq 'pro') {
                    $Edition = 'Professional'
                }
            } else {
                $files = (Get-ChildItem $setuppath\* | Where-Object { -not ([System.IO.Path]::hasExtension($_.fullname)) -and -not ($_.PSIsContainer) })
                if ($files -ne $null) {

                    if ($files.Count -eq '2') {
                        $editionletter = $files[-1].Name.toLower()
                    } else {
                        $editionletter = $files[1].Name.toLower()
                    }

                    $editionletter = $editionletter.replace('cdrom.','')
                    $editionletter_ = $editionletter.split('.')[0][-2]
                    $editionletter = $editionletter.split('.')[0][-1]

                    if ($editionletter -eq 'p') {
                        $Edition = 'Professional'
                    } elseif ($editionletter -eq 'c') {
                        $Edition = 'Home'
                    } elseif ($editionletter -eq 'w') {
                        $Edition = 'Workstation'
                    } elseif ($editionletter -eq 'b') {
                        $Edition = 'WebServer'
                    } elseif ($editionletter -eq 's') {
                        $Edition = 'StandardServer'
                        if ($editionletter_ -eq 't') {
                            $Edition = 'TerminalServer'
                        }
                    } elseif ($editionletter -eq 'a') {
                        if ($tmpResult.BuildNumber -le 2202) {
                            $Edition = 'AdvancedServer'
                        } else {
                            $Edition = 'EnterpriseServer'
                        }
                    } elseif ($editionletter -eq 'l') {
                        $Edition = 'SmallBusinessServer'
                    } elseif ($editionletter -eq 'd') {
                        $Edition = 'DatacenterServer'
                    }
                }
            }
            $tmpResult.Sku = $Edition
            $tmpResult.Editions = @($tmpResult.Sku)
        }
        $tmpResult.LanguageCode = $langcodes[(Get-Item $setuppath'\setup.exe').VersionInfo.Language]

        if ((Get-Item $setuppath\setup.exe).VersionInfo.IsDebug) {
            $tmpResult.BuildType = 'chk'
        } else {
            $tmpResult.BuildType = 'fre'
        }
        $tmpResult.Architecture = (Test-Arch $setuppath'\sources\setup.exe').FileType

        Write-Host "[$((Get-Date).ToString('MM/dd/yyyy hh:mm:ss tt'))] [Info] Checking critical system files for a build string and build type information..."
        & $7z x $setuppath'\sources\install.wim' "windows\system32\ntkrnlmp.exe" | Out-Null
        & $7z x $setuppath'\sources\install.wim' "windows\system32\ntoskrnl.exe" | Out-Null
        if (Test-Path .\windows\system32\ntkrnlmp.exe) {
            $tmpResult.CompileDate = (Get-Item .\windows\system32\ntkrnlmp.exe).VersionInfo.FileVersion.split(' ')[1].split('.')[1].replace(')','')
            $tmpResult.BranchName = (Get-Item .\windows\system32\ntkrnlmp.exe).VersionInfo.FileVersion.split(' ')[1].split('.')[0].Substring(1)
            if ((Get-Item .\windows\system32\ntkrnlmp.exe).VersionInfo.IsDebug) {
                $tmpResult.BuildType = 'chk'
            } else {
                $tmpResult.BuildType = 'fre'
            }
            $ProductVersion = (Get-Item .\windows\system32\ntkrnlmp.exe).VersionInfo.ProductVersion
            Remove-Item .\windows\system32\ntkrnlmp.exe -Force
        } elseif (Test-Path .\windows\system32\ntoskrnl.exe) {
            $tmpResult.CompileDate = (Get-Item .\windows\system32\ntoskrnl.exe).VersionInfo.FileVersion.split(' ')[1].split('.')[1].replace(')','')
            $tmpResult.BranchName = (Get-Item .\windows\system32\ntoskrnl.exe).VersionInfo.FileVersion.split(' ')[1].split('.')[0].Substring(1)
            if ((Get-Item .\windows\system32\ntoskrnl.exe).VersionInfo.IsDebug) {
                $tmpResult.BuildType = 'chk'
            } else {
                $tmpResult.BuildType = 'fre'
            }
            $ProductVersion = (Get-Item .\windows\system32\ntoskrnl.exe).VersionInfo.ProductVersion
            Remove-Item .\windows\system32\ntoskrnl.exe -Force
        }

        $tmpResult.MajorVersion = $ProductVersion.split('.')[0]
        $tmpResult.MinorVersion = $ProductVersion.split('.')[1]
        $tmpResult.BuildNumber = $ProductVersion.split('.')[2]
        $tmpResult.DeltaVersion = $ProductVersion.split('.')[3]

        Write-Host "[$((Get-Date).ToString('MM/dd/yyyy hh:mm:ss tt'))] [Info] Checking registry for a more accurate build string..."
        & $7z x $setuppath'\sources\install.wim' "windows\system32\config\" | Out-Null
        & 'reg' load HKLM\RenameISOs .\windows\system32\config\SOFTWARE | Out-Null
        $output = (& 'reg' query "HKLM\RenameISOs\Microsoft\Windows NT\CurrentVersion" /v "BuildLab")
        if (($output -ne $null) -and ($output[2] -ne $null) -and (-not ($output[2].split(' ')[-1].split('.')[-1]) -eq '')) {
            $tmpResult.CompileDate = $output[2].split(' ')[-1].split('.')[-1]
            $tmpResult.BranchName = $output[2].split(' ')[-1].split('.')[-2]
            $output_ = (& 'reg' query "HKLM\RenameISOs\Microsoft\Windows NT\CurrentVersion" /v "BuildLabEx")
            if (($output_[2] -ne $null) -and (-not ($output_[2].split(' ')[-1].split('.')[-1]) -eq '')) {
                if ($output_[2].split(' ')[-1] -like '*.*.*.*.*') {
                    $tmpResult.BuildNumber = $output_[2].split(' ')[-1].split('.')[0]
                    $tmpResult.DeltaVersion = $output_[2].split(' ')[-1].split('.')[1]
                }
            }
        } else {
            Write-Host "[$((Get-Date).ToString('MM/dd/yyyy hh:mm:ss tt'))] [Info] Registry check was unsuccessful. Aborting and continuing with critical system files build string..."
        }

        $tmpResult.Licensing = 'Retail'
        $output = (& 'reg' query "HKLM\RenameISOs\Microsoft\Windows NT\CurrentVersion\DefaultProductKey" /v "ProductId")
        if ($output -ne $null) {
            if ($output[2] -ne $null) {
                $var = $output[2].split(' ')[-1].Substring($output[2].split(' ')[-1].Length - 3,3)
                if ($var.toUpper() -eq "OEM") {
                    $tmpResult.Licensing = "OEM"
                }
            }
        }

        & 'reg' unload HKLM\RenameISOs | Out-Null
        & 'reg' load HKLM\RenameISOs .\windows\system32\config\SYSTEM | Out-Null
        $ProductSuite = (Get-ItemProperty -Path HKLM:\RenameISOs\ControlSet001\Control\ProductOptions -Name ProductSuite).ProductSuite
        
        & 'reg' unload HKLM\RenameISOs | Out-Null
        Remove-Item .\windows\system32\config\ -Recurse -Force
        Remove-Item .\windows -Recurse -Force
        
        if (($tmpResult.Editions -eq '') -or ($tmpResult.Editions -eq $null)) {
            if (($ProductSuite -ne $null) -and ($ProductSuite -ne '')) {
                if ($ProductSuite -is [System.Array]) {
                    if ($ProductSuite[0] -ne '') {
                        $tmpResult.Sku = $ProductSuite[0]
                    }
                }
                $tmpResult.Editions = @($tmpResult.Sku)
            }
        }

        $typename = @()
        foreach ($sku in $tmpResult.Editions) {
            if ($sku -is [Array]) {
                foreach ($edition in $sku) {
                    if (($edition.toLower() -like '*server*v') -and ($edition.toLower() -notlike '*server*hyperv')) {
                        if ($typename -notcontains "ServerV") {
                            $typename += "ServerV"
                        }
                    } elseif ($edition.toLower() -like '*server*') {
                        if ($typename -notcontains "Server") {
                            $typename += "Server"
                        }
                    } else {
                        if ($typename -notcontains "Client") {
                            $typename += "Client"
                        }
                    }
                }
            } else {
                if (($sku.toLower() -like '*server*v') -and ($sku.toLower() -notlike '*server*hyperv')) {
                    if ($typename -notcontains "ServerV") {
                        $typename += "ServerV"
                    }
                } elseif ($sku.toLower() -like '*server*') {
                    if ($typename -notcontains "Server") {
                        $typename += "Server"
                    }
                } else {
                    if ($typename -notcontains "Client") {
                        $typename += "Client"
                    }
                }
            }
        }

        $counter = -1
        foreach ($item in $tmpResult.Editions) {
            $counter++
            if ($tmpResult.Editions[$counter] -eq 'ads') {
                $tmpResult.Editions[$counter] = "AdvancedServer"
            } elseif ($tmpResult.Editions[$counter] -eq 'pro') {
                $tmpResult.Editions[$counter] = "Professional"
            }
        }
        if ($tmpResult.sku -eq 'ads') {
            $tmpResult.sku = "AdvancedServer"
        } elseif ($tmpResult.sku -eq 'pro') {
            $tmpResult.sku = "Professional"
        }

        $tmpResult.Type += $typename

        $tmpResult.BuildString = ($tmpResult.MajorVersion + '.' + $tmpResult.MinorVersion + '.' + $tmpResult.BuildNumber + '.' + $tmpResult.DeltaVersion + '.' + $tmpResult.BranchName + '.' + $tmpResult.CompileDate)
        $tmpResult.SetupPath = $SetupPath
    }
    return $tmpResult
}

function Identify-WIMLate2005($SetupPath) {
    $tmpResults = @()

    $BuildArray = @{}

    $WIMInfo = New-Object System.Collections.ArrayList
	$WIMInfo = @{}
	$WIMInfo['header'] = @{}
	$OutputVariable = ( & $wimlib info "$($setuppath)\sources\install.wim" --header)
	ForEach ($isofile_ in $OutputVariable) {
		$CurrentItem = ($isofile_ -replace '\s+', ' ').split('=')
		$CurrentItemName = $CurrentItem[0] -replace ' ', ''
		if (($CurrentItem[1] -replace ' ', '') -ne '') {
			$WIMInfo['header'][$CurrentItemName] = $CurrentItem[1].Substring(1)
		}
	}
    for ($i=1; $i -le $WIMInfo.header.ImageCount; $i++){
		$WIMInfo[$i] = @{}
		$OutputVariable = ( & $wimlib info "$($setuppath)\sources\install.wim" $i)
		ForEach ($isofile_ in $OutputVariable) {
			$CurrentItem = ($isofile_ -replace '\s+', ' ').split(':')
			$CurrentItemName = $CurrentItem[0] -replace ' ', ''
			if (($CurrentItem[1] -replace ' ', '') -ne '') {
				$WIMInfo[$i][$CurrentItemName] = $CurrentItem[1].Substring(1)
			}
		}
	}
    for ($i=1; $i -le $WIMInfo.header.ImageCount; $i++){
        $BuildPartStr = $WIMInfo[$i].MajorVersion + '.' + $WIMInfo[$i].MinorVersion + '.' + $WIMInfo[$i].Build + '.' + $WIMInfo[$i].ServicePackBuild + " " + $WIMInfo[$i].Architecture
        if ($BuildArray[$BuildPartStr] -eq $null) {
            $BuildArray[$BuildPartStr] = @()
            $BuildArray[$BuildPartStr] += $WIMInfo[$i]
        } else {
            $BuildArray[$BuildPartStr] += $WIMInfo[$i]
        }
    }

    foreach ($Build in ($BuildArray.GetEnumerator() | Select-Object Name)) {
        $IdentifyResult = "" | select `
            MajorVersion, `
            MinorVersion, `
            BuildNumber, `
            DeltaVersion, `
            BranchName, `
            CompileDate, `
            Tag, `
            Architecture, `
            BuildType, `
            Type, `
            Sku, `
            Editions, `
            Licensing, `
            LanguageCode, `
            VolumeLabel, `
            BuildString, `
            SetupPath
        $tmpResult = $IdentifyResult
        $editions = @()
        $maintestindex = 1
        if ($BuildArray[$Build.Name] -is [system.array]) {
            $allunstaged = $true
            foreach($index in $BuildArray[$Build.Name]) {
                if ($index.Flags -ne "Windows Foundation") {
                    $allunstaged = $false
                }
            }
            if ($allunstaged) {
                $tmpResult.Sku = "Unstaged"
            } else {
                foreach($index in $BuildArray[$Build.Name]) {
                    if ($index.Flags -eq "Windows Foundation") {
                        $editions += "Foundation"
                    } else {
                        if ($index.EditionID -eq $null) {
                            $editions += $index.Flags
                        } else {
                            $editions += $index.EditionID
                        }
                    }
                }
                if ($BuildArray[$Build.Name].Count -eq 1) {
                    if ($BuildArray[$Build.Name][0].EditionID -eq $null) {
                        $tmpResult.Sku = $BuildArray[$Build.Name][0].Flags
                    } else {
                        $tmpResult.Sku = $BuildArray[$Build.Name][0].EditionID
                    }
                }
            }
            $maintestindex = $BuildArray[$Build.Name][0].Index
        } else {
            if ($BuildArray[$Build.Name].EditionID -eq $null) {
                if ($BuildArray[$Build.Name].Flags -eq "Windows Foundation") {
                    $tmpResult.Sku = "Unstaged"
                } else {
                    $editions += $BuildArray[$Build.Name].Flags
                    $tmpResult.Sku = $BuildArray[$Build.Name].Flags
                }
            } else {
                if ($BuildArray[$Build.Name].Flags -eq "Windows Foundation") {
                $tmpResult.Sku = "Unstaged"
                } else {
                    $editions += $BuildArray[$Build.Name].EditionID
                    $tmpResult.Sku = $BuildArray[$Build.Name].EditionID
                }
            }
            $maintestindex = $BuildArray[$Build.Name].Index
        }
        $tmpResult.Editions = $editions

        if ($WIMInfo[[int]$maintestindex].Architecture -eq 'x86') {
            $tmpResult.Architecture = 'x86'
        } elseif ($WIMInfo[[int]$maintestindex].Architecture -eq 'x86_64') {
            $tmpResult.Architecture = 'amd64'
        } else {
            $tmpResult.Architecture = $WIMInfo[[int]$maintestindex].Architecture
        }

        Write-Host "[$((Get-Date).ToString('MM/dd/yyyy hh:mm:ss tt'))] [Info] Checking critical system files for a build string and build type information..."
        & $wimlib extract $SetupPath\sources\install.wim $maintestindex windows\system32\ntkrnlmp.exe windows\system32\ntoskrnl.exe --nullglob --no-acls | Out-Null
        if (Test-Path .\ntkrnlmp.exe) {
            $tmpResult.CompileDate = (Get-Item .\ntkrnlmp.exe).VersionInfo.FileVersion.split(' ')[1].split('.')[1].replace(')','')
            $tmpResult.BranchName = (Get-Item .\ntkrnlmp.exe).VersionInfo.FileVersion.split(' ')[1].split('.')[0].Substring(1)
            if ((Get-Item .\ntkrnlmp.exe).VersionInfo.IsDebug) {
                $tmpResult.BuildType = 'chk'
            } else {
                $tmpResult.BuildType = 'fre'
            }
            $ProductVersion = (Get-Item .\ntkrnlmp.exe).VersionInfo.ProductVersion
            Remove-Item .\ntkrnlmp.exe -Force
        } elseif (Test-Path .\ntoskrnl.exe) {
            $tmpResult.CompileDate = (Get-Item .\ntoskrnl.exe).VersionInfo.FileVersion.split(' ')[1].split('.')[1].replace(')','')
            $tmpResult.BranchName = (Get-Item .\ntoskrnl.exe).VersionInfo.FileVersion.split(' ')[1].split('.')[0].Substring(1)
            if ((Get-Item .\ntoskrnl.exe).VersionInfo.IsDebug) {
                $tmpResult.BuildType = 'chk'
            } else {
                $tmpResult.BuildType = 'fre'
            }
            $ProductVersion = (Get-Item .\ntoskrnl.exe).VersionInfo.ProductVersion
            Remove-Item .\ntoskrnl.exe -Force
        }

        $tmpResult.MajorVersion = $ProductVersion.split('.')[0]
        $tmpResult.MinorVersion = $ProductVersion.split('.')[1]
        $tmpResult.BuildNumber = $ProductVersion.split('.')[2]
        $tmpResult.DeltaVersion = $ProductVersion.split('.')[3]

        Write-Host "[$((Get-Date).ToString('MM/dd/yyyy hh:mm:ss tt'))] [Info] Checking registry for a more accurate build string and licensing information..."
        & $wimlib extract $SetupPath\sources\install.wim $maintestindex windows\system32\config\ --no-acls | Out-Null
        & 'reg' load HKLM\RenameISOs .\config\SOFTWARE | Out-Null
        $output = (& 'reg' query "HKLM\RenameISOs\Microsoft\Windows NT\CurrentVersion" /v "BuildLab")
        if (($output[2] -ne $null) -and (-not ($output[2].split(' ')[-1].split('.')[-1]) -eq '')) {
            $tmpResult.CompileDate = $output[2].split(' ')[-1].split('.')[-1]
            $tmpResult.BranchName = $output[2].split(' ')[-1].split('.')[-2]
            $output_ = (& 'reg' query "HKLM\RenameISOs\Microsoft\Windows NT\CurrentVersion" /v "BuildLabEx")
            if (($output_[2] -ne $null) -and (-not ($output_[2].split(' ')[-1].split('.')[-1]) -eq '')) {
                if ($output_[2].split(' ')[-1] -like '*.*.*.*.*') {
                    $tmpResult.BuildNumber = $output_[2].split(' ')[-1].split('.')[0]
                    $tmpResult.DeltaVersion = $output_[2].split(' ')[-1].split('.')[1]
                }
            }
        } else {
            Write-Host "[$((Get-Date).ToString('MM/dd/yyyy hh:mm:ss tt'))] [Info] Registry check for buildstring was unsuccessful. Aborting and continuing with critical system files build string..."
        }
        $tmpResult.Licensing = 'Retail'
        $output = (& 'reg' query "HKLM\RenameISOs\Microsoft\Windows NT\CurrentVersion\DefaultProductKey" /v "ProductId")
        if ($output -ne $null) {
            if ($output[2] -ne $null) {
                $var = $output[2].split(' ')[-1].Substring($output[2].split(' ')[-1].Length - 3,3)
                if ($var.toUpper() -eq "OEM") {
                    $tmpResult.Licensing = "OEM"
                }
            }
        }

        if (Test-Path "$($SetupPath)\sources\ei.cfg") {
            $content = @()
            Get-Content ("$($SetupPath)\sources\ei.cfg") | ForEach-Object -Process {
                $content += $_
            }
            $counter = 0
            foreach ($item in $content) {
                $counter++
                if ($item -eq '[EditionID]') {
                    $tmpResult.Sku = $content[$counter]
                }
            }
            $counter = 0
            foreach ($item in $content) {
                $counter++
                if ($item -eq '[Channel]') {
                    $tmpResult.Licensing = $content[$counter]
                }
            }
        }
        
        & 'reg' unload HKLM\RenameISOs | Out-Null
        Remove-Item .\config\ -Recurse -Force

        if ($tmpResult.Sku -eq "Unstaged") {
            
            $skus = @()
            
            $unstagedskus = (& $7z l -i!packages\*sku*\Security-Licensing-SLC-Component-SKU*pl*xrm* $SetupPath\sources\install.wim) | % { if ($_ -like '*Security-Licensing-SLC-Component-SKU*pl*xrm*') { $_.split(' \')[-2].split('-')[-1].split('_')[0] } } | Select -uniq
            if (($unstagedskus -ne $null) -and ($unstagedskus -ne "")) {
                    foreach ($sku in $unstagedskus) {
                        $skus+=$sku
                    }
                    $tmpResult.Editions += $skus
            } else {
                $unstagedskus = (& $7z l -i!packages\*\update* $SetupPath\sources\install.wim) | % { if ($_ -like '*update.mum*') { $_.split(' \')[-2] } }
                if (($unstagedskus -ne $null) -and ($unstagedskus -ne "")) {
                    foreach ($sku in $unstagedskus) {
                        $skus+=$sku
                    }
                    
                    $tmpResult.Editions += $skus
                } else {
                    $unstagedskus = (& $7z l -i!vlpackages\*\update* $setuppath\sources\install.wim) | % { if ($_ -like '*update.mum*') { $_.split(' \')[-2] } }
                    if (($unstagedskus -ne $null) -and ($unstagedskus -ne "")) {
                        foreach ($sku in $unstagedskus) {
                            $skus+=$sku
                        }
                        
                        $tmpResult.Editions += $skus
                    } else {
                        $unstagedskus = (& $7z l -i!packages\*\shellbrd*dll $SetupPath\sources\install.wim) | % { if ($_ -like '*shellbrd*dll') { if ($_.split(' \')[-2].split('-')[-1].split('_')[0] -eq 'edition') { $_.split(' \')[-2].split('-')[-2] } else { $_.split(' \')[-2].split('-')[-1].split('_')[0] } } } | Select -uniq
                        if (($unstagedskus -ne $null) -and ($unstagedskus -ne "")) {
                            foreach ($sku in $unstagedskus) {
                                $skus+=$sku
                            }
                            
                            $tmpResult.Editions += $skus
                        }
                    }
                }
            }
        }

        $typename = @()
        foreach ($sku in $tmpResult.Editions) {
            if ($sku -is [Array]) {
                foreach ($edition in $sku) {
                    if (($edition.toLower() -like '*server*v') -and ($edition.toLower() -notlike '*server*hyperv')) {
                        if ($typename -notcontains "ServerV") {
                            $typename += "ServerV"
                        }
                    } elseif ($edition.toLower() -like '*server*') {
                        if ($typename -notcontains "Server") {
                            $typename += "Server"
                        }
                    } else {
                        if ($typename -notcontains "Client") {
                            $typename += "Client"
                        }
                    }
                }
            } else {
                if (($sku.toLower() -like '*server*v') -and ($sku.toLower() -notlike '*server*hyperv')) {
                    if ($typename -notcontains "ServerV") {
                        $typename += "ServerV"
                    }
                } elseif ($sku.toLower() -like '*server*') {
                    if ($typename -notcontains "Server") {
                        $typename += "Server"
                    }
                } else {
                    if ($typename -notcontains "Client") {
                        $typename += "Client"
                    }
                }
            }
        }
        
        $tmpResult.Type += $typename

        $counter = -1
        foreach ($item in $tmpResult.Editions) {
            $counter++
            if ($tmpResult.Editions[$counter] -eq 'ads') {
                $tmpResult.Editions[$counter] = "AdvancedServer"
            } elseif ($tmpResult.Editions[$counter] -eq 'pro') {
                $tmpResult.Editions[$counter] = "Professional"
            }
        }
        if ($tmpResult.sku -eq 'ads') {
            $tmpResult.sku = "AdvancedServer"
        } elseif ($tmpResult.sku -eq 'pro') {
            $tmpResult.sku = "Professional"
        }

        Get-Content ("$($SetupPath)\sources\lang.ini") | ForEach-Object -Begin { $h = @() } -Process { $k = [regex]::split($_,'`r`n'); if (($k[0].CompareTo("") -ne 0)) { $h += $k[0] } }
        $tmpResult.LanguageCode = ($h[((0..($h.Count - 1) | Where { $h[$_] -eq '[Available UI Languages]' }) + 1)]).split('=')[0].Trim()

        $tmpResult.BuildString = ($tmpResult.MajorVersion + '.' + $tmpResult.MinorVersion + '.' + $tmpResult.BuildNumber + '.' + $tmpResult.DeltaVersion + '.' + $tmpResult.BranchName + '.' + $tmpResult.CompileDate)
        $tmpResult.SetupPath = $SetupPath

        $tmpResults += $tmpResult
    }
    return $tmpResults
}

function Identify-SetupPath ($SetupPath) {

    $Results = @()

    if ( `
        (Test-Path ($SetupPath + "\sources\install.wim")) `
        -and `
        (Test-Path ($SetupPath + "\sources\lang.ini")) `
        -and `
        (Test-Path ($SetupPath + "\sources\boot.wim"))`
    ) {
        <# 
            Newest type of setup up to this day (late Vista, seven, 8, 8.1, 10)
        #>
        Write-Host "[$((Get-Date).ToString('MM/dd/yyyy hh:mm:ss tt'))] [Info] Type of setup detected: WIM Based Setup, Late 2005 revision."
        $tmpResults = Identify-WIMLate2005($SetupPath)
        foreach ($tmpResult in $tmpResults) {
            $Results += $tmpResult
        }
    } elseif ( `
         (Test-Path ($setuppath + '\setup.exe')) `
         -and `
         (Test-Path ($setuppath + '\sources\install.wim'))`
         -and `
         (Test-Path ($setuppath + '\sources\boot.wim'))`
    ) {
        <#
            Late-Early Vista wim based setup.
        #>
        Write-Host "[$((Get-Date).ToString('MM/dd/yyyy hh:mm:ss tt'))] [Info] Type of setup detected: WIM Based Setup, Fall 2005 revision."
        $Results += Identify-WIMFall2005($SetupPath)
    } elseif ( `
         (Test-Path ($setuppath + '\setup.exe')) `
         -and `
         (Test-Path ($setuppath + '\sources\install.wim'))`
         -and `
         (-not (Test-Path ($setuppath + '\sources\boot.wim')))`
    ) {
        if ((& $7z l $setuppath\sources\install.wim)[-1] -like 'Warnings:*') {
            <#
                Early Vista wim based setup.
            #>
            Write-Host "[$((Get-Date).ToString('MM/dd/yyyy hh:mm:ss tt'))] [Info] Type of setup detected: WIM Based Setup, Late 2002 revision."
            $Results += Identify-WIMLate2002($SetupPath)
        } else {
            <#
                Early-Late Vista wim based setup.
            #>
            Write-Host "[$((Get-Date).ToString('MM/dd/yyyy hh:mm:ss tt'))] [Info] Type of setup detected: WIM Based Setup, Fall 2003 revision."
            $Results += Identify-WIMFall2003($SetupPath)
        }
    } else {
        $foundsomething = $false
        if ( `
            (
                (Test-Path ($setuppath + '\ia64\ntoskrnl.ex_')) `
                -and `
                (Test-Path ($setuppath + '\ia64\txtsetup.sif')) `
            ) -or ( `
                (Test-Path ($setuppath + '\ia64\ntoskrnl.exe')) `
                -and `
                (Test-Path ($setuppath + '\ia64\txtsetup.sif')) `
            ) -or ( `
                (Test-Path ($setuppath + '\ia64\NTKRNLMP.ex_')) `
                -and `
                (Test-Path ($setuppath + '\ia64\txtsetup.sif')) `
            ) -or ( `
                (Test-Path ($setuppath + '\ia64\NTKRNLMP.exe')) `
                -and `
                (Test-Path ($setuppath + '\ia64\txtsetup.sif')) `
            ) `
        ) {
            $foundsomething = $true
            Write-Host "[$((Get-Date).ToString('MM/dd/yyyy hh:mm:ss tt'))] [Info] Type of setup detected: Text Based Setup, ia64 variant."
            $Results += Identify-TextSetup $SetupPath "ia64"
        }  
        if ( `
            (
                (Test-Path ($setuppath + '\amd64\ntoskrnl.ex_')) `
                -and `
                (Test-Path ($setuppath + '\amd64\txtsetup.sif')) `
            ) -or ( `
                (Test-Path ($setuppath + '\amd64\ntoskrnl.exe')) `
                -and `
                (Test-Path ($setuppath + '\amd64\txtsetup.sif')) `
            ) -or ( `
                (Test-Path ($setuppath + '\amd64\NTKRNLMP.ex_')) `
                -and `
                (Test-Path ($setuppath + '\amd64\txtsetup.sif')) `
            ) -or ( `
                (Test-Path ($setuppath + '\amd64\NTKRNLMP.exe')) `
                -and `
                (Test-Path ($setuppath + '\amd64\txtsetup.sif')) `
            ) `
        ) {
            $foundsomething = $true
            Write-Host "[$((Get-Date).ToString('MM/dd/yyyy hh:mm:ss tt'))] [Info] Type of setup detected: Text Based Setup, amd64 variant."
            $Results += Identify-TextSetup $SetupPath "amd64"
        } 
        if ( `
            (
                (Test-Path ($setuppath + '\i386\ntoskrnl.ex_')) `
                -and `
                (Test-Path ($setuppath + '\i386\txtsetup.sif')) `
            ) -or ( `
                (Test-Path ($setuppath + '\i386\ntoskrnl.exe')) `
                -and `
                (Test-Path ($setuppath + '\i386\txtsetup.sif')) `
            ) -or ( `
                (Test-Path ($setuppath + '\i386\NTKRNLMP.ex_')) `
                -and `
                (Test-Path ($setuppath + '\i386\txtsetup.sif')) `
            ) -or ( `
                (Test-Path ($setuppath + '\i386\NTKRNLMP.exe')) `
                -and `
                (Test-Path ($setuppath + '\i386\txtsetup.sif')) `
            ) `
        ) {
            $foundsomething = $true
            Write-Host "[$((Get-Date).ToString('MM/dd/yyyy hh:mm:ss tt'))] [Info] Type of setup detected: Text Based Setup, i386 variant."
            $Results += Identify-TextSetup $SetupPath "i386"
        } 
        if ( `
            (
                (Test-Path ($setuppath + '\alpha\ntoskrnl.ex_')) `
                -and `
                (Test-Path ($setuppath + '\alpha\txtsetup.sif')) `
            ) -or ( `
                (Test-Path ($setuppath + '\alpha\ntoskrnl.exe')) `
                -and `
                (Test-Path ($setuppath + '\alpha\txtsetup.sif')) `
            ) -or ( `
                (Test-Path ($setuppath + '\alpha\NTKRNLMP.ex_')) `
                -and `
                (Test-Path ($setuppath + '\alpha\txtsetup.sif')) `
            ) -or ( `
                (Test-Path ($setuppath + '\alpha\NTKRNLMP.exe')) `
                -and `
                (Test-Path ($setuppath + '\alpha\txtsetup.sif')) `
            ) `
        ) {
            $foundsomething = $true
            Write-Host "[$((Get-Date).ToString('MM/dd/yyyy hh:mm:ss tt'))] [Info] Type of setup detected: Text Based Setup, alpha variant."
            $Results += Identify-TextSetup $SetupPath "alpha"
        }
        if (-not ($foundsomething)) {
            $listofbuildpaths = (Get-ChildItem $setuppath\*WIN*.CAB -Recurse).DirectoryName | Select -uniq | Where-Object { ((Get-ChildItem $_\PRECOPY*.CAB) -ne $null) }
            if (($listofbuildpaths -ne $null) -and ($listofbuildpaths -ne '')) {
                foreach ($build in $listofbuildpaths) {
                     Write-Host "[$((Get-Date).ToString('MM/dd/yyyy hh:mm:ss tt'))] [Info] Type of setup detected: Cabinet Based Setup, Fall 1994 revision."
                    $Results += Identify-CabinetFall1994 $build
                }
            } else {
                $listofbuildpaths = (Get-ChildItem $setuppath\*CHICO*.CAB -Recurse).DirectoryName | Select -uniq | Where-Object { ((Get-ChildItem $_\PRECOPY*.CAB) -ne $null) }
                if (($listofbuildpaths -ne $null) -and ($listofbuildpaths -ne '')) {
                    foreach ($build in $listofbuildpaths) {
                        Write-Host "[$((Get-Date).ToString('MM/dd/yyyy hh:mm:ss tt'))] [Info] Type of setup detected: Cabinet Based Setup, Early 1994 revision."
                        $Results += Identify-CabinetEarly1994 $build
                    }
                } else {
                    Write-Host -ForegroundColor Red "[$((Get-Date).ToString('MM/dd/yyyy hh:mm:ss tt'))] [Error] Type of setup detected: None."
                }
            }
        }
    }
    return $Results
}

function Mount-Identify ($isofile) {
  # We mount the ISO File
  Write-Host "[$((Get-Date).ToString('MM/dd/yyyy hh:mm:ss tt'))] [Info] Mounting $($isofile)..."
  Mount-DiskImage -ImagePath $isofile.fullname

  # We get the mounted drive letter
  $letter = (Get-DiskImage -ImagePath $isofile.fullname | Get-Volume).driveletter + ":"
  
  if ($letter -eq ":") {
		Write-Host -ForegroundColor red "[$((Get-Date).ToString('MM/dd/yyyy hh:mm:ss tt'))] [Error] We couldn't mount the iso file successfully, please check this file manually."
		return
  }
  
  Write-Host "[$((Get-Date).ToString('MM/dd/yyyy hh:mm:ss tt'))] [Info] Mounted $($isofile) as drive $($letter)"

  $results = Identify-SetupPath $letter
  if ($results -is [Array]) {
      $counter = 0
      foreach ($result in $results) {
          $results[$counter].VolumeLabel = (Get-DiskImage -ImagePath $isofile.fullname | Get-Volume).FileSystemLabel
          $counter++
      }
  } else {
      $results.VolumeLabel = (Get-DiskImage -ImagePath $isofile.fullname | Get-Volume).FileSystemLabel
  }

  Write-Host "[$((Get-Date).ToString('MM/dd/yyyy hh:mm:ss tt'))] [Info] Dismounting $($isofile)..."
  Get-DiskImage -ImagePath $isofile.fullname | Dismount-DiskImage
  return $results
}

function Generate-Filename($Scheme, $Results, $addLabel) {
    switch($Scheme) {
        #Normal
        0 {
            $filename = ""
            foreach ($result in $Results) {
                $tmpfilename = $result.MajorVersion + "." + $result.MinorVersion + "." + $result.BuildNumber

                if (($result.DeltaVersion -ne $null) -and ($result.DeltaVersion -ne "")) {
                    $tmpfilename = $tmpfilename + "." + $results.DeltaVersion
                }

                if (($result.BranchName -ne $null) -and ($result.BranchName -ne "")) {
                    $tmpfilename = $tmpfilename + "." + $results.BranchName
                }

                if (($result.CompileDate -ne $null) -and ($result.CompileDate -ne "")) {
                    $tmpfilename = $tmpfilename + "." + $results.CompileDate
                }

                if (($result.Tag -ne $null) -and ($result.Tag -ne "")) {
                    $tmpfilename = $tmpfilename + "_" + $result.Tag
                }

                $tmpfilename = $tmpfilename + "_" + $result.Architecture + $result.BuildType

                $typestr = ""

                foreach ($type in $result.Type) {
                    if ($typestr -eq "") {
                        $typestr = $type
                    } else {
                        $typestr = $typestr + "-" + $type
                    }
                }

                if ($typestr -ne "") {
                    $tmpfilename = $tmpfilename + "_" + $typestr
                }

                if (($result.Sku -eq $null) -and ($result.Sku -eq $null)) {
                    $editionstr = ""
                    foreach ($sku in $result.Editions) {
                        if ($editionstr -eq "") {
                            $editionstr = $sku
                        } else {
                            $editionstr = $editionstr + "-" + $sku
                        }
                    }
                } else {
                    $editionstr = $result.Sku
                }

                if ($editionstr -ne "") {
                    $tmpfilename = $tmpfilename + "-" + $editionstr
                }

                if (($result.Licensing -ne $null) -and ($result.Licensing -ne "")) {
                    $tmpfilename = $tmpfilename + "_" + $result.Licensing
                }

                if (($result.LanguageCode -ne $null) -and ($result.LanguageCode -ne "")) {
                    $tmpfilename = $tmpfilename + "_" + $result.LanguageCode
                }

                $tmpfilename = $tmpfilename.toLower()

                if ($filename -eq "") {
                    $filename = $tmpfilename
                } else {
                    $filename = $filename + "-" + $tmpfilename
                }
            }
            if ($addLabel) {
                $filename = $filename + "-" + $results[0].VolumeLabel + ".iso"
            } else {
                $filename = $filename + ".iso"
            }
        }
        #Partner like
        1 {
            $filename = ""
            foreach ($result in $results) {
                $arch = $result.Architecture

                if ($result.Architecture -eq 'x86') {
                    $arch = 'x86'
                }

                if ($result.Architecture -eq 'amd64') {
                    $arch = 'x64'
                }

                if ($result.Architecture -eq 'arm') {
                    $arch = 'woa'
                }

                if (($result.Licensing -ne $null) -and ($result.Licensing -ne "")) {
                    if ($result.Licensing.toLower() -eq 'volume') {
                        $ltag = 'VOL'
                    } elseif ($result.Licensing.toLower() -eq 'oem') {
                        $ltag = 'OEM'
                    } else {
                        $ltag = 'RET'
                    }
                }

                $Editionstr = ""
                foreach ($edition in $result.Editions) {
                    if ($Editionstr -eq "") {
                        $Editionstr = $edition.toUpper()
                        if ($edition -eq 'CoreSingleLanguage') { $Editionstr = 'SINGLELANGUAGE' }
                        if ($edition -eq 'CoreCountrySpecific') { $Editionstr = 'CHINA' }
                        if ($edition -eq 'Professional') { $Editionstr = 'PRO' }
                        if ($edition -eq 'ProfessionalN') { $Editionstr = 'PRON' }
                        if ($edition -eq 'ProfessionalWMC') { $Editionstr = 'PROWMC' }
                        if ($edition -eq 'CoreConnectedCountrySpecific') { $Editionstr = 'CORECONNECTEDCHINA' }
                        if ($edition -eq 'ProfessionalStudent') { $Editionstr = 'PROSTUDENT' }
                        if ($edition -eq 'ProfessionalStudentN') { $Editionstr = 'PROSTUDENTN' }
                    } else {
                        $Editionstr = $Editionstr + '-' + $edition.toUpper()
                        if ($edition -eq 'CoreSingleLanguage') { $Editionstr = $Editionstr + '-' + 'SINGLELANGUAGE' }
                        if ($edition -eq 'CoreCountrySpecific') { $Editionstr = $Editionstr + '-' + 'CHINA' }
                        if ($edition -eq 'Professional') { $Editionstr = $Editionstr + '-' + 'PRO' }
                        if ($edition -eq 'ProfessionalN') { $Editionstr = $Editionstr + '-' + 'PRON' }
                        if ($edition -eq 'ProfessionalWMC') { $Editionstr = $Editionstr + '-' + 'PROWMC' }
                        if ($edition -eq 'CoreConnectedCountrySpecific') { $Editionstr = $Editionstr + '-' + 'CORECONNECTEDCHINA' }
                        if ($edition -eq 'ProfessionalStudent') { $Editionstr = $Editionstr + '-' + 'PROSTUDENT' }
                        if ($edition -eq 'ProfessionalStudentN') { $Editionstr = $Editionstr + '-' + 'PROSTUDENTN' }
                    }
                }

                if ($Editionstr -eq "PRO-CORE") {
                    $ltag = "OEMRET"
                } elseif ($Editionstr -eq "PRON-COREN") {
                    $ltag = "OEMRET"
                }

                $typestr = ""
                foreach ($type in $result.Type) {
                    if ($typestr -eq "") {
                        $typestr = $type
                    } else {
                        $typestr = $typestr + "-" + $type
                    }
                }

                $tmpfilename = $result.BuildNumber
                
                if (($result.DeltaVersion -ne $null) -and ($result.DeltaVersion -ne "")) {
                    $tmpfilename = $tmpfilename + "." + $results.DeltaVersion
                }

                if (($result.CompileDate -ne $null) -and ($result.CompileDate -ne "")) {
                    $tmpfilename = $tmpfilename + "." + $results.CompileDate
                }

                if (($result.BranchName -ne $null) -and ($result.BranchName -ne "")) {
                    $tmpfilename = $tmpfilename + "." + $results.BranchName
                }

                if (($result.Tag -ne $null) -and ($result.Tag -ne "")) {
                    $tmpfilename = $tmpfilename + "_" + $result.Tag
                }

                if ($typestr -ne "") {
                    $tmpfilename = $tmpfilename + "_" + $typestr
                }

                if (($result.Sku -eq $null) -and ($result.Sku -eq $null)) {
                    if (($Editionstr -ne $null) -and ($Editionstr -ne "")) {
                        $tmpfilename = $tmpfilename + $Editionstr
                    }
                } else {
                    $Editionstr = $result.Sku
                    if ($result.Sku -eq 'CoreSingleLanguage') { $Editionstr = 'SINGLELANGUAGE' }
                    if ($result.Sku -eq 'CoreCountrySpecific') { $Editionstr = 'CHINA' }
                    if ($result.Sku -eq 'Professional') { $Editionstr = 'PRO' }
                    if ($result.Sku -eq 'ProfessionalN') { $Editionstr = 'PRON' }
                    if ($result.Sku -eq 'ProfessionalWMC') { $Editionstr = 'PROWMC' }
                    if ($result.Sku -eq 'CoreConnectedCountrySpecific') { $Editionstr = 'CORECONNECTEDCHINA' }
                    if ($result.Sku -eq 'ProfessionalStudent') { $Editionstr = 'PROSTUDENT' }
                    if ($result.Sku -eq 'ProfessionalStudentN') { $Editionstr = 'PROSTUDENTN' }
                    $tmpfilename = $tmpfilename + $Editionstr
                }

                if (($ltag -ne $null) -and ($ltag -ne "")) {
                    $tmpfilename = $tmpfilename + "_" + $ltag
                }

                $tmpfilename = $tmpfilename + '_' + $arch + $result.BuildType

                if (($result.LanguageCode -ne $null) -and ($result.LanguageCode -ne "")) {
                    $tmpfilename = $tmpfilename + "_" + $result.LanguageCode
                }
                
                $tmpfilename = $tmpfilename.toUpper()

                if ($filename -eq "") {
                    $filename = $tmpfilename
                } else {
                    $filename = $filename + "-" + $tmpfilename
                }
            }
            if ($addLabel) {
                $filename = $filename + "-" + $results[0].VolumeLabel + ".ISO"
            } else {
                $filename = $filename + ".ISO"
            }
        }
        #Win7 like
        2 {
            $filename = ""
            foreach ($result in $results) {
                if ($result.LanguageCode -eq 'en-gb') {
                    $lang = 'en-gb'
                } elseif ($result.LanguageCode -eq 'es-mx') {
                    $lang = 'es-mx'
                } elseif ($result.LanguageCode -eq 'fr-ca') {
                    $lang = 'fr-ca'
                } elseif ($result.LanguageCode -eq 'pt-pt') {
                    $lang = 'pp'
                } elseif ($result.LanguageCode -eq 'sr-latn-rs') {
                    $lang = 'sr-latn'
                } elseif ($result.LanguageCode -eq 'zh-cn') {
                    $lang = 'cn'
                } elseif ($result.LanguageCode -eq 'zh-tw') {
                    $lang = 'tw'
                } elseif ($result.LanguageCode -eq 'zh-hk') {
                    $lang = 'hk'
                } else {
                    $lang = $result.LanguageCode.split('-')[0]
                }

                $arch = $result.Architecture
                $EditionID = $null

                foreach ($item_ in $result.Editions) {
                    if ($EditionID -eq $null) {
                        $EditionID = $item_
                    } else {
                        $EditionID = $EditionID + '-' + $item_
                    }
                }

                if ($result.BranchName -ne $null) {
                    $tmpfilename = ($lang.toLower()) + '_' + $result.BuildNumber + '.' + $result.DeltaVersion + '.' + $result.BranchName + '.' + $result.CompileDate + '_' + $arch + $result.BuildType + '_' + $result.Sku + '_' + ($result.LanguageCode.toLower()) + '_' + $EditionID
                    if ($EditionID.toLower() -eq 'enterprise') { 
                        $tmpfilename = ($lang.toLower()) + '_' + $result.BuildNumber + '.' + $result.DeltaVersion + '.' + $result.BranchName + '.' + $result.CompileDate + '_' + $arch + $result.BuildType + '_' + $result.Sku + '_' + ($result.LanguageCode.toLower()) + '_VL_' + $EditionID
                    }
                    if ($EditionID.toLower() -eq 'enterprisen') {
                        $tmpfilename = ($lang.toLower()) + '_' + $result.BuildNumber + '.' + $result.DeltaVersion + '.' + $result.BranchName + '.' + $result.CompileDate + '_' + $arch + $result.BuildType + '_' + $result.Sku + '_' + ($result.LanguageCode.toLower()) + '_VL_' + $EditionID
                    }
                } else {
                    $tmpfilename = ($lang.toLower()) + '_' + $result.BuildNumber + '.' + $result.DeltaVersion + '.' + $result.CompileDate + '_' + $arch + $result.BuildType + '_' + $result.Sku + '_' + ($result.LanguageCode.toLower()) + '_' + $EditionID
                    if ($EditionID.toLower() -like '*enterprise*') {
                        $tmpfilename = ($lang.toLower()) + '_' + $result.BuildNumber + '.' + $result.DeltaVersion + '_' + $arch + $result.BuildType + '_' + $result.Sku + '_' + ($result.LanguageCode.toLower()) + '_VL_' + $EditionID
                    }
                }
                if ($filename -eq "") {
                    $filename = $tmpfilename
                } else {
                    $filename = $filename + "-" + $tmpfilename
                }
            }
            $filename = $filename + '-' + $result[0].VolumeLabel + '.iso'
        }
    }
    return $filename
}