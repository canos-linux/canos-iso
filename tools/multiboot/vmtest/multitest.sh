#!/bin/bash
# Multi-install test in the VM (run in background: setsid -f bash .../multitest.sh)
#  1 live ISO: build "Serpantinum" disk (laptop layout)   2 Serpantinum: install CanOS Privat + Public, GRUB, snapshots
#  3 Serpantinum (renamed) boots   4 CanOS Privat   5 CanOS Public (use it)   6 Serpantinum: canos-reset-public
#  7 CanOS Public again (welcome app must be back)
# Partial runs: FROM=<step>. Results: ~/CanOS/vm/multi/{multi.log,guest.txt,*.jpg}
V="$HOME/CanOS/vm"; T="$HOME/CanOS/iso/tools/multiboot"; R="$V/multi"
mkdir -p "$R"; FROM=${FROM:-1}
[ "$FROM" = 1 ] && rm -f "$R"/*.jpg "$R"/guest.txt "$R"/multi.log
exec >>"$R/multi.log" 2>&1
log() { echo "[$(date +%H:%M:%S)] $*"; }
q() { timeout 40 python3 "$V/qmp.py" "$@"; }
shot() { (cd "$V" && python3 vncshot.py "$1" >/dev/null && magick "$1.jpg" -resize 640x "$R/$1.jpg" && rm -f "$1.jpg"); }
running() { [ -f "$V/qemu.pid" ] && kill -0 "$(cat "$V/qemu.pid")" 2>/dev/null; }
stopvm() { running || return 0; q hmp system_powerdown >/dev/null; for i in $(seq 40); do running || return 0; sleep 2; done; kill "$(cat "$V/qemu.pid")"; sleep 3; }
waitoff() { for i in $(seq $(($1 / 5))); do running || return 0; sleep 5; done; return 1; }
fail() { log "FAIL: $*"; shot fail; stopvm; log "END FAIL"; exit 1; }
phase() { echo "$1" > "$V/serve/phase.txt"; }
g() { grep -E "$1" "$R/guest.txt" | tail -1; }
chk() { if tail -n +"${2:-1}" "$R/guest.txt" | grep -qE "$1"; then log "OK   $3"; else log "FAIL $3"; fi; }
mark() { wc -l < "$R/guest.txt"; }
# boot from disk; $1 = number of "down" presses in GRUB (empty = default entry)
bootdisk() {
    "$R/../multi-run.sh" disk || fail "VM start"
    # press Home every second until GRUB surely shows (stops the countdown, selects entry 0)
    if [ -n "$1" ]; then sleep 3; for i in $(seq 10); do q key home; sleep 1; done; for i in $(seq "$1"); do q key down; sleep 0.3; done; [ "$2" = shot ] && shot grub; q key ret; fi
}
login() { sleep 100; q type canos123; q key ret; sleep 50; }

log "START (FROM=$FROM)"; stopvm
cp "$T"/canos-* "$T"/vmtest/multi-guest.sh "$T"/vmtest/make-serpantinum.sh "$V/serve/"
cp "$T"/vmtest/multi-run.sh "$V/multi-run.sh"
iso=$(ls "$HOME"/CanOS/iso/out/desktop/*.iso | head -1); log "ISO $iso"
pkill -f "recv.py $R/guest.txt"; touch "$R/guest.txt"
python3 "$V/recv.py" "$R/guest.txt" "$V/serve/multi-guest.sh" & rp=$!
trap 'kill $rp 2>/dev/null' EXIT

if [ "$FROM" -le 1 ]; then
    log "1 live ISO -> build Serpantinum disk"
    rm -f "$R/disk.qcow2" "$R/vars.fd"; phase none
    "$V/multi-run.sh" iso || fail "VM start (ISO)"
    sleep 120
    q click 335 647; sleep 2; q key meta_l+ret; sleep 6
    q type "curl -s 10.0.2.2:8766/make-serpantinum.sh | sudo bash"; q key ret
    waitoff 1500 || fail "make-serpantinum did not finish"
    chk "make-serpantinum OK" 1 "Serpantinum disk built"
fi
if [ "$FROM" -le 2 ]; then
    log "2 Serpantinum: install CanOS Privat + Public"; m=$(mark); phase install
    bootdisk
    waitoff 2400 || fail "install phase did not finish"
    chk "PRIVAT_RC=0" $m "install CanOS Privat"; chk "PUBLIC_RC=0" $m "install CanOS Public"
    chk "GRUB_RC=0" $m "GRUB entries"; chk "SNAP_RC=0" $m "clean snapshots"
fi
if [ "$FROM" -le 3 ]; then
    log "3 Serpantinum (renamed) boots"; m=$(mark); phase check
    bootdisk 0 shot
    waitoff 300 || fail "Serpantinum check did not finish"
    chk "SERPANTINUM booted" $m "Serpantinum boots"; chk "MENU: Serpantinum Linux" $m "GRUB entry renamed"
fi
P=$(g '^IDX_PRIVAT=' | cut -d= -f2); U=$(g '^IDX_PUBLIC=' | cut -d= -f2)
[ -n "$P" ] && [ -n "$U" ] || fail "no GRUB index for CanOS entries"
log "GRUB index privat=$P public=$U"
if [ "$FROM" -le 4 ]; then
    log "4 CanOS Privat"; m=$(mark); phase privat
    bootdisk "$P"; login; shot privat; stopvm
    chk "##### @canos-privat phase" $m "CanOS Privat boots"; chk "CANVAS_RUNNING" $m "Canvas runs (Privat)"
fi
if [ "$FROM" -le 5 ]; then
    log "5 CanOS Public (first use)"; m=$(mark); phase pub1
    bootdisk "$U"; login; shot pub1; sleep 10; stopvm
    chk "##### @canos-public phase=pub1" $m "CanOS Public boots"; chk "CANVAS_RUNNING" $m "Canvas runs (Public)"
    chk "RESET_FROM_PUBLIC_RC=1" $m "reset refuses inside Public"; chk "usage simulated" $m "usage simulated"
fi
if [ "$FROM" -le 6 ]; then
    log "6 Serpantinum: canos-reset-public"; m=$(mark); phase reset
    bootdisk 0
    waitoff 300 || fail "reset phase did not finish"
    chk "RESET_RC=0" $m "canos-reset-public"
fi
if [ "$FROM" -le 7 ]; then
    log "7 CanOS Public after reset"; m=$(mark); phase pub2
    bootdisk "$U"; login; shot pub2; stopvm
    chk "MARKER=no ROOTMARKER=no" $m "markers gone after reset"; chk "SETTINGS_BEFORE_LOGIN=absent" $m "settings.json gone (welcome comes)"
    chk "CANVAS_RUNNING" $m "Canvas runs after reset"
fi
log "END"
