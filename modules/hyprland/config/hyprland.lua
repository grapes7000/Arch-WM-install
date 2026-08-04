-- Arch WM modular Hyprland configuration.
-- Machine-specific overrides belong in conf/local.lua.

archwm = archwm or {}

require("conf.env")
require("conf.monitors")
require("conf.defaults")
pcall(require, "generated.theme")
require("conf.input")
require("conf.behavior")
require("conf.windowrules")
require("conf.keybinds")
require("conf.autostart")
pcall(require, "conf.local")
