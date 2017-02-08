
if (NOT SETUP_DIR)
    set(SETUP_DIR ${CMAKE_CURRENT_LIST_DIR})
endif()
get_filename_component(SETUP_DIR ${SETUP_DIR} ABSOLUTE)
if (CMAKE_BUILD_TYPE)
    set(CONFIGURATION_TYPES ${CMAKE_BUILD_TYPE})
elseif (NOT CONFIGURATION_TYPES)
    set(CONFIGURATION_TYPES Debug Release)
endif ()
message(STATUS "SETUP_DIR: ${SETUP_DIR}")
message(STATUS "GENERATOR: ${GENERATOR}")
message(STATUS "CONFIGURATION_TYPES: ${CONFIGURATION_TYPES}")

if (CMAKE_BUILD_TYPE)
    set (SPECIFY_BUILD_TYPE "-DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}")
endif ()
if (GENERATOR)
    set(SPECIFY_GENERATOR -G ${GENERATOR})
endif ()

find_package(Git REQUIRED)

include(common.cmake)


FIND_PATH (AnyDSL_runtime_DIR anydsl_runtime-config.cmake
    PATHS
        ${AnyDSL_runtime_DIR}
        $ENV{AnyDSL_runtime_DIR}
        ${SETUP_DIR}/runtime/build
    PATH_SUFFIXES
        share/AnyDSL_runtime/cmake
)
message ( STATUS "AnyDSL_runtime_DIR: ${AnyDSL_runtime_DIR}" )

FIND_PATH (IMPALA_DIR impala-config.cmake
    PATHS
        ${IMPALA_DIR}
        $ENV{IMPALA_DIR}
        ${SETUP_DIR}/impala/build
    PATH_SUFFIXES
        share/impala/cmake
)
message ( STATUS "IMPALA_DIR: ${IMPALA_DIR}" )

SET ( STINCILLA_URL "https://github.com/AnyDSL/stincilla" )

clone_repository(stincilla ${STINCILLA_URL} cmake-for-jenkins)
set (VALIDATE_BACKENDS cpu )

foreach (_be ${VALIDATE_BACKENDS})
    configure_build(stincilla/build_${_be}
        -DIMPALA_DIR=${IMPALA_DIR}
        -DAnyDSL_runtime_DIR=${AnyDSL_runtime_DIR}
        -DBACKEND=${_be})
    compile(stincilla/build_${_be} --clean-first)
    run_tests(stincilla/build_${_be})
endforeach()
