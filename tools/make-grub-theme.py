#!/usr/bin/env python3
"""Builds the CanOS GRUB theme (archiso/grub/themes/canos) from the Calamares ring logo."""
import os, subprocess
from PIL import Image, ImageDraw

A = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "archiso")
OUT = os.path.join(A, "grub", "themes", "canos")
LOGO = os.path.join(A, "airootfs/usr/share/calamares/branding/canos/welcome.png")
FONT = os.path.join(A, "airootfs/usr/share/fonts/TTF/GoogleSansFlex.ttf")
BG, ACC = (15, 13, 18), (205, 189, 255)
os.makedirs(OUT, exist_ok=True)

img = Image.new("RGB", (1920, 1080), BG)
logo = Image.open(LOGO).convert("RGBA").resize((220, 220), Image.LANCZOS)
img.paste(logo, ((1920 - 220) // 2, 170), logo)
img.save(os.path.join(OUT, "background.png"))

sel = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
ImageDraw.Draw(sel).rectangle((0, 0, 15, 15), fill=ACC + (40,))
sel.save(os.path.join(OUT, "select_c.png"))

for size in (16, 20, 28):
    subprocess.run(["grub-mkfont", "-s", str(size), "-n", "Canvas Sans", "-o",
                    os.path.join(OUT, f"canvas_{size}.pf2"), FONT], check=True)

open(os.path.join(OUT, "theme.txt"), "w").write("""# CanOS GRUB theme
desktop-image: "background.png"
desktop-color: "#0f0d12"
title-text: ""
message-font: "Canvas Sans Regular 16"
message-color: "#8a8494"
terminal-font: "Canvas Sans Regular 16"

+ label {
    top = 39%
    left = 0
    width = 100%
    align = "center"
    text = "CanOS"
    font = "Canvas Sans Regular 28"
    color = "#cdbdff"
}

+ boot_menu {
    left = 50%-300
    top = 46%
    width = 600
    height = 44%
    item_font = "Canvas Sans Regular 20"
    selected_item_font = "Canvas Sans Regular 20"
    item_color = "#8a8494"
    selected_item_color = "#cdbdff"
    selected_item_pixmap_style = "select_*.png"
    item_height = 40
    item_padding = 16
    item_spacing = 6
    icon_width = 0
    icon_height = 0
    scrollbar = false
}

+ label {
    id = "__timeout__"
    top = 100%-50
    left = 0
    width = 100%
    align = "center"
    font = "Canvas Sans Regular 16"
    color = "#8a8494"
    text = "Booting in %d s"
}
""")
import shutil
SYS = os.path.join(A, "airootfs/usr/share/grub/themes/canos")
shutil.rmtree(SYS, ignore_errors=True)
shutil.copytree(OUT, SYS)
print("ok", OUT, SYS)
