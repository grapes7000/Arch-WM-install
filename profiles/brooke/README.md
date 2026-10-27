# Brooke: fresh CachyOS/Arch installation

Install CachyOS with **no desktop selected**. Log into the installed system as a normal sudo-enabled user, take a VM snapshot, then run:

```sh
sudo pacman -Syu --needed git python
git clone --branch brooke/desktop-first-pass https://github.com/grapes7000/Arch-WM-install.git
cd Arch-WM-install
bash install.sh
```

This branch defaults to the complete `brooke` profile. No separate base-desktop or overlay installation is required. The installer handles packages, the existing standalone theme engine, Hyprland, Quickshell, GTK styling, fonts/icons/cursors, wallpaper, Dunst, services, and the ReGreet login screen. After successful installation, reboot and choose Hyprland at login.

It downloads assets from **grapes7000/brooke-assets**, a private repo. The first run prompts for GitHub CLI authentication if needed; complete the device-code sign-in using a browser on another device if the VM has no browser yet. No token is embedded in this repo. The private commit and SHA-256 are pinned in `assets-lock.json`. Payload parts are reassembled and verified before extraction.

The original Mint computer and export directory are not required. The original profiles remain available explicitly, e.g. `bash install.sh --profile desktop`. Brooke does not require an AUR helper or the boyfriend's SSH-only dotfiles repo. It requires Hyprland 0.55+ for the existing Lua configuration; config validation runs before the login manager is enabled.

Other entrypoints:

```sh
bash install.sh --dry-run
bash install.sh --noninteractive                  # requires existing GitHub authentication
bash install.sh --assets-dir /path/to/brooke-assets
bash install.sh doctor --profile brooke
```

## What to test

- Exported wallpaper, striped 29px/41px bars, classic buttons and bottom-left application launcher.
- Launcher search, favorites, running-app buttons, four star workspaces and screenshot capture.
- Clock, battery/AC indication, tray menus, volume and music drawer.
- Floating windows, dialogs, maximize and the shared minimize/restore/close controls.
- Chicago95 GTK styling, Brooke cursors, BlackChancery/DOS fonts, and Krita's BrookiePink color scheme.
- Lock/unlock, reboot, a second installer run, and rollback.

The existing `arch-wm` shell name is retained, so autostart and launcher/brightness IPC use the same configuration. Wallpaper, notifications and the shell each have one configured startup process.

## Rollback

From a TTY in the VM:

```sh
cd Arch-WM-install
bash uninstall.sh --profile brooke
```

The base installer's ownership/backups restore replaced files and remove created payloads and enabled services. Packages remain unless `--remove-packages` is passed. Back up later manual edits before uninstalling. A VM snapshot is the easiest complete reset.

## First-pass limits

Classic per-window titlebars still need implementation: Hyprland cannot reuse XFWM decorations. The shared control panel is a fallback, and minimize/restore uses a shared special workspace. The pet, BrookeEyes, swipe keyboard, Wayland tablet helpers, and customization app are not implemented yet.

Unsupported source-machine shortcuts stay disabled; other optional shortcuts need their apps installed. The first install includes Thunar, Firefox, Kitty and Krita, rather than every app from the source computer. Krita receives its private color scheme/minimal font settings; brushes, executable plugins, tablet mappings and QuickShape remain in the original export for a later migration.

Exact XFCE spacers/pager placement, native Qt application styling and font rendering still need visual refinement. Existing theme switching can replace Brooke's palette; rerunning the Brooke profile restores its appearance contract.

**Actual CachyOS graphical boot is not verified yet.** The development rehearsal tested file installation and rollback with external package/service/config-validation commands mocked. The real installer performs those checks on the VM.

`scripts/brooke-profile.py` is the earlier optional export-inspection/import utility; it is not needed for this fresh-install workflow.
