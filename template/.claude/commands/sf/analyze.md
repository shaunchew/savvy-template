---
description: Read-only cross-artifact consistency check over spec.md, plan.md, and tasks.md before implementation — verifies criteria-to-task coverage, flags orphan tasks and contradictions, and checks constitution alignment.
argument-hint: "<category>/<NNN>"
---

# /sf:analyze

Audit a spec's three artifacts for internal consistency *after* `/sf:plan` and `/sf:tasks`, *before* `/sf:implement`. Read-only: it reports findings and changes nothing.

## Procedure

1. Requires an adopted project. If there is no `specs/` tree, tell the user to run `/sf:adopt` and exit.
2. Parse `$ARGUMENTS` as `<category>/<NNN>` (or a full spec-folder path). Resolve the folder by globbing `specs/<category>/<NNN>-*/`. Abort if zero or multiple matches.
3. Read `spec.md`, `plan.md`, `tasks.md`, and `constitution.md`. If `plan.md` or `tasks.md` is missing or still the empty template, stop and point the user to `/sf:plan` (then `/sf:tasks`).
4. Run the cross-artifact checks and collect findings:
   - **Coverage** — every acceptance criterion in `spec.md` maps to ≥1 task in `tasks.md`.
   - **Traceability** — every task traces back to a spec requirement; flag orphan tasks with no spec basis.
   - **Phase coverage** — `plan.md` phases collectively cover every spec requirement; flag any requirement no phase addresses.
   - **Contradictions** — conflicting claims across the three files (scope, ordering, naming, data shapes).
   - **Constitution** — anything that violates a principle in `constitution.md`.
5. Print a findings report grouped by check, each finding tagged `[CRITICAL]` / `[WARN]` / `[INFO]` with a one-line pointer to the offending file and line. If everything passes, say so explicitly.
6. Change nothing on disk. End by offering `/sf:spec-revise <category>/<NNN>` to fix findings, or `/sf:implement <category>/<NNN>` if clean.

## Arguments

- `$ARGUMENTS` — `<category>/<NNN>` (e.g. `product/003`) or a full spec-folder path.

## Invokes / invoked by

Flow position: `spec → clarify → plan → analyze → implement → ship`. Runs after `/sf:tasks`, before `/sf:implement`; its pre-planning complement is `/sf:clarify`. Read-only — never edits any file.

## Output

A severity-tagged findings report printed to the console. No files are modified. Ends with a suggested next command (`/sf:spec-revise` or `/sf:implement`).
