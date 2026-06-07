#!/usr/bin/env bash
# Auto-bump changed skills and publish those ahead of the registry.
#
# Rules:
#  - A change to a skill's published content (anything in the skill directory
#    except evals/) bumps that skill's PATCH version, UNLESS the version field
#    was already changed in this push (assumed a deliberate manual bump — left
#    as-is). Auto-bumps are committed back with [skip ci] and pushed.
#  - Then each skill is reconciled with the registry: repo version ahead ->
#    publish; equal -> nothing; registry ahead -> flagged as an error.
#
# Meant to run in CI on push to main, after the gates pass. Pushes made with
# CI's GITHUB_TOKEN do not trigger new runs, and [skip ci] is a second guard,
# so the bump commit cannot loop.
#
# Env:
#   BEFORE / AFTER   git SHAs bounding the push (default HEAD~1..HEAD)
#   DRY_RUN=1        print decisions; do not bump, commit, push, or publish
set -euo pipefail

BEFORE="${BEFORE:-HEAD~1}"
AFTER="${AFTER:-HEAD}"
DRY_RUN="${DRY_RUN:-}"
here="$(cd "$(dirname "$0")" && pwd)"

ver() { python3 "$here/_version.py" "$@"; }
plugin_name() { python3 -c "import json,sys;print(json.load(open(sys.argv[1]))['name'])" "$1"; }

# GitHub sends an all-zero BEFORE for a brand-new branch — fall back to the empty tree.
case "$BEFORE" in
  *[!0]*) : ;;
  *) BEFORE="$(git hash-object -t tree /dev/null)" ;;
esac

dirs="$(find . -path '*/.tessl-plugin/plugin.json' -not -path './.git/*' \
          | sed 's#/\.tessl-plugin/plugin.json$##')"

# ── Pass 1: auto-bump changed skills ──────────────────────────────────────────
bumped_any=0
for dir in $dirs; do
  pj="$dir/.tessl-plugin/plugin.json"
  # Published content only — evals/ changes do not trigger a bump/publish.
  changed="$(git diff --name-only "$BEFORE" "$AFTER" -- "$dir/" ":(exclude)$dir/evals" || true)"
  if [ -z "$changed" ]; then
    echo "── $dir: no published-content change"
    continue
  fi
  old_ver="$(git show "$BEFORE:$pj" 2>/dev/null | ver get - || true)"
  new_ver="$(ver get "$pj")"
  if [ -z "$old_ver" ]; then
    echo "── $dir: new skill (version $new_ver) — leaving as set"
  elif [ "$old_ver" != "$new_ver" ]; then
    echo "── $dir: version changed in push ($old_ver → $new_ver) — assuming manual bump"
  elif [ -n "$DRY_RUN" ]; then
    echo "── $dir: changed without version bump — would auto-bump patch from $new_ver"
  else
    b="$(ver bump-patch "$pj")"
    echo "── $dir: changed without version bump — auto-bumped $new_ver → $b"
    git add "$pj"
    bumped_any=1
  fi
done

if [ "$bumped_any" = 1 ]; then
  git commit -m "chore: bump skill versions [skip ci]" \
             -m "Automated patch bump for skills changed without a manual version bump."
  git push origin HEAD:main
fi

# ── Pass 2: reconcile with the registry and publish ───────────────────────────
fail=0
for dir in $dirs; do
  pj="$dir/.tessl-plugin/plugin.json"
  name="$(plugin_name "$pj")"
  repo="$(ver get "$pj")"
  info="$(tessl plugin info "$name" 2>&1 || true)"
  if printf '%s' "$info" | grep -qi "not found"; then
    reg=""
  else
    reg="$(printf '%s' "$info" | awk '/Latest Version/{print $3; exit}')"
  fi

  if [ -z "$reg" ]; then
    echo "── $name: not yet published → publish $repo"
    [ -n "$DRY_RUN" ] || tessl skill publish "$dir"
    continue
  fi

  case "$(ver cmp "$repo" "$reg")" in
    gt) echo "── $name: repo $repo > registry $reg → publish"
        [ -n "$DRY_RUN" ] || tessl skill publish "$dir" ;;
    eq) echo "── $name: up to date ($repo)" ;;
    lt) echo "::error::$name: registry ($reg) is AHEAD of repo ($repo) — version drift, needs attention"
        fail=1 ;;
  esac
done

exit "$fail"
