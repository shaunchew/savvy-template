#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'
# secret-scan.sh — blocks Bash commands containing common secret patterns. PreToolUse:Bash.

command -v jq >/dev/null 2>&1 || exit 0

payload="$(cat)"
[ -z "$payload" ] && exit 0

cmd="$(printf '%s' "$payload" | jq -r '.tool_input.command // empty' 2>/dev/null || true)"
[ -z "$cmd" ] && exit 0

# Each pattern is checked individually so we can report which one matched.
# Use printf '%s' to avoid escape interpretation; grep -E for ERE; -i for case-insensitive where safe.

block() {
  printf 'secret-scan.sh: blocked — likely secret in command (%s)\n' "$1" >&2
  exit 2
}

# AWS access key ID — strict case.
if printf '%s' "$cmd" | grep -E 'AKIA[0-9A-Z]{16}' >/dev/null 2>&1; then
  block "AWS access key ID"
fi

# AWS secret access key assignment.
if printf '%s' "$cmd" | grep -Ei "aws_secret_access_key[[:space:]]*=[[:space:]]*['\"]?[A-Za-z0-9/+=]{40}['\"]?" >/dev/null 2>&1; then
  block "AWS secret access key"
fi

# GitHub PATs (ghp_, gho_, ghu_, ghs_, ghr_).
if printf '%s' "$cmd" | grep -E 'gh[pousr]_[A-Za-z0-9]{36}' >/dev/null 2>&1; then
  block "GitHub token"
fi

# Slack tokens.
if printf '%s' "$cmd" | grep -E 'xox[abp]-[0-9A-Za-z-]{10,}' >/dev/null 2>&1; then
  block "Slack token"
fi

# Stripe live/test keys.
if printf '%s' "$cmd" | grep -E 'sk_(live|test)_[A-Za-z0-9]{20,}' >/dev/null 2>&1; then
  block "Stripe key"
fi

# OpenAI / Anthropic style sk- keys (must NOT match sk_live_/sk_test_ already handled).
# Require sk- (with dash) to avoid colliding with Stripe's sk_.
if printf '%s' "$cmd" | grep -E 'sk-[A-Za-z0-9_-]{20,}' >/dev/null 2>&1; then
  block "OpenAI/Anthropic-style API key"
fi

# Private key block headers.
# The key-type group is OPTIONAL via `( )?` — NOT a trailing-empty alternative `(RSA |...|)`,
# which ugrep/PCRE reject as an empty branch so the pattern silently never matches.
if printf '%s' "$cmd" | grep -E -- '-----BEGIN ((RSA|EC|OPENSSH|DSA|PGP) )?PRIVATE KEY-----' >/dev/null 2>&1; then
  block "private key block"
fi

# Generic api_key/secret/token/password assignment with a value >=16 chars in quotes.
# Keep this loose but require quoting to reduce false positives on flags like --token=...
if printf '%s' "$cmd" | grep -Ei "(api[_-]?key|secret|token|password)[[:space:]]*=[[:space:]]*['\"][^'\"]{16,}['\"]" >/dev/null 2>&1; then
  block "generic credential assignment"
fi

exit 0
