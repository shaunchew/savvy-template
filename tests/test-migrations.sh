#!/usr/bin/env bash
# Migrations: retroactive baselines are well-formed, the v1.4.0 bootstrap is
# tag-pinned and guards its project root, and the upgrade skill carries the
# plugin-mode refusal. Offline-only checks (no network, no curl).
. "$(dirname "$0")/helpers.sh"

BASE_DIR="$REPO_ROOT/migrations/baselines"
V140="$REPO_ROOT/migrations/v1.4.0.sh"
SKILL="$REPO_ROOT/skills/framework-upgrade/SKILL.md"

# --- baselines exist for every pre-manifest tag --------------------------------
for tag in v1.0.0 v1.0.1 v1.1.0 v1.2.0 v1.3.0 v1.4.0; do
  assert_file_exists "$BASE_DIR/$tag.json" "baseline $tag present"
done

# --- each baseline is valid JSON, has a non-empty files[], version == filename --
for f in "$BASE_DIR"/*.json; do
  [ -e "$f" ] || { fail "no baseline files found in $BASE_DIR"; break; }
  b="$(basename "$f" .json)"                     # vX.Y.Z
  assert_valid_json "$f" "baseline $b is valid JSON"

  n="$(jq -r '.files | length' "$f" 2>/dev/null)"
  assert_ne "0" "${n:-0}" "baseline $b has a non-empty files[]"

  ver="$(jq -r '.version' "$f" 2>/dev/null)"
  assert_eq "${b#v}" "$ver" "baseline $b version field matches its filename"
done

# --- v1.4.0.sh refuses to run outside a project root (no .claude → nonzero) -----
SB="$(make_sandbox)"
trap 'cleanup_sandbox "$SB"' EXIT
EMPTY="$SB/not-a-project"
mkdir -p "$EMPTY"
( cd "$EMPTY" && bash "$V140" ) >/dev/null 2>&1
rc=$?
assert_ne "0" "$rc" "v1.4.0.sh exits nonzero when run without a .claude/ dir"
assert_file_absent "$EMPTY/.claude/.savvy-manifest.json" "v1.4.0.sh writes nothing when it refuses"

# --- v1.4.0.sh is tag-pinned: no raw /main/ URLs (regression) ------------------
assert_not_contains "$V140" "/main/" "v1.4.0.sh contains no raw /main/ URL"
assert_contains "$V140" 'TAG="v1.4.0"' "v1.4.0.sh pins its remote fetches to the v1.4.0 tag"
assert_contains "$V140" '$TAG/template' "v1.4.0.sh builds the template RAW URL from the pinned tag"
assert_contains "$V140" "baseline_tag_for" "v1.4.0.sh maps coarse config.toml stamps to baseline tags"

# --- SKILL.md carries the plugin-mode guard ------------------------------------
assert_contains "$SKILL" "/plugin update sf@savvy" "SKILL.md step 0 refuses plugin-mode projects"
assert_contains "$SKILL" ".savvy-engine-version" "SKILL.md detects plugin mode via .savvy-engine-version"

# --- SKILL.md carries the sticky-conflict marker semantics ---------------------
assert_contains "$SKILL" "conflict: true" "SKILL.md documents the sticky conflict marker"

finish
