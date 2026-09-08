#!/usr/bin/env bash
# ~/.claude/hooks/check-claude-version.sh
# SessionStart hook. Detects a Claude Code version change since the last time
# /claude-update-check actually reviewed the changelog + settings docs, and
# nudges the agent to run it now. This script only detects the drift — it
# cannot fetch the changelog itself (plain shell has no route to public
# internet in this environment; only the agent-level WebFetch tool does).
#
# Must never break session start: every failure path is a silent exit 0.
set -uo pipefail

[[ -n "${CLAUDE_CONFIG_DIR:-}" ]] || exit 0
command -v claude > /dev/null 2>&1 || exit 0

installed=$(claude --version 2>/dev/null | awk '{print $1}')
[[ -n "$installed" ]] || exit 0

stamp_file="$CLAUDE_CONFIG_DIR/.claude-code-verified-version"
verified=$(cat "$stamp_file" 2>/dev/null || echo "")

[[ "$installed" == "$verified" ]] && exit 0

echo "=== CLAUDE CODE VERSION CHANGED ==="
echo "Installed: $installed"
echo "Last verified against changelog: ${verified:-never}"
echo ""
echo "Run the /claude-update-check steps now, before other work: fetch the"
echo "Claude Code changelog and settings-reference docs, compare against"
echo "this repo's share/claude/settings.json.example and \$CLAUDE_CONFIG_DIR/settings.json,"
echo "and reconcile any drift (see .claude/commands/claude-update-check.md)."
echo "=== END CLAUDE CODE VERSION CHANGED ==="
