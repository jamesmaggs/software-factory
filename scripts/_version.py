#!/usr/bin/env python3
"""Version helpers for skill plugin.json files.

  get <plugin.json | ->     print the version (empty string if unreadable/empty;
                            `-` reads JSON from stdin, e.g. a `git show` pipe)
  bump-patch <plugin.json>  increment the patch component in place, print new version
  cmp <a> <b>               print 'gt' | 'eq' | 'lt'  (a compared to b)
"""
import json
import sys


def read_version(src):
    try:
        if src == "-":
            data = sys.stdin.read()
            return json.loads(data).get("version", "") if data.strip() else ""
        with open(src) as f:
            return json.load(f).get("version", "")
    except Exception:
        return ""


def bump_patch(path):
    with open(path) as f:
        d = json.load(f)
    parts = [int(x) for x in str(d["version"]).split(".")]
    while len(parts) < 3:
        parts.append(0)
    parts[2] += 1
    d["version"] = ".".join(str(p) for p in parts[:3])
    with open(path, "w") as f:
        f.write(json.dumps(d, indent=2) + "\n")
    return d["version"]


def cmp(a, b):
    pa = [int(x) for x in a.split(".")]
    pb = [int(x) for x in b.split(".")]
    while len(pa) < len(pb):
        pa.append(0)
    while len(pb) < len(pa):
        pb.append(0)
    return "gt" if pa > pb else ("lt" if pa < pb else "eq")


cmd = sys.argv[1] if len(sys.argv) > 1 else ""
if cmd == "get":
    print(read_version(sys.argv[2]))
elif cmd == "bump-patch":
    print(bump_patch(sys.argv[2]))
elif cmd == "cmp":
    print(cmp(sys.argv[2], sys.argv[3]))
else:
    sys.exit(f"unknown command: {cmd!r}")
