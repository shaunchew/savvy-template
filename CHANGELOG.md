# Changelog

All notable changes to the `savvy-template` repo. This is the template's own changelog — per-project changelogs are generated inside each scaffolded project.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.2.0] — 2026-05-19

Gap-closing pass against the Claude Code large-codebase best practices blog post. All seven priority gaps from the v1.1 assessment closed.

### Added
- `.claudeignore` at template root — excludes secrets, build artifacts, archive directories from Claude's read scope.
- `permissions.deny` block in `template/.claude/settings.json` — blast-radius guards (rm -rf on root/HOME/.git/.claude, force-push, hard reset to origin, sudo, secret-file reads).
- `SessionStart` hook (`template/.claude/hooks/session-start.sh`) — deterministic intake-input detection, framework version banner, pending-changes count, scratchpad-mode by CWD. Replaces model-driven CLAUDE.md instruction.
- MCP integration scaffold: project-scoped `.mcp.json` at template root, `_mcp-template/` reference, Notion MCP as Mode A (recommended) alongside the existing GitHub Action sync as Mode B.
- Three canonical subagents in `template/.claude/agents/`: `explorer` (read-only mapping), `code-reviewer` (independent pre-`/ship` review), `parallel-runner` (isolated parallel work).
- Subdirectory `AGENTS.md` pattern doc at `template/docs/agents-subdir-pattern.md` + `framework-curator` decision-tree branch (subdir AGENTS.md applied directly, not deferred).
- Plugin distribution path: `.claude-plugin/plugin.json` manifest at framework root + `scripts/build-plugin.sh` to materialize the plugin layout from `template/.claude/`.
- `/review` slash command — delegates to the `code-reviewer` subagent with diff + spec context + constitution.
- Rule-decay check in `framework-linter` — flags AGENTS.md / CLAUDE.md / constitution.md lines unchanged > 180 days as candidates for `/curate` re-evaluation.

### Changed
- `template/.claude/config.toml` version bumped to `1.1`.
- `template/CLAUDE.md` no longer carries the intake-input session-start instruction (now handled deterministically by the hook).
- `project-intake` Batch 4 now proposes ADDITIONAL project-specific subagents on top of the universal three.

## [1.1.0]

### Added
- `/commands` and `/tutorial` slash commands.
- `migrations/` infrastructure for patching existing scaffolds.

### Fixed
- Post-scaffold message rendering.

## [1.0.1]

### Fixed
- Stop-hook envelope structure.

## [1.0.0]

### Added
- Initial v1.0 skeleton: directory structure, `copier.yml`, `docs/PLAN.md`, stubbed skills/commands/hooks/integrations, `cli/savvy.zsh` stub.
