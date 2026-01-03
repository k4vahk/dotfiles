#!/bin/bash

# --- CONFIGURACIÓN Y VARIABLES ---
set -e # El script se detiene si hay un error crítico
USER_HOME="/home/$USER"
CONFIG_DIR="$USER_HOME/.config"
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}[*] INICIANDO INSTALACIÓN MAESTRA ARCH LINUX${NC}"
echo -e "${BLUE}[*] Asegúrate de estar ejecutando esto en la carpeta donde están 'fish', 'kitty', 'qtile'...${NC}"

# --- 0. VALIDACIONES DE SEGURIDAD ---
if [ "$EUID" -eq 0 ]; then
  echo -e "${RED}[!] ERROR: No ejecutes esto como root. Usa tu usuario normal.${NC}"
  exit 1
fi

# Solicitar credenciales sudo al inicio y mantenerlas activas
echo -e "${BLUE}[*] Solicitando permisos de sudo para la instalación...${NC}"
sudo -v
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

# --- 1. INSTALACIÓN DE DEPENDENCIAS CRÍTICAS (PRE-GIT) ---
echo -e "${GREEN}[+] Actualizando pacman e instalando herramientas base...${NC}"
sudo pacman -Syu --noconfirm
# Instalamos git y base-devel PRIMERO para poder hacer todo lo demás
sudo pacman -S --needed --noconfirm base-devel git wget curl unzip rust

# --- 2. REPOSITORIOS BLACKARCH (Opcional) ---
echo -e "${BLUE}[*] ¿Deseas instalar BlackArch? (S/n)${NC}"
read -r response
if [[ "$response" =~ ^([sS][iI]|[sS])$ ]] || [[ -z "$response" ]]; then
    echo -e "${GREEN}[+] Instalando BlackArch strap...${NC}"
    curl -O https://blackarch.org/strap.sh
    chmod +x strap.sh
    sudo ./strap.sh
    sudo pacman -Syu --noconfirm
    rm strap.sh
    echo -e "${GREEN}[✓] BlackArch repositorios activos.${NC}"
fi

# --- 3. INSTALACIÓN DE PARU (AUR HELPER) ---
if ! command -v paru &> /dev/null; then
    echo -e "${GREEN}[+] Instalando Paru (puede tardar un poco)...${NC}"
    rm -rf /tmp/paru # Limpiar intentos previos
    git clone https://aur.archlinux.org/paru.git /tmp/paru
    cd /tmp/paru
    makepkg -si --noconfirm
    cd -
    echo -e "${GREEN}[✓] Paru instalado.${NC}"
else
    echo -e "${GREEN}[✓] Paru ya está instalado.${NC}"
fi

# --- 4. INSTALACIÓN DE PAQUETES OFICIALES ---
echo -e "${GREEN}[+] Instalando paquetes del sistema...${NC}"

PACMAN_PKGS=(
    # --- Sistema y Utilidades ---
    base base-devel openssh docker git wget curl
    net-tools unzip xclip xsel
    eza bat fastfetch neovim
    
    # --- Entorno Gráfico (X11) ---
    xorg-server xorg-xinit xorg-xrandr arandr
    mesa xf86-video-intel xf86-video-amdgpu # Drivers video
    
    # --- Qtile y Apariencia ---
    qtile
    picom           # Transparencias
    feh             # Wallpapers
    lxsession       # Polkit (necesario para apps con sudo gráfico)
    rofi            # Lanzador
    dunst           # Notificaciones
    
    # --- Audio (Pipewire - Estándar moderno) ---
    pipewire pipewire-pulse pipewire-alsa pamixer
    
    # --- Terminal y Shell ---
    kitty
    fish
    starship
    
    # --- Python (Vital para Qtile) ---
    python-pip python-psutil python-iwlib python-dbus
    
    # --- Virtualización ---
    virtualbox-guest-utils
    
    # --- Fuentes (Necesarias para iconos) ---
    ttf-mononoki-nerd
    ttf-firacode-nerd
    ttf-jetbrains-mono-nerd
    noto-fonts-emoji
)

sudo pacman -S --needed --noconfirm "${PACMAN_PKGS[@]}"

# --- 5. PAQUETES AUR ---
echo -e "${GREEN}[+] Instalando navegadores desde AUR...${NC}"
paru -S --needed --noconfirm librewolf-bin brave-bin

# --- 6. CONFIGURACIÓN DEL ENTORNO GRÁFICO (.xinitrc) ---
# ESTE PASO ES CRÍTICO: Sin esto, 'startx' no sabe que debe abrir Qtile
echo -e "${GREEN}[+] Configurando arranque de Qtile...${NC}"
echo "exec qtile start" > "$USER_HOME/.xinitrc"

# --- 7. COPIADO DE DOTFILES (ARCHIVOS DE CONFIGURACIÓN) ---
echo -e "${BLUE}[*] Copiando tus configuraciones...${NC}"

# Asegurar carpeta .config
mkdir -p "$CONFIG_DIR"

instalar_config() {
    NOMBRE="$1"
    if [ -e "./$NOMBRE" ]; then
        echo -e " -> Instalando $NOMBRE..."
        # Borrar config anterior para evitar conflictos de carpetas anidadas
        rm -rf "$CONFIG_DIR/$NOMBRE"
        # Copiar la nueva
        cp -r "./$NOMBRE" "$CONFIG_DIR/"
    else
        echo -e "${RED}[!] CUIDADO: No se encontró './$NOMBRE' en la carpeta actual.${NC}"
    fi
}

instalar_config "fish"
instalar_config "kitty"
instalar_config "qtile"
instalar_config "rofi"

# Starship va suelto a veces, o dentro de config. Lo ponemos en la raíz de .config
if [ -f "./starship.toml" ]; then
    echo " -> Instalando starship.toml..."
    cp "./starship.toml" "$CONFIG_DIR/starship.toml"
fi

# --- 8. HABILITAR SERVICIOS ---
echo -e "${GREEN}[+] Habilitando demonios del sistema...${NC}"
sudo systemctl enable --now sshd
sudo systemctl enable --now docker.service
sudo usermod -aG docker "$USER"

# Servicios de VirtualBox
sudo systemctl enable vboxservice || true
sudo systemctl start vboxservice || true

# --- 9. CONFIGURACIÓN FINAL (Shell y Root) ---
# Cambiar shell a Fish
if [[ "$SHELL" != */fish ]]; then
    echo -e "${GREEN}[+] Cambiando shell por defecto a Fish...${NC}"
    sudo usermod --shell /usr/bin/zsh $USER
    sudo usermod --shell /usr/bin/zsh root

    sudo ln -s -f /home/$USER/.config/fish/config.fish /root/.config/fish/config.fish
    sudo ln -s -f /home/$USER/.config/starship.toml /root/.config/starship.toml
fi

# Enlaces simbólicos para Root (Opcional pero recomendado)
echo -e "${GREEN}[+] Vinculando config de Fish a Root...${NC}"
sudo mkdir -p /root/.config/fish
[ -f "$CONFIG_DIR/fish/config.fish" ] && sudo ln -sf "$CONFIG_DIR/fish/config.fish" /root/.config/fish/config.fish
[ -f "$CONFIG_DIR/starship.toml" ] && sudo ln -sf "$CONFIG_DIR/starship.toml" /root/.config/starship.toml

echo -e "${BLUE}==============================================${NC}"
echo -e "${GREEN}   INSTALACIÓN FINALIZADA CON ÉXITO   ${NC}"
echo -e "${BLUE}==============================================${NC}"
echo -e "1. Escribe 'reboot' para reiniciar."
echo -e "2. Al volver, inicia sesión y escribe 'startx' para entrar a Qtile."
