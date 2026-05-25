#!/bin/bash

G="\e[32m"; R="\e[31m"; Y="\e[33m"; N="\e[0m"
ok(){ echo -e "${G}[OK]${N} $1"; }
er(){ echo -e "${R}[ERROR]${N} $1"; }
inf(){ echo -e "${Y}[INFO]${N} $1"; }

chk(){ command -v "$1" >/dev/null 2>&1; }

detect_env(){
    IS_TERMUX=0; DISTRO=""
    [[ -n "$TERMUX_VERSION" || "$PREFIX" == *termux* ]] && { IS_TERMUX=1; return; }
    [ -f /etc/os-release ] && . /etc/os-release
    case "$ID" in
        arch|manjaro) DISTRO="arch" ;;
        debian|ubuntu|linuxmint|pop) DISTRO="debian" ;;
        *) [ -n "$ID_LIKE" ] && case "$ID_LIKE" in
            *arch*) DISTRO="arch" ;;
            *debian*|*ubuntu*) DISTRO="debian" ;;
        esac ;;
    esac
}

need(){
    for x in "$@"; do
        chk "$x" || return 0
    done
    return 1
}

install_deps(){
    if [ "$IS_TERMUX" -eq 1 ]; then
        need curl git fastboot 7z || {
            ok "deps already installed"
            return
        }

        inf "Installing deps (Termux)..."
        termux-wake-lock 2>/dev/null || true
        apt-get update
        pkg install -y tur-repo x11-repo
        apt-get update
        apt update -y && yes | apt upgrade
        pkg install -y curl git termux-adb 7zip || pkg install -y p7zip
        return
    fi

    case "$DISTRO" in
        arch)
            need curl git fastboot 7z || {
                ok "deps already installed"
                return
            }

            inf "Installing deps (Arch)..."
            pacman -Syy
            pacman -S --noconfirm --needed curl git p7zip android-tools android-udev || true
            ;;
        debian)
            need curl git fastboot 7z || {
                ok "deps already installed"
                return
            }

            inf "Installing deps..."
            apt-get update
            apt-get install -y curl git p7zip-full android-tools-fastboot android-sdk-libsparse-utils || true
            ;;
        *)
            inf "Unknown distro - skipping dep install"
            ;;
    esac
}

dep(){
    chk git || { er "git not found"; exit 1; }
    chk fastboot || exit 1
}

run_local(){
    dep

    git rev-parse --is-inside-work-tree >/dev/null 2>&1 && {
        git fetch origin
        L=$(git rev-parse HEAD)
        R=$(git rev-parse origin/main)
        [ "$L" != "$R" ] && git reset --hard origin/main
    }

    chmod -R +x bin scripts 2>/dev/null
    bash scripts/installer.sh
}

boot(){
    D="${1:-$HOME/GSI-Flash-Tool}"

    [ -d "$D/.git" ] && {
        inf "repo exists"
        cd "$D" || exit 1
        run_local
        return
    }

    [ -e "$D" ] && [ ! -d "$D" ] && { er "path invalid"; exit 1; }

    chk git || { er "git not found"; exit 1; }

    inf "cloning"
    git clone https://github.com/weskerty/GSI-Flash-Tool.git --depth 1 --single-branch "$D" || exit 1

    cd "$D" || exit 1

    [ -f scripts/installer.sh ] || { er "missing entry"; exit 1; }

    run_local
}

detect_env
install_deps

if [ -d .git ]; then
    run_local
else
    boot "$@"
fi