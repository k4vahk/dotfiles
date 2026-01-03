# modules/layouts.py
from libqtile import layout
from libqtile.config import Match

layout_theme = {
    "border_width": 2,
    "margin": 8,
    "border_focus": "#51afef",
    "border_normal": "#1c1f24"
}

layouts = [
    layout.MonadTall(**layout_theme),
    layout.Max(),
    layout.Floating(**layout_theme),
]

floating_layout = layout.Floating(
    float_rules=[
        *layout.Floating.default_float_rules,
        Match(wm_class="confirmreset"),  # gitk
        Match(wm_class="makebranch"),  # gitk
        Match(wm_class="ssh-askpass"),  # ssh-askpass
    ]
)
