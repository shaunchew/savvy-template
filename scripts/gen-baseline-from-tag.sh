#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'
# gen-baseline-from-tag.sh — build a retroactive .savvy-manifest baseline for a
# released framework version from its git tag, WITHOUT checking the tag out.
#
# Pre-v1.4.0 releases shipped no manifest. To let those projects upgrade cleanly
# (refresh files they never touched, conflict only on files they edited), the
# bootstrap migration needs a baseline matching the project's CURRENT version.
# This generates `migrations/baselines/<tag>.json` from the tagged template/ tree.
#
# The policy classification MUST stay in sync with scripts/gen-manifest.sh.
#
# Usage:  scripts/gen-baseline-from-tag.sh v1.3.0

cd "$(dirname "$0")/.."
ROOT="$(pwd)"

say() { printf 'gen-baseline: %s\n' "$*" >&2; }
die() { say "error: $*"; exit 1; }

TAG="${1:-}"
[ -n "$TAG" ] || die "usage: $0 <tag>  (e.g. v1.3.0)"
git rev-parse "$TAG" >/dev/null 2>&1 || die "tag '$TAG' not found."

VERSION="${TAG#v}"
OUTDIR="$ROOT/migrations/baselines"
OUT="$OUTDIR/$TAG.json"
mkdir -p "$OUTDIR"

# Same classification as scripts/gen-manifest.sh — keep in sync.
classify() {
  local p="$1" base; base="$(basename "$p")"
  case "$p" in .claude/.savvy-manifest.json) printf 'skip'; return ;; esac
  [ "$base" = ".gitkeep" ] && { printf 'seeded'; return; }
  case "$p" in
    .claude/settings.json)                 printf 'merge';   return ;;
    .claude/config.toml)                   printf 'merge';   return ;;
    .claude/integrations/*/config.toml)    printf 'seeded';  return ;;
    .claude/integrations/*/README.md)      printf 'managed'; return ;;
    .claude/integrations/_mcp-template/*)  printf 'managed'; return ;;
    .claude/skills/*)                      printf 'managed'; return ;;
    .claude/commands/*)                    printf 'managed'; return ;;
    .claude/hooks/*)                       printf 'managed'; return ;;
    .claude/agents/*.md)                   printf 'managed'; return ;;
    docs/agents-subdir-pattern.md)         printf 'managed'; return ;;
  esac
  printf 'seeded'
}

json_escape() { printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'; }

tmp="$(mktemp)"; trap 'rm -f "$tmp"' EXIT
total=0
while IFS= read -r treepath; do
  rel="${treepath#template/}"
  policy="$(classify "$rel")"
  [ "$policy" = "skip" ] && continue
  # Hash the blob content at the tag (no checkout needed).
  h="$(git cat-file blob "$TAG:$treepath" | { sha256sum 2>/dev/null || shasum -a 256; } | cut -d' ' -f1)"
  # A managed file with a Jinja placeholder can't be hash-compared post-render → demote.
  if [ "$policy" = "managed" ] && git cat-file blob "$TAG:$treepath" | grep -q '{{'; then
    policy="seeded"
  fi
  printf '%s\t%s\t%s\n' "$rel" "$policy" "$h" >> "$tmp"
  total=$((total + 1))
done < <(git ls-tree -r --name-only "$TAG" -- template | LC_ALL=C sort)

{
  printf '{\n  "framework": "savvy-framework",\n  "version": "%s",\n  "generated": "%s",\n  "source": "retroactive baseline from git tag %s",\n  "files": [\n' \
    "$(json_escape "$VERSION")" "$(date +%Y-%m-%d)" "$TAG"
  n=0
  while IFS=$'\t' read -r rel policy h; do
    n=$((n + 1)); sep=','; [ "$n" -eq "$total" ] && sep=''
    printf '    { "path": "%s", "policy": "%s", "sha256": "%s" }%s\n' "$(json_escape "$rel")" "$policy" "$h" "$sep"
  done < "$tmp"
  printf '  ]\n}\n'
} > "$OUT"

say "wrote $OUT — baseline for $TAG ($total files)."
