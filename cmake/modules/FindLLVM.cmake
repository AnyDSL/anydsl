# Find the LLVM library
#
# To set manually the paths, define these environment variables:
#  LLVM_DIR           - path to LLVMConfig.cmake
#

# set(LLVM_VERSION ${PACKAGE_FIND_VERSION})
set(LLVM_URL "http://llvm.org/releases/${LLVM_FIND_VERSION}/llvm-${LLVM_FIND_VERSION}.src.tar.xz")

find_path(LLVM_DIR LLVMConfig.cmake
    PATHS
        ${LLVM_DIR}
        $ENV{LLVM_DIR}
        ${CONTRIB_DIR}/llvm
        ${CONTRIB_DIR}/llvm/build
    PATH_SUFFIXES
        share/llvm/cmake
)
if(NOT LLVM_DIR AND LLVM_FIND_REQUIRED)
    file(MAKE_DIRECTORY ${CONTRIB_DIR})
    set(LLVM_FILE ${CONTRIB_DIR}/llvm-${LLVM_FIND_VERSION}.tar.xz)
    if(NOT EXISTS ${LLVM_FILE})
        message(STATUS "Downloading ${LLVM_URL}")
        file(DOWNLOAD ${LLVM_URL} ${LLVM_FILE})
    endif()
    if(NOT EXISTS ${CONTRIB_DIR}/llvm)
        decompress(${LLVM_FILE})
        file(RENAME ${CONTRIB_DIR}/llvm-${LLVM_FIND_VERSION}.src ${CONTRIB_DIR}/llvm)
    endif()
    set(CLANG_URL "http://llvm.org/releases/${LLVM_FIND_VERSION}/cfe-${LLVM_FIND_VERSION}.src.tar.xz")
    set(CLANG_FILE ${CONTRIB_DIR}/cfe-${LLVM_FIND_VERSION}.tar.xz)
    if(NOT EXISTS ${CLANG_FILE})
        message(STATUS "Downloading ${CLANG_URL}")
        file(DOWNLOAD ${CLANG_URL} ${CLANG_FILE})
    endif()
    if(NOT EXISTS ${CONTRIB_DIR}/llvm/tools/clang)
        decompress(${CLANG_FILE})
        file(RENAME ${CONTRIB_DIR}/cfe-${LLVM_FIND_VERSION}.src ${CONTRIB_DIR}/llvm/tools/clang)
    endif()
    set(LLVM_TARGETS_TO_BUILD "AArch64;AMDGPU;ARM;NVPTX;X86" CACHE STRING "limit targets of LLVM" FORCE)
    file(MAKE_DIRECTORY ${CONTRIB_DIR}/llvm/build)
    execute_process(
        COMMAND ${CMAKE_COMMAND} -G ${CMAKE_GENERATOR}
            -DLLVM_INCLUDE_TESTS:BOOL=OFF
            "-DLLVM_TARGETS_TO_BUILD=${LLVM_TARGETS_TO_BUILD}"
            -DLLVM_ENABLE_RTTI:BOOL=ON
        ..
        WORKING_DIRECTORY ${CONTRIB_DIR}/llvm/build
    )

    if(MSVC)
        foreach(_cfg ${CMAKE_CONFIGURATION_TYPE})
            execute_process(COMMAND ${CMAKE_COMMAND} --build ${CONTRIB_DIR}/llvm/build --config ${_cfg} -- ${AnyDSL_BUILD_FLAGS})
        endforeach()
    elseif(DEFINED CMAKE_BUILD_TYPE)
        execute_process(COMMAND ${CMAKE_COMMAND} --build ${CONTRIB_DIR}/llvm/build -- ${AnyDSL_BUILD_FLAGS})
    else()
        message(STATUS "Please build the pre-configured LLVM at ${CONTRIB_DIR}/llvm/build")
    endif()

    find_path(LLVM_DIR LLVMConfig.cmake PATHS ${CONTRIB_DIR}/llvm/build ${CMAKE_CURRENT_BINARY_DIR} ${CMAKE_BINARY_DIR} PATH_SUFFIXES share/llvm/cmake contrib/llvm/share/llvm/cmake)
endif ()

if(EXISTS ${LLVM_DIR}/LLVMConfig.cmake)
    include(${LLVM_DIR}/LLVMConfig.cmake)
endif()

# include(FindPackageHandleStandardArgs)
# find_package_handle_standard_args(LLVM DEFAULT_MSG LLVM_DIR)
