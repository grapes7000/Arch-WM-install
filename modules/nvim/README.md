# Neovim IDE

This module is the source of truth for the Arch-WM-install Neovim setup. `scripts/install-nvim.sh` copies `modules/nvim/config/` to `~/.config/nvim`, backs up the previous config, syncs Lazy plugins, and installs the configured Tree-sitter parsers.

The goal is a custom Neovim IDE with the polish of LazyVim while keeping the pieces that fit this workstation best.

## Layout

The intended editing layout is:

```text
┌──────────────┬──────────────────────────────────────┬──────────────────┐
│ OPTIONAL     │                                      │ AI               │
│ SIDEBAR      │             EDITOR                   │ CodeCompanion    │
│ Neo-tree     │                                      │                  │
│              │                                      │                  │
├──────────────┴──────────────────────────────────────┴──────────────────┤
│ TERMINAL / DIAGNOSTICS                                                │
│ Snacks terminal / Trouble                                            │
└───────────────────────────────────────────────────────────────────────┘
```

Yazi is the primary interactive file browser. It opens as a large floating browser because Yazi's multi-column layout is much more useful with room to show parent/current/preview columns. Neo-tree remains available as a collapsible left overview when a persistent VS Code-style sidebar is useful. Oil remains available as an editable filesystem buffer.

## Plugin loading

Lazy.nvim intentionally does not load every installed plugin at startup. A display such as `18/35 loaded` means 35 plugins are installed/known and 18 are currently resident. The rest load when their trigger is used, for example on `InsertEnter`, a filetype, a command such as `:CodeCompanionChat`, or opening Yazi. This is expected and keeps startup fast.

## File browsing

`yazi.nvim` runs the real system Yazi inside Neovim and keeps file operations synchronized with Neovim buffers and LSP clients.

| Keys | Action |
| --- | --- |
| `-` | Open Yazi at the current file |
| `Space e e` | Open Yazi at the current file |
| `Space e c` | Open Yazi at Neovim's project cwd |
| `Space e r` | Resume the previous Yazi session |
| `Space e s` | Toggle the optional Neo-tree sidebar |
| `Space e f` | Reveal/focus the current file in the sidebar |
| `Space e o` | Open the floating Oil filesystem editor |

Inside Yazi, normal Yazi navigation remains intact, including `h/l` and left/right navigation. Additional Neovim integration keys include:

| Yazi key | Action |
| --- | --- |
| `F1` | Yazi/Neovim integration help |
| `Ctrl-v` | Open selected file in a vertical split |
| `Ctrl-x` | Open selected file in a horizontal split |
| `Ctrl-t` | Open selected file in a new tab |
| `Ctrl-s` | Telescope grep in the current Yazi directory/selection |
| `Ctrl-g` | GrugFar search/replace in the current Yazi directory/selection |
| `Ctrl-y` | Copy relative path |
| `Ctrl-q` | Send selected files to quickfix |
| `Tab` | Cycle/jump to open Neovim buffers |
| `Ctrl-\\` | Set Neovim's working directory from Yazi |

Neo-tree also maps `h/l` and the physical left/right arrow keys to collapse/open folders, so the optional sidebar follows the same navigation idea.

## Core keys

`<leader>` is Space.

| Keys | Action |
| --- | --- |
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
| `:AIStatus` | Show active AI providers, Ollama host and model |
| `:AIHealth` | Ping Ollama and check whether the configured model exists |
| `:ThemeReload` | Manually reload the Arch-WM theme palette |

Press Space and wait briefly to see the Which-Key menu.

## Theme-engine integration

Neovim follows the same theme selected by the Arch-WM `theme` command.

The theme engine writes its normalized active palette to:

```text
~/.config/theme-engine/generated/theme.json
```

Neovim reads that semantic palette and maps it into Catppuccin's highlight groups so plugin integrations remain polished instead of replacing the colorscheme with a handful of raw `:highlight` commands.

Dark themes use Catppuccin's dark base behavior and light themes use its light base behavior, while the actual background, surfaces, text, accents, diagnostics, selections, borders, Git/LSP/UI colors, Telescope, Neo-tree, Noice, Blink, and other integrated plugin colors come from the selected Arch-WM theme.

Neovim watches the generated theme directory. Running a theme change from another terminal should update a currently running Neovim automatically:

```bash
theme obsidian
theme porcelain
theme sorbet
```

If a live reload ever misses an event, run this once inside Neovim:

```vim
:ThemeReload
```

If the theme engine has not generated an active palette yet, Neovim falls back to the original pink Arch-WM palette.

## Command line UI

Noice replaces the stock command line/messages UI. Pressing `:` opens the centered floating command palette while searches stay compact at the bottom.

## Completion and language intelligence

Blink provides fast IDE completion from LSP, paths, snippets, the current buffer, and Minuet AI. The installer provides language servers for Lua, Python, Bash, JSON, YAML, HTML/CSS, JavaScript/TypeScript, C/C++, and QML/Qt.

Conform formats on save with LSP fallback. Trouble provides an IDE-style Problems panel. Gitsigns adds Git changes and hunk actions in the gutter. nvim-lint currently runs ShellCheck for Bash/sh.

## Terminal environment

The embedded Snacks terminal explicitly launches the workstation's `zsh` as a login shell. That means it loads the same Arch-WM `.zshrc`, including Starship, the active generated Starship theme, eza icon aliases, zoxide, atuin, fzf and local overrides from `~/.zshrc.local`.

The prompt and command output should therefore match a normal terminal closely. The outer window is still a Neovim terminal buffer, so Kitty-specific window chrome/padding is not reproduced inside the editor.

## AI: Ollama by default

Both CodeCompanion chat/inline edits and Minuet autocomplete use Ollama by default.

For a remote Ollama instance, set one environment variable in the user's untracked `~/.zshrc.local`:

```bash
export OLLAMA_HOST="http://HOST:11434"
```

`NVIM_OLLAMA_HOST` can override that value for Neovim only. A scheme-less value is accepted and normalized to `http://`.

The defaults are equivalent to:

```bash
NVIM_AI_CHAT=ollama \
NVIM_AI_COMPLETION=ollama \
NVIM_OLLAMA_MODEL=qwen2.5-coder:7b \
nvim .
```

Minuet uses Ollama's OpenAI-compatible `/v1/completions` endpoint for fill-in-the-middle autocomplete. The default `qwen2.5-coder:7b` model supports FIM completion. The starting context window is intentionally 512 characters for lower latency over a remote/local model; increase it with `NVIM_OLLAMA_CONTEXT` after confirming performance.

AI completion is automatically enabled as a Blink source. `Alt-y` manually requests Minuet if an automatic suggestion has not appeared. `:Minuet blink enable` explicitly re-enables Minuet autocomplete if it was toggled off during a session.

Useful checks:

```vim
:AIStatus
:AIHealth
:checkhealth codecompanion
```

Outside Neovim:

```bash
curl "$OLLAMA_HOST/api/tags"
```

The configured Ollama server must contain `qwen2.5-coder:7b`. Pull it on the Ollama host if needed:

```bash
ollama pull qwen2.5-coder:7b
```

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
:checkhealth yazi
:checkhealth codecompanion
:Lazy
:LspInfo
:ConformInfo
:AIStatus
:AIHealth
```

## LazyVim relationship

This is intentionally not a LazyVim distribution install. It borrows the pieces that make current LazyVim feel polished—Noice, Snacks, Blink, LSP, Conform, Gitsigns, Trouble, Bufferline, Flash, Todo Comments, persistence, LazyDev, and related UI conventions—while retaining this setup's theme-engine palette, Telescope, Yazi, Oil, explicit pacman-managed language servers, and the VS Code-style Edgy/CodeCompanion layout.
