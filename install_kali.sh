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

echo -e "${BLUE}[*] INICIANDO INSTALACIÓN FULL QTILE PARA KALI LINUX${NC}"

# --- 0. VALIDACIONES ---
if [ "$EUID" -eq 0 ]; then
  echo -e "${RED}[!] ERROR: Ejecuta como usuario normal (kali), NO como root.${NC}"
  exit 1
fi

sudo -v
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

# --- 1. BASE Y DEPENDENCIAS DE CONSTRUCCIÓN ---
echo -e "${GREEN}[+] Actualizando repositorios y base...${NC}"
sudo apt update && sudo apt upgrade -y
# Instalamos pip y herramientas de compilación por si algún widget de Qtile lo requiere
sudo apt install -y build-essential git wget curl unzip python3-pip libpangocairo-1.0-0

# --- 2. INSTALACIÓN DE PAQUETES (FULL QTILE) ---
echo -e "${GREEN}[+] Instalando Qtile y todo su ecosistema...${NC}"

PKGS=(
    # --- X11 y Servidor Gráfico (Vital si vienes de entorno Wayland o mínimo) ---
    xorg
    xserver-xorg
    xinit
    
    # --- Qtile y sus dependencias de Python ---
    qtile
    python3-xcffib      # Binding X11 (crítico)
    python3-cairocffi   # Gráficos (crítico)
    python3-psutil      # Widgets de CPU/RAM
    python3-dbus        # Notificaciones y control
    python3-xdg         # Manejo de rutas estándar
    python3-iwlib       # Widget de WiFi (Wlan)
    
    # --- Componentes del Entorno (La "experiencia" completa) ---
    picom               # Compositor (transparencias/sombras)
    feh                 # Fondo de pantalla (Wallpaper)
    rofi                # Lanzador de aplicaciones (Menú)
    dunst               # Servidor de notificaciones
    lxpolkit            # Agente de autenticación (para que Apps pidan password visualmente)
    arandr              # Gestor de pantallas (GUI para xrandr)
    
    # --- Terminal y Shell ---
    kitty
    fish
    
    # --- Audio (Pipewire) ---
    pipewire-audio
    pavucontrol
    alsa-utils
    pamixer             # Control de volumen por terminal (útil para atajos de teclado)
    
    # --- Herramientas Útiles ---
    neovim
    bat                 # Visualizador de archivos mejorado
    eza                 # ls mejorado
    fastfetch           # Información del sistema
    ranger              # Gestor de archivos gráfico
    xclip               # Portapapeles
    xsel                # Portapapeles
    flameshot           # Capturas de pantalla
    
    # --- Drivers Virtualización (si estás en VM) ---
    virtualbox-guest-x11
)

sudo apt install -y "${PKGS[@]}"

# Fix para 'bat' en Kali (conflicto de nombre)
if command -v batcat &> /dev/null; then
    mkdir -p "$USER_HOME/.local/bin"
    ln -sf /usr/bin/batcat "$USER_HOME/.local/bin/bat"
    export PATH="$USER_HOME/.local/bin:$PATH"
fi

# --- 3. STARSHIP ---
echo -e "${GREEN}[+] Instalando Starship...${NC}"
curl -sS https://starship.rs/install.sh | sh -s -- -y

# --- 4. FUENTES (NERD FONTS - Descarga Manual) ---
echo -e "${BLUE}[*] Instalando fuentes Nerd Fonts (Vital para iconos)...${NC}"
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

# --- 5. INSTALACIÓN DE DOTFILES ---
echo -e "${BLUE}[*] Copiando tus configuraciones...${NC}"
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

# --- 6. SHELL POR DEFECTO ---
if [[ "$SHELL" != */fish ]]; then
    echo -e "${GREEN}[+] Cambiando shell a Fish...${NC}"
    chsh -s "$(which fish)"
fi

echo -e "${BLUE}==============================================${NC}"
echo -e "${GREEN}   INSTALACIÓN COMPLETADA   ${NC}"
echo -e "${BLUE}==============================================${NC}"
echo -e "PASOS FINALES:"
echo -e "1. Asegúrate de que tu autostart.sh use 'feh':"
echo -e "   Ej: feh --bg-fill /usr/share/backgrounds/kali/kali-blue-gw.png &"
echo -e "2. Reinicia ('sudo reboot')."
echo -e "3. En el Login de Kali (arriba a la derecha o en el engranaje):"
echo -e "   Selecciona 'Qtile' antes de entrar."
