# Brooke Classic for Plasma 6 — first pass

Install CachyOS with **KDE Plasma** selected. Log into Plasma and run this
separate theme installer as your regular user. Do not run the repository's
main `install.sh` just to install this theme: that provisions the Hyprland
system and login manager.

```bash
sudo pacman -Syu --needed git python github-cli fontconfig
# First install only:
git clone --branch brooke/desktop-first-pass https://github.com/grapes7000/Arch-WM-install.git
cd Arch-WM-install
gh auth login
python scripts/install-brooke-kde.py --apply
```

For an existing checkout, switch to `brooke/desktop-first-pass` and pull first.
The GitHub account must have access to the private `grapes7000/brooke-assets`
repo. No API token is written into this repository. `--assets-dir PATH` can use
an existing private checkout instead.

`--apply` installs AND applies the Global Theme, including replacing the Plasma
panel layout. It backs up the affected files first and prints their directory.
Without `--apply`, it installs the package for selection in System Settings;
when applying it there, include the desktop layout to get the panels/wallpaper.

## Appearance

- Exact exported wallpaper, Chicago95 icons, BrookeCursor-48 and original fonts
  fetched from the pinned, checksum-verified private appearance archive.
- Hot pink/fuchsia selection and title bars; charcoal app views; gray controls.
- Original Chicago95-PinkPanel styling for GTK apps.
- Custom opaque panel frame embedding the original exported bar texture, with square beveled edges.
- Top panel: trash, clock and system tray (network, audio, battery, etc.).
- Bottom panel: star launcher, exported application launchers plus running apps, pager and show desktop. Missing applications are reported and omitted until installed.
- Standard Breeze window decorations with minimize/maximize/close buttons.
- One panel pair on Plasma's default screen; wallpaper on all desktops.

This is an adaptation, not an exact recreation of XFCE's window decorations or
of every Quickshell interaction. Qt apps use Breeze with the Brooke palette;
GTK apps use the original GTK theme. Plasma may enforce a minimum panel height
larger than the requested 29/41 pixels depending on scale and widget size.

This installer does not change the login manager, install a compositor, modify
Hyprland configuration, install Krita resources, or include QuickShape. When
both desktop sessions are installed, session selection belongs to the login
manager. Use the full installer below if you also want Arch-WM's ReGreet login screen.

## Recovery

Close applications and log out of Plasma. From a TTY, restore the printed backup:

```bash
python scripts/install-brooke-kde.py --rollback /path/printed/by/installer
```

Log back in. Restoring an older backup also restores the settings as they were
at that time. Rerunning the installer makes a new backup rather than replacing
previous backups. Private asset checkout is retained as a cache.

## Validation

Metadata, SVG frame IDs, JavaScript layout execution with a mock Plasma API,
and file backup/restore tests pass. A graphical Plasma 6/CachyOS run has **not**
been performed in this development environment. Test this first pass on the
new installation before treating it as finished.

Developer references:
- https://develop.kde.org/docs/plasma/theme/theme-porting-to-plasma6/
- https://develop.kde.org/docs/plasma/scripting/api/
- https://develop.kde.org/docs/plasma/theme/theme-details/

## Install Hyprland alongside Plasma, using Arch-WM's login screen

From this checkout, run:

```bash
git pull --ff-only
bash install.sh
python scripts/install-brooke-kde.py --apply
```

The full installer installs Hyprland/Quickshell and switches the login manager
to Arch-WM's ReGreet. It does not uninstall Plasma. Reboot, then choose either
Plasma or Hyprland from ReGreet's session selection before logging in. Running
the Plasma theme installer afterward reapplies the shared GTK appearance and
adds launchers for applications newly installed by the full installer.

Session identity is now supplied by the selected session, rather than a global
user environment file labeling Plasma as Hyprland. Log out/reboot after updating
so the old environment is replaced. Do not use --resume to skip these repairs.
