# Notion Integration

Mirrors spec and task state from this repo into a Notion database so non-engineers
can track progress without touching the codebase.

## Behavior

- On spec creation, `tasks.md` is pushed as rows into the configured Notion database.
- When `sync_mode = "realtime"`, a GitHub Action runs on every commit that touches
  a spec and updates the matching Notion rows.
- When `sync_mode = "manual"`, sync only runs when you invoke `/sync-notion`.
- `/ship` marks the associated Notion rows as complete.

## Enabling

1. Create a Notion integration and share the target database with it.
2. Set `database_id` in `config.toml` to the target database.
3. Add a `NOTION_TOKEN` secret in the repo's GitHub Actions settings.
4. Flip `[integrations] notion = true` in `.claude/config.toml`.
