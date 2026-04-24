# dotfiles

Mac dev environment for full-stack development: **FastAPI · PostgreSQL · React · Docker · Kubernetes**

## What's included

| File | Purpose |
|------|---------|
| `install.sh` | Bootstrap script — installs all tools, writes dotfiles |
| `.zshrc` | Shell aliases, plugins, history, workspace defaults |
| `.zprofile` | Login PATH setup (Homebrew, pyenv, local bins) |
| `.vimrc` | Vim config |
| `starship.toml` | Prompt config (copy to `~/.config/starship.toml`) |

## Quick start

```bash
git clone https://github.com/mshah/dotfiles.git ~/workspace/dotfiles
cd ~/workspace/dotfiles
chmod +x install.sh
./install.sh
```

The script is **idempotent** — safe to re-run on a fresh Mac or after a wipe.

## What gets installed

- **Xcode CLI Tools** — compilers, git, make
- **Homebrew** — package manager
- **Starship** — minimal single-line prompt
- **zsh-autosuggestions + zsh-syntax-highlighting** — shell plugins
- **MesloLGS Nerd Font** — terminal font with icons
- **pyenv or uv** — Python version manager (your choice)
- **nvm or fnm** — Node version manager (your choice)
- **Docker Desktop** — containers + local Kubernetes
- **kubectl + Helm** — Kubernetes CLI tools
- **Claude Code** — AI coding CLI (optional)

The script asks you to choose Python/Node managers and whether to install Claude Code — everything else is automatic.

## Scaffold a new project

```bash
./install.sh my-project
```

Creates a ready-to-run full-stack project at `~/workspace/my-project`:

```
my-project/
├── backend/           FastAPI app (Python 3.12)
│   ├── Dockerfile
│   ├── main.py
│   └── requirements.txt
├── frontend/          React + Vite
│   └── Dockerfile
├── k8s/               Helm charts
├── docker-compose.yml local dev
├── .env.example       environment template
├── .gitignore
└── CLAUDE.md          Claude Code project context
```

Start everything with one command:

```bash
cd ~/workspace/my-project
docker compose up
```

| Service  | URL |
|----------|-----|
| Frontend | http://localhost:5173 |
| API      | http://localhost:8000 |
| API Docs | http://localhost:8000/docs |
| Database | localhost:5432 |

## Shell aliases

**Navigation**

| Alias | Command |
|-------|---------|
| `ws` | `cd ~/workspace` |
| `ll` | `ls -la` |
| `..` / `...` | go up 1 / 2 dirs |
| `c` | `clear` |

**Git**

| Alias | Command |
|-------|---------|
| `gs` | `git status` |
| `ga` | `git add .` |
| `gc "msg"` | `git commit -m "msg"` |
| `gp` / `gl` | push / pull |
| `gco` / `gb` | checkout / branch |
| `glog` | pretty log graph |

**Python / FastAPI**

| Alias | Command |
|-------|---------|
| `venv` | `python -m venv .venv` |
| `activate` | `source .venv/bin/activate` |
| `pi` / `pr` / `pf` | install / install -r / freeze |
| `serve` | `uvicorn main:app --reload` (port 8000) |
| `serve8` | same, port 8080 |

**Node / React**

| Alias | Command |
|-------|---------|
| `ni` | `npm install` |
| `nr` | `npm run dev` |
| `nb` | `npm run build` |

**Misc**

| Alias | Command |
|-------|---------|
| `reload` | `source ~/.zshrc` |
| `zshrc` | `vim ~/.zshrc` |
| `myip` | `curl ifconfig.me` |

## Directory layout

```
~/workspace/          all projects live here
~/.nvm/               Node versions (if using nvm)
~/.pyenv/             Python versions (if using pyenv)
~/.config/starship.toml
~/.zshrc
~/.zprofile
~/.vimrc
```

## Manual dotfile linking (optional)

If you prefer symlinks instead of copying:

```bash
ln -sf ~/workspace/dotfiles/.zshrc ~/.zshrc
ln -sf ~/workspace/dotfiles/.zprofile ~/.zprofile
ln -sf ~/workspace/dotfiles/.vimrc ~/.vimrc
ln -sf ~/workspace/dotfiles/starship.toml ~/.config/starship.toml
```

## Why these choices

| Decision | Reason |
|----------|--------|
| `~/workspace` not `~/Documents` | Avoids iCloud syncing `node_modules` |
| `.venv` per project | Delete project = delete deps |
| Docker Desktop Kubernetes | Bundled, zero extra setup |
| Helm for deploys | One chart → GKE, EKS, any cluster |
| pyenv over system Python | Never conflicts with macOS system Python |
| Starship over Powerlevel10k | Single-line, fast, never wraps |
