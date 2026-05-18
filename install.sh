#!/usr/bin/env bash
#
# install.sh — one-liner installer for the Savvy Coding Framework.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/shaunchew/savvy-template/main/install.sh | bash
#   curl -fsSL https://raw.githubusercontent.com/shaunchew/savvy-template/main/install.sh | bash -s -- my-project
#   curl -fsSL https://raw.githubusercontent.com/shaunchew/savvy-template/main/install.sh | bash -s -- . --defaults
#
# Default target is the current directory (.). Pass a path as the first arg to
# scaffold into a new subdirectory or absolute path. Additional flags are
# forwarded to `copier copy`.
#
# What it does:
#   1. Ensures `uv` is installed (so `uvx` is available).
#   2. Runs `uvx copier copy gh:shaunchew/savvy-template <target>` with any
#      forwarded flags.

set -euo pipefail

REPO="gh:shaunchew/savvy-template"
TARGET="${1:-.}"
shift || true   # consume target if it was supplied

say() { printf 'savvy-install: %s\n' "$*" >&2; }
die() { say "error: $*"; exit 1; }

# --- ensure uv ---------------------------------------------------------------
if ! command -v uv >/dev/null 2>&1; then
  say "uv not found — installing via astral.sh/uv/install.sh"
  curl -LsSf https://astral.sh/uv/install.sh | sh
  # Make `uv` visible in this script's PATH after install.
  export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"
  command -v uv >/dev/null 2>&1 || die "uv install completed but binary not on PATH. Open a new shell and re-run."
fi

# --- run copier --------------------------------------------------------------
say "running: uvx copier copy $REPO $TARGET $*"
exec uvx copier copy "$REPO" "$TARGET" "$@"
