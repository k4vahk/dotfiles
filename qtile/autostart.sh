#!/bin/sh

# ==============================================================================
#   Integracion con el hipervisor (se detecta solo, no hay que editar nada)
# ==============================================================================
# Cada bloque solo corre si su comando existe, asi el mismo archivo sirve en
# VirtualBox, VMware o bare metal sin lanzar comandos inexistentes.

# --- VirtualBox: portapapeles compartido, drag & drop, etc. ---
if command -v VBoxClient >/dev/null 2>&1; then
    VBoxClient --clipboard &
    VBoxClient --draganddrop &
    VBoxClient --checkhostversion &
    VBoxClient --seamless &
fi

# --- VMware: portapapeles, drag & drop y autofit de resolucion ---
# qtile no ejecuta el autostart XDG, asi que hay que lanzar a mano el proceso
# de sesion de usuario (vmtoolsd -n vmusr). Si ya esta corriendo, no se duplica.
if ! pgrep -f "vmtoolsd -n vmusr" >/dev/null 2>&1; then
    if command -v vmware-user-suid-wrapper >/dev/null 2>&1; then
        vmware-user-suid-wrapper &
    elif command -v vmtoolsd >/dev/null 2>&1; then
        vmtoolsd -n vmusr &
    fi
fi

# Configuracion de pantalla: solo si existe la salida Virtual-1 (VM).
# En VMware el autofit de open-vm-tools ya ajusta la resolucion a la ventana;
# si te estorba, comenta este bloque.
if xrandr 2>/dev/null | grep -q "^Virtual-1 connected"; then
    xrandr --output Virtual-1 --mode 1920x1080 &
fi

# ==============================================================================
#   Resto del entorno
# ==============================================================================

# Gestor de portapapeles
copyq &

# Icono de red (si lo usas)
# nm-applet &

# Fondo de pantalla (si usas nitrogen o feh)
~/.fehbg &

# Picom
picom -b &

# Idiomas
#setxkbmap es &
