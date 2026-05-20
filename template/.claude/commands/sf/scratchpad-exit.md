---
description: Exit the current scratchpad back to normal project mode.
---

# /sf:scratchpad-exit

Leave scratchpad mode. Framework machinery (curator, bloat-watcher, spec-bootstrap, project-evolve) becomes active again. Scratchpad content is preserved for future return.

## Procedure

1. Detect the currently active scratchpad by reading the scratchpad-mode skill's state (or by inspecting which `scratchpads/<NNN>-*/` was last entered this session). If no scratchpad is active, print `Not in a scratchpad. Nothing to do.` and exit.
2. Enumerate files written under `scratchpads/<NNN>-<name>/` during this session (or, if state isn't tracked, list current contents of the folder with their mtimes).
3. Deactivate scratchpad mode so framework skills resume normal behavior on subsequent prompts.
4. Print a one-line summary, for example:
   ```
   Exited <NNN>-<name>. Wrote: SCRATCHPAD.md, notes.md, findings.md, generated/api-probe.py.
   ```
5. Do **not** create a git commit. Do not update `ROADMAP.md`, `CHANGELOG.md`, or `HANDOVER.md`. The user controls when (or whether) to promote via `/sf:promote-scratchpad`.

## Invokes

- `scratchpad-mode`

## Output

A single summary line listing the scratchpad name and files touched during the session. No git operations. No main-project files change.
