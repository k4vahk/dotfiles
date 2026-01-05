# modules/keys.py
from libqtile.config import Key
from libqtile.lazy import lazy

mod = "mod4"  # Tecla Super/Windows

keys = [
    # Mover foco
    Key([mod], "h", lazy.layout.left(), desc="Mover foco a la izquierda"),
    Key([mod], "l", lazy.layout.right(), desc="Mover foco a la derecha"),
    Key([mod], "j", lazy.layout.down(), desc="Mover foco abajo"),
    Key([mod], "k", lazy.layout.up(), desc="Mover foco arriba"),
    
    # Lanzar terminal
    Key([mod], "Return", lazy.spawn("kitty"), desc="Lanzar terminal"),

    # Rofi
    Key([mod], "m", lazy.spawn("rofi -show drun"), desc="Lanza rofi"),
    
    
    # Set Traget
    Key([mod], "t", lazy.spawn("/home/kava/.config/qtile/scripts/set_target.sh"),
        desc="Set CTF Target IP"),

    # 2. BORRAR OBJETIVO (Mod + Shift + t)
    # Un atajo rápido para limpiar sin abrir el menú
    Key([mod, "shift"], "t", lazy.spawn("sh -c 'echo \"No Target\" > /tmp/target'"), 
        desc="Clear CTF Target"
    ),

    # Kill window
    Key([mod], "w", lazy.window.kill()),

    # Control de Qtile
    Key([mod, "control"], "r", lazy.reload_config(), desc="Recargar config"),
    Key([mod, "control"], "q", lazy.shutdown(), desc="Salir de Qtile"),
]
