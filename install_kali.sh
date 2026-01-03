#!/bin/bash

# --- CONFIGURACIÓN Y COLORES ---
set -e # Detener si hay error crítico
USER_HOME="/home/$USER"
CONFIG_DIR="$USER_HOME/.config"
FONTS_DIR="$USER_HOME/.local/share/fonts"
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}[*] INICIANDO INSTALACIÓN CORREGIDA PARA KALI LINUX${NC}"

# --- 0. VALIDACIONES ---
if [ "$EUID" -eq 0 ]; then
  echo -e "${RED}[!] ERROR: Ejecuta como usuario normal (kali), NO como root.${NC}"
  exit 1
fi

sudo -v
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

# --- 1. PREPARACIÓN Y DEPENDENCIAS DE COMPILACIÓN ---
echo -e "${GREEN}[+] Actualizando repositorios...${NC}"
sudo apt update

echo -e "${GREEN}[+] Instalando herramientas de compilación...${NC}"
# Agregamos libiw-dev aquí, necesario para compilar el módulo wifi
sudo apt install -y build-essential git wget curl unzip python3-pip libpangocairo-1.0-0 libiw-dev

# --- 2. INSTALACIÓN DE PAQUETES (APT) ---
echo -e "${GREEN}[+] Instalando Qtile y utilidades...${NC}"

PKGS=(
    # --- Sistema X11 ---
    xorg
    xserver-xorg
    xinit
    
    # --- Qtile ---
    qtile
    python3-xcffib
    python3-cairocffi
    python3-psutil
    python3-dbus
    python3-xdg
    # ELIMINADO: python3-iwlib (Causaba el error)
    
    # --- Entorno ---
    picom
    feh
    rofi
    dunst
    lxpolkit
    arandr
    
    # --- Terminal/Shell ---
    kitty
    fish
    
    # --- Audio ---
    pipewire-audio
    pavucontrol
    alsa-utils
    pamixer
    
    # --- Herramientas ---
    neovim
    bat
    eza
    fastfetch
    thunar
    xclip
    xsel
    flameshot
    
    # --- Virtualización ---
    virtualbox-guest-x11
)

sudo apt install -y "${PKGS[@]}"

# --- 3. INSTALACIÓN MANUAL DE LIBRERÍAS PYTHON (PIP) ---
echo -e "${GREEN}[+] Instalando librería WiFi (iwlib) con pip...${NC}"
# Kali requiere --break-system-packages para instalar con pip a nivel sistema
# Esto es necesario porque el paquete nativo ya no existe en el repo.
sudo pip3 install iwlib --break-system-packages || echo -e "${RED}[!] Advertencia: Falló instalación de iwlib. El widget de WiFi podría no funcionar.${NC}"

# Fix para 'bat'
if command -v batcat &> /dev/null; then
    mkdir -p "$USER_HOME/.local/bin"
    ln -sf /usr/bin/batcat "$USER_HOME/.local/bin/bat"
    export PATH="$USER_HOME/.local/bin:$PATH"
fi

# --- 4. STARSHIP ---
echo -e "${GREEN}[+] Instalando Starship...${NC}"
curl -sS https://starship.rs/install.sh | sh -s -- -y

# --- 5. FUENTES NERD FONTS ---
echo -e "${BLUE}[*] Instalando fuentes...${NC}"
mkdir -p "$FONTS_DIR"

install_font() {
    FONT_NAME="$1"
    URL="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/$FONT_NAME.zip"
    echo " -> Descargando $FONT_NAME..."
    wget -q --show-progress -O "$FONT_NAME.zip" "$URL"
    unzip -o -q "$FONT_NAME.zip" -d "$FONTS_DIR"
    rm "$FONT_NAME.zip"
}

install_font "FiraCode"
install_font "JetBrainsMono"
install_font "Mononoki"

fc-cache -fv > /dev/null

# --- 6. DOTFILES ---
echo -e "${BLUE}[*] Copiando configuraciones...${NC}"
mkdir -p "$CONFIG_DIR"

instalar_config() {
    NOMBRE="$1"
    if [ -e "./$NOMBRE" ]; then
        echo -e " -> Configurando $NOMBRE..."
        rm -rf "$CONFIG_DIR/$NOMBRE"
        cp -r "./$NOMBRE" "$CONFIG_DIR/"
    else
        echo -e "${RED}[!] AVISO: No encontré la carpeta './$NOMBRE'.${NC}"
    fi
}

instalar_config "fish"
instalar_config "kitty"
instalar_config "qtile"
instalar_config "rofi"

if [ -f "./starship.toml" ]; then
    cp "./starship.toml" "$CONFIG_DIR/starship.toml"
fi

# --- 7. FINALIZAR ---
if [[ "$SHELL" != */fish ]]; then
    echo -e "${GREEN}[+] Cambiando shell a Fish...${NC}"
    chsh -s "$(which fish)"
fi

echo -e "${BLUE}==============================================${NC}"
echo -e "${GREEN}   INSTALACIÓN COMPLETADA   ${NC}"
echo -e "${BLUE}==============================================${NC}"
echo -e "Reinicia el sistema y selecciona Qtile en el login."
