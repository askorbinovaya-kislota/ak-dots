#!/data/data/com.termux/files/usr/bin/bash
set -eo pipefail

### functions
die() {
    echo "$@"
    exit 1
}

confirm() {
    if [[ $quiet = true ]]; then
        return 0;
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
        -q|--quiet) quiet=true;; # non-interactive mode
        *) die "Usage: ./switch-to-pacman.sh [-q]";;
    esac
done

### sanity checks
[[ -n $PREFIX ]] || die "prefix not set, is it termux?"
cd "$PREFIX/.."
if [[ -d "usr.bak" ]]; then
    die "prefix backup (usr.bak) exists. please examine it, rename it to something or wipe it"
elif [[ -d "usr-n" ]]; then
    die "destination directory (usr-n) exists. cd ..; rm -r usr-n"
fi

### the warning
print
print "welcome to termux-pacman installer (switch-to-pacman.sh)"
print "this script will reinstall termux, so you are going to lose:"
print "- all installed packages"
print "- all proot-distro installations"
print "- all files stored in usr ($PREFIX)"
print "however, your home directory is kept intact, and"
print "contents of your old usr will be saved in usr.bak"
print
print "more info: https://wiki.termux.com/wiki/Switching_package_manager"
print
print -n "continue? [Y/n] "
confirm || exit

### step 1: get arch
arch="$(uname -m)"
case "$arch" in
    armv7l|armv8l) arch="arm";;
    aarch64|i686|x86_64) ;;
    *) die "architecture not supported: $arch";;
esac

### start inside usr-n
mkdir "usr-n"
cd "usr-n"

### step 2: download
echo
echo "Downloading latest termux-pacman bootstrap..."
curl -LO "https://github.com/termux-pacman/termux-packages/releases/latest/download/bootstrap-$arch.zip"

### step 3: unpack
echo "Extracting bootstrap-$arch.zip..."
unzip -q "bootstrap-$arch.zip"
rm "bootstrap-$arch.zip"

### step 4: restore symlinks
echo "Restoring symlinks (it may take a while)..."
while IFS=← read -a arr; do
    # zip supports symlinks, why is this thing used???
    ln -s "${arr[0]}" "${arr[1]}"
done <SYMLINKS.txt
rm "SYMLINKS.txt"

### step 5: replace prefix
cd ..
PATH=/system/bin
mv -v "usr" "usr.bak"
mv -v "usr-n" "usr"

### step 6: remove old prefix (optional)
print
print "Done! Do you want to wipe your prefix backup? If you do, you won't"
print "be able to restore your old prefix, and will lose all information"
print "from it."
print -n "Destroy usr.bak? [Y/n] "

if confirm; then
    rm -rf "usr.bak"
fi

print
print -n "You should restart termux now. Close all sessions? [Y/n] "
if confirm; then
    /data/data/com.termux/files/usr/bin/am \
        stopservice com.termux/.app.TermuxService >/dev/null
fi
