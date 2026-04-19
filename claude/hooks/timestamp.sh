#!/bin/bash
set -euo pipefail

STATE_FILE="$HOME/.claude/hooks/.last_prompt_time"
NOW=$(date +%s)
NOW_HUMAN=$(date "+%A %Y-%m-%d %H:%M:%S %Z")

ELAPSED_MSG=""
if [ -f "$STATE_FILE" ]; then
    LAST=$(cat "$STATE_FILE")
    if [[ "$LAST" =~ ^[0-9]+$ ]]; then
        DIFF=$((NOW - LAST))
        if [ "$DIFF" -lt 60 ]; then
            ELAPSED_MSG="${DIFF}s"
        elif [ "$DIFF" -lt 3600 ]; then
            MINS=$((DIFF / 60))
            SECS=$((DIFF % 60))
            ELAPSED_MSG="${MINS}m ${SECS}s"
        elif [ "$DIFF" -lt 86400 ]; then
            HOURS=$((DIFF / 3600))
            MINS=$(( (DIFF % 3600) / 60 ))
            ELAPSED_MSG="${HOURS}h ${MINS}m"
        else
            DAYS=$((DIFF / 86400))
            HOURS=$(( (DIFF % 86400) / 3600 ))
            ELAPSED_MSG="${DAYS}d ${HOURS}h"
        fi
    fi
fi

# Write current time for next invocation
echo "$NOW" > "$STATE_FILE"

# Build the system message
if [ -n "$ELAPSED_MSG" ]; then
    MSG="[Time: ${NOW_HUMAN} | Since last message: ${ELAPSED_MSG}]"
else
    MSG="[Time: ${NOW_HUMAN} | First message this session]"
fi

# Output JSON for Claude Code — additionalContext injects into model context
printf '{"hookSpecificOutput":{"hookEventName":"UserPromptSubmit","additionalContext":"%s"}}\n' "$MSG"
exit 0
