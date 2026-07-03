# Contributing to the Savvy Framework

Thanks for considering a contribution. This document keeps it short and factual.

## What this repo is

The repo root **is** the engine: a Claude Code plugin (`sf`) — `commands/`,
`skills/`, `hooks/`, `agents/`, `.claude-plugin/`. Two directories are
**generated, never hand-edited**:

- `template/.claude/` — legacy in-tree engine mirror (for pre-plugin projects)
- `skeleton/` — the adoption seed used by `/sf:adopt`

After changing anything in the engine, regenerate them:

```bash
bash scripts/build-plugin.sh
```

CI fails if committed generated artifacts drift from what the script produces.

## Development rules

1. **Bash 3.2 compatible.** Every shell script must run on macOS system bash
   (no associative arrays, no `mapfile`, no `${var,,}`). CI runs the suite on
   macOS `/bin/bash` to enforce this.
2. **Zero runtime dependencies beyond `git` and `jq`.** Do not add more.
3. **Never-destructive by default.** Anything that touches a user's project
   must be create-if-absent, additive-merge, or explicitly confirmed — with a
   backup and a documented undo path. This is the framework's core promise.
4. **Tests are required.** Any change to `scripts/`, `hooks/`, or `migrations/`
   needs coverage in `tests/`. Run the suite before pushing:

```bash
bash tests/run.sh            # everything
bash tests/run.sh adopt      # just files matching "adopt"
```

## Pull requests

- Keep PRs to one logical change.
- Update `CHANGELOG.md` under `[Unreleased]`.
- If you changed the engine payload, include the regenerated `template/` /
  `skeleton/` / manifest in the same commit.

## Reporting bugs

Use the bug-report issue template. For anything that caused **data loss or
modified files it shouldn't have**, label it `safety` — those are treated as
release blockers.

## Security

See [SECURITY.md](SECURITY.md). Do not open public issues for vulnerabilities.
