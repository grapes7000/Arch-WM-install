-- Portable fallback: preferred mode, automatic position, native scale.
-- Add named monitor rules in conf/local.lua for mixed-DPI or fixed layouts.
hl.monitor({
    output = "",
    mode = "preferred",
    position = "auto",
    scale = "auto",
})
