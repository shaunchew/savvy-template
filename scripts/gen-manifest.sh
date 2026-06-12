#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'
# gen-manifest.sh — generate template/.claude/.savvy-manifest.json.
#
# The manifest is the file-ownership map that makes `/sf:upgrade` safe. For every
# framework-shipped file it records a content hash and a policy that tells an
# updater how the file may be touched:
#
#   managed — framework owns it (skills/commands/hooks/agents/framework docs).
#             Safe to refresh on update IF the project hasn't locally edited it.
#   merge   — structural merge required (settings.json, config.toml). The framework
#             owns part of the file; user additions must survive.
#   seeded  — scaffolded once, then belongs to the project forever (context files,
#             specs, scratchpads, docs, integration creds). NEVER overwritten on
#             update; only added when entirely absent.
#
# Paths are recorded relative to the PROJECT ROOT (the deployed location), i.e.
# `.claude/...`, `AGENTS.md`, not `template/...`.
#
# Run from anywhere; resolves the repo root from its own location. Invoked by
# build-plugin.sh and the release-gate skill on every version bump. Deterministic
# (sorted) so the manifest diffs cleanly in git.

cd "$(dirname "$0")/.."
ROOT="$(pwd)"
SRC="$ROOT/template"
OUT="$SRC/.claude/.savvy-manifest.json"

say() { printf 'gen-manifest.sh: %s\n' "$*" >&2; }
die() { say "error: $*"; exit 1; }

[ -d "$SRC/.claude" ] || die "template/.claude not found at $SRC."
[ -f "$ROOT/VERSION" ] || die "VERSION file not found at repo root."

VERSION="$(tr -d '[:space:]' < "$ROOT/VERSION")"
[ -n "$VERSION" ] || die "VERSION file is empty."

# --- hashing -----------------------------------------------------------------
if command -v sha256sum >/dev/null 2>&1; then
  hash_of() { sha256sum "$1" | cut -d' ' -f1; }
elif command -v shasum >/dev/null 2>&1; then
  hash_of() { shasum -a 256 "$1" | cut -d' ' -f1; }
else
  die "neither sha256sum nor shasum found — cannot hash files."
fi

# --- policy classification ---------------------------------------------------
# Input: path relative to template/ (e.g. ".claude/hooks/format.sh", "AGENTS.md").
# Output: managed | merge | seeded. First matching rule wins.
classify() {
  local p="$1" base
  base="$(basename "$p")"

  # Generated artifacts and bookkeeping are never tracked as content.
  case "$p" in
    .claude/.savvy-manifest.json) printf 'skip'; return ;;
  esac

  # Placeholder dir-markers: seeded so a fresh dir is created but never clobbered.
  [ "$base" = ".gitkeep" ] && { printf 'seeded'; return; }

  case "$p" in
    .claude/settings.json)                 printf 'merge';  return ;;
    .claude/config.toml)                   printf 'merge';  return ;;
    .claude/integrations/*/config.toml)    printf 'seeded'; return ;;
    .claude/integrations/*/README.md)      printf 'managed'; return ;;
    .claude/integrations/_mcp-template/*)  printf 'managed'; return ;;
    .claude/skills/*)                      printf 'managed'; return ;;
    .claude/commands/*)                    printf 'managed'; return ;;
    .claude/hooks/*)                       printf 'managed'; return ;;
    .claude/agents/*.md)                   printf 'managed'; return ;;
    docs/agents-subdir-pattern.md)         printf 'managed'; return ;;
  esac

  # Default: everything else belongs to the project once scaffolded.
  printf 'seeded'
}

# --- walk + emit -------------------------------------------------------------
tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT

managed=0; merge=0; seeded=0; total=0

# Collect, classify, hash. Sorted for determinism.
while IFS= read -r abs; do
  rel="${abs#"$SRC"/}"
  policy="$(classify "$rel")"
  [ "$policy" = "skip" ] && continue

  # A managed file containing an unrendered Jinja placeholder cannot be
  # hash-compared against a rendered deployment — demote it to seeded so the
  # updater never tries to refresh-by-hash and raise a false conflict.
  if [ "$policy" = "managed" ] && grep -q '{{' "$abs" 2>/dev/null; then
    say "warning: $rel is 'managed' but contains a Jinja placeholder — demoting to 'seeded'."
    policy="seeded"
  fi

  h="$(hash_of "$abs")"
  printf '%s\t%s\t%s\n' "$rel" "$policy" "$h" >> "$tmp"

  total=$((total + 1))
  case "$policy" in
    managed) managed=$((managed + 1)) ;;
    merge)   merge=$((merge + 1)) ;;
    seeded)  seeded=$((seeded + 1)) ;;
  esac
done < <(find "$SRC" -type f ! -name '.DS_Store' | LC_ALL=C sort)

# --- write JSON --------------------------------------------------------------
json_escape() { printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'; }

{
  printf '{\n'
  printf '  "framework": "savvy-framework",\n'
  printf '  "version": "%s",\n' "$(json_escape "$VERSION")"
  printf '  "generated": "%s",\n' "$(date +%Y-%m-%d)"
  printf '  "files": [\n'
  n=0
  while IFS=$'\t' read -r rel policy h; do
    n=$((n + 1))
    sep=','
    [ "$n" -eq "$total" ] && sep=''
    printf '    { "path": "%s", "policy": "%s", "sha256": "%s" }%s\n' \
      "$(json_escape "$rel")" "$policy" "$h" "$sep"
  done < "$tmp"
  printf '  ]\n'
  printf '}\n'
} > "$OUT"

say "wrote $OUT — v$VERSION · $total files (managed=$managed merge=$merge seeded=$seeded)."
