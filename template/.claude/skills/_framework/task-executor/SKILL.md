---
name: task-executor
description: Triggered by /sf:implement to execute a spec's tasks.md task-by-task — restate, implement in-scope, run tests, tick the checkbox, and checkpoint-commit one task at a time. Stops on a red test or out-of-scope work; never barrels on failure.
---

# Task Executor

Executes a spec's `tasks.md` as a disciplined, checkpointed loop: one task, one commit. The `tasks.md` checkboxes are the durable state — after each task-commit the loop re-reads the file, so it survives interruption and a `/sf:handover` mid-run captures exactly where things stand.

## When to invoke

- User runs `/sf:implement <category>/<NNN>` (optionally `--task N` or `--continue`).
- Do NOT invoke for authoring a spec (`/sf:spec`), planning (`/sf:plan`), deriving tasks (`/sf:tasks`), or shipping (`/sf:ship`).

## Procedure

Preconditions (the command checks these, but re-assert before any write):

1. **Adopted project.** `.claude/config.toml` must carry a `[framework]` marker. If absent, refuse and point at `/sf:adopt`.
2. **Clean tree.** `git status --porcelain` must be empty. Refuse otherwise — each task-commit has to be attributable to exactly one task, which is impossible on top of unrelated dirty changes.
3. **Task set.** Read `tasks.md`. Select tasks by mode: `--task N` picks that one numbered task; `--continue` and the default both take every unchecked `- [ ]` task in file order, starting at the first. Hard cap: one spec per invocation — never follow a reference into another spec's `tasks.md`.
4. **Test command.** Read `tasks.md` frontmatter for a `test:` key. If missing, run `bash "${CLAUDE_PLUGIN_ROOT}/scripts/sf-stack.sh"` (deterministic, read-only) to detect a plausible one, propose it to the user for confirmation ("What command runs this project's tests?" with the detected suggestion), and write the answer into the frontmatter so `--continue` and later runs don't re-ask.

Then, for each selected task in order:

5. **Restate.** Print the task text and its acceptance criteria (the italic `_Acceptance:_` hook, if present) before touching any code, so the intended outcome is explicit.
6. **Implement.** Make the change, touching only the files the task calls for. Scope guard: if the task turns out to require out-of-scope changes, STOP — do not improvise. Report what extra surface it needs and propose `/sf:spec-revise <category>/<NNN>` to widen the task; leave the tree as-is for the user.
7. **Test.** Run the recorded test command.
   - Pass → continue.
   - Fail → HALT on this task. Never barrel on red. Leave the changes in the working tree and the checkbox unticked; report the failing output and ask the user how to proceed.
8. **Record.** In `tasks.md`, flip the task's `- [ ]` to `- [x]` and append a one-line result note after the description (e.g. `— 12 tests green, added parser + fixture`).
9. **Checkpoint.** Stage only the files this task touched plus `tasks.md`, then commit with a plain `git commit` — respect the user's git config and any authorship convention in their global `~/.claude/CLAUDE.md`; NEVER hardcode `--author`. Message: `task(<NNN>.<n>): <task title>`. One task = one commit.
10. **Re-read before the next task.** Reload `tasks.md` from disk — the user may have edited it (reordered, added, or hand-checked tasks) between commits. Honor those edits and recompute the next unchecked task from the reloaded file.
11. **Finish.** When the task set is exhausted (or after the single `--task N`), stop. Report tasks completed this run, tasks remaining, and the next step. If none remain, suggest `/sf:ship <category>/<NNN>`.

## Invokes / invoked by

- `/sf:implement` — entry point; passes the resolved spec path and mode.
- `/sf:spec-revise` — proposed (not auto-run) when a task needs out-of-scope changes.
- `/sf:ship` — the suggested next step once every checkbox is ticked.

## Output

- One git commit per completed task (`task(<NNN>.<n>): <title>`), each staging only that task's files plus `tasks.md`.
- `tasks.md` checkboxes ticked with one-line result notes, and a `test:` frontmatter key once established.
- A run summary: tasks done this run, tasks remaining, next step (`/sf:ship` when done).

## Failure modes

- **Spec folder or `tasks.md` missing** → refuse; point at `/sf:spec`.
- **No unchecked tasks** → report the spec already implemented; suggest `/sf:ship`.
- **Not an adopted project** (no `.claude/config.toml` `[framework]` marker) → refuse; point at `/sf:adopt`.
- **Dirty tree at start** → refuse until the user commits or stashes.
- **A task's tests fail** → HALT on that task; leave the changes uncommitted and the checkbox unticked; ask how to proceed. Do not attempt the next task.
- **Task needs out-of-scope changes** → HALT; propose `/sf:spec-revise`; do not improvise the extra changes.
- **Test command unknown and the user declines to supply one** → cannot verify a task; refuse to mark any task done.
