-- Keyboard layout follows the installer (/etc/X11/xorg.conf.d/00-keyboard.conf), default: us
local function xkb(key, fallback)
  local ok, value = pcall(function()
    local f = io.open("/etc/X11/xorg.conf.d/00-keyboard.conf", "r")
    if not f then return nil end
    local s = f:read("*a")
    f:close()
    return s:match('Option%s+"' .. key .. '"%s+"([^"]*)"')
  end)
  if ok and value and value ~= "" then return value end
  return fallback
end

hl.config({
  general = {
    border_size = 2,
    gaps_in = 6,
    gaps_out = 12,
    resize_on_border = true,
    col = {
      active_border = { colors = { "rgba(b9a4ffee)", "rgba(7a5cffee)" }, angle = 45 },
      inactive_border = "rgba(1d1a2655)",
    },
  },
  decoration = {
    rounding = 14,
    active_opacity = 0.96,
    inactive_opacity = 0.9,
    blur = {
      enabled = true,
      size = 8,
      passes = 2,
      new_optimizations = true,
    },
    shadow = {
      enabled = true,
    },
  },
  input = {
    kb_layout = xkb("XkbLayout", "us"),
    kb_variant = xkb("XkbVariant", ""),
    kb_options = "grp:alt_shift_toggle",
    touchpad = {
      natural_scroll = true,
      disable_while_typing = true,
    },
  },
  ecosystem = {
    no_update_news = true,
    no_donation_nag = true,
  },
  misc = {
    disable_hyprland_logo = true,
    disable_splash_rendering = true,
    focus_on_activate = true,
  },
})

hl.curve("smooth", { type = "bezier", points = { {0.25, 1}, {0.5, 1} } })
hl.curve("pop", { type = "bezier", points = { {0.34, 1.56}, {0.64, 1} } })
hl.animation({ leaf = "windows", enabled = true, speed = 4, bezier = "pop", style = "popin 80%" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 4, bezier = "smooth", style = "slide" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 5, bezier = "smooth", style = "slide" })
hl.animation({ leaf = "fade", enabled = true, speed = 4, bezier = "smooth" })
hl.animation({ leaf = "border", enabled = true, speed = 8, bezier = "smooth" })
hl.animation({ leaf = "borderangle", enabled = true, speed = 60, bezier = "smooth", style = "loop" })

hl.layer_rule({ name = "canvas-blur", match = { namespace = "canvas" }, blur = true, ignore_alpha = 0.2 })
hl.window_rule({ name = "canvas-windows", match = { class = "org.quickshell" }, float = true, center = true })
hl.window_rule({ name = "calamares", match = { class = ".*[Cc]alamares.*" }, float = true, size = "1100 720", center = true })
hl.window_rule({ name = "pavucontrol", match = { class = "org.pulseaudio.pavucontrol" }, float = true, size = "800 520", center = true })
