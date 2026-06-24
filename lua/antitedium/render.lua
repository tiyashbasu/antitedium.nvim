local config = require("antitedium.config")

local M = {}

local uv = vim.uv or vim.loop
local ns = vim.api.nvim_create_namespace("antitedium")

local SPINNER =
{ "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }

local state = {
    bufnr = nil,
    text = nil, -- current suggestion text (nil while only a spinner shows)
    row = nil,  -- 0-indexed anchor row
    col = nil,  -- 0-indexed anchor col
    timer = nil,
    active = false, -- a suggestion is shown and awaiting accept/dismiss
}

local function stop_timer()
    if state.timer then
        state.timer:stop()
        if not state.timer:is_closing() then
            state.timer:close()
        end
        state.timer = nil
    end
end

local function clear_marks()
    if state.bufnr and vim.api.nvim_buf_is_valid(state.bufnr) then
        vim.api.nvim_buf_clear_namespace(state.bufnr, ns, 0, -1)
    end
end

function M.clear()
    stop_timer()
    clear_marks()
    state.text = nil
    state.active = false
end

-- Animated spinner at the cursor while waiting for a completion.
function M.show_spinner(bufnr, row, col)
    M.clear()
    state.bufnr = bufnr
    state.row = row - 1
    state.col = col
    local hl = config.get().highlight
    local i = 1
    local timer = uv.new_timer()
    state.timer = timer
    timer:start(
        0,
        100,
        vim.schedule_wrap(function()
            if not vim.api.nvim_buf_is_valid(bufnr) then
                M.clear()
                return
            end
            clear_marks()
            pcall(
                vim.api.nvim_buf_set_extmark,
                bufnr,
                ns,
                state.row,
                state.col,
                {
                    virt_text = { { SPINNER[i] .. " antitedium…", hl } },
                    virt_text_pos = "inline",
                }
            )
            i = (i % #SPINNER) + 1
        end)
    )
end

-- Show a suggestion as dimmed ghost text. Returns true if anything was shown.
function M.show_suggestion(bufnr, row, col, text)
    M.clear()
    if not text or text == "" then
        return false
    end
    if not vim.api.nvim_buf_is_valid(bufnr) then
        return false
    end
    if row - 1 >= vim.api.nvim_buf_line_count(bufnr) then
        return false
    end

    state.bufnr = bufnr
    state.row = row - 1
    state.col = col
    state.text = text
    state.active = true

    local hl = config.get().highlight
    local lines = vim.split(text, "\n", { plain = true })

    local ok =
        pcall(vim.api.nvim_buf_set_extmark, bufnr, ns, state.row, state.col, {
            virt_text = { { lines[1], hl } },
            virt_text_pos = "inline",
        })
    if not ok then
        M.clear()
        return false
    end

    if #lines > 1 then
        local virt_lines = {}
        for i = 2, #lines do
            table.insert(virt_lines, { { lines[i], hl } })
        end
        pcall(vim.api.nvim_buf_set_extmark, bufnr, ns, state.row, 0, {
            virt_lines = virt_lines,
        })
    end
    return true
end

function M.is_active()
    return state.active
end

-- Insert the current suggestion at its anchor position.
function M.accept()
    if not state.active or not state.text then
        return false
    end
    local bufnr, row, col, text = state.bufnr, state.row, state.col, state.text
    M.clear()

    if not vim.api.nvim_buf_is_valid(bufnr) then
        return false
    end

    local lines = vim.split(text, "\n", { plain = true })
    local ok =
        pcall(vim.api.nvim_buf_set_text, bufnr, row, col, row, col, lines)
    if not ok then
        return false
    end

    local new_row, new_col
    if #lines == 1 then
        new_row, new_col = row + 1, col + #lines[1]
    else
        new_row, new_col = row + #lines, #lines[#lines]
    end
    pcall(vim.api.nvim_win_set_cursor, 0, { new_row, new_col })
    return true
end

return M
