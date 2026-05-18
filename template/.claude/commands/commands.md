---
description: List every slash command available in this project, grouped by purpose, with one-line descriptions and which skill each invokes.
---

# /commands

Print the complete catalogue of savvy-framework slash commands shipped with this project.

## Procedure

1. Scan `.claude/commands/*.md` to confirm which commands exist in this project (in case of drift or future additions).
2. Emit a markdown report using the categorisation below. For each command, show:
   - Command name (with `argument-hint` if present)
   - One-line description (from the file's frontmatter `description:`)
   - `Invokes:` skill name (where applicable)
3. Append a "Discovered but not categorised" section if any `.claude/commands/*.md` file isn't listed below — so the report stays self-healing as commands are added.
4. End with one line: `Use /tutorial for guided walkthroughs of the most common flows.`

## Categories

**Spec lifecycle** — `/spec`, `/plan`, `/tasks`, `/ship`, `/spec-revise`, `/spec-archive`

**Session hygiene** — `/handover`, `/checkpoint`, `/lesson`

**Framework curation** — `/curate`, `/evolve`, `/lint-framework`, `/refresh-roadmap`, `/stack-evolve`, `/status-sync`

**Intake & bootstrap** — `/intake`

**Scratchpads** — `/scratchpad`, `/scratchpad-exit`, `/scratchpad-list`, `/promote-scratchpad`, `/archive-scratchpad`

**Legacy & migration** — `/legacy-review`

**Integrations** — `/sync-notion`

**Help & discovery** — `/commands`, `/tutorial`

## Output

A single markdown block with one table per category. No edits to any file.
