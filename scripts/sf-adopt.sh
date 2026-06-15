#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'
# sf-adopt.sh — adopt the sf engine into a project. Idempotent + reversible.
#
#   1. Seed the skeleton CREATE-IF-ABSENT (never overwrite); merge permissions.deny
#      additively and ensure the in-tree secret-scan floor guard exists.
#   2. DETACH any in-tree engine (legacy scaffold): remove the known engine files
#      individually (never `rm -rf` a tree), strip the 4 framework hook wirings from
#      settings.json (keep the secret-scan floor + any user hooks), back up to .savvy-old.
#   3. Enable the sf plugin at PROJECT scope (enabledPlugins in ./.claude/settings.json).
#
# Usage: sf-adopt.sh [--project DIR] [--yes]
#   --yes      proceed even if the git working tree is dirty / not a git repo
#   --project  target project dir (default: CWD)
#
# Safety: refuses a dirty git tree without --yes (so adoption is one reviewable, revertible
# commit); only ever creates files or removes the KNOWN framework engine set; backs up any
# settings.json it rewrites to settings.json.savvy-old.

PROJECT="$PWD"; ASSUME_YES=0
while [ $# -gt 0 ]; do
  case "$1" in
    --project) PROJECT="$2"; shift 2 ;;
    --yes|-y)  ASSUME_YES=1; shift ;;
    *) printf 'sf-adopt.sh: unknown arg: %s\n' "$1" >&2; exit 2 ;;
  esac
done
command -v jq >/dev/null 2>&1 || { printf 'sf-adopt.sh: jq required. Aborting.\n' >&2; exit 1; }

# --- locate the plugin root (and its embedded skeleton) ---
PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-}"
if [ -z "$PLUGIN_ROOT" ] || [ ! -d "$PLUGIN_ROOT/skeleton" ]; then
  # self-locate: this script lives at <plugin-root>/scripts/sf-adopt.sh
  PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
fi
SK="$PLUGIN_ROOT/skeleton"
[ -d "$SK" ] || { printf 'sf-adopt.sh: embedded skeleton not found at %s. Aborting.\n' "$SK" >&2; exit 1; }

PROJECT="$(cd "$PROJECT" && pwd)"
printf 'sf-adopt.sh: adopting into %s (skeleton: %s)\n' "$PROJECT" "$SK" >&2

# --- git-guard: refuse a dirty tree without --yes ---
if git -C "$PROJECT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  if [ "$ASSUME_YES" -eq 0 ] && [ -n "$(git -C "$PROJECT" status --porcelain)" ]; then
    printf 'sf-adopt.sh: working tree is dirty. Commit/stash first, or pass --yes. Aborting.\n' >&2
    exit 1
  fi
else
  if [ "$ASSUME_YES" -eq 0 ]; then
    printf 'sf-adopt.sh: %s is not a git repo (adoption would not be revertible). Pass --yes to proceed. Aborting.\n' "$PROJECT" >&2
    exit 1
  fi
fi

PROJ_NAME="$(basename "$PROJECT")"
created=(); skipped=(); detached=()

# --- 1. seed skeleton CREATE-IF-ABSENT ---
seed_file() { # $1=relpath under skeleton
  local rel="$1" src="$SK/$1" dst="$PROJECT/$1"
  if [ -e "$dst" ]; then skipped+=("$rel"); return 0; fi
  mkdir -p "$(dirname "$dst")"
  sed -e "s/__PROJECT_NAME__/$PROJ_NAME/g" \
      -e "s/__PROJECT_DESCRIPTION__/TODO: one-line project description./g" \
      "$src" > "$dst"
  [ "${rel##*.}" = "sh" ] && chmod +x "$dst"
  created+=("$rel")
}

# everything in the skeleton EXCEPT settings.json (handled specially below for merge)
while IFS= read -r src; do
  rel="${src#"$SK"/}"
  [ "$rel" = ".claude/settings.json" ] && continue
  seed_file "$rel"
done < <(find "$SK" -type f | sort)

# project work dirs (create-if-absent)
for d in specs docs scratchpads; do
  [ -d "$PROJECT/$d" ] || { mkdir -p "$PROJECT/$d"; created+=("$d/"); }
done

# --- 2. settings.json: seed-or-merge (permissions.deny additive + secret-scan floor) ---
SETTINGS="$PROJECT/.claude/settings.json"
mkdir -p "$PROJECT/.claude"
if [ ! -f "$SETTINGS" ]; then
  cp "$SK/.claude/settings.json" "$SETTINGS"
  created+=(".claude/settings.json")
else
  cp "$SETTINGS" "$SETTINGS.savvy-old"
  # union deny rules; ensure a PreToolUse:Bash secret-scan floor-guard entry exists.
  jq --slurpfile sk "$SK/.claude/settings.json" '
    .permissions.deny = ((.permissions.deny // []) + ($sk[0].permissions.deny // []) | unique)
    | (.hooks.PreToolUse // []) as $pre
    | if ([ $pre[]?.hooks[]?.command // "" ] | any(test("secret-scan\\.sh")))
      then .
      else .hooks.PreToolUse = ($pre + $sk[0].hooks.PreToolUse) end
  ' "$SETTINGS.savvy-old" > "$SETTINGS"
  detached+=("merged permissions.deny + ensured secret-scan floor (backup: settings.json.savvy-old)")
fi

# --- 3. DETACH in-tree engine, if present ---
detach_files() { # remove known engine files individually, then rmdir empty parents
  local removed=0
  # commands: the in-tree set lives under .claude/commands/sf/<name>.md — match the plugin's command names
  if [ -d "$PROJECT/.claude/commands/sf" ]; then
    for f in "$PLUGIN_ROOT"/commands/*.md; do
      local n; n="$(basename "$f")"
      [ -f "$PROJECT/.claude/commands/sf/$n" ] && { rm -f "$PROJECT/.claude/commands/sf/$n"; removed=$((removed+1)); }
    done
    rmdir "$PROJECT/.claude/commands/sf" 2>/dev/null || true
    rmdir "$PROJECT/.claude/commands" 2>/dev/null || true
  fi
  # skills: .claude/skills/_framework/<name>/SKILL.md
  if [ -d "$PROJECT/.claude/skills/_framework" ]; then
    for d in "$PLUGIN_ROOT"/skills/*/; do
      local n; n="$(basename "$d")"
      [ -f "$PROJECT/.claude/skills/_framework/$n/SKILL.md" ] && { rm -f "$PROJECT/.claude/skills/_framework/$n/SKILL.md"; rmdir "$PROJECT/.claude/skills/_framework/$n" 2>/dev/null || true; removed=$((removed+1)); }
    done
    rmdir "$PROJECT/.claude/skills/_framework" 2>/dev/null || true
    rmdir "$PROJECT/.claude/skills" 2>/dev/null || true
  fi
  # agents: the 3 canonical framework agents only
  for f in "$PLUGIN_ROOT"/agents/*.md; do
    local n; n="$(basename "$f")"
    [ -f "$PROJECT/.claude/agents/$n" ] && { rm -f "$PROJECT/.claude/agents/$n"; removed=$((removed+1)); }
  done
  # drop the framework-seeded .gitkeep so the now-empty agents/ dir can go
  if [ -d "$PROJECT/.claude/agents" ] && [ "$(ls -A "$PROJECT/.claude/agents" 2>/dev/null)" = ".gitkeep" ]; then
    rm -f "$PROJECT/.claude/agents/.gitkeep"
  fi
  rmdir "$PROJECT/.claude/agents" 2>/dev/null || true
  # framework hook scripts (keep secret-scan.sh — the floor guard)
  for n in format.sh bloat-check.sh session-start.sh session-end.sh; do
    [ -f "$PROJECT/.claude/hooks/$n" ] && { rm -f "$PROJECT/.claude/hooks/$n"; removed=$((removed+1)); }
  done
  echo "$removed"
}

n_removed="$(detach_files)"
if [ "${n_removed:-0}" -gt 0 ]; then
  detached+=("removed $n_removed in-tree engine file(s)")
fi

# strip the 4 framework hook wirings from settings.json (keep secret-scan + user hooks)
if [ -f "$SETTINGS" ] && grep -qE 'format\.sh|bloat-check\.sh|session-start\.sh|session-end\.sh' "$SETTINGS" 2>/dev/null; then
  [ -f "$SETTINGS.savvy-old" ] || cp "$SETTINGS" "$SETTINGS.savvy-old"
  jq '
    def strip($re):
      if type == "array"
      then [ .[] | (.hooks |= map(select((.command // "") | test($re) | not))) | select((.hooks | length) > 0) ]
      else . end;
    (.hooks.PostToolUse // empty) |= strip("/(format|bloat-check)\\.sh")
    | (.hooks.SessionStart // empty) |= strip("/session-start\\.sh")
    | (.hooks.Stop // empty)         |= strip("/session-end\\.sh")
    | .hooks |= with_entries(select((.value | length) > 0))
  ' "$SETTINGS" > "$SETTINGS.tmp" && mv "$SETTINGS.tmp" "$SETTINGS"
  detached+=("stripped framework hook wirings from settings.json")
fi

# --- 4. enable the plugin at PROJECT scope ---
if [ -f "$SETTINGS" ]; then
  jq '.enabledPlugins = ((.enabledPlugins // {}) + {"sf@savvy": true})' "$SETTINGS" > "$SETTINGS.tmp" && mv "$SETTINGS.tmp" "$SETTINGS"
  detached+=("enabled sf@savvy at project scope")
fi

# --- report ---
printf '\nsf-adopt.sh: DONE.\n' >&2
printf '  created : %s\n' "${created[*]:-(none)}" >&2
printf '  skipped : %s\n' "${skipped[*]:-(none)}" >&2
printf '  changed : %s\n' "${detached[*]:-(none)}" >&2
printf '\nNext: ensure the marketplace is known, then restart Claude Code:\n  /plugin marketplace add shaunchew/savvy-template\nReview the diff (git status) — everything is create-if-absent or backed up to .savvy-old.\n' >&2
