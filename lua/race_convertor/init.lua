local M = {}

M.config = {}

function M.setup(opts)
    M.config = vim.tbl_deep_extend("force", M.config, opts or {})
end

function M.open_floating_prompt()
    local generator = require('race_convertor.generator')
    
    local buf = vim.api.nvim_create_buf(false, true)
    
    local width = 45
    local height = 1
    
    local ui = vim.api.nvim_list_uis()[1]
    local col = math.floor((ui.width - width) / 2)
    local row = math.floor((ui.height - height) / 2)
    
    local opts = {
        relative = 'editor',
        width = width,
        height = height,
        col = col,
        row = row,
        style = 'minimal',
        border = 'rounded',
        title = ' Enter VS Project Name ',
        title_pos = 'center'
    }
    
    local win = vim.api.nvim_open_win(buf, true, opts)
    
    vim.cmd('startinsert')
    
    vim.keymap.set('i', '<CR>', function()
        local lines = vim.api.nvim_buf_get_lines(buf, 0, 1, false)
        local project_name = lines[1]
        
        vim.cmd('stopinsert')
        vim.api.nvim_win_close(win, true)
        
        if project_name and project_name ~= "" then
            generator.generate(project_name)
        else
            print("Export cancelled: No project name provided.")
        end
    end, { buffer = buf })
    
    vim.keymap.set('i', '<Esc>', function()
        vim.cmd('stopinsert')
        vim.api.nvim_win_close(win, true)
        print("Export cancelled.")
    end, { buffer = buf })
    
    vim.keymap.set('n', '<Esc>', function()
        vim.api.nvim_win_close(win, true)
        print("Export cancelled.")
    end, { buffer = buf })
end

return M