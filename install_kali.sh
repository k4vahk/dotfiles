#!/bin/bash

# ==============================================================================
#   INSTALADOR DE ENTORNO QTILE PARA KALI LINUX
#   Uso: clonar el repo -> cd dotfiles -> ./install_kali.sh
#   Reproduce el entorno completo (qtile + zsh + p10k) en VM o bare metal.
# ==============================================================================

set -e  # Detener el script si hay un error critico

# --- COLORES PARA OUTPUT ---
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}[*] INICIANDO INSTALACION DEL ENTORNO QTILE PARA KALI${NC}"

# ==============================================================================
#   0. VALIDACIONES
# ==============================================================================
if [ "$EUID" -eq 0 ]; then
    echo -e "${RED}[!] ERROR: Ejecuta como usuario normal (kava), NO como root.${NC}"
    exit 1
fi

# Verificar que estamos dentro de la carpeta de dotfiles (debe existir ./qtile)
if [ ! -d "./qtile" ]; then
    echo -e "${RED}[!] ERROR: No encuentro la carpeta 'qtile'.${NC}"
    echo -e "${RED}    Ejecuta este script DENTRO de tu carpeta de dotfiles.${NC}"
    exit 1
fi

# Guardar la ruta del repo de dotfiles (donde se ejecuta el script)
DOTFILES_DIR="$(pwd)"
CONFIG_DIR="$HOME/.config"
FONTS_DIR="$HOME/.local/share/fonts"

# Mantener permisos de sudo vivos durante toda la ejecucion
sudo -v
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

# ==============================================================================
#   1. DETECCION DE ENTORNO (VM vs BARE METAL)
# ==============================================================================
echo -e "${BLUE}[*] Detectando tipo de entorno...${NC}"
if systemd-detect-virt -q; then
    IS_VM=true
    VIRT_TYPE="$(systemd-detect-virt)"
    echo -e "${GREEN}[+] Entorno virtualizado detectado: ${VIRT_TYPE}${NC}"
else
    IS_VM=false
    echo -e "${GREEN}[+] Bare metal detectado.${NC}"
fi

# ==============================================================================
#   2. PREPARACION Y DEPENDENCIAS
# ==============================================================================
echo -e "${GREEN}[+] Actualizando repositorios...${NC}"
sudo apt update

echo -e "${GREEN}[+] Creando directorios de usuario (Documents, Downloads...)${NC}"
sudo apt install -y xdg-user-dirs
xdg-user-dirs-update

echo -e "${GREEN}[+] Instalando dependencias de compilacion...${NC}"
# python3-dev y libffi-dev son OBLIGATORIOS para compilar widgets de Qtile
sudo apt install -y build-essential git wget curl unzip python3-pip \
    python3-dev libffi-dev libpangocairo-1.0-0 libiw-dev

# ==============================================================================
#   3. INSTALACION DE PAQUETES (APT)
# ==============================================================================
echo -e "${GREEN}[+] Instalando paquetes del sistema...${NC}"

PKGS=(
    # --- Sistema X11 y Login ---
    xorg
    lightdm
    lightdm-gtk-greeter

    # --- Qtile y dependencias ---
    qtile
    python3-xcffib
    python3-cairocffi
    python3-psutil
    python3-dbus
    python3-xdg

    # --- Entorno visual y temas ---
    picom
    feh
    rofi
    dunst
    lxpolkit               # Autenticacion grafica (sudo grafico)
    arandr                 # Gestion de pantallas
    lxappearance           # Configurar temas GTK
    arc-theme              # Tema oscuro GTK
    papirus-icon-theme     # Iconos

    # --- Red ---
    network-manager-gnome  # Icono nm-applet en la barra

    # --- Terminal / Shell ---
    kitty
    zsh
    zsh-autosuggestions
    zsh-syntax-highlighting

    # --- Fuentes ---
    fonts-ubuntu           # Fuente Ubuntu (texto de la barra)

    # --- Audio ---
    pipewire-audio
    pavucontrol
    alsa-utils
    pamixer

    # --- Herramientas y servicios ---
    neovim
    bat
    eza
    fastfetch
    thunar
    thunar-archive-plugin  # Click derecho -> Extraer aqui
    xclip
    xsel
    flameshot
    openssh-server
    docker.io
    seclists                # Wordlists para pentesting
)

sudo apt install -y "${PKGS[@]}"

# ==============================================================================
#   4. GUEST UTILS (segun el hipervisor detectado)
# ==============================================================================
if [ "$IS_VM" = true ]; then
    case "$VIRT_TYPE" in
        oracle)
            echo -e "${GREEN}[+] VirtualBox detectado. Instalando VirtualBox Guest Utils...${NC}"
            sudo apt install -y virtualbox-guest-x11 virtualbox-guest-utils || \
                echo -e "${RED}[!] Advertencia: fallo la instalacion de guest utils de VirtualBox.${NC}"
            # Agregar al grupo vboxsf solo si el grupo existe (carpetas compartidas)
            if getent group vboxsf > /dev/null; then
                sudo usermod -aG vboxsf "$USER"
            fi
            ;;
        vmware)
            echo -e "${GREEN}[+] VMware detectado. Instalando open-vm-tools...${NC}"
            sudo apt install -y open-vm-tools open-vm-tools-desktop || \
                echo -e "${RED}[!] Advertencia: fallo la instalacion de open-vm-tools.${NC}"
            # Habilitar el servicio de VMware Tools
            sudo systemctl enable open-vm-tools 2>/dev/null || true
            ;;
        *)
            echo -e "${BLUE}[*] Hipervisor '${VIRT_TYPE}' detectado, sin guest utils especificas configuradas.${NC}"
            echo -e "${BLUE}    (KVM/QEMU: instala 'qemu-guest-agent' si lo necesitas manualmente)${NC}"
            ;;
    esac
else
    echo -e "${BLUE}[*] Bare metal: se omiten los guest utils de virtualizacion.${NC}"
fi

# ==============================================================================
#   5. LIBRERIAS Y FIXES (PIP)
# ==============================================================================
# --break-system-packages es requerido en Kali/Debian 12+

echo -e "${GREEN}[+] Instalando qtile-extras (decoraciones de la barra)...${NC}"
sudo pip3 install qtile-extras --break-system-packages || \
    echo -e "${RED}[!] Advertencia: fallo qtile-extras. La barra podria no cargar bien.${NC}"

echo -e "${GREEN}[+] Instalando libreria WiFi (iwlib)...${NC}"
sudo pip3 install iwlib --break-system-packages || \
    echo -e "${RED}[!] Advertencia: fallo iwlib. El widget wlan podria no cargar.${NC}"

echo -e "${GREEN}[+] Instalando dbus-fast (silencia warnings de qtile)...${NC}"
sudo pip3 install dbus-fast --break-system-packages || \
    echo -e "${RED}[!] Advertencia: fallo dbus-fast (no critico).${NC}"

# Fix para 'bat' (Debian lo renombra a batcat por conflicto de nombres)
# Symlink en /usr/local/bin para que funcione en user Y en root (flujo sudo su)
if command -v batcat &> /dev/null; then
    sudo ln -sf /usr/bin/batcat /usr/local/bin/bat
fi

# ==============================================================================
#   5b. LIBREWOLF (navegador, via extrepo - metodo oficial Debian)
# ==============================================================================
echo -e "${GREEN}[+] Instalando LibreWolf...${NC}"
if ! command -v librewolf &> /dev/null; then
    sudo apt install -y extrepo
    sudo extrepo enable librewolf
    sudo extrepo update librewolf
    sudo apt update
    sudo apt install -y librewolf || \
        echo -e "${RED}[!] Advertencia: fallo la instalacion de LibreWolf.${NC}"
else
    echo " -> LibreWolf ya esta instalado."
fi

# ==============================================================================
#   6. LSD (ultima version desde GitHub)
# ==============================================================================
echo -e "${GREEN}[+] Instalando lsd (reemplazo de ls)...${NC}"
if ! command -v lsd &> /dev/null; then
    LSD_URL=$(curl -s https://api.github.com/repos/lsd-rs/lsd/releases/latest \
        | grep "browser_download_url" \
        | grep "amd64.deb" \
        | grep -v "musl" \
        | cut -d '"' -f 4)

    if [ -n "$LSD_URL" ]; then
        echo " -> Descargando desde: $LSD_URL"
        wget -q --show-progress -O /tmp/lsd.deb "$LSD_URL"
        sudo dpkg -i /tmp/lsd.deb || sudo apt-get install -f -y
        rm -f /tmp/lsd.deb
    else
        echo -e "${RED}[!] No pude obtener la URL de lsd. Instalalo manualmente.${NC}"
    fi
else
    echo " -> lsd ya esta instalado."
fi

# ==============================================================================
#   7. STARSHIP  --> ELIMINADO (reemplazado por Powerlevel10k)
# ==============================================================================

# ==============================================================================
#   8. POWERLEVEL10K (ruta compartida, portable para user y root)
# ==============================================================================
echo -e "${GREEN}[+] Instalando Powerlevel10k en ruta compartida...${NC}"
P10K_DIR="/usr/share/powerlevel10k"
if [ ! -d "$P10K_DIR" ]; then
    sudo git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$P10K_DIR"
else
    echo " -> Powerlevel10k ya esta clonado en $P10K_DIR."
fi

# ==============================================================================
#   9. FUENTES NERD FONTS
# ==============================================================================
echo -e "${BLUE}[*] Instalando Nerd Fonts...${NC}"
mkdir -p "$FONTS_DIR"

install_font() {
    FONT_NAME="$1"
    # Idempotencia: extraer a subcarpeta para que el guard -d funcione
    if [ ! -d "$FONTS_DIR/$FONT_NAME" ]; then
        URL="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/$FONT_NAME.zip"
        echo " -> Descargando $FONT_NAME..."
        wget -q --show-progress -O "/tmp/$FONT_NAME.zip" "$URL"
        unzip -o -q "/tmp/$FONT_NAME.zip" -d "$FONTS_DIR/$FONT_NAME"
        rm -f "/tmp/$FONT_NAME.zip"
    else
        echo " -> $FONT_NAME ya instalada."
    fi
}

install_font "FiraCode"
install_font "JetBrainsMono"
install_font "UbuntuMono"     # Iconos de la barra
install_font "Mononoki"
install_font "Hack"

echo " -> Actualizando cache de fuentes..."
fc-cache -f > /dev/null

# ==============================================================================
#   10. COPIA DE DOTFILES
# ==============================================================================
echo -e "${BLUE}[*] Copiando configuraciones...${NC}"
mkdir -p "$CONFIG_DIR"

# Copiar carpetas de config a ~/.config (con backup si ya existen)
instalar_config() {
    NOMBRE="$1"
    if [ -e "$DOTFILES_DIR/$NOMBRE" ]; then
        echo -e " -> Configurando $NOMBRE..."
        # Backup con timestamp si ya existe
        if [ -e "$CONFIG_DIR/$NOMBRE" ]; then
            mv "$CONFIG_DIR/$NOMBRE" "$CONFIG_DIR/${NOMBRE}.bak.$(date +%Y%m%d%H%M%S)"
        fi
        cp -r "$DOTFILES_DIR/$NOMBRE" "$CONFIG_DIR/"
    else
        echo -e "${RED}[!] AVISO: No existe './$NOMBRE' para copiar.${NC}"
    fi
}

instalar_config "kitty"
instalar_config "picom"
instalar_config "qtile"
instalar_config "rofi"

# Copiar dotfiles de zsh al home (con backup si existen)
echo -e "${GREEN}[+] Copiando .zshrc y .p10k.zsh...${NC}"
for f in ".zshrc" ".p10k.zsh"; do
    if [ -f "$DOTFILES_DIR/$f" ]; then
        [ -f "$HOME/$f" ] && cp "$HOME/$f" "$HOME/${f}.bak.$(date +%Y%m%d%H%M%S)"
        cp "$DOTFILES_DIR/$f" "$HOME/$f"
    else
        echo -e "${RED}[!] AVISO: No encuentro $f en los dotfiles.${NC}"
    fi
done

# ==============================================================================
#   11. SERVICIOS Y GRUPOS
# ==============================================================================
echo -e "${GREEN}[+] Activando servicios del sistema...${NC}"
sudo systemctl enable lightdm
sudo systemctl enable ssh
sudo systemctl enable docker

echo -e "${GREEN}[+] Configurando permisos de grupos...${NC}"
sudo usermod -aG docker "$USER"

# ==============================================================================
#   12. SHELL ZSH (USER Y ROOT)
# ==============================================================================
echo -e "${GREEN}[+] Estableciendo zsh como shell por defecto...${NC}"

# Shell del usuario
if [[ "$SHELL" != */zsh ]]; then
    sudo usermod --shell /usr/bin/zsh "$USER"
fi

# Shell de root
sudo usermod --shell /usr/bin/zsh root

# Espejo de config para root (symlinks a las configs del usuario)
echo -e "${GREEN}[+] Enlazando configs de zsh para root...${NC}"
[ -e /root/.zshrc ]   && sudo mv /root/.zshrc   "/root/.zshrc.bak.$(date +%Y%m%d%H%M%S)"
[ -e /root/.p10k.zsh ] && sudo mv /root/.p10k.zsh "/root/.p10k.zsh.bak.$(date +%Y%m%d%H%M%S)"
sudo ln -sf "$HOME/.zshrc"   /root/.zshrc
sudo ln -sf "$HOME/.p10k.zsh" /root/.p10k.zsh

# Enlazar config de kitty para root (para que la terminal en root tenga tu tema)
echo -e "${GREEN}[+] Enlazando config de kitty para root...${NC}"
sudo mkdir -p /root/.config
[ -e /root/.config/kitty ] && sudo mv /root/.config/kitty "/root/.config/kitty.bak.$(date +%Y%m%d%H%M%S)"
sudo ln -sf "$CONFIG_DIR/kitty" /root/.config/kitty

# ==============================================================================
#   FINALIZADO
# ==============================================================================
echo -e "${BLUE}===============================================${NC}"
echo -e "${GREEN}    INSTALACION FINALIZADA CON EXITO    ${NC}"
echo -e "${BLUE}===============================================${NC}"
echo -e ""
echo -e "Notas:"
echo -e "  - Si las fuentes no cargan en la terminal, revisa la config de kitty."
if [ "$IS_VM" = false ]; then
    echo -e "  ${BLUE}- Estas en BARE METAL: revisa que picom tenga use-damage/vsync${NC}"
    echo -e "  ${BLUE}  en TRUE para mejor rendimiento (en VM van en false).${NC}"
elif [ "$VIRT_TYPE" = "vmware" ]; then
    echo -e "  ${BLUE}- Estas en VMware: tiene mejor soporte 3D que VirtualBox.${NC}"
    echo -e "  ${BLUE}  Si quieres, puedes probar backend=\"glx\" en picom en vez de${NC}"
    echo -e "  ${BLUE}  xrender para ver si rinde mejor (activa 3D acceleration${NC}"
    echo -e "  ${BLUE}  en la config de la VM en VMware primero).${NC}"
fi
echo -e ""
echo -e " -> REINICIA AHORA con: ${GREEN}sudo reboot${NC}"
