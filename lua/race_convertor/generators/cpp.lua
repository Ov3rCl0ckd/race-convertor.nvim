local M = {}

local function generate_vcxproj(vcxproj_path, project_name, project_guid, unique_files, vs_config)
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
    <VCProjectVersion>%s</VCProjectVersion>
    <Keyword>Win32Proj</Keyword>
    <ProjectGuid>{%s}</ProjectGuid>
    <RootNamespace>%s</RootNamespace>
    <WindowsTargetPlatformVersion>10.0</WindowsTargetPlatformVersion>
  </PropertyGroup>
  <Import Project="$(VCTargetsPath)\Microsoft.Cpp.Default.props" />
  <PropertyGroup Condition="'$(Configuration)|$(Platform)'=='Debug|x64'" Label="Configuration">
    <ConfigurationType>Application</ConfigurationType>
    <UseDebugLibraries>true</UseDebugLibraries>
    <PlatformToolset>%s</PlatformToolset>
    <CharacterSet>Unicode</CharacterSet>
  </PropertyGroup>
  <PropertyGroup Condition="'$(Configuration)|$(Platform)'=='Release|x64'" Label="Configuration">
    <ConfigurationType>Application</ConfigurationType>
    <UseDebugLibraries>false</UseDebugLibraries>
    <PlatformToolset>%s</PlatformToolset>
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
]], vs_config.vcxproj_version, project_guid, project_name, vs_config.cpp_toolset, vs_config.cpp_toolset, item_group)

    local vcxproj_file, err = io.open(vcxproj_path, "w")
    if vcxproj_file then
        vcxproj_file:write(vcxproj_content)
        vcxproj_file:close()
    else
        error(string.format("[Chamber Phase Error]: Failed to open vcxproj file for writing at '%s'. Details: %s", vcxproj_path, tostring(err)))
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

    local filters_file, err = io.open(filters_path, "w")
    if filters_file then
        filters_file:write(filters_content)
        filters_file:close()
    else
        error(string.format("[Chamber Phase Error]: Failed to open filters file for writing at '%s'. Details: %s", filters_path, tostring(err)))
    end
end

function M.generate(paths, project_name, project_guid, unique_files, vs_config)
    generate_vcxproj(paths.project_file_path, project_name, project_guid, unique_files, vs_config)
    generate_filters(paths.filters_path, unique_files)
end

return M