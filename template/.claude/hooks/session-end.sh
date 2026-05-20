#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'
# session-end.sh — surfaces /sf:handover, pending-changes, and /sf:lesson reminders. Stop hook.

# jq not strictly required (we don't parse stdin), but honor the graceful-degrade convention.
# Drain stdin so the caller doesn't block on a pipe.
cat >/dev/null 2>&1 || true

# Locate project root: walk up from CWD looking for .claude/. Fallback to CWD.
find_root() {
  local dir="$PWD"
  while [ "$dir" != "/" ]; do
    if [ -d "$dir/.claude" ]; then
      printf '%s' "$dir"
      return 0
    fi
    dir="$(dirname "$dir")"
  done
  printf '%s' "$PWD"
}

root="$(find_root)"

# 1. HANDOVER.md staleness check.
handover="$root/HANDOVER.md"
if [ -f "$handover" ]; then
  # mtime in epoch seconds — portable for macOS (stat -f %m) and Linux (stat -c %Y).
  if mtime="$(stat -f %m "$handover" 2>/dev/null)"; then
    :
  else
    mtime="$(stat -c %Y "$handover" 2>/dev/null || printf '0')"
  fi
  now="$(date +%s)"
  age=$(( now - mtime ))
  if [ "$age" -gt 3600 ]; then
    printf 'session-end.sh: HANDOVER.md not updated this session. Consider /sf:handover.\n' >&2
  fi
else
  printf 'session-end.sh: no HANDOVER.md found. Consider /sf:handover.\n' >&2
fi

# 2. pending-changes.md entry count.
pending="$root/.claude/pending-changes.md"
if [ -f "$pending" ]; then
  entries="$(grep -c '^> \*\*20' "$pending" 2>/dev/null || true)"
  entries="${entries:-0}"
  if [ "$entries" -gt 0 ]; then
    printf 'session-end.sh: %s pending change(s) awaiting /sf:curate.\n' "$entries" >&2
  fi
fi

# 3. /sf:lesson reminder: scan lessons.md for today's date heading.
lessons="$root/.claude/lessons.md"
today="$(date +%Y-%m-%d)"
if [ -f "$lessons" ]; then
  if ! grep -E "^## ${today}" "$lessons" >/dev/null 2>&1; then
    printf 'session-end.sh: no lesson recorded today. Consider /sf:lesson "...".\n' >&2
  fi
else
  printf 'session-end.sh: no lesson recorded today. Consider /sf:lesson "...".\n' >&2
fi

exit 0
