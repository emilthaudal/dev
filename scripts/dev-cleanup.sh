#!/bin/zsh
# Daily disk cleanup: prunes old Docker data in Colima and removes git worktrees
# whose PR is merged. Run by ~/Library/LaunchAgents/com.emtb.dev-cleanup.plist.
# DRY_RUN=1 dev-cleanup.sh  -> report only, delete nothing.

export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
DEV="$HOME/Developer"
DRY_RUN=${DRY_RUN:-0}

echo "=== $(date '+%F %T') dev-cleanup (dry_run=$DRY_RUN)"

# --- Docker (Colima) -------------------------------------------------------
# Only touches things unused for 3+ days so today's images and cache survive.
if colima status >/dev/null 2>&1; then
  if [[ $DRY_RUN == 1 ]]; then
    docker system df
  else
    docker container prune -f --filter until=24h | tail -1
    docker image prune -af --filter until=72h | tail -1
    docker builder prune -af --filter until=72h | tail -1
    # No volume prune: stopped DBs keep their data in anonymous volumes.
    docker network prune -f --filter until=24h >/dev/null
    colima ssh -- sudo fstrim -a >/dev/null 2>&1
  fi
else
  echo "colima not running, skipping docker"
fi

# --- Worktrees -------------------------------------------------------------
# Tokens are per call, so the active gh account is never switched.
WORK_TOKEN=$(gh auth token --user emilthaudalwg 2>/dev/null)
PERSONAL_TOKEN=$(gh auth token --user emilthaudal 2>/dev/null)
# Directories some process (e.g. a running agent or shell) is sitting in.
BUSY=$(lsof -a -d cwd -Fn 2>/dev/null | sed -n 's/^n//p')
REGENERABLE='(^|/)(node_modules|dist|build|out|coverage|\.turbo|\.next|\.nyc_output|\.cache|cdk\.out|\.serverless|test-results|generated)(/|$)|(^|/)\.yarn/(cache|unplugged|install-state\.gz|build-state\.yml)|(^|/)\.DS_Store$|\.tsbuildinfo$|\.eslintcache$'

find "$DEV" -maxdepth 4 -name .git -type d -prune 2>/dev/null | while read -r g; do
  repo=${g:h}
  [[ $repo == $DEV/wag/* ]] && token=$WORK_TOKEN || token=$PERSONAL_TOKEN

  git -C "$repo" worktree prune
  git -C "$repo" worktree list --porcelain | awk '/^worktree/{p=substr($0,10)} /^branch/{print p "\t" substr($0,8)}' | tail -n +2 |
  while IFS=$'\t' read -r wt ref; do
    branch=${ref#refs/heads/}
    name=${wt:t}

    if [[ -n $(git -C "$wt" status --porcelain 2>/dev/null) ]]; then
      echo "keep $name: uncommitted changes"; continue
    fi
    # Ignored files are deleted too, so only allow regenerable build output.
    extra=$(git -C "$wt" status --porcelain --ignored 2>/dev/null | sed -n 's/^!! //p' | grep -vE "$REGENERABLE" | head -3)
    if [[ -n $extra ]]; then
      echo "keep $name: ignored files ${(f)extra}"; continue
    fi
    if [[ -z $(git -C "$wt" branch -r --contains HEAD 2>/dev/null) ]]; then
      echo "keep $name: unpushed commits"; continue
    fi
    if print -l -- $BUSY | grep -q "^$wt\(/\|$\)"; then
      echo "keep $name: in use"; continue
    fi
    # e.g. a plugin marketplace loaded from a worktree
    if grep -qF "\"$wt\"" "$HOME/.claude/settings.json" 2>/dev/null; then
      echo "keep $name: referenced in ~/.claude/settings.json"; continue
    fi
    state=$(cd "$repo" && GH_TOKEN=$token gh pr list --head "$branch" --state all --json state -q '.[0].state' 2>/dev/null)
    if [[ $state != MERGED ]]; then
      echo "keep $name: PR ${state:-none}"; continue
    fi

    size=$(du -sh "$wt" 2>/dev/null | cut -f1)
    if [[ $DRY_RUN == 1 ]]; then
      echo "would remove $name ($size)"
    elif git -C "$repo" worktree remove "$wt" 2>&1; then
      echo "removed $name ($size)"
    else
      echo "FAILED $name"
    fi
  done
done

df -h "$HOME" | tail -1
