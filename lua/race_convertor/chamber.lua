local gathering = require('race_convertor.gathering')
local execution = require('race_convertor.execution')
local project_types = require('race_convertor.project_types')
local vs_versions = require('race_convertor.vs_versions')

local M = {}

local function generate_guid()
    local template ='xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
    math.randomseed(os.time() + vim.loop.hrtime())
    return string.upper(string.gsub(template, '[xy]', function (c)
        local v = (c == 'x') and math.random(0, 0xf) or math.random(8, 0xb)
        return string.format('%x', v)
    end))
end

local function generate_sln(sln_path, project_name, project_guid, lang_config, vs_config)
    local sln_content = string.format([[
Microsoft Visual Studio Solution File, Format Version 12.00
# Visual Studio Version %s
VisualStudioVersion = %s
MinimumVisualStudioVersion = 10.0.40219.1
Project("{%s}") = "%s", "%s\%s%s", "{%s}"
EndProject
Global
	GlobalSection(SolutionConfigurationPlatforms) = preSolution
		Debug|x64 = Debug|x64
		Release|x64 = Release|x64
	EndGlobalSection
	GlobalSection(ProjectConfigurationPlatforms) = postSolution
		{%s}.Debug|x64.ActiveCfg = Debug|x64
		{%s}.Debug|x64.Build.0 = Debug|x64
		{%s}.Release|x64.ActiveCfg = Release|x64
		{%s}.Release|x64.Build.0 = Release|x64
	EndGlobalSection
	GlobalSection(SolutionProperties) = preSolution
		HideSolutionNode = FALSE
	EndGlobalSection
EndGlobal
]], vs_config.sln_header_version, vs_config.sln_full_version, lang_config.sln_type_guid, project_name, project_name, project_name, lang_config.project_extension, project_guid, project_guid, project_guid, project_guid, project_guid)

    local sln_file, err = io.open(sln_path, "w")
    if sln_file then
        sln_file:write(sln_content)
        sln_file:close()
    else
        error(string.format("[Chamber Phase Error]: Failed to open Solution file for writing at '%s'. Details: %s", sln_path, tostring(err)))
    end
end

function M.generate(project_name, language, vs_version)
    if type(project_name) ~= "string" or project_name == "" then
        error("[Chamber Phase Error]: 'project_name' must be provided as a non-empty string.")
    end

    language = language or "cpp"
    local lang_config = project_types.registry[language]
    if not lang_config then
        error(string.format("[Chamber Phase Error]: Unsupported language '%s'. Available types are: cpp", language))
    end

    vs_version = vs_version or "2022"
    local vs_config = vs_versions.registry[tostring(vs_version)]
    if not vs_config then
        error(string.format("[Chamber Phase Error]: Unsupported Visual Studio version '%s'.", tostring(vs_version)))
    end

    local project_guid = generate_guid()
    
    -- Phase 1: Setup and Discovery
    local paths = gathering.setup_directories(project_name, lang_config)
    if type(paths) ~= "table" then
        error("[Chamber Phase Error]: gathering.setup_directories did not return a valid paths table.")
    end

    local unique_files = gathering.copy_and_find_files(paths.project_dir, lang_config.extensions)
    if type(unique_files) ~= "table" then
        error("[Chamber Phase Error]: gathering.copy_and_find_files did not return a valid table of files.")
    end

    if #unique_files == 0 then
        print(string.format("[Warning]: No files found for language '%s' in '%s'!", language, vim.fn.getcwd()))
        return
    end

    -- Phase 2: Configuration 
    generate_sln(paths.sln_path, project_name, project_guid, lang_config, vs_config)
    lang_config.generate_project_files(paths, project_name, project_guid, unique_files, vs_config)
    
    print(string.format("Created structured Visual Studio %s project files for %s!", vs_version, language))

    -- Phase 3: Execution
    execution.execute_msbuild(paths.sln_path, project_name)
end

return M