#!/usr/bin/env bash
# session-start.sh / session-end.sh: must no-op gracefully in projects that
# never adopted the framework (the plugin's hooks fire everywhere once enabled),
# never block, and never write into non-framework projects.
. "$(dirname "$0")/helpers.sh"

SB="$(make_sandbox)"
trap 'cleanup_sandbox "$SB"' EXIT

START="$REPO_ROOT/hooks/session-start.sh"
END="$REPO_ROOT/hooks/session-end.sh"

# --- non-framework project: silent no-op, zero writes ----------------------------
BARE="$SB/not-a-framework-project"
mkdir -p "$BARE/src"
before="$(find "$BARE" | LC_ALL=C sort)"
( cd "$BARE" && printf '{}' | bash "$START" >/dev/null 2>&1 )
assert_exit_code 0 $? "session-start exits 0 in non-framework project"
after="$(find "$BARE" | LC_ALL=C sort)"
assert_eq "$before" "$after" "session-start writes nothing into a non-framework project"

( cd "$BARE" && printf '{}' | bash "$END" >/dev/null 2>&1 )
assert_exit_code 0 $? "session-end exits 0 in non-framework project"

# --- non-framework project WITH a .claude dir (common for Claude Code users) ----
CC="$SB/claude-user-project"
mkdir -p "$CC/.claude"
before="$(find "$CC" | LC_ALL=C sort)"
( cd "$CC" && printf '{}' | CLAUDE_PLUGIN_ROOT="$REPO_ROOT" bash "$START" >/dev/null 2>&1 )
assert_exit_code 0 $? "session-start (plugin mode) exits 0 with bare .claude dir"
after="$(find "$CC" | LC_ALL=C sort)"
assert_eq "$before" "$after" "plugin-mode session-start must not write into a non-framework project's .claude"

# --- framework project: banner printed, engine stamp allowed --------------------
FW="$SB/framework-project"
mkdir -p "$FW/.claude"
cat > "$FW/.claude/config.toml" <<'EOF'
[framework]
version = "1.4.0"
variant = "solo"
EOF
out="$(cd "$FW" && printf '{}' | bash "$START" 2>&1)"
assert_exit_code 0 $? "session-start exits 0 in framework project"
case "$out" in
  *"v1.4.0"*) pass ;;
  *) fail "version banner missing from session-start output: $out" ;;
esac

# Plugin mode: engine version stamped into an ADOPTED project only.
( cd "$FW" && printf '{}' | CLAUDE_PLUGIN_ROOT="$REPO_ROOT" bash "$START" >/dev/null 2>&1 )
assert_file_exists "$FW/.claude/.savvy-engine-version" "engine version stamped in adopted project"

# --- hooks must drain stdin and never hang (3s watchdog) -------------------------
( cd "$FW" && printf '{}' | bash "$START" >/dev/null 2>&1 ) &
hpid=$!
n=0
while kill -0 "$hpid" 2>/dev/null; do
  n=$((n + 1))
  if [ "$n" -gt 30 ]; then kill "$hpid" 2>/dev/null; fail "session-start hung >3s"; break; fi
  sleep 0.1
done
[ "$n" -le 30 ] && pass

finish
