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
    [Alias('a')][string]$Accent = 'Pink'
)
begin {
    if ($Name) {
        [string]$BASE_NAME = [System.IO.Path]::GetFileNameWithoutExtension($Name)
    } else {
        [string]$BASE_NAME = 'dracula-' + $Accent.ToLower()
    }

    if ($Accent -eq 'Purple') {
        $accentHex = '#BD93F9'; $titleName = 'Dracula Purple'
    } else {
        $accentHex = '#FF79C6'; $titleName = 'Dracula';
    }

    $ROOT_PATH = [System.IO.Path]::GetFullPath("$PSScriptRoot/..")
    [System.IO.Directory]::SetCurrentDirectory($ROOT_PATH)

    $META_DATA = @{'properties' = @{}; 'fonts' = @{}; 'icons' = @{} }
    $sourcePath = [System.IO.Path]::Combine($ROOT_PATH, 'res')

    # This will validate the properties.txt file. This method is
    # the same as using the ConvertFrom-StringData cmdlets.
    $fileMetaData = [System.IO.Path]::Combine($sourcePath, 'properties.txt')
    if ([System.IO.File]::Exists($fileMetaData)) {
        foreach ($line in [System.IO.File]::ReadAllLines($fileMetaData)) {
            [string]$line = $line.Trim().Trim(@('"', "'"))
            if ($line -and $line[0] -ne '#') {
                [string]$value = $line.Split('=')[1].Trim().Trim(@('"', "'"))
                [string]$name = $line.Split('=')[0].Trim().Trim(@('"', "'"))
                switch ($name) {
                    'font_primary' { $META_DATA.fonts.Add($name, $value) }
                    'font_secondary' { $META_DATA.fonts.Add($name, $value) }
                    'font_title' { $META_DATA.fonts.Add($name, $value) }
                    'font_popup' { $META_DATA.fonts.Add($name, $value) }
                    'font_editor' { $META_DATA.fonts.Add($name, $value) }
                    'font_hex' { $META_DATA.fonts.Add($name, $value) }
                    Default { $META_DATA.properties.Add($name, $value) }
                }
            }
        }
        if ($Accent -eq 'Purple' -and $META_DATA.properties) {
            $META_DATA.properties['title'] = $titleName
            @(
                'highlight_bar_action_buttons', 'highlight_bar_main_buttons',
                'highlight_bar_tab_buttons', 'highlight_bar_tool_buttons',
                'highlight_visited_folder', 'text_bar_tab_selected',
                'text_button_inverse', 'text_edit_selection_foreground',
                'text_grid_primary_inverse', 'text_link_pressed',
                'text_popup_header', 'text_popup_primary_inverse',
                'text_popup_secondary_inverse', 'tint_bar_tab_icons',
                'tint_page_separator', 'tint_popup_icons', 'tint_progress_bar',
                'tint_scroll_thumbs', 'tint_tab_indicator_selected'
            ).ForEach({ $META_DATA.properties[$_] = $accentHex })
        }
    } else {
        [System.Console]::WriteLine("Cannot found: $fileMetaData.")
        exit 1
    }
    $sourceIconDir = [System.IO.Path]::Combine($sourcePath, 'icons')
    $iconConfigFile = [System.IO.Path]::Combine($sourcePath, 'icons.csv')
    if ([System.IO.File]::Exists($iconConfigFile)) {
        $read = [System.IO.File]::ReadAllText($iconConfigFile)
        $data = ConvertFrom-Csv -InputObject $read -Delimiter ','
        for ($i = 0; $i -lt $data.Count; $i++) {
            $name = [string]$data.name[$i]
            $size = [int]$data.size[$i]
            $META_DATA.icons.Add($name, $size)
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
        function svg2png([string]$i, [string]$o, [int]$h, [int]$w) {
            & "$svgTool" @($i, '--output', $o, '--height', $h, '--width', $w, '--format', 'png')
        }
    } else {
        [System.Console]::WriteLine("Need to install 'rsvg-convert' or 'cairosvg'.")
        exit 1
    }
}
process {
    [System.Console]::WriteLine("Building name '$BASE_NAME' with accent '$Accent'")

    $buildRootDir = [System.IO.Path]::Combine($ROOT_PATH, 'build')
    $buildNameDir = [System.IO.Path]::Combine($buildRootDir, $BASE_NAME)
    $buildFontDir = [System.IO.Path]::Combine($buildNameDir, 'fonts')
    $buildIconDir = [System.IO.Path]::Combine($buildNameDir, 'drawable')

    if ([System.IO.Directory]::Exists($buildNameDir)) {
        [System.IO.Directory]::Delete($buildNameDir, $true)
    }

    foreach ($buildDir in $buildRootDir, $buildFontDir, $buildIconDir) {
        if (-not([System.IO.Directory]::Exists($buildDir))) {
            $null = [System.IO.Directory]::CreateDirectory($buildDir)
        }
    }

    [System.Console]::WriteLine('Copying fonts...')
    $sourceFontDir = [System.IO.Path]::Combine($sourcePath, 'fonts')
    foreach ($font in $META_DATA.fonts.keys) {
        if ($META_DATA.fonts[$font]) {
            $fontValue = $META_DATA.fonts[$font] -replace '\\', '/'
            $fontName = $fontValue.Split('/')[-1]
            $fontDir = $fontValue.Split('/')[-2]
            if ($fontValue.EndsWith('.ttf')) {
                if ($fontValue -ne "fonts/$fontDir/$fontName") {
                    $fontValue = "fonts/$fontDir/$fontName"
                }
                $fromDirPath = [System.IO.Path]::Combine($sourceFontDir, $fontDir)
                $fromFileName = [System.IO.Path]::Combine($fromDirPath, $fontName)
                if ([System.IO.File]::Exists($fromFileName)) {
                    $META_DATA.properties[$font] = $fontValue
                    $destDirPath = [System.IO.Path]::Combine($buildFontDir, $fontDir)
                    if (-not([System.IO.Directory]::Exists($destDirPath))) {
                        $null = [System.IO.Directory]::CreateDirectory($destDirPath)
                    }
                    $itemFiles = [System.IO.Directory]::EnumerateFiles($fromDirPath)
                    foreach ($itemFile in $itemFiles) {
                        $itemName = [System.IO.Path]::GetFileName($itemFile)
                        $destFileName = [System.IO.Path]::Combine($destDirPath, $itemName)
                        if (-not([System.IO.File]::Exists($destFileName))) {
                            [System.IO.File]::Copy($itemFile, $destFileName, $true)
                        }
                    }
                } else {
                    [System.Console]::WriteLine("Cannot found '$fromFileName'.")
                }
            } else {
                [System.Console]::WriteLine("Is not ttf format '$fontValue'.")
            }
        } else {
            $META_DATA.properties.Remove($font)
        }
    }

    [System.Console]::WriteLine('Converting icons...')
    foreach ($icon in $META_DATA.icons.keys) {
        $svgFile = [System.IO.Path]::Combine($sourceIconDir, "$icon.svg")
        $pngFile = [System.IO.Path]::Combine($buildIconDir, "$icon.png")
        $outSize = [int]$META_DATA.icons[$icon]
        $options = @{'i' = "$svgFile"; 'o' = "$pngFile" }
        if ([System.IO.File]::Exists($svgFile)) {
            if ($outSize) { $options['h'] = $outSize; $options['w'] = $outSize }
            if ($svgFile.EndsWith('folder.svg') -and ($Accent -eq 'Purple')) {
                $default = [System.IO.File]::ReadAllText($svgFile)
                $purples = $default -replace '\"#FF79C6\"', '"#BD93F9"'
                $tmpfile = [System.IO.Path]::GetTempFileName()
                [System.IO.File]::WriteAllText($tmpfile, $purples)
                $options['i'] = "$tmpfile"
            }
            svg2png @options
            if ($tmpfile -and [System.IO.File]::Exists($tmpfile)) {
                [System.IO.File]::Delete($tmpfile)
            }
        } else {
            [System.Console]::WriteLine("Cannot found: $svgFile.")
        }
    }

    [System.Console]::WriteLine('Generating properties...')
    $buildPropXml = [System.IO.Path]::Combine($buildNameDir, 'properties.xml')
    try {
        $xmldoc = [System.Xml.XmlDocument]::new()
        $xmldec = $xmldoc.CreateXmlDeclaration('1.0', 'utf-8', $null)
        $null = $xmldoc.AppendChild($xmldec)
        $root = $xmldoc.CreateElement('properties')
        $null = $xmldoc.AppendChild($root)
        foreach ($item in $META_DATA.properties.keys) {
            if ($META_DATA.properties[$item]) {
                $child = $xmldoc.CreateElement('entry')
                $child.SetAttribute('key', $item)
                $child.InnerText = $META_DATA.properties[$item]
                $null = $root.AppendChild($child)
            }
        }
    } finally {
        $xmldoc.Save($buildPropXml)
    }

    [System.Console]::WriteLine('Packaging themes...')
    $zipFile = $buildNameDir + '.mit'
    $shaFile = $zipFile + '.sha1'
    if ([System.IO.File]::Exists($zipFile)) {
        [System.IO.File]::Delete($zipFile)
    }
    try {
        $null = [System.Reflection.Assembly]::LoadWithPartialName('System.IO.Compression.FileSystem')
        $level = [System.IO.Compression.CompressionLevel]::Optimal
        [System.IO.Compression.ZipFile]::CreateFromDirectory($buildNameDir, $zipFile, $level, $false)
        $mode = [System.IO.Compression.ZipArchiveMode]::Update
        $stream = [System.IO.Compression.ZipFile]::Open($zipFile, $mode)
        $fileIncludes = 'screenshot.png', 'README.md', 'LICENSE'
        foreach ($file in $fileIncludes) {
            $path = [System.IO.Path]::Combine($ROOT_PATH, $file)
            if ([System.IO.File]::Exists($path)) {
                $null = [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile(
                    $stream, $path, $file, $level)
            }
        }
    } finally {
        if ($stream) { $stream.Dispose() }
        if ([System.IO.File]::Exists($zipFile)) {
            [System.Console]::WriteLine('Calculating hashes...')
            try {
                $alg = [System.Security.Cryptography.HashAlgorithm]::Create('SHA1')
                $rel = [System.IO.Path]::GetFileName($zipFile)
                $fs = [System.IO.File]::OpenRead($zipFile)
                $bytes = $alg.ComputeHash($fs).ForEach({ $_.ToString('x2') })
                $lines = [string]::Join('', $bytes) + ' *' + $rel
                [System.IO.File]::WriteAllText($shaFile, $lines)
            } finally {
                if ($fs) { $fs.Dispose() }
                if ($alg) { $alg.Dispose() }
            }
        }
    }
}
end {
    [System.Console]::WriteLine('Packaged file results:')
    [System.IO.Directory]::GetFiles($buildRootDir, "$BASE_NAME.*")
    if ([System.IO.Directory]::Exists($buildNameDir)) {
        [System.IO.Directory]::Delete($buildNameDir, $true)
    }
}
