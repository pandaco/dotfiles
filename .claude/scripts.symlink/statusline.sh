#!/bin/bash
# Status line for Claude Code — inspired by Powerlevel10k lean theme.
# Left side: dir  git-branch git-status
# Right side: model  context%

input=$(cat)

# --- Directory (from Claude's cwd, mimicking p10k dir segment) ---
cwd=$(printf '%s' "$input" | jq -r '.cwd // empty')
if [ -n "$cwd" ]; then
  home="$HOME"
  display_dir="${cwd/#$home/~}"
  printf '\033[38;5;31m%s\033[0m' "$display_dir"
fi

# --- Git branch + status (from workspace.repo and git) ---
git_info=""
branch=$(git -C "$cwd" --no-optional-locks symbolic-ref --short HEAD 2>/dev/null)
if [ -z "$branch" ]; then
  branch=$(git -C "$cwd" --no-optional-locks rev-parse --short HEAD 2>/dev/null)
  [ -n "$branch" ] && branch="@${branch}"
fi

if [ -n "$branch" ]; then
  # Truncate long branch names like p10k does (>32 chars → first12…last12)
  if [ "${#branch}" -gt 32 ]; then
    branch="${branch:0:12}…${branch: -12}"
  fi

  # Collect status indicators
  status_flags=""
  git_status=$(git -C "$cwd" --no-optional-locks status --porcelain 2>/dev/null)
  staged=$(printf '%s' "$git_status" | grep -c '^[MADRC]')
  unstaged=$(printf '%s' "$git_status" | grep -c '^.[MD]')
  untracked=$(printf '%s' "$git_status" | grep -c '^??')
  [ "$staged" -gt 0 ] && status_flags="${status_flags} \033[38;5;178m+${staged}\033[0m"
  [ "$unstaged" -gt 0 ] && status_flags="${status_flags} \033[38;5;178m!${unstaged}\033[0m"
  [ "$untracked" -gt 0 ] && status_flags="${status_flags} \033[38;5;39m?${untracked}\033[0m"

  # Ahead/behind
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

# --- Model + effort level ---
model=$(printf '%s' "$input" | jq -r '.model.display_name // empty')
effort=$(printf '%s' "$input" | jq -r '.effort.level // empty')
if [ -n "$model" ]; then
  printf '  \033[38;5;244m%s\033[0m' "$model"
  if [ -n "$effort" ]; then
    case "$effort" in
      low)    effort_color=76  ;;   # green
      medium) effort_color=178 ;;   # amber
      high)   effort_color=196 ;;   # red
      xhigh)  effort_color=196 ;;   # red
      max)    effort_color=196 ;;   # red
      *)      effort_color=244 ;;   # grey fallback
    esac
    printf ' \033[38;5;244m[\033[38;5;%dm%s\033[38;5;244m]\033[0m' "$effort_color" "$effort"
  fi
fi

# --- Context usage ---
used=$(printf '%s' "$input" | jq -r '.context_window.used_percentage // empty')
if [ -n "$used" ]; then
  used_int=$(printf '%.0f' "$used")
  if [ "$used_int" -ge 80 ]; then
    color=196   # red
  elif [ "$used_int" -ge 50 ]; then
    color=178   # amber
  else
    color=76    # green
  fi
  printf ' \033[38;5;%dm%d%%/ctx\033[0m' "$color" "$used_int"
fi

# --- 5-hour session rate limit ---
five_hour_pct=$(printf '%s' "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
seven_day_pct=$(printf '%s' "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
if [ -n "$five_hour_pct" ] || [ -n "$seven_day_pct" ]; then
  rate_limit_out=""
  if [ -n "$five_hour_pct" ]; then
    five_int=$(printf '%.0f' "$five_hour_pct")
    if [ "$five_int" -ge 80 ]; then
      rl_color=196
    elif [ "$five_int" -ge 50 ]; then
      rl_color=178
    else
      rl_color=76
    fi
    rate_limit_out="$(printf '\033[38;5;%dm%d%%/5h\033[0m' "$rl_color" "$five_int")"
  fi
  if [ -n "$seven_day_pct" ]; then
    seven_int=$(printf '%.0f' "$seven_day_pct")
    if [ "$seven_int" -ge 80 ]; then
      week_color=196
    elif [ "$seven_int" -ge 50 ]; then
      week_color=178
    else
      week_color=76
    fi
    week_seg="$(printf '\033[38;5;%dm%d%%/7d\033[0m' "$week_color" "$seven_int")"
    if [ -n "$rate_limit_out" ]; then
      rate_limit_out="${rate_limit_out} ${week_seg}"
    else
      rate_limit_out="$week_seg"
    fi
  fi
  printf ' %s' "$rate_limit_out"
fi
