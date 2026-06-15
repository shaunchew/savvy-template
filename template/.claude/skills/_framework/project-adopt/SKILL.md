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

2. **Run the helper** from the project root:

   ```
   "${CLAUDE_PLUGIN_ROOT}/scripts/sf-adopt.sh" ${ARGUMENTS}
   ```

   - It refuses a dirty git tree (or a non-git dir) unless `--yes` is passed — keep that
     guard; do not add `--yes` yourself unless the user explicitly asked. If it aborts on a
     dirty tree, report that and let the user commit/stash first.
   - It is **idempotent** — safe to re-run.

3. **Report what changed** from the helper's summary: files created, files skipped
   (already present — never overwritten), engine files detached, and the project-scope
   enablement. Note that any rewritten `settings.json` was backed up to
   `.claude/settings.json.savvy-old`.

4. **Tell the user to restart Claude Code** so the project-scope plugin activation and the
   detached hook set take effect.

5. **Suggest** `/sf:intake` if this is a fresh adoption and the seeded `AGENTS.md` /
   `constitution.md` still carry the `TODO` placeholder description.

## Safety invariants (enforced by the helper, not by prose)

- Skeleton writes are **create-if-absent** — an existing file is never overwritten.
- `permissions.deny` is merged as an **additive union**; user-defined hooks are preserved.
- Detach removes only the **known** framework engine files (the plugin's own command/skill/
  agent/hook names), one file at a time — never `rm -rf` of a directory.
- The in-tree **secret-scan floor guard** is always kept, so the secret block survives even
  with the plugin absent.
- Every `settings.json` rewrite is backed up to `settings.json.savvy-old`; on a git repo the
  whole change is one revertible diff.

## Output

- A seeded + (if legacy) detached project with `sf@savvy` enabled at project scope.
- A summary of created / skipped / detached items and the backup path.
- A restart reminder.
