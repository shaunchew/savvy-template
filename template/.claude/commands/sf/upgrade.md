---
description: Safely upgrade this project's savvy-framework files to a newer release — diffs against the ownership manifest, shows a plan, and applies only on confirmation. Never touches your work.
---

# /sf:upgrade

Bring this project's framework files (skills, commands, hooks, agents, settings)
up to a newer savvy-framework release without disturbing your actual work.

> **Legacy-only.** `/sf:upgrade` is for projects that still carry the engine
> *in-tree*. If this project was adopted via `/sf:adopt` — i.e. it runs the engine as
> the `sf@savvy` plugin (`enabledPlugins["sf@savvy"] == true` in `.claude/settings.json`,
> or a `.claude/.savvy-engine-version` file is present) — the skill STOPS immediately
> and changes nothing. Update the engine with **`/plugin update sf@savvy`** instead.

Optional arguments:
- `--apply` — auto-apply non-conflicting changes; conflicts and removals still
  require confirmation.
- `--force` — proceed even if the local version is not older than the target.
- `<path>` — point at a local framework checkout or a specific
  `.savvy-manifest.json` to upgrade from (instead of the installed plugin / remote).

## Procedure

1. Invoke the `framework-upgrade` skill with any arguments passed through. The skill's
   FIRST action is a plugin-mode guard: if this project is plugin-adopted it stops and
   prints that engine updates go through `/plugin update sf@savvy` (no file action).
2. The skill resolves a target release (explicit path → installed plugin → tagged
   release; never `main`, which may drop `template/`),
   loads the local `.claude/.savvy-manifest.json` baseline (or enters conservative
   mode if absent), and classifies every framework file as add / refresh / conflict /
   merge / up-to-date / removed.
3. Pass the skill's upgrade plan to the user unchanged. Do NOT apply anything before
   the user confirms (except non-conflicting actions when `--apply` was given).
4. Before touching anything, the skill establishes a rollback point (clean git tree so
   the upgrade is one revertible change, or a `.claude/.savvy-backup-<version>/` copy
   for non-git projects). On confirmation it applies adds/refreshes, merges
   settings.json and config.toml additively, writes conflict files as `<path>.savvy-new`
   (leaving your originals untouched), runs any in-range `migrations/v*.sh` transforms,
   and rewrites the local baseline manifest (marking unresolved conflicts sticky).
5. Relay the final report: what changed, which conflicts need review (with their
   `.savvy-new` paths), which migrations ran, how to roll back, and the reminder to
   reload Claude Code.

## Safety

- `seeded` files — your specs, docs, context files (AGENTS.md, CLAUDE.md,
  constitution.md, ROADMAP, etc.), scratchpads, integration creds — are NEVER
  overwritten. They only get created if entirely absent.
- A framework file you edited is NEVER silently overwritten; the new version lands
  beside it as `*.savvy-new` for you to reconcile.
- Projects with no manifest yet (anything scaffolded before v1.4.0) upgrade safely
  via conservative mode: anything that differs is treated as a conflict, not a refresh.
- A file you kept over an upstream change stays a conflict on every later upgrade (a
  sticky `conflict: true` marker in the manifest) — it is never silently refreshed back.
- The upgrade is one revertible unit: a clean git tree means `git revert` undoes it;
  a non-git project gets a `.claude/.savvy-backup-<version>/` copy of everything changed.
- Plugin-adopted projects are refused outright — use `/plugin update sf@savvy` there.

## Invokes

- `framework-upgrade` — receives the passed-through arguments; returns the plan and,
  on confirmation, performs the upgrade.

## Output

The upgrade plan, then (on confirmation) the applied changes plus a final report of
conflicts, migrations run, and reload reminder.
