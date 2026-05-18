---
description: Create a new spec folder with spec.md/plan.md/tasks.md/checklist.md, auto-numbered within category, and update ROADMAP.
argument-hint: "<category>/<name>"
---

# /spec

Bootstrap a single new spec folder with the four canonical files and update ROADMAP.

## Procedure

1. Parse `$ARGUMENTS` as `<category>/<name>`. If the format does not match, abort with a usage hint and exit.
2. Validate `<category>` is one of `product`, `marketing`, `ops`, `research`. If not, abort and list the valid categories.
3. Validate `<name>` matches kebab-case (`^[a-z0-9]+(-[a-z0-9]+)*$`). If not, abort with the rule and an example.
4. Invoke the `spec-bootstrap` skill with `category=<category>` and `name=<name>`. The skill auto-numbers within the category, creates `specs/<category>/<NNN>-<name>/` with `spec.md`, `plan.md`, `tasks.md`, `checklist.md`, pre-fills frontmatter, and updates `ROADMAP.md`.
5. On success, print the created folder path (e.g. `specs/product/003-google-oauth/`) and the suggested branch name (`<category>/<NNN>-<name>`).
6. On failure, surface the skill's error verbatim — do not retry silently.

## Arguments

- `$ARGUMENTS` — single token `<category>/<name>`. Example: `product/google-oauth`. Category from {product, marketing, ops, research}; name kebab-case.

## Invokes

- `spec-bootstrap` — receives parsed `category` and `name`; returns the created folder path and assigned `NNN`.

## Output

A new `specs/<category>/<NNN>-<name>/` folder containing four files, an updated `ROADMAP.md`, and a printed summary with the folder path and suggested branch name.
