#!/usr/bin/env bash
# ~/.claude/hooks/session-start.sh
# Runs at the start of every Claude Code session.
# Output is injected into the conversation as a system-reminder.

set -euo pipefail

DATE=$(date '+%A %Y-%m-%d %H:%M %Z')
HOST=$(hostname -s 2>/dev/null || echo "$HOSTNAME")
USER_NAME=${USER:-$(id -un)}

echo "=== SESSION START ==="
echo "Time : $DATE"
echo "Host : $HOST  User: $USER_NAME"

# Git context if inside a repo
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  BRANCH=$(git symbolic-ref --short HEAD 2>/dev/null || git rev-parse --short HEAD)
  STATUS=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
  REMOTE=$(git remote get-url origin 2>/dev/null | sed 's|.*[:/]\([^/]*/[^/]*\)$|\1|' || echo "")
  echo "Git  : branch=$BRANCH  dirty=$STATUS files${REMOTE:+  remote=$REMOTE}"
fi

# Memory reminder (if .remember/ exists in home)
REMEMBER_DIR="$HOME/.remember"
if [[ -d "$REMEMBER_DIR" ]]; then
  NOW_FILE="$REMEMBER_DIR/now.md"
  if [[ -f "$NOW_FILE" ]]; then
    echo ""
    echo "--- now.md (recent context) ---"
    tail -20 "$NOW_FILE"
  fi
  TODAY=$(date '+%Y-%m-%d')
  TODAY_FILE="$REMEMBER_DIR/today-${TODAY}.md"
  if [[ -f "$TODAY_FILE" ]]; then
    echo ""
    echo "--- today's log ---"
    tail -30 "$TODAY_FILE"
  fi
fi

echo "=== END SESSION START ==="
