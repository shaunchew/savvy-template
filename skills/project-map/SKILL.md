---
name: project-map
description: Brownfield convergence via /sf:map [--refresh] — surveys an existing codebase read-only and writes an as-built baseline under docs/as-built/ (an index plus up to six area docs) as ground truth for spec-driven work. Create-if-absent; --refresh diffs before overwriting.
---

# Project Map

Builds an **as-built baseline** of an existing codebase so the framework's spec-driven flow has ground truth to converge on. Surveys the tree read-only and writes a map under `docs/as-built/`: an index plus one doc per major area, each ending in the questions the code cannot answer.

## When to invoke

- User runs `/sf:map` (create-if-absent) or `/sf:map --refresh` (re-survey and update).
- `/sf:intake` detects a brownfield repo (real source already present, not a fresh scaffold) and suggests mapping before authoring specs.
- `/sf:spec` or `/sf:plan` needs ground truth for an area that has no as-built doc yet.

## Safety contract

This is the framework's brand — honor it exactly:

- **Read-only over source.** Never edit, move, or delete any file outside `docs/as-built/`.
- **Writes land only under `docs/as-built/`.** Nothing else is created or touched.
- **Create-if-absent by default.** If `docs/as-built/` already exists and `--refresh` was not passed, stop.
- **`--refresh` diffs before it overwrites.** Regenerate into memory, show a per-file diff summary, and get explicit confirmation before writing over any existing as-built doc.
- **Never run build/test/lint commands.** Detect them from config and record them as text; only run one if the user explicitly asks.
- **Budget-bounded.** Obey `bloat-watcher` discipline: each area doc ≤80 lines, the index lean; link deeper rather than inline.

## Procedure

1. **Confirm adoption.** Read `.claude/config.toml`; if there is no `[framework]` marker, refuse in one line and stop.
2. **Gate on existing docs.** If `docs/as-built/` exists and `--refresh` was not passed, list what is there and stop. If `--refresh` was passed, note that you are in refresh mode (step 8 governs writes).
3. **Survey read-only.** Map the following without running anything (optionally dispatch the read-only `explorer` subagent to keep raw search output out of context):
   - directory layout and the roots the repo builds from;
   - languages and frameworks — run `bash "${CLAUDE_PLUGIN_ROOT}/scripts/sf-stack.sh" --json` (deterministic, read-only manifest detection) rather than inferring by eye;
   - entry points (CLIs, servers, jobs, exported packages);
   - build / test / lint commands, read from config — recorded, not executed;
   - key modules and their responsibilities;
   - external services and third-party dependencies;
   - data stores (databases, caches, queues, schemas, migrations);
   - config surfaces (env vars, config files, feature flags).
4. **Detect monorepos.** If the tree declares multiple workspaces (npm/pnpm/yarn workspaces, `go.work`, a Cargo workspace, nx/turbo), map the top-level workspaces only and say so in the index; leave per-workspace depth as linked follow-ups.
5. **Cluster into areas.** Group findings into at most ~6 major areas. If the codebase has more, consolidate and note the cap in the index rather than sprawling into dozens of docs.
6. **Write the index — `docs/as-built/README.md`.** A one-paragraph system summary; a detected-stack table; entry points; build/test/lint commands (marked "detected, not run"); and a link to each area doc. Keep it lean.
7. **Write one `docs/as-built/<area>.md` per area (≤80 lines).** Each records:
   - **Purpose** — what this area does, in two or three sentences.
   - **Key files** — `path — responsibility`, the load-bearing ones only.
   - **Invariants observed** — rules the code clearly upholds (e.g. never writes X directly, all requests pass through Y). Only what the code actually shows.
   - **KNOWN-UNKNOWNS** — what the code does not reveal (intent, ownership, why-decisions), phrased as questions for the user. Never guess; an honest question beats an invented answer.
8. **Refresh writes (`--refresh` only).** Before overwriting anything, show a diff summary — files added / changed / removed, and the section-level deltas per changed file — and require an explicit `y`. On anything other than `y`, write nothing and leave the existing docs intact.
9. **Report.** Print the index path, the area docs written, and the total count of KNOWN-UNKNOWNS raised. Suggest resolving them, and note that `/sf:spec` and `/sf:plan` can now cite these docs as ground truth.

## Output

- `docs/as-built/README.md` — the map index.
- `docs/as-built/<area>.md` — one per area, up to ~6, each ≤80 lines.
- Console summary: index path, area docs written, KNOWN-UNKNOWNS count, and next steps.
- Under `--refresh`: the same set, but only after a confirmed diff; no unconfirmed overwrite ever happens.

## Failure modes

- **Not an adopted project** (no `[framework]` in `.claude/config.toml`) → refuse in one line, suggest `/sf:adopt`, and write nothing.
- **`docs/as-built/` exists and `--refresh` absent** → print the existing index and area list, then stop.
- **Giant monorepo** → map top-level workspaces only, state the reduction in the index, and leave deeper areas as linked follow-ups.
- **No detectable source** (empty or near-empty repo) → report cleanly and suggest `/sf:intake` for greenfield, rather than mapping nothing.
- **Refresh diff declined** → change nothing; the existing docs stay as they were.
- **An area's intent is unreadable from code** → do not invent it; record it as a KNOWN-UNKNOWN and move on.
