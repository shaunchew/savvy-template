# Distribution Rearchitecture — Stress-Test Findings

_Date: 2026-06-15 · Subject: savvy-framework plugin-as-engine distribution rearchitecture (Phases 0–3) · Four adversarial red-team lenses + consolidated amendments._

## Summary & Verdict

The strategic architecture — relocate the engine OUT of the project tree and ship it as a Claude Code plugin so updating it is structurally incapable of touching project files — **survives all four red-team lenses and is the correct way to kill update-fear.** The Claude Code docs confirm every capability the plan needs exists. **However, Phase 0 as written does NOT survive** and must be re-scoped before any work begins. The locked plan rests on two false premises corrected here as architecture (not preference): (1) there is **no `gh:` install path** — distribution is marketplace-mediated (`/plugin marketplace add` + `/plugin install sf@savvy`), and the repo today has no `marketplace.json`, a gitignored/empty payload, the wrong plugin name (`savvy-framework`), and skills nested one level too deep; (2) plugins are **not** user-scope-only-latest-wins — a real git-tracked PROJECT scope exists and updates are **version-GATED** when an explicit semver is set, which is the actual mechanism (not a diff engine) that makes a v1.4 project immune to a v2.0 update.

**GO / NO-GO: PROCEED WITH AMENDMENTS.** With the 13 ranked amendments and the 11-row Phase 0 gate matrix applied, the plan is GO. **Without P0 items 1–5 it is a NO-GO** because Phase 0 would produce an empty or double-firing plugin and a false-green gate that would license the destructive Phase 3 cutover.

Update-fear is killed by **LOCATION** (engine out-of-tree) **AND** by explicit-**version GATING**, with sha-pin and a session-start floor-warning as belt-and-suspenders.

---

## Severity-Ranked Findings

| Lens | Severity | Finding | Evidence | Amendment |
|---|---|---|---|---|
| Plugin Mechanism | **FATAL** | No `/plugin install gh:...` path exists; install is marketplace-mediated two-step and repo has **no `marketplace.json`** → nothing installs. | Docs: install is `/plugin marketplace add owner/repo` (repo must contain `.claude-plugin/marketplace.json`) then `/plugin install name@marketplace`. `find . -name marketplace.json` → none. | P0-1 |
| Plugin Mechanism | **FATAL** | Payload is **gitignored** (`.gitignore` 17-20) → a marketplace clone fetches an EMPTY plugin. | `git ls-files .claude-plugin/` returns only `plugin.json` + `.savvy-manifest.json`. Marketplace installs clone git; untracked files don't ship. | P0-2 |
| Plugin Mechanism | **FATAL** | Plugin name still `savvy-framework` → commands resolve as `/savvy-framework:*`, NOT `/sf:*`, defeating the locked namespace decision. | `plugin.json` `"name":"savvy-framework"`. Docs: components are namespaced by the plugin manifest `name`. | P0-1 |
| Plugin Mechanism | **FATAL** | Skills nested one level too deep under `_framework/` → loader scans `skills/<name>/SKILL.md`, finds no SKILL.md in `_framework/`, loads ZERO skills. | `find … -name SKILL.md` → all under `skills/_framework/<skill>/SKILL.md`. | P0-2 |
| Sequencing | **FATAL** | Plugin + in-tree `settings.json` hooks **MERGE and both fire**; deduped only by exact command-string match. `${CLAUDE_PLUGIN_ROOT}/hooks/x.sh` ≠ `.claude/hooks/x.sh` → guaranteed **double-fire** (banner ×2, secret-scan ×2, format+bloat ×2 with possible contradictory exit-2) for every existing v1.0–v1.4 project that installs the plugin pre-cutover. | Hooks-guide docs: array fields concatenated+deduped, command hooks deduped by command string. Repo `settings.json` registers all 5 via relative paths. | P0-5 |
| Sequencing | **FATAL** | Phase 0 exit gate leans on bare `${CLAUDE_PLUGIN_ROOT}`, which is **intermittently UNSET** for SessionStart/PreToolUse/PostToolUse/PreCompact — 4 of the 5 hooks the gate must prove → false-green gate risk. | anthropics/claude-code #42564 (closed not-planned), #27145, #9447. Stop/SessionEnd protected via inline resolver. | P0-3 |
| Cutover | **FATAL** | Orphan-by-ordering: migration can delete in-tree engine while the `sf` plugin is NOT installed (curl\|bash standalone path structurally cannot verify presence) → project left with zero engine. | `framework-upgrade/SKILL.md` runs migrations last, resolvable from remote; `migrations/README.md` curl\|bash. No precondition enforces plugin presence. | P1-4 |
| Cutover | **FATAL** | No usable baseline coverage: only v1.1/v1.2/v1.3 baselines exist on disk; v1.0 ambiguous, v1.4 absent → hash gate degrades to `.savvy-old` for the majority, leaving manifest/settings pointing at deleted paths (hooks silently fail). | `ls migrations/baselines/` → only v1.1.0/v1.2.0/v1.3.0. `v1.0.1.sh` shows v1.0 had a different hook shape. | P1-5 |
| Version-Pinning | **HIGH** | Locked premise is wrong (in a good way): real PROJECT scope exists (`.claude/settings.json` `enabledPlugins`, git-tracked) and updates are **version-GATED** when explicit `version` set. | Docs: install scopes table; version resolution = plugin.json → marketplace entry → git SHA; update skips if resolved version unchanged. `plugin.json` already sets `1.4.0`. | P0-4 |
| Version-Pinning | **HIGH** | True silent-drift vector is **background auto-update at startup**, neutralized only by explicit-version gating; there is **no clean per-plugin auto-update off switch**. | Docs: "Background auto-updates run at startup." `DISABLE_AUTOUPDATER`/`autoUpdatesChannel` govern the CC binary, not plugins. | P0-4 |
| Sequencing | **HIGH** | Deleting `template/` engine in Phase 1 **strands legacy projects**: `v1.4.0.sh`, baselines fetch, and `update_nudge` all curl `…/main/template/.claude/*` raw URLs. | `v1.4.0.sh` hardcodes `RAW=…/main/template`; `session-start.sh` curls `…/main/template/.claude/.savvy-manifest.json`. | P1-1 |
| Sequencing | **HIGH** | Phase 0 is not behaviorally non-destructive: un-gitignoring payload + `marketplace.json` makes repo installable; an existing user's `/plugin install` changes runtime behavior (double-fire) with zero files deleted. | `.gitignore` 17-20; additive hook-merge semantics. | P1-2 |
| Cutover | **HIGH** | `settings.json` hook-strip can't whole-file hash-gate (file is `merge` policy, users add own hooks/permissions); naive jq strip misses entries or deletes user-co-owned arrays; floor secret-scan may not be re-seeded. | `gen-manifest.sh` classifies `settings.json` as `merge`. Invariants #3/#4. | P1-3 |
| Cutover | **HIGH** | Non-idempotent / partial-application: delete-dirs-then-rewrite-settings is not atomic; a mid-run failure leaves engine deleted but settings wired to dead paths. `v1.3.0.sh` deletes by name (`rm -f`, no hash gate) — the anti-pattern Invariant #5 must fix. | `migrations/README.md` idempotency contract; `v1.3.0.sh` rm-by-name. | P1-3 |
| Cutover | **HIGH** | Git-guard gaps: `git reset --hard` cannot restore gitignored/untracked deletions; non-git projects have only `.savvy-old`; curl\|bash + CI are non-interactive → destructive run with no confirmation. | `git reset` semantics; repo's own `.gitignore` ignores engine dirs; standalone path is non-interactive. | P1-3 |
| Plugin Mechanism | **MED** | `permissions.deny` cannot be carried by the plugin (plugin `settings.json` supports only `agent`/`subagentStatusLine`). Plan already routes it through seeded skeleton — validates Invariant #3. | Docs: plugin settings.json supported keys. | (none — already handled) |
| Plugin Mechanism | **MED** | Agents dir has a stray 0-byte `.gitkeep`; plugin agents reject `hooks`/`mcpServers`/`permissionMode` frontmatter for security. | `ls .claude-plugin/agents` → 3 `.md` + `.gitkeep`. Docs: forbidden agent frontmatter keys. | P2-1 |
| Plugin Mechanism / Sequencing | **MED** | `session-start.sh` forks a background curl to a hardcoded raw URL (old distribution path) → stale `/sf:upgrade` nudges that contradict the `/plugin update` story; breaks when manifest deleted in Phase 3. | `session-start.sh` `update_nudge()` curls `…/main/template/.claude/.savvy-manifest.json`. | P1-6 |
| Version-Pinning / Cutover | **MED** | Cross-project drift: a manual `sf` plugin update to v2.0 moves ALL projects at once; pre-cutover projects double-load both engines. | Docs: plugins user-scoped, no auto-run of migration, but manual update is global. | P1-6 |
| Cutover | **MED** | Version-parse fragility: `grep '^version' config.toml \| sed` is TOML-section-unaware → reformatted TOML silently yields wrong/empty version → wrong baseline → wrong delete set. | `v1.4.0.sh` + `session-start.sh` use column-0 grep, no `[framework]` awareness. | P1-5 |
| Cutover | **MED** | Hand-edited engine files & user-authored custom files in engine dirs orphaned/lost if cutover `rm -rf`s a dir. | `gen-manifest.sh` manifest lists only framework files; `v1.3.0.sh` narrow twin-check is the safe pattern. | P1-3 |
| Sequencing | **MED** | Duplicate `/sf:` COMMAND collision (in-tree folder-namespaced vs plugin name-namespaced) behavior is unverified — may error, shadow, or list twice. | 28 files under both `commands/sf/`; docs don't authoritatively state collision behavior. | P0-5 (atomic detach eliminates window) |
| Cutover | **MED** | `settings.json` strip risks reintroducing the v1.0.1 bare-Stop crash if it leaves the file in a malformed shape. | `v1.0.1.sh` exists solely to repair a malformed Stop-hook envelope. | P1-3 |
| Version-Pinning / Sequencing | **LOW** | Mid-session updates non-atomic: hooks/monitors/MCP keep OLD `${CLAUDE_PLUGIN_ROOT}` until `/reload-plugins`; old dir lingers ~7 days. | Docs: `${CLAUDE_PLUGIN_ROOT}` changes on update; run `/reload-plugins`. | P2-2 |
| Version-Pinning | **LOW** | Skill/command name stability: without frontmatter `name`, CC falls back to the install-dir name (a version string that changes per update) → `/sf:` names could rename across versions. | Docs: fallback to install directory name for marketplace plugins. | P2-1 |
| Version-Pinning | **LOW** | Marketplace name must be non-reserved and not collide (adding a second with same name replaces the first). | Docs: marketplace `name` required, kebab-case, reserved-names list. | P0-1 (use `savvy`) |
| Sequencing | **LOW** | Plugin cache caveat: do not write persistent state to `CLAUDE_PLUGIN_ROOT` (updates replace the dir); current hooks write to project `.claude/` (fine), but `update_nudge` becomes redundant/conflicting. | Docs: use `CLAUDE_PLUGIN_DATA`, not `CLAUDE_PLUGIN_ROOT`, for state. | P1-6 |

---

## Ranked Plan Amendments

### P0 — blocking; must land before/within Phase 0 (or Phase 1 where noted)

- **P0-1 — marketplace.json + plugin name + real install language (Phase 0).** Author `.claude-plugin/marketplace.json` at repo root with a non-reserved name (`savvy`), `owner.name`, and `plugins:[{name:"sf",source:"."}]`. Set `plugin.json` `name` → `sf` and add `displayName "Savvy Framework"`. Reframe ALL distribution docs from the fictional `/plugin install gh:…` to the real two-step: `/plugin marketplace add shaunchew/savvy-template` then `/plugin install sf@savvy`.
- **P0-2 — commit a NON-EMPTY, real payload (Phase 0).** Remove `.gitignore` 17-20 AND resolve authorship now (bring Phase 1's inversion forward enough that committed engine files are source of truth — preferred — or commit build-output). `.claude-plugin/{skills,commands,hooks,agents}/` must be git-tracked with actual files. Flatten skills to `skills/<name>/SKILL.md` (drop `_framework/`) OR set `plugin.json` `skills:["./skills/_framework/"]`. Strip the 0-byte `agents/.gitkeep`. `chmod +x` all hook scripts.
- **P0-3 — hooks.json with self-locating hooks (Phase 0).** Author `.claude-plugin/hooks/hooks.json` for all 4 events (PreToolUse:Bash→secret-scan; PostToolUse:Edit|Write→format + bloat-check; SessionStart→session-start; Stop→session-end). Do NOT trust bare `${CLAUDE_PLUGIN_ROOT}`: every hook self-locates via inline `$0`/`BASH_SOURCE` resolver (the pattern Stop/SessionEnd already use), with `${CLAUDE_PLUGIN_ROOT:-<fallback>}` as defensive belt; quoted exec-form commands. This neutralizes the upstream env-var bug regardless of which events it hits.
- **P0-4 — explicit-semver as Safety Invariant #6 (Phase 1).** SF must ALWAYS ship an explicit `version` (the update cache key); commit-SHA/per-commit publishing is FORBIDDEN. Set version in `plugin.json` ONLY (single sink, stamped from `VERSION`) — NEVER also in the marketplace entry (plugin.json wins silently and masks a stale marketplace version). This is the primary mechanism making a v1.4 project immune to a v2.0 update.
- **P0-5 — atomic adoption / detach (Phase 2, but the coexistence detector ships from Phase 0).** `/sf:adopt` must DETACH the in-tree engine (remove in-tree `.claude/commands/sf/`, `.claude/skills/_framework/`, `.claude/agents/`, AND strip the 5 framework hook entries from `settings.json`) in the SAME operation that activates the plugin. Move detach from Phase 3 → Phase 2. Until detached, plugin+in-tree is UNSUPPORTED; ship a session-start coexistence detector from Phase 0 that emits a single loud warning when both engines are live.

### P1 — must be absorbed before its phase

- **P1-1 — do NOT physically delete `template/` engine bytes in Phase 1.** Defer the on-remote deletion to the Phase 3 cutover release. Authorship inversion may happen in Phase 1, but `…/main/template/.claude` bytes must stay reachable for legacy `v1.4.0.sh`, baselines fetch, and `update_nudge`.
- **P1-2 — redefine Phase 0 "non-destructive."** = "no file deletion AND no behavior change for projects that do NOT install the plugin." Treat install onto a project that still has in-tree hooks as unsupported. Consider `defaultEnabled:false` (CC v2.1.154+) so an early install doesn't auto-activate hooks until opt-in.
- **P1-3 — transactional cutover migration (Phase 3).** Snapshot-first and fully transactional, in order: (1) clean committed git tree (refuse dirty; non-git → `.savvy-old` only, no delete); (2) positively confirm a live `sf` plugin whose version ≥ in-tree engine; (3) verify ALL engine hashes — **ABORT the whole cutover on ANY hash-miss** (never partial-delete); (4) re-seed the floor secret-scan guard + assert `permissions.deny` intact BEFORE stripping; (5) strip `settings.json` hooks by EXACT command-string allowlist only (the 5 known scripts), then re-validate JSON against the hook schema (re-run the v1.0.1 bare-Stop shape check); (6) delete ONLY manifest-listed framework files individually (never `rm -rf` a dir) so user customs survive; (7) write a completion marker (re-runs and never-had-engine codex/gemini projects = no-ops). `.savvy-old` is PRIMARY recovery (git can't restore ignored/untracked); require explicit `--yes` for destructive actions; standalone curl\|bash defaults to report-only.
- **P1-4 — plugin-presence hard precondition.** The cutover must positively confirm a live `sf` plugin (≥ in-tree version) before any deletion, else REFUSE and print install instructions. The curl\|bash standalone path is downgraded to "detect + report + instruct," never "delete."
- **P1-5 — full baseline coverage + real TOML parse (Phase 3).** Generate baselines for EVERY reachable release (v1.0, v1.0.1, v1.1, v1.2, v1.3, v1.4 + patch variants), not just v1.0+v1.4. Parse `config.toml` version with `python3 tomllib` scoped to `[framework].version`, NOT a column-0 grep; if ambiguous/unparseable, REFUSE the destructive path rather than guess.
- **P1-6 — repoint session-start to a REQUIRED Phase 2 deliverable.** The PLUGIN session-start hook reads its OWN version from `${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json`, writes `.claude/.savvy-engine-version` into the project tree, and emits a non-blocking LOUD warning when live engine version is outside the `config.toml [framework]` compatibility floor OR when an in-tree engine is detected alongside the plugin (double-load). DROP the remote-manifest curl `update_nudge` (the marketplace/`/plugin update` now owns "newer available"). Keep `find_root()`. No hook may write state under `CLAUDE_PLUGIN_ROOT`.

### P2 — should-do; documentation/release-gate hardening

- **P2-1 — frontmatter/name release gate.** Every shipped skill/command MUST declare an explicit frontmatter `name`; plugin name MUST be `sf`. Fail the build if any `SKILL.md` lacks `name`. Grep the 3 agent files for forbidden keys (`hooks`, `mcpServers`, `permissionMode`) and remove if present.
- **P2-2 — document pinning tiers, project scope, reload.** (A) DEFAULT — explicit semver + manual opt-in `/plugin update`; (B) HARD FREEZE — `source.sha` on the plugin entry in `marketplace.json` (marketplace-source supports `ref` but NOT `sha`; only plugin-source supports `sha`; sha survives tag deletion). Document `/sf:adopt` writing `enabledPlugins` at PROJECT scope so enablement is git-tracked. Document `/reload-plugins` after any version change before trusting behavior.

---

## Residual Risks & Disposition

| Risk | Severity | Disposition |
|---|---|---|
| Background auto-update at startup is the true silent cross-project drift vector; no clean per-plugin off switch. | MED | Mitigate via explicit-version gating (Invariant #6) — auto-update is a no-op until the version string changes — plus session-start version-stamp + floor warning. Do NOT design around a disable switch that doesn't exist. |
| Mid-session updates non-atomic (old `${CLAUDE_PLUGIN_ROOT}` until `/reload-plugins`; old dir ~7 days). | LOW | Accept with docs: instruct `/reload-plugins`/restart after version change. Hooks self-locate so never resolve to a stale absolute path; seeded secret-scan floor is path-stable. |
| Duplicate `/sf:` COMMAND collision behavior unverified (error/shadow/list-twice). | MED | Phase 0 observation documents actual behavior; atomic `/sf:adopt` detach eliminates the collision window for adopters; coexistence warning makes it visible until then. |
| Non-adopting v1.0–v1.4 projects rely on the curl-based upgrade path; premature `template/` remote deletion 404s it. | MED | Defer physical `template/` deletion to the Phase 3 cutover release (P1-1); optionally ship a legacy-bridge migration at a stable non-template URL. |
| Hand-edited engine files & user-authored customs in engine dirs orphaned/lost during cutover. | MED | Cutover deletes ONLY manifest-listed framework files individually (never `rm -rf`); hand-edited → `.savvy-old` + report; surviving customs left with guidance that the plugin won't auto-load them. |
| Baseline coverage may remain imperfect even after generating all baselines (hand-edited variants). | LOW | Safe-by-design: any hash-miss aborts the whole cutover → `.savvy-old` + report. Project is never destroyed, only un-migrated. |
| `permissions.deny` cannot be carried by the plugin. | LOW | Already handled: `permissions.deny` + ONE secret-scan floor guard stay in the seeded skeleton `settings.json` (Invariants #3/#4). Document the docs citation. |
| SessionStart remains the most fragile event even with self-location (depends on command PATH being invokable at SessionStart). | LOW | P0-T4/T5 test SessionStart specifically (banner must print) with the env var set AND unset. Documented fallback: keep SessionStart (and secret-scan floor) in the seeded `settings.json` with a project-relative path. |

---

## What Was Verified vs Assumed

**Verified directly in the repo (high confidence):**
- No `marketplace.json` anywhere (`find`); `plugin.json` name is still `savvy-framework` with version `1.4.0`.
- Payload gitignored (`.gitignore` 17-20); `git ls-files .claude-plugin/` tracks only `plugin.json` + `.savvy-manifest.json`.
- Skills live under `skills/_framework/<name>/SKILL.md` (one level too deep); `agents/` has a 0-byte `.gitkeep`.
- No `hooks/hooks.json`; hooks wired only in project-relative `settings.json`; `session-start.sh` curls a hardcoded `…/main/template/.claude/.savvy-manifest.json`.
- Baselines on disk: only v1.1.0/v1.2.0/v1.3.0. `v1.3.0.sh` deletes by name (`rm -f`, no hash gate). `v1.0.1.sh` repairs a malformed Stop-hook envelope. Version parse is a column-0 `grep`/`sed`, not TOML-aware.
- `gen-manifest.sh` classifies `settings.json`/`config.toml` as `merge` policy.

**Verified against Claude Code docs (high confidence):**
- Install is marketplace-mediated two-step; no `gh:` path. Components namespaced by plugin manifest `name`. Skills scanned at `skills/<name>/SKILL.md`. Plugin `settings.json` supports only `agent`/`subagentStatusLine`. Plugin agents reject `hooks`/`mcpServers`/`permissionMode`. Version resolution = plugin.json → marketplace entry → git SHA; update skips if unchanged. Background auto-updates run at startup; no per-plugin off switch. Project/user/local install scopes exist. `source.sha` pins (plugin-source only). Hooks from all layers merge + dedup by command string. `${CLAUDE_PLUGIN_ROOT}` changes on update; use `CLAUDE_PLUGIN_DATA` for state.

**Verified via upstream issue tracker (medium-high confidence):**
- `CLAUDE_PLUGIN_ROOT` intermittently unset for SessionStart/PreToolUse/PostToolUse/PreCompact — anthropics/claude-code #42564 (closed not-planned), #27145, #9447. Treated as P0 because the self-locate fix makes it moot.

**Assumed / NOT empirically confirmed (lower confidence — must be tested in the Phase 0 gate):**
- Exact `/sf:` vs `/sf:sf:` double-namespace behavior for `commands/sf/` subdir in the target CC version (P0-T3).
- In-tree-command vs plugin-command collision resolution (the one coexistence claim no red-team could authoritatively verify) (P0-T6/coexist).
- Whether `defaultEnabled:false` and project-scope-set-via-TUI behave as documented in the installed CC version.
- That double-fire reproduces exactly as predicted (expected, but to be confirmed empirically in P0-T6).

The 11-row Phase 0 gate matrix (P0-T1 install → P0-T11 name-stability) in the consolidated plan is the empirical instrument that converts these assumptions into verified facts before any destructive Phase 3 work is licensed.
