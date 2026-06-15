---
description: Adopt this project into the Savvy framework — seed the skeleton create-if-absent, detach any in-tree engine, and enable the sf plugin at project scope. Idempotent and reversible.
argument-hint: "[--yes]"
---

# /sf:adopt

Bring the current repository under the Savvy framework using the `sf` plugin engine, without overwriting anything you already have.

Use the **project-adopt** skill to run the adoption. It will:

1. Refuse to proceed on a dirty git tree (so adoption is one reviewable, revertible commit) unless `--yes` is passed.
2. Seed the skeleton **create-if-absent** — `AGENTS.md`, `CLAUDE.md`, `constitution.md`, `ROADMAP.md`, `HANDOVER.md`, `.claude/config.toml`, and the `specs/` `docs/` `scratchpads/` dirs. Existing files are never touched.
3. Seed (or additively merge) `.claude/settings.json` — the `permissions.deny` guards plus the in-tree **secret-scan floor guard** (so the secret block survives even if the plugin is absent). Your own deny rules and hooks are preserved.
4. **Detach** any legacy in-tree engine — remove the known `commands/sf/`, `skills/_framework/`, and framework `agents/` files, and strip the framework's `session-start`/`session-end`/`format`/`bloat-check` hook wirings from `settings.json` (keeping the secret-scan floor). The previous `settings.json` is backed up to `settings.json.savvy-old`.
5. Enable `sf@savvy` at **project scope** so the engine travels with this repo and nowhere else.

Pass `$ARGUMENTS` through to the skill (e.g. `--yes`).

Prerequisite: the plugin must be installed first (that is how this command exists):

```
/plugin marketplace add shaunchew/savvy-template
/plugin install sf@savvy
```
