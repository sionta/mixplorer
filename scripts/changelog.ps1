[CmdletBinding(DefaultParameterSetName = 'stdout')]
param (
    [Parameter(ParameterSetName = 'stdout')]
    [Alias('i')][int]$Index = 0,
    [Parameter(ParameterSetName = 'stdout')]
    [Alias('n')][switch]$NoHeader,
    [Parameter(ParameterSetName = 'example')]
    [Alias('e')][switch]$Example
)
begin {
    $examples = @'
## [1.3.0] - 2023-09-03

### Added

- New `Purple` accent color.
- New filled icon in bookmarks.

### Fixed

<!-- is comments -->
- Button icons oversized.

[1.3.0]: <https://github.com/dracula/mixplorer/compare/v1.2.0...v1.3.0>

## [1.0.0] - 2021-10-22

_Initial commits._

[1.0.0]: <https://github.com/dracula/mixplorer/commits/v1.0.0>
'@
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
        "File could not be found '$srcFile'."
    }
}
process {
    if ($results) {
        $temp = [System.IO.Path]::GetTempFileName()
        [System.IO.File]::WriteAllText($temp, $results)
        $lines = [System.IO.File]::ReadAllLines($temp)
        [System.IO.File]::Delete($temp)
        $lines = $lines -notmatch '\<\!-[\W\w]*?-\>' # <!-- comments -->
        $head = $lines -match '^##\s\[([\d.]+)\]'    # ## [semver] - yyyy-mm-dd
        $foot = $lines -match '^\[([\d.]+)\]\:'      # [semver]: <url>
        if ($head[0] -and $foot[0]) {
            $words = [System.Collections.Generic.List[string[]]]::new()
            foreach ($line in $lines) {
                if ($line -eq $head[1]) { break }
                if ($line -eq $foot[0] -and $NoHeader) { break }
                if ($line -eq $head[0] -and $NoHeader) { continue }
                $words.Add($line)
            }
        } else {
            "Incorrect syntax, for example:"
            $examples
        }
    }
}
end {
    if ($words) {
        if (!$words[0]) { $words.RemoveAt(0) }
        if (!$words[-1]) { $words.RemoveAt($words.Count - 1) }
        $words
    }
    return
}

<# DUMMY REGEX
    # see: https://stackoverflow.com/a/42681472
    # tool: https://regex101.com/r/WHYshG/1
    currentDate = [string]::Format('{0:yyyy-MM-dd}', [datetime]::Now)
    patternDate = '\d{4}-\d{2}-\d{2}' # yyyy-mm-dd
#>
