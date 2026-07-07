#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'
# sf-stack.sh — READ-ONLY polyglot stack detector.
#
# Walks a project (pruning vendored/build dirs, bounded depth) and reports the
# language and build stacks it finds BY MANIFEST FILE — never by counting file
# extensions — together with a plausible test and format command for each. This
# is the deterministic source /sf:intake and /sf:implement consult to answer
# "how do I test/format here" instead of guessing.
#
# Usage: sf-stack.sh [--project DIR] [--json]
# Exit codes: 0 = report produced (even when nothing is detected — this is a pure
#             report); 2 = usage/environment error (unknown arg, missing DIR, no jq).

command -v jq >/dev/null 2>&1 || { printf 'sf-stack.sh: jq is required\n' >&2; exit 2; }

PROJECT="$PWD"
JSON=0
MAXDEPTH=3
while [ $# -gt 0 ]; do
  case "$1" in
    --project) PROJECT="${2:-}"; shift 2 ;;
    --json)    JSON=1; shift ;;
    -h|--help) printf 'usage: sf-stack.sh [--project DIR] [--json]\n'; exit 0 ;;
    *) printf 'sf-stack.sh: unknown arg: %s\n' "$1" >&2; exit 2 ;;
  esac
done
[ -d "$PROJECT" ] || { printf 'sf-stack.sh: no such directory: %s\n' "$PROJECT" >&2; exit 2; }
PROJECT="$(cd "$PROJECT" && pwd)"

# --- one bounded, pruned filesystem pass --------------------------------------
# Absolute paths of every file within MAXDEPTH, skipping the usual noise dirs.
# `|| true`: find exits nonzero on unreadable subdirs, which set -e must ignore.
ALL="$(find "$PROJECT" -maxdepth "$MAXDEPTH" \
  \( -name .git -o -name node_modules -o -name vendor -o -name dist \
     -o -name build -o -name .venv -o -name target \) -prune \
  -o -type f -print 2>/dev/null || true)"

# first_match <case-glob> — echo the first ALL entry whose full path matches the
# glob (e.g. '*/package.json', '*/*.csproj'), or "" if none. A here-string (not a
# pipe) keeps this in-process so an early break cannot raise SIGPIPE under set -e.
first_match() {
  local f match=""
  while IFS= read -r f; do
    case "$f" in
      $1) match="$f"; break ;;
    esac
  done <<< "$ALL"
  printf '%s' "$match"
}

has() { [ -n "$(first_match "$1")" ]; }

rel() { # $1=absolute path under PROJECT -> project-relative path
  case "$1" in
    "$PROJECT"/*) printf '%s' "${1#"$PROJECT"/}" ;;
    *)            printf '%s' "$1" ;;
  esac
}

# --- accumulate detected stacks as a JSON array -------------------------------
STACKS='[]'
add_stack() { # kind name language manager manifest_abs test format
  STACKS="$(printf '%s' "$STACKS" | jq \
    --arg kind "$1" --arg name "$2" --arg language "$3" --arg manager "$4" \
    --arg manifest "$(rel "$5")" --arg test "$6" --arg format "$7" \
    '. + [{kind:$kind,name:$name,language:$language,manager:$manager,manifest:$manifest,test:$test,format:$format}]')"
}

# --- Node.js -------------------------------------------------------------------
pkg="$(first_match '*/package.json')"
if [ -n "$pkg" ]; then
  if   has '*/pnpm-lock.yaml'; then nm=pnpm; t="pnpm test"; fx="pnpm exec prettier --write ."
  elif has '*/yarn.lock';      then nm=yarn; t="yarn test"; fx="yarn prettier --write ."
  elif has '*/bun.lockb' || has '*/bun.lock'; then nm=bun; t="bun test"; fx="bunx prettier --write ."
  else nm=npm; t="npm test"; fx="npx prettier --write ."
  fi
  if has '*/tsconfig.json'; then lang=typescript; else lang=javascript; fi
  add_stack language "Node.js" "$lang" "$nm" "$pkg" "$t" "$fx"
fi

# --- Python --------------------------------------------------------------------
pyproj="$(first_match '*/pyproject.toml')"
setup="$(first_match '*/setup.py')"
reqs="$(first_match '*/requirements.txt')"
if [ -n "$pyproj" ] || [ -n "$setup" ] || [ -n "$reqs" ]; then
  if   has '*/uv.lock'; then nm=uv
  elif [ -n "$pyproj" ] && grep -q '^\[tool\.uv\]' "$pyproj" 2>/dev/null; then nm=uv
  elif has '*/poetry.lock'; then nm=poetry
  elif [ -n "$pyproj" ] && grep -q '^\[tool\.poetry\]' "$pyproj" 2>/dev/null; then nm=poetry
  else nm=pip
  fi
  case "$nm" in
    uv)     t="uv run pytest";     fx="uv run black ." ;;
    poetry) t="poetry run pytest"; fx="poetry run black ." ;;
    *)      t="pytest";            fx="black ." ;;
  esac
  add_stack language "Python" python "$nm" "${pyproj:-${setup:-$reqs}}" "$t" "$fx"
fi

# --- Rust ----------------------------------------------------------------------
cargo="$(first_match '*/Cargo.toml')"
if [ -n "$cargo" ]; then
  add_stack language "Rust" rust cargo "$cargo" "cargo test" "cargo fmt"
fi

# --- Go ------------------------------------------------------------------------
gomod="$(first_match '*/go.mod')"
if [ -n "$gomod" ]; then
  add_stack language "Go" go go "$gomod" "go test ./..." "gofmt -w ."
fi

# --- Ruby ----------------------------------------------------------------------
gemfile="$(first_match '*/Gemfile')"
if [ -n "$gemfile" ]; then
  add_stack language "Ruby" ruby bundler "$gemfile" "bundle exec rake test" "rubocop -a"
fi

# --- JVM (Maven / Gradle) ------------------------------------------------------
pom="$(first_match '*/pom.xml')"
gradle="$(first_match '*/build.gradle')"
gradlekts="$(first_match '*/build.gradle.kts')"
if [ -n "$pom" ]; then
  add_stack language "Java" java maven "$pom" "mvn test" "mvn spotless:apply"
elif [ -n "$gradle" ] || [ -n "$gradlekts" ]; then
  add_stack language "Java" java gradle "${gradle:-$gradlekts}" "gradle test" "gradle spotlessApply"
fi

# --- PHP -----------------------------------------------------------------------
composer="$(first_match '*/composer.json')"
if [ -n "$composer" ]; then
  add_stack language "PHP" php composer "$composer" "composer test" "php-cs-fixer fix"
fi

# --- Elixir --------------------------------------------------------------------
mix="$(first_match '*/mix.exs')"
if [ -n "$mix" ]; then
  add_stack language "Elixir" elixir mix "$mix" "mix test" "mix format"
fi

# --- .NET / C# -----------------------------------------------------------------
csproj="$(first_match '*/*.csproj')"
sln="$(first_match '*/*.sln')"
if [ -n "$csproj" ] || [ -n "$sln" ]; then
  add_stack language ".NET" csharp dotnet "${csproj:-$sln}" "dotnet test" "dotnet format"
fi

# --- CMake (C/C++) -------------------------------------------------------------
cmake="$(first_match '*/CMakeLists.txt')"
if [ -n "$cmake" ]; then
  add_stack build "CMake" cmake cmake "$cmake" "ctest" "clang-format -i"
fi

# --- Make ----------------------------------------------------------------------
makef="$(first_match '*/Makefile')"
if [ -n "$makef" ]; then
  add_stack build "Make" make make "$makef" "make test" ""
fi

# --- markers (infrastructure / CI presence, no test/format of their own) -------
docker=false
if has '*/Dockerfile' || has '*/docker-compose.yml' || has '*/docker-compose.yaml' \
   || has '*/compose.yml' || has '*/compose.yaml'; then
  docker=true
fi
ci=false
[ -d "$PROJECT/.github/workflows" ] && ci=true

# --- assemble the stable report object ----------------------------------------
OUT="$(jq -n \
  --arg project "$PROJECT" \
  --argjson stacks "$STACKS" \
  --argjson docker "$docker" \
  --argjson ci "$ci" \
  '{project:$project, stacks:$stacks, markers:{docker:$docker, ci:$ci}, count:($stacks|length)}')"

if [ "$JSON" -eq 1 ]; then
  printf '%s\n' "$OUT"
  exit 0
fi

# --- human-readable render -----------------------------------------------------
printf 'sf-stack: %s\n' "$PROJECT"
n="$(printf '%s' "$OUT" | jq -r '.count')"
if [ "$n" -eq 0 ]; then
  printf '  (no recognized stacks)\n'
else
  printf '%s' "$OUT" | jq -r '
    .stacks[]
    | "  \(.name)  [\(.manifest)]"
      + "\n      manager: \(.manager)   test: \(.test)"
      + (if .format == "" then "" else "   format: \(.format)" end)'
fi
markers="$(printf '%s' "$OUT" | jq -r '[.markers | to_entries[] | select(.value) | .key] | join(", ")')"
if [ -n "$markers" ]; then
  printf '  markers: %s\n' "$markers"
fi
printf '  %s stack(s) detected\n' "$n"
exit 0
