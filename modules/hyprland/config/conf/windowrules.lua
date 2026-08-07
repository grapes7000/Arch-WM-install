-- Smart rules keep transient and utility windows predictable without broadly
-- matching normal application windows. Theme appearance stays in theme.json;
-- this file owns compositor behavior only.
hl.window_rule({
    name = "arch-wm-settings-float",
    match = {
        class = "^(pavucontrol|blueman-manager|nm-connection-editor|nwg-look|qt5ct|qt6ct)$",
    },
    float = true,
    center = true,
})

hl.window_rule({
    name = "arch-wm-file-picker-float",
    match = {
        title = "^(Open File|Open Files|Save File|Save As|Choose File|Choose Files|Select File|Select Folder)$",
    },
    float = true,
    center = true,
})

hl.window_rule({
    name = "arch-wm-auth-dialog-float",
    match = {
        title = "^(Authentication Required|Authenticate|Password Required|Unlock Keyring)$",
    },
    float = true,
    center = true,
})

hl.window_rule({
    name = "arch-wm-small-utility-float",
    match = {
        class = "^(org.pulseaudio.pavucontrol|org.gnome.Calculator|qalculate-gtk|org.gnome.NautilusPreviewer)$",
    },
    float = true,
    center = true,
})

hl.window_rule({
    name = "arch-wm-picture-in-picture-float",
    match = {
        title = "^(Picture-in-Picture|Picture in picture)$",
    },
    float = true,
})
