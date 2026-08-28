# Neovim IDE

This module is the source of truth for the Arch-WM-install Neovim setup. `scripts/install-nvim.sh` copies `modules/nvim/config/` to `~/.config/nvim`, backs up the previous config, syncs Lazy plugins, and installs the configured Tree-sitter parsers.

The goal is a custom Neovim IDE with the polish of LazyVim while keeping the pieces that fit this workstation best.

## Layout

The intended editing layout is:

```text
┌──────────────┬──────────────────────────────────────┬──────────────────┐
│ FILES        │                                      │ AI               │
│ Neo-tree     │             EDITOR                   │ CodeCompanion    │
│              │                                      │                  │
│              │                                      │                  │
├──────────────┴──────────────────────────────────────┴──────────────────┤
│ TERMINAL / DIAGNOSTICS                                                │
│ Snacks terminal / Trouble                                            │
└───────────────────────────────────────────────────────────────────────┘
```

Edgy manages the persistent left, right, and bottom regions. Neo-tree is the IDE-style file sidebar; Oil remains available as a fast editable filesystem buffer.

## Core keys

`<leader>` is Space.

| Keys | Action |
| --- | --- |
| `Space e e` | Toggle/reveal left file explorer |
| `Space e f` | Focus current file in explorer |
| `-` | Open parent directory with Oil |
| `Space f f` | Find files |
| `Space f g` | Search text across project |
| `Space f b` | Open buffers |
| `Space f r` | Recent files |
| `Space f s` | Document symbols |
| `Space s r` | Search and replace across project |
| `Ctrl-h/j/k/l` | Move between panes |
| `Alt-h/j/k/l` | Resize panes |
| `Space s v` | Vertical editor split |
| `Space s h` | Horizontal editor split |
| `Space t t` or `Ctrl-/` | Toggle full-width bottom terminal |
| `Space t f` | Floating terminal |
| `Space x x` | Project diagnostics at bottom |
| `Space l r` | Rename symbol |
| `Space l a` | LSP code action |
| `Space l f` | Format buffer |
| `gd` | Go to definition |
| `gr` | References |
| `K` | Hover documentation |
| `Space a c` | Toggle right-side AI chat |
| `Space a a` | AI action palette |
| `Space a e` | AI inline edit |
| `Space a d` | Add visual selection to AI chat |
| `Alt-y` | Manually request Minuet completion |
| `:AIStatus` | Show active AI providers |

Press Space and wait briefly to see the Which-Key menu.

## Command line UI

Noice replaces the stock command line/messages UI. Pressing `:` opens the centered floating command palette while searches stay compact at the bottom.

## Completion and language intelligence

Blink provides fast IDE completion from LSP, paths, snippets, and the current buffer. The installer provides language servers for Lua, Python, Bash, JSON, YAML, HTML/CSS, JavaScript/TypeScript, C/C++, and QML/Qt.

Conform formats on save with LSP fallback. Trouble provides an IDE-style Problems panel. Gitsigns adds Git changes and hunk actions in the gutter. nvim-lint currently runs ShellCheck for Bash/sh.

## AI: local by default

By default both chat and autocomplete use local Ollama:

```bash
ollama pull qwen2.5-coder:7b
ollama serve
nvim .
```

The defaults are equivalent to:

```bash
NVIM_AI_CHAT=ollama \
NVIM_AI_COMPLETION=ollama \
NVIM_OLLAMA_MODEL=qwen2.5-coder:7b \
nvim .
```

`OLLAMA_HOST` can point at another Ollama host. `NVIM_OLLAMA_CONTEXT` controls Minuet's local completion context and defaults to 1024.

Minuet uses Ollama's OpenAI-compatible `/v1/completions` endpoint for fill-in-the-middle autocomplete. The default `qwen2.5-coder:7b` model supports that workflow.

## AI: Copilot fallback

Use GitHub Copilot for inline autocomplete:

```bash
NVIM_AI_COMPLETION=copilot nvim .
```

Run this once inside Neovim if needed:

```vim
:Copilot auth
```

You can also use Copilot for CodeCompanion chat:

```bash
NVIM_AI_CHAT=copilot NVIM_AI_COMPLETION=copilot nvim .
```

## AI: Codex / ChatGPT fallback

CodeCompanion supports Codex as an ACP coding agent for the right-side chat. Install `codex-acp` and then launch:

```bash
NVIM_AI_CHAT=codex nvim .
```

The adapter is configured for ChatGPT authentication rather than requiring an OpenAI API key. Codex ACP is used for agent/chat work; autocomplete remains Ollama by default because ACP agents are not low-latency completion backends.

A useful mixed setup is:

```bash
NVIM_AI_CHAT=codex NVIM_AI_COMPLETION=copilot nvim .
```

That gives Codex in the right-side agent panel and Copilot ghost-text autocomplete while typing.

## AI: OpenAI API option

If an API-key-backed fallback is preferred:

```bash
OPENAI_API_KEY='...' \
NVIM_AI_CHAT=openai \
NVIM_AI_COMPLETION=openai \
nvim .
```

Override the configured OpenAI models with `NVIM_OPENAI_MODEL` or `NVIM_CODEX_MODEL`.

## Health checks

Inside Neovim:

```vim
:checkhealth
:checkhealth codecompanion
:Lazy
:LspInfo
:ConformInfo
:AIStatus
```

For local AI, also verify outside Neovim:

```bash
ollama list
curl http://127.0.0.1:11434/api/tags
```

## LazyVim relationship

This is intentionally not a LazyVim distribution install. It borrows the pieces that make current LazyVim feel polished—Noice, Snacks, Blink, LSP, Conform, Gitsigns, Trouble, Bufferline, Flash, Todo Comments, persistence, LazyDev, and related UI conventions—while retaining this setup's custom Catppuccin palette, Telescope, Oil, explicit pacman-managed language servers, and the VS Code-style Neo-tree/Edgy/CodeCompanion layout.
