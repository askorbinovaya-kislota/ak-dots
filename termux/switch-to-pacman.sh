#!/data/data/com.termux/files/usr/bin/bash
set -eo pipefail

### functions
# https://gist.github.com/lukechilds/a83e1d7127b78fef38c2914c4ececc3c
get-latest-release() {
    curl --silent "https://api.github.com/repos/$1/releases/latest" |
    grep '"tag_name":' |
    sed -E 's/.*"([^"]+)".*/\1/'
}

arch() {
    local arch
    case "$(uname -m)" in
        armv7l|armv8l) arch="arm";;
        aarch64) arch="aarch64";;
        i686) arch="i686";;
        x86_64) arch="x86_64";;
        *) die "architecture not supported: $(uname -m)";;
    esac
    echo "$arch"
}

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

### step 1: getting the url
REPO="termux-pacman/termux-packages"
RELEASE="$(get-latest-release $REPO)" || die "could not get latest release"
BOOTSTRAP="bootstrap-$(arch).zip"
URL="https://github.com/$REPO/releases/download/$RELEASE/$BOOTSTRAP"

### start inside usr-n
mkdir "usr-n"
cd "usr-n"

### step 2: downloading
echo
echo "Downloading latest termux-pacman bootstrap..."
curl -L -o "$BOOTSTRAP" "$URL"

### step 3: unpacking
echo "Extracting $BOOTSTRAP..."
unzip -q "$BOOTSTRAP"
rm "$BOOTSTRAP"

### step 4: restoring symlinks
echo "Restoring symlinks (it may take a while)..."
while IFS=← read -a arr; do
    # zip supports symlinks, why is this thing used???
    ln -s "${arr[0]}" "${arr[1]}"
done <SYMLINKS.txt
rm "SYMLINKS.txt"

### step 5: replacing prefix
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
