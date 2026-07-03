#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'
# sf-eject.sh — cleanly REVERSE an adoption. The mirror image of sf-adopt.sh.
#
#   1. Disable the sf plugin at project scope (settings.json).
#   2. Strip the secret-scan floor wiring; quarantine the floor script if unedited.
#   3. Quarantine every seeded skeleton file whose content is still EXACTLY what
#      adopt seeded (provably framework boilerplate). Files you edited are KEPT
#      and reported — eject never removes your work.
#   4. Remove the framework's empty work dirs (specs/ docs/ scratchpads/) only if empty.
#   5. Optionally (--restore-settings) restore the pre-adopt settings.json.savvy-old.
#
# NOTHING is deleted: removed files are MOVED to .claude/.savvy-detached-<ts>/.
#
# Usage: sf-eject.sh [--project DIR] [--yes] [--restore-settings]

PROJECT="$PWD"; ASSUME_YES=0; RESTORE_SETTINGS=0
while [ $# -gt 0 ]; do
  case "$1" in
    --project) PROJECT="$2"; shift 2 ;;
    --yes|-y)  ASSUME_YES=1; shift ;;
    --restore-settings) RESTORE_SETTINGS=1; shift ;;
    *) printf 'sf-eject.sh: unknown arg: %s\n' "$1" >&2; exit 2 ;;
  esac
done
command -v jq >/dev/null 2>&1 || { printf 'sf-eject.sh: jq required. Aborting.\n' >&2; exit 1; }

# --- locate the plugin root (for the skeleton to compare seeds against) ---
PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-}"
if [ -z "$PLUGIN_ROOT" ] || [ ! -d "$PLUGIN_ROOT/skeleton" ]; then
  PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
fi
SK="$PLUGIN_ROOT/skeleton"
[ -d "$SK" ] || { printf 'sf-eject.sh: embedded skeleton not found at %s. Aborting.\n' "$SK" >&2; exit 1; }

PROJECT="$(cd "$PROJECT" && pwd)"
SETTINGS="$PROJECT/.claude/settings.json"

# --- guards: mirror adopt's (dirty tree, symlink, invalid JSON) ---
if git -C "$PROJECT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  if [ "$ASSUME_YES" -eq 0 ] && [ -n "$(git -C "$PROJECT" status --porcelain)" ]; then
    printf 'sf-eject.sh: working tree is dirty. Commit/stash first, or pass --yes. Aborting.\n' >&2
    exit 1
  fi
else
  if [ "$ASSUME_YES" -eq 0 ]; then
    printf 'sf-eject.sh: %s is not a git repo (eject would not be revertible). Pass --yes to proceed. Aborting.\n' "$PROJECT" >&2
    exit 1
  fi
fi
if [ -L "$SETTINGS" ]; then
  printf 'sf-eject.sh: settings.json is a symlink — refusing to rewrite it. Aborting.\n' >&2
  exit 1
fi
if [ -f "$SETTINGS" ] && ! jq -e . "$SETTINGS" >/dev/null 2>&1; then
  printf 'sf-eject.sh: settings.json is not valid JSON. Fix it first. Aborting.\n' >&2
  exit 1
fi

PROJ_NAME="$(basename "$PROJECT")"
PROJ_NAME_SED="$(printf '%s' "$PROJ_NAME" | sed -e 's/[\\/&]/\\&/g')"
QUARANTINE="$PROJECT/.claude/.savvy-detached-$(date +%Y%m%d-%H%M%S)"
removed=(); kept=(); changed=()

quarantine_file() { # $1 = path relative to $PROJECT; returns 1 if absent
  local rel="$1" dst
  [ -f "$PROJECT/$rel" ] || return 1
  dst="$QUARANTINE/$rel"
  mkdir -p "$(dirname "$dst")"
  mv "$PROJECT/$rel" "$dst"
}

# seeded_matches REL — does the project file still equal what adopt would seed?
seeded_matches() {
  local rel="$1" src="$SK/$1"
  [ -f "$src" ] || return 1
  sed -e "s/__PROJECT_NAME__/$PROJ_NAME_SED/g" \
      -e "s/__PROJECT_DESCRIPTION__/TODO: one-line project description./g" \
      "$src" | cmp -s - "$PROJECT/$rel"
}

# --- 1+2. settings.json: restore backup, or strip the framework's additions ---
if [ -f "$SETTINGS" ]; then
  if [ "$RESTORE_SETTINGS" -eq 1 ] && [ -f "$SETTINGS.savvy-old" ]; then
    quarantine_file ".claude/settings.json" || true
    mv "$SETTINGS.savvy-old" "$SETTINGS"
    changed+=("restored pre-adopt settings.json from .savvy-old (previous version quarantined)")
  else
    if ! jq '
      (if .enabledPlugins then .enabledPlugins |= with_entries(select(.key != "sf@savvy")) else . end)
      | (if (.enabledPlugins // {}) == {} then del(.enabledPlugins) else . end)
      | (if .hooks.PreToolUse then
           .hooks.PreToolUse |= [ .[] | (.hooks |= map(select((.command // "") | test("\\.claude/hooks/secret-scan\\.sh") | not))) | select((.hooks | length) > 0) ]
         else . end)
      | (if .hooks then .hooks |= with_entries(select((.value | length) > 0)) else . end)
      | (if (.hooks // {}) == {} then del(.hooks) else . end)
    ' "$SETTINGS" > "$SETTINGS.tmp"; then
      rm -f "$SETTINGS.tmp"
      printf 'sf-eject.sh: ERROR — failed to rewrite settings.json (left unchanged). Aborting.\n' >&2
      exit 1
    fi
    mv "$SETTINGS.tmp" "$SETTINGS"
    changed+=("disabled sf@savvy + stripped secret-scan floor wiring (framework deny rules left in place — remove manually if unwanted)")
  fi
fi

# --- 3. quarantine unedited seeded files; keep edited ones ---
while IFS= read -r src; do
  rel="${src#"$SK"/}"
  [ "$rel" = ".claude/settings.json" ] && continue
  if [ -f "$PROJECT/$rel" ]; then
    if seeded_matches "$rel"; then
      quarantine_file "$rel" && removed+=("$rel")
    else
      kept+=("$rel (you edited it)")
    fi
  fi
done < <(find "$SK" -type f | sort)

# framework bookkeeping files
for rel in .claude/.savvy-engine-version .claude/.savvy-update-cache; do
  quarantine_file "$rel" && removed+=("$rel") || true
done

# --- 4. remove now-empty framework work dirs ---
for d in specs docs scratchpads; do
  rmdir "$PROJECT/$d" 2>/dev/null && removed+=("$d/ (was empty)") || true
done
rmdir "$PROJECT/.claude/hooks" 2>/dev/null || true

# --- report ---
printf '\nsf-eject.sh: DONE.\n' >&2
printf '  removed (quarantined): %s\n' "${removed[*]:-(none)}" >&2
printf '  kept (your edits)    : %s\n' "${kept[*]:-(none)}" >&2
printf '  changed              : %s\n' "${changed[*]:-(none)}" >&2
if [ -d "$QUARANTINE" ]; then
  printf '\nEverything removed was MOVED to:\n  %s\nReview it, then delete the dir. ' "$QUARANTINE" >&2
fi
if [ -f "$PROJECT/.claude/config.toml" ] && grep -q '^\[framework\]' "$PROJECT/.claude/config.toml" 2>/dev/null; then
  printf '\nNOTE: .claude/config.toml still declares [framework] (you edited it, so it was kept) — plugin hooks will continue to treat this project as adopted until you remove that section.\n' >&2
fi
printf '\nFinally, uninstall the engine if no other project uses it: /plugin uninstall sf@savvy\n' >&2
