return {
  {
    "echasnovski/mini.ai",
    version = false,
    event = "VeryLazy",
    opts = {
      n_lines = 500,
    },
  },

  {
    "mfussenegger/nvim-lint",
    event = { "BufReadPost", "BufWritePost", "InsertLeave" },
    config = function()
      local lint = require("lint")
      lint.linters_by_ft = {
        bash = { "shellcheck" },
        sh = { "shellcheck" },
      }

      local group = vim.api.nvim_create_augroup("brooke_nvim_lint", { clear = true })
      vim.api.nvim_create_autocmd({ "BufWritePost", "InsertLeave" }, {
        group = group,
        callback = function()
          lint.try_lint()
        end,
      })
    end,
  },

  {
    "nvim-treesitter/nvim-treesitter-context",
    event = { "BufReadPost", "BufNewFile" },
    opts = {
      max_lines = 3,
      multiline_threshold = 1,
      trim_scope = "outer",
      mode = "cursor",
      separator = "─",
    },
    keys = {
      { "<leader>tc", "<cmd>TSContext toggle<cr>", desc = "Toggle code context" },
    },
  },

  -- Keep AI regeneration as a single insert-mode action. This optional spec
  -- augments Minuet only when the main AI configuration enables the plugin.
  {
    "milanglacier/minuet-ai.nvim",
    optional = true,
    keys = {
      {
        "<M-r>",
        function()
          local action = require("minuet.virtualtext").action
          action.dismiss()
          vim.schedule(action.next)
        end,
        mode = "i",
        desc = "Regenerate AI completion",
      },
    },
  },
}
