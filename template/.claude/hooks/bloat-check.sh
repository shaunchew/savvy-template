#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'
# bloat-check.sh — enforces line budgets on framework docs. PostToolUse:Edit|Write.

command -v jq >/dev/null 2>&1 || exit 0

payload="$(cat)"
[ -z "$payload" ] && exit 0

file_path="$(printf '%s' "$payload" | jq -r '.tool_response.filePath // .tool_input.file_path // empty' 2>/dev/null || true)"
[ -z "$file_path" ] && exit 0
[ ! -f "$file_path" ] && exit 0

# Use basename and full path for matching.
base="$(basename "$file_path")"

soft=0
hard=0
suggestion=""

# Match in priority order — most specific first.
case "$file_path" in
  *.claude/pending-changes.md|*/.claude/pending-changes.md)
    # Special case: count entries, not lines.
    entries="$(grep -c '^> \*\*20' "$file_path" 2>/dev/null || true)"
    entries="${entries:-0}"
    if [ "$entries" -ge 50 ]; then
      printf 'bloat-check.sh: pending-changes.md at %s entries. Run /curate.\n' "$entries" >&2
    fi
    exit 0
    ;;
  *specs/*/*/spec.md)
    soft=100; hard=200
    suggestion="shrink to <=200 lines; move detail to plan.md"
    ;;
  *specs/*/*/plan.md)
    soft=150; hard=300
    suggestion="split into phase docs under specs/<id>/phases/"
    ;;
esac

# Fall back to basename for top-level docs.
if [ "$soft" -eq 0 ]; then
  case "$base" in
    AGENTS.md)
      soft=40; hard=60
      suggestion="split detail into docs/ or specs/"
      ;;
    CLAUDE.md)
      soft=10; hard=15
      suggestion="fold Claude-specific guidance into AGENTS.md"
      ;;
    constitution.md)
      soft=50; hard=80
      suggestion="promote section to docs/decisions/ as ADR"
      ;;
    ROADMAP.md)
      soft=80; hard=150
      suggestion="archive completed milestones to docs/history/"
      ;;
    HANDOVER.md)
      soft=30; hard=50
      suggestion="archive older handovers to docs/handovers/"
      ;;
  esac
fi

# Not a budgeted file.
[ "$soft" -eq 0 ] && exit 0

lines="$(wc -l < "$file_path" 2>/dev/null | tr -d ' ')"
lines="${lines:-0}"

if [ "$lines" -ge "$hard" ]; then
  printf 'bloat-check.sh: %s at %s lines (soft %s, hard %s). Consider extraction: %s. BLOCKING. Extract content before continuing.\n' \
    "$file_path" "$lines" "$soft" "$hard" "$suggestion" >&2
  exit 2
elif [ "$lines" -ge "$soft" ]; then
  printf 'bloat-check.sh: %s at %s lines (soft %s, hard %s). Consider extraction: %s\n' \
    "$file_path" "$lines" "$soft" "$hard" "$suggestion" >&2
fi

exit 0
