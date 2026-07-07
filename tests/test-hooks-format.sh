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

# Go (gofmt): adopted project, canonical file — hook exits 0 and leaves it
# byte-identical whether or not gofmt is installed (a lone package clause is
# already gofmt-clean; on CI gofmt is absent and the go branch is a no-op).
printf 'package main\n' > "$SB/adopted/src/main.go"
cp "$SB/adopted/src/main.go" "$SB/go.clean.before"
assert_eq 0 "$(run_hook "$SB/adopted/src/main.go")" "hook exits 0 for .go in adopted project"
assert_same_content "$SB/go.clean.before" "$SB/adopted/src/main.go" "canonical .go untouched in adopted project"

# Go (gofmt): NON-adopted project, deliberately mis-formatted file — the adoption
# gate must stop the hook from ever invoking gofmt, so the file stays identical
# even on a machine where gofmt IS installed (the regression the gate prevents).
mkdir -p "$SB/plain/src"
printf 'package main\nfunc  main( ){}\n' > "$SB/plain/src/messy.go"
cp "$SB/plain/src/messy.go" "$SB/go.messy.before"
assert_eq 0 "$(run_hook "$SB/plain/src/messy.go")" "hook exits 0 for .go in non-adopted project"
assert_same_content "$SB/go.messy.before" "$SB/plain/src/messy.go" "non-adopted .go untouched (gate holds)"

# Resilience.
printf '' | bash "$HOOK" >/dev/null 2>&1
assert_exit_code 0 $? "empty stdin exits 0"

finish
