local config = require("antitedium.config")

local M = {}

local uv = vim.uv or vim.loop

-- The single in-flight request; a new request cancels the previous one.
local current = nil -- { handle = SystemObj, id = number }
local seq = 0

-- Strip a surrounding markdown code fence the model sometimes emits despite
-- instructions (e.g. a leading ```lua and a trailing ```).
local function strip_fences(text)
    local lines = vim.split(text, "\n", { plain = true })
    if #lines > 0 and lines[1]:match("^%s*```") then
        table.remove(lines, 1)
        for i = #lines, 1, -1 do
            if lines[i]:match("^%s*```%s*$") then
                table.remove(lines, i)
                break
            elseif lines[i]:match("%S") then
                break
            end
        end
    end
    return table.concat(lines, "\n")
end

-- Parse `claude -p --output-format json` output: { result, is_error, ... }.
local function parse_result(stdout)
    local ok, decoded = pcall(vim.json.decode, stdout)
    if not ok or type(decoded) ~= "table" then
        return nil, "failed to parse claude output"
    end
    if decoded.is_error then
        return nil, decoded.result or "claude returned an error"
    end
    return decoded.result, nil
end

function M.cancel()
    if current and current.handle then
        pcall(function()
            current.handle:kill("sigterm")
        end)
    end
    current = nil
end

-- opts: { user_prompt, system_prompt, on_done(text), on_error(msg) }
function M.complete(opts)
    M.cancel()
    local cfg = config.get()
    seq = seq + 1
    local id = seq

    local args = {
        cfg.command,
        "-p",
        opts.user_prompt,
        "--system-prompt",
        opts.system_prompt,
        "--output-format",
        "json",
        "--no-session-persistence",
        "--tools",
        "",
        "--model",
        cfg.model,
    }

    local handle = vim.system(args, {
        text = true,
        timeout = cfg.timeout_ms,
        -- neutral cwd to avoid pulling in the project's CLAUDE.md / git context
        cwd = uv.os_tmpdir(),
    }, function(out)
        vim.schedule(function()
            -- drop stale responses (a newer request superseded this one)
            if not current or current.id ~= id then
                return
            end
            current = nil

            if out.code ~= 0 then
                local msg
                if out.signal and out.signal ~= 0 then
                    return -- killed by cancel(); stay silent
                elseif out.stderr and out.stderr ~= "" then
                    msg = out.stderr
                else
                    msg = "claude exited with code " .. tostring(out.code)
                end
                opts.on_error(msg)
                return
            end

            local result, err = parse_result(out.stdout)
            if err then
                opts.on_error(err)
                return
            end
            opts.on_done(strip_fences(result or ""))
        end)
    end)

    current = { handle = handle, id = id }
end

return M
