[CmdletBinding()]
param (
	[ValidateScript({($_ -ge 0) -and ($_ -le 3)})]
	[int] $Scheme = 0,
	[switch] $addLabel,
	[switch] $mkCSV,
	[switch] $noMove,
	[string] $unknowndir = ".\unknown",
	[ValidateNotNullOrEmpty()]  
    [ValidateScript({(Test-Path $_)})] 
	[parameter(Mandatory=$false,HelpMessage="The place where the ISOs are")]
	[System.IO.DirectoryInfo] $Path = '.'
)

if (-not (Test-Path '.\logs\')) {
	mkdir .\logs | out-null
}
start-transcript -path ".\logs\RenameISOs_$(get-date -format yyMMdd-HHmm).log" | out-null

Write-Host '
RenameISOs (c) gus33000 - It just works with LH pre-reset.
Rename Windows Beta ISOs to understandable filenames.
Version 0.3.6
'

Write-Host 'Loading utilities module...'
. '.\bin\utils.ps1'
. '.\bin\RenameISOs.ps1'

$counter = 0
foreach ($item in (dir $Path -Filter *.iso | % {$_})) {
	$counter += 1
}

Write-Host ('Found '+$counter+' ISOs.')

$counter_ = 0
foreach ($item in (dir $Path -Filter *.iso | % {$_})) {
	Write-Host ('_' * ($Host.UI.RawUI.WindowSize.Width - 1))
	Write-Host ''
	$counter_ += 1
	Write-Host ('Checking item '+$counter_+' of '+$counter+'...')
	
	$results = get-BetterISOFilename($item)
	
	$filename = $results[0]

	if (-not ($noMove)) {
		if ($filename -eq $null) {
			if (-not (Test-Path ($unknowndir))) {
				mkdir $unknowndir | out-null
			}
			Move-item $item.fullname $unknowndir
			Continue
		}
	}
	if ($filename -ne $item) {
		# Ask for an alt filename if it already exist at the root, we assume here that the user will not rename it to the same one, or it will throw
		# a System.IO.Exception and continue anyway
		while ((Test-Path ($path.toString()+'\'+$filename)) -and ($filename -ne $item)) {
			$filename = Read-Host 'Filename already exist, what should be the new filename then?'
		}
		# Renaming the file
		Write-Host "Renaming $($item) to $($filename)..."
		$dest = $path.toString()+'\'+$filename
		Move-Item -literalpath "$($item.fullname)" -destination "$($dest)"
		if ($mkCSV) {
			$editionstr = ""
			
			foreach ($edition in $results[1].Editions) {
				if ($editionstr -eq "") {
					$editionstr = $edition
				} else {
					$editionstr = $editionstr+"-"+$edition
				}
			}
			"MajorVersion,MinorVersion,BuildNumber,DeltaVersion,BranchName,CompileDate,Tag,Architecture,BuildType,Type,Sku,Editions,Licensing,LanguageCode,VolumeLabel,BuildString" > ($path.toString()+'\'+$filename+'.csv')
			
			($results[1].MajorVersion+","+$results[1].MinorVersion+","+$results[1].BuildNumber+","+$results[1].DeltaVersion+","+$results[1].BranchName+","+$results[1].CompileDate+","+$results[1].Tag+","+$results[1].Architecture+","+$results[1].BuildType+","+$results[1].Type+","+$results[1].Sku+","+$editionstr+","+$results[1].Licensing+","+$results[1].LanguageCode+","+$results[1].VolumeLabel+","+$results[1].BuildString) >> ($dest+'.csv')
		}
	} else {
		Write-Host "Filename is already good."
		if ($mkCSV) {
			$editionstr = ""
			
			foreach ($edition in $results[1].Editions) {
				if ($editionstr -eq "") {
					$editionstr = $edition
				} else {
					$editionstr = $editionstr+"-"+$edition
				}
			}
			"MajorVersion,MinorVersion,BuildNumber,DeltaVersion,BranchName,CompileDate,Tag,Architecture,BuildType,Type,Sku,Editions,Licensing,LanguageCode,VolumeLabel,BuildString" > ($path.toString()+'\'+$filename+'.csv')
			($results[1].MajorVersion+","+$results[1].MinorVersion+","+$results[1].BuildNumber+","+$results[1].DeltaVersion+","+$results[1].BranchName+","+$results[1].CompileDate+","+$results[1].Tag+","+$results[1].Architecture+","+$results[1].BuildType+","+$results[1].Type+","+$results[1].Sku+","+$editionstr+","+$results[1].Licensing+","+$results[1].LanguageCode+","+$results[1].VolumeLabel+","+$results[1].BuildString) >> ($path.toString()+'\'+$filename+'.csv')
		}
	}
}

Write-Host 'Done.'

stop-transcript | out-null