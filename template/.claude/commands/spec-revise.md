---
description: Revise spec.md/plan.md/tasks.md for an existing spec without re-bootstrapping.
argument-hint: "<category>/<NNN>"
---

# /spec-revise

Make targeted edits to an existing spec's `spec.md`, `plan.md`, or `tasks.md` without re-running `/spec`. Status changes trigger a roadmap refresh.

## Procedure

1. Parse `$ARGUMENTS` as `<category>/<NNN>` (e.g. `product/012`). Validate format with a regex like `^[a-z-]+/\d{3}$`. If invalid, print expected format and abort.
2. Locate the spec folder by globbing `specs/<category>/<NNN>-*/`. If zero or multiple matches, list candidates and abort.
3. Read and display `spec.md`, `plan.md`, and `tasks.md` (truncate each to first ~40 lines for the preview). Show frontmatter `status:` for each.
4. Ask the user: "Which file(s) to revise? [spec/plan/tasks/all]" and "What change?". Accept free-form change description.
5. For each selected file, propose a unified-diff-style preview of the edit. Ask `Apply this edit? [y/n/skip]`. Apply approved edits via Edit (preserve frontmatter).
6. If any frontmatter `status:` field changed (e.g. `planning` -> `implementing`, `implementing` -> `shipped`), run `/refresh-roadmap` to rewrite `ROADMAP.md`.
7. Print a one-line summary: which files were revised and whether the roadmap was refreshed.

## Arguments

- `$ARGUMENTS` — spec reference in `<category>/<NNN>` form. Validate before doing anything else.

## Output

Inline previews of the spec's current state, per-file diff prompts, and a final summary listing files edited. Files changed: one or more of `specs/<category>/<NNN>-*/spec.md`, `plan.md`, `tasks.md`, and optionally `ROADMAP.md`.
