#!/usr/bin/env bash
set -u

printf '%s\n' 'GIT SAFETY CHECK'
status="$(git status --porcelain)"
if [[ -n "$status" ]]; then
  printf '%s\n' 'WARNING: working tree contains existing changes.'
  printf '%s\n' "$status"
  printf '%s\n' 'NO AUTOMATIC COMMIT WILL BE CREATED.'
  exit 5
fi

printf '%s\n' 'Working tree clean.'
exit 0
