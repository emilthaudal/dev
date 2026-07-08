# ── PATH ────────────────────────────────────────────────────────────────────
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.local/share/sonarqube-cli/bin:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"
export PATH="$PATH:$HOME/Library/Application Support/JetBrains/Toolbox/scripts"

# ── TOOLS ───────────────────────────────────────────────────────────────────
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# Colima (Docker Desktop replacement)
export DOCKER_HOST="unix://$HOME/.colima/default/docker.sock"
export TESTCONTAINERS_DOCKER_SOCKET_OVERRIDE="/var/run/docker.sock"

# ── SECRETS ─────────────────────────────────────────────────────────────────
# Secrets are stored in ~/.secrets (not committed to version control)
[[ -f "$HOME/.secrets" ]] && source "$HOME/.secrets"

# ── HISTORY ─────────────────────────────────────────────────────────────────
HISTSIZE=10000
SAVEHIST=10000
HISTFILE="$HOME/.zsh_history"
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt SHARE_HISTORY
setopt APPEND_HISTORY

# ── COMPLETION ──────────────────────────────────────────────────────────────
autoload -Uz compinit
compinit -i
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' # case-insensitive

# ── PLUGINS (via Homebrew) ───────────────────────────────────────────────────
# zsh-autosuggestions
source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh

# zsh-syntax-highlighting (must be last plugin sourced)
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# zsh-you-should-use
source /opt/homebrew/share/zsh-you-should-use/you-should-use.plugin.zsh

# ── KEYBINDINGS ─────────────────────────────────────────────────────────────
bindkey '^[^[[D' backward-word   # alt+left  — word jump
bindkey '^[^[[C' forward-word    # alt+right — word jump
# (up/down arrow history search is handled by atuin below)

# ── BUN COMPLETIONS ─────────────────────────────────────────────────────────
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# ── ZOXIDE (smart cd) ───────────────────────────────────────────────────────
# z <query> to jump to frecent dirs; zi for interactive picker (uses fzf)
eval "$(zoxide init zsh)"

# ── FZF ─────────────────────────────────────────────────────────────────────
# Ctrl+T: fuzzy file picker  Ctrl+R: fuzzy history  Alt+C: fuzzy cd
source <(fzf --zsh)
export FZF_DEFAULT_OPTS="
  --color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8
  --color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc
  --color=marker:#b4befe,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8
  --color=selected-bg:#45475a
  --height 40% --border rounded --layout reverse
"
# Use fd for fzf file finding (respects .gitignore, faster)
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'

# ── ATUIN (shell history) ────────────────────────────────────────────────────
# Ctrl+R: fuzzy search across all sessions with context (replaces default history search)
eval "$(atuin init zsh --disable-up-arrow)"

# ── BAT (better cat) ────────────────────────────────────────────────────────
export BAT_THEME="Catppuccin Mocha"
# Use bat for man pages
export MANPAGER="sh -c 'col -bx | bat -l man -p'"
export MANROFFOPT="-c"

# ── EZA + LS ALIASES ────────────────────────────────────────────────────────
alias ls='eza --icons --group-directories-first'
alias la='eza --icons --group-directories-first -a'
alias ll='eza --icons --group-directories-first -la --git --time-style=relative'
alias lt='eza --icons --tree --level=2 --group-directories-first'
alias ltt='eza --icons --tree --level=3 --group-directories-first'

# ── PROMPT: STARSHIP ────────────────────────────────────────────────────────
eval "$(starship init zsh)"

# ── GIT ALIASES ─────────────────────────────────────────────────────────────
source "$HOME/.config/zsh/git-aliases.zsh"

# ── AIKIDO ENDPOINT PROTECTION ──────────────────────────────────────────────
# (Managed by Aikido Security — do not edit manually)
# aikido-endpoint-cert-config-start
export NODE_EXTRA_CA_CERTS="/Library/Application Support/AikidoSecurity/EndpointProtection/run/endpoint-protection-combined-ca.pem"
# aikido-endpoint-cert-config-end
# aikido-endpoint-pip-cert-config-start
export PIP_CERT="/Library/Application Support/AikidoSecurity/EndpointProtection/run/endpoint-protection-pip-combined-ca.pem"
export REQUESTS_CA_BUNDLE="/Library/Application Support/AikidoSecurity/EndpointProtection/run/endpoint-protection-pip-combined-ca.pem"
export POETRY_CERTIFICATES_PYPI_CERT="/Library/Application Support/AikidoSecurity/EndpointProtection/run/endpoint-protection-pip-combined-ca.pem"
export UV_SYSTEM_CERTS=true
# aikido-endpoint-pip-cert-config-end
# aikido-endpoint-ruby-cert-config-start
export BUNDLE_SSL_CA_CERT="/Library/Application Support/AikidoSecurity/EndpointProtection/run/endpoint-protection-ruby-combined-ca.pem"
# aikido-endpoint-ruby-cert-config-end
# aikido-endpoint-curl-cert-config-start
export CURL_CA_BUNDLE="/Library/Application Support/AikidoSecurity/EndpointProtection/run/endpoint-protection-openssl-combined-ca.pem"
# aikido-endpoint-curl-cert-config-end
