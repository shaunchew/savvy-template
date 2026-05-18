---
name: bloat-watcher
description: PostToolUse hook that counts lines on context files after Edit/Write, warns when soft targets are crossed, and stops further appends once hard ceilings break.
---

# Bloat Watcher

Monitors line counts on length-budgeted context files. Fires from the PostToolUse hook on `Edit` or `Write` against any tracked file. Budgets defined in `docs/PLAN.md` Appendix A.

## When to invoke

- PostToolUse hook on `Edit` or `Write` whose path is one of: `AGENTS.md`, `CLAUDE.md`, `constitution.md`, `ROADMAP.md`, `HANDOVER.md`, `specs/**/spec.md`, `specs/**/plan.md`, `.claude/pending-changes.md`.

## Procedure

1. Identify the edited file and look up its budget:

   | File | Soft | Hard |
   |---|---|---|
   | `AGENTS.md` | 40 | 60 |
   | `CLAUDE.md` | 10 | 15 |
   | `constitution.md` | 50 | 80 |
   | `spec.md` | 100 | 200 |
   | `plan.md` | 150 | 300 |
   | `ROADMAP.md` | 80 | 150 |
   | `HANDOVER.md` | 30 | 50 |
   | `.claude/pending-changes.md` | n/a | warn at 50 entries |

2. Count non-trailing-blank lines (`wc -l` minus trailing empty lines). For `pending-changes.md`, count entries (lines starting with `## ` and a date).
3. Compare:
   - Below soft target -> exit silently.
   - Between soft and hard -> emit a warning to Claude with the file path, current count, both thresholds, and concrete extraction candidates (see step 4).
   - At or above hard ceiling -> emit a STOP message: refuse further appends to this file until content is extracted. Block subsequent Edit/Write on this path within the same turn.
   - `pending-changes.md` at 50+ entries -> warn and suggest `/curate`.
4. Extraction suggestions by file:
   - `AGENTS.md` -> move detail to `docs/` or a feature `spec.md`; collapse command lists by referencing a script.
   - `CLAUDE.md` -> move to `AGENTS.md` if it's project context rather than Claude behavior.
   - `constitution.md` -> extract specific decisions into `docs/decisions/<NNN>-<name>.md` as ADRs; keep only invariants.
   - `ROADMAP.md` -> archive shipped items to `CHANGELOG.md`.
   - `HANDOVER.md` -> regenerate via `/handover`; it's meant to be rewritten, not appended to.
   - `spec.md` / `plan.md` -> split detail into `plan.md` / `tasks.md` respectively.
5. Identify roughly which lines to extract by scanning for the longest section under the relevant heading, and reference its heading in the warning.

## Output

- No output when under soft target.
- A warning message naming the file, count, threshold, and at least one extraction candidate when between soft and hard.
- A blocking STOP message when hard is exceeded.

## Failure modes

- File not in budget table: exit silently.
- File missing after the edit (e.g., a rename): exit silently.
- Cannot read file (permission, etc.): emit a soft warning describing the read failure; do not block.
