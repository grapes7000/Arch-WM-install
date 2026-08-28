local chat_provider = vim.env.NVIM_AI_CHAT or "ollama"
local completion_provider = vim.env.NVIM_AI_COMPLETION or "ollama"
local ollama_model = vim.env.NVIM_OLLAMA_MODEL or "qwen2.5-coder:7b"
local openai_model = vim.env.NVIM_OPENAI_MODEL or "gpt-5.6-luna"
local codex_model = vim.env.NVIM_CODEX_MODEL or "gpt-5.6-terra"

local function codecompanion_adapter()
  if chat_provider == "copilot" then
    return "copilot"
  end
  if chat_provider == "openai" then
    return { name = "openai", model = openai_model }
  end
  if chat_provider == "codex" then
    return { name = "codex", model = codex_model }
  end
  return { name = "ollama", model = ollama_model }
end

return {
  {
    "olimorris/codecompanion.nvim",
    version = "^19.0.0",
    cmd = {
      "CodeCompanion",
      "CodeCompanionActions",
      "CodeCompanionChat",
      "CodeCompanionCLI",
      "CodeCompanionCmd",
    },
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
    },
    opts = {
      adapters = {
        acp = {
          codex = function()
            return require("codecompanion.adapters").extend("codex", {
              defaults = {
                auth_method = "chat-gpt",
              },
            })
          end,
        },
      },
      interactions = {
        chat = {
          adapter = codecompanion_adapter(),
        },
        inline = {
          adapter = chat_provider == "codex" and { name = "ollama", model = ollama_model } or codecompanion_adapter(),
        },
        cmd = {
          adapter = chat_provider == "codex" and { name = "ollama", model = ollama_model } or codecompanion_adapter(),
        },
      },
      display = {
        chat = {
          window = {
            layout = "vertical",
            position = "right",
            width = 0.32,
            full_height = false,
            border = "rounded",
          },
        },
        action_palette = {
          provider = "telescope",
          opts = {
            show_preset_actions = true,
            show_preset_prompts = true,
            title = "AI actions",
          },
        },
      },
      opts = {
        send_code = true,
      },
    },
    keys = {
      { "<leader>ac", "<cmd>CodeCompanionChat Toggle<cr>", mode = { "n", "v" }, desc = "Toggle AI chat" },
      { "<leader>aa", "<cmd>CodeCompanionActions<cr>", mode = { "n", "v" }, desc = "AI actions" },
      { "<leader>ae", "<cmd>CodeCompanion<cr>", mode = { "n", "v" }, desc = "AI inline edit" },
      { "<leader>ad", "<cmd>CodeCompanionChat Add<cr>", mode = "v", desc = "Add selection to AI chat" },
      { "<leader>aC", "<cmd>CodeCompanionCLI<cr>", mode = { "n", "v" }, desc = "AI CLI agent" },
    },
    init = function()
      vim.api.nvim_create_user_command("AIStatus", function()
        vim.notify(
          string.format(
            "AI chat: %s | completion: %s | Ollama model: %s",
            chat_provider,
            completion_provider,
            ollama_model
          ),
          vim.log.levels.INFO,
          { title = "Neovim AI" }
        )
      end, {})
    end,
  },

  {
    "milanglacier/minuet-ai.nvim",
    event = "InsertEnter",
    enabled = completion_provider == "ollama" or completion_provider == "openai",
    opts = function()
      if completion_provider == "openai" then
        return {
          provider = "openai",
          n_completions = 1,
          context_window = 4096,
          throttle = 800,
          debounce = 300,
          provider_options = {
            openai = {
              model = openai_model,
              api_key = "OPENAI_API_KEY",
              optional = {
                max_completion_tokens = 128,
                reasoning_effort = "none",
              },
            },
          },
        }
      end

      return {
        provider = "openai_fim_compatible",
        n_completions = 1,
        context_window = tonumber(vim.env.NVIM_OLLAMA_CONTEXT) or 1024,
        throttle = 1200,
        debounce = 400,
        provider_options = {
          openai_fim_compatible = {
            name = "Ollama",
            end_point = (vim.env.OLLAMA_HOST or "http://127.0.0.1:11434") .. "/v1/completions",
            model = ollama_model,
            api_key = function()
              return "ollama"
            end,
            optional = {
              max_tokens = 128,
              top_p = 0.9,
            },
          },
        },
      }
    end,
  },

  {
    "saghen/blink.cmp",
    optional = true,
    opts = function(_, opts)
      if completion_provider ~= "ollama" and completion_provider ~= "openai" then
        return opts
      end

      opts.sources = opts.sources or {}
      opts.sources.default = opts.sources.default or { "lsp", "path", "snippets", "buffer" }
      if not vim.tbl_contains(opts.sources.default, "minuet") then
        table.insert(opts.sources.default, 1, "minuet")
      end
      opts.sources.providers = opts.sources.providers or {}
      opts.sources.providers.minuet = {
        name = "AI",
        module = "minuet.blink",
        async = true,
        timeout_ms = 5000,
        score_offset = 50,
      }
      opts.keymap = opts.keymap or {}
      opts.keymap["<M-y>"] = {
        function(cmp)
          cmp.show({ providers = { "minuet" } })
        end,
      }
      return opts
    end,
  },

  {
    "zbirenbaum/copilot.lua",
    cmd = "Copilot",
    event = "InsertEnter",
    enabled = completion_provider == "copilot" or chat_provider == "copilot",
    opts = {
      panel = { enabled = false },
      suggestion = {
        enabled = completion_provider == "copilot",
        auto_trigger = true,
        hide_during_completion = false,
        keymap = {
          accept = "<M-l>",
          accept_word = "<M-w>",
          accept_line = "<M-j>",
          next = "<M-]>",
          prev = "<M-[>",
          dismiss = "<C-]>",
        },
      },
      filetypes = {
        markdown = true,
        help = true,
      },
    },
  },
}
