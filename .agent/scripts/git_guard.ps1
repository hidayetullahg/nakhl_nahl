$ErrorActionPreference = 'Stop'

Write-Host 'GIT SAFETY CHECK'
$status = git status --porcelain
if ($status) {
  Write-Host 'WARNING: working tree contains existing changes.'
  git status --short
  Write-Host 'NO AUTOMATIC COMMIT WILL BE CREATED.'
  exit 5
}

Write-Host 'Working tree clean.'
exit 0
