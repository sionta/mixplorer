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
    [Alias('n')][string]$Name = 'Dracula',
    [ValidateSet('Pink', 'Purple')]
    [Alias('a')][string]$Accent = 'Pink'
)

if ($Name -notmatch '^Dracula') {
    $BASE_NAME = [System.IO.Path]::GetFileNameWithoutExtension($Name)
} else {
    $BASE_NAME = ($Name + '-' + $Accent).ToLower()
}

if ($Accent -eq 'Purple') {
    $accentHex, $titleName = '#BD93F9', 'Dracula Purple'
} else {
    $accentHex, $titleName = '#FF79C6', 'Dracula'
}

$ROOT_PATH = [System.IO.Path]::GetFullPath("$PSScriptRoot/..")
[System.IO.Directory]::SetCurrentDirectory($ROOT_PATH)

$iniData = [System.Collections.Hashtable]::new()
$iniFile = [System.IO.Path]::Combine($ROOT_PATH, 'res', 'config.ini')
if ([System.IO.File]::Exists($iniFile)) {
    if (-not $iniData['properties']) { $iniData['properties'] = @{} }
    $lines = [System.IO.File]::ReadAllLines($iniFile)
    foreach ($line in $lines.Trim()) {
        if ($line -and (-not $line.StartsWith('#'))) {
            $line = $line.Trim().Trim(@('"', "'"))
            if ($line -match '^\[(.*)\]$') {
                $section = $Matches[1]
                $iniData[$section] = @{}
            } elseif ($line -match '^(.*?)\s*=\s*(.*)$') {
                $name, $value = $Matches[1..2]
                # $name, $value = $Matches[1], $Matches[2]
                if ($section -match '^(icons|fonts)$') {
                    $iniData[$section][$name] = $value
                }
                if ($section -match '^(colors|settings)$') {
                    $iniData['properties'][$name] = $value
                    $iniData.Remove($section)
                }
            }
        }
    }
} else {
    [System.Console]::WriteLine("Cannot found '$iniFile'.")
    exit 1
}

if ($Accent -eq 'Purple' -and $iniData.properties) {
    $iniData.properties['title'] = $titleName
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
    ).ForEach({ $iniData.properties[$_] = $accentHex })
}

$tools = 'rsvg-convert', 'cairosvg'
if ($IsWindows -or $PSEdition -eq 'Desktop') {
    $rsvg_convert = [System.IO.Path]::Combine($ROOT_PATH, 'bin', 'rsvg-convert.exe')
    if ([System.IO.File]::Exists($rsvg_convert)) {
        $addPath = [System.IO.Path]::GetDirectoryName($rsvg_convert)
        $oldPath = [System.Environment]::GetEnvironmentVariable('Path')
        $newPath = ($oldPath.Split(';') -notlike $addPath) + $addPath -join ';'
        [System.Environment]::SetEnvironmentVariable('Path', $newPath)
    }
    $tools = $tools.ForEach({ $_ + '.exe' })
    $sep = ';'
} else {
    $sep = ':'
}
foreach ($path in $env:PATH -split $sep) {
    if ([System.IO.Directory]::Exists($path)) {
        foreach ($tool in $tools) {
            if ([System.IO.File]::Exists("$path/$tool")) {
                $svgTool = [System.IO.FileInfo]::new("$path/$tool")[0]
            }
        }
    }
}
if (-not $svgTool) {
    [System.Console]::WriteLine("Please install 'rsvg-convert' or 'cairosvg'.")
    exit 1
}

$BUILD_PATH = [System.IO.Path]::Combine($ROOT_PATH, 'build')
if (-not([System.IO.Directory]::Exists($BUILD_PATH))) {
    $null = [System.IO.Directory]::CreateDirectory($BUILD_PATH)
}
$BUILD_NAME = [System.IO.Path]::Combine($BUILD_PATH, $BASE_NAME)
if ([System.IO.Directory]::Exists($BUILD_NAME)) {
    $null = [System.IO.Directory]::CreateDirectory($BUILD_NAME)
}
$BUILD_ICON = [System.IO.Path]::Combine($BUILD_NAME, 'drawable')
$BUILD_FONT = [System.IO.Path]::Combine($BUILD_NAME, 'fonts')

foreach ($build in $BUILD_NAME, $BUILD_ICON, $BUILD_FONT) {
    if (-not([System.IO.Directory]::Exists($build))) {
        $null = [System.IO.Directory]::CreateDirectory($build)
    }
}

foreach ($key in $iniData.fonts.Keys) {
    $value = $iniData.fonts[$key]
    if ($value) {
        $value = $value -replace '\\', '/'
        $base, $name = $value.Split('/')[-2..-1]
        if ($value -ne "fonts/$base/$name") { $value = "fonts/$base/$name" }
        if ($value.EndsWith('.ttf')) {
            $iniData.properties[$key] = $value
            $fromdir = [System.IO.Path]::Combine($ROOT_PATH, 'res', 'fonts', $base)
            if ([System.IO.Directory]::Exists($fromdir)) {
                $fromfile = [System.IO.Path]::Combine($fromdir, $name)
                if ([System.IO.File]::Exists($fromfile)) {
                    $target_dir = [System.IO.Path]::Combine($BUILD_FONT, $base)
                    if (-not([System.IO.Directory]::Exists($target_dir))) {
                        $null = [System.IO.Directory]::CreateDirectory($target_dir)
                    }
                    $files = [System.IO.Directory]::EnumerateFiles($fromdir)
                    foreach ($oldfile in $files) {
                        $fn = [System.IO.Path]::GetFileName($oldfile)
                        $newfile = [System.IO.Path]::Combine($target_dir, $fn)
                        [System.IO.File]::Copy($oldfile, $newfile, $true)
                    }
                } else {
                    [System.Console]::WriteLine("File not found '$fromfile'.")
                }
            } else {
                [System.Console]::WriteLine("Directory not found '$fromdir'.")
            }
        } else {
            [System.Console]::WriteLine("Value '$value' is not .ttf format.")
        }
    } else {
        $iniData.properties.Remove($key)
    }
}


$SOURCE_ICON = [System.IO.Path]::Combine($ROOT_PATH, 'res', 'icons')
foreach ($key in $iniData.icons.Keys) {
    $outsize = $iniData.icons[$key]
    $svgfile = [System.IO.Path]::Combine($SOURCE_ICON, "$key.svg")
    $pngfile = [System.IO.Path]::Combine($BUILD_ICON, "$key.png")
    $options = '--format', 'png', '--output', $pngfile, $svgfile
    if ($outsize) { $options += '--height', $outsize, '--width', $outsize }
    if ([System.IO.File]::Exists($svgfile)) {
        if ($svgFile.EndsWith('folder.svg') -and ($Accent -eq 'Purple')) {
            $default = [System.IO.File]::ReadAllText($svgFile)
            $purples = $default -replace '#FF79C6', '#BD93F9'
            $tmpfile = [System.IO.Path]::GetTempFileName()
            [System.IO.File]::WriteAllText($tmpfile, $purples)
            $options = ($options -notlike $svgfile) + $tmpfile
        }
        & "$($svgTool.FullName)" $options
        if ($tmpfile -and [System.IO.File]::Exists($tmpfile)) {
            [System.IO.File]::Delete($tmpfile)
        }
    } else {
        [System.Console]::WriteLine("Cannot found: $svgFile.")
    }
}

$xmlFile = [System.IO.Path]::Combine($BUILD_NAME, 'properties.xml')
try {
    $xml = [System.Xml.XmlDocument]::new()
    $dec = $xml.CreateXmlDeclaration('1.0', 'utf-8', $null)
    $null = $xml.AppendChild($dec)
    $root = $xml.CreateElement('properties')
    $null = $xml.AppendChild($root)
    foreach ($key in $iniData.properties.Keys) {
        $value = $iniData.properties[$key]
        if ($value) {
            $child = $xml.CreateElement('entry')
            $child.SetAttribute('key', $key)
            $child.InnerText = $value
            $null = $root.AppendChild($child)
        }
    }
} finally {
    $xml.Save($xmlFile)
}

$zipFile = $BUILD_NAME + '.mit'
$shaFile = $zipFile + '.sha1'
if ([System.IO.File]::Exists($zipFile)) {
    [System.IO.File]::Delete($zipFile)
}
try {
    $null = [System.Reflection.Assembly]::LoadWithPartialName('System.IO.Compression.FileSystem')
    $level = [System.IO.Compression.CompressionLevel]::Optimal
    [System.IO.Compression.ZipFile]::CreateFromDirectory($BUILD_NAME, $zipFile, $level, $false)
    $mode = [System.IO.Compression.ZipArchiveMode]::Update
    $stream = [System.IO.Compression.ZipFile]::Open($zipFile, $mode)
    $fileIncludes = 'screenshot.png', 'README.md', 'LICENSE'
    foreach ($file in $fileIncludes) {
        $path = [System.IO.Path]::Combine($ROOT_PATH, $file)
        if ([System.IO.File]::Exists($path)) {
            $null = [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($stream, $path, $file, $level)
        }
    }
} finally {
    if ($stream) { $stream.Dispose() }
    if ([System.IO.File]::Exists($zipFile)) {
        try {
            $alg = [System.Security.Cryptography.HashAlgorithm]::Create('SHA1')
            $fs = [System.IO.File]::OpenRead($zipFile)
            $bytes = $alg.ComputeHash($fs).ForEach({ $_.ToString('x2') })
            $texts = [string]::Join('', $bytes) + ' *' + [System.IO.Path]::GetFileName($zipFile)
            [System.IO.File]::WriteAllText($shaFile, $texts)
        } finally {
            if ($fs) { $fs.Dispose() }
            if ($alg) { $alg.Dispose() }
        }
    }
}

# [System.IO.Directory]::GetFiles($BUILD_PATH, "$BASE_NAME.*")
# if ([System.IO.Directory]::Exists($BUILD_NAME)) {
#     [System.IO.Directory]::Delete($BUILD_NAME, $true)
# }
