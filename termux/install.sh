#!/bin/bash
set -e

die() {
    echo "$*"
    exit 1
}

confirm() {
    local answer
    read answer
    [[ $answer =~ ^[Yy] ]] || [[ -z $answer ]]
}

### parsing args
for arg in "$@"; do
    case $arg in
        --wine) wine=true;;
        *) die "Usage: ./install.sh [--wine]";;
    esac
done

### ensure we are in termux
[[ -n $TERMUX_VERSION ]] || die "this script should be run only on termux."

### this script can be run in different cwd
cd "$(dirname "$0")"

### promote termux-pacman
if ! command -v pacman >/dev/null; then
    echo "Hello. Do you want to switch to pacman?"
    echo "It is much faster than apt, and has the same termux repos."
    echo -n "Install termux-pacman now? [Y/n] "
    if confirm; then
        echo
        exec ./switch-to-pacman.sh
        die "could not exec"
    fi
    echo
fi

### the warning
echo "This installer is going to !overwrite! your dotfiles,"
echo "so please make backups if you have something important."
echo "To check what is being overwritten, please examine this script."
echo -n "Continue? [Y/n] "
confirm || exit
echo

### installation
cp -v bashrc ~/.bashrc

mkdir -pv ~/.config/htop
cp -v htoprc ~/.config/htop/

mkdir -pv ~/.termux
cp -v dark-tea.properties ~/.termux/colors.properties
cp -v mononoki-nerd.ttf ~/.termux/font.ttf
ln -sf $PREFIX/etc/motd.sh ~/.termux/motd.sh
cp -v termux.properties ~/.termux/termux.properties
if [[ $wine = true ]]; then
    mkdir -pv ~/.local/bin
    cp -av winebin/* ~/.local/bin
fi

termux-reload-settings

### additional packages
pkgs="bash-completion eza htop neofetch miniserve"
echo
echo "Would you like to install additional packages used in these dotfiles?"
echo "Those are not hard dependency, but are referenced in these dotfiles."
echo
echo "Package list: $pkgs"
echo
echo -n "Continue with installation? [Y/n] "
if confirm; then
    pkg in $pkgs
fi
echo

echo "All done. Please restart termux to reload settings."
