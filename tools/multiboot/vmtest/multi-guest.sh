#!/bin/bash
# Runs as root at boot in every system of the multi-install test VM (vmcheck.service).
# Branches on the booted subvolume and the phase served by the host (phase.txt).
H=10.0.2.2:8766
P=$(curl -s $H/phase.txt)
S=$(findmnt -no OPTIONS / | grep -o 'subvol=[^,]*' | sed 's|subvol=/*||')
post() { curl -s --data-binary @- $H >/dev/null; }
get() { curl -sf $H/$1 -o /usr/local/bin/$1 && chmod 755 /usr/local/bin/$1; }
top() { mkdir -p /run/top; mountpoint -q /run/top || mount -o subvolid=5 "$(findmnt -no SOURCE / | sed 's/\[.*//')" /run/top; }
O=/run/mg.out
exec >$O 2>&1
echo "##### $S phase=$P $(date +%T)"

waitcanvas() {   # wait for the user session, then report Canvas + edition
    for i in $(seq 90); do p=$(pgrep -u alex -f 'share/canvas/shell.qml' | head -1); [ -n "$p" ] && break; sleep 2; done
    { echo "##### $S session $(date +%T)"
      [ -n "$p" ] && echo "CANVAS_RUNNING pid=$p" || echo "CANVAS_NOT_RUNNING"
      [ -n "$p" ] && tr '\0' '\n' < /proc/$p/environ | grep -E '^CANVAS_EDITION|^LANG='
      sleep 8; echo "SETTINGS_AFTER_LOGIN=$([ -f /home/alex/.config/canvas/settings.json ] && echo present || echo absent)"
      grep -o '"welcomeDone": *[a-z]*' /home/alex/.config/canvas/settings.json 2>/dev/null
      grep -o '"language": *"[a-z]*"' /home/alex/.config/canvas/settings.json 2>/dev/null; } | post
}

canoscheck() {
    echo "HOST=$(cat /etc/hostname)"; findmnt -no TARGET,SOURCE / /home
    grep -v '^#' /etc/fstab; id alex; ls /home
    echo "PRIVATE_JSON=$([ -e /home/alex/.config/canvas/private.json ] && echo yes || echo no)"
    echo "SETTINGS_BEFORE_LOGIN=$([ -f /home/alex/.config/canvas/settings.json ] && echo present || echo absent)"
    echo "MARKER=$([ -e /home/alex/used-marker ] && echo yes || echo no) ROOTMARKER=$([ -e /etc/canos-used ] && echo yes || echo no)"
    grep -c initial_session /etc/greetd/config.toml; systemctl is-enabled greetd NetworkManager
    cat /etc/locale.conf /etc/vconsole.conf; grep XkbLayout /etc/X11/xorg.conf.d/00-keyboard.conf
    pacman -Q calamares cachyos-calamares-config 2>&1 | tail -2; ls /boot; ls /usr/local/bin
    echo "LIVEUSER=$(id liveuser >/dev/null 2>&1 && echo yes || echo no)"
    cat /etc/sudoers.d/* 2>/dev/null | grep -v '^#'
    findmnt /boot/efi >/dev/null && echo "ESP_MOUNTED" || echo "ESP_NOT_MOUNTED"
}

case "$S" in
@)
    echo "SERPANTINUM booted ($(uname -r))"
    case "$P" in
    install)
        for t in canos-install-subvol canos-reset-public canos-grub-entries; do get $t; done
        canos-install-subvol -y -i /dev/sr0 -u alex -f "Alex Test" -p canos123 -H canos-privat canos-privat >/run/i1.log 2>&1
        echo "PRIVAT_RC=$?"; tail -6 /run/i1.log
        canos-install-subvol -y -i /dev/sr0 -u alex -f "Alex Test" -p canos123 -H canos-public canos-public >/run/i2.log 2>&1
        echo "PUBLIC_RC=$?"; tail -6 /run/i2.log
        # test hook into both CanOS systems (before the clean snapshot)
        top
        for s in canos-privat canos-public; do
            cp /etc/systemd/system/vmcheck.service /run/top/@$s/etc/systemd/system/
            ln -sf /etc/systemd/system/vmcheck.service /run/top/@$s/etc/systemd/system/multi-user.target.wants/vmcheck.service
        done
        umount /run/top
        canos-grub-entries -r Serpantinum; echo "GRUB_RC=$?"
        canos-reset-public --snapshot; echo "SNAP_RC=$?"
        ;;
    reset)
        get canos-reset-public
        canos-reset-public -y; echo "RESET_RC=$?"
        ;;
    esac
    top
    btrfs subvolume list / | awk '{print $NF}' | tr '\n' ' '; echo
    btrfs subvolume show /run/top/@canos-public-clean 2>/dev/null | grep -i flags
    grep -E "^(menuentry|submenu) " /boot/grub/grub.cfg | sed "s/^\(menuentry\|submenu\) '\([^']*\)'.*/MENU: \2/"
    # menu position as GRUB shows it (top-level entries incl. those inside if-blocks, not inside submenus)
    awk '/^submenu /{print "TOP: " $0; sub_=1; next} sub_ && /^}/{sub_=0; next} !sub_ && /^[ \t]*menuentry /{print "TOP: " $0}' /boot/grub/grub.cfg \
      | awk "/'CanOS Privat'/{print \"IDX_PRIVAT=\" NR-1} /'CanOS Public'/{print \"IDX_PUBLIC=\" NR-1}"
    sed -n '/BEGIN CanOS/,/END CanOS/p' /etc/grub.d/40_custom | grep -E "linux|initrd|search"
    grep DISTRIBUTOR /etc/default/grub; ls /etc/default/grub* /etc/grub.d/40_custom*
    sha256sum /boot/efi/EFI/Microsoft/Boot/bootmgfw.efi; efibootmgr | grep -iE "^Boot(Order|0)"
    df -h / | tail -1; btrfs filesystem du -s --human-readable /run/top/@* 2>/dev/null | tail -12
    umount /run/top 2>/dev/null
    post < $O
    sleep 2; poweroff
    ;;
@canos-privat)
    canoscheck; post < $O
    waitcanvas
    ;;
@canos-public)
    canoscheck
    curl -sf $H/canos-reset-public -o /run/crp && chmod +x /run/crp && { /run/crp -y; echo "RESET_FROM_PUBLIC_RC=$?"; }
    post < $O
    waitcanvas
    if [ "$P" = pub1 ]; then   # simulate usage
        sed -i 's/"welcomeDone": *false/"welcomeDone": true/' /home/alex/.config/canvas/settings.json 2>/dev/null
        touch /home/alex/used-marker /etc/canos-used; chown alex: /home/alex/used-marker; sync
        echo "##### usage simulated" | post
    fi
    ;;
*)
    post < $O
    ;;
esac
