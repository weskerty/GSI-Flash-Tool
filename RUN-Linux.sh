#!/bin/bash

cd "$(dirname "$0")" 2>/dev/null || exit 1

G="\e[32m"; R="\e[31m"; Y="\e[33m"; N="\e[0m"
ok(){ echo -e "${G}[OK]${N} $1"; }
er(){ echo -e "${R}[ERROR]${N} $1"; }
inf(){ echo -e "${Y}[INFO]${N} $1"; }

chk(){ command -v "$1" >/dev/null 2>&1; }

dep(){
  chk git && ok "git" || { er "git"; exit 1; }
  chk fastboot && ok "fastboot" || { er "fastboot"; exit 1; }
}

clone(){
  D="${1:-$HOME/GSI-Flash-Tool}"

  [ -e "$D" ] && {
    inf "exists"
    cd "$D" 2>/dev/null || { er "bad dir"; exit 1; }
    [ -f RUN-Linux.sh ] && exec bash RUN-Linux.sh
    er "no RUN"
    exit 1
  }

  dep
  inf "clone $D"
  git clone https://github.com/weskerty/GSI-Flash-Tool.git --depth 1 --single-branch "$D" || exit 1
  cd "$D" || exit 1
  exec bash RUN-Linux.sh
}

run(){
  dep

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

[ -d .git ] && run || clone "$@"




