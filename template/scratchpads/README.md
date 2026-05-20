# Scratchpads

Isolated exploration workspaces for spikes, prototypes, and throwaway research.

Each scratchpad is a self-contained subdirectory (`scratchpads/<slug>/`) where you can experiment without the friction of the full spec workflow. Use them for: exploring an unfamiliar library, prototyping an approach before committing to it, working through an investigation, or sketching ideas you're not yet ready to formalize.

## Behavior inside a scratchpad

While the working context is inside `scratchpads/<slug>/`, framework guardrails are intentionally inert:

- `framework-curator`, `bloat-watcher`, `spec-bootstrap`, and `project-evolve` do not run.
- `ROADMAP.md`, `CHANGELOG.md`, and `HANDOVER.md` are not updated.
- Scratchpad content does not count toward bloat or doc budgets.

This keeps exploration cheap. Treat scratchpads as drafts: messy is fine.

## Promoting and archiving

- `/sf:promote-scratchpad` — convert findings into real `specs/` entries, ADRs under `docs/decisions/`, or runbooks. Use this once an exploration has produced something worth keeping.
- `/sf:archive-scratchpad` — move a finished or abandoned scratchpad into `scratchpads/_archive/` to preserve history without cluttering the active list.
