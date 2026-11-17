#!/usr/bin/env python3
"""Builds the CanOS GRUB theme (archiso/grub/themes/canos + airootfs copy for installed systems).
Dark Canvas background with a soft glow, ring "C" logo, rounded selection, icons per entry,
countdown as a thin bar. Fonts (Google Sans Flex as .pf2) are made with grub-mkfont if available."""
import math, os, shutil, subprocess
from PIL import Image, ImageDraw, ImageFilter

A = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "archiso")
OUT = os.path.join(A, "grub", "themes", "canos")
FONT = os.path.join(A, "airootfs/usr/share/fonts/TTF/GoogleSansFlex.ttf")
BG, ACC, SUB = (15, 13, 18), (205, 189, 255), (138, 132, 148)
SS = 4
os.makedirs(OUT, exist_ok=True)


def ring(size, color, width_f=0.075):
    W = size * SS
    im = Image.new("RGBA", (W, W), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    r, c, lw = W * 0.38, W / 2, W * width_f
    a0, a1 = 0.22 * 180, 1.78 * 180
    d.arc([c - r - lw / 2, c - r - lw / 2, c + r + lw / 2, c + r + lw / 2], a0, a1, fill=color, width=int(lw))
    for a in (a0, a1):
        x, y = c + r * math.cos(math.radians(a)), c + r * math.sin(math.radians(a))
        d.ellipse([x - lw / 2, y - lw / 2, x + lw / 2, y + lw / 2], fill=color)
    dr = W * 0.06
    d.ellipse([c + r - dr, c - dr, c + r + dr, c + dr], fill=color)
    return im.resize((size, size), Image.LANCZOS)


# background: dark with a soft accent glow behind the logo
img = Image.new("RGB", (1920, 1080), BG)
glow = Image.new("RGB", (1920, 1080), BG)
ImageDraw.Draw(glow).ellipse((960 - 520, 250 - 330, 960 + 520, 250 + 330), fill=(44, 36, 66))
glow = glow.filter(ImageFilter.GaussianBlur(160))
img = Image.blend(img, glow, 0.85)
logo = ring(150, ACC + (255,))
img.paste(logo, ((1920 - 150) // 2, 150), logo)
img.save(os.path.join(OUT, "background.png"))

# rounded selection (9-slice): corners radius R, edges, center
R = 12
fill = (ACC[0], ACC[1], ACC[2], 46)
full = Image.new("RGBA", (2 * R * SS + SS, 2 * R * SS + SS), (0, 0, 0, 0))
ImageDraw.Draw(full).rounded_rectangle((0, 0, full.width - 1, full.height - 1), radius=R * SS, fill=fill)
full = full.resize((2 * R + 1, 2 * R + 1), Image.LANCZOS)
parts = {
    "nw": (0, 0, R, R), "n": (R, 0, R + 1, R), "ne": (R + 1, 0, 2 * R + 1, R),
    "w": (0, R, R, R + 1), "c": (R, R, R + 1, R + 1), "e": (R + 1, R, 2 * R + 1, R + 1),
    "sw": (0, R + 1, R, 2 * R + 1), "s": (R, R + 1, R + 1, 2 * R + 1), "se": (R + 1, R + 1, 2 * R + 1, 2 * R + 1),
}
for k, box in parts.items():
    full.crop(box).save(os.path.join(OUT, f"select_{k}.png"))

# terminal box while a kernel loads: transparent, so the background stays visible
for k in ("nw", "n", "ne", "w", "c", "e", "sw", "s", "se"):
    Image.new("RGBA", (4, 4), (0, 0, 0, 0)).save(os.path.join(OUT, f"terminal_box_{k}.png"))

# countdown bar
Image.new("RGBA", (8, 4), ACC + (255,)).save(os.path.join(OUT, "bar_c.png"))
Image.new("RGBA", (8, 4), SUB + (60,)).save(os.path.join(OUT, "barbg_c.png"))

# icons (32 px): CanOS ring, Windows panes, firmware gear, generic OS
icons = os.path.join(OUT, "icons")
os.makedirs(icons, exist_ok=True)
I = 32


def icon_canvas():
    return Image.new("RGBA", (I * SS, I * SS), (0, 0, 0, 0))


def save(im, *names):
    im = im.resize((I, I), Image.LANCZOS)
    for n in names:
        im.save(os.path.join(icons, n + ".png"))


save(ring(I * SS, ACC + (255,), 0.11), "canos", "arch")

win = icon_canvas()
d = ImageDraw.Draw(win)
g, s = 3 * SS, (I * SS - 3 * SS) // 2 - 2 * SS
o = 3 * SS
for x in (o, o + s + g):
    for y in (o, o + s + g):
        d.rounded_rectangle((x, y, x + s, y + s), radius=2 * SS, fill=(220, 214, 230, 255))
save(win, "windows")

gear = icon_canvas()
d = ImageDraw.Draw(gear)
c, ro, ri = I * SS / 2, 13 * SS, 9 * SS
for k in range(8):
    a = math.radians(k * 45)
    x, y = c + ro * math.cos(a), c + ro * math.sin(a)
    d.ellipse((x - 3.2 * SS, y - 3.2 * SS, x + 3.2 * SS, y + 3.2 * SS), fill=(220, 214, 230, 255))
d.ellipse((c - ri - 2 * SS, c - ri - 2 * SS, c + ri + 2 * SS, c + ri + 2 * SS), fill=(220, 214, 230, 255))
d.ellipse((c - 4.5 * SS, c - 4.5 * SS, c + 4.5 * SS, c + 4.5 * SS), fill=(0, 0, 0, 0))
save(gear, "efi")

osi = icon_canvas()
d = ImageDraw.Draw(osi)
d.rounded_rectangle((4 * SS, 6 * SS, 28 * SS, 24 * SS), radius=3 * SS, outline=(220, 214, 230, 255), width=3 * SS)
d.rectangle((12 * SS, 26 * SS, 20 * SS, 28 * SS), fill=(220, 214, 230, 255))
save(osi, "os", "memtest")

if shutil.which("grub-mkfont"):
    for size in (16, 20, 28):
        subprocess.run(["grub-mkfont", "-s", str(size), "-n", "Canvas Sans", "-o",
                        os.path.join(OUT, f"canvas_{size}.pf2"), FONT], check=True)

open(os.path.join(OUT, "theme.txt"), "w").write("""# CanOS GRUB theme (tools/make-grub-theme.py)
desktop-image: "background.png"
desktop-color: "#0f0d12"
title-text: ""
message-font: "Canvas Sans Regular 16"
message-color: "#8a8494"
terminal-font: "Canvas Sans Regular 16"
terminal-box: "terminal_box_*.png"
terminal-left: "0"
terminal-top: "100%-2"
terminal-width: "2"
terminal-height: "2"
terminal-border: "0"

+ label {
    top = 29%
    left = 0
    width = 100%
    align = "center"
    text = "CanOS"
    font = "Canvas Sans Regular 28"
    color = "#ece7f2"
}

+ boot_menu {
    left = 50%-310
    top = 38%
    width = 620
    height = 48%
    item_font = "Canvas Sans Regular 20"
    selected_item_font = "Canvas Sans Regular 20"
    item_color = "#8a8494"
    selected_item_color = "#ece7f2"
    selected_item_pixmap_style = "select_*.png"
    item_height = 40
    item_padding = 12
    item_spacing = 26
    icon_width = 28
    icon_height = 28
    item_icon_space = 18
    scrollbar = false
}

+ progress_bar {
    id = "__timeout__"
    left = 50%-150
    top = 100%-70
    width = 300
    height = 4
    show_text = false
    bar_style = "barbg_*.png"
    highlight_style = "bar_*.png"
}

+ label {
    id = "__timeout__"
    top = 100%-56
    left = 0
    width = 100%
    align = "center"
    font = "Canvas Sans Regular 16"
    color = "#6f6879"
    text = "%d"
}
""")
SYS = os.path.join(A, "airootfs/usr/share/grub/themes/canos")
shutil.rmtree(SYS, ignore_errors=True)
shutil.copytree(OUT, SYS)
# canos-tools ships it too, so systems installed from older ISOs get updates
PKG = os.path.join(A, "..", "packaging", "canos-tools", "grub-theme")
shutil.rmtree(PKG, ignore_errors=True)
shutil.copytree(OUT, PKG)
print("ok", OUT, SYS, PKG)
