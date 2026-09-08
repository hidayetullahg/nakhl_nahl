#!/usr/bin/env bash
set -u

printf '%s\n' 'NAKHL & NAHL PROJECT SCAN'
printf '%s\n' '========================='

dash_files=$(find lib -type f -name '*.dart' -print)
printf 'Dart files: '
printf '%s\n' "$dash_files" | sed '/^$/d' | wc -l
printf 'Dart lines: '
printf '%s\n' "$dash_files" | sed '/^$/d' | xargs -r cat | wc -l

printf '%s\n' 'SQL migrations:'
find supabase/migrations -maxdepth 1 -type f -name '*.sql' -printf '%f\n' 2>/dev/null | sort

printf 'Tests: '
find test -type f -name '*_test.dart' -print 2>/dev/null | wc -l

printf '%s\n' 'Git status:'
git status --short
printf '%s\n' 'Latest commits:'
git log --oneline -10

printf '%s\n' 'Candidate duplicate project roots:'
find .. -mindepth 1 -maxdepth 3 -type f -name pubspec.yaml -print 2>/dev/null | sort
