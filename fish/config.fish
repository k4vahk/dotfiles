if status is-interactive
    # 1. Quitar el mensaje de bienvenida "Welcome to fish"
    set -U fish_greeting

    # 2. Iniciar Starship (El prompt moderno)
    starship init fish | source
    
    # 3. Mostrar info del sistema al abrir terminal (Opcional)
    # fastfetch 
end
# --- CAMBIAR WALLPAPER ---
# Función para cambiar wallpaper con feh
function setbg
    # Verificar si se pasó un argumento
    if test (count $argv) -lt 1
        echo "❌ Error: Debes indicar la ruta de la imagen."
        echo "Uso: setbg /ruta/a/tu/imagen.jpg"
        return 1
    end

    # Ejecutar feh (esto actualiza automáticamente ~/.fehbg)
    feh --bg-fill $argv[1]

    echo "✅  Fondo actualizado correctamente."
end

# --- EXTRACTPORTS ---
function extractPorts
    # Verifica que hayas pasado un archivo como argumento
    if test (count $argv) -lt 1
        echo "Uso: extractPorts <archivo_nmap>"
        return 1
    end

    set target_file $argv[1]

    # Extraer puertos
    set ports (cat $target_file | grep -oP '\d{1,5}/open' | awk '{print $1}' FS='/' | xargs | tr ' ' ',')
    
    # Extraer IP
    set ip_address (cat $target_file | grep -oP '\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}' | sort -u | head -n 1)

    # Mostrar información (Sin crear archivo temporal, es más limpio)
    echo -e "\n[*] Extracting information...\n"
    echo -e "\t[*] IP Address: $ip_address"
    echo -e "\t[*] Open ports: $ports\n"
    
    # Copiar al portapapeles
    echo $ports | tr -d '\n' | xclip -sel clip
    
    echo -e "[*] Ports copied to clipboard\n"
end

# --- MKT ---
function mkt
	mkdir {nmap, content, exploits}
	echo "✅ Directorios Creados..."
end


# --- CLEAR HISTORY ---
function wipe
	history clear
	echo "Writing /dev/null to history..."
	echo "✅ Historial eliminado completamente."
end


# --- ALIASES (Atajos) ---

# Reemplazar 'ls' con 'eza' (con iconos y directorios primero)
alias ls='eza --icons --group-directories-first'
alias ll='eza -l --icons --group-directories-first'
alias la='eza -la --icons --group-directories-first'
alias tree='eza --tree --icons'

# Reemplazar 'cat' con 'bat'
alias cat='bat'

# Atajos para Git
alias g='git'
alias gs='git status'
alias ga='git add'
alias gc='git commit -m'
alias gp='git push'

# Atajos de sistema (Arch Linux)
alias update='sudo pacman -Syu'
alias install='sudo pacman -S'
alias remove='sudo pacman -Rs'

# Editor
alias v='nvim'
alias vim='nvim'
