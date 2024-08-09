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
    echo "ERROR: $*"
    exit 1
}

confirm() {
    local answer
    read answer
    [[ $answer =~ ^[Yy] ]] || [[ -z $answer ]]
}

### sanity checks
[[ -n $PREFIX ]] || die "prefix not set, is it termux?"
cd "$PREFIX/.."
if [[ -d "usr.bak" ]]; then
    die "prefix backup exists. please examine it, rename it to something or wipe it"
elif [[ -d "usr-n" ]]; then
    die "destination directory (usr-n) exists. cd ..; rm -r usr-n"
fi

### the warning
echo "welcome to termux-pacman installer (switch-to-pacman.sh)"
echo "this script will reinstall termux, so you are going to lose:"
echo "- all installed packages"
echo "- all proot-distro installations"
echo "- all files stored in usr ($PREFIX)"
echo "however, your home directory is kept intact"
echo "contents of your old usr will be saved in usr.bak"
echo -n "continue? [Y/n] "
confirm || exit
echo

### step 1: getting the url
REPO="termux-pacman/termux-packages"
RELEASE="$(get-latest-release $REPO)" || die "could not get latest release"
BOOTSTRAP="bootstrap-$(arch).zip"
URL="https://github.com/$REPO/releases/download/$RELEASE/$BOOTSTRAP"

### start inside usr-n
mkdir "usr-n"
cd "usr-n"

### step 2: downloading
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
echo
echo "Done! Do you want to wipe your prefix backup? If you do, you won't"
echo "be able to restore your old prefix, and will lose all information"
echo "from it. (which exactly: already printed in the beginning)"
echo -n "Destroy usr.bak? [Y/n] "

if confirm; then
    rm -rf "usr.bak"
fi
echo

echo -n "You should restart termux now. Close all sessions? [Y/n] "
if confirm; then
    /data/data/com.termux/files/usr/bin/am \
        stopservice com.termux/.app.TermuxService >/dev/null
fi
