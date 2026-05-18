---
description: Smart router for ongoing project changes; speculative changes apply immediately, ground-truth defers to pending-changes.
argument-hint: "\"<change>\""
---

# /evolve

Route an arbitrary project change to the right action — new spec, spec revision, archive, stack change, status sync — and split speculative edits (apply now) from ground-truth edits (defer to pending-changes).

## Procedure

1. Parse `$ARGUMENTS` as a single quoted change description. If empty or missing, ask the user for the change in one sentence and abort if still empty.
2. Invoke the `project-evolve` skill with the change text. Let it read `AGENTS.md`, `constitution.md`, `ROADMAP.md`, and `.claude/lessons.md` to classify the change.
3. The skill returns a routing summary: which files/specs will be touched, which edits are immediate (specs, plans, tasks, ADR drafts, ROADMAP) and which are deferred (AGENTS.md, CLAUDE.md, constitution.md, integration configs).
4. Print the routing summary to the user and ask `Apply? [y/n]`. On `n`, stop and write nothing.
5. On `y`, let the skill execute immediate writes and append deferred entries to `.claude/pending-changes.md` with timestamp, target file, proposed content, and source `/evolve "<change>"`.
6. Print the final report block: "Applied immediately: ..." and "Deferred to .claude/pending-changes.md (N entries): ...". Remind the user to run `/curate` after `/ship` to apply deferred changes.

## Arguments

- `$ARGUMENTS` — the change description as a single quoted string. Strip surrounding quotes before passing to the skill.

## Invokes

- `project-evolve`

## Output

A routing summary, a y/n prompt, and a final report listing files written and pending-changes entries appended. Files changed: any spec.md/plan.md/tasks.md under `specs/`, `ROADMAP.md`, new `docs/decisions/NNN-*.md` placeholders, `.claude/agents/*`, and `.claude/pending-changes.md`.
