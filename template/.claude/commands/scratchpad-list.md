---
description: List all active scratchpads with age and last-touched date.
---

# /scratchpad-list

List active scratchpads with age (days since created) and last-modified (days since most-recent mtime in the folder). Sort by recency. Highlight staleness.

## Procedure

1. Enumerate directories matching `scratchpads/<NNN>-*/` (skip `scratchpads/_archive/`).
2. For each, gather:
   - `name` — folder basename
   - `created` — from `SCRATCHPAD.md` frontmatter `created:`, falling back to folder ctime
   - `age_days` — today minus created
   - `last_modified_days` — today minus most-recent mtime across all files in the folder
   - `generated_count` — number of files under `generated/`
3. Sort the list by `last_modified_days` ascending (most-recently-touched first).
4. Print a fixed-width table with columns: `Name | Age | Last touched | Generated files`. Append a `WARN stale` marker on any row where `last_modified_days > 60`.
5. If there are zero active scratchpads, print `No active scratchpads. Create one with /scratchpad <name>.`
6. After the table, print a single-line legend: `Stale threshold: 60 days without modification. Promote with /promote-scratchpad or archive with /archive-scratchpad.`

## Output

A sorted table of active scratchpads with age and mtime, stale rows flagged. No files change.
