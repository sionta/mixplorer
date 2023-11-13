param([string]$tagName)
$tagMessage = "Release version $($tagName -replace 'v','')"
$currentBranch = git rev-parse --abbrev-ref HEAD
git add .
git commit -m 'Add untracked files'
git push origin $currentBranch
git tag -a $tagName -m $tagMessage
git push origin $tagName
