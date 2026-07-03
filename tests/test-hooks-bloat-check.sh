#!/usr/bin/env bash
# bloat-check.sh: budgets fire for the files they claim to watch (regression:
# an over-applied /sf: rename made the specs/ patterns dead — spec files are
# spec.md/plan.md, never sf:spec.md).
. "$(dirname "$0")/helpers.sh"

SB="$(make_sandbox)"
trap 'cleanup_sandbox "$SB"' EXIT

HOOK="$REPO_ROOT/hooks/bloat-check.sh"

run_hook() { # $1=file-path -> echoes exit code; stderr captured to $SB/err
  printf '{"tool_input":{"file_path":%s}}' "$(printf '%s' "$1" | jq -Rs .)" | bash "$HOOK" >/dev/null 2>"$SB/err"
  echo $?
}

mklines() { # $1=path $2=count
  mkdir -p "$(dirname "$1")"
  i=0; : > "$1"
  while [ "$i" -lt "$2" ]; do echo "line $i" >> "$1"; i=$((i + 1)); done
}

# The hook only acts inside ADOPTED projects — mark the fixture as one.
mkdir -p "$SB/proj/.claude"
printf '[framework]\nversion = "1.4.0"\n' > "$SB/proj/.claude/config.toml"

# Over-hard-budget spec.md blocks (exit 2) with a suggestion.
mklines "$SB/proj/specs/product/001-thing/spec.md" 250
assert_eq 2 "$(run_hook "$SB/proj/specs/product/001-thing/spec.md")" "spec.md over hard budget exits 2"
assert_contains "$SB/err" "Consider extraction" "block message includes suggestion"

# Under-soft-budget spec.md passes silently.
mklines "$SB/proj/specs/product/002-small/spec.md" 20
assert_eq 0 "$(run_hook "$SB/proj/specs/product/002-small/spec.md")" "small spec.md passes"

# plan.md budget fires too.
mklines "$SB/proj/specs/product/001-thing/plan.md" 400
assert_eq 2 "$(run_hook "$SB/proj/specs/product/001-thing/plan.md")" "plan.md over hard budget exits 2"

# AGENTS.md basename budget.
mklines "$SB/proj/AGENTS.md" 100
assert_eq 2 "$(run_hook "$SB/proj/AGENTS.md")" "AGENTS.md over hard budget exits 2"

# Unbudgeted file passes.
mklines "$SB/proj/src/main.py" 5000
assert_eq 0 "$(run_hook "$SB/proj/src/main.py")" "unbudgeted file ignored"

# pending-changes.md path (entry counting, never blocks).
mkdir -p "$SB/proj/.claude"
i=0; : > "$SB/proj/.claude/pending-changes.md"
while [ "$i" -lt 60 ]; do printf '> **2026-01-01** entry %s\n' "$i" >> "$SB/proj/.claude/pending-changes.md"; i=$((i + 1)); done
assert_eq 0 "$(run_hook "$SB/proj/.claude/pending-changes.md")" "pending-changes never blocks"
grep -q "curate" "$SB/err" && pass || fail "pending-changes over 50 entries should nudge /sf:curate"

# Resilience: garbage stdin.
printf 'not json' | bash "$HOOK" >/dev/null 2>&1
assert_exit_code 0 $? "garbage stdin exits 0"

# --- adoption gate: NON-adopted projects are never bloat-policed ------------------
mklines "$SB/other/AGENTS.md" 500
assert_eq 0 "$(run_hook "$SB/other/AGENTS.md")" "non-adopted project: no budget enforcement, exit 0"

# pending-changes: both entry formats are counted (blockquote legacy + heading current).
: > "$SB/proj/.claude/pending-changes.md"
i=0
while [ "$i" -lt 30 ]; do printf '> **2026-01-01 10:00** — old-style %s\n' "$i" >> "$SB/proj/.claude/pending-changes.md"; i=$((i + 1)); done
i=0
while [ "$i" -lt 30 ]; do printf '## 2026-01-02 11:00 · file.md · new-style %s\n' "$i" >> "$SB/proj/.claude/pending-changes.md"; i=$((i + 1)); done
run_hook "$SB/proj/.claude/pending-changes.md" >/dev/null
grep -q "60 entries" "$SB/err" && pass || fail "should count 60 entries across both formats, got: $(cat "$SB/err")"

finish
