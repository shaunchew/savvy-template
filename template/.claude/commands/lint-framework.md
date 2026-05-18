---
description: Run framework-linter to detect drift, missing files, malformed specs, rule violations, template drift, and stale scratchpads.
---

# /lint-framework

Run the framework linter and surface its findings with concrete fix suggestions.

## Procedure

1. Invoke the `framework-linter` skill with no arguments. It scans for: file-budget violations on AGENTS.md / CLAUDE.md / constitution.md, missing required files, malformed spec frontmatter, rule violations from the placement decision tree, template version drift, stale `_legacy/<migration>/` folders (>90 days unreviewed), and stale scratchpads (>60 days, not promoted or archived).
2. Pass the linter's Markdown report through to the user unchanged. Do not reformat or summarize away its detail.
3. For each finding, append a one-line suggested fix command beneath the finding when there is a sensible one. Examples:
   - Bloat in AGENTS.md → `Suggest: trim via /curate or move to docs/`
   - Stale `_legacy/` → `Suggest: /legacy-review <folder>`
   - Stale scratchpad → `Suggest: /promote-scratchpad <name>` or `/archive-scratchpad <name> "<reason>"`
   - Missing `ROADMAP.md` regeneration → `Suggest: /refresh-roadmap`
   - Template version drift → `Suggest: copier update`
4. If the linter returns no findings, print `Framework state clean.` and exit.

## Invokes

- `framework-linter` — receives no arguments; returns a Markdown report of findings or an empty result.

## Output

The linter's Markdown report with per-finding fix suggestions appended, or a single `Framework state clean.` line.
