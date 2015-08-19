
$Host.UI.RawUI.WindowTitle = "ESD Toolkit - August Tech Preview 2015"

Write-Host '
Based on the script by abbodi1406
ESD Toolkit - July Tech Preview 2015 - Copyright 2015 (c) gus33000 - Version 3.0
For testing purposes only. Build 3.0.10115.0.fbl_release(gus33000).150819-1634
'

Write-Host 'Loading utilities module...'
. '.\utils.ps1'

New-Enum iso.filenametype Partner Consumer Windows7
New-Enum wim.extensiontype WIM ESD

function Gather-Info (
	[parameter(Mandatory=$true,HelpMessage="The complete path to the ESD file to convert.")]
	[Array] $ESD,
	
	[parameter(Mandatory=$true,HelpMessage="The type of filename used for the iso")]
	[iso.filenametype] $filenametype
)
{
	
	$ESDInfo = New-Object System.Collections.ArrayList
	$ESDInfo=@{}
	
	foreach ($esdfile in $ESD) {
		$ESDInfo[$esdfile] = @{}
		$OutputVariable = ( & $wimlib info "$($esdfile)" 4)
		ForEach ($Item in $OutputVariable) {
			$CurrentItem = ($Item -replace '\s+', ' ').split(':')
			$CurrentItemName = $CurrentItem[0] -replace ' ', ''
			if (($CurrentItem[1] -replace ' ', '') -ne '') {
				$ESDInfo[$esdfile][$CurrentItemName] = $CurrentItem[1].Substring(1)
			}
		}
	}
	
	$tag = 'ir3'
	
	$MainESDFile = $ESD[0]
	
	if ($ESDInfo.$MainESDFile.ServicePackBuild -eq '17056') {
		$tag = 'ir4'
	}
	if ($ESDInfo.$MainESDFile.ServicePackBuild -eq '17415') {
		$tag = 'ir5'
	}
	if ($ESDInfo.$MainESDFile.ServicePackBuild -gt '17415') {
		$tag = 'ir6'
	}
	
	if ($ESDInfo.$MainESDFile.Architecture -eq 'x86') {
		$arch = 'x86'
	}
	
	if ($ESDInfo.$MainESDFile.Architecture -eq 'x86_64') {
		$arch = 'x64'
	}
	
	$DVDLabel = ($tag+'_CCSA_'+$arch+'FRER_'+$ESDInfo.$MainESDFile.DefaultLanguage+'_DV9').ToUpper()
	if ($ESD.Count -eq 1) {
		if ($ESDInfo.$MainESDFile.EditionID -eq 'Core') {$DVDLabel = ($tag+'_CCRA_'+$arch+'FRER_'+$ESDInfo.$MainESDFile.DefaultLanguage+'_DV9').ToUpper()}
		if ($ESDInfo.$MainESDFile.EditionID -eq 'CoreN') {$DVDLabel = ($tag+'_CCRNA_'+$arch+'FRER_'+$ESDInfo.$MainESDFile.DefaultLanguage+'_DV9').ToUpper()}
		if ($ESDInfo.$MainESDFile.EditionID -eq 'CoreSingleLanguage') {$DVDLabel = ($tag+'_CSLA_'+$arch+'FRER_'+$ESDInfo.$MainESDFile.DefaultLanguage+'_DV9').ToUpper()}
		if ($ESDInfo.$MainESDFile.EditionID -eq 'CoreCountrySpecific') {$DVDLabel = ($tag+'_CCHA_'+$arch+'FRER_'+$ESDInfo.$MainESDFile.DefaultLanguage+'_DV9').ToUpper()}
		if ($ESDInfo.$MainESDFile.EditionID -eq 'Professional') {$DVDLabel = ($tag+'_CPRA_'+$arch+'FRER_'+$ESDInfo.$MainESDFile.DefaultLanguage+'_DV9').ToUpper()}
		if ($ESDInfo.$MainESDFile.EditionID -eq 'ProfessionalN') {$DVDLabel = ($tag+'_CPRNA_'+$arch+'FRER_'+$ESDInfo.$MainESDFile.DefaultLanguage+'_DV9').ToUpper()}
		if ($ESDInfo.$MainESDFile.EditionID -eq 'ProfessionalWMC') {$DVDLabel = ($tag+'_CPWMCA_'+$arch+'FRER_'+$ESDInfo.$MainESDFile.DefaultLanguage+'_DV9').ToUpper()}
		if ($ESDInfo.$MainESDFile.EditionID -eq 'CoreConnected') {$DVDLabel = ($tag+'_CCONA_'+$arch+'FRER_'+$ESDInfo.$MainESDFile.DefaultLanguage+'_DV9').ToUpper()}
		if ($ESDInfo.$MainESDFile.EditionID -eq 'CoreConnectedN') {$DVDLabel = ($tag+'_CCONNA_'+$arch+'FRER_'+$ESDInfo.$MainESDFile.DefaultLanguage+'_DV9').ToUpper()}
		if ($ESDInfo.$MainESDFile.EditionID -eq 'CoreConnectedSingleLanguage') {$DVDLabel = ($tag+'_CCSLA_'+$arch+'FRER_'+$ESDInfo.$MainESDFile.DefaultLanguage+'_DV9').ToUpper()}
		if ($ESDInfo.$MainESDFile.EditionID -eq 'CoreConnectedCountrySpecific') {$DVDLabel = ($tag+'_CCCHA_'+$arch+'FRER_'+$ESDInfo.$MainESDFile.DefaultLanguage+'_DV9').ToUpper()}
		if ($ESDInfo.$MainESDFile.EditionID -eq 'ProfessionalStudent') {$DVDLabel = ($tag+'_CPRSA_'+$arch+'FRER_'+$ESDInfo.$MainESDFile.DefaultLanguage+'_DV9').ToUpper()}
		if ($ESDInfo.$MainESDFile.EditionID -eq 'ProfessionalStudentN') {$DVDLabel = ($tag+'_CPRSNA_'+$arch+'FRER_'+$ESDInfo.$MainESDFile.DefaultLanguage+'_DV9').ToUpper()}
	}
	
	if ([int] $ESDInfo.$MainESDFile.Build -gt '9600') {
		$DVDLabel = ('JM1_CCSA_'+$arch+'FRE_'+$ESDInfo.$MainESDFile.DefaultLanguage+'_DV5').ToUpper()
		if ($ESD.Count -eq 1) {
			if ($ESDInfo.$MainESDFile.EditionID -eq 'Core') {$DVDLabel = ('JM1_CCRA_'+$arch+'FRER_'+$ESDInfo.$MainESDFile.DefaultLanguage+'_DV5').ToUpper()}
			if ($ESDInfo.$MainESDFile.EditionID -eq 'CoreSingleLanguage') {$DVDLabel = ('JM1_CSLA_'+$arch+'FRER_'+$ESDInfo.$MainESDFile.DefaultLanguage+'_DV5').ToUpper()}
			if ($ESDInfo.$MainESDFile.EditionID -eq 'CoreCountrySpecific') {$DVDLabel = ('JM1_CCHA_'+$arch+'FRER_'+$ESDInfo.$MainESDFile.DefaultLanguage+'_DV5').ToUpper()}
			if ($ESDInfo.$MainESDFile.EditionID -eq 'Professional') {$DVDLabel = ('JM1_CPRA_'+$arch+'FRER_'+$ESDInfo.$MainESDFile.DefaultLanguage+'_DV5').ToUpper()}
			if ($ESDInfo.$MainESDFile.EditionID -eq 'Enterprise') {$DVDLabel = ('JM1_CENA_'+$arch+'FREV_'+$ESDInfo.$MainESDFile.DefaultLanguage+'_DV5').ToUpper()}
		}
	}
	
	if ([int] $ESDInfo.$MainESDFile.Build -ge '9896') {
		$DVDLabel = ('J_CCSA_'+$arch+'FRE_'+$ESDInfo.$MainESDFile.DefaultLanguage+'_DV5').ToUpper()
		if ($ESD.Count -eq 1) {
			if ($ESDInfo.$MainESDFile.EditionID -eq 'Core') {$DVDLabel = ('J_CCRA_'+$arch+'FRER_'+$ESDInfo.$MainESDFile.DefaultLanguage+'_DV5').ToUpper()}
			if ($ESDInfo.$MainESDFile.EditionID -eq 'CoreSingleLanguage') {$DVDLabel = ('J_CSLA_'+$arch+'FRER_'+$ESDInfo.$MainESDFile.DefaultLanguage+'_DV5').ToUpper()}
			if ($ESDInfo.$MainESDFile.EditionID -eq 'CoreCountrySpecific') {$DVDLabel = ('J_CCHA_'+$arch+'FRER_'+$ESDInfo.$MainESDFile.DefaultLanguage+'_DV5').ToUpper()}
			if ($ESDInfo.$MainESDFile.EditionID -eq 'Professional') {$DVDLabel = ('J_CPRA_'+$arch+'FRER_'+$ESDInfo.$MainESDFile.DefaultLanguage+'_DV5').ToUpper()}
			if ($ESDInfo.$MainESDFile.EditionID -eq 'Enterprise') {$DVDLabel = ('J_CENA_'+$arch+'FREV_'+$ESDInfo.$MainESDFile.DefaultLanguage+'_DV5').ToUpper()}
		}
	}
	
	foreach ($esdfile in $ESD) {
		& $wimlib extract "$($esdfile)" 1 sources\idwbinfo.txt | out-null
		& $wimlib extract "$($esdfile)" 1 setup.exe | out-null
	
		$ESDInfo[$esdfile]['CompileDate'] = (Get-item .\setup.exe).VersionInfo.FileVersion.split('()')[1].split('.')[1]
		$ESDInfo[$esdfile]['BuildBranch'] = (Get-item .\setup.exe).VersionInfo.FileVersion.split('()')[1].split('.')[0]
			
		$iniContent = Get-IniContent '.\idwbinfo.txt'
		$ESDInfo[$esdfile]['BuildType'] = $iniContent['BUILDINFO']['BuildType']	
		
		Remove-Item '.\setup.exe'
		Remove-Item '.\idwbinfo.txt'
	}
	
	$filename = ''
	
	if ($filenametype -eq 'Partner') {
		foreach ($esdfile in $ESD) {
			if ($Edition -eq $null) {
				$Licensing = 'RET'
				if ($ESDInfo.$esdfile.EditionID -eq 'Core') {$Edition = 'CORE'}
				if ($ESDInfo.$esdfile.EditionID -eq 'CoreN') {$Edition = 'COREN'}
				if ($ESDInfo.$esdfile.EditionID -eq 'CoreSingleLanguage') {$Edition = 'SINGLELANGUAGE'}
				if ($ESDInfo.$esdfile.EditionID -eq 'CoreCountrySpecific') {$Edition = 'CHINA'}
				if ($ESDInfo.$esdfile.EditionID -eq 'Professional') {$Edition = 'PRO'}
				if ($ESDInfo.$esdfile.EditionID -eq 'ProfessionalN') {$Edition = 'PRON'}
				if ($ESDInfo.$esdfile.EditionID -eq 'ProfessionalWMC') {$Edition = 'PROWMC'}
				if ($ESDInfo.$esdfile.EditionID -eq 'CoreConnected') {$Edition = 'CORECONNECTED'}
				if ($ESDInfo.$esdfile.EditionID -eq 'CoreConnectedN') {$Edition = 'CORECONNECTEDN'}
				if ($ESDInfo.$esdfile.EditionID -eq 'CoreConnectedSingleLanguage') {$Edition = 'CORECONNECTEDSINGLELANGUAGE'}
				if ($ESDInfo.$esdfile.EditionID -eq 'CoreConnectedCountrySpecific') {$Edition = 'CORECONNECTEDCHINA'}
				if ($ESDInfo.$esdfile.EditionID -eq 'ProfessionalStudent') {$Edition = 'PROSTUDENT'}
				if ($ESDInfo.$esdfile.EditionID -eq 'ProfessionalStudentN') {$Edition = 'PROSTUDENTN'}
				if ($ESDInfo.$esdfile.EditionID -eq 'Enterprise') {
					$Licensing = 'VOL'
					$Edition = 'ENTERPRISE'
				}
			} else {
				if ($ESDInfo.$esdfile.EditionID -eq 'Core') {
					if (-Not $Licensing -contains '*RET*') {$Licensing = $Licensing+'-RET'}
					$Edition = $Edition+'-CORE'
				}
				if ($ESDInfo.$esdfile.EditionID -eq 'CoreN') {
					if (-Not $Licensing -contains '*RET*') {$Licensing = $Licensing+'-RET'}
					$Edition = $Edition+'-COREN'
				}
				if ($ESDInfo.$esdfile.EditionID -eq 'CoreSingleLanguage') {
					if (-Not $Licensing -contains '*RET*') {$Licensing = $Licensing+'-RET'}
					$Edition = $Edition+'-SINGLELANGUAGE'
				}
				if ($ESDInfo.$esdfile.EditionID -eq 'CoreCountrySpecific') {
					if (-Not $Licensing -contains '*RET*') {$Licensing = $Licensing+'-RET'}
					$Edition = $Edition+'-CHINA'
				}
				if ($ESDInfo.$esdfile.EditionID -eq 'Professional') {
					if (-Not $Licensing -contains '*RET*') {$Licensing = $Licensing+'-RET'}
					$Edition = $Edition+'-PRO'
				}
				if ($ESDInfo.$esdfile.EditionID -eq 'ProfessionalN') {
					if (-Not $Licensing -contains '*RET*') {$Licensing = $Licensing+'-RET'}
					$Edition = $Edition+'-PRON'
				}
				if ($ESDInfo.$esdfile.EditionID -eq 'ProfessionalWMC') {
					if (-Not $Licensing -contains '*RET*') {$Licensing = $Licensing+'-RET'}
					$Edition = $Edition+'-PROWMC'
				}
				if ($ESDInfo.$esdfile.EditionID -eq 'CoreConnected') {
					if (-Not $Licensing -contains '*RET*') {$Licensing = $Licensing+'-RET'}
					$Edition = $Edition+'-CORECONNECTED'
				}
				if ($ESDInfo.$esdfile.EditionID -eq 'CoreConnectedN') {
					if (-Not $Licensing -contains '*RET*') {$Licensing = $Licensing+'-RET'}
					$Edition = $Edition+'-CORECONNECTEDN'
				}
				if ($ESDInfo.$esdfile.EditionID -eq 'CoreConnectedSingleLanguage') {
					if (-Not $Licensing -contains '*RET*') {$Licensing = $Licensing+'-RET'}
					$Edition = $Edition+'-CORECONNECTEDSINGLELANGUAGE'
				}
				if ($ESDInfo.$esdfile.EditionID -eq 'CoreConnectedCountrySpecific') {
					if (-Not $Licensing -contains '*RET*') {$Licensing = $Licensing+'-RET'}
					$Edition = $Edition+'-CORECONNECTEDCHINA'
				}
				if ($ESDInfo.$esdfile.EditionID -eq 'ProfessionalStudent') {
					if (-Not $Licensing -contains '*RET*') {$Licensing = $Licensing+'-RET'}
					$Edition = $Edition+'-PROSTUDENT'
				}
				if ($ESDInfo.$esdfile.EditionID -eq 'ProfessionalStudentN') {
					if (-Not $Licensing -contains '*RET*') {$Licensing = $Licensing+'-RET'}
					$Edition = $Edition+'-PROSTUDENTN'
				}
				if ($ESDInfo.$esdfile.EditionID -eq 'Enterprise') {
					if (-Not $Licensing -contains '*VOL*') {$Licensing = $Licensing+'-VOL'}
					$Edition = $Edition+'-ENTERPRISE'
				}
				if ($ESDInfo.$esdfile.EditionID -eq 'Education') {
					if (-Not $Licensing -contains '*VOL*') {$Licensing = $Licensing+'-VOL'}
					$Edition = $Edition+'-EDUCATION'
				}
				if ($ESDInfo.$esdfile.EditionID -eq 'EducationN') {
					if (-Not $Licensing -contains '*VOL*') {$Licensing = $Licensing+'-VOL'}
					$Edition = $Edition+'-EDUCATIONN'
				}
			}
		}
		
		if ($Edition -contains 'PRO-CORE') {
			$Licensing = $Licensing -replace 'RET', 'OEMRET'
		}
		
		$FILENAME = ($ESDInfo.$MainESDFile.Build+'.'+$ESDInfo.$MainESDFile.ServicePackBuild+'.'+$ESDInfo.$MainESDFile.CompileDate+'.'+$ESDInfo.$MainESDFile.BuildBranch+'_CLIENT'+$Edition+'_'+$Licensing+'_'+$arch+$ESDInfo.$MainESDFile.buildtype+'_'+$ESDInfo.$MainESDFile.DefaultLanguage+'.iso').ToUpper()
	}
	
	if ($filenametype -eq 'Consumer') {
		if ($ESDInfo.$MainESDFile.DefaultLanguage -eq 'en-gb') {
			$lang = 'en-gb'
		} elseif ($ESDInfo.$MainESDFile.DefaultLanguage -eq 'es-mx') {
			$lang = 'es-mx'
		} elseif ($ESDInfo.$MainESDFile.DefaultLanguage -eq 'fr-ca') {
			$lang = 'fr-ca'
		} elseif ($ESDInfo.$MainESDFile.DefaultLanguage -eq 'pt-pt') {
			$lang = 'pp'
		} elseif ($ESDInfo.$MainESDFile.DefaultLanguage -eq 'sr-latn-rs') {
			$lang = 'sr-latn'
		} elseif ($ESDInfo.$MainESDFile.DefaultLanguage -eq 'zh-cn') {
			$lang = 'cn'
		} elseif ($ESDInfo.$MainESDFile.DefaultLanguage -eq 'zh-tw') {
			$lang = 'tw'
		} elseif ($ESDInfo.$MainESDFile.DefaultLanguage -eq 'zh-hk') {
			$lang = 'hk'
		} else {
			$lang = $ESDInfo.$MainESDFile.DefaultLanguage.split('-')[0]
		}
		
		if ($arch -eq 'x64') {
			$arch2 = 'x64'
		} else {
			$arch2 = 'x32'
		}
		
		$filename = $lang+'_windows_8.1_'+$tag+'_'+$arch+'_dvd.iso'
		if ($ESD.Count -eq 1) {
			if ($ESDInfo.$MainESDFile.EditionID -eq 'Core') {$filename = $lang+'_windows_8.1_'+$tag+'_'+$arch+'_dvd.iso'}
			if ($ESDInfo.$MainESDFile.EditionID -eq 'CoreN') {$filename = $lang+'_windows_8.1_n_'+$tag+'_'+$arch+'_dvd.iso'}
			if ($ESDInfo.$MainESDFile.EditionID -eq 'CoreSingleLanguage') {$filename = $lang+'_windows_8.1_singlelanguage_'+$tag+'_'+$arch+'_dvd.iso'}
			if ($ESDInfo.$MainESDFile.EditionID -eq 'CoreCountrySpecific') {$filename = $lang+'_windows_8.1_china_'+$tag+'_'+$arch+'_dvd.iso'}
			if ($ESDInfo.$MainESDFile.EditionID -eq 'Professional') {$filename = $lang+'_windows_8.1_pro_'+$tag+'_'+$arch+'_dvd.iso'}
			if ($ESDInfo.$MainESDFile.EditionID -eq 'ProfessionalN') {$filename = $lang+'_windows_8.1_pro_n_'+$tag+'_'+$arch+'_dvd.iso'}
			if ($ESDInfo.$MainESDFile.EditionID -eq 'ProfessionalWMC') {$filename = $lang+'_windows_8.1_pro_wmc_'+$tag+'_'+$arch+'_dvd.iso'}
			if ($ESDInfo.$MainESDFile.EditionID -eq 'CoreConnected') {$filename = $lang+'_windows_8.1_with_bing_'+$tag+'_'+$arch+'_dvd.iso'}
			if ($ESDInfo.$MainESDFile.EditionID -eq 'CoreConnectedN') {$filename = $lang+'_windows_8.1_n_with_bing_'+$tag+'_'+$arch+'_dvd.iso'}
			if ($ESDInfo.$MainESDFile.EditionID -eq 'CoreConnectedSingleLanguage') {$filename = $lang+'_windows_8.1_singlelanguage_with_bing_'+$tag+'_'+$arch+'_dvd.iso'}
			if ($ESDInfo.$MainESDFile.EditionID -eq 'CoreConnectedCountrySpecific') {$filename = $lang+'_windows_8.1_china_with_bing_'+$tag+'_'+$arch+'_dvd.iso'}
			if ($ESDInfo.$MainESDFile.EditionID -eq 'ProfessionalStudent') {$filename = $lang+'_windows_8.1_pro_student_'+$tag+'_'+$arch+'_dvd.iso'}
			if ($ESDInfo.$MainESDFile.EditionID -eq 'ProfessionalStudentN') {$filename = $lang+'_windows_8.1_pro_student_n_'+$tag+'_'+$arch+'_dvd.iso'}
		}
		
		if ([int] $ESDInfo.$MainESDFile.Build -gt '9600') {
			$filename = 'WindowsTechnicalPreview-'+$arch+'-'+($ESDInfo.$esdfile.DefaultLanguage.ToUpper())+'.iso'
			if ($ESD.Count -eq 1) {
				if ($ESDInfo.$MainESDFile.EditionID -eq 'Core') {$filename = 'WindowsTechnicalPreview-Core-'+$arch+'-'+($ESDInfo.$esdfile.DefaultLanguage.ToUpper())+'.iso'}
				if ($ESDInfo.$MainESDFile.EditionID -eq 'CoreSingleLanguage') {$filename = 'WindowsTechnicalPreview-SingleLanguage-'+$arch+'-'+($ESDInfo.$esdfile.DefaultLanguage.ToUpper())+'.iso'}
				if ($ESDInfo.$MainESDFile.EditionID -eq 'CoreCountrySpecific') {$filename = 'WindowsTechnicalPreview-China-'+$arch+'-'+($ESDInfo.$esdfile.DefaultLanguage.ToUpper())+'.iso'}
				if ($ESDInfo.$MainESDFile.EditionID -eq 'Professional') {$filename = 'WindowsTechnicalPreview-Pro-'+$arch+'-'+($ESDInfo.$esdfile.DefaultLanguage.ToUpper())+'.iso'}
				if ($ESDInfo.$MainESDFile.EditionID -eq 'Enterprise') {$filename = 'WindowsTechnicalPreview-Enterprise-'+$arch+'-'+($ESDInfo.$esdfile.DefaultLanguage.ToUpper())+'.iso'}
			}
		}
		
		if ([int] $ESDInfo.$MainESDFile.Build -gt '9841') {
			$filename = 'WindowsTechnicalPreview-'+$ESDInfo.$MainESDFile.Build+'-'+$arch2+'-'+($ESDInfo.$esdfile.DefaultLanguage.ToUpper())+'.iso'
			if ($ESD.Count -eq 1) {
				if ($ESDInfo.$MainESDFile.EditionID -eq 'Core') {$filename = 'WindowsTechnicalPreview-Core-'+$ESDInfo.$MainESDFile.Build+'-'+$arch2+'-'+($ESDInfo.$esdfile.DefaultLanguage.ToUpper())+'.iso'}
				if ($ESDInfo.$MainESDFile.EditionID -eq 'CoreSingleLanguage') {$filename = 'WindowsTechnicalPreview-SingleLanguage-'+$ESDInfo.$MainESDFile.Build+'-'+$arch2+'-'+($ESDInfo.$esdfile.DefaultLanguage.ToUpper())+'.iso'}
				if ($ESDInfo.$MainESDFile.EditionID -eq 'CoreCountrySpecific') {$filename = 'WindowsTechnicalPreview-China-'+$ESDInfo.$MainESDFile.Build+'-'+$arch2+'-'+($ESDInfo.$esdfile.DefaultLanguage.ToUpper())+'.iso'}
				if ($ESDInfo.$MainESDFile.EditionID -eq 'Professional') {$filename = 'WindowsTechnicalPreview-Pro-'+$ESDInfo.$MainESDFile.Build+'-'+$arch2+'-'+($ESDInfo.$esdfile.DefaultLanguage.ToUpper())+'.iso'}
				if ($ESDInfo.$MainESDFile.EditionID -eq 'Enterprise') {$filename = 'WindowsTechnicalPreview-Enterprise-'+$ESDInfo.$MainESDFile.Build+'-'+$arch2+'-'+($ESDInfo.$esdfile.DefaultLanguage.ToUpper())+'.iso'}
			}
		}
		
		if ([int] $ESDInfo.$MainESDFile.Build -ge '9896') {
			$filename = 'Windows10_TechnicalPreview_'+$arch2+'_'+($ESDInfo.$esdfile.DefaultLanguage.ToUpper())+'_'+$ESDInfo.$MainESDFile.Build+'.iso'
			if ($ESD.Count -eq 1) {
				if ($ESDInfo.$MainESDFile.EditionID -eq 'Core') {$filename = 'Windows10_Core_TechnicalPreview_'+$arch2+'_'+($ESDInfo.$esdfile.DefaultLanguage.ToUpper())+'_'+$ESDInfo.$MainESDFile.Build+'.iso'}
				if ($ESDInfo.$MainESDFile.EditionID -eq 'CoreSingleLanguage') {$filename = 'Windows10_SingleLanguage_TechnicalPreview_'+$arch2+'_'+($ESDInfo.$esdfile.DefaultLanguage.ToUpper())+'_'+$ESDInfo.$MainESDFile.Build+'.iso'}
				if ($ESDInfo.$MainESDFile.EditionID -eq 'CoreCountrySpecific') {$filename = 'Windows10_China_TechnicalPreview_'+$arch2+'_'+($ESDInfo.$esdfile.DefaultLanguage.ToUpper())+'_'+$ESDInfo.$MainESDFile.Build+'.iso'}
				if ($ESDInfo.$MainESDFile.EditionID -eq 'Professional') {$filename = 'Windows10_Pro_TechnicalPreview_'+$arch2+'_'+($ESDInfo.$esdfile.DefaultLanguage.ToUpper())+'_'+$ESDInfo.$MainESDFile.Build+'.iso'}
				if ($ESDInfo.$MainESDFile.EditionID -eq 'Enterprise') {$filename = 'Windows10_Enterprise_TechnicalPreview_'+$arch2+'_'+($ESDInfo.$esdfile.DefaultLanguage.ToUpper())+'_'+$ESDInfo.$MainESDFile.Build+'.iso'}
			}
		}
		
		if ([int] $ESDInfo.$MainESDFile.Build -gt '10066') {
			$filename = 'Windows10_InsiderPreview_'+$arch2+'_'+($ESDInfo.$esdfile.DefaultLanguage.ToUpper())+'_'+$ESDInfo.$MainESDFile.Build+'.iso'
			if ($ESD.Count -eq 1) {
				if ($ESDInfo.$MainESDFile.EditionID -eq 'Core') {$filename = 'Windows10_Core_InsiderPreview_'+$arch2+'_'+($ESDInfo.$esdfile.DefaultLanguage.ToUpper())+'_'+$ESDInfo.$MainESDFile.Build+'.iso'}
				if ($ESDInfo.$MainESDFile.EditionID -eq 'CoreSingleLanguage') {$filename = 'Windows10_SingleLanguage_InsiderPreview_'+$arch2+'_'+($ESDInfo.$esdfile.DefaultLanguage.ToUpper())+'_'+$ESDInfo.$MainESDFile.Build+'.iso'}
				if ($ESDInfo.$MainESDFile.EditionID -eq 'CoreCountrySpecific') {$filename = 'Windows10_China_InsiderPreview_'+$arch2+'_'+($ESDInfo.$esdfile.DefaultLanguage.ToUpper())+'_'+$ESDInfo.$MainESDFile.Build+'.iso'}
				if ($ESDInfo.$MainESDFile.EditionID -eq 'Professional') {$filename = 'Windows10_Pro_InsiderPreview_'+$arch2+'_'+($ESDInfo.$esdfile.DefaultLanguage.ToUpper())+'_'+$ESDInfo.$MainESDFile.Build+'.iso'}
				if ($ESDInfo.$MainESDFile.EditionID -eq 'Enterprise') {$filename = 'Windows10_Enterprise_InsiderPreview_'+$arch2+'_'+($ESDInfo.$esdfile.DefaultLanguage.ToUpper())+'_'+$ESDInfo.$MainESDFile.Build+'.iso'}
			}
		}
		
		if ([int] $ESDInfo.$MainESDFile.Build -ge '10100') {
			if ([int] $ESDInfo.$MainESDFile.Build -lt '10104') {
				$filename = 'Windows10_TechnicalPreview_'+$arch2+'_'+($ESDInfo.$esdfile.DefaultLanguage.ToUpper())+'_'+$ESDInfo.$MainESDFile.Build+'.iso'
				if ($ESD.Count -eq 1) {
					if ($ESDInfo.$MainESDFile.EditionID -eq 'Core') {$filename = 'Windows10_Core_TechnicalPreview_'+$arch2+'_'+($ESDInfo.$esdfile.DefaultLanguage.ToUpper())+'_'+$ESDInfo.$MainESDFile.Build+'.iso'}
					if ($ESDInfo.$MainESDFile.EditionID -eq 'CoreSingleLanguage') {$filename = 'Windows10_SingleLanguage_TechnicalPreview_'+$arch2+'_'+($ESDInfo.$esdfile.DefaultLanguage.ToUpper())+'_'+$ESDInfo.$MainESDFile.Build+'.iso'}
					if ($ESDInfo.$MainESDFile.EditionID -eq 'CoreCountrySpecific') {$filename = 'Windows10_China_TechnicalPreview_'+$arch2+'_'+($ESDInfo.$esdfile.DefaultLanguage.ToUpper())+'_'+$ESDInfo.$MainESDFile.Build+'.iso'}
					if ($ESDInfo.$MainESDFile.EditionID -eq 'Professional') {$filename = 'Windows10_Pro_TechnicalPreview_'+$arch2+'_'+($ESDInfo.$esdfile.DefaultLanguage.ToUpper())+'_'+$ESDInfo.$MainESDFile.Build+'.iso'}
					if ($ESDInfo.$MainESDFile.EditionID -eq 'Enterprise') {$filename = 'Windows10_Enterprise_TechnicalPreview_'+$arch2+'_'+($ESDInfo.$esdfile.DefaultLanguage.ToUpper())+'_'+$ESDInfo.$MainESDFile.Build+'.iso'}
				}
			}
		}
	}
	
	if ($filenametype -eq 'Windows7') {
		if ($ESDInfo.$MainESDFile.DefaultLanguage -eq 'en-gb') {
			$lang = 'en-gb'
		} elseif ($ESDInfo.$MainESDFile.DefaultLanguage -eq 'es-mx') {
			$lang = 'es-mx'
		} elseif ($ESDInfo.$MainESDFile.DefaultLanguage -eq 'fr-ca') {
			$lang = 'fr-ca'
		} elseif ($ESDInfo.$MainESDFile.DefaultLanguage -eq 'pt-pt') {
			$lang = 'pp'
		} elseif ($ESDInfo.$MainESDFile.DefaultLanguage -eq 'sr-latn-rs') {
			$lang = 'sr-latn'
		} elseif ($ESDInfo.$MainESDFile.DefaultLanguage -eq 'zh-cn') {
			$lang = 'cn'
		} elseif ($ESDInfo.$MainESDFile.DefaultLanguage -eq 'zh-tw') {
			$lang = 'tw'
		} elseif ($ESDInfo.$MainESDFile.DefaultLanguage -eq 'zh-hk') {
			$lang = 'hk'
		} else {
			$lang = $ESDInfo.$MainESDFile.DefaultLanguage.split('-')[0]
		}
		
		foreach ($esdfile in $ESD) {
			if ($Edition -eq $null) {
				if ($ESDInfo.$esdfile.EditionID -eq 'Core') {$Edition = 'CORE'}
				if ($ESDInfo.$esdfile.EditionID -eq 'CoreN') {$Edition = 'COREN'}
				if ($ESDInfo.$esdfile.EditionID -eq 'CoreSingleLanguage') {$Edition = 'SINGLELANGUAGE'}
				if ($ESDInfo.$esdfile.EditionID -eq 'CoreCountrySpecific') {$Edition = 'CHINA'}
				if ($ESDInfo.$esdfile.EditionID -eq 'Professional') {$Edition = 'PRO'}
				if ($ESDInfo.$esdfile.EditionID -eq 'ProfessionalN') {$Edition = 'PRON'}
				if ($ESDInfo.$esdfile.EditionID -eq 'ProfessionalWMC') {$Edition = 'PROWMC'}
				if ($ESDInfo.$esdfile.EditionID -eq 'CoreConnected') {$Edition = 'CORECONNECTED'}
				if ($ESDInfo.$esdfile.EditionID -eq 'CoreConnectedN') {$Edition = 'CORECONNECTEDN'}
				if ($ESDInfo.$esdfile.EditionID -eq 'CoreConnectedSingleLanguage') {$Edition = 'CORECONNECTEDSINGLELANGUAGE'}
				if ($ESDInfo.$esdfile.EditionID -eq 'CoreConnectedCountrySpecific') {$Edition = 'CORECONNECTEDCHINA'}
				if ($ESDInfo.$esdfile.EditionID -eq 'ProfessionalStudent') {$Edition = 'PROSTUDENT'}
				if ($ESDInfo.$esdfile.EditionID -eq 'ProfessionalStudentN') {$Edition = 'PROSTUDENTN'}
				if ($ESDInfo.$esdfile.EditionID -eq 'Enterprise') {$Edition = 'ENTERPRISE'}
			} else {
				if ($ESDInfo.$esdfile.EditionID -eq 'Core') {$Edition = $Edition+'-CORE'}
				if ($ESDInfo.$esdfile.EditionID -eq 'CoreN') {$Edition = $Edition+'-COREN'}
				if ($ESDInfo.$esdfile.EditionID -eq 'CoreSingleLanguage') {$Edition = $Edition+'-SINGLELANGUAGE'}
				if ($ESDInfo.$esdfile.EditionID -eq 'CoreCountrySpecific') {$Edition = $Edition+'-CHINA'}
				if ($ESDInfo.$esdfile.EditionID -eq 'Professional') {$Edition = $Edition+'-PRO'}
				if ($ESDInfo.$esdfile.EditionID -eq 'ProfessionalN') {$Edition = $Edition+'-PRON'}
				if ($ESDInfo.$esdfile.EditionID -eq 'ProfessionalWMC') {$Edition = $Edition+'-PROWMC'}
				if ($ESDInfo.$esdfile.EditionID -eq 'CoreConnected') {$Edition = $Edition+'-CORECONNECTED'}
				if ($ESDInfo.$esdfile.EditionID -eq 'CoreConnectedN') {$Edition = $Edition+'-CORECONNECTEDN'}
				if ($ESDInfo.$esdfile.EditionID -eq 'CoreConnectedSingleLanguage') {$Edition = $Edition+'-CORECONNECTEDSINGLELANGUAGE'}
				if ($ESDInfo.$esdfile.EditionID -eq 'CoreConnectedCountrySpecific') {$Edition = $Edition+'-CORECONNECTEDCHINA'}
				if ($ESDInfo.$esdfile.EditionID -eq 'ProfessionalStudent') {$Edition = $Edition+'-PROSTUDENT'}
				if ($ESDInfo.$esdfile.EditionID -eq 'ProfessionalStudentN') {$Edition = $Edition+'-PROSTUDENTN'}
				if ($ESDInfo.$esdfile.EditionID -eq 'Enterprise') {$Edition = $Edition+'-ENTERPRISE'}
			}
		}
		
		$EditionID = $null
		
		foreach ($esdfile in $ESD) {
			if ($EditionID -eq $null) {
				$EditionID = $ESDInfo.$esdfile.EditionID
			} else {
				$EditionID = $EditionID+'-'+$ESDInfo.$esdfile.EditionID
			}
		}
		
		$filename = ($lang.toLower())+'_'+$ESDInfo.$MainESDFile.Build+'.'+$ESDInfo.$MainESDFile.ServicePackBuild+'.'+$ESDInfo.$MainESDFile.CompileDate+'_'+$arch+$ESDInfo.$MainESDFile.BuildType+'_'+($Edition.toLower())+'_'+($ESDInfo.$MainESDFile.DefaultLanguage.toLower())+'_'+$EditionID+'-'+$DVDLabel+'.iso'
		if ($EditionID.toLower() -eq 'enterprise') {$filename = ($lang.toLower())+'_'+$ESDInfo.$MainESDFile.Build+'.'+$ESDInfo.$MainESDFile.ServicePackBuild+'.'+$ESDInfo.$MainESDFile.CompileDate+'_'+$arch+$ESDInfo.$MainESDFile.BuildType+'_'+($Edition.toLower())+'_'+($ESDInfo.$MainESDFile.DefaultLanguage.toLower())+'_VL_'+$EditionID+'-'+$DVDLabel+'.iso'}
		if ($EditionID.toLower() -eq 'enterprisen') {$filename = ($lang.toLower())+'_'+$ESDInfo.$MainESDFile.Build+'.'+$ESDInfo.$MainESDFile.ServicePackBuild+'.'+$ESDInfo.$MainESDFile.CompileDate+'_'+$arch+$ESDInfo.$MainESDFile.BuildType+'_'+($Edition.toLower())+'_'+($ESDInfo.$MainESDFile.DefaultLanguage.toLower())+'_VL_'+$EditionID+'-'+$DVDLabel+'.iso'}
	}
	
	foreach ($esdfile in $ESD) {
		Write-Host ''
		Output ([out.level] 'Info') ('=' * 50)
		Output ([out.level] 'Info') ('File : '+$esdfile)
		Output ([out.level] 'Info') ('Build : '+$($ESDInfo.$esdfile.Build)+'.'+$($ESDInfo.$esdfile.ServicePackBuild)+'.'+$($ESDInfo.$esdfile.CompileDate))
		Output ([out.level] 'Info') ('Build Branch : '+$($ESDInfo.$esdfile.BuildBranch))
		Output ([out.level] 'Info') ('Build Type : '+$($ESDInfo.$esdfile.BuildType))
		Output ([out.level] 'Info') ('Architecture : '+$arch)
		Output ([out.level] 'Info') ('Edition : '+$($ESDInfo.$esdfile.EditionID))
		Output ([out.level] 'Info') ('Language : '+$($ESDInfo.$esdfile.DefaultLanguage))
		Output ([out.level] 'Info') ('=' * 50)
		Write-Host ''
	}
	
	return $DVDLabel, $FILENAME, $ESDInfo
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
	
	[parameter(Mandatory=$true,HelpMessage="The type of filename used for the iso (Partner, Consumer or Windows7)")]
	[iso.filenametype] $filenametype,
	
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
			$ProcessESD += $esdfile+".bak"
			$DeleteESD += $esdfile+".bak"
			$TempESD = $esdfile + ".bak"
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
	$ISOInfos = (Gather-Info $ProcessESD $filenametype)
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
		$name = $null
		$sw = [System.Diagnostics.Stopwatch]::StartNew();
		if ($extensiontype -eq 'ESD') {
			& $wimlib export "$($esdfile)" 4 .\Media\sources\install.esd --compress=LZMS --solid | ForEach-Object -Process {
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
			$globalprogress = $globalprogress + (100 / $ProcessESD.Count)
			
			if ($ISOInfos[2].$esdfile.EditionID -eq 'ProfessionalWMC') {
				Write-Host ''
				cmd /c ($wimlib + ' update ".\Media\sources\install.esd" $indexcounter <wim-update.txt')
			}
		} else {
			$name = $null
			& $wimlib export "$($esdfile)" 4 .\Media\sources\install.wim --compress=maximum | ForEach-Object -Process {
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
			$globalprogress = $globalprogress + (100 / $ProcessESD.Count)

			if ($ISOInfos[2].$esdfile.EditionID -eq 'ProfessionalWMC') {
				cmd /c ($wimlib + ' update ".\Media\sources\install.wim" $indexcounter <wim-update.txt')
				Write-Host ''
			}
		}
		$indexcounter++
		$sw.Stop();
		$sw.Reset();
	}
	Write-Progress -Activity ('Creating the Windows image...') -Complete
	
	Output ([out.level] 'Info') 'Gathering Timestamp information from the Setup Media...'
	$timestamp = (Get-ChildItem .\Media\sources\setup.exe | % {[System.TimeZoneInfo]::ConvertTimeToUtc($_.creationtime).ToString("MM/dd/yyyy,HH:mm:ss")})
	Output ([out.level] 'Info') 'Generating ISO...'
	
	$BootData='2#p0,e,bMedia\boot\etfsboot.com#pEF,e,bMedia\efi\Microsoft\boot\efisys.bin'
	& "cmd" "/c" ".\bin\cdimage.exe" "-bootdata:$BootData" "-o" "-h" "-m" "-u2" "-udfver102" "-t$timestamp" "-l$($ISOInfos[0])" "$($Destination)\Media" """$($ISOInfos[1])"""<#  | ForEach-Object -Process {
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
		0 {$filenametype = ([iso.filenametype] "Consumer")}
		1 {$filenametype = ([iso.filenametype] "Partner")}
		2 {$filenametype = ([iso.filenametype] "Windows7")}
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
		Convert-ESD -CryptoKey $key -filenametype $filenametype -extensiontype $extensiontype
	} else {
		Convert-ESD -filenametype $filenametype -extensiontype $extensiontype
	}
	
	
}

Wizard-Decrypt