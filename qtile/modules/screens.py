import subprocess
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

# Flecha DERECHA (Lado Izquierdo) >>
def right_arrow(bg_color, fg_color):
    return widget.TextBox(
        text='\uE0B0',
        padding=0,
        fontsize=24,
        background=bg_color,
        foreground=fg_color,
    )

# Flecha IZQUIERDA (Lado Derecho) <<
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
                # === LADO IZQUIERDO ===
                
                # 1. BLOQUE ARCH (Azul)
                widget.TextBox(
                    text="  ",
                    background=colors[6],
                    foreground=colors[0],
                    padding=5,
                    fontsize=18
                ),
                right_arrow(secondary_bg, colors[6]),

                # 2. BLOQUE IP LOCAL (Gris Medio)
                widget.TextBox(
                    text=" 󰈀 ", 
                    background=secondary_bg,
                    foreground=colors[6],
                    padding=5
                ),
                widget.GenPollText(
                    func=lambda: get_ip("enp0s3"), # <--- Revisa tu interfaz
                    update_interval=5,
                    background=secondary_bg,
                    foreground="#ffffff",
                    padding=5
                ),
                right_arrow(colors[0], secondary_bg),

                # 3. WORKSPACES
                widget.GroupBox(
                    highlight_method='line',
                    highlight_color=[colors[0], colors[1]],
                    this_current_screen_border=colors[6],
                    inactive=colors[1],
                    background=colors[0],
                    padding_x=5
                ),
                
                # --- AQUÍ QUITAMOS EL WindowName ---
                # Antes había: widget.WindowName(), lo hemos borrado.

                # === ESPACIO CENTRAL ===
                widget.Spacer(), 

                # === LADO DERECHO (Nuevos Widgets) ===

                # 1. INTERNET (Velocidad) - Fondo Gris Claro (Colors[2])
                left_arrow(colors[0], colors[2]),
                widget.TextBox(
                    text=" ",
                    background=colors[2],
                    foreground=colors[0],
                    padding=2
                ),
                widget.Net(
                    interface="enp0s3", # <--- Revisa tu interfaz
                    format='{down}↓↑{up}',
                    background=colors[2],
                    foreground=colors[0],
                    padding=5
                ),

                # 2. CPU - Fondo Cian (Colors[8])
                left_arrow(colors[2], colors[8]),
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

                # 3. RAM - Fondo Magenta (Colors[7])
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

                # 4. VPN (HackTheBox) - Fondo Verde (Colors[4])
                left_arrow(colors[7], colors[4]),
                widget.TextBox(
                    text=" ",
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

                # 5. RELOJ - Fondo Naranja (Colors[5])
                left_arrow(colors[4], colors[5]),
                widget.Clock(
                    format="%d/%m %H:%M",
                    background=colors[5],
                    foreground=colors[0],
                    padding=10
                ),

                # 6. SALIDA - Fondo Rojo (Colors[3])
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
