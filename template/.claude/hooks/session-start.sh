#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'
# session-start.sh — deterministic context loading. SessionStart hook.
#   1. Detects .claude/intake-input.md and signals /intake.
#   2. Prints framework version + variant from .claude/config.toml.
#   3. Reports pending-changes count awaiting /curate.
#   4. Detects scratchpad-mode by CWD and reminds Claude framework machinery is inert.

# Drain stdin so the caller doesn't block.
cat >/dev/null 2>&1 || true

# Locate project root: walk up looking for .claude/. Fallback to CWD.
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

# 1. Intake-input detection — deterministic replacement for the CLAUDE.md instruction.
intake_input="$root/.claude/intake-input.md"
if [ -f "$intake_input" ]; then
  printf 'session-start.sh: .claude/intake-input.md detected. Run /intake --from-file .claude/intake-input.md to bootstrap.\n' >&2
fi

# 2. Framework version + variant banner.
config="$root/.claude/config.toml"
if [ -f "$config" ]; then
  version="$(grep -E '^version' "$config" | head -1 | sed -E 's/.*"([^"]+)".*/\1/')"
  variant="$(grep -E '^variant' "$config" | head -1 | sed -E 's/.*"([^"]+)".*/\1/')"
  if [ -n "${version:-}" ] || [ -n "${variant:-}" ]; then
    printf 'session-start.sh: savvy framework v%s · variant=%s\n' "${version:-unknown}" "${variant:-unknown}" >&2
  fi
fi

# 3. Pending-changes count.
pending="$root/.claude/pending-changes.md"
if [ -f "$pending" ]; then
  entries="$(grep -c '^> \*\*20' "$pending" 2>/dev/null || true)"
  entries="${entries:-0}"
  if [ "$entries" -gt 0 ]; then
    printf 'session-start.sh: %s pending change(s) awaiting /curate.\n' "$entries" >&2
  fi
fi

# 4. Scratchpad-mode detection. CWD inside scratchpads/<name>/ (not _archive).
case "$PWD" in
  */scratchpads/_archive*) ;;
  */scratchpads/*)
    sp_name="$(printf '%s' "$PWD" | sed -E 's|.*/scratchpads/([^/]+).*|\1|')"
    printf 'session-start.sh: scratchpad-mode active (%s). Framework machinery is inert; main-project files are read-only reference.\n' "$sp_name" >&2
    ;;
esac

exit 0
