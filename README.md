# savvy-template

The Savvy Coding Framework — a self-owned, agent-agnostic, tool-agnostic framework for managing solo-developer projects across multiple AI coding assistants (Claude Code, Codex, Gemini).

This repo is a [Copier](https://copier.readthedocs.io/) template. It is consumed via the `savvy` CLI, the `copier copy` command, or the `shaunchew/savvy-template-quickstart` GitHub Template wrapper.

## Quick start

```bash
# Recommended — via savvy CLI (see cli/savvy.zsh)
savvy new my-project --llm claude --idea "one-line idea here"

# Or directly via Copier
uvx copier copy gh:shaunchew/savvy-template my-project
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
