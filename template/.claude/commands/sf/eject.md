---
description: Cleanly remove the framework from this project — the mirror image of /sf:adopt. Unedited seeded files are quarantined (never deleted), files you edited are kept, and the plugin is disabled at project scope.
argument-hint: "[--yes] [--restore-settings]"
---

# /sf:eject

Reverse an adoption. The same safety contract as `/sf:adopt`, applied in the other direction: **nothing is deleted, your edits are never touched.**

Before running, confirm with the user that they want to remove the framework from this project (this is an intentional, explicit action — never run it speculatively).

Then run the bundled script, passing `$ARGUMENTS` through:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/sf-eject.sh" $ARGUMENTS
```

What it does:

1. Refuses a dirty git tree without `--yes` (so the eject is one revertible commit).
2. Disables `sf@savvy` in `.claude/settings.json` and strips the secret-scan floor wiring. Framework `permissions.deny` rules are left in place (they are harmless protections) — mention they can be removed by hand. With `--restore-settings`, the pre-adopt `settings.json.savvy-old` is restored instead.
3. Moves every seeded file that is **still byte-identical to what adopt seeded** into a `.claude/.savvy-detached-<timestamp>/` quarantine. Any seeded file the user edited is **kept** and listed.
4. Removes the framework's work dirs (`specs/`, `docs/`, `scratchpads/`) only if empty.

Afterwards, relay the script's report to the user, including:
- the quarantine path (review, then delete),
- any kept files (their edits — theirs to keep or remove),
- the note about `.claude/config.toml` if it was kept (hooks stay dormant-gated on it),
- the final step they may want: `/plugin uninstall sf@savvy`.
