<#
.SYNOPSIS
    Build Dracula theme.
.DESCRIPTION
    A tool to build Dracula theme for MiXplorer.
.EXAMPLE
    ./build.ps1 -Name Dracula -Accent Purple -Verbose
    This result in a Dracula.mit theme with a Purple accent and
    by default the Accent is Pink.
.NOTES
    rsvg-convert or cairosvg is required to convert svg to png format.
.LINK
    https://draculatheme.com/mixplorer
#>
[CmdletBinding()]
param (
    [Alias('n')][string]$Name,
    [ValidateSet('Pink', 'Purple')]
    [Alias('a')][string]$Accent = 'Pink',
    [Alias('f')][switch]$Force
)
begin {
    [System.Console]::WriteLine('Initializing...')
    [System.IO.Directory]::SetCurrentDirectory("$PSScriptRoot/..")
    $ROOT_PATH = [System.Environment]::CurrentDirectory

    if ($Accent -eq 'Purple') {
        $accentHex = '#BD93F9'; $titleName = 'Dracula Purple'
    } else {
        $accentHex = '#FF79C6'; $titleName = 'Dracula';
    }
    if ($Name) {
        $BASE_NAME = [System.IO.Path]::GetFileNameWithoutExtension($Name)
    } else {
        $BASE_NAME = 'dracula-' + $Accent.ToLower()
    }

    $metaData = [System.Collections.Hashtable]::new()
    $sourceRootDir = [System.IO.Path]::Combine($ROOT_PATH, 'res')

    # This will validate the templates.txt file. This method is
    # the same as using the ConvertFrom-StringData cmdlets.
    $fileMetaData = [System.IO.Path]::Combine($sourceRootDir, 'templates.txt')
    if ([System.IO.File]::Exists($fileMetaData)) {
        $metaData.Add('properties', [System.Collections.Hashtable]::new())
        $metaData.Add('fonts', [System.Collections.Hashtable]::new())
        foreach ($line in [System.IO.File]::ReadAllLines($fileMetaData)) {
            [string]$line = $line.Trim().Trim(@('"', "'"))
            if ($line -and $line[0] -ne '#') {
                [string]$value = $line.Split('=')[1].Trim().Trim(@('"', "'"))
                [string]$name = $line.Split('=')[0].Trim().Trim(@('"', "'"))
                switch ($name) {
                    'font_primary' { $metaData.fonts.Add($name, $value) }
                    'font_secondary' { $metaData.fonts.Add($name, $value) }
                    'font_title' { $metaData.fonts.Add($name, $value) }
                    'font_popup' { $metaData.fonts.Add($name, $value) }
                    'font_editor' { $metaData.fonts.Add($name, $value) }
                    'font_hex' { $metaData.fonts.Add($name, $value) }
                    Default { $metaData.properties.Add($name, $value) }
                }
            }
        }
        if ($Accent -eq 'Purple') {
            $metaData.properties['title'] = $titleName; @(
                'highlight_bar_action_buttons', 'highlight_bar_main_buttons',
                'highlight_bar_tab_buttons', 'highlight_bar_tool_buttons',
                'highlight_visited_folder', 'text_bar_tab_selected',
                'text_button_inverse', 'text_edit_selection_foreground',
                'text_grid_primary_inverse', 'text_link_pressed',
                'text_popup_header', 'text_popup_primary_inverse',
                'text_popup_secondary_inverse', 'tint_bar_tab_icons',
                'tint_page_separator', 'tint_popup_icons', 'tint_progress_bar',
                'tint_scroll_thumbs', 'tint_tab_indicator_selected'
            ).ForEach({ $metaData.properties[$_] = $accentHex })
        }
    } else {
        [System.Console]::WriteLine("Cannot found: $fileMetaData.")
        exit 1
    }
    $sourceIconDir = [System.IO.Path]::Combine($sourceRootDir, 'icons')
    $iconConfigFile = [System.IO.Path]::Combine($sourceRootDir, 'icons.csv')
    if ([System.IO.File]::Exists($iconConfigFile)) {
        $metaData.Add('icons', [System.Collections.Hashtable]::new())
        $read = [System.IO.File]::ReadAllText($iconConfigFile)
        $data = ConvertFrom-Csv -InputObject $read -Delimiter ','
        for ($i = 0; $i -lt $data.Count; $i++) {
            $name = $data.name[$i]
            $size = $data.size[$i]
            $metaData.icons.Add($name, $size)
        }
    } else {
        [System.Console]::WriteLine("Cannot found: $iconConfigFile.")
        exit 1
    }
    if ($IsWindows -or $PSEdition -eq 'Desktop') {
        $rsvg_convert = [System.IO.Path]::Combine($ROOT_PATH, 'bin', 'rsvg-convert.exe')
        if ([System.IO.File]::Exists($rsvg_convert)) {
            $addPath = [System.IO.Path]::GetDirectoryName($rsvg_convert)
            $oldPath = [System.Environment]::GetEnvironmentVariable('Path')
            $newPath = ($oldPath.Split(';') -notlike $addPath) + $addPath -join ';'
            [System.Environment]::SetEnvironmentVariable('Path', $newPath)
        }
    }
    $svgTool = ('rsvg-convert', 'cairosvg').ForEach({ Get-Command -Name $_ -ea:0 })[0]
    if ($svgTool) {
        New-Alias -Name 'svg2png' -Value "$svgTool" -Description 'Convert svg to png'
    } else {
        [System.Console]::WriteLine("Need to install 'rsvg-convert' or 'cairosvg'.")
        exit 1
    }
}
process {
    [System.Console]::WriteLine("Building name '$BASE_NAME' with accent '$Accent'.")
    $buildRootDir = [System.IO.Path]::Combine($ROOT_PATH, 'build')
    $buildNameDir = [System.IO.Path]::Combine($buildRootDir, $BASE_NAME)
    $buildFontDir = [System.IO.Path]::Combine($buildNameDir, 'fonts')
    $buildIconDir = [System.IO.Path]::Combine($buildNameDir, 'drawable')
    if ([System.IO.Directory]::Exists($buildNameDir)) {
        [System.IO.Directory]::Delete($buildNameDir, $true)
    }
    foreach ($buildDir in $buildRootDir, $buildFontDir, $buildIconDir) {
        if (-not([System.IO.Directory]::Exists($buildDir))) {
            [System.IO.Directory]::CreateDirectory($buildDir) | Out-Null
        }
    }

    [System.Console]::WriteLine('Copying font files...')
    $sourceFontDir = [System.IO.Path]::Combine($sourceRootDir, 'fonts')
    foreach ($font in $metaData.fonts.keys) {
        if ($metaData.fonts[$font]) {
            $fontFileValue = $metaData.fonts[$font] -replace '\\', '/'
            $fontFileName = [System.IO.Path]::GetFileName($fontFileValue)
            $fontDirName = [System.IO.Path]::GetDirectoryName($fontFileValue)
            if ($fontFileValue.EndsWith('.ttf')) {
                if ($fontFileValue -ne "fonts/$fontDirName/$fontFileName") {
                    $fontFileValue = "fonts/$fontDirName/$fontFileName"
                }
                $fromDirPath = [System.IO.Path]::Combine($sourceFontDir, $fontDirName)
                $fromFilePath = [System.IO.Path]::Combine($fromDirPath, $fontFileName)
                if ([System.IO.File]::Exists($fromFilePath)) {
                    $metaData.properties[$font] = $fontFileValue
                    $destDirPath = [System.IO.Path]::Combine($buildFontDir, $fontDirName)
                    if (-not([System.IO.Directory]::Exists($destDirPath))) {
                        [System.IO.Directory]::CreateDirectory($destDirPath) | Out-Null
                    }
                    foreach ($itemFile in [System.IO.Directory]::EnumerateFiles($fromDirPath)) {
                        $itemName = [System.IO.Path]::GetFileName($itemFile)
                        $destFilePath = [System.IO.Path]::Combine($destDirPath, $itemName)
                        if (-not([System.IO.File]::Exists($destFilePath))) {
                            [System.IO.File]::Copy($itemFile, $destFilePath, $true)
                        }
                    }
                } else {
                    [System.Console]::WriteLine("Cannot found: $fromFilePath.")
                }
            } else {
                [System.Console]::WriteLine("Is not ttf format: $fontFileValue.")
            }
        } else {
            $metaData.properties.Remove($font)
        }
    }

    [System.Console]::WriteLine('Converting icon files...')
    foreach ($icon in $metaData.icons.keys) {
        $inputSvgFile = [System.IO.Path]::Combine($sourceIconDir, "$icon.svg")
        $outputPngFile = [System.IO.Path]::Combine($buildIconDir, "$icon.png")
        if ([System.IO.File]::Exists($inputSvgFile)) {
            $default_folder_icon = $null; $purple_folder_icon = $null
            if ($inputSvgFile.EndsWith('folder.svg') -and ($Accent -eq 'Purple')) {
                $default_folder_icon = [System.IO.File]::ReadAllText($inputSvgFile)
                $purple_folder_icon = $default_folder_icon -replace '\"#FF79C6\"', '"#BD93F9"'
                [System.IO.File]::WriteAllText($inputSvgFile, $purple_folder_icon)
            }
            $outputPngSize = $metaData.icons[$icon]
            if ($outputPngSize) { $resizes = '--width', "$outputPngSize", '--height', "$outputPngSize" }
            svg2png "$inputSvgFile" '--output' "$outputPngFile" $resizes
            if ($default_folder_icon) {
                [System.IO.File]::WriteAllText($inputSvgFile, $default_folder_icon)
            }
        } else {
            [System.Console]::WriteLine("Cannot found: $inputSvgFile.")
        }
    }

    [System.Console]::WriteLine('Generating properties file...')
    $buildPropXml = [System.IO.Path]::Combine($buildNameDir, 'properties.xml')
    try {
        $xmldoc = [System.Xml.XmlDocument]::new()
        $xmldec = $xmldoc.CreateXmlDeclaration('1.0', 'utf-8', $null)
        $xmldoc.AppendChild($xmldec) | Out-Null
        $elroot = $xmldoc.CreateElement('properties')
        $xmldoc.AppendChild($elroot) | Out-Null
        foreach ($item in $metaData.properties.keys) {
            if ($metaData.properties[$item]) {
                $child = $xmldoc.CreateElement('entry')
                $child.SetAttribute('key', $item)
                $child.InnerText = $metaData.properties[$item]
                $elroot.AppendChild($child) | Out-Null
            }
        }
    } finally {
        $xmldoc.Save($buildPropXml)
    }

    [System.Console]::WriteLine('Packaging theme files...')
    $filePack = $buildNameDir + '.mit'
    if ([System.IO.File]::Exists($filePack)) {
        [System.IO.File]::Delete($filePack)
    }
    try {
        [System.Reflection.Assembly]::LoadWithPartialName('System.IO.Compression.FileSystem') | Out-Null
        $level = [System.IO.Compression.CompressionLevel]::Optimal
        [System.IO.Compression.ZipFile]::CreateFromDirectory($buildNameDir, $filePack, $level, $false)
        $mode = [System.IO.Compression.ZipArchiveMode]::Update
        $stream = [System.IO.Compression.ZipFile]::Open($filePack, $mode)
        foreach ($file in 'screenshot.png', 'README.md', 'LICENSE') {
            $path = [System.IO.Path]::Combine($ROOT_PATH, $file)
            if ([System.IO.File]::Exists($path)) {
                [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile(
                    $stream, $path, $file, $level
                ) | Out-Null
            }
        }
    } finally {
        $stream.Dispose()
    }
    try {
        $filePackHash = $filePack + '.sha1'
        $alg = [System.Security.Cryptography.HashAlgorithm]::Create('SHA1')
        $rel = [System.IO.Path]::GetFileName($filePack)
        $fs = [System.IO.File]::OpenRead($filePack)
        $bytes = $alg.ComputeHash($fs).ForEach({ $_.ToString('x2') })
        $lines = [string]::Join('', $bytes) + ' *' + $rel
        [System.IO.File]::WriteAllText($filePackHash, $lines)
    } finally {
        $fs.Dispose()
        $alg.Dispose()
    }
}
end {
    if ($Force -and [System.IO.Directory]::Exists($buildNameDir)) {
        [System.IO.Directory]::Delete($buildNameDir, $true)
    }
    [System.Console]::WriteLine('Finished. packaged file results:')
    [System.IO.Directory]::GetFiles($buildRootDir, "$BASE_NAME.*")
}
