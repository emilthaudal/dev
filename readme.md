# EMTB Dev Environment

> Last updated: October 2026

## Stack overview

```
Ghostty  →  herdr  →  zsh + Starship
```

| Layer      | Tool                     | Notes                                      |
| ---------- | ------------------------ | ------------------------------------------ |
| Terminal   | **Ghostty**              | GPU-rendered, macOS-native                 |
| Multiplexer| **herdr**                | Workspaces, panes, tabs. Prefix: `ctrl+b`  |
| Shell      | **zsh** (no OMZ)         | Plugins loaded directly via Homebrew       |
| Prompt     | **Starship** v1.26       | Embark palette, Nerd Font icons            |
| Font       | **Monaspace Argon NF**   | Texture healing + `ss01`–`ss08`, Nerd Font built-in |
| Theme      | **Embark**               | Set once in Ghostty; herdr and Starship follow it. See [Theme](#theme) |

---

## Theme

Embark everywhere, picked with the theme explorer at
https://claude.ai/artifact/HGf6mRax4x6qCD4moX4mYB (previews themes on a mockup of
Ghostty + herdr + VS Code, compares Monaspace Argon vs Neon, and gives the
config lines for each tool).

**Ghostty is the single source of truth.** To change theme, change the
`theme =` line in Ghostty and the tools below follow:

| Tool          | How it gets the theme                                                       |
| ------------- | --------------------------------------------------------------------------- |
| Ghostty       | `theme = Embark`                                                            |
| herdr         | `[theme] name = "terminal"` — uses Ghostty's ANSI colors                    |
| Starship      | `palette = "embark"` + ANSI names (`fg:purple`), hex only in `[palettes.embark]` |
| Claude Code   | `"theme": "auto"`                                                           |
| CC statusline | Its own truecolor palette in `~/.claude/aurora-palette.json` (Embark hex values) |
| VS Code/Cursor| `"workbench.colorTheme": "Embark Theme"` — needs its own setting            |

Still hardcoded to the old Catppuccin colors: the herdr agent sidebar rows
(`[ui.sidebar.agents]`, `#f9e2af` / `#89b4fa` / `#a6e3a1`).

When switching theme, also update `[palettes.*]` in `starship.toml`,
`aurora-palette.json` and the VS Code/Cursor setting.

---

## Terminal: Ghostty

Config: `~/Library/Application Support/com.mitchellh.ghostty/config`

Key settings:
- Font: `Monaspace Argon NF`, size 13, features `calt` + `ss01`–`ss08`
- Theme: `Embark`
- `⌥+Backspace` word delete via an explicit keybind (`alt+backspace=text:\x1b\x7f`);
  `⌥+←/→` word jump is a Ghostty default. `macos-option-as-alt` is deliberately
  **off** so Option still types Danish/compose characters (e.g. `⌥+'` → `@`)
- Native window decorations on, copy-on-select, `bold-is-bright`
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
| Previous/next workspace | `ctrl+alt+↑/↓`    |
| Previous/next agent  | `ctrl+alt+,` / `ctrl+alt+.` |
| Zoom pane            | `ctrl+alt+z`         |
| Dispatch a wag task  | `ctrl+alt+a`         |

Fallback prefix: `ctrl+b` (tmux-style)

Other settings:
- `ctrl+alt+a` opens a popup running `~/.local/bin/wag-task-popup`, which asks
  for a task and starts a Claude agent for it in a new tab via `wag-task`
- Agent sidebar shows four rows per agent: state + workspace + ticket, terminal
  title, repos, PRs. `$ticket`, `$repos` and `$prs` are filled in by the Claude
  hook `~/.claude/hooks/wag-task-context.py`
- Toasts are delivered in the terminal; theme follows Ghostty (`terminal`)

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

- Model `opus`; permissions default to `auto` mode; output style `Concise`; effort `high` for Opus/Sonnet, `medium` for Opus 5.5; theme `auto`
- Statusline: custom script showing user@host, cwd, git branch/dirty count/ahead-behind, model, context-remaining bar, session cost/duration/lines changed, and 5h/7d rate-limit bars. Colors come from `~/.claude/aurora-palette.json` (gradient `stops` + named colors), which the agent-progress mod also reads
- Hooks:
  - `SessionStart` → herdr's pane-tracking integration (`~/.claude/hooks/herdr-agent-state.sh`) — **not** stored here; herdr's Claude integration installs and overwrites it
  - `SessionStart`/`SessionEnd`/`UserPromptSubmit`/`PostToolUse` → `~/.claude/hooks/wag-task-context.py`, which feeds ticket/repos/PRs to the herdr agent sidebar
- Plugins beyond the defaults: `whiteaway` (work plugin, loaded from the `agent-plugins-whiteaway` worktree under `wag/worktrees`), `datadog`, `code-modernization`, `typesafe`, `swift-lsp`
- Global instructions live in `~/.claude/CLAUDE.md` (`AGENTS.md` symlinks to it)

`claude/settings.json` in this repo hardcodes `/Users/emtb/...` paths for the hooks/statusline commands — update the username if restoring onto a different account. The `autoMode` block (work-specific allow/deny rules and environment description) is left out of the copy here because this repo is public.

---

## Disk cleanup job

`scripts/dev-cleanup.sh`, run daily at 09:30 by a launchd agent
(`launchd/com.emtb.dev-cleanup.plist`). Written because the disk kept filling up
with agent worktrees and Docker build cache.

What it removes:
- **Docker (Colima):** containers stopped for 24h+, images and build cache older
  than 3 days, unused networks; then `fstrim` in the VM. Volumes are **never**
  pruned (stopped DBs keep data in anonymous volumes)
- **Git worktrees** under `~/Developer` (repo search depth 4) — only when
  all of these hold:
  - the branch's PR is merged (uses the work `gh` account for `wag/`, personal elsewhere)
  - no uncommitted or untracked changes
  - HEAD is on a remote branch
  - ignored files are only regenerable build output (`node_modules`, `dist`, `.yarn/cache`, …)
  - no process has its cwd inside it
  - it isn't referenced in `~/.claude/settings.json` (e.g. a plugin marketplace)

Branches are never deleted, so committed work always survives.

| | |
| --- | --- |
| Script | `~/.local/bin/dev-cleanup.sh` |
| Log | `~/Library/Logs/dev-cleanup.log` (each kept worktree is logged with the reason) |
| Preview | `DRY_RUN=1 ~/.local/bin/dev-cleanup.sh` |
| Run now | `launchctl kickstart gui/$(id -u)/com.emtb.dev-cleanup` |
| Disable | `launchctl bootout gui/$(id -u)/com.emtb.dev-cleanup` |

Worktrees containing submodules can't be removed without `--force`; they show
up as `FAILED` in the log and need removing by hand.

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
| `claude/aurora-palette.json`      | Statusline + agent-progress palette (Embark) |
| `settings.json`                   | VS Code user settings (Cursor's are similar) |
| `scripts/dev-cleanup.sh`          | Daily disk cleanup (worktrees + Docker) |
| `launchd/com.emtb.dev-cleanup.plist` | launchd agent that runs it at 09:30 |

---

## Installation (fresh machine)

```sh
# 1. Install Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 2. Install tools
brew install starship zsh-autosuggestions zsh-syntax-highlighting zsh-you-should-use \
             zoxide fzf atuin eza bat git-delta fd ripgrep lazygit gh \
             zsh-you-should-use

brew install --cask ghostty font-monaspace   # official Monaspace, includes the NF variants

# 3. Copy config files from this repo (see table above)

# 4. Set up ~/.secrets with NPM_TOKEN (and any other secrets)
echo 'export NPM_TOKEN="..."' > ~/.secrets && chmod 600 ~/.secrets

# 5. Build bat theme cache
bat cache --build

# 6. Copy Claude Code config (fix the /Users/emtb path inside settings.json first)
cp claude/settings.json ~/.claude/settings.json
cp claude/statusline-command.sh ~/.claude/statusline-command.sh
cp claude/aurora-palette.json ~/.claude/aurora-palette.json

# 7. Install the daily disk cleanup job
mkdir -p ~/.local/bin && cp scripts/dev-cleanup.sh ~/.local/bin/ && chmod +x ~/.local/bin/dev-cleanup.sh
cp launchd/com.emtb.dev-cleanup.plist ~/Library/LaunchAgents/
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.emtb.dev-cleanup.plist

# 8. Restart terminal
```
