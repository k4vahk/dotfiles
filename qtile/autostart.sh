#!/bin/sh

# RESOLUCION
xrandr --output Virtual-1 --mode 1920x1080 &

# Ejecuta el último fondo que configuraste con feh
~/.fehbg $

# (Opcional) Icono de red o volumen si los usas
# nm-applet &
# volumeicon &
