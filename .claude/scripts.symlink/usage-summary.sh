#!/bin/bash
# Stop hook — print a per-turn token and rate-limit summary to the terminal.
# Claude Code pipes the session JSON into stdin when this hook fires.

input=$(cat)

# --- Per-turn token counts (from last API call) ---
input_tokens=$(printf '%s' "$input" | jq -r '.context_window.current_usage.input_tokens // empty')
output_tokens=$(printf '%s' "$input" | jq -r '.context_window.current_usage.output_tokens // empty')
cache_write=$(printf '%s' "$input" | jq -r '.context_window.current_usage.cache_creation_input_tokens // empty')
cache_read=$(printf '%s' "$input" | jq -r '.context_window.current_usage.cache_read_input_tokens // empty')

# --- Cumulative context ---
total_input=$(printf '%s' "$input" | jq -r '.context_window.total_input_tokens // empty')
ctx_size=$(printf '%s' "$input" | jq -r '.context_window.context_window_size // empty')
used_pct=$(printf '%s' "$input" | jq -r '.context_window.used_percentage // empty')

# --- Rate limits ---
five_hour_pct=$(printf '%s' "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
five_hour_reset=$(printf '%s' "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
seven_day_pct=$(printf '%s' "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')

# Nothing to show if there was no API call this turn
[ -z "$input_tokens" ] && [ -z "$output_tokens" ] && exit 0

# Build the output line
line=""

if [ -n "$input_tokens" ] || [ -n "$output_tokens" ]; then
  in_val="${input_tokens:-0}"
  out_val="${output_tokens:-0}"
  line="tokens  in:${in_val}  out:${out_val}"

  if [ -n "$cache_read" ] && [ "$cache_read" -gt 0 ] 2>/dev/null; then
    line="${line}  cache-read:${cache_read}"
  fi
  if [ -n "$cache_write" ] && [ "$cache_write" -gt 0 ] 2>/dev/null; then
    line="${line}  cache-write:${cache_write}"
  fi
fi

if [ -n "$used_pct" ]; then
  used_int=$(printf '%.0f' "$used_pct")
  if [ -n "$total_input" ] && [ -n "$ctx_size" ]; then
    line="${line}  |  ctx ${used_int}% used (${total_input}/${ctx_size})"
  else
    line="${line}  |  ctx ${used_int}% used"
  fi
fi

if [ -n "$five_hour_pct" ]; then
  five_int=$(printf '%.0f' "$five_hour_pct")
  reset_str=""
  if [ -n "$five_hour_reset" ]; then
    reset_str=" resets $(date -r "$five_hour_reset" "+%H:%M" 2>/dev/null)"
  fi
  line="${line}  |  5h session: ${five_int}%${reset_str}"
fi

if [ -n "$seven_day_pct" ]; then
  seven_int=$(printf '%.0f' "$seven_day_pct")
  line="${line}  7d: ${seven_int}%"
fi

[ -n "$line" ] && printf '\033[2m%s\033[0m\n' "$line"

exit 0
