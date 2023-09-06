[CmdletBinding(DefaultParameterSetName = 'Header')]
param (
    [Parameter(ParameterSetName = 'Header')]
    [Alias('d')][int]$Depth = 0,
    [Parameter(ParameterSetName = 'Header')]
    [Alias('n')][switch]$NoHeader,
    [Parameter(ParameterSetName = 'Example')]
    [Alias('e')][switch]$Example
)

function example_changelog {
    'Add changes to CHANGELOG.md. For example:'; ''
    Write-Host -ForegroundColor Cyan @'
## [2.0.0] - 2020-02-20

_If you are upgrading: please see [`UPGRADING.md`](UPGRADING.md)._

### Removed

- **Breaking:** remove `write()` method from public API (`01e3a64`)

[2.0.0]: <https://github.com/owner/repo/tree/v2.0.0>

## [1.0.0] - 2010-01-10

_First release._

[1.0.0]: <https://github.com/owner/repo/tree/v1.0.0>
'@
    return
}

if ($Example) { return example_changelog }

$srcFile = [System.IO.Path]::GetFullPath("$PSScriptRoot/../CHANGELOG.md")
if (!([System.IO.File]::Exists($srcFile))) {
    "File could not be found '$srcFile'."
    example_changelog
    exit 1
}

function latest_changelog {
    [System.Text.RegularExpressions.Regex]::Matches(
        [System.IO.File]::ReadAllText($srcFile),
        [System.String]::new('^##[^#\n]+([\W\w]*?)\[([\d.]+)\]\:.+'),
        [System.Text.RegularExpressions.RegexOptions]::Multiline
    ).Value[$Depth]
    return
}

function noheader_changelog {
    $f = [System.IO.Path]::GetTempFileName()
    [System.IO.File]::WriteAllText($f, $(latest_changelog))
    $l = [System.IO.File]::ReadAllLines($f)
    [System.IO.File]::Delete($f)
    $h = $l -match '^##\s\[([\d.]+)\]\s-\s\d{4}-\d{2}-\d{2}'
    $e = $l -match '\[([\d.]+)\]\:'
    $w = [System.Collections.Generic.List[string]]::new()
    foreach ($i in $l) {
        if ($i.Contains($h)) { continue };
        if ($i.Contains($e)) { break };
        $w.Add($i)
    }
    if ($w[0].Length -eq 0) { $w.RemoveAt(0) }
    if ($w[-1].Length -eq 0) { $w.RemoveAt($w.Count - 1) }
    return $w
}

if ($NoHeader) {
    return noheader_changelog
} else {
    return latest_changelog
}

# OLDER
<# $ROOT_PATH = [System.IO.Path]::GetFullPath("$PSScriptRoot/..")
$inFileChangelog = [System.IO.Path]::Combine($ROOT_PATH, 'CHANGELOG.md')
if (!([System.IO.File]::Exists($inFileChangelog))) {
    "File could not be found '$inFileChangelog'."
    exit 1
}

[System.Console]::InputEncoding = [System.Console]::OutputEncoding = $OutputEncoding = [System.Text.UTF8Encoding]::new()
$pattern = @{ head = '^##\s\[([\d.]+)\]\s-\s\d{4}-\d{2}-\d{2}'; date = '\d{4}-\d{2}-\d{2}'; link = '\[([\d.]+)\]\:' }
$readLines = [System.IO.File]::ReadAllLines($inFileChangelog)
$headings = $readLines -match $pattern.head
$headLink = $readLines -match $pattern.link
$currentDate = [string]::Format('{0:yyyy-MM-dd}', [datetime]::Now)

if ($headings[0] -match $pattern.head) {
    $writeLines = [System.Collections.Generic.List[string]]::new()
    foreach ($line in $readLines) {
        if ($line.Contains($headings[1])) { break }
        if ($line.Contains($headings[0]) -and $NowDate) {
            $line = $line -replace $pattern.date, $currentDate
        }
        $writeLines.Add($line)
    }
    if ($writeLines[-1].Length -eq 0) { $writeLines.RemoveAt($writeLines.Count - 1) }
    if ($NoHeader) {
        if ($writeLines[0].Contains($headings[0])) { $writeLines.RemoveAt(0) }
        if ($writeLines[0].Length -eq 0) { $writeLines.RemoveAt(0) }
    } elseif ($headLink[0] -match $pattern.link) {
        $writeLines.Add($null); $writeLines.Add($headLink[0])
    }
    return $writeLines
} else {
    "Mismatched heading like '## [semver] - yyyy-MM-dd'."
    "example heading: ## [1.0.0] - $currentDate"
    exit 1
} #>
