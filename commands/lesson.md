---
description: Append a tagged lesson to .claude/lessons.md.
argument-hint: "\"<text>\""
---

# /sf:lesson

Record a one-line lesson into `.claude/lessons.md` via the lesson-recorder skill.

## Procedure

1. Treat all of `$ARGUMENTS` as the lesson text. Trim surrounding quotes if the user wrapped the argument in them.
2. If `$ARGUMENTS` is empty, prompt the user for the lesson text inline and continue once provided.
3. Invoke the `lesson-recorder` skill with the lesson text. The skill parses any `[tag]` prefix (`[placement]`, `[gotcha]`, `[pattern]`, `[mistake-avoided]`), prepends a timestamp, and appends to `.claude/lessons.md`.
4. Print the tag the skill assigned (or "untagged") and the file path.

## Arguments

- `$ARGUMENTS` — the lesson text. May begin with a bracket tag like `[gotcha]` to set the category. Example: `[gotcha] the CI cache key must include the lockfile hash or installs go stale`.

## Invokes

- `lesson-recorder` — receives the raw lesson text; returns the parsed tag and the line written.

## Output

A new entry appended to `.claude/lessons.md`. Console prints the assigned tag and the file path.
