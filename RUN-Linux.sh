#!/bin/bash

cd "$(dirname "$0")" 2>/dev/null || cd /tmp || exit 1

G="\e[32m"; R="\e[31m"; Y="\e[33m"; N="\e[0m"

ok(){ echo -e "${G}[OK]${N} $1"; }
er(){ echo -e "${R}[ERROR]${N} $1"; }
inf(){ echo -e "${Y}[INFO]${N} $1"; }

chk(){ command -v "$1" >/dev/null 2>&1; }

dep(){
  M=0
  chk git && ok "git" || { er "git"; M=1; }
  chk fastboot && ok "fastboot" || { er "fastboot"; M=1; }

  [ "$M" -eq 0 ] && return 0

  inf "install deps"

  if chk pacman; then
    sudo pacman -Syu git android-tools android-udev --noconfirm --needed
  elif chk apt-get; then
    sudo apt-get update
    sudo apt-get install -y git android-sdk-platform-tools
  else
    er "no pkg mgr"
    exit 1
  fi
}

boot(){
  D="${1:-$HOME/GSI-Flash-Tool}"
  inf "clone -> $D"
  git clone https://github.com/weskerty/GSI-Flash-Tool.git --depth 1 --single-branch "$D" || exit 1
  cd "$D" || exit 1
  exec bash RUN-Linux.sh
}

run(){
  dep

  chk git && ok "git" || exit 1
  chk fastboot && ok "fastboot" || exit 1

  git rev-parse --is-inside-work-tree >/dev/null 2>&1 && {
    git fetch origin
    L=$(git rev-parse HEAD)
    R=$(git rev-parse origin/main)
    [ "$L" != "$R" ] && git reset --hard origin/main
  }

  chmod -R +x bin scripts 2>/dev/null


echo "              Power Button"
echo "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀ ⬇️"
echo "⠀⠀⠀⠀⠀⠀⠀⢠⣾⣿⣿⠿⠿⠿⠿⠿⢿⣿⠿⢿⣿⣷⡄"
echo "⠀⠀⠀⠀⠀⠀⠀⢸⣿⠿⠿⠿⠿⠿⠿⠿⠿⠿⠿⠿⠿⣿⡇"
echo "⠀⠀⠀⠀⠀⠀⠀⢸⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿"
echo "⠀⠀⠀⠀⠀⠀⠀⢸⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⡇"
echo "⠀⠀⠀⠀⠀⠀⠀⢸⣿⠀⠀FASTBOOT ⠀⣿⣿ ⬅️ Vol Down"
echo "⠀⠀⠀⠀⠀⠀⠀⢸⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⡇"
echo "⠀⠀⠀⠀⠀⠀⠀⢸⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⡇"
echo "⠀⠀⠀⠀⠀⠀⠀⢸⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⡇"
echo "⠀⠀⠀⠀⠀⠀⠀⢸⣿⣶⣶⣶⣶⣶⣶⣶⣶⣶⣶⣶⣶⣿⡇"
echo "⠀⠀⠀⠀⠀⠀⠀⠘⢿⣿⣿⣿⣦⣤⣤⣤⣤⣴⣿⣿⣿⡿⠃"



  bash scripts/installer.sh
}

if [ ! -d .git ]; then
  boot "$@"
else
  run
fi
