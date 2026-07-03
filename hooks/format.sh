#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'
# format.sh — runs Prettier/Black on edited files. PostToolUse:Edit|Write.

# Degrade gracefully if jq is missing.
command -v jq >/dev/null 2>&1 || exit 0

# Read stdin once.
payload="$(cat)"
[ -z "$payload" ] && exit 0

# Prefer tool_response.filePath (post-edit canonical), fallback to tool_input.file_path.
file_path="$(printf '%s' "$payload" | jq -r '.tool_response.filePath // .tool_input.file_path // empty' 2>/dev/null || true)"

# Skip if missing or non-existent.
[ -z "$file_path" ] && exit 0
[ ! -f "$file_path" ] && exit 0

# Skip ignored directories.
case "$file_path" in
  */.git/*|*/node_modules/*|*/.venv/*|*/dist/*|*/build/*) exit 0 ;;
  .git/*|node_modules/*|.venv/*|dist/*|build/*) exit 0 ;;
esac

# Only act inside ADOPTED framework projects — the plugin's hooks fire in every
# project once the plugin is enabled, and reformatting a non-adopted project's
# files to prettier/black defaults is exactly the "mess up existing projects"
# failure this framework promises never to cause. Marker: .claude/config.toml
# with a [framework] section, found walking up from the edited file.
dir="$(cd "$(dirname "$file_path")" 2>/dev/null && pwd)" || exit 0
adopted=0
while [ -n "$dir" ] && [ "$dir" != "/" ]; do
  if [ -f "$dir/.claude/config.toml" ]; then
    grep -q '^\[framework\]' "$dir/.claude/config.toml" 2>/dev/null && adopted=1
    break
  fi
  [ "$dir" = "${HOME:-}" ] && break
  dir="$(dirname "$dir")"
done
[ "$adopted" -eq 1 ] || exit 0

# Determine extension (lowercase).
ext="${file_path##*.}"
ext="$(printf '%s' "$ext" | tr '[:upper:]' '[:lower:]')"

case "$ext" in
  js|jsx|ts|tsx|json|md|css|scss|html|yaml|yml)
    if command -v npx >/dev/null 2>&1; then
      # Check that prettier is resolvable (local or global). --no-install avoids surprise downloads.
      if npx --no-install prettier --version >/dev/null 2>&1; then
        if npx --no-install prettier --write "$file_path" >/dev/null 2>&1; then
          printf 'format.sh: prettier %s\n' "$file_path" >&2
        fi
      fi
    fi
    ;;
  py)
    if command -v black >/dev/null 2>&1; then
      if black --quiet "$file_path" >/dev/null 2>&1; then
        printf 'format.sh: black %s\n' "$file_path" >&2
      fi
    fi
    ;;
esac

exit 0
