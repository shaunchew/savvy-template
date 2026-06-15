---
description: Enter a scratchpad workspace at scratchpads/<NNN>-<name>/; framework curator/bloat-watcher/spec-bootstrap/project-evolve go inert.
argument-hint: "<name>"
---

# /sf:scratchpad

Create or enter an isolated exploration workspace under `scratchpads/<NNN>-<name>/`. Inside it, framework machinery (curator, bloat-watcher, spec-bootstrap, project-evolve) is inert.

## Procedure

1. Parse `$ARGUMENTS` as a single `<name>` token. Validate it is kebab-case: regex `^[a-z][a-z0-9-]*[a-z0-9]$`, no underscores, no spaces, no uppercase. On invalid input, print expected format and abort.
2. Search `scratchpads/` for an existing folder ending in `-<name>` (e.g. `scratchpads/003-<name>/`). If found, enter that one — do not create a new folder.
3. If not found, determine the next number by scanning `scratchpads/NNN-*/` (max + 1, zero-padded 3 digits) and pass `{name, NNN}` to the `scratchpad-mode` skill to create the folder.
4. The skill creates `scratchpads/<NNN>-<name>/` with `SCRATCHPAD.md` (frontmatter status active, created date, topic prompt), empty `notes.md`, empty `findings.md`, and `generated/` directory.
5. Activate scratchpad mode: subsequent edits stay scoped to that folder; main project files become read-only references.
6. Print a banner:
   ```
   Entered scratchpad: <NNN>-<name>
   Inert here: framework-curator, bloat-watcher, spec-bootstrap, project-evolve.
   Read-only: AGENTS.md, specs/, docs/, CHANGELOG.md, ROADMAP.md, HANDOVER.md.
   Writable: scratchpads/<NNN>-<name>/ only.
   Exit with /sf:scratchpad-exit. Promote with /sf:promote-scratchpad <NNN>-<name>.
   ```
7. Ask: "What are you exploring?" so the user can seed `SCRATCHPAD.md` topic.

## Arguments

- `$ARGUMENTS` — required `<name>` in kebab-case. Reject invalid names before any filesystem action.

## Invokes

- `scratchpad-mode`

## Output

A banner explaining what's inert plus the topic prompt. Files changed: `scratchpads/<NNN>-<name>/SCRATCHPAD.md`, `notes.md`, `findings.md`, and `generated/` (all created on first entry; no-op on subsequent entries to an existing scratchpad).
