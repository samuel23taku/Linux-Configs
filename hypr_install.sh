#!/bin/bash

# Run the entire script with sudo once
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script with sudo"
  exit 1
fi

# Save the real username
REAL_USER=$(logname)
REAL_HOME="/home/$REAL_USER"

echo "Installing Hyprland environment for user: $REAL_USER"

# Update system and install packages
echo "Updating system and installing packages..."
pacman -Syyu base-devel hyprland waybar hyprpaper wofi neovim fish git obsidian firefox \
terminator neofetch libreoffice-still cmake net-tools man-pages man-db swaylock \
wl-clipboard mako xdg-desktop-portal-hyprland --noconfirm

# Handle snapd installation
echo "Setting up Snap..."
pacman -S snapd --noconfirm
systemctl enable --now snapd.socket
systemctl enable --now snapd.apparmor

# Create necessary directories first (prevents move failures)
echo "Creating configuration directories..."
mkdir -p $REAL_HOME/.config/{waybar,hypr,mako,wofi}
chown -R $REAL_USER:$REAL_USER $REAL_HOME/.config

# Copy config files from current directory if they exist
echo "Setting up configuration files..."
if [ -d "./waybar" ]; then
  cp -r ./waybar/* $REAL_HOME/.config/waybar/
  chown -R $REAL_USER:$REAL_USER $REAL_HOME/.config/waybar
fi

if [ -d "./hypr" ]; then
  cp -r ./hypr/* $REAL_HOME/.config/hypr/
  chown -R $REAL_USER:$REAL_USER $REAL_HOME/.config/hypr
fi

if [ -d "./mako" ]; then
  cp -r ./mako/* $REAL_HOME/.config/mako/
  chown -R $REAL_USER:$REAL_USER $REAL_HOME/.config/mako
fi

if [ -d "./wofi" ]; then
  cp -r ./wofi/* $REAL_HOME/.config/wofi/
  chown -R $REAL_USER:$REAL_USER $REAL_HOME/.config/wofi
fi

# Setup Neovim configuration - do this as the real user
echo "Setting up Neovim..."
sudo -u $REAL_USER git clone https://github.com/samuel23taku/Neovim-Setup.git $REAL_HOME/.config/nvim

# Setup wlogout
echo "Setting up wlogout..."
if [ ! -f "/usr/bin/wlogout" ]; then
  # Install wlogout dependencies
  pacman -S meson ninja wayland-protocols gtk3 scdoc --noconfirm
  
  # Clone and build as real user
  cd /tmp
  sudo -u $REAL_USER git clone https://github.com/ArtsyMacaw/wlogout.git
  cd wlogout
  sudo -u $REAL_USER meson build
  sudo -u $REAL_USER ninja -C build
  ninja -C build install
  
  # Create config directory
  mkdir -p $REAL_HOME/.config/wlogout
  chown $REAL_USER:$REAL_USER $REAL_HOME/.config/wlogout
fi

# Install yay as real user
echo "Installing yay and AUR packages..."
cd /tmp
sudo -u $REAL_USER git clone https://aur.archlinux.org/yay-git.git
cd yay-git
sudo -u $REAL_USER makepkg -si --noconfirm
cd ..

# Install AUR packages as real user
sudo -u $REAL_USER yay -S --noconfirm --answerdiff=N --answerclean=N google-chrome

# Install snap packages
echo "Installing Snap packages..."
sudo -u $REAL_USER snap wait system seed.loaded
sudo -u $REAL_USER snap install code --classic
sudo -u $REAL_USER snap install spotify

# Create power menu script
echo "Creating power menu script..."
POWER_MENU="$REAL_HOME/.local/bin/power-menu.sh"
mkdir -p $REAL_HOME/.local/bin
chown $REAL_USER:$REAL_USER $REAL_HOME/.local/bin

cat > $POWER_MENU << 'EOL'
#!/bin/bash

# Power menu options
options="Lock screen
Logout
Suspend
Hibernate
Reboot
Shutdown"

# Show menu and get selection
selected=$(echo -e "$options" | wofi --dmenu --insensitive --prompt "Power Menu" --width 250 --height 260)

# Execute the selected option
case $selected in
    "Lock screen")
        swaylock
        ;;
    "Logout")
        hyprctl dispatch exit
        ;;
    "Suspend")
        systemctl suspend
        ;;
    "Hibernate")
        systemctl hibernate
        ;;
    "Reboot")
        systemctl reboot
        ;;
    "Shutdown")
        systemctl poweroff
        ;;
    *)
        echo "No option selected"
        ;;
esac
EOL

chmod +x $POWER_MENU
chown $REAL_USER:$REAL_USER $POWER_MENU

# Add power menu keybinding to Hyprland config if it doesn't exist
if [ -f "$REAL_HOME/.config/hypr/hyprland.conf" ]; then
  if ! grep -q "power-menu.sh" "$REAL_HOME/.config/hypr/hyprland.conf"; then
    echo '# Power menu keybinding' >> $REAL_HOME/.config/hypr/hyprland.conf
    echo 'bind = SUPER, escape, exec, ~/.local/bin/power-menu.sh' >> $REAL_HOME/.config/hypr/hyprland.conf
  fi
fi

# Final cleanup and permissions
chown -R $REAL_USER:$REAL_USER $REAL_HOME/.config
chown -R $REAL_USER:$REAL_USER $REAL_HOME/.local

echo "Hyprland installation completed! You can now reboot and select Hyprland from your display manager."
echo "Power menu is accessible with Super+Escape"
