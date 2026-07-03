#!/usr/bin/env bash
# gen-manifest.sh: valid deterministic JSON, correct policy classification,
# every listed file exists, hashes verify.
. "$(dirname "$0")/helpers.sh"

SB="$(make_sandbox)"
trap 'cleanup_sandbox "$SB"' EXIT

COPY="$SB/engine"
repo_copy "$COPY"

M="$COPY/template/.claude/.savvy-manifest.json"

( cd "$COPY" && bash scripts/gen-manifest.sh >/dev/null 2>&1 )
assert_exit_code 0 $? "gen-manifest.sh runs clean"
assert_valid_json "$M" "manifest is valid JSON"

assert_eq "$(tr -d '[:space:]' < "$COPY/VERSION")" "$(jq -r .version "$M")" "manifest version == VERSION"

# Determinism.
cp "$M" "$SB/m1.json"
( cd "$COPY" && bash scripts/gen-manifest.sh >/dev/null 2>&1 )
assert_same_content "$SB/m1.json" "$M" "manifest generation is deterministic"

# Every path exists and its hash matches the file on disk.
bad=0
while IFS=$'\t' read -r p h; do
  if [ ! -f "$COPY/template/$p" ]; then
    bad=$((bad + 1))
  elif [ "$(shasum -a 256 "$COPY/template/$p" | cut -d' ' -f1)" != "$h" ]; then
    bad=$((bad + 1))
  fi
done < <(jq -r '.files[] | [.path, .sha256] | @tsv' "$M")
assert_eq "0" "$bad" "all manifest entries exist with matching hashes"

# Spot-check policy classification invariants.
assert_eq "merge"  "$(jq -r '.files[] | select(.path == ".claude/settings.json") | .policy' "$M")" "settings.json is merge"
assert_eq "merge"  "$(jq -r '.files[] | select(.path == ".claude/config.toml") | .policy' "$M")" "config.toml is merge"
assert_eq "seeded" "$(jq -r '.files[] | select(.path == "AGENTS.md") | .policy' "$M")" "AGENTS.md is seeded"
# No managed file may carry an unrendered Jinja placeholder (would break hash refresh).
assert_eq "0" "$(jq -r '.files[] | select(.policy == "managed") | .path' "$M" | while IFS= read -r p; do grep -l '{{' "$COPY/template/$p" 2>/dev/null; done | wc -l | tr -d ' ')" "no managed file contains Jinja"

finish
