-- Brooke's Arch WM Neovim config
-- Managed by Arch-WM-install. Plugin manager: lazy.nvim.

vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

local opt = vim.opt
opt.number = true
opt.relativenumber = true
opt.cursorline = true
opt.termguicolors = true
opt.signcolumn = "yes"
opt.wrap = false
opt.scrolloff = 8
opt.sidescrolloff = 8
opt.mouse = "a"
opt.clipboard = "unnamedplus"
opt.ignorecase = true
opt.smartcase = true
opt.splitbelow = true
opt.splitright = true
opt.undofile = true
opt.swapfile = false
opt.backup = false
opt.updatetime = 250
opt.timeoutlen = 400
opt.expandtab = true
opt.shiftwidth = 2
opt.tabstop = 2
opt.softtabstop = 2
opt.smartindent = true
opt.completeopt = { "menu", "menuone", "noselect" }

-- Keep Markdown comfy to read.
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "markdown", "text", "gitcommit" },
  callback = function()
    vim.opt_local.wrap = true
    vim.opt_local.linebreak = true
    vim.opt_local.spell = false
  end,
})

-- Small quality-of-life keymaps.
local map = vim.keymap.set
map("n", "<leader>w", "<cmd>write<cr>", { desc = "Save file" })
map("n", "<leader>q", "<cmd>quit<cr>", { desc = "Quit window" })
map("n", "<Esc>", "<cmd>nohlsearch<cr>", { desc = "Clear search highlight" })
map("n", "<C-h>", "<C-w>h", { desc = "Window left" })
map("n", "<C-j>", "<C-w>j", { desc = "Window down" })
map("n", "<C-k>", "<C-w>k", { desc = "Window up" })
map("n", "<C-l>", "<C-w>l", { desc = "Window right" })
map("v", "<", "<gv", { desc = "Indent left" })
map("v", ">", ">gv", { desc = "Indent right" })

-- Bootstrap lazy.nvim.
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local out = vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "--branch=stable",
    "https://github.com/folke/lazy.nvim.git",
    lazypath,
  })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to install lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
    }, true, {})
    return
  end
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  spec = {
    {
      "catppuccin/nvim",
      name = "catppuccin",
      priority = 1000,
      config = function()
        require("catppuccin").setup({
          flavour = "mocha",
          transparent_background = false,
          color_overrides = {
            mocha = {
              rosewater = "#ff8fce",
              flamingo = "#ff70c5",
              pink = "#ff3eae",
              mauve = "#d85cff",
              red = "#ff5c8a",
              peach = "#ff8ac6",
              yellow = "#f5c2e7",
              green = "#a6e3c7",
              teal = "#94e2d5",
              sky = "#89dceb",
              sapphire = "#74c7ec",
              blue = "#89b4fa",
              lavender = "#cba6f7",
              text = "#f5e9f2",
              subtext1 = "#d8cbd4",
              subtext0 = "#b9adb5",
              overlay2 = "#958a92",
              overlay1 = "#756c72",
              overlay0 = "#5d565b",
              surface2 = "#454047",
              surface1 = "#353138",
              surface0 = "#29262d",
              base = "#111014",
              mantle = "#0c0b0e",
              crust = "#080709",
            },
          },
          custom_highlights = function(colors)
            return {
              CursorLine = { bg = colors.surface0 },
              LineNr = { fg = colors.overlay0 },
              CursorLineNr = { fg = colors.pink, bold = true },
              Visual = { bg = colors.surface2 },
              Search = { bg = colors.pink, fg = colors.crust, bold = true },
            }
          end,
          integrations = {
            telescope = { enabled = true },
            which_key = true,
            native_lsp = { enabled = true },
          },
        })
        vim.cmd.colorscheme("catppuccin")
      end,
    },

    {
      "nvim-telescope/telescope.nvim",
      version = "*",
      dependencies = {
        "nvim-lua/plenary.nvim",
        "nvim-tree/nvim-web-devicons",
      },
      config = function()
        local telescope = require("telescope")
        telescope.setup({
          defaults = {
            prompt_prefix = "    ",
            selection_caret = " 󰜴 ",
            path_display = { "smart" },
            layout_config = { prompt_position = "top" },
            sorting_strategy = "ascending",
            border = true,
          },
          pickers = {
            find_files = { hidden = true },
          },
        })

        local builtin = require("telescope.builtin")
        map("n", "<leader>ff", builtin.find_files, { desc = "Find files" })
        map("n", "<leader>fg", builtin.live_grep, { desc = "Search text" })
        map("n", "<leader>fb", builtin.buffers, { desc = "Open buffers" })
        map("n", "<leader>fh", builtin.help_tags, { desc = "Help tags" })
        map("n", "<leader>fr", builtin.oldfiles, { desc = "Recent files" })
      end,
    },

    {
      "nvim-treesitter/nvim-treesitter",
      lazy = false,
      build = ":TSUpdate",
      config = function()
        local ts = require("nvim-treesitter")
        ts.setup({})
        local parsers = {
          "bash",
          "json",
          "lua",
          "markdown",
          "markdown_inline",
          "python",
          "vim",
          "vimdoc",
        }
        ts.install(parsers)

        vim.api.nvim_create_autocmd("FileType", {
          pattern = { "bash", "json", "lua", "markdown", "python", "vim" },
          callback = function(args)
            pcall(vim.treesitter.start, args.buf)
          end,
        })
      end,
    },

    {
      "nvim-lualine/lualine.nvim",
      dependencies = { "nvim-tree/nvim-web-devicons" },
      opts = {
        options = {
          theme = "catppuccin",
          globalstatus = true,
          component_separators = { left = "│", right = "│" },
          section_separators = { left = "", right = "" },
        },
        sections = {
          lualine_a = { "mode" },
          lualine_b = { "branch", "diff" },
          lualine_c = { { "filename", path = 1 } },
          lualine_x = { "diagnostics", "encoding", "filetype" },
          lualine_y = { "progress" },
          lualine_z = { "location" },
        },
      },
    },

    {
      "folke/which-key.nvim",
      event = "VeryLazy",
      opts = {},
    },

    {
      "stevearc/oil.nvim",
      lazy = false,
      dependencies = { "nvim-tree/nvim-web-devicons" },
      opts = {
        default_file_explorer = true,
        columns = { "icon", "permissions", "size" },
        view_options = { show_hidden = true },
        float = { padding = 2, border = "rounded" },
      },
      keys = {
        { "-", "<cmd>Oil<cr>", desc = "Open parent directory" },
        { "<leader>e", "<cmd>Oil --float<cr>", desc = "Floating file browser" },
      },
    },

    {
      "MeanderingProgrammer/render-markdown.nvim",
      ft = { "markdown" },
      dependencies = {
        "nvim-treesitter/nvim-treesitter",
        "nvim-tree/nvim-web-devicons",
      },
      opts = {
        preset = "obsidian",
        render_modes = { "n", "c", "t" },
        heading = { sign = false },
        code = { sign = false, width = "block", right_pad = 1 },
        pipe_table = { style = "round" },
      },
    },

    {
      "windwp/nvim-autopairs",
      event = "InsertEnter",
      opts = {},
    },

    {
      "numToStr/Comment.nvim",
      opts = {},
    },
  },
  install = { colorscheme = { "catppuccin", "habamax" } },
  checker = { enabled = true, notify = false },
  change_detection = { notify = false },
  ui = { border = "rounded" },
})

-- Highlight yanked text briefly so edits feel less invisible.
vim.api.nvim_create_autocmd("TextYankPost", {
  callback = function()
    vim.highlight.on_yank({ higroup = "IncSearch", timeout = 120 })
  end,
})
