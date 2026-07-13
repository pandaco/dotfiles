#!/bin/bash
# Écrit l'état de l'agent (working / idle / waiting) dans un fichier par session,
# consommé par statusline.sh. Appelé par les hooks UserPromptSubmit, PreToolUse,
# Notification et Stop (voir settings.json).
# Usage : agent-state.sh <state>   (le JSON du hook arrive sur stdin)

state="$1"
session_id=$(jq -r '.session_id // empty')
[ -z "$state" ] || [ -z "$session_id" ] && exit 0
printf '%s' "$state" > "${TMPDIR:-/tmp}/claude-agent-state-${session_id}"
