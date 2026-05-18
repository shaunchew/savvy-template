---
name: lesson-recorder
description: Triggered by /lesson "<text>" or the Stop hook prompt to append a tagged entry (placement, gotcha, pattern, mistake-avoided) to .claude/lessons.md.
---

# Lesson Recorder

Captures lessons learned during a session by appending a tagged entry to `.claude/lessons.md`. Never edits prior entries.

## When to invoke

- User runs `/lesson "<text>"`.
- The Stop hook prompts for a lesson at session end and the user provides one.

## Procedure

1. Receive `<text>` as input. Strip surrounding whitespace.
2. Look for a leading tag in square brackets at the start of the text (e.g., `[placement] ...`, `[gotcha] ...`, `[pattern] ...`, `[mistake-avoided] ...`). Tag matching is case-insensitive; normalize to lowercase.
3. Validate the tag against the allowed set: `placement`, `gotcha`, `pattern`, `mistake-avoided`.
   - If a bracketed tag exists and is valid: strip the bracketed prefix from the text body; keep the tag.
   - If a bracketed tag exists but is not in the allowed set: ask the user once to pick from the allowed four. Wait for the reply before proceeding.
   - If no bracketed tag is present: ask the user once for a tag from the allowed four. Wait for the reply.
4. Compute the timestamp using the local clock as `YYYY-MM-DD HH:MM`.
5. If `.claude/lessons.md` does not exist, create it with a single H1 header: `# Lessons`.
6. Append (never insert, never reorder) the following block to the end of `.claude/lessons.md`:
   ```
   ## YYYY-MM-DD HH:MM — [<tag>]

   <text>

   ---
   ```
   Ensure there is exactly one blank line between the previous content and the new entry.
7. After writing, count the lines of `.claude/lessons.md` and report: `Appended lesson [<tag>] at YYYY-MM-DD HH:MM. File now N lines.`

## Output

- An appended entry in `.claude/lessons.md`.
- A one-line confirmation including the tag, timestamp, and resulting line count.

## Failure modes

- Empty `<text>` after stripping the tag: refuse and ask for a non-empty lesson body.
- User declines to provide a tag when prompted: abort without writing, tell the user the lesson was not recorded.
- `.claude/lessons.md` not writable: report the error and do not attempt to write elsewhere.
- Existing file does not end with a newline: add one before appending to preserve the block separator.
