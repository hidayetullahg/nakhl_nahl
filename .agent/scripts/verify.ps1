$ErrorActionPreference = 'Stop'

Write-Host 'NAKHL & NAHL QUALITY GATE'

flutter analyze
if ($LASTEXITCODE -ne 0) { Write-Host 'QUALITY GATE FAILED: flutter analyze'; exit 10 }

flutter test
if ($LASTEXITCODE -ne 0) { Write-Host 'QUALITY GATE FAILED: flutter test'; exit 20 }

# Read-only format check; do not rewrite files.
dart format --output=none --set-exit-if-changed lib/
if ($LASTEXITCODE -ne 0) { Write-Host 'QUALITY GATE FAILED: dart format'; exit 30 }

Write-Host 'QUALITY GATE PASSED'
exit 0
