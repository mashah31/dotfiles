#!/usr/bin/env bash
# dotfiles/install.sh — https://github.com/mashah31/dotfiles
# macOS dev environment: shell, languages, containers, k8s, cloud, GitHub auth.
#
# This script does NOT scaffold projects.
# To bootstrap a new full-stack app, use:
#   ~/workspace/bootstrap-fastapi-react/scaffold.sh my-app
#
# Usage:
#   ./install.sh

set -euo pipefail

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; RED='\033[0;31m'; RESET='\033[0m'
ok()   { echo -e "${GREEN}✔${RESET} $1"; }
info() { echo -e "${BLUE}→${RESET} $1"; }
warn() { echo -e "${YELLOW}⚠${RESET} $1"; }
err()  { echo -e "${RED}✘${RESET} $1" >&2; }
ask()  { echo -e "${YELLOW}?${RESET} $1"; }

has()         { command -v "$1" &>/dev/null; }
arm()         { [[ $(uname -m) == "arm64" ]]; }
brew_prefix() { arm && echo "/opt/homebrew" || echo "/usr/local"; }
append_once() { grep -qF "$1" "$2" 2>/dev/null || echo "$1" >> "$2"; }
backup()      { [[ -f "$1" && ! -L "$1" ]] && cp "$1" "$1.bak.$(date +%s)" && info "backed up $1 → $1.bak.*"; true; }

DOTFILES="$(cd "$(dirname "$0")" && pwd)"
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

# ── 3. Shell + modern CLI tools + font ───────────────────────────────────────
CORE_PKGS=(starship zsh-autosuggestions zsh-syntax-highlighting eza bat fd ripgrep zoxide fzf jq git)
for pkg in "${CORE_PKGS[@]}"; do
  brew list "$pkg" &>/dev/null || brew install "$pkg"
done
brew list --cask font-meslo-lg-nerd-font &>/dev/null || brew install --cask font-meslo-lg-nerd-font
ok "Starship + zsh plugins + modern CLI (eza, bat, fd, rg, zoxide, fzf, jq) + Nerd Font"

# Starship config
mkdir -p "$HOME/.config"
if [[ ! -f "$HOME/.config/starship.toml" ]]; then
  cp "$DOTFILES/starship.toml" "$HOME/.config/starship.toml"
  ok "Starship config → ~/.config/starship.toml"
else
  ok "Starship config already exists — skipping"
fi

# ── 4. Python: uv (default) ──────────────────────────────────────────────────
ask "Python manager? 1) uv (recommended)  2) pyenv  3) skip  [1]:"
read -rp "" PY; PY="${PY:-1}"
case "$PY" in
  1)
    has uv || brew install uv
    ok "uv $(uv --version)"
    ;;
  2)
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
  3) warn "Skipping Python setup" ;;
esac

# ── 5. Node: fnm (default) ───────────────────────────────────────────────────
ask "Node manager? 1) fnm (recommended)  2) nvm  3) skip  [1]:"
read -rp "" NODE; NODE="${NODE:-1}"
case "$NODE" in
  1)
    has fnm || brew install fnm
    append_once 'eval "$(fnm env --use-on-cd)"' "$ZSHRC"
    eval "$(fnm env --use-on-cd)"
    fnm install --lts && fnm use lts-latest && fnm default lts-latest
    ok "Node $(node --version) via fnm"
    ;;
  2)
    if ! has nvm && [[ ! -d "$HOME/.nvm" ]]; then
      brew install nvm
      mkdir -p "$HOME/.nvm"
      append_once 'export NVM_DIR="$HOME/.nvm"' "$ZSHRC"
      append_once "[ -s \"$(brew_prefix)/opt/nvm/nvm.sh\" ] && \\. \"$(brew_prefix)/opt/nvm/nvm.sh\"" "$ZSHRC"
      export NVM_DIR="$HOME/.nvm"
      [ -s "$(brew_prefix)/opt/nvm/nvm.sh" ] && \. "$(brew_prefix)/opt/nvm/nvm.sh"
    fi
    nvm install --lts && nvm alias default node
    ok "Node $(node --version) via nvm"
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

# ── 7. Kubernetes + cloud + DB tools ─────────────────────────────────────────
for pkg in kubectl helm kubectx k9s gh; do
  has "$pkg" || brew install "$pkg"
done
ok "kubectl + Helm + kubectx + k9s + gh CLI"

# ── 7a. GitHub auth (gh OAuth — no PATs, no tokens in URLs) ──────────────────
if gh auth status &>/dev/null; then
  ok "GitHub already authenticated as $(gh api user -q .login 2>/dev/null)"
else
  info "Authenticating with GitHub via OAuth (browser)..."
  info "Choose: GitHub.com → HTTPS → Login with a web browser"
  gh auth login --hostname github.com --git-protocol https --web
  ok "GitHub authenticated"
fi

# Set git credential helper to gh (overwrites osxkeychain — gh is strictly better)
git config --global credential.helper "!gh auth git-credential"
ok "Git credential helper → gh auth git-credential"

# Remove stale Keychain entry for github.com (leftover from PAT era)
security delete-internet-password -s github.com 2>/dev/null && \
  info "Removed stale github.com Keychain entry" || true

# Scan workspace repos for token-embedded remote URLs and fix them
info "Scanning repos for embedded credentials in remote URLs..."
DIRTY=0
while IFS= read -r cfg; do
  repo_dir="$(dirname "$(dirname "$cfg")")"
  if grep -qE "https://[^@]+:[^@]+@github.com" "$cfg" 2>/dev/null; then
    warn "Embedded credentials found in $repo_dir — fixing..."
    (
      cd "$repo_dir"
      for remote in $(git remote); do
        url="$(git remote get-url "$remote")"
        clean_url="$(echo "$url" | sed 's|https://[^@]*@github.com|https://github.com|')"
        git remote set-url "$remote" "$clean_url"
        ok "Fixed remote '$remote' in $repo_dir"
      done
    )
    DIRTY=1
  fi
done < <(find "$WORKSPACE" -name "config" -path "*/.git/config" 2>/dev/null)
[[ "$DIRTY" -eq 0 ]] && ok "No embedded credentials found in remote URLs"

# Google Cloud SDK (primary cloud)
if ! has gcloud; then
  ask "Install Google Cloud SDK (gcloud)? [Y/n]:"
  read -rp "" GC; GC="${GC:-Y}"
  if [[ "$GC" =~ ^[Yy]$ ]]; then
    brew install --cask google-cloud-sdk
    ok "gcloud installed — run \`gcloud init\` to authenticate"
  fi
fi

# ── 8. Claude Code (optional — primary LLM is provider-agnostic) ─────────────
ask "Install Claude Code CLI for agentic dev? [Y/n]:"
read -rp "" CC; CC="${CC:-Y}"
if [[ "$CC" =~ ^[Yy]$ ]]; then
  if ! has claude; then
    npm install -g @anthropic-ai/claude-code
    append_once 'export PATH="$HOME/.local/bin:$PATH"' "$ZSHRC"
    export PATH="$HOME/.local/bin:$PATH"
  fi
  claude auth status &>/dev/null || claude auth login
  ok "Claude Code $(claude --version)"

  mkdir -p "$HOME/.claude"
  cp "$DOTFILES/statusline-command.sh" "$HOME/.claude/statusline-command.sh"
  chmod +x "$HOME/.claude/statusline-command.sh"
  if [[ ! -f "$HOME/.claude/settings.json" ]]; then
    cat > "$HOME/.claude/settings.json" << 'EOF'
{
  "statusLine": {
    "type": "command",
    "command": "bash ~/.claude/statusline-command.sh"
  }
}
EOF
  else
    python3 -c "
import json
p = '$HOME/.claude/settings.json'
with open(p) as f: s = json.load(f)
s['statusLine'] = {'type': 'command', 'command': 'bash ~/.claude/statusline-command.sh'}
with open(p, 'w') as f: json.dump(s, f, indent=2)
"
  fi
  ok "Claude Code statusline configured"

  # Global CLAUDE.md + rules — auto-loaded in every Claude Code session
  backup "$HOME/.claude/CLAUDE.md"
  cp "$DOTFILES/CLAUDE.md.template" "$HOME/.claude/CLAUDE.md"
  ok "Global CLAUDE.md → ~/.claude/CLAUDE.md"

  mkdir -p "$HOME/.claude/rules"
  cp "$DOTFILES/rules/"*.md "$HOME/.claude/rules/"
  ok "Claude rules → ~/.claude/rules/"
fi

# ── 9. Dotfiles (.zshrc, .vimrc, .gitconfig) ─────────────────────────────────
backup "$ZSHRC"
if grep -q "# dotfiles — interactive shell config" "$ZSHRC" 2>/dev/null; then
  ok ".zshrc already configured — skipping"
else
  cat "$DOTFILES/.zshrc" >> "$ZSHRC"
  ok ".zshrc updated"
fi

backup "$HOME/.vimrc"
[[ -f "$HOME/.vimrc" ]] || cp "$DOTFILES/.vimrc" "$HOME/.vimrc"
ok ".vimrc"

backup "$HOME/.gitconfig"
if [[ ! -f "$HOME/.gitconfig" ]] || ! grep -q "autoSetupRemote" "$HOME/.gitconfig" 2>/dev/null; then
  cp "$DOTFILES/.gitconfig" "$HOME/.gitconfig"
  ok ".gitconfig copied"
  warn "Set your name/email: git config --global user.name '...' && git config --global user.email '...'"
else
  ok ".gitconfig already configured — skipping"
fi


# ── Done ──────────────────────────────────────────────────────────────────────
echo ""
ok "All done."
echo "  Python  $(python --version 2>/dev/null || uv python list 2>/dev/null | head -1 || echo '—')"
echo "  Node    $(node --version 2>/dev/null || echo '—')"
echo "  Docker  $(docker --version 2>/dev/null | cut -d' ' -f3 | tr -d ',' || echo '—')"
echo "  kubectl $(kubectl version --client -o json 2>/dev/null | jq -r .clientVersion.gitVersion || echo '—')"
echo "  gcloud  $(gcloud --version 2>/dev/null | head -1 || echo '—')"
echo "  Claude  $(claude --version 2>/dev/null || echo '—')"
echo ""
warn "Run: source ~/.zshrc  (or open a new terminal tab)"
info "To bootstrap a new app: ~/workspace/bootstrap-fastapi-react/scaffold.sh my-app"
