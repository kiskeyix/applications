#!/usr/bin/env bash
# ~/.claude/hooks/session-start.sh
# Runs at the start of every Claude Code session.
# Output is injected into the conversation as context. Claude Code already
# provides the date and git status, so this only adds which machine this is.
#
# It also puts ~/.path.setup on the Bash tool's PATH. The tool's shell snapshot
# ends by re-exporting the claude process's own PATH, so whatever ~/.bashrc
# added is lost, and a session started by systemd never had it. Claude Code
# sources CLAUDE_ENV_FILE ahead of every Bash command, background ones too.

set -euo pipefail

HOST=$(hostname -s 2>/dev/null || echo "$HOSTNAME")
USER_NAME=${USER:-$(id -un)}

echo "Host: $HOST  User: $USER_NAME"

if [[ -n "${CLAUDE_ENV_FILE:-}" && -r "$HOME/.path.setup" ]]; then
  echo '. "$HOME/.path.setup"' >> "$CLAUDE_ENV_FILE"
fi
