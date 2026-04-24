#!/usr/bin/env bash
# Mac dev environment bootstrap — FastAPI + PostgreSQL + React + Docker + Claude Code
# Idempotent: safe to re-run anytime.
# Usage:
#   ./install.sh              — environment setup only
#   ./install.sh my-project   — setup + scaffold a new project

set -euo pipefail

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; RESET='\033[0m'
ok()   { echo -e "${GREEN}✔${RESET} $1"; }
info() { echo -e "${BLUE}→${RESET} $1"; }
warn() { echo -e "${YELLOW}⚠${RESET} $1"; }
ask()  { echo -e "${YELLOW}?${RESET} $1"; }

has()         { command -v "$1" &>/dev/null; }
arm()         { [[ $(uname -m) == "arm64" ]]; }
brew_prefix() { arm && echo "/opt/homebrew" || echo "/usr/local"; }
append_once() { grep -qF "$1" "$2" 2>/dev/null || echo "$1" >> "$2"; }

DOTFILES="$(cd "$(dirname "$0")" && pwd)"
PROJECT="${1:-}"
WORKSPACE="$HOME/workspace"
ZSHRC="$HOME/.zshrc"
ZPROFILE="$HOME/.zprofile"

# ── 1. Xcode CLI Tools ────────────────────────────────────────────────────────
if ! xcode-select -p &>/dev/null; then
  info "Installing Xcode CLI tools (follow the popup)..."
  xcode-select --install
  read -rp "Press Enter once installation completes..."
fi
sudo xcodebuild -license accept 2>/dev/null || true
ok "Xcode CLI tools"

# ── 2. Homebrew ───────────────────────────────────────────────────────────────
if has brew; then
  brew update --quiet
else
  info "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  append_once "eval \"\$($(brew_prefix)/bin/brew shellenv zsh)\"" "$ZPROFILE"
  eval "$($(brew_prefix)/bin/brew shellenv zsh)"
fi
ok "Homebrew $(brew --version | head -1)"

# ── 3. Shell: Starship + plugins + font ──────────────────────────────────────
for pkg in starship zsh-autosuggestions zsh-syntax-highlighting; do
  brew list "$pkg" &>/dev/null || brew install "$pkg"
done
brew list --cask font-meslo-lg-nerd-font &>/dev/null || brew install --cask font-meslo-lg-nerd-font
ok "Starship + zsh plugins + MesloLGS Nerd Font"

# Starship config
mkdir -p "$HOME/.config"
if [[ ! -f "$HOME/.config/starship.toml" ]]; then
  cp "$DOTFILES/starship.toml" "$HOME/.config/starship.toml"
  ok "Starship config → ~/.config/starship.toml"
else
  ok "Starship config already exists — skipping"
fi

# ── 4. Python version manager ─────────────────────────────────────────────────
ask "Python manager? 1) pyenv  2) uv  3) skip  [1]:"
read -rp "" PY; PY="${PY:-1}"
case "$PY" in
  1)
    if ! has pyenv; then
      brew install pyenv
      append_once 'export PYENV_ROOT="$HOME/.pyenv"' "$ZPROFILE"
      append_once 'export PATH="$PYENV_ROOT/bin:$PATH"' "$ZPROFILE"
      append_once 'eval "$(pyenv init -)"' "$ZPROFILE"
      export PYENV_ROOT="$HOME/.pyenv"
      export PATH="$PYENV_ROOT/bin:$PATH"
      eval "$(pyenv init -)"
    fi
    ask "Python version? [3.12]:"
    read -rp "" PY_VER; PY_VER="${PY_VER:-3.12}"
    pyenv versions | grep -q "$PY_VER" || pyenv install "$PY_VER"
    pyenv global "$PY_VER"
    ok "Python $(python --version)"
    ;;
  2)
    has uv || brew install uv
    ok "uv $(uv --version)"
    ;;
  3) warn "Skipping Python setup" ;;
esac

# ── 5. Node version manager ───────────────────────────────────────────────────
ask "Node manager? 1) nvm  2) fnm  3) skip  [1]:"
read -rp "" NODE; NODE="${NODE:-1}"
case "$NODE" in
  1)
    if ! has nvm && [[ ! -d "$HOME/.nvm" ]]; then
      brew install nvm
      mkdir -p "$HOME/.nvm"
      append_once 'export NVM_DIR="$HOME/.nvm"' "$ZSHRC"
      append_once "[ -s \"$(brew_prefix)/opt/nvm/nvm.sh\" ] && \\. \"$(brew_prefix)/opt/nvm/nvm.sh\"" "$ZSHRC"
      export NVM_DIR="$HOME/.nvm"
      [ -s "$(brew_prefix)/opt/nvm/nvm.sh" ] && \. "$(brew_prefix)/opt/nvm/nvm.sh"
    fi
    ask "Node version? [lts]:"
    read -rp "" NODE_VER; NODE_VER="${NODE_VER:-lts}"
    if [ "$NODE_VER" = "lts" ]; then
      nvm install --lts && nvm alias default node
    else
      nvm install "$NODE_VER" && nvm alias default "$NODE_VER"
    fi
    ok "Node $(node --version)"
    ;;
  2)
    has fnm || brew install fnm
    append_once 'eval "$(fnm env --use-on-cd)"' "$ZSHRC"
    eval "$(fnm env --use-on-cd)"
    fnm install --lts && fnm use lts-latest
    ok "Node $(node --version) via fnm"
    ;;
  3) warn "Skipping Node setup" ;;
esac

# ── 6. Docker Desktop ─────────────────────────────────────────────────────────
if has docker; then
  ok "Docker $(docker --version | cut -d' ' -f3 | tr -d ',')"
else
  brew install --cask docker
  warn "Open Docker Desktop from Applications to finish setup"
  warn "Enable Kubernetes: Settings → Kubernetes → Enable Kubernetes"
  read -rp "Press Enter once Docker Desktop is running..."
fi

# ── 7. Kubernetes tools ───────────────────────────────────────────────────────
has kubectl || brew install kubectl
has helm    || brew install helm
ok "kubectl + Helm"

# ── 8. Claude Code ────────────────────────────────────────────────────────────
ask "Install Claude Code CLI? (requires Anthropic account) [Y/n]:"
read -rp "" CC; CC="${CC:-Y}"
if [[ "$CC" =~ ^[Yy]$ ]]; then
  if ! has claude; then
    npm install -g @anthropic-ai/claude-code
    append_once 'export PATH="$HOME/.local/bin:$PATH"' "$ZSHRC"
    export PATH="$HOME/.local/bin:$PATH"
  fi
  claude auth status &>/dev/null || claude auth login
  ok "Claude Code $(claude --version)"
fi

# ── 9. Dotfiles (.zshrc, .vimrc) ─────────────────────────────────────────────
if grep -q "# dotfiles" "$ZSHRC" 2>/dev/null; then
  ok ".zshrc already configured — skipping"
else
  cat "$DOTFILES/.zshrc" >> "$ZSHRC"
  ok ".zshrc updated"
fi

if [[ -f "$HOME/.vimrc" ]]; then
  ok ".vimrc already exists — skipping"
else
  cp "$DOTFILES/.vimrc" "$HOME/.vimrc"
  ok ".vimrc copied"
fi

# ── 10. Scaffold new project (optional) ──────────────────────────────────────
if [[ -n "$PROJECT" ]]; then
  PROJECT_DIR="$WORKSPACE/$PROJECT"
  [[ -d "$PROJECT_DIR" ]] && { warn "Project '$PROJECT' already exists at $PROJECT_DIR"; exit 0; }

  mkdir -p "$PROJECT_DIR"/{backend,frontend,k8s/charts}
  cd "$PROJECT_DIR"
  git init -q

  cat > .gitignore << 'EOF'
.venv/
__pycache__/
*.pyc
.env
node_modules/
dist/
.DS_Store
*.log
EOF

  cat > .env.example << 'EOF'
DATABASE_URL=postgresql://user:password@localhost:5432/appdb
POSTGRES_USER=user
POSTGRES_PASSWORD=password
POSTGRES_DB=appdb
APP_ENV=development
SECRET_KEY=change-me
DEBUG=true
EOF

  cp .env.example .env

  cat > docker-compose.yml << 'EOF'
services:
  db:
    image: postgres:16-alpine
    environment:
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      POSTGRES_DB: ${POSTGRES_DB}
    ports:
      - "5432:5432"
    volumes:
      - pgdata:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER}"]
      interval: 5s
      timeout: 5s
      retries: 5

  backend:
    build: ./backend
    ports:
      - "8000:8000"
    environment:
      DATABASE_URL: ${DATABASE_URL}
    volumes:
      - ./backend:/app
    depends_on:
      db:
        condition: service_healthy
    command: uvicorn main:app --host 0.0.0.0 --port 8000 --reload

  frontend:
    build: ./frontend
    ports:
      - "5173:5173"
    volumes:
      - ./frontend:/app
      - /app/node_modules
    depends_on:
      - backend

volumes:
  pgdata:
EOF

  cat > backend/Dockerfile << 'EOF'
FROM python:3.12-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
EOF

  cat > backend/requirements.txt << 'EOF'
fastapi
uvicorn[standard]
sqlalchemy
alembic
psycopg2-binary
python-dotenv
pydantic-settings
EOF

  cat > backend/main.py << 'EOF'
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI(title="API", version="0.1.0")
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:5173"],
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/health")
def health():
    return {"status": "ok"}
EOF

  cat > frontend/Dockerfile << 'EOF'
FROM node:24-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
EXPOSE 5173
CMD ["npm", "run", "dev", "--", "--host"]
EOF

  cat > CLAUDE.md << EOF
# $PROJECT

## Stack
- Backend: FastAPI (Python 3.12) · port 8000
- Frontend: React + Vite · port 5173
- Database: PostgreSQL 16 · port 5432
- Infra: Docker Compose (local) → Helm + Kubernetes (prod)

## Quick Start
\`\`\`bash
docker compose up
\`\`\`

| Service  | URL |
|----------|-----|
| Frontend | http://localhost:5173 |
| API      | http://localhost:8000 |
| API Docs | http://localhost:8000/docs |

## Commands
\`\`\`bash
docker compose up        # start all services
docker compose down -v   # stop + clean volumes
docker compose logs -f   # follow logs
\`\`\`
EOF

  ok "Project scaffolded: $PROJECT_DIR"
  info "Next: cd ~/workspace/$PROJECT && docker compose up"
fi

# ── Done ──────────────────────────────────────────────────────────────────────
echo ""
ok "All done."
echo "  Python  $(python --version 2>/dev/null || echo '—')"
echo "  Node    $(node --version 2>/dev/null || echo '—')"
echo "  Docker  $(docker --version 2>/dev/null | cut -d' ' -f3 | tr -d ',' || echo '—')"
echo "  kubectl $(kubectl version --client --short 2>/dev/null | head -1 || echo '—')"
echo "  Claude  $(claude --version 2>/dev/null || echo '—')"
echo ""
warn "Run: source ~/.zshrc  (or open a new terminal tab)"
[[ -n "$PROJECT" ]] && info "Project ready: cd ~/workspace/$PROJECT && docker compose up"
