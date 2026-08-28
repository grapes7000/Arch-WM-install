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
opt.updatetime = 200
opt.timeoutlen = 400
opt.expandtab = true
opt.shiftwidth = 2
opt.tabstop = 2
opt.softtabstop = 2
opt.smartindent = true
opt.completeopt = { "menu", "menuone", "noselect" }
opt.laststatus = 3
opt.showmode = false
opt.cmdheight = 0
opt.pumheight = 12
opt.fillchars = { eob = " ", fold = " ", foldopen = "", foldclose = "" }
if vim.fn.has("nvim-0.11") == 1 then
  opt.winborder = "rounded"
end

local map = vim.keymap.set
map("n", "<leader>w", "<cmd>write<cr>", { desc = "Save file" })
map("n", "<leader>q", "<cmd>quit<cr>", { desc = "Quit window" })
map("n", "<Esc>", "<cmd>nohlsearch<cr>", { desc = "Clear search highlight" })
map("n", "<C-h>", "<C-w>h", { desc = "Window left" })
map("n", "<C-j>", "<C-w>j", { desc = "Window down" })
map("n", "<C-k>", "<C-w>k", { desc = "Window up" })
map("n", "<C-l>", "<C-w>l", { desc = "Window right" })
map("n", "<leader>sv", "<cmd>vsplit<cr>", { desc = "Vertical split" })
map("n", "<leader>sh", "<cmd>split<cr>", { desc = "Horizontal split" })
map("n", "<leader>sc", "<cmd>close<cr>", { desc = "Close split" })
map("n", "<M-h>", "<cmd>vertical resize -3<cr>", { desc = "Narrow window" })
map("n", "<M-l>", "<cmd>vertical resize +3<cr>", { desc = "Widen window" })
map("n", "<M-j>", "<cmd>resize -2<cr>", { desc = "Shorten window" })
map("n", "<M-k>", "<cmd>resize +2<cr>", { desc = "Taller window" })
map("v", "<", "<gv", { desc = "Indent left" })
map("v", ">", ">gv", { desc = "Indent right" })

vim.diagnostic.config({
  severity_sort = true,
  underline = true,
  signs = true,
  virtual_text = { spacing = 2, prefix = "●" },
  float = { border = "rounded", source = "if_many" },
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = { "markdown", "text", "gitcommit", "codecompanion" },
  callback = function()
    vim.opt_local.wrap = true
    vim.opt_local.linebreak = true
    vim.opt_local.spell = false
  end,
})

vim.api.nvim_create_autocmd("TextYankPost", {
  callback = function()
    vim.highlight.on_yank({ higroup = "IncSearch", timeout = 120 })
  end,
})

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
    { import = "plugins" },
  },
  install = { colorscheme = { "catppuccin", "habamax" } },
  checker = { enabled = true, notify = false },
  change_detection = { notify = false },
  ui = { border = "rounded" },
})
