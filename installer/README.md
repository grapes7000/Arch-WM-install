# Installer Framework

Implement stage modules here. Keep `install.sh` and `uninstall.sh` as thin argument-parsing entrypoints.

Recommended Python package layout:

```text
installer/
├── cli.py
├── context.py
├── state.py
├── backup.py
├── packages.py
├── managed_files.py
├── stages/
│   ├── preflight.py
│   ├── repositories.py
│   ├── packages.py
│   ├── theme_engine.py
│   ├── hyprland.py
│   ├── quickshell.py
│   ├── services.py
│   ├── session.py
│   └── validate.py
└── rollback.py
```

Every stage exposes `check`, `apply`, `verify` and `rollback` operations and writes structured state.
