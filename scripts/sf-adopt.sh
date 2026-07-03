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
# Usage: sf-adopt.sh [--project DIR] [--yes] [--dry-run]
#   --yes      proceed even if the git working tree is dirty / not a git repo
#   --project  target project dir (default: CWD)
#   --dry-run  print exactly what would happen; change NOTHING
#
# Safety: refuses a dirty git tree without --yes (so adoption is one reviewable, revertible
# commit); only ever creates files or removes the KNOWN framework engine set; backs up any
# settings.json it rewrites to settings.json.savvy-old.

PROJECT="$PWD"; ASSUME_YES=0; DRY=0
while [ $# -gt 0 ]; do
  case "$1" in
    --project) PROJECT="$2"; shift 2 ;;
    --yes|-y)  ASSUME_YES=1; shift ;;
    --dry-run) DRY=1; shift ;;
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
# Escape sed-replacement metacharacters (&, \, delimiter) so a project dir like
# "app&api" cannot corrupt seeded file content.
PROJ_NAME_SED="$(printf '%s' "$PROJ_NAME" | sed -e 's/[\\/&]/\\&/g')"
created=(); skipped=(); detached=()

# --- pre-flight: an existing settings.json must be valid JSON, or we abort BEFORE
# touching anything (a mid-run jq failure would leave a half-adopted project). ---
if [ -L "$PROJECT/.claude/settings.json" ]; then
  printf 'sf-adopt.sh: %s/.claude/settings.json is a symlink. Adopt would sever it and replace it with a regular file (your link target, e.g. a dotfiles repo, would stop receiving changes). Replace the symlink with a real file first. Nothing was changed. Aborting.\n' "$PROJECT" >&2
  exit 1
fi
if [ -f "$PROJECT/.claude/settings.json" ] && ! jq -e . "$PROJECT/.claude/settings.json" >/dev/null 2>&1; then
  printf 'sf-adopt.sh: %s/.claude/settings.json is not valid JSON. Fix it first — nothing was changed. Aborting.\n' "$PROJECT" >&2
  exit 1
fi

# .claude/ being gitignored voids the "one revertible commit" guarantee — git never
# protects those files. Warn (detach still quarantines rather than deletes).
if git -C "$PROJECT" check-ignore -q .claude 2>/dev/null; then
  printf 'sf-adopt.sh: WARNING — .claude/ is gitignored in this project; git history will NOT protect files under it. Detached files are quarantined, not deleted, but consider un-ignoring .claude/.\n' >&2
fi

# --- 1. seed skeleton CREATE-IF-ABSENT ---
seed_file() { # $1=relpath under skeleton
  local rel="$1" src="$SK/$1" dst="$PROJECT/$1"
  if [ -e "$dst" ]; then skipped+=("$rel"); return 0; fi
  if [ "$DRY" -eq 1 ]; then created+=("$rel"); return 0; fi
  mkdir -p "$(dirname "$dst")"
  sed -e "s/__PROJECT_NAME__/$PROJ_NAME_SED/g" \
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
  if [ ! -d "$PROJECT/$d" ]; then
    [ "$DRY" -eq 0 ] && mkdir -p "$PROJECT/$d"
    created+=("$d/")
  fi
done

# --- 2. settings.json: seed-or-merge (permissions.deny additive + secret-scan floor) ---
SETTINGS="$PROJECT/.claude/settings.json"
[ "$DRY" -eq 0 ] && mkdir -p "$PROJECT/.claude"
if [ ! -f "$SETTINGS" ]; then
  if [ "$DRY" -eq 0 ]; then cp "$SK/.claude/settings.json" "$SETTINGS"; fi
  created+=(".claude/settings.json")
else
  # union deny rules; ensure a PreToolUse:Bash secret-scan floor-guard entry exists.
  merged_tmp="$(mktemp)"
  jq --slurpfile sk "$SK/.claude/settings.json" '
    .permissions.deny = ((.permissions.deny // []) + ($sk[0].permissions.deny // []) | unique)
    | (.hooks.PreToolUse // []) as $pre
    | if ([ $pre[]?.hooks[]?.command // "" ] | any(test("secret-scan\\.sh")))
      then .
      else .hooks.PreToolUse = ($pre + $sk[0].hooks.PreToolUse) end
  ' "$SETTINGS" > "$merged_tmp"
  # Idempotency: rewrite (and back up) ONLY when the merge changes something.
  # Compare canonically — deny is a set, so order-insensitive.
  canon() { jq -S '(.permissions.deny // []) |= sort' "$1"; }
  if [ "$(canon "$merged_tmp")" = "$(canon "$SETTINGS")" ]; then
    rm -f "$merged_tmp"
  elif [ "$DRY" -eq 1 ]; then
    rm -f "$merged_tmp"
    detached+=("WOULD merge permissions.deny + ensure secret-scan floor (backup to settings.json.savvy-old)")
  else
    # Keep-FIRST backup: .savvy-old is the true pre-adopt snapshot; a re-adopt
    # must never overwrite it with an already-framework-touched version.
    [ -f "$SETTINGS.savvy-old" ] || cp "$SETTINGS" "$SETTINGS.savvy-old"
    mv "$merged_tmp" "$SETTINGS"
    detached+=("merged permissions.deny + ensured secret-scan floor (backup: settings.json.savvy-old)")
  fi
fi

# --- 3. DETACH in-tree engine, if present (quarantine — NEVER delete) ---
# Detached files are MOVED to .claude/.savvy-detached-<timestamp>/<original path>,
# preserving any local edits even when .claude/ is gitignored, the tree is not a
# git repo, or a user file merely shares a name with an engine file. Deleting by
# name-match is not safe: we cannot prove the file is the pristine framework copy.
QUARANTINE="$PROJECT/.claude/.savvy-detached-$(date +%Y%m%d-%H%M%S)"

quarantine_file() { # $1 = path relative to $PROJECT; returns 1 if absent
  local rel="$1" dst
  [ -f "$PROJECT/$rel" ] || return 1
  [ "$DRY" -eq 1 ] && return 0
  dst="$QUARANTINE/$rel"
  mkdir -p "$(dirname "$dst")"
  mv "$PROJECT/$rel" "$dst"
}

do_rmdir() { [ "$DRY" -eq 1 ] && return 0; rmdir "$1"; }

detach_files() { # quarantine known engine files individually, then rmdir empty parents
  local removed=0
  # commands: the in-tree set lives under .claude/commands/sf/<name>.md — match the plugin's command names
  if [ -d "$PROJECT/.claude/commands/sf" ]; then
    for f in "$PLUGIN_ROOT"/commands/*.md; do
      local n; n="$(basename "$f")"
      quarantine_file ".claude/commands/sf/$n" && removed=$((removed+1))
    done
    do_rmdir "$PROJECT/.claude/commands/sf" 2>/dev/null || true
    do_rmdir "$PROJECT/.claude/commands" 2>/dev/null || true
  fi
  # skills: .claude/skills/_framework/<name>/SKILL.md
  if [ -d "$PROJECT/.claude/skills/_framework" ]; then
    for d in "$PLUGIN_ROOT"/skills/*/; do
      local n; n="$(basename "$d")"
      quarantine_file ".claude/skills/_framework/$n/SKILL.md" && { rmdir "$PROJECT/.claude/skills/_framework/$n" 2>/dev/null || true; removed=$((removed+1)); }
    done
    do_rmdir "$PROJECT/.claude/skills/_framework" 2>/dev/null || true
    do_rmdir "$PROJECT/.claude/skills" 2>/dev/null || true
  fi
  # agents: the 3 canonical framework agents only
  for f in "$PLUGIN_ROOT"/agents/*.md; do
    local n; n="$(basename "$f")"
    quarantine_file ".claude/agents/$n" && removed=$((removed+1))
  done
  # drop the framework-seeded .gitkeep so the now-empty agents/ dir can go
  if [ "$DRY" -eq 0 ] && [ -d "$PROJECT/.claude/agents" ] && [ "$(ls -A "$PROJECT/.claude/agents" 2>/dev/null)" = ".gitkeep" ]; then
    rm -f "$PROJECT/.claude/agents/.gitkeep"
  fi
  do_rmdir "$PROJECT/.claude/agents" 2>/dev/null || true
  # framework hook scripts (keep secret-scan.sh — the floor guard)
  for n in format.sh bloat-check.sh session-start.sh session-end.sh; do
    quarantine_file ".claude/hooks/$n" && removed=$((removed+1))
  done
  # legacy upgrade bookkeeping: a leftover baseline manifest would make the next
  # /sf:upgrade re-install the whole in-tree engine we just detached. Quarantine it.
  quarantine_file ".claude/.savvy-manifest.json" && removed=$((removed+1))
  quarantine_file ".claude/.savvy-update-cache" && removed=$((removed+1))
  echo "$removed"
}

n_removed="$(detach_files)"
if [ "${n_removed:-0}" -gt 0 ]; then
  if [ "$DRY" -eq 1 ]; then
    detached+=("WOULD move $n_removed in-tree engine file(s) to a .claude/.savvy-detached-<ts>/ quarantine")
  else
    detached+=("moved $n_removed in-tree engine file(s) to ${QUARANTINE#"$PROJECT"/}")
  fi
fi

# strip the 4 framework hook wirings from settings.json (keep secret-scan + user hooks).
# The pattern is anchored to .claude/hooks/ so a USER hook that happens to end in
# e.g. scripts/format.sh is never touched.
if [ "$DRY" -eq 1 ] && [ -f "$SETTINGS" ] && grep -qE '\.claude/hooks/(format|bloat-check|session-start|session-end)\.sh' "$SETTINGS" 2>/dev/null; then
  detached+=("WOULD strip framework hook wirings from settings.json")
elif [ -f "$SETTINGS" ] && grep -qE '\.claude/hooks/(format|bloat-check|session-start|session-end)\.sh' "$SETTINGS" 2>/dev/null; then
  [ -f "$SETTINGS.savvy-old" ] || cp "$SETTINGS" "$SETTINGS.savvy-old"
  if ! jq '
    def strip($re):
      if type == "array"
      then [ .[] | (.hooks |= map(select((.command // "") | test($re) | not))) | select((.hooks | length) > 0) ]
      else . end;
    (.hooks.PostToolUse // empty) |= strip("\\.claude/hooks/(format|bloat-check)\\.sh")
    | (.hooks.SessionStart // empty) |= strip("\\.claude/hooks/session-start\\.sh")
    | (.hooks.Stop // empty)         |= strip("\\.claude/hooks/session-end\\.sh")
    | .hooks |= with_entries(select((.value | length) > 0))
  ' "$SETTINGS" > "$SETTINGS.tmp"; then
    rm -f "$SETTINGS.tmp"
    printf 'sf-adopt.sh: ERROR — failed to strip framework hook wirings from settings.json (file left unchanged). Aborting.\n' >&2
    exit 1
  fi
  mv "$SETTINGS.tmp" "$SETTINGS"
  detached+=("stripped framework hook wirings from settings.json")
fi

# --- 4. enable the plugin at PROJECT scope (skip if already enabled — idempotent) ---
if [ "$DRY" -eq 1 ]; then
  if [ ! -f "$SETTINGS" ] || [ "$(jq -r '.enabledPlugins["sf@savvy"] // empty' "$SETTINGS" 2>/dev/null)" != "true" ]; then
    detached+=("WOULD enable sf@savvy at project scope")
  fi
elif [ -f "$SETTINGS" ] && [ "$(jq -r '.enabledPlugins["sf@savvy"] // empty' "$SETTINGS")" != "true" ]; then
  if ! jq '.enabledPlugins = ((.enabledPlugins // {}) + {"sf@savvy": true})' "$SETTINGS" > "$SETTINGS.tmp"; then
    rm -f "$SETTINGS.tmp"
    printf 'sf-adopt.sh: ERROR — failed to enable sf@savvy in settings.json (file left unchanged). Aborting.\n' >&2
    exit 1
  fi
  mv "$SETTINGS.tmp" "$SETTINGS"
  detached+=("enabled sf@savvy at project scope")
fi

# --- report ---
if [ "$DRY" -eq 1 ]; then
  printf '\nsf-adopt.sh: DRY-RUN — nothing was changed. Plan:\n' >&2
else
  printf '\nsf-adopt.sh: DONE.\n' >&2
fi
printf '  created : %s\n' "${created[*]:-(none)}" >&2
printf '  skipped : %s\n' "${skipped[*]:-(none)}" >&2
printf '  changed : %s\n' "${detached[*]:-(none)}" >&2
if [ -d "$QUARANTINE" ]; then
  printf '\nDetached engine files were MOVED (not deleted) to:\n  %s\nReview them (any local edits you made are preserved there), then delete the dir when satisfied.\n' "$QUARANTINE" >&2
fi
printf '\nNext: ensure the marketplace is known, then restart Claude Code:\n  /plugin marketplace add shaunchew/savvy-template\nReview the diff (git status). New files are create-if-absent; settings.json edits are backed up to settings.json.savvy-old; detached engine files are quarantined, never deleted.\n' >&2
