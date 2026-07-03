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
# One engine file carries a LOCAL USER EDIT — detach must preserve it.
echo "MY PRECIOUS LOCAL CUSTOMIZATION" >> "$PROJ/.claude/commands/sf/plan.md"
echo "user's own command" > "$PROJ/.claude/commands/sf/my-custom.md"

# Legacy upgrade bookkeeping that would resurrect the engine on /sf:upgrade.
echo '{"version":"1.4.0","files":[]}' > "$PROJ/.claude/.savvy-manifest.json"

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
      { "matcher": "Edit", "hooks": [ { "type": "command", "command": ".claude/hooks/user-extra.sh" } ] },
      { "matcher": "Write", "hooks": [ { "type": "command", "command": "bash scripts/format.sh" } ] }
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

# Framework engine files removed from their live locations.
for c in ship plan spec; do
  assert_file_absent "$PROJ/.claude/commands/sf/$c.md" "legacy command $c detached"
done
assert_file_absent "$PROJ/.claude/skills/_framework/release-gate/SKILL.md" "legacy skill detached"
assert_file_absent "$PROJ/.claude/agents/explorer.md" "legacy framework agent detached"
for h in format bloat-check session-start session-end; do
  assert_file_absent "$PROJ/.claude/hooks/$h.sh" "framework hook script $h detached"
done

# ...but QUARANTINED, not deleted — including the user's local edit.
Q="$(ls -d "$PROJ/.claude/.savvy-detached-"* 2>/dev/null | head -1)"
assert_dir_exists "$Q" "quarantine dir created"
assert_file_exists "$Q/.claude/commands/sf/plan.md" "detached file preserved in quarantine"
assert_contains "$Q/.claude/commands/sf/plan.md" "MY PRECIOUS LOCAL CUSTOMIZATION" "user's local edit to engine file survives detach"

# Legacy upgrade markers quarantined so /sf:upgrade cannot resurrect the engine.
assert_file_absent "$PROJ/.claude/.savvy-manifest.json" "legacy baseline manifest detached"
assert_file_exists "$Q/.claude/.savvy-manifest.json" "legacy manifest preserved in quarantine"

# User artifacts preserved.
assert_file_exists "$PROJ/.claude/commands/sf/my-custom.md" "user command preserved"
assert_file_exists "$PROJ/.claude/skills/_framework/my-skill/SKILL.md" "user skill preserved"
assert_file_exists "$PROJ/.claude/agents/my-agent.md" "user agent preserved"
assert_file_exists "$PROJ/.claude/hooks/user-extra.sh" "user hook script preserved"
assert_file_exists "$PROJ/.claude/hooks/secret-scan.sh" "secret-scan floor script preserved"

# Settings: framework wirings gone, floor + user hook stay, still valid.
S="$PROJ/.claude/settings.json"
assert_valid_json "$S" "settings.json valid after detach"
assert_eq "false" "$(jq '[.hooks | to_entries[].value[]?.hooks[]?.command // ""] | any(test("\\.claude/hooks/(format|bloat-check|session-start|session-end)\\.sh"))' "$S")" "4 framework hook wirings stripped"
assert_eq "true" "$(jq '[.hooks.PreToolUse[]?.hooks[]?.command // ""] | any(test("secret-scan"))' "$S")" "secret-scan wiring kept"
assert_eq "true" "$(jq '[.hooks.PostToolUse[]?.hooks[]?.command // ""] | any(test("user-extra"))' "$S")" "user hook wiring kept"
assert_eq "true" "$(jq '[.hooks.PostToolUse[]?.hooks[]?.command // ""] | any(. == "bash scripts/format.sh")' "$S")" "user hook named like a framework hook (scripts/format.sh) survives the anchored strip"
assert_file_exists "$S.savvy-old" "settings backup exists after detach"

# --- gitignored .claude: the git guard is blind there; quarantine must still save data ---
GI="$SB/gitignored-claude-app"
make_git_project "$GI" "gitignored-claude-app"
echo '.claude/' > "$GI/.gitignore"
( cd "$GI" && git add -A && git commit -qm gitignore )
mkdir -p "$GI/.claude/commands/sf"
echo "engine file with LOCAL TWEAK" > "$GI/.claude/commands/sf/plan.md"
# tree reads clean (.claude ignored) → adopt runs WITHOUT --yes
"$COPY/scripts/sf-adopt.sh" --project "$GI" >/dev/null 2>"$SB/gi-err"
assert_exit_code 0 $? "adopt proceeds on clean-looking tree with gitignored .claude"
grep -qi 'WARNING' "$SB/gi-err" && pass || fail "adopt should warn that .claude/ is gitignored"
GQ="$(ls -d "$GI/.claude/.savvy-detached-"* 2>/dev/null | head -1)"
assert_file_exists "$GQ/.claude/commands/sf/plan.md" "gitignored engine file quarantined, not deleted"
assert_contains "$GQ/.claude/commands/sf/plan.md" "LOCAL TWEAK" "local tweak survives despite no git protection"

finish
