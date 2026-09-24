#!/usr/bin/env bash
# ~/.claude/hooks/check-claude-version.sh
# SessionStart hook. Detects a Claude Code version change since the last time
# /claude-update-check actually reviewed the changelog + settings docs, and
# nudges the agent to run it now. This script only detects the drift — the
# changelog/docs fetch is left to the agent so session start stays fast.
#
# Must never break session start: every failure path is a silent exit 0.
set -uo pipefail

# Claude Code doesn't export CLAUDE_CONFIG_DIR to hooks; it defaults to ~/.claude.
config_dir="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
command -v claude > /dev/null 2>&1 || exit 0

installed=$(claude --version 2>/dev/null | awk '{print $1}')
[[ -n "$installed" ]] || exit 0

stamp_file="$config_dir/.claude-code-verified-version"
verified=$(cat "$stamp_file" 2>/dev/null || echo "")

[[ "$installed" == "$verified" ]] && exit 0

echo "=== CLAUDE CODE VERSION CHANGED ==="
echo "Installed: $installed"
echo "Last verified against changelog: ${verified:-never}"
echo ""
echo "Run /claude-update-check now, before other work: fetch the Claude Code"
echo "changelog and settings reference, compare against $config_dir/settings.json"
echo "and its template, and reconcile any drift."
echo "=== END CLAUDE CODE VERSION CHANGED ==="
