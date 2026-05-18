---
name: framework-curator
description: Validates proposed edits to AGENTS.md, CLAUDE.md, or constitution.md against the placement decision tree; routes accepted additions to .claude/pending-changes.md for /curate sign-off.
---

# Framework Curator

Gatekeeper for the three core context files (`AGENTS.md`, `CLAUDE.md`, `constitution.md`). Validates proposed additions against the placement decision tree from `docs/PLAN.md` §5.11 and defers approved changes to `.claude/pending-changes.md` until `/curate` applies them.

## When to invoke

- Any proposed Edit or Write targeting `AGENTS.md`, `CLAUDE.md`, or `constitution.md`.
- Any `/evolve` step that suggests adding stack, commands, conventions, Claude-specific behavior, or invariants.
- Any time another skill proposes content but is unsure where it belongs.

## Procedure

1. Receive the proposed addition as `{target_file, field, content, source}` where `source` is the invoking command (e.g., `/evolve "..."`).
2. Walk the placement decision tree in order; pick the FIRST matching branch:
   1. Enforceable by a linter or formatter -> reject; tell user the tool enforces it.
   2. Inferable from `package.json`, code, README, or tests -> reject as redundant.
   3. Stack, command, or quirk Claude wouldn't guess -> route to `AGENTS.md` (deferred).
   4. Claude-specific behavior (compaction, plan mode, hook interactions) -> route to `CLAUDE.md` (deferred).
   5. Project-wide invariant or non-negotiable -> route to `constitution.md` (deferred).
   6. Must happen every time -> route to a hook in `.claude/settings.json`.
   7. Specialized workflow used sometimes -> route to a new skill in `.claude/skills/`.
   8. Feature-specific -> route to that feature's `spec.md` / `plan.md` / `tasks.md`.
   9. Current operational state (config, status) -> route to `docs/ops/`.
   10. Historical decision -> route to `docs/decisions/` as an ADR.
   11. Speculative or exploratory -> route to `scratchpads/<name>/`.
   12. Reusable across projects -> route to `~/.claude/skills/`.
   13. Anything else -> tell the user it probably doesn't need to exist.
3. If branches 3-5 matched, BLOCK direct edits unless the invocation came from `/curate`. Instead append to `.claude/pending-changes.md`:
   ```
   ## YYYY-MM-DD HH:MM · <target-file> · <field>
   <content>
   Source: <source>
   ```
   Use the local clock for the timestamp.
4. Report to the user: which branch matched, what action was taken, and (when deferred) remind them to run `/curate` after the current work ships.

## Output

- A one-line decision (`branch <n>: <action>`).
- When deferred: an appended entry in `.claude/pending-changes.md`.
- When invoked via `/curate`: the actual edit to the target core file, plus removal of the entry from `.claude/pending-changes.md`.

## Failure modes

- Direct edit attempted on `AGENTS.md`/`CLAUDE.md`/`constitution.md` outside `/curate`: refuse the edit, append to pending-changes instead, and tell the user.
- Ambiguous content matching multiple branches: pick the highest-priority (lowest-numbered) branch and note the tie in the report.
- `.claude/pending-changes.md` missing: create it with the header from PLAN §4.8, then append.
- Target file missing entirely: do not auto-create core files; report the gap and suggest `/lint-framework`.
