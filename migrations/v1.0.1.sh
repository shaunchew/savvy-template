#!/usr/bin/env bash
#
# v1.0.1.sh — retroactive fix for projects scaffolded from savvy-template v1.0.0.
#
# Fixes: .claude/settings.json — wraps the Stop hook in the {matcher, hooks: [...]}
# envelope. v1.0.0 shipped a bare hook object which causes Claude Code to skip
# the entire settings.json with:
#
#   hooks › Stop › 0 › hooks: Expected array, but received undefined
#
# Usage (from your project root):
#   curl -fsSL https://raw.githubusercontent.com/shaunchew/savvy-template/main/migrations/v1.0.1.sh | bash
#
# Or download and run locally:
#   curl -fsSL https://raw.githubusercontent.com/shaunchew/savvy-template/main/migrations/v1.0.1.sh -o /tmp/v1.0.1.sh
#   bash /tmp/v1.0.1.sh
#
# Idempotent — safe to re-run; exits cleanly if already fixed.

set -euo pipefail

say() { printf 'v1.0.1: %s\n' "$*" >&2; }
die() { say "error: $*"; exit 1; }

SETTINGS=".claude/settings.json"

[ -f "$SETTINGS" ] || die "$SETTINGS not found — run this from your project root."
command -v jq >/dev/null 2>&1 || die "jq not installed. Install with 'brew install jq' (macOS) or 'apt install jq' (linux)."

# Detect: is hooks.Stop[0] a bare hook object (has .type and .command, no .hooks)?
needs_fix=$(jq '
  (.hooks.Stop // [])
  | map(select(has("type") and has("command") and (has("hooks") | not)))
  | length > 0
' "$SETTINGS")

if [ "$needs_fix" != "true" ]; then
  say "already migrated — Stop hook is in matcher+hooks shape. No change."
  exit 0
fi

# Wrap the bare hook objects in the {matcher: "", hooks: [...]} envelope.
tmp="$(mktemp)"
jq '
  .hooks.Stop = [
    {
      "matcher": "",
      "hooks": .hooks.Stop
    }
  ]
' "$SETTINGS" > "$tmp"

mv "$tmp" "$SETTINGS"
say "fixed $SETTINGS — Stop hook wrapped in matcher+hooks envelope."
say "reload Claude Code (or restart the session) for the change to take effect."
