#!/usr/bin/env bash
# run.sh — zero-dependency test runner for savvy-framework.
#
#   bash tests/run.sh              run every tests/test-*.sh
#   bash tests/run.sh adopt        run only files matching *adopt*
#
# Each test file runs in its own bash process so a crash in one cannot poison
# the others. A file passes iff it exits 0 (the `finish` helper enforces that
# all assertions in it passed). Requires: bash 3.2+, git, jq.

set -u
TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"

command -v jq >/dev/null 2>&1 || { echo "tests: jq is required" >&2; exit 1; }
command -v git >/dev/null 2>&1 || { echo "tests: git is required" >&2; exit 1; }

filter="${1:-}"
total=0; failed=0; failed_files=""

for t in "$TESTS_DIR"/test-*.sh; do
  [ -f "$t" ] || { echo "tests: no test files found" >&2; exit 1; }
  name="$(basename "$t")"
  if [ -n "$filter" ]; then
    case "$name" in *"$filter"*) ;; *) continue ;; esac
  fi
  total=$((total + 1))
  printf '== %s\n' "$name"
  if bash "$t"; then
    printf '   ok\n'
  else
    failed=$((failed + 1))
    failed_files="$failed_files $name"
  fi
done

echo
if [ "$total" -eq 0 ]; then
  echo "tests: no test files matched filter '$filter'" >&2
  exit 1
fi
if [ "$failed" -eq 0 ]; then
  printf 'ALL PASS (%d file(s))\n' "$total"
else
  printf 'FAILURES: %d of %d file(s):%s\n' "$failed" "$total" "$failed_files"
  exit 1
fi
