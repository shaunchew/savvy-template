# Telegram Integration

Mobile capture bot that lets you fire tasks into this repo's sandbox from
anywhere via Telegram.

## Behavior

- Runs as a standalone deployment under `bot/` (not part of this repo's runtime).
- Accepts text messages and image attachments from approved chats.
- Forwards captured tasks to the repo sandbox over the configured webhook.
- A message containing `/sf:spec product/003` auto-tags the task against that spec.

## Enabling

1. Deploy the bot separately and obtain a public webhook URL.
2. Set `webhook_url` in `config.toml` to that URL.
3. Add your Telegram chat IDs to `allowed_chat_ids` (anything else is rejected).
4. Export `TELEGRAM_BOT_TOKEN` in the bot's runtime environment.
5. Flip `[integrations] telegram = true` in `.claude/config.toml`.
