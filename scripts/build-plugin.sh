#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'
# build-plugin.sh — Phase 1 (authorship inverted).
#
# The Claude Code plugin payload at the REPO ROOT is now the SOLE authored source of
# truth for the engine:
#     /commands/<cmd>.md            (flat — namespaced /sf:<cmd> by the plugin name)
#     /skills/<name>/SKILL.md       (flat — discoverable depth)
#     /hooks/{*.sh,hooks.json}      (self-locating resolver)
#     /agents/<name>.md
#     /.claude-plugin/{plugin.json (name=sf), marketplace.json}
#
# This script no longer BUILDS the plugin (the plugin is the source). It does two jobs:
#   1. Stamps the single version source (VERSION) into plugin.json and asserts that
#      config.toml agrees — failing the build on a mismatch.
#   2. Reverse-generates the LEGACY in-tree engine under template/.claude/ FROM the root
#      payload (UN-flattening: skills/<n> -> skills/_framework/<n>, commands -> commands/sf),
#      so existing projects (and the curl-based migrations that fetch raw template/ URLs)
#      keep working until the Phase 3 cutover deletes template/. template/ is GENERATED,
#      never hand-edited.
#
# Run before publishing a release tag, or whenever the engine changes.

cd "$(dirname "$0")/.."
ROOT="$(pwd)"

# --- preconditions: the authored source must exist ---
for required in commands skills hooks agents .claude-plugin/plugin.json; do
  if [ ! -e "$ROOT/$required" ]; then
    printf 'build-plugin.sh: authored source missing: %s. Aborting.\n' "$required" >&2
    exit 1
  fi
done
command -v jq >/dev/null 2>&1 || { printf 'build-plugin.sh: jq required. Aborting.\n' >&2; exit 1; }

# --- 1. single version source: VERSION -> plugin.json, assert config.toml agrees ---
if [ ! -f "$ROOT/VERSION" ]; then
  printf 'build-plugin.sh: VERSION file missing. Aborting.\n' >&2; exit 1
fi
VERSION="$(tr -d '[:space:]' < "$ROOT/VERSION")"

tmp_pj="$(mktemp)"
jq --arg v "$VERSION" '.version = $v' "$ROOT/.claude-plugin/plugin.json" > "$tmp_pj" && mv "$tmp_pj" "$ROOT/.claude-plugin/plugin.json"
printf 'build-plugin.sh: stamped plugin.json version=%s from VERSION.\n' "$VERSION" >&2

cfg="$ROOT/template/.claude/config.toml"
if [ -f "$cfg" ]; then
  cfg_ver="$(grep -E '^version' "$cfg" 2>/dev/null | head -1 | sed -E 's/.*"([^"]+)".*/\1/' || true)"
  if [ -n "${cfg_ver:-}" ] && [ "$cfg_ver" != "$VERSION" ]; then
    printf 'build-plugin.sh: VERSION (%s) != template config.toml version (%s). Fix to match. Aborting.\n' "$VERSION" "$cfg_ver" >&2
    exit 1
  fi
fi

# --- 2. reverse-generate the legacy in-tree engine under template/.claude/ from root ---
T="$ROOT/template/.claude"
mkdir -p "$T/commands/sf" "$T/skills/_framework" "$T/hooks" "$T/agents"

# commands: flat root/commands/<cmd>.md -> template/.claude/commands/sf/<cmd>.md
# EXCEPT plugin-lifecycle commands (adopt/doctor/eject): they invoke
# ${CLAUDE_PLUGIN_ROOT}/scripts/* which does not exist in-tree — shipping them in
# the legacy mirror would give legacy projects commands that cannot work (and the
# legacy /sf:upgrade would then "helpfully" install them).
rm -rf "$T/commands/sf"; mkdir -p "$T/commands/sf"
for f in "$ROOT"/commands/*.md; do
  case "$(basename "$f")" in
    adopt.md|doctor.md|eject.md) continue ;;
  esac
  cp "$f" "$T/commands/sf/"
done

# skills: root/skills/<n>/SKILL.md -> template/.claude/skills/_framework/<n>/SKILL.md
# (project-adopt excluded — plugin-lifecycle, references ${CLAUDE_PLUGIN_ROOT}/scripts/*)
rm -rf "$T/skills/_framework"; mkdir -p "$T/skills/_framework"
for d in "$ROOT"/skills/*/; do
  n="$(basename "$d")"
  [ "$n" = "project-adopt" ] && continue
  mkdir -p "$T/skills/_framework/$n"
  cp "$d/SKILL.md" "$T/skills/_framework/$n/SKILL.md"
done

# hooks: root/hooks/*.sh -> template/.claude/hooks/ (NOT hooks.json — that is plugin-only;
# legacy projects wire hooks via .claude/settings.json instead).
for f in "$ROOT"/hooks/*.sh; do
  cp "$f" "$T/hooks/$(basename "$f")"
  chmod +x "$T/hooks/$(basename "$f")"
done

# agents: root/agents/*.md -> template/.claude/agents/ (preserve template's .gitkeep)
cp "$ROOT"/agents/*.md "$T/agents/"

printf 'build-plugin.sh: reverse-generated template/.claude/{commands,skills,hooks,agents} from root payload.\n' >&2

# --- 2b. regenerate the ownership manifest (legacy /sf:upgrade hashes) ---
# MUST run after the template regeneration above: the manifest hashes template/
# content, and hashing first would ship a manifest one iteration stale.
if [ -x "$ROOT/scripts/gen-manifest.sh" ]; then
  "$ROOT/scripts/gen-manifest.sh"
fi

# --- 3b. generate the embedded adoption skeleton under skeleton/ from template/ ---
# /sf:adopt seeds these create-if-absent into a project. Jinja is substituted to plain
# defaults; project-specific tokens are left as __PROJECT_NAME__/__PROJECT_DESCRIPTION__
# for sf-adopt to fill at seed time.
SK="$ROOT/skeleton"
rm -rf "$SK"; mkdir -p "$SK/.claude/hooks"
jinja_strip() { # $1=src $2=dst
  sed -E \
    -e 's/\{\{[[:space:]]*project_name[[:space:]]*\}\}/__PROJECT_NAME__/g' \
    -e 's/\{\{[[:space:]]*project_description[[:space:]]*\}\}/__PROJECT_DESCRIPTION__/g' \
    -e 's/\{\{[[:space:]]*variant[[:space:]]*\}\}/solo/g' \
    -e 's/\{\{[[:space:]]*github_username[[:space:]]*\}\}/shaunchew/g' \
    -e 's/\{\{[[:space:]]*include_[a-z_]+_integration[[:space:]]*\|[[:space:]]*lower[[:space:]]*\}\}/false/g' \
    "$1" > "$2"
}
for f in AGENTS.md CLAUDE.md constitution.md ROADMAP.md HANDOVER.md README.md; do
  [ -f "$ROOT/template/$f" ] && jinja_strip "$ROOT/template/$f" "$SK/$f"
done
for f in config.toml lessons.md pending-changes.md; do
  [ -f "$ROOT/template/.claude/$f" ] && jinja_strip "$ROOT/template/.claude/$f" "$SK/.claude/$f"
done
# Reduced floor-guard settings.json: keep permissions + ONLY the PreToolUse secret-scan
# floor guard (security survives even when the plugin is absent); other 4 hooks plugin-only.
# deny is unique-sorted so the seeded form is byte-stable under sf-adopt's
# merge (jq `unique` sorts — an unsorted seed would make re-adopt rewrite it).
jq '{permissions: (.permissions | .deny = ((.deny // []) | unique))} + {hooks: {PreToolUse: (.hooks.PreToolUse // [])}}' \
  "$ROOT/template/.claude/settings.json" > "$SK/.claude/settings.json"
# The floor guard needs its script in-tree.
cp "$ROOT/hooks/secret-scan.sh" "$SK/.claude/hooks/secret-scan.sh"
chmod +x "$SK/.claude/hooks/secret-scan.sh"
if grep -rE '\{\{|\{%' "$SK" 2>/dev/null | head -5; then
  printf 'build-plugin.sh: WARNING — residual Jinja in skeleton/.\n' >&2
fi
printf 'build-plugin.sh: generated embedded adoption skeleton under skeleton/.\n' >&2

# Ship the manifest with the plugin so an installed engine can resolve legacy upgrades.
if [ -f "$T/.savvy-manifest.json" ]; then
  cp "$T/.savvy-manifest.json" "$ROOT/.claude-plugin/.savvy-manifest.json"
fi

# Guard: no unresolved Copier placeholders in the shipped plugin payload.
if grep -rE '\{\{[^}]+\}\}' "$ROOT/commands" "$ROOT/skills" "$ROOT/hooks" "$ROOT/agents" --include='*.md' --include='*.sh' 2>/dev/null | head -5; then
  printf 'build-plugin.sh: WARNING — unresolved Copier placeholders in plugin payload.\n' >&2
fi

printf 'build-plugin.sh: done. Root payload is source; template/.claude regenerated for legacy.\n' >&2
