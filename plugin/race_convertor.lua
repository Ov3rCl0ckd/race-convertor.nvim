-- Ensure the plugin is only loaded once
if vim.g.loaded_race_convertor == 1 then
    return
end
vim.g.loaded_race_convertor = 1

-- Create a Neovim command so the user can just type :ExportToVS
vim.api.nvim_create_user_command('ExportToVS', function()
    require('race_convertor').open_floating_prompt()
end, {})

-- We can optionally provide a default mapping here, but lazy.nvim users
-- typically set their own mappings in the config block.
-- For backwards compatibility with the original request:
vim.keymap.set('n', '<leader>ll', function()
    require('race_convertor').open_floating_prompt()
end, { desc = "Export current C/C++ files to a Visual Studio Solution" })