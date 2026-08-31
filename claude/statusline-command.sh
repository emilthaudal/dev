#!/usr/bin/env bash
# Claude Code status line — spaceship/powerline-inspired, Nerd Font icons

input=$(cat)

cwd=$(echo "$input" | jq -r '.cwd // .workspace.current_dir // ""')
model=$(echo "$input" | jq -r '.model.display_name // ""')
repo_owner=$(echo "$input" | jq -r '.workspace.repo.owner // ""')
repo_name=$(echo "$input" | jq -r '.workspace.repo.name // ""')
worktree_branch=$(echo "$input" | jq -r '.worktree.branch // ""')
git_worktree=$(echo "$input" | jq -r '.workspace.git_worktree // ""')
remaining=$(echo "$input" | jq -r '.context_window.remaining_percentage // empty')
five_hour=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
five_hour_reset=$(echo "$input" | jq -r '.rate_limits.five_hour.reset_at // empty')
seven_day=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
cost_usd=$(echo "$input" | jq -r '.cost.total_cost_usd // empty')
duration_ms=$(echo "$input" | jq -r '.cost.total_duration_ms // empty')
lines_added=$(echo "$input" | jq -r '.cost.total_lines_added // empty')
lines_removed=$(echo "$input" | jq -r '.cost.total_lines_removed // empty')

user=$(whoami)
host=$(hostname -s)
dir=$(basename "$cwd")

# ANSI color codes
RESET='\033[0m'
BOLD='\033[1m'
CYAN='\033[36m'
GREEN='\033[32m'
YELLOW='\033[33m'
BLUE='\033[34m'
MAGENTA='\033[35m'
DIM='\033[2m'
RED='\033[31m'

# Nerd Font icons (Font Awesome / powerline codepoints, via \u escapes for portability)
ICON_DIR=$''         # folder-open
ICON_BRANCH=$''      # powerline git branch
ICON_CLOCK=$''       # clock-o
ICON_CHIP=$''        # microchip
ICON_HOURGLASS=$''   # hourglass-half (5h window)
ICON_CALENDAR=$''    # calendar (7d window)
ICON_DIRTY=$'✚'       # heavy greek cross (dirty files)
ICON_AHEAD=$'↑'       # up arrow
ICON_BEHIND=$'↓'      # down arrow

# render an N-char block bar for a 0-100 percentage
render_bar() {
    local pct=$1 len=$2 filled empty bar=""
    filled=$((pct * len / 100))
    empty=$((len - filled))
    for ((i = 0; i < filled; i++)); do bar="${bar}█"; done
    for ((i = 0; i < empty; i++)); do bar="${bar}░"; done
    echo "$bar"
}

# color for a used-percentage, low->high thresholds
color_for_used_pct() {
    local pct=$1
    if [ "$pct" -ge 90 ]; then
        echo "${RED}"
    elif [ "$pct" -ge 70 ]; then
        echo "${YELLOW}"
    else
        echo "${GREEN}"
    fi
}

parts=()

# user@host
parts+=("$(printf "${CYAN}${user}${RESET}${DIM}@${RESET}${CYAN}${host}${RESET}")")

# current directory
parts+=("$(printf "${BOLD}${BLUE}${ICON_DIR} ${dir}${RESET}")")

# git repo/branch/status
if [ -n "$repo_owner" ] && [ -n "$repo_name" ]; then
    git_info="${repo_owner}/${repo_name}"
    branch=""
    if [ -n "$worktree_branch" ]; then
        branch="$worktree_branch"
    elif [ -n "$git_worktree" ]; then
        branch="$git_worktree"
    else
        branch=$(git -C "$cwd" --no-optional-locks symbolic-ref --short HEAD 2>/dev/null)
    fi
    [ -n "$branch" ] && git_info="${git_info} ${ICON_BRANCH} ${branch}"

    # dirty file count
    dirty_count=$(git -C "$cwd" --no-optional-locks status --porcelain 2>/dev/null | wc -l | tr -d ' ')
    if [ -n "$dirty_count" ] && [ "$dirty_count" -gt 0 ] 2>/dev/null; then
        git_info="${git_info} $(printf "${YELLOW}${ICON_DIRTY}${dirty_count}${GREEN}")"
    fi

    # ahead/behind vs upstream
    ab=$(git -C "$cwd" --no-optional-locks rev-list --left-right --count '@{u}...HEAD' 2>/dev/null)
    if [ -n "$ab" ]; then
        behind=$(echo "$ab" | awk '{print $1}')
        ahead=$(echo "$ab" | awk '{print $2}')
        [ "$ahead" -gt 0 ] 2>/dev/null && git_info="${git_info} $(printf "${CYAN}${ICON_AHEAD}${ahead}${GREEN}")"
        [ "$behind" -gt 0 ] 2>/dev/null && git_info="${git_info} $(printf "${RED}${ICON_BEHIND}${behind}${GREEN}")"
    fi

    parts+=("$(printf "${GREEN}${git_info}${RESET}")")
fi

# model
if [ -n "$model" ]; then
    parts+=("$(printf "${MAGENTA}${ICON_CHIP} ${model}${RESET}")")
fi

# context remaining as a bar
if [ -n "$remaining" ]; then
    pct=$(printf '%.0f' "$remaining")
    if [ "$pct" -lt 20 ]; then
        color="${RED}"
    elif [ "$pct" -lt 50 ]; then
        color="${YELLOW}"
    else
        color="${DIM}"
    fi
    bar=$(render_bar "$pct" 10)
    parts+=("$(printf "${color}${bar} ${pct}%% left${RESET}")")
fi

# session cost, duration, lines changed
session_parts=()
if [ -n "$cost_usd" ]; then
    cost_fmt=$(printf '%.2f' "$cost_usd")
    session_parts+=("$(printf "${DIM}\$${cost_fmt}${RESET}")")
fi
if [ -n "$duration_ms" ]; then
    secs=$((duration_ms / 1000))
    h=$((secs / 3600))
    m=$(((secs % 3600) / 60))
    if [ "$h" -gt 0 ]; then
        dur_str="${h}h${m}m"
    else
        dur_str="${m}m"
    fi
    session_parts+=("$(printf "${DIM}${ICON_CLOCK} ${dur_str}${RESET}")")
fi
if [ -n "$lines_added" ] || [ -n "$lines_removed" ]; then
    la=${lines_added:-0}
    lr=${lines_removed:-0}
    if [ "$la" -gt 0 ] 2>/dev/null || [ "$lr" -gt 0 ] 2>/dev/null; then
        session_parts+=("$(printf "${GREEN}+${la}${RESET}${DIM}/${RESET}${RED}-${lr}${RESET}")")
    fi
fi
if [ ${#session_parts[@]} -gt 0 ]; then
    session_str=""
    for sp in "${session_parts[@]}"; do
        if [ -z "$session_str" ]; then
            session_str="$sp"
        else
            session_str="${session_str} ${sp}"
        fi
    done
    parts+=("$session_str")
fi

# rate limits (Claude.ai subscription — 5-hour and 7-day windows) as mini bars
rate_parts=()
if [ -n "$five_hour" ]; then
    pct=$(printf '%.0f' "$five_hour")
    color=$(color_for_used_pct "$pct")
    bar=$(render_bar "$pct" 6)
    reset_str=""
    if [ -n "$five_hour_reset" ]; then
        now=$(date +%s)
        # handle both seconds and milliseconds epoch
        if [ "$five_hour_reset" -gt 1000000000000 ] 2>/dev/null; then
            reset_epoch=$((five_hour_reset / 1000))
        else
            reset_epoch=$five_hour_reset
        fi
        diff=$((reset_epoch - now))
        if [ "$diff" -gt 0 ]; then
            h=$((diff / 3600))
            m=$(((diff % 3600) / 60))
            if [ "$h" -gt 0 ]; then
                reset_str="${DIM} (${h}h${m}m)${RESET}"
            else
                reset_str="${DIM} (${m}m)${RESET}"
            fi
        fi
    fi
    rate_parts+=("$(printf "${DIM}${ICON_HOURGLASS} ${RESET}${color}${bar} ${pct}%%${RESET}${reset_str}")")
fi
if [ -n "$seven_day" ]; then
    pct=$(printf '%.0f' "$seven_day")
    color=$(color_for_used_pct "$pct")
    bar=$(render_bar "$pct" 6)
    rate_parts+=("$(printf "${DIM}${ICON_CALENDAR} ${RESET}${color}${bar} ${pct}%%${RESET}")")
fi
if [ ${#rate_parts[@]} -gt 0 ]; then
    rate_str=""
    for rp in "${rate_parts[@]}"; do
        if [ -z "$rate_str" ]; then
            rate_str="$rp"
        else
            rate_str="${rate_str}  ${rp}"
        fi
    done
    parts+=("$rate_str")
fi

# Join with separator
sep="$(printf " ${DIM}|${RESET} ")"
result=""
for part in "${parts[@]}"; do
    if [ -z "$result" ]; then
        result="$part"
    else
        result="${result}${sep}${part}"
    fi
done

printf "%b\n" "$result"
