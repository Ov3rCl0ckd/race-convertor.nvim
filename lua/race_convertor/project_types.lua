local cpp_generator = require('race_convertor.generators.cpp')

local M = {}

M.registry = {
    cpp = {
        id = "cpp",
        extensions = { "**/*.c", "**/*.cpp", "**/*.h", "**/*.hpp" },
        project_extension = ".vcxproj",
        sln_type_guid = "8BC9CEB8-8B4A-11D0-8D11-00A0C91BC942",
        generate_project_files = function(paths, project_name, project_guid, unique_files, vs_config)
            cpp_generator.generate(paths, project_name, project_guid, unique_files, vs_config)
        end
    }
}

return M