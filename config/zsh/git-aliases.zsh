# Git aliases — ported from Oh My Zsh git plugin
# https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/git

# ── HELPER FUNCTIONS ────────────────────────────────────────────────────────

function git_current_branch() {
  local ref
  ref=$(command git symbolic-ref --quiet HEAD 2>/dev/null)
  local ret=$?
  if [[ $ret != 0 ]]; then
    [[ $ret == 128 ]] && return  # not in a git repo
    ref=$(command git rev-parse --short HEAD 2>/dev/null) || return
  fi
  echo ${ref#refs/heads/}
}

function git_main_branch() {
  command git rev-parse --git-dir &>/dev/null || return
  local ref
  for ref in refs/{heads,remotes/{origin,upstream}}/{main,trunk,mainline,default,stable,master}; do
    if command git show-ref -q --verify $ref; then
      echo ${ref:t}
      return 0
    fi
  done
  echo main
}

function git_develop_branch() {
  command git rev-parse --git-dir &>/dev/null || return
  local branch
  for branch in dev devel develop development; do
    if command git show-ref -q --verify refs/heads/$branch; then
      echo $branch
      return 0
    fi
  done
  echo develop
}

function _git_log_prettily() {
  [[ -n $1 ]] && git log --pretty=$1
}

# ── ALIASES ─────────────────────────────────────────────────────────────────

alias g='git'

# add
alias ga='git add'
alias gaa='git add --all'
alias gapa='git add --patch'
alias gau='git add --update'
alias gav='git add --verbose'

# apply
alias gap='git apply'
alias gapt='git apply --3way'

# am
alias gam='git am'
alias gama='git am --abort'
alias gamc='git am --continue'
alias gams='git am --skip'
alias gamscp='git am --show-current-patch'

# branch
alias gb='git branch'
alias gba='git branch --all'
alias gbd='git branch --delete'
alias gbD='git branch --delete --force'
alias gbm='git branch --move'
alias gbnm='git branch --no-merged'
alias gbr='git branch --remote'
alias gbg='LANG=C git branch -vv | grep ": gone\]"'
alias gbgd='LANG=C git branch --no-color -vv | grep ": gone\]" | cut -c 3- | awk '"'"'{print $1}'"'"' | xargs git branch -d'
alias gbgD='LANG=C git branch --no-color -vv | grep ": gone\]" | cut -c 3- | awk '"'"'{print $1}'"'"' | xargs git branch -D'

# bisect
alias gbs='git bisect'
alias gbsb='git bisect bad'
alias gbsg='git bisect good'
alias gbsn='git bisect new'
alias gbso='git bisect old'
alias gbsr='git bisect reset'
alias gbss='git bisect start'

# blame
alias gbl='git blame -w'

# checkout
alias gco='git checkout'
alias gcb='git checkout -b'
alias gcB='git checkout -B'
alias gcm='git checkout $(git_main_branch)'
alias gcd='git checkout $(git_develop_branch)'
alias gcor='git checkout --recurse-submodules'

# cherry-pick
alias gcp='git cherry-pick'
alias gcpa='git cherry-pick --abort'
alias gcpc='git cherry-pick --continue'

# clean
alias gclean='git clean --interactive -d'
alias gpristine='git reset --hard && git clean --force -dfx'

# clone
alias gcl='git clone --recurse-submodules'
alias gclf='git clone --recursive --shallow-submodules --filter=blob:none --also-filter-submodules'

# commit
alias gc='git commit --verbose'
alias gc!='git commit --verbose --amend'
alias gcn='git commit --verbose --no-edit'
alias gcn!='git commit --verbose --no-edit --amend'
alias gca='git commit --verbose --all'
alias gca!='git commit --verbose --all --amend'
alias gcan!='git commit --verbose --all --no-edit --amend'
alias gcans!='git commit --verbose --all --signoff --no-edit --amend'
alias gcann!='git commit --verbose --all --date=now --no-edit --amend'
alias gcam='git commit --all --message'
alias gcas='git commit --all --signoff'
alias gcasm='git commit --all --signoff --message'
alias gcmsg='git commit --message'
alias gcs='git commit --gpg-sign'
alias gcsm='git commit --signoff --message'
alias gcss='git commit --gpg-sign --signoff'
alias gcssm='git commit --gpg-sign --signoff --message'
alias gcfu='git commit --fixup'

# config
alias gcf='git config --list'

# count
alias gcount='git shortlog --summary --numbered'

# diff
alias gd='git diff'
alias gdca='git diff --cached'
alias gdcw='git diff --cached --word-diff'
alias gds='git diff --staged'
alias gdw='git diff --word-diff'
alias gdt='git diff-tree --no-commit-id --name-only -r'
alias gdup='git diff @{upstream}'
alias gdct='git describe --tags $(git rev-list --tags --max-count=1)'

# describe
# (gdct above)

# fetch
alias gf='git fetch'
alias gfo='git fetch origin'

# grep / ls-files
alias gfg='git ls-files | grep'

# help
alias ghh='git help'

# log
alias gl='git pull'
alias glg='git log --stat'
alias glgp='git log --stat --patch'
alias glgg='git log --graph'
alias glgga='git log --graph --decorate --all'
alias glgm='git log --graph --max-count=10'
alias glo='git log --oneline --decorate'
alias glog='git log --oneline --decorate --graph'
alias gloga='git log --oneline --decorate --graph --all'
alias glol='git log --graph --pretty="%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ar) %C(bold blue)<%an>%Creset"'
alias glols='git log --graph --pretty="%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ar) %C(bold blue)<%an>%Creset" --stat'
alias glola='git log --graph --pretty="%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ar) %C(bold blue)<%an>%Creset" --all'
alias glod='git log --graph --pretty="%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ad) %C(bold blue)<%an>%Creset"'
alias glods='git log --graph --pretty="%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ad) %C(bold blue)<%an>%Creset" --date=short'
alias glp='_git_log_prettily'
alias gluc='git pull upstream $(git_current_branch)'
alias glum='git pull upstream $(git_main_branch)'

# merge
alias gm='git merge'
alias gma='git merge --abort'
alias gmc='git merge --continue'
alias gms='git merge --squash'
alias gmff='git merge --ff-only'
alias gmom='git merge origin/$(git_main_branch)'
alias gmum='git merge upstream/$(git_main_branch)'
alias gmtl='git mergetool --no-prompt'
alias gmtlvim='git mergetool --no-prompt --tool=vimdiff'

# push
alias gp='git push'
alias gpd='git push --dry-run'
alias gpf!='git push --force'
alias gpsup='git push --set-upstream origin $(git_current_branch)'
alias gpv='git push --verbose'
alias gpoat='git push origin --all && git push origin --tags'
alias gpod='git push origin --delete'
alias gpu='git push upstream'

# pull
alias gpr='git pull --rebase'
alias gpra='git pull --rebase --autostash'
alias gprav='git pull --rebase --autostash -v'
alias gprv='git pull --rebase -v'
alias gprom='git pull --rebase origin $(git_main_branch)'
alias gpromi='git pull --rebase=interactive origin $(git_main_branch)'
alias gprum='git pull --rebase upstream $(git_main_branch)'
alias gprumi='git pull --rebase=interactive upstream $(git_main_branch)'
alias ggpull='git pull origin "$(git_current_branch)"'
alias ggpush='git push origin "$(git_current_branch)"'
alias ggsup='git branch --set-upstream-to=origin/$(git_current_branch)'

# rebase
alias grb='git rebase'
alias grba='git rebase --abort'
alias grbc='git rebase --continue'
alias grbd='git rebase $(git_develop_branch)'
alias grbi='git rebase --interactive'
alias grbm='git rebase $(git_main_branch)'
alias grbom='git rebase origin/$(git_main_branch)'
alias grbo='git rebase --onto'
alias grbs='git rebase --skip'
alias grbum='git rebase upstream/$(git_main_branch)'

# reflog
alias grf='git reflog'

# remote
alias gr='git remote'
alias gra='git remote add'
alias grmv='git remote rename'
alias grrm='git remote remove'
alias grset='git remote set-url'
alias grup='git remote update'
alias grv='git remote --verbose'

# reset
alias grh='git reset'
alias grhh='git reset --hard'
alias grhk='git reset --keep'
alias grhs='git reset --soft'
alias groh='git reset origin/$(git_current_branch) --hard'
alias gru='git reset --'

# restore
alias grs='git restore'
alias grss='git restore --source'
alias grst='git restore --staged'

# revert
alias grev='git revert'
alias greva='git revert --abort'
alias grevc='git revert --continue'

# rm
alias grm='git rm'
alias grmc='git rm --cached'

# show
alias gsh='git show'
alias gsps='git show --pretty=short --show-signature'

# stash
alias gsta='git stash push'
alias gstaa='git stash apply'
alias gstall='git stash --all'
alias gstc='git stash clear'
alias gstd='git stash drop'
alias gstl='git stash list'
alias gstp='git stash pop'
alias gsts='git stash show --patch'
alias gstu='git stash push --include-untracked'

# status
alias gst='git status'
alias gss='git status --short'
alias gsb='git status --short --branch'

# submodule
alias gsi='git submodule init'
alias gsu='git submodule update'

# switch
alias gsw='git switch'
alias gswc='git switch --create'
alias gswm='git switch $(git_main_branch)'
alias gswd='git switch $(git_develop_branch)'

# tag
alias gta='git tag --annotate'
alias gts='git tag --sign'
alias gtv='git tag | sort -V'
alias gtl='gtl(){ git tag --sort=-v:refname -n --list "${1}*" }; noglob gtl'

# worktree
alias gwt='git worktree'
alias gwta='git worktree add'
alias gwtls='git worktree list'
alias gwtmv='git worktree move'
alias gwtrm='git worktree remove'

# assume-unchanged
alias gignore='git update-index --assume-unchanged'
alias gignored='git ls-files -v | grep "^[[:lower:]]"'
alias gunignore='git update-index --no-assume-unchanged'

# wip (work in progress)
alias gwip='git add -A; git rm $(git ls-files --deleted) 2>/dev/null; git commit --no-verify --no-gpg-sign --message "--wip-- [skip ci]"'
alias gunwip='git rev-list --max-count=1 --format="%s" HEAD | grep -q "\--wip--" && git reset HEAD~1'
alias gwipe='git reset --hard && git clean --force -df'

# goto repo root
alias grt='cd "$(git rev-parse --show-toplevel || echo .)"'

# log with author stats
alias gwch='git log --patch --abbrev-commit --pretty=medium --raw'
