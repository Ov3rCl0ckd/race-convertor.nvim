local M = {}

local function generate_guid()
    local template ='xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
    math.randomseed(os.time() + vim.loop.hrtime())
    return string.upper(string.gsub(template, '[xy]', function (c)
        local v = (c == 'x') and math.random(0, 0xf) or math.random(8, 0xb)
        return string.format('%x', v)
    end))
end

function M.generate(project_name)
    local project_guid = generate_guid()
    
    local current_dir = vim.fn.getcwd()
    local parent_dir = vim.fn.fnamemodify(current_dir, ":h")
    local export_dir = parent_dir .. "/" .. project_name .. "_VS_Export"
    local project_dir = export_dir .. "/" .. project_name

    vim.fn.mkdir(project_dir, "p")

    -- 2. Find all C/C++ files
    local files = vim.fn.glob("**/*.c", false, true)
    vim.list_extend(files, vim.fn.glob("**/*.cpp", false, true))
    vim.list_extend(files, vim.fn.glob("**/*.h", false, true))
    vim.list_extend(files, vim.fn.glob("**/*.hpp", false, true))

    if #files == 0 then
        print("No .c, .cpp, or .h files found in the current directory!")
        return
    end

    local unique_files = {}
    for _, filepath in ipairs(files) do
        if not filepath:match("^[bB]uild[/\\]") and not filepath:match("^[oO]ut[/\\]") and not filepath:match("%.vs[/\\]") then
            -- We extract just the filename so they sit cleanly in the project directory
            local filename = vim.fn.fnamemodify(filepath, ":t")
            local dest = project_dir .. "/" .. filename
            
            vim.loop.fs_copyfile(filepath, dest)
            
            -- Keep track to add to the XML
            local exists = false
            for _, v in ipairs(unique_files) do
                if v == filename then exists = true end
            end
            if not exists then table.insert(unique_files, filename) end
        end
    end

    -- 4. Generate the .sln
    local sln_path = export_dir .. "/" .. project_name .. ".sln"
    local sln_content = string.format([[
Microsoft Visual Studio Solution File, Format Version 12.00
# Visual Studio Version 17
VisualStudioVersion = 17.0.31903.59
MinimumVisualStudioVersion = 10.0.40219.1
Project("{8BC9CEB8-8B4A-11D0-8D11-00A0C91BC942}") = "%s", "%s\%s.vcxproj", "{%s}"
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
]], project_name, project_name, project_name, project_guid, project_guid, project_guid, project_guid, project_guid)

    local sln_file = io.open(sln_path, "w")
    if sln_file then
        sln_file:write(sln_content)
        sln_file:close()
    end

    -- 5. Generate the .vcxproj
    local vcxproj_path = project_dir .. "/" .. project_name .. ".vcxproj"
    
    local item_group = "<ItemGroup>\n"
    for _, file in ipairs(unique_files) do
        if file:match("%.h$") or file:match("%.hpp$") then
            item_group = item_group .. '    <ClInclude Include="' .. file .. '" />\n'
        else
            item_group = item_group .. '    <ClCompile Include="' .. file .. '" />\n'
        end
    end
    item_group = item_group .. "  </ItemGroup>"

    local vcxproj_content = string.format([[
<?xml version="1.0" encoding="utf-8"?>
<Project DefaultTargets="Build" xmlns="http://schemas.microsoft.com/developer/msbuild/2003">
  <ItemGroup Label="ProjectConfigurations">
    <ProjectConfiguration Include="Debug|x64">
      <Configuration>Debug</Configuration>
      <Platform>x64</Platform>
    </ProjectConfiguration>
    <ProjectConfiguration Include="Release|x64">
      <Configuration>Release</Configuration>
      <Platform>x64</Platform>
    </ProjectConfiguration>
  </ItemGroup>
  <PropertyGroup Label="Globals">
    <VCProjectVersion>17.0</VCProjectVersion>
    <Keyword>Win32Proj</Keyword>
    <ProjectGuid>{%s}</ProjectGuid>
    <RootNamespace>%s</RootNamespace>
    <WindowsTargetPlatformVersion>10.0</WindowsTargetPlatformVersion>
  </PropertyGroup>
  <Import Project="$(VCTargetsPath)\Microsoft.Cpp.Default.props" />
  <PropertyGroup Condition="'$(Configuration)|$(Platform)'=='Debug|x64'" Label="Configuration">
    <ConfigurationType>Application</ConfigurationType>
    <UseDebugLibraries>true</UseDebugLibraries>
    <PlatformToolset>v145</PlatformToolset>
    <CharacterSet>Unicode</CharacterSet>
  </PropertyGroup>
  <PropertyGroup Condition="'$(Configuration)|$(Platform)'=='Release|x64'" Label="Configuration">
    <ConfigurationType>Application</ConfigurationType>
    <UseDebugLibraries>false</UseDebugLibraries>
    <PlatformToolset>v145</PlatformToolset>
    <WholeProgramOptimization>true</WholeProgramOptimization>
    <CharacterSet>Unicode</CharacterSet>
  </PropertyGroup>
  <Import Project="$(VCTargetsPath)\Microsoft.Cpp.props" />
  <ImportGroup Label="ExtensionSettings">
  </ImportGroup>
  <ImportGroup Label="Shared">
  </ImportGroup>
  <ImportGroup Label="PropertySheets" Condition="'$(Configuration)|$(Platform)'=='Debug|x64'">
    <Import Project="$(UserRootDir)\Microsoft.Cpp.$(Platform).user.props" Condition="exists('$(UserRootDir)\Microsoft.Cpp.$(Platform).user.props')" Label="LocalAppDataPlatform" />
  </ImportGroup>
  <ImportGroup Label="PropertySheets" Condition="'$(Configuration)|$(Platform)'=='Release|x64'">
    <Import Project="$(UserRootDir)\Microsoft.Cpp.$(Platform).user.props" Condition="exists('$(UserRootDir)\Microsoft.Cpp.$(Platform).user.props')" Label="LocalAppDataPlatform" />
  </ImportGroup>
  <PropertyGroup Label="UserMacros" />
  <ItemDefinitionGroup Condition="'$(Configuration)|$(Platform)'=='Debug|x64'">
    <ClCompile>
      <WarningLevel>Level3</WarningLevel>
      <SDLCheck>true</SDLCheck>
      <PreprocessorDefinitions>_DEBUG;_CONSOLE;%%(PreprocessorDefinitions)</PreprocessorDefinitions>
      <ConformanceMode>true</ConformanceMode>
      <LanguageStandard>stdcpp20</LanguageStandard>
    </ClCompile>
    <Link>
      <SubSystem>Console</SubSystem>
      <GenerateDebugInformation>true</GenerateDebugInformation>
    </Link>
  </ItemDefinitionGroup>
  <ItemDefinitionGroup Condition="'$(Configuration)|$(Platform)'=='Release|x64'">
    <ClCompile>
      <WarningLevel>Level3</WarningLevel>
      <FunctionLevelLinking>true</FunctionLevelLinking>
      <IntrinsicFunctions>true</IntrinsicFunctions>
      <SDLCheck>true</SDLCheck>
      <PreprocessorDefinitions>NDEBUG;_CONSOLE;%%(PreprocessorDefinitions)</PreprocessorDefinitions>
      <ConformanceMode>true</ConformanceMode>
      <LanguageStandard>stdcpp20</LanguageStandard>
    </ClCompile>
    <Link>
      <SubSystem>Console</SubSystem>
      <EnableCOMDATFolding>true</EnableCOMDATFolding>
      <OptimizeReferences>true</OptimizeReferences>
      <GenerateDebugInformation>true</GenerateDebugInformation>
    </Link>
  </ItemDefinitionGroup>
%s
  <Import Project="$(VCTargetsPath)\Microsoft.Cpp.targets" />
  <ImportGroup Label="ExtensionTargets">
  </ImportGroup>
</Project>
]], project_guid, project_name, item_group)

    local vcxproj_file = io.open(vcxproj_path, "w")
    if vcxproj_file then
        vcxproj_file:write(vcxproj_content)
        vcxproj_file:close()
    end

    -- 6. Generate the .vcxproj.filters file for Solution Explorer magic
    local filters_path = project_dir .. "/" .. project_name .. ".vcxproj.filters"
    
    local filter_item_group = "  <ItemGroup>\n"
    for _, file in ipairs(unique_files) do
        if file:match("%.h$") or file:match("%.hpp$") then
            filter_item_group = filter_item_group .. string.format([[    <ClInclude Include="%s">
      <Filter>Header Files</Filter>
    </ClInclude>
]], file)
        else
            filter_item_group = filter_item_group .. string.format([[    <ClCompile Include="%s">
      <Filter>Source Files</Filter>
    </ClCompile>
]], file)
        end
    end
    filter_item_group = filter_item_group .. "  </ItemGroup>\n"

    local filters_content = string.format([[
<?xml version="1.0" encoding="utf-8"?>
<Project ToolsVersion="4.0" xmlns="http://schemas.microsoft.com/developer/msbuild/2003">
  <ItemGroup>
    <Filter Include="Source Files">
      <UniqueIdentifier>{4FC737F1-C7A5-4376-A066-2A32D752A2FF}</UniqueIdentifier>
      <Extensions>cpp;c;cc;cxx;c++;cppm;ixx;def;odl;idl;hpj;bat;asm;asmx</Extensions>
    </Filter>
    <Filter Include="Header Files">
      <UniqueIdentifier>{93995380-89BD-4b04-88EB-625FBE52EBFB}</UniqueIdentifier>
      <Extensions>h;hh;hpp;hxx;h++;hm;inl;inc;ipp;xsd</Extensions>
    </Filter>
  </ItemGroup>
%s
</Project>
]], filter_item_group)

    local filters_file = io.open(filters_path, "w")
    if filters_file then
        filters_file:write(filters_content)
        filters_file:close()
    end

    print("Created structured Visual Studio project files!")

    -- 7. Compile synchronously
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