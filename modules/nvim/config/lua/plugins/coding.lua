return {
  {
    "nvim-treesitter/nvim-treesitter",
    lazy = false,
    build = ":TSUpdate",
    config = function()
      local ts = require("nvim-treesitter")
      ts.setup({})
      local parsers = {
        "bash",
        "c",
        "cpp",
        "css",
        "diff",
        "gitcommit",
        "gitignore",
        "html",
        "javascript",
        "json",
        "lua",
        "markdown",
        "markdown_inline",
        "python",
        "toml",
        "tsx",
        "typescript",
        "vim",
        "vimdoc",
        "yaml",
      }
      ts.install(parsers)

      vim.api.nvim_create_autocmd("FileType", {
        pattern = {
          "bash",
          "c",
          "cpp",
          "css",
          "html",
          "javascript",
          "json",
          "lua",
          "markdown",
          "python",
          "toml",
          "tsx",
          "typescript",
          "vim",
          "yaml",
        },
        callback = function(args)
          pcall(vim.treesitter.start, args.buf)
        end,
      })
    end,
  },

  {
    "saghen/blink.cmp",
    version = "*",
    event = { "InsertEnter", "CmdlineEnter" },
    dependencies = { "rafamadriz/friendly-snippets" },
    opts = {
      keymap = {
        preset = "enter",
        ["<C-y>"] = { "select_and_accept" },
        ["<Tab>"] = { "select_and_accept", "snippet_forward", "fallback" },
        ["<S-Tab>"] = { "snippet_backward", "fallback" },
      },
      appearance = {
        nerd_font_variant = "mono",
      },
      completion = {
        documentation = {
          auto_show = true,
          auto_show_delay_ms = 200,
          window = { border = "rounded" },
        },
        menu = { border = "rounded" },
        ghost_text = { enabled = true },
      },
      signature = { enabled = true, window = { border = "rounded" } },
      sources = {
        default = { "lsp", "path", "snippets", "buffer" },
      },
      cmdline = {
        enabled = true,
        keymap = { preset = "cmdline" },
        completion = {
          menu = { auto_show = true },
          ghost_text = { enabled = true },
        },
      },
    },
  },

  {
    "folke/lazydev.nvim",
    ft = "lua",
    cmd = "LazyDev",
    opts = {
      library = {
        { path = "${3rd}/luv/library", words = { "vim%.uv" } },
        { path = "lazy.nvim", words = { "Lazy" } },
        { path = "snacks.nvim", words = { "Snacks" } },
      },
    },
  },

  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = { "saghen/blink.cmp", "folke/lazydev.nvim" },
    config = function()
      local capabilities = require("blink.cmp").get_lsp_capabilities()
      local servers = {
        lua_ls = {
          settings = {
            Lua = {
              diagnostics = { globals = { "vim", "Snacks" } },
              workspace = { checkThirdParty = false },
              telemetry = { enable = false },
            },
          },
        },
        pyright = {},
        bashls = {},
        jsonls = {},
        yamlls = {},
        html = {},
        cssls = {},
        ts_ls = {},
        clangd = {},
        qmlls = {},
      }

      for name, config in pairs(servers) do
        config.capabilities = vim.tbl_deep_extend("force", {}, capabilities, config.capabilities or {})
        vim.lsp.config(name, config)
        vim.lsp.enable(name)
      end

      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(args)
          local opts = { buffer = args.buf }
          vim.keymap.set("n", "gd", vim.lsp.buf.definition, vim.tbl_extend("force", opts, { desc = "Go to definition" }))
          vim.keymap.set("n", "gr", vim.lsp.buf.references, vim.tbl_extend("force", opts, { desc = "References" }))
          vim.keymap.set("n", "gI", vim.lsp.buf.implementation, vim.tbl_extend("force", opts, { desc = "Implementation" }))
          vim.keymap.set("n", "gy", vim.lsp.buf.type_definition, vim.tbl_extend("force", opts, { desc = "Type definition" }))
          vim.keymap.set("n", "K", vim.lsp.buf.hover, vim.tbl_extend("force", opts, { desc = "Hover documentation" }))
          vim.keymap.set("n", "<leader>lr", vim.lsp.buf.rename, vim.tbl_extend("force", opts, { desc = "Rename symbol" }))
          vim.keymap.set({ "n", "v" }, "<leader>la", vim.lsp.buf.code_action, vim.tbl_extend("force", opts, { desc = "Code action" }))
          vim.keymap.set("n", "<leader>ld", vim.diagnostic.open_float, vim.tbl_extend("force", opts, { desc = "Line diagnostics" }))
          vim.keymap.set("n", "<leader>lh", vim.lsp.buf.signature_help, vim.tbl_extend("force", opts, { desc = "Signature help" }))
          vim.keymap.set("n", "]d", function() vim.diagnostic.jump({ count = 1, float = true }) end, vim.tbl_extend("force", opts, { desc = "Next diagnostic" }))
          vim.keymap.set("n", "[d", function() vim.diagnostic.jump({ count = -1, float = true }) end, vim.tbl_extend("force", opts, { desc = "Previous diagnostic" }))
        end,
      })
    end,
  },

  {
    "stevearc/conform.nvim",
    event = { "BufWritePre" },
    cmd = { "ConformInfo" },
    opts = {
      formatters_by_ft = {
        lua = { "stylua" },
        sh = { "shfmt" },
        bash = { "shfmt" },
      },
      format_on_save = {
        timeout_ms = 2500,
        lsp_format = "fallback",
      },
    },
    keys = {
      {
        "<leader>lf",
        function()
          require("conform").format({ async = true, lsp_format = "fallback" })
        end,
        mode = { "n", "v" },
        desc = "Format buffer",
      },
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
}
