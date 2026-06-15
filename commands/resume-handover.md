---
description: Bootstrap a new session by reading HANDOVER.md, the active spec, and recent git state; summarize where to pick up.
---

# /sf:resume-handover

Counterpart to `/sf:handover`. Where `/sf:handover` *writes* the bridge file, this command *reads* it (plus surrounding context) and emits a short brief so the next session can pick up without ambiguity.

## Procedure

1. Read `HANDOVER.md` from the project root. If it does not exist, print "No HANDOVER.md found — run /sf:handover at the end of a session to create one." and stop.
2. In parallel, gather current state: `git status` (no `-uall`), `git log -5 --oneline`, `git branch --show-current`.
3. Identify the active spec: scan `specs/<category>/*/` for any with frontmatter `status: in-progress` or whose folder name matches the current branch (`<category>/<NNN>-*`). If found, read its `spec.md` summary section (or first 30 lines).
4. Compare `HANDOVER.md`'s `Last updated:` timestamp against `git log -1 --format=%cI` for the most recent commit. If the handover is older than the latest commit, flag it as potentially stale.
5. Print a brief in this exact shape:
   - `## Resuming from HANDOVER.md`
   - `Updated: <timestamp>` — plus `(stale — last commit is newer)` if applicable.
   - `Goal: <one line from HANDOVER.md ## Goal>`
   - `Branch: <name>` + last commit subject.
   - `Active spec: <path>` — one-line summary, or `none` if no in-progress spec.
   - `Files in flight: <count>` — list paths if ≤5, else show count.
   - `Next step: <verbatim from HANDOVER.md ## Next step>`
   - `Pending /sf:curate: <count from HANDOVER.md>`
6. Do not modify any file. Output only the brief.

## Output

A markdown brief printed to the console. No file writes. If the handover looks stale relative to git, the brief says so explicitly so the user knows to verify before acting on `Next step`.
