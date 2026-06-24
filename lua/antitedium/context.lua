local config = require("antitedium.config")

local M = {}

-- Capture bounded context around the cursor.
-- Returns { prefix, suffix, filetype, filepath, row (1-idx), col (0-idx) }.
function M.capture(bufnr)
    bufnr = bufnr or vim.api.nvim_get_current_buf()
    local win = vim.api.nvim_get_current_win()
    local cursor = vim.api.nvim_win_get_cursor(win) -- { row (1-indexed), col (0-indexed) }
    local row, col = cursor[1], cursor[2]

    local opts = config.get()
    local total = vim.api.nvim_buf_line_count(bufnr)

    local start_row = math.max(0, row - 1 - opts.context.before_lines)
    local end_row = math.min(total, row + opts.context.after_lines)

    local cur_line = vim.api.nvim_buf_get_lines(bufnr, row - 1, row, false)[1]
        or ""
    local before_in_line = string.sub(cur_line, 1, col)
    local after_in_line = string.sub(cur_line, col + 1)

    local lines_before =
        vim.api.nvim_buf_get_lines(bufnr, start_row, row - 1, false)
    local lines_after = vim.api.nvim_buf_get_lines(bufnr, row, end_row, false)

    local prefix = before_in_line
    if #lines_before > 0 then
        prefix = table.concat(lines_before, "\n") .. "\n" .. before_in_line
    end

    local suffix = after_in_line
    if #lines_after > 0 then
        suffix = after_in_line .. "\n" .. table.concat(lines_after, "\n")
    end

    return {
        prefix = prefix,
        suffix = suffix,
        filetype = vim.bo[bufnr].filetype,
        filepath = vim.api.nvim_buf_get_name(bufnr),
        row = row,
        col = col,
    }
end

-- Build the FIM-style user prompt payload from captured context.
function M.build_prompt(ctx)
    local ft = (ctx.filetype ~= nil and ctx.filetype ~= "") and ctx.filetype
        or "text"
    return table.concat({
        "Filetype: " .. ft,
        "<CODE_BEFORE>",
        ctx.prefix,
        "</CODE_BEFORE>",
        "<CURSOR>",
        "<CODE_AFTER>",
        ctx.suffix,
        "</CODE_AFTER>",
    }, "\n")
end

return M
