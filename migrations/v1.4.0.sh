#!/usr/bin/env bash
#
# v1.4.0.sh — bootstrap an existing project onto the manifest-driven upgrade system.
#
# Pre-v1.4.0 projects have no `.claude/.savvy-manifest.json` and no `/sf:upgrade`
# command, so they cannot use the new safe-upgrade flow until those land. This
# script installs exactly three things, fetching them from the framework remote:
#   1. .claude/commands/sf/upgrade.md           (the /sf:upgrade command)
#   2. .claude/skills/_framework/framework-upgrade/SKILL.md  (the upgrade skill)
#   3. .claude/.savvy-manifest.json             (the ownership BASELINE for the
#      project's CURRENT version — so the first /sf:upgrade refreshes files you
#      never edited and flags only the ones you did, instead of flagging everything)
#
# It does NOT modify any other file. After running this once, use /sf:upgrade for
# all future framework updates — it will refresh framework files safely and never
# touch your work.
#
# FROZEN ARTIFACT: this migration belongs to the v1.4.0 release, so every remote
# fetch below is pinned to the immutable `v1.4.0` tag, NEVER `main`. A later phase
# of the rearchitecture drops `template/` from `main`; a `main`-pinned fetch would
# then break permanently. The tag's tree carries both the template files and the
# migrations/baselines/ this script needs, frozen forever.
#
# Usage (from your project root):
#   curl -fsSL https://raw.githubusercontent.com/shaunchew/savvy-template/v1.4.0/migrations/v1.4.0.sh | bash
#
# Or download and read first:
#   curl -fsSL https://raw.githubusercontent.com/shaunchew/savvy-template/v1.4.0/migrations/v1.4.0.sh -o /tmp/v1.4.0.sh
#   less /tmp/v1.4.0.sh
#   bash /tmp/v1.4.0.sh
#
# Idempotent — safe to re-run; re-fetches the current files (which /sf:upgrade
# then reconciles against your local edits, if any).

set -euo pipefail

say() { printf 'v1.4.0: %s\n' "$*" >&2; }
die() { say "error: $*"; exit 1; }

# Pinned to the immutable release tag (see FROZEN ARTIFACT note above), never main.
TAG="v1.4.0"
RAW="https://raw.githubusercontent.com/shaunchew/savvy-template/$TAG/template"
BASE_RAW="https://raw.githubusercontent.com/shaunchew/savvy-template/$TAG/migrations/baselines"

[ -d ".claude" ] || die ".claude not found — run this from your project root."
command -v curl >/dev/null 2>&1 || die "curl not installed."

fetch() {
  # fetch <remote-relative-path> <local-dest>
  local rel="$1" dest="$2"
  mkdir -p "$(dirname "$dest")"
  if curl -fsSL "$RAW/$rel" -o "$dest"; then
    say "installed $dest"
  else
    die "failed to fetch $rel from remote."
  fi
}

fetch ".claude/commands/sf/upgrade.md" \
      ".claude/commands/sf/upgrade.md"
fetch ".claude/skills/_framework/framework-upgrade/SKILL.md" \
      ".claude/skills/_framework/framework-upgrade/SKILL.md"

# Install the BASELINE manifest matching this project's current version, so the
# first /sf:upgrade can tell "unedited, safe to refresh" from "you edited this".
# Baselines live at migrations/baselines/v<tag>.json and are named by GIT TAG.
#
# Pre-v1.4.0 config.toml stamps are COARSE ("1.0", "1.1", "1.3") and several tags
# can share one stamp, so the recorded stamp is NOT itself a baseline filename.
# Map the stamp to the git tag whose shipped file set it corresponds to. When a
# stamp is shared by multiple tags, pick the OLDEST: its baseline treats more files
# as possibly-edited (→ conflict, never auto-overwritten) rather than fewer, which
# is the conservative, safe lean. An unrecognized stamp resolves to nothing and
# falls through to conservative mode below.
baseline_tag_for() {
  case "$1" in
    1.0)   printf 'v1.0.0' ;;   # stamp shared by v1.0.0, v1.0.1, v1.1.0 → oldest
    1.1)   printf 'v1.2.0' ;;
    1.3)   printf 'v1.3.0' ;;
    1.4.0) printf 'v1.4.0' ;;
    *)     printf '' ;;
  esac
}

cur_version=""
if [ -f ".claude/config.toml" ]; then
  cur_version="$(grep -E '^version' ".claude/config.toml" | head -1 | sed -E 's/.*"([^"]+)".*/\1/')"
fi

installed_baseline=0
if [ -n "$cur_version" ]; then
  baseline_tag="$(baseline_tag_for "$cur_version")"
  if [ -n "$baseline_tag" ]; then
    mkdir -p ".claude"
    if curl -fsSL "$BASE_RAW/$baseline_tag.json" -o ".claude/.savvy-manifest.json" 2>/dev/null; then
      say "installed .claude/.savvy-manifest.json (baseline $baseline_tag for your stamped v$cur_version)."
      installed_baseline=1
    fi
  fi
fi

if [ "$installed_baseline" -eq 0 ]; then
  say "no baseline resolved for stamp v${cur_version:-unknown}; /sf:upgrade will run in conservative mode"
  say "(safe — it flags every differing framework file as a conflict rather than refreshing). No manifest installed."
fi

say "done. Reload Claude Code, then run /sf:upgrade to review and apply the rest of the update safely."
say "note: /sf:upgrade will treat any framework file you previously edited as a conflict (kept, written beside as *.savvy-new) — it will not overwrite your changes."
