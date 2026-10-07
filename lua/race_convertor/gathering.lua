local M = {}

function M.setup_directories(project_name)
    local current_dir = vim.fn.getcwd()
    local parent_dir = vim.fn.fnamemodify(current_dir, ":h")
    local export_dir = parent_dir .. "/" .. project_name .. "_VS_Export"
    local project_dir = export_dir .. "/" .. project_name
    
    vim.fn.mkdir(project_dir, "p")
    
    return {
        export_dir = export_dir,
        project_dir = project_dir,
        sln_path = export_dir .. "/" .. project_name .. ".sln",
        vcxproj_path = project_dir .. "/" .. project_name .. ".vcxproj",
        filters_path = project_dir .. "/" .. project_name .. ".vcxproj.filters"
    }
end

function M.copy_and_find_files(project_dir)
    local files = vim.fn.glob("**/*.c", false, true)
    vim.list_extend(files, vim.fn.glob("**/*.cpp", false, true))
    vim.list_extend(files, vim.fn.glob("**/*.h", false, true))
    vim.list_extend(files, vim.fn.glob("**/*.hpp", false, true))

    local unique_files = {}
    for _, filepath in ipairs(files) do
        if not filepath:match("^[bB]uild[/\\]") and not filepath:match("^[oO]ut[/\\]") and not filepath:match("%.vs[/\\]") then
            local filename = vim.fn.fnamemodify(filepath, ":t")
            local dest = project_dir .. "/" .. filename
            
            vim.loop.fs_copyfile(filepath, dest)
            
            local exists = false
            for _, v in ipairs(unique_files) do
                if v == filename then exists = true end
            end
            if not exists then table.insert(unique_files, filename) end
        end
    end
    
    return unique_files
end

return M