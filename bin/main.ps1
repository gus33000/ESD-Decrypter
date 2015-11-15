try{
	Add-Type -AssemblyName PresentationCore,PresentationFramework,WindowsBase,system.windows.forms
} catch {
	Throw "Failed to load Windows Presentation Framework assemblies."
}

function Get-ScriptDirectory {
    Split-Path -parent $PSCommandPath
}

function New-Enum ([string] $name) {
    $appdomain = [System.Threading.Thread]::GetDomain()
    $assembly = new-object System.Reflection.AssemblyName
    $assembly.Name = "EmittedEnum"
	$assemblyBuilder = $appdomain.DefineDynamicAssembly($assembly, 
	[System.Reflection.Emit.AssemblyBuilderAccess]::Save -bor [System.Reflection.Emit.AssemblyBuilderAccess]::Run);
    $moduleBuilder = $assemblyBuilder.DefineDynamicModule("DynamicModule", "DynamicModule.mod");
    $enumBuilder = $moduleBuilder.DefineEnum($name, [System.Reflection.TypeAttributes]::Public, [System.Int32]);
    for($i = 0; $i -lt $args.Length; $i++)
    {
        $null = $enumBuilder.DefineLiteral($args[$i], $i);
    }
    $enumBuilder.CreateType() > $null;
}

# Is this a Wow64 powershell host
function Test-Wow64() {
	return (Test-Win32) -and (test-path env:\PROCESSOR_ARCHITEW6432)
}

# Is this a 64 bit process
function Test-Win64() {
	return [IntPtr]::size -eq 8
}

# Is this a 32 bit process
function Test-Win32() {
	return [IntPtr]::size -eq 4
}

New-Enum out.level Info Warning Error

function Output ([out.level] $level, [string] $message) {
	$output = '['+$level+'] '+$message
	Write-Host $output
}

New-Enum iso.filenametype Partner Consumer Windows7
New-Enum wim.extensiontype WIM ESD

if (Test-Wow64) {
	$wimlib = '.\bin\wimlib-imagex.exe'
} elseif (Test-Win64) {
	$wimlib = '.\bin\bin64\wimlib-imagex.exe'
} elseif (Test-Win32) {
	$wimlib = '.\bin\wimlib-imagex.exe'
} else {
	return
}

function doConvertESD (
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
) {
	Begin { 
		Function Update-Window { 
			Param ( 
				$Control, 
				$Property, 
				$Value, 
				[switch]$AppendContent 
			) 
		 
		   # This is kind of a hack, there may be a better way to do this 
		   If ($Property -eq "Close") { 
			  $syncHash.Window.Dispatcher.invoke([action]{$syncHash.Window.Close()},"Normal") 
			  Return 
		   } 
		   
		   # This updates the control based on the parameters passed to the function 
		   $syncHash.$Control.Dispatcher.Invoke([action]{ 
			  # This bit is only really meaningful for the TextBox control, which might be useful for logging progress steps 
			   If ($PSBoundParameters['AppendContent']) { 
				   $syncHash.$Control.AppendText($Value) 
			   } Else { 
				   $syncHash.$Control.$Property = $Value 
			   } 
		   }, "Normal") 
		} 
		
		function Copy-File {
			param( [string]$from, [string]$to)
			$ffile = [io.file]::OpenRead($from)
			$tofile = [io.file]::OpenWrite($to)
			try {
				$sw = [System.Diagnostics.Stopwatch]::StartNew();
				[byte[]]$buff = new-object byte[] (4096*1024)
				[long]$total = [long]$count = 0
				do {
					$count = $ffile.Read($buff, 0, $buff.Length)
					$tofile.Write($buff, 0, $count)
					$total += $count
					[int]$pctcomp = ([int]($total/$ffile.Length* 100));
					[int]$secselapsed = [int]($sw.elapsedmilliseconds.ToString())/1000;
					if ( $secselapsed -ne 0 ) {
						[single]$xferrate = (($total/$secselapsed)/1mb);
					} else {
						[single]$xferrate = 0.0
					}
					if ($total % 1mb -eq 0) {
						if($pctcomp -gt 0)`
							{[int]$secsleft = ((($secselapsed/$pctcomp)* 100)-$secselapsed);
							} else {
							[int]$secsleft = 0};
							if ($pastpct -ne $pctcomp) {
								Update-Window ConvertProgress Value $pctcomp
							}
							$pastpct = $pctcomp
					}
				} while ($count -gt 0)
					$sw.Stop();
					$sw.Reset();
				}
			finally {
				Update-Window ConvertProgress Value 100
				$ffile.Close();
				$tofile.Close();
				
			}
		}

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
			$DVD = 'DV9'
			
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
			
			if ([int] $WIMInfo[4].Build -gt '9600') {
				$tag = 'JM1'
				$DVD = 'DV5'
			}
			if ([int] $WIMInfo[4].Build -ge '9896') {
				$tag = 'J'
				$DVD = 'DV5'
			}
			
			$DVDLabel = ($tag+'_CCSA_'+$arch+'FRE_'+$WIMInfo[4].DefaultLanguage+'_'+$DVD).ToUpper()
			if ($WIMInfo.header.ImageCount -eq 4) {
				if ($WIMInfo[4].EditionID -eq 'Core') {$DVDLabel = ($tag+'_CCRA_'+$arch+'FRE_'+$WIMInfo[4].DefaultLanguage+'_'+$DVD).ToUpper()}
				if ($WIMInfo[4].EditionID -eq 'CoreConnected') {$DVDLabel = ($tag+'_CCONA_'+$arch+'FRE_'+$WIMInfo[4].DefaultLanguage+'_'+$DVD).ToUpper()}
				if ($WIMInfo[4].EditionID -eq 'CoreConnectedCountrySpecific') {$DVDLabel = ($tag+'_CCCHA_'+$arch+'FRE_'+$WIMInfo[4].DefaultLanguage+'_'+$DVD).ToUpper()}
				if ($WIMInfo[4].EditionID -eq 'CoreConnectedN') {$DVDLabel = ($tag+'_CCONNA_'+$arch+'FRE_'+$WIMInfo[4].DefaultLanguage+'_'+$DVD).ToUpper()}
				if ($WIMInfo[4].EditionID -eq 'CoreConnectedSingleLanguage') {$DVDLabel = ($tag+'_CCSLA_'+$arch+'FRE_'+$WIMInfo[4].DefaultLanguage+'_'+$DVD).ToUpper()}
				if ($WIMInfo[4].EditionID -eq 'CoreCountrySpecific') {$DVDLabel = ($tag+'_CCHA_'+$arch+'FRE_'+$WIMInfo[4].DefaultLanguage+'_'+$DVD).ToUpper()}
				if ($WIMInfo[4].EditionID -eq 'CoreN') {$DVDLabel = ($tag+'_CCRNA_'+$arch+'FRE_'+$WIMInfo[4].DefaultLanguage+'_'+$DVD).ToUpper()}
				if ($WIMInfo[4].EditionID -eq 'CoreSingleLanguage') {$DVDLabel = ($tag+'_CSLA_'+$arch+'FRE_'+$WIMInfo[4].DefaultLanguage+'_'+$DVD).ToUpper()}
				if ($WIMInfo[4].EditionID -eq 'Professional') {$DVDLabel = ($tag+'_CPRA_'+$arch+'FRE_'+$WIMInfo[4].DefaultLanguage+'_'+$DVD).ToUpper()}
				if ($WIMInfo[4].EditionID -eq 'ProfessionalN') {$DVDLabel = ($tag+'_CPRNA_'+$arch+'FRE_'+$WIMInfo[4].DefaultLanguage+'_'+$DVD).ToUpper()}
				if ($WIMInfo[4].EditionID -eq 'ProfessionalStudent') {$DVDLabel = ($tag+'_CPRSA_'+$arch+'FRE_'+$WIMInfo[4].DefaultLanguage+'_'+$DVD).ToUpper()}
				if ($WIMInfo[4].EditionID -eq 'ProfessionalStudentN') {$DVDLabel = ($tag+'_CPRSNA_'+$arch+'FRE_'+$WIMInfo[4].DefaultLanguage+'_'+$DVD).ToUpper()}
				if ($WIMInfo[4].EditionID -eq 'ProfessionalWMC') {$DVDLabel = ($tag+'_CPWMCA_'+$arch+'FRE_'+$WIMInfo[4].DefaultLanguage+'_'+$DVD).ToUpper()}
				if ($WIMInfo[4].EditionID -eq 'Education') {$DVDLabel = ($tag+'_CEDA_'+$arch+'FRE_'+$WIMInfo[4].DefaultLanguage+'_'+$DVD).ToUpper()}
				if ($WIMInfo[4].EditionID -eq 'EducationN') {$DVDLabel = ($tag+'_CEDNA_'+$arch+'FRE_'+$WIMInfo[4].DefaultLanguage+'_'+$DVD).ToUpper()}
				if ($WIMInfo[4].EditionID -eq 'Enterprise') {$DVDLabel = ($tag+'_CENA_'+$arch+'FREV_'+$WIMInfo[4].DefaultLanguage+'_'+$DVD).ToUpper()}
				if ($WIMInfo[4].EditionID -eq 'EnterpriseN') {$DVDLabel = ($tag+'_CENNA_'+$arch+'FREV_'+$WIMInfo[4].DefaultLanguage+'_'+$DVD).ToUpper()}
				if ($WIMInfo[4].EditionID -eq 'EnterpriseS') {$DVDLabel = ($tag+'_CES_'+$arch+'FREV_'+$WIMInfo[4].DefaultLanguage+'_'+$DVD).ToUpper()}
				if ($WIMInfo[4].EditionID -eq 'EnterpriseSN') {$DVDLabel = ($tag+'_CESN_'+$arch+'FREV_'+$WIMInfo[4].DefaultLanguage+'_'+$DVD).ToUpper()}

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
		[void][System.Reflection.Assembly]::LoadWithPartialName('presentationframework') 
		$syncHash = [hashtable]::Synchronized(@{}) 
		$newRunspace =[runspacefactory]::CreateRunspace() 
		$newRunspace.ApartmentState = "STA" 
		$newRunspace.ThreadOptions = "ReuseThread"           
		$newRunspace.Open() 
		$newRunspace.SessionStateProxy.SetVariable("syncHash",$syncHash)           
		$psCmd = [PowerShell]::Create().AddScript({    
			[xml]$xaml = Get-Content -Path 'bin\converting.xaml'
		  
			$reader=(New-Object System.Xml.XmlNodeReader $xaml) 
			$syncHash.Window=[Windows.Markup.XamlReader]::Load( $reader ) 
			
			$xaml.SelectNodes("//*[@Name]") | %{
				$syncHash.$($_.Name) = $syncHash.Window.FindName($_.Name)
			}
			
			$syncHash.DecryptingESDFile.Source = "$(Get-ScriptDirectory)\emptyness.png"
			$syncHash.GatheringBuildInformations.Source = "$(Get-ScriptDirectory)\emptyness.png"
			$syncHash.ExtractingMainSetupFiles.Source = "$(Get-ScriptDirectory)\emptyness.png"
			$syncHash.ExportingWindowsPreinstallationEnvironement.Source = "$(Get-ScriptDirectory)\emptyness.png"
			$syncHash.ExportingWindowsInstallation.Source = "$(Get-ScriptDirectory)\emptyness.png"
			$syncHash.CreatingtheISOFile.Source = "$(Get-ScriptDirectory)\emptyness.png"
			
			$syncHash.Window.Add_Closing({
				if (!($syncHash.ConvertEnded.Visibility -eq "Visible")) {
					$_.Cancel = $true
				}
			})
			
			$syncHash.Window.ShowDialog() | Out-Null 
			$syncHash.Error = $Error
		}) 
		$psCmd.Runspace = $newRunspace 
		$data = $psCmd.BeginInvoke() 
		While (!($syncHash.Window.IsInitialized)) { 
		   Start-Sleep -S 1 
		}
	} # End Begin Block
	 
	 
	Process { 
		
		Update-Window ESD_ToolKit Icon "$(Get-ScriptDirectory)\icon.ico"
		
		$MainESDFile = $ESD[0]
		
		$ProcessESD = @()
		$DeleteESD = @()
		
		Update-Window DecryptingESDFile Source "$(Get-ScriptDirectory)\arrow.png"
		
		foreach ($esdfile in $ESD) {
			& $wimlib info "$($esdfile)" > $null
			if (!$?) {
				$ProcessESD += $esdfile+".mod"
				$DeleteESD += $esdfile+".mod"
				$TempESD = $esdfile + ".mod"
				Output ([out.level] 'Info') 'Copying ESD File...'
				
				Update-Window ConvertProgress Value 0
				Update-Window ConvertProgress Visibility "Visible"
				
				Copy-File $esdfile $TempESD
				
				Update-Window ConvertProgress Visibility "Collapsed"
				Update-Window ConvertProgressMarquee Visibility "Visible"
				
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
		Update-Window DecryptingESDFile Source "$(Get-ScriptDirectory)\check.png"
		
		Update-Window GatheringBuildInformations Source "$(Get-ScriptDirectory)\arrow.png"
		
		Update-Window ConvertProgress Visibility "Collapsed"
		Update-Window ConvertProgressMarquee Visibility "Visible"
		
		Output ([out.level] 'Info') 'Gathering build information...'
		$ISOInfos = (Get-InfosFromESD $ProcessESD)
		
		$ISOInfos
		
		Update-Window GatheringBuildInformations Source "$(Get-ScriptDirectory)\check.png"
		
		Update-Window ExtractingMainSetupFiles Source "$(Get-ScriptDirectory)\arrow.png"
		
		Output ([out.level] 'Info') 'Creating Media Temporary Directory...'
		New-Item -ItemType Directory '.\Media' | out-null
		Output ([out.level] 'Info') 'Creating Setup Media Layout...'
		
		Update-Window ConvertProgressMarquee Visibility "Collapsed"
		Update-Window ConvertProgress Value 0
		Update-Window ConvertProgress Visibility "Visible"
		$name = $null
		& $wimlib apply "$($ProcessESD[0])" 1 .\Media\ | ForEach-Object -Process {
			if ($name -eq $null) {
				$name = $_
			}
			$progress = [regex]::match($_,'\(([^\)]+)\%').Groups[1].Value
			if ($progress -match "[0-9]") {
				if ($progress -ne $lastpct) {
					Update-Window ConvertProgress Value $progress
				}
				$lastpct = $progress
			}
		}
		Update-Window ConvertProgressMarquee Visibility "Collapsed"
		Update-Window ConvertProgress Value 0
		Update-Window ConvertProgress Visibility "Visible"
		Output ([out.level] 'Info') 'Deleting MediaMeta.xml file...'
		Remove-Item .\Media\MediaMeta.xml
		
		Update-Window ExtractingMainSetupFiles Source "$(Get-ScriptDirectory)\check.png"
		
		Update-Window ExportingWindowsPreinstallationEnvironement Source "$(Get-ScriptDirectory)\arrow.png"
		
		Output ([out.level] 'Info') 'Creating bootable setup image...'
		
		Update-Window ConvertProgressMarquee Visibility "Collapsed"
		Update-Window ConvertProgress Value 0
		Update-Window ConvertProgress Visibility "Visible"
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
				if ($progress -ne $lastpct) {
					Update-Window ConvertProgress Value $progress
				}
				$lastpct = $progress
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
				if ($progress -ne $lastpct) {
					Update-Window ConvertProgress Value $progress
				}
				$lastpct = $progress
			}
		}
		$sw.Stop();
		$sw.Reset();
		
		Update-Window ExportingWindowsPreinstallationEnvironement Source "$(Get-ScriptDirectory)\check.png"
		
		Update-Window ExportingWindowsInstallation Source "$(Get-ScriptDirectory)\arrow.png"
		
		Update-Window ConvertProgressMarquee Visibility "Collapsed"
		Update-Window ConvertProgress Value 0
		Update-Window ConvertProgress Visibility "Visible"
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
							if ($progress -ne $lastpct) {
								Update-Window ConvertProgress Value $progress
							}
							$lastpct = $progress
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
							if ($progress -ne $lastpct) {
								Update-Window ConvertProgress Value $progress
							}
							$lastpct = $progress
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
		Update-Window ExportingWindowsInstallation Source "$(Get-ScriptDirectory)\check.png"
		
		Update-Window CreatingtheISOFile Source "$(Get-ScriptDirectory)\arrow.png"
		
		Update-Window ConvertProgress Visibility "Collapsed"
		Update-Window ConvertProgressMarquee Visibility "Visible"
		Output ([out.level] 'Info') 'Gathering Timestamp information from the Setup Media...'
		$timestamp = (Get-ChildItem .\Media\sources\setup.exe | % {[System.TimeZoneInfo]::ConvertTimeToUtc($_.creationtime).ToString("MM/dd/yyyy,HH:mm:ss")})
		Output ([out.level] 'Info') 'Generating ISO...'
		
		$BootData='2#p0,e,bMedia\boot\etfsboot.com#pEF,e,bMedia\efi\Microsoft\boot\efisys.bin'
		& "cmd" "/c" ".\bin\cdimage.exe" "-bootdata:$BootData" "-o" "-h" "-m" "-u2" "-udfver102" "-t$timestamp" "-l$($ISOInfos.VolumeLabel)" ".\Media" """$($Destination)\$($ISOInfos.FileName)"""
		
		Update-Window CreatingtheISOFile Source "$(Get-ScriptDirectory)\check.png"
		Update-Window ConvertEnded Visibility "Visible"
		
		Write-Host ''
		Output ([out.level] 'Info') 'Removing Temporary Directories and Files...'
		Remove-Item -recurse .\Media
		foreach ($esdfile in $DeleteESD) {
			Remove-Item $esdfile
		}
		Update-Window Window Close
	}
}

function LoadXamlFile( $path )
{
	[xml]$xmlWPF = Get-Content -Path $path
    $xamGUI = [Windows.Markup.XamlReader]::Load((new-object System.Xml.XmlNodeReader $xmlWPF))
	$vars = @{}
	$xmlWPF.SelectNodes("//*[@Name]") | %{
		$vars[($_.Name)] = $xamGUI.FindName($_.Name)
	}
	$vars["Window"] = $xamGUI
    return $vars
}

$Global:LastPage = @()

function SetPage($MainWindow, $NewPage) {
	[array]$Global:LastPage += $MainWindow.Window.Content.Name
	$MainWindow.Window.Content = $NewPage.Window
	
	$Global:CurrentPage = $NewPage
	
	$NewPage.Window.add_Loaded({
		Switch ($MainWindow.Window.Content.Name) {
			"Welcome" {
				$Global:CurrentPage.Button2.isEnabled = ""
			}
			"ImageFormat" {
				if ($Global:VarImageFormat -eq "WIM") {
					$Global:CurrentPage.WIM.isChecked = "True"
				} elseif ($Global:VarImageFormat -eq "ESD") {
					$Global:CurrentPage.ESD.isChecked = "True"
				}
			}
			"FileFormat" {
				if ($Global:VarFileFormat -eq "Consumer") {
					$Global:CurrentPage.Consumer.isChecked = "True"
				} elseif ($Global:VarFileFormat -eq "Partner") {
					$Global:CurrentPage.Partner.isChecked = "True"
				} elseif ($Global:VarFileFormat -eq "Windows7") {
					$Global:CurrentPage.Windows7.isChecked = "True"
				}
			}
			"AskRSAKey" {
				if ($Global:VarAskRSAKey -eq $true) {
					$Global:CurrentPage.CustomKey.isChecked = "True"
				} elseif ($Global:VarAskRSAKey -eq $false) {
					$Global:CurrentPage.NoCustomKey.isChecked = "True"
				}
			}
			"AskDestinationPath" {
				if ($Global:VarPath -eq '.') {
					$Global:CurrentPage.NoCustomPath.isChecked = "True"
				} elseif ($Global:VarPath -ne $null) {
					$Global:CurrentPage.CustomPath.isChecked = "True"
				}
			}
			"RSAKey" {
				if ($Global:VarRSAKey -ne "") {
					$Global:CurrentPage.RSAKeyString.Text = $Global:VarRSAKey
				}
			}
			"SelectESD" {
				foreach ($item in (get-item *.esd)) {
					$Global:CurrentPage.ESDList.items.Add([pscustomobject]@{'File'=$item.Name; 'Path'=$item.FullName}) | out-null
				}
				$Global:CurrentPage.ESDList.items.Add([pscustomobject]@{'File'="Select another esd file"}) | out-null
				$Global:CurrentPage.ESDList.SelectedIndex = 0
			}
			"Recap" {
			
				$Global:CurrentPage.CheckMark.Source = "$(Get-ScriptDirectory)\check.png"
				$Global:CurrentPage.CheckMark_.Source = "$(Get-ScriptDirectory)\check.png"
				$Global:CurrentPage.CheckMark__.Source = "$(Get-ScriptDirectory)\check.png"
				$Global:CurrentPage.CheckMark___.Source = "$(Get-ScriptDirectory)\check.png"
				$Global:CurrentPage.CheckMark____.Source = "$(Get-ScriptDirectory)\check.png"
				$Global:CurrentPage.CheckMark_____.Source = "$(Get-ScriptDirectory)\check.png"
				$Global:CurrentPage.CheckMark______.Source = "$(Get-ScriptDirectory)\check.png"
				$Global:CurrentPage.CheckMark_______.Source = "$(Get-ScriptDirectory)\check.png"
				$Global:CurrentPage.CheckMark________.Source = "$(Get-ScriptDirectory)\check.png"
				$Global:CurrentPage.CheckMark_________.Source = "$(Get-ScriptDirectory)\check.png"
				
				$Global:CurrentPage.ESDSelected.Visibility = "Visible"
				
				if ($Global:VarImageFormat -eq "WIM") {
					$Global:CurrentPage.WIMFormat.Visibility = "Visible"
				} elseif ($Global:VarImageFormat -eq "ESD") {
					$Global:CurrentPage.ESDFormat.Visibility = "Visible"
				}
				
				if ($Global:VarFileFormat -eq "Consumer") {
					$Global:CurrentPage.ConsumerFormat.Visibility = "Visible"
				} elseif ($Global:VarFileFormat -eq "Partner") {
					$Global:CurrentPage.PartnerFormat.Visibility = "Visible"
				} elseif ($Global:VarFileFormat -eq "Windows7") {
					$Global:CurrentPage.Windows7Format.Visibility = "Visible"
				}
				
				if ($Global:VarAskRSAKey -eq $true) {
					$Global:CurrentPage.CustomRSAKey.Visibility = "Visible"
				} elseif ($Global:VarAskRSAKey -eq $false) {
					$Global:CurrentPage.NoCustomRSAKey.Visibility = "Visible"
				}
				
				if ($Global:VarPath -eq '.') {
					$Global:CurrentPage.NoCustomPathSelected.Visibility = "Visible"
				} else {
					$Global:CurrentPage.CustomPathSelected.Visibility = "Visible"
				}
			}
		}
	})
	
	$NewPage.Button.add_Click({
		Switch ($MainWindow.Window.Content.Name) {
			"Welcome" {
				if ($Global:CurrentPage.ConvertESD.isChecked) {
					$ImageFormat = LoadXamlFile 'bin\ImageFormat.xaml'
					SetPage $MainWindow $ImageFormat
				} elseif ($Global:CurrentPage.Download.isChecked) {
					$MainWindow.Window.Close()
				}
			}
			"ImageFormat" {
				if ($Global:CurrentPage.WIM.isChecked) {
					$Global:VarImageFormat = "WIM"
				} elseif ($Global:CurrentPage.ESD.isChecked) {
					$Global:VarImageFormat = "ESD"
				}
				$FileFormat = LoadXamlFile 'bin\FileFormat.xaml'
				SetPage $MainWindow $FileFormat
			}
			"FileFormat" {
				if ($Global:CurrentPage.Consumer.isChecked) {
					$Global:VarFileFormat = "Consumer"
				} elseif ($Global:CurrentPage.Partner.isChecked) {
					$Global:VarFileFormat = "Partner"
				} elseif ($Global:CurrentPage.Windows7.isChecked) {
					$Global:VarFileFormat = "Windows7"
				}
				$AskRSAKey = LoadXamlFile 'bin\AskRSAKey.xaml'
				SetPage $MainWindow $AskRSAKey
			}
			"AskRSAKey" {
				if ($Global:CurrentPage.NoCustomKey.isChecked) {
					$Global:VarAskRSAKey = $false
					$AskDestinationPath = LoadXamlFile 'bin\AskDestinationPath.xaml'
					SetPage $MainWindow $AskDestinationPath
				} elseif ($Global:CurrentPage.CustomKey.isChecked) {
					$Global:VarAskRSAKey = $true
					$RSAKey = LoadXamlFile 'bin\RSAKey.xaml'
					SetPage $MainWindow $RSAKey
				}
			}
			"AskDestinationPath" {
				if ($Global:CurrentPage.NoCustomPath.isChecked) {
					$Global:VarPath = '.'
				} elseif ($Global:CurrentPage.CustomPath.isChecked) {
					$app = new-object -com Shell.Application
					$folder = $app.BrowseForFolder(0, "Select Destination Folder", 0, "C:\")
					$Global:VarPath = $folder.Self.Path
					if ($Global:VarPath -eq $null) {
						$MainWindow.Window.Close()
						return
					}
				}
				$SelectESD = LoadXamlFile 'bin\SelectESD.xaml'
				SetPage $MainWindow $SelectESD
			}
			"RSAKey" {
				$Global:VarRSAKey = $Global:CurrentPage.RSAKeyString.Text
				$AskDestinationPath = LoadXamlFile 'bin\AskDestinationPath.xaml'
				SetPage $MainWindow $AskDestinationPath
			}
			"SelectESD" {
				$Global:VarSelectedFile = $Global:CurrentPage.ESDList.SelectedItems.Path
				if ($Global:CurrentPage.ESDList.SelectedItems.Path -eq $null) {
					[System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null
					$OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
					$OpenFileDialog.filter = "ESD file (*.esd)| *.esd"
					$OpenFileDialog.ShowDialog() | Out-Null
					$Global:VarSelectedFile = $OpenFileDialog.filename
				}
				if ($Global:VarSelectedFile -eq "") {
					$MainWindow.Window.Close()
					return
				}
				$Recap = LoadXamlFile 'bin\Recap.xaml'
				SetPage $MainWindow $Recap
			}
			"Recap" {
				$MainWindow.Window.Close()
 				if ($VarRSAKey -eq "") {
					doConvertESD -extensiontype $VarImageFormat -ESD $VarSelectedFile -Destination $VarPath
				} if ($VarRSAKey -eq $null) {
					doConvertESD -extensiontype $VarImageFormat -ESD $VarSelectedFile -Destination $VarPath
				} else {
					doConvertESD -CryptoKey $VarRSAKey -extensiontype $VarImageFormat -ESD $VarSelectedFile -Destination $VarPath
				}
				
				[xml]$Global:xmlWPF = Get-Content -Path 'bin\ConvertEnd.xaml'
				
				$Global:xamGUI = [Windows.Markup.XamlReader]::Load((new-object System.Xml.XmlNodeReader $xmlWPF))

				$xmlWPF.SelectNodes("//*[@Name]") | %{
					Set-Variable -Name ($_.Name) -Value $xamGUI.FindName($_.Name) -Scope Global
				}
				
				$ESD_ToolKit.Icon = "$(Get-ScriptDirectory)\icon.ico"
				
				$CheckMarkEnd.Source = "$(Get-ScriptDirectory)\check_big.png"
				
				$Button.add_Click({$xamGUI.Close()})
				
				$xamGUI.ShowDialog() | out-null
			}
			
		}
	})
	
	$NewPage.Button2.add_Click({
		if ($lastpage -ne $null) {
			if ($lastpage -is [system.array]) {
				$Page = LoadXamlFile ('bin\'+$lastpage[-1]+".xaml")
				$Global:LastPage = $Global:LastPage | Where-Object { $_ -ne $Global:LastPage[-1] }
			} else {
				$Page = LoadXamlFile ('bin\'+$lastpage+".xaml")
				$Global:LastPage = @()
			}
			SetPage $MainWindow $Page
			if ($lastpage -is [system.array]) {
				$Global:LastPage = $Global:LastPage | Where-Object { $_ -ne $Global:LastPage[-1] }
			} else {
				$Global:LastPage = @()
			}
		}
	})
}

$MainWindow = LoadXamlFile 'bin\MainWindow.xaml'

$MainWindow.ESD_ToolKit.Icon = "$(Get-ScriptDirectory)\icon.ico"

$Welcome = LoadXamlFile 'bin\welcome.xaml'

SetPage $MainWindow $Welcome

$MainWindow.Window.ShowDialog()