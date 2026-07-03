---
description: Interactive walkthrough of the savvy framework — pick a scenario (fresh project, existing project, spec lifecycle, curation, scratchpad) and follow a guided flow with the commands to run at each step.
argument-hint: "[scenario]"
---

# /sf:tutorial

Guided walkthroughs of the most common framework flows. Use this when onboarding to the framework or when you want to remember how a specific lifecycle works end-to-end.

## Procedure

1. If `$ARGUMENTS` is empty, present the menu below and ask the user to pick one. If an argument is given, jump directly to that scenario.
2. For the chosen scenario, walk the steps below imperatively. At each step show:
   - **What:** what this step accomplishes
   - **Run:** the exact command(s) or action(s) the user should take
   - **Watch for:** what success looks like, common failure modes
3. After each step, ask if the user wants to continue, pause, or jump to another scenario. Do not run the commands for the user — this is a walkthrough, not an executor.
4. When a scenario completes, offer to walk through another.

## Scenarios

### Menu

| Scenario | When to pick it |
|---|---|
| `fresh-project` | You just scaffolded a brand-new project and want to bootstrap context. |
| `existing-project` | You added the framework to an existing repo and need to seed context. |
| `spec-lifecycle` | You have a feature/change in mind and want to go from idea to shipped. |
| `curation` | You're getting pending-changes warnings or want to clean up AGENTS.md / CLAUDE.md / constitution drift. |
| `scratchpad` | You want to explore an idea without polluting the project's specs/docs. |
| `release` | You're shipping a spec and want to walk the release gate. |
| `legacy-migration` | You're adopting the framework on an existing repo and want to triage legacy files. |

### fresh-project

1. **What:** Verify the scaffold is healthy. **Run:** `/sf:lint-framework`. **Watch for:** any reported drift or missing files.
2. **What:** If `.claude/intake-input.md` exists, intake should auto-run on session start. **Run:** confirm `CLAUDE.md` has the auto-intake line. **Watch for:** a five-batch flow starting — core files, specs, ADRs, subagents, integrations.
3. **What:** If auto-intake didn't fire, kick it off. **Run:** `/sf:intake "<one-line description of the project>"`. **Watch for:** approval prompts between batches; one commit per batch.
4. **What:** Add your first spec. **Run:** `/sf:spec product/<feature-name>`. **Watch for:** four files created in `specs/product/001-.../` and a ROADMAP update.
5. **What:** Record any onboarding gotchas. **Run:** `/sf:lesson "[placement] <what you learned>"`.

### existing-project

1. **What:** Confirm scaffold landed cleanly. **Run:** `ls -la .claude/ specs/ docs/`. **Watch for:** all directories present; no merge conflict markers in any framework file.
2. **What:** Decide on migration variant. **Run:** choose one — Variant A = passive coexistence (just leave old files in place); Variant B = active archival into `_legacy/` via `/sf:legacy-review --initial-migration` (which requires a clean git tree).
3. **What:** If Variant B, sweep non-conforming files. **Run:** `/sf:legacy-review --initial-migration`. **Watch for:** per-item Keep/Delete/Restore prompts; a `_legacy/initial-migration-<date>/` folder appears.
4. **What:** Bootstrap context from the existing codebase. **Run:** `/sf:intake "<what this project already does + where it's headed>"`. **Watch for:** the intake skill will read the existing code and propose AGENTS.md / specs / ADRs that match reality.
5. **What:** Sanity check. **Run:** `/sf:lint-framework` then `/sf:handover`.

### spec-lifecycle

1. **Create.** `/sf:spec <category>/<name>` → creates `specs/<category>/NNN-<name>/{spec,plan,tasks,checklist}.md`.
2. **Plan.** `/sf:plan <category>/NNN` → fills `plan.md` (approach, files, sequencing, risks).
3. **Tasks.** `/sf:tasks <category>/NNN` → derives a checkbox task list from plan.
4. **Implement.** Work the tasks. Mark `- [x]` as you complete each. Commit per task or per logical group using conventional commits (`feat(<category>/NNN): ...`).
5. **Revise mid-flight.** `/sf:spec-revise <category>/NNN` for any scope or approach change.
6. **Ship.** `/sf:ship <category>/NNN` → walks checklist, updates CHANGELOG, marks spec shipped, proposes a tag.
7. **Lessons.** `/sf:lesson "[pattern] <what worked>"` for anything reusable.

### curation

1. **Inspect.** `cat .claude/pending-changes.md` — see queued additions to AGENTS.md / CLAUDE.md / constitution / integration configs.
2. **Curate.** `/sf:curate` → walk each entry: Apply / Reject / Defer.
3. **Cleanup.** After curate, `pending-changes.md` should read `_(0 entries)_`.
4. **Audit.** `/sf:lint-framework` to verify no rule violations or budget breaches remain.

### scratchpad

1. **Enter.** `/sf:scratchpad <name>` → creates `scratchpads/NNN-<name>/`. Framework curator/bloat-watcher/spec-bootstrap/project-evolve go inert.
2. **Explore.** Write freely in `SCRATCHPAD.md`, `notes.md`, `findings.md`, `generated/`. No ROADMAP / CHANGELOG / HANDOVER side-effects.
3. **Lessons still work.** `/sf:lesson "..."` writes to `.claude/lessons.md` as normal.
4. **Decide outcome.** Either `/sf:promote-scratchpad <NNN>-<name>` (turn findings into a real spec/ADR, archive the scratchpad) or `/sf:archive-scratchpad <NNN>-<name>` (no promotion, just file away).
5. **Exit.** `/sf:scratchpad-exit` returns to normal mode.

### release

1. **Open the gate.** `/sf:ship <category>/NNN`. The release-gate skill walks the spec's `checklist.md` item-by-item.
2. **Per item:** answer y / n / skip. Any `n` halts the release; fix and re-run.
3. **On all-pass:** the skill updates CHANGELOG `[Unreleased]` → `[X.Y.Z] — <date>`, marks the spec `status: shipped`, refreshes ROADMAP, proposes a SemVer tag.
4. **If Notion enabled:** the skill triggers `/sf:sync-notion` to mark Notion rows complete.
5. **Tag and push:** confirm the SemVer bump, then `git tag vX.Y.Z && git push --tags`.

### legacy-migration

1. **Run the initial sweep.** `/sf:legacy-review --initial-migration` from project root.
2. **Per item:** Keep archived / Delete / Restore. Restored files move back to their suggested active location.
3. **Read the audit.** Check `_legacy/initial-migration-<date>/MIGRATION_NOTES.md` for the summary.
4. **Periodic walk.** `/sf:legacy-review` again later to triage any items left unresolved.
5. **Don't let it stagnate.** Framework-linter warns if `_legacy/` folders go >90 days without being fully reviewed.

## Arguments

- `$ARGUMENTS` — optional scenario key (one of: `fresh-project`, `existing-project`, `spec-lifecycle`, `curation`, `scratchpad`, `release`, `legacy-migration`). Omit to see the menu.

## Output

Conversational walkthrough. No file writes.
