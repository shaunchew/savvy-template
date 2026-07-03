#!/usr/bin/env bash
# Brownfield adopt: a project with its own README, context files, settings.json
# (custom hooks, deny rules, other plugins) must come through with every user
# artifact byte-identical or additively merged — never clobbered.
. "$(dirname "$0")/helpers.sh"

SB="$(make_sandbox)"
trap 'cleanup_sandbox "$SB"' EXIT

COPY="$SB/engine"
repo_copy "$COPY"

PROJ="$SB/legacy-app"
make_git_project "$PROJ" "legacy-app"

cat > "$PROJ/README.md" <<'EOF'
MY OWN README — precious user content.
EOF
cat > "$PROJ/AGENTS.md" <<'EOF'
MY OWN AGENTS FILE.
EOF
mkdir -p "$PROJ/.claude/hooks"
cat > "$PROJ/.claude/hooks/my-hook.sh" <<'EOF'
#!/bin/sh
exit 0
EOF
cat > "$PROJ/.claude/settings.json" <<'EOF'
{
  "permissions": {
    "deny": ["Read(./secrets/**)"],
    "allow": ["Bash(npm test:*)"]
  },
  "hooks": {
    "PreToolUse": [
      { "matcher": "Bash", "hooks": [ { "type": "command", "command": ".claude/hooks/my-hook.sh" } ] }
    ]
  },
  "enabledPlugins": { "other@market": true },
  "model": "opus"
}
EOF
( cd "$PROJ" && git add -A && git commit -qm "user state" )

"$COPY/scripts/sf-adopt.sh" --project "$PROJ" >/dev/null 2>&1
assert_exit_code 0 $? "adopt exits 0 on brownfield project"

# User files byte-identical.
assert_contains "$PROJ/README.md" "MY OWN README" "user README untouched"
assert_eq "1" "$(wc -l < "$PROJ/README.md" | tr -d ' ')" "user README not appended to"
assert_contains "$PROJ/AGENTS.md" "MY OWN AGENTS FILE." "user AGENTS.md untouched"

# Settings merged additively.
S="$PROJ/.claude/settings.json"
assert_valid_json "$S" "merged settings.json is valid JSON"
assert_eq "true" "$(jq -r '.enabledPlugins["other@market"]' "$S")" "user plugin still enabled"
assert_eq "true" "$(jq -r '.enabledPlugins["sf@savvy"]' "$S")" "sf plugin enabled"
assert_eq "opus" "$(jq -r '.model' "$S")" "unrelated user key preserved"
assert_eq "true" "$(jq '.permissions.deny | index("Read(./secrets/**)") != null' "$S")" "user deny rule preserved"
assert_eq "true" "$(jq '.permissions.allow | index("Bash(npm test:*)") != null' "$S")" "user allow rule preserved"
assert_eq "true" "$(jq '[.hooks.PreToolUse[]?.hooks[]?.command // ""] | any(test("my-hook"))' "$S")" "user hook preserved"
assert_eq "true" "$(jq '[.hooks.PreToolUse[]?.hooks[]?.command // ""] | any(test("secret-scan"))' "$S")" "secret-scan floor added"

# Backup of the pre-merge settings exists and holds the original.
assert_file_exists "$S.savvy-old" "settings backup written"
assert_eq "false" "$(jq 'has("enabledPlugins") and (.enabledPlugins | has("sf@savvy"))' "$S.savvy-old")" "backup is the pre-adopt version"

# Skeleton files the user did NOT have are seeded.
assert_file_exists "$PROJ/constitution.md" "missing skeleton files still seeded"

# Nothing was deleted from the user's project.
assert_file_exists "$PROJ/.claude/hooks/my-hook.sh" "user hook script preserved"

finish
