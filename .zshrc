# dotfiles — interactive shell config
# github.com/mashah31/dotfiles

# ── Starship prompt ───────────────────────────────────────────────────────────
export STARSHIP_CONFIG="$HOME/.config/starship.toml"
eval "$(starship init zsh)"

# ── Plugins (Apple Silicon path; Intel falls back to /usr/local/share) ───────
for plugin in zsh-autosuggestions zsh-syntax-highlighting; do
  for prefix in /opt/homebrew /usr/local; do
    [[ -f "$prefix/share/$plugin/$plugin.zsh" ]] && \
      source "$prefix/share/$plugin/$plugin.zsh" && break
  done
done

# ── History ───────────────────────────────────────────────────────────────────
HISTSIZE=50000
SAVEHIST=50000
HISTFILE=~/.zsh_history
setopt HIST_IGNORE_DUPS HIST_IGNORE_SPACE HIST_REDUCE_BLANKS SHARE_HISTORY EXTENDED_HISTORY

# ── Workspace ─────────────────────────────────────────────────────────────────
export WORKSPACE="$HOME/workspace"
alias ws="cd $WORKSPACE"

# ── Modern CLI replacements (fall back to coreutils if not installed) ─────────
command -v eza      &>/dev/null && alias ls="eza --group-directories-first" && alias ll="eza -lah --git --group-directories-first"
command -v bat      &>/dev/null && alias cat="bat --paging=never --style=plain"
command -v fd       &>/dev/null && alias find="fd"
command -v rg       &>/dev/null && alias grep="rg"
command -v zoxide   &>/dev/null && eval "$(zoxide init zsh)" && alias cd="z"

# ── Navigation ────────────────────────────────────────────────────────────────
alias ..="cd .."
alias ...="cd ../.."
alias c="clear"

# ── Git (safe defaults — no destructive aliases) ─────────────────────────────
alias gs="git status"
alias ga="git add"                          # explicit paths only — never `git add .`
alias gc="git commit"                       # opens $EDITOR — write proper messages
alias gca="git commit --amend --no-edit"
alias gp="git push"
alias gpf="git push --force-with-lease"     # safe force push
alias gl="git pull --rebase --autostash"
alias gco="git checkout"
alias gcb="git checkout -b"
alias gb="git branch"
alias gd="git diff"
alias gds="git diff --staged"
alias glog="git log --oneline --graph --decorate --all"
alias gundo="git reset --soft HEAD~1"       # undo last commit, keep changes staged

# ── Python / uv (uv is the default — no pip aliases) ─────────────────────────
alias uvs="uv sync"
alias uva="uv add"
alias uvr="uv run"
alias venv="uv venv"
alias activate="source .venv/bin/activate"
alias serve="uv run uvicorn app.main:app --reload"
alias serve8="uv run uvicorn app.main:app --reload --port 8080"
alias aerich="uv run aerich"

# ── Node / npm ────────────────────────────────────────────────────────────────
alias ni="npm install"
alias nr="npm run dev"
alias nb="npm run build"
alias nt="npm run test"
alias nl="npm run lint"
alias ntc="npm run typecheck"

# ── Docker / Kubernetes ──────────────────────────────────────────────────────
alias dc="docker compose"
alias dcu="docker compose up"
alias dcd="docker compose down"
alias dcl="docker compose logs -f"
alias k="kubectl"
alias kgp="kubectl get pods"
alias kgs="kubectl get svc"
alias kl="kubectl logs -f"
alias kctx="kubectl config use-context"
alias h="helm"

# ── Misc ──────────────────────────────────────────────────────────────────────
alias zshrc="${EDITOR:-vim} ~/.zshrc"
alias reload="source ~/.zshrc"
alias myip="curl -s ifconfig.me && echo"
alias path='echo -e ${PATH//:/\\n}'

# ── GitHub auth helpers ───────────────────────────────────────────────────────
alias ghw="gh auth status"                           # check auth status
alias ghfix="git remote -v | grep -oE 'https://[^@]+@[^ ]+' | head -1 | sed 's|https://[^@]*@|https://|' | xargs git remote set-url origin"  # strip embedded creds

# Warn if current repo has a token embedded in a remote URL
_git_credential_check() {
  if [[ -f .git/config ]] && grep -qE "https://[^@]+:[^@]+@github\.com" .git/config 2>/dev/null; then
    echo "⚠ WARNING: embedded credentials in .git/config — run: ghfix"
  fi
}
add-zsh-hook chpwd _git_credential_check
autoload -Uz add-zsh-hook

# ── Editor ────────────────────────────────────────────────────────────────────
export EDITOR="vim"
export VISUAL="vim"

# ── fzf (if installed) ────────────────────────────────────────────────────────
[[ -f ~/.fzf.zsh ]] && source ~/.fzf.zsh
