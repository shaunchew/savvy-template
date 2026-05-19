#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'
# build-plugin.sh — materializes the Claude Code plugin layout from template/.claude/.
#
# Source of truth lives under template/.claude/ (so Copier scaffolds it into new
# projects). The plugin layout mirrors that into the framework root so the
# repo is also installable via /plugin install <path>.
#
# Run this before publishing a release tag, or whenever skills/commands/hooks/agents
# change. The materialized directories are .gitignored — the manifest at
# .claude-plugin/plugin.json is the only checked-in piece.

cd "$(dirname "$0")/.."
ROOT="$(pwd)"

if [ ! -d "$ROOT/template/.claude" ]; then
  printf 'build-plugin.sh: template/.claude not found at %s. Aborting.\n' "$ROOT" >&2
  exit 1
fi

if [ ! -f "$ROOT/.claude-plugin/plugin.json" ]; then
  printf 'build-plugin.sh: .claude-plugin/plugin.json missing. Aborting.\n' >&2
  exit 1
fi

# Remove previous materialization (keep manifest).
for dir in skills commands hooks agents; do
  if [ -d "$ROOT/.claude-plugin/$dir" ]; then
    rm -rf "$ROOT/.claude-plugin/$dir"
  fi
done

# Mirror from template/.claude/.
for dir in skills commands hooks agents; do
  if [ -d "$ROOT/template/.claude/$dir" ]; then
    cp -R "$ROOT/template/.claude/$dir" "$ROOT/.claude-plugin/$dir"
    printf 'build-plugin.sh: materialized .claude-plugin/%s/ from template/.claude/%s/\n' "$dir" "$dir" >&2
  fi
done

# Strip Copier placeholders from any *.toml or *.md inside the plugin layout.
# Plugin install paths can't render Jinja, so any unresolved {{ ... }} would be a bug.
if grep -rE '\{\{[^}]+\}\}' "$ROOT/.claude-plugin/" --include='*.md' --include='*.toml' --include='*.sh' 2>/dev/null | head -5; then
  printf 'build-plugin.sh: WARNING — unresolved Copier placeholders found in plugin output. Plugin will not work as-is for these files.\n' >&2
fi

printf 'build-plugin.sh: done. Plugin layout ready under .claude-plugin/.\n' >&2
