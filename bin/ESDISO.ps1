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

function Select-Menu ($displayoptions,$arrayofoptions) {
  do {
    $counter = 0
    if ($displayoptions.Count -ne 1) {
      foreach ($item in $displayoptions) {
        $counter++
        $padding = ' ' * ((([string]$displayoptions.Length).Length) - (([string]$counter).Length))
        Write-Host -ForegroundColor White ('[' + $counter + ']' + $padding + ' ' + $item)
      }
      Write-Host ''
      $choice = Read-Host -Prompt "Select number and press enter"
    } else {
      $counter++
      $choice = 1
    }
  } until ([int]$choice -gt 0 -and [int]$choice -le $counter)
  $choice = $choice - 1
  return $arrayofoptions[$choice]
}

function Convert-ESD (
  [ValidateNotNullOrEmpty()]
  [ValidateScript({ (Test-Path $_) })]
  [Parameter(Mandatory = $true,HelpMessage = "The complete path to the ESD file to convert.")]
  [array]$ESDFiles,
  [ValidateNotNullOrEmpty()]
  [Parameter(Mandatory = $true,HelpMessage = "The place where the final ISO file will be stored")]
  [System.IO.DirectoryInfo]$Destination = ".\",
  [ValidateNotNullOrEmpty()]
  [Parameter(Mandatory = $false,HelpMessage = "The crypto key that will be used to decrypt the ESD file.")]
  $DecryptionKey
)
{
  if (($DecryptionKey -eq "") -or ($DecryptionKey -eq $null)) {
    & "$bin\Convert-ESDISO.ps1" -ESDFiles $ESDFiles -Destination $Destination
  } else {
    & "$bin\Convert-ESDISO.ps1" -ESDFiles $ESDFiles -Destination $Destination -DecryptionKey $DecryptionKey
  }
}

$Title = "Do you want to use a custom Cryptographic key ?"

$message = "You can specify a custom Crypto Key if the embedded ones can't decrypt your esd file."

$NO = New-Object System.Management.Automation.Host.ChoiceDescription "&No",`
   "No, continue with the included Crypto keys."

$YES = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes",`
   "Yes, I want to specify a custom key, but I'll try to decrypt the esd file with your custom key and the embedded ones."

$options = [System.Management.Automation.Host.ChoiceDescription[]]($NO,$YES)

$result = $host.ui.PromptForChoice($title,$message,$options,0)

switch ($result)
{
  0 { $CustomKey = $false }
  1 { $CustomKey = $true }
}
if ($CustomKey -eq $true) {
  $key = Read-Host 'Please enter a complete Cryptographic Key'
}

$Title = "Do you want to use a custom Destination Path ?"

$message = "You can specify a custom Destination Path for your ISO file."

$NO = New-Object System.Management.Automation.Host.ChoiceDescription "&No",`
   "No, place the ISO file in the current folder."

$YES = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes",`
   "Yes, I want to specify a custom destination path."

$options = [System.Management.Automation.Host.ChoiceDescription[]]($NO,$YES)

$result = $host.ui.PromptForChoice($title,$message,$options,0)

switch ($result)
{
  0 { $CustomPath = '.' }
  1 { $CustomPath = Read-Host 'Please enter a custom destination path' }
}

foreach ($item in (Get-Item *.esd)) {
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
  $selected = Select-Menu $esdnames $esdpaths

  if ($selected -eq 'None') {
    Write-Host
    Write-Host -ForegroundColor Yellow "You will be asked for ESDFiles[...], you will need to enter a full esd file path, you will be asked again for ESD[...], if you want to combine multiple esd files, enter another full esd file path, otherwise press [ENTER] on your keyboard."
    if ($CustomKey -eq $true) {
      Convert-ESD -DecryptionKey $key -Destination $CustomPath
    } else {
      Convert-ESD -Destination $CustomPath
    }
  } else {
    if ($CustomKey -eq $true) {
      Convert-ESD -DecryptionKey $key -Destination $CustomPath -ESDFiles $selected
    } else {
      Convert-ESD -Destination $CustomPath -ESDFiles $selected
    }
  }
} else {
  Write-Host
  Write-Host -ForegroundColor Yellow "You will be asked for ESDFiles[...], you will need to enter a full esd file path, you will be asked again for ESD[...], if you want to combine multiple esd files, enter another full esd file path, otherwise press [ENTER] on your keyboard."
  if ($CustomKey -eq $true) {
    Convert-ESD -DecryptionKey $key -Destination $CustomPath
  } else {
    Convert-ESD -Destination $CustomPath
  }
}
