
set(AnyDSL_PKG_LLVM_VERSION "10.0.1" CACHE STRING "LLVM version of AnyDSL")
set(AnyDSL_PKG_RV_TAG "origin/release/10.x" CACHE STRING "LLVM is build with this git tag of RV")

set(AnyDSL_PKG_LLVM_URL "https://github.com/llvm/llvm-project/releases/download/llvmorg-${AnyDSL_PKG_LLVM_VERSION}/llvm-project-${AnyDSL_PKG_LLVM_VERSION}.tar.xz" CACHE STRING "where to download LLVM")
set(AnyDSL_PKG_RV_URL "https://github.com/cdl-saarland/rv" CACHE STRING "where to clone RV")

if(${CMAKE_VERSION} VERSION_GREATER_EQUAL 3.20)
    message(WARNING "We experienced issues on some platforms using latest versions of CMake to build LLVM.")
endif()

include(FetchContent)

FetchContent_Declare(RV
    GIT_REPOSITORY ${AnyDSL_PKG_RV_URL}
    GIT_TAG ${AnyDSL_PKG_RV_TAG}
    GIT_SUBMODULES_RECURSE TRUE
)
message(STATUS "Make RV available ...")
FetchContent_GetProperties(RV)
if(NOT rv_POPULATED)
    FetchContent_Populate(RV)
endif()


FetchContent_Declare(LLVM
    URL  ${AnyDSL_PKG_LLVM_URL}
    PATCH_COMMAND ${CMAKE_COMMAND} -D LLVM_VERSION=${AnyDSL_PKG_LLVM_VERSION} -P ${CMAKE_CURRENT_SOURCE_DIR}/patches/llvm/apply.cmake
    SOURCE_SUBDIR llvm
)
set(LLVM_TARGETS_TO_BUILD "AArch64;AMDGPU;ARM;NVPTX;X86" CACHE STRING "limit targets of LLVM")
set(LLVM_ENABLE_PROJECTS "clang;lld" CACHE STRING "enable projects of LLVM")
set(LLVM_EXTERNAL_PROJECTS "rv" CACHE STRING "external projects of LLVM")
set(LLVM_EXTERNAL_RV_SOURCE_DIR ${rv_SOURCE_DIR})
set(LLVM_INCLUDE_TESTS OFF)
set(LLVM_ENABLE_RTTI ON)
message(STATUS "Make LLVM available ...")
FetchContent_MakeAvailable(LLVM)

find_path(LLVM_DIR LLVMConfig.cmake
    PATHS
        ${llvm_BINARY_DIR}
    PATH_SUFFIXES
        lib/cmake/llvm
        share/llvm/cmake
)
