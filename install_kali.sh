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

echo -e "${BLUE}[*] INICIANDO INSTALACIÓN (MODO: FEH) PARA KALI LINUX${NC}"

# --- 0. VALIDACIONES ---
if [ "$EUID" -eq 0 ]; then
  echo -e "${RED}[!] ERROR: Ejecuta como usuario normal, NO como root.${NC}"
  exit 1
fi

sudo -v
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

# --- 1. BASE ---
echo -e "${GREEN}[+] Actualizando y preparando dependencias...${NC}"
sudo apt update && sudo apt upgrade -y
sudo apt install -y build-essential git wget curl unzip python3-pip

# --- 2. INSTALACIÓN DE PAQUETES ---
echo -e "${GREEN}[+] Instalando Entorno y Herramientas...${NC}"

PKGS=(
    # --- Gráficos y Window Manager ---
    xorg
    qtile
    picom
    feh                 # <--- CAMBIO: Feh en lugar de Nitrogen
    rofi
    dunst
    lxpolkit
    
    # --- Python/Widgets ---
    python3-psutil
    python3-dbus
    python3-iwlib
    
    # --- Terminal/Shell ---
    kitty
    fish
    
    # --- Audio ---
    pipewire-audio
    pavucontrol
    
    # --- Utils ---
    neovim
    bat
    eza
    fastfetch
    thunar
    xclip
    xsel
    
    # --- Virtualización ---
    virtualbox-guest-x11
)

sudo apt install -y "${PKGS[@]}"

# Fix para 'bat' en Kali
if command -v batcat &> /dev/null; then
    mkdir -p "$USER_HOME/.local/bin"
    ln -sf /usr/bin/batcat "$USER_HOME/.local/bin/bat"
    export PATH="$USER_HOME/.local/bin:$PATH"
fi

# --- 3. STARSHIP ---
echo -e "${GREEN}[+] Instalando Starship...${NC}"
curl -sS https://starship.rs/install.sh | sh -s -- -y

# --- 4. FUENTES (NERD FONTS) ---
echo -e "${BLUE}[*] Instalando fuentes (descarga manual)...${NC}"
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

# --- 5. DOTFILES ---
echo -e "${BLUE}[*] Instalando configuraciones...${NC}"
mkdir -p "$CONFIG_DIR"

instalar_config() {
    NOMBRE="$1"
    if [ -e "./$NOMBRE" ]; then
        echo -e " -> Configurando $NOMBRE..."
        rm -rf "$CONFIG_DIR/$NOMBRE"
        cp -r "./$NOMBRE" "$CONFIG_DIR/"
    else
        echo -e "${RED}[!] AVISO: Falta carpeta './$NOMBRE'.${NC}"
    fi
}

instalar_config "fish"
instalar_config "kitty"
instalar_config "qtile"
instalar_config "rofi"

if [ -f "./starship.toml" ]; then
    cp "./starship.toml" "$CONFIG_DIR/starship.toml"
fi

# --- 6. SHELL ---
if [[ "$SHELL" != */fish ]]; then
    echo -e "${GREEN}[+] Cambiando shell a Fish...${NC}"
    chsh -s "$(which fish)"
fi

echo -e "${BLUE}==============================================${NC}"
echo -e "${GREEN}   INSTALACIÓN FINALIZADA   ${NC}"
echo -e "${BLUE}==============================================${NC}"
echo -e "IMPORTANTE: Edita tu autostart.sh para usar feh:"
echo -e "   Borra: nitrogen --restore &"
echo -e "   Pon:   feh --bg-fill /ruta/a/tu/imagen.jpg &"
echo -e "Reinicia para ver los cambios."
