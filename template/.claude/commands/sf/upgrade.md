---
description: Safely upgrade this project's savvy-framework files to a newer release — diffs against the ownership manifest, shows a plan, and applies only on confirmation. Never touches your work.
---

# /sf:upgrade

Bring this project's framework files (skills, commands, hooks, agents, settings)
up to a newer savvy-framework release without disturbing your actual work.

Optional arguments:
- `--apply` — auto-apply non-conflicting changes; conflicts and removals still
  require confirmation.
- `--force` — proceed even if the local version is not older than the target.
- `<path>` — point at a local framework checkout or a specific
  `.savvy-manifest.json` to upgrade from (instead of the installed plugin / remote).

## Procedure

1. Invoke the `framework-upgrade` skill with any arguments passed through.
2. The skill resolves a target release (explicit path → installed plugin → remote),
   loads the local `.claude/.savvy-manifest.json` baseline (or enters conservative
   mode if absent), and classifies every framework file as add / refresh / conflict /
   merge / up-to-date / removed.
3. Pass the skill's upgrade plan to the user unchanged. Do NOT apply anything before
   the user confirms (except non-conflicting actions when `--apply` was given).
4. On confirmation, the skill applies adds/refreshes, merges settings.json and
   config.toml additively, writes conflict files as `<path>.savvy-new` (leaving your
   originals untouched), runs any in-range `migrations/v*.sh` transforms, and rewrites
   the local baseline manifest.
5. Relay the final report: what changed, which conflicts need review (with their
   `.savvy-new` paths), which migrations ran, and the reminder to reload Claude Code.

## Safety

- `seeded` files — your specs, docs, context files (AGENTS.md, CLAUDE.md,
  constitution.md, ROADMAP, etc.), scratchpads, integration creds — are NEVER
  overwritten. They only get created if entirely absent.
- A framework file you edited is NEVER silently overwritten; the new version lands
  beside it as `*.savvy-new` for you to reconcile.
- Projects with no manifest yet (anything scaffolded before v1.4.0) upgrade safely
  via conservative mode: anything that differs is treated as a conflict, not a refresh.

## Invokes

- `framework-upgrade` — receives the passed-through arguments; returns the plan and,
  on confirmation, performs the upgrade.

## Output

The upgrade plan, then (on confirmation) the applied changes plus a final report of
conflicts, migrations run, and reload reminder.
