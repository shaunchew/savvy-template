# =============================================================================
# savvy.zsh — savvy CLI v1.0
# -----------------------------------------------------------------------------
# Filename:    savvy.zsh
# Version:     1.0.0
# Project:     savvy-framework
#
# Install:
#   1. Place this file somewhere stable, e.g. ~/Documents/projects/savvy-framework/cli/savvy.zsh
#   2. Add the following line to your ~/.zshrc:
#        source ~/Documents/projects/savvy-framework/cli/savvy.zsh
#   3. Reload your shell:
#        exec zsh
#
# Signature (from plan §11.1):
#   savvy new <name> --llm <agent> --idea "<text>" [--idea-from-file <path>] [--variant <type>]
#
# Defaults:
#   --llm     claude   (claude | codex | gemini)
#   --variant software-dev  (software-dev | data-science)
#
# Behaviour (per §11.1):
#   1. Validates the chosen LLM CLI is installed (claude / codex / gemini)
#   2. Runs `uvx copier copy gh:shaunchew/savvy-template <name>`
#      with --data project_name / variant / llm
#   3. Writes the idea text to <name>/.claude/intake-input.md
#   4. cd's into <name>/
#   5. Launches the LLM CLI; the agent auto-detects intake-input.md (via CLAUDE.md
#      / AGENTS.md instructions) and runs `/intake --from-file`
#
# Verbatim source: plan §11.2 (preserved below as the body of `savvy()`).
# =============================================================================

savvy() {
  case "$1" in
    new)
      shift
      local name="$1"; shift
      local llm="claude"
      local idea=""
      local idea_file=""
      local variant="software-dev"

      if [[ -z "$name" || "$name" == --* ]]; then
        print -u2 "savvy: missing <name> argument"
        print -u2 "Usage: savvy new <name> [--llm claude|codex|gemini] [--idea \"<text>\"|--idea-from-file <path>] [--variant software-dev|data-science]"
        return 1
      fi

      while [[ $# -gt 0 ]]; do
        case "$1" in
          --llm) llm="$2"; shift 2 ;;
          --idea) idea="$2"; shift 2 ;;
          --idea-from-file) idea_file="$2"; shift 2 ;;
          --variant) variant="$2"; shift 2 ;;
          *) print -u2 "savvy: unknown option: $1"; return 1 ;;
        esac
      done

      # Validate LLM CLI is installed
      if ! command -v "$llm" >/dev/null 2>&1; then
        print -u2 "savvy: LLM CLI '$llm' not found on PATH. Install it before running savvy new."
        return 1
      fi

      # Validate idea input
      if [[ -z "$idea" && -z "$idea_file" ]]; then
        print -u2 "savvy: must provide --idea \"<text>\" or --idea-from-file <path>"
        return 1
      fi
      if [[ -n "$idea_file" && ! -f "$idea_file" ]]; then
        print -u2 "savvy: --idea-from-file path not found: $idea_file"
        return 1
      fi

      # Validate target directory doesn't already exist
      if [[ -e "$name" ]]; then
        print -u2 "savvy: target '$name' already exists; refusing to overwrite"
        return 1
      fi

      # Run copier
      uvx copier copy gh:shaunchew/savvy-template "$name" \
        --data project_name="$name" \
        --data variant="$variant" \
        --data llm="$llm" \
        --defaults || {
          print -u2 "savvy: copier scaffold failed"
          return 1
        }

      # Write idea to intake-input.md
      cd "$name" || return 1
      mkdir -p .claude
      if [[ -n "$idea_file" ]]; then
        cp "$idea_file" .claude/intake-input.md
      elif [[ -n "$idea" ]]; then
        print -r -- "$idea" > .claude/intake-input.md
      fi

      # Launch the chosen LLM (exec hands control over to the agent)
      case "$llm" in
        claude) exec claude ;;
        codex)  exec codex ;;
        gemini) exec gemini ;;
        *) print -u2 "savvy: unsupported LLM: $llm"; return 1 ;;
      esac
      ;;

    ""|-h|--help|help)
      cat <<'USAGE'
savvy — scaffold a new project from the savvy-framework template.

Usage:
  savvy new <name> [--llm claude|codex|gemini]
                   [--idea "<text>" | --idea-from-file <path>]
                   [--variant software-dev|data-science]

Defaults:
  --llm     claude
  --variant software-dev

Examples:
  savvy new my-app --idea "A CLI that summarises podcasts"
  savvy new my-app --llm codex --idea-from-file ./brief.md --variant data-science
USAGE
      [[ -z "$1" ]] && return 1 || return 0
      ;;

    *)
      print -u2 "savvy: unknown sub-command: $1"
      print -u2 "Run 'savvy help' for usage."
      return 1
      ;;
  esac
}
