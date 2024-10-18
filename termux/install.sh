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
if [[ $TERMUX_MAIN_PACKAGE_FORMAT != pacman ]]; then
    echo "Hello. Do you want to switch to pacman?"
    echo "It is much faster than apt, and I'd suggest it if you are"
    echo "more familiar with archlinux than with debian."
    echo -n "Install termux-pacman now? [Y/n] "
    if confirm; then
        echo
        exec ./switch-to-pacman.sh
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
cp -v $PREFIX/etc/motd.sh ~/.termux/motd.sh
cp -v termux.properties ~/.termux/termux.properties
if [[ $wine = true ]]; then
    mkdir -pv ~/.local/bin
    cp -av winebin/* ~/.local/bin
fi
echo

### additional packages
pkgs="eza htop neofetch miniserve"
echo "Would you like to install additional packages used in these dotfiles?"
echo "Those are not hard dependency, are tiny and useful, and i'd suggest to"
echo "install at least eza."
echo
echo "Package list: $pkgs"
echo
echo -n "Continue with installation? [Y/n] "
if confirm; then
    pkg in $pkgs
fi
echo

echo "All done. Please restart termux to reload settings."
