#!/usr/bin/env bash
# Heavyweight quality gate: run scenario evals for each tessl plugin that has
# an evals/ directory, and fail if any with-skill scenario scores below
# TESSL_EVAL_FLOOR (default 80%). Intended for CI, not per-commit — evals run
# real agents in the cloud and take minutes.
#
# `tessl eval run` is asynchronous (it starts the run and returns immediately),
# so this gate captures the run id and polls until the run completes before
# scoring it.
#
# Usage: scripts/tessl-eval-gate.sh
set -euo pipefail

FLOOR="${TESSL_EVAL_FLOOR:-80}"
# Pin the agent: the eval default model drifts (e.g. to GLM), and the gate
# should measure the skill against a known, consistent agent.
AGENT="${TESSL_EVAL_AGENT:-claude:claude-sonnet-4-6}"
POLL_INTERVAL="${TESSL_EVAL_POLL_INTERVAL:-15}"
POLL_MAX="${TESSL_EVAL_POLL_MAX:-80}"   # 80 * 15s = up to 20 min per plugin
here="$(cd "$(dirname "$0")" && pwd)"

uuid_re='[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}'

status_of() {
  # Extract .data.attributes.status from an eval view JSON on stdin (empty if unparseable).
  python3 -c 'import sys, json
try:
    print(json.load(sys.stdin)["data"]["attributes"].get("status", ""))
except Exception:
    print("")' 2>/dev/null || true
}

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
  echo "── eval gate: $dir (floor ${FLOOR}%, agent ${AGENT}) ──"

  out="$(tessl eval run "$dir" --agent "$AGENT" 2>&1)" || true
  echo "$out"
  id="$(printf '%s\n' "$out" | grep -oE "$uuid_re" | head -1 || true)"
  if [ -z "$id" ]; then
    echo "✘ could not determine eval run id for $dir"
    rc=1
    continue
  fi

  echo "  polling run $id for completion ..."
  run_status=""   # not `status`: that name is read-only in zsh
  view=""
  i=0
  while [ "$i" -lt "$POLL_MAX" ]; do
    view="$(tessl eval view "$id" --json 2>/dev/null || true)"
    run_status="$(printf '%s' "$view" | status_of)"
    case "$run_status" in
      completed) break ;;
      failed|errored|error|cancelled|canceled) break ;;
    esac
    i=$((i + 1))
    sleep "$POLL_INTERVAL"
  done

  if [ "$run_status" != "completed" ]; then
    echo "✘ eval run $id did not complete (status='${run_status:-timeout}')"
    rc=1
    continue
  fi

  if ! printf '%s' "$view" | python3 "$here/_eval_score.py" "$FLOOR"; then
    rc=1
  fi
done

if [ "$ran" -eq 0 ]; then
  echo "eval-gate: no plugins with evals/ found, nothing to run."
  exit 0
fi
if [ "$rc" -eq 0 ]; then echo "✓ eval gate passed"; else echo "✘ eval gate FAILED"; fi
exit "$rc"
