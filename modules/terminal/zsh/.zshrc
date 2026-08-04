# Fast Arch WM Zsh profile. Personal overrides belong in ~/.zshrc.local.

export PATH="$HOME/.local/bin:$PATH"
export EDITOR="${EDITOR:-nvim}"
export VISUAL="$EDITOR"
export PAGER="${PAGER:-less}"
export LESS="-R --mouse"
export STARSHIP_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/theme-engine/generated/starship.toml"
export BAT_THEME="ansi"

HISTFILE="${XDG_STATE_HOME:-$HOME/.local/state}/zsh/history"
HISTSIZE=100000
SAVEHIST=100000
mkdir -p "${HISTFILE:h}" "${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
setopt APPEND_HISTORY INC_APPEND_HISTORY SHARE_HISTORY
setopt HIST_IGNORE_ALL_DUPS HIST_SAVE_NO_DUPS HIST_REDUCE_BLANKS HIST_IGNORE_SPACE
setopt AUTO_CD AUTO_PUSHD PUSHD_IGNORE_DUPS INTERACTIVE_COMMENTS
setopt NO_BEEP

# Native completion with a cached dump keeps repeat startup quick.
autoload -Uz compinit
_zcompdump="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompdump-${ZSH_VERSION}"
if [[ -s "$_zcompdump" ]]; then
  compinit -C -d "$_zcompdump"
else
  compinit -d "$_zcompdump"
fi
unset _zcompdump
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|=*' 'l:|=* r:|=*'
zstyle ':completion:*' group-name ''
zstyle ':completion:*:descriptions' format '%F{magenta}-- %d --%f'
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}

bindkey -e
bindkey '^[[H' beginning-of-line
bindkey '^[[F' end-of-line
bindkey '^[[3~' delete-char
bindkey '^P' up-line-or-history
bindkey '^N' down-line-or-history

# Modern navigation and history. Atuin owns Ctrl-R; arrows remain native.
command -v zoxide >/dev/null && eval "$(zoxide init zsh)"
command -v atuin >/dev/null && eval "$(atuin init zsh --disable-up-arrow)"
if command -v fzf >/dev/null; then
  if fzf --zsh >/dev/null 2>&1; then
    source <(fzf --zsh)
  else
    [[ -r /usr/share/fzf/key-bindings.zsh ]] && source /usr/share/fzf/key-bindings.zsh
    [[ -r /usr/share/fzf/completion.zsh ]] && source /usr/share/fzf/completion.zsh
  fi
fi
export FZF_DEFAULT_OPTS="--height=45% --layout=reverse --border=rounded --info=inline --preview-window=right:55%:wrap"
command -v fd >/dev/null && export FZF_DEFAULT_COMMAND="fd --type f --hidden --follow --exclude .git"

# Packaged plugins are loaded directly instead of a large shell framework.
for _plugin in \
  /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh \
  /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh; do
  [[ -r "$_plugin" ]] && source "$_plugin" && break
done
unset _plugin

[[ -r "${XDG_CONFIG_HOME:-$HOME/.config}/zsh/aliases.zsh" ]] && \
  source "${XDG_CONFIG_HOME:-$HOME/.config}/zsh/aliases.zsh"
command -v starship >/dev/null && eval "$(starship init zsh)"

# Syntax highlighting must load last.
for _plugin in \
  /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh \
  /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh; do
  [[ -r "$_plugin" ]] && source "$_plugin" && break
done
unset _plugin

[[ -r "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"
