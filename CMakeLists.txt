cmake_minimum_required(VERSION 3.4 FATAL_ERROR)

project(AnyDSL)

list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/cmake/modules)

get_filename_component(AnyDSL_CONTRIB_DIR ${CMAKE_CURRENT_SOURCE_DIR}/contrib ABSOLUTE)
set(AnyDSL_REMOTE_URL "https://github.com/AnyDSL" CACHE STRING "url used by git to checkout AnyDSL packages")
set(AnyDSL_DEFAULT_BRANCH master CACHE STRING "the default branch of thorin, impala, etc.")
set(AnyDSL_LLVM_REQUIRED ON CACHE BOOL "forces the availability of LLVM to build AnyDSL packages")

message(STATUS "AnyDSL contrib directory: ${AnyDSL_CONTRIB_DIR}")
message(STATUS "AnyDSL remote url: ${AnyDSL_REMOTE_URL}")
message(STATUS "AnyDSL default branch: ${AnyDSL_DEFAULT_BRANCH}")

# Half
find_package(Half 1.11.0 REQUIRED)
message(STATUS "Half_DIR: ${Half_DIR}")

# LLVM and clang
if(AnyDSL_LLVM_REQUIRED AND NOT CMAKE_DISABLE_FIND_PACKAGE_LLVM)
    set(LLVM_REQUIRED "REQUIRED")
endif()
set(AnyDSL_RV_BRANCH release_80 CACHE STRING "LLVM is build with this branch of RV")
find_package(LLVM 8.0.0 ${LLVM_REQUIRED})
message(STATUS "LLVM_DIR: ${LLVM_DIR}")
message(STATUS "LLVM_ENABLE_RTTI: ${LLVM_ENABLE_RTTI}")

include(cmake/fetch-package.cmake)

# AnyDSL_thorin
fetch_anydsl_package(AnyDSL_thorin_DIR thorin thorin ${AnyDSL_REMOTE_URL}/thorin)
message(STATUS "AnyDSL_thorin_DIR: ${AnyDSL_thorin_DIR}")
set(Thorin_DIR ${AnyDSL_thorin_DIR})
if(TARGET LLVM-Build)
    add_dependencies(thorin LLVM-Build)
endif()

# AnyDSL_impala
fetch_anydsl_package(AnyDSL_impala_DIR impala impala ${AnyDSL_REMOTE_URL}/impala)
message(STATUS "AnyDSL_impala_DIR: ${AnyDSL_impala_DIR}")
set(Impala_DIR ${AnyDSL_impala_DIR})

# AnyDSL_runtime
fetch_anydsl_package(AnyDSL_runtime_DIR runtime AnyDSL_runtime ${AnyDSL_REMOTE_URL}/runtime)
message(STATUS "AnyDSL_runtime_DIR: ${AnyDSL_runtime_DIR}")

add_custom_target(pull COMMENT ">>> pull all AnyDSL packages")
add_dependencies(pull pull-thorin pull-impala pull-runtime)

add_subdirectory(applications)
