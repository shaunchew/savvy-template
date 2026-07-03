---
name: project-evolve
description: Smart router for ongoing changes via /sf:evolve "<change>"; applies specs/plans/tasks/checklists/ROADMAP/ADRs/subagents immediately, defers AGENTS/CLAUDE/constitution edits and integration flips to pending-changes.md.
---

# Project Evolve

Smart router for ongoing project changes. Classifies a single-sentence change description and routes it: speculative edits apply immediately; ground-truth edits (core context files, integration flips) defer to `.claude/pending-changes.md` via `framework-curator`.

## When to invoke

- User runs `/sf:evolve "<change description>"`.
- User describes an ongoing change ("add X feature", "drop Y scope", "switch from A to B stack", "refine spec Z") without specifying a target file.
- Do NOT invoke for shipping (`/sf:ship`), curation sign-off (`/sf:curate`), or scratchpad work.

## Procedure

1. Read current project state: `AGENTS.md`, `constitution.md`, `ROADMAP.md`, `.claude/lessons.md`, and the list of specs under `specs/`. This is read-only context.
2. Classify the change into one of:
   - **net-new feature** -> propose new spec(s) under appropriate category.
   - **scope removal** -> propose `/sf:spec-archive` on matching spec(s).
   - **stack change** -> propose AGENTS.md addition (deferred) + ADR draft (immediate).
   - **spec refinement** -> propose edits to that spec's `spec.md` / `plan.md` / `tasks.md` / `checklist.md`.
   - **status sync** -> propose ROADMAP and spec frontmatter updates from git/PR state.
   - **invariant or non-negotiable** -> propose constitution.md addition (deferred).
   - **Claude-behavior tweak** -> propose CLAUDE.md addition (deferred).
   - **integration flip** -> propose `.claude/config.toml` change (deferred).
   - **unclear** -> walk the placement decision tree (defined in the `framework-curator` skill) explicitly and report which branch matched.
3. Print the routing decision in one line: `This change is <category> -> target <file/folder> -> <immediate|deferred>`. Ask `y/n` to proceed.
4. On `y`, execute APPLY-IMMEDIATELY for: new specs (folder + 4 files), edits to existing spec files, `ROADMAP.md` updates, ADR drafts in `docs/decisions/`, new subagents in `.claude/agents/`. Write directly. Run `bloat-watcher` if it is loaded.
5. On `y`, execute DEFER for: `AGENTS.md` additions, `CLAUDE.md` additions, `constitution.md` additions, `.claude/config.toml` integration flips. Invoke `framework-curator` with `{target_file, field, content, source: "/sf:evolve '<text>'"}`. The curator appends an entry to `.claude/pending-changes.md`.
6. If the change touches both speculative and ground-truth surfaces (e.g., new spec PLUS stack change), execute both arms and report each.
7. Final report. List applied-immediately changes, list deferred entries, remind the user to run `/sf:curate` once related work ships.

## Output

- Immediate: new or edited files under `specs/`, `docs/decisions/`, `.claude/agents/`, plus `ROADMAP.md`.
- Deferred: appended entries in `.claude/pending-changes.md` (one per ground-truth change).
- A summary message listing both arms.

## Failure modes

- Change description ambiguous between two categories: walk the decision tree and pick the highest-priority branch; tell the user which alternatives were considered.
- Spec reference not resolvable (`/sf:evolve "tweak the auth spec"` but no matching spec): list candidates and ask the user to disambiguate; do not guess.
- `framework-curator` unavailable: refuse the deferred arm, write nothing to core files, tell the user to load the curator skill.
- Change request is actually exploratory ("I want to try X"): suggest `/sf:scratchpad <name>` instead and do not write to project state.
- User rejects the routing decision: do nothing; offer to re-classify with more detail.
