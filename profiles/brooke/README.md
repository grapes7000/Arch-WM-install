# Brooke desktop — first development pass

An opt-in shell profile for `brooke/desktop-first-pass`, based on Brooke's XFCE customization export. The normal shell entrypoint remains unchanged. Personal wallpaper, icons, fonts and Krita resources are imported locally; none are published in this repository.

## Implemented

- Separate `modules/shell/brooke.qml` entrypoint using existing launcher, drawer, audio, tray, battery and lock-state services.
- Full-width 29px top and 41px bottom layer-shell bars with the exported stripe texture, square beveled buttons, trash, DOS-style clock, audio, tray, music drawer and launchers.
- Captured launcher order and custom imagery imported from XFCE XML/desktop files. Browser-profile arguments and source-machine commands are replaced with reviewed portable mappings. Unsupported shortcuts remain visible but disabled.
- Scrollable launcher strip for smaller VM displays, running-app groups (click repeatedly to cycle windows), four star workspaces, region screenshot button.
- Existing application search/categories/favorites launcher positioned at bottom left (600 × 500 maximum, intentionally larger than Whisker to fit the existing launcher controls).
- Floating-first Lua fragment and shared window controls: arrange, minimize to a special workspace, restore that workspace, maximize and close.
- Pink/black palette and BlackChancery typography using the shared theme contract; the base profile continues to default to Inter.
- Optional isolated Krita resource/config staging with the source-machine ResourceDirectory override removed. Python plugins and ABI-specific binaries are not activated.
- Dry-run importer, content-based no-op updates, per-file backups, pre-write journal, destination traversal/symlink checks, and rollback that preserves later edits.

## CachyOS VM setup

Take a VM snapshot and copy the complete private export directory into the VM. The export must contain `assets/rootfs`, not just the Markdown reports.

```sh
git clone --branch brooke/desktop-first-pass https://github.com/grapes7000/Arch-WM-install.git
cd Arch-WM-install
```

First get the base repository's Hyprland/Quickshell session working using its installer instructions. CachyOS compatibility and current Hyprland syntax still need a VM acceptance run. This overlay does not install packages, create a login session, change the bootloader, or enable services.

Requirements in the VM: the base shell dependencies, Thunar/GIO, the Chicago95 theme's GTK engines where required, Adwaita fallback icons, fontconfig, hyprshot, hyprpaper and Dunst. Application shortcuts require their applications to be installed. Do not install every source-machine application automatically.

Dry-run (replace the example export path):

```sh
python3 scripts/brooke-profile.py --export "$HOME/brooke-desktop-export"
```

Install the profile only inside the test VM:

```sh
python3 scripts/brooke-profile.py --export "$HOME/brooke-desktop-export" --apply --krita
fc-cache -f
```

The importer prints its exact backup/journal directory. It installs a separate shell under `~/.config/quickshell/brooke`, assets under `~/.local/share/brooke-desktop`, GTK appearance settings, and the two shared generated theme JSON files. These writes can affect the VM's other desktop sessions; use the snapshot and rollback below.

Validate the QML on the VM with Qt's `qmllint` and the installed Quickshell import paths before making it the login default. This build has NOT been rendered or accepted on a running Hyprland VM yet.

For the repo's Lua-based Hyprland version, append this line **after existing rules** in the VM's local configuration:

```lua
dofile(os.getenv("HOME") .. "/.config/hypr/brooke.lua")
```

If the VM uses the older `.conf` syntax, do not source Lua from it. Use a compatible base version or translate the fragment after checking that installed version. Keep this manual line recorded: importer rollback does not edit the base Hyprland configuration.

Stop the base shell process in the VM before running the Brooke entrypoint; do not leave two bars/tray hosts running. Then launch from a terminal inside Hyprland:

```sh
env QT_QUICK_CONTROLS_STYLE=Basic GTK_THEME=Chicago95-PinkPanel \
  XCURSOR_THEME=BrookeCursor XCURSOR_SIZE=32 \
  quickshell -p "$HOME/.config/quickshell/brooke"
```

Set the active icon theme to Chicago95 with the VM's appearance tool. The exported cursor assets are installed, but the current Hyprland cursor may additionally need setting in that session. Native Qt clients need their own theme integration; setting GTK_THEME does not theme them.

Use the generated `~/.local/share/brooke-desktop/hyprpaper.conf` with the VM's single hyprpaper process, and `~/.local/share/brooke-desktop/dunstrc` with its single Dunst process. Do not run competing wallpaper/notification daemons. No existing daemon is stopped or reconfigured automatically by the importer.

After the first successful interactive run, change the VM's Quickshell autostart path to the Brooke entrypoint. Keep the original path to revert. Avoid running the base installer over the overlay without checking whether it regenerates the shared theme files.

## Isolated Krita test

With `--krita`, resources are staged separately; the normal Krita profile remains untouched. Test with:

```sh
XDG_CONFIG_HOME="$HOME/.local/share/brooke-desktop/krita-test/config" \
XDG_DATA_HOME="$HOME/.local/share/brooke-desktop/krita-test/share" krita
```

The initial port omits executable plugins, QuickShape binaries, caches and X11 input helpers. BrookiePink/resources may depend on the installed Krita version. This is a resource migration test, not a validated tablet or plugin port.

## VM acceptance checklist

- Compare against the export screenshots at 1920 × 1200, then a smaller VM resolution.
- Both bars visible, correct texture/heights; top reserves space, bottom intentionally permits underlap.
- Wallpaper imagery remains one background, with no fake app windows created over it.
- Launcher opens at bottom left, searches, launches, saves favorites, and closes with Escape/outside click.
- Task buttons focus/cycle windows; star workspaces switch; screenshot saves successfully.
- Clock seconds tick; battery handles a VM with no battery; volume, media and tray menus work.
- Floating applications, dialogs and fullscreen behave sensibly; window-control minimize/restore tested with multiple windows.
- Lock with Hyprlock: bars, menus and controls disappear; input cannot invoke actions while locked.
- GTK fonts/icons/cursors and Krita resources compare with reference captures.
- Import twice: second import reports zero changes. Rollback restores prior files.

## Rollback

Stop the Brooke shell, restore the original Quickshell autostart, remove the manually added `dofile` line, and restore the VM's wallpaper/Dunst launch configuration. Then use the directory printed by the importer (the directory containing `journal.jsonl`):

```sh
python3 scripts/brooke-profile.py --rollback "$HOME/.local/state/brooke-desktop/PRINTED_TIMESTAMP"
```

Files changed since import are skipped rather than overwritten. Packages and empty directories are not removed. A VM snapshot is the fastest complete reset.

## Still to build / validate

- **Per-window classic titlebars and their buttons.** Hyprland does not reuse XFWM decorations. The shared control panel is a functional fallback, not a replacement for Brooke's requested titlebars. Minimize/restore currently groups hidden windows in a special workspace rather than implementing conventional per-window minimization.
- Exact XFCE spacers, launcher separators, pager location and pixel-level typography; current composition is a close first layout, not a pixel-perfect recreation.
- BrookeEyes/desktop pet, swipe keyboard and Wayland tablet helpers. No X11 helper or privileged service is imported or executed.
- A visual customization app and named saved-look selector. Existing theme switching remains available, but can overwrite the Brooke palette; JSON edits are the first-pass controls.
- Missing Artemis/Meshmixer/custom-helper launch mappings, installed-app availability detection, and native Qt application styling.
- Expand the bar layout editor beyond the current JSON-driven two-panel arrangement. Both panels use the existing widget registry and capability-filtered WidgetHost.
- Full clean-VM QML/render, login, reboot, lock, resume and rollback acceptance. No claim of runtime validation is made by the importer tests.
