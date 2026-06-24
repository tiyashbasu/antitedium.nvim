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
