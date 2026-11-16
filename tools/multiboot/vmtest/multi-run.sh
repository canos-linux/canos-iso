#!/bin/bash
# Multi-install test VM: own disk + vars, ISO always attached (install source). Usage: multi-run.sh iso|disk
V="$HOME/CanOS/vm"; R="$V/multi"
mkdir -p "$R"
iso=$(ls "$HOME"/CanOS/iso/out/desktop/*.iso 2>/dev/null | head -1)
[ -f "$R/disk.qcow2" ] || qemu-img create -f qcow2 "$R/disk.qcow2" 40G >/dev/null
[ -f "$R/vars.fd" ] || cp /usr/share/edk2/x64/OVMF_VARS.4m.fd "$R/vars.fd"
cdboot=",bootindex=0"; [ "$1" = "disk" ] && cdboot=""
qemu-system-x86_64 -enable-kvm -machine q35 -cpu host -smp 4 -m 4096 \
    -drive if=pflash,format=raw,readonly=on,file=/usr/share/edk2/x64/OVMF_CODE.4m.fd \
    -drive if=pflash,format=raw,file="$R/vars.fd" \
    -drive file="$R/disk.qcow2",if=none,id=hd -device virtio-blk-pci,drive=hd,bootindex=1 \
    -drive file="$iso",media=cdrom,if=none,id=cd,readonly=on -device ide-cd,drive=cd$cdboot \
    -device virtio-vga-gl,xres=1280,yres=800 -display egl-headless -vnc unix:"$V/vnc.sock" \
    -device qemu-xhci -device usb-tablet -device usb-kbd \
    -nic user,model=virtio-net-pci \
    -qmp unix:"$V/qmp.sock",server,nowait \
    -daemonize -pidfile "$V/qemu.pid"
