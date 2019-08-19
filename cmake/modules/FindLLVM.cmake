# Find the LLVM library
#
# To set manually the paths, define these environment variables:
#  LLVM_DIR           - path to LLVMConfig.cmake
#

if(NOT LLVM_FIND_VERSION)
    message(FATAL_ERROR "Please specify the required LLVM version")
endif()
if(NOT LLVM_URL)
    set(LLVM_URL "http://llvm.org/releases/${LLVM_FIND_VERSION}/llvm-${LLVM_FIND_VERSION}.src.tar.xz")
endif()

get_filename_component(BUILD_DIR_NAME ${CMAKE_BINARY_DIR} NAME)
set(LLVM_SOURCE_DIR ${AnyDSL_CONTRIB_DIR}/llvm-${LLVM_FIND_VERSION})
set(LLVM_BUILD_DIR ${LLVM_SOURCE_DIR}/${BUILD_DIR_NAME})

find_path(LLVM_DIR LLVMConfig.cmake
    PATHS
        ${LLVM_DIR}
        $ENV{LLVM_DIR}
        ${LLVM_SOURCE_DIR}
        ${AnyDSL_CONTRIB_DIR}/llvm
        ${LLVM_BUILD_DIR}
    PATH_SUFFIXES
        lib/cmake/llvm
        share/llvm/cmake
)

# download and extract LLVM and CLANG
if(NOT LLVM_DIR AND LLVM_FIND_REQUIRED)
    file(MAKE_DIRECTORY ${AnyDSL_CONTRIB_DIR})
    set(LLVM_FILE ${AnyDSL_CONTRIB_DIR}/llvm-${LLVM_FIND_VERSION}.tar.xz)
    if(NOT EXISTS ${LLVM_FILE})
        message(STATUS "Downloading ${LLVM_URL}")
        file(DOWNLOAD ${LLVM_URL} ${LLVM_FILE})
    endif()
    if(NOT EXISTS ${LLVM_SOURCE_DIR})
        message(STATUS "Extracting ${LLVM_FILE}")
        get_filename_component(_dir ${LLVM_FILE} DIRECTORY)
        get_filename_component(_file ${LLVM_FILE} NAME)
        execute_process(
            COMMAND ${CMAKE_COMMAND} -E tar xf ${_file}
            WORKING_DIRECTORY ${_dir})
        if(EXISTS ${AnyDSL_CONTRIB_DIR}/llvm-${LLVM_FIND_VERSION}.src)
            file(RENAME ${AnyDSL_CONTRIB_DIR}/llvm-${LLVM_FIND_VERSION}.src ${LLVM_SOURCE_DIR})
        endif()
    endif()

    # check for pre-build llvm
    find_path(LLVM_DIR LLVMConfig.cmake PATHS ${LLVM_SOURCE_DIR} PATH_SUFFIXES lib/cmake/llvm share/llvm/cmake)

    if(NOT LLVM_DIR)
        set(CLANG_URL "http://llvm.org/releases/${LLVM_FIND_VERSION}/cfe-${LLVM_FIND_VERSION}.src.tar.xz")
        set(CLANG_FILE ${AnyDSL_CONTRIB_DIR}/cfe-${LLVM_FIND_VERSION}.tar.xz)
        if(NOT EXISTS ${CLANG_FILE})
            message(STATUS "Downloading ${CLANG_URL}")
            file(DOWNLOAD ${CLANG_URL} ${CLANG_FILE})
        endif()
        if(NOT EXISTS ${LLVM_SOURCE_DIR}/tools/clang)
            message(STATUS "Extracting ${CLANG_FILE}")
            get_filename_component(_dir ${CLANG_FILE} DIRECTORY)
            get_filename_component(_file ${CLANG_FILE} NAME)
            execute_process(
                COMMAND ${CMAKE_COMMAND} -E tar xf ${_file}
                WORKING_DIRECTORY ${_dir})
            file(RENAME ${AnyDSL_CONTRIB_DIR}/cfe-${LLVM_FIND_VERSION}.src ${LLVM_SOURCE_DIR}/tools/clang)
        endif()

        if(AnyDSL_RV_BRANCH)
            set(RV_URL "https://github.com/cdl-saarland/rv/archive/${AnyDSL_RV_BRANCH}.zip")
            set(RV_FILE ${AnyDSL_CONTRIB_DIR}/rv-${AnyDSL_RV_BRANCH}.zip)
            if(NOT EXISTS ${RV_FILE})
                message(STATUS "Downloading ${RV_FILE}")
                file(DOWNLOAD ${RV_URL} ${RV_FILE})
            endif()
            if(NOT EXISTS ${LLVM_SOURCE_DIR}/tools/rv)
                decompress(${RV_FILE})
                file(RENAME ${AnyDSL_CONTRIB_DIR}/rv-${AnyDSL_RV_BRANCH} ${LLVM_SOURCE_DIR}/tools/rv)
            endif()
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
    if(CMAKE_VS_PLATFORM_TOOLSET_HOST_ARCHITECTURE)
        set(SPECIFY_TOOLSET_OPTION -T host=${CMAKE_VS_PLATFORM_TOOLSET_HOST_ARCHITECTURE})
    endif()
    if(CMAKE_BUILD_TYPE)
        set(SPECIFY_BUILD_TYPE -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE})
    endif()
    if(DEFINED BUILD_SHARED_LIBS)
        set(SPECIFY_BUILD_SHARED_LIBS -DBUILD_SHARED_LIBS:BOOL=${BUILD_SHARED_LIBS})
    endif()
    execute_process(
        COMMAND ${CMAKE_COMMAND} ${LLVM_SOURCE_DIR} -G ${CMAKE_GENERATOR} ${SPECIFY_PLATFORM} ${SPECIFY_TOOLSET_OPTION} ${SPECIFY_BUILD_TYPE}
            -DLLVM_INCLUDE_TESTS:BOOL=ON
            "-DLLVM_TARGETS_TO_BUILD=${LLVM_TARGETS_TO_BUILD}"
            -DLLVM_ENABLE_RTTI:BOOL=ON
            ${SPECIFY_BUILD_SHARED_LIBS}
        WORKING_DIRECTORY ${LLVM_BUILD_DIR}
    )

    if(MSVC)
        add_custom_target(LLVM
            COMMAND ${CMAKE_COMMAND} --build ${LLVM_BUILD_DIR} --config $<CONFIG> -- ${AnyDSL_BUILD_FLAGS}
            COMMENT "Building pre-configured LLVM at ${LLVM_BUILD_DIR}"
            VERBATIM)
    elseif(DEFINED CMAKE_BUILD_TYPE)
        add_custom_target(LLVM
            COMMAND ${CMAKE_COMMAND} --build ${LLVM_BUILD_DIR} -- ${AnyDSL_BUILD_FLAGS}
            COMMENT "Building pre-configured LLVM at ${LLVM_BUILD_DIR} (${CMAKE_BUILD_TYPE})"
            VERBATIM)
    else()
        message(WARNING "Please build the pre-configured LLVM at ${LLVM_BUILD_DIR}")
    endif()

    find_path(LLVM_DIR LLVMConfig.cmake
        PATHS
            ${LLVM_BUILD_DIR}
            ${CMAKE_CURRENT_BINARY_DIR}
            ${CMAKE_BINARY_DIR}
        PATH_SUFFIXES
            lib/cmake/llvm
            contrib/llvm/lib/cmake/llvm
            share/llvm/cmake
            contrib/llvm/share/llvm/cmake
    )
endif ()

if(EXISTS ${LLVM_DIR}/LLVMConfig.cmake)
    include(${LLVM_DIR}/LLVMConfig.cmake)
endif()

