---
description: Author or refresh plan.md for a named spec — technical approach, file layout, and sequencing.
argument-hint: "<category>/<NNN>"
---

# /plan

Draft or refresh `plan.md` for an existing spec — technical approach, files touched, sequencing, risks.

## Procedure

1. Parse `$ARGUMENTS` as `<category>/<NNN>`. Resolve the spec folder by globbing `specs/<category>/<NNN>-*/`. If zero or multiple matches, abort with the candidates listed.
2. Read the spec's `spec.md` and `plan.md`, and read `constitution.md` for invariants to respect.
3. Walk the user through filling each section in `plan.md`, preserving any existing content the user wants to keep:
   - `## Approach` — the technical strategy in 3-8 bullets.
   - `## Files` — paths that will be created or modified, grouped logically.
   - `## Sequencing` — ordered phases of work; each phase should be independently testable where possible.
   - `## Risks` — what could break, blockers, dependencies, rollback considerations.
4. Confirm with the user before writing. Then write the result back to the spec's `plan.md`.
5. Enforce length budget: target 150 lines, hard ceiling 300. If over, ask the user what to trim before writing.
6. Print a one-line summary and the file path on completion.

## Arguments

- `$ARGUMENTS` — `<category>/<NNN>` (e.g. `product/003`). Category from {product, marketing, ops, research}; NNN is the three-digit spec number.

## Output

`specs/<category>/<NNN>-*/plan.md` rewritten with the four sections filled. Console prints the path and final line count.
