-- Keep common utility windows predictable without matching user applications broadly.
hl.window_rule({
    name = "arch-wm-settings-float",
    match = {
        class = "^(pavucontrol|blueman-manager|nm-connection-editor)$",
    },
    float = true,
    center = true,
})

hl.window_rule({
    name = "arch-wm-file-picker-float",
    match = {
        title = "^(Open File|Save File|Choose Files?)$",
    },
    float = true,
    center = true,
})
