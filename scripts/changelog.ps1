[CmdletBinding()]
param (
    [Alias('d')][int]$Depth = 0,
    [Alias('n')][switch]$NoHeader

)
$srcFile = [System.IO.Path]::GetFullPath("$PSScriptRoot/../CHANGELOG.md")
if (!([System.IO.File]::Exists($srcFile))) {
    "File could not be found '$srcFile'."
    exit 1
}
$results = [System.Text.RegularExpressions.Regex]::Matches(
    [System.IO.File]::ReadAllText($srcFile),
    [System.String]::new('^##[^#\n]+([\W\w]*?)(^\[[\d.]+\]\:.+)'),
    [System.Text.RegularExpressions.RegexOptions]::Multiline
).Value[$Depth]
# $results = [System.Text.RegularExpressions.Regex]::Match(
#     [System.IO.File]::ReadAllText($srcFile),
#     [System.String]::new('^##[^#\n]+([\W\w]*?)^##[^#\n]+'),
#     [System.Text.RegularExpressions.RegexOptions]::Multiline
# )
if ($results) {
    $temp = [System.IO.Path]::GetTempFileName()
    [System.IO.File]::WriteAllText($temp, $results)
    $lines = [System.IO.File]::ReadAllLines($temp)
    $head = $lines -match '^##\s\[([\d.]+)\]\s-\s\d{4}-\d{2}-\d{2}'
    $foot = $lines -match '\[([\d.]+)\]\:'
    $words = [System.Collections.Generic.List[string]]::new()
    foreach ($line in $lines) {
        if ($line.Contains($head[1])) { break }
        if ($line.Contains($foot[0]) -and $NoHeader) { break }
        if ($line.Contains($head[0]) -and $NoHeader) { continue }
        $words.Add($line)
    }
    if ($words[-1].Length -eq 0) { $words.RemoveAt($words.Count - 1) }
    if ($NoHeader) {
        if ($words[0].Contains($head[0])) { $words.RemoveAt(0) }
        if ($words[0].Length -eq 0) { $words.RemoveAt(0) }
    }
    [System.IO.File]::Delete($temp)
    return $words
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
