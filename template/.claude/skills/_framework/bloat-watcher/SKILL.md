---
name: bloat-watcher
description: Monitors line counts on context files after edits via PostToolUse hook; flags AGENTS.md, CLAUDE.md, constitution.md, and other length-budgeted files as extraction candidates when ceilings are breached.
---

# Bloat Watcher

Monitors line counts on context files. Triggered by the PostToolUse hook on edits to AGENTS.md, CLAUDE.md, constitution.md, and other length-budgeted files. Flags extraction candidates when soft or hard ceilings are breached. Budgets defined in Appendix A.

## Status

Stub — content to be filled in Phase 1 implementation. See `docs/PLAN.md` §5 for the full spec.
