---
name: project-adopt
description: Adopt a repository into the Savvy framework via the sf plugin — seed the skeleton create-if-absent, detach any legacy in-tree engine, and enable the plugin at project scope. Idempotent, git-guarded, and reversible. Invoked by /sf:adopt.
---

# Project Adopt

Adopts the current project onto the `sf` plugin engine. The mechanical work is done by a
single tested helper that physically cannot overwrite your files; this skill orchestrates
it and guides the before/after steps.

## When to use

- Adding the framework to an **existing** repo that never had it (the original pain point).
- Migrating a **legacy** project (in-tree engine, scaffolded before the plugin era) onto the
  plugin — the helper detaches the in-tree engine so hooks stop double-firing.

## Procedure

1. **Confirm the plugin is installed.** `/sf:adopt` only exists because the `sf` plugin is
   loaded. If the user has not added the marketplace yet, tell them to run
   `/plugin marketplace add shaunchew/savvy-template` then `/plugin install sf@savvy` first.

2. **Offer a dry run first** when the project is non-trivial (existing `.claude/`, legacy
   engine, or the user sounds unsure): run the helper with `--dry-run` and show the plan —
   it prints exactly what would be seeded / skipped / merged / detached and changes nothing.

3. **Run the helper** from the project root:

   ```
   "${CLAUDE_PLUGIN_ROOT}/scripts/sf-adopt.sh" ${ARGUMENTS}
   ```

   - It refuses a dirty git tree (or a non-git dir) unless `--yes` is passed — keep that
     guard; do not add `--yes` yourself unless the user explicitly asked. If it aborts on a
     dirty tree, report that and let the user commit/stash first.
   - It refuses a symlinked or invalid-JSON `settings.json` **before touching anything**;
     relay the message and let the user fix it.
   - It is **idempotent** — safe to re-run (a re-run changes nothing and never disturbs the
     original `.savvy-old` backup).

4. **Report what changed** from the helper's summary: files created, files skipped
   (already present — never overwritten), engine files **quarantined**, and the
   project-scope enablement. Two locations matter:
   - `.claude/settings.json.savvy-old` — the pre-adopt settings backup (kept from the
     FIRST adoption; never overwritten by re-runs).
   - `.claude/.savvy-detached-<timestamp>/` — every detached in-tree engine file, MOVED
     there rather than deleted (any local edits the user made to those files are preserved
     inside). Tell the user to review it and delete it when satisfied.

5. **Tell the user to restart Claude Code** so the project-scope plugin activation and the
   detached hook set take effect.

6. **Suggest** `/sf:intake` if this is a fresh adoption and the seeded `AGENTS.md` /
   `constitution.md` still carry the `TODO` placeholder description. Mention `/sf:doctor`
   for a read-only health check any time, and `/sf:eject` as the documented way out.

## Safety invariants (enforced by the helper, not by prose)

- Skeleton writes are **create-if-absent** — an existing file is never overwritten.
- `permissions.deny` is merged as an **additive union**; user-defined hooks are preserved.
- Detach **quarantines** — the known framework engine files (the plugin's own command/
  skill/agent/hook names, plus legacy upgrade bookkeeping like `.savvy-manifest.json`) are
  MOVED one file at a time to `.claude/.savvy-detached-<timestamp>/`, never deleted. A user
  file that merely shares an engine filename, or a locally edited engine file, is therefore
  always recoverable — even when `.claude/` is gitignored (the helper warns about that too).
- User hook wirings survive: only commands pointing at `.claude/hooks/<the 4 framework
  hooks>` are stripped from `settings.json`.
- The in-tree **secret-scan floor guard** is always kept, so the secret block survives even
  with the plugin absent.
- Every `settings.json` rewrite is backed up to `settings.json.savvy-old` (keep-first); on a
  git repo the whole change is one revertible diff.

## Output

- A seeded + (if legacy) detached project with `sf@savvy` enabled at project scope.
- A summary of created / skipped / quarantined items, the backup path, and the quarantine dir.
- A restart reminder.
