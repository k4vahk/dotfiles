import subprocess
import os
from libqtile import bar
from libqtile.config import Screen
# Widgets desde qtile_extras para que las decoraciones (capsulas) rendericen
from qtile_extras import widget
from qtile_extras.widget.decorations import RectDecoration
from .colors import colors, bar_background, capsule_background, separator_color

# ==============================================================================
#  FUENTES  (replicando el estilo de los dotfiles de mmsaeed509 / imagen 2)
# ==============================================================================
FONT_TEXT = "Ubuntu Medium"
FONT_ICON = "UbuntuMono Nerd Font"
FONT_WS = "JetBrainsMono Nerd Font"

# ==============================================================================
#  COLORES DE LA BARRA
# ==============================================================================
bar_bg     = bar_background       # barra (fondo continuo)
capsule_bg = capsule_background   # capsulas (resaltan sobre la barra)
sep_color  = separator_color      # (ya no se usan separadores, pero se deja importado)

vpn_green  = colors[4]   # verde de la paleta para la VPN

# ==============================================================================
#  DECORACION DE CAPSULA
# ==============================================================================
# group=True hace que los widgets contiguos con la MISMA decoracion compartan
# una sola capsula. Como ahora metemos Spacers SIN decoracion entre cada modulo,
# cada par icono+dato forma su propia capsula individual (estilo referencia).
def capsule(radius=10):
    return [
        RectDecoration(
            colour=capsule_bg,
            radius=radius,
            filled=True,
            padding_y=4,
            group=True,
        )
    ]

# Espacio entre capsulas individuales
GAP = 6

# ==============================================================================
#  FUNCIONES
# ==============================================================================
def get_ip(interface):
    try:
        cmd = f"ip -4 -o addr show dev {interface} | awk '{{print $4}}' | cut -d/ -f1"
        ip = subprocess.check_output(cmd, shell=True).decode().strip()
        return ip if ip else "..."
    except:
        return "N/A"

def get_target():
    try:
        if os.path.exists("/tmp/target"):
            with open("/tmp/target", "r") as f:
                target = f.read().strip()
                return target if target else "No Target"
        else:
            return "No Target"
    except:
        return "Error"

# ==============================================================================
#  DEFAULTS
# ==============================================================================
widget_defaults = dict(
    font=FONT_TEXT,
    fontsize=14,
    padding=3,
)
extension_defaults = widget_defaults.copy()

CAP_PAD = 8
FS_TEXT = 14
FS_ICON = 16
FS_WS = 13

# ==============================================================================
#  BARRA
# ==============================================================================
screens = [
    Screen(
        top=bar.Bar(
            [
                # ================= LADO IZQUIERDO =================

                # -- Capsula: Logo --
                widget.TextBox(
                    text="  ",
                    font=FONT_ICON,
                    foreground=colors[6],
                    fontsize=18,
                    padding=CAP_PAD,
                    decorations=capsule(),
                ),
                widget.Spacer(length=GAP),

                # -- Capsula: IP local --
                widget.TextBox(
                    text="\U000f0200",
                    font=FONT_ICON,
                    foreground=colors[6],
                    fontsize=FS_ICON,
                    padding=4,
                    decorations=capsule(),
                ),
                widget.GenPollText(
                    func=lambda: get_ip("eth0"),
                    update_interval=5,
                    font=FONT_TEXT,
                    fontsize=FS_TEXT,
                    foreground=colors[1],
                    padding=6,
                    decorations=capsule(),
                ),
                widget.Spacer(length=GAP),

                # -- Capsula: VPN --
                widget.TextBox(
                    text="󰆧",
                    font=FONT_ICON,
                    foreground=vpn_green,
                    fontsize=FS_ICON,
                    padding=4,
                    decorations=capsule(),
                ),
                widget.GenPollText(
                    func=lambda: get_ip("tun0"),
                    update_interval=5,
                    font=FONT_TEXT,
                    fontsize=FS_TEXT,
                    foreground=vpn_green,
                    padding=6,
                    decorations=capsule(),
                ),

                # ================= CENTRO: Workspaces =================
                widget.Spacer(),
                widget.GroupBox(
                    font=FONT_WS,
                    fontsize=FS_WS,
                    highlight_method='text',
                    # Workspace ACTUAL (donde estas ahora): magenta
                    this_current_screen_border=colors[7],
                    # Workspaces OCUPADOS (con ventanas) pero no actuales: azul
                    active=colors[6],
                    # Workspaces VACIOS: gris tenue
                    inactive="#565f89",
                    # Workspace con ventana URGENTE: rojo
                    urgent_border=colors[3],
                    padding_x=6,
                    padding_y=4,
                    decorations=capsule(),
                ),
                widget.Spacer(),

                # ================= LADO DERECHO =================

                # -- Capsula: CPU --
                widget.TextBox(
                    text="󰍛",
                    font=FONT_ICON,
                    foreground=colors[8],
                    fontsize=FS_ICON,
                    padding=4,
                    decorations=capsule(),
                ),
                widget.CPU(
                    format='{load_percent}%',
                    font=FONT_TEXT,
                    fontsize=FS_TEXT,
                    foreground=colors[8],
                    padding=6,
                    decorations=capsule(),
                ),
                widget.Spacer(length=GAP),

                # -- Capsula: RAM --
                widget.TextBox(
                    text="󰘚",
                    font=FONT_ICON,
                    foreground=colors[7],
                    fontsize=FS_ICON,
                    padding=4,
                    decorations=capsule(),
                ),
                widget.Memory(
                    format='{MemUsed: .0f}M',
                    measure_mem='M',
                    font=FONT_TEXT,
                    fontsize=FS_TEXT,
                    foreground=colors[7],
                    padding=6,
                    decorations=capsule(),
                ),
                widget.Spacer(length=GAP),

                # -- Capsula: Target --
                widget.TextBox(
                    text="\U000f05ff",
                    font=FONT_ICON,
                    foreground=colors[3],
                    fontsize=FS_ICON,
                    padding=4,
                    decorations=capsule(),
                ),
                widget.GenPollText(
                    func=get_target,
                    update_interval=2,
                    font=FONT_TEXT,
                    fontsize=FS_TEXT,
                    foreground=colors[3],
                    padding=6,
                    decorations=capsule(),
                ),
                widget.Spacer(length=GAP),

                # -- Capsula: Reloj --
                widget.TextBox(
                    text="\U000f00ed",
                    font=FONT_ICON,
                    foreground=colors[9],
                    fontsize=FS_ICON,
                    padding=4,
                    decorations=capsule(),
                ),
                widget.Clock(
                    format="%d/%m %H:%M",
                    font=FONT_TEXT,
                    fontsize=FS_TEXT,
                    foreground=colors[9],
                    padding=6,
                    decorations=capsule(),
                ),
                widget.Spacer(length=GAP),

                # -- Capsula: Exit --
                widget.QuickExit(
                    default_text='\U000f0425',
                    font=FONT_ICON,
                    fontsize=FS_ICON,
                    countdown_format='{}',
                    foreground=colors[3],
                    padding=CAP_PAD,
                    decorations=capsule(),
                ),
            ],
            30,
            background=bar_bg,
            margin=[6, 8, 4, 8],   # [arriba, der, abajo, izq] - barra flotante con gaps
        ),
    ),
]
