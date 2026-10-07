#!/usr/bin/env bash
# Claude Code status line — aurora palette shared with the agent-progress mod, Nerd Font icons

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

rgb() { printf '\033[38;2;%d;%d;%dm' "$1" "$2" "$3"; }

RESET='\033[0m'
BOLD='\033[1m'
LAVENDER=$(rgb 196 181 253)
MUTED=$(rgb 124 106 166)
RULE=$(rgb 76 58 120)
PINK=$(rgb 236 72 153)
PURPLE=$(rgb 167 139 250)
BLUE=$(rgb 96 165 250)
CYAN=$(rgb 34 211 238)
OK=$(rgb 52 211 153)
WARN=$(rgb 251 191 36)
BAD=$(rgb 244 63 94)

STOP_R=(124 192 236 139 59 34)
STOP_G=(58 38 72 92 130 211)
STOP_B=(237 211 153 246 246 238)

# The agent-progress mod reads the same palette, so both stay in one colour scheme.
PALETTE="$HOME/.claude/aurora-palette.json"
if [ -f "$PALETTE" ]; then
    stops_seen=0
    while read -r key value; do
        [[ "$value" =~ ^#[0-9a-fA-F]{6}$ ]] || continue
        h=${value#\#}
        r=$((16#${h:0:2})) g=$((16#${h:2:2})) b=$((16#${h:4:2}))
        case "$key" in
            stop)
                if [ "$stops_seen" -eq 0 ]; then STOP_R=() STOP_G=() STOP_B=(); fi
                stops_seen=1
                STOP_R+=("$r") STOP_G+=("$g") STOP_B+=("$b")
                ;;
            lavender) LAVENDER=$(rgb "$r" "$g" "$b") ;;
            muted) MUTED=$(rgb "$r" "$g" "$b") ;;
            rule) RULE=$(rgb "$r" "$g" "$b") ;;
            pink) PINK=$(rgb "$r" "$g" "$b") ;;
            purple) PURPLE=$(rgb "$r" "$g" "$b") ;;
            blue) BLUE=$(rgb "$r" "$g" "$b") ;;
            cyan) CYAN=$(rgb "$r" "$g" "$b") ;;
            ok) OK=$(rgb "$r" "$g" "$b") ;;
            warn) WARN=$(rgb "$r" "$g" "$b") ;;
            bad) BAD=$(rgb "$r" "$g" "$b") ;;
        esac
    done < <(jq -r 'to_entries[] | if .key == "stops" then .value[] | "stop \(.)" else "\(.key) \(.value)" end' "$PALETTE" 2>/dev/null)
fi

# gradient colour at pos 0..1000
grad() {
    local n=$((${#STOP_R[@]} - 1)) span i f
    span=$(($1 * n))
    i=$((span / 1000))
    [ "$i" -ge "$n" ] && i=$((n - 1))
    f=$((span - i * 1000))
    rgb $((STOP_R[i] + (STOP_R[i + 1] - STOP_R[i]) * f / 1000)) \
        $((STOP_G[i] + (STOP_G[i + 1] - STOP_G[i]) * f / 1000)) \
        $((STOP_B[i] + (STOP_B[i + 1] - STOP_B[i]) * f / 1000))
}

# render an N-cell ━/─ bar for a 0-100 percentage; a colour argument replaces the gradient
render_bar() {
    local pct=$1 len=$2 solid=$3 filled bar="" i
    filled=$((pct * len / 100))
    for ((i = 0; i < len; i++)); do
        if [ "$i" -lt "$filled" ]; then
            bar="${bar}${solid:-$(grad $((i * 1000 / (len > 1 ? len - 1 : 1))))}━"
        elif [ "$i" -eq "$filled" ]; then
            bar="${bar}${RULE}╺"
        else
            bar="${bar}${RULE}─"
        fi
    done
    printf '%s%b' "$bar" "$RESET"
}

# solid colour for a used-percentage once it gets high; empty keeps the gradient
alarm_for_used_pct() {
    local pct=$1
    if [ "$pct" -ge 90 ]; then
        echo "${BAD}"
    elif [ "$pct" -ge 70 ]; then
        echo "${WARN}"
    fi
}

ICON_DIR=$''
ICON_BRANCH=$''
ICON_CLOCK=$''
ICON_CHIP=$''
ICON_HOURGLASS=$''
ICON_CALENDAR=$''
ICON_PR=$''

parts=()

parts+=("$(printf "${LAVENDER}${user}${MUTED}@${LAVENDER}${host}${RESET}")")
parts+=("$(printf "${BOLD}${PINK}${ICON_DIR} ${dir}${RESET}")")

if [ -n "$repo_owner" ] && [ -n "$repo_name" ]; then
    git_info="${BLUE}${repo_owner}/${repo_name}"
    branch=""
    if [ -n "$worktree_branch" ]; then
        branch="$worktree_branch"
    elif [ -n "$git_worktree" ]; then
        branch="$git_worktree"
    else
        branch=$(git -C "$cwd" --no-optional-locks symbolic-ref --short HEAD 2>/dev/null)
    fi
    [ -n "$branch" ] && git_info="${git_info} ${PURPLE}${ICON_BRANCH} ${branch}"

    dirty_count=$(git -C "$cwd" --no-optional-locks status --porcelain 2>/dev/null | wc -l | tr -d ' ')
    if [ -n "$dirty_count" ] && [ "$dirty_count" -gt 0 ] 2>/dev/null; then
        git_info="${git_info} ${WARN}✚${dirty_count}"
    fi

    ab=$(git -C "$cwd" --no-optional-locks rev-list --left-right --count '@{u}...HEAD' 2>/dev/null)
    if [ -n "$ab" ]; then
        behind=$(echo "$ab" | awk '{print $1}')
        ahead=$(echo "$ab" | awk '{print $2}')
        [ "$ahead" -gt 0 ] 2>/dev/null && git_info="${git_info} ${CYAN}↑${ahead}"
        [ "$behind" -gt 0 ] 2>/dev/null && git_info="${git_info} ${BAD}↓${behind}"
    fi

    parts+=("$(printf "${git_info}${RESET}")")
fi

if [ -n "$model" ]; then
    parts+=("$(printf "${PURPLE}${ICON_CHIP} ${model}${RESET}")")
fi

if [ -n "$remaining" ]; then
    pct=$(printf '%.0f' "$remaining")
    solid=""
    [ "$pct" -lt 20 ] && solid="${BAD}"
    [ "$pct" -ge 20 ] && [ "$pct" -lt 50 ] && solid="${WARN}"
    parts+=("$(render_bar "$pct" 10 "$solid")$(printf " ${MUTED}${pct}%% left${RESET}")")
fi

session_parts=()
if [ -n "$cost_usd" ]; then
    session_parts+=("$(printf "${MUTED}\$$(printf '%.2f' "$cost_usd")${RESET}")")
fi
if [ -n "$duration_ms" ]; then
    secs=$((duration_ms / 1000))
    h=$((secs / 3600))
    m=$(((secs % 3600) / 60))
    if [ "$h" -gt 0 ]; then dur_str="${h}h${m}m"; else dur_str="${m}m"; fi
    session_parts+=("$(printf "${MUTED}${ICON_CLOCK} ${dur_str}${RESET}")")
fi
la=${lines_added:-0}
lr=${lines_removed:-0}
if [ "$la" -gt 0 ] 2>/dev/null || [ "$lr" -gt 0 ] 2>/dev/null; then
    session_parts+=("$(printf "${OK}+${la}${RULE}/${BAD}-${lr}${RESET}")")
fi
[ ${#session_parts[@]} -gt 0 ] && parts+=("${session_parts[*]}")

rate_parts=()
if [ -n "$five_hour" ]; then
    pct=$(printf '%.0f' "$five_hour")
    reset_str=""
    if [ -n "$five_hour_reset" ]; then
        now=$(date +%s)
        if [ "$five_hour_reset" -gt 1000000000000 ] 2>/dev/null; then
            reset_epoch=$((five_hour_reset / 1000))
        else
            reset_epoch=$five_hour_reset
        fi
        diff=$((reset_epoch - now))
        if [ "$diff" -gt 0 ]; then
            h=$((diff / 3600))
            m=$(((diff % 3600) / 60))
            if [ "$h" -gt 0 ]; then reset_str=" ${MUTED}(${h}h${m}m)"; else reset_str=" ${MUTED}(${m}m)"; fi
        fi
    fi
    rate_parts+=("$(printf "${MUTED}${ICON_HOURGLASS} ")$(render_bar "$pct" 6 "$(alarm_for_used_pct "$pct")")$(printf " ${LAVENDER}${pct}%%${reset_str}${RESET}")")
fi
if [ -n "$seven_day" ]; then
    pct=$(printf '%.0f' "$seven_day")
    rate_parts+=("$(printf "${MUTED}${ICON_CALENDAR} ")$(render_bar "$pct" 6 "$(alarm_for_used_pct "$pct")")$(printf " ${LAVENDER}${pct}%%${RESET}")")
fi
if [ ${#rate_parts[@]} -gt 0 ]; then
    rate_str="${rate_parts[0]}"
    [ ${#rate_parts[@]} -gt 1 ] && rate_str="${rate_str}  ${rate_parts[1]}"
    parts+=("$rate_str")
fi

# open PRs, as the control-panel mod last counted them
pr_file="$HOME/.claude/control-panel-status.json"
if [ -f "$pr_file" ]; then
    age=$(( $(date +%s) - $(stat -f %m "$pr_file" 2>/dev/null || stat -c %Y "$pr_file") ))
    if [ "$age" -lt 900 ]; then
        read -r prs failing running green < <(jq -r '"\(.prs) \(.failing) \(.running) \(.green)"' "$pr_file")
        pr_str="${PINK}${ICON_PR} ${prs}"
        [ "$failing" -gt 0 ] 2>/dev/null && pr_str="${pr_str} ${BAD}✗${failing}"
        [ "$running" -gt 0 ] 2>/dev/null && pr_str="${pr_str} ${WARN}●${running}"
        [ "$green" -gt 0 ] 2>/dev/null && pr_str="${pr_str} ${OK}✓${green}"
        parts+=("$(printf "${pr_str}${RESET}")")
    fi
fi

sep="$(printf " ${RULE}│${RESET} ")"
result=""
for part in "${parts[@]}"; do
    if [ -z "$result" ]; then result="$part"; else result="${result}${sep}${part}"; fi
done

printf "%b\n" "$result"
