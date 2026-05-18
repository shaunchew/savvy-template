---
description: Convert scratchpad findings into a real spec or ADR; archives the scratchpad after.
argument-hint: "<NNN>-<name>"
---

# /promote-scratchpad

Convert a scratchpad's findings into a real spec or ADR, then archive the scratchpad with a pointer back to the promoted artifact.

## Procedure

1. Parse `$ARGUMENTS` as `<NNN>-<name>`. Validate format `^\d{3}-[a-z][a-z0-9-]*$`. On invalid input, print expected format and abort.
2. Resolve the folder `scratchpads/<NNN>-<name>/`. If missing, list active scratchpads and abort.
3. Read `SCRATCHPAD.md`, `notes.md`, `findings.md`, and list `generated/` contents. Summarise to the user in 5-10 lines: topic, key findings, what was prototyped.
4. Ask the user to choose a promotion target:
   ```
   Promote to:
     [s] spec    — pick category (product/marketing/ops/research)
     [a] adr     — write docs/decisions/NNN-<name>.md
     [b] both    — spec + ADR
     [c] cancel
   ```
5. Branch on the choice:
   - **spec / both:** prompt for category, then invoke the `spec-bootstrap` skill with the scratchpad findings as seed content for `spec.md` Background and `plan.md` Approach. It creates `specs/<category>/<NNN>-<name>/` with the four standard files.
   - **adr / both:** determine next ADR number from `docs/decisions/NNN-*.md`, then write `docs/decisions/<NNN>-<name>.md` with Context/Decision/Consequences drawn from `findings.md`.
   - **cancel:** stop without any writes.
6. Write `scratchpads/<NNN>-<name>/PROMOTED-TO.md` listing the new spec ref and/or ADR path with today's date and a one-line rationale.
7. Move the scratchpad folder from `scratchpads/<NNN>-<name>/` to `scratchpads/_archive/<NNN>-<name>/` (use `git mv` if tracked). Update `SCRATCHPAD.md` frontmatter `status: promoted`.
8. Run `/refresh-roadmap` if a spec was created.
9. Print a final summary: what was promoted, where it lives now, and where the scratchpad was archived.

## Arguments

- `$ARGUMENTS` — required `<NNN>-<name>` matching an existing folder under `scratchpads/`. Validate before any write.

## Invokes

- `spec-bootstrap` (when promoting to a spec)

## Output

A findings summary, a target prompt, then a final summary line. Files changed: new `specs/<category>/<NNN>-<name>/*` and/or `docs/decisions/<NNN>-<name>.md`, plus `scratchpads/_archive/<NNN>-<name>/PROMOTED-TO.md` and the moved scratchpad folder. Optionally `ROADMAP.md`.
