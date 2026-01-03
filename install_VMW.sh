#!/bin/bash

# --- CONFIGURACIÓN Y VARIABLES ---
set -e 
USER_HOME="/home/$USER"
CONFIG_DIR="$USER_HOME/.config"
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}[*] INICIANDO POST-INSTALACIÓN (VMware Edition)${NC}"

# --- 0. VALIDACIONES ---
if [ "$EUID" -eq 0 ]; then
  echo -e "${RED}[!] ERROR: Ejecuta esto con tu usuario normal, no como root.${NC}"
  exit 1
fi

echo -e "${BLUE}[*] Solicitando permisos sudo...${NC}"
sudo -v
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

# --- 1. DEPENDENCIAS BASE ---
echo -e "${GREEN}[+] Asegurando base-devel y git...${NC}"
sudo pacman -S --needed --noconfirm base base-devel git wget curl unzip rust

# --- 2. REPOSITORIOS BLACKARCH (Opcional) ---
echo -e "${BLUE}[*] ¿Deseas instalar BlackArch? (S/n)${NC}"
read -r response
if [[ "$response" =~ ^([sS][iI]|[sS])$ ]] || [[ -z "$response" ]]; then
    echo -e "${GREEN}[+] Instalando BlackArch...${NC}"
    curl -O https://blackarch.org/strap.sh
    chmod +x strap.sh
    sudo ./strap.sh
    sudo pacman -Syu --noconfirm
    rm strap.sh
fi

# --- 3. INSTALACIÓN DE PARU ---
if ! command -v paru &> /dev/null; then
    echo -e "${GREEN}[+] Instalando Paru...${NC}"
    rm -rf /tmp/paru 
    git clone https://aur.archlinux.org/paru.git /tmp/paru
    cd /tmp/paru
    makepkg -si --noconfirm
    cd -
fi

# --- 4. PAQUETES DEL SISTEMA ---
echo -e "${GREEN}[+] Instalando paquetes (Versión VMware)...${NC}"

PACMAN_PKGS=(
    # Utilidades
    openssh docker net-tools xclip xsel
    eza bat fastfetch neovim
    
    # Entorno Gráfico (X11)
    xorg-server xorg-xinit xorg-xrandr arandr
    
    # --- ESPECÍFICO VMWARE (Drivers Video) ---
    mesa xf86-video-vmware 
    
    # Qtile y Apariencia
    qtile picom feh lxsession rofi dunst
    
    # Terminal y Shell
    kitty fish starship
    
    # Python
    python-pip python-psutil python-iwlib python-dbus
    
    # --- ESPECÍFICO VMWARE (Herramientas) ---
    open-vm-tools gtkmm3
    
    # Fuentes
    ttf-mononoki-nerd ttf-firacode-nerd ttf-jetbrains-mono-nerd noto-fonts-emoji
)

sudo pacman -S --needed --noconfirm "${PACMAN_PKGS[@]}"

# --- 5. PAQUETES AUR ---
echo -e "${GREEN}[+] Instalando navegadores (AUR)...${NC}"
paru -S --needed --noconfirm librewolf-bin brave-bin

# --- 6. CONFIGURACIÓN XINITRC ---
echo "exec qtile start" > "$USER_HOME/.xinitrc"

# --- 7. DOTFILES ---
echo -e "${BLUE}[*] Copiando configuraciones...${NC}"
mkdir -p "$CONFIG_DIR"

instalar_config() {
    if [ -e "./$1" ]; then
        rm -rf "$CONFIG_DIR/$1"
        cp -r "./$1" "$CONFIG_DIR/"
        echo " -> $1 instalado."
    else
        echo -e "${RED}[!] Falta la carpeta ./$1${NC}"
    fi
}

instalar_config "fish"
instalar_config "kitty"
instalar_config "qtile"
instalar_config "rofi"
[ -f "./starship.toml" ] && cp "./starship.toml" "$CONFIG_DIR/starship.toml"

# --- 8. HABILITAR SERVICIOS ---
echo -e "${GREEN}[+] Habilitando servicios...${NC}"
sudo systemctl enable --now sshd
sudo systemctl enable --now docker.service
sudo usermod -aG docker "$USER"

# --- ESPECÍFICO VMWARE ---
echo -e "${GREEN}[+] Activando servicios de VMware Tools...${NC}"
sudo systemctl enable --now vmtoolsd.service

# --- 9. CAMBIO DE SHELL (CORREGIDO) ---
if [[ "$SHELL" != */fish ]]; then
    echo -e "${GREEN}[+] Cambiando shell a Fish...${NC}"
    sudo usermod --shell /usr/bin/fish $USER
    sudo usermod --shell /usr/bin/fish root
fi

# Vincular config de root
sudo mkdir -p /root/.config/fish
[ -f "$CONFIG_DIR/fish/config.fish" ] && sudo ln -sf "$CONFIG_DIR/fish/config.fish" /root/.config/fish/config.fish
[ -f "$CONFIG_DIR/starship.toml" ] && sudo ln -sf "$CONFIG_DIR/starship.toml" /root/.config/starship.toml

echo -e "${GREEN}[✓] INSTALACIÓN VMWARE COMPLETADA. Reinicia el sistema.${NC}"
