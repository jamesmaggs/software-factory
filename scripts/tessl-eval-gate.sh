#!/usr/bin/env bash
# Heavyweight quality gate: run scenario evals for each tessl plugin that has
# an evals/ directory, and fail if any with-skill scenario scores below
# TESSL_EVAL_FLOOR (default 80%). Intended for CI, not per-commit — evals run
# real agents in the cloud and take minutes.
#
# Usage: scripts/tessl-eval-gate.sh
set -euo pipefail

FLOOR="${TESSL_EVAL_FLOOR:-80}"
here="$(cd "$(dirname "$0")" && pwd)"

dirs="$(find . -path '*/.tessl-plugin/plugin.json' -not -path './.git/*' \
          | sed 's#/\.tessl-plugin/plugin.json$##')"

rc=0
ran=0
for dir in $dirs; do
  if [ ! -d "$dir/evals" ]; then
    echo "── eval gate: $dir has no evals/, skipping"
    continue
  fi
  ran=1
  echo "── eval gate: $dir (floor ${FLOOR}%) ──"
  # Run to completion (progress on stdout/stderr), then score the latest run.
  tessl eval run "$dir"
  if ! tessl eval view --last --json | python3 "$here/_eval_score.py" "$FLOOR"; then
    rc=1
  fi
done

if [ "$ran" -eq 0 ]; then
  echo "eval-gate: no plugins with evals/ found, nothing to run."
  exit 0
fi
if [ "$rc" -eq 0 ]; then echo "✓ eval gate passed"; else echo "✘ eval gate FAILED"; fi
exit "$rc"
