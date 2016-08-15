import-module "$(Split-Path -Parent -Path $MyInvocation.MyCommand.Definition)\Synchronous-ZipAndUnzip.psm1"

<#
	The version of this Auto Updater
#>
$auver = "0.0.0.1"

Write-host "
GusTools Auto Updater version $($auver)
Gustave M. (gus33000) - Copyright 2014-2016
"

<#
	Location of the required binaries for this script
#>
$bin = "$((Split-Path -Parent -Path $MyInvocation.MyCommand.Definition).Split('\')[0..($(Split-Path -Parent -Path $MyInvocation.MyCommand.Definition).Split('\').Count - 2)] -join '\')\bin"

<#
	Location of the root folder for GusTools
#>
$root = $((Split-Path -Parent -Path $MyInvocation.MyCommand.Definition).Split('\')[0..($(Split-Path -Parent -Path $MyInvocation.MyCommand.Definition).Split('\').Count - 2)] -join '\')

<#
	Location of the current version xml
#>
$locver = "$($bin)\version.xml"

<#
	Location of the remote version xml
#>
$versionxmlloc = "file:///C:/Users/gus33000/Documents/New_ESD-Decrypter/other/remoteversion.xml"

Write-host "Checking for updates..."

if (-not (Test-Path $locver)) {
	Write-host "We couldn't find the local version xml file. Checking for updates is aborted."
	return
}

<#
	Check if remote version xml is available to the client
#>
$error.Clear()
$time = Measure-Command { $request = Invoke-WebRequest -Uri $versionxmlloc } 2>$null

if ($error.Count -eq 0) {
	Write-host "Connection to the remote version file took $($time.TotalMilliseconds) milliseconds."
} else {
	Write-host "We couldn't find the remote version xml file. Checking for updates is aborted."
	return
}

<#
	Load both version xmls
#>
[xml]$curver = Get-content $locver
$wc = New-Object System.Net.WebClient
$wc.Encoding = [System.Text.Encoding]::utf8
[xml]$remotever = $wc.DownloadString($versionxmlloc)

$counter = 0
$IsCorrectAuVer = $false
foreach ($num in $remotever.versioninfo.version.minau.Split('.')) {
	if ($auver.Split('.')[$counter] -ge $num) {
		$IsCorrectAuVer = $true
	} else {
		$IsCorrectAuVer = $false
		break
	}
	$counter++
}

<#
	This block is executed when the minimum Auto Updater version requirement is met.
#>
if ($IsCorrectAuVer) {
	Write-host "Minimum updater version requirement is met. Minimum required version: $($curver.versioninfo.version.minau)"
	$counter = 0
	$IsUpdateAvailable = $false
	foreach ($num in $remotever.versioninfo.version.version.Split('.')) {
		if ($curver.versioninfo.version.version.Split('.')[$counter] -ge $num) {
			$IsUpdateAvailable = $false
		} else {
			$IsUpdateAvailable = $true
			break
		}
		$counter++
	}
	if ($IsUpdateAvailable) {
		Write-host "
A new update is available!
		
Current version: $($curver.versioninfo.version.version) - $($curver.versioninfo.version.buildstring)
Remote version: $($remotever.versioninfo.version.version) - $($remotever.versioninfo.version.buildstring)

$($remotever.versioninfo.changelog.title)
$('=' * ($remotever.versioninfo.changelog.title).Length)
$($remotever.versioninfo.changelog.'#text')"
		$title = "Do you want to install this update?"
		$message = "Yes will install the above update, No won't install that update."
		$yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", "Yes"
		$no = New-Object System.Management.Automation.Host.ChoiceDescription "&No", "No"
		$options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)
		$choice=$host.ui.PromptForChoice($title, $message, $options, 0)
		if ($choice -eq 0) {
			Write-host ""
			$url = $remotever.versioninfo.download.url
			$output = "$($root)\tmpup.zip"
			$start_time = Get-Date
			Import-Module BitsTransfer
			Start-BitsTransfer -Source $url -Destination $output
			Write-Output "Time taken: $((Get-Date).Subtract($start_time).Seconds) second(s)"
			if (Test-Path $bin\..\tmpup.zip) {
				try {
					Remove-item -force -recurse $bin
					Expand-ZipFile -ZipFilePath "$($root)\tmpup.zip" -DestinationDirectoryPath "$($root)" -OverwriteWithoutPrompting
					Remove-item -force "$($root)\tmpup.zip"
					Write-host "GusTools has been successfully updated!"
				} catch {
					Write-host "An error occured while expanding the update. The update process is aborted."
				}
			} else {
				Write-host "An error occured while downloading the update. The update process is aborted."
			}
		}
	} else {
		Write-host "No updates are available. You are running the latest available version of GusTools."
	}
} else {
	Write-host "Minimum updater version requirement isn't met. Minimum required version: $($curver.versioninfo.version.minau)
	
Please re-download a copy of GusTools at http://gus33000.github.io/ESD-Decrypter in order to update this tool. Checking for updates is aborted."
}