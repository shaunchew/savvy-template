---
name: spec-bootstrap
description: Triggered by /spec <category>/<name> to auto-number, scaffold spec.md/plan.md/tasks.md/checklist.md with prefilled frontmatter, and append the new spec to ROADMAP.md.
---

# Spec Bootstrap

Scaffolds a new spec folder with the four required files and registers it in `ROADMAP.md`. Triggered by `/spec <category>/<name>`.

## When to invoke

- User runs `/spec <category>/<name>`.
- `project-intake` or `project-evolve` proposes a new spec and the user approves.

## Procedure

1. Parse arguments. Require `<category>/<name>` where `<category>` is one of `product`, `marketing`, `ops`, `research`. Reject any other category.
2. Normalize `<name>` to kebab-case (lowercase, hyphens, ASCII only).
3. Auto-number. Scan `specs/<category>/` for directories matching `NNN-*`. Pick max numeric prefix + 1. Zero-pad to three digits. If `specs/<category>/` does not exist, start at `001`.
4. Compute folder path: `specs/<category>/<NNN>-<kebab-name>/`. If it already exists, abort with an error.
5. Compute today's date as `YYYY-MM-DD`.
6. Create the folder and write four files. Each file begins with this frontmatter (substituting values):
   ```
   ---
   title: <name>
   category: <category>
   number: <NNN>
   status: draft
   created: <YYYY-MM-DD>
   ---
   ```
7. File bodies after the frontmatter:
   - `spec.md`: H1 `# <title>` then sections `## Problem`, `## Solution sketch`, `## Out of scope`, `## Acceptance`.
   - `plan.md`: H1 `# Plan — <title>` then `## Approach`, `## Files`, `## Sequencing`, `## Risks`.
   - `tasks.md`: H1 `# Tasks — <title>` then one starter line `- [ ] <first task>`.
   - `checklist.md`: H1 `# Release gate — <title>` then `## Release gate checklist` with rows `- [ ] Tests pass`, `- [ ] Docs updated`, `- [ ] CHANGELOG entry`, `- [ ] Approvals`, `- [ ] Notion synced (if enabled)`.
8. Append the spec to `ROADMAP.md`. Find the `### <Category>` heading under `## Active` (matching the spec's category, title-cased). If missing, create it. Append a line: `- <NNN>-<kebab-name> — draft`.
9. Print to the user: created folder path, list of files, and a suggested branch name: `<category>/<NNN>-<kebab-name>` (per Appendix B).

## Output

- New folder `specs/<category>/<NNN>-<kebab-name>/` with four files.
- Updated `ROADMAP.md` with a new entry under the right category.
- A one-line summary plus the suggested branch command.

## Failure modes

- Invalid category: refuse and list the four allowed values.
- Folder already exists at the computed path: abort without writing; suggest `/spec-revise <ref>`.
- `ROADMAP.md` missing: write a new minimal `ROADMAP.md` with `## Active` and the category heading, then append.
- Name resolves to empty after kebab-casing: refuse and ask for a non-empty name.
