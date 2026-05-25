#!/bin/bash

_KSU_STANDALONE=0
[ "$(type -t log_ok)" = "function" ] || {
    _KSU_STANDALONE=1
    BD="$(dirname "$(dirname "$(realpath "$0")")")"
    C_R='\033[0;31m' C_G='\033[0;32m' C_Y='\033[0;33m' C_C='\033[0;36m' C_W='\033[1;37m' NC='\033[0m'
    log_ok()   { echo -e "${C_G}[OK]${NC} $1" >&2; }
    log_err()  { echo -e "${C_R}[ERR]${NC} $1" >&2; }
    log_warn() { echo -e "${C_Y}[WARN]${NC} $1" >&2; }
    log_info() { echo -e "${C_C}[INFO]${NC} $1" >&2; }
    chk_opt()  { local f="$BD/$1"; [ -f "$f" ] && echo "$f" || echo ""; }
}

_chk_ksu_bin() {
    local arch; arch=$(uname -m)
    local bin=""
    if [ "${IS_TERMUX:-0}" -eq 1 ]; then
        [ "$arch" = "aarch64" ] && bin="$BD/bin/kSU/ksud-aarch64-linux-android"
    else
        case "$arch" in
            aarch64) bin="$BD/bin/kSU/ksud-aarch64-unknown-linux-musl" ;;
            x86_64)  bin="$BD/bin/kSU/ksud-x86_64-unknown-linux-musl" ;;
        esac
    fi
    [ -f "$bin" ] || { log_err "ksud not found for $arch"; return 1; }
    chmod +x "$bin"
    echo "$bin"
}

_chk_mboot_bin() {
    local arch; arch=$(uname -m)
    local bin=""
    case "$arch" in
        aarch64) bin="$BD/bin/magiskboot/aarch64" ;;
        x86_64)  bin="$BD/bin/magiskboot/x86_64" ;;
    esac
    [ -f "$bin" ] || return 1
    chmod +x "$bin"
    echo "$bin"
}

_ksu_patch() {
    local img="$1" ksud="$2" mboot="$3"
    local base; base="$(basename "$img" .img)"
    local out="$BD/patched.img"

    local cmd="$ksud boot-patch -b \"$img\" -o \"$BD\" --out-name patched.img"
    [ -n "$mboot" ] && cmd="$cmd --magiskboot \"$mboot\""
    local output; output=$(eval $cmd 2>&1)
    local rc=$?
    echo "$output" >&2
    if [ $rc -eq 0 ] && [ -f "$out" ]; then
        mv "$img" "${img%.img}.OLD.img"
        mv "$out" "$img"
        log_ok "Patched: $img (original -> ${base}.OLD.img)"
        return 0
    fi
    log_err "ksud failed (rc=$rc)"
    return 1
}

ksu_main() {
    local ksud mboot
    ksud=$(_chk_ksu_bin) || { read -r -p $'\nPress enter to continue...' _; return; }
    mboot=$(_chk_mboot_bin 2>/dev/null || true)

    local opts=()

    if [ "$_KSU_STANDALONE" -eq 1 ]; then
        [ -n "$(chk_opt "init_boot.img")"   ] && opts+=("init_boot.img")
        [ -n "$(chk_opt "vendor_boot.img")" ] && opts+=("vendor_boot.img")
        [ -n "$(chk_opt "boot.img")"        ] && opts+=("boot.img")
    else
        local warned=0
        local init_f; init_f=$(chk_opt "init_boot.img")
        local vend_f; vend_f=$(chk_opt "vendor_boot.img")
        local boot_f; boot_f=$(chk_opt "boot.img")

        local has_init=0 has_vend=0 has_boot=0
        has_part "init_boot_a"   && has_init=1
        has_part "vendor_boot_a" && has_vend=1
        has_part "boot_a"        && has_boot=1

        if [ $has_init -eq 1 ] && [ -z "$init_f" ] && [ $warned -eq 0 ]; then
            log_warn "KSU recommends init_boot - file not present"
            warned=1
        fi

        [ $has_init -eq 1 ] && [ -n "$init_f" ] && opts+=("init_boot.img")
        [ $has_vend -eq 1 ] && [ -n "$vend_f" ] && opts+=("vendor_boot.img")
        [ $has_boot -eq 1 ] && [ -n "$boot_f" ] && opts+=("boot.img")
    fi

    if [ ${#opts[@]} -eq 0 ]; then
        log_warn "No valid target for KSU patch"
        read -r -p $'\nPress enter to continue...' _
        return
    fi

    local chosen=""
    if [ ${#opts[@]} -eq 1 ]; then
        chosen="${opts[0]}"
        log_info "Target: $chosen"
    else
        echo "" >&2
        echo -e "${C_W}Select patch target:${NC}" >&2
        for i in "${!opts[@]}"; do
            echo -e "  $((i+1))) ${opts[$i]}" >&2
        done
        echo -e "  (enter = ${opts[0]})" >&2
        read -r -p "> " sel
        if [[ "$sel" =~ ^[0-9]+$ ]] && [ "$sel" -ge 1 ] && [ "$sel" -le ${#opts[@]} ]; then
            chosen="${opts[$((sel-1))]}"
        else
            chosen="${opts[0]}"
        fi
        log_info "Target: $chosen"
    fi

    _ksu_patch "$BD/$chosen" "$ksud" "$mboot"
}

ksu_main