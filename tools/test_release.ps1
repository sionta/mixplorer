param(
    [string]$tagName,
    [switch]$All
)

foreach ($tool in 'git','gh') {
    if (-not(Get-Command $tool -ea:0)) {
        Write-Host "Please install: $tool."
        exit 1
    }
}

# eg. ./tools/test_release.ps1 'v1.3.0'

$repository = 'sionta/mixplorer'

if ($All) {
    git tag | ForEach-Object { git tag -d $_ }
    git ls-remote --tags origin | ForEach-Object {
        $remoteTag = $_.Split('/')[-1]
        git push origin --delete $remoteTag
        gh release delete $remoteTag --repo $repository --yes --cleanup-tag
    }
    return
}

# $apiGithub = gh api repos/$repository/releases | ConvertFrom-Json
gh release delete $tagName --repo $repository --yes --cleanup-tag

$tagMessage = "Release version $($tagName -replace 'v','')"
$commitMessage = $([System.Guid]::NewGuid()).ToString().Split('-')[0]
$currentBranch = git rev-parse --abbrev-ref HEAD

# delete tag locally
$tagLocally = git tag -l | Where-Object { $_ -eq $tagName }
if ($tagLocally) { git tag -d $tagName }

# delete tag remotely
$tagRemotely = git ls-remote --tags origin $tagName
if ($tagRemotely) {git push origin --delete $tagName}

# push commit all and push tag name
git add .
git commit -m $commitMessage
git push origin $currentBranch
git tag -a $tagName -m $tagMessage
git push origin $tagName
