#!/bin/sh

# Configuración de pantalla (si usas xrandr)
xrandr --output Virtual-1 --mode 1920x1080 &

# Soporte para VirtualBox (Portapapeles compartido, etc)
VBoxClient --clipboard &
VBoxClient --draganddrop &
VBoxClient --checkhostversion &
VBoxClient --seamless &

# Gestor de portapapeles
copyq &

# Icono de red (si lo usas)
# nm-applet &

# Fondo de pantalla (si usas nitrogen o feh)
~/.fehbg $

# Picom
picom -b &
