---
description: Walk a spec's checklist; on all-pass update CHANGELOG, move spec to shipped, tag release, and sync Notion if enabled.
argument-hint: "<category>/<NNN>"
---

# /sf:ship

Run the release gate on a spec — walk its checklist, update CHANGELOG, mark the spec shipped, propose a tag, and finalize with a conventional commit.

## Procedure

1. Parse `$ARGUMENTS` as `<category>/<NNN>`. Resolve the spec folder by globbing `specs/<category>/<NNN>-*/`. Abort if zero or multiple matches.
2. Invoke the `release-gate` skill with the resolved spec path. The skill will:
   - Walk `checklist.md` item-by-item, requiring an explicit pass/fail for each.
   - Stop on the first failure and report what blocks shipping.
   - On all-pass, append an entry to `CHANGELOG.md` under `## [Unreleased]`, flip the spec's status frontmatter to `shipped`, propose a semver tag, and trigger `/sf:sync-notion` if `[integrations] notion = true` in `.claude/config.toml`.
3. On all-pass, draft a conventional-commit message (`feat:`, `fix:`, `chore:`, or `docs:` based on the spec category and contents) that references `<category>/<NNN>` and a one-line summary of what shipped.
4. Show the proposed commit message to the user and confirm before running `git commit -m "<message>"`. Do not pass `--author`; let the commit use the user's own git config (and honor any authorship convention in their global `~/.claude/CLAUDE.md`).
5. Remind the user to run `/sf:curate` if `.claude/pending-changes.md` has unresolved entries.

## Arguments

- `$ARGUMENTS` — `<category>/<NNN>` (e.g. `product/003`).

## Invokes

- `release-gate` — receives the resolved spec path; returns pass/fail state and the proposed tag.

## Output

Updated `CHANGELOG.md`, spec frontmatter flipped to `shipped`, a new git commit, a proposed tag printed to console, and a Notion sync trigger when enabled.
