---
description: Archive a scratchpad without promoting it (move to scratchpads/_archive/).
argument-hint: "<NNN>-<name>"
---

# /archive-scratchpad

Archive a scratchpad without promoting anything from it. Used when an exploration ended in "not worth pursuing" but the record is worth keeping.

## Procedure

1. Parse `$ARGUMENTS` as `<NNN>-<name>`. Validate format `^\d{3}-[a-z][a-z0-9-]*$`. On invalid input, print expected format and abort.
2. Resolve the folder `scratchpads/<NNN>-<name>/`. If missing, list active scratchpads and abort.
3. Show the user a one-paragraph summary of the scratchpad (read `SCRATCHPAD.md` topic + first line of `findings.md`) and ask `Archive without promoting? [y/n]`. Abort on `n`.
4. Optionally prompt for a one-line archive reason; if provided, write it into `SCRATCHPAD.md` frontmatter as `archive_reason:`.
5. Update `SCRATCHPAD.md` frontmatter: set `status: archived` and add `archived_at: <YYYY-MM-DD>`. Preserve other frontmatter.
6. Move the folder from `scratchpads/<NNN>-<name>/` to `scratchpads/_archive/<NNN>-<name>/` (use `git mv` if tracked).
7. Append one line to `scratchpads/_archive/INDEX.md` in the form `- <NNN>-<name> · archived <YYYY-MM-DD> · <reason or "no reason given">`. Create `INDEX.md` with a `# Archived scratchpads` header if it does not exist.
8. Print: `Archived <NNN>-<name> -> scratchpads/_archive/<NNN>-<name>/. Logged in scratchpads/_archive/INDEX.md.`

## Arguments

- `$ARGUMENTS` — required `<NNN>-<name>` matching an existing folder under `scratchpads/`. Validate before any write.

## Output

A confirmation prompt, optional reason prompt, then a one-line summary. Files changed: moved scratchpad folder (now under `scratchpads/_archive/`), its `SCRATCHPAD.md` (status + archived_at), and `scratchpads/_archive/INDEX.md` (appended or created).
