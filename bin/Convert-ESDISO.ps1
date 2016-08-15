<#
.SYNOPSIS
    Converts a Windows Store infrastructure electronic software download file (ESD) to a fully functional Windows Installation disc image.
.DESCRIPTION
    This cmdlet will be able to convert any type of esd files, even encrypted ones into a fully functional ISO. The cmdlet will succeed only if a valid decryption key was found or the ESD file wasn't encrypted and if the ESD file is a valid ESD file.
.PARAMETER ESDFiles
    An array or a string of paths to some ESD Files that will be used for the install.wim image file.
.PARAMETER Destination
    A string containing the path where the ISO file will be created.
.PARAMETER DecryptionKey
    An optional RSA Key that will be used to decrypt the ESD file.
.PARAMETER TempDirectory
    An optional path to a custom temporary directory that will be used to decrypt the ESD file.
.PARAMETER x86RecoveryEnvESD
    The path to the esd that will be used for the Recovery environment. (boot.wim /index:1)
.PARAMETER x86PEESD
    The path to the esd that will be used for the Pre-installation environment. (boot.wim /index:2)
.PARAMETER x64RecoveryEnvESD
    The path to the esd that will be used for the Recovery environment. (boot.wim /index:1)
.PARAMETER x64PEESD
    The path to the esd that will be used for the Pre-installation environment. (boot.wim /index:2)
.PARAMETER woaRecoveryEnvESD
    The path to the esd that will be used for the Recovery environment. (boot.wim /index:1)
.PARAMETER woaPEESD
    The path to the esd that will be used for the Pre-installation environment. (boot.wim /index:2)
.EXAMPLE
    Convert-ESDISO.ps1 -ESDFiles "D:\ESDs\9926.esd" -Destination "D:\ISOs\Converted ESDs\"
.EXAMPLE
    Convert-ESDISO.ps1 -ESDFiles @("D:\ESDs\9926.esd", "D:\ESDs\9925.esd") -Destination "D:\ISOs\Converted ESDs\"
.EXAMPLE
    Convert-ESDISO.ps1 -ESDFiles "D:\ESDs\9926.esd" -Destination "D:\ISOs\Converted ESDs\" -DecryptionKey "BwIAAACkAABSU0EyAAgAAAEAAQCb7Jceg+YeJXNdb7HHJ0irxNsGSWu7itcuEQkfS+znxm6XwxmfINt8SGzbIIka2eOB2t9L0lGwSM0uP3UPyhBzzc8FL735OL+RnimL4SVKDb5AsYpREOcNQgKsk6OOeo8q8+4+swvwfe6+VloNqCrjiE6bCS7TrC+haV+eabj1QaT+aSXNWrukmrvi1VFoQIVeet5BqHzciVV+bv3/iSG/EEkxV6Yqq4Y2o9bvSDIbE+lGc1bKPlT9zy+lYx+WMB0Nfzo7nIrKs7qCw8GbeRTsHo5GMWxrLNltFsDpoO0C62pSvxEGB/id2TwESrd7brudppjjJ+LdbCBUNam6zx2lhZmjconDvvWLYC6KXVVgTh5WHjv8z0dxkD+Hc6o6OhdXuxAA5xtZYgIah8t2ZVK5V2PEFnusqZP7fqbSUJOp6sZe3AZWWVZz6dg6VqYpDMbKBz8rhHXXHjkaqIMrmxnSmHoB4fsxelWre9oxQoQJUkASAUhflDPKtFVe30oLsN6fNwBBNVKywJogPsClqIuNiQDpsXRFg8PYBgvqDQz8DRfDpu5WyhQjdD+eVQpeczWmTyPuwfGB0TscKDhzIhSwebKK0NwCn2LunmdJEOjJsnsYLrE63rsQdcXimzPifQ5XWlV9GUqo5ce+AlX0IMmw7DSZJBe9Sr1adBFuHQvRvQ1tGyQ5oD7WxKshS8WbvKT6cZb0XBE0Ru82gl9uSvJAgOJG9E8g7BApwCfaWAMEVj/Xd8DZSjZ0VWxRlsVkhjxWeiiQWg85J08JdjC2soG14IiXRTVAGogUTcUVlOPkovrWoRVqTMLAA+Vh0R6BpcAexwUv4YVmw2661iDUmnkYWyXMcSBQP43h5SjdLirO19b/1UD9lvaCaZpyokKMD6+GNJyCX9stVuS7c1ow/nsuVDgx3Rv7wE0as5h9WSheM5p6Lzf1UTHy1Mg2XpJAn37amw7rUnOkz4qqJ5ItRwAAhRn2Cn+PUtp5Ti1vfHmPd0PodAdTUo+5lYOGmXJxx0SHTh3dSCkSIJWjoAFYnrtEWMTszcenxYlZc2e6dWNZUPO4VyftrGkF4FpWxFC63Gd15uf3vUlStFXRArMh9KQ14sf4PGmpxmoXNZBWNsa7xizW83lkS3sbtnHtLEk6xyJ01sj+HWPoEuTzSbs6v3P8NstpN37xJui+hafIA5ILpB04qlxrxIRKEow31QzrMINyiwjCnxzIrXFuEQq9aY1930q5XgYfoV8OZirdIWKYtvPWzBgEkmi5w930kqjRyA81XwhH74guWww7A1lImbygBDl5wyE8GRVg2Emy7pU2sybyvtjMLSBgmTK8h6UqEXaupvuVCYjC8BzkUGWfTG9eh50TPpFZMO4vB2l2tbfwA2oTBwvjuwaDwdUIFXYjmdti3A+EGuhvDAeGzGxZhOmQir84CYXEKMj4yaqFvaKecMCtOOwWWpAEIzRWxXJIXN6EPqiZGEauZUAXjicVI/jpkKGhWUnaLZhNFTYD6Nl/eBMA2TPj6w4AiOnr21bDjgE="
.NOTES
    Author: Gustave M.
    Date:   June 29, 2016  
#>
[CmdletBinding()]
param(
  [Parameter(Mandatory = $true,HelpMessage = "An array or a string of paths to some ESD Files that will be used for the install.wim image file.")]
  [ValidateNotNullOrEmpty()]
  [string[]]
  $ESDFiles,

  [Parameter(Mandatory = $true,HelpMessage = "A string containing the path where the ISO file will be created.")]
  [ValidateNotNullOrEmpty()]
  [ValidateScript({ (Test-Path $_) })]
  [string]
  $Destination = ".\",

  [Parameter(Mandatory = $false,HelpMessage = "An optional RSA Key that will be used to decrypt the ESD file.")]
  [ValidateNotNullOrEmpty()]
  [string]
  $DecryptionKey,

  [Parameter(Mandatory = $false,HelpMessage = "An optional path to a custom temporary directory that will be used to decrypt the ESD file.")]
  [ValidateNotNullOrEmpty()]
  [ValidateScript({ (Test-Path $_) })]
  [string]
  $TempDirectory,


  [Parameter(Mandatory = $false,HelpMessage = "The path to the esd that will be used for the Recovery environment. (boot.wim /index:1)")]
  [ValidateNotNullOrEmpty()]
  [ValidateScript({ (Test-Path $_) })]
  [string]
  $x86RecoveryEnvESD,

  [Parameter(Mandatory = $false,HelpMessage = "The path to the esd that will be used for the Pre-installation environment. (boot.wim /index:2)")]
  [ValidateNotNullOrEmpty()]
  [ValidateScript({ (Test-Path $_) })]
  [string]
  $x86PEESD,

  [Parameter(Mandatory = $false,HelpMessage = "The path to the esd that will be used for the Recovery environment. (boot.wim /index:1)")]
  [ValidateNotNullOrEmpty()]
  [ValidateScript({ (Test-Path $_) })]
  [string]
  $x64RecoveryEnvESD,

  [Parameter(Mandatory = $false,HelpMessage = "The path to the esd that will be used for the Pre-installation environment. (boot.wim /index:2)")]
  [ValidateNotNullOrEmpty()]
  [ValidateScript({ (Test-Path $_) })]
  [string]
  $x64PEESD,

  [Parameter(Mandatory = $false,HelpMessage = "The path to the esd that will be used for the Recovery environment. (boot.wim /index:1)")]
  [ValidateNotNullOrEmpty()]
  [ValidateScript({ (Test-Path $_) })]
  [string]
  $woaRecoveryEnvESD,

  [Parameter(Mandatory = $false,HelpMessage = "The path to the esd that will be used for the Pre-installation environment. (boot.wim /index:2)")]
  [ValidateNotNullOrEmpty()]
  [ValidateScript({ (Test-Path $_) })]
  [string]
  $woaPEESD
)

<#
	Location of the required binaries for this script
#>
$bin = (Split-Path -Parent -Path $MyInvocation.MyCommand.Definition)

<#
	Location of the root folder for GusTools
#>
$root = $((Split-Path -Parent -Path $MyInvocation.MyCommand.Definition).Split('\')[0..($(Split-Path -Parent -Path $MyInvocation.MyCommand.Definition).Split('\').Count - 2)] -join '\')

<#
	Location of the current version xml
#>
$locver = "$($bin)\version.xml"

[xml]$curver = Get-Content $locver

Write-Host "
$($curver.versioninfo.branding.title) - ESD to ISO Converter
$($curver.versioninfo.branding.copyright)
$($curver.versioninfo.version.version) - $($curver.versioninfo.version.buildstring)
"

$Global:toolpath = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
$Global:cdimage253 = "$($toolpath)\cdimage\2.53\cdimage.exe"
$Global:decryptesd = "$($toolpath)\decryptesd\decryptesd.exe"
$Global:7z = "$($toolpath)\7z\7z.exe"

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

if ($TempDirectory -eq "") {
  if (-not (Test-Path "$(Split-Path -Parent -Path $MyInvocation.MyCommand.Definition)\tmp")) {
    New-Item -Path "$(Split-Path -Parent -Path $MyInvocation.MyCommand.Definition)\tmp" -ItemType "directory" | Out-Null
  }
  $TempDirectory = "$(Split-Path -Parent -Path $MyInvocation.MyCommand.Definition)\tmp"
}

if (-not (ValidateEnv)) {
  return $false
}

$Mediadir = "$($TempDirectory)\Media"

if (-not (Test-Path $Mediadir)) {
  New-Item -Path $Mediadir -ItemType "directory" | Out-Null
}

function New-x64x86Media {
  Copy-Item $Mediadir\x86\boot\ $Mediadir\ -Recurse
  Copy-Item $Mediadir\x86\efi\ $Mediadir\ -Recurse
  Copy-Item $Mediadir\x86\bootmgr $Mediadir\
  Copy-Item $Mediadir\x86\bootmgr.efi $Mediadir\
  Copy-Item $Mediadir\x86\autorun.inf $Mediadir\
  Copy-Item $Mediadir\x86\setup.exe $Mediadir\
  Copy-Item $Mediadir\x64\efi\boot\bootx64.efi $Mediadir\efi\boot\
  $x64guid = bcdedit /store $Mediadir\boot\bcd /v `
     | Select-String "path" -Context 2,0 `
     | % { $_.Context.PreContext[0] -replace '^identifier +' } `
     | ? { $_ -ne "{default}" }
  bcdedit /store $Mediadir\boot\bcd /set "{default}" description "Windows 10 Setup (64-bit)"
  bcdedit /store $Mediadir\boot\bcd /set "{default}" device ramdisk=[boot]\x64\sources\boot.wim,$x64guid
  bcdedit /store $Mediadir\boot\bcd /set "{default}" osdevice ramdisk=[boot]\x64\sources\boot.wim,$x64guid
  bcdedit /store $Mediadir\boot\bcd /copy "{default}" /d "Windows 10 Setup (32-bit)"
  $x86guid = bcdedit /store $Mediadir\boot\bcd /v `
     | Select-String "path" -Context 2,0 `
     | % { $_.Context.PreContext[0] -replace '^identifier +' } `
     | ? { $_ -ne "$x64guid" }
  bcdedit /store $Mediadir\boot\bcd /set "$($x86guid)" device ramdisk=[boot]\x86\sources\boot.wim,$x64guid
  bcdedit /store $Mediadir\boot\bcd /set "$($x86guid)" osdevice ramdisk=[boot]\x86\sources\boot.wim,$x64guid
  Remove-Item $Mediadir\boot\bcd.LOG -Force
  Remove-Item $Mediadir\boot\bcd.LOG1 -Force
  Remove-Item $Mediadir\boot\bcd.LOG2 -Force
}

function New-x64x86armMedia {
  Copy-Item $Mediadir\x86\boot\ $Mediadir\ -Recurse
  Copy-Item $Mediadir\x86\efi\ $Mediadir\ -Recurse
  Copy-Item $Mediadir\x86\bootmgr $Mediadir\
  Copy-Item $Mediadir\x86\bootmgr.efi $Mediadir\
  Copy-Item $Mediadir\x86\autorun.inf $Mediadir\
  Copy-Item $Mediadir\x86\setup.exe $Mediadir\
  Copy-Item $Mediadir\x64\efi\boot\bootx64.efi $Mediadir\efi\boot\
  Copy-Item $Mediadir\arm\efi\boot\bootarm.efi $Mediadir\efi\boot\
  $x64guid = bcdedit /store $Mediadir\boot\bcd /v `
     | Select-String "path" -Context 2,0 `
     | % { $_.Context.PreContext[0] -replace '^identifier +' } `
     | ? { $_ -ne "{default}" }
  bcdedit /store $Mediadir\boot\bcd /set "{default}" description "Windows 10 Setup (64-bit)"
  bcdedit /store $Mediadir\boot\bcd /set "{default}" device ramdisk=[boot]\x64\sources\boot.wim,$x64guid
  bcdedit /store $Mediadir\boot\bcd /set "{default}" osdevice ramdisk=[boot]\x64\sources\boot.wim,$x64guid
  bcdedit /store $Mediadir\boot\bcd /copy "{default}" /d "Windows 10 Setup (32-bit)"
  $x86guid = bcdedit /store $Mediadir\boot\bcd /v `
     | Select-String "path" -Context 2,0 `
     | % { $_.Context.PreContext[0] -replace '^identifier +' } `
     | ? { $_ -ne "$x64guid" }
  bcdedit /store $Mediadir\boot\bcd /set "$($x86guid)" device ramdisk=[boot]\x86\sources\boot.wim,$x64guid
  bcdedit /store $Mediadir\boot\bcd /set "$($x86guid)" osdevice ramdisk=[boot]\x86\sources\boot.wim,$x64guid
  bcdedit /store $Mediadir\boot\bcd /copy "{default}" /d "Windows 10 Setup (ARM)"
  $armguid = bcdedit /store $Mediadir\boot\bcd /v `
     | Select-String "path" -Context 2,0 `
     | % { $_.Context.PreContext[0] -replace '^identifier +' } `
     | ? { ($_ -ne "$x64guid") -and ($_ -ne "$x86guid") }
  bcdedit /store $Mediadir\boot\bcd /set "$($armguid)" device ramdisk=[boot]\arm\sources\boot.wim,$x64guid
  bcdedit /store $Mediadir\boot\bcd /set "$($armguid)" osdevice ramdisk=[boot]\arm\sources\boot.wim,$x64guid
  Remove-Item $Mediadir\boot\bcd.LOG -Force
  Remove-Item $Mediadir\boot\bcd.LOG1 -Force
  Remove-Item $Mediadir\boot\bcd.LOG2 -Force
}

function Copy-File {
  param([string]$from,[string]$to)
  $ffile = [io.file]::OpenRead($from)
  $tofile = [io.file]::OpenWrite($to)
  Write-Progress `
     -Activity "Copying file" `
     -Status ($from.Split("\") | select -Last 1) `
     -PercentComplete 0
  try {
    $sw = [System.Diagnostics.Stopwatch]::StartNew();
    [byte[]]$buff = New-Object byte[] (4096 * 1024)
    [long]$total = [long]$count = 0
    do {
      $count = $ffile.Read($buff,0,$buff.Length)
      $tofile.Write($buff,0,$count)
      $total += $count
      [int]$pctcomp = ([int]($total / $ffile.Length * 100));
      [int]$secselapsed = [int]($sw.elapsedmilliseconds.ToString()) / 1000;
      if ($secselapsed -ne 0) {
        [single]$xferrate = (($total / $secselapsed) / 1mb);
      } else {
        [single]$xferrate = 0.0
      }
      if ($total % 1mb -eq 0) {
        if ($pctcomp -gt 0) `
           { [int]$secsleft = ((($secselapsed / $pctcomp) * 100) - $secselapsed);
        } else {
          [int]$secsleft = 0 };
        Write-Progress `
           -Activity ("Copying file at " + "{0:n2}" -f $xferrate + " MB/s") `
           -Status ($from.Split("\") | select -Last 1) `
           -PercentComplete $pctcomp `
           -SecondsRemaining $secsleft;
      }
    } while ($count -gt 0)
    $sw.Stop();
    $sw.Reset();
  }
  finally {
    Write-Progress -Activity ($pctcomp.ToString() + "% Copying file @ " + "{0:n2}" -f $xferrate + " MB/s") -Complete
    Write-Host "[$((Get-Date).ToString('MM/dd/yyyy hh:mm:ss tt'))] [Info]" (($from.Split("\") | select -Last 1) + `
         " copied in " + $secselapsed + " seconds at " + `
         "{0:n2}" -f [int](($ffile.Length / $secselapsed) / 1mb) + " MB/s.");
    $ffile.Close();
    $tofile.Close();

  }
}

function Decrypt-ESDs ($ESDs) {
  $NewESDs = @()
  foreach ($ESD in $ESDs) {
    Write-Host "[$((Get-Date).ToString('MM/dd/yyyy hh:mm:ss tt'))] [Info] Gathering informations for $($ESD)"
    & $wimlib info "$($ESD)" 2>&1| Out-Null
    if ($LASTEXITCODE -eq 74) {
      Write-Host -ForegroundColor yellow "[$((Get-Date).ToString('MM/dd/yyyy hh:mm:ss tt'))] [Warning] $($ESD) is encrypted, attempting to decrypt the file"
      $ESDModPath = "$($TempDirectory)\$((Get-ChildItem $ESD).Name).mod"
      Copy-File -From "$($ESD)" -To "$ESDModPath"
      if (($DecryptionKey -eq $null) -or ($DecryptionKey -eq "")) {
        & $decryptesd "-f" "$($ESDModPath)"
      } else {
        & $decryptesd "-f" "$($ESDModPath)" "-k" "$($DecryptionKey)"
      }
      if ($LASTEXITCODE -ne 0) {
        Write-Host -ForegroundColor red "[$((Get-Date).ToString('MM/dd/yyyy hh:mm:ss tt'))] [Error] Decryption failed for $($ESD)"
        return $false
      }
      $NewESDs += $ESDModPath
    } elseif ($LASTEXITCODE -ne 0) {
      Write-Host -ForegroundColor red "[$((Get-Date).ToString('MM/dd/yyyy hh:mm:ss tt'))] [Error] Couldn't read $($ESD)"
      return $false
    } else {
      $NewESDs += $ESD
    }
  }
  return $NewESDs
}

function GatherMinimalInfos ($esdfile) {
  $counter = 0

  $WIMInfo = New-Object System.Collections.ArrayList
  $WIMInfo = @{}

  for ($i = 1; $i -le 3; $i++) {
    $counter++
    $WIMInfo[$counter] = @{}
    $OutputVariable = (& $wimlib info "$($esdfile)" $i)
    if ($LASTEXITCODE -ne 0) {
      Write-Host -ForegroundColor red "[$((Get-Date).ToString('MM/dd/yyyy hh:mm:ss tt'))] [Error] Gathering informations failed for $($esdfile)"
      return $false
    }
    foreach ($Item in $OutputVariable) {
      $CurrentItem = ($Item -replace '\s+',' ').Split(':')
      $CurrentItemName = $CurrentItem[0] -replace ' ',''
      if (($CurrentItem[1] -replace ' ','') -ne '') {
        $WIMInfo[$counter][$CurrentItemName] = $CurrentItem[1].Substring(1)
      }
    }
  }

  $header = @{}
  $OutputVariable = (& $wimlib info "$($esdfile)" --header)
  if ($LASTEXITCODE -ne 0) {
    Write-Host -ForegroundColor red "[$((Get-Date).ToString('MM/dd/yyyy hh:mm:ss tt'))] [Error] Gathering informations failed for $($esdfile)"
    return $false
  }
  foreach ($Item in $OutputVariable) {
    $CurrentItem = ($Item -replace '\s+',' ').Split('=')
    $CurrentItemName = $CurrentItem[0] -replace ' ',''
    if (($CurrentItem[1] -replace ' ','') -ne '') {
      $header[$CurrentItemName] = $CurrentItem[1].Substring(1)
    }
  }

  for ($i = 4; $i -le $header.ImageCount; $i++) {
    $counter++
    $WIMInfo[$counter] = @{}
    $OutputVariable = (& $wimlib info "$($esdfile)" $i)
    foreach ($Item in $OutputVariable) {
      $CurrentItem = ($Item -replace '\s+',' ').Split(':')
      $CurrentItemName = $CurrentItem[0] -replace ' ',''
      if (($CurrentItem[1] -replace ' ','') -ne '') {
        $WIMInfo[$counter][$CurrentItemName] = $CurrentItem[1].Substring(1)
      }
    }
  }

  $WIMInfo["header"] = @{}
  $WIMInfo["header"]["ImageCount"] = ($counter.ToString())

  return $WIMInfo
}

$ESDsToProcess = Decrypt-ESDs $ESDFiles
if ($ESDsToProcess -eq $false) {
  Write-Host -ForegroundColor red "[$((Get-Date).ToString('MM/dd/yyyy hh:mm:ss tt'))] [Error] Gathering informations step failed, cleaning temporary directory and aborting execution"
  Remove-Item -Path $TempDirectory -Recurse
  return $false
}

$x86ESDs = @()
$x64ESDs = @()
$woaESDs = @()

foreach ($esdfile in $ESDsToProcess) {
  $tmpinfo = GatherMinimalInfos ($esdfile)
  if ($tmpinfo -eq $false) {
    Write-Host -ForegroundColor red "[$((Get-Date).ToString('MM/dd/yyyy hh:mm:ss tt'))] [Error] Gathering informations step failed, cleaning temporary directory and aborting execution"
    Remove-Item -Path $TempDirectory -Recurse
    return $false
  }
  Write-Host "[$((Get-Date).ToString('MM/dd/yyyy hh:mm:ss tt'))] [Info] Processing $($tmpinfo[4].DisplayName) $($tmpinfo[2].MajorVersion).$($tmpinfo[4].MinorVersion).$($tmpinfo[4].Build).$($tmpinfo[4].ServicePackBuild) $($tmpinfo[4].Architecture)"
  switch ($tmpinfo[3].Architecture) {
    "x86" {
      $x86ESDs += $esdfile
    }
    "x86_64" {
      $x64ESDs += $esdfile
    }
    "woa" {
      $woaESDs += $esdfile
    }
    "arm" {
      $woaESDs += $esdfile
    }
  }
}

function Convert-Single ($InstallESDs,$PEESD,$REESD,$Output) {
  Write-Host "[$((Get-Date).ToString('MM/dd/yyyy hh:mm:ss tt'))] [Info] Expanding Setup files - In Progress"
  $name = $null
  & $wimlib apply "$($PEESD)" 1 "$($Output)" | ForEach-Object -Process {
    if ($name -eq $null) {
      $name = $_
    }
    $progress = [regex]::match($_,'\(([^\)]+)\%').Groups[1].Value
    if ($progress -match "[0-9]") {
      Write-Progress -Activity ('Expanding Setup files...') -Status ($name) -PercentComplete $progress -CurrentOperation $_
    }
  }
  Write-Progress -Activity ('Expanding Setup files...') -Complete
  Remove-Item "$($Output)\MediaMeta.xml"
  Write-Host "[$((Get-Date).ToString('MM/dd/yyyy hh:mm:ss tt'))] [Info] Expanding Setup files - Done"

  Write-Host "[$((Get-Date).ToString('MM/dd/yyyy hh:mm:ss tt'))] [Info] Exporting Windows Recovery environement - In Progress"
  $sw = [System.Diagnostics.Stopwatch]::StartNew();
  $operationname = $null
  & $wimlib export "$($REESD)" 2 "$($Output)\sources\boot.wim" --compress=maximum | ForEach-Object -Process {
    if ($operationname -eq $null) {
      $operationname = $_
    }
    $global:lastprogress = $progress
    $global:progress = [regex]::match($_,'\(([^\)]+)\%').Groups[1].Value
    if ($global:progress -match "[0-9]") {
      $total = $_.Split(' ')[0]
      $totalsize = $_.Split(' ')[3]
      [long]$pctcomp = ([long]($total / $totalsize * 100));
      [long]$secselapsed = [long]($sw.elapsedmilliseconds.ToString()) / 1000;
      if ($pctcomp -ne 0) {
        [long]$secsleft = ((($secselapsed / $pctcomp) * 100) - $secselapsed)
      } else {
        [long]$secsleft = 0
      }
      Write-Progress -Activity ('Exporting Windows Recovery environement...') -Status ($operationname) -PercentComplete ($global:progress) -SecondsRemaining $secsleft -CurrentOperation $_
    }
  }
  $sw.Stop();
  $sw.Reset();
  Write-Host "[$((Get-Date).ToString('MM/dd/yyyy hh:mm:ss tt'))] [Info] Exporting Windows Recovery environement - Done"
  Write-Progress -Activity ('Exporting Windows Recovery environement...') -Complete

  Write-Host "[$((Get-Date).ToString('MM/dd/yyyy hh:mm:ss tt'))] [Info] Exporting Windows Preinstallation environement - In Progress"
  $sw = [System.Diagnostics.Stopwatch]::StartNew();
  $operationname = $null
  & $wimlib export "$($PEESD)" 3 "$($Output)\sources\boot.wim" --boot | ForEach-Object -Process {
    if ($operationname -eq $null) {
      $operationname = $_
    }
    $global:lastprogress = $progress
    $global:progress = [regex]::match($_,'\(([^\)]+)\%').Groups[1].Value
    if ($global:progress -match "[0-9]") {
      $total = $_.Split(' ')[0]
      $totalsize = $_.Split(' ')[3]
      [long]$pctcomp = ([long]($total / $totalsize * 100));
      [long]$secselapsed = [long]($sw.elapsedmilliseconds.ToString()) / 1000;
      if ($pctcomp -ne 0) {
        [long]$secsleft = ((($secselapsed / $pctcomp) * 100) - $secselapsed)
      } else {
        [long]$secsleft = 0
      }
      Write-Progress -Activity ('Exporting Windows Preinstallation environement...') -Status ($operationname) -PercentComplete ($global:progress) -SecondsRemaining $secsleft -CurrentOperation $_
    }
  }
  $sw.Stop();
  $sw.Reset();
  Write-Host "[$((Get-Date).ToString('MM/dd/yyyy hh:mm:ss tt'))] [Info] Exporting Windows Preinstallation environement - Done"
  Write-Progress -Activity ('Exporting Windows Preinstallation environement...') -Complete

  Write-Host "[$((Get-Date).ToString('MM/dd/yyyy hh:mm:ss tt'))] [Info] Exporting Windows Installation - In Progress"
  foreach ($esdfile in $InstallESDs) {
    $header = @{}
    $OutputVariable = (& $wimlib info "$($esdfile)" --header)
    foreach ($Item in $OutputVariable) {
      $CurrentItem = ($Item -replace '\s+',' ').Split('=')
      $CurrentItemName = $CurrentItem[0] -replace ' ',''
      if (($CurrentItem[1] -replace ' ','') -ne '') {
        $header[$CurrentItemName] = $CurrentItem[1].Substring(1)
      }
    }
    for ($i = 4; $i -le $header.ImageCount; $i++) {
      $operationname = $null
      $sw = [System.Diagnostics.Stopwatch]::StartNew();
      $indexcount = 1
      if (Test-Path $Output\sources\install.wim) {
        $header = @{}
        $OutputVariable = (& $wimlib info "$($Output)\sources\install.wim" --header)
        foreach ($Item in $OutputVariable) {
          $CurrentItem = ($Item -replace '\s+',' ').Split('=')
          $CurrentItemName = $CurrentItem[0] -replace ' ',''
          if (($CurrentItem[1] -replace ' ','') -ne '') {
            $header[$CurrentItemName] = $CurrentItem[1].Substring(1)
          }
        }
        $indexcount = $header.ImageCount + 1
      }
      & $wimlib export "$($esdfile)" $i "$($Output)\sources\install.wim" --compress=maximum | ForEach-Object -Process {
        if ($operationname -eq $null) {
          $operationname = $_
        }
        $lastprogress = $progress
        $progress = [regex]::match($_,'\(([^\)]+)\%').Groups[1].Value
        if ($progress -match "[0-9]") {
          $total = $_.Split(' ')[0]
          $totalsize = $_.Split(' ')[3]
          [long]$pctcomp = ([long]($total / $totalsize * 100));
          [long]$secselapsed = [long]($sw.elapsedmilliseconds.ToString()) / 1000;
          if ($pctcomp -ne 0) {
            [long]$secsleft = ((($secselapsed / $pctcomp) * 100) - $secselapsed)
          } else {
            [long]$secsleft = 0
          }
          Write-Progress -Activity ('Exporting Windows Installation...') -Status ($operationname) -PercentComplete ($progress) -SecondsRemaining $secsleft -CurrentOperation $_
        }
      }
    }
  }
  Write-Host "[$((Get-Date).ToString('MM/dd/yyyy hh:mm:ss tt'))] [Info] Exporting Windows Installation - Done"
  Write-Progress -Activity ('Exporting Windows Installation...') -Complete
}

if ($x86ESDs -ne @()) {
  if ($x64ESDs -ne @()) {
    if ($woaESDs -ne @()) {
      #Multi woa x86 x64 here
      Write-Host -ForegroundColor red "[$((Get-Date).ToString('MM/dd/yyyy hh:mm:ss tt'))] [Error] ARM Support is not yet supported for creating multiarchitectural images"
    } else {

      if ($x86PEESD -eq "") {
        $x86PEESD = $x86ESDs[0]
      }
      if ($x86RecoveryEnvESD -eq "") {
        $x86RecoveryEnvESD = $x86ESDs[0]
      }
      Convert-Single -InstallESDs $x86ESDs -PEESD $x86PEESD -REESD $x86RecoveryEnvESD -Output "$($Mediadir)\x86\"
      if ($x64PEESD -eq "") {
        $x64PEESD = $x64ESDs[0]
      }
      if ($x64RecoveryEnvESD -eq "") {
        $x64RecoveryEnvESD = $x64ESDs[0]
      }
      Convert-Single -InstallESDs $x64ESDs -PEESD $x64PEESD -REESD $x64RecoveryEnvESD -Output "$($Mediadir)\x64\"
      New-x64x86Media
      & "$($toolpath)\Rebuild-ISO.ps1" -SourcePath "$($Mediadir)" -Destination "$($Destination)"

    }
  } else {

    if ($x86PEESD -eq "") {
      $x86PEESD = $x86ESDs[0]
    }
    if ($x86RecoveryEnvESD -eq "") {
      $x86RecoveryEnvESD = $x86ESDs[0]
    }
    Convert-Single -InstallESDs $x86ESDs -PEESD $x86PEESD -REESD $x86RecoveryEnvESD -Output "$($Mediadir)"
    & "$($toolpath)\Rebuild-ISO.ps1" -SourcePath "$($Mediadir)" -Destination "$($Destination)"

  }
} else {
  if ($x64ESDs -ne @()) {
    if ($woaESDs -ne @()) {
      #Multi woa x64 here
      Write-Host -ForegroundColor red "[$((Get-Date).ToString('MM/dd/yyyy hh:mm:ss tt'))] [Error] ARM Support is not yet supported for creating multiarchitectural images"
    } else {

      if ($x64PEESD -eq "") {
        $x64PEESD = $x64ESDs[0]
      }
      if ($x64RecoveryEnvESD -eq "") {
        $x64RecoveryEnvESD = $x64ESDs[0]
      }
      Convert-Single -InstallESDs $x64ESDs -PEESD $x64PEESD -REESD $x64RecoveryEnvESD -Output $Mediadir
      & "$($toolpath)\Rebuild-ISO.ps1" -SourcePath "$($Mediadir)" -Destination "$($Destination)"
    }
  } elseif ($woaESDs -ne @()) {
      if ($woaPEESD -eq "") {
        $woaPEESD = $woaESDs[0]
      }
      if ($woaRecoveryEnvESD -eq "") {
        $woaRecoveryEnvESD = $woaESDs[0]
      }
      Convert-Single -InstallESDs $woaESDs -PEESD $woaPEESD -REESD $woaRecoveryEnvESD -Output $Mediadir
      & "$($toolpath)\Rebuild-ISO.ps1" -SourcePath "$($Mediadir)" -Destination "$($Destination)"
  } else {
    Write-Host -ForegroundColor red "[$((Get-Date).ToString('MM/dd/yyyy hh:mm:ss tt'))] [Error] Unknown architecture type detected for the provided esds. Cleaning temporary directory and aborting execution"
    Remove-Item -Path $TempDirectory -Recurse
    return $false
  }
}
Write-Host "[$((Get-Date).ToString('MM/dd/yyyy hh:mm:ss tt'))] [Info] Done"
Remove-Item -Path $TempDirectory -Recurse
return $true