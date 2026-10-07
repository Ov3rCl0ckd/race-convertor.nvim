local M = {}

M.registry = {
    ["2019"] = {
        sln_header_version = "16",
        sln_full_version = "16.0.28729.0",
        vcxproj_version = "16.0",
        cpp_toolset = "v142"
    },
    ["2022"] = {
        sln_header_version = "17",
        sln_full_version = "17.0.31903.59",
        vcxproj_version = "17.0",
        cpp_toolset = "v143" -- Adjusted to standard v143 for VS2022, but handles correctly
    },
    ["2026"] = {
        sln_header_version = "18", -- Speculative version for future VS2026
        sln_full_version = "18.0.0.0",
        vcxproj_version = "18.0",
        cpp_toolset = "v145" -- Preserved your original v145 toolset reference here
    }
}

return M