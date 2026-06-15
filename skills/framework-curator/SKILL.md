---
name: framework-curator
description: Validates proposed edits to AGENTS.md, CLAUDE.md, or constitution.md against the placement decision tree; routes accepted additions to .claude/pending-changes.md for /sf:curate sign-off.
---

# Framework Curator

Gatekeeper for the three core context files (`AGENTS.md`, `CLAUDE.md`, `constitution.md`). Validates proposed additions against the placement decision tree from `docs/PLAN.md` §5.11 and defers approved changes to `.claude/pending-changes.md` until `/sf:curate` applies them.

## When to invoke

- Any proposed Edit or Write targeting `AGENTS.md`, `CLAUDE.md`, or `constitution.md`.
- Any `/sf:evolve` step that suggests adding stack, commands, conventions, Claude-specific behavior, or invariants.
- Any time another skill proposes content but is unsure where it belongs.

## Procedure

1. Receive the proposed addition as `{target_file, field, content, source}` where `source` is the invoking command (e.g., `/sf:evolve "..."`).
2. Walk the placement decision tree in order; pick the FIRST matching branch:
   1. Enforceable by a linter or formatter -> reject; tell user the tool enforces it.
   2. Inferable from `package.json`, code, README, or tests -> reject as redundant.
   3. Stack, command, or quirk Claude wouldn't guess, AND only applies to one subdirectory subtree -> route to that subtree's `AGENTS.md` (apply directly; subdir AGENTS.md is NOT deferred). See `docs/agents-subdir-pattern.md`.
   4. Stack, command, or quirk Claude wouldn't guess (project-wide) -> route to root `AGENTS.md` (deferred).
   5. Claude-specific behavior (compaction, plan mode, hook interactions) -> route to `CLAUDE.md` (deferred).
   6. Project-wide invariant or non-negotiable -> route to `constitution.md` (deferred).
   7. Must happen every time -> route to a hook in `.claude/settings.json`.
   8. Specialized workflow used sometimes -> route to a new skill in `.claude/skills/`.
   9. Feature-specific -> route to that feature's `spec.md` / `plan.md` / `tasks.md`.
   10. Current operational state (config, status) -> route to `docs/ops/`.
   11. Historical decision -> route to `docs/decisions/` as an ADR.
   12. Speculative or exploratory -> route to `scratchpads/<name>/`.
   13. Reusable across projects -> route to `~/.claude/skills/`.
   14. Anything else -> tell the user it probably doesn't need to exist.
3. If branches 4-6 matched (root AGENTS.md / CLAUDE.md / constitution.md), BLOCK direct edits unless the invocation came from `/sf:curate`. Instead append to `.claude/pending-changes.md`:
   ```
   ## YYYY-MM-DD HH:MM · <target-file> · <field>
   <content>
   Source: <source>
   ```
   Use the local clock for the timestamp.
4. Report to the user: which branch matched, what action was taken, and (when deferred) remind them to run `/sf:curate` after the current work ships.

## Output

- A one-line decision (`branch <n>: <action>`).
- When deferred: an appended entry in `.claude/pending-changes.md`.
- When invoked via `/sf:curate`: the actual edit to the target core file, plus removal of the entry from `.claude/pending-changes.md`.

## Failure modes

- Direct edit attempted on `AGENTS.md`/`CLAUDE.md`/`constitution.md` outside `/sf:curate`: refuse the edit, append to pending-changes instead, and tell the user.
- Ambiguous content matching multiple branches: pick the highest-priority (lowest-numbered) branch and note the tie in the report.
- `.claude/pending-changes.md` missing: create it with the header from PLAN §4.8, then append.
- Target file missing entirely: do not auto-create core files; report the gap and suggest `/sf:lint-framework`.
