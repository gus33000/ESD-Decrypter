[CmdletBinding()]
param(
  [ValidateScript({ (Test-Path $_) })]
  [Parameter(Mandatory = $false,HelpMessage = "The complete path to the Setup directory to rebuild.")]
  [string]$SourcePath,

  [ValidateScript({ (Test-Path $_) })]
  [Parameter(Mandatory = $false,HelpMessage = "The place where the final ISO file will be stored")]
  [System.IO.DirectoryInfo]$Destination = '.\'
)

<#
	Location of the required binaries for this script
#>
$bin = (Split-Path -Parent -Path $MyInvocation.MyCommand.Definition)

<#
	Location of the root folder for GusTools
#>
$root = $((Split-Path -Parent -Path $MyInvocation.MyCommand.Definition).Split('\')[0..($(Split-Path -Parent -Path $MyInvocation.MyCommand.Definition).Split('\').Count - 2)] -join '\')

$Global:toolpath = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
$Global:cdimage253 = "$($toolpath)\cdimage\2.53\cdimage.exe"
$Global:decryptesd = "$($toolpath)\decryptesd\decryptesd.exe"
$Global:7z = "$($toolpath)\7z\7z.exe"

if (Test-Path "$($SourcePath)\MediaMeta.xml") {
  Write-Host "MediaMeta file has been detected, please move this file elsewhere or delete it if you don't want to back it up. Exiting..."
  return
}

function Get-ScriptDirectory {
  return Split-Path -Parent $PSCommandPath
}

$ScriptDir = Get-ScriptDirectory

function Get-InfosFromSingle(
  [Parameter(Mandatory = $true,HelpMessage = "The complete path to the ISO Path.")]
  [string]$PATH
) {

  function Get-DirectoryStats {
    param($directory,$recurse,$format)

    Write-Progress -Activity "$($ScriptDir)\Get-DirStats.ps1" -Status "Reading '$($directory.FullName)'"
    $files = $directory | Get-ChildItem -Force -Recurse:$recurse | Where-Object { -not $_.PSIsContainer }
    if ($files) {
      Write-Progress -Activity "$($ScriptDir)\Get-DirStats.ps1" -Status "Calculating '$($directory.FullName)'"
      $output = $files | Measure-Object -Sum -Property Length | Select-Object @{ Name = "Path"; Expression = { $directory.FullName } },@{ Name = "Files"; Expression = { $_.Count; $script:totalcount += $_.Count } },@{ Name = "Size"; Expression = { $_.Sum; $script:totalbytes += $_.Sum } }
    } else {
      $output = "" | Select-Object @{ Name = "Path"; Expression = { $directory.FullName } },@{ Name = "Files"; Expression = { 0 } },@{ Name = "Size"; Expression = { 0 } }
    }
    if (-not $format) { $output } else { $output | Format-Output }
  }

    $isodata = "" | select FileName,SetupPath,VolumeLabel,timestamp

    $isodata.SetupPath = $PATH

    $results = Identify-SetupPath $PATH

    if ($results.Count -gt 1) {
    	$isodata.VolumeLabel = "ESD-ISO"
    } else {

      #Generating Label

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

        $tag = 'IR3'
        if ([int]$result.DeltaVersion -eq '17056') {
          $tag = 'IR4'
        }
        if ([int]$result.DeltaVersion -eq '17415') {
          $tag = 'IR5'
        }
        if ([int]$result.DeltaVersion -gt '17415') {
          $tag = 'IR6'
        }
        if ([int]$result.BuildNumber -gt '9600') {
          $tag = 'JM1'
        }
        if ([int]$result.BuildNumber -ge '9896') {
          $tag = 'J'
        }

        if ($result.Licensing.toLower() -eq 'volume') {
          $ltag = 'V'
        } elseif ($result.Licensing.toLower() -eq 'oem') {
          $ltag = 'O'
        } else {
          $ltag = ''
        }

        if ($result.BuildType.toLower() -eq "fre") {
          $bldt = "FRE"
        } elseif ($result.BuildType.toLower() -eq "chk") {
          $bldt = "CHK"
        }

        $DVDSize = ((Get-DirectoryStats $PATH).size / 1GB)

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
        
        if ($result.Editions -eq @("Professional", "Core")) {
          $skut = "CCSA"
        } elseif ($result.Editions -eq @("ProfessionalN", "CoreN")) {
          $skut = "CCSNA"
        } elseif ($result.Editions.Count -gt 1) {
          $isodata.VolumeLabel = "ESD-ISO"
        } else {
          if ($result.Sku -eq 'Core') { $Skut = 'CCRA' }
          if ($result.Sku -eq 'CoreARM') { $Skut = 'CCSA'}
          if ($result.Sku -eq 'CoreConnected') { $Skut = 'CCONA' }
          if ($result.Sku -eq 'CoreConnectedCountrySpecific') { $Skut = 'CCCHA' }
          if ($result.Sku -eq 'CoreConnectedN') { $Skut = 'CCONNA' }
          if ($result.Sku -eq 'CoreConnectedSingleLanguage') { $Skut = 'CCSLA' }
          if ($result.Sku -eq 'CoreCountrySpecific') { $Skut = 'CCHA' }
          if ($result.Sku -eq 'CoreN') { $Skut = 'CCRNA' }
          if ($result.Sku -eq 'CoreSingleLanguage') { $Skut = 'CSLA' }
          if ($result.Sku -eq 'PPIPro') { $Skut = 'CPPIA' }
          if ($result.Sku -eq 'Professional') { $Skut = 'CPRA' }
          if ($result.Sku -eq 'ProfessionalN') { $Skut = 'CPRNA' }
          if ($result.Sku -eq 'ProfessionalStudent') { $Skut = 'CPRSA' }
          if ($result.Sku -eq 'ProfessionalStudentN') { $Skut = 'CPRSNA' }
          if ($result.Sku -eq 'ProfessionalWMC') { $Skut = 'CPWMCA' }
          if ($result.Sku -eq 'Education') { $Skut = 'CEDA' }
          if ($result.Sku -eq 'EducationN') { $Skut = 'CEDNA' }
          if ($result.Sku -eq 'Enterprise') { $Skut = 'CENA' }
          if ($result.Sku -eq 'EnterpriseN') { $Skut = 'CENNA' }
          if ($result.Sku -eq 'EnterpriseS') { $Skut = 'CES' }
          if ($result.Sku -eq 'EnterpriseSN') { $Skut = 'CESN' }
        }
        $isodata.VolumeLabel = ($tag + '_' + $Skut + '_' + $arch + $bldt + $ltag + '_' + $result.LanguageCode + '_' + $DVD).toUpper()
      }
    }
    #Generating Filename

      $isodata.FileName = Generate-Filename 1 $results

      $isodata.timestamp = (Get-ChildItem $Path\setup.exe | % { [System.TimeZoneInfo]::ConvertTimeToUtc($_.LastWriteTime).ToString("MM/dd/yyyy,HH:mm:ss") })

      return $isodata,$results
}

function Get-InfosFromSetupPath (
  [Parameter(Mandatory = $true,HelpMessage = "The complete path to the ISO Path.")]
  [string]$PATH
)
{
  . "$($ScriptDir)\Identify-ISO.ps1"

  $isodatas = "" | select FileName,SetupPath,VolumeLabel,timestamp

  $isodatas.SetupPath = $PATH
  $isodatas.timestamp = (Get-ChildItem $Path\setup.exe | % { [System.TimeZoneInfo]::ConvertTimeToUtc($_.LastWriteTime).ToString("MM/dd/yyyy,HH:mm:ss") })

  $results = @()

  if (Test-Path $PATH\x64\setup.exe) {
    if (Test-Path $PATH\x86\setup.exe) {
      if (Test-Path $PATH\arm\setup.exe) {
        #x64 x86 arm

        $isodatas.VolumeLabel = "ESD-ISO"

        $x64results = Get-InfosFromSingle "$($PATH)\x64\setup.exe"
        $x86results = Get-InfosFromSingle "$($PATH)\x86\setup.exe"
        $armresults = Get-InfosFromSingle "$($PATH)\arm\setup.exe"

        foreach ($result in $x64results[1]) {
          $results += $result
        }
        foreach ($result in $x86results[1]) {
          $results += $result
        }
        foreach ($result in $armresults[1]) {
          $results += $result
        }

        $isodatas.FileName = $x64results[0].FileName + "_" + $x86results[0].FileName + "_" + $armresults[0].FileName
      } else {
        #x64 x86

        $isodatas.VolumeLabel = "ESD-ISO"

        $x64results = Get-InfosFromSingle "$($PATH)\x64\setup.exe"
        $x86results = Get-InfosFromSingle "$($PATH)\x86\setup.exe"

        foreach ($result in $x64results[1]) {
          $results += $result
        }
        foreach ($result in $x86results[1]) {
          $results += $result
        }

        $isodatas.FileName = $x64results[0].FileName + "_" + $x86results[0].FileName
      }
    } elseif (Test-Path $PATH\arm\setup.exe) {
      #arm x64
      $isodatas.VolumeLabel = "ESD-ISO"

        $x64results = Get-InfosFromSingle "$($PATH)\x64\setup.exe"
        $armresults = Get-InfosFromSingle "$($PATH)\arm\setup.exe"

        foreach ($result in $x64results[1]) {
          $results += $result
        }
        foreach ($result in $armresults[1]) {
          $results += $result
        }

        $isodatas.FileName = $x64results[0].FileName + "_" + $armresults[0].FileName
    } else {
        $isodatas.VolumeLabel = "ESD-ISO"

        $x64results = Get-InfosFromSingle "$($PATH)\x64\setup.exe"

        foreach ($result in $x64results[1]) {
          $results += $result
        }

        $isodatas.FileName = $x64results[0].FileName
    }
  } else {
    if (Test-Path $PATH\x86\setup.exe) {
      if (Test-Path $PATH\arm\setup.exe) {
        $isodatas.VolumeLabel = "ESD-ISO"

        $x86results = Get-InfosFromSingle "$($PATH)\x86\setup.exe"
        $armresults = Get-InfosFromSingle "$($PATH)\arm\setup.exe"

        foreach ($result in $x86results[1]) {
          $results += $result
        }
        foreach ($result in $armresults[1]) {
          $results += $result
        }

        $isodatas.FileName = $x86results[0].FileName + "_" + $armresults[0].FileName
      } else {
        $isodatas.VolumeLabel = "ESD-ISO"

        $x64results = Get-InfosFromSingle "$($PATH)\x86\setup.exe"

        foreach ($result in $x86results[1]) {
          $results += $result
        }

        $isodatas.FileName = $x86results[0].FileName
      }
    } elseif (Test-Path $PATH\sources\setup.exe) {
      $singleresults = Get-InfosFromSingle $PATH
      foreach ($result in $singleresults[1]) {
          $results += $result
        }
      $isodatas.FileName = $singleresults[0].FileName
      $isodatas.VolumeLabel = $singleresults[0].VolumeLabel
    } else {
      return
    }
  }
  return $isodatas,$results
}

$results = Get-InfosFromSetupPath $SourcePath
$result = $results[0]
$results[1] | Format-List | Out-Host
$results[0] | Format-List | Out-Host

Write-Host 'Generating ISO...'
$BootData="2#p0,e,b$($SourcePath)\boot\etfsboot.com#pEF,e,b$($SourcePath)\efi\Microsoft\boot\efisys.bin"
& "cmd" "/c" "$($ScriptDir)\cdimage\2.53\cdimage.exe" "-bootdata:$BootData" "-o" "-h" "-m" "-u2" "-udfver102" "-t$($results.timestamp)" "-l$($results.VolumeLabel)" "$($SourcePath)\" """$($Destination)\$($results.FileName)"""