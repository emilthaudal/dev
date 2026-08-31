# EMTB Dev Environment

> Last updated: July 2026

## Stack overview

```
Ghostty  →  herdr  →  zsh + Starship
```

| Layer      | Tool                     | Notes                                      |
| ---------- | ------------------------ | ------------------------------------------ |
| Terminal   | **Ghostty**              | GPU-rendered, macOS-native                 |
| Multiplexer| **herdr**                | Workspaces, panes, tabs. Prefix: `ctrl+b`  |
| Shell      | **zsh** (no OMZ)         | Plugins loaded directly via Homebrew       |
| Prompt     | **Starship** v1.26       | Catppuccin Mocha, Nerd Font icons          |
| Font       | **Maple Mono NF**        | Ligatures, Nerd Font built-in              |
| Theme      | **Catppuccin Mocha**     | Consistent across Ghostty, herdr, Starship, delta, bat, fzf |

---

## Terminal: Ghostty

Config: `~/Library/Application Support/com.mitchellh.ghostty/config`

Key settings:
- Font: `MapleMono NF`, size 13, ligatures on (`calt`, `liga`)
- Theme: `catppuccin-mocha`
- `macos-option-as-alt = true` — enables `⌥+Backspace` word delete, `⌥+←/→` word jump
- Cursor: blinking bar
- Shell integration: zsh

---

## Multiplexer: herdr

Config: `~/.config/herdr/config.toml`

Key bindings (prefix-free `ctrl+alt` chords):

| Action               | Binding              |
| -------------------- | -------------------- |
| Workspace picker     | `ctrl+alt+w`         |
| New workspace        | `ctrl+alt+n`         |
| New tab              | `ctrl+alt+t`         |
| Close pane           | `ctrl+alt+x`         |
| Pane navigation      | `ctrl+alt+h/j/k/l`   |
| Split vertical       | `ctrl+alt+d`         |
| Split horizontal     | `ctrl+alt+shift+s`   |
| Toggle sidebar       | `ctrl+alt+s`         |
| Open lazygit         | `ctrl+alt+i`         |
| Fuzzy goto           | `ctrl+alt+g`         |

Fallback prefix: `ctrl+b` (tmux-style)

---

## Shell: zsh

Config: `~/.zshrc`

No Oh My Zsh. Plugins sourced directly from Homebrew:

| Plugin                   | Source                                               | Purpose                              |
| ------------------------ | ---------------------------------------------------- | ------------------------------------ |
| zsh-autosuggestions      | `/opt/homebrew/share/zsh-autosuggestions/`           | Fish-style inline suggestions        |
| zsh-syntax-highlighting  | `/opt/homebrew/share/zsh-syntax-highlighting/`       | Real-time command colouring          |
| zsh-you-should-use       | `/opt/homebrew/share/zsh-you-should-use/`            | Reminds you to use existing aliases  |

Git aliases (160+) live in `~/.config/zsh/git-aliases.zsh` — ported from the OMZ git plugin, no OMZ dependency.

Secrets (e.g. `NPM_TOKEN`) stored in `~/.secrets` (chmod 600, gitignored), sourced at shell start.

---

## Prompt: Starship

Config: `~/.config/starship.toml`

Segments shown: OS icon → directory → git branch/status → Node/Bun/Python/Rust/Docker → command duration

---

## CLI tools

### Navigation & search

| Tool      | Replaces  | Usage                                                      |
| --------- | --------- | ---------------------------------------------------------- |
| **zoxide**  | `cd`        | `z <query>` — jump to frecent dir; `zi` — interactive picker |
| **fzf**     | —           | `Ctrl+T` file picker, `Alt+C` fuzzy cd. Used by zoxide `zi` |
| **fd**      | `find`      | Backing fzf's file search (`FZF_DEFAULT_COMMAND`)           |
| **ripgrep** | `grep`      | Fast recursive search                                       |

### File viewing

| Tool   | Replaces | Usage                                                       |
| ------ | -------- | ----------------------------------------------------------- |
| **bat**  | `cat`    | Syntax-highlighted output. Also renders `man` pages         |
| **eza**  | `ls`     | Icons, git status, relative timestamps                      |

`ls` aliases:
```
ls   — icons + dirs first
la   — same + hidden files
ll   — long format + git status + relative timestamps
lt   — tree, 2 levels
ltt  — tree, 3 levels
```

### Git

| Tool      | Purpose                                                       |
| --------- | ------------------------------------------------------------- |
| **delta**   | Git diff pager — syntax highlighted, line numbers, Catppuccin |
| **lazygit** | TUI git client, opened via `ctrl+alt+i` in herdr              |
| **gh**      | GitHub CLI                                                    |

delta config in `~/.gitconfig` — hooks in automatically via `core.pager`.

### History

| Tool      | Binding    | Purpose                                                   |
| --------- | ---------- | --------------------------------------------------------- |
| **atuin**   | `Ctrl+R`   | SQLite history across all sessions — timestamps, exit codes, cwd context |

---

## Version management

- **nvm** — Node.js (installed, lazy-loaded)
- **bun** — JS runtime + package manager (`~/.bun/bin` on PATH)

---

## Other tools

- **Colima** — Docker Desktop replacement. `DOCKER_HOST` set in `.zshrc`
- **JetBrains Toolbox** — IDE launcher scripts on PATH
- **Aikido Security** — endpoint protection, injects CA certs into `.zshrc` (do not remove)
- **hatch** — Python project manager (`~/.local/bin`)
- **sonarqube-cli** — static analysis (`~/.local/share/sonarqube-cli/bin`)

---

## Claude Code

Config: `~/.claude/settings.json`

- Permissions default to `auto` mode; output style `Concise`; effort level `high` for Opus/Sonnet
- Statusline: custom script showing user@host, cwd, git branch/dirty count/ahead-behind, model, context-remaining bar, session cost/duration/lines changed, and 5h/7d rate-limit bars
- `SessionStart` hook wired to herdr's pane-tracking integration (`~/.claude/hooks/herdr-agent-state.sh`) — that hook file itself is **not** stored here; it's auto-installed/overwritten by `herdr`'s Claude integration on setup, not hand-maintained

`claude/settings.json` in this repo hardcodes `/Users/emtb/...` paths for the hooks/statusline commands — update the username if restoring onto a different account.

---

## Config files in this repo

| File                              | Description                        |
| --------------------------------- | ---------------------------------- |
| `zshrc`                           | Main shell config                  |
| `zprofile`                        | Login shell (brew shellenv only)   |
| `config/zsh/git-aliases.zsh`      | Git aliases (160+), no OMZ needed  |
| `config/starship.toml`            | Starship prompt config             |
| `config/herdr/config.toml`        | herdr multiplexer config           |
| `ghostty/config`                  | Ghostty terminal config            |
| `gitconfig`                       | Git config (delta, user, etc.)     |
| `claude/settings.json`            | Claude Code settings (statusline, hooks, permissions) |
| `claude/statusline-command.sh`    | Claude Code statusline script      |

---

## Installation (fresh machine)

```sh
# 1. Install Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 2. Install tools
brew install starship zsh-autosuggestions zsh-syntax-highlighting zsh-you-should-use \
             zoxide fzf atuin eza bat git-delta fd ripgrep lazygit gh \
             zsh-you-should-use

brew install --cask ghostty font-maple-mono-nf

# 3. Copy config files from this repo (see table above)

# 4. Set up ~/.secrets with NPM_TOKEN (and any other secrets)
echo 'export NPM_TOKEN="..."' > ~/.secrets && chmod 600 ~/.secrets

# 5. Build bat theme cache
bat cache --build

# 6. Copy Claude Code config (fix the /Users/emtb path inside settings.json first)
cp claude/settings.json ~/.claude/settings.json
cp claude/statusline-command.sh ~/.claude/statusline-command.sh

# 7. Restart terminal
```
