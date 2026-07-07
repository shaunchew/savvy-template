---
description: Brownfield convergence — survey an existing codebase read-only and write an as-built baseline under docs/as-built/ so spec-driven work has ground truth. Create-if-absent; --refresh diffs before overwriting.
argument-hint: "[--refresh]"
---

# /sf:map

Build an **as-built baseline** of an existing codebase — what the project actually is, right now, read from its own source. This gives `/sf:spec` and `/sf:plan` ground truth to converge on instead of guessing. Read-only over your code; writes land only under `docs/as-built/`.

## Procedure

1. Confirm this is an adopted project — `.claude/config.toml` must carry a `[framework]` marker. If it does not, refuse in one line, point the user at `/sf:adopt`, and change nothing.
2. Invoke the `project-map` skill, passing `$ARGUMENTS` through (`--refresh` or empty).
3. The skill surveys the tree read-only, clusters it into at most ~6 areas, and writes `docs/as-built/README.md` (the index) plus one `docs/as-built/<area>.md` per area — each capturing purpose, key files, observed invariants, and the KNOWN-UNKNOWNS the code cannot answer.
4. On completion, print the index path, the area docs written, and the count of KNOWN-UNKNOWNS raised for the user to resolve.

## Arguments

- `$ARGUMENTS` — optional `--refresh`. Absent: create-if-absent, and refuse if `docs/as-built/` already exists. Present: re-survey and update existing docs, but only after showing a diff summary and getting confirmation.

## Invokes / invoked by

- Invokes `project-map` — receives `$ARGUMENTS`; owns the survey, the safety contract, and every write.
- Suggested by `/sf:intake` for brownfield repos (an existing codebase rather than a fresh scaffold).
- Consumed by `/sf:spec` and `/sf:plan`, which may cite `docs/as-built/` as ground truth.

## Output

`docs/as-built/README.md` plus up to six `docs/as-built/<area>.md` files (create-if-absent, or diffed-and-confirmed under `--refresh`). Console prints the index path and the list of KNOWN-UNKNOWNS to resolve. No source file is modified; no build or test command is run.

## Failure modes

- Not an adopted project (no `[framework]` in `.claude/config.toml`) → refuse in one line, suggest `/sf:adopt`.
- `docs/as-built/` already exists and `--refresh` not passed → print what is there and stop.
- Giant monorepo → map top-level workspaces only and say so; deeper areas become linked follow-ups, not guesses.
