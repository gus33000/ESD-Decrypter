#Requires -Version 2.0
 
# Recursive function to calculate the total number of files and directories in the Zip file.
function GetNumberOfItemsInZipFileItems($shellItems)
{
    [int]$totalItems = $shellItems.Count
    foreach ($shellItem in $shellItems)
    {
        if ($shellItem.IsFolder)
        { $totalItems += GetNumberOfItemsInZipFileItems -shellItems $shellItem.GetFolder.Items() }
    }
    $totalItems
}
 
# Recursive function to move a directory into a Zip file, since we can move files out of a Zip file, but not directories, and copying a directory into a Zip file when it already exists is not allowed.
function MoveDirectoryIntoZipFile($parentInZipFileShell, $pathOfItemToCopy)
{
    # Get the name of the file/directory to copy, and the item itself.
    $nameOfItemToCopy = Split-Path -Path $pathOfItemToCopy -Leaf
    if ($parentInZipFileShell.IsFolder)
    { $parentInZipFileShell = $parentInZipFileShell.GetFolder }
    $itemToCopyShell = $parentInZipFileShell.ParseName($nameOfItemToCopy)
     
    # If this item does not exist in the Zip file yet, or it is a file, move it over.
    if ($itemToCopyShell -eq $null -or !$itemToCopyShell.IsFolder)
    {
        $parentInZipFileShell.MoveHere($pathOfItemToCopy)
         
        # Wait for the file to be moved before continuing, to avoid erros about the zip file being locked or a file not being found.
        while (Test-Path -Path $pathOfItemToCopy)
        { Start-Sleep -Milliseconds 10 }
    }
    # Else this is a directory that already exists in the Zip file, so we need to traverse it and copy each file/directory within it.
    else
    {
        # Copy each file/directory in the directory to the Zip file.
        foreach ($item in (Get-ChildItem -Path $pathOfItemToCopy -Force))
        {
            MoveDirectoryIntoZipFile -parentInZipFileShell $itemToCopyShell -pathOfItemToCopy $item.FullName
        }
    }
}
 
# Recursive function to move all of the files that start with the File Name Prefix to the Directory To Move Files To.
function MoveFilesOutOfZipFileItems($shellItems, $directoryToMoveFilesToShell, $fileNamePrefix)
{
    # Loop through every item in the file/directory.
    foreach ($shellItem in $shellItems)
    {
        # If this is a directory, recursively call this function to iterate over all files/directories within it.
        if ($shellItem.IsFolder)
        { 
            $totalItems += MoveFilesOutOfZipFileItems -shellItems $shellItem.GetFolder.Items() -directoryToMoveFilesTo $directoryToMoveFilesToShell -fileNameToMatch $fileNameToMatch
        }
        # Else this is a file.
        else
        {
            # If this file name starts with the File Name Prefix, move it to the specified directory.
            if ($shellItem.Name.StartsWith($fileNamePrefix))
            {
                $directoryToMoveFilesToShell.MoveHere($shellItem)
            }
        }           
    }
}
 
function Expand-ZipFile
{
    [CmdletBinding()]
    param
    (
        [parameter(Position=1,Mandatory=$true)]
        [ValidateScript({(Test-Path -Path $_ -PathType Leaf) -and $_.EndsWith('.zip', [StringComparison]::OrdinalIgnoreCase)})]
        [string]$ZipFilePath, 
         
        [parameter(Position=2,Mandatory=$false)]
        [string]$DestinationDirectoryPath, 
         
        [Alias("Force")]
        [switch]$OverwriteWithoutPrompting
    )
     
    BEGIN { }
    END { }
    PROCESS
    {   
        # If a Destination Directory was not given, create one in the same directory as the Zip file, with the same name as the Zip file.
        if ($DestinationDirectoryPath -eq $null -or $DestinationDirectoryPath.Trim() -eq [string]::Empty)
        {
            $zipFileDirectoryPath = Split-Path -Path $ZipFilePath -Parent
            $zipFileNameWithoutExtension = [System.IO.Path]::GetFileNameWithoutExtension($ZipFilePath)
            $DestinationDirectoryPath = Join-Path -Path $zipFileDirectoryPath -ChildPath $zipFileNameWithoutExtension
        }
         
        # If the directory to unzip the files to does not exist yet, create it.
        if (!(Test-Path -Path $DestinationDirectoryPath -PathType Container)) 
        { New-Item -Path $DestinationDirectoryPath -ItemType Container -gt $null }
 
        # Flags and values found at: https://msdn.microsoft.com/en-us/library/windows/desktop/bb759795%28v=vs.85%29.aspx
        $FOF_SILENT = 0x0004
        $FOF_NOCONFIRMATION = 0x0010
        $FOF_NOERRORUI = 0x0400
 
        # Set the flag values based on the parameters provided.
        $copyFlags = 0
        if ($OverwriteWithoutPrompting)
        { $copyFlags = $FOF_NOCONFIRMATION }
    #   { $copyFlags = $FOF_SILENT + $FOF_NOCONFIRMATION + $FOF_NOERRORUI }
 
        # Get the Shell object, Destination Directory, and Zip file.
        $shell = New-Object -ComObject Shell.Application
        $destinationDirectoryShell = $shell.NameSpace($DestinationDirectoryPath)
        $zipShell = $shell.NameSpace($ZipFilePath)
         
        # Start copying the Zip files into the destination directory, using the flags specified by the user. This is an asynchronous operation.
        $destinationDirectoryShell.CopyHere($zipShell.Items(), $copyFlags)
 
        # Get the number of files and directories in the Zip file.
        $numberOfItemsInZipFile = GetNumberOfItemsInZipFileItems -shellItems $zipShell.Items()
         
        # The Copy (i.e. unzip) operation is asynchronous, so wait until it is complete before continuing. That is, sleep until the Destination Directory has the same number of files as the Zip file.
        while ((Get-ChildItem -Path $DestinationDirectoryPath -Recurse -Force).Count -lt $numberOfItemsInZipFile)
        { Start-Sleep -Milliseconds 100 }
    }
}
 
function Compress-ZipFile
{
    [CmdletBinding()]
    param
    (
        [parameter(Position=1,Mandatory=$true)]
        [ValidateScript({Test-Path -Path $_})]
        [string]$FileOrDirectoryPathToAddToZipFile, 
     
        [parameter(Position=2,Mandatory=$false)]
        [string]$ZipFilePath,
         
        [Alias("Force")]
        [switch]$OverwriteWithoutPrompting
    )
     
    BEGIN { }
    END { }
    PROCESS
    {
        # If a Zip File Path was not given, create one in the same directory as the file/directory being added to the zip file, with the same name as the file/directory.
        if ($ZipFilePath -eq $null -or $ZipFilePath.Trim() -eq [string]::Empty)
        { $ZipFilePath = Join-Path -Path $FileOrDirectoryPathToAddToZipFile -ChildPath '.zip' }
         
        # If the Zip file to create does not have an extension of .zip (which is required by the shell.application), add it.
        if (!$ZipFilePath.EndsWith('.zip', [StringComparison]::OrdinalIgnoreCase))
        { $ZipFilePath += '.zip' }
         
        # If the Zip file to add the file to does not exist yet, create it.
        if (!(Test-Path -Path $ZipFilePath -PathType Leaf))
        { New-Item -Path $ZipFilePath -ItemType File -gt $null }
 
        # Get the Name of the file or directory to add to the Zip file.
        $fileOrDirectoryNameToAddToZipFile = Split-Path -Path $FileOrDirectoryPathToAddToZipFile -Leaf
 
        # Get the number of files and directories to add to the Zip file.
        $numberOfFilesAndDirectoriesToAddToZipFile = (Get-ChildItem -Path $FileOrDirectoryPathToAddToZipFile -Recurse -Force).Count
         
        # Get if we are adding a file or directory to the Zip file.
        $itemToAddToZipIsAFile = Test-Path -Path $FileOrDirectoryPathToAddToZipFile -PathType Leaf
 
        # Get Shell object and the Zip File.
        $shell = New-Object -ComObject Shell.Application
        $zipShell = $shell.NameSpace($ZipFilePath)
 
        # We will want to check if we can do a simple copy operation into the Zip file or not. Assume that we can't to start with.
        # We can if the file/directory does not exist in the Zip file already, or it is a file and the user wants to be prompted on conflicts.
        $canPerformSimpleCopyIntoZipFile = $false
 
        # If the file/directory does not already exist in the Zip file, or it does exist, but it is a file and the user wants to be prompted on conflicts, then we can perform a simple copy into the Zip file.
        $fileOrDirectoryInZipFileShell = $zipShell.ParseName($fileOrDirectoryNameToAddToZipFile)
        $itemToAddToZipIsAFileAndUserWantsToBePromptedOnConflicts = ($itemToAddToZipIsAFile -and !$OverwriteWithoutPrompting)
        if ($fileOrDirectoryInZipFileShell -eq $null -or $itemToAddToZipIsAFileAndUserWantsToBePromptedOnConflicts)
        {
            $canPerformSimpleCopyIntoZipFile = $true
        }
         
        # If we can perform a simple copy operation to get the file/directory into the Zip file.
        if ($canPerformSimpleCopyIntoZipFile)
        {
            # Start copying the file/directory into the Zip file since there won't be any conflicts. This is an asynchronous operation.
            $zipShell.CopyHere($FileOrDirectoryPathToAddToZipFile)  # Copy Flags are ignored when copying files into a zip file, so can't use them like we did with the Expand-ZipFile function.
             
            # The Copy operation is asynchronous, so wait until it is complete before continuing.
            # Wait until we can see that the file/directory has been created.
            while ($zipShell.ParseName($fileOrDirectoryNameToAddToZipFile) -eq $null)
            { Start-Sleep -Milliseconds 100 }
             
            # If we are copying a directory into the Zip file, we want to wait until all of the files/directories have been copied.
            if (!$itemToAddToZipIsAFile)
            {
                # Get the number of files and directories that should be copied into the Zip file.
                $numberOfItemsToCopyIntoZipFile = (Get-ChildItem -Path $FileOrDirectoryPathToAddToZipFile -Recurse -Force).Count
             
                # Get a handle to the new directory we created in the Zip file.
                $newDirectoryInZipFileShell = $zipShell.ParseName($fileOrDirectoryNameToAddToZipFile)
                 
                # Wait until the new directory in the Zip file has the expected number of files and directories in it.
                while ((GetNumberOfItemsInZipFileItems -shellItems $newDirectoryInZipFileShell.GetFolder.Items()) -lt $numberOfItemsToCopyIntoZipFile)
                { Start-Sleep -Milliseconds 100 }
            }
        }
        # Else we cannot do a simple copy operation. We instead need to move the files out of the Zip file so that we can merge the directory, or overwrite the file without the user being prompted.
        # We cannot move a directory into the Zip file if a directory with the same name already exists, as a MessageBox warning is thrown, not a conflict resolution prompt like with files.
        # We cannot silently overwrite an existing file in the Zip file, as the flags passed to the CopyHere/MoveHere functions seem to be ignored when copying into a Zip file.
        else
        {
            # Create a temp directory to hold our file/directory.
            $tempDirectoryPath = $null
            $tempDirectoryPath = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath ([System.IO.Path]::GetRandomFileName())
            New-Item -Path $tempDirectoryPath -ItemType Container -gt $null
         
            # If we will be moving a directory into the temp directory.
            $numberOfItemsInZipFilesDirectory = 0
            if ($fileOrDirectoryInZipFileShell.IsFolder)
            {
                # Get the number of files and directories in the Zip file's directory.
                $numberOfItemsInZipFilesDirectory = GetNumberOfItemsInZipFileItems -shellItems $fileOrDirectoryInZipFileShell.GetFolder.Items()
            }
         
            # Start moving the file/directory out of the Zip file and into a temp directory. This is an asynchronous operation.
            $tempDirectoryShell = $shell.NameSpace($tempDirectoryPath)
            $tempDirectoryShell.MoveHere($fileOrDirectoryInZipFileShell)
             
            # If we are moving a directory, we need to wait until all of the files and directories in that Zip file's directory have been moved.
            $fileOrDirectoryPathInTempDirectory = Join-Path -Path $tempDirectoryPath -ChildPath $fileOrDirectoryNameToAddToZipFile
            if ($fileOrDirectoryInZipFileShell.IsFolder)
            {
                # The Move operation is asynchronous, so wait until it is complete before continuing. That is, sleep until the Destination Directory has the same number of files as the directory in the Zip file.
                while ((Get-ChildItem -Path $fileOrDirectoryPathInTempDirectory -Recurse -Force).Count -lt $numberOfItemsInZipFilesDirectory)
                { Start-Sleep -Milliseconds 100 }
            }
            # Else we are just moving a file, so we just need to check for when that one file has been moved.
            else
            {
                # The Move operation is asynchronous, so wait until it is complete before continuing.
                while (!(Test-Path -Path $fileOrDirectoryPathInTempDirectory))
                { Start-Sleep -Milliseconds 100 }
            }
             
            # We want to copy the file/directory to add to the Zip file to the same location in the temp directory, so that files/directories are merged.
            # If we should automatically overwrite files, do it.
            if ($OverwriteWithoutPrompting)
            { Copy-Item -Path $FileOrDirectoryPathToAddToZipFile -Destination $tempDirectoryPath -Recurse -Force }
            # Else the user should be prompted on each conflict.
            else
            { Copy-Item -Path $FileOrDirectoryPathToAddToZipFile -Destination $tempDirectoryPath -Recurse -Confirm -ErrorAction SilentlyContinue }  # SilentlyContinue errors to avoid an error for every directory copied.
 
            # For whatever reason the zip.MoveHere() function is not able to move empty directories into the Zip file, so we have to put dummy files into these directories 
            # and then remove the dummy files from the Zip file after.
            # If we are copying a directory into the Zip file.
            $dummyFileNamePrefix = 'Dummy.File'
            [int]$numberOfDummyFilesCreated = 0
            if ($fileOrDirectoryInZipFileShell.IsFolder)
            {
                # Place a dummy file in each of the empty directories so that it gets copied into the Zip file without an error.
                $emptyDirectories = Get-ChildItem -Path $fileOrDirectoryPathInTempDirectory -Recurse -Force -Directory | Where-Object { (Get-ChildItem -Path $_ -Force) -eq $null }
                foreach ($emptyDirectory in $emptyDirectories)
                {
                    $numberOfDummyFilesCreated++
                    New-Item -Path (Join-Path -Path $emptyDirectory.FullName -ChildPath "$dummyFileNamePrefix$numberOfDummyFilesCreated") -ItemType File -Force -gt $null
                }
            }       
 
            # If we need to copy a directory back into the Zip file.
            if ($fileOrDirectoryInZipFileShell.IsFolder)
            {
                MoveDirectoryIntoZipFile -parentInZipFileShell $zipShell -pathOfItemToCopy $fileOrDirectoryPathInTempDirectory
            }
            # Else we need to copy a file back into the Zip file.
            else
            {
                # Start moving the merged file back into the Zip file. This is an asynchronous operation.
                $zipShell.MoveHere($fileOrDirectoryPathInTempDirectory)
            }
             
            # The Move operation is asynchronous, so wait until it is complete before continuing.
            # Sleep until all of the files have been moved into the zip file. The MoveHere() function leaves empty directories behind, so we only need to watch for files.
            do
            {
                Start-Sleep -Milliseconds 100
                $files = Get-ChildItem -Path $fileOrDirectoryPathInTempDirectory -Force -Recurse | Where-Object { !$_.PSIsContainer }
            } while ($files -ne $null)
             
            # If there are dummy files that need to be moved out of the Zip file.
            if ($numberOfDummyFilesCreated -gt 0)
            {
                # Move all of the dummy files out of the supposed-to-be empty directories in the Zip file.
                MoveFilesOutOfZipFileItems -shellItems $zipShell.items() -directoryToMoveFilesToShell $tempDirectoryShell -fileNamePrefix $dummyFileNamePrefix
                 
                # The Move operation is asynchronous, so wait until it is complete before continuing.
                # Sleep until all of the dummy files have been moved out of the zip file.
                do
                {
                    Start-Sleep -Milliseconds 100
                    [Object[]]$files = Get-ChildItem -Path $tempDirectoryPath -Force -Recurse | Where-Object { !$_.PSIsContainer -and $_.Name.StartsWith($dummyFileNamePrefix) }
                } while ($files -eq $null -or $files.Count -lt $numberOfDummyFilesCreated)
            }
             
            # Delete the temp directory that we created.
            Remove-Item -Path $tempDirectoryPath -Force -Recurse -gt $null
        }
    }
}
 
# Specify which functions should be publicly accessible.
Export-ModuleMember -Function Expand-ZipFile
Export-ModuleMember -Function Compress-ZipFile