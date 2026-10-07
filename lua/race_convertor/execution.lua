local M = {}

function M.execute_msbuild(sln_path, project_name)
    if type(sln_path) ~= "string" or sln_path == "" then
        error("[Execution Phase Error]: 'sln_path' is missing, invalid, or empty.")
    end

    print("Compiling project using MSBuild (Neovim will pause for a few seconds)...")
    local ps_script = string.format([[
        $vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
        if (-not (Test-Path $vswhere)) {
            Write-Error "vswhere.exe not found at: $vswhere"
            exit 2
        }

        $msbuild = & $vswhere -latest -requires Microsoft.Component.MSBuild -find MSBuild\**\Bin\MSBuild.exe | Select-Object -First 1
        if (-not $msbuild) {
            Write-Error "MSBuild.exe could not be found via vswhere. Please check your Visual Studio installation."
            exit 3
        }

        & "$msbuild" "%s" -p:Configuration=Debug -p:Platform=x64 -v:m
        exit $LASTEXITCODE
    ]], sln_path)

    local cmd = { "powershell", "-NoProfile", "-Command", ps_script }
    local result = vim.fn.system(cmd)
    
    if vim.v.shell_error == 0 then
        print("Build Successful! Generated .exe and folders in: " .. project_name .. "_VS_Export")
    else
        print(string.format("\n[Execution Phase Error]: MSBuild failed with exit code: %s", tostring(vim.v.shell_error)))
        print("--- PowerShell / MSBuild Output ---")
        print(result)
        print("-----------------------------------")
        print("Action Required: Open " .. project_name .. ".sln in Visual Studio to investigate the build errors further.")
    end
end

return M