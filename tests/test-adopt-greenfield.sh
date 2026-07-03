#!/usr/bin/env bash
# Greenfield adopt: empty git project gets the full skeleton, plugin enabled,
# tokens substituted, work dirs created.
. "$(dirname "$0")/helpers.sh"

SB="$(make_sandbox)"
trap 'cleanup_sandbox "$SB"' EXIT

COPY="$SB/engine"
repo_copy "$COPY"

PROJ="$SB/my-fresh-app"
make_git_project "$PROJ" "my-fresh-app"

"$COPY/scripts/sf-adopt.sh" --project "$PROJ" >/dev/null 2>&1
assert_exit_code 0 $? "adopt exits 0 on clean greenfield project"

for f in AGENTS.md CLAUDE.md constitution.md ROADMAP.md README.md; do
  assert_file_exists "$PROJ/$f" "skeleton seeds $f"
done
for d in specs docs scratchpads; do
  assert_dir_exists "$PROJ/$d" "work dir $d/ created"
done

# Token substitution: project name filled in, no raw placeholders left anywhere.
assert_contains "$PROJ/AGENTS.md" "my-fresh-app" "project name substituted into AGENTS.md"
if grep -rq "__PROJECT_NAME__" "$PROJ" 2>/dev/null; then
  fail "raw __PROJECT_NAME__ placeholder left in seeded project"
else
  pass
fi

# Settings: valid JSON, plugin enabled at project scope, secret-scan floor wired.
S="$PROJ/.claude/settings.json"
assert_file_exists "$S" "settings.json seeded"
assert_valid_json "$S" "settings.json is valid JSON"
assert_eq "true" "$(jq -r '.enabledPlugins["sf@savvy"]' "$S")" "sf@savvy enabled"
assert_eq "true" "$(jq '[.hooks.PreToolUse[]?.hooks[]?.command // ""] | any(test("secret-scan"))' "$S")" "secret-scan floor guard wired"

# Floor-guard script present and executable.
G="$PROJ/.claude/hooks/secret-scan.sh"
assert_file_exists "$G" "floor-guard secret-scan.sh seeded"
if [ -x "$G" ]; then pass; else fail "secret-scan.sh not executable"; fi

# The existing file from before adoption is untouched.
assert_contains "$PROJ/EXISTING.md" "my-fresh-app" "pre-existing file untouched"

finish
