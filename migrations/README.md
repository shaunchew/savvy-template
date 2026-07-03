# Migrations

Shape A migration scripts: per-patch idempotent fixes that already-scaffolded projects can pull and apply without relying on `copier update` or `.copier-answers.yml`.

## Relationship to `/sf:upgrade` (since v1.4.0)

As of v1.4.0 the primary update path is **`/sf:upgrade`**, driven by the ownership manifest (`.claude/.savvy-manifest.json`). It handles the common cases automatically by content hash: adding new framework files and refreshing unmodified `managed` files, while never touching `seeded` project data and never silently overwriting framework files you edited.

Migration scripts here are now reserved for genuine **transforms** that a file-replace cannot express — e.g. rewriting the shape of an existing `settings.json` hook (`v1.0.1.sh`) or removing orphaned files left by a rename (`v1.3.0.sh`). `/sf:upgrade` discovers in-range scripts and runs them as the final step of an upgrade. They remain runnable standalone via the `curl | bash` one-liner for projects not using `/sf:upgrade`.

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

Migration scripts are **frozen artifacts**: each is pinned to the immutable release
tag it belongs to, never `main`. A later phase of the distribution rearchitecture
removes `template/` from `main`, so a `main`-pinned `curl` would break permanently.
Fetch each migration from its own tag (`v<version>`):

```bash
curl -fsSL https://raw.githubusercontent.com/shaunchew/savvy-template/v<version>/migrations/v<version>.sh | bash
```

Or download first if you want to read before running:

```bash
curl -fsSL https://raw.githubusercontent.com/shaunchew/savvy-template/v<version>/migrations/v<version>.sh -o /tmp/migrate.sh
less /tmp/migrate.sh   # inspect
bash /tmp/migrate.sh
```

## Catalogue

| Version | What it fixes |
|---|---|
| `v1.0.1.sh` | Wraps `.claude/settings.json` `Stop` hook in the `{matcher, hooks: [...]}` envelope. Fixes Claude Code's `hooks › Stop › 0 › hooks: Expected array, but received undefined` validation error. |
| `v1.3.0.sh` | Removes orphaned flat `.claude/commands/*.md` files left behind after commands moved into the namespaced `.claude/commands/sf/*.md` (invoked as `/sf:<name>`). Run after `copier update`. |
| `v1.4.0.sh` | Bootstraps a pre-v1.4.0 project onto the manifest-driven upgrade system: installs `/sf:upgrade` (command + skill) and the ownership baseline manifest matching the project's current version (from `migrations/baselines/`). After this, use `/sf:upgrade` for all future updates. |

## Baselines (`migrations/baselines/`)

`baselines/v<tag>.json` are retroactive `.savvy-manifest` snapshots of shipped releases that predate the manifest system, named by **git tag** and hashed straight from the tagged `template/` tree (`scripts/gen-baseline-from-tag.sh v<tag>` — reads the tag, no checkout; policy classification stays in sync with `gen-manifest.sh`). The full set is committed: `v1.0.0`, `v1.0.1`, `v1.1.0`, `v1.2.0`, `v1.3.0`, `v1.4.0`. Going forward every release ships its manifest in-tree, so no new baselines are needed.

The `v1.4.0.sh` bootstrap installs the baseline matching a project's current version so the first `/sf:upgrade` can distinguish "framework file you never edited → safe to refresh" from "framework file you edited → conflict."

**Stamp → baseline tag mapping.** Pre-v1.4.0 `config.toml` version stamps are *coarse* and do not match baseline filenames one-to-one — several tags share a stamp. `v1.4.0.sh` maps the recorded stamp to a git tag, picking the **oldest** tag for a shared stamp (its baseline treats more files as possibly-edited → conflict, which is the conservative, safe lean):

| `config.toml` stamp | tags carrying it | baseline installed |
|---|---|---|
| `1.0` | v1.0.0, v1.0.1, v1.1.0 | `v1.0.0.json` (oldest) |
| `1.1` | v1.2.0 | `v1.2.0.json` |
| `1.3` | v1.3.0 | `v1.3.0.json` |
| `1.4.0` | v1.4.0 | `v1.4.0.json` |

An unrecognized stamp installs no baseline and `/sf:upgrade` runs in conservative mode. Because `v1.4.0.sh` fetches baselines from the pinned `v1.4.0` tag, that tag's `migrations/baselines/` tree must carry every baseline the mapping can name; a missing one degrades gracefully to conservative mode (safe, never overwrites).

## Authoring a new migration

When adding `vX.Y.Z.sh`:

1. Copy an existing script as a template — match the header block + idempotency pattern.
2. Test on a fresh scaffold AND on a scaffold that has already been migrated (must be a no-op).
3. Add a row to the catalogue table above.
4. Reference the migration in the GitHub release notes for that version.

## Trade-offs (recorded for memory)

Shape A was picked over Shape B (full migration framework with state tracking) in v1.0.2. Promote to Shape B if the manual run-this-script UX starts to bite — likely after ~4 patches accumulate.

Each script is more code than the underlying fix; that's the cost. The benefit is that users don't need to know which file or syntax to edit — they paste a one-liner.
