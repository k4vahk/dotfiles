# ~/.config/qtile/config.py
import os
import sys
import subprocess
from libqtile import hook

sys.path.append(os.path.dirname(__file__))

from modules.keys import keys, mod
from modules.groups import groups
from modules.layouts import layouts, floating_layout
from modules.screens import screens

# Configuraciones generales
dgroups_key_binder = None
dgroups_app_rules = []
follow_mouse_focus = True
bring_front_click = False
cursor_warp = False
auto_fullscreen = True
focus_on_window_activation = "smart"
reconfigure_screens = True
wmname = "LG3D"

# Hook para autostart (Opcional, si quieres iniciar apps al principio)
@hook.subscribe.startup_once
def autostart():
     home = os.path.expanduser('~/.config/qtile/autostart.sh')
     subprocess.Popen(["VBoxClient", "--clipboard"])
     subprocess.Popen(["copyq"])
     subprocess.Popen([home])
