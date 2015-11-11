[CmdletBinding()]
param (
	[ValidateScript({($_ -ge 0) -and ($_ -le 3)})]
	[int] $Scheme = 0,
	[switch] $addLabel,
	
    [ValidateScript({(Test-Path $_) -and ((Get-Item $_).Extension -eq ".esd")})] 
	[parameter(Mandatory=$false,HelpMessage="The complete path to the ESD file to convert.")]
	[Array] $ESD,
 
    [ValidateScript({(Test-Path $_)})] 
	[parameter(Mandatory=$false,HelpMessage="The place where the final ISO file will be stored")]
	[System.IO.DirectoryInfo] $Destination = '.\',
	
	[parameter(Mandatory=$false,HelpMessage="The crypto key that will be used to decrypt the ESD file.")]
	$CryptoKey,
	
	[parameter(Mandatory=$false,HelpMessage="The type of extension used for the Windows Image (WIM or ESD)")]
	$extensiontype
)

$Host.UI.RawUI.WindowTitle = "ESD Toolkit - November Tech Preview 2015"

start-transcript -path ".\logs\ESDDecrypter_$(get-date -format yyMMdd-HHmm).log" | out-null

Write-Host '
Based on the script by abbodi1406
ESD Toolkit - November Tech Preview 2015 - Copyright 2015 (c) gus33000 - Version 3.0
For testing purposes only. Build 3.0.10120.0.th2_release_multi(gus33000).151111-1134
'

Write-Host 'Loading utilities module...'
. '.\bin\utils.ps1'

function Select-ESD ($esdarray) {
	$ESDFILES = New-Object System.Collections.ArrayList
	$ESDFILES = @{}
	foreach ($esd in $esdarray) {
		$esdname = $esd.split('/')[-1]
		$esdhash = $esd.split('_')[-1].split('.')[0]
		$build = $esdname.split('.')[0]
		$subver = $esdname.split('.')[1]
		$lab = $esdname.split('.')[3].split('CLIENT')[0].Substring(0,$esdname.split('.')[3].split('CLIENT')[0].Length-1)
		$compiledate = $esdname.split('.')[2]
		$buildstring = $build+'.'+$subver+'.'+$lab+'.'+$compiledate
		$otherpart = $esdname.Substring(($build+'.'+$subver+'.'+$compiledate+'.'+$lab).Length)
		$arch = $otherpart.split('_')[3]
		$lang = $otherpart.split('_')[4]
		$sku = $otherpart.split('_')[1]
		$licensing = $otherpart.split('_')[2]
		$ESDFILES[$esdname] = @{}
		$ESDFILES[$esdname]['buildstring'] = $buildstring
		$ESDFILES[$esdname]['url'] = $esd
		$ESDFILES[$esdname]['Hash'] = $esdhash
		$ESDFILES[$esdname]['Architecture'] = $arch
		$ESDFILES[$esdname]['Language'] = $lang
		$ESDFILES[$esdname]['Edition'] = $sku
		$ESDFILES[$esdname]['Licensing'] = $licensing
	}
	$builds = @()
	foreach ($esd in $ESDFILES.GetEnumerator().Name) {
		if ($builds -notcontains $ESDFILES.$esd.buildstring) {
			$builds += $ESDFILES.$esd.buildstring
		}
	}
	$builds = $builds | sort
	Write-Host '
Please select your build
========================
'
	$FinalBuild = Menu-Select $builds $builds
	$lists = @{}
	foreach ($esd in $ESDFILES.GetEnumerator().Name) {
		if ($ESDFILES.$esd.buildstring -eq $FinalBuild) {
			$lists.$esd += $ESDFILES.$esd
		}
	}
	$langs = @()
	foreach ($esd in $lists.GetEnumerator().Name) {
		if ($langs -notcontains $ESDFILES.$esd.Language) {
			$langs += $ESDFILES.$esd.Language
		}
	}
	$langs = $langs | sort
	$commonlangs = ($langs -replace 'ar-sa', 'Arabic' -replace 'bg-bg', 'Bulgarian' -replace 'cs-cz', 'Czech' -replace 'da-dk', 'Danish' -replace 'de-de', 'German' -replace 'el-gr', 'Greek' -replace 'en-gb', 'English (United Kingdom)' -replace 'en-us', 'English' -replace 'es-es', 'Spanish' -replace 'et-ee', 'Estonian' -replace 'fi-fi', 'Finnish' -replace 'fr-fr', 'French' -replace 'he-il', 'Hebrew' -replace 'hr-hr', 'Croatian' -replace 'hu-hu', 'Hungarian' -replace 'it-it', 'Italian' -replace 'ja-jp', 'Japanese' -replace 'ko-kr', 'Korean' -replace 'lt-lt', 'Lithuanian' -replace 'nb-no', 'Norwegian (Bokmål)' -replace 'nl-nl', 'Dutch' -replace 'pl-pl', 'Polish' -replace 'pt-br', 'Portuguese (Brazil)' -replace 'pt-pt', 'Portuguese (Portugal)' -replace 'ro-ro', 'Romanian' -replace 'ru-ru', 'Russian' -replace 'sk-sk', 'Slovak' -replace 'sl-si', 'Slovenian' -replace 'sr-latn-rs', 'Serbian Latin' -replace 'sv-se', 'Swedish' -replace 'th-th', 'Thai' -replace 'tr-tr', 'Turkish' -replace 'uk-ua', 'Ukrainian' -replace 'zh-cn', 'Chinese Simplified' -replace 'zh-hk', 'Chinese Traditional HK' -replace 'zh-tw', 'Chinese Traditional TW')
	Write-Host '
Please select your language
===========================
'
	$FinalLanguage = Menu-Select $commonlangs $langs
	$listsbackup = $lists
	$lists = @{}
	foreach ($esd in $listsbackup.GetEnumerator().Name) {
		if ($ESDFILES.$esd.Language -eq $FinalLanguage) {
			$lists.$esd += $ESDFILES.$esd
		}
	}
	$editions = @()
	foreach ($esd in $lists.GetEnumerator().Name) {
		if ($editions -notcontains $lists.$esd.Edition) {
			$editions += $lists.$esd.Edition
		}
	}
	$editions = $editions | sort
	$commoneditions = ($editions -replace 'CLIENTCOREK', 'Windows 10 K' -replace 'CLIENTPRO', 'Windows 10 Pro' -replace 'CLIENTSINGLELANGUAGE', 'Windows 10 Single Language' -replace 'CLIENTPROK', 'Windows 10 Pro K' -replace 'CLIENTCORE', 'Windows 10' -replace 'CLIENTCOREN', 'Windows 10 N' -replace 'CLIENTCHINA', 'Windows 10 China' -replace 'CLIENTCOREKN', 'Windows 10 KN' -replace 'CLIENTPROKN', 'Windows 10 Pro KN' -replace 'CLIENTPRON', 'Windows 10 Pro N' -replace 'CLIENTENTERPRISE', 'Windows 10 Enterprise')
	Write-Host '
Please select your edition
==========================
'
	$FinalEdition = Menu-Select $commoneditions $editions
	$listsbackup = $lists
	$lists = @{}
	foreach ($esd in $listsbackup.GetEnumerator().Name) {
		if ($ESDFILES.$esd.Edition -eq $FinalEdition) {
			$lists.$esd += $ESDFILES.$esd
		}
	}
	$architectures = @()
	foreach ($esd in $ESDFILES.GetEnumerator().Name) {
		if ($architectures -notcontains $ESDFILES.$esd.Architecture) {
			$architectures += $ESDFILES.$esd.Architecture
		}
	}
	$architectures = $architectures | sort
	$DisplayArchitectures = ($architectures -replace 'x64', '64-bit (x64)' -replace 'x86', '32-bit (x86)' -replace 'fre', '')
	Write-Host '
Please select your architecture
===============================
'
	$FinalArchitecture = Menu-Select $DisplayArchitectures $architectures
	$listsbackup = $lists
	$lists = @{}
	foreach ($esd in $listsbackup.GetEnumerator().Name) {
		if ($ESDFILES.$esd.Architecture -eq $FinalArchitecture) {
			$lists.$esd += $ESDFILES.$esd
		}
	}
	if (-not $lists.Length -eq 1) {
		Write-Host '
Please select your installation media
=====================================
'
		Do {
			$counter = 0
			foreach ($esd in $lists.GetEnumerator().Name) {
				$counter++
				$buildstring = $ESDFILES.$esd.buildstring
				$edition = $ESDFILES.$esd.Edition -replace 'CLIENTCOREK', 'Windows 10 K' -replace 'CLIENTPRO', 'Windows 10 Pro' -replace 'CLIENTSINGLELANGUAGE', 'Windows 10 Single Language' -replace 'CLIENTPROK', 'Windows 10 Pro K' -replace 'CLIENTCORE', 'Windows 10' -replace 'CLIENTCOREN', 'Windows 10 N' -replace 'CLIENTCHINA', 'Windows 10 China' -replace 'CLIENTCOREKN', 'Windows 10 KN' -replace 'CLIENTPROKN', 'Windows 10 Pro KN' -replace 'CLIENTPRON', 'Windows 10 Pro N' -replace 'CLIENTENTERPRISE', 'Windows 10 Enterprise'
				$architecture = $ESDFILES.$esd.Architecture -replace 'x64', '64-bit (x64)' -replace 'x86', '32-bit (x86)' -replace 'fre', ''
				$language = $ESDFILES.$esd.Language -replace 'ar-sa', 'Arabic' -replace 'bg-bg', 'Bulgarian' -replace 'cs-cz', 'Czech' -replace 'da-dk', 'Danish' -replace 'de-de', 'German' -replace 'el-gr', 'Greek' -replace 'en-gb', 'English (United Kingdom)' -replace 'en-us', 'English' -replace 'es-es', 'Spanish' -replace 'et-ee', 'Estonian' -replace 'fi-fi', 'Finnish' -replace 'fr-fr', 'French' -replace 'he-il', 'Hebrew' -replace 'hr-hr', 'Croatian' -replace 'hu-hu', 'Hungarian' -replace 'it-it', 'Italian' -replace 'ja-jp', 'Japanese' -replace 'ko-kr', 'Korean' -replace 'lt-lt', 'Lithuanian' -replace 'nb-no', 'Norwegian (Bokmål)' -replace 'nl-nl', 'Dutch' -replace 'pl-pl', 'Polish' -replace 'pt-br', 'Portuguese (Brazil)' -replace 'pt-pt', 'Portuguese (Portugal)' -replace 'ro-ro', 'Romanian' -replace 'ru-ru', 'Russian' -replace 'sk-sk', 'Slovak' -replace 'sl-si', 'Slovenian' -replace 'sr-latn-rs', 'Serbian Latin' -replace 'sv-se', 'Swedish' -replace 'th-th', 'Thai' -replace 'tr-tr', 'Turkish' -replace 'uk-ua', 'Ukrainian' -replace 'zh-cn', 'Chinese Simplified' -replace 'zh-hk', 'Chinese Traditional HK' -replace 'zh-tw', 'Chinese Traditional TW'
				$number = '['+$counter+']'
				$padding = ' ' * $number.length
				Write-Host ('=' * ($number+' BuildString : '+$buildstring).Length)
				Write-Host $number' BuildString : '$buildstring
				Write-Host $padding' Name        : '$edition
				Write-Host $padding' Architecture: '$architecture
				Write-Host $padding' Language    : '$language
				Write-Host ('=' * ($number+' BuildString : '+$buildstring).Length)
			}
			Write-Host ''
			$choice = read-host -prompt "Select number and press enter"
		} until ([int]$choice -gt 0 -and [int]$choice -le $counter)
		$choice = $choice - 1
		$FinalItem = $lists.GetEnumerator().Name[$choice]
	} else {
		$FinalItem = $lists.GetEnumerator().Name
	}
	cls
	$source = $ESDFILES.$FinalItem.url
	$destination = $PSScriptRoot+'\'+($FinalItem -replace ('_'+$ESDFILES.$FinalItem.hash), '')
	downloadFile $source $destination
	return $destination
}

function DownloadFrom-XML ($url) {
	if ($url -contains '.\bin\') {
		[xml]$doc = Get-content $url
	} else {
		$wc = New-Object System.Net.WebClient
		$wc.Encoding = [System.Text.Encoding]::utf8
		[xml]$doc = $wc.DownloadString($url)
	}
	
	$commonlangs = @()
	$langs = @()
	foreach ($lang in $doc.PublishedMedia.Languages.Language.LanguageCode) {
		if ($lang -ne 'default') {
			if (($doc.PublishedMedia.Files.File | ? { $_.LanguageCode -eq $lang }) -ne $null) {
				$langs += $lang
				$commonlangs += ($doc.PublishedMedia.Files.File | ? { $_.LanguageCode -eq $lang })[0].Language
			}
		}
	}
	Write-Host '
Please select your language
===========================
'
	$FinalLanguage = Menu-Select $commonlangs $langs
	$lists = ($doc.PublishedMedia.Files.File | ? { $_.LanguageCode -eq $FinalLanguage})
	$editions = @()
	foreach ($edition in ($lists.Edition_Loc -replace '%', '')) {
		if ($editions -notcontains $edition) {
			$editions += $edition
		}
	}
	$DisplayEditions = @()
	foreach ($edition in $editions) {
			$DisplayEditions += (($doc.PublishedMedia.Languages.Language | ? { $_.LanguageCode -eq 'default'}).$edition)
	}
	Write-Host '
Please select your edition
==========================
'
	$FinalEdition = Menu-Select $DisplayEditions $editions
	$lists = ($lists | ? { $_.Edition_Loc -eq '%'+$FinalEdition+'%'})
	$architectures = @()
	foreach ($arch in ($lists.Architecture_Loc -replace '%', '')) {
		if ($architectures -notcontains $arch) {
			$architectures += $arch
		}
	}
	$DisplayArchitectures = @()
	foreach ($arch in $architectures) {
			$DisplayArchitectures += (($doc.PublishedMedia.Languages.Language | ? { $_.LanguageCode -eq 'default'}).$arch)
	}
	Write-Host '
Please select your architecture
===============================
'
	$FinalArchitecture = Menu-Select $DisplayArchitectures $architectures
	$lists = $doc.PublishedMedia.Files.File | ? {($_.LanguageCode -eq $FinalLanguage) -and ($_.Edition_Loc -eq '%'+$FinalEdition+'%') -and ($_.Architecture_Loc -eq '%'+$FinalArchitecture+'%')}
	if (-not $lists.FileName.Count -eq 1) {
		Write-Host '
Please select your installation media
=====================================
'
		Do {
			$counter = 0
			foreach ($item in $lists) {
				$counter++
				$edition = ($doc.PublishedMedia.Languages.Language | ? { $_.LanguageCode -eq 'default'}).$FinalEdition
				$architecture = ($doc.PublishedMedia.Languages.Language | ? { $_.LanguageCode -eq 'default'}).$FinalArchitecture
				$language = $item.Language
				$size = ($item.Size) / 1GB
				$number = '['+$counter+']'
				$padding = ' ' * $number.length
				Write-Host ('=' * 36)
				Write-Host $number Name : $edition
				Write-Host $padding Architecture : $architecture
				Write-Host $padding Language : $language
				Write-Host $padding Size : ([math]::Round($size, 2))GB
				Write-Host ('=' * 36)
			}
			Write-Host ''
			$choice = read-host -prompt "Select number and press enter"
		} until ([int]$choice -gt 0 -and [int]$choice -le $counter)
		$choice = $choice - 1
		$FinalItem = $lists[$choice]
	} else {
		if ($lists -is [system.array]) {
			$FinalItem = $lists[0]
		} else {
			$FinalItem = $lists
		}
	}
	cls
	$source = $FinalItem.FilePath
	$destination = $PSScriptRoot+'\'+$FinalItem.FileName
	downloadFile $source $destination
	return $destination, $FinalItem.Key
}

function DownloadGA2 {
	$URLListFile = ".\bin\W81GA2.txt"  
	$URLList = Get-Content $URLListFile -ErrorAction SilentlyContinue
	$ESDFILES = New-Object System.Collections.ArrayList
	$ESDFILES = @{}
	foreach ($esdlink in $UrlList) {
		$esdname = $esdlink.split('/')[-1]
		$SKU = $esdname.split('-')[1]
		$arch = $esdname.split('-')[2]
		$lang = $esdname.split('-')[3]
		$sku = ($sku -replace 'Windows8NESDwithApps', 'CLIENTCOREN' -replace 'Windows8ESDwithApps', 'CLIENTCORE' -replace 'ProNESDwithApps', 'CLIENTPRON' -replace 'ProESDwithApps', 'CLIENTPRO')
		$lang = ($lang -replace "Arabic", "ar-sa"`
		-replace "Bulgarian", "bg-bg"`
		-replace "Czech", "cs-cz"`
		-replace "Danish", "da-dk"`
		-replace "German", "de-de"`
		-replace "Greek", "el-gr"`
		-replace "EnglishUnitedKingdom", "en-gb"`
		-replace "English", "en-us"`
		-replace "Spanish", "es-es"`
		-replace "Estonian", "et-ee"`
		-replace "Finnish", "fi-fi"`
		-replace "French", "fr-fr"`
		-replace "Hebrew", "he-il"`
		-replace "Croatian", "hr-hr"`
		-replace "Hungarian", "hu-hu"`
		-replace "Italian", "it-it"`
		-replace "Japanese", "ja-jp"`
		-replace "Korean", "ko-kr"`
		-replace "Latvian", "lv-lv"`
		-replace "Lithuanian", "lt-lt"`
		-replace "NorwegianBokmal", "nb-no"`
		-replace "Dutch", "nl-nl"`
		-replace "Polish", "pl-pl"`
		-replace "PortugueseBrazil", "pt-br"`
		-replace "PortuguesePortugal", "pt-pt"`
		-replace "Romanian", "ro-ro"`
		-replace "Russian", "ru-ru"`
		-replace "Slovak", "sk-sk"`
		-replace "Slovenian", "sl-si"`
		-replace "SerbianLatin", "sr-latn-rs"`
		-replace "Swedish", "sv-se"`
		-replace "Thai", "th-th"`
		-replace "Turkish", "tr-tr"`
		-replace "Ukrainian", "uk-ua"`
		-replace "ChineseSimplified", "zh-cn"`
		-replace "ChineseTraditionalHK", "zh-hk"`
		-replace "ChineseTraditionalTW", "zh-tw")
		$arch = $arch -replace '32bit', 'x86' -replace '64bit', 'x64'
		$ESDFILES[$esdname] = @{}
		$ESDFILES[$esdname]['buildstring'] = '9600.17050.winblue_refresh.140317-1640'
		$ESDFILES[$esdname]['url'] = $esdlink
		$ESDFILES[$esdname]['Architecture'] = $arch
		$ESDFILES[$esdname]['Language'] = $lang
		$ESDFILES[$esdname]['Edition'] = $sku
	}
	$URLListFile = ".\bin\W81GA2_.txt"  
	$URLList = Get-Content $URLListFile -ErrorAction SilentlyContinue
	
	foreach ($esd in $URLList) {
		$esdname = $esd.split('/')[-1]
		$esdhash = $esd.split('_')[-1].split('.')[0]
		$build = $esdname.split('.')[0]
		$subver = $esdname.split('.')[1]
		$lab = $esdname.split('.')[2]
		$compiledate = $esdname.split('.')[3].Substring(0,11)
		$buildstring = $build+'.'+$subver+'.'+$lab+'.'+$compiledate
		$otherpart = $esdname.Substring(($build+'.'+$subver+'.'+$compiledate+'.'+$lab).Length)
		$arch = $otherpart.split('_')[1] -replace 'fre', ''
		$lang = $otherpart.split('_')[4] -replace '-ir3', ''
		$sku = $otherpart.split('_')[3] -replace 'corecountryspecific', 'CLIENTCHINA' -replace 'professionalwmc', 'CLIENTPROWMC' -replace 'coresinglelanguage', 'CLIENTSINGLELANGUAGE'
		$ESDFILES[$esdname] = @{}
		$ESDFILES[$esdname]['buildstring'] = $buildstring
		$ESDFILES[$esdname]['url'] = $esd
		$ESDFILES[$esdname]['Hash'] = $esdhash
		$ESDFILES[$esdname]['Architecture'] = $arch
		$ESDFILES[$esdname]['Language'] = $lang
		$ESDFILES[$esdname]['Edition'] = $sku
	}
	
	$langs = @()
	foreach ($esd in $ESDFILES.GetEnumerator().Name) {
		if ($langs -notcontains $ESDFILES.$esd.Language) {
			$langs += $ESDFILES.$esd.Language
		}
	}
	$langs = $langs | sort
	$commonlangs = ($langs -replace 'ar-sa', 'Arabic' -replace 'bg-bg', 'Bulgarian' -replace 'cs-cz', 'Czech' -replace 'da-dk', 'Danish' -replace 'de-de', 'German' -replace 'el-gr', 'Greek' -replace 'en-gb', 'English (United Kingdom)' -replace 'en-us', 'English' -replace 'es-es', 'Spanish' -replace 'et-ee', 'Estonian' -replace 'fi-fi', 'Finnish' -replace 'fr-fr', 'French' -replace 'he-il', 'Hebrew' -replace 'hr-hr', 'Croatian' -replace 'hu-hu', 'Hungarian' -replace 'it-it', 'Italian' -replace 'ja-jp', 'Japanese' -replace 'ko-kr', 'Korean' -replace 'lv-lv', 'Latvian' -replace 'lt-lt', 'Lithuanian' -replace 'nb-no', 'Norwegian (Bokmål)' -replace 'nl-nl', 'Dutch' -replace 'pl-pl', 'Polish' -replace 'pt-br', 'Portuguese (Brazil)' -replace 'pt-pt', 'Portuguese (Portugal)' -replace 'ro-ro', 'Romanian' -replace 'ru-ru', 'Russian' -replace 'sk-sk', 'Slovak' -replace 'sl-si', 'Slovenian' -replace 'sr-latn-rs', 'Serbian Latin' -replace 'sv-se', 'Swedish' -replace 'th-th', 'Thai' -replace 'tr-tr', 'Turkish' -replace 'uk-ua', 'Ukrainian' -replace 'zh-cn', 'Chinese Simplified' -replace 'zh-hk', 'Chinese Traditional HK' -replace 'zh-tw', 'Chinese Traditional TW')
	Write-Host '
Please select your language
===========================
'
	$FinalLanguage = Menu-Select $commonlangs $langs
	$lists = @{}
	foreach ($esd in $ESDFILES.GetEnumerator().Name) {
		if ($ESDFILES.$esd.Language -eq $FinalLanguage) {
			$lists.$esd += $ESDFILES.$esd
		}
	}
	$editions = @()
	foreach ($esd in $lists.GetEnumerator().Name) {
		if ($editions -notcontains $lists.$esd.Edition) {
			$editions += $lists.$esd.Edition
		}
	}
	$editions = $editions | sort
	$commoneditions = ($editions -replace 'CLIENTCOREKN', 'Windows 8.1 KN' -replace 'CLIENTPROKN', 'Windows 8.1 Pro KN' -replace 'CLIENTPRON', 'Windows 8.1 Pro N' -replace 'CLIENTPROK', 'Windows 8.1 Pro K' -replace 'CLIENTCOREK', 'Windows 8.1 K' -replace 'CLIENTCOREN', 'Windows 8.1 N' -replace 'CLIENTPROWMC', 'Windows 8.1 Pro with Media Center' -replace 'CLIENTCHINA', 'Windows 8.1 China' -replace 'CLIENTENTERPRISE', 'Windows 8.1 Enterprise' -replace 'CLIENTPRO', 'Windows 8.1 Pro' -replace 'CLIENTSINGLELANGUAGE', 'Windows 8.1 Single Language' -replace 'CLIENTCORE', 'Windows 8.1')
	Write-Host '
Please select your edition
==========================
'
	$FinalEdition = Menu-Select $commoneditions $editions
	$listsbackup = $lists
	$lists = @{}
	foreach ($esd in $listsbackup.GetEnumerator().Name) {
		if ($ESDFILES.$esd.Edition -eq $FinalEdition) {
			$lists.$esd += $ESDFILES.$esd
		}
	}
	$architectures = @()
	foreach ($esd in $ESDFILES.GetEnumerator().Name) {
		if ($architectures -notcontains $ESDFILES.$esd.Architecture) {
			$architectures += $ESDFILES.$esd.Architecture
		}
	}
	$architectures = $architectures | sort
	$DisplayArchitectures = ($architectures -replace 'x64', '64-bit (x64)' -replace 'x86', '32-bit (x86)' -replace 'fre', '')
	Write-Host '
Please select your architecture
===============================
'
	$FinalArchitecture = Menu-Select $DisplayArchitectures $architectures
	$listsbackup = $lists
	$lists = @{}
	foreach ($esd in $listsbackup.GetEnumerator().Name) {
		if ($ESDFILES.$esd.Architecture -eq $FinalArchitecture) {
			$lists.$esd += $ESDFILES.$esd
		}
	}
	if (-not $lists.Length -eq 1) {
		Write-Host '
Please select your installation media
=====================================
'
		Do {
			$counter = 0
			foreach ($esd in $lists.GetEnumerator().Name) {
				$counter++
				$buildstring = $ESDFILES.$esd.buildstring
				$edition = $ESDFILES.$esd.Edition -replace 'CLIENTCOREKN', 'Windows 8.1 KN' -replace 'CLIENTPROKN', 'Windows 8.1 Pro KN' -replace 'CLIENTPRON', 'Windows 8.1 Pro N' -replace 'CLIENTPROK', 'Windows 8.1 Pro K' -replace 'CLIENTCOREK', 'Windows 8.1 K' -replace 'CLIENTCOREN', 'Windows 8.1 N' -replace 'CLIENTCHINA', 'Windows 8.1 China' -replace 'CLIENTENTERPRISE', 'Windows 8.1 Enterprise' -replace 'CLIENTPRO', 'Windows 8.1 Pro' -replace 'CLIENTSINGLELANGUAGE', 'Windows 8.1 Single Language' -replace 'CLIENTCORE', 'Windows 8.1'
				$architecture = $ESDFILES.$esd.Architecture -replace 'x64', '64-bit (x64)' -replace 'x86', '32-bit (x86)' -replace 'fre', ''
				$language = $ESDFILES.$esd.Language -replace 'ar-sa', 'Arabic' -replace 'bg-bg', 'Bulgarian' -replace 'cs-cz', 'Czech' -replace 'da-dk', 'Danish' -replace 'de-de', 'German' -replace 'el-gr', 'Greek' -replace 'en-gb', 'English (United Kingdom)' -replace 'en-us', 'English' -replace 'es-es', 'Spanish' -replace 'et-ee', 'Estonian' -replace 'fi-fi', 'Finnish' -replace 'fr-fr', 'French' -replace 'he-il', 'Hebrew' -replace 'hr-hr', 'Croatian' -replace 'hu-hu', 'Hungarian' -replace 'it-it', 'Italian' -replace 'ja-jp', 'Japanese' -replace 'ko-kr', 'Korean' -replace 'lt-lt', 'Lithuanian' -replace 'nb-no', 'Norwegian (Bokmål)' -replace 'nl-nl', 'Dutch' -replace 'pl-pl', 'Polish' -replace 'pt-br', 'Portuguese (Brazil)' -replace 'pt-pt', 'Portuguese (Portugal)' -replace 'ro-ro', 'Romanian' -replace 'ru-ru', 'Russian' -replace 'sk-sk', 'Slovak' -replace 'sl-si', 'Slovenian' -replace 'sr-latn-rs', 'Serbian Latin' -replace 'sv-se', 'Swedish' -replace 'th-th', 'Thai' -replace 'tr-tr', 'Turkish' -replace 'uk-ua', 'Ukrainian' -replace 'zh-cn', 'Chinese Simplified' -replace 'zh-hk', 'Chinese Traditional HK' -replace 'zh-tw', 'Chinese Traditional TW'
				$number = '['+$counter+']'
				$padding = ' ' * $number.length
				Write-Host ('=' * ($number+' BuildString : '+$buildstring).Length)
				Write-Host $number' BuildString : '$buildstring
				Write-Host $padding' Name        : '$edition
				Write-Host $padding' Architecture: '$architecture
				Write-Host $padding' Language    : '$language
				Write-Host ('=' * ($number+' BuildString : '+$buildstring).Length)
			}
			Write-Host ''
			$choice = read-host -prompt "Select number and press enter"
		} until ([int]$choice -gt 0 -and [int]$choice -le $counter)
		$choice = $choice - 1
		$FinalItem = $lists.GetEnumerator().Name[$choice]
	} else {
		$FinalItem = $lists.GetEnumerator().Name
	}
	cls
	$source = $ESDFILES.$FinalItem.url
	$destination = $PSScriptRoot+'\'+$FinalItem
	downloadFile $source $destination
	return $destination
}

New-Enum iso.filenametype Partner Consumer Windows7
New-Enum wim.extensiontype WIM ESD

function Get-InfosFromESD(
	[parameter(Mandatory=$true,HelpMessage="The complete path to the ESD file to convert.")]
	[Array] $ESD
) {
	
	$result = "" | select MajorVersion, MinorVersion, BuildNumber, DeltaVersion, BranchName, CompileDate, Architecture, BuildType, Type, Sku, Editions, Licensing, LanguageCode, VolumeLabel, FileName
	
	$editions = @()
	$counter = 0
	
	$WIMInfo = New-Object System.Collections.ArrayList
	$WIMInfo=@{}
	
	for ($i=1; $i -le 3; $i++){
		$counter++
		$WIMInfo[$counter] = @{}
		$OutputVariable = ( & $wimlib info "$($ESD[0])" $i)
		ForEach ($Item in $OutputVariable) {
			$CurrentItem = ($Item -replace '\s+', ' ').split(':')
			$CurrentItemName = $CurrentItem[0] -replace ' ', ''
			if (($CurrentItem[1] -replace ' ', '') -ne '') {
				$WIMInfo[$counter][$CurrentItemName] = $CurrentItem[1].Substring(1)
			}
		}
	}
	
	foreach ($esdfile in $ESD) {
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
	& $wimlib extract $ESD[0] 4 windows\system32\ntkrnlmp.exe windows\system32\ntoskrnl.exe --nullglob --no-acls | out-null
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
	& $wimlib extract $ESD[0] 4 windows\system32\config\ --no-acls | out-null
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
		
	if (($WIMInfo.header.ImageCount -eq 7) -and ($result.Type -eq 'server')) {
		$result.Sku = $null
	}
		
	& $wimlib extract $ESD[0] 1 sources\lang.ini --nullglob --no-acls | out-null
	Get-Content ('lang.ini') | foreach-object -begin {$h=@()} -process { $k = [regex]::split($_,'`r`n'); if(($k[0].CompareTo("") -ne 0)) { $h += $k[0] } }
	$result.LanguageCode = ($h[((0..($h.Count - 1) | Where { $h[$_] -eq '[Available UI Languages]' }) + 1)]).split('=')[0].Trim()
	remove-item lang.ini -force
	
	$tag = 'ir3'
	
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
	
	$DVDLabel = ($tag+'_CCSA_'+$arch+'FRER_'+$WIMInfo[4].DefaultLanguage+'_DV9').ToUpper()
	if ($WIMInfo.header.ImageCount -eq 4) {
		if ($WIMInfo[4].EditionID -eq 'Core') {$DVDLabel = ($tag+'_CCRA_'+$arch+'FRER_'+$WIMInfo[4].DefaultLanguage+'_DV9').ToUpper()}
		if ($WIMInfo[4].EditionID -eq 'CoreN') {$DVDLabel = ($tag+'_CCRNA_'+$arch+'FRER_'+$WIMInfo[4].DefaultLanguage+'_DV9').ToUpper()}
		if ($WIMInfo[4].EditionID -eq 'CoreSingleLanguage') {$DVDLabel = ($tag+'_CSLA_'+$arch+'FRER_'+$WIMInfo[4].DefaultLanguage+'_DV9').ToUpper()}
		if ($WIMInfo[4].EditionID -eq 'CoreCountrySpecific') {$DVDLabel = ($tag+'_CCHA_'+$arch+'FRER_'+$WIMInfo[4].DefaultLanguage+'_DV9').ToUpper()}
		if ($WIMInfo[4].EditionID -eq 'Professional') {$DVDLabel = ($tag+'_CPRA_'+$arch+'FRER_'+$WIMInfo[4].DefaultLanguage+'_DV9').ToUpper()}
		if ($WIMInfo[4].EditionID -eq 'ProfessionalN') {$DVDLabel = ($tag+'_CPRNA_'+$arch+'FRER_'+$WIMInfo[4].DefaultLanguage+'_DV9').ToUpper()}
		if ($WIMInfo[4].EditionID -eq 'ProfessionalWMC') {$DVDLabel = ($tag+'_CPWMCA_'+$arch+'FRER_'+$WIMInfo[4].DefaultLanguage+'_DV9').ToUpper()}
		if ($WIMInfo[4].EditionID -eq 'CoreConnected') {$DVDLabel = ($tag+'_CCONA_'+$arch+'FRER_'+$WIMInfo[4].DefaultLanguage+'_DV9').ToUpper()}
		if ($WIMInfo[4].EditionID -eq 'CoreConnectedN') {$DVDLabel = ($tag+'_CCONNA_'+$arch+'FRER_'+$WIMInfo[4].DefaultLanguage+'_DV9').ToUpper()}
		if ($WIMInfo[4].EditionID -eq 'CoreConnectedSingleLanguage') {$DVDLabel = ($tag+'_CCSLA_'+$arch+'FRER_'+$WIMInfo[4].DefaultLanguage+'_DV9').ToUpper()}
		if ($WIMInfo[4].EditionID -eq 'CoreConnectedCountrySpecific') {$DVDLabel = ($tag+'_CCCHA_'+$arch+'FRER_'+$WIMInfo[4].DefaultLanguage+'_DV9').ToUpper()}
		if ($WIMInfo[4].EditionID -eq 'ProfessionalStudent') {$DVDLabel = ($tag+'_CPRSA_'+$arch+'FRER_'+$WIMInfo[4].DefaultLanguage+'_DV9').ToUpper()}
		if ($WIMInfo[4].EditionID -eq 'ProfessionalStudentN') {$DVDLabel = ($tag+'_CPRSNA_'+$arch+'FRER_'+$WIMInfo[4].DefaultLanguage+'_DV9').ToUpper()}
	}
	
	if ([int] $WIMInfo[4].Build -gt '9600') {
		$DVDLabel = ('JM1_CCSA_'+$arch+'FRE_'+$WIMInfo[4].DefaultLanguage+'_DV5').ToUpper()
		if ($WIMInfo.header.ImageCount -eq 4) {
			if ($WIMInfo[4].EditionID -eq 'Core') {$DVDLabel = ('JM1_CCRA_'+$arch+'FRER_'+$WIMInfo[4].DefaultLanguage+'_DV5').ToUpper()}
			if ($WIMInfo[4].EditionID -eq 'CoreSingleLanguage') {$DVDLabel = ('JM1_CSLA_'+$arch+'FRER_'+$WIMInfo[4].DefaultLanguage+'_DV5').ToUpper()}
			if ($WIMInfo[4].EditionID -eq 'CoreCountrySpecific') {$DVDLabel = ('JM1_CCHA_'+$arch+'FRER_'+$WIMInfo[4].DefaultLanguage+'_DV5').ToUpper()}
			if ($WIMInfo[4].EditionID -eq 'Professional') {$DVDLabel = ('JM1_CPRA_'+$arch+'FRER_'+$WIMInfo[4].DefaultLanguage+'_DV5').ToUpper()}
			if ($WIMInfo[4].EditionID -eq 'Enterprise') {$DVDLabel = ('JM1_CENA_'+$arch+'FREV_'+$WIMInfo[4].DefaultLanguage+'_DV5').ToUpper()}
		}
	}
	
	if ([int] $WIMInfo[4].Build -ge '9896') {
		$DVDLabel = ('J_CCSA_'+$arch+'FRE_'+$WIMInfo[4].DefaultLanguage+'_DV5').ToUpper()
		if ($WIMInfo.header.ImageCount -eq 4) {
			if ($WIMInfo[4].EditionID -eq 'Core') {$DVDLabel = ('J_CCRA_'+$arch+'FRER_'+$WIMInfo[4].DefaultLanguage+'_DV5').ToUpper()}
			if ($WIMInfo[4].EditionID -eq 'CoreSingleLanguage') {$DVDLabel = ('J_CSLA_'+$arch+'FRER_'+$WIMInfo[4].DefaultLanguage+'_DV5').ToUpper()}
			if ($WIMInfo[4].EditionID -eq 'CoreCountrySpecific') {$DVDLabel = ('J_CCHA_'+$arch+'FRER_'+$WIMInfo[4].DefaultLanguage+'_DV5').ToUpper()}
			if ($WIMInfo[4].EditionID -eq 'Professional') {$DVDLabel = ('J_CPRA_'+$arch+'FRER_'+$WIMInfo[4].DefaultLanguage+'_DV5').ToUpper()}
			if ($WIMInfo[4].EditionID -eq 'Enterprise') {$DVDLabel = ('J_CENA_'+$arch+'FREV_'+$WIMInfo[4].DefaultLanguage+'_DV5').ToUpper()}
		}
	}
	
	$result.VolumeLabel = $DVDLabel
	
	$Edition = $null
	$Licensing = $null
	
	foreach ($item_ in $result.Editions) {
		if ($Edition -eq $null) {
			$Licensing = 'RET'
			$Edition_ = $item_
			if ($item_ -eq 'Core') {$Edition_ = 'CORE'}
			if ($item_ -eq 'CoreN') {$Edition_ = 'COREN'}
			if ($item_ -eq 'CoreSingleLanguage') {$Edition_ = 'SINGLELANGUAGE'}
			if ($item_ -eq 'CoreCountrySpecific') {$Edition_ = 'CHINA'}
			if ($item_ -eq 'Professional') {$Edition_ = 'PRO'}
			if ($item_ -eq 'ProfessionalN') {$Edition_ = 'PRON'}
			if ($item_ -eq 'ProfessionalWMC') {$Edition_ = 'PROWMC'}
			if ($item_ -eq 'CoreConnected') {$Edition_ = 'CORECONNECTED'}
			if ($item_ -eq 'CoreConnectedN') {$Edition_ = 'CORECONNECTEDN'}
			if ($item_ -eq 'CoreConnectedSingleLanguage') {$Edition_ = 'CORECONNECTEDSINGLELANGUAGE'}
			if ($item_ -eq 'CoreConnectedCountrySpecific') {$Edition_ = 'CORECONNECTEDCHINA'}
			if ($item_ -eq 'ProfessionalStudent') {$Edition_ = 'PROSTUDENT'}
			if ($item_ -eq 'ProfessionalStudentN') {$Edition_ = 'PROSTUDENTN'}
			if ($item_ -eq 'Enterprise') {
				$Licensing = 'VOL'
				$Edition_ = 'ENTERPRISE'
			}
			$Edition = $Edition_
		} else {
			$Edition_ = $item_
			if ($item_ -eq 'Core') {$Edition_ = 'CORE'}
			if ($item_ -eq 'CoreN') {$Edition_ = 'COREN'}
			if ($item_ -eq 'CoreSingleLanguage') {$Edition_ = 'SINGLELANGUAGE'}
			if ($item_ -eq 'CoreCountrySpecific') {$Edition_ = 'CHINA'}
			if ($item_ -eq 'Professional') {$Edition_ = 'PRO'}
			if ($item_ -eq 'ProfessionalN') {$Edition_ = 'PRON'}
			if ($item_ -eq 'ProfessionalWMC') {$Edition_ = 'PROWMC'}
			if ($item_ -eq 'CoreConnected') {$Edition_ = 'CORECONNECTED'}
			if ($item_ -eq 'CoreConnectedN') {$Edition_ = 'CORECONNECTEDN'}
			if ($item_ -eq 'CoreConnectedSingleLanguage') {$Edition_ = 'CORECONNECTEDSINGLELANGUAGE'}
			if ($item_ -eq 'CoreConnectedCountrySpecific') {$Edition_ = 'CORECONNECTEDCHINA'}
			if ($item_ -eq 'ProfessionalStudent') {$Edition_ = 'PROSTUDENT'}
			if ($item_ -eq 'ProfessionalStudentN') {$Edition_ = 'PROSTUDENTN'}
			if ($item_ -eq 'Enterprise') {
				$Licensing = $Licensing+'VOL'
				$Edition_ = 'ENTERPRISE'
			}
			$Edition = $Edition+'-'+$Edition_
		}
	}
	
	if ($result.Type.toLower() -eq 'server') {
		$Edition = $Edition.toUpper()  -replace 'SERVERHYPER', 'SERVERHYPERCORE' -replace 'SERVER', ''
	}
	
	if ($result.Licensing.toLower() -eq 'volume') {
		$Licensing = 'VOL'
	} elseif ($result.Licensing.toLower() -eq 'oem') {
		$Licensing = 'OEM'
	} elseif ($Licensing -eq $null) {
		$Licensing = 'RET'
	}
	
	if ($Edition -contains 'PRO-CORE') {
		$Licensing = $Licensing -replace 'RET', 'OEMRET'
	} elseif ($result.Sku -eq $null -and $result.Type.toLower() -eq 'server') {
		$Edition = ''
		if ($result.Licensing.toLower() -eq 'retail') {
			$Licensing = 'OEMRET'
		}
		if ($result.Licensing.toLower() -eq 'retail' -and [int]$result.BuildNumber -lt 9900) {
			$Licensing = 'OEM'
		}
	} elseif ($result.Editions.Count -eq 1 -and $result.Type.toLower() -eq 'server') {
		$Licensing = 'OEM'
	}
	
	if ([int]$result.BuildNumber -lt 8008) {
		$Edition = $result.Sku
	}
	
	if ($Edition -eq 'unstaged') {
		$Edition = ''
	}
	
	$arch = $result.Architecture -replace 'amd64', 'x64'
	if ($result.BranchName -eq $null) {
		$FILENAME = ($result.BuildNumber+'.'+$result.DeltaVersion)
	} else {
		$FILENAME = ($result.BuildNumber+'.'+$result.DeltaVersion+'.'+$result.CompileDate+'.'+$result.BranchName)
	}
	
	$FILENAME = ($FILENAME+'_'+$result.Type+$Edition+'_'+$Licensing+'_'+$arch+$result.BuildType+'_'+$result.LanguageCode)
	
	if ($addLabel) {
		$filename = $filename+'-'+$result.VolumeLabel
	}
	$result.FileName = ($filename+'.iso').ToUpper()
	
	return $result
}

function Convert-ESD (
	[ValidateNotNullOrEmpty()]  
    [ValidateScript({(Test-Path $_) -and ((Get-Item $_).Extension -eq ".esd")})] 
	[parameter(Mandatory=$true,HelpMessage="The complete path to the ESD file to convert.")]
	[Array] $ESD,

	[ValidateNotNullOrEmpty()]  
    [ValidateScript({(Test-Path $_)})] 
	[parameter(Mandatory=$true,HelpMessage="The place where the final ISO file will be stored")]
	[System.IO.DirectoryInfo] $Destination,
	
	[ValidateNotNullOrEmpty()]
	[parameter(Mandatory=$false,HelpMessage="The crypto key that will be used to decrypt the ESD file.")]
	$CryptoKey,
	
	[parameter(Mandatory=$true,HelpMessage="The type of extension used for the Windows Image (WIM or ESD)")]
	[wim.extensiontype] $extensiontype
)
{
	
	$MainESDFile = $ESD[0]
	
	$ProcessESD = @()
	$DeleteESD = @()
	
	foreach ($esdfile in $ESD) {
		& $wimlib info "$($esdfile)" > $null
		if (!$?) {
			$ProcessESD += $esdfile+".mod"
			$DeleteESD += $esdfile+".mod"
			$TempESD = $esdfile + ".mod"
			Output ([out.level] 'Info') 'Copying ESD File...'
			Copy-File $esdfile $TempESD
			Output ([out.level] 'Info') 'Decrypting ESD File...'
			& ".\bin\esddecrypt.exe" "$($TempESD)" "$($CryptoKey)"
			if ($LASTEXITCODE -ne 0) {
				Write-Host 'Error! ' $LASTEXITCODE
				foreach ($esdfile in $DeleteESD) {
					Remove-Item $esdfile
				}
				return
			}
		} else {
			$ProcessESD += $esdfile
		}
	}
	
	Output ([out.level] 'Info') 'Gathering build information...'
	$ISOInfos = (Get-InfosFromESD $ProcessESD)
	
	$ISOInfos
	
	Output ([out.level] 'Info') 'Creating Media Temporary Directory...'
	New-Item -ItemType Directory '.\Media' | out-null
	Output ([out.level] 'Info') 'Creating Setup Media Layout...'
	
	$name = $null
    & $wimlib apply "$($ProcessESD[0])" 1 .\Media\ | ForEach-Object -Process {
		if ($name -eq $null) {
			$name = $_
		}
		$progress = [regex]::match($_,'\(([^\)]+)\%').Groups[1].Value
		if ($progress -match "[0-9]") {
			Write-Progress -Activity ('Creating Setup Media Layout...') -status ($name) -PercentComplete $progress -CurrentOperation $_;
		}
	}
	Write-Progress -Activity ('Creating Setup Media Layout...') -Complete
	
	Output ([out.level] 'Info') 'Deleting MediaMeta.xml file...'
	Remove-Item .\Media\MediaMeta.xml
	Output ([out.level] 'Info') 'Creating bootable setup image...'
	
	$sw = [System.Diagnostics.Stopwatch]::StartNew();
	$name = $null
    & $wimlib export "$($ProcessESD[0])" 2 .\Media\sources\boot.wim --compress=maximum | ForEach-Object -Process {
		if ($name -eq $null) {
			$name = $_
		}
		$progress = [regex]::match($_,'\(([^\)]+)\%').Groups[1].Value
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
			$progress = [long]$progress / 2
			Write-Progress -Activity ('Creating bootable setup image...') -status ($name) -PercentComplete ($progress) -SecondsRemaining $secsleft -CurrentOperation $_' (1/2)';
		}
	}
	$sw.Stop();
	$sw.Reset();
	
	$sw = [System.Diagnostics.Stopwatch]::StartNew();
	$name = $null
	& $wimlib export "$($ProcessESD[0])" 3 .\Media\sources\boot.wim --boot | ForEach-Object -Process {
		if ($name -eq $null) {
			$name = $_
		}
		$progress = [regex]::match($_,'\(([^\)]+)\%').Groups[1].Value
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
			$progress = [long]$progress / 2 + 50
			Write-Progress -Activity ('Creating bootable setup image...') -status ($name) -PercentComplete ($progress) -SecondsRemaining $secsleft -CurrentOperation $_' (2/2)';
		}
	}
	$sw.Stop();
	$sw.Reset();
	Write-Progress -Activity ('Creating bootable setup image...') -Complete
	
	Output ([out.level] 'Info') 'Creating the Windows image...'
	$indexcounter = 1
	$globalprogress = 0
	foreach ($esdfile in $ProcessESD) {
		$header = @{}
		$OutputVariable = ( & $wimlib info "$($esdfile)" --header)
		ForEach ($Item in $OutputVariable) {
			$CurrentItem = ($Item -replace '\s+', ' ').split('=')
			$CurrentItemName = $CurrentItem[0] -replace ' ', ''
			if (($CurrentItem[1] -replace ' ', '') -ne '') {
				$header[$CurrentItemName] = $CurrentItem[1].Substring(1)
			}
		}
		$name = $null
		$sw = [System.Diagnostics.Stopwatch]::StartNew();
		if ($extensiontype -eq 'ESD') {
			for ($i=4; $i -le $header.ImageCount; $i++) {
				& $wimlib export "$($esdfile)" $i .\Media\sources\install.esd --compress=LZMS --solid | ForEach-Object -Process {
					if ($name -eq $null) {
						$name = $_
					}
					$progress = [regex]::match($_,'\(([^\)]+)\%').Groups[1].Value
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
						$progress = [long]$progress / $ProcessESD.Count + $globalprogress
						Write-Progress -Activity ('Creating the Windows image...') -status ($name) -PercentComplete ($progress) -SecondsRemaining $secsleft -CurrentOperation ($_+' ('+$indexcounter+'/'+$ProcessESD.Count+')');
					}
				}
				$indexcounter++
				if ($WIMInfo.$indexcounter.EditionID -eq 'ProfessionalWMC') {
					cmd /c ($wimlib + ' update ".\Media\sources\install.esd" $indexcounter <wim-update.txt')
					Write-Host ''
				}
			}
			$globalprogress = $globalprogress + (100 / $ProcessESD.Count)
		} else {
			$name = $null
			for ($i=4; $i -le $header.ImageCount; $i++) {
				& $wimlib export "$($esdfile)" $i .\Media\sources\install.wim --compress=maximum | ForEach-Object -Process {
					if ($name -eq $null) {
						$name = $_
					}
					$progress = [regex]::match($_,'\(([^\)]+)\%').Groups[1].Value
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
						Write-Progress -Activity ('Creating the Windows image...') -status ($name) -PercentComplete ($progress) -SecondsRemaining $secsleft -CurrentOperation ($_+' ('+$indexcounter+'/'+$ProcessESD.Count+')');
					}
				}
				$indexcounter++
				if ($WIMInfo.$indexcounter.EditionID -eq 'ProfessionalWMC') {
					cmd /c ($wimlib + ' update ".\Media\sources\install.wim" $indexcounter <wim-update.txt')
					Write-Host ''
				}
			}
			$globalprogress = $globalprogress + (100 / $ProcessESD.Count)
		}
		$sw.Stop();
		$sw.Reset();
	}
	Write-Progress -Activity ('Creating the Windows image...') -Complete
	
	Output ([out.level] 'Info') 'Gathering Timestamp information from the Setup Media...'
	$timestamp = (Get-ChildItem .\Media\sources\setup.exe | % {[System.TimeZoneInfo]::ConvertTimeToUtc($_.creationtime).ToString("MM/dd/yyyy,HH:mm:ss")})
	Output ([out.level] 'Info') 'Generating ISO...'
	
	$BootData='2#p0,e,bMedia\boot\etfsboot.com#pEF,e,bMedia\efi\Microsoft\boot\efisys.bin'
	& "cmd" "/c" ".\bin\cdimage.exe" "-bootdata:$BootData" "-o" "-h" "-m" "-u2" "-udfver102" "-t$timestamp" "-l$($ISOInfos.VolumeLabel)" "$($Destination)\Media" """$($ISOInfos.FileName)"""<#  | ForEach-Object -Process {
		if ($count -eq 11) {Write-Host ''}
		if ($count -eq 30) {Write-Host ''}
		$count++
	} #>
	
	Write-Host ''
	Output ([out.level] 'Info') 'Removing Temporary Directories and Files...'
    Remove-Item -recurse .\Media
	foreach ($esdfile in $DeleteESD) {
		Remove-Item $esdfile
	}
}

function ESD-ise ($ISOFile, $Destination) {
	#& 'bin\7z' x -y -o'.\WIMExtract' "$($ISOFile)" -ir@'bin\exclude.txt'
	#& 'bin\7z' x -y -o'.\ISOExtract' "$($ISOFile)" -xr@'bin\exclude.txt'
	
	$WIMInfo = New-Object System.Collections.ArrayList
	$WIMInfo=@{}
	
	$WIMInfo['header'] = @{}
	$OutputVariable = ( & $wimlib info ".\WIMExtract\sources\install.wim" --header)
	ForEach ($Item in $OutputVariable) {
		$CurrentItem = ($Item -replace '\s+', ' ').split('=')
		$CurrentItemName = $CurrentItem[0] -replace ' ', ''
		if (($CurrentItem[1] -replace ' ', '') -ne '') {
			$WIMInfo['header'][$CurrentItemName] = $CurrentItem[1].Substring(1)
		}
	}
	
	for ($i=1; $i -le $WIMInfo.header.ImageCount; $i++){
		$WIMInfo[$i] = @{}
		$OutputVariable = ( & $wimlib info ".\WIMExtract\sources\install.wim" $i)
		ForEach ($Item in $OutputVariable) {
			$CurrentItem = ($Item -replace '\s+', ' ').split(':')
			$CurrentItemName = $CurrentItem[0] -replace ' ', ''
			if (($CurrentItem[1] -replace ' ', '') -ne '') {
				$WIMInfo[$i][$CurrentItemName] = $CurrentItem[1].Substring(1)
			}
		}
	}
	Write-Host '
Please Select which Index do you want to export to the ESD Image
================================================================
'
	Do {
		$counter = 0
		for ($i=1; $i -le $WIMInfo.header.ImageCount; $i++) {
			$counter++
			$padding = ' ' * ((([string]$WIMInfo.header.ImageCount).Length) - (([string]$counter).Length))
			Write-host ('['+$counter+']'+$padding) $WIMInfo.$i.DisplayName
			Write-host ((' ' * ('['+$counter+']').Length)+$padding) $WIMInfo.$i.DisplayDescription
			Write-host ((' ' * ('['+$counter+']').Length)+$padding) $WIMInfo.$i.Architecture
		}
		Write-Host ''
		$choice = read-host -prompt "Select number and press enter"
	} until ([int]$choice -gt 0 -and [int]$choice -le $counter)
	
	& $wimlib capture .\ISOExtract test.esd "Windows Setup Media" "Windows Setup Media" --compress=LZX
	$name = $null
	$sw = [System.Diagnostics.Stopwatch]::StartNew();
	& $wimlib export .\WIMExtract\sources\boot.wim 1 test.esd --compress=LZX | ForEach-Object -Process {
		if ($name -eq $null) {
			$name = $_
		}
		$progress = [regex]::match($_,'\(([^\)]+)\%').Groups[1].Value
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
			$progress = [long]$progress / 2
			Write-Progress -Activity ('Exporting bootable setup image...') -status ($name) -PercentComplete ($progress) -SecondsRemaining $secsleft -CurrentOperation ($_+' (1/2)');
		}
	}
	$sw.Stop();
	$sw.Reset();
	$name = $null
	$sw = [System.Diagnostics.Stopwatch]::StartNew();
	& $wimlib export .\WIMExtract\sources\boot.wim 2 test.esd --compress=LZX | ForEach-Object -Process {
		if ($name -eq $null) {
			$name = $_
		}
		$progress = [regex]::match($_,'\(([^\)]+)\%').Groups[1].Value
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
			$progress = [long]$progress / 2 + 50
			Write-Progress -Activity ('Exporting bootable setup image...') -status ($name) -PercentComplete ($progress) -SecondsRemaining $secsleft -CurrentOperation ($_+' (2/2)');
		}
	}
	$sw.Stop();
	$sw.Reset();
	Write-Progress -Activity ('Exporting bootable setup image...') -Complete
	$name = $null
	$sw = [System.Diagnostics.Stopwatch]::StartNew();
	& $wimlib export .\WIMExtract\sources\install.wim $choice test.esd --compress=LZX | ForEach-Object -Process {
		if ($name -eq $null) {
			$name = $_
		}
		$progress = [regex]::match($_,'\(([^\)]+)\%').Groups[1].Value
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
			Write-Progress -Activity ('Exporting the Windows image...') -status ($name) -PercentComplete ($progress) -SecondsRemaining $secsleft -CurrentOperation ($_);
		}
	}
	$sw.Stop();
	$sw.Reset();
	Write-Progress -Activity ('Exporting the Windows image...') -Complete
}

function Wizard-Decrypt() {

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
	
	$Title = "What type of filename do you want for your ISO file ?"
	
	$message = "ESD Decrypter needs to know which type of filename your final iso will have (according to your preferences)."

	$CONSUMER = New-Object System.Management.Automation.Host.ChoiceDescription "&Consumer Format", `
	    "Example: Windows10_SingleLanguage_InsiderPreview_x32_EN-US_10074.iso"
	
	$PARTNER = New-Object System.Management.Automation.Host.ChoiceDescription "&Partner/Internal Format", `
	    "Example: 10074.0.150424-1350.FBL_IMPRESSIVE_CLIENTSINGLELANGUAGE_RET_X86FRE_EN-US.ISO"
	
	$W7 = New-Object System.Management.Automation.Host.ChoiceDescription "&Windows 7 and earlier Format", `
	    "Example: en_10074.0.150424-1350_x86fre_singlelanguage_en-us_CoreSingleLanguage-J_CSLA_X86FRER_EN-US_DV5.iso"
		
	$options = [System.Management.Automation.Host.ChoiceDescription[]]($CONSUMER, $PARTNER, $W7)
	
	$result = $host.ui.PromptForChoice($title, $message, $options, 0) 
	
	switch ($result)
  	{
		0 {$scheme = 0}
		1 {$scheme = 1}
		2 {$scheme = 2}
    }
	
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
				Convert-ESD -CryptoKey $key -extensiontype $extensiontype -ESD $selected -Destination $CustomPath
			} else {
				Convert-ESD -extensiontype $extensiontype -ESD $selected -Destination $CustomPath
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

function Download-Decrypt {
	$versions = @('https://wscont.apps.microsoft.com/winstore/OSUpgradeNotification/products_1.xml', 'https://wscont.apps.microsoft.com/winstore/OSUpgradeNotification/products_472.xml', 'https://wscont.apps.microsoft.com/winstore/OSUpgradeNotification/MediaCreationTool/prod/Products.xml', "https://wscont.apps.microsoft.com/winstore/OSUpgradeNotification/MediaCreationTool/prod/Products11092015.xml")

	$DisplayItems = @()
	foreach ($item in $versions) {
		$wc = New-Object System.Net.WebClient
		$wc.Encoding = [System.Text.Encoding]::utf8
		[xml]$doc = $wc.DownloadString($item)
		$FileName = ($doc.PublishedMedia.Files.File.FileName | % { $_ })[0]
		$build = $FileName.split('.')[0]
		$subver = $FileName.split('.')[1]
		$lab = $FileName.split('.')[2]
		$compiledate = $FileName.split('.')[3].split('_')[0]
		$DisplayItems += ($doc.PublishedMedia.release+' ('+$build+'.'+$subver+'.'+$lab+'.'+$compiledate+')')
	}
	$versions += '.\bin\Products_10240.xml'
	[xml]$doc = get-content .\bin\Products_10240.xml
	$FileName = ($doc.PublishedMedia.Files.File.FileName | % { $_ })[0]
	$build = $FileName.split('.')[0]
	$subver = $FileName.split('.')[1]
	$lab = $FileName.split('.')[2]
	$compiledate = $FileName.split('.')[3].split('_')[0]
	$DisplayItems += ($doc.PublishedMedia.release+' ('+$build+'.'+$subver+'.'+$lab+'.'+$compiledate+')')
	$versions += '9600.17050.winblue_refresh.140317-1640'
	$DisplayItems += 'Windows Blue March 2014 Update GA 2 (9600.17050.winblue_refresh.140317-1640)'
	$versions += 'http://ms-vnext.net/Win10esds/urls/'
	$DisplayItems += 'MS-vNext ESD Download list'

	Write-Host '
Please select your version
==========================
'
	Write-host 'Credits to MS-vNext for the work done on this database, without them, this downloader would not be here, so all the credits goes for them.'
	Write-host ''
	$selected = Menu-Select $DisplayItems $versions

	if ($selected -eq 'http://ms-vnext.net/Win10esds/urls/') {
		$Links = (Invoke-WebRequest -UseBasicParsing -Uri 'http://ms-vnext.net/Win10esds/urls/').Links.href
		$esdfile = Select-ESD $Links
	} elseif ($selected -eq '9600.17050.winblue_refresh.140317-1640') {
		$esdfile = DownloadGA2
	} else {
		$result = DownloadFrom-XML $selected
		$esdfile = $result[0]
		$key = $result[1]
	}
	
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
	
	$Title = "What type of filename do you want for your ISO file ?"
	
	$message = "ESD Decrypter needs to know which type of filename your final iso will have (according to your preferences)."

	$CONSUMER = New-Object System.Management.Automation.Host.ChoiceDescription "&Consumer Format", `
	    "Example: Windows10_SingleLanguage_InsiderPreview_x32_EN-US_10074.iso"
	
	$PARTNER = New-Object System.Management.Automation.Host.ChoiceDescription "&Partner/Internal Format", `
	    "Example: 10074.0.150424-1350.FBL_IMPRESSIVE_CLIENTSINGLELANGUAGE_RET_X86FRE_EN-US.ISO"
	
	$W7 = New-Object System.Management.Automation.Host.ChoiceDescription "&Windows 7 and earlier Format", `
	    "Example: en_10074.0.150424-1350_x86fre_singlelanguage_en-us_CoreSingleLanguage-J_CSLA_X86FRER_EN-US_DV5.iso"
		
	$options = [System.Management.Automation.Host.ChoiceDescription[]]($CONSUMER, $PARTNER, $W7)
	
	$result = $host.ui.PromptForChoice($title, $message, $options, 0) 
	
	switch ($result)
  	{
		0 {$scheme = 0}
		1 {$scheme = 1}
		2 {$scheme = 2}
    }
	if ($key -eq $null) {
	
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
			Convert-ESD -CryptoKey $key -extensiontype $extensiontype -ESD $esdfile -Destination '.'
		} else {
			Convert-ESD -extensiontype $extensiontype -ESD $esdfile -Destination '.'
		}
	} else {
		Convert-ESD -CryptoKey $key -extensiontype $extensiontype -ESD $esdfile -Destination '.'
	}
}

if ($ESD -ne $null) {
	if ($CryptoKey -eq $null) {
		Convert-ESD -ESD $ESD -Destination $Destination -extensiontype $extensiontype
	} else {
		Convert-ESD -ESD $ESD -Destination $Destination -extensiontype $extensiontype -CryptoKey $CryptoKey
	}
	return
}

$Title = "Where do you want to go today ?"
	
$message = "Please select what you want to do."

$ESD_ = New-Object System.Management.Automation.Host.ChoiceDescription "Decrypt an &ESD File", `
    "TBD"
	
$DESD = New-Object System.Management.Automation.Host.ChoiceDescription "&Download and Decrypt an ESD File", `
    "TBD"
	
$options = [System.Management.Automation.Host.ChoiceDescription[]]($ESD_, $DESD)
	
$result = $host.ui.PromptForChoice($title, $message, $options, 0) 
	
switch ($result)
{
	0 {Wizard-Decrypt}
	1 {Download-Decrypt}
}

Write-Host 'Done.'

stop-transcript | out-null