# Migrations

Shape A migration scripts: per-patch idempotent fixes that already-scaffolded projects can pull and apply without relying on `copier update` or `.copier-answers.yml`.

## When a migration ships

Every release that changes framework-managed files in a way that affects existing projects ships a corresponding script here. Releases that only change scaffold behavior (e.g., post-copy task messages) do not need one — they take effect at the next scaffold.

## Contract for migration scripts

Every script in this directory MUST be:

1. **Idempotent.** Safe to re-run. If the project is already migrated, exit 0 with a "no change" message.
2. **Standalone.** No dependency on `.copier-answers.yml`, `copier`, or any local framework state beyond the files being migrated.
3. **Scoped.** Each script fixes one release worth of drift. Do not bundle unrelated fixes.
4. **Self-describing.** Header comment block must include: what release it patches, what files it touches, the one-line `curl | bash` invocation, and a description of the change.
5. **Loud.** Print every change to stderr, prefixed with the script name.
6. **Resilient.** Detect missing files / tools gracefully — exit non-zero with a clear error message.

## Usage from a project root

```bash
curl -fsSL https://raw.githubusercontent.com/shaunchew/savvy-template/main/migrations/<version>.sh | bash
```

Or download first if you want to read before running:

```bash
curl -fsSL https://raw.githubusercontent.com/shaunchew/savvy-template/main/migrations/<version>.sh -o /tmp/migrate.sh
less /tmp/migrate.sh   # inspect
bash /tmp/migrate.sh
```

## Catalogue

| Version | What it fixes |
|---|---|
| `v1.0.1.sh` | Wraps `.claude/settings.json` `Stop` hook in the `{matcher, hooks: [...]}` envelope. Fixes Claude Code's `hooks › Stop › 0 › hooks: Expected array, but received undefined` validation error. |

## Authoring a new migration

When adding `vX.Y.Z.sh`:

1. Copy an existing script as a template — match the header block + idempotency pattern.
2. Test on a fresh scaffold AND on a scaffold that has already been migrated (must be a no-op).
3. Add a row to the catalogue table above.
4. Reference the migration in the GitHub release notes for that version.

## Trade-offs (recorded for memory)

Shape A was picked over Shape B (full migration framework with state tracking) in v1.0.2. Promote to Shape B if the manual run-this-script UX starts to bite — likely after ~4 patches accumulate.

Each script is more code than the underlying fix; that's the cost. The benefit is that users don't need to know which file or syntax to edit — they paste a one-liner.
