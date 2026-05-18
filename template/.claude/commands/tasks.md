---
description: Generate or refresh tasks.md for a named spec — discrete steps with acceptance hooks.
argument-hint: "<category>/<NNN>"
---

# /tasks

Derive a discrete task list for a spec from its `plan.md`, preserving any prior progress.

## Procedure

1. Parse `$ARGUMENTS` as `<category>/<NNN>`. Resolve the spec folder by globbing `specs/<category>/<NNN>-*/`. Abort if zero or multiple matches.
2. Read the spec's `plan.md`. If it is still the empty template, stop and tell the user to run `/plan <category>/<NNN>` first.
3. Read the existing `tasks.md`. Build a map of previously-checked items (`- [x] ...`) so progress is not lost.
4. Derive a new task list from `plan.md`: numbered Markdown checkboxes (`1. - [ ] <description>`). Each task must be self-contained and small enough to verify; append a one-line acceptance hook in italics underneath where it isn't obvious (e.g. `_Acceptance: unit test passes for X._`).
5. Reconcile: for any new task whose description matches a previously-checked item, carry over the `[x]`. For checked items with no matching new task, move them under a `## Completed (carried over)` section at the bottom.
6. Write the result to `tasks.md`. Print the task count and the path.

## Arguments

- `$ARGUMENTS` — `<category>/<NNN>` (e.g. `product/003`).

## Output

`specs/<category>/<NNN>-*/tasks.md` rewritten with derived tasks plus carried-over checked items. Console prints task count and path.
