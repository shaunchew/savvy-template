---
description: Tag a mid-session checkpoint — snapshot HANDOVER, prompt for /sf:lesson, and append a commit marker.
---

# /sf:checkpoint

Mark a mid-session checkpoint: refresh `HANDOVER.md`, optionally capture a lesson, and write a non-destructive commit marker only if there are real changes.

## Procedure

1. Run `/sf:handover` to regenerate `HANDOVER.md` from current state.
2. Ask the user: "Anything to capture as a lesson before checkpointing? (one line, or skip)". If they provide text, invoke the `lesson-recorder` skill with that text. If they skip, continue.
3. Run `git status --porcelain` to detect tracked-file changes. If the working tree is clean (no staged or unstaged modifications to tracked files), skip committing and print "No changes to checkpoint." Done.
4. If there are changes, prompt the user for a one-line summary (default: derive from recent file changes). Stage tracked changes only (do not use `git add -A`; use `git add -u` plus any explicitly-named new files the user lists).
5. Commit with `git commit -m "checkpoint: <one-line summary>"`. Do not pass `--author`; let the commit use the user's own git config (and honor any authorship convention in their global `~/.claude/CLAUDE.md`).
6. Print the commit hash, the updated `HANDOVER.md` path, and any lesson tag that was recorded.

## Invokes

- `lesson-recorder` — receives the user's lesson text when one is provided; appends to `.claude/lessons.md`.

## Output

`HANDOVER.md` regenerated; optionally a new entry in `.claude/lessons.md`; optionally a new `checkpoint:` commit. Console prints a one-line summary of each action taken or skipped.
