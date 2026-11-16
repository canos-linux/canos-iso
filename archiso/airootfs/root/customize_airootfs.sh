#!/bin/bash
# CanOS: replace the calamares package default (limine) with the CanOS bootloader config (GRUB).
# Shipping it directly in airootfs conflicts with the package file during pacstrap.
install -m644 /etc/calamares/modules/bootloader_canos.conf /etc/calamares/modules/bootloader.conf
