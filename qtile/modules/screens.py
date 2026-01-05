import subprocess
import os
from libqtile import bar, widget
from libqtile.config import Screen
from .colors import colors

# Definimos un color gris medio para el bloque de la IP
secondary_bg = "#373b41" 

# --- FUNCIONES ---

def get_ip(interface):
    try:
        cmd = f"ip -4 -o addr show dev {interface} | awk '{{print $4}}' | cut -d/ -f1"
        ip = subprocess.check_output(cmd, shell=True).decode().strip()
        return ip if ip else "..."
    except:
        return "N/A"

def get_target():
    try:
        # Lee el archivo /tmp/target para mostrar el objetivo
        if os.path.exists("/tmp/target"):
            with open("/tmp/target", "r") as f:
                target = f.read().strip()
                return target if target else "No Target"
        else:
            return "No Target"
    except:
        return "Error"

# Flecha DERECHA (Para el lado izquierdo de la barra) >>
# Lógica: Foreground = Color del widget ACTUAL. Background = Color del widget SIGUIENTE.
def right_arrow(bg_color, fg_color):
    return widget.TextBox(
        text='\uE0B0',
        padding=0,
        fontsize=24,
        background=bg_color,
        foreground=fg_color,
    )

# Flecha IZQUIERDA (Para el lado derecho de la barra) <<
# Lógica: Foreground = Color del widget SIGUIENTE. Background = Color del widget ANTERIOR.
def left_arrow(bg_color, fg_color):
    return widget.TextBox(
        text='\uE0B2',
        padding=0,
        fontsize=24,
        background=bg_color,
        foreground=fg_color,
    )

widget_defaults = dict(
    font="JetBrainsMono Nerd Font",
    fontsize=14,
    padding=3,
)
extension_defaults = widget_defaults.copy()

screens = [
    Screen(
        top=bar.Bar(
            [
                # ============================================
                #               LADO IZQUIERDO
                # ============================================
                
                # 1. LOGO ARCH (Fondo: AZUL colors[6])
                widget.TextBox(
                    text="  ",
                    background=colors[6],
                    foreground=colors[0],
                    padding=5,
                    fontsize=18
                ),
                
                # Transición: Azul -> Gris (IP)
                right_arrow(secondary_bg, colors[6]),

                # 2. IP LOCAL (Fondo: GRIS secondary_bg)
                widget.TextBox(
                    text=" 󰈀 ", 
                    background=secondary_bg,
                    foreground=colors[6],
                    padding=5
                ),
                widget.GenPollText(
                    func=lambda: get_ip("enp0s3"), # <--- ¡REVISA TU INTERFAZ! (ej. eth0, wlan0)
                    update_interval=5,
                    background=secondary_bg,
                    foreground="#ffffff",
                    padding=5
                ),

                # Transición: Gris -> Verde (VPN)
                right_arrow(colors[4], secondary_bg),

                # 3. VPN (Fondo: VERDE colors[4])
                widget.TextBox(
                    text="  ",
                    background=colors[4],
                    foreground=colors[0],
                    padding=5
                ),
                widget.GenPollText(
                    func=lambda: get_ip("tun0"),
                    update_interval=5,
                    background=colors[4],
                    foreground=colors[0],
                ),

                # Transición: Verde -> Negro (Workspaces)
                right_arrow(colors[0], colors[4]),

                # 4. WORKSPACES (Fondo: NEGRO colors[0])
                widget.GroupBox(
                    highlight_method='line',
                    highlight_color=[colors[0], colors[1]],
                    this_current_screen_border=colors[6],
                    inactive=colors[1],
                    background=colors[0],
                    padding_x=5
                ),
                
                # ============================================
                #               ESPACIO CENTRAL
                # ============================================
                widget.Spacer(), 

                # ============================================
                #               LADO DERECHO
                # ============================================

                # 1. CPU (Fondo: CIAN colors[8])
                # Flecha comienza desde el fondo negro (0) hacia Cian (8)
                left_arrow(colors[0], colors[8]),
                widget.TextBox(
                    text=" ",
                    background=colors[8],
                    foreground=colors[0],
                    padding=2
                ),
                widget.CPU(
                    format='{load_percent}%',
                    background=colors[8],
                    foreground=colors[0],
                    padding=5
                ),

                # 2. RAM (Fondo: MAGENTA colors[7])
                # Transición: Cian -> Magenta
                left_arrow(colors[8], colors[7]),
                widget.TextBox(
                    text=" ",
                    background=colors[7],
                    foreground=colors[0],
                    padding=2
                ),
                widget.Memory(
                    format='{MemUsed: .0f}M',
                    measure_mem='M',
                    background=colors[7],
                    foreground=colors[0],
                    padding=5
                ),

                # 3. TARGET / OBJETIVO (Fondo: ROJO colors[3])
                # Transición: Magenta -> Rojo
                left_arrow(colors[7], colors[3]),
                widget.TextBox(
                    text="什 ", 
                    background=colors[3],
                    foreground=colors[0],
                    padding=2
                ),
                widget.GenPollText(
                    func=get_target,
                    update_interval=2,
                    background=colors[3],
                    foreground=colors[0],
                    padding=5
                ),

                # 4. RELOJ (Fondo: NARANJA colors[5])
                # Transición: Rojo -> Naranja
                left_arrow(colors[3], colors[5]),
                widget.Clock(
                    format="%d/%m %H:%M",
                    background=colors[5],
                    foreground=colors[0],
                    padding=10
                ),

                # 5. SALIDA (Fondo: ROJO colors[3])
                # Transición: Naranja -> Rojo
                left_arrow(colors[5], colors[3]),
                widget.QuickExit(
                    default_text='  ',
                    countdown_format=' {} ',
                    background=colors[3],
                    foreground=colors[0],
                ),
            ],
            26,
            background=colors[0],
        ),
    ),
]
