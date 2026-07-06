#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'
# session-start.sh — deterministic context loading. SessionStart hook.
#   1. Detects .claude/intake-input.md and signals /sf:intake.
#   2. Prints framework version + variant from .claude/config.toml.
#   3. Reports pending-changes count awaiting /sf:curate.
#   4. Detects scratchpad-mode by CWD and reminds Claude framework machinery is inert.

# Drain stdin so the caller doesn't block.
cat >/dev/null 2>&1 || true

# Locate project root: walk up looking for .claude/. Fallback to CWD.
# Stops BEFORE $HOME: ~/.claude is the user's global Claude config, never a
# project root — walking into it made this hook write stamps into ~/.claude.
find_root() {
  local dir="$PWD"
  while [ "$dir" != "/" ] && [ "$dir" != "${HOME:-/nonexistent}" ]; do
    if [ -d "$dir/.claude" ]; then
      printf '%s' "$dir"
      return 0
    fi
    dir="$(dirname "$dir")"
  done
  printf '%s' "$PWD"
}

root="$(find_root)"

# 1. Intake-input detection — deterministic replacement for the CLAUDE.md instruction.
intake_input="$root/.claude/intake-input.md"
if [ -f "$intake_input" ]; then
  printf 'session-start.sh: .claude/intake-input.md detected. Run /sf:intake --from-file .claude/intake-input.md to bootstrap.\n'
fi

# 2. Framework version + variant banner.
config="$root/.claude/config.toml"
if [ -f "$config" ]; then
  # grep|head can exit non-zero (no match / SIGPIPE); guard against `set -o pipefail` aborting the hook.
  version="$(grep -E '^version' "$config" 2>/dev/null | head -1 | sed -E 's/.*"([^"]+)".*/\1/' || true)"
  variant="$(grep -E '^variant' "$config" 2>/dev/null | head -1 | sed -E 's/.*"([^"]+)".*/\1/' || true)"
  if [ -n "${version:-}" ] || [ -n "${variant:-}" ]; then
    printf 'session-start.sh: savvy framework v%s · variant=%s\n' "${version:-unknown}" "${variant:-unknown}"
  fi
fi

# 3. Pending-changes count.
pending="$root/.claude/pending-changes.md"
if [ -f "$pending" ]; then
  entries="$(grep -cE '^(> \*\*20|## 20)' "$pending" 2>/dev/null || true)"
  entries="${entries:-0}"
  if [ "$entries" -gt 0 ]; then
    printf 'session-start.sh: %s pending change(s) awaiting /sf:curate.\n' "$entries"
  fi
fi

# 4. Scratchpad-mode detection. CWD inside scratchpads/<name>/ (not _archive).
case "$PWD" in
  */scratchpads/_archive*) ;;
  */scratchpads/*)
    sp_name="$(printf '%s' "$PWD" | sed -E 's|.*/scratchpads/([^/]+).*|\1|')"
    printf 'session-start.sh: scratchpad-mode active (%s). Framework machinery is inert; main-project files are read-only reference.\n' "$sp_name"
    ;;
esac

# 4b. Coexistence detector. When the engine is installed as the `sf` plugin AND an in-tree
#     copy of the engine hooks is still wired into the project, both fire (plugin hooks merge
#     with in-tree hooks; dedup is by exact command string, and the plugin's self-locating
#     command differs from the in-tree project-relative one). Warn once, point to /sf:adopt.
#     Harmless in legacy in-tree-only projects (no plugin → the in-tree hook is the only one;
#     this branch keys off CLAUDE_PLUGIN_ROOT being set, which only the plugin invocation has).
#     Gated on (a) an adopted framework project and (b) the in-tree hook actually being
#     the savvy engine copy — a user's OWN session-start hook in a non-framework project
#     must never trigger advice to run /sf:adopt (which would detach their hook).
if [ -n "${CLAUDE_PLUGIN_ROOT:-}" ] && [ -f "$root/.claude/hooks/session-start.sh" ] \
   && [ -f "$root/.claude/config.toml" ] \
   && grep -q '^\[framework\]' "$root/.claude/config.toml" 2>/dev/null \
   && grep -q 'savvy' "$root/.claude/hooks/session-start.sh" 2>/dev/null \
   && [ -f "$root/.claude/settings.json" ] \
   && grep -q '\.claude/hooks/session-start\.sh' "$root/.claude/settings.json" 2>/dev/null; then
  printf 'session-start.sh: ⚠ COEXISTENCE — the sf plugin and an in-tree engine are both active; hooks will DOUBLE-FIRE. Run /sf:adopt to detach the in-tree engine.\n'
fi

# 5. Framework update nudge — cached, non-blocking, fully silent on any failure.
#    Compares the local version against a cached "latest" marker and points to
#    /sf:upgrade when newer. The remote check runs in the background (detached) and
#    only updates the cache for the NEXT session, so session start never blocks on
#    the network. Projects with no cache simply get the nudge one session later.
update_nudge() {
  [ -n "${version:-}" ] || return 0          # no local version known → nothing to compare
  local cache="$root/.claude/.savvy-update-cache"
  local manifest_url="https://raw.githubusercontent.com/shaunchew/savvy-template/main/template/.claude/.savvy-manifest.json"
  local now latest checked age
  now="$(date +%s)"

  # Read cached latest version + last-checked epoch, if present.
  if [ -f "$cache" ]; then
    latest="$(grep -E '^latest=' "$cache" 2>/dev/null | head -1 | cut -d= -f2)"
    checked="$(grep -E '^checked=' "$cache" 2>/dev/null | head -1 | cut -d= -f2)"
  fi

  # Print the nudge if the cached latest is strictly newer than local.
  if [ -n "${latest:-}" ] && version_gt "$latest" "$version"; then
    printf 'session-start.sh: framework update available (v%s → v%s). Run /sf:upgrade to review.\n' "$version" "$latest"
  fi

  # Refresh the cache in the background if stale (>24h) or missing, and curl exists.
  age=$(( now - ${checked:-0} ))
  if [ "$age" -ge 86400 ] && command -v curl >/dev/null 2>&1; then
    nohup sh -c '
      v="$(curl -fsSL --max-time 3 "'"$manifest_url"'" 2>/dev/null \
            | grep -o "\"version\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" \
            | head -1 | sed -E "s/.*\"([^\"]+)\"$/\1/")"
      [ -n "$v" ] && printf "latest=%s\nchecked=%s\n" "$v" "'"$now"'" > "'"$cache"'"
    ' >/dev/null 2>&1 &
  fi
}

# Semver-ish compare: returns 0 (true) if $1 > $2. Pads missing components with 0.
version_gt() {
  local a b i av bv
  IFS='.' read -r -a a <<< "${1%%[!0-9.]*}"
  IFS='.' read -r -a b <<< "${2%%[!0-9.]*}"
  for i in 0 1 2; do
    av="${a[i]:-0}"; bv="${b[i]:-0}"
    av="${av:-0}"; bv="${bv:-0}"
    if [ "$av" -gt "$bv" ] 2>/dev/null; then return 0; fi
    if [ "$av" -lt "$bv" ] 2>/dev/null; then return 1; fi
  done
  return 1
}

# 6. Engine version stamp (plugin mode only). When running as the sf plugin, read the
#    plugin's own version, record it at .claude/.savvy-engine-version (so the project can
#    see which engine served it), and warn if the project's config.toml declares a
#    compatibility floor newer than the installed engine. Replaces the remote /sf:upgrade
#    nudge for plugin-based projects — engine updates flow through /plugin update, not a
#    project-tree fetch.
version_stamp() {
  local proot="${CLAUDE_PLUGIN_ROOT:-}"
  [ -n "$proot" ] || return 0
  local pj="$proot/.claude-plugin/plugin.json"
  [ -f "$pj" ] || return 0
  local engine_ver
  engine_ver="$(grep -E '"version"' "$pj" 2>/dev/null | head -1 | sed -E 's/.*"version"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/' || true)"
  [ -n "${engine_ver:-}" ] || return 0

  # Stamp ONLY projects that adopted the PLUGIN (sf@savvy enabled at project scope).
  # A legacy in-tree project also has config.toml — stamping it would make the
  # /sf:upgrade plugin-mode guard wrongly refuse to serve it. And a bare .claude/
  # dir is any Claude Code user's project — the plugin must never write into it.
  local stamp="$root/.claude/.savvy-engine-version"
  if [ -f "$root/.claude/config.toml" ] && [ -f "$root/.claude/settings.json" ] \
     && grep -q '"sf@savvy"[[:space:]]*:[[:space:]]*true' "$root/.claude/settings.json" 2>/dev/null; then
    printf '%s\n' "$engine_ver" > "$stamp" 2>/dev/null || true
  fi

  # Compatibility floor: if config.toml's framework version is NEWER than the installed
  # engine, the project expects a newer engine than is loaded — warn (non-blocking).
  if [ -n "${version:-}" ] && version_gt "$version" "$engine_ver"; then
    printf 'session-start.sh: ⚠ engine v%s is OLDER than this project'\''s floor v%s. Run /plugin update sf@savvy.\n' "$engine_ver" "$version"
  fi
}

# Dispatch: plugin-mode projects get the version stamp; legacy in-tree projects keep the
# remote /sf:upgrade nudge (retired at the Phase 3 cutover).
if [ -n "${CLAUDE_PLUGIN_ROOT:-}" ]; then
  version_stamp || true
else
  update_nudge || true
fi

exit 0
