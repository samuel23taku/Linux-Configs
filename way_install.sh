pacman -Syyu base-devel hyprland waybar hyprpaper snapd wofi neovim fish git obsidian firefox terminator neofetch libreoffice-still cmake net-tools man-pages man-db --noconfirm

#Service enable
systemctl enable --now snapd.socket


# Desktop setup
mv waybar ~/.config/
mv hypr  ~/.config/
mv mako ~/.config/
mv wofi ~/.config/


# Editor setup
git clone https://github.com/samuel23taku/Neovim-Setup.git ~/.config/nvim

snap install code --classic
snap install spotify

git clone https://aur.archlinux.org/yay-git.git
cd yay
makepkg -si
cd ..


yay -S --noconfirm --answerdiff=N --answerclean=N google-chrome wlogout


