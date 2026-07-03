# Changelog

All notable changes to the `savvy-template` repo. This is the template's own changelog — per-project changelogs are generated inside each scaffolded project.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.5.0] — 2026-07-03

### Added
- **Zero-dependency test suite** (`tests/`): pure-bash runner (bash 3.2 compatible; needs only `git` + `jq`) with 200+ assertions covering adopt (greenfield / brownfield / detach / idempotency / guards / dry-run), eject round-trips, doctor verdicts, build determinism + generated-artifact drift, manifest integrity, and hook contracts (secret-scan block/allow, adoption gating, session hooks).
- **CI** (`.github/workflows/ci.yml`): test suite on ubuntu (bash 5) and macOS (system bash 3.2), shellcheck error gate, plugin-payload JSON/version integrity, soft version-bump reminder. Tag-triggered `release.yml` verifies tag ↔ VERSION ↔ plugin.json ↔ CHANGELOG agreement, runs the suite, checks artifact drift, and publishes the GitHub Release from the CHANGELOG section.
- **`/sf:doctor`** — read-only installation health check (`scripts/sf-doctor.sh`): plugin state, settings integrity, floor-guard wiring, engine/config version alignment, coexistence remnants, legacy-manifest and `*.savvy-new` leftovers, git protection of `.claude/`.
- **`/sf:eject`** — clean reversal of adoption (`scripts/sf-eject.sh`): disables the plugin at project scope, strips the floor wiring (or `--restore-settings` restores the pre-adopt backup), quarantines seeded files that are still byte-identical to their seeds, and **keeps every file you edited**.
- **`/sf:adopt --dry-run`** — prints the full adoption plan (seed / skip / merge / detach / enable) while changing nothing.
- Community files: `CONTRIBUTING.md`, `SECURITY.md`, issue templates, PR template.

### Fixed (safety — from the adversarial audit; all regression-tested)
- **Detach could permanently delete user files.** `sf-adopt.sh` removed in-tree engine files by name-match with no backup — destroying local edits, and user-owned files that merely shared an engine filename; a gitignored `.claude/` silently bypassed the dirty-tree guard. Detach now **quarantines** everything to `.claude/.savvy-detached-<ts>/` (never deletes), warns when `.claude/` is gitignored, and the final report no longer overclaims.
- **Re-adopt clobbered the pre-adopt `settings.json.savvy-old` backup** (keep-first now) and spuriously rewrote `settings.json` (canonical-compare no-op detection).
- **Adopt could half-apply**: invalid `settings.json` now aborts before any mutation; a symlinked `settings.json` is refused (it would have been severed); `jq` failures in the strip/enable steps abort loudly instead of being swallowed.
- **The hook-strip regex deleted user hooks** whose command path merely ended in `/format.sh` etc. — now anchored to `.claude/hooks/`.
- **Adopt left legacy upgrade markers** (`.claude/.savvy-manifest.json`) that would make the next `/sf:upgrade` re-install the entire detached in-tree engine — now quarantined; `/sf:upgrade` additionally refuses to run in plugin-mode projects.
- **`/sf:upgrade` destroyed user edits on the second run**: unresolved conflicts were re-baselined as "clean", so the next upgrade classified them refresh-safe. Conflict entries now carry an explicit marker and stay conflicts until resolved; upgrades also require a clean git tree (or write a backup dir on non-git projects).
- **`build-plugin.sh` generated the manifest before regenerating `template/`**, shipping hashes one iteration stale (the committed manifest was missing the Phase-2 adopt entries).
- **Plugin hooks acted in non-adopted projects**: `format.sh` reformatted arbitrary projects' files to prettier/black defaults, `bloat-check.sh` "BLOCKING"-flagged their docs, `session-end.sh` nagged about handovers, and `session-start.sh` stamped `.savvy-engine-version` into any repo with a `.claude/` dir (and into `~/.claude` when no project root was found). All four now gate on the `.claude/config.toml` `[framework]` marker and stop the root-walk before `$HOME`.
- **`secret-scan.sh` false positives**: the `sk-` pattern matched inside ordinary kebab-case words (`desk-organizer-…`, `risk-assessment-…`) — now boundary-anchored. SessionStart messages moved to stdout (stderr was invisible to Claude).
- **The v1.3.0 `/sf:` rename corrupted data-file references**: `spec.md`/`plan.md` became `sf:spec.md`/`sf:plan.md` in 7 engine files, silently killing spec/plan line budgets and teaching wrong paths — fixed, budgets regression-tested.
- Migrations pinned to `raw/main` URLs (would 404 after the Phase 3 cutover) now pin to immutable tags; the v1.4.0 baseline fetch maps historical version stamps to real baseline files (it could never succeed before).
- Shipped commands no longer hardcode the framework author's personal git identity into adopters' commits; `pending-changes.md` entry format unified (hooks count both legacy and current formats); `legacy-review` sweep policy inlined (no more dangling `docs/PLAN.md` references); dead `copier update` upgrade channel de-documented.
- **`/sf:adopt` (Phase 2).** One command to adopt any repo onto the `sf` plugin engine: seeds the skeleton create-if-absent, additively merges `permissions.deny`, keeps an in-tree secret-scan floor guard, **detaches** any legacy in-tree engine (removes known engine files individually + strips the 4 framework hook wirings, backing up `settings.json` to `.savvy-old`), and enables `sf@savvy` at project scope. Backed by the tested `scripts/sf-adopt.sh` (git-guarded, idempotent, create-if-absent). The plugin embeds a generated `skeleton/` (Jinja-stripped from `template/`).
- Session-start engine version stamp (plugin mode): writes `.claude/.savvy-engine-version` and warns when the installed engine is older than the project's `config.toml` floor; legacy in-tree projects keep the `/sf:upgrade` nudge.

### Changed
- **Distribution rearchitecture — Phase 1 (authorship inversion).** The engine now ships as a Claude Code plugin named `sf` whose authored source of truth is the repo-root payload (`commands/` flat → `/sf:<cmd>`, `skills/<name>/SKILL.md`, `hooks/{*.sh,hooks.json}`, `agents/`, `.claude-plugin/{plugin.json,marketplace.json}`). Installs land out-of-tree, so engine updates can never touch project files, and `/plugin update sf@savvy` is version-gated. `scripts/build-plugin.sh` is reversed: it now reverse-generates the legacy in-tree engine under `template/.claude/` from the root payload (kept for pre-plugin projects until the Phase 3 cutover) and gates on a `VERSION`/`config.toml` version mismatch.
- `plugin.json` name `savvy-framework` → `sf`; `repository` is now a string (object form fails `claude plugin validate`); `marketplace.json` authored (marketplace `savvy`, plugin source `.`).

### Fixed
- `session-start.sh` guarded against `set -o pipefail` aborting the hook when `config.toml` lacks a `version` line; added a coexistence detector that warns once when the `sf` plugin and an in-tree engine both run.
- `secret-scan.sh` private-key regex used a trailing empty alternative `(RSA |…|)` that `ugrep` rejects, so RSA private keys passed unblocked; fixed to `((RSA|EC|OPENSSH|DSA|PGP) )?`.

### Docs
- ADR `docs/decisions/0001-engine-as-plugin.md`, executed Phase 0 gate `docs/distribution/phase-0-gate.md` (GO), and red-team record. README plugin-install section corrected (no `gh:` path; real marketplace flow).

## [1.4.0] — 2026-06-12

### Added
- **Manifest-driven safe upgrades.** New `.claude/.savvy-manifest.json` records every framework file with a `sha256` and an ownership `policy` (`managed` / `merge` / `seeded`). This is the map that lets updates distinguish framework code (safe to refresh), files you locally edited (conflict — never silently overwritten), and your own work (specs/docs/context files — never touched).
- `/sf:upgrade` command + `framework-upgrade` skill — diffs the project against a newer release (explicit path → installed plugin → remote), prints an add/refresh/conflict/merge/migrations plan, and applies only on confirmation. Conflicts land as `<path>.savvy-new` beside untouched originals. Projects with no manifest (anything before v1.4.0) upgrade safely via conservative mode.
- `scripts/gen-manifest.sh` — generates the ownership manifest; Jinja-bearing files are auto-excluded from `managed` to avoid false conflicts.
- `VERSION` file as the single source of truth; `build-plugin.sh` stamps `plugin.json` and the manifest from it.
- Cached, non-blocking framework-update nudge in `session-start.sh` — points to `/sf:upgrade` when a newer version is available; silent offline.

### Changed
- `framework-linter` now reports framework-version drift and locally-modified `managed` files (check 5b).
- `release-gate` regenerates the manifest and re-stamps versions on every framework release.
- Version drift fixed: `config.toml`, `plugin.json`, and `VERSION` now all read `1.4.0` (was `1.3` / `1.1.0`).

## [1.3.0] — 2026-05-20

### Added
- `/sf:resume-handover` slash command — counterpart to `/sf:handover`: reads `HANDOVER.md`, active spec, and recent git state to bootstrap a new session. Flags stale handovers when the most recent commit is newer than the handover timestamp.
- `migrations/v1.3.0.sh` — removes orphaned flat command files in existing projects after the namespacing move. Idempotent; keeps custom top-level commands with no `sf/` twin.

### Changed
- **Namespaced all slash commands under `/sf:`.** Every command moved from `template/.claude/commands/*.md` into `template/.claude/commands/sf/*.md`. Invocation now uses the `/sf:` prefix (e.g. `/sf:spec`, `/sf:ship`, `/sf:handover`). All cross-references in skills, hooks, agents, docs, and the `/sf:commands` index updated.
- `template/.claude/config.toml` version bumped to `1.3`.

## [1.2.0] — 2026-05-19

Gap-closing pass against the Claude Code large-codebase best practices blog post. All seven priority gaps from the v1.1 assessment closed.

### Added
- `.claudeignore` at template root — excludes secrets, build artifacts, archive directories from Claude's read scope.
- `permissions.deny` block in `template/.claude/settings.json` — blast-radius guards (rm -rf on root/HOME/.git/.claude, force-push, hard reset to origin, sudo, secret-file reads).
- `SessionStart` hook (`template/.claude/hooks/session-start.sh`) — deterministic intake-input detection, framework version banner, pending-changes count, scratchpad-mode by CWD. Replaces model-driven CLAUDE.md instruction.
- MCP integration scaffold: project-scoped `.mcp.json` at template root, `_mcp-template/` reference, Notion MCP as Mode A (recommended) alongside the existing GitHub Action sync as Mode B.
- Three canonical subagents in `template/.claude/agents/`: `explorer` (read-only mapping), `code-reviewer` (independent pre-`/sf:ship` review), `parallel-runner` (isolated parallel work).
- Subdirectory `AGENTS.md` pattern doc at `template/docs/agents-subdir-pattern.md` + `framework-curator` decision-tree branch (subdir AGENTS.md applied directly, not deferred).
- Plugin distribution path: `.claude-plugin/plugin.json` manifest at framework root + `scripts/build-plugin.sh` to materialize the plugin layout from `template/.claude/`.
- `/sf:review` slash command — delegates to the `code-reviewer` subagent with diff + spec context + constitution.
- Rule-decay check in `framework-linter` — flags AGENTS.md / CLAUDE.md / constitution.md lines unchanged > 180 days as candidates for `/sf:curate` re-evaluation.

### Changed
- `template/.claude/config.toml` version bumped to `1.1`.
- `template/CLAUDE.md` no longer carries the intake-input session-start instruction (now handled deterministically by the hook).
- `project-intake` Batch 4 now proposes ADDITIONAL project-specific subagents on top of the universal three.

## [1.1.0]

### Added
- `/sf:commands` and `/sf:tutorial` slash commands.
- `migrations/` infrastructure for patching existing scaffolds.

### Fixed
- Post-scaffold message rendering.

## [1.0.1]

### Fixed
- Stop-hook envelope structure.

## [1.0.0]

### Added
- Initial v1.0 skeleton: directory structure, `copier.yml`, `docs/PLAN.md`, stubbed skills/commands/hooks/integrations, `cli/savvy.zsh` stub.
