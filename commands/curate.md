---
description: Review .claude/pending-changes.md and apply approved additions to AGENTS.md, CLAUDE.md, constitution.md, and integration configs.
---

# /sf:curate

Walk every entry in `.claude/pending-changes.md` and apply, reject, or defer each one. Rewrite the file when done.

## Procedure

1. Read `.claude/pending-changes.md`. If it contains zero entries (only the boilerplate intro or the literal `_(0 entries)_`), print `No pending changes.` and exit.
2. Parse entries by their `## YYYY-MM-DD HH:MM · <target-file> · <field>` headings. For each entry, present to the user:
   - Target file (AGENTS.md / CLAUDE.md / constitution.md / integration config).
   - Proposed content block.
   - Source (which `/sf:evolve` invocation and which spec, if recorded).
3. Offer three options per entry:
   - **Apply** — invoke the `framework-curator` skill with `(target_file, proposed_content)`. The skill validates placement against the decision tree (§5.10) and performs the actual edit. On success, mark the entry resolved.
   - **Reject** — ask the user for a one-line rationale. If they provide one, append it to `.claude/lessons.md` tagged `[mistake-avoided]` via the `lesson-recorder` skill. Mark the entry resolved.
   - **Defer** — leave the entry in place, move to the next.
4. After every entry has been processed, rewrite `.claude/pending-changes.md`:
   - Drop applied and rejected entries.
   - Keep deferred entries in chronological order under the original header.
   - If zero entries remain, write the file as the boilerplate intro plus `_(0 entries)_`.
5. Print a tally: `<N> applied, <M> rejected, <K> deferred`.

## Invokes

- `framework-curator` — receives `(target_file, proposed_content)` per Apply; validates placement and performs the edit.
- `lesson-recorder` — receives rejection rationale text when provided; appends a `[mistake-avoided]` lesson.

## Output

`.claude/pending-changes.md` rewritten with only deferred entries (or empty marker). Edits applied to one or more of AGENTS.md / CLAUDE.md / constitution.md / integration configs. Optional new entries in `.claude/lessons.md`. Console prints a tally.
