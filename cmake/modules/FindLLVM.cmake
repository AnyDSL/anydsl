# Find the LLVM library
#
# To set manually the paths, define these environment variables:
#  LLVM_DIR           - path to LLVMConfig.cmake
#

if(NOT LLVM_FIND_VERSION)
    set(LLVM_FIND_VERSION 3.8.1)
endif()
if(NOT LLVM_URL)
    set(LLVM_URL "http://llvm.org/releases/${LLVM_FIND_VERSION}/llvm-${LLVM_FIND_VERSION}.src.tar.xz")
endif()

set(LLVM_BUILD_DIR ${CONTRIB_DIR}/llvm/build)
if(CMAKE_BUILD_TYPE)
    set(LLVM_BUILD_DIR ${LLVM_BUILD_DIR}_${CMAKE_BUILD_TYPE})
endif()

find_path(LLVM_DIR LLVMConfig.cmake
    PATHS
        ${LLVM_DIR}
        $ENV{LLVM_DIR}
        ${CONTRIB_DIR}/llvm
        ${LLVM_BUILD_DIR}
    PATH_SUFFIXES
        share/llvm/cmake
)

# download and extract LLVM and CLANG
if(NOT LLVM_DIR AND LLVM_FIND_REQUIRED)
    file(MAKE_DIRECTORY ${CONTRIB_DIR})
    set(LLVM_FILE ${CONTRIB_DIR}/llvm.tar.xz)
    if(NOT EXISTS ${LLVM_FILE})
        message(STATUS "Downloading ${LLVM_URL}")
        file(DOWNLOAD ${LLVM_URL} ${LLVM_FILE} SHOW_PROGRESS)
    endif()
    if(NOT EXISTS ${CONTRIB_DIR}/llvm)
        decompress(${LLVM_FILE})
        if(EXISTS ${CONTRIB_DIR}/llvm-${LLVM_FIND_VERSION}.src)
            file(RENAME ${CONTRIB_DIR}/llvm-${LLVM_FIND_VERSION}.src ${CONTRIB_DIR}/llvm)
        endif()
    endif()

    # check for pre-build llvm
    find_path(LLVM_DIR LLVMConfig.cmake PATHS ${CONTRIB_DIR}/llvm PATH_SUFFIXES share/llvm/cmake)

    if(NOT LLVM_DIR)
        set(CLANG_URL "http://llvm.org/releases/${LLVM_FIND_VERSION}/cfe-${LLVM_FIND_VERSION}.src.tar.xz")
        set(CLANG_FILE ${CONTRIB_DIR}/cfe-${LLVM_FIND_VERSION}.tar.xz)
        if(NOT EXISTS ${CLANG_FILE})
            message(STATUS "Downloading ${CLANG_URL}")
            file(DOWNLOAD ${CLANG_URL} ${CLANG_FILE} SHOW_PROGRESS)
        endif()
        if(NOT EXISTS ${CONTRIB_DIR}/llvm/tools/clang)
            decompress(${CLANG_FILE})
            file(RENAME ${CONTRIB_DIR}/cfe-${LLVM_FIND_VERSION}.src ${CONTRIB_DIR}/llvm/tools/clang)
        endif()
        file(MAKE_DIRECTORY ${LLVM_BUILD_DIR})
    endif()
endif()

# always configure and build LLVM at AnyDSL's cmake configure time
# this is fast if it previously happened and allows to resume LLVM builds
if(EXISTS ${LLVM_BUILD_DIR} AND NOT TARGET LLVM)
    set(LLVM_TARGETS_TO_BUILD "AArch64;AMDGPU;ARM;NVPTX;X86" CACHE STRING "limit targets of LLVM" FORCE)
    if(CMAKE_GENERATOR_PLATFORM)
        set(SPECIFY_PLATFORM -A ${CMAKE_GENERATOR_PLATFORM})
    endif()
    if(CMAKE_BUILD_TYPE)
        set(SPECIFY_BUILD_TYPE -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE})
    endif()
    execute_process(
        COMMAND ${CMAKE_COMMAND} .. -G ${CMAKE_GENERATOR} ${SPECIFY_PLATFORM} ${SPECIFY_BUILD_TYPE}
            -DLLVM_INCLUDE_TESTS:BOOL=OFF
            "-DLLVM_TARGETS_TO_BUILD=${LLVM_TARGETS_TO_BUILD}"
            -DLLVM_ENABLE_RTTI:BOOL=ON
        WORKING_DIRECTORY ${LLVM_BUILD_DIR}
    )

    if(MSVC)
        message(STATUS "Building pre-configured LLVM at ${CONTRIB_DIR}/llvm/build (${CMAKE_CONFIGURATION_TYPES})")
        foreach(_cfg ${CMAKE_CONFIGURATION_TYPES})
            execute_process(COMMAND ${CMAKE_COMMAND} --build ${CONTRIB_DIR}/llvm/build --config ${_cfg} -- ${AnyDSL_BUILD_FLAGS})
        endforeach()
    elseif(DEFINED CMAKE_BUILD_TYPE)
        add_custom_target(LLVM ALL
            COMMAND ${CMAKE_COMMAND} --build ${LLVM_BUILD_DIR} -- ${AnyDSL_BUILD_FLAGS}
            COMMENT "Building pre-configured LLVM at ${LLVM_BUILD_DIR} (${CMAKE_BUILD_TYPE})"
            VERBATIM)
    else()
        message(WARNING "Please build the pre-configured LLVM at ${LLVM_BUILD_DIR}")
    endif()

    find_path(LLVM_DIR LLVMConfig.cmake PATHS ${LLVM_BUILD_DIR} ${CMAKE_CURRENT_BINARY_DIR} ${CMAKE_BINARY_DIR} PATH_SUFFIXES share/llvm/cmake contrib/llvm/share/llvm/cmake)
endif ()

if(EXISTS ${LLVM_DIR}/LLVMConfig.cmake)
    include(${LLVM_DIR}/LLVMConfig.cmake)
endif()

