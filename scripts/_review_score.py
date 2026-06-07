#!/usr/bin/env python3
"""Read `tessl skill review --json` on stdin; exit non-zero if below threshold.

Usage: tessl skill review <dir> --json | _review_score.py <threshold>
"""
import json
import sys

threshold = float(sys.argv[1]) if len(sys.argv) > 1 else 90.0
data = json.load(sys.stdin)
score = data["review"]["reviewScore"]
ok = score >= threshold
print(f"  reviewScore={score}  threshold={threshold:g}  {'PASS' if ok else 'FAIL'}")
sys.exit(0 if ok else 1)
