#!/usr/bin/env bash
# build-plugin.sh: version stamping, determinism, and no-drift — the committed
# generated artifacts (template/.claude engine mirror, skeleton/, shipped
# manifest) must match what the script regenerates from the root payload.
. "$(dirname "$0")/helpers.sh"

SB="$(make_sandbox)"
trap 'cleanup_sandbox "$SB"' EXIT

COPY="$SB/engine"
repo_copy "$COPY"

# snapshot of committed generated artifacts before regeneration; the manifest's
# "generated" date line is normalized out (it changes on every regen by design).
snap() { # $1=root $2=out
  ( cd "$1" && find template/.claude skeleton .claude-plugin -type f ! -name '.DS_Store' 2>/dev/null \
      | LC_ALL=C sort | while IFS= read -r f; do
        printf '%s  %s\n' "$(sed '/"generated":/d' "$f" | shasum | cut -d' ' -f1)" "$f"
      done ) > "$2"
}
snap "$COPY" "$SB/before.sum"

( cd "$COPY" && bash scripts/build-plugin.sh >/dev/null 2>&1 )
assert_exit_code 0 $? "build-plugin.sh runs clean"
snap "$COPY" "$SB/after1.sum"

# Manifest 'generated' date changes run-to-run days, so compare excluding it is
# unnecessary — both runs happen now. Determinism: second run must be identical.
( cd "$COPY" && bash scripts/build-plugin.sh >/dev/null 2>&1 )
assert_exit_code 0 $? "build-plugin.sh runs clean twice"
snap "$COPY" "$SB/after2.sum"
assert_same_content "$SB/after1.sum" "$SB/after2.sum" "regeneration is deterministic"

# No drift: committed artifacts == regenerated artifacts.
if cmp -s "$SB/before.sum" "$SB/after1.sum"; then
  pass
else
  fail "generated artifacts drifted from committed state: $(comm -3 "$SB/before.sum" "$SB/after1.sum" | head -20 | tr '\n' ' ')"
fi

# Version stamped from VERSION into plugin.json.
v="$(tr -d '[:space:]' < "$COPY/VERSION")"
assert_eq "$v" "$(jq -r .version "$COPY/.claude-plugin/plugin.json")" "plugin.json version == VERSION"

# VERSION/config.toml mismatch must abort.
MIS="$SB/mismatch"
repo_copy "$MIS"
echo "9.9.9" > "$MIS/VERSION"
( cd "$MIS" && bash scripts/build-plugin.sh >/dev/null 2>&1 )
rc=$?
assert_ne "0" "$rc" "VERSION vs config.toml mismatch aborts the build"

# No residual Jinja in the generated skeleton.
if grep -rE '\{\{|\{%' "$COPY/skeleton" >/dev/null 2>&1; then
  fail "residual Jinja constructs in skeleton/"
else
  pass
fi

finish
