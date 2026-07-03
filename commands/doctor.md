---
description: Read-only health check of the framework installation in this project — plugin state, settings integrity, hook wiring, version alignment, coexistence and leftover-file detection. Changes nothing.
argument-hint: ""
---

# /sf:doctor

Diagnose the framework installation in the current project without changing a single byte.

Run the bundled checker and show the user its full output:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/sf-doctor.sh"
```

It reports, line by line:

- **toolchain** — `jq` / `git` availability.
- **adoption state** — `.claude/config.toml` `[framework]` marker and version.
- **settings integrity** — valid JSON, `sf@savvy` enabled, secret-scan floor guard wired *and* executable, symlink hazards.
- **engine alignment** — which engine version is serving the session vs. the project's recorded floor.
- **coexistence** — in-tree engine remnants that would make hooks double-fire (fix: `/sf:adopt`).
- **leftovers** — legacy baseline manifest (upgrade-resurrection risk), unreconciled `*.savvy-new` files, quarantine dirs awaiting review, `settings.json.savvy-old` backups.
- **git protection** — repo present, `.claude/` not gitignored.

Exit code 0 means healthy (warnings allowed); 1 means problems were found.

After showing the output, briefly explain any `FAIL`/`WARN` lines in plain language and offer the one-line fix for each (most map to `/sf:adopt`, `chmod +x`, or deleting reviewed leftovers). Do NOT apply fixes without the user's confirmation — this command's contract is read-only.
