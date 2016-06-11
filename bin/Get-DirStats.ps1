# Get-DirStats.ps1
# Written by Bill Stewart (bstewart@iname.com)
# Outputs file system directory statistics.

#requires -version 2

<#
.SYNOPSIS
Outputs file system directory statistics.

.DESCRIPTION
Outputs file system directory statistics (number of files and the sum of all file sizes) for one or more directories.

.PARAMETER Path
Specifies a path to one or more file system directories. Wildcards are not permitted. The default path is the current directory (.).

.PARAMETER LiteralPath
Specifies a path to one or more file system directories. Unlike Path, the value of LiteralPath is used exactly as it is typed.

.PARAMETER Only
Outputs statistics for a directory but not any of its subdirectories.

.PARAMETER Every
Outputs statistics for every directory in the specified path instead of only the first level of directories.

.PARAMETER FormatNumbers
Formats numbers in the output object to include thousands separators.

.PARAMETER Total
Outputs a summary object after all other output that sums all statistics.
#>

[CmdletBinding(DefaultParameterSetName="Path")]
param(
  [parameter(Position=0,Mandatory=$false,ParameterSetName="Path",ValueFromPipeline=$true)]
    $Path=(get-location).Path,
  [parameter(Position=0,Mandatory=$true,ParameterSetName="LiteralPath")]
    [String[]] $LiteralPath,
    [Switch] $Only,
    [Switch] $Every,
    [Switch] $FormatNumbers,
    [Switch] $Total
)

begin {
  $ParamSetName = $PSCmdlet.ParameterSetName
  if ( $ParamSetName -eq "Path" ) {
    $PipelineInput = ( -not $PSBoundParameters.ContainsKey("Path") ) -and ( -not $Path )
  }
  elseif ( $ParamSetName -eq "LiteralPath" ) {
    $PipelineInput = $false
  }

  # Script-level variables used with -Total.
  [UInt64] $script:totalcount = 0
  [UInt64] $script:totalbytes = 0

  # Returns a [System.IO.DirectoryInfo] object if it exists.
  function Get-Directory {
    param( $item )

    if ( $ParamSetName -eq "Path" ) {
      if ( Test-Path -Path $item -PathType Container ) {
        $item = Get-Item -Path $item -Force
      }
    }
    elseif ( $ParamSetName -eq "LiteralPath" ) {
      if ( Test-Path -LiteralPath $item -PathType Container ) {
        $item = Get-Item -LiteralPath $item -Force
      }
    }
    if ( $item -and ($item -is [System.IO.DirectoryInfo]) ) {
      return $item
    }
  }

  # Filter that outputs the custom object with formatted numbers.
  function Format-Output {
    process {
      $_ | Select-Object Path,
        @{Name="Files"; Expression={"{0:N0}" -f $_.Files}},
        @{Name="Size"; Expression={"{0:N0}" -f $_.Size}}
    }
  }

  # Outputs directory statistics for the specified directory. With -recurse,
  # the function includes files in all subdirectories of the specified
  # directory. With -format, numbers in the output objects are formatted with
  # the Format-Output filter.
  function Get-DirectoryStats {
    param( $directory, $recurse, $format )

    Write-Progress -Activity "Get-DirStats.ps1" -Status "Reading '$($directory.FullName)'"
    $files = $directory | Get-ChildItem -Force -Recurse:$recurse | Where-Object { -not $_.PSIsContainer }
    if ( $files ) {
      Write-Progress -Activity "Get-DirStats.ps1" -Status "Calculating '$($directory.FullName)'"
      $output = $files | Measure-Object -Sum -Property Length | Select-Object `
        @{Name="Path"; Expression={$directory.FullName}},
        @{Name="Files"; Expression={$_.Count; $script:totalcount += $_.Count}},
        @{Name="Size"; Expression={$_.Sum; $script:totalbytes += $_.Sum}}
    }
    else {
      $output = "" | Select-Object `
        @{Name="Path"; Expression={$directory.FullName}},
        @{Name="Files"; Expression={0}},
        @{Name="Size"; Expression={0}}
    }
    if ( -not $format ) { $output } else { $output | Format-Output }
  }
}

process {
  # Get the item to process, no matter whether the input comes from the
  # pipeline or not.
  if ( $PipelineInput ) {
    $item = $_
  }
  else {
    if ( $ParamSetName -eq "Path" ) {
      $item = $Path
    }
    elseif ( $ParamSetName -eq "LiteralPath" ) {
      $item = $LiteralPath
    }
  }

  # Write an error if the item is not a directory in the file system.
  $directory = Get-Directory -item $item
  if ( -not $directory ) {
    Write-Error -Message "Path '$item' is not a directory in the file system." -Category InvalidType
    return
  }

  # Get the statistics for the first-level directory.
  Get-DirectoryStats -directory $directory -recurse:$false -format:$FormatNumbers
  # -Only means no further processing past the first-level directory.
  if ( $Only ) { return }

  # Get the subdirectories of the first-level directory and get the statistics
  # for each of them.
  $directory | Get-ChildItem -Force -Recurse:$Every |
    Where-Object { $_.PSIsContainer } | ForEach-Object {
      Get-DirectoryStats -directory $_ -recurse:(-not $Every) -format:$FormatNumbers
    }
}

end {
  # If -Total specified, output summary object.
  if ( $Total ) {
    $output = "" | Select-Object `
      @{Name="Path"; Expression={"<Total>"}},
      @{Name="Files"; Expression={$script:totalcount}},
      @{Name="Size"; Expression={$script:totalbytes}}
    if ( -not $FormatNumbers ) { $output } else { $output | Format-Output }
  }
}
