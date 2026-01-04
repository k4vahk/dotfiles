#!/bin/bash

# --- CONFIGURACIÓN Y COLORES ---
set -e # Detener script si hay un error crítico
USER_HOME="/home/$USER"
CONFIG_DIR="$USER_HOME/.config"
FONTS_DIR="$USER_HOME/.local/share/fonts"

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}[*] INICIANDO INSTALACIÓN QTILE PARA KALI (BARE METAL / VBOX)${NC}"

# --- 0. VALIDACIONES ---
if [ "$EUID" -eq 0 ]; then
  echo -e "${RED}[!] ERROR: Ejecuta como usuario normal (kali), NO como root.${NC}"
  exit 1
fi

# Mantener permisos de sudo vivos durante toda la ejecución
sudo -v
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

# --- 1. PREPARACIÓN Y DIRECTORIOS ---
echo -e "${GREEN}[+] Creando directorios de usuario (Documents, Downloads...)${NC}"
sudo apt update
sudo apt install -y xdg-user-dirs
xdg-user-dirs-update

echo -e "${GREEN}[+] Instalando dependencias de compilación...${NC}"
# python3-dev y libffi-dev son OBLIGATORIOS para compilar widgets de Qtile
sudo apt install -y build-essential git wget curl unzip python3-pip libpangocairo-1.0-0 libiw-dev python3-dev libffi-dev

# --- 2. INSTALACIÓN DE PAQUETES (APT) ---
echo -e "${GREEN}[+] Instalando Paquetes del Sistema...${NC}"

PKGS=(
    # --- Sistema X11 y Login ---
    xorg
    xserver-xorg
    lightdm
    lightdm-gtk-greeter
    
    # --- Qtile y Dependencias ---
    qtile
    python3-xcffib
    python3-cairocffi
    python3-psutil
    python3-dbus
    python3-xdg
    
    # --- Entorno Visual y Temas ---
    picom
    feh
    rofi
    dunst
    lxpolkit              # Autenticación gráfica (sudo gráfico)
    arandr                # Gestión de pantallas
    lxappearance          # Configurar temas GTK
    arc-theme             # Tema oscuro GTK
    papirus-icon-theme    # Iconos
    
    # --- Red ---
    network-manager-gnome # Para tener el icono nm-applet en la barra
    
    # --- Terminal/Shell ---
    kitty
    fish
    
    # --- Audio ---
    pipewire-audio
    pavucontrol
    alsa-utils
    pamixer
    
    # --- Herramientas y Servicios ---
    neovim
    bat
    eza
    fastfetch
    thunar
    thunar-archive-plugin # Click derecho -> Extraer aquí
    xclip
    xsel
    flameshot
    openssh-server
    docker.io
    
    # --- Virtualización ---
    virtualbox-guest-x11
    virtualbox-guest-utils
)

sudo apt install -y "${PKGS[@]}"

# --- 3. FIXES Y LIBRERÍAS ---

# Fix para el módulo WiFi de Qtile (iwlib)
echo -e "${GREEN}[+] Instalando librería WiFi (iwlib) con pip...${NC}"
# Usamos --break-system-packages (Requerido en Kali/Debian 12+)
sudo pip3 install iwlib --break-system-packages || echo -e "${RED}[!] Advertencia: Falló iwlib. El widget wlan podría no cargar.${NC}"

# Fix para 'bat' (Debian lo renombra a batcat por conflicto de nombres)
if command -v batcat &> /dev/null; then
    mkdir -p "$USER_HOME/.local/bin"
    ln -sf /usr/bin/batcat "$USER_HOME/.local/bin/bat"
    export PATH="$USER_HOME/.local/bin:$PATH"
fi

# --- 4. STARSHIP ---
echo -e "${GREEN}[+] Instalando Starship Prompt...${NC}"
if ! command -v starship &> /dev/null; then
    curl -sS https://starship.rs/install.sh | sh -s -- -y
fi

# --- 5. FUENTES NERD FONTS ---
echo -e "${BLUE}[*] Instalando fuentes...${NC}"
mkdir -p "$FONTS_DIR"

install_font() {
    FONT_NAME="$1"
    if [ ! -d "$FONTS_DIR/$FONT_NAME" ]; then
        URL="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/$FONT_NAME.zip"
        echo " -> Descargando $FONT_NAME..."
        wget -q --show-progress -O "$FONT_NAME.zip" "$URL"
        unzip -o -q "$FONT_NAME.zip" -d "$FONTS_DIR"
        rm "$FONT_NAME.zip"
    else
        echo " -> $FONT_NAME ya instalada."
    fi
}

install_font "FiraCode"
install_font "JetBrainsMono"
install_font "Mononoki"
install_font "Hack" 

echo " -> Actualizando caché de fuentes..."
fc-cache -fv > /dev/null

# --- 6. DOTFILES ---
echo -e "${BLUE}[*] Copiando configuraciones...${NC}"
mkdir -p "$CONFIG_DIR"

# Verificación simple para evitar errores si no estás en la carpeta correcta
if [ ! -d "./qtile" ]; then
    echo -e "${RED}[!] ALERTA CRÍTICA: No encuentro la carpeta 'qtile'. Ejecuta este script DENTRO de tu carpeta de dotfiles.${NC}"
else
    instalar_config() {
        NOMBRE="$1"
        if [ -e "./$NOMBRE" ]; then
            echo -e " -> Configurando $NOMBRE..."
            rm -rf "$CONFIG_DIR/$NOMBRE"
            cp -r "./$NOMBRE" "$CONFIG_DIR/"
        else
            echo -e "${RED}[!] AVISO: No existe carpeta './$NOMBRE' para copiar.${NC}"
        fi
    }

    instalar_config "fish"
    instalar_config "kitty"
    instalar_config "qtile"
    instalar_config "rofi"
    instalar_config "dunst"
    instalar_config "picom"

    if [ -f "./starship.toml" ]; then
        cp "./starship.toml" "$CONFIG_DIR/starship.toml"
    fi
fi

# --- 7. SERVICIOS Y GRUPOS ---
echo -e "${GREEN}[+] Activando servicios del sistema...${NC}"

# Habilitar Login Gráfico
sudo systemctl enable lightdm

# Servicios
sudo systemctl enable ssh
sudo systemctl enable docker

# Permisos
sudo usermod -aG docker "$USER"
sudo usermod -aG vboxsf "$USER"

# --- 8. CONFIGURACIÓN DE SHELL (ROOT Y USER) ---
echo -e "${GREEN}[+] Configurando Fish Shell (User & Root)...${NC}"

# 1. Cambiar shell del usuario actual
if [[ "$SHELL" != */fish ]]; then
    sudo usermod --shell /usr/bin/fish "$USER"
fi

# 2. Cambiar shell de root
sudo usermod --shell /usr/bin/fish root

# 3. Vincular configuración de root a la del usuario (Espejo)
# Esto permite que cuando hagas 'sudo -i', veas el mismo tema y configs que tu usuario
echo -e "${GREEN}[+] Creando enlaces simbólicos para root...${NC}"
sudo mkdir -p /root/.config/fish
sudo mkdir -p /root/.config/starship

# Backup si existe algo
[ -f /root/.config/fish/config.fish ] && sudo mv /root/.config/fish/config.fish /root/.config/fish/config.fish.bak

# Enlazar configs
if [ -f "$CONFIG_DIR/fish/config.fish" ]; then
    sudo ln -sf "$CONFIG_DIR/fish/config.fish" /root/.config/fish/config.fish
fi

if [ -f "$CONFIG_DIR/starship.toml" ]; then
    sudo ln -sf "$CONFIG_DIR/starship.toml" /root/.config/starship.toml
fi

echo -e "${BLUE}==============================================${NC}"
echo -e "${GREEN}   INSTALACIÓN FINALIZADA CON ÉXITO   ${NC}"
echo -e "${BLUE}==============================================${NC}"
echo -e "AVISO: Si las fuentes no cargan en la terminal al reiniciar,"
echo -e "asegúrate de seleccionarlas en la config de Kitty o Terminal."
echo -e ""
echo -e " -> REINICIA AHORA con: sudo reboot"
