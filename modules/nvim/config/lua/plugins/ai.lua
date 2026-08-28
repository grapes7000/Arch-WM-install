local chat_provider = vim.env.NVIM_AI_CHAT or "ollama"
local completion_provider = vim.env.NVIM_AI_COMPLETION or "ollama"
local ollama_model = vim.env.NVIM_OLLAMA_MODEL or "qwen2.5-coder:7b"
local openai_model = vim.env.NVIM_OPENAI_MODEL or "gpt-5.6-luna"
local codex_model = vim.env.NVIM_CODEX_MODEL or "gpt-5.6-terra"

local function normalize_url(value)
  value = value or "http://127.0.0.1:11434"
  if not value:match("^https?://") then
    value = "http://" .. value
  end
  return value:gsub("/+$", "")
end

local ollama_host = normalize_url(vim.env.NVIM_OLLAMA_HOST or vim.env.OLLAMA_HOST)
local curl_path = vim.fn.exepath("curl")

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

local function ollama_health()
  if curl_path == "" then
    vim.notify(
      "curl is not available in Neovim's PATH. Install it with: sudo pacman -S curl",
      vim.log.levels.ERROR,
      { title = "Neovim AI" }
    )
    return
  end

  vim.system({ curl_path, "-fsS", "--max-time", "4", ollama_host .. "/api/tags" }, { text = true }, function(result)
    vim.schedule(function()
      if result.code ~= 0 then
        vim.notify(
          string.format(
            "Cannot reach Ollama at %s\ncurl exit: %s\n%s",
            ollama_host,
            result.code,
            result.stderr or ""
          ),
          vim.log.levels.ERROR,
          { title = "Neovim AI" }
        )
        return
      end

      local ok, payload = pcall(vim.json.decode, result.stdout or "")
      if not ok or type(payload) ~= "table" then
        vim.notify("Ollama responded, but /api/tags was not valid JSON", vim.log.levels.WARN, { title = "Neovim AI" })
        return
      end

      local models = {}
      local found = false
      for _, item in ipairs(payload.models or {}) do
        local name = item.name or item.model
        if name then
          table.insert(models, name)
          if name == ollama_model or name:match("^" .. vim.pesc(ollama_model) .. ":") then
            found = true
          end
        end
      end

      local message = string.format(
        "Ollama reachable: %s\nModel: %s (%s)",
        ollama_host,
        ollama_model,
        found and "installed" or "NOT FOUND"
      )
      if #models > 0 then
        message = message .. "\nAvailable: " .. table.concat(models, ", ")
      end
      vim.notify(message, found and vim.log.levels.INFO or vim.log.levels.WARN, { title = "Neovim AI" })
    end)
  end)
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
        http = {
          ollama = function()
            return require("codecompanion.adapters").extend("ollama", {
              env = {
                url = ollama_host,
              },
              schema = {
                model = {
                  default = ollama_model,
                },
              },
            })
          end,
        },
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
            "AI chat: %s | completion: %s\nOllama: %s\nModel: %s\ncurl: %s",
            chat_provider,
            completion_provider,
            ollama_host,
            ollama_model,
            curl_path ~= "" and curl_path or "MISSING"
          ),
          vim.log.levels.INFO,
          { title = "Neovim AI" }
        )
      end, {})
      vim.api.nvim_create_user_command("AIHealth", ollama_health, { desc = "Check Ollama connectivity and configured model" })
    end,
  },

  {
    "milanglacier/minuet-ai.nvim",
    -- Minuet's virtual-text auto_trigger_ft is evaluated during setup and
    -- enables matching buffers as their FileType events fire. Load it at
    -- startup so setup happens before normal code buffers are opened.
    lazy = false,
    enabled = completion_provider == "ollama" or completion_provider == "openai",
    opts = function()
      local common = {
        n_completions = 1,
        add_single_line_entry = false,
        throttle = 900,
        debounce = 350,
        request_timeout = 5.0,
        curl_cmd = curl_path ~= "" and curl_path or "curl",
        virtualtext = {
          auto_trigger_ft = { "*" },
          auto_trigger_ignore_ft = {
            "TelescopePrompt",
            "neo-tree",
            "snacks_terminal",
            "yazi",
            "codecompanion",
            "lazy",
            "help",
          },
          show_on_completion_menu = true,
          keymap = {
            accept = "<M-l>",
            accept_line = "<M-j>",
            next = "<M-y>",
            prev = "<M-[>",
            dismiss = "<C-]>",
          },
        },
      }

      if completion_provider == "openai" then
        common.provider = "openai"
        common.context_window = 4096
        common.provider_options = {
          openai = {
            model = openai_model,
            api_key = "OPENAI_API_KEY",
            optional = {
              max_completion_tokens = 128,
              reasoning_effort = "none",
            },
          },
        }
        return common
      end

      common.provider = "openai_fim_compatible"
      common.context_window = tonumber(vim.env.NVIM_OLLAMA_CONTEXT) or 512
      common.provider_options = {
        openai_fim_compatible = {
          name = "Ollama",
          end_point = ollama_host .. "/v1/completions",
          model = ollama_model,
          api_key = function()
            return "ollama"
          end,
          optional = {
            max_tokens = 64,
            top_p = 0.9,
            stop = { "\n\n" },
          },
        },
      }
      return common
    end,
  },

  {
    "saghen/blink.cmp",
    optional = true,
    opts = function(_, opts)
      if completion_provider ~= "ollama" and completion_provider ~= "openai" then
        return opts
      end

      -- AI completion uses Minuet virtual text instead of the Blink popup.
      -- Blink remains focused on fast LSP/path/snippet/buffer completion.
      opts.sources = opts.sources or {}
      opts.sources.default = opts.sources.default or { "lsp", "path", "snippets", "buffer" }
      for index = #opts.sources.default, 1, -1 do
        if opts.sources.default[index] == "minuet" then
          table.remove(opts.sources.default, index)
        end
      end

      opts.keymap = opts.keymap or {}
      opts.keymap["<Tab>"] = {
        function()
          local ok, vt = pcall(require, "minuet.virtualtext")
          if ok and vt.action.is_visible() then
            vt.action.accept()
            return true
          end
          return false
        end,
        "select_and_accept",
        "snippet_forward",
        "fallback",
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
