#!/bin/bash
cd "$(dirname "$0")" || exit 1


# === Update ===
git fetch origin
L=$(git rev-parse HEAD)
R=$(git rev-parse origin/main)
[ "$L" != "$R" ] && git reset --hard origin/main
# === Update === 

chmod -R +x bin 
chmod -R +x scripts
bash scripts/installer.sh