#!/bin/bash

# Pasos para instalar una rom y activar adb a traves de twrp si tienes la pantalla rota.

ADBKEY="$HOME/.android/adbkey.pub"
PARTS="system system_root vendor vendor_dlkm odm odm_dlkm product system_ext"
PROPVARS="ro.adb.secure=0 persist.sys.usb.config=adb"

DEV=$(adb devices | grep -v "List" | grep -v "^$" | awk '{print $1}' | head -n1 | tr -d '\r')
#DEV=$(adb devices | grep -v "List" | grep -v "^$" | awk '{print $1}' | head -n1)

if [ -z "$DEV" ]; then
  echo "Error Dispositivo \$NoDetectado"
  exit 1
fi

echo "Dispositivo \$DEV"

adb -s "$DEV" push "$ADBKEY" /sdcard/adbkey.pub
adb -s "$DEV" shell "mkdir -p /data/misc/adb"
adb -s "$DEV" shell "cp /sdcard/adbkey.pub /data/misc/adb/adb_keys"
adb -s "$DEV" shell "chmod 600 /data/misc/adb/adb_keys"
adb -s "$DEV" shell "chown 2000:2000 /data/misc/adb/adb_keys"

for P in $PARTS; do
  adb -s "$DEV" shell "mount /$P" >/dev/null 2>&1
  adb -s "$DEV" shell "mount -o rw,remount /$P" >/dev/null 2>&1
done

FOUND=0

for P in $PARTS; do
  for CANDIDATE in "/$P/build.prop" "/$P/system/build.prop" "/$P/default.prop"; do
    EXISTS=$(adb -s "$DEV" shell "[ -f $CANDIDATE ] && echo si || echo no")
    EXISTS=$(echo "$EXISTS" | tr -d '\r\n')
    if [ "$EXISTS" = "si" ]; then
      echo "Encontrado \$CANDIDATE"
      FOUND=1

      adb -s "$DEV" shell "grep -q '^ro.adb.secure=' $CANDIDATE && sed -i 's/^ro.adb.secure=.*/ro.adb.secure=0/' $CANDIDATE || echo 'ro.adb.secure=0' >> $CANDIDATE"
      adb -s "$DEV" shell "grep -q '^persist.sys.usb.config=' $CANDIDATE && sed -i 's/^persist.sys.usb.config=.*/persist.sys.usb.config=adb/' $CANDIDATE || echo 'persist.sys.usb.config=adb' >> $CANDIDATE"
    fi
  done
done

if [ "$FOUND" -eq 0 ]; then
  echo "NoEncontrado \$EscribiendoDefault"
  adb -s "$DEV" shell "echo 'ro.adb.secure=0' >> /default.prop"
  adb -s "$DEV" shell "echo 'persist.sys.usb.config=adb' >> /default.prop"
fi

echo "Listo \$Fin"

# ---------------------------------------------------------
# instalar rom Ginkgo crDroid
#
# adb -s 159f7d45 push "crdroid.zip" /sdcard/crdroid.zip
# adb -s 159f7d45 shell twrp wipe data
# adb -s 159f7d45 shell twrp wipe cache
# adb -s 159f7d45 shell twrp wipe dalvik
# adb -s 159f7d45 shell twrp install /sdcard/crdroid.zip
# ---------------------------------------------------------

# el wipe se queda trabado, no se si se queda trabado o solo twrp no informa a la temrinal que finalizo el proceso, ctrl + c cancela y luego instalas la rom y funciona. 
# el 159f7d45 es el id del adb device en ese momento debes cambiar por el tuyo. 
