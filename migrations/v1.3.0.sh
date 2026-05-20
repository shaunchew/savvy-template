#!/usr/bin/env bash
#
# v1.3.0.sh — retroactive cleanup for projects scaffolded from savvy-template <= v1.2.0.
#
# Fixes: slash commands moved from .claude/commands/*.md into the namespaced
# .claude/commands/sf/*.md (invoked as /sf:<name>). A `copier update` adds the
# new sf/ files but may leave the old flat command files behind as orphans,
# which would still register as the un-prefixed /<name> commands and shadow the
# new namespaced ones. This script removes those orphaned flat files.
#
# An orphan is defined narrowly: a top-level .claude/commands/<name>.md that has
# a matching .claude/commands/sf/<name>.md sibling. Custom commands you authored
# at the top level (with no sf/ twin) are left untouched.
#
# Usage (from your project root):
#   curl -fsSL https://raw.githubusercontent.com/shaunchew/savvy-template/main/migrations/v1.3.0.sh | bash
#
# Or download and run locally:
#   curl -fsSL https://raw.githubusercontent.com/shaunchew/savvy-template/main/migrations/v1.3.0.sh -o /tmp/v1.3.0.sh
#   less /tmp/v1.3.0.sh   # inspect
#   bash /tmp/v1.3.0.sh
#
# Idempotent — safe to re-run; exits cleanly if there are no orphans.

set -euo pipefail

say() { printf 'v1.3.0: %s\n' "$*" >&2; }
die() { say "error: $*"; exit 1; }

CMD_DIR=".claude/commands"

[ -d "$CMD_DIR" ] || die "$CMD_DIR not found — run this from your project root."

if [ ! -d "$CMD_DIR/sf" ]; then
  die "$CMD_DIR/sf not found. Run 'copier update' first to pull the namespaced commands, then re-run this script."
fi

removed=0
for old in "$CMD_DIR"/*.md; do
  [ -e "$old" ] || continue            # no flat files at all
  name="$(basename "$old")"
  if [ -f "$CMD_DIR/sf/$name" ]; then
    rm -f "$old"
    say "removed orphaned flat command: $CMD_DIR/$name (now $CMD_DIR/sf/$name → /sf:${name%.md})"
    removed=$((removed + 1))
  else
    say "kept $CMD_DIR/$name — no sf/ twin, treated as a custom command."
  fi
done

if [ "$removed" -eq 0 ]; then
  say "already migrated — no orphaned flat commands found. No change."
  exit 0
fi

say "done. Removed $removed orphaned flat command file(s). Commands now invoke as /sf:<name>."
say "reload Claude Code (or restart the session) for the change to take effect."
