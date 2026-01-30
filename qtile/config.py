import os
import sys
import subprocess
import time
from libqtile import hook

# Aseguramos que python encuentre tus módulos
sys.path.append(os.path.dirname(__file__))

# Importamos tus módulos
# Nota: Si alguno falla, Qtile podría crashear, asegúrate de que no tengan errores de sintaxis.
from modules.keys import keys, mod
from modules.groups import groups
from modules.layouts import layouts, floating_layout
from modules.screens import screens

# --- Configuraciones del Sistema ---

dgroups_key_binder = None
dgroups_app_rules = []

# Comportamiento del mouse y foco
follow_mouse_focus = True
bring_front_click = False
cursor_warp = False # Cambia a True si quieres que el mouse salte al centro de la ventana al cambiar foco

# Reglas de ventanas y fullscreen
auto_fullscreen = True
focus_on_window_activation = "smart" # "smart" es lo ideal, evita que popups roben foco innecesariamente
reconfigure_screens = True

# Hack para que aplicaciones Java (como IntelliJ o Minecraft) funcionen bien en Tiling WMs
wmname = "LG3D"

# --- Hooks (Autostart) ---

@hook.subscribe.startup_once
def autostart():
    """
    Ejecuta el script de inicio.
    Es mejor centralizar todo en el .sh en lugar de tener subprocesos sueltos aquí.
    """
    home = os.path.expanduser('~/.config/qtile/autostart.sh')
    
    # Verificamos si el script existe y es ejecutable antes de lanzarlo
    if os.path.isfile(home):
        subprocess.Popen([home])

@hook.subscribe.setgroup
def virtualbox_refresh():
    # Pequeño trigger para forzar el redibujado en la VM
    qtile.current_screen.group.cmd_toscreen()
