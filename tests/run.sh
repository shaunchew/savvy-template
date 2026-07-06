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
git -C "$TESTS_DIR/.." rev-parse --is-inside-work-tree >/dev/null 2>&1 \
  || { echo "tests: must run from a git checkout (fixtures are built with git ls-files)" >&2; exit 1; }

# Pin the interpreter: test bodies and the scripts they invoke must run under the
# SAME bash that launched this runner ($BASH), not whatever `bash` PATH resolves
# to — otherwise the macOS CI job's "system bash 3.2" pin silently stops at run.sh.
SHIM_DIR="$(mktemp -d "${TMPDIR:-/tmp}/savvy-bash-shim.XXXXXX")"
trap 'rm -rf -- "$SHIM_DIR"' EXIT
ln -s "${BASH:-/bin/bash}" "$SHIM_DIR/bash"
PATH="$SHIM_DIR:$PATH"
export PATH

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
