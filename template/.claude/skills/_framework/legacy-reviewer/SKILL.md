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

1. Scan the repo for files outside the canonical structure defined in `docs/PLAN.md` §3 (anything not in `specs/`, `docs/`, `.claude/`, `src/`, etc.).
2. Group findings by likely origin (old `plans/`, `tasks/`, ad-hoc notes, abandoned drafts).
3. Present each group to the user with proposed archive action. Do NOT move anything yet.
4. Once the user approves, bulk-move approved items to `_legacy/initial-migration-YYYY-MM-DD/` preserving relative paths.
5. Generate `_legacy/initial-migration-YYYY-MM-DD/MIGRATION_NOTES.md` summarizing what got archived and why, using the format in PLAN §5.9.
6. Create an empty `REVIEW-LOG.md` in the same folder. Tell the user to run `/sf:legacy-review <that-folder>` later for item-by-item decisions.

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
