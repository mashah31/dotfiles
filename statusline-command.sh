#!/bin/sh
# Claude Code status line: Starship-style prompt + context bar + model

input=$(cat)

# ── Directory (cyan, truncated to last 2 parts like Starship) ──────────────
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // empty')
if [ -z "$cwd" ]; then
  cwd=$(pwd)
fi
# Substitute /Users/mshah/workspace -> ~/workspace
cwd_display="${cwd/#\/Users\/mshah\/workspace/\~\/workspace}"
# Substitute /Users/mshah -> ~
cwd_display="${cwd_display/#\/Users\/mshah/\~}"
# Truncate to last 2 path components (mirrors truncation_length = 2)
dir_display=$(echo "$cwd_display" | awk -F'/' '{
  n = NF
  if (n <= 2) { print $0 }
  else { print $(n-1)"/"$n }
}')

# ── Git branch & status ────────────────────────────────────────────────────
git_info=""
if git -C "$cwd" rev-parse --git-dir > /dev/null 2>&1; then
  branch=$(git -C "$cwd" symbolic-ref --short HEAD 2>/dev/null)
  if [ -n "$branch" ]; then
    # Git status flags (mirrors Starship git_status)
    git_flags=$(git -C "$cwd" --no-optional-locks status --porcelain 2>/dev/null)
    status_str=""
    if [ -n "$git_flags" ]; then
      status_str=$(printf "\033[31m*\033[0m")  # bold red for dirty
    fi
    git_info=$(printf " \033[35m %s\033[0m%s" "$branch" "$status_str")
  fi
fi

# ── Python virtualenv ──────────────────────────────────────────────────────
py_info=""
if [ -n "$VIRTUAL_ENV" ]; then
  venv_name=$(basename "$VIRTUAL_ENV")
  py_info=$(printf " \033[33m %s\033[0m" "$venv_name")
fi

# ── Context window progress bar ────────────────────────────────────────────
model=$(echo "$input" | jq -r '.model.display_name // "Unknown Model"')
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
input_tokens=$(echo "$input" | jq -r '.context_window.current_usage.input_tokens // empty')
ctx_size=$(echo "$input" | jq -r '.context_window.context_window_size // empty')

ctx_bar=""
ctx_color=""
ctx_alert=""
if [ -n "$used_pct" ]; then
  filled=$(echo "$used_pct" | awk '{printf "%d", ($1 / 100) * 20}')
  empty=$((20 - filled))
  bar=""
  i=0
  while [ $i -lt "$filled" ]; do bar="${bar}#"; i=$((i + 1)); done
  i=0
  while [ $i -lt "$empty" ]; do bar="${bar}-"; i=$((i + 1)); done

  # Color thresholds: green < 50%, yellow 50-75%, red >= 75%
  pct_int=$(echo "$used_pct" | awk '{printf "%d", $1}')
  if [ "$pct_int" -ge 75 ]; then
    ctx_color="\033[31m"   # red
    ctx_alert=" (!)"
  elif [ "$pct_int" -ge 50 ]; then
    ctx_color="\033[33m"   # yellow
    ctx_alert=" (~)"
  else
    ctx_color="\033[32m"   # green
    ctx_alert=""
  fi

  # Token count label: show Xk/Yk when sizes are available, else just pct
  if [ -n "$input_tokens" ] && [ -n "$ctx_size" ]; then
    used_k=$(echo "$input_tokens $ctx_size" | awk '{printf "%.0fk/%.0fk", $1/1000, $2/1000}')
    ctx_bar=$(printf "${ctx_color}[%s] %.0f%% (%s)%s\033[0m" "$bar" "$used_pct" "$used_k" "$ctx_alert")
  else
    ctx_bar=$(printf "${ctx_color}[%s] %.0f%%%s\033[0m" "$bar" "$used_pct" "$ctx_alert")
  fi
fi

# ── Assemble status line ───────────────────────────────────────────────────
dir_part=$(printf "\033[36m%s\033[0m" "$dir_display")

right_part="$model"
if [ -n "$ctx_bar" ]; then
  right_part="$ctx_bar | $model"
fi

printf "%s%s%s  \033[2m%s\033[0m" "$dir_part" "$git_info" "$py_info" "$right_part"
