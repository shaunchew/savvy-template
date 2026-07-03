#!/usr/bin/env bash
# Idempotency: running adopt a second time must be a no-op — settings.json
# byte-stable, no duplicate hooks/deny entries, user edits to seeded files kept.
. "$(dirname "$0")/helpers.sh"

SB="$(make_sandbox)"
trap 'cleanup_sandbox "$SB"' EXIT

COPY="$SB/engine"
repo_copy "$COPY"

PROJ="$SB/twice-app"
make_git_project "$PROJ" "twice-app"

"$COPY/scripts/sf-adopt.sh" --project "$PROJ" >/dev/null 2>&1
assert_exit_code 0 $? "first adopt succeeds"

# User customizes a seeded file after adoption.
echo "USER CUSTOMIZATION" >> "$PROJ/AGENTS.md"
( cd "$PROJ" && git add -A && git commit -qm "post-adopt state" )

S="$PROJ/.claude/settings.json"
cp "$S" "$SB/settings.after-first.json"

"$COPY/scripts/sf-adopt.sh" --project "$PROJ" >/dev/null 2>&1
assert_exit_code 0 $? "second adopt succeeds"

# Settings stable: no growth, no duplicates.
assert_valid_json "$S" "settings.json still valid JSON"
assert_eq "$(jq -S . "$SB/settings.after-first.json" | hash_stdin)" \
          "$(jq -S . "$S" | hash_stdin)" \
          "settings.json semantically unchanged by re-adopt"
assert_eq "1" "$(jq '[.hooks.PreToolUse[]?.hooks[]?.command // "" | select(test("secret-scan"))] | length' "$S")" "secret-scan floor wired exactly once"
assert_eq "$(jq '.permissions.deny | length' "$S")" "$(jq '.permissions.deny | unique | length' "$S")" "no duplicate deny entries"

# Seeded files not re-overwritten.
assert_contains "$PROJ/AGENTS.md" "USER CUSTOMIZATION" "user edit to seeded file survives re-adopt"

# Re-adopt leaves the tree completely clean — strict no-op.
changed="$(cd "$PROJ" && git status --porcelain || true)"
assert_eq "" "$changed" "re-adopt produces no working-tree changes at all"

# --- keep-first backup: .savvy-old must always be the true PRE-adopt snapshot ---
PROJ2="$SB/backup-app"
make_git_project "$PROJ2" "backup-app"
mkdir -p "$PROJ2/.claude"
cat > "$PROJ2/.claude/settings.json" <<'EOF'
{ "permissions": { "deny": [] }, "userMarker": "ORIGINAL-PRE-ADOPT" }
EOF
( cd "$PROJ2" && git add -A && git commit -qm settings )
"$COPY/scripts/sf-adopt.sh" --project "$PROJ2" >/dev/null 2>&1
assert_contains "$PROJ2/.claude/settings.json.savvy-old" "ORIGINAL-PRE-ADOPT" "backup holds pre-adopt settings"
# user edits settings post-adopt, then re-adopts (e.g. after deleting a deny rule)
jq '.permissions.deny = []' "$PROJ2/.claude/settings.json" > "$PROJ2/.claude/settings.json.tmp" \
  && mv "$PROJ2/.claude/settings.json.tmp" "$PROJ2/.claude/settings.json"
( cd "$PROJ2" && git add -A && git commit -qm "user trimmed deny" )
"$COPY/scripts/sf-adopt.sh" --project "$PROJ2" >/dev/null 2>&1
assert_contains "$PROJ2/.claude/settings.json.savvy-old" "ORIGINAL-PRE-ADOPT" "re-adopt does NOT clobber the original backup"

finish
