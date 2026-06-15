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

# --- 2. regenerate the ownership manifest (legacy /sf:upgrade hashes) ---
if [ -x "$ROOT/scripts/gen-manifest.sh" ]; then
  "$ROOT/scripts/gen-manifest.sh"
fi

# --- 3. reverse-generate the legacy in-tree engine under template/.claude/ from root ---
T="$ROOT/template/.claude"
mkdir -p "$T/commands/sf" "$T/skills/_framework" "$T/hooks" "$T/agents"

# commands: flat root/commands/<cmd>.md -> template/.claude/commands/sf/<cmd>.md
rm -rf "$T/commands/sf"; mkdir -p "$T/commands/sf"
cp "$ROOT"/commands/*.md "$T/commands/sf/"

# skills: root/skills/<n>/SKILL.md -> template/.claude/skills/_framework/<n>/SKILL.md
rm -rf "$T/skills/_framework"; mkdir -p "$T/skills/_framework"
for d in "$ROOT"/skills/*/; do
  n="$(basename "$d")"
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

# Ship the manifest with the plugin so an installed engine can resolve legacy upgrades.
if [ -f "$T/.savvy-manifest.json" ]; then
  cp "$T/.savvy-manifest.json" "$ROOT/.claude-plugin/.savvy-manifest.json"
fi

# Guard: no unresolved Copier placeholders in the shipped plugin payload.
if grep -rE '\{\{[^}]+\}\}' "$ROOT/commands" "$ROOT/skills" "$ROOT/hooks" "$ROOT/agents" --include='*.md' --include='*.sh' 2>/dev/null | head -5; then
  printf 'build-plugin.sh: WARNING — unresolved Copier placeholders in plugin payload.\n' >&2
fi

printf 'build-plugin.sh: done. Root payload is source; template/.claude regenerated for legacy.\n' >&2
