---
description: Manually push current spec/task state to Notion; no-op when [integration.notion] enabled = false.
---

# /sync-notion

Push current spec/task state to Notion. No-op when the Notion integration is disabled.

## Procedure

1. Read `.claude/config.toml`. If `[integrations] notion` is absent, `false`, or the file is missing, print `Notion integration disabled — no-op.` and exit cleanly.
2. Read `.claude/integrations/notion/config.toml`. Require `database_id` to be set; if empty, print a one-line error pointing at the config and exit.
3. Require the `NOTION_TOKEN` environment variable. If unset, print a one-line error explaining how to set it and exit without partial writes.
4. Walk `specs/<category>/*/` for all four categories (skip `specs/_archive/`). For each spec:
   - Read `spec.md` frontmatter (`title`, `status`, `NNN`, `category`).
   - Read `tasks.md` and parse each `- [ ]` / `- [x]` line as a row.
   - Upsert into the Notion database, matching existing rows by the composite key `<category>/<NNN>` so the operation is idempotent. Use the spec's `status` for the parent record and the checkbox state for each task row.
5. Track successes and failures per spec. After the walk, print a one-line-per-spec summary (`product/003: 7 tasks synced`) and a final tally.
6. Do not write anything back into the repo — Notion mirrors the repo, never the other way around.

## Output

Notion database rows upserted to match the current `specs/` state. Console prints a per-spec summary and a final tally, or a single no-op line when disabled.
