# Notion Integration

Mirrors spec and task state from this repo into a Notion database so non-engineers can track progress without touching the codebase.

This integration has two modes — **MCP (recommended)** and **GitHub Action sync (legacy)**.

## Mode A — MCP (recommended)

Use the official Notion MCP server. Lets Claude read/write Notion directly during sessions.

1. Create a Notion integration at https://www.notion.so/profile/integrations and share the target database with it. Copy the integration's internal token.
2. Export the token in your shell environment:
   ```bash
   echo 'export NOTION_API_KEY="ntn_..."' >> ~/.zshrc
   source ~/.zshrc
   ```
3. Enable the Notion server in the project's `.mcp.json` (uncomment the block under `mcpServers`):
   ```json
   {
     "mcpServers": {
       "notion": {
         "type": "http",
         "url": "https://mcp.notion.com/mcp",
         "headers": { "Authorization": "Bearer ${NOTION_API_KEY}" }
       }
     }
   }
   ```
4. Set `database_id` in `config.toml`.
5. Flip `[integration.mcp] enabled = true` in `config.toml` and `[integrations] notion = true` in `.claude/config.toml`.
6. Restart Claude Code. Verify with `/mcp` — `notion` should be listed.

## Mode B — GitHub Action sync (legacy / out-of-band)

For cases where you want background sync on commits without a live session.

1. Create a Notion integration and share the target database with it.
2. Set `database_id` in `config.toml`.
3. Add a `NOTION_TOKEN` secret in the repo's GitHub Actions settings.
4. Flip `[integrations] notion = true` in `.claude/config.toml`.

Behavior:
- On spec creation, `tasks.md` is pushed as rows into the configured Notion database.
- When `sync_mode = "realtime"`, a GitHub Action runs on every commit that touches a spec and updates matching rows.
- When `sync_mode = "manual"`, sync only runs when you invoke `/sf:sync-notion`.
- `/sf:ship` marks associated Notion rows as complete.

## Picking a mode

- Use MCP when most of your Notion interaction is during Claude Code sessions (creating/updating specs, marking rows complete).
- Use GitHub Action sync when you want background mirroring independent of who's at the keyboard.
- The two modes can coexist — MCP for live editing, Action for guaranteed mirroring.

See [`../_mcp-template/README.md`](../_mcp-template/README.md) for the general MCP pattern.
