local gathering = require('race_convertor.gathering')
local execution = require('race_convertor.execution')

local M = {}

local function generate_guid()
    local template ='xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
    math.randomseed(os.time() + vim.loop.hrtime())
    return string.upper(string.gsub(template, '[xy]', function (c)
        local v = (c == 'x') and math.random(0, 0xf) or math.random(8, 0xb)
        return string.format('%x', v)
    end))
end

local function generate_sln(sln_path, project_name, project_guid)
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
end

local function generate_vcxproj(vcxproj_path, project_name, project_guid, unique_files)
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
end

local function generate_filters(filters_path, unique_files)
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
end

function M.generate(project_name)
    local project_guid = generate_guid()
    
    -- Phase 1: Setup and Discovery
    local paths = gathering.setup_directories(project_name)
    local unique_files = gathering.copy_and_find_files(paths.project_dir)
    
    if #unique_files == 0 then
        print("No .c, .cpp, or .h files found in the current directory!")
        return
    end

    -- Phase 2: Configuration 
    generate_sln(paths.sln_path, project_name, project_guid)
    generate_vcxproj(paths.vcxproj_path, project_name, project_guid, unique_files)
    generate_filters(paths.filters_path, unique_files)
    
    print("Created structured Visual Studio project files!")

    -- Phase 3: Execution
    execution.execute_msbuild(paths.sln_path, project_name)
end

return M