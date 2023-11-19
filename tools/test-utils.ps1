function Remove-EntryFromZip {
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [Alias('p')][string]$Path,
        [Parameter(Mandatory = $true, Position = 1)]
        [Alias('l')][string[]]$List
    )
    try {
        $null = [Reflection.Assembly]::LoadWithPartialName('System.IO.Compression')
        $stream = [System.IO.FileStream]::new($Path, [System.IO.FileMode]::Open)
        $mode = [System.IO.Compression.ZipArchiveMode]::Update
        $zip = [System.IO.Compression.ZipArchive]::new($stream, $mode)
        $zip.Entries.Where({ $List -contains $_.Name }).ForEach({ $_.Delete() })
    } finally {
        if ($zip) { $zip.Dispose() }
        if ($stream) { $stream.Dispose() }
    }
}

function Get-FileMetaData {
    <#
    .SYNOPSIS
        Returns metadata information about a single file.
    .DESCRIPTION
        This function will return all metadata information about a specific file. It can be used to access the information stored in the filesystem.
    .EXAMPLE
        Get-FileMetaData -File "c:\temp\image.jpg"
        Get information about an image file.
    .EXAMPLE
        Get-FileMetaData -File "c:\temp\image.jpg" | Select Dimensions
        Show the dimensions of the image.
    .EXAMPLE
        Get-ChildItem -Path .\ -Filter *.exe | foreach {Get-FileMetaData -File $_.FullName | Select Name,"File version"}
        Show the file version of all binary files in the current folder.
    #>
    param([Parameter(Mandatory = $True)][string]$File)

    if (!(Test-Path $File -PathType Leaf)) {
        Write-Error "File does not exist: $File"
        return
    }

    $fileinfo = Get-Item $File
    $pathname = $fileinfo.DirectoryName
    $filename = $fileinfo.Name

    $property = @{}

    try {
        $shellobj = New-Object -ComObject Shell.Application
        $folderobj = $shellobj.NameSpace($pathname)
        $fileobj = $folderobj.ParseName($filename)

        for ($i = 0; $i -le 300; $i++) {
            $name = $folderobj.getDetailsOf($null, $i);
            if ($name -and $fileobj) {
                $value = $folderobj.getDetailsOf($fileobj, $i);
                if ($value) { $property["$name"] = "$value" }
            }
        }
    } finally {
        if ($shellobj) {
            [System.Runtime.InteropServices.Marshal]::ReleaseComObject($shellobj) | Out-Null
        }
    }

    return New-Object psobject -Property $property
}
