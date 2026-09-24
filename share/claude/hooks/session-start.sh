#!/usr/bin/env bash
# ~/.claude/hooks/session-start.sh
# Runs at the start of every Claude Code session.
# Output is injected into the conversation as context. Claude Code already
# provides the date and git status, so this only adds which machine this is.

set -euo pipefail

HOST=$(hostname -s 2>/dev/null || echo "$HOSTNAME")
USER_NAME=${USER:-$(id -un)}

echo "Host: $HOST  User: $USER_NAME"
