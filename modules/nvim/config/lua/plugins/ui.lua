local terminal_shell = vim.fn.exepath("zsh")
if terminal_shell == "" then
  terminal_shell = vim.o.shell
end

return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    config = function()
      require("arch_theme").setup()
    end,
  },

  {
    "folke/snacks.nvim",
    priority = 900,
    lazy = false,
    opts = {
      bigfile = { enabled = true },
      dashboard = { enabled = true },
      input = { enabled = true },
      notifier = { enabled = true, timeout = 3000 },
      quickfile = { enabled = true },
      terminal = {
        shell = { terminal_shell, "-l" },
        win = {
          position = "bottom",
          height = 0.30,
          border = "top",
          wo = { winbar = "" },
          keys = {
            nav_h = { "<C-h>", "<cmd>wincmd h<cr>", mode = "t", desc = "Window left" },
            nav_j = { "<C-j>", "<cmd>wincmd j<cr>", mode = "t", desc = "Window down" },
            nav_k = { "<C-k>", "<cmd>wincmd k<cr>", mode = "t", desc = "Window up" },
            nav_l = { "<C-l>", "<cmd>wincmd l<cr>", mode = "t", desc = "Window right" },
          },
        },
      },
    },
    keys = {
      {
        "<leader>tt",
        function()
          Snacks.terminal.toggle()
        end,
        mode = { "n", "t" },
        desc = "Toggle bottom terminal",
      },
      {
        "<C-/>",
        function()
          Snacks.terminal.toggle()
        end,
        mode = { "n", "t" },
        desc = "Toggle bottom terminal",
      },
      {
        "<leader>tf",
        function()
          Snacks.terminal.toggle(nil, { win = { position = "float", width = 0.8, height = 0.8 } })
        end,
        mode = { "n", "t" },
        desc = "Toggle floating terminal",
      },
    },
  },

  {
    "folke/noice.nvim",
    event = "VeryLazy",
    dependencies = { "MunifTanjim/nui.nvim" },
    opts = {
      lsp = {
        override = {
          ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
          ["vim.lsp.util.stylize_markdown"] = true,
        },
      },
      presets = {
        bottom_search = true,
        command_palette = true,
        long_message_to_split = true,
        inc_rename = false,
        lsp_doc_border = true,
      },
      routes = {
        {
          filter = { event = "msg_show", find = "%d+L, %d+B" },
          view = "mini",
        },
      },
    },
    keys = {
      { "<leader>nh", "<cmd>Noice history<cr>", desc = "Notification history" },
      { "<leader>nd", "<cmd>Noice dismiss<cr>", desc = "Dismiss notifications" },
    },
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
      extensions = { "neo-tree", "lazy", "trouble" },
    },
  },

  {
    "akinsho/bufferline.nvim",
    version = "*",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {
      options = {
        diagnostics = "nvim_lsp",
        separator_style = "slant",
        always_show_bufferline = false,
        offsets = {
          { filetype = "neo-tree", text = "  SIDEBAR", text_align = "left", separator = true },
        },
      },
    },
    keys = {
      { "<S-h>", "<cmd>BufferLineCyclePrev<cr>", desc = "Previous buffer" },
      { "<S-l>", "<cmd>BufferLineCycleNext<cr>", desc = "Next buffer" },
      { "<leader>bd", "<cmd>bdelete<cr>", desc = "Delete buffer" },
    },
  },

  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
      spec = {
        { "<leader>a", group = "AI" },
        { "<leader>b", group = "Buffers" },
        { "<leader>e", group = "Explorer" },
        { "<leader>f", group = "Find" },
        { "<leader>g", group = "Git" },
        { "<leader>l", group = "LSP" },
        { "<leader>n", group = "Notifications" },
        { "<leader>s", group = "Splits / Search" },
        { "<leader>t", group = "Terminal" },
        { "<leader>x", group = "Diagnostics" },
      },
    },
  },

  {
    "folke/edgy.nvim",
    event = "VeryLazy",
    opts = {
      animate = { enabled = false },
      exit_when_last = false,
      options = {
        left = { size = 36 },
        right = { size = 0.32 },
        bottom = { size = 0.30 },
      },
      left = {
        {
          title = "  FILES",
          ft = "neo-tree",
          filter = function(buf)
            return vim.b[buf].neo_tree_source == "filesystem"
          end,
          pinned = true,
          collapsed = true,
          open = "Neotree show position=left filesystem",
        },
      },
      right = {
        {
          title = "  AI",
          ft = "codecompanion",
          size = { width = 0.32 },
        },
      },
      bottom = {
        {
          ft = "snacks_terminal",
          size = { height = 0.30 },
          filter = function(_buf, win)
            return vim.w[win].snacks_win
              and vim.w[win].snacks_win.position == "bottom"
              and vim.w[win].snacks_win.relative == "editor"
              and not vim.w[win].trouble_preview
          end,
        },
        { ft = "trouble", size = { height = 0.30 } },
        { ft = "qf", title = "Quickfix", size = { height = 0.30 } },
      },
    },
  },

  {
    "MeanderingProgrammer/render-markdown.nvim",
    ft = { "markdown", "codecompanion" },
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
}
