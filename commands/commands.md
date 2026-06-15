---
description: List every slash command available in this project, grouped by purpose, with one-line descriptions and which skill each invokes.
---

# /sf:commands

Print the complete catalogue of savvy-framework slash commands shipped with this project.

## Procedure

1. Scan `.claude/commands/sf/*.md` to confirm which commands exist in this project (in case of drift or future additions).
2. Emit a markdown report using the categorisation below. For each command, show:
   - Command name (e.g. `/sf:spec`, with `argument-hint` if present)
   - One-line description (from the file's frontmatter `description:`)
   - `Invokes:` skill name (where applicable)
3. Append a "Discovered but not categorised" section if any `.claude/commands/sf/*.md` file isn't listed below — so the report stays self-healing as commands are added.
4. End with one line: `Use /sf:tutorial for guided walkthroughs of the most common flows.`

## Categories

**Spec lifecycle** — `/sf:spec`, `/sf:plan`, `/sf:tasks`, `/sf:ship`, `/sf:spec-revise`, `/sf:spec-archive`

**Session hygiene** — `/sf:handover`, `/sf:resume-handover`, `/sf:checkpoint`, `/sf:lesson`

**Framework curation** — `/sf:curate`, `/sf:evolve`, `/sf:lint-framework`, `/sf:refresh-roadmap`, `/sf:stack-evolve`, `/sf:status-sync`

**Intake & bootstrap** — `/sf:intake`

**Scratchpads** — `/sf:scratchpad`, `/sf:scratchpad-exit`, `/sf:scratchpad-list`, `/sf:promote-scratchpad`, `/sf:archive-scratchpad`

**Legacy & migration** — `/sf:legacy-review`, `/sf:upgrade`

**Integrations** — `/sf:sync-notion`

**Help & discovery** — `/sf:commands`, `/sf:tutorial`

## Output

A single markdown block with one table per category. No edits to any file.
