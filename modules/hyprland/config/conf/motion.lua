-- Arch-WM compositor motion layer.
--
-- Loaded after generated.theme so these motion rules stay coherent across
-- color themes. Set ARCH_WM_LOW_MOTION=1 before starting Hyprland to disable
-- the two relatively expensive deformation effects while keeping the fast
-- spatial animation language intact.

local low_motion = os.getenv("ARCH_WM_LOW_MOTION") == "1"

hl.config({
    animations = {
        enabled = true,
        workspace_wraparound = true,
    },
    decoration = {
        motion_blur = {
            enabled = not low_motion,
            samples = 3,
        },
        wobble = {
            enabled = not low_motion,
            mesh = 10,
            stiffness = 420.0,
            damping = 34.0,
            mass = 1.0,
            intensity = 0.035,
            value_epsilon = 0.18,
            velocity_epsilon = 1.5,
        },
    },
})

-- Short, controlled springs: enough overshoot to feel physical without making
-- windows rubbery. Separate curves let workspaces carry slightly more mass
-- than individual windows.
hl.curve("archWindowSpring", {
    type = "spring",
    mass = 1.0,
    stiffness = 285.0,
    dampening = 25.0,
})

hl.curve("archWorkspaceSpring", {
    type = "spring",
    mass = 1.0,
    stiffness = 215.0,
    dampening = 23.0,
})

hl.curve("archLayerEase", {
    type = "bezier",
    points = { { 0.16, 1.0 }, { 0.30, 1.0 } },
})

-- Windows feel attached to the pointer while moving, then settle through a
-- spring. Open/close use a compact pop rather than a long full-screen slide.
hl.animation({
    leaf = "windowsIn",
    enabled = true,
    speed = 3.0,
    spring = "archWindowSpring",
    style = "popin 93%",
})
hl.animation({
    leaf = "windowsOut",
    enabled = true,
    speed = 2.5,
    bezier = "archLayerEase",
    style = "popin 96%",
})
hl.animation({
    leaf = "windowsMove",
    enabled = true,
    speed = 3.1,
    spring = "archWindowSpring",
})

-- Workspace transitions retain direction but only travel part of the screen,
-- which reads faster and more modern than a full-width slide.
hl.animation({
    leaf = "workspaces",
    enabled = true,
    speed = 3.4,
    spring = "archWorkspaceSpring",
    style = "slidefade 22%",
})
hl.animation({
    leaf = "specialWorkspace",
    enabled = true,
    speed = 3.6,
    spring = "archWorkspaceSpring",
    style = "slidefadevert 20%",
})

-- Layer-shell surfaces inherit these defaults. Per-namespace rules below give
-- the bar, drawers and launcher a spatial origin that matches their UI.
hl.animation({
    leaf = "layersIn",
    enabled = true,
    speed = 2.7,
    bezier = "archLayerEase",
    style = "popin 96%",
})
hl.animation({
    leaf = "layersOut",
    enabled = true,
    speed = 2.3,
    bezier = "archLayerEase",
    style = "fade",
})
hl.animation({
    leaf = "fadePopups",
    enabled = true,
    speed = 2.2,
    bezier = "archLayerEase",
})

-- Focus feedback. Angle animations are deliberately one-shot: never use the
-- looping angle style here because it forces continuous compositor frames.
hl.animation({
    leaf = "border",
    enabled = true,
    speed = 2.2,
    spring = "archWindowSpring",
})
hl.animation({
    leaf = "borderangle",
    enabled = true,
    speed = 3.4,
    bezier = "archLayerEase",
    style = "once",
})
hl.animation({
    leaf = "glowangle",
    enabled = true,
    speed = 3.4,
    bezier = "archLayerEase",
    style = "once",
})

hl.layer_rule({
    name = "arch-wm-bar-motion",
    match = { namespace = "arch-wm:bar.*" },
    blur = true,
    ignore_alpha = 0.08,
    animation = "slide top",
})

hl.layer_rule({
    name = "arch-wm-drawer-motion",
    match = { namespace = "arch-wm-drawer.*" },
    blur = true,
    ignore_alpha = 0.08,
    dim_around = true,
    animation = "slide right",
})

hl.layer_rule({
    name = "arch-wm-launcher-motion",
    match = { namespace = "arch-wm-launcher" },
    blur = true,
    ignore_alpha = 0.06,
    dim_around = true,
    animation = "popin 94%",
})
