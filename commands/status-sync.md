---
description: Push current ROADMAP and spec statuses to any enabled mirror (e.g. Notion dashboards).
---

# /sf:status-sync

Push the current `ROADMAP.md` state and per-spec statuses to any enabled external mirror. Operates over the roadmap rather than per-spec tasks (the per-task sync is `/sf:sync-notion`).

## Procedure

1. Read `.claude/config.toml` and enumerate integrations (`notion`, `telegram`, `ram`, future). For each, check `[integration.<name>] enabled = true`.
2. Read `ROADMAP.md` and parse the Active section into structured rows: `{category, NNN, name, status, summary}`. Also collect frontmatter `status:` from each linked `specs/<category>/<NNN>-*/spec.md` and reconcile any mismatch against the roadmap line (prefer spec.md as ground truth; warn on drift).
3. For each enabled integration with a dashboard surface:
   - **notion:** push the parsed rows to the dashboards database declared in `.claude/integrations/notion/config.toml`. Upsert by `(category, NNN)`. Update `status`, `summary`, and `last_synced_at`.
   - Other integrations: skip unless they declare a dashboard surface in their `config.toml`.
4. For each disabled integration, print a single line: `<name>: disabled (skipped)`.
5. If no integrations are enabled, print `No mirrors enabled. Edit .claude/config.toml to turn one on.` and exit cleanly.
6. Print a final report: count of rows pushed per integration, count of drift warnings reconciled, and any errors.

## Invokes

- (none — uses the integration plumbing in `.claude/integrations/<name>/skill/` directly)

## Output

Per-integration status lines and a final summary. No local files change unless drift reconciliation rewrites a spec's frontmatter `status:` (in which case those spec.md files are edited and the user is told which ones).
