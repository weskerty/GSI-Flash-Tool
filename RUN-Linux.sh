#!/bin/bash

cd "$(dirname "$0")" || exit 1

G="\e[32m"
R="\e[31m"
Y="\e[33m"
N="\e[0m"

ok() {
    echo -e "${G}[OK]${N} $1"
}

er() {
    echo -e "${R}[ERROR]${N} $1"
}

inf() {
    echo -e "${Y}[INFO]${N} $1"
}

chk() {
    command -v "$1" >/dev/null 2>&1
}


M=0

if chk git; then
    ok "git ok"
else
    er "git off"
    M=1
fi

if chk fastboot; then
    ok "fastboot ok"
else
    er "fastboot off"
    M=1
fi

if [ "$M" -eq 1 ]; then
    inf "Instalando dependencias..."

    if chk pacman; then
        inf "Arch Based"
        sudo pacman -Syu git android-tools android-udev --needed --noconfirm

    elif chk apt-get; then
        inf "Debian Based"
        sudo apt-get update
        sudo apt-get install git android-sdk-platform-tools -y

    else
        er "Sistem off"
        exit 1
    fi
fi

# === Verify ===

chk git && ok "git ok" || {
    er "git fallo"
    exit 1
}

chk fastboot && ok "fastboot ok" || {
    er "fastboot fallo"
    exit 1
}

# === Update ===

git fetch origin

L=$(git rev-parse HEAD)
R1=$(git rev-parse origin/main)

[ "$L" != "$R1" ] && git reset --hard origin/main


chmod -R +x bin
chmod -R +x scripts

bash scripts/installer.sh