param([string]$tagName)

# delete_tag.ps1
if ($tagName) {
    $tagExistsLocally = git tag -l | Where-Object { $_ -eq $tagName }
    if ($tagExistsLocally) { git tag -d $tagName }
    $tagExistsRemotely = git ls-remote --tags origin $tagName
    if ($tagExistsRemotely) { git push origin --delete $tagName }
} else {
    git tag | ForEach-Object { git tag -d $_ }
    git ls-remote --tags origin | ForEach-Object {
        $remoteTag = $_.Split('/')[-1]
        git push origin --delete $remoteTag
    }
}

# push_tag.ps1
$tagMessage = "Release version $($tagName -replace 'v','')"
$commitMessage = $([System.Guid]::NewGuid()).ToString().Split('-')[0]
$currentBranch = git rev-parse --abbrev-ref HEAD
git add .
git commit -m $commitMessage
git push origin $currentBranch
git tag -a $tagName -m $tagMessage
git push origin $tagName
