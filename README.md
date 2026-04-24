# dotfiles

macOS dev environment for FastAPI · React · Docker · Kubernetes.  
Works on Apple Silicon and Intel. Idempotent — safe to re-run anytime.

## Install

```bash
git clone https://github.com/mashah31/dotfiles ~/workspace/dotfiles
cd ~/workspace/dotfiles && ./install.sh
```

Prompts you to choose Python manager (pyenv or uv) and Node manager (nvm or fnm). Everything else is automatic.

## What gets installed

Homebrew · Starship · zsh-autosuggestions · zsh-syntax-highlighting · MesloLGS Nerd Font · pyenv or uv · nvm or fnm · Docker Desktop · kubectl · Helm · Claude Code (optional)

## Files

| File | What it does |
|------|-------------|
| `install.sh` | Bootstraps the full environment |
| `.zshrc` | Aliases, plugins, history, workspace default |
| `.zprofile` | Login PATH — Homebrew, pyenv, local bins |
| `.vimrc` | Vim settings |
| `starship.toml` | Prompt config → `~/.config/starship.toml` |

## Scaffold a new project

```bash
./install.sh my-app
```

Creates `~/workspace/my-app` with FastAPI + React/Vite + Docker Compose + Helm ready to go:

```
my-app/
├── backend/           FastAPI (Python 3.12)
├── frontend/          React + Vite
├── k8s/               Helm charts
├── docker-compose.yml
├── .env.example
└── CLAUDE.md
```

```bash
cd ~/workspace/my-app && docker compose up
```

| Service  | URL |
|----------|-----|
| Frontend | http://localhost:5173 |
| API      | http://localhost:8000 |
| API Docs | http://localhost:8000/docs |

## Symlink instead of copy

```bash
ln -sf ~/workspace/dotfiles/.zshrc ~/.zshrc
ln -sf ~/workspace/dotfiles/.zprofile ~/.zprofile
ln -sf ~/workspace/dotfiles/.vimrc ~/.vimrc
ln -sf ~/workspace/dotfiles/starship.toml ~/.config/starship.toml
```

## Aliases

See [`.zshrc`](.zshrc) — git, python/fastapi, node/react, navigation.
