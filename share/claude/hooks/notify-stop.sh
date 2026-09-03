#!/usr/bin/env bash
# ~/.claude/hooks/notify-stop.sh
# Fires on every Claude "Stop" event (when Claude finishes responding).
# Sends a desktop notification so you know it's done without watching the terminal.

# Parse optional JSON input for context (Claude may pass stop reason, etc.)
REASON=""
if command -v jq >/dev/null 2>&1 && [[ -p /dev/stdin ]]; then
  INPUT=$(cat)
  REASON=$(echo "$INPUT" | jq -r '.stop_reason // empty' 2>/dev/null || true)
fi

TITLE="Claude Code"
BODY="${REASON:-Claude finished}"

if command -v notify-send >/dev/null 2>&1; then
  # Linux / GNOME / libnotify
  notify-send --app-name "Claude Code" \
              --icon utilities-terminal \
              --expire-time 4000 \
              "$TITLE" "$BODY" 2>/dev/null || true

elif command -v osascript >/dev/null 2>&1; then
  # macOS fallback
  osascript -e "display notification \"$BODY\" with title \"$TITLE\"" 2>/dev/null || true

elif command -v terminal-notifier >/dev/null 2>&1; then
  terminal-notifier -title "$TITLE" -message "$BODY" 2>/dev/null || true
fi

# Also ring the terminal bell so tmux can surface it in the status bar
printf '\a'

exit 0
