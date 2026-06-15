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

## When to invoke

- User runs `/sf:upgrade` (optionally `/sf:upgrade --apply` to skip the second
  confirmation, or `/sf:upgrade <path-to-target>` to point at a specific source).
- User asks to "update the framework", "pull the latest framework", or "upgrade savvy".
- Do NOT invoke for application dependency upgrades — this is framework-only.

## Procedure

### 1. Locate the target release (what we're upgrading TO)

Resolve a target manifest, in this order:
1. Explicit path argument → read `<arg>/.claude/.savvy-manifest.json` (or `<arg>`
   if it points straight at a manifest).
2. Installed plugin → if a `savvy-framework` plugin is installed locally, read its
   bundled `.savvy-manifest.json`.
3. Remote → fetch `https://raw.githubusercontent.com/shaunchew/savvy-template/main/template/.claude/.savvy-manifest.json`
   with a short timeout. If a specific tag is desired, swap `main` for `v<version>`.

If none resolve (offline, no plugin, no arg): report that no target source is
available and stop. Suggest re-running with a path to a local checkout.

Read the target `version`. Read the local version from `.claude/config.toml`
`[framework] version`. If target ≤ local, print `Already up to date (v<local>).`
and stop — unless `--force` was passed.

### 2. Load the local baseline (what we're upgrading FROM)

Read `.claude/.savvy-manifest.json` from the project root.

- **Present** → use it as the `baseline` for each file (trusted record of what was
  last installed and whether the user has since edited it).
- **Absent** (every project scaffolded before manifests existed) → enter
  **conservative mode**: there is no trusted baseline, so treat *any* managed file
  whose `current` hash differs from `target` as a **conflict** (cannot prove it's
  unmodified). Nothing is auto-refreshed silently. This is the backward-compatible
  path — it never assumes a file is safe to overwrite.

### 3. Classify every file in the target manifest

For each entry `{path, policy, target_hash}`:

- **File absent on disk** → **ADD** (safe — nothing to overwrite), regardless of policy.
- **policy = seeded** → **SKIP** (untouched). Never refresh a seeded file. Only the
  ADD case above can ever create it.
- **policy = merge** → **MERGE** (see step 5). Never overwrite wholesale.
- **policy = managed**, file present:
  - `current == target` → **UP-TO-DATE** (no action).
  - `current == baseline` (and `baseline != target`) → **REFRESH** (you never edited
    it; safe to replace with the new version).
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

### 7. Apply (only after confirmation)

In this order:
1. **Add** the new files.
2. **Refresh** the unmodified managed files.
3. **Conflict** files: leave the original untouched; ensure `<path>.savvy-new` exists.
4. **Merge** settings.json / config.toml additively.
5. **Run migrations** in version order. Each is idempotent; a failure halts the rest
   and is reported.
6. **Write the new baseline**: regenerate `.claude/.savvy-manifest.json` from the
   target manifest. For files that were added, refreshed, or merged, the baseline
   hash is the new on-disk hash (matching target). For **conflict** files left
   unresolved, record the file's *current* (kept) hash, NOT the target hash — so
   the project still reflects reality and a later edit stays detectable. The
   conflict is surfaced in the report, not silently buried.

### 8. Report

Print what was applied, what conflicts remain (with the `.savvy-new` paths to review),
which migrations ran, and a reminder to reload Claude Code so hook/settings changes
take effect. Remind the user to delete `*.savvy-new` files once they've reconciled.

## Invokes / invoked by

- `/sf:upgrade` — entry point.
- `framework-linter` — surfaces "update available" and "managed file locally modified"
  as findings; points here.
- `session-start.sh` hook — prints the cached update-available nudge that points here.

## Output

- A plan report (always), then on confirmation: added/refreshed files, additive
  merges to settings.json/config.toml, `*.savvy-new` files for conflicts, any
  migrations run, and a rewritten `.claude/.savvy-manifest.json` baseline.

## Failure modes

- **No target source resolvable** (offline, no plugin, no arg): report and stop; no changes.
- **No local manifest**: conservative mode — every differing managed file is a
  conflict, nothing auto-overwritten. This is expected for pre-manifest projects.
- **Not a framework project** (no `.claude/` or no `config.toml`): refuse with a
  one-line error.
- **Target ≤ local version**: report up-to-date; do nothing unless `--force`.
- **Migration script fails**: halt remaining migrations, report which one and its
  output; file changes already applied stand (they are independent and idempotent).
- **`jq` unavailable for JSON parsing**: parse the manifest with the available tool
  (python3 fallback) or instruct the user to install `jq`; do not guess hashes.
- **A `seeded` file differs from target**: this is normal and expected (it's your
  work). Never report it as a conflict; only count it under untouched.
