-- Arch-WM compositor motion + lighting layer.
--
-- Loaded after generated.theme so this file can add a coherent motion/effects
-- personality without replacing the theme's colors, gaps, opacity or border
-- choices. Hyprland 0.55 remains the compatibility baseline.

local low_motion = os.getenv("ARCH_WM_LOW_MOTION") == "1"
local profile = string.lower(os.getenv("ARCH_WM_EFFECTS_PROFILE") or "cinematic")
if profile ~= "performance" and profile ~= "balanced" and profile ~= "cinematic" then
    profile = "cinematic"
end
if low_motion then
    profile = "performance"
end

-- Detect installed Hyprland rather than assuming the newest wiki schema. If
-- version probing ever fails we deliberately fall back to the 0.55-safe path.
local function installed_hyprland_version()
    local handle = io.popen("Hyprland --version 2>/dev/null")
    if not handle then
        return 0, 55
    end
    local output = handle:read("*a") or ""
    handle:close()
    local major, minor = output:match("[vV]?(%d+)%.(%d+)")
    return tonumber(major) or 0, tonumber(minor) or 55
end

local hypr_major, hypr_minor = installed_hyprland_version()
local function hypr_at_least(major, minor)
    return hypr_major > major or (hypr_major == major and hypr_minor >= minor)
end

local balanced = profile == "balanced"
local cinematic = profile == "cinematic"
local effects_enabled = balanced or cinematic

local shadow_range = cinematic and 28 or (balanced and 18 or 8)
local shadow_offset = cinematic and { 0, 5 } or (balanced and { 0, 3 } or { 0, 2 })
local blur_size = cinematic and 7 or (balanced and 5 or 3)
local blur_passes = cinematic and 2 or 1
local dim_strength = cinematic and 0.055 or (balanced and 0.035 or 0.0)
local glow_range = cinematic and 13 or (balanced and 9 or 5)

hl.config({
    animations = {
        enabled = true,
        workspace_wraparound = true,
    },
    decoration = {
        -- All of these keys exist on the 0.55 baseline.
        dim_inactive = effects_enabled,
        dim_strength = dim_strength,
        dim_special = cinematic and 0.30 or (balanced and 0.22 or 0.14),
        dim_around = cinematic and 0.38 or (balanced and 0.30 or 0.22),
        blur = {
            enabled = effects_enabled,
            size = blur_size,
            passes = blur_passes,
        },
        shadow = {
            enabled = true,
            range = shadow_range,
            render_power = cinematic and 2 or 3,
            sharp = false,
            color = cinematic and 0x88000000 or (balanced and 0x70000000 or 0x44000000),
            color_inactive = cinematic and 0x48000000 or 0x36000000,
            offset = shadow_offset,
            scale = cinematic and 0.97 or 0.985,
        },
        -- Inner glow landed in Hyprland 0.55. Keep it restrained: the goal is
        -- focused-window lighting, not a permanent neon outline.
        glow = {
            enabled = effects_enabled,
            range = glow_range,
            render_power = cinematic and 2 or 3,
            color = cinematic and "rgba(4f8cff66)" or "rgba(4f8cff44)",
            color_inactive = cinematic and "rgba(8b5cf61a)" or "rgba(4f8cff10)",
        },
    },
})

-- Motion blur was added after the 0.55 baseline. Gate the entire table so an
-- older compositor never sees an unknown key.
if effects_enabled and hypr_at_least(0, 56) then
    hl.config({
        decoration = {
            motion_blur = {
                enabled = true,
                samples = cinematic and 4 or 3,
            },
        },
    })
end

-- Wobble is intentionally opt-in even on newer builds. It is visually loud and
-- can interact badly with glow/shadow extents on large windows. Enable it with
-- ARCH_WM_EXPERIMENTAL_WOBBLE=1 only on a 0.57+ compositor.
if cinematic and os.getenv("ARCH_WM_EXPERIMENTAL_WOBBLE") == "1"
        and hypr_at_least(0, 57) then
    hl.config({
        decoration = {
            wobble = {
                enabled = true,
                mesh = 10,
                stiffness = 430.0,
                damping = 35.0,
                mass = 1.0,
                intensity = 0.035,
                value_epsilon = 0.18,
                velocity_epsilon = 1.5,
            },
        },
    })
end

-- Profile-shaped springs. Performance settles fastest; cinematic carries a
-- little more mass without turning windows into rubber.
local window_stiffness = cinematic and 245.0 or (balanced and 285.0 or 360.0)
local window_dampening = cinematic and 22.0 or (balanced and 25.0 or 32.0)
local workspace_stiffness = cinematic and 185.0 or (balanced and 215.0 or 300.0)
local workspace_dampening = cinematic and 20.0 or (balanced and 23.0 or 30.0)

hl.curve("archWindowSpring", {
    type = "spring",
    mass = 1.0,
    stiffness = window_stiffness,
    dampening = window_dampening,
})

hl.curve("archWorkspaceSpring", {
    type = "spring",
    mass = 1.0,
    stiffness = workspace_stiffness,
    dampening = workspace_dampening,
})

hl.curve("archLayerEase", {
    type = "bezier",
    points = cinematic and { { 0.12, 0.96 }, { 0.22, 1.0 } }
        or { { 0.16, 1.0 }, { 0.30, 1.0 } },
})

hl.curve("archFocusEase", {
    type = "bezier",
    points = { { 0.22, 0.82 }, { 0.24, 1.0 } },
})

hl.animation({
    leaf = "windowsIn",
    enabled = true,
    speed = cinematic and 3.4 or (balanced and 3.0 or 2.2),
    spring = "archWindowSpring",
    style = cinematic and "popin 90%" or "popin 93%",
})
hl.animation({
    leaf = "windowsOut",
    enabled = true,
    speed = cinematic and 2.5 or 2.2,
    bezier = "archLayerEase",
    style = "popin 96%",
})
hl.animation({
    leaf = "windowsMove",
    enabled = true,
    speed = cinematic and 3.4 or (balanced and 3.1 or 2.4),
    spring = "archWindowSpring",
})

hl.animation({
    leaf = "workspaces",
    enabled = true,
    speed = cinematic and 4.0 or (balanced and 3.4 or 2.8),
    spring = "archWorkspaceSpring",
    style = cinematic and "slidefade 26%" or "slidefade 22%",
})
hl.animation({
    leaf = "specialWorkspace",
    enabled = true,
    speed = cinematic and 4.1 or (balanced and 3.6 or 3.0),
    spring = "archWorkspaceSpring",
    style = cinematic and "slidefadevert 24%" or "slidefadevert 20%",
})

hl.animation({
    leaf = "layersIn",
    enabled = true,
    speed = cinematic and 3.1 or 2.7,
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
    speed = cinematic and 2.5 or 2.2,
    bezier = "archFocusEase",
})

-- Focus lighting transitions: opacity, shadow, glow and dimming all settle on
-- the same short curve instead of snapping independently.
for _, leaf in ipairs({ "fadeSwitch", "fadeShadow", "fadeGlow", "fadeDim" }) do
    hl.animation({
        leaf = leaf,
        enabled = true,
        speed = cinematic and 2.6 or 2.1,
        bezier = "archFocusEase",
    })
end

hl.animation({
    leaf = "border",
    enabled = true,
    speed = cinematic and 2.6 or 2.2,
    spring = "archWindowSpring",
})
hl.animation({
    leaf = "borderangle",
    enabled = true,
    speed = cinematic and 4.0 or 3.4,
    bezier = "archLayerEase",
    style = "once",
})

hl.layer_rule({
    name = "arch-wm-bar-motion",
    match = { namespace = "arch-wm:bar.*" },
    blur = effects_enabled,
    ignore_alpha = 0.08,
    animation = "slide top",
})

hl.layer_rule({
    name = "arch-wm-drawer-motion",
    match = { namespace = "arch-wm-drawer.*" },
    blur = effects_enabled,
    ignore_alpha = 0.08,
    dim_around = effects_enabled,
    animation = "slide right",
})

hl.layer_rule({
    name = "arch-wm-launcher-motion",
    match = { namespace = "arch-wm-launcher" },
    blur = effects_enabled,
    ignore_alpha = 0.06,
    dim_around = effects_enabled,
    animation = cinematic and "popin 91%" or "popin 94%",
})
