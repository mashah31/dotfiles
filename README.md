# dotfiles

Opinionated **macOS dev environment** — shell, languages, containers, k8s, cloud, GitHub auth.
Works on Apple Silicon and Intel. Idempotent — safe to re-run.

> **This repo is mac setup only.** Project scaffolding lives elsewhere — see [Related repos](#related-repos).

## Install

```bash
git clone https://github.com/mashah31/dotfiles ~/workspace/dotfiles
cd ~/workspace/dotfiles && ./install.sh
```

Existing `.zshrc`, `.vimrc`, `.gitconfig`, `~/.claude/CLAUDE.md` are backed up to `*.bak.<timestamp>` before any change.

## What gets installed

| Category | Tools |
|----------|-------|
| Shell | Starship, zsh-autosuggestions, zsh-syntax-highlighting, MesloLGS Nerd Font |
| Modern CLI | eza, bat, fd, ripgrep, zoxide, fzf, jq |
| Languages | uv (Python 3.12) · fnm (Node LTS) |
| Containers | Docker Desktop |
| Kubernetes | kubectl, Helm, kubectx, k9s |
| Cloud | gcloud (Google Cloud SDK) |
| Git | git, gh CLI (OAuth — no PATs) |
| Optional | Claude Code CLI |

## Files

| File | Purpose |
|------|---------|
| `install.sh` | Mac environment bootstrap (no project scaffolding) |
| `.zshrc` | Aliases, plugins, history, modern CLI integration |
| `.zprofile` | Login PATH — Homebrew, pyenv, local bins |
| `.gitconfig` | Safe defaults: rebase on pull, gh credential helper, autoSetupRemote, conflictStyle=zdiff3 |
| `.vimrc` | Minimal Vim config |
| `.gitignore` | OS + editor noise |
| `starship.toml` | Prompt config → `~/.config/starship.toml` |
| `statusline-command.sh` | Claude Code status line |
| `CLAUDE.md.template` | Canonical full-stack guide — installed to `~/.claude/CLAUDE.md` (global) |

## GitHub Auth (zero-management, no PATs)

`install.sh` authenticates GitHub via **`gh` OAuth**:

```bash
gh auth login --hostname github.com --git-protocol https --web
```

- `git push`/`pull`/`clone` work silently — token managed by `gh`, stored in macOS Keychain
- No long-lived PATs, no tokens in URLs, no rotation
- `credential.helper = !gh auth git-credential` baked into `.gitconfig`

## Global CLAUDE.md

`install.sh` copies `CLAUDE.md.template` to `~/.claude/CLAUDE.md`. Claude Code auto-loads it in every session, every directory.

Re-sync after editing the template:
```bash
cp ~/workspace/dotfiles/CLAUDE.md.template ~/.claude/CLAUDE.md
```

## Key aliases

```bash
# Git (safe defaults)
gs ga gc gp gpf gl gco gcb gd gds glog gundo

# Python (uv)
uvs uva uvr venv activate serve aerich

# Docker / k8s
dc dcu dcd dcl k kgp kl kctx h
```

`ga="git add"` (not `git add .`) — explicit only.
`gc="git commit"` (not `-m`) — opens `$EDITOR`.
`gpf="git push --force-with-lease"` — never bare `--force`.

## Symlink instead of copy

Keep dotfiles git-managed:

```bash
ln -sf ~/workspace/dotfiles/.zshrc       ~/.zshrc
ln -sf ~/workspace/dotfiles/.zprofile    ~/.zprofile
ln -sf ~/workspace/dotfiles/.vimrc       ~/.vimrc
ln -sf ~/workspace/dotfiles/.gitconfig   ~/.gitconfig
ln -sf ~/workspace/dotfiles/starship.toml ~/.config/starship.toml
```

## Related repos

| Repo | What |
|------|------|
| `~/workspace/bootstrap-fastapi-react` | Full-stack project scaffold — `./scaffold.sh my-app` creates a runnable FastAPI + React 19 + Postgres + Helm app |
| `~/workspace/packages/pyauth` | Shared JWT auth package — used by every scaffolded backend, no auth code duplication |

Tomorrow you can add `bootstrap-django-htmx/` or `bootstrap-go-react/` independently — this dotfiles repo doesn't change.

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| `command not found: brew` | `eval "$(/opt/homebrew/bin/brew shellenv)"` then re-run |
| Starship prompt broken / `?` glyphs | iTerm/Ghostty: set font to **MesloLGS Nerd Font** |
| `zsh-autosuggestions` not loading | `source ~/.zshrc` (or open new tab) |
| Statusline shows nothing | `brew install jq` |

## Uninstall / rollback

```bash
ls ~/.zshrc.bak.*                       # find the backup
mv ~/.zshrc.bak.1234567890 ~/.zshrc     # restore
brew uninstall <pkg>                    # remove tools
```

## License

MIT.
