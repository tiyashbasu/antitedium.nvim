# antitedium.nvim

On-demand AI code completion for Neovim, powered by your **Anthropic Claude
subscription** via the local `claude` CLI — no API key required.

Press a key, wait a few seconds, get a suggestion as dimmed ghost text, then
`<Tab>` to accept or move/edit to dismiss.

## Why on-demand (not as-you-type)?

A completion through the `claude` CLI takes ~5s (most of it the inference
round-trip, which a warm process can't avoid). That's too slow for real-time
ghost text, but perfectly fine for a deliberate keypress. So antitedium is
trigger-based: you ask for a completion when you want one.

Each request spawns one `claude -p` process that answers a single turn and
exits, so no context ever leaks between files.

## Requirements

- Neovim 0.10+
- [Claude Code](https://claude.com/claude-code) (`claude`) installed, on your
  `PATH`, and logged in (run `claude` once interactively to authenticate).

## Install (lazy.nvim)

```lua
{
    "tiyashbasu/antitedium.nvim",
    config = function()
        require("antitedium").setup()
    end,
}
```

## Usage

| Default key | Command         | Scope                              |
| ----------- | --------------- | ---------------------------------- |
| `<leader>cl`| `:AntitediumLine` | complete to end of current line    |
| `<leader>cc`| `:AntitediumBlock`| complete a short block (few lines) |
| `<leader>cb`| `:AntitediumFull` | complete a full function/block     |

While a suggestion is shown:

- `<Tab>` — accept (insert at cursor)
- `<C-]>` — dismiss
- any cursor move / edit / leaving insert mode also dismisses it

Run `:checkhealth antitedium` to verify the `claude` CLI is found and a live
completion succeeds.

## Configuration (defaults)

```lua
require("antitedium").setup({
    command = "claude",
    model = "haiku",
    timeout_ms = 30000,
    context = { before_lines = 60, after_lines = 20 },
    trigger_modes = { "n" }, -- add "i" for insert-mode triggers (note: <leader>
    -- maps interfere with typing in insert mode)
    keys = { accept = "<Tab>", dismiss = "<C-]>" },
    highlight = "Comment",
    profiles = {
        line = {
            keymap = "<leader>cl",
            max_tokens = 40,
            instruction = "Complete only to the end of the current line.",
        },
        block = {
            keymap = "<leader>cc",
            max_tokens = 150,
            instruction = "Complete the current statement or a short block of a few lines.",
        },
        full = {
            keymap = "<leader>cb",
            max_tokens = 400,
            instruction = "Complete the full function or block.",
        },
    },
})
```

## Checking available models

The `model` option above accepts either an **alias** (always resolves to the
latest of that tier) or a **full model ID**. There is no `claude models list`
command; here's how to see what's available:

- **Interactive picker** — run `claude` (with no `-p`), then type `/model`. It
  lists the models your subscription can use and lets you pick one. The IDs
  shown there are what you can put in antitedium's `model` config.
- **Aliases** (recommended — they auto-track the latest version):
  `haiku`, `sonnet`, `opus`. For completion you usually want the
  fastest/cheapest, i.e. `haiku`.
- **`claude --help`** documents the `--model` format and shows example IDs.
- **Full version IDs** (pin an exact model) are listed on Anthropic's models
  docs: <https://docs.anthropic.com/en/docs/about-claude/models>. Examples at
  time of writing: `claude-haiku-4-5`, `claude-sonnet-4-6`, `claude-opus-4-8`,
  `claude-fable-5`.

Quick way to confirm a given model works with your setup (it just runs one
completion through it):

```sh
claude -p "Reply with exactly: OK" --model haiku --no-session-persistence
```

`:checkhealth antitedium` does the same check against whatever `model` you have
configured.

## Known limitations

- **~5s latency per request** — inherent to the CLI path; this is why it's
  on-demand, not as-you-type.
- **Global `CLAUDE.md` is still loaded** by the CLI (it can't be suppressed
  without `--bare`, which forces API-key auth we don't have). A strong system
  prompt keeps output clean in practice, but be aware your global memory file
  is in context for each request.
- **Triggers are normal-mode by default** — insert-mode `<leader>` maps
  interfere with typing; opt in via `trigger_modes`.
