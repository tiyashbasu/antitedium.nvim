local config = require("antitedium.config")

local M = {}

local mapped_buf = nil

-- Bind buffer-local accept/dismiss keys, active only while a suggestion shows.
function M.bind(bufnr, on_accept, on_dismiss)
    M.unbind()
    local cfg = config.get()
    vim.keymap.set({ "n", "i" }, cfg.keys.accept, on_accept, {
        buffer = bufnr,
        nowait = true,
        desc = "antitedium: accept suggestion",
    })
    vim.keymap.set({ "n", "i" }, cfg.keys.dismiss, on_dismiss, {
        buffer = bufnr,
        nowait = true,
        desc = "antitedium: dismiss suggestion",
    })
    mapped_buf = bufnr
end

function M.unbind()
    if mapped_buf and vim.api.nvim_buf_is_valid(mapped_buf) then
        local cfg = config.get()
        pcall(
            vim.keymap.del,
            { "n", "i" },
            cfg.keys.accept,
            { buffer = mapped_buf }
        )
        pcall(
            vim.keymap.del,
            { "n", "i" },
            cfg.keys.dismiss,
            { buffer = mapped_buf }
        )
    end
    mapped_buf = nil
end

return M
