
set(AnyDSL_PKG_LLVM_VERSION "16.0.6" CACHE STRING "LLVM version of AnyDSL")
set(AnyDSL_PKG_RV_TAG "origin/release/16.x" CACHE STRING "LLVM is build with this git tag of RV")

set(AnyDSL_PKG_LLVM_URL "https://github.com/llvm/llvm-project/releases/download/llvmorg-${AnyDSL_PKG_LLVM_VERSION}/llvm-project-${AnyDSL_PKG_LLVM_VERSION}.src.tar.xz" CACHE STRING "where to download LLVM")
set(AnyDSL_PKG_RV_URL "https://github.com/cdl-saarland/rv" CACHE STRING "where to clone RV")

include(FetchContent)

FetchContent_Declare(RV
    GIT_REPOSITORY ${AnyDSL_PKG_RV_URL}
    GIT_TAG ${AnyDSL_PKG_RV_TAG}
    GIT_SUBMODULES vecmath/sleef
)
message(STATUS "Make RV available ...")
FetchContent_GetProperties(RV)
if(NOT rv_POPULATED)
    FetchContent_Populate(RV)
endif()

FetchContent_Declare(LLVM
    URL  ${AnyDSL_PKG_LLVM_URL}
    PATCH_COMMAND ${CMAKE_COMMAND} -D LLVM_VERSION=${AnyDSL_PKG_LLVM_VERSION} -P ${CMAKE_CURRENT_SOURCE_DIR}/patches/llvm/apply.cmake
)
set(LLVM_TARGETS_TO_BUILD "AArch64;AMDGPU;ARM;NVPTX;X86" CACHE STRING "limit targets of LLVM")
set(LLVM_ENABLE_PROJECTS "clang;lld" CACHE STRING "enable projects of LLVM")
set(LLVM_EXTERNAL_PROJECTS "rv" CACHE STRING "external projects of LLVM")
set(LLVM_EXTERNAL_RV_SOURCE_DIR ${rv_SOURCE_DIR})
set(LLVM_INCLUDE_TESTS OFF)
set(LLVM_ENABLE_RTTI ON)

message(STATUS "Make LLVM available ...")
FetchContent_GetProperties(LLVM)

if(NOT llvm_POPULATED)
    FetchContent_Populate(LLVM)
endif()

message(STATUS "llvm_SOURCE_DIR: ${llvm_SOURCE_DIR}")
add_subdirectory(${llvm_SOURCE_DIR}/llvm ${llvm_BINARY_DIR})

find_path(LLVM_DIR LLVMConfig.cmake
    PATHS
        ${llvm_BINARY_DIR}
    PATH_SUFFIXES
        lib/cmake/llvm
        share/llvm/cmake
)

find_path(Clang_DIR ClangConfig.cmake
    PATHS
        ${llvm_BINARY_DIR}
        ${CMAKE_BINARY_DIR}
        ${CMAKE_CURRENT_BINARY_DIR}
    PATH_SUFFIXES
        lib/cmake/clang
        share/clang/cmake
)

set(LLVM_DIR ${llvm_BINARY_DIR}/lib/cmake/llvm)
