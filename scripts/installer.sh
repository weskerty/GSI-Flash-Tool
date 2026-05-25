#!/bin/bash

C_R='\033[0;31m' C_G='\033[0;32m' C_Y='\033[0;33m' C_C='\033[0;36m' C_W='\033[1;37m' NC='\033[0m'

BD="$(dirname "$(dirname "$(realpath "$0")")")"
GSI_IMG="" SLOT="a" WIPE=0 IN_FBD=0 IS_TERMUX=0 HAS_ROOT=0 IS_VAB=0 _SA=0 _SB=0 _GVA=""
SUPER_META_MIN=$(( 64 * 1024 * 1024 ))
GSI_MARGIN=$(( 64 * 1024 * 1024 ))

log_ok()   { echo -e "${C_G}[OK]${NC} $1" >&2; }
log_err()  { echo -e "${C_R}[ERR]${NC} $1" >&2; }
log_warn() { echo -e "${C_Y}[WARN]${NC} $1" >&2; }
log_info() { echo -e "${C_C}[INFO]${NC} $1" >&2; }

fb_var() {
    if [ -n "$_GVA" ]; then
        echo "$_GVA" | grep "^$1:" | sed "s/^$1://" | tr -d '[:space:]'
        return
    fi
    $_FB_BIN getvar "$1" 2>&1 | grep "^$1:" | sed "s/^$1://" | tr -d '[:space:]'
}
gva() { echo "$_GVA" | grep "^$1:" | sed "s/^$1://" | tr -d '[:space:]'; }
h2d()     { printf '%d' "$1" 2>/dev/null || echo 0; }
mb()      { echo $(( $1 / 1024 / 1024 )); }
opp()     { [ "$SLOT" = "a" ] && echo "b" || echo "a"; }
chk_opt() { local f="$BD/$1"; [ -f "$f" ] && echo "$f" || echo ""; }

detect_env() {
    if [[ "$PREFIX" == *termux* ]] || [[ -n "$TERMUX_VERSION" ]]; then
        IS_TERMUX=1
        [ "$(su -c whoami 2>/dev/null)" = "root" ] && HAS_ROOT=1
    fi
}

_FB_BIN=""
chk_deps() {
    [ "$IS_TERMUX" -eq 1 ] && return
    if command -v fastboot &>/dev/null; then
        _FB_BIN="fastboot"
    else
        local bin_path="$BD/bin/platform-tools/linux/x86_64/fastboot"
        if [ -f "$bin_path" ]; then
            chmod +x "$bin_path"
            export LD_LIBRARY_PATH="$BD/bin/platform-tools/linux/x86_64/lib64:$LD_LIBRARY_PATH"
            _FB_BIN="$bin_path"
            log_warn "Using bundled fastboot: $bin_path"
        else
            log_err "fastboot not found"; exit 1
        fi
    fi
}

to_fastbootd() {
    log_info "Entering fastbootD..."
    $_FB_BIN reboot fastboot
    local s; s=$(fb_var is-userspace)
    [ "$s" = "yes" ] && { log_ok "fastbootD ready"; IN_FBD=1; } || { log_err "fastbootD not responding"; exit 1; }
}

to_bootloader() {
    [ "$IN_FBD" -eq 0 ] && return
    log_info "Switching to bootloader..."
    $_FB_BIN reboot bootloader
    fb_var version >/dev/null 2>&1
    IN_FBD=0; log_ok "Bootloader ready"
}

detect_state() {

    log_warn "Press and hold [Power] and [Vol-] at the same time until FASTBOOT appears."

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


    log_info "Waiting for device..."
    _GVA=$($_FB_BIN getvar all 2>&1 | sed 's/(bootloader) //g')
    local s; s=$(gva is-userspace)
    if [ "$s" = "yes" ]; then
        log_ok "fastbootD ready"; IN_FBD=1
    else
        log_info "In bootloader, switching to fastbootD..."
        $_FB_BIN reboot fastboot
        log_info "Waiting for fastbootD..."
        _GVA=$($_FB_BIN getvar all 2>&1 | sed 's/(bootloader) //g')
        s=$(gva is-userspace)
        [ "$s" = "yes" ] && { log_ok "fastbootD ready"; IN_FBD=1; } || { log_err "fastbootD not responding"; exit 1; }
    fi
}

has_part() { local s; s=$(h2d "$(echo "$_GVA" | grep "^partition-size:$1:" | sed "s/^partition-size:$1://" | tr -d '[:space:]')"); [ "$s" -gt 0 ]; }

show_summary() {
    echo "" >&2
    echo -e "${C_W}--- Device ---${NC}" >&2
    local product os_ver api_lvl abi vndk treble batt
    product=$(fb_var product)
    os_ver=$(fb_var version-os)
    api_lvl=$(fb_var first-api-level)
    abi=$(fb_var cpu-abi)
    vndk=$(fb_var version-vndk)
    treble=$(fb_var treble-enabled)
    batt=$(fb_var battery-soc)
    echo -e "  ${C_C}Product:${NC} $product  ${C_C}Android:${NC} $os_ver  ${C_C}API:${NC} $api_lvl  ${C_C}ABI:${NC} $abi" >&2
    [ -n "$vndk" ] && echo -e "  ${C_C}VNDK:${NC} $vndk" >&2 || echo -e "  ${C_Y}VNDK: not reported${NC}" >&2
    if [ "$treble" = "true" ]; then
        echo -e "  ${C_G}[OK]${NC} Treble: enabled" >&2
    else
        echo -e "  ${C_Y}[WARN]${NC} Treble: not reported" >&2
        echo "" >&2
        echo -e "${C_Y}Device does not report Treble. GSI may not work. Continue? (Y/n):${NC}" >&2
        read -r -p "> " ans
        [[ "$ans" =~ ^[Nn]$ ]] && { log_warn "Aborted"; exit 0; }
    fi
    [ -n "$batt" ] && {
        echo -e "  ${C_C}Battery:${NC} $batt%" >&2
        [ "$batt" -lt 30 ] && log_warn "Battery below 30% - risk of power loss during flash"
    }
    echo "" >&2
    echo -e "${C_W}--- Bootloader ---${NC}" >&2
    local unlocked; unlocked=$(fb_var unlocked)
    if [ "$unlocked" = "yes" ]; then
        echo -e "  ${C_G}[OK]${NC} Bootloader: unlocked" >&2
    else
        echo -e "  ${C_R}[ERR]${NC} Bootloader LOCKED - unlock before flashing" >&2
        echo "" >&2
        echo -e "${C_R}Unlock bootloader and retry. Aborting.${NC}" >&2
        exit 1
    fi
    echo "" >&2
    echo -e "${C_W}--- Partitions ---${NC}" >&2
    _SA=$(h2d "$(fb_var partition-size:system_a)")
    _SB=$(h2d "$(fb_var partition-size:system_b)")
    [ "$_SA" -gt 0 ] && echo -e "  ${C_C}system_a:${NC} $(mb $_SA)MB" >&2 || echo -e "  ${C_R}system_a: not found${NC}" >&2
    [ "$_SB" -gt 0 ] && echo -e "  ${C_C}system_b:${NC} $(mb $_SB)MB" >&2 || echo -e "  ${C_Y}system_b: empty (VAB)${NC}" >&2
    fr=$(super_free)
    echo -e "  ${C_C}super free:${NC} $(mb $fr)MB" >&2
    echo "" >&2
    echo -e "${C_W}--- Files in $BD ---${NC}" >&2
    local fb_ver; fb_ver=$($_FB_BIN --version 2>&1 | head -1)
    echo -e "  ${C_C}fastboot:${NC} $fb_ver" >&2
    echo "" >&2
    for f in vbmeta vbmeta_system vbmeta_vendor vbmeta_boot; do
        has_part "${f}_a" || continue
        local fp; fp=$(chk_opt "${f}.img")
        [ -n "$fp" ] && echo -e "  ${C_G}[+]${NC} ${f}.img: $(du -h "$fp" | cut -f1)" >&2 \
                     || echo -e "  ${C_Y}[-]${NC} ${f}.img: missing (possible bootloop)" >&2
    done
    for f in boot vendor_boot recovery; do
        has_part "${f}_a" || continue
        local fp; fp=$(chk_opt "${f}.img")
        [ -n "$fp" ] && echo -e "  ${C_G}[+]${NC} ${f}.img: $(du -h "$fp" | cut -f1)" >&2 \
                     || echo -e "  ${C_C}[-]${NC} ${f}.img: not present (optional)" >&2
    done
}

detect_slot() {
    if [ "$_SA" -eq 0 ] && [ "$_SB" -eq 0 ]; then
        _SA=$(h2d "$(fb_var partition-size:system_a)")
        _SB=$(h2d "$(fb_var partition-size:system_b)")
    fi
    if [ "$_SA" -gt 0 ] && [ "$_SB" -gt 0 ]; then
        echo "" >&2
        echo -e "${C_W}Target slot (a/b) [default: a]:${NC}" >&2
        read -r -p "> " s
        [[ "$s" =~ ^[Bb]$ ]] && SLOT="b" || SLOT="a"
        log_ok "Slot: $SLOT"
    elif [ "$_SA" -gt 0 ]; then
        IS_VAB=1; SLOT="a"
        log_warn "VAB detected - only system_a has size, forcing slot a"
    elif [ "$_SB" -gt 0 ]; then
        IS_VAB=1; SLOT="b"
        log_warn "VAB detected - only system_b has size, forcing slot b"
    else
        log_err "No system partition found (system_a=0, system_b=0)"; exit 1
    fi
}

_7Z_BIN=""
chk_7z() {
    if command -v 7z &>/dev/null; then _7Z_BIN="7z"; return 0; fi
    if command -v 7zz &>/dev/null; then _7Z_BIN="7zz"; return 0; fi

    local arch; arch=$(uname -m)
    local bin_path=""
    case "$arch" in
        x86_64)  bin_path="$BD/bin/7zip/x86_64/7zz" ;;
        aarch64) bin_path="$BD/bin/7zip/aarch64/7zz" ;;
        *)       log_err "Arch $arch not supported by bundled 7zip"; return 1 ;;
    esac

    if [ -f "$bin_path" ]; then
        chmod +x "$bin_path"
        _7Z_BIN="$bin_path"
        log_info "Using bundled 7zip: $bin_path"
        return 0
    fi

    log_err "7zip not found - install: pkg install p7zip (Termux) / apt install p7zip-full (PC)"
    log_err "Tried: 7z, 7zz, $bin_path"
    return 1
}

extract_gsi() {
    local src="$1" dir; dir="$(dirname "$src")"
    chk_7z || exit 1
    log_info "Extracting $src..."
    "$_7Z_BIN" e "$src" -o"$dir" -y >&2 || { log_err "Extraction failed"; exit 1; }
    local base; base="$(basename "$src")"
    base="${base%.*}"
    [[ "$base" == *.tar ]] && base="${base%.tar}"
    [[ "$base" == *.img ]] && base="${base%.img}"
    local found="$dir/$base.img"
    if [ ! -f "$found" ]; then
        log_warn "Expected $base.img not found, looking for system.img..."
        found=$(find "$dir" -maxdepth 2 -name "system.img" | head -1)
    fi
    if [ ! -f "$found" ]; then
        log_err "No .img found after extraction. Files extracted:"
        find "$dir" -maxdepth 2 -name "*.img" | while read -r f; do
            echo -e "  ${C_C}$(basename "$f")${NC} ($(du -h "$f" | cut -f1))" >&2
        done
        exit 1
    fi
    log_info "Removing $src..."; rm -f "$src"
    log_ok "Extracted: $found"
    echo "$found"
}

ask_gsi() {
    echo "" >&2
    echo -e "${C_W}GSI image path:${NC}" >&2
    read -r -p "> " input
    input=${input//\'/}; input=${input//\"/}
    [ -f "$input" ] || { log_err "Not found: $input"; exit 1; }
    if [[ "$input" != *.img ]]; then
        input=$(extract_gsi "$input")
        [ -f "$input" ] || exit 1
    fi
    local gsi_sz; gsi_sz=$(stat -c%s "$input")
    if [ "$gsi_sz" -lt $(( 500 * 1024 * 1024 )) ]; then
        log_warn "GSI is $(du -h "$input" | cut -f1) - suspiciously small for a system image"
        echo -e "${C_Y}Continue anyway? (y/N):${NC}" >&2
        read -r -p "> " ans
        [[ "$ans" =~ ^[Yy]$ ]] || { log_warn "Aborted"; exit 0; }
    fi
    GSI_IMG="$input"
    log_ok "GSI: $GSI_IMG ($(du -h "$GSI_IMG" | cut -f1))"
}

super_free() {
    local super_dec used_dec=0
    super_dec=$(h2d "$(gva partition-size:super)")
    while IFS= read -r line; do
        local part sz is_log
        part=$(echo "$line" | awk -F: '{print $2}')
        sz=$(echo "$line" | awk -F: '{print $3}' | tr -d '[:space:]')
        is_log=$(echo "$_GVA" | grep "^is-logical:${part}:" | sed "s/^is-logical:${part}://" | tr -d '[:space:]')
        [ "$is_log" = "yes" ] && used_dec=$(( used_dec + $(h2d "$sz") ))
    done < <(echo "$_GVA" | grep "^partition-size:")
    echo $(( super_dec - used_dec ))
}

try_free_space() {
    local needed="$1" avail="$2"
    local opp_slot; opp_slot=$(opp)

    local sys_opp; sys_opp=$(h2d "$(fb_var "partition-size:system_$opp_slot")")
    if [ "$sys_opp" -gt 0 ]; then
        local new_avail=$(( avail + sys_opp ))
        log_warn "Need $(mb $needed)MB. Delete system_$opp_slot ($(mb $sys_opp)MB, inactive slot)? (y/N):"
        read -r -p "> " ans
        if [[ "$ans" =~ ^[Yy]$ ]]; then
            $_FB_BIN delete-logical-partition "system_$opp_slot" \
                && log_ok "system_$opp_slot deleted" || { log_err "Delete failed"; exit 1; }
            avail=$new_avail
            [ "$avail" -ge "$needed" ] && { echo "$avail"; return 0; }
        fi
    fi

    local prod_opp; prod_opp=$(h2d "$(fb_var "partition-size:product_$opp_slot")")
    if [ "$prod_opp" -gt 0 ]; then
        local new_avail=$(( avail + prod_opp ))
        log_warn "Still need more. Delete product_$opp_slot ($(mb $prod_opp)MB, inactive slot)? (y/N):"
        read -r -p "> " ans
        if [[ "$ans" =~ ^[Yy]$ ]]; then
            $_FB_BIN delete-logical-partition "product_$opp_slot" \
                && log_ok "product_$opp_slot deleted" || { log_err "Delete failed"; exit 1; }
            avail=$new_avail
            [ "$avail" -ge "$needed" ] && { echo "$avail"; return 0; }
        fi
    fi

    local prod_cur; prod_cur=$(h2d "$(fb_var "partition-size:product_$SLOT")")
    if [ "$prod_cur" -gt 0 ]; then
        local new_avail=$(( avail + prod_cur ))
        log_warn "Still need more. Delete product_$SLOT ($(mb $prod_cur)MB, active slot)? (y/N):"
        read -r -p "> " ans
        if [[ "$ans" =~ ^[Yy]$ ]]; then
            $_FB_BIN delete-logical-partition "product_$SLOT" \
                && log_ok "product_$SLOT deleted" || { log_err "Delete failed"; exit 1; }
            avail=$new_avail
            [ "$avail" -ge "$needed" ] && { echo "$avail"; return 0; }
        fi
    fi

    echo "$avail"
    return 1
}

do_resize() {
    local needed=$(( $(stat -c%s "$GSI_IMG") + GSI_MARGIN ))
    local cur_dec; cur_dec=$(h2d "$(fb_var "partition-size:system_$SLOT")")

    log_info "GSI+margin: $(mb $needed)MB | system_$SLOT: $(mb $cur_dec)MB"

    if [ "$cur_dec" -gt "$needed" ]; then
        log_info "system_$SLOT larger than needed, shrinking..."
        $_FB_BIN resize-logical-partition "system_$SLOT" "$needed" \
            && log_ok "Shrink done" || log_warn "Shrink failed, continuing"
        cur_dec=$needed
    fi

    [ "$cur_dec" -ge "$needed" ] && { log_ok "No resize needed"; return 0; }

    local free_dec; free_dec=$(super_free)
    local avail=$(( cur_dec + free_dec ))
    log_info "Super free: $(mb $free_dec)MB | Max possible: $(mb $avail)MB"

    if [ "$avail" -ge "$needed" ]; then
        $_FB_BIN resize-logical-partition "system_$SLOT" "$needed" \
            && { log_ok "Resize done"; return 0; } \
            || { log_err "Resize failed"; exit 1; }
    fi

    local new_avail
    new_avail=$(try_free_space "$needed" "$avail") || {
        log_err "Insufficient space after all options. Aborting."
        exit 1
    }

    $_FB_BIN resize-logical-partition "system_$SLOT" "$needed" \
        && log_ok "Resize done" || { log_err "Resize failed"; exit 1; }
}

try_mirror_opp() {
    [ "$IS_VAB" -eq 1 ] && { log_info "VAB - skipping OTA mirror"; return; }
    local opp_slot; opp_slot=$(opp)
    local sys_size; sys_size=$(h2d "$(fb_var "partition-size:system_$SLOT")")
    local opp_size; opp_size=$(h2d "$(fb_var "partition-size:system_$opp_slot")")

    if [ "$opp_size" -eq 0 ]; then
        log_warn "system_$opp_slot does not exist - no OTA mirror possible"
        return
    fi

    local needed_extra=$(( sys_size - opp_size ))
    if [ "$needed_extra" -le 0 ]; then
        log_ok "system_$opp_slot already adequate - OTA slot $opp_slot ready"
        return
    fi

    local free_dec; free_dec=$(super_free)
    local post_free=$(( free_dec - needed_extra ))
    if [ "$post_free" -lt "$SUPER_META_MIN" ]; then
        log_warn "Not enough super space for OTA mirror"
        return
    fi

    echo "" >&2
    echo -e "${C_Y}Mirror system_$opp_slot to $(mb $sys_size)MB for future OTA? (Y/n):${NC}" >&2
    read -r -p "> " ans
    [[ "$ans" =~ ^[Nn]$ ]] && { log_info "OTA mirror skipped"; return; }

    $_FB_BIN resize-logical-partition "system_$opp_slot" "$sys_size" \
        && log_ok "system_$opp_slot mirrored" \
        || log_warn "Mirror failed - resize manually via fastbootD"
}

show_plan() {
    local vbm vbms vbmv vbmb boot vb rec omit="" warn=0
    vbm=$(chk_opt "vbmeta.img")
    vbms=$(chk_opt "vbmeta_system.img")
    vbmv=$(chk_opt "vbmeta_vendor.img")
    vbmb=$(chk_opt "vbmeta_boot.img")
    boot=$(chk_opt "boot.img")
    vb=$(chk_opt "vendor_boot.img")
    rec=$(chk_opt "recovery.img")

    echo "" >&2
    log_info "--- Flash plan (slot $SLOT) ---"
    log_info "GSI -> system_$SLOT: $GSI_IMG"
    echo "" >&2

    has_part "vbmeta_$SLOT"        && { [ -n "$vbm"  ] && log_info "vbmeta_$SLOT:        $vbm"  || { log_warn "vbmeta.img missing - possible bootloop";        warn=1; }; }
    has_part "vbmeta_system_$SLOT" && { [ -n "$vbms" ] && log_info "vbmeta_system_$SLOT: $vbms" || { log_warn "vbmeta_system.img missing - possible bootloop"; warn=1; }; }
    has_part "vbmeta_vendor_$SLOT" && { [ -n "$vbmv" ] && log_info "vbmeta_vendor_$SLOT: $vbmv" || { log_warn "vbmeta_vendor.img missing - possible bootloop"; warn=1; }; }
    has_part "vbmeta_boot_$SLOT"   && { [ -n "$vbmb" ] && log_info "vbmeta_boot_$SLOT:   $vbmb" || { log_warn "vbmeta_boot.img missing - possible bootloop";   warn=1; }; }

    has_part "boot_$SLOT"        && { [ -n "$boot" ] && log_info "boot_$SLOT:        $boot" || omit="boot.img"; }
    has_part "vendor_boot_$SLOT" && { [ -n "$vb"   ] && log_info "vendor_boot_$SLOT: $vb"  || omit="$omit vendor_boot.img"; }
    has_part "recovery_$SLOT"    && { [ -n "$rec"  ] && log_info "recovery_$SLOT:    $rec" || omit="$omit recovery.img"; }
    [ -n "$omit" ] && log_warn "Omitted:$omit"

    if [ "$warn" -eq 1 ]; then
        echo "" >&2
        echo -e "${C_Y}Missing vbmeta files. Continue? (Y/n):${NC}" >&2
        read -r -p "> " ans
        [[ "$ans" =~ ^[Nn]$ ]] && { log_warn "Aborted"; exit 0; }
    fi

    echo "" >&2
    echo -e "${C_R}Wipe userdata + metadata? (y/N) [IRREVERSIBLE]:${NC}" >&2
    read -r -p "> " w
    [[ "$w" =~ ^[Yy]$ ]] && WIPE=1

    echo "" >&2
    echo -e "${C_W}Confirm flash? (Y/n):${NC}" >&2
    read -r -p "> " c
    [[ "$c" =~ ^[Nn]$ ]] && { log_warn "Aborted"; exit 0; }
}

do_flash() {
    local vbm vbms vbmv vbmb boot vb rec VF="--disable-verity --disable-verification"
    vbm=$(chk_opt "vbmeta.img")
    vbms=$(chk_opt "vbmeta_system.img")
    vbmv=$(chk_opt "vbmeta_vendor.img")
    vbmb=$(chk_opt "vbmeta_boot.img")
    boot=$(chk_opt "boot.img")
    vb=$(chk_opt "vendor_boot.img")
    rec=$(chk_opt "recovery.img")

    do_resize

    [ -n "$vbm"  ] && has_part "vbmeta_$SLOT"        && { $_FB_BIN $VF flash "vbmeta_$SLOT"        "$vbm"  && log_ok "vbmeta_$SLOT"        || log_err "vbmeta_$SLOT failed"; }
    [ -n "$vbms" ] && has_part "vbmeta_system_$SLOT" && { $_FB_BIN $VF flash "vbmeta_system_$SLOT" "$vbms" && log_ok "vbmeta_system_$SLOT" || log_err "vbmeta_system_$SLOT failed"; }
    [ -n "$vbmv" ] && has_part "vbmeta_vendor_$SLOT" && { $_FB_BIN $VF flash "vbmeta_vendor_$SLOT" "$vbmv" && log_ok "vbmeta_vendor_$SLOT" || log_err "vbmeta_vendor_$SLOT failed"; }
    [ -n "$vbmb" ] && has_part "vbmeta_boot_$SLOT"   && { $_FB_BIN $VF flash "vbmeta_boot_$SLOT"   "$vbmb" && log_ok "vbmeta_boot_$SLOT"   || log_err "vbmeta_boot_$SLOT failed"; }

    log_info "Flashing GSI..."
    $_FB_BIN flash "system_$SLOT" "$GSI_IMG" && log_ok "system_$SLOT" || { log_err "system_$SLOT failed"; exit 1; }

    to_bootloader

    [ -n "$boot" ] && has_part "boot_$SLOT"        && { $_FB_BIN flash "boot_$SLOT"        "$boot" && log_ok "boot_$SLOT"        || log_err "boot_$SLOT failed"; }
    [ -n "$vb"   ] && has_part "vendor_boot_$SLOT" && { $_FB_BIN flash "vendor_boot_$SLOT" "$vb"   && log_ok "vendor_boot_$SLOT" || log_err "vendor_boot_$SLOT failed"; }
    [ -n "$rec"  ] && has_part "recovery_$SLOT"    && { $_FB_BIN flash "recovery_$SLOT"    "$rec"  && log_ok "recovery_$SLOT"    || log_err "recovery_$SLOT failed"; }

    if [ "$WIPE" -eq 1 ]; then
        $_FB_BIN erase userdata && log_ok "userdata erased"
        $_FB_BIN erase metadata && log_ok "metadata erased"
    fi

    try_mirror_opp

    $_FB_BIN set_active "$SLOT"
    $_FB_BIN reboot
    log_ok "Done! Booting slot $SLOT..."
}

do_termux_update() {
    local opp_slot; opp_slot=$(opp)
    local tgt="/dev/block/by-name/system_$opp_slot"
    [ -b "$tgt" ] || { log_err "Block device not found: $tgt"; exit 1; }

    local gsi_size part_size
    gsi_size=$(stat -c%s "$GSI_IMG")
    part_size=$(su -c "blockdev --getsize64 $tgt" 2>/dev/null)
    part_size=$(( part_size + 0 ))

    log_info "GSI: $(mb $gsi_size)MB | system_$opp_slot: $(mb $part_size)MB"

    if [ "$gsi_size" -gt "$part_size" ]; then
        log_err "GSI does not fit in system_$opp_slot - resize required via fastbootD"
        exit 1
    fi

    local boot vb rec omit="" warn=0
    boot=$(chk_opt "boot.img")
    vb=$(chk_opt "vendor_boot.img")
    rec=$(chk_opt "recovery.img")

    echo "" >&2
    log_info "--- Termux OTA plan (slot $opp_slot) ---"
    log_info "GSI -> system_$opp_slot: $GSI_IMG"
    [ -n "$boot" ] && log_info "boot_$opp_slot:        $boot"      || { log_warn "boot.img missing - possible bootloop"; warn=1; }
    [ -n "$vb"   ] && log_info "vendor_boot_$opp_slot: $vb"        || { log_warn "vendor_boot.img missing - possible bootloop"; warn=1; }
    [ -n "$rec"  ] && log_info "recovery_$opp_slot:    $rec"       || omit="recovery.img"
    [ -n "$omit" ] && log_warn "Omitted: $omit"

    if [ "$warn" -eq 1 ]; then
        echo "" >&2
        echo -e "${C_Y}Missing boot files. Continue? (Y/n):${NC}" >&2
        read -r -p "> " ans
        [[ "$ans" =~ ^[Nn]$ ]] && { log_warn "Aborted"; exit 0; }
    fi

    echo "" >&2
    echo -e "${C_W}Confirm OTA flash to slot $opp_slot? (Y/n):${NC}" >&2
    read -r -p "> " c
    [[ "$c" =~ ^[Nn]$ ]] && { log_warn "Aborted"; exit 0; }

    log_info "Writing GSI to system_$opp_slot..."
    su -c "dd if=\"$GSI_IMG\" of=\"$tgt\" bs=4M status=progress" \
        && log_ok "system_$opp_slot written" || { log_err "dd failed"; exit 1; }

    for pair in "boot.img:boot_$opp_slot" "vendor_boot.img:vendor_boot_$opp_slot" "recovery.img:recovery_$opp_slot"; do
        local fname="${pair%%:*}" pname="${pair##*:}"
        local fpath; fpath=$(chk_opt "$fname")
        [ -z "$fpath" ] && continue
        local ptgt="/dev/block/by-name/$pname"
        [ -b "$ptgt" ] || { log_warn "$ptgt not found, skipping"; continue; }
        su -c "dd if=\"$fpath\" of=\"$ptgt\" bs=4M status=progress" \
            && log_ok "$pname written" || log_err "$pname failed"
    done

    local slot_num; slot_num=$([ "$opp_slot" = "a" ] && echo 0 || echo 1)
    su -c "bootctl set-active-boot-slot $slot_num" \
        && log_ok "Active slot -> $opp_slot" || log_err "bootctl failed - set slot manually"

    echo "" >&2
    log_ok "OTA done!"
    echo -e "${C_Y}Reboot now? (Y/n):${NC}" >&2
    read -r -p "> " r
    [[ "$r" =~ ^[Nn]$ ]] || su -c "reboot"
}

_ask_ksu() {
    local _ksu_avail=0
    { has_part "init_boot_a"   && [ -n "$(chk_opt "init_boot.img")"   ]; } && _ksu_avail=1
    { has_part "vendor_boot_a" && [ -n "$(chk_opt "vendor_boot.img")" ]; } && _ksu_avail=1
    { has_part "boot_a"        && [ -n "$(chk_opt "boot.img")"        ]; } && _ksu_avail=1
    [ "$_ksu_avail" -eq 0 ] && return
    echo "" >&2
    echo -e "${C_W}Install KernelSU? (y/N):${NC}" >&2
    read -r -p "> " _ksu_ans
    [[ "$_ksu_ans" =~ ^[Yy]$ ]] && source "$BD/scripts/ksu.sh"
}

main() {
    echo "" >&2
    echo -e "${C_W}=== GSI Flash Tool ===${NC}" >&2

    detect_env
    chk_deps

    if [ "$IS_TERMUX" -eq 1 ]; then
        if [ "$HAS_ROOT" -eq 1 ]; then
            log_ok "Mode: Termux OTA"
            local sa sb
            sa=$(su -c "blockdev --getsize64 /dev/block/by-name/system_a" 2>/dev/null || echo 0)
            sb=$(su -c "blockdev --getsize64 /dev/block/by-name/system_b" 2>/dev/null || echo 0)
            sa=$(( sa + 0 )); sb=$(( sb + 0 ))
            if [ "$sa" -eq 0 ] || [ "$sb" -eq 0 ]; then
                log_err "VAB device - Termux OTA requires both slots with real size"
                log_err "Use fastbootD mode from PC instead"
                exit 1
            fi
            local cur_slot; cur_slot=$(su -c "getprop ro.boot.slot_suffix" 2>/dev/null | tr -d '_')
            [ -z "$cur_slot" ] && cur_slot=$(su -c "bootctl get-current-slot" 2>/dev/null)
            [ "$cur_slot" = "0" ] && cur_slot="a"
            [ "$cur_slot" = "1" ] && cur_slot="b"
            if [ "$cur_slot" = "a" ]; then SLOT="b"
            elif [ "$cur_slot" = "b" ]; then SLOT="a"
            else log_err "Could not detect active slot"; exit 1
            fi
            log_info "Active slot: $cur_slot -> flashing to: $SLOT"
        else
            log_err "Termux detected but no root - connect to PC and run in fastbootD mode"
            exit 1
        fi
    else
        log_info "Mode: fastbootD"
        detect_state
        show_summary
        detect_slot
    fi

    ask_gsi
    _ask_ksu

    if [ "$IS_TERMUX" -eq 1 ]; then
        do_termux_update
    else
        show_plan
        do_flash
    fi
}

main