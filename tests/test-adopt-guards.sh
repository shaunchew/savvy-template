#!/usr/bin/env bash
# Guards: adopt must refuse dirty trees and non-git dirs without --yes, and
# must not half-apply anything when it refuses.
. "$(dirname "$0")/helpers.sh"

SB="$(make_sandbox)"
trap 'cleanup_sandbox "$SB"' EXIT

COPY="$SB/engine"
repo_copy "$COPY"

# --- dirty tree refused --------------------------------------------------------
PROJ="$SB/dirty-app"
make_git_project "$PROJ" "dirty-app"
echo "uncommitted" > "$PROJ/wip.txt"

"$COPY/scripts/sf-adopt.sh" --project "$PROJ" >/dev/null 2>&1
rc=$?
assert_ne "0" "$rc" "adopt refuses dirty working tree"
assert_file_absent "$PROJ/AGENTS.md" "no files seeded after refusal"
assert_file_absent "$PROJ/.claude/settings.json" "no settings written after refusal"

# --- dirty tree with --yes proceeds --------------------------------------------
"$COPY/scripts/sf-adopt.sh" --project "$PROJ" --yes >/dev/null 2>&1
assert_exit_code 0 $? "adopt proceeds on dirty tree with --yes"
assert_file_exists "$PROJ/AGENTS.md" "seeding happened with --yes"

# --- non-git dir refused ---------------------------------------------------------
NOGIT="$SB/no-git-app"
mkdir -p "$NOGIT"
"$COPY/scripts/sf-adopt.sh" --project "$NOGIT" >/dev/null 2>&1
rc=$?
assert_ne "0" "$rc" "adopt refuses non-git dir without --yes"
assert_file_absent "$NOGIT/AGENTS.md" "nothing seeded in refused non-git dir"

# --- non-git dir with --yes proceeds -------------------------------------------
"$COPY/scripts/sf-adopt.sh" --project "$NOGIT" --yes >/dev/null 2>&1
assert_exit_code 0 $? "adopt proceeds on non-git dir with --yes"

# --- unknown flag is an error ---------------------------------------------------
"$COPY/scripts/sf-adopt.sh" --bogus >/dev/null 2>&1
assert_exit_code 2 $? "unknown argument exits 2"

# --- invalid settings.json: abort BEFORE any mutation ----------------------------
BADJSON="$SB/bad-json-app"
make_git_project "$BADJSON" "bad-json-app"
mkdir -p "$BADJSON/.claude"
echo '{ not valid json' > "$BADJSON/.claude/settings.json"
( cd "$BADJSON" && git add -A && git commit -qm bad )
"$COPY/scripts/sf-adopt.sh" --project "$BADJSON" >/dev/null 2>&1
rc=$?
assert_ne "0" "$rc" "adopt refuses invalid settings.json"
assert_file_absent "$BADJSON/AGENTS.md" "nothing seeded when settings.json is invalid"
assert_file_absent "$BADJSON/.claude/settings.json.savvy-old" "no backup written when refused"

# --- project name with sed metacharacters must not corrupt seeded files ----------
NASTY="$SB/app&api"
make_git_project "$NASTY" "nasty"
"$COPY/scripts/sf-adopt.sh" --project "$NASTY" >/dev/null 2>&1
assert_exit_code 0 $? "adopt succeeds with & in project dir name"
assert_contains "$NASTY/AGENTS.md" "app&api" "ampersand name substituted literally"
assert_not_contains "$NASTY/AGENTS.md" "__PROJECT_NAME__" "no raw placeholder with nasty name"

finish
