---
description: Regenerate HANDOVER.md from current state (goal, files in flight, what failed, next step, pending changes count); 50-line cap.
---

# /sf:handover

Regenerate `HANDOVER.md` from scratch as a session bridge. Never append — always overwrite.

## Procedure

1. Gather current state by running, in parallel: `git status` (no `-uall`), `git log -5 --oneline`, `git branch --show-current`, and a recent `git diff --stat` for files modified in the working tree.
2. Identify the active spec(s): scan `specs/<category>/*/` for any with status frontmatter `in-progress` or matching the current branch name (`<category>/<NNN>-*`).
3. Count entries in `.claude/pending-changes.md` (each `## YYYY-MM-DD ...` heading is one entry; treat the boilerplate intro lines as zero).
4. Compose a fresh `HANDOVER.md` with these sections, in order, filling only what is known (omit a section if truly empty rather than padding):
   - `# Handover`
   - `Last updated: <ISO timestamp>`
   - `## Goal` — one sentence on what's being worked toward.
   - `## Current state` — branch, last commit summary, test status if discoverable.
   - `## Files in flight` — paths from `git status` with a one-line `what's being changed` per entry.
   - `## What's been tried that didn't work` — pull from recent reverted commits or session notes if available; leave empty if nothing fits.
   - `## Next step` — exactly one concrete action.
   - `## Pending changes awaiting /sf:curate` — `<count> entries in .claude/pending-changes.md`.
5. Overwrite `HANDOVER.md`. Enforce a hard ceiling of 50 lines — if the draft exceeds it, trim from `## Files in flight` and `## What's been tried` first.
6. Print the new line count and confirm the write.

## Output

`HANDOVER.md` rewritten end-to-end, under 50 lines. Console prints the line count.
