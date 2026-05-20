---
name: scratchpad-mode
description: Isolated exploration workspace under scratchpads/<name>/ where framework-curator, bloat-watcher, spec-bootstrap, and project-evolve are inert and ROADMAP/CHANGELOG/HANDOVER are not updated; /sf:promote-scratchpad converts findings to real specs/ADRs.
---

# Scratchpad Mode

Isolated exploration workspace under `scratchpads/<NNN>-<name>/`. While active, framework machinery is inert and main project files are read-only reference. `/sf:promote-scratchpad` converts findings into real specs or ADRs.

## When to invoke

- User runs `/sf:scratchpad <name>` (create or enter).
- User runs `/sf:scratchpad-list`, `/sf:scratchpad-exit`, `/sf:promote-scratchpad <ref>`, or `/sf:archive-scratchpad <ref>`.
- Any session work originating inside a `scratchpads/<NNN>-<name>/` path.

## Procedure

### `/sf:scratchpad <name>`

1. Look up the highest existing `NNN` prefix under `scratchpads/` and increment. If `<name>` already exists, enter it instead of creating.
2. Create `scratchpads/<NNN>-<name>/` with these files:
   - `SCRATCHPAD.md` -- header with Status (`active`), Created date, Context, Topic, Open questions, "What this could become" (use the template in PLAN §5.10).
   - `notes.md` -- empty.
   - `findings.md` -- empty.
   - `generated/` -- empty directory (keep with `.gitkeep` if needed).
   - `REVIEW.md` -- empty (populated on promotion).
3. Announce: "Scratchpad mode active in `scratchpads/<NNN>-<name>/`. Main project is read-only."
4. While the session's working scope is this folder:
   - `framework-curator`, `bloat-watcher`, `spec-bootstrap`, `project-evolve` treat the scratchpad as inert (do not gate, do not warn, do not write outside it).
   - Do NOT update `ROADMAP.md`, `CHANGELOG.md`, or `HANDOVER.md`.
   - Main project files may be READ for reference. They MUST NOT be written.
   - `/sf:lesson` continues to work (lessons are universal).

### `/sf:scratchpad-exit`

1. Print scratchpad path and a one-line state summary.
2. Return to normal project mode. Do NOT commit scratchpad files automatically; let the user decide. Scratchpad state is preserved on disk for future return.

### `/sf:scratchpad-list`

1. Enumerate `scratchpads/` direct children. For each: name, age (days since `Created` in SCRATCHPAD.md), last-modified time, generated-file count, status.
2. Show `_archive/` count separately; suppress unless user passed `--all`.

### `/sf:promote-scratchpad <NNN>-<name>`

1. Read `SCRATCHPAD.md`, `notes.md`, `findings.md`, and contents of `generated/`.
2. Run the five-batch flow from `project-intake` scoped to scratchpad content (specs, ADRs, doc additions, updates to existing specs). All ground-truth additions (AGENTS/CLAUDE/constitution) route through `framework-curator` as deferred.
3. On user approval per batch, write the promoted artifacts into the real project.
4. Write `REVIEW.md` inside the scratchpad documenting what got promoted (one bullet per produced artifact with destination path).
5. Move the scratchpad to `scratchpads/_archive/<NNN>-<name>/` and flip `SCRATCHPAD.md` `Status:` to `promoted`.

### `/sf:archive-scratchpad <NNN>-<name>`

1. Append the user-supplied rationale to `SCRATCHPAD.md` under an `## Archive reason` heading.
2. Flip `Status:` to `archived` and move the folder to `scratchpads/_archive/<NNN>-<name>/`. No promotion.

## Output

- New folder `scratchpads/<NNN>-<name>/` with the five seed files.
- Edits scoped strictly inside that folder while mode is active.
- On promotion: real specs, ADRs, or doc updates plus a `REVIEW.md` audit trail.
- On archive: moved folder under `scratchpads/_archive/` with rationale recorded.

## Failure modes

- Skill or user attempts to write outside `scratchpads/<NNN>-<name>/` while active: refuse the write, remind the user main project is read-only, suggest `/sf:scratchpad-exit` first.
- `/sf:promote-scratchpad` invoked on an already-archived scratchpad: refuse; tell the user it has no active findings.
- Numbering collision (two scratchpads at the same `NNN`): bump to the next free integer and warn.
- v1.0 honesty caveat: true session-level isolation requires a fresh Claude Code session. v1.0 enforces inertness via in-session discipline only -- if the same session later exits scratchpad mode, Claude still remembers what was explored. The file-system separation is the durable boundary.
