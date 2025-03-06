#!/bin/bash
set -e

die() {
    echo "$@"
    exit 1
}

confirm() {
    if [[ $quiet = true ]]; then
        return 0
    fi

    local answer
    read answer
    [[ $answer =~ ^[Yy] ]] || [[ -z $answer ]]
}

print() {
    if [[ $quiet != true ]]; then
        echo "$@"
    fi
}

### parsing args
for arg in "$@"; do
    case $arg in
        --wine) wine=true;; # adds wine wrappers to .local/bin
        -q|--quiet) quiet=true;; # non-interactive mode
        *) die "Usage: ./install.sh [-q] [--wine]";;
    esac
done

### ensure we are in termux
[[ -n $TERMUX_VERSION ]] || die "this script should be run only on termux."

### this script can be run in different cwd
cd "$(dirname "$0")"

### promote termux-pacman
if [[ $quiet != true ]] && ! command -v pacman >/dev/null; then
    print
    print "Hello. Do you want to switch to pacman?"
    print "It is much faster than apt, and has the same termux repos."
    print -n "Install termux-pacman now? [Y/n] "
    if confirm; then
        exec ./switch-to-pacman.sh
    fi
    print
fi

### the warning
print
print "This installer is going to !overwrite! your dotfiles,"
print "so please make backups if you have something important."
print "To check what is being overwritten, please examine this script."
print -n "Continue? [Y/n] "
confirm || exit
print

### installation
cp -v bashrc ~/.bashrc

mkdir -pv ~/.config/htop
cp -v htoprc ~/.config/htop/
mkdir -pv ~/.config/fastfetch
cp -v fastfetch.jsonc ~/.config/fastfetch/config.jsonc
mkdir -pv ~/.config/python
cp -v startup.py ~/.config/python/startup.py
mkdir -pv ~/.config/nano
cp -v nanorc ~/.config/nano/nanorc

mkdir -pv ~/.termux
cp -v dark-tea-lighter.properties ~/.termux/colors.properties
cp -v mononoki-nerd.ttf ~/.termux/font.ttf
ln -sf $PREFIX/etc/motd.sh ~/.termux/motd.sh
cp -v termux.properties ~/.termux/termux.properties

mkdir -pv ~/.local/bin
cp -v py ~/.local/bin/py
cp -v hex ~/.local/bin/hex

if [[ $wine = true ]]; then
    cp -av winebin/* ~/.local/bin
fi

termux-reload-settings

### additional packages
pkgs="eza htop fastfetch miniserve xxd bat gitoxide wget file p7zip 7zip"
print
print "Would you like to install additional packages used in these dotfiles?"
print "Those are not hard dependency, but are referenced in these dotfiles."
print
print "Package list: $pkgs"
print
print -n "Continue with installation? [Y/n] "
if confirm; then
    pkg in $pkgs
fi
print

echo "All done. Please restart termux to reload settings."
