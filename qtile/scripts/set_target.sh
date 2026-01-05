#!/bin/bash

# Lanza rofi para pedir la IP
# -p "Target" pone el texto de ayuda
target=$(rofi -dmenu -p "󰓾 Target IP" -theme-str 'window {width: 20%;}')

# Si el usuario escribió algo (no está vacío)
if [ -n "$target" ]; then
    echo "$target" > /tmp/target
else
    # Si escapas o lo dejas vacío, limpia el target
    echo "No Target" > /tmp/target
fi
