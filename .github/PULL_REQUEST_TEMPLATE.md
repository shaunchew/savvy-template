## What

<!-- One-paragraph summary of the change -->

## Why

## Checklist

- [ ] `bash tests/run.sh` passes locally
- [ ] New/changed behavior in `scripts/`, `hooks/`, or `migrations/` has test coverage
- [ ] Ran `bash scripts/build-plugin.sh` and committed regenerated `template/` + `skeleton/` + manifest (if the engine payload changed)
- [ ] `CHANGELOG.md` updated under `[Unreleased]`
- [ ] No new runtime dependencies beyond `git` + `jq`; bash 3.2 compatible
