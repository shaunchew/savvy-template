# RAM (Remote AI Maestro) Integration

RAM is a standalone frontend that exposes a unified capture surface across all
your repos. Tasks captured in RAM are routed to the sandbox of the repo they
belong to.

## Behavior

- Tasks captured in RAM are tagged with this repo's `project_slug`.
- RAM dispatches the task to the matching repo sandbox over `ram_endpoint`.
- Requires a separately deployed RAM frontend — this integration is the client
  half of that connection.

## Enabling

1. Stand up the RAM frontend (separate deployment).
2. Set `ram_endpoint` in `config.toml` to the RAM dispatch URL.
3. Export `RAM_TOKEN` in the environment running this repo's sandbox.
4. Flip `[integrations] ram = true` in `.claude/config.toml`.

The `project_slug` defaults to the templated project name and rarely needs
overriding.
