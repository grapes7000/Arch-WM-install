# Familiar commands with modern output. Originals remain available with command(1).
if command -v eza >/dev/null; then
  alias ls='eza --icons=auto --group-directories-first'
  alias ll='eza -la --icons=auto --group-directories-first --git'
  alias tree='eza --tree --icons=auto --group-directories-first'
fi
command -v bat >/dev/null && alias cat='bat --paging=never --style=plain'
command -v dust >/dev/null && alias du='dust'
command -v duf >/dev/null && alias df='duf'
command -v bottom >/dev/null && alias top='btm'
command -v tealdeer >/dev/null && alias help='tldr'

alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias c='clear'
alias mkdir='mkdir -p'
alias grep='grep --color=auto'
alias ip='ip --color=auto'
alias ports='ss -tulanp'
alias reload-shell='exec zsh'
alias update='sudo pacman -Syu'
alias orphaned='pacman -Qtdq'
alias g='git'
alias gs='git status --short --branch'
alias gd='git diff'
alias gl='git log --graph --decorate --oneline --all -20'
alias lg='lazygit'
alias fm='yazi'
alias sys='fastfetch'

# Enter a temporary directory and clean it when the subshell exits.
tmpd() {
  local dir
  dir="$(mktemp -d)" || return
  (cd "$dir" && exec zsh)
  rm -rf -- "$dir"
}
