set(AnyDSL_PKG_LLVM_VERSION "18.1.8" CACHE STRING "LLVM version of AnyDSL")
set(AnyDSL_PKG_LLVM_URL "https://github.com/llvm/llvm-project/releases/download/llvmorg-${AnyDSL_PKG_LLVM_VERSION}/llvm-project-${AnyDSL_PKG_LLVM_VERSION}.src.tar.xz" CACHE STRING "where to download LLVM")

# LLVM's version handling requires exact matches of major.minor to ensure API compatibility
# however, LLVM does not support version ranges for CMake's find_package() command
string(REGEX MATCH "^([0-9]+)\.([0-9]+)" AnyDSL_PKG_LLVM_VERSION_MAJOR_MINOR ${AnyDSL_PKG_LLVM_VERSION})
set(AnyDSL_PKG_LLVM_VERSION_MAJOR ${CMAKE_MATCH_1})
set(AnyDSL_PKG_LLVM_VERSION_MINOR ${CMAKE_MATCH_2})
foreach(_minor_version RANGE 0 ${AnyDSL_PKG_LLVM_VERSION_MINOR})
    find_package(LLVM ${AnyDSL_PKG_LLVM_VERSION_MAJOR}.${_minor_version} CONFIG QUIET)
endforeach()
if (NOT LLVM_FOUND AND NOT CMAKE_DISABLE_FIND_PACKAGE_LLVM)
	find_package(LLVM CONFIG QUIET)
    if (NOT LLVM_FOUND)
        message(WARNING
"LLVM not found. This is probably not what you want to do. You can either set AnyDSL_PKG_LLVM_AUTOBUILD to ON, or set LLVM_DIR to point to LLVM ${AnyDSL_PKG_LLVM_VERSION}.
You can get also rid of this warning by setting CMAKE_DISABLE_FIND_PACKAGE_LLVM to ON.")
    else()
        message(WARNING
		"LLVM ${LLVM_VERSION} found, but this version does not match what AnyDSL expects. This is probably not what you want to do. You can either set AnyDSL_PKG_LLVM_AUTOBUILD to ON, or set LLVM_DIR to point to LLVM ${AnyDSL_PKG_LLVM_VERSION_MAJOR}.
You can also get rid of this warning by setting AnyDSL_PKG_LLVM_VERSION to ${LLVM_VERSION}, or by enabling CMAKE_DISABLE_FIND_PACKAGE_LLVM.")
    endif()
endif()

if(AnyDSL_PKG_LLVM_AUTOBUILD AND NOT CMAKE_DISABLE_FIND_PACKAGE_LLVM)
    include(FetchContent)

    FetchContent_Declare(LLVM
        URL  ${AnyDSL_PKG_LLVM_URL}
        PATCH_COMMAND ${CMAKE_COMMAND} -D LLVM_VERSION=${AnyDSL_PKG_LLVM_VERSION} -P ${CMAKE_CURRENT_SOURCE_DIR}/patches/llvm/apply.cmake
        DOWNLOAD_EXTRACT_TIMESTAMP OFF
    )
    set(LLVM_TARGETS_TO_BUILD "AArch64;AMDGPU;ARM;NVPTX;X86" CACHE STRING "limit targets of LLVM")
    set(LLVM_ENABLE_PROJECTS "clang;lld" CACHE STRING "enable projects of LLVM")
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
endif()
