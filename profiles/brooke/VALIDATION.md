# Validation record

- Full repository Python suite: 142 tests passed (including eight fresh-installer tests and four export-importer tests).
- Four layouts, fourteen widget manifests and generated registry passed validation.
- Real private archive rehearsal in an empty temporary home: 17,258 data files, shell/Hyprland/theme/GTK/wallpaper/Dunst and Krita UI installed; payload checks passed, and tracked rollback removed the managed shell/Hyprland/assets. External commands were mocked.
- All 49 uploaded archive-part Git blob hashes matched the local binary payload. Private commit and SHA-256 are pinned. No asset archive was published to the public repo.
- Earlier export-import rehearsal verified 18,444 files with zero mismatches and a no-op repeat.
- Python compilation passed. Original desktop settings, services and packages were not changed.
- Package installation, GitHub device login, QML compilation, Hyprland config execution, real login/reboot/lock and rendered appearance still require CachyOS VM acceptance.
