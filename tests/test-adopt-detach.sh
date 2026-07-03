#!/usr/bin/env bash
# Detach: a project carrying the OLD in-tree engine gets exactly the known
# engine files removed — user-added commands/agents/hooks and the secret-scan
# floor stay, and settings.json loses only the 4 framework hook wirings.
. "$(dirname "$0")/helpers.sh"

SB="$(make_sandbox)"
trap 'cleanup_sandbox "$SB"' EXIT

COPY="$SB/engine"
repo_copy "$COPY"

PROJ="$SB/pre-plugin-app"
make_git_project "$PROJ" "pre-plugin-app"

# --- simulate the legacy in-tree scaffold -------------------------------------
mkdir -p "$PROJ/.claude/commands/sf" "$PROJ/.claude/skills/_framework" "$PROJ/.claude/hooks" "$PROJ/.claude/agents"

# Framework commands (subset, names must match the plugin's) + one user command.
for c in ship plan spec; do
  echo "legacy $c command" > "$PROJ/.claude/commands/sf/$c.md"
done
echo "user's own command" > "$PROJ/.claude/commands/sf/my-custom.md"

# Framework skill + user skill.
mkdir -p "$PROJ/.claude/skills/_framework/release-gate" "$PROJ/.claude/skills/_framework/my-skill"
echo "legacy skill" > "$PROJ/.claude/skills/_framework/release-gate/SKILL.md"
echo "user skill" > "$PROJ/.claude/skills/_framework/my-skill/SKILL.md"

# Framework agents + user agent.
echo "legacy explorer" > "$PROJ/.claude/agents/explorer.md"
echo "user agent" > "$PROJ/.claude/agents/my-agent.md"

# Hook scripts: 4 framework + floor guard + user hook.
for h in format bloat-check session-start session-end secret-scan user-extra; do
  printf '#!/bin/sh\nexit 0\n' > "$PROJ/.claude/hooks/$h.sh"
done

cat > "$PROJ/.claude/settings.json" <<'EOF'
{
  "permissions": { "deny": [] },
  "hooks": {
    "PreToolUse": [
      { "matcher": "Bash", "hooks": [ { "type": "command", "command": ".claude/hooks/secret-scan.sh" } ] }
    ],
    "PostToolUse": [
      { "matcher": "Edit|Write", "hooks": [
        { "type": "command", "command": ".claude/hooks/format.sh" },
        { "type": "command", "command": ".claude/hooks/bloat-check.sh" }
      ] },
      { "matcher": "Edit", "hooks": [ { "type": "command", "command": ".claude/hooks/user-extra.sh" } ] }
    ],
    "SessionStart": [
      { "hooks": [ { "type": "command", "command": ".claude/hooks/session-start.sh" } ] }
    ],
    "Stop": [
      { "hooks": [ { "type": "command", "command": ".claude/hooks/session-end.sh" } ] }
    ]
  }
}
EOF
( cd "$PROJ" && git add -A && git commit -qm "legacy scaffold state" )

"$COPY/scripts/sf-adopt.sh" --project "$PROJ" >/dev/null 2>&1
assert_exit_code 0 $? "adopt over legacy scaffold succeeds"

# Framework engine files removed.
for c in ship plan spec; do
  assert_file_absent "$PROJ/.claude/commands/sf/$c.md" "legacy command $c removed"
done
assert_file_absent "$PROJ/.claude/skills/_framework/release-gate/SKILL.md" "legacy skill removed"
assert_file_absent "$PROJ/.claude/agents/explorer.md" "legacy framework agent removed"
for h in format bloat-check session-start session-end; do
  assert_file_absent "$PROJ/.claude/hooks/$h.sh" "framework hook script $h removed"
done

# User artifacts preserved.
assert_file_exists "$PROJ/.claude/commands/sf/my-custom.md" "user command preserved"
assert_file_exists "$PROJ/.claude/skills/_framework/my-skill/SKILL.md" "user skill preserved"
assert_file_exists "$PROJ/.claude/agents/my-agent.md" "user agent preserved"
assert_file_exists "$PROJ/.claude/hooks/user-extra.sh" "user hook script preserved"
assert_file_exists "$PROJ/.claude/hooks/secret-scan.sh" "secret-scan floor script preserved"

# Settings: framework wirings gone, floor + user hook stay, still valid.
S="$PROJ/.claude/settings.json"
assert_valid_json "$S" "settings.json valid after detach"
assert_eq "false" "$(jq '[.hooks | to_entries[].value[]?.hooks[]?.command // ""] | any(test("format\\.sh|bloat-check\\.sh|session-start\\.sh|session-end\\.sh"))' "$S")" "4 framework hook wirings stripped"
assert_eq "true" "$(jq '[.hooks.PreToolUse[]?.hooks[]?.command // ""] | any(test("secret-scan"))' "$S")" "secret-scan wiring kept"
assert_eq "true" "$(jq '[.hooks.PostToolUse[]?.hooks[]?.command // ""] | any(test("user-extra"))' "$S")" "user hook wiring kept"
assert_file_exists "$S.savvy-old" "settings backup exists after detach"

finish
