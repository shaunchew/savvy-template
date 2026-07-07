---
description: Interrogate a spec's spec.md before planning — surface unstated assumptions, undefined terms, missing acceptance criteria, and unbounded scope, then record answers under a dated Clarifications section.
argument-hint: "<category>/<NNN>"
---

# /sf:clarify

Pressure-test a spec's `spec.md` *before* `/sf:plan`, so planning starts from resolved requirements instead of hidden guesses. Append-only: it records answers, it never rewrites your spec prose.

## Procedure

1. Requires an adopted project. If there is no `specs/` tree, tell the user to run `/sf:adopt` and exit.
2. Parse `$ARGUMENTS` as `<category>/<NNN>` (or a full spec-folder path). Resolve the folder by globbing `specs/<category>/<NNN>-*/`. Abort if zero or multiple matches.
3. Read the spec's `spec.md`. If it is missing or still the empty template, stop and point the user to `/sf:spec`.
4. Scan `spec.md` for ambiguity across these lenses, keeping the highest-leverage gaps:
   - Unstated assumptions and undefined domain terms.
   - Missing or untestable acceptance criteria.
   - Unbounded scope words ("fast", "simple", "scalable", "etc.", "and so on").
   - Unaddressed failure and edge cases.
   - Integration points the spec is silent on (auth, data, external services).
5. Ask the user **at most 5** questions in a single batch, ordered highest-leverage first, multiple-choice wherever a closed set of answers is plausible. Do not ask what the spec already answers.
6. Append the Q&A to `spec.md` under a `## Clarifications` section — create it if absent, otherwise append. Prefix the batch with a dated subheading (`### <YYYY-MM-DD>`). Never touch the user's existing prose above it.
7. Print the folder path and suggest `/sf:plan <category>/<NNN>` as the next step.

## Arguments

- `$ARGUMENTS` — `<category>/<NNN>` (e.g. `product/003`) or a full spec-folder path.

## Invokes / invoked by

Flow position: `spec → clarify → plan → analyze → implement → ship`. Runs after `/sf:spec`, before `/sf:plan`; its post-planning complement is `/sf:analyze`. Edits only the target spec's `spec.md`.

## Output

`specs/<category>/<NNN>-*/spec.md` with a dated batch appended under `## Clarifications`. Console prints the folder path and the suggested next command.
