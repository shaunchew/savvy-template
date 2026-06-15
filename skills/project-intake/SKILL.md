---
name: project-intake
description: One-shot project bootstrap from a description via /sf:intake "<idea>", /sf:intake --from-file, or session-start detection of .claude/intake-input.md; runs five approval-gated batches with one commit each.
---

# Project Intake

One-shot project bootstrap from an idea description. Runs five approval-gated batches with one commit per batch so git history stays clean.

## When to invoke

- User runs `/sf:intake "<idea text>"` (inline description).
- User runs `/sf:intake --from-file <path>` (CLI-driven bootstrap).
- Session starts and `.claude/intake-input.md` exists (per template CLAUDE.md instruction); read that file as the idea description.

## Procedure

1. Acquire the idea text from the trigger source. Analyze it for project type (data-science / software-dev / hybrid), stack hints, components, and domain constraints. Print this analysis and ask for confirmation before proceeding.
2. Determine bootstrap mode. If this is the initial run (template just scaffolded, AGENTS.md/CLAUDE.md/constitution.md are still default), apply Batch 1-5 edits DIRECTLY. If invoked manually on an established repo, route Batch 1 and Batch 5 additions through `framework-curator` (defer to `.claude/pending-changes.md`).
3. **Batch 1 - Core files.** Draft full contents for: `AGENTS.md` (Stack, Commands, Conventions, Negative rules, On-demand context sections), `CLAUDE.md` (only project-specific additions beyond template defaults), `constitution.md` (Architecture invariants, Quality gates, Security posture, Non-negotiable conventions), `README.md` (one-paragraph project summary + quickstart). Show the user the proposed contents. Ask `y` / `select` / `modify`. On approval, write and commit with message `chore(intake): batch 1 - core files`.
4. **Batch 2 - Specs.** Propose 2-5 initial specs derived from the idea, each as `specs/<category>/<NNN>-<kebab>/` with `spec.md`, `plan.md`, `tasks.md`, `checklist.md`. Use category mapping from PLAN §3 (product / marketing / ops / research). For each approved spec, invoke `spec-bootstrap` to scaffold. Update `ROADMAP.md` `## Active` section with the new specs. Commit `chore(intake): batch 2 - initial specs`.
5. **Batch 3 - ADRs.** Propose foundational decisions as placeholders under `docs/decisions/<NNN>-<kebab>.md` (stack choice, deployment target, auth approach, data store, anything else load-bearing). Each ADR has Context / Decision / Consequences sections with `Decision: TBD` placeholders the user fills later. Commit `chore(intake): batch 3 - foundational ADRs`.
6. **Batch 4 - Subagents.** The template ships three universal subagents in `.claude/agents/`: `explorer` (read-only mapping), `code-reviewer` (independent review before `/sf:ship`), `parallel-runner` (isolated parallel work). Propose ADDITIONAL project-specific subagents on top of these (e.g., stack-specific test-writer, schema-migrator, domain-expert). Do not duplicate the universal three. Each file has the standard subagent frontmatter. Commit `chore(intake): batch 4 - subagents`.
7. **Batch 5 - Integrations.** Ask which of `notion`, `telegram`, `ram` to enable. For each chosen integration, in initial-bootstrap mode write to `.claude/config.toml` directly; in manual mode route through `framework-curator` to defer to `.claude/pending-changes.md`. Do NOT request credentials inside this skill — point the user at the integration's own setup doc. Commit `chore(intake): batch 5 - integrations`.
8. After Batch 1 commits, if `.claude/intake-input.md` exists, DELETE it (its content is now reflected in committed files).
9. Print a final summary: files created per batch, commits made, deferred entries (if any). Suggest `/sf:lint-framework` to verify and `/sf:plan <first-spec>` to start work.

## Output

- Five git commits (one per batch), each scoped to that batch's files.
- New / overwritten: `AGENTS.md`, `CLAUDE.md`, `constitution.md`, `README.md`, `specs/<category>/<NNN>-*/`, `docs/decisions/<NNN>-*.md`, `.claude/agents/*.md`, `ROADMAP.md`, optional `.claude/config.toml`, optional `.claude/pending-changes.md` entries.
- `.claude/intake-input.md` removed after Batch 1.

## Failure modes

- User rejects a batch entirely (`n`): skip that batch, do NOT commit, continue to the next.
- User modifies a batch: incorporate edits, re-present, require explicit `y` before committing.
- Mid-batch interruption: leave uncommitted files staged but inform the user nothing was committed for that batch; resume cleanly on next `/sf:intake`.
- Idea text too vague to categorize: ask three targeted clarifying questions before Batch 1, do not guess.
- `framework-curator` is unavailable and intake is in manual mode: refuse Batch 1 / Batch 5, tell the user to ensure the curator skill is loaded.
