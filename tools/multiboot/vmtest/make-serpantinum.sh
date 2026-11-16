#!/bin/bash
# Runs in the CanOS live VM (as root): rebuilds Serkan's laptop layout on /dev/vda
# (GPT, ESP p1, placeholders p2-p4 like Windows, Btrfs p5 with @ @home @root @srv @cache @log @tmp)
# and pacstraps a minimal CachyOS "Serpantinum" with GRUB (\EFI\cachyos, GRUB_DISTRIBUTOR=CanOS).
exec > /tmp/serp.log 2>&1
set -ex
D=/dev/vda
post() { curl -s --data-binary @- 10.0.2.2:8766 >/dev/null || true; }
trap 'echo "##### make-serpantinum FAILED line $LINENO"; tail -25 /tmp/serp.log | post' ERR

wipefs -af $D; sgdisk -Z $D
sgdisk -n1:0:+260M -t1:ef00 -c1:EFI -n2:0:+16M -t2:0c01 -c2:MSR -n3:0:+2G -t3:0700 -c3:Windows \
       -n4:0:+512M -t4:2700 -c4:Recovery -n5:0:0 -t5:8300 -c5:linux $D
partprobe $D; udevadm settle; sleep 2
mkfs.fat -F32 -n EFI ${D}1
mkfs.btrfs -f -L linux ${D}5
mount ${D}5 /mnt
for s in @ @home @root @srv @cache @log @tmp; do btrfs subvolume create /mnt/$s; done
umount /mnt
o=noatime,compress=zstd:1
mount -o subvol=/@,$o ${D}5 /mnt
mkdir -p /mnt/{home,root,srv,var/cache,var/log,var/tmp,boot/efi}
mount -o subvol=/@home,$o ${D}5 /mnt/home
mount -o subvol=/@root,$o ${D}5 /mnt/root
mount -o subvol=/@srv,$o ${D}5 /mnt/srv
mount -o subvol=/@cache,$o ${D}5 /mnt/var/cache
mount -o subvol=/@log,$o ${D}5 /mnt/var/log
mount -o subvol=/@tmp,$o ${D}5 /mnt/var/tmp
mount -o umask=0077 ${D}1 /mnt/boot/efi
# fake Windows boot files (must stay untouched)
mkdir -p /mnt/boot/efi/EFI/Microsoft/Boot
echo "fake windows bootmgr" > /mnt/boot/efi/EFI/Microsoft/Boot/bootmgfw.efi

pacstrap /mnt base linux-cachyos mkinitcpio btrfs-progs grub efibootmgr sudo squashfs-tools arch-install-scripts nano
genfstab -U /mnt > /mnt/etc/fstab

cat > /mnt/root/setup.sh <<'EOF'
set -ex
ln -sf /usr/share/zoneinfo/Europe/Vienna /etc/localtime
sed -i 's/^#\(de_AT.UTF-8 UTF-8\)/\1/; s/^#\(en_US.UTF-8 UTF-8\)/\1/' /etc/locale.gen
locale-gen
echo LANG=de_AT.UTF-8 > /etc/locale.conf
echo KEYMAP=us > /etc/vconsole.conf
echo serpantinum > /etc/hostname
useradd -m -G wheel -s /bin/bash serkan
echo serkan:serkan123 | chpasswd
echo root:serkan123 | chpasswd
echo "%wheel ALL=(ALL:ALL) ALL" > /etc/sudoers.d/10-wheel
mkdir -p /home/serkan/.config/canvas && echo '{}' > /home/serkan/.config/canvas/private.json
chown -R serkan: /home/serkan
printf '[Match]\nName=en*\n[Network]\nDHCP=yes\n' > /etc/systemd/network/20-wired.network
systemctl enable systemd-networkd systemd-resolved vmcheck.service
sed -i -e 's/^GRUB_DISTRIBUTOR=.*/GRUB_DISTRIBUTOR="CanOS"/' -e 's/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=10/' \
       -e "s/^GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT='nowatchdog nvme_load=YES splash loglevel=3'/" /etc/default/grub
grep -q '^GRUB_DISTRIBUTOR=' /etc/default/grub || echo 'GRUB_DISTRIBUTOR="CanOS"' >> /etc/default/grub
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=cachyos
grub-mkconfig -o /boot/grub/grub.cfg
EOF

# test hook (VM only): fetch and run the multi test script at every boot
cat > /mnt/etc/systemd/system/vmcheck.service <<'EOF'
[Unit]
Description=CanOS VM test hook
After=network-online.target
Wants=network-online.target
[Service]
Type=simple
ExecStart=/bin/bash -c 'for i in $(seq 90); do curl -sf 10.0.2.2:8766/multi-guest.sh -o /run/mg.sh && break; sleep 2; done; bash /run/mg.sh'
[Install]
WantedBy=multi-user.target
EOF
arch-chroot /mnt bash /root/setup.sh
rm /mnt/root/setup.sh
umount -R /mnt
{ echo "##### make-serpantinum OK"; lsblk -o NAME,SIZE,FSTYPE,PARTLABEL $D; efibootmgr; } | post
poweroff
