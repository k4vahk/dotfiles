# ~/.zshrc
# ==============================================================================
#  Fixes de entorno (deben ir arriba)
# ==============================================================================

# Fix para apps Java en WMs no-reparenting (qtile, dwm, etc.)
export _JAVA_AWT_WM_NONREPARENTING=1

# Powerlevel10k instant prompt. Debe quedarse al inicio del .zshrc.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# ==============================================================================
#  Historial
# ==============================================================================

setopt histignorealldups sharehistory

HISTSIZE=1000
SAVEHIST=1000
HISTFILE="$HOME/.zsh_history"

# ==============================================================================
#  Keybindings
# ==============================================================================

# Emacs keybindings aunque EDITOR sea vi
bindkey -e

# ==============================================================================
#  Sistema de completado
# ==============================================================================

autoload -Uz compinit
compinit

zstyle ':completion:*' auto-description 'specify: %d'
zstyle ':completion:*' completer _expand _complete _correct _approximate
zstyle ':completion:*' format 'Completing %d'
zstyle ':completion:*' group-name ''
zstyle ':completion:*' menu select=2
eval "$(dircolors -b)"
zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*' list-colors ''
zstyle ':completion:*' list-prompt %SAt %p: Hit TAB for more, or the character to insert%s
zstyle ':completion:*' matcher-list '' 'm:{a-z}={A-Z}' 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=* l:|=*'
zstyle ':completion:*' menu select=long
zstyle ':completion:*' select-prompt %SScrolling active: current selection at %p%s
zstyle ':completion:*' use-compctl false
zstyle ':completion:*' verbose true
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#)*=0=01;31'
zstyle ':completion:*:kill:*' command 'ps -u $USER -o pid,%cpu,tty,cputime,cmd'

# ==============================================================================
#  Powerlevel10k
# ==============================================================================

# Ruta compartida y portable (funciona para user y root)
source /usr/share/powerlevel10k/powerlevel10k.zsh-theme

# Tu tema personalizado. Para reconfigurar: `p10k configure`
[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh

# ==============================================================================
#  Aliases
# ==============================================================================

alias ll='lsd -lh --group-dirs=first'
alias la='lsd -a --group-dirs=first'
alias l='lsd --group-dirs=first'
alias lla='lsd -lha --group-dirs=first'
alias ls='lsd --group-dirs=first'
alias cat='bat'

# ==============================================================================
#  Herramientas externas (fzf)
# ==============================================================================

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# ==============================================================================
#  Funciones
# ==============================================================================

# Crear estructura de directorios para un target
function mkt(){
	mkdir {nmap,content,exploits}
}

# Extraer puertos e IP de un output de nmap y copiarlos al portapapeles
function extractPorts(){
    ports="$(cat $1 | grep -oP '\d{1,5}/open' | awk '{print $1}' FS='/' | xargs | tr ' ' ',')"
    ip_address="$(cat $1 | grep -oP '\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}' | sort -u | head -n 1)"
    echo -e "\n[*] Extracting information...\n" > extractPorts.tmp
    echo -e "\t[*] IP Address: $ip_address"  >> extractPorts.tmp
    echo -e "\t[*] Open ports: $ports\n"  >> extractPorts.tmp
    echo $ports | tr -d '\n' | xclip -sel clip
    echo -e "[*] Ports copied to clipboard\n"  >> extractPorts.tmp
    cat extractPorts.tmp; rm extractPorts.tmp
}

# Colores para las páginas de 'man'
function man() {
    env \
    LESS_TERMCAP_mb=$'\e[01;31m' \
    LESS_TERMCAP_md=$'\e[01;31m' \
    LESS_TERMCAP_me=$'\e[0m' \
    LESS_TERMCAP_se=$'\e[0m' \
    LESS_TERMCAP_so=$'\e[01;44;33m' \
    LESS_TERMCAP_ue=$'\e[0m' \
    LESS_TERMCAP_us=$'\e[01;32m' \
    man "$@"
}

# Preview con fzf (h = preview abajo)
function fzf-lovely(){
	if [ "$1" = "h" ]; then
		fzf -m --reverse --preview-window down:20 --preview '[[ $(file --mime {}) =~ binary ]] &&
 	                echo {} is a binary file ||
	                 (bat --style=numbers --color=always {} ||
	                  highlight -O ansi -l {} ||
	                  coderay {} ||
	                  rougify {} ||
	                  cat {}) 2> /dev/null | head -500'
	else
	        fzf -m --preview '[[ $(file --mime {}) =~ binary ]] &&
	                         echo {} is a binary file ||
	                         (bat --style=numbers --color=always {} ||
	                          highlight -O ansi -l {} ||
	                          coderay {} ||
	                          rougify {} ||
	                          cat {}) 2> /dev/null | head -500'
	fi
}

# Setear wallpaper: con argumento pone ese, sin argumento elige aleatorio
function wall(){
    local dir="$HOME/wallpapers"   # ajusta a tu ruta
    if [ -n "$1" ]; then
        feh --bg-fill "$1"
    else
        feh --bg-fill "$(find "$dir" -type f \( -iname '*.jpg' -o -iname '*.png' -o -iname '*.jpeg' \) | shuf -n 1)"
    fi
}

# Borrado seguro de un archivo (scrub + shred)
function rmk(){
	scrub -p dod $1
	shred -zun 10 -v $1
}

# Vaciar el historial (archivo + sesión actual)
function clear_history {
    : > "$HISTFILE"
    fc -p "$HISTFILE"
    echo "Historial borrado (archivo y sesión actual)."
}

# ==============================================================================
#  Plugins (el orden importa: syntax-highlighting SIEMPRE al final)
# ==============================================================================

# Rutas de los paquetes apt de Kali/Debian
source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# ==============================================================================
#  Keybindings extra (Home/End/Delete/word-jump)
# ==============================================================================

bindkey "^[[H" beginning-of-line
bindkey "^[[F" end-of-line
bindkey "^[[3~" delete-char
bindkey "^[[1;3C" forward-word
bindkey "^[[1;3D" backward-word

# ==============================================================================
#  Powerlevel10k instant prompt finalize. Debe quedarse al final.
# ==============================================================================

(( ! ${+functions[p10k-instant-prompt-finalize]} )) || p10k-instant-prompt-finalize

