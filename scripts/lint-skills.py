#!/usr/bin/env python3
"""Lint SKILL.md files against the Agent Skills spec (https://agentskills.io/specification).

Checks the structural rules a conformance checker should enforce:
  - YAML frontmatter delimited by `---`, followed by a non-empty body
  - name: required, 1-64 chars, ^[a-z0-9]+(-[a-z0-9]+)*$, must match the directory name
  - description: required, 1-1024 chars, non-empty
  - compatibility: if present, 1-500 chars
  - unknown top-level frontmatter keys           -> warning
  - body over 500 lines (spec recommendation)    -> warning

Usage:
  lint-skills.py [<SKILL.md | skill-dir> ...]   # defaults to every skills/*/SKILL.md

Exit status is non-zero if any skill has errors. Warnings never fail the run.
Dependency-free (no PyYAML): a minimal parser reads top-level frontmatter keys.
"""
import os
import re
import sys

KNOWN_KEYS = {"name", "description", "license", "compatibility", "metadata", "allowed-tools"}
NAME_RE = re.compile(r"^[a-z0-9]+(-[a-z0-9]+)*$")


def split_frontmatter(text):
    """Return (frontmatter_lines, body, error)."""
    lines = text.split("\n")
    if not lines or lines[0].strip() != "---":
        return None, None, "missing opening '---' frontmatter delimiter on line 1"
    for i in range(1, len(lines)):
        if lines[i].strip() == "---":
            return lines[1:i], "\n".join(lines[i + 1:]), None
    return None, None, "frontmatter is not closed with a '---' delimiter"


def parse_top_level(fm_lines):
    """Minimal frontmatter parse -> {key: value_text}. Nested blocks (e.g. metadata)
    are joined into value_text; good enough for presence and length checks."""
    entries, current = {}, None
    for line in fm_lines:
        stripped = line.strip()
        if not stripped or stripped.startswith("#"):
            continue
        if line[:1] not in (" ", "\t"):  # top-level key
            m = re.match(r"^([^:\s]+):\s?(.*)$", line)
            if not m:
                continue
            key, inline = m.group(1), m.group(2).strip()
            entries[key] = _unquote(inline)
            current = key
        elif current is not None:  # continuation / nested line
            entries[current] = (entries[current] + " " + stripped).strip()
    return entries


def _unquote(v):
    if len(v) >= 2 and v[0] == v[-1] and v[0] in "\"'":
        return v[1:-1]
    return v


def lint_skill(skill_md):
    """Return (errors, warnings) for one SKILL.md path."""
    errors, warnings = [], []
    try:
        text = open(skill_md, encoding="utf-8").read()
    except OSError as e:
        return [f"cannot read file: {e}"], []
    if not text.strip():
        return ["file is empty"], []

    fm_lines, body, err = split_frontmatter(text)
    if err:
        return [err], []
    fm = parse_top_level(fm_lines)

    # name
    name = fm.get("name")
    if name is None or name == "":
        errors.append("missing required field: name")
    else:
        if len(name) > 64:
            errors.append(f"name exceeds 64 characters ({len(name)})")
        if not NAME_RE.match(name):
            errors.append(
                f"name '{name}' is invalid: use lowercase a-z, 0-9 and single hyphens, "
                "no leading/trailing or consecutive hyphens"
            )
        parent = os.path.basename(os.path.dirname(os.path.abspath(skill_md)))
        if name != parent:
            errors.append(f"name '{name}' must match the parent directory name '{parent}'")

    # description
    desc = fm.get("description")
    if desc is None or desc.strip() == "":
        errors.append("missing required field: description")
    elif len(desc) > 1024:
        errors.append(f"description exceeds 1024 characters ({len(desc)})")

    # compatibility
    compat = fm.get("compatibility")
    if compat is not None and len(compat) > 500:
        errors.append(f"compatibility exceeds 500 characters ({len(compat)})")

    # unknown keys
    for key in fm:
        if key not in KNOWN_KEYS:
            warnings.append(f"unknown frontmatter key: {key}")

    # body
    if body is None or body.strip() == "":
        errors.append("SKILL.md has no body content after the frontmatter")
    elif body.count("\n") + 1 > 500:
        warnings.append(f"body is over 500 lines ({body.count(chr(10)) + 1}); consider splitting into reference files")

    return errors, warnings


def discover():
    found = []
    for root in ("skills",):
        for dirpath, _dirs, files in os.walk(root):
            if "SKILL.md" in files:
                found.append(os.path.join(dirpath, "SKILL.md"))
    return sorted(found)


def resolve(arg):
    if os.path.isdir(arg):
        return os.path.join(arg, "SKILL.md")
    return arg


def main(argv):
    targets = [resolve(a) for a in argv] or discover()
    if not targets:
        print("lint-skills: no SKILL.md files found")
        return 0

    failed = 0
    for skill_md in targets:
        errors, warnings = lint_skill(skill_md)
        for w in warnings:
            print(f"  ⚠ {skill_md}: {w}")
        if errors:
            failed += 1
            for e in errors:
                print(f"  ✘ {skill_md}: {e}")
        else:
            print(f"  ✓ {skill_md}")

    print()
    if failed:
        print(f"✘ {failed} of {len(targets)} skill(s) failed the lint")
        return 1
    print(f"✓ all {len(targets)} skill(s) pass the Agent Skills structural lint")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
