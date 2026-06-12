---
name: framework-linter
description: On-demand checker run via /sf:lint-framework that emits a structured Markdown report of drift, missing files, malformed specs, budget violations, version drift, and stale _legacy/scratchpad folders.
---

# Framework Linter

On-demand diagnostic run via `/sf:lint-framework`. Walks the repository, checks framework invariants, and emits a Markdown report grouped by severity. Performs no edits.

## When to invoke

- User runs `/sf:lint-framework`.
- Another skill (e.g., release-gate, legacy-reviewer) requests a pre-check.

## Procedure

Run every check below; collect findings into three buckets: `error`, `warning`, `info`.

1. **Required files.** Verify each of these exists at repo root or its declared path; missing = `error`:
   - `AGENTS.md`, `CLAUDE.md`, `constitution.md`, `ROADMAP.md`, `CHANGELOG.md`, `HANDOVER.md`, `.claude/settings.json`.
2. **Length budgets.** For each file in PLAN.md Appendix A, count non-trailing-blank lines. Over soft = `warning`. Over hard = `error`.
3. **Spec structure.** For each `specs/<category>/<NNN>-<name>/`:
   - Verify all four required files exist: `spec.md`, `plan.md`, `tasks.md`, `checklist.md`. Missing = `error`.
   - Verify YAML frontmatter in `spec.md` parses and contains `title`, `category`, `number`, `status`, `created`. Malformed = `error`.
   - Verify the folder's `<NNN>` matches `spec.md`'s `number` field. Mismatch = `error`.
   - Verify `<category>` is one of `product`, `marketing`, `ops`, `research`. Other = `error`.
4. **ROADMAP consistency.** Cross-check `ROADMAP.md` entries against spec folders:
   - Spec exists but not listed in ROADMAP = `warning`.
   - ROADMAP entry has no matching spec folder = `warning`.
   - Status in ROADMAP disagrees with `spec.md` frontmatter `status` = `warning`.
5. **Template version drift.** Read `.copier-answers.yml` if present; compare `_commit` against latest tag from the savvy-template remote. Drift across a minor version = `info`; across a major = `warning`.
5b. **Framework version + manifest drift.** Read `.claude/.savvy-manifest.json` if present:
   - Compare its `version` against the latest available framework version (installed plugin manifest, or the remote `template/.claude/.savvy-manifest.json`). Newer available = `info`, suggest `/sf:upgrade`.
   - For each `managed` entry, hash the on-disk file and compare against the manifest `sha256`. Any mismatch = `info` ("locally modified framework file — `/sf:upgrade` will treat it as a conflict, not overwrite it"). List the paths.
   - Manifest absent (pre-v1.4.0 project) = single `info`: "no framework manifest — run `/sf:upgrade` once to establish a baseline." Do not error.
6. **Stale `_legacy/` folders.** For each `_legacy/<migration>/`:
   - Folder mtime > 90 days AND no `REVIEW-LOG.md` = `warning`. Suggest `/sf:legacy-review <migration>`.
   - `REVIEW-LOG.md` present but does not contain "fully-reviewed" marker AND mtime > 90 days = `warning`.
7. **Stale scratchpads.** For each `scratchpads/<name>/` (excluding `_archive/`):
   - mtime > 60 days = `warning`. Suggest `/sf:promote-scratchpad <name>` or `/sf:archive-scratchpad <name>`.
8. **Pending changes overflow.** If `.claude/pending-changes.md` has > 50 entries, raise `warning`. Suggest `/sf:curate`.
9. **Rule decay.** Run `git blame` against `AGENTS.md`, `CLAUDE.md`, and `constitution.md`. For each non-blank, non-heading line whose last modification is older than 180 days, raise `info` with the line excerpt. The Claude Code blog recommends quarterly review of these files to remove rules that compensate for older model limitations; flag them as candidates for `/sf:curate` re-evaluation. Skip when not a git repo.

## Output

Print a Markdown report to stdout. Structure:

```
# Framework Lint Report — YYYY-MM-DD HH:MM

## Errors (N)
- <file>: <message>

## Warnings (N)
- <file>: <message>  [suggested fix]

## Info (N)
- <message>

## Summary
errors: N · warnings: N · info: N
```

End with the one-line summary count by severity. Do not modify any files.

## Failure modes

- No `.copier-answers.yml`: skip check 5 and add an `info` line noting the template version is unknown.
- No network access for version check: degrade checks 5 and 5b to a single `info` entry each; do not error.
- No `.claude/.savvy-manifest.json`: emit the single pre-v1.4.0 `info` from check 5b; do not run the per-file hash comparison.
- Malformed frontmatter that cannot be parsed: report as `error` with the parser message, continue with remaining specs.
- Repo not initialized with the framework (no `AGENTS.md`): emit a single `error` and stop further checks.
