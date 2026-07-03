#!/usr/bin/env bash
# secret-scan.sh contract: exit 2 + stderr message on secrets, exit 0 on
# everything else (including empty/garbage stdin — hooks must fail open).
. "$(dirname "$0")/helpers.sh"

SB="$(make_sandbox)"
trap 'cleanup_sandbox "$SB"' EXIT

HOOK="$REPO_ROOT/hooks/secret-scan.sh"

run_hook() { # $1=command-string -> echoes exit code
  printf '{"tool_input":{"command":%s}}' "$(printf '%s' "$1" | jq -Rs .)" | bash "$HOOK" >/dev/null 2>&1
  echo $?
}

# --- must BLOCK (exit 2) --------------------------------------------------------
assert_eq 2 "$(run_hook 'export AWS_KEY=AKIA_SCRUBBED')" "blocks AWS access key ID"
assert_eq 2 "$(run_hook 'echo ghp_SCRUBBED > tok')" "blocks GitHub PAT"
assert_eq 2 "$(run_hook 'curl -H "Authorization: Bearer xoxb-SCRUBBED"')" "blocks Slack token"
assert_eq 2 "$(run_hook 'STRIPE=sk_live_SCRUBBED')" "blocks Stripe live key"
assert_eq 2 "$(run_hook 'export OPENAI_API_KEY=sk-SCRUBBED')" "blocks sk- style key"
assert_eq 2 "$(run_hook 'echo "-----BEGIN RSA PRIVATE KEY-----" > k.pem')" "blocks RSA private key header"
assert_eq 2 "$(run_hook 'echo "-----BEGIN PRIVATE KEY-----" > k.pem')" "blocks bare private key header (optional type group)"
assert_eq 2 "$(run_hook "password = 'hunter2hunter2hunter2'")" "blocks generic credential assignment"

# --- must ALLOW (exit 0) --------------------------------------------------------
assert_eq 0 "$(run_hook 'npm test')" "allows plain command"
assert_eq 0 "$(run_hook 'grep -r password_reset src/')" "allows innocent mention of password"
assert_eq 0 "$(run_hook 'git commit -m "rotate api key handling"')" "allows commit message about keys"
assert_eq 0 "$(run_hook 'curl --token=$MY_TOKEN https://api.example.com')" "allows unquoted var-based token flag"
assert_eq 0 "$(run_hook 'ls -la ~/.ssh/')" "allows listing key dir"

# --- resilience -----------------------------------------------------------------
printf '' | bash "$HOOK" >/dev/null 2>&1
assert_exit_code 0 $? "empty stdin exits 0"
printf 'this is not json' | bash "$HOOK" >/dev/null 2>&1
assert_exit_code 0 $? "garbage stdin exits 0"
printf '{"tool_input":{}}' | bash "$HOOK" >/dev/null 2>&1
assert_exit_code 0 $? "missing command field exits 0"

# Block message names the pattern on stderr (Claude shows this to the user).
msg="$(printf '{"tool_input":{"command":"x=AKIA_SCRUBBED"}}' | bash "$HOOK" 2>&1 >/dev/null || true)"
case "$msg" in
  *"AWS access key"*) pass ;;
  *) fail "block message should name the matched pattern, got: $msg" ;;
esac

# The skeleton floor-guard copy must be identical to the engine copy (divergence
# means adopted projects run a stale scanner).
assert_same_content "$REPO_ROOT/hooks/secret-scan.sh" "$REPO_ROOT/skeleton/.claude/hooks/secret-scan.sh" "skeleton floor-guard matches engine copy"

finish
