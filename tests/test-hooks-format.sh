#!/usr/bin/env bash
# format.sh: must NEVER reformat files in non-adopted projects (the plugin's
# hooks fire everywhere once enabled), and must skip vendored/ignored dirs.
. "$(dirname "$0")/helpers.sh"

SB="$(make_sandbox)"
trap 'cleanup_sandbox "$SB"' EXIT

HOOK="$REPO_ROOT/hooks/format.sh"

run_hook() { # $1=file-path
  printf '{"tool_input":{"file_path":%s}}' "$(printf '%s' "$1" | jq -Rs .)" | bash "$HOOK" >/dev/null 2>&1
  echo $?
}

# Non-adopted project: file content must be byte-identical after the hook.
mkdir -p "$SB/plain/src"
printf '{   "a":1,\n      "b"  : 2 }\n' > "$SB/plain/src/ugly.json"
cp "$SB/plain/src/ugly.json" "$SB/ugly.before"
assert_eq 0 "$(run_hook "$SB/plain/src/ugly.json")" "hook exits 0 in non-adopted project"
assert_same_content "$SB/ugly.before" "$SB/plain/src/ugly.json" "file untouched in non-adopted project"

# Adopted project: hook may act (we only assert it doesn't crash — prettier/black
# availability varies by machine; behavior with formatters present is exercised
# in CI where npx is absent → graceful skip).
mkdir -p "$SB/adopted/.claude" "$SB/adopted/src"
printf '[framework]\nversion = "1.4.0"\n' > "$SB/adopted/.claude/config.toml"
printf '{"a": 1}\n' > "$SB/adopted/src/ok.json"
assert_eq 0 "$(run_hook "$SB/adopted/src/ok.json")" "hook exits 0 in adopted project"

# Vendored dirs skipped even in adopted projects.
mkdir -p "$SB/adopted/node_modules/pkg"
printf '{ "x":1 }\n' > "$SB/adopted/node_modules/pkg/p.json"
cp "$SB/adopted/node_modules/pkg/p.json" "$SB/vendored.before"
run_hook "$SB/adopted/node_modules/pkg/p.json" >/dev/null
assert_same_content "$SB/vendored.before" "$SB/adopted/node_modules/pkg/p.json" "node_modules file untouched"

# Resilience.
printf '' | bash "$HOOK" >/dev/null 2>&1
assert_exit_code 0 $? "empty stdin exits 0"

finish
