local M = {}

function M.execute_msbuild(sln_path, project_name)
    print("Compiling project using MSBuild (Neovim will pause for a few seconds)...")
    local ps_script = string.format([[
        $vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
        if (Test-Path $vswhere) {
            $msbuild = & $vswhere -latest -requires Microsoft.Component.MSBuild -find MSBuild\**\Bin\MSBuild.exe | Select-Object -First 1
            if ($msbuild) {
                & "$msbuild" "%s" -p:Configuration=Debug -p:Platform=x64 -v:m
                exit $LASTEXITCODE
            }
        }
        exit 1
    ]], sln_path)

    local cmd = { "powershell", "-NoProfile", "-Command", ps_script }
    local result = vim.fn.system(cmd)
    
    if vim.v.shell_error == 0 then
        print("Build Successful! Generated .exe and folders in: " .. project_name .. "_VS_Export")
    else
        print("Build failed. Open " .. project_name .. ".sln in Visual Studio to investigate.")
    end
end

return M