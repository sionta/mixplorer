param([string]$tagName)
$tagMessage = "Release version $($tagName -replace 'v','')"
$commitMessage = $([System.Guid]::NewGuid()).ToString().Split('-')[0]
$currentBranch = git rev-parse --abbrev-ref HEAD

git add .
git commit -m $commitMessage
git push origin $currentBranch
git tag -a $tagName -m $tagMessage
git push origin $tagName
