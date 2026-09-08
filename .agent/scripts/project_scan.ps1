$ErrorActionPreference = 'Stop'

Write-Host 'NAKHL & NAHL PROJECT SCAN'
Write-Host '========================='

$dartFiles = Get-ChildItem -Path lib -Filter *.dart -Recurse
Write-Host "Dart files: $($dartFiles.Count)"
$totalLines = 0
foreach ($file in $dartFiles) { $totalLines += (Get-Content $file.FullName).Count }
Write-Host "Dart lines: $totalLines"

Write-Host 'SQL migrations:'
Get-ChildItem -Path supabase/migrations -Filter *.sql | Sort-Object Name | Select-Object -ExpandProperty Name

$tests = Get-ChildItem -Path test -Filter *_test.dart -Recurse
Write-Host "Tests: $($tests.Count)"

Write-Host 'Git status:'
git status --short
Write-Host 'Latest commits:'
git log --oneline -10

Write-Host 'Candidate duplicate project roots:'
Get-ChildItem -Path .. -Filter pubspec.yaml -Recurse -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName
