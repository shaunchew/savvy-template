# Phase 0 Gate — Plugin Distribution PROVE Step

Status: **BLOCKING GATE**. Phase 1 (authorship inversion) MUST NOT begin until this
gate returns GO. Nothing is deleted in Phase 0 — this step only *proves* that the
out-of-tree plugin mechanism works end to end on a throwaway repo.

Plan reference: "THE LOCKED PLAN (savvy-framework distribution rearchitecture, 2026-06-15)",
Phase 0 + the 13 amendments + the 11-row Phase 0 matrix.

---

## Goal of the gate

Prove, with reproducible commands, that the Savvy engine can ship **solely as a Claude
Code plugin installed out-of-tree** and that this kills update-fear by **location**
(engine lives in `~/.claude/plugins`, structurally unable to touch project files) and by
**explicit-version gating** (a `/plugin update` is a no-op unless the version string
changes). The gate must produce a result that can be trusted to *license the eventual
destructive Phase 3 cutover* — therefore false-greens (empty plugin, env-var-dependent
hooks that silently no-op, latent double-fire) are treated as gate failures, not warnings.

The gate is GO only when all of the following are demonstrated on real installs:

1. The plugin **installs via the real marketplace-mediated flow** (there is no `gh:`
   install path — that premise in early drafts is false; see preconditions).
2. A **fresh clone ships a non-empty payload** and skills load at discoverable depth.
3. Commands and skills **resolve under `/sf:`**, not `/savvy-framework:`, with no
   double-prefix.
4. **All 5 hooks fire** (SessionStart, PreToolUse, PostToolUse, Stop, SessionEnd),
   **exactly once on a bare repo**, and survive `CLAUDE_PLUGIN_ROOT` being unset.
5. **Updates are version-gated** (the actual immunity mechanism), with the double-fire
   coexistence hazard empirically confirmed so Phase 2's atomic detach is justified.

---

## Preconditions (must be true before running the matrix)

These are the verified-against-repo blockers. The matrix is meaningless until they are
addressed, because without them the install either fails outright or produces a
false-green (empty / mis-namespaced / double-firing plugin).

- [ ] **P0-1 marketplace.json exists.** Author `.claude-plugin/marketplace.json` at repo
  root with a non-reserved marketplace name (`savvy`), `owner.name`, and
  `plugins: [{ "name": "sf", "source": "." }]`. **There is no `/plugin install gh:...`
  path** in Claude Code — installation is marketplace-mediated only. The real flow is
  `/plugin marketplace add shaunchew/savvy-template` then `/plugin install sf@savvy`.
  *Confirmed in repo: no marketplace.json is tracked (only `plugin.json` and
  `.savvy-manifest.json`).*
- [ ] **P0-2 plugin name is `sf`.** Change `plugin.json` `name` from `savvy-framework`
  to `sf`; add `displayName: "Savvy Framework"`. With the wrong name the namespace
  resolves as `/savvy-framework:`, defeating the locked `/sf:` decision.
  *Confirmed in repo: `plugin.json` name is still `savvy-framework`.*
- [ ] **P0-3 non-empty, git-tracked payload.** Remove `.gitignore` lines 17–20
  (the four `.claude-plugin/{skills,commands,hooks,agents}/` ignore rules) AND commit a
  real engine payload (bring Phase 1 inversion forward enough that committed files are
  the source of truth, *or* commit build-output). All four engine dirs must be
  git-tracked with actual files. *Confirmed in repo: those four dirs are gitignored and
  comment-marked "generated"; a marketplace clone would ship an EMPTY plugin.*
- [ ] **P0-4 skills at discoverable depth.** Either flatten to `skills/<name>/SKILL.md`
  (drop the `_framework/` wrapper) OR set `plugin.json` `skills: ["./skills/_framework/"]`
  to point the scanner at the wrapper. *Confirmed in repo: skills are nested one level
  too deep under `_framework/`, so zero skills load by default.* Also `chmod +x` every
  committed hook script and strip the 0-byte `.gitkeep` from `agents/`.
- [ ] **P0-5 hooks.json with self-locating commands.** Author `.claude-plugin/hooks/hooks.json`
  covering 4 events (PreToolUse:Bash→secret-scan; PostToolUse:Edit|Write→format +
  bloat-check; SessionStart→session-start; Stop→session-end). Every command must
  **self-locate its own directory via an inline `$0`/`BASH_SOURCE` resolver**, with
  `${CLAUDE_PLUGIN_ROOT:-<fallback>}` only as a defensive belt — do **not** trust the
  bare env var. *Confirmed upstream (anthropics/claude-code #42564 / #27145 / #9447):
  `CLAUDE_PLUGIN_ROOT` is intermittently unset for SessionStart/PreToolUse/PostToolUse/
  PreCompact — exactly the events this gate must prove.* Use quoted exec-form commands to
  tolerate spaces. The 5 hook scripts currently live only in `template/.claude/hooks/`.
- [ ] **P0-6 explicit semver set, never duplicated.** `plugin.json` must carry an
  explicit `version` (already `1.4.0` — keep it). Never also put the version in the
  marketplace entry (plugin.json wins silently and masks a stale marketplace version).
  Commit-SHA / per-commit publishing is FORBIDDEN (Safety Invariant #6).
- [ ] **Environment**: a clean machine (or fresh `~/.claude`), a target Claude Code
  version supporting plugins + `hooks.json`, and a local clone path for the marketplace
  add. T5 additionally requires one Linux host alongside macOS.

---

## Test matrix

| ID | What it proves | Steps | Pass criteria | Fail fallback |
|----|----------------|-------|---------------|---------------|
| **T1 — install** | Plugin installs via the REAL marketplace flow (no `gh:` path) and is enabled. | From a clean machine, from the local clone path run `/plugin marketplace add <clone path>`, then `/plugin install sf@savvy`. Run `/plugin list` and `claude plugin details sf`. | `marketplace add` succeeds with no reserved-name/collision error; install succeeds; `/plugin list` shows `sf` **ENABLED**; `details` renders. | If marketplace.json absent or install errors → gate FAILS hard. Author marketplace.json (non-reserved name `savvy`) + set plugin.json name `sf`. No downstream test is meaningful until this passes. |
| **T2 — non-empty clone** | A fresh git clone ships a NON-EMPTY payload (empty-plugin bug dead) and skills are discoverable. | `git clone` repo into `/tmp`. Run `git ls-files .claude-plugin/ \| grep -c SKILL.md` and inspect `/tmp` clone `.claude-plugin/{skills,commands,hooks,agents}/`. After install, check `claude plugin details sf` skills inventory. | SKILL.md count > 0; all four engine dirs in the fresh clone non-empty; details lists all 11 skills by name (bloat-watcher, framework-curator, …); count == expected. | If clone empty → remove `.gitignore` 17–20 and commit real files. If skills missing → flatten to `skills/<name>/SKILL.md` or set `skills: ["./skills/_framework/"]`. |
| **T3 — `/sf:` namespace** | Commands + skills resolve under `/sf:`, not `/savvy-framework:`, with no double-prefix. | After install, list commands. Invoke `/sf:ship` (or any command) and at least one skill. Confirm `/savvy-framework:*` does not exist. Check `commands/sf/ship.md` does not resolve as `/sf:sf:ship`. | `/sf:ship` resolves; ≥1 `/sf:` skill resolves; `/savvy-framework:*` absent; no `/sf:sf:` double-prefix. | Set plugin.json name `sf`. If `commands/sf/` subdir double-namespaces in this CC version, move command files up one level out of the `sf/` subdir. |
| **T4 — 5 hooks fire (bare repo)** | All 5 hook events fire EXACTLY ONCE on a bare repo (no in-tree settings.json hooks) — plugin contributes hooks, nothing is masked. | On a bare throwaway repo with NO in-tree settings.json hooks: open a new session (**SessionStart**); edit a file (**PostToolUse** format+bloat); run a Bash cmd containing an `AKIA…` pattern (**PreToolUse** secret-scan); end a turn (**Stop**); close/exit the session (**SessionEnd**). Inspect `claude --debug` hook-registration; grep stderr for the version banner and count. | Each of the 5 events observed firing; banner count == 1; secret-scan blocks with **exit 2**; no `MODULE_NOT_FOUND` or `/hooks/x.sh` path error in `--debug`. | Author/repair `hooks/hooks.json` with self-locating (`$0`/`BASH_SOURCE`) commands. If any event silent, fix that hook's resolver. |
| **T5 — hooks survive env unset** | Hooks survive the confirmed `CLAUDE_PLUGIN_ROOT`-unset bug — they self-locate and do not depend on the env var. | Run each hook script directly with `CLAUDE_PLUGIN_ROOT` explicitly **unset**. Also run the full install+fire test on BOTH macOS and one Linux to catch intermittency. | Every hook self-locates and runs with the var both SET and UNSET, on both OSes — no `/hooks/x.sh MODULE_NOT_FOUND`. | If any hook fails with the var unset, rewrite its command to inline-resolve via `$0`/`BASH_SOURCE` (or `${CLAUDE_PLUGIN_ROOT:-<fallback>}`). **BLOCKING sub-requirement, not Phase 2 polish.** |
| **T6 — double-fire proof** | The coexistence double-fire hazard is REAL (must be gated, not assumed away) — establishes the empirical basis for Phase 2 atomic detach. | On a SECOND repo that carries the in-tree seeded `settings.json` hooks, install the plugin. Grep stderr for the SessionStart banner and count; observe secret-scan/format firing counts. | Banner appears **TWICE** (double-fire confirmed). This is an expected/diagnostic pass — it proves the hazard and validates `/sf:adopt` atomic detach + coexistence warning. | If it does NOT double-fire, investigate dedup in the target CC version and document; the coexistence rule may relax, but default remains "gate it". |
| **T7 — coexistence warning** | The session-start coexistence detector (shipped from Phase 0) warns when both engines are live. | With the plugin installed on the repo that still has the in-tree engine, open a new session. | A single loud non-blocking warning naming the double-load and directing the user to run `/sf:adopt` (detach). No spurious "/sf:upgrade available" remote nudge. | Add/repair the coexistence branch in session-start; strip the remote-manifest curl nudge. |
| **T8 — version gate** | Updates are version-GATED (not latest-wins): no version bump ⇒ no update; bump ⇒ update. Settles the version-pinning question; validates Safety Invariant #6. | Install `sf` at version X. Push a commit changing a skill but NOT the version; in the installed project run `/plugin update sf`. Then bump `plugin.json` version and run `/plugin update sf` again. Also restart Claude (startup auto-update) after a non-bumped commit. | First update reports "already at latest" and the skill change is NOT picked up; restart does NOT change the engine while version unchanged; after the bump, update applies the change. | If a non-bumped commit is picked up, the plugin is in SHA/commit mode → ensure explicit version is set in `plugin.json` and NOT duplicated in the marketplace entry. |
| **T9 — sha-pin freeze** | A HARD freeze via `source.sha` on the plugin entry holds across a later update (definitive per-project pin). | Craft a marketplace.json plugin entry with `source.sha` = an OLD commit and version pinned. Install it. Run `claude plugin list`. Bump and attempt `/plugin update sf`. | `plugin list` shows the old version; later `/plugin update` does NOT advance it (sha pin holds). | Document as advisory only if sha-pin behaves unexpectedly; the default explicit-semver opt-in model (T8) remains the primary guarantee. |
| **T10 — project scope** | Engine enablement can be PROJECT-scoped and git-tracked (contradicting the user-scope-only premise) — engine travels with the repo, does not leak to other dirs. | Run `claude plugin install sf@savvy --scope project`. Confirm `enabledPlugins` appears in `./.claude/settings.json` (NOT `~/.claude/settings.json`). Start Claude from a DIFFERENT directory. | `enabledPlugins` is in the project `.claude/settings.json`; `sf` commands NOT loaded when started from the other directory. | If TUI can't set project scope post-install, document editing `.claude/settings.json` directly; `/sf:adopt` writes it programmatically. |
| **T11 — name stability** | `/sf:` command/skill names are frontmatter-driven and STABLE across a version bump (not directory/version-driven). | After install, `claude plugin list` and record command/skill names. Bump version, `/plugin update`, re-list. | All `/sf:` command and skill names UNCHANGED after the version bump. | If any name changed, add explicit frontmatter `name` to the offending SKILL.md/command; add the release-gate check that fails the build on a missing name. |

---

## Gate decision rule

**Proceed to Phase 1 only if ALL of the following hold:**

- **T1, T2, T3 — PASS (hard).** Install works via the real marketplace flow, the clone
  payload is non-empty with all skills at discoverable depth, and everything resolves
  under `/sf:` with no double-prefix. Any failure here = the plugin is empty,
  uninstallable, or mis-namespaced → **NO-GO**.
- **T4 + T5 — PASS (hard).** All 5 hooks fire exactly once on a bare repo AND survive
  `CLAUDE_PLUGIN_ROOT` being unset on both macOS and Linux. A hook that only works while
  the env var happens to be set is a **false-green** and is treated as a failure, because
  it would license the destructive Phase 3 on a lie. Any silent/missing event or
  env-dependent hook → **NO-GO**.
- **T8 — PASS (hard).** Updates are version-gated: a non-bumped commit is a no-op, a bump
  applies. This is the actual mechanism that makes a v1.4 project immune to a v2.0 update.
  If a non-bumped commit is picked up (SHA mode) → **NO-GO** until explicit semver gating
  is restored.
- **T6 — DIAGNOSTIC PASS REQUIRED.** Double-fire must be *observed* (banner twice). This
  is a confirming pass, not a failure: it supplies the empirical basis for the Phase 2
  atomic-detach amendment. If double-fire is NOT observed, do not silently proceed —
  document the dedup behavior and keep "gate it" as the default before continuing.
- **T7 — PASS.** The session-start coexistence detector emits exactly one loud warning
  and no stale remote nudge.

**Advisory (record results; do not block on these):**

- **T9 (sha-pin), T10 (project scope), T11 (name stability).** These strengthen the
  pinning story and confirm the project-scope option. Failures here are documented as
  recipe caveats and folded into Phase 2 deliverables (`/sf:adopt` writing project-scope
  `enabledPlugins`, the frontmatter-`name` release-gate check) — they do not by
  themselves block Phase 1, **except** that if T11 reveals names change on version bump,
  the frontmatter-`name` fix becomes a Phase 1 prerequisite.

**Decision summary:** GO requires `T1∧T2∧T3∧T4∧T5∧T8∧T7` PASS and `T6` diagnostic-confirmed.
Any single hard failure = **NO-GO**.

---

## If the gate fails

Phase 0 is non-destructive by design — a failed gate strands nothing, because **nothing
has been deleted and no project that does not install the plugin has changed behavior.**
The fallback path is:

1. **Do not advance to Phase 1.** Authorship inversion and any deletion stay frozen. The
   existing four distribution mechanisms (Copier, current plugin shape, sha256-manifest
   `/sf:upgrade`, migration scripts) remain the supported path; nothing about them is
   touched.
2. **Fix forward against the specific failing row.** Each matrix row carries its own
   "Fail fallback" remedy. The common roots, in priority order: (a) author
   `marketplace.json` with non-reserved name `savvy` (T1); (b) un-gitignore + commit a
   real payload, flatten skills (T2); (c) set plugin name `sf` (T3); (d) author
   `hooks/hooks.json` with self-locating `$0`/`BASH_SOURCE` resolvers and re-test with the
   env var UNSET (T4/T5); (e) ensure explicit semver in `plugin.json` only (T8).
3. **Re-run the full matrix from T1.** Do not partially re-run — an install-level fix can
   invalidate earlier passes. The gate is only meaningful as a clean end-to-end pass on a
   fresh `~/.claude` / throwaway repo.
4. **Redefine "non-destructive" behaviorally if needed.** Because plugin and in-tree
   hooks MERGE (T6), an early install changes runtime behavior (double-fire) even with
   zero files deleted. If this is disruptive during iteration, ship the plugin with
   `defaultEnabled: false` (CC v2.1.154+) so an early install does not auto-activate hooks
   until the user opts in post-adopt.
5. **Escalate only structural impossibilities.** If a target-CC-version behavior makes a
   hard requirement unachievable (e.g. `/sf:` namespace cannot be made stable, or
   version-gating cannot be enforced), that is a plan-level finding — re-open the
   architecture decision rather than working around it, since these are the premises the
   destructive Phase 3 depends on.
