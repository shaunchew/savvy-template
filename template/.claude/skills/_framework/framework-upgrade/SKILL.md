---
name: framework-upgrade
description: Triggered by /sf:upgrade. Diffs the project's installed framework files against a newer release using the .savvy-manifest.json ownership map, then prints a plan (add / refresh / conflict / merge / migrations) and applies only on confirmation. Never overwrites project data or locally-modified framework files without sign-off.
---

# Framework Upgrade

Safely brings an already-scaffolded project up to a newer framework version. The
guarantee: **your work is never touched, and no framework file you edited is
overwritten without you seeing it first.** This skill detects what changed,
explains it, and applies only what you approve.

## The ownership model

Every release ships `.claude/.savvy-manifest.json` — a list of framework files,
each with a `sha256` and a `policy`:

- **managed** — framework owns it (skills, commands, hooks, agents, framework
  docs). Safe to refresh *only if you haven't locally edited it*.
- **merge** — `settings.json`, `config.toml`. Framework owns part; your additions
  must survive. Never blind-overwritten.
- **seeded** — created once at scaffold, then yours forever (AGENTS.md, CLAUDE.md,
  constitution.md, ROADMAP.md, CHANGELOG.md, HANDOVER.md, README.md, lessons.md,
  pending-changes.md, integration creds, and everything under specs/, scratchpads/,
  docs/, _legacy/). **Never overwritten on upgrade** — only created if entirely absent.

Three hashes drive every decision for a given file:
- `target` — hash in the new release's manifest (what we'd install).
- `baseline` — hash in the project's *local* manifest (what was last installed).
- `current` — hash of the file as it sits on disk right now.

A baseline entry may also carry a **`conflict: true`** marker. It means: at a prior
upgrade this managed file was locally modified (`current != baseline`), so the new
version was set aside as `<path>.savvy-new` and the user's version was kept. The
marker's `sha256` is the *kept* (current) hash at that time. The marker makes the
conflict **sticky**: the file stays a CONFLICT on every later upgrade — it is NEVER
eligible for a silent REFRESH — until either the on-disk file converges to the new
`target` (upstream now matches what the user has) or the user explicitly accepts the
resolution. Only then is the marker cleared. Without this marker a resolved-by-keeping
file would look identical to an untouched file on the next run (`current == baseline`)
and get silently overwritten — the exact data-loss bug this marker prevents.

## When to invoke

- User runs `/sf:upgrade` (optionally `/sf:upgrade --apply` to skip the second
  confirmation, or `/sf:upgrade <path-to-target>` to point at a specific source).
- User asks to "update the framework", "pull the latest framework", or "upgrade savvy".
- Do NOT invoke for application dependency upgrades — this is framework-only.

## Procedure

### 0. Refuse to run in a plugin-adopted project (MANDATORY — do this FIRST)

`/sf:upgrade` is **legacy-only**: it exists solely for projects that still carry the
framework engine *in-tree* (`.claude/commands/sf/*`, `.claude/skills/_framework/*`,
etc.). Projects that ran `/sf:adopt` no longer have those files — the engine was
detached and now ships as the `sf@savvy` plugin, and engine updates flow through
`/plugin update sf@savvy`, NOT through this skill.

Before anything else, detect plugin mode. The project is plugin-adopted if EITHER:
- `.claude/settings.json` parses and has `enabledPlugins["sf@savvy"] == true`, OR
- `.claude/.savvy-engine-version` exists.

If either is true, **STOP immediately**. Take NO file action whatsoever (no fetch, no
classify, no manifest read/write). Print exactly this and end:

```
This project uses the savvy engine as a plugin (sf@savvy). Framework/engine updates
flow through:  /plugin update sf@savvy
/sf:upgrade is legacy-only — it is for projects that still carry the engine in-tree,
which this project no longer does. Nothing was changed.
```

Only if the project is NOT plugin-adopted (no `enabledPlugins["sf@savvy"]`, no
`.claude/.savvy-engine-version`) do you continue to step 1.

### 1. Locate the target release (what we're upgrading TO)

Resolve a target manifest, in this order (prefer the earliest that succeeds):
1. Explicit path argument → read `<arg>/.claude/.savvy-manifest.json` (or `<arg>`
   if it points straight at a manifest).
2. Installed plugin → if a `savvy-framework` plugin is installed locally, read its
   bundled `.savvy-manifest.json`.
3. Remote **tagged release** → do NOT fetch from `.../main/template/...`. The
   framework is mid-rearchitecture and a later phase removes `template/` from `main`,
   so a `main`-pinned fetch will break permanently. Resolve the newest release TAG
   and fetch from that immutable ref instead:
   - Ask the GitHub API for the latest release tag:
     `https://api.github.com/repos/shaunchew/savvy-template/releases/latest` → read
     `.tag_name`. If there is no published "latest" release, list tags at
     `https://api.github.com/repos/shaunchew/savvy-template/tags` and pick the highest
     `v<X.Y.Z>`.
   - Fetch `https://raw.githubusercontent.com/shaunchew/savvy-template/<tag>/template/.claude/.savvy-manifest.json`
     with a short timeout.
   - If the API is unreachable, try a couple of plausible recent tags directly against
     the same raw-URL pattern (e.g. the version just above the local one) before giving up.

If none resolve (offline, no plugin, no arg, no reachable tag): report that no target
source is available and stop. Suggest re-running with a path to a local checkout.

Read the target `version`. Read the local version from `.claude/config.toml`
`[framework] version`. If target ≤ local, print `Already up to date (v<local>).`
and stop — unless `--force` was passed.

### 2. Load the local baseline (what we're upgrading FROM)

Read `.claude/.savvy-manifest.json` from the project root.

- **Present** → use it as the `baseline` for each file (trusted record of what was
  last installed and whether the user has since edited it). A baseline entry may also
  carry `conflict: true` (see "The ownership model") — an unresolved prior conflict.
  Honor it in step 3: such a file is **never** refresh-eligible while the marker
  stands, even if `current == baseline`.
- **Absent** (every project scaffolded before manifests existed) → enter
  **conservative mode**: there is no trusted baseline, so treat *any* managed file
  whose `current` hash differs from `target` as a **conflict** (cannot prove it's
  unmodified). Nothing is auto-refreshed silently. This is the backward-compatible
  path — it never assumes a file is safe to overwrite. Conservative mode has no
  baseline entries at all, so no `conflict: true` markers exist yet — they first
  appear in the baseline this run *writes* (step 8), where every file left in
  CONFLICT is recorded with the marker so the stickiness carries forward.

### 3. Classify every file in the target manifest

For each entry `{path, policy, target_hash}`:

- **File absent on disk** → **ADD** (safe — nothing to overwrite), regardless of policy.
- **policy = seeded** → **SKIP** (untouched). Never refresh a seeded file. Only the
  ADD case above can ever create it.
- **policy = merge** → **MERGE** (see step 5). Never overwrite wholesale.
- **policy = managed**, file present — evaluate these in order, first match wins:
  - `current == target` → **UP-TO-DATE** (no action). The on-disk file already equals
    the new release. If the baseline entry carried `conflict: true`, this is the moment
    the conflict is *resolved* — clear the marker when writing the baseline (step 8).
  - baseline entry has **`conflict: true`** (and `current != target`) → **CONFLICT**
    (sticky). This is an unresolved prior conflict; it stays a conflict *regardless of
    whether `current == baseline`*. Do NOT refresh. Only offer to clear it if the user
    explicitly accepts the resolution; otherwise re-emit `<path>.savvy-new` (if `target`
    differs from `current`) and keep the marker. **Never** treat a `conflict: true`
    entry as REFRESH-eligible — doing so silently overwrites the file the user chose to
    keep, which is the data-loss bug this rule exists to stop.
  - `current == baseline` (no conflict marker, and `baseline != target`) → **REFRESH**
    (you never edited it; safe to replace with the new version).
  - `current != baseline` (or no baseline) → **CONFLICT** (you edited it, or we
    can't prove you didn't). Do not overwrite. Write the new version alongside as
    `<path>.savvy-new` and record a conflict for the report.

Also detect **REMOVED** files: paths in the local baseline manifest that are absent
from the target manifest → the framework dropped them. Report only; never delete
without explicit confirmation (a removed managed file may be one you repurposed).

### 4. Collect transform migrations

List `migrations/v<X.Y.Z>.sh` scripts whose version is in the range `(local, target]`.
These handle genuine *transforms* (e.g. rewriting a settings.json hook shape) that a
file-replace cannot express. Resolve them from the same source as the target manifest
(plugin dir, local checkout, or remote raw URL). Present them as part of the plan;
run them (in version order) only after the file changes are applied and confirmed.

### 5. Plan the merges (settings.json, config.toml)

Never overwrite these. Instead compute an additive merge:
- **`.claude/settings.json`** — ensure every framework-shipped `permissions.deny`
  entry and every framework hook (PostToolUse/PreToolUse/SessionStart/Stop pointing
  at `.claude/hooks/*.sh`) is present. Preserve all user-added permissions, hooks,
  and other keys verbatim. If a framework hook entry is missing, add it; if the user
  changed a framework value, surface it as a merge conflict line rather than clobbering.
- **`.claude/config.toml`** — update only `[framework] version` to the target
  version. Leave `variant`, `[integrations]` toggles, and everything else untouched.

Show the exact proposed merge diff in the plan.

### 6. Present the plan — STOP before applying

Print a single Markdown report grouped by action. Apply NOTHING yet:

```
# Framework Upgrade Plan — v<local> → v<target>

## Add (N)          new framework files, nothing to overwrite
- <path>

## Refresh (N)      managed files you have not edited — safe to update
- <path>

## Conflict (N)     managed files you edited — written as <path>.savvy-new, originals untouched
- <path>  (your version kept; review <path>.savvy-new)

## Merge (N)
- .claude/settings.json  (+2 deny entries, +1 hook; your additions preserved)
- .claude/config.toml    (version 1.3.0 → 1.4.0 only)

## Migrations to run (N)
- v1.4.0.sh — <one-line purpose>

## Untouched (your work)
- <count> seeded files (specs, docs, context files, scratchpads) — not touched.
- <count> removed-upstream files kept in place (listed below if any).

## Summary
add: N · refresh: N · conflict: N · merge: N · migrations: N · untouched-seeded: N
```

Then ask the user to confirm: apply all, apply a subset, or cancel. If invoked with
`--apply`, skip the prompt for the **non-conflicting** actions only — conflicts and
removals ALWAYS require explicit confirmation.

### 7. Establish a rollback point (before writing anything)

An upgrade touches many files at once. Make the whole thing revertible BEFORE the
first overwrite, choosing based on whether the project is a git repo:

- **Git repo** → require a **clean working tree** (`git status --porcelain` empty).
  If dirty, STOP and ask the user to commit/stash first, or to explicitly acknowledge
  proceeding dirty. The point: with a clean tree the entire upgrade lands as one set of
  changes the user can undo in a single `git revert <commit>` (or `git checkout -- .`
  before committing). Do not silently proceed on a dirty tree.
- **Not a git repo** → there is no revert, so make a physical backup. For **every file
  about to be REFRESHed or MERGEd** (not adds — those can just be deleted, not seeded
  files — those are never touched), copy the current on-disk file to
  `.claude/.savvy-backup-<target-version>/<original-relative-path>` *before* overwriting
  it, preserving the relative path. Create the backup dir if absent. Report its location
  so the user can restore by copying files back.

Record which rollback mechanism was used; you will name it in the final report (step 9).

### 8. Apply (only after confirmation)

In this order:
1. **Add** the new files.
2. **Refresh** the unmodified managed files.
3. **Conflict** files: leave the original untouched; ensure `<path>.savvy-new` exists.
4. **Merge** settings.json / config.toml additively.
5. **Run migrations** in version order. Each is idempotent; a failure halts the rest
   and is reported.
6. **Write the new baseline**: regenerate `.claude/.savvy-manifest.json` from the
   target manifest. For files that were added, refreshed, or merged, the baseline
   `sha256` is the new on-disk hash (matching target) and carries **no** conflict
   marker. For files left in **CONFLICT** (unresolved), you MUST record BOTH:
   - `"sha256"`: the file's *current* (kept) hash — NOT the target hash, so the
     project reflects reality and a later edit stays detectable; and
   - `"conflict": true` — the sticky marker (see "The ownership model").

   Recording the kept hash *without* the marker is the data-loss bug: on the next
   upgrade `current == baseline` would classify as REFRESH and silently overwrite the
   user's file. The marker is what keeps it a CONFLICT until it is genuinely resolved.

   **Clearing the marker** (a conflict that resolved this run): if a file that
   previously carried `conflict: true` reached `current == target`, or the user
   explicitly accepted the new version, write its `sha256` as the resolved on-disk hash
   and OMIT the `conflict` key entirely. Do not carry a stale marker forward.

   Example conflict entry:
   `{ "path": ".claude/hooks/format.sh", "policy": "managed", "sha256": "<kept-hash>", "conflict": true }`

### 9. Report

Print what was applied, what conflicts remain (with the `.savvy-new` paths to review),
which migrations ran, and a reminder to reload Claude Code so hook/settings changes
take effect. Remind the user to delete `*.savvy-new` files once they've reconciled.

State how to roll back (from step 7): for a git repo, the exact `git revert` (or
`git checkout -- .`) that undoes the upgrade; for a non-git project, the
`.claude/.savvy-backup-<target-version>/` directory and how to restore from it (copy
its files back over the originals). Also remind the user to delete that backup dir once
they're satisfied the upgrade is good.

## Invokes / invoked by

- `/sf:upgrade` — entry point.
- `framework-linter` — surfaces "update available" and "managed file locally modified"
  as findings; points here.
- `session-start.sh` hook — prints the cached update-available nudge that points here.

## Output

- A plan report (always), then on confirmation: added/refreshed files, additive
  merges to settings.json/config.toml, `*.savvy-new` files for conflicts, any
  migrations run, a rewritten `.claude/.savvy-manifest.json` baseline (with
  `conflict: true` markers on unresolved conflicts), and — for non-git projects — a
  `.claude/.savvy-backup-<target-version>/` directory holding the pre-upgrade copies
  of every refreshed/merged file.

## Failure modes

- **Plugin-adopted project** (`enabledPlugins["sf@savvy"] == true` or
  `.claude/.savvy-engine-version` present): STOP at step 0 with no file action;
  engine updates flow through `/plugin update sf@savvy`. `/sf:upgrade` is legacy-only.
- **No target source resolvable** (offline, no plugin, no arg, no reachable release
  tag): report and stop; no changes. Never fall back to `main` — it may no longer
  carry `template/`.
- **No local manifest**: conservative mode — every differing managed file is a
  conflict, nothing auto-overwritten. This is expected for pre-manifest projects.
- **Not a framework project** (no `.claude/` or no `config.toml`): refuse with a
  one-line error.
- **Target ≤ local version**: report up-to-date; do nothing unless `--force`.
- **Dirty working tree (git repo)**: STOP before applying; ask the user to commit or
  stash, or to explicitly acknowledge proceeding dirty (step 7). Keeps the upgrade a
  single revertible change.
- **Non-git project**: no `git revert` safety net, so REFRESH/MERGE targets are copied
  to `.claude/.savvy-backup-<target-version>/` before overwrite (step 7); restore by
  copying them back.
- **Sticky conflict silently refreshed**: a baseline entry left with the *kept* hash
  but WITHOUT `conflict: true` re-classifies as REFRESH next run and overwrites a file
  the user chose to keep. Prevented by always writing `conflict: true` for unresolved
  conflicts (step 8) and never treating such entries as refresh-eligible (step 3).
- **Migration script fails**: halt remaining migrations, report which one and its
  output; file changes already applied stand (they are independent and idempotent).
- **`jq` unavailable for JSON parsing**: parse the manifest with the available tool
  (python3 fallback) or instruct the user to install `jq`; do not guess hashes.
- **A `seeded` file differs from target**: this is normal and expected (it's your
  work). Never report it as a conflict; only count it under untouched.
