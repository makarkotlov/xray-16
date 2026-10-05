add_executable(xrCDBOpcode13Tests CollisionQueries.cpp CacheFailures.cpp LegacyCache.cpp RayEndpoints.cpp)
target_include_directories(xrCDBOpcode13Tests PRIVATE "${XRAY_SOURCE_DIR}/src")
target_link_libraries(xrCDBOpcode13Tests PRIVATE xrCDB xrCore xrMiscMath)

function(add_collision_test name policy)
    # Each policy runs in its own process: the engine caches its routing policy.
    # Separate directories also keep parallel tests from sharing cache files.
    file(MAKE_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/${name}")
    add_test(NAME ${name} COMMAND xrCDBOpcode13Tests ${ARGN})
    set_tests_properties(${name} PROPERTIES
        TIMEOUT 60
        ENVIRONMENT "XRAY_COLLISION_QUERIES=${policy}"
        WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/${name}"
    )
endfunction()

add_collision_test(xrCDB.opcode13_queries opcode)
add_collision_test(xrCDB.opcode13_threaded_queries opcode -mt_cdb)
if (XRAY_COLLISION_EMBREE)
    foreach(policy hybrid embree)
        add_collision_test(xrCDB.${policy}_queries ${policy})
        add_collision_test(xrCDB.${policy}_threaded_queries ${policy} -mt_cdb)
    endforeach()
    if (MSVC)
        add_test(NAME xrCDB.embree_master_gold_link
            COMMAND "${CMAKE_COMMAND}"
                "-DXRAY_SOURCE_DIR=${XRAY_SOURCE_DIR}"
                "-DXRAY_EMBREE_ROOT=${XRAY_EMBREE_ROOT}"
                "-DXRAY_MSBUILD=${CMAKE_VS_MSBUILD_COMMAND}"
                "-DTEST_OUTPUT_DIR=${CMAKE_CURRENT_BINARY_DIR}/embree_master_gold_link"
                -P "${XRAY_SOURCE_DIR}/misc/windows/opcode/tests/CheckEmbreeStaticLink.cmake"
        )
        set_tests_properties(xrCDB.embree_master_gold_link PROPERTIES TIMEOUT 60)
    endif()
endif()

add_executable(xrCDBBenchmark Benchmark.cpp)
target_include_directories(xrCDBBenchmark PRIVATE "${XRAY_SOURCE_DIR}/src")
target_link_libraries(xrCDBBenchmark PRIVATE xrCDB xrCore)
