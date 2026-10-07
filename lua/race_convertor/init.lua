local M = {}

M.config = {}

function M.setup(opts)
    M.config = vim.tbl_deep_extend("force", M.config, opts or {})
end

function M.open_floating_prompt()
    -- Dynamically require so cache busting works during dev
    local generator = require('race_convertor.generator')
    
    -- 1. Create a scratch buffer for our input
    local buf = vim.api.nvim_create_buf(false, true)
    
    -- 2. Define the dimensions of the floating window
    local width = 45
    local height = 1
    
    -- 3. Calculate position to center the window
    local ui = vim.api.nvim_list_uis()[1]
    local col = math.floor((ui.width - width) / 2)
    local row = math.floor((ui.height - height) / 2)
    
    -- 4. Define window options
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
    
    -- 5. Open the floating window
    local win = vim.api.nvim_open_win(buf, true, opts)
    
    -- 6. Automatically enter Insert Mode
    vim.cmd('startinsert')
    
    -- 7. Handle pressing <CR> (Enter) to confirm
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
    
    -- 8. Handle pressing <Esc> to cancel
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