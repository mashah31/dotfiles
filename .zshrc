# dotfiles — shell config
# github.com/mshah/dotfiles

# ── Starship prompt ───────────────────────────────────────────────────────────
export STARSHIP_CONFIG="$HOME/.config/starship.toml"
eval "$(starship init zsh)"

# ── Plugins ───────────────────────────────────────────────────────────────────
# Apple Silicon path; Intel uses /usr/local/share/...
[[ -f /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]] && \
  source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
[[ -f /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]] && \
  source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# ── History ───────────────────────────────────────────────────────────────────
HISTSIZE=10000
SAVEHIST=10000
HISTFILE=~/.zsh_history
setopt HIST_IGNORE_DUPS SHARE_HISTORY

# ── Workspace ─────────────────────────────────────────────────────────────────
export WORKSPACE="$HOME/workspace"
alias ws="cd $WORKSPACE"

# ── Navigation ────────────────────────────────────────────────────────────────
alias ..="cd .."
alias ...="cd ../.."
alias ll="ls -la"
alias c="clear"

# ── Git ───────────────────────────────────────────────────────────────────────
alias gs="git status"
alias ga="git add ."
alias gc="git commit -m"
alias gp="git push"
alias gl="git pull"
alias gco="git checkout"
alias gb="git branch"
alias glog="git log --oneline --graph --decorate"

# ── Python / FastAPI ──────────────────────────────────────────────────────────
alias venv="python -m venv .venv"
alias activate="source .venv/bin/activate"
alias pi="pip install"
alias pf="pip freeze > requirements.txt"
alias pr="pip install -r requirements.txt"
alias serve="uvicorn main:app --reload"
alias serve8="uvicorn main:app --reload --port 8080"

# ── Node / React ──────────────────────────────────────────────────────────────
alias ni="npm install"
alias nr="npm run dev"
alias nb="npm run build"

# ── Misc ──────────────────────────────────────────────────────────────────────
alias zshrc="vim ~/.zshrc"
alias reload="source ~/.zshrc"
alias myip="curl ifconfig.me"

# ── Default directory ─────────────────────────────────────────────────────────
cd "$HOME/workspace" 2>/dev/null || true
