# savvy-template

The Savvy Coding Framework — a self-owned, agent-agnostic, tool-agnostic framework for managing solo-developer projects across multiple AI coding assistants (Claude Code, Codex, Gemini).

This repo is a [Copier](https://copier.readthedocs.io/) template. It is consumed via the `savvy` CLI, the `copier copy` command, or the `shaunchew/savvy-template-quickstart` GitHub Template wrapper.

## Quick start

There are two onboarding paths. Pick one, then open your LLM CLI to start using the framework.

### Path A — Starting a fresh project

Pick whichever is easiest:

```bash
# One-liner. Auto-installs `uv` and scaffolds into a new subdir.
curl -fsSL https://raw.githubusercontent.com/shaunchew/savvy-template/main/install.sh | bash -s -- my-project

# If `uv` is already installed.
uvx copier copy gh:shaunchew/savvy-template my-project

# If the `savvy` zsh CLI is sourced (see "Optional savvy CLI" below).
savvy new my-project --llm claude --idea "one-line idea here"
```

Copier walks you through the prompts (`project_name`, `variant`, `llm`, integration toggles). When it finishes it auto-runs `git init && git add . && git commit` for a clean baseline.

### Path B — Adding to an existing project

If you already have a project folder (with or without an existing git repo), scaffold into the current directory using `.`:

```bash
cd ~/path/to/existing-project

# Recommended first: commit any uncommitted work so the framework scaffold
# lands as a separate commit and your existing history stays clean.
git add . && git commit -m "snapshot before savvy scaffold"

# Then one of:
curl -fsSL https://raw.githubusercontent.com/shaunchew/savvy-template/main/install.sh | bash
# or
uvx copier copy gh:shaunchew/savvy-template .
```

Notes for existing projects:

- Don't use `savvy new` for this — it always creates a new subdirectory.
- If you already have `README.md`, `AGENTS.md`, `CHANGELOG.md`, etc., Copier will prompt per file. Choose carefully.
- Two migration variants are supported. **Variant A (passive coexistence)** is the default — new structure lands alongside old files; legacy ages out naturally. **Variant B (active archival)** sweeps non-conforming files into `_legacy/initial-migration-<date>/` for triage; run `/legacy-review --initial-migration` inside Claude Code after the scaffold. See `docs/PLAN.md` §12.

### Do I need an LLM CLI session?

**Not for scaffolding.** The `copier copy` step is pure file generation — no LLM required.

**Yes for everything after.** The framework is exercised inside a Claude Code (or Codex / Gemini) session: slash commands like `/spec`, `/plan`, `/ship`, `/intake`, `/curate` only work there. After scaffolding:

```bash
cd <project>
claude   # or codex / gemini if you chose those at scaffold time
```

For fresh projects, `savvy new` writes `.claude/intake-input.md` and the `SessionStart` hook (`.claude/hooks/session-start.sh`) deterministically surfaces it so Claude runs `/intake --from-file` on session start. For existing projects (Path B), kick off context-building manually:

```
/intake "<one-line description of what this project does and where it's headed>"
```

That walks the 5-batch bootstrap (core files → specs → ADRs → subagents → integrations), with per-batch approval.

### Optional — `savvy` CLI on your machine

Wraps the one-liner with intake-prefill and LLM auto-launch:

```bash
git clone https://github.com/shaunchew/savvy-template ~/code/savvy-template
echo 'source ~/code/savvy-template/cli/savvy.zsh' >> ~/.zshrc
source ~/.zshrc

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

## Patching an existing scaffold

For projects scaffolded from an older version, each release that needs a retroactive fix ships an idempotent script in [`migrations/`](migrations/). Apply one-liner:

```bash
cd <your-project>
curl -fsSL https://raw.githubusercontent.com/shaunchew/savvy-template/main/migrations/<version>.sh | bash
```

See [`migrations/README.md`](migrations/README.md) for the catalogue and the contract these scripts follow.
