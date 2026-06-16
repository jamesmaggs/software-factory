#!/usr/bin/env bash
# Deterministic linter for Agent Skills.
#
# Checks a SKILL.md (and its directory) against the mechanically-verifiable rules
# in Anthropic's Agent Skills spec and best-practices checklist: frontmatter
# limits, body length, reference nesting, path style, and a few high-signal
# heuristics. It does NOT judge writing quality or effectiveness -- that is
# skill-evaluator's job.
#
# Usage:  lint_skill.sh <path-to-skill-dir-or-SKILL.md> [--json]
# Exit:   0 = no errors (warnings allowed), 1 = errors found, 2 = unreadable.
#
# Depends only on bash, awk, grep, sed -- no Python, no network.

set -u

JSON=0
TARGET=""
for arg in "$@"; do
  case "$arg" in
    --json) JSON=1 ;;
    *) TARGET="$arg" ;;
  esac
done

if [ -z "$TARGET" ]; then
  echo "usage: lint_skill.sh <path-to-skill-dir-or-SKILL.md> [--json]" >&2
  exit 2
fi
if [ ! -e "$TARGET" ]; then
  echo "Path not found: $TARGET" >&2
  exit 2
fi

if [ -d "$TARGET" ]; then
  SKILL_DIR="$TARGET"
  SKILL_MD="$TARGET/SKILL.md"
else
  SKILL_MD="$TARGET"
  SKILL_DIR="$(dirname "$TARGET")"
fi
SKILL_NAME="$(basename "$SKILL_DIR")"

# ---- result accumulators (parallel arrays) ----
IDS=(); SEVS=(); PASS=(); MSGS=()
add(){ IDS+=("$1"); SEVS+=("$2"); PASS+=("$3"); MSGS+=("$4"); }
ok(){   add "$1" error 1 "${2:-}"; }
err(){  add "$1" error 0 "$2"; }
warn(){ add "$1" warning 0 "$2"; }

emit_and_exit(){
  errors=0; warns=0; passed=0; total=${#IDS[@]}
  for i in "${!IDS[@]}"; do
    if [ "${PASS[$i]}" = "1" ]; then passed=$((passed+1));
    elif [ "${SEVS[$i]}" = "error" ]; then errors=$((errors+1));
    else warns=$((warns+1)); fi
  done
  verdict="clean"
  [ $((errors+warns)) -gt 0 ] && verdict="pass-with-warnings"
  [ "$errors" -gt 0 ] && verdict="fail"

  if [ "$JSON" = "1" ]; then
    printf '{\n  "skill": "%s",\n  "checks": [\n' "$(esc "$SKILL_NAME")"
    for i in "${!IDS[@]}"; do
      sep=","; [ "$i" -eq $((total-1)) ] && sep=""
      p="false"; [ "${PASS[$i]}" = "1" ] && p="true"
      printf '    {"id": "%s", "severity": "%s", "passed": %s, "message": "%s"}%s\n' \
        "$(esc "${IDS[$i]}")" "${SEVS[$i]}" "$p" "$(esc "${MSGS[$i]}")" "$sep"
    done
    printf '  ],\n  "summary": {"errors": %s, "warnings": %s, "passed": %s, "total": %s},\n' \
      "$errors" "$warns" "$passed" "$total"
    printf '  "verdict": "%s"\n}\n' "$verdict"
  else
    echo "Linting skill: $SKILL_NAME"
    echo "==============================="
    for i in "${!IDS[@]}"; do
      if [ "${PASS[$i]}" = "1" ]; then tag="ok  ";
      elif [ "${SEVS[$i]}" = "error" ]; then tag="FAIL";
      else tag="warn"; fi
      if [ -n "${MSGS[$i]}" ]; then
        echo "  [$tag] ${IDS[$i]}: ${MSGS[$i]}"
      else
        echo "  [$tag] ${IDS[$i]}"
      fi
    done
    echo ""
    echo "Verdict: $(echo "$verdict" | tr '[:lower:]' '[:upper:]')  ($errors errors, $warns warnings, $passed/$total checks passed)"
  fi
  [ "$errors" -gt 0 ] && exit 1
  exit 0
}

esc(){ printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'; }
trim(){ printf '%s' "$1" | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//'; }
unquote(){ printf '%s' "$1" | sed -E "s/^([\"'])(.*)\\1$/\\2/"; }

# resolve a path relative to a base dir, normalizing .. via a subshell cd
resolve(){ # $1 = base dir, $2 = relative-or-absolute path
  local base="$1" p="$2" d b
  case "$p" in /*) d="$(dirname "$p")"; b="$(basename "$p")";;
                *) d="$base/$(dirname "$p")"; b="$(basename "$p")";; esac
  ( cd "$d" 2>/dev/null && printf '%s/%s\n' "$(pwd)" "$b" ) 2>/dev/null
}

# extract local .md link targets from a file (one per line, anchors stripped)
extract_md_links(){ # $1 = file
  grep -oE '\]\([^)]+\)' "$1" 2>/dev/null \
    | sed -E 's/^\]\(//; s/\)$//; s/#.*$//' \
    | while IFS= read -r t; do
        [ -z "$t" ] && continue
        case "$t" in *://*|mailto:*) continue;; esac
        case "$t" in *.md) printf '%s\n' "$t";; esac
      done
}

# ---- read file ----
if [ ! -f "$SKILL_MD" ]; then
  err "skill-md-exists" "No SKILL.md found at $SKILL_MD"
  emit_and_exit
fi

first_line="$(head -n1 "$SKILL_MD")"
if [ "$first_line" != "---" ]; then
  err "frontmatter" "SKILL.md has no YAML frontmatter block (--- ... ---)."
  emit_and_exit
fi
ok "frontmatter" "Frontmatter block present."

# closing fence line number
fm_end="$(awk 'NR>1 && $0=="---"{print NR; exit}' "$SKILL_MD")"
if [ -z "$fm_end" ]; then
  err "frontmatter" "Frontmatter opening --- has no closing ---."
  emit_and_exit
fi

FM="$(awk -v e="$fm_end" 'NR>1 && NR<e' "$SKILL_MD")"
BODY="$(awk -v e="$fm_end" 'NR>e' "$SKILL_MD")"

# ---- name ----
NAME="$(printf '%s\n' "$FM" | awk '/^name:/{sub(/^name:[[:space:]]*/,""); print; exit}')"
NAME="$(unquote "$(trim "$NAME")")"
if [ -z "$NAME" ]; then
  err "name-present" "Frontmatter is missing a non-empty name."
else
  ok "name-present"
  if [ "${#NAME}" -gt 64 ]; then err "name-length" "name is ${#NAME} chars; max is 64."; else ok "name-length"; fi
  if printf '%s' "$NAME" | grep -qE '^[a-z0-9]+(-[a-z0-9]+)*$'; then ok "name-charset"; else
    err "name-charset" "name must be lowercase a-z, 0-9 and single hyphens, no leading/trailing or consecutive hyphens: '$NAME'."; fi
  if printf '%s' "$NAME" | grep -qiE 'anthropic|claude'; then
    err "name-reserved" "name contains a reserved word (anthropic, claude)."; else ok "name-reserved"; fi
  if printf '%s' "$NAME" | grep -qE '<[^>]+>'; then err "name-no-xml" "name contains XML tags."; else ok "name-no-xml"; fi
  if [ "$NAME" = "$SKILL_NAME" ]; then ok "name-dir-match"; else
    err "name-dir-match" "name '$NAME' must match the skill directory name '$SKILL_NAME'."; fi
fi

# ---- description (with folded continuation lines) ----
DESC="$(printf '%s\n' "$FM" | awk '
  /^description:/ && !ind { line=$0; sub(/^description:[[:space:]]*/,"",line); val=line; ind=1; next }
  ind {
    if ($0 ~ /^[A-Za-z0-9_-]+:[[:space:]]/) { exit }
    t=$0; sub(/^[[:space:]]+/,"",t); val=val" "t
  }
  END{ print val }')"
DESC="$(unquote "$(trim "$DESC")")"
if [ -z "$DESC" ]; then
  err "desc-present" "Frontmatter is missing a non-empty description."
else
  ok "desc-present"
  if [ "${#DESC}" -gt 1024 ]; then err "desc-length" "description is ${#DESC} chars; max is 1024."; else ok "desc-length"; fi
  if printf '%s' "$DESC" | grep -qE '<[^>]+>'; then err "desc-no-xml" "description contains XML tags."; else ok "desc-no-xml"; fi
  # Only flag genuine first/second-person skill-speak. Bare "I"/"you" false-positive
  # on quoted user phrases (e.g. 'how do I do X'), so match verb phrases instead.
  if printf '%s' "$DESC" | grep -qiE "(^|[^a-z])(i can|i'll|i'm|i will|i help|i'd|i am|let me|you can use|you should use|use me to)([^a-z]|$)"; then
    warn "desc-third-person" "description may be written in first/second person (e.g. 'I can help you'). It is injected into the system prompt and should read in third person."
  else ok "desc-third-person"; fi
  if printf '%s' "$DESC" | grep -qiE 'use when|use this|when the user|when working|use it when|use whenever'; then
    ok "desc-when-cue"
  else
    warn "desc-when-cue" "description may not say WHEN to use the skill (no 'use when / when the user' cue). It should carry both what it does and when to trigger."
  fi
fi

# ---- body length ----
BODY_LINES="$(printf '%s\n' "$BODY" | wc -l | tr -d ' ')"
if [ "$BODY_LINES" -gt 500 ]; then
  warn "body-length" "SKILL.md body is $BODY_LINES lines; guidance is under 500. Split detail into reference files."
elif [ "$BODY_LINES" -ge 450 ]; then
  warn "body-length" "SKILL.md body is $BODY_LINES lines, approaching the 500-line guidance."
else
  ok "body-length" "Body is $BODY_LINES lines."
fi

# ---- windows paths ----
if printf '%s' "$BODY" | grep -qE '[A-Za-z0-9_.-]+\\[A-Za-z0-9_.\\-]+'; then
  warn "forward-slashes" "Body appears to contain Windows-style backslash paths. Use forward slashes everywhere."
else ok "forward-slashes"; fi

# ---- time-sensitive info ----
if printf '%s' "$BODY" | grep -qiE '(as of[[:space:]]+[0-9]{4}|before[[:space:]]+[a-z]+[[:space:]]+20[0-9][0-9]|after[[:space:]]+[a-z]+[[:space:]]+20[0-9][0-9]|(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)[a-z]*[[:space:]]+20[0-9][0-9])'; then
  warn "time-sensitive" "Body contains time-sensitive phrasing (a month/year or before/after a date). Move it into an 'old patterns' section so it does not go stale."
else ok "time-sensitive"; fi

# ---- references: existence, one-level-deep, TOC ----
TMP_BODY_MD="$(mktemp)"; printf '%s\n' "$BODY" > "$TMP_BODY_MD"
BODY_REFS=""           # newline-separated resolved paths linked from SKILL.md
MISSING=""; NESTED=""
SKILL_MD_RESOLVED="$(resolve "$SKILL_DIR" "$(basename "$SKILL_MD")")"

while IFS= read -r link; do
  [ -z "$link" ] && continue
  rp="$(resolve "$SKILL_DIR" "$link")"
  BODY_REFS="$BODY_REFS
$rp"
done <<EOF
$(extract_md_links "$TMP_BODY_MD")
EOF

while IFS= read -r link; do
  [ -z "$link" ] && continue
  rp="$(resolve "$SKILL_DIR" "$link")"
  if [ ! -f "$rp" ]; then
    MISSING="$MISSING $link"
    continue
  fi
  rlines="$(wc -l < "$rp" | tr -d ' ')"
  if [ "$rlines" -gt 100 ]; then
    if ! head -n 15 "$rp" | grep -qi 'contents'; then
      warn "ref-toc" "Reference '$link' is $rlines lines but has no table of contents near the top. Long reference files should list their contents."
    fi
  fi
  while IFS= read -r nlink; do
    [ -z "$nlink" ] && continue
    nrp="$(resolve "$(dirname "$rp")" "$nlink")"
    [ "$nrp" = "$SKILL_MD_RESOLVED" ] && continue
    case "$BODY_REFS" in *"$nrp"*) : ;; *) NESTED="$NESTED ${link}->${nlink}";; esac
  done <<EOF2
$(extract_md_links "$rp")
EOF2
done <<EOF3
$(extract_md_links "$TMP_BODY_MD")
EOF3
rm -f "$TMP_BODY_MD"

if [ -n "$MISSING" ]; then
  warn "ref-exists" "SKILL.md links to file(s) that do not exist:$MISSING"
else ok "ref-exists"; fi
if [ -n "$NESTED" ]; then
  warn "ref-one-level-deep" "Found nested references (a reference file linking to a file not linked from SKILL.md):$NESTED. Keep references one level deep."
else ok "ref-one-level-deep"; fi

# ---- generic file names ----
GENERIC="$(find "$SKILL_DIR" -name '*.md' 2>/dev/null | while IFS= read -r f; do
  b="$(basename "$f")"
  printf '%s\n' "$b" | grep -qiE '^(utils?|helpers?|tools?|doc[0-9]*|file[0-9]+|untitled|temp|misc)\.md$' && printf '%s ' "$b"
done)"
if [ -n "$GENERIC" ]; then
  warn "file-names" "Generic/uninformative file names found: $GENERIC. Name files by content so Claude can navigate by name."
else ok "file-names"; fi

emit_and_exit
