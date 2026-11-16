#!/bin/bash
# Builds cachyos-calamares-next in a clean chroot (does not touch the host system).
set -e
base="$HOME/CanOS/pkg"
src="$base/CachyOS-PKGBUILDS/cachyos-calamares"
root="$base/chroot"
deps=$(bash -c "source '$src/PKGBUILD'; echo \${depends[@]} \${makedepends[@]}")
if [ ! -d "$root/usr" ]; then
    sudo mkdir -p "$root"
    sudo pacstrap -c -C "$HOME/CanOS/iso/archiso/pacman.conf" "$root" base base-devel git $deps
fi
# build for every x86-64 CPU, not just this laptop (-march=native broke the installer on other PCs)
sudo sed -i -E 's/-march=[a-z0-9-]*/-march=x86-64/; s/-mtune=[a-z0-9-]*/-mtune=generic/; s/ -O3 / -O2 /' "$root/etc/makepkg.conf"
sudo arch-chroot "$root" bash -c "id builder >/dev/null 2>&1 || useradd -m builder"
sudo rm -rf "$root/home/builder/calamares"
sudo cp -r "$src" "$root/home/builder/calamares"
sudo arch-chroot "$root" chown -R builder: /home/builder/calamares
sudo arch-chroot "$root" su builder -c "cd ~/calamares && makepkg --noconfirm --nocheck"
mkdir -p "$base/repo"
cp "$root"/home/builder/calamares/*.pkg.tar.zst "$base/repo/"
repo-add -q "$base/repo/canos-local.db.tar.gz" "$base/repo/"*.pkg.tar.zst
ls -la "$base/repo"
