local M = {}

function M.check()
    local h = vim.health
    h.start("antitedium")

    local cfg = require("antitedium.config").get()

    if vim.fn.executable(cfg.command) == 1 then
        h.ok("`" .. cfg.command .. "` found on PATH")
    else
        h.error("`" .. cfg.command .. "` not found on PATH", {
            "Install Claude Code and ensure it is on your PATH: https://claude.com/claude-code",
        })
        return
    end

    h.info("running a live round-trip (this may take a few seconds)…")

    local res = vim.system({
        cfg.command,
        "-p",
        "Reply with exactly: OK",
        "--output-format",
        "json",
        "--no-session-persistence",
        "--tools",
        "",
        "--model",
        cfg.model,
    }, { text = true, timeout = cfg.timeout_ms }):wait()

    if res.code ~= 0 then
        h.error(
            "claude round-trip failed (exit " .. tostring(res.code) .. ")",
            {
                res.stderr ~= "" and res.stderr or "no stderr output",
                "Check that you are logged in: run `claude` once interactively.",
            }
        )
        return
    end

    local ok, decoded = pcall(vim.json.decode, res.stdout)
    if ok and type(decoded) == "table" and not decoded.is_error then
        h.ok("live completion succeeded (model: " .. cfg.model .. ")")
    else
        h.error("claude returned an unexpected response", { res.stdout or "" })
    end
end

return M
