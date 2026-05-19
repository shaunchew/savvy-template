# Subdirectory `AGENTS.md` pattern

When a project grows past one cohesive component (multiple services, a frontend/backend split, vendored or large generated dirs), root `AGENTS.md` is the wrong place to put per-area conventions. Subdirectory `AGENTS.md` files load on-demand as Claude navigates into the directory — keeping root lean and area-specific guidance close to the code.

## When to drop a subdirectory `AGENTS.md`

- The directory has commands, conventions, or quirks that don't apply to the rest of the repo (e.g., a `frontend/` with its own dev server + lint config).
- The directory uses a different language or framework than the root.
- The directory has narrow scope (a microservice, a vendored module) and Claude shouldn't apply root-level rules there.

Don't drop one for every subdirectory. If the only thing you'd write is "this folder follows the same rules as root," skip it.

## File budget

Same discipline as root `AGENTS.md`:

- **Hard ceiling:** 60 lines per file, enforced by `bloat-watcher` (extend `bloat-check.sh` to match `*/AGENTS.md` if you adopt this widely).
- **Content rule:** non-inferable only — stack, commands, conventions, negative rules. Don't restate what root already says.

## Template

```markdown
# <area name> — agent context

Scope: <one line — what this directory contains and why it has its own AGENTS.md>

## Stack (overrides root)
- {fill, only if different from root}

## Commands (scoped to this area)
- Setup: `{fill}`
- Run: `{fill}`
- Test: `{fill}`

## Conventions (this area only)
- {fill: 1–3 conventions}

## Negative rules (this area only)
- Never {fill}

## See also
- Root `AGENTS.md` for project-wide context.
- `specs/<category>/...` for active work in this area.
```

## Placement decision

The `framework-curator` placement tree (skill: `framework-curator`) routes here when:

1. Content is a stack/command/convention Claude wouldn't guess, AND
2. It only applies inside one specific directory subtree

If the content applies project-wide, it belongs in root `AGENTS.md`. If it's a single non-obvious file edit, it belongs in a code comment instead.

## Discovery

Claude Code automatically walks up the directory tree at session start and on Read, loading `AGENTS.md`/`CLAUDE.md` it encounters. No manual import. Just create the file and Claude will find it when working in that area.
