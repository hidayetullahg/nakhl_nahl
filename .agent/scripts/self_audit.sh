#!/usr/bin/env bash
set -u

printf '%s\n' 'NAKHL & NAHL SELF AUDIT'
status=0

printf '%s\n' '--- deleted files ---'
if git diff --name-status | awk '$1 ~ /^D/ {print; found=1} END {exit found ? 0 : 1}'; then
  printf '%s\n' 'SELF-AUDIT FAILED: deleted tracked file detected.'
  status=40
fi

printf '%s\n' '--- changed migrations ---'
changed_migrations="$(git diff --name-only -- supabase/migrations)"
if [[ -n "$changed_migrations" ]]; then
  printf '%s\n' "$changed_migrations"
  printf '%s\n' 'SELF-AUDIT FAILED: existing migration modified; use a new forward-only file.'
  status=41
fi

printf '%s\n' '--- possible secrets in diff ---'
if git diff --no-ext-diff | grep -Eiq "(^|[^A-Za-z])(api[_-]?key|secret|private[_-]?key|password|token)[[:space:]]*[:=][[:space:]]*[A-Za-z0-9_./+=-]{12,}"; then
  printf '%s\n' 'SELF-AUDIT FAILED: possible secret detected in diff.'
  status=42
fi

printf '%s\n' '--- changed files ---'
git diff --name-only
printf '%s\n' '--- untracked files ---'
git ls-files --others --exclude-standard

if [[ $status -eq 0 ]]; then
  printf '%s\n' 'SELF-AUDIT PASSED'
else
  printf '%s\n' "SELF-AUDIT FAILED: code $status"
fi
exit "$status"
