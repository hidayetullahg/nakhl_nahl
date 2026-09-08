#!/usr/bin/env bash
set -u

printf '%s\n' 'NAKHL & NAHL QUALITY GATE'

flutter analyze
analyze_status=$?
if [[ $analyze_status -ne 0 ]]; then
  printf '%s\n' 'QUALITY GATE FAILED: flutter analyze'
  exit 10
fi

flutter test
test_status=$?
if [[ $test_status -ne 0 ]]; then
  printf '%s\n' 'QUALITY GATE FAILED: flutter test'
  exit 20
fi

# --output=none makes the check read-only; it does not rewrite the worktree.
dart format --output=none --set-exit-if-changed lib/
format_status=$?
if [[ $format_status -ne 0 ]]; then
  printf '%s\n' 'QUALITY GATE FAILED: dart format'
  exit 30
fi

printf '%s\n' 'QUALITY GATE PASSED'
exit 0
