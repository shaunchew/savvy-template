---
description: Propose stack-level changes (language/runtime/framework); drafts an ADR and deferred AGENTS.md additions.
argument-hint: "[\"<change>\"]"
---

# /stack-evolve

Propose a stack-level change (new language, runtime, framework, or deploy target). Writes an ADR immediately and queues the corresponding AGENTS.md additions for later sign-off.

## Procedure

1. Parse `$ARGUMENTS`. If empty, prompt: "Describe the stack change (one paragraph):". If present, use it as `<change>`.
2. Read `AGENTS.md` (Stack and Commands sections) and `docs/decisions/` to understand current state and existing ADR numbering.
3. Determine the next ADR number by scanning `docs/decisions/NNN-*.md` (zero-padded 3 digits, max + 1).
4. Draft two outputs in memory without writing yet:
   - **ADR (immediate):** `docs/decisions/<NNN>-<kebab-slug>.md` with frontmatter (`status: proposed`, `date: <YYYY-MM-DD>`) and sections Context / Decision / Consequences derived from `<change>`.
   - **Deferred AGENTS.md additions:** the exact lines that would go under `## Stack` and/or `## Commands`, formatted as a pending-changes entry (timestamp, target `AGENTS.md`, field, proposed content, source `/stack-evolve "<change>"`).
5. Print both drafts to the user side by side. Ask `Write ADR and queue AGENTS.md changes? [y/n/edit]`. On `edit`, accept revisions and re-render. On `n`, abort.
6. On `y`, route the AGENTS.md additions through `framework-curator` to validate placement, then write the ADR to `docs/decisions/<NNN>-<kebab-slug>.md` and append the deferred entry to `.claude/pending-changes.md`.
7. Print: "Wrote docs/decisions/<NNN>-<slug>.md. Queued 1 entry in .claude/pending-changes.md. Run /curate after /ship to apply AGENTS.md updates."

## Arguments

- `$ARGUMENTS` — optional change description. If absent, prompt interactively. Strip surrounding quotes.

## Invokes

- `framework-curator` (to validate the deferred AGENTS.md additions before appending)

## Output

Two drafts printed before any write, a confirmation prompt, then a one-line summary. Files changed: `docs/decisions/<NNN>-<kebab-slug>.md` (created) and `.claude/pending-changes.md` (appended).
