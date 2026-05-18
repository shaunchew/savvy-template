---
description: Walk _legacy/<migration>/ items deciding Keep/Delete/Restore; --initial-migration scans repo at first adoption.
argument-hint: "[--initial-migration]"
---

# /legacy-review

Run the legacy-reviewer walkthrough across `_legacy/` folders. With `--initial-migration`, scans the working tree for files that don't fit the new structure and proposes archival.

## Procedure

1. Parse `$ARGUMENTS`. If it contains `--initial-migration`, set flag `initial=true`. Otherwise `initial=false`. Any other token is treated as a specific `<migration-folder>` name under `_legacy/` and passed through.
2. Invoke the `legacy-reviewer` skill with `{initial: <bool>, target: <folder-or-null>}`.
3. The skill handles the loop:
   - If `initial=true`: scan repo for files outside the framework structure (e.g. root-level `PLAN.md`, `TASKS.md`, ad-hoc folders), propose `_legacy/initial-migration-<YYYY-MM-DD>/` archival per item with y/n/skip prompts, and generate `MIGRATION_NOTES.md` on approved moves.
   - If a target folder is given: walk that one folder.
   - Otherwise: discover all `_legacy/<migration>/` folders, show their review status (untouched / partial / full), and let the user pick which to walk.
4. For each item walked, the skill presents three options: **Keep archived** / **Delete now** / **Restore to active location** (restore routes context files through `framework-curator` first).
5. The skill appends each decision to `_legacy/<migration>/REVIEW-LOG.md` with timestamp, item, action, optional note.
6. When all items in a migration folder are reviewed, the skill prompts: "Move folder to `_legacy/_archive/` or remove entirely?".
7. On return, print a one-line summary: number of items reviewed, kept, deleted, restored, plus any folder-level finalization that occurred.

## Arguments

- `$ARGUMENTS` — optional. Either `--initial-migration` (special scan mode), a `<migration-folder>` name, or empty (interactive picker). Pass through to the skill verbatim.

## Invokes

- `legacy-reviewer`
- `framework-curator` (transitively, when restoring context files)

## Output

Interactive per-item prompts driven by the skill, then a final summary. Files changed: `_legacy/<migration>/REVIEW-LOG.md` (appended), files deleted/restored as the user approves, and `MIGRATION_NOTES.md` created in initial-migration mode.
