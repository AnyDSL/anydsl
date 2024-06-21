cmake_minimum_required(VERSION 3.17 FATAL_ERROR)

project(AnyDSL)

set(AnyDSL_REMOTE_URL "https://github.com/AnyDSL" CACHE STRING "url used by git to checkout AnyDSL packages")
set(AnyDSL_DEFAULT_BRANCH master CACHE STRING "the default branch of thorin, impala, etc.")
message(STATUS "AnyDSL remote url: ${AnyDSL_REMOTE_URL}")
message(STATUS "AnyDSL default branch: ${AnyDSL_DEFAULT_BRANCH}")

set(AnyDSL_PKG_Half_AUTOBUILD OFF CACHE BOOL "forces the availability of Half to build AnyDSL packages")
set(AnyDSL_PKG_LLVM_AUTOBUILD OFF CACHE BOOL "forces the availability of LLVM to build AnyDSL packages")
set(AnyDSL_PKG_RV_AUTOBUILD   OFF CACHE BOOL "forces the availability of RV to build AnyDSL packages")

# Half
if(AnyDSL_PKG_Half_AUTOBUILD AND NOT CMAKE_DISABLE_FIND_PACKAGE_Half)
    include(cmake/half-package.cmake)
endif()
if(Half_DIR)
    message(STATUS "Half_DIR: ${Half_DIR}")
else()
    message(STATUS "Half not found.")
endif()

# LLVM and clang
if(AnyDSL_PKG_LLVM_AUTOBUILD AND NOT CMAKE_DISABLE_FIND_PACKAGE_LLVM)
    include(cmake/llvm-package.cmake)
endif()
if(AnyDSL_PKG_RV_AUTOBUILD)
    include(cmake/rv-package.cmake)
endif()
find_package(LLVM QUIET)
if(LLVM_FOUND)
    message(STATUS "LLVM_DIR: ${LLVM_DIR}")
    message(STATUS "LLVM_VERSION: ${LLVM_VERSION}")
    message(STATUS "LLVM_ENABLE_RTTI: ${LLVM_ENABLE_RTTI}")
    message(STATUS "LLVM_LINK_LLVM_DYLIB: ${LLVM_LINK_LLVM_DYLIB}")
else()
    message(STATUS "LLVM not found.")
endif()


include(cmake/fetch-package.cmake)

# AnyDSL_thorin
fetch_anydsl_package(AnyDSL_thorin_DIR thorin thorin ${AnyDSL_REMOTE_URL}/thorin)
message(STATUS "AnyDSL_thorin_DIR: ${AnyDSL_thorin_DIR}")
set(Thorin_DIR ${AnyDSL_thorin_DIR})
# TODO: this actually fixes missing dependency in thorin to include llvm/IR/Attributes.inc
if(TARGET intrinsics_gen)
    add_dependencies(thorin intrinsics_gen)
endif()


# AnyDSL_impala
fetch_anydsl_package(AnyDSL_impala_DIR impala impala ${AnyDSL_REMOTE_URL}/impala)
message(STATUS "AnyDSL_impala_DIR: ${AnyDSL_impala_DIR}")
set(Impala_DIR ${AnyDSL_impala_DIR})

# AnyDSL_artic
fetch_anydsl_package(AnyDSL_artic_DIR artic artic ${AnyDSL_REMOTE_URL}/artic)
message(STATUS "AnyDSL_artic_DIR: ${AnyDSL_artic_DIR}")
set(Artic_DIR ${AnyDSL_artic_DIR})

# AnyDSL_runtime
fetch_anydsl_package(AnyDSL_runtime_DIR runtime AnyDSL_runtime ${AnyDSL_REMOTE_URL}/runtime)
message(STATUS "AnyDSL_runtime_DIR: ${AnyDSL_runtime_DIR}")
# this triggers the build of clang that is required for the anydsl_runtime_wrap() macro of the runtime
# TODO: actually clang shall be build for impala/artic as they require further processing of their output
if(TARGET clang)
    add_dependencies(runtime clang)
endif()


add_custom_target(pull COMMENT ">>> pull all AnyDSL packages")
add_dependencies(pull pull-thorin pull-impala pull-artic pull-runtime)

add_subdirectory(applications)
