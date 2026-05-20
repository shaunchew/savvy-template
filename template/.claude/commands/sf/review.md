---
description: Run an independent code review on the current branch's pending changes via the code-reviewer subagent.
argument-hint: "[spec-ref]"
---

# /sf:review

Get a second-opinion code review on the diff of the current branch before `/sf:ship`. Delegates to the `code-reviewer` subagent so review output doesn't pollute the main session's context.

## Procedure

1. Determine the diff base:
   - If on `main`/`master`: error out with "no diff against itself; run on a feature branch."
   - Else: base is the merge-base with `main` (fall back to `master` if no `main`).
2. Determine the spec context:
   - If `$ARGUMENTS` is non-empty, treat it as a spec ref (`<category>/<NNN>` or full folder path). Load that spec's `spec.md`, `plan.md`, `checklist.md`.
   - Else, infer from the current branch name (`<category>/<NNN>-*` convention). If inference fails, proceed without spec context but tell the user.
3. Invoke the `code-reviewer` subagent with:
   - The diff (output of `git diff <base>...HEAD`)
   - The spec docs (if available)
   - `constitution.md` (always)
4. Print the subagent's verdict and findings unchanged.
5. If the verdict is `REQUEST-CHANGES` or there are blocking findings, do NOT proceed to suggest `/sf:ship`. Otherwise suggest `/sf:ship <ref>` as the next step.

## Arguments

- `$ARGUMENTS` (optional) — spec reference (`<category>/<NNN>` or full path). When omitted, the subagent infers from branch name.

## Invokes

- `code-reviewer` subagent — receives the diff, spec docs, and constitution; returns a structured review with `APPROVE` / `APPROVE-WITH-NITS` / `REQUEST-CHANGES` verdict.

## Output

The subagent's review printed verbatim, followed by a one-line next-step recommendation.

## Failure modes

- No `code-reviewer` subagent registered: error out and direct the user to `.claude/agents/code-reviewer.md`.
- Empty diff (no changes vs base): tell the user there's nothing to review.
- Cannot find merge-base with main/master: ask the user to specify the base explicitly.
