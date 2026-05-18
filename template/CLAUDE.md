# Claude overlay

See `AGENTS.md` for canonical agent context.

IMPORTANT: When proposing to add content to CLAUDE.md, AGENTS.md, or constitution.md, use the framework-curator skill to validate placement. Such changes are deferred to .claude/pending-changes.md during /evolve and applied only via /curate sign-off.

On session start, check for .claude/intake-input.md. If present, run /intake --from-file .claude/intake-input.md.

- Prefer plan mode for non-trivial work.
- Run `/ship` release gate before tagging.
