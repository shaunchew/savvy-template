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

# Fake credentials are ASSEMBLED AT RUNTIME (prefix + body concatenation) so no
# secret-shaped literal ever exists in this file — otherwise GitHub push
# protection and every adopter's secret scanner flags the test suite itself.
body="abcdefghijklmnopqrstuvwxyz123456"
aws_key="AKIA$(printf 'IOSFODNN7EXAMPLE')"
gh_pat="ghp_$(printf '0123456789%s12' "${body%??????}")"
slack_tok="xoxb-$(printf '1234567890-abcdefghij')"
stripe_key="sk_live_$(printf '%s' "${body%????????}")"
openai_key="sk-$(printf '%s' "$body")"

# --- must BLOCK (exit 2) --------------------------------------------------------
assert_eq 2 "$(run_hook "export AWS_KEY=$aws_key")" "blocks AWS access key ID"
assert_eq 2 "$(run_hook "echo $gh_pat > tok")" "blocks GitHub PAT"
assert_eq 2 "$(run_hook "curl -H \"Authorization: Bearer $slack_tok\"")" "blocks Slack token"
assert_eq 2 "$(run_hook "STRIPE=$stripe_key")" "blocks Stripe live key"
assert_eq 2 "$(run_hook "export OPENAI_API_KEY=$openai_key")" "blocks sk- style key"
assert_eq 2 "$(run_hook 'echo "-----BEGIN RSA PRIVATE KEY-----" > k.pem')" "blocks RSA private key header"
assert_eq 2 "$(run_hook 'echo "-----BEGIN PRIVATE KEY-----" > k.pem')" "blocks bare private key header (optional type group)"
assert_eq 2 "$(run_hook "password = 'hunter2hunter2hunter2'")" "blocks generic credential assignment"

# --- must ALLOW (exit 0) --------------------------------------------------------
assert_eq 0 "$(run_hook 'npm test')" "allows plain command"
assert_eq 0 "$(run_hook 'grep -r password_reset src/')" "allows innocent mention of password"
assert_eq 0 "$(run_hook 'git commit -m "rotate api key handling"')" "allows commit message about keys"
assert_eq 0 "$(run_hook 'curl --token=$MY_TOKEN https://api.example.com')" "allows unquoted var-based token flag"
assert_eq 0 "$(run_hook 'ls -la ~/.ssh/')" "allows listing key dir"
assert_eq 0 "$(run_hook 'mv desk-organizer-listing-tool-v2 archive/')" "allows kebab-case word containing sk-"
assert_eq 0 "$(run_hook 'cat docs/risk-assessment-2026-final-draft.md')" "allows risk-assessment style filenames"

# --- resilience -----------------------------------------------------------------
printf '' | bash "$HOOK" >/dev/null 2>&1
assert_exit_code 0 $? "empty stdin exits 0"
printf 'this is not json' | bash "$HOOK" >/dev/null 2>&1
assert_exit_code 0 $? "garbage stdin exits 0"
printf '{"tool_input":{}}' | bash "$HOOK" >/dev/null 2>&1
assert_exit_code 0 $? "missing command field exits 0"

# Block message names the pattern on stderr (Claude shows this to the user).
msg="$(printf '{"tool_input":{"command":"x=%s"}}' "$aws_key" | bash "$HOOK" 2>&1 >/dev/null || true)"
case "$msg" in
  *"AWS access key"*) pass ;;
  *) fail "block message should name the matched pattern, got: $msg" ;;
esac

# The skeleton floor-guard copy must be identical to the engine copy (divergence
# means adopted projects run a stale scanner).
assert_same_content "$REPO_ROOT/hooks/secret-scan.sh" "$REPO_ROOT/skeleton/.claude/hooks/secret-scan.sh" "skeleton floor-guard matches engine copy"

finish
