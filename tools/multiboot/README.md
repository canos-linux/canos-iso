# CanOS multi-install (subvolumes)

Install CanOS next to an existing Btrfs system without new partitions:
each install gets its own subvolume pair `@<name>` + `@<name>-home`,
booted through extra entries in the GRUB of the main system.

| Script | What it does |
|---|---|
| `canos-install-subvol` | Unpacks `airootfs.sfs` from the ISO into `@<name>` and runs the same steps as the Calamares installer (canospre, machine-id, fstab, locale, keyboard, initramfs, user, greeter, remove live packages). Never touches partitions, ESP or bootloader. |
| `canos-grub-entries` | Writes the CanOS entries into `/etc/grub.d/40_custom` (between `### BEGIN/END CanOS`), optionally sets `GRUB_DISTRIBUTOR` (`-r Serpantinum`), runs `grub-mkconfig`. Backups: `*.canos-bak`. `--remove` takes the entries out again. |
| `canos-reset-public` | `--snapshot`: read-only snapshots `@canos-public-clean` / `@canos-public-home-clean`. Without option: deletes `@canos-public(-home)` and recreates them from the clean snapshots. Refuses to run inside CanOS Public. |

Typical run (from the main system, ISO file downloaded):

```sh
sudo ./canos-install-subvol -i canos.iso -u <user> canos-privat
sudo ./canos-install-subvol -i canos.iso -u alex canos-public
sudo ./canos-grub-entries -r Serpantinum
sudo ./canos-reset-public --snapshot     # before the first login into CanOS Public
```

`vmtest/` holds the VM test (`multitest.sh`): it rebuilds the laptop layout,
runs all three scripts from the main system and boots every entry.
