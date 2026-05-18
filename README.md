# savvy-template

The Savvy Coding Framework — a self-owned, agent-agnostic, tool-agnostic framework for managing solo-developer projects across multiple AI coding assistants (Claude Code, Codex, Gemini).

This repo is a [Copier](https://copier.readthedocs.io/) template. It is consumed via the `savvy` CLI, the `copier copy` command, or the `shaunchew/savvy-template-quickstart` GitHub Template wrapper.

## Quick start

**One-liner** — scaffolds into the current directory (auto-installs `uv` if missing):

```bash
curl -fsSL https://raw.githubusercontent.com/shaunchew/savvy-template/main/install.sh | bash
```

Into a new subdirectory:

```bash
curl -fsSL https://raw.githubusercontent.com/shaunchew/savvy-template/main/install.sh | bash -s -- my-project
```

If you already have `uv` installed:

```bash
uvx copier copy gh:shaunchew/savvy-template .          # current dir
uvx copier copy gh:shaunchew/savvy-template my-project # new subdir
```

Or via the `savvy` CLI (after sourcing `cli/savvy.zsh` in your `~/.zshrc`):

```bash
savvy new my-project --llm claude --idea "one-line idea here"
```

## What you get

- **Markdown-only core.** No DB. No external service required.
- **Spec-driven development.** constitution → spec → plan → tasks → implement.
- **Agent-portable.** `AGENTS.md` canonical; `CLAUDE.md` slim overlay.
- **10 universal framework skills** that police the framework itself in every project.
- **23 slash commands** for the daily workflow (`/spec`, `/plan`, `/ship`, `/handover`, `/curate`, …).
- **Opt-in integrations** for Notion, Telegram, and RAM. Disabled by default.
- **Updates propagate** via `copier update`.

## Layout

```
savvy-framework/
├── copier.yml          # Copier configuration (questions + tasks + migrations)
├── docs/
│   └── PLAN.md         # The living v1.0 spec for the framework itself
├── cli/
│   └── savvy.zsh       # v1.0 CLI — zsh function for ~/.zshrc
└── template/           # Everything Copier copies into a new project
    ├── AGENTS.md
    ├── CLAUDE.md
    ├── constitution.md
    ├── .claude/
    ├── specs/
    ├── docs/
    └── …
```

See [`docs/PLAN.md`](docs/PLAN.md) for the full specification.

## Status

v1.0 — Ready to scaffold. See `docs/PLAN.md` §15 for the rollout plan.
