---
description: Move a superseded spec to specs/_archive/ with a reason note.
argument-hint: "<category>/<NNN>"
---

# /sf:spec-archive

Archive a spec that is being cancelled or superseded. Move the folder to `specs/_archive/`, mark its status, capture the rationale, and refresh the roadmap.

## Procedure

1. Parse `$ARGUMENTS` as `<category>/<NNN>`. Validate format `^[a-z-]+/\d{3}$`. On invalid input, print expected format and abort.
2. Resolve the spec folder by globbing `specs/<category>/<NNN>-*/`. If zero or multiple matches, list candidates and abort.
3. Display the spec's `spec.md` frontmatter and first paragraph so the user confirms they're archiving the right one. Ask `Archive this spec? [y/n]`. Abort on `n`.
4. Prompt: "Archive reason (one line):". Capture as `<reason>`. Require non-empty.
5. Update the spec's `spec.md` frontmatter: set `status: archived` and add `archived_at: <YYYY-MM-DD>` (today). Preserve all other frontmatter.
6. Create `ARCHIVE-REASON.md` in the spec folder containing: date, original status before archiving, the `<reason>` text, and a `Source: /sf:spec-archive` line.
7. Move the folder from `specs/<category>/<NNN>-<name>/` to `specs/_archive/<NNN>-<name>/` (preserve the numeric prefix; flatten category). Use `git mv` if the repo is git-tracked.
8. Run `/sf:refresh-roadmap` to rewrite `ROADMAP.md` so the archived spec drops off Active.
9. Print: "Archived <category>/<NNN>-<name> -> specs/_archive/<NNN>-<name>/. Reason: <reason>. ROADMAP refreshed."

## Arguments

- `$ARGUMENTS` — spec reference `<category>/<NNN>`. Validate before any filesystem operation.

## Output

A confirmation prompt, a reason prompt, then a summary line. Files changed: `specs/_archive/<NNN>-<name>/spec.md` (status updated), `specs/_archive/<NNN>-<name>/ARCHIVE-REASON.md` (created), and `ROADMAP.md` (refreshed). The original `specs/<category>/<NNN>-<name>/` folder is removed (moved).
