#!/usr/bin/env bash
# The reversibility trio: adopt --dry-run changes nothing, sf-doctor is
# read-only and truthful, sf-eject round-trips a greenfield adopt back to
# (almost) pristine while preserving user edits.
. "$(dirname "$0")/helpers.sh"

SB="$(make_sandbox)"
trap 'cleanup_sandbox "$SB"' EXIT

COPY="$SB/engine"
repo_copy "$COPY"

# --- adopt --dry-run: full plan, zero mutations -----------------------------------
DR="$SB/dryrun-app"
make_git_project "$DR" "dryrun-app"
mkdir -p "$DR/.claude/commands/sf"
echo "legacy" > "$DR/.claude/commands/sf/plan.md"
( cd "$DR" && git add -A && git commit -qm fixture )

out="$("$COPY/scripts/sf-adopt.sh" --project "$DR" --dry-run 2>&1)"
assert_exit_code 0 $? "dry-run exits 0"
case "$out" in
  *DRY-RUN*) pass ;;
  *) fail "dry-run output should say DRY-RUN: $out" ;;
esac
case "$out" in
  *AGENTS.md*) pass ;;
  *) fail "dry-run plan should list files it would seed" ;;
esac
changed="$(cd "$DR" && git status --porcelain)"
assert_eq "" "$changed" "dry-run leaves the working tree untouched"
assert_file_exists "$DR/.claude/commands/sf/plan.md" "dry-run does not detach anything"

# --- doctor: read-only, correct verdicts ------------------------------------------
# Healthy adopted project:
AD="$SB/healthy-app"
make_git_project "$AD" "healthy-app"
"$COPY/scripts/sf-adopt.sh" --project "$AD" >/dev/null 2>&1
before="$(cd "$AD" && find . -not -path './.git/*' | LC_ALL=C sort | hash_stdin)"
( cd "$AD" && bash "$COPY/scripts/sf-doctor.sh" >/dev/null 2>&1 )
assert_exit_code 0 $? "doctor exits 0 on healthy adopted project"
after="$(cd "$AD" && find . -not -path './.git/*' | LC_ALL=C sort | hash_stdin)"
assert_eq "$before" "$after" "doctor creates/removes nothing"

# Plain project without .claude/ (pre-adoption first contact): full report, exit 0.
PL="$SB/plain-app"
make_git_project "$PL" "plain-app"
d_plain="$(cd "$PL" && bash "$COPY/scripts/sf-doctor.sh" 2>&1)"
assert_exit_code 0 $? "doctor exits 0 on plain project with no .claude/"
case "$d_plain" in
  *"problem(s)"*) pass ;;
  *) fail "doctor must print its summary line on a plain project (report truncated?): $d_plain" ;;
esac

# Unreadable subdir must not kill the report.
UD="$SB/unreadable-app"
make_git_project "$UD" "unreadable-app"
"$COPY/scripts/sf-adopt.sh" --project "$UD" >/dev/null 2>&1
mkdir -p "$UD/vendor/locked"
chmod a-rx "$UD/vendor/locked"
( cd "$UD" && bash "$COPY/scripts/sf-doctor.sh" >/dev/null 2>&1 )
rc=$?
chmod u+rx "$UD/vendor/locked"
assert_eq 0 "$rc" "doctor survives an unreadable subdir"

# Broken project (invalid settings JSON) → exit 1:
BR="$SB/broken-app"
make_git_project "$BR" "broken-app"
mkdir -p "$BR/.claude"
printf '[framework]\nversion = "1.4.0"\n' > "$BR/.claude/config.toml"
echo '{ nope' > "$BR/.claude/settings.json"
( cd "$BR" && bash "$COPY/scripts/sf-doctor.sh" >/dev/null 2>&1 )
rc=$?
assert_eq 1 "$rc" "doctor exits 1 when settings.json is invalid"

# Doctor flags legacy manifest leftovers:
echo '{}' > "$AD/.claude/.savvy-manifest.json"
d_out="$(cd "$AD" && bash "$COPY/scripts/sf-doctor.sh" 2>&1 || true)"
case "$d_out" in
  *"legacy baseline manifest"*) pass ;;
  *) fail "doctor should warn about leftover legacy manifest" ;;
esac
rm -f "$AD/.claude/.savvy-manifest.json"

# --- eject: round-trip preserves user work ------------------------------------------
EJ="$SB/eject-app"
make_git_project "$EJ" "eject-app"
"$COPY/scripts/sf-adopt.sh" --project "$EJ" >/dev/null 2>&1
( cd "$EJ" && git add -A && git commit -qm adopted )
# user edits one seeded file and adds their own file
echo "MY ROADMAP EDITS" >> "$EJ/ROADMAP.md"
echo "user file" > "$EJ/notes.md"
( cd "$EJ" && git add -A && git commit -qm "user work" )

"$COPY/scripts/sf-eject.sh" --project "$EJ" >/dev/null 2>&1
assert_exit_code 0 $? "eject exits 0"

# Unedited seeds gone from live tree, preserved in quarantine.
assert_file_absent "$EJ/AGENTS.md" "unedited seeded AGENTS.md removed"
assert_file_absent "$EJ/constitution.md" "unedited seeded constitution removed"
Q="$(ls -d "$EJ/.claude/.savvy-detached-"* 2>/dev/null | head -1)"
assert_file_exists "$Q/AGENTS.md" "removed seed preserved in quarantine"

# Edited seed + user file kept.
assert_file_exists "$EJ/ROADMAP.md" "edited seeded file kept"
assert_contains "$EJ/ROADMAP.md" "MY ROADMAP EDITS" "user edits intact"
assert_file_exists "$EJ/notes.md" "user's own file untouched"

# Plugin disabled; secret-scan floor unwired; settings still valid JSON.
S="$EJ/.claude/settings.json"
assert_valid_json "$S" "settings.json valid after eject"
assert_eq "" "$(jq -r '.enabledPlugins["sf@savvy"] // empty' "$S")" "sf@savvy disabled"
assert_eq "false" "$(jq '[.hooks.PreToolUse[]?.hooks[]?.command // ""] | any(test("secret-scan"))' "$S")" "floor wiring stripped"

# Work dirs (empty) removed.
assert_file_absent "$EJ/specs" "empty specs/ removed"

# Guards: eject refuses dirty tree.
EJ2="$SB/eject-dirty"
make_git_project "$EJ2" "eject-dirty"
"$COPY/scripts/sf-adopt.sh" --project "$EJ2" >/dev/null 2>&1
echo wip > "$EJ2/wip.txt"
"$COPY/scripts/sf-eject.sh" --project "$EJ2" >/dev/null 2>&1
rc=$?
assert_ne "0" "$rc" "eject refuses dirty tree without --yes"
assert_file_exists "$EJ2/AGENTS.md" "nothing ejected after refusal"

finish
