[CmdletBinding(DefaultParameterSetName = 'output')]
param (
    [Parameter(ParameterSetName = 'output')]
    [Alias('i')][int]$Index = 0,
    [Parameter(ParameterSetName = 'output')]
    [Alias('n')][switch]$NoHeader,
    [Parameter(ParameterSetName = 'sample')]
    [Alias('e')][switch]$Example
)

if ($Example) { return $examples }

# [System.Console]::InputEncoding = [System.Console]::OutputEncoding = $OutputEncoding = [System.Text.UTF8Encoding]::new()
$srcFile = [System.IO.Path]::GetFullPath("$PSScriptRoot/../CHANGELOG.md")
if ([System.IO.File]::Exists($srcFile)) {
    $results = [System.Text.RegularExpressions.Regex]::Matches(
        [System.IO.File]::ReadAllText($srcFile),
        [string]'^##\s\[\d.+\][\n\W\w]*?\[[\d.]+\]\:.*[^\n]',
        [System.Text.RegularExpressions.RegexOptions]::Multiline
    ).Value[$Index]
} else {
    Write-Error "File could not be found '$srcFile'."
}

if ($results) {
    $mlines = $results -split "`n"
    $mlines = $mlines -notmatch '\<\!-[\W\w]*?-\>'    # <!-- comments -->
    $header = $mlines -match '^##\s\[([\d.]+)\]'       # ## [semver] - yyyy-mm-dd
    $footer = $mlines -match '^\[([\d.]+)\]\:'         # [semver]: <url>
    if ($header[0] -and $footer[0]) {
        foreach ($line in $mlines) {
            if ($line -eq $header[1]) { break }
            if ($line -eq $footer[0] -and $NoHeader) { break }
            if ($line -eq $header[0] -and $NoHeader) { continue }
            Write-Host $line
        }
    } else {
        Write-Error "Incorrect syntax, for example:`n"
        Write-Host $examples -ForegroundColor Green
        exit 1
    }
}

$examples = @'
## [1.3.0] - 2023-09-03

### Added

- New `Purple` accent color.
- New filled icon in bookmarks.

<!-- Markdown comment -->

### Fixed

- Button icons oversized.

[1.3.0]: <https://github.com/dracula/mixplorer/compare/v1.2.0...v1.3.0>

## [1.0.0] - 2021-10-22

_Initial commits._

[1.0.0]: <https://github.com/dracula/mixplorer/commits/v1.0.0>
'@

<# DUMMY REGEX
    # see: https://stackoverflow.com/a/42681472
    # tool: https://regex101.com/r/WHYshG/1
    currentDate = [string]::Format('{0:yyyy-MM-dd}', [datetime]::Now)
    patternDate = '\d{4}-\d{2}-\d{2}' # yyyy-mm-dd
#>
