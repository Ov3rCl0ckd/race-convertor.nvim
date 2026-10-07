local M = {}

function M.setup_directories(project_name, lang_config)
    if type(project_name) ~= "string" or project_name == "" then
        error("[Gathering Phase Error]: 'project_name' is missing, invalid, or empty.")
    end
    if type(lang_config) ~= "table" then
        error("[Gathering Phase Error]: 'lang_config' is missing or invalid.")
    end

    local current_dir = vim.fn.getcwd()
    if not current_dir or current_dir == "" then
        error("[Gathering Phase Error]: Failed to get current working directory.")
    end

    local parent_dir = vim.fn.fnamemodify(current_dir, ":h")
    local export_dir = parent_dir .. "/" .. project_name .. "_VS_Export"
    local project_dir = export_dir .. "/" .. project_name
    
    local success, err = pcall(vim.fn.mkdir, project_dir, "p")
    if not success then
        error(string.format("[Gathering Phase Error]: Failed to create project directory at '%s'. Details: %s", project_dir, tostring(err)))
    end
    
    local project_ext = lang_config.project_extension or ".vcxproj"
    
    return {
        export_dir = export_dir,
        project_dir = project_dir,
        sln_path = export_dir .. "/" .. project_name .. ".sln",
        project_file_path = project_dir .. "/" .. project_name .. project_ext,
        filters_path = project_ext == ".vcxproj" and (project_dir .. "/" .. project_name .. ".vcxproj.filters") or nil
    }
end

function M.copy_and_find_files(project_dir, extensions)
    if type(project_dir) ~= "string" or project_dir == "" then
        error("[Gathering Phase Error]: 'project_dir' is missing, invalid, or empty.")
    end
    if type(extensions) ~= "table" or #extensions == 0 then
        error("[Gathering Phase Error]: 'extensions' list is missing or empty.")
    end

    local files = {}
    for _, ext in ipairs(extensions) do
        vim.list_extend(files, vim.fn.glob(ext, false, true))
    end

    local unique_files = {}
    for _, filepath in ipairs(files) do
        if not filepath:match("^[bB]uild[/\\]") and not filepath:match("^[oO]ut[/\\]") and not filepath:match("%.vs[/\\]") then
            local filename = vim.fn.fnamemodify(filepath, ":t")
            local dest = project_dir .. "/" .. filename
            
            local copy_success, copy_err = vim.loop.fs_copyfile(filepath, dest)
            if not copy_success then
                error(string.format("[Gathering Phase Error]: Failed to copy file '%s' to '%s'. Details: %s", filepath, dest, tostring(copy_err)))
            end
            
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