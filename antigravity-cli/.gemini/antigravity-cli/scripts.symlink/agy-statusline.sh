#!/bin/bash
# Status line for Google Antigravity CLI

input=$(cat)

# --- Directory ---
cwd=$(printf '%s' "$input" | jq -r '.cwd // empty')
if [ -n "$cwd" ]; then
  home="$HOME"
  display_dir="${cwd/#$home/~}"
  printf '\033[38;5;31m%s\033[0m' "$display_dir"
fi

# --- Git branch + status ---
git_info=""
if [ -n "$cwd" ] && [ -d "$cwd/.git" ] || git -C "$cwd" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  branch=$(git -C "$cwd" --no-optional-locks symbolic-ref --short HEAD 2>/dev/null)
  if [ -z "$branch" ]; then
    branch=$(git -C "$cwd" --no-optional-locks rev-parse --short HEAD 2>/dev/null)
    [ -n "$branch" ] && branch="@${branch}"
  fi

  if [ -n "$branch" ]; then
    if [ "${#branch}" -gt 32 ]; then
      branch="${branch:0:12}…${branch: -12}"
    fi

    status_flags=""
    git_status=$(git -C "$cwd" --no-optional-locks status --porcelain 2>/dev/null)
    staged=$(printf '%s' "$git_status" | grep -c '^[MADRC]')
    unstaged=$(printf '%s' "$git_status" | grep -c '^.[MD]')
    untracked=$(printf '%s' "$git_status" | grep -c '^??')
    [ "$staged" -gt 0 ] && status_flags="${status_flags} \033[38;5;178m+${staged}\033[0m"
    [ "$unstaged" -gt 0 ] && status_flags="${status_flags} \033[38;5;178m!${unstaged}\033[0m"
    [ "$untracked" -gt 0 ] && status_flags="${status_flags} \033[38;5;39m?${untracked}\033[0m"

    remote_ref=$(git -C "$cwd" --no-optional-locks rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null)
    if [ -n "$remote_ref" ]; then
      ahead=$(git -C "$cwd" --no-optional-locks rev-list --count "${remote_ref}..HEAD" 2>/dev/null)
      behind=$(git -C "$cwd" --no-optional-locks rev-list --count "HEAD..${remote_ref}" 2>/dev/null)
      [ "${behind:-0}" -gt 0 ] && status_flags="${status_flags} \033[38;5;76m⇣${behind}\033[0m"
      [ "${ahead:-0}" -gt 0 ] && status_flags="${status_flags} \033[38;5;76m⇡${ahead}\033[0m"
    fi

    printf ' \033[38;5;76m%s\033[0m' "$branch"
    [ -n "$status_flags" ] && printf "$status_flags"
  fi
fi

# --- Agent State ---
agent_state=$(printf '%s' "$input" | jq -r '.agent_state // empty')
if [ -n "$agent_state" ]; then
  case "$agent_state" in
    working) state_icon="⚙️  working" ;;
    idle)    state_icon="💤  idle" ;;
    waiting_for_user) state_icon="⏳  waiting" ;;
    *)       state_icon="$agent_state" ;;
  esac
  printf '  \033[38;5;147m%s\033[0m' "$state_icon"
fi

# --- Model ---
model=$(printf '%s' "$input" | jq -r '.model.display_name // .model // empty')
if [ -n "$model" ] && [ "$model" != "null" ]; then
  printf '  \033[38;5;244m%s\033[0m' "$model"
fi

# --- Tokens (In/Out) ---
tokens=$(printf '%s' "$input" | jq -r '
  def kfmt: if . >= 1000 then (. / 1000 | floor | tostring) + "k" else tostring end;
  if .context_window.total_input_tokens != null then
    "📥  \(.context_window.total_input_tokens | kfmt) | 📤  \(.context_window.total_output_tokens | kfmt)"
  else empty end
')
if [ -n "$tokens" ]; then
  printf '  \033[38;5;250m%s\033[0m' "$tokens"
fi

# --- Context usage ---
used_ctx=$(printf '%s' "$input" | jq -r '.context_window.used_percentage // empty | if type=="number" then floor else empty end')
if [ -n "$used_ctx" ]; then
  if [ "$used_ctx" -ge 80 ]; then color=196
  elif [ "$used_ctx" -ge 50 ]; then color=178
  else color=76
  fi
  printf ' \033[38;5;%dm%d%%/ctx\033[0m' "$color" "$used_ctx"
fi

# --- Heavy Context Warning ---
heavy_ctx=$(printf '%s' "$input" | jq -r '.exceeds_200k_tokens // false')
if [ "$heavy_ctx" = "true" ]; then
  printf ' \033[38;5;196m⚠️  Heavy Context\033[0m'
fi

# --- Rate limits usage (Gemini 5h / 7d) ---
used_5h=$(printf '%s' "$input" | jq -r '.quota."gemini-5h".remaining_fraction // empty | if type=="number" then ((1 - .) * 100 | floor) else empty end')
used_7d=$(printf '%s' "$input" | jq -r '.quota."gemini-weekly".remaining_fraction // empty | if type=="number" then ((1 - .) * 100 | floor) else empty end')

out_5h=""
if [ -n "$used_5h" ]; then
  if [ "$used_5h" -ge 80 ]; then rl_color=196
  elif [ "$used_5h" -ge 50 ]; then rl_color=178
  else rl_color=76; fi
  out_5h="$(printf '\033[38;5;%dm%d%%/5h\033[0m' "$rl_color" "$used_5h")"
fi

out_7d=""
if [ -n "$used_7d" ]; then
  if [ "$used_7d" -ge 80 ]; then week_color=196
  elif [ "$used_7d" -ge 50 ]; then week_color=178
  else week_color=76; fi
  out_7d="$(printf '\033[38;5;%dm%d%%/7d\033[0m' "$week_color" "$used_7d")"
fi

[ -n "$out_5h" ] && printf ' %s' "$out_5h"
[ -n "$out_7d" ] && printf ' %s' "$out_7d"

echo
