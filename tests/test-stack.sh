#!/usr/bin/env bash
# sf-stack.sh: deterministic, READ-ONLY polyglot stack detection by manifest file.
. "$(dirname "$0")/helpers.sh"

SB="$(make_sandbox)"
trap 'cleanup_sandbox "$SB"' EXIT

SCRIPT="$REPO_ROOT/scripts/sf-stack.sh"

# json_true <file> <jq-filter> <label> — pass iff the filter is truthy.
json_true() {
  if jq -e "$2" "$1" >/dev/null 2>&1; then pass; else fail "${3:-json_true}"; fi
}

# --- fixtures -----------------------------------------------------------------
# node + pnpm
mkdir -p "$SB/node/src"
printf '{"name":"x","scripts":{"test":"jest"}}\n' > "$SB/node/package.json"
printf 'lockfileVersion: 5.4\n' > "$SB/node/pnpm-lock.yaml"

# python + uv (pyproject with a [tool.uv] table, no lockfile needed)
mkdir -p "$SB/py/pkg"
printf '[project]\nname = "x"\n[tool.uv]\ndev-dependencies = []\n' > "$SB/py/pyproject.toml"

# rust
mkdir -p "$SB/rust/src"
printf '[package]\nname = "x"\n' > "$SB/rust/Cargo.toml"

# go
mkdir -p "$SB/go/cmd"
printf 'module example.com/x\n\ngo 1.22\n' > "$SB/go/go.mod"

# polyglot: node at root + python in a subdir
mkdir -p "$SB/poly/api"
printf '{"name":"x"}\n' > "$SB/poly/package.json"
printf '[project]\nname = "x"\n' > "$SB/poly/api/pyproject.toml"

# markers-only: Dockerfile + GitHub Actions, no language manifest
mkdir -p "$SB/infra/.github/workflows"
printf 'FROM alpine\n' > "$SB/infra/Dockerfile"
printf 'name: ci\n' > "$SB/infra/.github/workflows/ci.yml"

# empty
mkdir -p "$SB/empty"

# --- node ---------------------------------------------------------------------
bash "$SCRIPT" --project "$SB/node" > "$SB/node.out" 2>&1
assert_exit_code 0 $? "node: exit 0"
assert_contains "$SB/node.out" "Node.js" "node: stack name present"
assert_contains "$SB/node.out" "pnpm test" "node: pnpm test command"
bash "$SCRIPT" --project "$SB/node" --json > "$SB/node.json" 2>&1
assert_valid_json "$SB/node.json" "node: --json is valid JSON"
json_true "$SB/node.json" '.stacks[0] | has("kind") and has("name") and has("language") and has("manager") and has("manifest") and has("test") and has("format")' "node: stack object has all expected keys"
json_true "$SB/node.json" '. | has("project") and has("stacks") and has("markers") and has("count")' "node: top-level object has expected keys"
json_true "$SB/node.json" '.stacks[0].manager == "pnpm"' "node: manager is pnpm in JSON"
json_true "$SB/node.json" '.markers | has("docker") and has("ci")' "node: markers has docker+ci keys"
json_true "$SB/node.json" '.count == 1' "node: count is 1"

# --- python + uv --------------------------------------------------------------
bash "$SCRIPT" --project "$SB/py" > "$SB/py.out" 2>&1
assert_contains "$SB/py.out" "Python" "python: stack name present"
assert_contains "$SB/py.out" "uv run pytest" "python: uv test command"
bash "$SCRIPT" --project "$SB/py" --json > "$SB/py.json" 2>&1
assert_valid_json "$SB/py.json" "python: --json is valid JSON"
json_true "$SB/py.json" '.stacks[0].language == "python" and .stacks[0].manager == "uv"' "python: language+manager in JSON"
json_true "$SB/py.json" '.stacks[0].manifest == "pyproject.toml"' "python: manifest reported relative"

# --- rust ---------------------------------------------------------------------
bash "$SCRIPT" --project "$SB/rust" --json > "$SB/rust.json" 2>&1
assert_valid_json "$SB/rust.json" "rust: --json is valid JSON"
json_true "$SB/rust.json" '.stacks[0].language == "rust" and .stacks[0].test == "cargo test"' "rust: language+test in JSON"

# --- go -----------------------------------------------------------------------
bash "$SCRIPT" --project "$SB/go" --json > "$SB/go.json" 2>&1
assert_valid_json "$SB/go.json" "go: --json is valid JSON"
json_true "$SB/go.json" '.stacks[0].language == "go" and .stacks[0].test == "go test ./..."' "go: language+test in JSON"

# --- polyglot (node + python) -------------------------------------------------
bash "$SCRIPT" --project "$SB/poly" --json > "$SB/poly.json" 2>&1
assert_valid_json "$SB/poly.json" "poly: --json is valid JSON"
json_true "$SB/poly.json" '.count == 2' "poly: two stacks detected"
json_true "$SB/poly.json" '[.stacks[].language] as $l | ($l | index("javascript")) != null and ($l | index("python")) != null' "poly: both node and python detected"

# --- markers-only -------------------------------------------------------------
bash "$SCRIPT" --project "$SB/infra" > "$SB/infra.out" 2>&1
assert_contains "$SB/infra.out" "no recognized stacks" "infra: reports no language stacks"
assert_contains "$SB/infra.out" "docker" "infra: docker marker shown in human output"
bash "$SCRIPT" --project "$SB/infra" --json > "$SB/infra.json" 2>&1
json_true "$SB/infra.json" '.markers.docker == true and .markers.ci == true and .count == 0' "infra: docker+ci markers set, zero stacks"

# --- empty --------------------------------------------------------------------
bash "$SCRIPT" --project "$SB/empty" > "$SB/empty.out" 2>&1
assert_exit_code 0 $? "empty: exit 0 (pure report)"
assert_contains "$SB/empty.out" "no recognized stacks" "empty: reports no stacks"
bash "$SCRIPT" --project "$SB/empty" --json > "$SB/empty.json" 2>&1
json_true "$SB/empty.json" '.count == 0 and (.stacks | length) == 0' "empty: zero stacks in JSON"

# --- read-only: detection must not create/modify anything in the fixture ------
before="$(cd "$SB/poly" && find . | sort)"
bash "$SCRIPT" --project "$SB/poly" --json >/dev/null 2>&1
bash "$SCRIPT" --project "$SB/poly" >/dev/null 2>&1
after="$(cd "$SB/poly" && find . | sort)"
assert_eq "$before" "$after" "read-only: fixture tree unchanged after detection"

# --- usage errors -------------------------------------------------------------
bash "$SCRIPT" --bogus >/dev/null 2>&1
assert_exit_code 2 $? "unknown arg exits 2"
bash "$SCRIPT" --project "$SB/does-not-exist" >/dev/null 2>&1
assert_exit_code 2 $? "missing --project directory exits 2"

finish
