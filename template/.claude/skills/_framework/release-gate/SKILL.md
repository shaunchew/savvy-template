---
name: release-gate
description: Triggered by /sf:ship <category>/<NNN> to walk checklist.md item-by-item; on all-pass updates CHANGELOG, moves spec to shipped, tags the release, and optionally syncs to Notion.
---

# Release Gate

Triggered by `/sf:ship <category>/<NNN>`. Walks `checklist.md` item-by-item; on all-pass, updates `CHANGELOG.md`, flips the spec status to shipped, updates `ROADMAP.md`, proposes a SemVer bump and git tag, and triggers Notion sync if enabled.

## When to invoke

- User runs `/sf:ship <category>/<NNN>` (e.g., `/sf:ship product/009`).
- User asks to "release", "ship", or "tag" a specific spec that has a `checklist.md`.
- Do NOT invoke for arbitrary commits or for specs without a checklist.

## Procedure

1. Resolve the spec folder under `specs/<category>/<NNN>-*/`. If multiple match, ask which one.
2. Read `spec.md` frontmatter — confirm `status: draft` (or `in-progress`). Refuse if already `shipped` or `archived`.
3. Read `checklist.md`. For each line of the form `- [ ] <item>`, in file order:
   1. Print the item text to the user.
   2. Ask: `y` (passed), `n` (failed), or `skip` (defer).
   3. On `y`: rewrite that line in place as `- [x] <item>` and continue.
   4. On `n` or `skip`: HALT. Report which item blocked the release. Do NOT touch CHANGELOG, ROADMAP, or status. Exit.
4. Already-checked items (`- [x]`) are confirmed silently; do not re-prompt.
5. On all-pass, infer CHANGELOG sections from `spec.md` headings: `## Added` -> Added, `## Changed` -> Changed, `## Fixed` -> Fixed. Anything else falls back to Changed.
6. Append a bulleted entry per section under the `## [Unreleased]` block in `CHANGELOG.md`. Create the `[Unreleased]` block at the top of the file if missing.
7. Propose a SemVer bump based on inferred sections (Added => minor, Fixed only => patch, Changed touching invariants => major). Ask the user to confirm or override; rename `## [Unreleased]` to `## [<version>] - YYYY-MM-DD` (local date) and re-add an empty `## [Unreleased]` block above it.
8. Update `spec.md` frontmatter: `status: draft` -> `status: shipped`, add `shipped: YYYY-MM-DD`. Leave the spec folder in place.
9. Update `ROADMAP.md`: move the spec line from `## Active` to `## Recently shipped` with the shipped date.
10. Check `.claude/config.toml`. If `[integrations] notion = true`, invoke the `notion` integration sync skill against the spec; if absent, skip silently.
11. Stage the changed files and propose the commit message `feat(<category>/<NNN>): ship <spec name>` per Appendix B conventional commits. Propose the git tag `v<version>`. Do NOT push or tag without explicit user confirmation.

## Output

- Edits in place: `checklist.md` (boxes ticked), `spec.md` (status flipped), `CHANGELOG.md` (new version block), `ROADMAP.md` (moved entry).
- A proposed commit and tag, awaiting user confirmation.
- Notion sync side effect if enabled.

## Failure modes

- Spec has no `checklist.md`: refuse and tell the user to add one or use `/sf:spec-revise` to scaffold it.
- Any item answered `n` or `skip`: halt with the blocking item name; leave all files untouched except partial check marks already written (those stand — they are real).
- `CHANGELOG.md` missing: create it with `# Changelog\n\n## [Unreleased]\n` header, then append.
- Version proposal rejected by user: accept their override verbatim if it parses as SemVer; otherwise ask again.
- Notion sync fails: report the error but do NOT roll back the file changes — the release stands; the sync can be retried.
