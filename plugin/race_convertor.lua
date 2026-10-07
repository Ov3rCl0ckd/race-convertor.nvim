if vim.g.loaded_race_convertor == 1 then
    return
end
vim.g.loaded_race_convertor = 1

vim.api.nvim_create_user_command('ExportToVS', function()
    require('race_convertor').open_floating_prompt()
end, {})

vim.keymap.set('n', '<leader>ll', function()
    require('race_convertor').open_floating_prompt()
end, { desc = "Export current C/C++ files to a Visual Studio Solution" })