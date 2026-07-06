#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'
# sf-doctor.sh — READ-ONLY health check for a (possibly) framework-adopted project.
#
# Diagnoses the installation without changing a single byte: plugin enablement,
# settings integrity, secret-scan floor, engine/config version alignment,
# in-tree-engine coexistence, legacy-upgrade leftovers, unreconciled *.savvy-new
# files, quarantine dirs awaiting review, and git protection of .claude/.
#
# Usage: sf-doctor.sh [--project DIR]
# Exit codes: 0 = healthy (warnings allowed), 1 = problems found.

PROJECT="$PWD"
while [ $# -gt 0 ]; do
  case "$1" in
    --project) PROJECT="$2"; shift 2 ;;
    *) printf 'sf-doctor.sh: unknown arg: %s\n' "$1" >&2; exit 2 ;;
  esac
done
PROJECT="$(cd "$PROJECT" && pwd)"

problems=0; warnings=0
ok()   { printf '  ok    %s\n' "$1"; }
warn() { printf '  WARN  %s\n' "$1"; warnings=$((warnings + 1)); }
bad()  { printf '  FAIL  %s\n' "$1"; problems=$((problems + 1)); }

printf 'sf-doctor: %s\n' "$PROJECT"

# --- 0. toolchain ---------------------------------------------------------------
command -v jq >/dev/null 2>&1 && ok "jq available" || bad "jq missing — settings merges and hooks degrade without it"
command -v git >/dev/null 2>&1 && ok "git available" || warn "git missing — no revert safety net for framework operations"

# --- 1. adoption state ----------------------------------------------------------
CFG="$PROJECT/.claude/config.toml"
adopted=0
if [ -f "$CFG" ] && grep -q '^\[framework\]' "$CFG" 2>/dev/null; then
  adopted=1
  cfg_ver="$(grep -E '^version' "$CFG" 2>/dev/null | head -1 | sed -E 's/.*"([^"]+)".*/\1/' || true)"
  ok "adopted framework project (config.toml [framework], v${cfg_ver:-unknown})"
else
  printf '  info  not an adopted framework project (no .claude/config.toml [framework] section)\n'
fi

# --- 2. settings.json integrity ---------------------------------------------------
S="$PROJECT/.claude/settings.json"
if [ -L "$S" ]; then
  warn "settings.json is a symlink — /sf:adopt refuses this; framework merges would sever it"
fi
if [ -f "$S" ]; then
  if command -v jq >/dev/null 2>&1 && jq -e . "$S" >/dev/null 2>&1; then
    ok "settings.json is valid JSON"
    if [ "$(jq -r '.enabledPlugins["sf@savvy"] // empty' "$S")" = "true" ]; then
      ok "sf@savvy enabled at project scope"
    elif [ "$adopted" -eq 1 ]; then
      warn "adopted project but sf@savvy not enabled in settings.json — run /sf:adopt again"
    fi
    if jq -e '[.hooks.PreToolUse[]?.hooks[]?.command // ""] | any(test("secret-scan"))' "$S" >/dev/null 2>&1; then
      G="$PROJECT/.claude/hooks/secret-scan.sh"
      if [ -x "$G" ]; then
        ok "secret-scan floor guard wired and executable"
      elif [ -f "$G" ]; then
        bad "secret-scan.sh exists but is not executable (chmod +x .claude/hooks/secret-scan.sh)"
      else
        bad "settings.json wires secret-scan but .claude/hooks/secret-scan.sh is missing — Bash calls may error"
      fi
    elif [ "$adopted" -eq 1 ]; then
      warn "no secret-scan floor guard in settings.json — secrets in Bash commands are not blocked when the plugin is absent"
    fi
  elif command -v jq >/dev/null 2>&1; then
    bad "settings.json is INVALID JSON — Claude Code ignores it entirely (deny rules + hooks inactive)"
  fi
elif [ "$adopted" -eq 1 ]; then
  warn "adopted project without .claude/settings.json"
fi

# --- 3. engine/config version alignment (plugin mode) -----------------------------
STAMP="$PROJECT/.claude/.savvy-engine-version"
if [ -n "${CLAUDE_PLUGIN_ROOT:-}" ] && [ -f "$CLAUDE_PLUGIN_ROOT/.claude-plugin/plugin.json" ]; then
  eng="$(grep -E '"version"' "$CLAUDE_PLUGIN_ROOT/.claude-plugin/plugin.json" 2>/dev/null | head -1 | sed -E 's/.*"version"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/' || true)"
  [ -n "${eng:-}" ] && ok "sf engine v$eng is serving this session"
elif [ -f "$STAMP" ]; then
  printf '  info  last engine that served this project: v%s\n' "$(head -1 "$STAMP" | tr -d '[:space:]')"
fi

# --- 4. coexistence: in-tree engine remnants --------------------------------------
remnants=0
for n in format.sh bloat-check.sh session-start.sh session-end.sh; do
  [ -f "$PROJECT/.claude/hooks/$n" ] && remnants=$((remnants + 1))
done
[ -d "$PROJECT/.claude/commands/sf" ] && remnants=$((remnants + 1))
[ -d "$PROJECT/.claude/skills/_framework" ] && remnants=$((remnants + 1))
if [ "$remnants" -gt 0 ]; then
  warn "in-tree engine remnants present ($remnants) — hooks may double-fire alongside the plugin; run /sf:adopt to detach"
else
  ok "no in-tree engine remnants (no double-fire risk)"
fi

# --- 5. legacy-upgrade leftovers ---------------------------------------------------
if [ -f "$PROJECT/.claude/.savvy-manifest.json" ]; then
  warn "legacy baseline manifest present (.claude/.savvy-manifest.json) — a legacy /sf:upgrade could re-install the in-tree engine; /sf:adopt quarantines it"
fi
# `|| true` inside the substitutions: find exits nonzero on unreadable subdirs
# (and a missing .claude/), and under set -e -o pipefail that would kill the
# whole report mid-run with a false "problems found" exit code.
new_count="$(find "$PROJECT" -name '*.savvy-new' -not -path '*/.git/*' 2>/dev/null | wc -l | tr -d ' ' || true)"
if [ "${new_count:-0}" -gt 0 ]; then
  warn "$new_count unreconciled *.savvy-new file(s) from a past upgrade — review and delete them"
fi
q_count=0
if [ -d "$PROJECT/.claude" ]; then
  q_count="$(find "$PROJECT/.claude" -maxdepth 1 -type d -name '.savvy-detached-*' 2>/dev/null | wc -l | tr -d ' ' || true)"
fi
if [ "${q_count:-0}" -gt 0 ]; then
  printf '  info  %s quarantine dir(s) under .claude/ from adopt/eject — review, then delete when satisfied\n' "$q_count"
fi
[ -f "$S.savvy-old" ] && printf '  info  settings.json.savvy-old backup present (pre-adopt snapshot)\n'

# --- 6. git protection --------------------------------------------------------------
if git -C "$PROJECT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  ok "inside a git repository"
  if git -C "$PROJECT" check-ignore -q .claude 2>/dev/null; then
    warn ".claude/ is gitignored — git history does not protect framework/project config"
  fi
else
  warn "not a git repository — framework operations have no revert path here"
fi

# --- summary -------------------------------------------------------------------------
printf 'sf-doctor: %d problem(s), %d warning(s)\n' "$problems" "$warnings"
[ "$problems" -eq 0 ]
