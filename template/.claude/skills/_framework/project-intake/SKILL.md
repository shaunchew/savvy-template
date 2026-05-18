---
name: project-intake
description: One-shot project bootstrap from a description via /intake "<idea>", /intake --from-file, or session-start detection of .claude/intake-input.md; runs five approval-gated batches with one commit each.
---

# Project Intake

One-shot project bootstrap from a description. Runs a five-batch flow: (1) Core files, (2) Specs, (3) ADRs, (4) Subagents, (5) Integrations. Triggered by `/intake "<idea>"`, `/intake --from-file <path>`, or session-start detection of `.claude/intake-input.md`. Each batch has approval gates (y/select/modify) with one commit per batch.

## Status

Stub — content to be filled in Phase 1 implementation. See `docs/PLAN.md` §5 for the full spec.
