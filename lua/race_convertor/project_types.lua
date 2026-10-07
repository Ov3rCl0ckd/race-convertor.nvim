local cpp_generator = require('race_convertor.generators.cpp')

local M = {}

M.registry = {
    cpp = {
        id = "cpp",
        extensions = { "**/*.c", "**/*.cpp", "**/*.h", "**/*.hpp" },
        project_extension = ".vcxproj",
        sln_type_guid = "8BC9CEB8-8B4A-11D0-8D11-00A0C91BC942",
        generate_project_files = cpp_generator.generate
    }
}

return M