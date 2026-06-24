if vim.g.loaded_antitedium then
    return
end
vim.g.loaded_antitedium = true

-- User commands work even before setup(); setup() additionally wires keymaps.
vim.api.nvim_create_user_command("AntitediumLine", function()
    require("antitedium").complete("line")
end, { desc = "antitedium: complete current line" })

vim.api.nvim_create_user_command("AntitediumBlock", function()
    require("antitedium").complete("block")
end, { desc = "antitedium: complete short block" })

vim.api.nvim_create_user_command("AntitediumFull", function()
    require("antitedium").complete("full")
end, { desc = "antitedium: complete full block" })
