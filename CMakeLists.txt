cmake_minimum_required(VERSION 3.1 FATAL_ERROR)

project(AnyDSL)

list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/cmake/modules)

include(common.cmake)

get_filename_component(CONTRIB_DIR ${CMAKE_CURRENT_SOURCE_DIR}/contrib ABSOLUTE)
set(AnyDSL_DEFAULT_BRANCH master CACHE STRING "the default branch of thorin, impala, etc.")
set(AnyDSL_LLVM_REQUIRED ON CACHE BOOL "forces the availability of LLVM to build AnyDSL packages")
if(CMAKE_GENERATOR STREQUAL "Unix Makefiles")
    set(AnyDSL_PARALLEL_BUILD "-j")
elseif(MSVC)
    set(AnyDSL_PARALLEL_BUILD "/maxcpucount")
endif()
set(AnyDSL_BUILD_FLAGS ${AnyDSL_BUILD_FLAGS} ${AnyDSL_PARALLEL_BUILD} CACHE STRING "additional flags passed to the build system")

message(STATUS "AnyDSL contrib directory: ${CONTRIB_DIR}")
message(STATUS "AnyDSL default branch: ${AnyDSL_DEFAULT_BRANCH}")
message(STATUS "AnyDSL build flags: ${AnyDSL_BUILD_FLAGS}")

# Half
find_package(Half 1.11.0 REQUIRED)
message(STATUS "Half_DIR: ${Half_DIR}")

# LLVM and clang
if(AnyDSL_LLVM_REQUIRED AND NOT CMAKE_DISABLE_FIND_PACKAGE_LLVM)
    set(LLVM_REQUIRED "REQUIRED")
endif()
find_package(LLVM 4.0.1 EXACT ${LLVM_REQUIRED})
message(STATUS "LLVM_DIR: ${LLVM_DIR}")

include(cmake/fetch-package.cmake)

# cdl-saarland/rv
# fetch_anydsl_package(RV_DIR rv rv https://github.com/cdl-saarland/rv ${CMAKE_CURRENT_SOURCE_DIR}/rv)
# message(STATUS "RV_DIR: ${RV_DIR}")

# AnyDSL_thorin
fetch_anydsl_package(AnyDSL_thorin_DIR thorin thorin https://github.com/AnyDSL/thorin)
message(STATUS "AnyDSL_thorin_DIR: ${AnyDSL_thorin_DIR}")
# preset of deprecated variables
set(Thorin_DIR ${AnyDSL_thorin_DIR})
set(THORIN_DIR ${AnyDSL_thorin_DIR})
if(TARGET LLVM)
    add_dependencies(thorin LLVM)
endif()

# AnyDSL_runtime
fetch_anydsl_package(AnyDSL_runtime_DIR runtime AnyDSL_runtime https://github.com/AnyDSL/runtime)
message(STATUS "AnyDSL_runtime_DIR: ${AnyDSL_runtime_DIR}")

# AnyDSL_impala
fetch_anydsl_package(AnyDSL_impala_DIR impala impala https://github.com/AnyDSL/impala)
message(STATUS "AnyDSL_impala_DIR: ${AnyDSL_impala_DIR}")
# preset of deprecated variables
set(Impala_DIR ${AnyDSL_impala_DIR})
set(IMPALA_DIR ${AnyDSL_impala_DIR})

if (CTest_CONFIG_URL)
    file(DOWNLOAD ${CTest_CONFIG_URL} ${CMAKE_CURRENT_SOURCE_DIR}/CTestConfig.cmake)
endif()
include(CTest)
