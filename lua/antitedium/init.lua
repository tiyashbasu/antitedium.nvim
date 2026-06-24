local config = require("antitedium.config")
local context = require("antitedium.context")
local client = require("antitedium.client")
local render = require("antitedium.render")
local keymaps = require("antitedium.keymaps")

local M = {}

local augroup =
    vim.api.nvim_create_augroup("antitedium_session", { clear = true })

-- Tear down an active (or pending) suggestion session.
local function end_session()
    client.cancel()
    keymaps.unbind()
    render.clear()
    pcall(vim.api.nvim_clear_autocmds, { group = augroup })
end

local function on_accept()
    render.accept()
    end_session()
end

local function on_dismiss()
    end_session()
end

-- Wire accept/dismiss keys and auto-dismiss on movement/edit/mode-change.
local function start_session(bufnr)
    keymaps.bind(bufnr, on_accept, on_dismiss)
    vim.api.nvim_create_autocmd({
        "CursorMoved",
        "CursorMovedI",
        "TextChanged",
        "TextChangedI",
        "InsertLeave",
        "BufLeave",
    }, {
        group = augroup,
        buffer = bufnr,
        callback = function()
            on_dismiss()
        end,
    })
end

-- Trigger a completion for the named scope profile.
function M.complete(profile_name)
    local cfg = config.get()
    local profile = cfg.profiles[profile_name]
    if not profile then
        vim.notify(
            "antitedium: unknown profile '" .. tostring(profile_name) .. "'",
            vim.log.levels.ERROR
        )
        return
    end

    -- abandon anything in flight / on screen first
    end_session()

    local bufnr = vim.api.nvim_get_current_buf()
    local ctx = context.capture(bufnr)
    local user_prompt = context.build_prompt(ctx)
    local system_prompt = cfg.system_prompt .. " " .. profile.instruction

    render.show_spinner(bufnr, ctx.row, ctx.col)

    client.complete({
        user_prompt = user_prompt,
        system_prompt = system_prompt,
        on_done = function(text)
            render.clear() -- stop the spinner
            text = vim.trim(text)
            if text == "" then
                vim.notify("antitedium: empty completion", vim.log.levels.INFO)
                return
            end
            if render.show_suggestion(bufnr, ctx.row, ctx.col, text) then
                start_session(bufnr)
            end
        end,
        on_error = function(msg)
            render.clear()
            vim.notify("antitedium: " .. msg, vim.log.levels.ERROR)
        end,
    })
end

function M.setup(opts)
    local cfg = config.setup(opts)
    for name, profile in pairs(cfg.profiles) do
        if profile.keymap then
            vim.keymap.set(cfg.trigger_modes, profile.keymap, function()
                M.complete(name)
            end, { desc = "antitedium: complete (" .. name .. ")" })
        end
    end
end

return M
