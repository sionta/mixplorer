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

if ($Accent -eq 'Purple') {
    $colorCode, $titleName = '#BD93F9', 'Dracula Purple'
} else {
    $colorCode, $titleName = '#FF79C6', 'Dracula'
}

if ($Name -eq 'Dracula') {
    $BASE_NAME = ($Name + '-' + $Accent).ToLower()
} else {
    $BASE_NAME = [System.IO.Path]::GetFileNameWithoutExtension($Name)
}

[System.IO.Directory]::SetCurrentDirectory('$PSScriptRoot/..')
$ROOT_PATH = [System.Environment]::CurrentDirectory
$BUILD_PATH = [System.IO.Path]::Combine($ROOT_PATH, 'build')
$SOURCE_PATH = [System.IO.Path]::Combine($ROOT_PATH, 'res')

$iniData = [System.Collections.Hashtable]::new()
$iniFile = [System.IO.Path]::Combine($SOURCE_PATH, 'props.cfg')
if ([System.IO.File]::Exists($iniFile)) {
    # $comments = @(';','#')
    $lines = [System.IO.File]::ReadAllLines($iniFile)
    if ($lines -match '^\s*\[(\w+)\]\s*$|^\s*(\w+)\s*=\s*(.+)\s*$') {
        foreach ($line in $lines.Trim()) {
            if ($line -and (-not $line.StartsWith('#'))) {
                $line = $line.Trim().Trim(@('"', "'"))
                if ($line -match '^\[(.*)\]$') {
                    $section = $Matches[1]
                    $iniData[$section] = @{}
                } elseif ($line -match '^(.*?)\s*=\s*(.*)$') {
                    $name, $value = $Matches[1..2]
                    if ($section -match '^(colors|settings)$') {
                        if (-not $iniData['properties']) {
                            $iniData['properties'] = @{}
                        }
                        $iniData['properties'][$name] = $value
                        $iniData.Remove($section)
                    } elseif ($section -match '^(icons|fonts)$') {
                        $iniData[$section][$name] = $value
                    }
                }
            }
        }
        if ($Accent -eq 'Purple' -and $iniData['properties']) {
            $iniData['properties']['title'] = "$titleName"
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
            ).ForEach({ $iniData['properties']["$_"] = "$colorCode" })
        }
    }
} else {
    [System.Console]::WriteLine("Cannot found '$iniFile'.")
    exit 1
}

# Get executable 'rsvg-convert' or 'cairosvg' file path
$svgTools = @('rsvg-convert', 'cairosvg')
$svgTool , $sep = $null, [System.IO.Path]::PathSeparator
if ($IsWindows -or $PSEdition -eq 'Desktop') {
    $svgTools = $svgTools.ForEach({ [System.IO.Path]::ChangeExtension($_, 'exe') })
    $rsvg_convert = [System.IO.Path]::Combine($ROOT_PATH, 'bin', 'rsvg-convert.exe')
    if ([System.IO.File]::Exists($rsvg_convert)) {
        # $svgTool = [System.IO.FileInfo]::new($rsvg_convert)
        $addPath = [System.IO.Path]::GetDirectoryName($rsvg_convert)
        $oldPath = [System.Environment]::GetEnvironmentVariable('Path')
        $newPath = ($oldPath -split $sep -notlike $addPath) + $addPath -join $sep
        [System.Environment]::SetEnvironmentVariable('Path', $newPath)
    }
}

foreach ($tool in $svgTools) {
    $paths = $env:PATH -split $sep
    foreach ($path in $paths) {
        $toolPath = [System.IO.Path]::Combine($path, $tool)
        if (-not $svgTool -and [System.IO.File]::Exists($toolPath)) {
            $svgTool = [System.IO.FileInfo]::new($toolPath)
        }
    }
}

if (-not $svgTool) {
    [System.Console]::WriteLine("Please install 'rsvg-convert' or 'cairosvg'.")
    exit 1
}

# Create build directory path
$BUILD_NAME = [System.IO.Path]::Combine($BUILD_PATH, $BASE_NAME)
$BUILD_ICON = [System.IO.Path]::Combine($BUILD_NAME, 'drawable')
$BUILD_FONT = [System.IO.Path]::Combine($BUILD_NAME, 'fonts')
if ([System.IO.Directory]::Exists($BUILD_NAME)) {
    [System.IO.Directory]::Delete($BUILD_NAME, $true)
}

$buildPaths = @($BUILD_PATH, $BUILD_NAME, $BUILD_ICON, $BUILD_FONT)
foreach ($build in $buildPaths) {
    if (-not([System.IO.Directory]::Exists($build))) {
        $null = [System.IO.Directory]::CreateDirectory($build)
    }
}

# Validate fonts
foreach ($key in $iniData['fonts'].Keys) {
    $value = $iniData['fonts'][$key] -replace '\\', '/'
    if (-not $value) { $iniData['properties'].Remove($key); continue }
    $pattern = '^fonts\/[A-Za-z0-9\s._-]+\/[A-Za-z0-9\s._-]+\.ttf$'
    if ($value -match $pattern) {
        # basedir: FontName (eg. /OpenSans/),
        # basename: FontName.ttf (eg. OpenSans-Regular.ttf)
        $basedir, $basename = $value.Split('/')[-2..-1]
        $fromdir = [System.IO.Path]::Combine($SOURCE_PATH, 'fonts', $basedir)
        if ([System.IO.Directory]::Exists($fromdir)) {
            $fromfile = [System.IO.Path]::Combine($fromdir, $basename)
            if ([System.IO.File]::Exists($fromfile)) {
                $iniData['properties'][$key] = $value
                $destdir = [System.IO.Path]::Combine($BUILD_FONT, $basedir)
                if (-not([System.IO.Directory]::Exists($destdir))) {
                    $null = [System.IO.Directory]::CreateDirectory($destdir)
                }
                foreach ($oldfile in [System.IO.Directory]::EnumerateFiles($fromdir)) {
                    $newfile = [System.IO.Path]::Combine(
                        $destdir, [System.IO.Path]::GetFileName($oldfile)
                    )
                    [System.IO.File]::Copy($oldfile, $newfile, $true)
                }
            } else {
                [System.Console]::WriteLine("File not found '$fromfile'.")
                $iniData['properties'].Remove($key)
            }
        } else {
            [System.Console]::WriteLine("Directory not found '$fromdir'.")
            $iniData['properties'].Remove($key)
        }
    } else {
        [System.Console]::WriteLine("The syntax must be like 'fonts/FontNameDir/FontName.tff'")
        [System.Console]::WriteLine('Example: fonts/opensans/opensans-regular.tff')
        $iniData['properties'].Remove($key)
    }
}

foreach ($key in $iniData['icons'].Keys) {
    $outsize = $iniData['icons'][$key]
    $svgfile = [System.IO.Path]::Combine($SOURCE_PATH, 'icons', "$key.svg")
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
        & "$svgTool" $options
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
    foreach ($key in $iniData['properties'].Keys) {
        $value = $iniData['properties'][$key]
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

$zipFile = [System.IO.Path]::ChangeExtension($BUILD_NAME, 'mit')
$shaFile = [System.IO.Path]::ChangeExtension($zipFile, 'sha1')
if ([System.IO.File]::Exists($zipFile)) {
    [System.IO.File]::Delete($zipFile)
}
try {
    $null = [System.Reflection.Assembly]::LoadWithPartialName('System.IO.Compression.FileSystem')
    $level = [System.IO.Compression.CompressionLevel]::Optimal
    [System.IO.Compression.ZipFile]::CreateFromDirectory(
        $BUILD_NAME, $zipFile, $level, $false)
    $mode = [System.IO.Compression.ZipArchiveMode]::Update
    $stream = [System.IO.Compression.ZipFile]::Open($zipFile, $mode)
    $fileIncludes = @('screenshot.png', 'README.md', 'LICENSE')
    foreach ($file in $fileIncludes) {
        $path = [System.IO.Path]::Combine($ROOT_PATH, $file)
        if ([System.IO.File]::Exists($path)) {
            $null = [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile(
                $stream, $path, $file, $level)
        }
    }
} finally {
    if ($stream) { $stream.Dispose() }
}

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
if ([System.IO.Directory]::Exists($BUILD_NAME)) {
    [System.IO.Directory]::Delete($BUILD_NAME, $true)
}
[System.IO.Directory]::GetFiles($BUILD_PATH, "$BASE_NAME.*")
