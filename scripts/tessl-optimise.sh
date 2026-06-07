#!/usr/bin/env bash
# Development helper (NOT a gate): run tessl's automated optimise loop, which
# rewrites the skill to raise its review score until it reaches the threshold
# or runs out of iterations. Fully automated (--yes auto-accepts rewrites);
# review the resulting diff before committing.
#
# Usage:
#   scripts/tessl-optimise.sh                 # all plugins
#   scripts/tessl-optimise.sh ./commit        # one plugin
set -euo pipefail

THRESHOLD="${TESSL_REVIEW_THRESHOLD:-90}"
MAX_ITERS="${TESSL_OPTIMISE_MAX_ITERATIONS:-5}"

if [ "$#" -gt 0 ]; then
  dirs="$*"
else
  dirs="$(find . -path '*/.tessl-plugin/plugin.json' -not -path './.git/*' \
            | sed 's#/\.tessl-plugin/plugin.json$##')"
fi

for dir in $dirs; do
  echo "── optimise: $dir (threshold ${THRESHOLD}, max ${MAX_ITERS} iterations) ──"
  tessl skill review "$dir" --optimize --threshold "$THRESHOLD" \
    --max-iterations "$MAX_ITERS" --yes
done

echo "Optimise complete — review the diff (git diff) before committing."
