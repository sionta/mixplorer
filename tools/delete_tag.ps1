param([string]$tagName)
if ($tagName) {
    # Check if the tag exists locally
    $tagExistsLocally = git tag -l | Where-Object { $_ -eq $tagName }
    # Delete Locally
    if ($tagExistsLocally) { git tag -d $tagName }
    # Check if the tag exists remotely
    $tagExistsRemotely = git ls-remote --tags origin $tagName
    # Delete Remotely
    if ($tagExistsRemotely) { git push origin --delete $tagName }
} else {
    # Delete all tags locally
    git tag | ForEach-Object { git tag -d $_ }
    # Delete all tags remotely
    git ls-remote --tags origin | ForEach-Object {
        $remoteTag = $_.Split('/')[-1]
        git push origin --delete $remoteTag
    }
}
