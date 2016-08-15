# Functions:
# New-Enum
# Remove-InvalidFileNameChars
# Get-IniContent
# Test-Wow64
# Test-Win64
# Test-Win32
# Test-Arch
# Menu-Select
# DownloadFile
# Output
# Copy-File
# -------------
# Setups WIMLib

<#
	Location of the required binaries for this script
#>
$bin = (Split-Path -Parent -Path $MyInvocation.MyCommand.Definition)

function New-Enum ([string]$name) {
  $appdomain = [System.Threading.Thread]::GetDomain()
  $assembly = New-Object System.Reflection.AssemblyName
  $assembly.Name = "EmittedEnum"
  $assemblyBuilder = $appdomain.DefineDynamicAssembly($assembly,
    [System.Reflection.Emit.AssemblyBuilderAccess]::Save -bor [System.Reflection.Emit.AssemblyBuilderAccess]::Run);
  $moduleBuilder = $assemblyBuilder.DefineDynamicModule("DynamicModule","DynamicModule.mod");
  $enumBuilder = $moduleBuilder.DefineEnum($name,[System.Reflection.TypeAttributes]::Public,[System.Int32]);
  for ($i = 0; $i -lt $args.Length; $i++)
  {
    $null = $enumBuilder.DefineLiteral($args[$i],$i);
  }
  $enumBuilder.CreateType() > $null;
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

# Is this a Wow64 powershell host
function Test-Wow64 () {
  return (Test-Win32) -and (Test-Path env:\PROCESSOR_ARCHITEW6432)
}

# Is this a 64 bit process
function Test-Win64 () {
  return [intptr]::size -eq 8
}

# Is this a 32 bit process
function Test-Win32 () {
  return [intptr]::size -eq 4
}

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
    0 { $result.FileType = 'NATIVE' }
    0x1d3 { $result.FileType = 'AM33' }
    0x8664 { $result.FileType = 'AMD64' }
    0x1c0 { $result.FileType = 'ARM' }
    0xaa64 { $result.FileType = 'ARM64' }
    0x1c4 { $result.FileType = 'ARMNT' }
    0xebc { $result.FileType = 'EBC' }
    0x14c { $result.FileType = 'X86' }
    0x200 { $result.FileType = 'IA64' }
    0x9041 { $result.FileType = 'M32R' }
    0x266 { $result.FileType = 'MIPS16' }
    0x366 { $result.FileType = 'MIPSFPU' }
    0x466 { $result.FileType = 'MIPSFPU16' }
    0x1f0 { $result.FileType = 'POWERPC' }
    0x1f1 { $result.FileType = 'POWERPCFP' }
    0x166 { $result.FileType = 'R4000' }
    0x1a2 { $result.FileType = 'SH3' }
    0x1a3 { $result.FileType = 'SH3DSP' }
    0x1a6 { $result.FileType = 'SH4' }
    0x1a8 { $result.FileType = 'SH5' }
    0x1c2 { $result.FileType = 'THUMB' }
    0x169 { $result.FileType = 'WCEMIPSV2' }
  }

  $result
}

function Menu-Select ($displayoptions,$arrayofoptions) {
  do {
    $counter = 0
    foreach ($item in $displayoptions) {
      $counter++
      $padding = ' ' * ((([string]$displayoptions.Length).Length) - (([string]$counter).Length))
      Write-Host -ForegroundColor White ('[' + $counter + ']' + $padding + ' ' + $item)
    }
    Write-Host ''
    $choice = Read-Host -Prompt "Select number and press enter"
  } until ([int]$choice -gt 0 -and [int]$choice -le $counter)
  $choice = $choice - 1
  return $arrayofoptions[$choice]
}

function DownloadFile ($url,$targetFile) {
  $uri = New-Object "System.Uri" "$url"
  $request = [System.Net.HttpWebRequest]::Create($uri)
  $request.set_Timeout(15000) #15 second timeout
  $response = $request.GetResponse()
  $totalLength = [System.Math]::Floor($response.get_ContentLength() / 1024)
  $responseStream = $response.GetResponseStream()
  $targetStream = New-Object -TypeName System.IO.FileStream -ArgumentList $targetFile,Create
  $buffer = New-Object byte[] 10KB
  $count = $responseStream.Read($buffer,0,$buffer.Length)
  $downloadedBytes = $count
  while ($count -gt 0)
  {
    $targetStream.Write($buffer,0,$count)
    $count = $responseStream.Read($buffer,0,$buffer.Length)
    $downloadedBytes = $downloadedBytes + $count
    $percent = "{0:N2}" -f ((([System.Math]::Floor($downloadedBytes / 1024)) / $totalLength) * 100)
    Write-Progress -Activity "Downloading file '$($url.split('/') | Select -Last 1)'" -Status "Downloaded ($([System.Math]::Floor($downloadedBytes/1024))K of $($totalLength)K) ($($percent)%): " -PercentComplete ((([System.Math]::Floor($downloadedBytes / 1024)) / $totalLength) * 100)
  }
  Write-Progress -Activity "Finished downloading file '$($url.split('/') | Select -Last 1)'"
  $targetStream.Flush()
  $targetStream.Close()
  $targetStream.Dispose()
  $responseStream.Dispose()
}

New-Enum out.level Info Warning Error

function Output ([out.level]$level,[string]$message) {
  $output = '[' + $level + '] ' + $message
  Write-Host $output
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
           -Activity ($pctcomp.ToString() + "% Copying file @ " + "{0:n2}" -f $xferrate + " MB/s") `
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
    Output ([out.level]'Info') (($from.Split("\") | select -Last 1) + `
         " copied in " + $secselapsed + " seconds at " + `
         "{0:n2}" -f [int](($ffile.Length / $secselapsed) / 1mb) + " MB/s.");
    $ffile.Close();
    $tofile.Close();

  }
}

if (Test-Wow64) {
  $wimlib = "$($bin)\wimlib\bin86\wimlib-imagex.exe"
} elseif (Test-Win64) {
  $wimlib = "$($bin)\wimlib\bin64\wimlib-imagex.exe"
} elseif (Test-Win32) {
  $wimlib = "$($bin)\wimlib\bin86\bin\wimlib-imagex.exe"
} else {
  return
}
