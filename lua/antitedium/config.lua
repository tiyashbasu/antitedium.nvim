local M = {}

M.defaults = {
    -- claude CLI invocation
    command = "claude",
    model = "claude-haiku-4-5",
    timeout_ms = 30000,

    -- system prompt shared by all profiles (a per-profile instruction is appended)
    system_prompt = table.concat({
        "You are a code completion engine.",
        "Output ONLY the raw text to insert at the <CURSOR> position.",
        "No explanations, no markdown code fences, no repetition of the surrounding code.",
        "If unsure, output the single most likely completion.",
    }, " "),

    -- how much surrounding code to send (lines around the cursor)
    context = {
        before_lines = 60,
        after_lines = 20,
    },

    -- completion scope profiles; each is bound to its own trigger keymap.
    -- max_tokens is advisory (bounded via the instruction; the claude CLI print
    -- mode does not expose a hard --max-tokens flag).
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

    -- trigger keymaps are mapped in these modes (normal by default; insert-mode
    -- <leader> maps interfere with typing, so opt in via config if you want them)
    trigger_modes = { "n" },

    -- accept/dismiss keys, active (buffer-local) only while a suggestion is shown.
    -- In insert mode, leaving insert (<Esc>) auto-dismisses via InsertLeave, so we
    -- do not hijack <Esc>; <C-]> is an explicit dismiss for normal mode.
    keys = {
        accept = "<Tab>",
        dismiss = "<C-]>",
    },

    -- highlight group for the ghost text / spinner
    highlight = "Comment",
}

M.options = nil

function M.setup(opts)
    M.options =
        vim.tbl_deep_extend("force", vim.deepcopy(M.defaults), opts or {})
    return M.options
end

function M.get()
    if not M.options then
        M.options = vim.deepcopy(M.defaults)
    end
    return M.options
end

return M
