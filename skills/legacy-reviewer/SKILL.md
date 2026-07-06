---
name: legacy-reviewer
description: Walks _legacy/<migration>/ items one-by-one offering Keep archived / Delete now / Restore; logs decisions to REVIEW-LOG.md. Initial pass via /sf:legacy-review --initial-migration.
---

# Legacy Reviewer

Walks items in `_legacy/<migration-name>/` one at a time. Per-item options: Keep archived, Delete now, or Restore. Logs every decision to `REVIEW-LOG.md`.

## When to invoke

- User runs `/sf:legacy-review` (walk all pending items across migrations).
- User runs `/sf:legacy-review <migration-folder>` (single migration).
- User runs `/sf:legacy-review --initial-migration` (first-time framework adoption on an existing repo).
- `framework-linter` warns about a `_legacy/<migration>/` folder older than 90 days.

## Procedure

### Standard walk (no `--initial-migration`)

1. List subfolders under `_legacy/` with status: untouched / partially-reviewed / fully-reviewed (derived by comparing folder contents against `REVIEW-LOG.md`).
2. If the user passed a specific migration folder, scope to it; otherwise ask which to walk.
3. Read `MIGRATION_NOTES.md` to understand what was moved and why. Read `REVIEW-LOG.md` to build the set of already-decided items; skip those.
4. For each remaining file or directory, present the path and a one-line summary, then ask:
   - `keep` -> mark as reviewed-and-kept; no file move.
   - `delete` -> `rm` the item (use `git rm` if tracked).
   - `restore` -> propose a destination path inferred from `MIGRATION_NOTES.md` "What moved" section; let the user confirm or override; move with `mv` (or `git mv`). If the item is `AGENTS.md`, `CLAUDE.md`, or `constitution.md`, route through `framework-curator` before writing.
5. After each decision, append to `_legacy/<migration>/REVIEW-LOG.md` under a `## YYYY-MM-DD` heading (create heading for today if missing): `- <path> -- <KEPT-ARCHIVED|DELETED|RESTORED to <dest>>: <one-line rationale>`.
6. When every item in the migration folder has a log entry, ask: "Move folder to `_legacy/_archive/`, or remove entirely?" Act accordingly.

### Initial-migration walk (`--initial-migration`)

This is a bulk file-move over someone's existing repository. Treat it as destructive and gate it hard.

1. **Pre-flight: require a clean tree.** Run `git status --porcelain --untracked-files=no`. If it prints anything (any staged or unstaged change to TRACKED files), or the directory is not a git repo, ABORT and tell the user to commit or stash first. Untracked files do NOT block the sweep — they are often exactly the stray notes being swept (moved with plain `mv`, per step 5). A clean tree is what makes the whole sweep one revertible diff — never sweep with a dirty tree.

2. **Scan for candidates, honoring the never-sweep whitelist.** List files and directories at the repo root (and obvious ad-hoc note locations) that are not part of the framework, the project's own source, or standard tooling. NEVER move anything matching this whitelist:
   - Framework dirs: `specs/`, `docs/`, `scratchpads/`, `.claude/`, `_legacy/`.
   - The project's own source dirs (whatever roots the repo clearly builds from — e.g. `src/`, `lib/`, `app/`, `pkg/`, `internal/`, `cmd/`).
   - Build / tooling manifests: `package.json`, `pyproject.toml`, `Cargo.toml`, `go.mod`, `Gemfile`, `pom.xml`, `build.gradle`, `Makefile`, `CMakeLists.txt`.
   - Lockfiles: `package-lock.json`, `yarn.lock`, `pnpm-lock.yaml`, `poetry.lock`, `Cargo.lock`, `go.sum`, `Gemfile.lock`, and the like.
   - CI / config: `.github/`, `.gitlab-ci.yml`, and any other CI configuration.
   - `LICENSE*`, `README.md`, `.git*` (`.gitignore`, `.gitattributes`, …), `.env*`, `node_modules/`, `vendor/`, `dist/`, `build/`.

   Everything else is only a *candidate* — typically stray planning docs (a root-level `PLAN.md`, `TASKS.md`), scratch notes, or abandoned drafts.

3. **Group candidates** by likely origin (old `plans/`, `tasks/`, ad-hoc notes, abandoned drafts) and present each to the user. Do NOT move anything yet.

4. **Confirm per item.** Require an explicit `y`/`n`/`skip` for anything that is not clearly ad-hoc scratch notes. Only unambiguous scratch notes may be batched, and even then show the full list and get one confirmation before moving.

5. **Move approved items** into `_legacy/initial-migration-YYYY-MM-DD/`, preserving relative paths. Use `git mv` for tracked files (preserves history); use plain `mv` only for untracked files. Never `rm -rf`, and never move a whole directory blindly — move its files.

6. **Write `_legacy/initial-migration-YYYY-MM-DD/MIGRATION_NOTES.md`** from this template, one table row per moved file:

   ```
   # Migration notes — initial adoption — YYYY-MM-DD

   Swept non-conforming files into this folder during `/sf:legacy-review --initial-migration`.
   Nothing here was deleted; each row records where a file came from and how to restore it.

   | Moved file (under this folder) | Original path | Restore command |
   |---|---|---|
   | PLAN.md | ./PLAN.md | git mv _legacy/initial-migration-YYYY-MM-DD/PLAN.md ./PLAN.md |

   To restore everything, run each row's restore command (use plain `mv` instead of `git mv`
   for files that were untracked when they were moved).
   ```

7. **Create an empty `REVIEW-LOG.md`** in the same folder. Tell the user to run `/sf:legacy-review <that-folder>` later for item-by-item Keep/Delete/Restore decisions.

## Output

- Updated `_legacy/<migration>/REVIEW-LOG.md` (append-only).
- File moves: deletions, restores back into active layout, or folder moves into `_legacy/_archive/`.
- For `--initial-migration`: a populated `_legacy/initial-migration-<date>/` with `MIGRATION_NOTES.md` and an empty `REVIEW-LOG.md`.

## Failure modes

- `MIGRATION_NOTES.md` missing: ask the user to skip or reconstruct from `git log`; do not auto-generate guesses.
- `REVIEW-LOG.md` missing: create it with a `# Review Log -- <migration> -- YYYY-MM-DD` header before first append.
- Restore destination conflicts with an existing file: refuse the restore, ask the user to choose another path or delete instead.
- User aborts mid-walk: leave already-logged decisions in place; the folder simply remains partially-reviewed.
- `--initial-migration` finds nothing outside canonical layout: report cleanly and do not create an empty `_legacy/` folder.
