# CanOS

**Yes, I CanOS.** – A fast, beautiful Linux system with its own desktop, [Canvas](https://github.com/canos-linux/canvas).

Website: **https://canos-linux.github.io/**

CanOS is based on [CachyOS](https://cachyos.org) and [Arch Linux](https://archlinux.org). This repository builds the CanOS live ISO with an offline Calamares installer.

## Download

The current ISO (`canos-1.0-x86_64.iso`) and its SHA256 checksum are linked on the website and in the GitHub releases.

## Build

On an Arch-based system with `archiso`:

```
./canos-prepare.sh          # copies Canvas into the live system
sudo ./buildiso.sh -p desktop -w
```

The ISO ends up in `out/desktop/`.

## What's inside

- Canvas desktop on Hyprland, own greeter, GRUB theme and Calamares branding
- CachyOS kernel (+ LTS), NVIDIA drivers kept only on NVIDIA machines
- Firefox, Nautilus, Text Editor, Loupe, Celluloid, Papers, Calculator, kitty
- `canos-update` (system + Flatpak updates)
- `tools/multiboot/` – install CanOS next to another Linux on Btrfs subvolumes, with Secure Boot and a resettable public system

## Credits

CanOS stands on the shoulders of the [CachyOS live ISO](https://github.com/CachyOS/CachyOS-Live-ISO) and its team, Arch Linux, Hyprland, Quickshell and Calamares. Thank you!

## License

GPL-3.0 – see [LICENSE](LICENSE).
