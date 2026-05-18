---
description: One-shot project bootstrap from an idea — 5-batch flow (core files, specs, ADRs, subagents, integrations) with per-batch approval.
argument-hint: "\"<idea>\" | --from-file <path>"
---

# /intake

One-shot project bootstrap from an idea description. Runs the 5-batch flow with per-batch approval.

## Procedure

1. Resolve the idea text from `$ARGUMENTS`:
   - If `$ARGUMENTS` starts with `--from-file `, read the path that follows; remember the path so it can be cleaned up later.
   - Else if `$ARGUMENTS` is non-empty, treat it as the inline idea text (strip surrounding quotes).
   - Else, look for `.claude/intake-input.md`. If found, use its contents and remember the path for cleanup.
   - Else, prompt the user for the idea text inline.
2. Invoke the `project-intake` skill with the resolved idea text. The skill analyzes the description (project type, stack hints, components, domain constraints) and runs five approval batches, one commit per batch:
   - Batch 1 — Core files (AGENTS.md, CLAUDE.md, constitution.md, and any special root docs).
   - Batch 2 — Specs decomposed across `product` / `marketing` / `ops` / `research`.
   - Batch 3 — ADR placeholders under `docs/decisions/`.
   - Batch 4 — Subagents under `.claude/agents/`.
   - Batch 5 — Integration recommendations (with credential prompts).
3. After the skill returns from Batch 1's commit, if the idea came from `.claude/intake-input.md`, delete that file so it isn't re-detected on the next session start.
4. On full completion, print a summary of what was created and suggest the next moves: `/lint-framework` to verify, then `/plan <first-spec>` to start work.

## Arguments

- `$ARGUMENTS` — one of: `"<idea text>"`, `--from-file <path>`, or empty (auto-detect `.claude/intake-input.md`).

## Invokes

- `project-intake` — receives the resolved idea text; runs the 5-batch flow with approval gates and per-batch commits.

## Output

A fully scaffolded project: core files, specs, ADR placeholders, subagent definitions, and integration configs. Five commits, one per batch. `.claude/intake-input.md` removed if it was the source. Console prints a summary and suggested next commands.
