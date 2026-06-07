#!/usr/bin/env bash
# Fast quality gate: lint + skill review for each tessl plugin.
# Fails if any skill's review score is below TESSL_REVIEW_THRESHOLD (default 90).
#
# Usage:
#   scripts/tessl-review-gate.sh                 # all plugins in the repo
#   scripts/tessl-review-gate.sh ./commit ./foo  # only the named plugin dirs
set -euo pipefail

THRESHOLD="${TESSL_REVIEW_THRESHOLD:-90}"
here="$(cd "$(dirname "$0")" && pwd)"

if [ "$#" -gt 0 ]; then
  dirs="$*"
else
  dirs="$(find . -path '*/.tessl-plugin/plugin.json' -not -path './.git/*' \
            | sed 's#/\.tessl-plugin/plugin.json$##')"
fi

if [ -z "$dirs" ]; then
  echo "review-gate: no tessl plugins found, nothing to check."
  exit 0
fi

rc=0
for dir in $dirs; do
  echo "── review gate: $dir (threshold ${THRESHOLD}) ──"
  tessl skill lint "$dir"
  if ! tessl skill review "$dir" --json | python3 "$here/_review_score.py" "$THRESHOLD"; then
    rc=1
  fi
done

if [ "$rc" -eq 0 ]; then echo "✓ review gate passed"; else echo "✘ review gate FAILED"; fi
exit "$rc"
