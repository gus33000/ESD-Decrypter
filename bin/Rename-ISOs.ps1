[CmdletBinding()]
param(
  [ValidateNotNullOrEmpty()]
  [ValidateScript({ (Test-Path $_) })]
  [Parameter(Mandatory = $false,HelpMessage = "The place where the ISOs are")]
  [System.IO.DirectoryInfo]$Path = '.',
  [ValidateScript({ ($_ -ge 0) -and ($_ -le 3) })]
  [int]$Scheme = 0,
  [switch]$addLabel,
  [switch]$mkCSV,
  [switch]$noMove,
  [string]$unknowndir = ".\unknown"
)


if (-not (Get-Command Mount-DiskImage -ErrorAction SilentlyContinue))
{
  Write-Host '
	Sorry, but your system does not have the ability to mount ISO files.
	This is maybe because you are running an older version of Windows than 6.2
	
	Error: Cannot find Mount-DiskImage
	'
  return
}

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
$($curver.versioninfo.branding.title) - Rename ISOs
$($curver.versioninfo.branding.copyright)
$($curver.versioninfo.version.version) - $($curver.versioninfo.version.buildstring)
"

if (-not (Test-Path "$($root)\logs\")) {
  mkdir $root\logs | Out-Null
}
Start-Transcript -Path "$($root)\logs\RenameISOs_$(get-date -format yyMMdd-HHmm).log" | Out-Null

."$($bin)\Identify-ISO.ps1"

$counter = 0
foreach ($item in (Get-ChildItem $Path -Filter *.iso | % { $_ })) {
  $counter += 1
}

Write-Host ('Found ' + $counter + ' ISOs.')

$counter_ = 0
foreach ($item in (Get-ChildItem $Path -Filter *.iso | % { $_ })) {
  Write-Host ('_' * ($Host.ui.RawUI.WindowSize.Width - 1))
  Write-Host ''
  $counter_ += 1
  Write-Host ('Checking item ' + $counter_ + ' of ' + $counter + '...')

  $results = Mount-Identify $item

  if (($results -eq $null) -or ($results -eq "")) {
	  if (-not ($noMove)) {
		  if (-not (Test-Path ($unknowndir))) {
			mkdir $unknowndir | Out-Null
		  }
		  Move-Item $item.FullName $unknowndir
	  }
	  continue
  }
  
  $results

  $filename = Generate-Filename $Scheme $results $addLabel

  if (-not ($noMove)) {
    if ($filename -eq $null) {
      if (-not (Test-Path ($unknowndir))) {
        mkdir $unknowndir | Out-Null
      }
      Move-Item $item.FullName $unknowndir
      continue
    }
  }
  if ($filename -ne $item) {
    # Ask for an alt filename if it already exist at the root, we assume here that the user will not rename it to the same one, or it will throw
    # a System.IO.Exception and continue anyway
    while ((Test-Path ($path.ToString() + '\' + $filename)) -and ($filename -ne $item)) {
      $filename = Read-Host 'Filename already exist, what should be the new filename then?'
    }
    # Renaming the file
    Write-Host "Renaming $($item) to $($filename)..."
    $dest = $path.ToString() + '\' + $filename
    Move-Item -LiteralPath "$($item.fullname)" -Destination "$($dest)"
    if ($mkCSV) {
      foreach ($result in $results) {
        $editionstr = ""

      foreach ($edition in $result.Editions) {
        if ($editionstr -eq "") {
          $editionstr = $edition
        } else {
          $editionstr = $editionstr + "-" + $edition
        }
      }

      $typestr = ""

      foreach ($type in $result.Type) {
        if ($editionstr -eq "") {
          $editionstr = $edition
        } else {
          $editionstr = $editionstr + "-" + $edition
        }
      }

      if (-not (Test-Path ($path.ToString() + '\' + $filename + '.csv'))) {
        "MajorVersion,MinorVersion,BuildNumber,DeltaVersion,BranchName,CompileDate,Tag,Architecture,BuildType,Type,Sku,Editions,Licensing,LanguageCode,VolumeLabel,BuildString" > ($path.ToString() + '\' + $filename + '.csv')
      }
      
      ($result.MajorVersion + "," + $result.MinorVersion + "," + $result.BuildNumber + "," + $result.DeltaVersion + "," + $result.BranchName + "," + $result.CompileDate + "," + $result.Tag + "," + $result.Architecture + "," + $result.BuildType + "," + $typestr + "," + $result.Sku + "," + $editionstr + "," + $result.Licensing + "," + $result.LanguageCode + "," + $result.VolumeLabel + "," + $result.BuildString) >> ($path.ToString() + '\' + $filename + '.csv')
      }
    }
  } else {
    Write-Host "Filename is already good."
    if ($mkCSV) {
      foreach ($result in $results) {
        $editionstr = ""

      foreach ($edition in $result.Editions) {
        if ($editionstr -eq "") {
          $editionstr = $edition
        } else {
          $editionstr = $editionstr + "-" + $edition
        }
      }

      $typestr = ""

      foreach ($type in $result.Type) {
        if ($editionstr -eq "") {
          $editionstr = $edition
        } else {
          $editionstr = $editionstr + "-" + $edition
        }
      }

      if (-not (Test-Path ($path.ToString() + '\' + $filename + '.csv'))) {
        "MajorVersion,MinorVersion,BuildNumber,DeltaVersion,BranchName,CompileDate,Tag,Architecture,BuildType,Type,Sku,Editions,Licensing,LanguageCode,VolumeLabel,BuildString" > ($path.ToString() + '\' + $filename + '.csv')
      }
      
      ($result.MajorVersion + "," + $result.MinorVersion + "," + $result.BuildNumber + "," + $result.DeltaVersion + "," + $result.BranchName + "," + $result.CompileDate + "," + $result.Tag + "," + $result.Architecture + "," + $result.BuildType + "," + $typestr + "," + $result.Sku + "," + $editionstr + "," + $result.Licensing + "," + $result.LanguageCode + "," + $result.VolumeLabel + "," + $result.BuildString) >> ($path.ToString() + '\' + $filename + '.csv')
      }
    }
  }
}

Write-Host 'Done.'

Stop-Transcript | Out-Null
