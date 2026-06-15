---
description: Rebuild ROADMAP.md index from specs/ folder contents; 150-line cap.
---

# /sf:refresh-roadmap

Rebuild `ROADMAP.md` from scratch by scanning every spec folder.

## Procedure

1. For each category in `product`, `marketing`, `ops`, `research`, list every direct child folder of `specs/<category>/` matching `<NNN>-<name>/`. Skip `specs/_archive/`.
2. For each spec folder, read `spec.md` frontmatter to extract `status` and `title` (or fall back to a humanized form of the folder name if either is missing).
3. Group entries by category. Within each category, sort by `NNN` ascending.
4. Compose a fresh `ROADMAP.md` with this layout:
   - `# Roadmap`
   - `Last refreshed: <ISO timestamp>`
   - `## Active` — per category subsection (`### Product`, `### Marketing`, `### Ops`, `### Research`). Each entry is `- [<category>/<NNN>-<name>](specs/<category>/<NNN>-<name>/) — <status> · <title>`. Omit a category subsection if it has no specs.
   - `## Recently shipped` — single line: `See CHANGELOG.md.`
5. Overwrite `ROADMAP.md`. Enforce a hard ceiling of 150 lines — if over, truncate the longest category and append a `(+N more — see specs/)` line for that category.
6. Print the spec count per category and the final line count.

## Output

`ROADMAP.md` rewritten end-to-end, under 150 lines. Console prints a count summary.
