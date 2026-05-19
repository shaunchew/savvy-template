# MCP integration template

Reference pattern for adding a Model Context Protocol (MCP) server to this project. MCP is the modern, preferred way to wire external systems (Notion, GitHub, Linear, internal APIs) into Claude Code.

## When to use MCP vs bespoke integration

| Use MCP when... | Use bespoke (`.claude/integrations/<name>/`) when... |
|---|---|
| Vendor publishes an official MCP server (Notion, GitHub, Sentry, Linear) | No MCP exists and you need a custom hook/skill |
| You want tool-call semantics (Claude invokes named functions) | You need GitHub Action sync, webhook capture, or other out-of-band flow |
| Read/write to an external system on demand | Cron-style background sync |

## Wiring an MCP server

1. **Find the MCP server endpoint or package.** Most vendors host one. Examples:
   - Notion: `https://mcp.notion.com/mcp` (hosted)
   - GitHub: `https://api.githubcopilot.com/mcp/` (hosted) or `gh mcp` (stdio)
   - Custom: stdio command running your server

2. **Add an entry to `.mcp.json`** at the project root:

   ```json
   {
     "mcpServers": {
       "notion": {
         "type": "http",
         "url": "https://mcp.notion.com/mcp",
         "headers": {
           "Authorization": "Bearer ${NOTION_API_KEY}"
         }
       },
       "my-internal-api": {
         "type": "stdio",
         "command": "node",
         "args": ["./scripts/my-mcp-server.js"]
       }
     }
   }
   ```

3. **Store credentials in environment variables**, never inline in `.mcp.json`. Source from `.env` (already in `.claudeignore`) or your shell.

4. **Restart Claude Code** for the new MCP server to register. Verify with `/mcp`.

## Per-integration MCP toggle

If your bespoke integration directory wants to expose an MCP variant, add this to its `config.toml`:

```toml
[integration.mcp]
enabled = false
server_name = "notion"  # matches the key in .mcp.json
```

The framework's MCP-aware skills (Notion sync, etc.) will prefer the MCP server when enabled.

## Security

- Add `.mcp.json` to `.gitignore` if it contains environment-variable-substituted secrets you'd rather keep out of git history. Default scaffold keeps it tracked (env vars resolve at runtime, no secrets at rest).
- Use `permissions.deny` in `.claude/settings.json` to block MCP tools you don't trust.
