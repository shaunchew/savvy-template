# savvy-framework — Constitution

Non-negotiable principles for this project. Edit deliberately; treat as load-bearing.

## Architecture invariants

- Engine-as-plugin: the engine lives out-of-tree in the plugin cache; adopted projects hold only seeds, settings, and the `[framework]` marker. Engine updates are version-gated `/plugin update` and can never touch project files.
- Single authored source: the repo root payload → `template/` (legacy mirror) and `skeleton/` (adoption seed) are build outputs of `scripts/build-plugin.sh`, with the manifest generated AFTER template regeneration (ordering matters).
- Upgrades are manifest-driven with sticky `"conflict": true` markers — an unresolved conflict is never refresh-eligible; "keep mine" never clears it.

## Quality gates

- `bash tests/run.sh` green on macOS system bash AND Linux before any commit to main.
- CI drift gate: regenerated `template/` + `skeleton/` + manifest must match the committed artifacts.
- Release gate (`release.yml`): tag ↔ VERSION ↔ plugin.json ↔ CHANGELOG agreement, full suite, drift check — a tag that fails does not release.
- Any behavior change in `scripts/`, `hooks/`, or `migrations/` ships with a regression test.

## Security posture

- The secret-scan hook blocks credential-leaking Bash commands in every project (it blocks secrets and nothing else — it never touches files).
- All other hooks are least-privilege: no-op unless the project carries the `[framework]` adoption marker.
- No secret-shaped literals in the repo, ever — fixtures are runtime-assembled.

## Non-negotiable conventions

- Quarantine, never delete: detach and eject move files to `.claude/.savvy-detached-<ts>/`. Deleting by name-match is forbidden.
- Seeding is create-if-absent; settings merges are additive with a keep-first `.savvy-old` backup.
- bash 3.2 compatibility; zero dependencies beyond git + jq.
