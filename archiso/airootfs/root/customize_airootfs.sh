#!/bin/bash
# CanOS: replace the calamares package default (limine) with the CanOS bootloader config (GRUB).
# Shipping it directly in airootfs conflicts with the package file during pacstrap.
install -m644 /etc/calamares/modules/bootloader_canos.conf /etc/calamares/modules/bootloader.conf
# CanOS: unlock gnome-keyring at login (browsers, apps store passwords there)
if ! grep -q pam_gnome_keyring /etc/pam.d/greetd; then
  sed -i "/^auth.*include.*system-local-login/a auth       optional     pam_gnome_keyring.so" /etc/pam.d/greetd
  echo "session    optional     pam_gnome_keyring.so auto_start" >> /etc/pam.d/greetd
fi
