```bash
# Eliminar gnome y sus dependencias
sudo apt purge --autoremove -y gnome-core gdm3 task-gnome-desktop

# Asegurar que no quede basura
sudo apt autoremove -y

# Forma correcta de Actualizar Kali
sudo apt update
sudo apt full-upgrade -y
sudo apt autoremove --purge -y
sudo apt autoclean

```
