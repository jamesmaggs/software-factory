#!/usr/bin/env python3
"""Read `tessl eval view --json` on stdin; exit non-zero if any
with-skill scenario scores below the floor.

A scenario is run in two variants: `baseline` (no skill) and a with-skill
variant (e.g. `usage-spec`). We gate on the with-skill variants — that is
the behaviour the installed skill actually produces.

Usage: tessl eval view <id|--last> --json | _eval_score.py <floor>
"""
import json
import sys

floor = float(sys.argv[1]) if len(sys.argv) > 1 else 80.0
data = json.load(sys.stdin)
attrs = data.get("data", {}).get("attributes", data)
scenarios = attrs.get("scenarios", [])

rows = []
worst = 100.0
for s in scenarios:
    name = s.get("shortDescription") or s.get("id", "?")
    for sol in s.get("solutions", []):
        variant = sol.get("variant") or sol.get("label") or "?"
        if variant == "baseline":
            continue  # gate on with-skill behaviour, not the no-skill control
        results = sol.get("assessmentResults", [])
        got = sum(a.get("score", 0) for a in results)
        mx = sum(a.get("max_score", 0) for a in results)
        pct = 100.0 * got / mx if mx else 0.0
        worst = min(worst, pct)
        rows.append((pct, variant, name))

if not rows:
    print("  no with-skill eval results found", file=sys.stderr)
    sys.exit(2)

for pct, variant, name in rows:
    print(f"  {pct:5.1f}%  [{variant}]  {name}")
ok = worst >= floor
print(f"  worst with-skill score={worst:.1f}%  floor={floor:g}  {'PASS' if ok else 'FAIL'}")
sys.exit(0 if ok else 1)
