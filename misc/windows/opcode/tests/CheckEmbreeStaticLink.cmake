cmake_minimum_required(VERSION 3.23)

foreach(required XRAY_SOURCE_DIR XRAY_EMBREE_ROOT TEST_OUTPUT_DIR)
    if (NOT DEFINED ${required} OR "${${required}}" STREQUAL "")
        message(FATAL_ERROR "Set ${required} before running the native Embree static-link check.")
    endif()
endforeach()

if (NOT XRAY_MSBUILD)
    cmake_host_system_information(RESULT visual_studio_dir QUERY VS_17_DIR)
    unset(XRAY_MSBUILD)
    find_program(XRAY_MSBUILD NAMES MSBuild.exe
        HINTS "${visual_studio_dir}/MSBuild/Current/Bin" REQUIRED)
endif()

file(MAKE_DIRECTORY "${TEST_OUTPUT_DIR}")
execute_process(
    COMMAND "${XRAY_MSBUILD}" "${XRAY_SOURCE_DIR}/src/xrCDB/xrCDB.vcxproj"
        /nologo /v:minimal /t:CheckEmbreeStaticLink
        "/p:Configuration=Release Master Gold" /p:Platform=x64
        /p:XRAY_COLLISION_EMBREE=true
        "/p:XRAY_EMBREE_ROOT=${XRAY_EMBREE_ROOT}"
        "/p:SolutionDir=${XRAY_SOURCE_DIR}/src/"
        "/p:ForceImportAfterCppTargets=${CMAKE_CURRENT_LIST_DIR}/EmbreeStaticLink.targets"
        "/p:EmbreeSmokeOutput=${TEST_OUTPUT_DIR}"
    RESULT_VARIABLE build_result
    OUTPUT_VARIABLE build_stdout ERROR_VARIABLE build_stderr)
file(WRITE "${TEST_OUTPUT_DIR}/build.log" "${build_stdout}${build_stderr}")
if (NOT build_result STREQUAL "0")
    message(FATAL_ERROR "Native Embree static linking failed (${build_result}):\n${build_stdout}${build_stderr}")
endif()

execute_process(
    COMMAND "${CMAKE_COMMAND}" -E env "PATH=${XRAY_EMBREE_ROOT}/bin;$ENV{PATH}"
        "${TEST_OUTPUT_DIR}/EmbreeStaticConsumer.exe"
    RESULT_VARIABLE run_result
    OUTPUT_VARIABLE run_stdout ERROR_VARIABLE run_stderr)
file(WRITE "${TEST_OUTPUT_DIR}/run.log" "${run_stdout}${run_stderr}")
if (NOT run_result STREQUAL "0")
    message(FATAL_ERROR "Native Embree static-link executable failed (${run_result}):\n${run_stdout}${run_stderr}")
endif()
message(STATUS "Native Master Gold library resolves and runs Embree through its static consumer")
