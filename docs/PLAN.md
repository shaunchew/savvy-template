---
title: Savvy Coding Framework — Plan
version: 1.0
status: Ready to scaffold
author: Shaun Chew · The Savvy Developer
source: Notion page 36489ab2de478112ad10ec62067094f1
---

# Savvy Coding Framework — Plan

A self-owned, agent-agnostic, tool-agnostic framework for managing solo-developer projects across multiple AI coding assistants. Designed for Claude Code as the daily driver, portable to Codex and Gemini, integrable with any task system as an opt-in add-on. Driven by a single CLI command that handles project initialization end-to-end.

**Author:** Shaun Chew · The Savvy Developer
**Version:** v1.0
**Status:** Ready to scaffold

---

## 1. Purpose & Philosophy

### What this is

A standard structure, workflow, and tooling layer for AI-assisted software development that:

- Works with no external service dependency. Core runs entirely off markdown files and per-agent tooling. No Notion, RAM, Telegram, or third-party SaaS required.
- Adopts spec-driven development as methodology: constitution → spec → plan → tasks → implement. Inspired by GitHub Spec Kit, no CLI dependency.
- Ships a single `savvy` CLI that handles new-project bootstrap end-to-end: takes a project idea + LLM choice, runs Copier + intake skill, hands off to a fully scaffolded session.
- Provides Copier-based scaffolding (canonical mechanism), wrapped by `savvy` CLI (one-command UX) and `shaunchew/savvy-template-quickstart` (GitHub Template UX).
- Supports gradual migration of existing repos. New specs follow the new structure; legacy files stay untouched.
- Lets template improvements flow to existing projects via `copier update`.
- Stays agent-portable. AGENTS.md is canonical context, CLAUDE.md is a slim Claude-specific overlay.
- Ships **universal framework skills** that maintain the framework itself in every project — routing content, gating CLAUDE.md additions, watching for bloat, bootstrapping projects, evolving them.

### What this is NOT

- Not a fork or wrapper of GitHub Spec Kit. Methodology borrowed; tooling independent.
- Not coupled to Notion, Telegram, Remote AI Maestro, or any specific task system. Those are bolt-on integrations.
- Not opinionated about your stack at the constitution level — placeholders for per-project fill-in.
- Not a replacement for any Claude Code, Codex, or Gemini feature.

### Design principles

**Tool-agnostic core, opt-in integrations.** Core works without any external service. Integrations live under `.claude/integrations/<name>/` with their own enable flag.

**Agent-portable by default.** AGENTS.md is the canonical context file (recognized by Codex, Gemini, Cursor, Copilot, and increasingly Claude). CLAUDE.md is a slim overlay for Claude-specific quirks only.

**Ruthless brevity in context files.** AGENTS.md ≤60 lines, CLAUDE.md ≤15 lines. Only non-inferable content. Use hooks for deterministic enforcement.

**Specs are time-bounded, docs are ongoing.** Time-bounded work with a definition of done → `specs/`. Ongoing state → `docs/`. ADRs → `docs/decisions/`.

**Repo is canonical, everything else mirrors.** Notion, dashboards, task queues sync FROM the repo.

**Updates propagate.** Improvements to the template flow to all existing projects via `copier update`.

**The framework polices itself.** Universal skills shipped with every project actively prevent drift, bloat, and misplacement of content.

**Speculative changes apply immediately; ground-truth changes defer until sign-off.** Specs/plans/tasks/ADRs evolve freely. AGENTS.md/CLAUDE.md/constitution.md changes are batched in `.claude/pending-changes.md` and applied only at deliberate review moments via `/curate`. This separates exploratory work from canonical updates.

**One-command bootstrap.** `savvy new <name> --llm <agent> --idea "<text>"` handles the entire project initialization (Copier + intake), so a new project goes from idea to fully scaffolded in a single command + one Claude Code session.

**Active archival over silent coexistence.** When structural changes happen (initial migration onto framework, or major version updates), old files don't quietly stay alongside new — they move to `_legacy/<migration-name>/` for deliberate review. The `legacy-reviewer` skill walks each item with three options (keep archived / delete / restore to active). This makes cleanup intentional rather than indefinitely deferred.

**Scratchpads for exploration that doesn't touch the project.** Sometimes you want to explore ideas, draft documents, prototype code, or have free-form discussions about the project without those affecting ROADMAP, specs, CHANGELOG, or any main-project state. Scratchpads (`scratchpads/<name>/`) are first-class isolated workspaces inside the repo — Claude operates in a mode where framework machinery (curator, bloat-watcher, spec-bootstrap) is inert and changes don't propagate to main project files. When a scratchpad's exploration becomes ready, `/promote-scratchpad` converts findings into real specs and ADRs.

---

## 2. Decisions Locked In

| Decision | Choice | Rationale |
|---|---|---|
| Scaffolding mechanism | Copier + GitHub template wrapper + `savvy` CLI | Three entry points covering different UX preferences |
| Source of truth | Repo canonical, Notion mirrors via sync skill | Avoids dual-write conflicts |
| Migration approach | Gradual — new specs use new structure, old stays | Zero forced refactor |
| Methodology | Spec Kit patterns, no CLI dependency | Methodology > tooling |
| Canonical context file | AGENTS.md (≤60 lines) | Cross-tool standard |
| Claude-specific overlay | CLAUDE.md (≤15 lines) | Native Claude Code support |
| Constitution scope | Placeholder template, filled per project | Each project gets its own |
| Specs structure | `specs/<category>/NNN-name/` | product/marketing/ops/research |
| Task capture | Framework-agnostic; integrations as add-ons | Notion/Telegram/RAM optional |
| Notion sync (when on) | Real-time via GitHub Action, gated by config | Per-project opt-in |
| Hooks shipped | Format-on-write, secret-scan, bloat-check, Stop-checkpoint | Minimum deterministic enforcement |
| Universal skills shipped | Curator, bloat-watcher, linter, spec-bootstrap, lesson-recorder, release-gate, project-intake, project-evolve, legacy-reviewer, scratchpad-mode | Framework self-maintenance + bootstrap + cleanup + exploration |
| Slash commands shipped | `/spec`, `/plan`, `/tasks`, `/ship`, `/handover`, `/checkpoint`, `/refresh-roadmap`, `/sync-notion`, `/lint-framework`, `/lesson`, `/curate`, `/intake`, `/evolve`, `/spec-revise`, `/spec-archive`, `/stack-evolve`, `/status-sync`, `/legacy-review`, `/scratchpad`, `/scratchpad-exit`, `/scratchpad-list`, `/promote-scratchpad`, `/archive-scratchpad` | Methodology + bootstrap + ongoing updates + cleanup + exploration |
| CLI wrapper | `savvy` shell function (v1.0), Homebrew tap (v1.1+) | Solo-friendly first, share-friendly later |
| /evolve scope | Spec/plan/tasks/ADRs apply immediately; AGENTS/CLAUDE/constitution defer to pending-changes.md | Exploratory work fast, ground-truth deliberate |
| Migration archival | Old structures move to `_legacy/<migration-name>/` for review, not silent coexistence | Deliberate cleanup over indefinite drift |
| Scratchpads | First-class `scratchpads/<name>/` workspaces; framework machinery inert in scratchpad-mode | Exploration without polluting main project state |
| Template repo | `shaunchew/savvy-template` (public) | Discoverable, no IP risk |

---

## 3. Repository Structure

```
<repo>/
├── AGENTS.md                       # ≤60 lines: canonical agent context
├── CLAUDE.md                       # ≤15 lines: Claude-specific overlay
├── README.md                       # human-facing
├── ROADMAP.md                      # auto-refreshed index of active specs
├── CHANGELOG.md                    # what's been shipped
├── HANDOVER.md                     # live session bridge
├── constitution.md                 # non-negotiable principles (per-project)
├── .claude/
│   ├── settings.json               # hooks configuration
│   ├── config.toml                 # framework-level config (integrations on/off)
│   ├── lessons.md                  # session-learned lessons (curated)
│   ├── pending-changes.md          # proposed core-file edits awaiting /curate sign-off
│   ├── intake-input.md             # transient: idea text written by savvy CLI, consumed by /intake
│   ├── commands/                   # slash commands
│   │   ├── spec.md
│   │   ├── plan.md
│   │   ├── tasks.md
│   │   ├── ship.md
│   │   ├── handover.md
│   │   ├── checkpoint.md
│   │   ├── refresh-roadmap.md
│   │   ├── sync-notion.md
│   │   ├── lint-framework.md
│   │   ├── lesson.md
│   │   ├── curate.md
│   │   ├── intake.md
│   │   ├── evolve.md
│   │   ├── spec-revise.md
│   │   ├── spec-archive.md
│   │   ├── stack-evolve.md
│   │   ├── status-sync.md
│   │   ├── legacy-review.md
│   │   ├── scratchpad.md
│   │   ├── scratchpad-exit.md
│   │   ├── scratchpad-list.md
│   │   ├── promote-scratchpad.md
│   │   └── archive-scratchpad.md
│   ├── agents/                     # subagent definitions (project-specific)
│   ├── hooks/                      # hook scripts
│   │   ├── format.sh
│   │   ├── bloat-check.sh
│   │   ├── secret-scan.sh
│   │   └── session-end.sh
│   ├── skills/
│   │   ├── _framework/             # universal skills (DO NOT DELETE)
│   │   │   ├── framework-curator/
│   │   │   ├── bloat-watcher/
│   │   │   ├── framework-linter/
│   │   │   ├── spec-bootstrap/
│   │   │   ├── lesson-recorder/
│   │   │   ├── release-gate/
│   │   │   ├── project-intake/
│   │   │   ├── project-evolve/
│   │   │   ├── legacy-reviewer/
│   │   │   └── scratchpad-mode/
│   │   └── (project-specific skills go here)
│   └── integrations/               # opt-in add-ons (all disabled by default)
│       ├── notion/
│       │   ├── README.md
│       │   ├── config.toml         # enabled = false by default
│       │   └── skill/SKILL.md
│       ├── telegram/
│       │   ├── README.md
│       │   ├── config.toml
│       │   └── bot/                # standalone bot source
│       └── ram/
│           ├── README.md
│           └── config.toml
├── specs/
│   ├── product/
│   │   └── NNN-feature-name/
│   │       ├── spec.md
│   │       ├── plan.md
│   │       ├── tasks.md
│   │       ├── design.md           # optional, only if visual work
│   │       └── checklist.md
│   ├── marketing/
│   ├── ops/
│   ├── research/
│   └── _archive/                   # superseded specs
├── docs/
│   ├── decisions/                  # ADRs: NNN-decision-name.md
│   ├── ops/                        # current operational state
│   ├── analytics/                  # query library, dashboard configs
│   ├── runbooks/                   # incident response
│   ├── investor-updates/           # YYYY-MM.md
│   └── research/                   # living reference
├── _legacy/                        # archived structures from migrations
│   ├── initial-migration-YYYY-MM-DD/    # first-time onto framework
│   │   ├── MIGRATION_NOTES.md
│   │   ├── REVIEW-LOG.md
│   │   └── {original files/folders moved here}
│   ├── v1-to-v2-YYYY-MM-DD/             # major version migrations
│   └── _archive/                        # fully-reviewed, kept-for-record
├── scratchpads/                    # isolated exploration workspaces
│   ├── README.md
│   ├── NNN-short-name/                  # individual scratchpad
│   │   ├── SCRATCHPAD.md                # lightweight context for this scratchpad
│   │   ├── notes.md                     # free-form
│   │   ├── findings.md                  # what was learned
│   │   ├── generated/                   # any Claude-generated files
│   │   └── REVIEW.md                    # written at /promote time
│   └── _archive/                        # archived scratchpads
├── .github/
│   └── workflows/                  # CI + integration workflows (conditional on config)
└── <your actual code>
```

For other agents, parallel structures:

```
.codex/                              # Codex-specific tooling
.gemini/                             # Gemini-specific tooling
```

Both read from the same `AGENTS.md` and `specs/`.

---

## 4. Core Files (Templates)

### 4.1 AGENTS.md

Canonical agent context. ≤60 lines. Content must be **non-inferable** from code, README, lint configs, or tests.

```markdown
# Project: {{project_name}}

## Stack
- {fill: backend language + framework}
- {fill: frontend if applicable}
- {fill: database}
- {fill: deploy target}
- {fill: notable non-obvious dependencies}

## Commands
- Setup: `{fill}`
- Run dev: `{fill}`
- Test: `{fill}`
- Deploy: `{fill}`

## Conventions (non-obvious)
- {fill: 2-4 conventions linters don't enforce}

## Negative rules
- Never {fill}
- Never {fill}

## On-demand context
- Detailed architecture: `docs/`
- Active feature work: `specs/`
- Decisions and rationale: `docs/decisions/`
- Constitution (invariants): `constitution.md`
```

### 4.2 CLAUDE.md

Claude-specific overlay. ≤15 lines.

```markdown
# Claude-specific

This project follows the Savvy Coding Framework. Universal project context is in `AGENTS.md` — read it first.

## Claude Code behaviors
- IMPORTANT: When proposing to add content to CLAUDE.md, AGENTS.md, or constitution.md, use the `framework-curator` skill to validate placement. Such changes are deferred to `.claude/pending-changes.md` during `/evolve` and applied only via `/curate` sign-off.
- When compacting, preserve: active spec, current file list, test status.
- Prefer plan mode for any task touching >3 files.
- Use the `release-gate` skill before merging to main.
- On session start, check for `.claude/intake-input.md`. If present, run `/intake --from-file .claude/intake-input.md`.
```

### 4.3 constitution.md

Filled per project. No pre-population — explicit, deliberate authoring.

```markdown
# Constitution — {{project_name}}

Non-negotiable principles for this project. Changes require deliberate review. Edits are gated by the `framework-curator` skill and deferred via `.claude/pending-changes.md`.

## Architecture invariants
- {fill}

## Quality gates
- {fill}

## Security posture
- {fill}

## Non-negotiable conventions
- {fill}
```

### 4.4 ROADMAP.md

Auto-refreshed index. ≤100 lines.

```markdown
# Roadmap

Last refreshed: {{auto}}

## Active

### Product
- [product/001-google-oauth](specs/product/001-google-oauth/) — In progress · Sign-in flow with Google
- [product/002-ssm-relay](specs/product/002-ssm-relay/) — Planning · SSM connection layer

### Marketing
- [marketing/001-launch-blog](specs/marketing/001-launch-blog/) — Drafting · Launch announcement

### Ops
- [ops/001-cost-alerts](specs/ops/001-cost-alerts/) — Implementing · Cloudwatch budget alerts

## Recently shipped
See `CHANGELOG.md`.
```

### 4.5 CHANGELOG.md

```markdown
# Changelog

## [Unreleased]

## [0.3.0] — 2026-05-12
### Added
- product/001-google-oauth: Google SSO with role-based access

### Changed
- ops/001-cost-alerts: Migrated to Cloudwatch

### Fixed
- (none)
```

### 4.6 HANDOVER.md

Auto-updated by `/handover` and Stop hook.

```markdown
# Handover

Last updated: {{auto}}

## Goal
{What we're working toward right now}

## Current state
{Branch, last commit, test status}

## Files in flight
- {path}: {what's being changed}

## What's been tried that didn't work
- {attempt}: {why it failed}

## Next step
{One concrete action}

## Pending changes awaiting /curate
- {count} entries in .claude/pending-changes.md
```

### 4.7 Spec templates

Each `specs/<category>/NNN-feature/` contains:

**spec.md** — What and why.
**plan.md** — Technical approach.
**tasks.md** — Snapshot at planning.
**checklist.md** — Acceptance gate.

(Templates as in v1.0 — see appendix or template repo.)

### 4.8 .claude/pending-changes.md

```markdown
# Pending Changes — Awaiting Sign-off

Changes to core files (AGENTS.md, CLAUDE.md, constitution.md) and integration configs proposed by /evolve invocations but not yet applied. Review and approve via `/curate` when work is complete (typically after `/ship`).

## YYYY-MM-DD HH:MM · <target-file> · <field>
<proposed change>
Source: /evolve "<change description>" → <spec ref if applicable>

(entries appended chronologically)
```

---

## 5. Universal Framework Skills

Every project scaffolded from the template ships with these eight skills under `.claude/skills/_framework/`. They maintain the framework itself — preventing drift, bloat, and misplacement, and powering the bootstrap and evolution workflows.

### 5.1 framework-curator

Gatekeeper for edits to AGENTS.md, CLAUDE.md, and constitution.md. Validates proposed additions against framework rules, routes to correct file if wrong target, requires explicit user approval. (Detailed in §5.10 — placement decision tree.)

### 5.2 bloat-watcher

Monitors line counts. PostToolUse hook triggers on edits to context files; returns warnings to Claude when files approach or exceed budgets, with specific lines flagged as extraction candidates.

### 5.3 framework-linter

On-demand validation via `/lint-framework`. Identifies drift, missing files, malformed specs, rule violations, template version drift, stale `_legacy/` migration folders (older than 90 days without full review), and stale scratchpads (active scratchpads older than 60 days that haven't been promoted or archived).

### 5.4 spec-bootstrap

Triggered by `/spec <category>/<name>`. Auto-numbers within category, creates folder + 4 files from templates, pre-fills frontmatter, updates ROADMAP.md.

### 5.5 lesson-recorder

Captures lessons during sessions via `/lesson "<text>"` or via Stop hook prompt. Appends to `.claude/lessons.md` with tags (placement, gotcha, pattern, mistake-avoided).

### 5.6 release-gate

Triggered by `/ship <category>/<NNN>`. Walks through `checklist.md` item by item, on all-pass updates CHANGELOG, moves spec status to shipped, tags release, triggers Notion sync if enabled.

### 5.7 project-intake (new in v1.0)

**Purpose:** One-shot project bootstrap from a description. Takes any size product idea, decomposes it, drafts all framework artifacts, presents in approval batches, executes.

**Triggered when:**
- User runs `/intake "<idea>"` (inline)
- User runs `/intake --from-file <path>` (file-based, what the `savvy` CLI uses)
- Session starts and `.claude/intake-input.md` exists (auto-detected per CLAUDE.md instruction)

**Behavior:**

1. **Analyze** the description:
   - Identify project type (data-science vs software-dev vs hybrid)
   - Extract stack hints
   - Identify components/teams/modules
   - Identify domain constraints (regulated industry, financial, healthcare, etc.)
2. **Draft proposals** in five batches:
   - **Batch 1 — Core files:** AGENTS.md content, CLAUDE.md overlay, constitution.md invariants, and any special root docs (e.g., `docs/investment-policy.md` for trading projects). All routed through framework-curator for validation.
   - **Batch 2 — Specs:** Decomposes the description into specs across categories (product/marketing/ops/research). Proposes count, names, and category mapping.
   - **Batch 3 — ADRs:** Identifies architecture decisions worth recording upfront. Creates placeholders in `docs/decisions/` (you fill content when you make each decision).
   - **Batch 4 — Subagents:** Proposes specialized agents that would help. Creates definitions in `.claude/agents/`.
   - **Batch 5 — Integrations:** Recommends which integrations to enable based on the description (e.g., "Trade desk → Telegram", "portfolio mirroring → Notion"). Prompts for credentials.
3. **Approval gates** between batches. User can `y` (approve all), `select` (cherry-pick), or `modify` (revise proposal).
4. **Execute** approved changes. One commit per batch for clean git history.
5. **Hand off:** Print summary, suggest `/lint-framework` to verify, suggest `/plan <first-spec>` to start work.

**Example invocation (full trace in §11):**

```
You: /intake --from-file .claude/intake-input.md

Claude: [reads file, analyzes]
        Project: stocks-trading-agents (software-dev variant, financial domain)

        BATCH 1 — Core files
        ...
        Approve? [y/edit/skip]

You: y
Claude: [writes, commits "intake: core files"]

        BATCH 2 — 14 specs proposed
        ...
```

### 5.8 project-evolve (new in v1.0)

**Purpose:** Drive ongoing changes to the project. Smart router that figures out what kind of change is happening (net-new feature, scope cut, stack pivot, status update) and routes to the right action. Critically, applies speculative changes immediately but defers ground-truth changes to `.claude/pending-changes.md`.

**Triggered when:** User runs `/evolve "<change description>"`

**Behavior:**

1. **Analyze** the change against current project state (reads AGENTS.md, constitution.md, ROADMAP.md, lessons.md):
   - Net-new feature → propose new spec(s)
   - Scope removal → propose archive
   - Stack change → propose AGENTS.md edits + ADR
   - Refinement to existing spec → revise that spec
   - Status sync → check git/PR state, update spec statuses
2. **Apply immediately (no gating beyond bloat-watcher):**
   - New specs (folder + 4 files)
   - Updates to spec.md / plan.md / tasks.md / checklist.md within specs
   - ROADMAP.md updates
   - ADR drafts in `docs/decisions/` (placeholders)
   - New subagents in `.claude/agents/`
3. **Defer to `.claude/pending-changes.md`:**
   - AGENTS.md additions (commands, stack, conventions, negative rules)
   - CLAUDE.md additions
   - constitution.md additions
   - Integration config flips

   Each pending entry has timestamp, target file, proposed content, source (which /evolve invocation), and which spec it relates to.
4. **Report at the end:**

   ```
   Applied immediately:
   - New spec: product/012-copy-trading (4 files)
   - Updated: product/009-trade-desk/plan.md (proxy mode notes)
   - Updated: product/011-position-broadcaster/plan.md (copy-follower channels)
   - New ADR placeholder: docs/decisions/006-copy-trading-data-model.md
   - ROADMAP.md refreshed

   Deferred to .claude/pending-changes.md (2 entries):
   - constitution.md addition (risk multiplier)
   - AGENTS.md command addition (copy-trade simulation)

   Run /curate when work is shipped to apply deferred changes.
   ```

**Specific shortcut commands** (for when you know exactly what you want):

- `/spec-revise <ref> "<change>"` — modify an existing spec's spec.md/plan.md/tasks.md
- `/spec-archive <ref> "<reason>"` — move to specs/_archive/, update ROADMAP, log to CHANGELOG
- `/stack-evolve "<change>"` — explicit AGENTS.md stack section update (deferred to pending) + ADR creation (immediate)
- `/status-sync` — scan git branches matching `<category>/<NNN>-*` patterns, check PR statuses, update spec status frontmatter in spec.md, refresh ROADMAP

These shortcuts skip the analysis step and go straight to the action. Useful for power use; `/evolve` is the default for natural use.

### 5.9 legacy-reviewer (new in v1.0)

**Purpose:** Walks the user through `_legacy/` migration folders one item at a time, capturing decisions about what to keep, delete, or restore. Makes cleanup intentional rather than indefinitely deferred.

**Triggered when:**
- User runs `/legacy-review` (manual review session)
- User runs `/legacy-review <migration-folder>` (review specific migration)
- framework-linter detects a `_legacy/<migration>/` folder older than 90 days without complete review (surfaces a warning suggesting `/legacy-review`)

**Behavior:**

1. **Discovery.** Lists all migration folders under `_legacy/` with status: untouched, partially-reviewed, fully-reviewed.
2. **Per-folder walkthrough.** For each migration folder, reads `MIGRATION_NOTES.md` to understand what was moved and from where. Reads `REVIEW-LOG.md` to skip already-decided items. Then walks unreviewed items.
3. **Per-item decision.** For each file or folder, presents three options:
   - **Keep archived** (do nothing, mark as reviewed-and-kept)
   - **Delete now** (move to git-deleted state)
   - **Restore to active location** (move back; if it's a context file like AGENTS.md or CLAUDE.md, route through framework-curator first)
4. **Logging.** Each decision appends to `_legacy/<migration>/REVIEW-LOG.md` with timestamp, item, action, optional note.
5. **Folder finalization.** When all items in a migration folder are reviewed (kept or deleted), prompts: "Move folder to `_legacy/_archive/` (kept for record) or remove entirely?"

**`_legacy/<migration>/MIGRATION_NOTES.md` format** (auto-generated by migration scripts):

```markdown
# Migration: v1-to-v2 · 2026-08-15

Triggered by: copier update v1.5.3 → v2.0.0
Migration script: .savvy/migrations/v2.0.0/run.sh

## What moved
- `plans/` → renamed to `specs/product/`
- `master_plan.md` → split into `ROADMAP.md` + `CHANGELOG.md`
- Old `tasks/` directory → flattened into respective spec tasks.md files

## What was removed (already in legacy/)
- {list of files now in this _legacy folder}

## What was created fresh
- {list of new files added by v2.0 that didn't exist in v1}
```

**`_legacy/<migration>/REVIEW-LOG.md` format:**

```markdown
# Review Log — v1-to-v2 · 2026-08-15

## 2026-08-22
- `plans/2025-12-roadmap.md` → DELETED (superseded by ROADMAP.md)
- `master_plan.md` → KEPT-ARCHIVED (historical reference)
- `tasks/auth-rebuild.md` → RESTORED to specs/product/004-auth-rebuild/tasks.md

## 2026-09-15
- `tasks/old-misc.md` → DELETED
- Folder marked fully-reviewed. Moving to _legacy/_archive/.
```

**Migration script integration.** When `copier update` runs across a major version boundary, the migration script (declared in `copier.yml _migrations`) creates `_legacy/<from-version>-to-<to-version>-<date>/`, copies the old structure into it, then performs the new structure transforms in the working copy. User finishes update with both new structure (active) and `_legacy/` (frozen archive). `/legacy-review` becomes the cleanup workflow.

### 5.10 scratchpad-mode (new in v1.0)

**Purpose:** Provides isolated exploration workspaces inside a project. Lets the user have free-form conversations, draft documents, prototype code, and generate files without those changes touching ROADMAP, specs, CHANGELOG, or any main-project state. When the exploration becomes ready, `/promote-scratchpad` converts findings into real specs and ADRs.

**Triggered when:**
- User runs `/scratchpad <name>` (creates if doesn't exist, enters if it does)
- Implicitly active whenever the working scope is inside `scratchpads/<name>/`

**Behavior in scratchpad mode:**

1. **Scoping.** Claude operates exclusively within `scratchpads/<this-one>/`. Main project files (AGENTS.md, specs, docs, code) are read-only reference — Claude can look at them but won't modify them.
2. **Framework machinery disabled.**
   - framework-curator: inert (scratchpad files can be freely edited; no placement validation)
   - bloat-watcher: inert (scratchpads can be any length)
   - spec-bootstrap: refuses (specs are main-project state)
   - project-evolve: refuses (would write to main project)
   - ROADMAP.md, CHANGELOG.md, HANDOVER.md: not updated
3. **Generated files** go in `scratchpads/<this-one>/generated/`. Any drafts, prototypes, research outputs, sketches.
4. **Persistence.** All scratchpad content is committed to git by default. User can `.gitignore` specific scratchpads for private explorations.
5. **What's still active:** `/lesson` works (lessons are universal). `/handover` updates HANDOVER.md noting "currently in scratchpad X". `/lint-framework` works but only flags scratchpad-specific issues (staleness).

**Exit:** `/scratchpad-exit` returns Claude to normal project mode. The scratchpad's state is preserved for future return.

**`scratchpads/<name>/SCRATCHPAD.md` format** (lightweight, ≤30 lines):

```markdown
# Scratchpad: <name>

**Status:** active | promoted | archived
**Created:** YYYY-MM-DD
**Context:** What this is exploring

## Topic
{One-paragraph description of what you're exploring}

## Open questions
- {question}
- {question}

## What this could become
{Optional: speculation about whether this might become a spec, ADR, or just stay archived}
```

**Promotion via `/promote-scratchpad <name>`:**

1. Claude reads `SCRATCHPAD.md`, `notes.md`, `findings.md`, and any generated files
2. Proposes what becomes what — same five-batch flow as `/intake` but scoped to scratchpad content:
   - New specs (if exploration suggests time-bounded work)
   - New ADRs (if architectural decisions were made)
   - New docs entries (if reference material was produced)
   - Updates to existing specs (if scratchpad refined an in-flight spec)
3. User approves per batch
4. Promoted content goes through normal framework gates (framework-curator validates AGENTS.md/CLAUDE.md/constitution.md proposals, etc.)
5. `REVIEW.md` is written into the scratchpad documenting what got promoted
6. Scratchpad moves to `scratchpads/_archive/<name>/` (or stays in place if user prefers)

**Archive via `/archive-scratchpad <name> "<reason>"`:** Moves scratchpad to `scratchpads/_archive/<name>/` without promoting. Used when exploration ended in "nope, not worth pursuing" but the work record is worth keeping.

**`/scratchpad-list` output:**

```
Active scratchpads (3):
  001-explore-tiktok-api          · 5 days old · 2 generated files
  003-revenue-share-models        · 12 days old · 0 generated files
  004-llm-fallback-architecture   · 38 days old · 6 generated files  ⚠ approaching staleness

Promoted (recently, 2):
  002-payment-provider-research   · promoted 8 days ago → specs/product/004, docs/decisions/008

Archived (5):
  ... (suppressed; use --all to show)
```

**Honest caveat on conversational isolation.** True session-level isolation requires either starting a fresh Claude Code session or relying on in-session discipline. v1.0 uses the latter: scratchpad-mode tells Claude to behave as if isolated, and the file-system separation reinforces it. Worst case in a long session is that Claude knows what you explored — it just won't write to main project files. Real session-fork capability is deferred to v1.1 or later if/when Claude Code supports it.

### 5.11 Placement decision tree (used by framework-curator)

When Claude or the user proposes adding content somewhere, the curator walks this tree:

```
Is the content...
  → Enforceable by a linter or formatter?            → Don't document. Let the tool enforce.
  → Inferable from package.json/code/README/tests?   → Don't document. Redundant.
  → A stack/command/quirk Claude wouldn't guess?     → AGENTS.md (deferred to pending if via /evolve)
  → Claude-specific behavior (compaction, etc.)?     → CLAUDE.md (deferred to pending if via /evolve)
  → A project-wide invariant or non-negotiable?      → constitution.md (deferred to pending if via /evolve)
  → Something that must happen every time?           → Hook in .claude/settings.json
  → A specialized workflow used sometimes?           → New skill in .claude/skills/
  → Specific to one feature?                         → That feature's spec/plan/tasks
  → Current operational state (config, status)?     → docs/ops/
  → A historical decision?                           → docs/decisions/ as ADR
  → Speculative/exploratory thinking?                → scratchpads/<name>/ (no curator gating)
  → A reusable pattern across projects?              → Promote to ~/.claude/skills/ globally
  → Anything else?                                   → Probably doesn't need to exist
```

---

## 6. Workflow — Day to Day

### Starting a new project (one command)

```bash
# Terminal — 30 seconds + 15-20 min Claude session
$ savvy new stocks-trading-agents --llm claude --idea "$(cat idea.md)"
# (savvy CLI runs copier, writes intake-input.md, launches claude)

# Claude Code auto-detects intake-input.md, runs /intake
# You approve 5 batches in ~15 min
# Done. ~120 files, all configured.
```

### Adding new work to existing project

```
You: /evolve "Add copy trading feature where users mirror top traders"

Claude: [project-evolve analyzes]
        Applied: new spec product/012, updates to 009 and 011, ADR placeholder
        Deferred: 2 changes to constitution.md and AGENTS.md

You: /plan product/012  # start working on the spec
```

### Doing the work

Standard `/plan`, `/tasks`, code, test. HANDOVER.md updates via Stop hook.

### Shipping

```
You: /ship product/012
Claude: [release-gate walks checklist]
        Spec shipped. CHANGELOG updated.
        Reminder: 2 pending changes from this work — run /curate.

You: /curate
Claude: [walks pending-changes.md entries, framework-curator validates each]
        2 changes reviewed, both approved, applied to constitution.md and AGENTS.md.
```

### Session continuity

Stop hook on session end:
1. Runs `/checkpoint` — proposes CLAUDE.md updates (deferred to pending-changes.md)
2. Runs `/handover` — updates HANDOVER.md
3. Reports pending-changes count
4. Optionally prompts for `/lesson`

### Exploration via scratchpads

```
You: /scratchpad explore-tiktok-api

Claude: [scratchpad-mode skill activates]
        Created scratchpads/001-explore-tiktok-api/
        Initialized SCRATCHPAD.md, notes.md, findings.md, generated/

        You're in scratchpad mode. Framework machinery is inert here.
        Anything you write or generate stays in this folder until you
        /promote-scratchpad or /archive-scratchpad.

        What are you exploring?

You: I want to understand the TikTok API options for video URL extraction.
     Compare official API, yt-dlp, and a third-party scraping service.

Claude: [writes notes.md with research approach]
        [as conversation progresses, fills findings.md, prototypes code
         into generated/]

# ... (free-form exploration, multiple sessions over days) ...

You: /scratchpad-exit

# Later, when ready to promote:

You: /promote-scratchpad explore-tiktok-api

Claude: [reads scratchpad contents, proposes]
        Findings suggest yt-dlp is the right choice. Proposing:

        New spec: product/007-tiktok-extraction (4 files)
        New ADR: docs/decisions/006-tiktok-extraction-approach (filled
                 in from findings.md)
        Generated prototype code: copy to specs/product/007/generated/
                                   for reference

        Approve all? [y/select/modify]

You: y

Claude: [executes promotion]
        Scratchpad archived to scratchpads/_archive/001-explore-tiktok-api/
        REVIEW.md written documenting what was promoted.
```

Scratchpads bridge the gap between "I have an idea" and "this is real work the project should track." They're freely creatable, freely abandonable, and have a clean promotion path when they pan out.

---

## 7. Slash Commands Reference

| Command | Purpose | Triggers |
|---|---|---|
| `/intake "<idea>"` or `/intake --from-file <path>` | Bootstrap entire project from a description | project-intake skill |
| `/evolve "<change>"` | Smart router for ongoing changes | project-evolve skill |
| `/spec <category>/<name>` | Bootstrap a single new spec | spec-bootstrap skill |
| `/plan` | Draft plan.md for current spec | Claude reads spec.md + constitution |
| `/tasks` | Break plan into tasks | Claude generates tasks.md |
| `/ship <category>/<NNN>` | Run release-gate to ship a spec | release-gate skill |
| `/handover` | Refresh HANDOVER.md | Reads git state + active spec |
| `/checkpoint` | Propose CLAUDE.md edits (deferred), update CHANGELOG | framework-curator skill |
| `/curate` | Walk pending-changes.md entries, apply or reject | framework-curator skill |
| `/refresh-roadmap` | Auto-regenerate ROADMAP.md | Scans specs/, writes index |
| `/sync-notion` | Manual Notion sync trigger | Only works if integration enabled |
| `/lint-framework` | Validate framework state | framework-linter skill |
| `/lesson "<text>"` | Record a lesson | lesson-recorder skill |
| `/spec-revise <ref> "<change>"` | Edit an existing spec | project-evolve subroutine |
| `/spec-archive <ref> "<reason>"` | Archive/cancel a spec | project-evolve subroutine |
| `/stack-evolve "<change>"` | AGENTS.md stack update + ADR | project-evolve subroutine |
| `/status-sync` | Sync spec statuses from git/PR state | project-evolve subroutine |
| `/legacy-review [migration-folder]` | Walk `_legacy/` items, decide keep/delete/restore | legacy-reviewer skill |
| `/scratchpad <name>` | Enter or create an isolated exploration workspace | scratchpad-mode skill |
| `/scratchpad-exit` | Return from scratchpad to main project mode | scratchpad-mode skill |
| `/scratchpad-list` | Show all scratchpads with status | scratchpad-mode skill |
| `/promote-scratchpad <name>` | Convert scratchpad findings to specs/ADRs | scratchpad-mode + /evolve |
| `/archive-scratchpad <name> "<reason>"` | Archive scratchpad without promoting | scratchpad-mode skill |

---

## 8. Hooks Reference

`.claude/settings.json`:

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          { "type": "command", "command": ".claude/hooks/format.sh" },
          { "type": "command", "command": ".claude/hooks/bloat-check.sh" }
        ]
      }
    ],
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          { "type": "command", "command": ".claude/hooks/secret-scan.sh" }
        ]
      }
    ],
    "Stop": [
      { "type": "command", "command": ".claude/hooks/session-end.sh" }
    ]
  }
}
```

**format.sh** — Runs Prettier/Black on edited files.
**bloat-check.sh** — Runs bloat-watcher against AGENTS.md, CLAUDE.md, constitution.md.
**secret-scan.sh** — Scans for common secret patterns before commit/push.
**session-end.sh** — Invokes `/handover`, surfaces pending-changes count, optionally prompts for `/lesson`.

---

## 9. Add-On Integrations

All integrations live under `.claude/integrations/<name>/` and ship disabled. Each has a `config.toml`:

```toml
[integration]
enabled = false

[integration.notion]
database_id = ""
sync_mode = "realtime"
```

When `enabled = true`, the integration's hooks/skills/workflows activate.

### 9.1 notion (sync skill)

On spec creation: pushes tasks.md as Notion DB rows. On commit (real-time): syncs changes via GitHub Action. On `/ship`: marks Notion rows complete. Manual: `/sync-notion`.

### 9.2 telegram (capture forwarder)

Bot accepts text + images on mobile, fires to your sandbox via webhook. Standalone deployment. Tasks captured via Telegram can auto-tag a spec via `/spec product/003` syntax.

### 9.3 ram (Remote AI Maestro capture)

RAM frontend exposes capture surface for this repo. Tasks tagged with repo, routed to correct sandbox. Same mark-complete loop as Notion.

### 9.4 Future integrations

Pattern extends to any task system. Candidates: Linear, Jira, GitHub Projects, Asana, Trello.

---

## 10. Template Repository — Implementation

### 10.1 Repo: `shaunchew/savvy-template`

Public GitHub repo containing the template structure plus Copier configuration.

### 10.2 copier.yml

```yaml
_min_copier_version: "9.0"

project_name:
  type: str
  help: Project name (kebab-case)

project_description:
  type: str
  help: One-line description

variant:
  type: str
  help: Project type
  choices: [software-dev, data-science]
  default: software-dev

llm:
  type: str
  help: Primary AI coding agent (scaffolds the corresponding tooling directory)
  choices: [claude, codex, gemini]
  default: claude

github_username:
  type: str
  default: shaunchew

include_notion_integration:
  type: bool
  default: false

include_telegram_integration:
  type: bool
  default: false

include_ram_integration:
  type: bool
  default: false

_tasks:
  - "git init"
  - "git add ."
  - "git commit -m 'Initial scaffold from savvy-template'"
  - "{% if variant == 'data-science' %}pip install -e . --break-system-packages{% endif %}"
  - "echo 'Template ready. Run \"savvy intake\" or open Claude Code to begin.'"
```

The `llm` variable controls which `.<agent>/` directory is generated. v1.0 supports Claude fully; Codex and Gemini scaffold the directory structure but the framework skills are Claude-format (porting deferred).

### 10.3 GitHub Template wrapper

`shaunchew/savvy-template-quickstart` is marked as GitHub Template. Contains a setup script wrapping Copier for one-click UX from GitHub web.

### 10.4 Updating existing projects

```bash
cd <project>
copier update                # interactive
# review changes, accept/reject per file
git add . && git commit -m "framework: update to v1.1.0"
```

---

## 11. The `savvy` CLI

### 11.1 What it does

Single command that handles project initialization end-to-end:

```bash
savvy new <name> --llm <agent> --idea "<text>" [--idea-from-file <path>] [--variant <type>]
```

1. Runs `copier copy gh:shaunchew/savvy-template <name>` with provided defaults
2. Writes the idea text to `<name>/.claude/intake-input.md`
3. cd's into `<name>/`
4. Launches the LLM CLI (`claude`, `codex`, or `gemini`)
5. The LLM auto-detects `.claude/intake-input.md` (via CLAUDE.md instruction) and runs `/intake --from-file`

End result: from one terminal command to fully scaffolded project in ~15-20 minutes.

### 11.2 Implementation

v1.0: shell function in `~/.zshrc`:

```bash
savvy() {
  case "$1" in
    new)
      shift
      local name="$1"; shift
      local llm="claude"
      local idea=""
      local idea_file=""
      local variant="software-dev"

      while [[ $# -gt 0 ]]; do
        case "$1" in
          --llm) llm="$2"; shift 2 ;;
          --idea) idea="$2"; shift 2 ;;
          --idea-from-file) idea_file="$2"; shift 2 ;;
          --variant) variant="$2"; shift 2 ;;
          *) echo "Unknown option: $1"; return 1 ;;
        esac
      done

      # Run copier
      uvx copier copy gh:shaunchew/savvy-template "$name" \
        --data project_name="$name" \
        --data variant="$variant" \
        --data llm="$llm" \
        --defaults

      # Write idea to intake-input.md
      cd "$name" || return 1
      mkdir -p .claude
      if [[ -n "$idea_file" ]]; then
        cp "$idea_file" .claude/intake-input.md
      elif [[ -n "$idea" ]]; then
        echo "$idea" > .claude/intake-input.md
      fi

      # Launch the chosen LLM
      case "$llm" in
        claude) claude ;;
        codex) codex ;;
        gemini) gemini ;;
        *) echo "Unsupported LLM: $llm"; return 1 ;;
      esac
      ;;

    *)
      echo "Usage: savvy new <name> [--llm claude|codex|gemini] [--idea \"<text>\"|--idea-from-file <path>] [--variant software-dev|data-science]"
      return 1
      ;;
  esac
}
```

v1.1+: Graduate to a Homebrew tap (`brew install shaunchew/tap/savvy`) with a proper Go or Python implementation for cross-machine portability.

### 11.3 Known limitations (v1.0)

- Codex and Gemini scaffold the `.codex/` or `.gemini/` directories but the universal framework skills inside are Claude-format. Auto-detection of intake-input.md works via the agent's equivalent of CLAUDE.md (AGENTS.md is the cross-tool fallback). Full skill port to Codex/Gemini is ~4 hours each, deferred to as-needed basis.
- The LLM CLI must be installed and authenticated; the wrapper does a presence check and fails with a helpful message.
- File-based idea input only — multi-paragraph briefs paste fine as `-idea "$(cat brief.md)"` but `-idea-from-file` is cleaner.

---

## 12. Migration Playbook — Existing Repos

Two variants. Both supported; pick per repo based on your appetite.

**Variant A — Passive coexistence (low-touch).** Old files stay in their original locations alongside new structure. Naturally retired over time.

**Variant B — Active archival (deliberate).** Files you choose move to `_legacy/initial-migration-<date>/` for review via `/legacy-review`. Clean separation between old and new from day one.

Choose A when the existing repo is messy but you don't want to deal with it yet. Choose B when you want a clean slate and are willing to spend an hour reviewing.

### 12.1 Variant A — Passive coexistence

Strategy: new specs use new structure, old files stay. Zero forced refactor.

**Step 1: Add the framework**

```bash
cd <existing-repo>
uvx copier copy gh:shaunchew/savvy-template . --answers-file <existing-answers>
```

Copier adds the new structure alongside existing files. Old files untouched.

**Step 2: Author core files**

Use framework-curator to author AGENTS.md, CLAUDE.md, constitution.md. ~30-60 min per repo for first pass.

**Step 3: Migrate active work to new spec structure**

For in-flight work, create new specs via `/spec <category>/<name>` or `/evolve "<description>"`. Old PLAN.md, TASKS.md, ad-hoc docs stay in place.

**Step 4: Let old structure age out**

Old files stay until naturally retired. No mass migration required.

**Step 5: Optional cleanup later**

When a repo has fully transitioned, prune old files. No deadline.

### 12.2 Variant B — Active archival via `_legacy/`

Strategy: deliberate triage at framework adoption time. Old structure gets moved to `_legacy/initial-migration-<date>/` for `/legacy-review` to walk through.

**Step 1: Add the framework + run initial archive**

```bash
cd <existing-repo>
uvx copier copy gh:shaunchew/savvy-template . --answers-file <existing-answers>

# Inside Claude Code:
> /legacy-review --initial-migration
```

The `--initial-migration` flag is special: it scans the repo for files that don't fit the new structure (existing PLAN.md, TASKS.md, ad-hoc folders) and *proposes* which to archive. You approve per item:

- "Move `plan.md` → `_legacy/initial-migration-2026-05-20/plan.md`?" → [y/n/skip]
- "Move `tasks/` → `_legacy/initial-migration-2026-05-20/tasks/`?" → [y/n/skip]

Approved items move to `_legacy/`. `MIGRATION_NOTES.md` is generated automatically.

**Step 2: Author core files**

Same as Variant A.

**Step 3: Migrate active work**

For in-flight work, create new specs. If the work has notes/plans in `_legacy/`, the spec.md "Background" section can reference them.

**Step 4: Review the legacy folder**

Run `/legacy-review` periodically (or when prompted by framework-linter staleness warning). Walk each item: keep archived, delete now, or restore to active location.

**Step 5: Finalize**

When all items in `_legacy/initial-migration-<date>/` have been reviewed and either deleted or kept-archived, the folder either moves to `_legacy/_archive/` or is removed entirely.

### First pilot: Remote AI Maestro

Natural pilot. Most active project, cleanest Notion-side structure. **Use Variant B for the pilot** — gives you the most learning about how the legacy-reviewer skill performs in practice. After pilot succeeds (1-2 weeks of dogfooding), propagate to The Collections, Grimoire, others — pick A or B per project.

---

## 13. Multi-Agent Portability — Codex, Gemini, Others

### 13.1 At init

`savvy new <name> --llm <agent>` scaffolds the appropriate `.<agent>/` directory. AGENTS.md (universal) is generated identically regardless of agent.

### 13.2 Adding a second agent later

`savvy add-llm <agent>` (planned for v1.1) — scaffolds the parallel `.<agent>/` directory in an existing repo without touching `.claude/`.

### 13.3 Framework skill port cost

The 8 universal framework skills are written for Claude Code skill format. Porting to Codex's skills mode is ~4 hours focused work. Gemini similar. Defer until you actually adopt a second agent.

### 13.4 What stays Claude-specific

- `.claude/` directory (skills, commands, hooks)
- CLAUDE.md (Claude-specific overlay)
- Anthropic-specific features (plan mode, extended thinking)

These don't translate. Don't try to abstract them.

---

## 14. Propagation & Updates

### 14.1 Versioning

`savvy-template` follows semantic versioning:
- **Major (v2.0.0):** Breaking changes to structure. Migration script required. Old structure moves to `_legacy/v<from>-to-v<to>-<date>/` for `/legacy-review`.
- **Minor (v1.1.0):** Additive. Safe `copier update`. No `_legacy/` archival needed.
- **Patch (v1.0.1):** Fixes. Always safe. No structural changes.

### 14.2 Update workflow per project

```bash
cd <project>
copier update     # interactive, shows diff per file
git add . && git commit -m "framework: update to v1.x.y"
```

For **major version updates**, the workflow runs a migration script (declared in `copier.yml` under `_migrations`) *before* the interactive diff prompts. The migration script:

1. Creates `_legacy/v<from>-to-v<to>-<date>/` and copies old structure into it
2. Performs structural transforms (rename folders, split files, etc.) on the working copy
3. Writes `MIGRATION_NOTES.md` documenting what moved and why
4. Hands control back to Copier for the standard interactive diff prompts

After update completes, the user has both the new structure (active) and `_legacy/` (frozen archive). `/legacy-review` is the cleanup workflow — see §5.9.

Each major version that introduces structural changes ships with its own migration script in `_migrations` of `copier.yml`. There's no generic migration engine; logic is authored per release.

### 14.3 Cadence

- Critical fixes: immediate propagate
- New features: at next active session per project
- Major version migrations: do one project at a time with `/legacy-review` follow-up
- Quarterly review: sweep all projects to latest

### 14.4 Drift detection

`/lint-framework` includes:
- Template version check (warns if more than 2 minor versions behind)
- Stale `_legacy/` folder check (warns if any `_legacy/<migration>/` is older than 90 days without complete review)

---

## 15. Roll-out Plan

### Phase 1 — Build the template + CLI (Week 1–3)

1. Create `shaunchew/savvy-template` repo
2. Author all template files
3. Build 10 universal skills (curator, bloat-watcher, linter, spec-bootstrap, lesson-recorder, release-gate, project-intake, project-evolve, legacy-reviewer, scratchpad-mode)
4. Write 23 slash commands
5. Configure hooks
6. Set up Copier config (`copier.yml`) with `llm` variable + `_migrations` skeleton for future major versions
7. Write `savvy` shell function, add to `~/.zshrc`
8. Create `shaunchew/savvy-template-quickstart` as GitHub Template wrapper

### Phase 2 — Pilot on Remote AI Maestro (Week 4)

1. Run `savvy new` or `copier copy` on Remote AI Maestro (gradual mode)
2. Author core files (or run `/intake` if rebuilding from scratch)
3. Migrate one active spec to new structure
4. Enable Notion + Telegram integrations
5. Use the framework for 1 week
6. Iterate based on findings

### Phase 3 — Propagate (Week 5–7)

1. The Collections — enable Notion + RAM
2. Grimoire — enable Notion
3. Other active repos in order of activity

### Phase 4 — Telegram bot (optional, Week 6+)

Standalone deployment, added as integration where wanted.

### Phase 5 — RAM-native capture (Q3)

Build native capture UI in RAM when it's next feature focus.

### Phase 6 — Codex/Gemini skill ports (as needed)

When you actually adopt a second agent, port the 8 framework skills to that agent's format. ~4-8 hours per agent.

---

## 16. Open Questions for Next Iteration

Deferred to v1.1 or v2.0:

1. **Cross-project portfolio view.** `savvy status` CLI command that aggregates state across all repos. v1.2.
2. **Lesson promotion.** Global `~/.claude/lessons-global.md` for patterns that apply broadly. v1.2.
3. **`savvy add-llm <agent>`.** Add a parallel agent directory to an existing repo. v1.1.
4. **Spec dependencies.** Explicit `depends_on:` frontmatter linking specs. v1.1.
5. **Auto-archive.** 90-day default move from `specs/<category>/` to `specs/_archive/`. v1.2.
6. **Constitution evolution semantics.** When constitution.md changes mid-project, how do older specs reconcile? Document pattern in v1.1.
7. **Homebrew tap for `savvy`.** Cross-machine portability. v1.1.
8. **The System integration.** Decide which capabilities live in The System vs the framework. Defer until The System is closer to production.

---

## Appendix A: File Length Budgets

| File | Soft target | Hard ceiling | Enforced by |
|---|---|---|---|
| AGENTS.md | 40 lines | 60 lines | bloat-watcher hook |
| CLAUDE.md | 10 lines | 15 lines | bloat-watcher hook |
| constitution.md | 50 lines | 80 lines | bloat-watcher hook |
| spec.md | 100 lines | 200 lines | bloat-watcher (warn) |
| plan.md | 150 lines | 300 lines | bloat-watcher (warn) |
| ROADMAP.md | 80 lines | 150 lines | bloat-watcher (warn) |
| HANDOVER.md | 30 lines | 50 lines | regenerated each `/handover` |
| pending-changes.md | (no limit) | (warn at 50 entries) | bloat-watcher (suggest /curate) |

## Appendix B: Naming Conventions

- **Specs:** `specs/<category>/<NNN>-<kebab-case-name>/`
- **ADRs:** `docs/decisions/<NNN>-<kebab-case-name>.md`
- **Lessons:** chronological append to `.claude/lessons.md`
- **Branches:** `<category>/<NNN>-<kebab-case-name>` matching spec folder
- **Commits:** Conventional commits (`feat:`, `fix:`, `chore:`, `docs:`)

## Appendix C: Quick Reference — When to Use What

- "Start a new project from idea" → `savvy new <name> --idea "..."`
- "Add a new feature mid-project" → `/evolve "<description>"`
- "Sign off on pending core-file changes" → `/curate`
- "Just bootstrap one new spec" → `/spec <category>/<name>`
- "Edit an existing spec" → `/spec-revise <ref> "..."`
- "Cancel/archive a spec" → `/spec-archive <ref> "..."`
- "Major stack change" → `/stack-evolve "..."`
- "Sync spec statuses from git" → `/status-sync`
- "Explore an idea without affecting main project" → `/scratchpad <name>`
- "Return from scratchpad to main project" → `/scratchpad-exit`
- "Promote scratchpad findings into real specs/ADRs" → `/promote-scratchpad <name>`
- "Archive a scratchpad that didn't pan out" → `/archive-scratchpad <name> "..."`
- "Review old files in `_legacy/` and decide keep/delete/restore" → `/legacy-review`
- "Adopt the framework on an existing repo with active triage" → Variant B in §12.2
- "Adopt the framework on an existing repo without triage" → Variant A in §12.1
- "How do I describe my stack to Claude?" → AGENTS.md (via /curate)
- "How do I configure Claude-specific behavior?" → CLAUDE.md (via /curate)
- "How do I lock in non-negotiable principle?" → constitution.md (via /curate)
- "How do I capture a permanent technical decision?" → ADR in `docs/decisions/`
- "How do I track ongoing operational state?" → `docs/ops/`
- "How do I capture a learned lesson?" → `/lesson "..."`
- "How do I update the framework everywhere?" → `copier update` per repo
- "How do I add a new task system integration?" → New folder under `.claude/integrations/`

---

**End of plan v1.0.**

This document is itself a living spec for the framework, versioned with the template at `shaunchew/savvy-template/docs/PLAN.md`.
