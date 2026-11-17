#!/bin/bash
# CanOS: replace the calamares package default (limine) with the CanOS bootloader config (GRUB).
# Shipping it directly in airootfs conflicts with the package file during pacstrap.
install -m644 /etc/calamares/modules/bootloader_canos.conf /etc/calamares/modules/bootloader.conf
# CanOS: ESP on /boot/efi (works with small Windows ESPs), hostname default "canos"
install -m644 /etc/calamares/modules/partition_canos.conf /etc/calamares/modules/partition.conf
install -m644 /etc/calamares/modules/users_canos.conf /etc/calamares/modules/users.conf
# CanOS: locales for both Canvas languages (fixes "setlocale: cannot change locale")
sed -i -E 's/^#\s*(en_US\.UTF-8 UTF-8|de_AT\.UTF-8 UTF-8|de_DE\.UTF-8 UTF-8)/\1/' /etc/locale.gen
locale-gen
# CanOS: canos-fetch as fish greeting (file belongs to cachyos-fish-config, so it can't ship in airootfs)
if [ -f /etc/skel/.config/fish/config.fish ]; then
  cat > /etc/skel/.config/fish/config.fish <<'FISH'
source /usr/share/cachyos-fish-config/cachyos-config.fish

# CanOS: system info when a terminal opens (canos-fetch --full shows everything)
function fish_greeting
    if command -q canos-fetch
        canos-fetch
    else
        fastfetch
    end
end
FISH
fi
# CanOS: unlock gnome-keyring at login (browsers, apps store passwords there)
if ! grep -q pam_gnome_keyring /etc/pam.d/greetd; then
  sed -i "/^auth.*include.*system-local-login/a auth       optional     pam_gnome_keyring.so" /etc/pam.d/greetd
  echo "session    optional     pam_gnome_keyring.so auto_start" >> /etc/pam.d/greetd
fi
