local M = {}

local uv = vim.uv or vim.loop
local theme_file = vim.fn.expand("~/.config/theme-engine/generated/theme.json")
local theme_dir = vim.fn.fnamemodify(theme_file, ":h")

local watcher
local debounce

local fallback = {
  name = "pink-fallback",
  dark = true,
  roles = {
    bg = "#111014",
    bg_alt = "#29262D",
    text = "#F5E9F2",
    text_dim = "#B9ADB5",
    accent = "#FF3EAE",
    accent2 = "#D85CFF",
    urgent = "#FF5C8A",
    surface_0 = "#29262D",
    surface_1 = "#353138",
    surface_2 = "#454047",
    border_normal = "#5D565B",
    border_subtle = "#454047",
    warning = "#F5C2E7",
    success = "#A6E3C7",
    info = "#89B4FA",
    ansi_green = "#A6E3C7",
    ansi_yellow = "#F5C2E7",
    ansi_blue = "#89B4FA",
    ansi_cyan = "#94E2D5",
  },
}

local function read_theme()
  local ok, lines = pcall(vim.fn.readfile, theme_file)
  if not ok or not lines or #lines == 0 then
    return fallback
  end

  local decoded_ok, theme = pcall(vim.json.decode, table.concat(lines, "\n"))
  if not decoded_ok or type(theme) ~= "table" or type(theme.roles) ~= "table" then
    return fallback
  end

  return theme
end

local function role(roles, name, default)
  local value = roles[name]
  if type(value) == "string" and value ~= "" then
    return value
  end
  return default
end

local function palette(theme)
  local r = theme.roles
  local bg = role(r, "bg", fallback.roles.bg)
  local bg_alt = role(r, "bg_alt", bg)
  local text = role(r, "text", fallback.roles.text)
  local muted = role(r, "text_dim", text)
  local accent = role(r, "accent", fallback.roles.accent)
  local accent2 = role(r, "accent2", accent)
  local urgent = role(r, "urgent", fallback.roles.urgent)
  local surface0 = role(r, "surface_0", bg_alt)
  local surface1 = role(r, "surface_1", surface0)
  local surface2 = role(r, "surface_2", surface1)
  local border = role(r, "border_subtle", role(r, "border_normal", muted))
  local warning = role(r, "warning", role(r, "ansi_yellow", accent2))
  local success = role(r, "success", role(r, "ansi_green", accent2))
  local info = role(r, "info", role(r, "ansi_blue", accent2))
  local cyan = role(r, "ansi_cyan", info)

  return {
    rosewater = accent2,
    flamingo = accent,
    pink = accent,
    mauve = accent2,
    red = urgent,
    maroon = urgent,
    peach = warning,
    yellow = warning,
    green = success,
    teal = cyan,
    sky = cyan,
    sapphire = info,
    blue = info,
    lavender = accent2,
    text = text,
    subtext1 = muted,
    subtext0 = muted,
    overlay2 = muted,
    overlay1 = border,
    overlay0 = border,
    surface2 = surface2,
    surface1 = surface1,
    surface0 = surface0,
    base = bg,
    mantle = bg_alt,
    crust = bg,
  }
end

local function catppuccin_opts(theme)
  local flavour = theme.dark == false and "latte" or "mocha"
  local colors = palette(theme)

  return {
    flavour = flavour,
    transparent_background = false,
    color_overrides = {
      [flavour] = colors,
    },
    custom_highlights = function(c)
      return {
        CursorLine = { bg = c.surface0 },
        LineNr = { fg = c.overlay0 },
        CursorLineNr = { fg = c.pink, bold = true },
        Visual = { bg = c.surface2 },
        Search = { bg = c.pink, fg = c.crust, bold = true },
        IncSearch = { bg = c.mauve, fg = c.crust, bold = true },
      }
    end,
    integrations = {
      blink_cmp = true,
      gitsigns = true,
      native_lsp = { enabled = true },
      neotree = true,
      noice = true,
      telescope = { enabled = true },
      treesitter = true,
      which_key = true,
    },
  }
end

function M.apply(opts)
  opts = opts or {}
  local theme = read_theme()
  vim.o.background = theme.dark == false and "light" or "dark"

  local ok, catppuccin = pcall(require, "catppuccin")
  if not ok then
    return false
  end

  catppuccin.setup(catppuccin_opts(theme))
  vim.cmd.colorscheme("catppuccin")
  vim.g.arch_wm_theme = theme.name or "unknown"

  if opts.notify then
    vim.notify("Neovim theme: " .. vim.g.arch_wm_theme, vim.log.levels.INFO, { title = "Theme Engine" })
  end

  return true
end

local function schedule_reload()
  if not debounce then
    debounce = uv.new_timer()
  end
  debounce:stop()
  debounce:start(120, 0, vim.schedule_wrap(function()
    M.apply()
  end))
end

function M.watch()
  if watcher or vim.fn.isdirectory(theme_dir) ~= 1 then
    return
  end

  watcher = uv.new_fs_event()
  watcher:start(theme_dir, {}, function(err, filename)
    if err then
      return
    end
    if filename == nil or filename == "theme.json" or filename == ".active" then
      schedule_reload()
    end
  end)

  vim.api.nvim_create_autocmd("VimLeavePre", {
    once = true,
    callback = function()
      if watcher then
        watcher:stop()
        watcher:close()
        watcher = nil
      end
      if debounce then
        debounce:stop()
        debounce:close()
        debounce = nil
      end
    end,
  })
end

function M.setup()
  M.apply()
  M.watch()

  pcall(vim.api.nvim_del_user_command, "ThemeReload")
  vim.api.nvim_create_user_command("ThemeReload", function()
    M.apply({ notify = true })
  end, { desc = "Reload colors from the Arch-WM theme engine" })
end

return M
