return {
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
      vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "Find files" })
      vim.keymap.set("n", "<leader>fg", builtin.live_grep, { desc = "Search project text" })
      vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "Open buffers" })
      vim.keymap.set("n", "<leader>fh", builtin.help_tags, { desc = "Help tags" })
      vim.keymap.set("n", "<leader>fr", builtin.oldfiles, { desc = "Recent files" })
      vim.keymap.set("n", "<leader>fs", builtin.lsp_document_symbols, { desc = "Document symbols" })
      vim.keymap.set("n", "<leader>fS", builtin.lsp_workspace_symbols, { desc = "Workspace symbols" })
    end,
  },

  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    lazy = false,
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons",
      "MunifTanjim/nui.nvim",
    },
    opts = {
      sources = { "filesystem", "buffers", "git_status" },
      close_if_last_window = false,
      popup_border_style = "rounded",
      open_files_do_not_replace_types = { "terminal", "Trouble", "trouble", "qf", "codecompanion", "edgy" },
      filesystem = {
        bind_to_cwd = false,
        follow_current_file = { enabled = true },
        use_libuv_file_watcher = true,
        filtered_items = {
          visible = true,
          hide_dotfiles = false,
          hide_gitignored = false,
        },
      },
      window = {
        position = "left",
        width = 36,
        mappings = {
          ["l"] = "open",
          ["h"] = "close_node",
          ["<space>"] = "none",
        },
      },
    },
    config = function(_, opts)
      require("neo-tree").setup(opts)
      vim.api.nvim_create_autocmd("VimEnter", {
        once = true,
        callback = function()
          if #vim.api.nvim_list_uis() == 0 then
            return
          end
          vim.schedule(function()
            pcall(vim.cmd, "Neotree show position=left filesystem")
          end)
        end,
      })
    end,
    keys = {
      { "<leader>ee", "<cmd>Neotree toggle position=left filesystem reveal<cr>", desc = "Toggle file explorer" },
      { "<leader>ef", "<cmd>Neotree focus position=left filesystem reveal<cr>", desc = "Focus current file" },
      { "<leader>eb", "<cmd>Neotree toggle position=left buffers<cr>", desc = "Buffer explorer" },
      { "<leader>eg", "<cmd>Neotree toggle position=left git_status<cr>", desc = "Git explorer" },
    },
  },

  {
    "stevearc/oil.nvim",
    lazy = false,
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {
      default_file_explorer = false,
      columns = { "icon", "permissions", "size" },
      view_options = { show_hidden = true },
      float = { padding = 2, border = "rounded" },
    },
    keys = {
      { "-", "<cmd>Oil<cr>", desc = "Edit parent directory" },
      { "<leader>eo", "<cmd>Oil --float<cr>", desc = "Floating Oil browser" },
    },
  },

  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      current_line_blame = false,
      signs = {
        add = { text = "│" },
        change = { text = "│" },
        delete = { text = "󰍵" },
        topdelete = { text = "‾" },
        changedelete = { text = "~" },
        untracked = { text = "┆" },
      },
      on_attach = function(bufnr)
        local gs = package.loaded.gitsigns
        local function bmap(mode, lhs, rhs, desc)
          vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
        end
        bmap("n", "]h", gs.next_hunk, "Next git hunk")
        bmap("n", "[h", gs.prev_hunk, "Previous git hunk")
        bmap("n", "<leader>gp", gs.preview_hunk, "Preview git hunk")
        bmap("n", "<leader>gr", gs.reset_hunk, "Reset git hunk")
        bmap("n", "<leader>gb", gs.blame_line, "Git blame line")
      end,
    },
  },

  {
    "folke/trouble.nvim",
    cmd = "Trouble",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {},
    keys = {
      { "<leader>xx", "<cmd>Trouble diagnostics toggle position=bottom<cr>", desc = "Project diagnostics" },
      { "<leader>xb", "<cmd>Trouble diagnostics toggle filter.buf=0 position=bottom<cr>", desc = "Buffer diagnostics" },
      { "<leader>xs", "<cmd>Trouble symbols toggle focus=false<cr>", desc = "Symbols" },
      { "<leader>xq", "<cmd>Trouble qflist toggle<cr>", desc = "Quickfix" },
    },
  },

  {
    "MagicDuck/grug-far.nvim",
    cmd = { "GrugFar", "GrugFarWithin" },
    opts = { headerMaxWidth = 80 },
    keys = {
      { "<leader>sr", "<cmd>GrugFar<cr>", mode = { "n", "x" }, desc = "Search and replace" },
    },
  },

  {
    "folke/flash.nvim",
    event = "VeryLazy",
    opts = {},
    keys = {
      { "s", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash jump" },
      { "S", mode = { "n", "x", "o" }, function() require("flash").treesitter() end, desc = "Flash Treesitter" },
    },
  },

  {
    "folke/todo-comments.nvim",
    event = { "BufReadPost", "BufNewFile" },
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = {},
    keys = {
      { "]t", function() require("todo-comments").jump_next() end, desc = "Next TODO" },
      { "[t", function() require("todo-comments").jump_prev() end, desc = "Previous TODO" },
      { "<leader>ft", "<cmd>TodoTelescope<cr>", desc = "Find TODOs" },
    },
  },

  {
    "folke/persistence.nvim",
    event = "BufReadPre",
    opts = {},
    keys = {
      { "<leader>qs", function() require("persistence").load() end, desc = "Restore session" },
      { "<leader>ql", function() require("persistence").load({ last = true }) end, desc = "Restore last session" },
    },
  },
}
