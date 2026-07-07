---
description: Checkpointed, task-by-task execution of a spec's tasks.md — one task, one commit; runs tests, ticks the checkbox, and stops on red.
argument-hint: "<category>/<NNN> [--task N] [--continue]"
---

# /sf:implement

Execute a spec's `tasks.md` one task at a time, committing each completed task on its own so progress is attributable and resumable. The disciplined executor that sits between planning a spec and shipping it.

## Procedure

1. Parse `$ARGUMENTS`. The first token is a spec reference — either `<category>/<NNN>` (validate `^[a-z-]+/\d{3}$`) or a spec folder path. Resolve the folder by globbing `specs/<category>/<NNN>-*/`; abort if zero or multiple match. Optional flags: `--task N` (run exactly task N, then stop) and `--continue` (resume at the first unchecked task).
2. Refuse unless this is an adopted project (`.claude/config.toml` with a `[framework]` marker). If absent, print a one-line refusal pointing at `/sf:adopt`.
3. Refuse on a dirty git tree (`git status --porcelain` non-empty) — every task must land as its own commit, so the tree must start clean. Tell the user to commit or stash first.
4. Read the spec's `tasks.md`. If the folder or file is missing, refuse with a one-liner pointing at `/sf:spec`. If it is still the empty bootstrap template, point at `/sf:tasks`. If it has no unchecked (`- [ ]`) tasks, report the spec already implemented and suggest `/sf:ship <category>/<NNN>`.
5. Invoke the `task-executor` skill with the resolved spec path and the selected mode. The skill establishes the test command (from `tasks.md` frontmatter, else asking once and recording it), then runs the checkpointed loop: restate each task, implement it touching only in-scope files, run the tests, tick the checkbox with a one-line result note, and commit `task(<NNN>.<n>): <title>`. It halts on a test failure or on any task that needs out-of-scope changes.
6. Hard cap: one spec per invocation. When the skill returns, relay its run summary — tasks completed this run, tasks remaining, and the next step.

## Arguments

- `$ARGUMENTS` — `<category>/<NNN>` (or a spec folder path), optionally followed by `--task N` or `--continue`. Default (no flag) walks every unchecked task in order; `--continue` is the explicit resume alias; `--task N` runs exactly one.

## Invokes / invoked by

- `task-executor` — receives the resolved spec path and mode; runs the task-by-task commit loop.
- Flow position: consumes the `tasks.md` produced by `/sf:plan` → `/sf:tasks`; feeds `/sf:ship` once every box is ticked.
- `/sf:handover` captures mid-implement state without extra bookkeeping — the `tasks.md` checkboxes *are* the state.
- On out-of-scope work, defers to `/sf:spec-revise` rather than improvising.

## Output

One git commit per completed task (`task(<NNN>.<n>): <title>`), `tasks.md` checkboxes ticked with one-line result notes, and a run summary. On a red test or out-of-scope task, a halt report with the changes left in the tree for inspection.
