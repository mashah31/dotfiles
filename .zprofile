# dotfiles — login shell PATH setup
# Loaded once on login (before .zshrc)

# ── Homebrew ──────────────────────────────────────────────────────────────────
# Apple Silicon
[[ -f /opt/homebrew/bin/brew ]] && eval "$(/opt/homebrew/bin/brew shellenv zsh)"
# Intel fallback
[[ -f /usr/local/bin/brew ]] && eval "$(/usr/local/bin/brew shellenv zsh)"

# ── pyenv ─────────────────────────────────────────────────────────────────────
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)" 2>/dev/null || true

# ── Local bins ────────────────────────────────────────────────────────────────
export PATH="$HOME/.local/bin:$PATH"
