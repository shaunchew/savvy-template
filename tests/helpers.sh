# shellcheck shell=bash
# helpers.sh — shared test helpers for the savvy-framework test suite (sourced, not executed).
#
# Constraints honored throughout:
#   * bash 3.2 compatible (macOS system bash): no associative arrays, no mapfile,
#     no ${var,,}, no &>>.
#   * Zero external test-framework dependencies. jq and git are required (same
#     runtime deps as the framework itself).
#   * Every test runs in an isolated tmpdir; the repo under test is a pristine
#     copy (git archive of HEAD + working-tree overlay), never the real checkout.

set -u

# Repo root = parent of tests/.
TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$TESTS_DIR/.." && pwd)"

_pass_count=0
_fail_count=0
_fail_messages=""

# --- assertions ---------------------------------------------------------------

fail() { # $1=message — record a failure, keep going so one test file reports all
  _fail_count=$((_fail_count + 1))
  _fail_messages="${_fail_messages}
  FAIL: $1"
  printf '  FAIL: %s\n' "$1" >&2
}

pass() {
  _pass_count=$((_pass_count + 1))
}

assert_eq() { # $1=expected $2=actual $3=label
  if [ "$1" = "$2" ]; then pass; else fail "${3:-assert_eq}: expected [$1], got [$2]"; fi
}

assert_ne() { # $1=unexpected $2=actual $3=label
  if [ "$1" != "$2" ]; then pass; else fail "${3:-assert_ne}: value should differ from [$1]"; fi
}

assert_file_exists() { # $1=path $2=label
  if [ -f "$1" ]; then pass; else fail "${2:-file exists}: missing $1"; fi
}

assert_file_absent() { # $1=path $2=label
  if [ ! -e "$1" ]; then pass; else fail "${2:-file absent}: unexpectedly present $1"; fi
}

assert_dir_exists() { # $1=path $2=label
  if [ -d "$1" ]; then pass; else fail "${2:-dir exists}: missing $1"; fi
}

assert_contains() { # $1=file $2=needle $3=label
  if grep -qF -- "$2" "$1" 2>/dev/null; then pass; else fail "${3:-contains}: $1 does not contain [$2]"; fi
}

assert_not_contains() { # $1=file $2=needle $3=label
  if grep -qF -- "$2" "$1" 2>/dev/null; then fail "${3:-not_contains}: $1 contains [$2]"; else pass; fi
}

assert_valid_json() { # $1=file $2=label
  if jq -e . "$1" >/dev/null 2>&1; then pass; else fail "${2:-valid json}: $1 is not valid JSON"; fi
}

assert_exit_code() { # $1=expected $2=actual $3=label
  if [ "$1" -eq "$2" ]; then pass; else fail "${3:-exit code}: expected $1, got $2"; fi
}

assert_same_content() { # $1=file_a $2=file_b $3=label
  if cmp -s "$1" "$2"; then pass; else fail "${3:-same content}: $1 and $2 differ"; fi
}

# --- hashing (sha256sum on Linux, shasum on macOS) -----------------------------

if command -v sha256sum >/dev/null 2>&1; then
  hash_file() { sha256sum "$1" | cut -d' ' -f1; }
  hash_stdin() { sha256sum | cut -d' ' -f1; }
else
  hash_file() { shasum -a 256 "$1" | cut -d' ' -f1; }
  hash_stdin() { shasum -a 256 | cut -d' ' -f1; }
fi

# --- sandbox ------------------------------------------------------------------

# make_sandbox — echo a fresh tmpdir for this test file.
make_sandbox() {
  mktemp -d "${TMPDIR:-/tmp}/savvy-test.XXXXXX"
}

# cleanup_sandbox <dir> — guarded recursive delete: refuses anything that does
# not look like a sandbox this suite created.
cleanup_sandbox() {
  case "$1" in
    */savvy-test.*) rm -rf -- "$1" ;;
    *) printf 'cleanup_sandbox: refusing to delete %s\n' "$1" >&2; return 1 ;;
  esac
}

# repo_copy <dst> — copy of the repo working tree (tracked + untracked-but-not-
# ignored files at their current on-disk content, via git ls-files) into <dst>.
# Requires a git checkout — run.sh guards this.
repo_copy() {
  mkdir -p "$1"
  # Tracked + untracked-but-not-ignored files, honoring .gitignore.
  ( cd "$REPO_ROOT" && git ls-files -co --exclude-standard ) | while IFS= read -r f; do
    d="$1/$(dirname "$f")"
    mkdir -p "$d"
    cp -p "$REPO_ROOT/$f" "$1/$f"
  done
}

# make_git_project <dir> [name] — init a git repo with one commit so adopt's
# dirty-guard passes.
make_git_project() {
  mkdir -p "$1"
  ( cd "$1" \
    && git init -q \
    && git config user.email test@example.com \
    && git config user.name "Savvy Tests" \
    && printf '# %s\n' "${2:-fixture}" > EXISTING.md \
    && git add -A && git commit -qm init )
}

# --- runner protocol ----------------------------------------------------------

# finish — print per-file summary and exit non-zero on any failure.
# Every test-*.sh file must end with: finish
finish() {
  printf '  %d passed, %d failed\n' "$_pass_count" "$_fail_count"
  [ "$_fail_count" -eq 0 ]
}
