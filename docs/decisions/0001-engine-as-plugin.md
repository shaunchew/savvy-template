# 0001 — Engine ships as a Claude Code plugin; skeleton seeded once

## Status

Accepted — 2026-06-15

## Context

The framework distributed itself through **four overlapping mechanisms** that all touched project trees and competed for the same files:

1. **Copier** — greenfield scaffolding via `copier.yml` / `install.sh` / `cli/savvy.zsh`.
2. **Plugin** — `.claude-plugin/` (payload gitignored and effectively empty; plugin named `savvy-framework`, not `sf`; no `marketplace.json`).
3. **sha256-manifest `/sf:upgrade`** — a hand-rolled diff/upgrade engine driven by `.savvy-manifest.json`.
4. **Migration scripts** — `migrations/*.sh`, including delete-by-name transforms (`v1.3.0.sh`) that could remove user files.

This produced two acute pains:

- **Update-fear.** Every update mechanism reached into the project tree, so users could not trust an upgrade not to overwrite or delete their work. The diff/manifest engine tried to make this safe but only relocated the fear.
- **Drift and duplication.** The same engine files existed in `template/.claude/` and `.claude-plugin/` with no single source of truth, and four code paths could mutate a project, none of them the obvious one.

## Decision

Collapse the four mechanisms into **two layers plus one frozen escape hatch**.

### Two-layer model

- **ENGINE** (skills / commands / hooks / agents) ships **only as a Claude Code plugin**. `.claude-plugin/` becomes the **sole authored copy** (authorship inverted; engine dirs deleted from `template/`). It installs into `~/.claude/plugins`, **outside every project tree**, and updates via `/plugin update`. Update-fear dies by **location**, not by a diff engine: an engine that lives outside the repo is structurally incapable of touching project files.
- **SKELETON** (~12 seeded files: `AGENTS.md`, `CLAUDE.md`, `constitution.md`, ROADMAP/CHANGELOG, `config.toml`, the `permissions.deny` settings fragment, specs/docs READMEs) is laid down once by a single **create-if-absent `/sf:adopt`** serving both new and existing projects. Overwrite is not a capability of that code path.
- **MIGRATIONS** are frozen — reserved for genuine one-time transforms, hash-gated and git-guarded.

### Three locked owner decisions

1. **Retire Copier entirely.** `/sf:adopt` covers greenfield + brownfield; `install.sh` and `cli/savvy.zsh` fold in.
2. **Plugin name = `sf`.** Preserves the `/sf:` command namespace (plugin skills/commands are namespaced by plugin name).
3. **Skeleton bytes are embedded in the plugin** — no live fetch, so adoption is offline / air-gapped capable.

### Safety invariants (enforced mechanically)

1. Seeded writes route through **one writer-boundary function** that physically cannot overwrite/truncate/delete.
2. Every mutating op is **git-guarded** (refuse dirty tree / take a snapshot) → reversible by `git reset`.
3. `permissions.deny` is **additive union only** and stays in the seeded settings.json (plugins cannot carry deny rules).
4. **One secret-scan floor guard** stays in seeded settings.json → can never vanish if the plugin is absent.
5. **Exactly one code path may delete** (a migration), only on a known-baseline sha match; otherwise back up as `.savvy-old` and report.
6. SF **always ships an explicit `version`** in `plugin.json` (the update cache key); commit-SHA / per-commit publishing is forbidden.

## Consequences

### Positive

- Engine updates cannot touch project files — update-fear is killed by location.
- One source of truth for the engine; one writer boundary for seeded files; one delete path.
- Explicit-version gating makes `/plugin update` a no-op until the version string changes, so a v1.4 project is structurally immune to v2.0 semantics.
- Offline-capable adoption; no remote fetch dependency.

### Negative / risks

- **Multi-CLI re-scope.** The pitch is now "Claude-driven engine + agent-portable markdown context," **not** "agent-agnostic engine." There is zero Codex/Gemini payload. Those users get the same `AGENTS.md` / specs / docs structure and prose contract, but **no slash-command/hook automation**. A real port is a future, separate package.
- **Version-pinning / silent-drift risk.** Background auto-update at startup is the true cross-project drift vector and there is **no clean per-plugin auto-update off switch**. Mitigated by explicit-version gating (Invariant #6) plus a session-start version stamp (`.claude/.savvy-engine-version`) that warns on a `config.toml` compatibility-floor mismatch. sha-pin on the plugin source is the hard freeze.
- **Coexistence window.** A project that still has the in-tree engine plus the installed plugin will **double-fire hooks** (commands merge, deduped only by exact string). `/sf:adopt` must detach the in-tree engine atomically; until then it is an unsupported interim state.

## Alternatives considered

- **Keep all four mechanisms.** Rejected: this is the status quo that produces update-fear, drift, and four competing writers. No single source of truth.
- **Plugin-only (no seeded skeleton).** Rejected: `permissions.deny` and a secret-scan floor guard cannot live in a plugin's settings.json, and projects need a git-tracked, prose-portable context layer (`AGENTS.md`, specs, docs) that survives even when the plugin is absent.
- **Copier-only (drop the plugin).** Rejected: Copier writes into the project tree, so every engine update re-touches project files — exactly the update-fear we are eliminating. It also gives Claude Code no native command/hook/skill surface.

## Amendments from red-team

Folded-in P0/P1 corrections to the locked plan (full set tracked in the rearchitecture brief):

- **P0 — Real distribution path.** There is no `gh:` install. Author `.claude-plugin/marketplace.json` (marketplace name `savvy`, plugin `{name: "sf", source: "."}`), set `plugin.json` name to `sf`. Install is two-step: `/plugin marketplace add shaunchew/savvy-template` then `/plugin install sf@savvy`.
- **P0 — Non-empty payload.** Remove `.gitignore` lines 17–20; commit real engine files; flatten skills to `skills/<name>/SKILL.md` (or point `plugin.json` `skills` at the wrapper); strip the 0-byte `agents/.gitkeep`; `chmod +x` all hook scripts.
- **P0 — Self-locating hooks.** Author `hooks/hooks.json` for all four events. `CLAUDE_PLUGIN_ROOT` is intermittently unset (upstream bug) for SessionStart/PreToolUse/PostToolUse/PreCompact, so every hook must self-locate via `$0`/`BASH_SOURCE` with `${CLAUDE_PLUGIN_ROOT:-<fallback>}` as a belt.
- **P0 — Explicit semver is a release invariant** (Safety Invariant #6); version set in `plugin.json` only, never duplicated in the marketplace entry.
- **P0 — Atomic adopt (moved to Phase 2).** `/sf:adopt` detaches the in-tree engine (remove in-tree `commands/sf/`, `skills/_framework/`, `agents/`, strip the 5 framework hook entries) in the **same** operation that activates the plugin. Ship a session-start coexistence warning from Phase 0.
- **P1 — Defer the physical `template/` delete to the Phase 3 cutover.** Legacy projects' migrations and session-start nudge curl those raw URLs; deleting in Phase 1 would strand them.
- **P1 — Transactional cutover.** Snapshot-first; refuse dirty tree; confirm a live `sf` plugin at version ≥ in-tree engine; abort the whole cutover on any hash-miss; re-seed the floor guard and assert `permissions.deny` before stripping; delete only manifest-listed files individually (never `rm -rf` a dir); `.savvy-old` is primary recovery; `--yes` required.
- **P1 — Full baseline coverage** (v1.0 … v1.4 and patch variants), parsed with a real TOML reader scoped to `[framework].version`; refuse the destructive path on ambiguous version.
- **P1 — Session-start version stamp** is a required Phase 2 deliverable: plugin reads its own version, writes `.claude/.savvy-engine-version`, warns on floor mismatch or double-load; drop the remote-manifest nudge.
