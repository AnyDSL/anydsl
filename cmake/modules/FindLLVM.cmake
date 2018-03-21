# Find the LLVM library
#
# To set manually the paths, define these environment variables:
#  LLVM_DIR           - path to LLVMConfig.cmake
#

if(NOT LLVM_FIND_VERSION)
    set(LLVM_FIND_VERSION 5.0.1)
endif()
if(NOT LLVM_URL)
    set(LLVM_URL "http://llvm.org/releases/${LLVM_FIND_VERSION}/llvm-${LLVM_FIND_VERSION}.src.tar.xz")
endif()

get_filename_component(BUILD_DIR_NAME ${CMAKE_BINARY_DIR} NAME)
set(LLVM_SOURCE_DIR ${CONTRIB_DIR}/llvm-${LLVM_FIND_VERSION})
set(LLVM_BUILD_DIR ${LLVM_SOURCE_DIR}/${BUILD_DIR_NAME})

find_path(LLVM_DIR LLVMConfig.cmake
    PATHS
        ${LLVM_DIR}
        $ENV{LLVM_DIR}
        ${LLVM_SOURCE_DIR}
        ${CONTRIB_DIR}/llvm
        ${LLVM_BUILD_DIR}
    PATH_SUFFIXES
        lib/cmake/llvm
        share/llvm/cmake
)

# download and extract LLVM and CLANG
if(NOT LLVM_DIR AND LLVM_FIND_REQUIRED)
    file(MAKE_DIRECTORY ${CONTRIB_DIR})
    set(LLVM_FILE ${CONTRIB_DIR}/llvm-${LLVM_FIND_VERSION}.tar.xz)
    if(NOT EXISTS ${LLVM_FILE})
        message(STATUS "Downloading ${LLVM_URL}")
        file(DOWNLOAD ${LLVM_URL} ${LLVM_FILE} SHOW_PROGRESS)
    endif()
    if(NOT EXISTS ${LLVM_SOURCE_DIR})
        decompress(${LLVM_FILE})
        if(EXISTS ${CONTRIB_DIR}/llvm-${LLVM_FIND_VERSION}.src)
            file(RENAME ${CONTRIB_DIR}/llvm-${LLVM_FIND_VERSION}.src ${LLVM_SOURCE_DIR})
        endif()
    endif()

    # check for pre-build llvm
    find_path(LLVM_DIR LLVMConfig.cmake PATHS ${LLVM_SOURCE_DIR} PATH_SUFFIXES lib/cmake/llvm share/llvm/cmake)

    if(NOT LLVM_DIR)
        set(CLANG_URL "http://llvm.org/releases/${LLVM_FIND_VERSION}/cfe-${LLVM_FIND_VERSION}.src.tar.xz")
        set(CLANG_FILE ${CONTRIB_DIR}/cfe-${LLVM_FIND_VERSION}.tar.xz)
        if(NOT EXISTS ${CLANG_FILE})
            message(STATUS "Downloading ${CLANG_URL}")
            file(DOWNLOAD ${CLANG_URL} ${CLANG_FILE} SHOW_PROGRESS)
        endif()
        if(NOT EXISTS ${LLVM_SOURCE_DIR}/tools/clang)
            decompress(${CLANG_FILE})
            file(RENAME ${CONTRIB_DIR}/cfe-${LLVM_FIND_VERSION}.src ${LLVM_SOURCE_DIR}/tools/clang)
        endif()

        if(RV_BRANCH)
            set(RV_URL "https://github.com/cdl-saarland/rv/archive/${RV_BRANCH}.zip")
	    set(RV_FILE ${CONTRIB_DIR}/rv-${RV_BRANCH}.zip)
	    if(NOT EXISTS ${RV_FILE})
		message(STATUS "Downloading ${RV_FILE}")
		file(DOWNLOAD ${RV_URL} ${RV_FILE} SHOW_PROGRESS)
	    endif()
	    if(NOT EXISTS ${LLVM_SOURCE_DIR}/tools/rv)
		decompress(${RV_FILE})
		file(RENAME ${CONTRIB_DIR}/rv-${RV_BRANCH} ${LLVM_SOURCE_DIR}/tools/rv)
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
    set(LLVM_DISABLE_OBSOLETE_BUILD_TARGETS
        -DLLVM_TOOL_BUGPOINT_BUILD:BOOL=OFF
        -DLLVM_TOOL_BUGPOINT_PASSES_BUILD:BOOL=OFF
        -DLLVM_TOOL_DSYMUTIL_BUILD:BOOL=OFF
        -DLLVM_TOOL_GOLD_BUILD:BOOL=OFF
        -DLLVM_TOOL_LLC_BUILD:BOOL=OFF
        -DLLVM_TOOL_LLI_BUILD:BOOL=OFF
        -DLLVM_TOOL_LLVM_AR_BUILD:BOOL=OFF
        -DLLVM_TOOL_LLVM_AS_FUZZER_BUILD:BOOL=OFF
        -DLLVM_TOOL_LLVM_BCANALYZER_BUILD:BOOL=OFF
        -DLLVM_TOOL_LLVM_COV_BUILD:BOOL=OFF
        -DLLVM_TOOL_LLVM_CXXDUMP_BUILD:BOOL=OFF
        -DLLVM_TOOL_LLVM_C_TEST_BUILD:BOOL=OFF
        -DLLVM_TOOL_LLVM_DIFF_BUILD:BOOL=OFF
        -DLLVM_TOOL_LLVM_DIS_BUILD:BOOL=OFF
        -DLLVM_TOOL_LLVM_DWARFDUMP_BUILD:BOOL=OFF
        -DLLVM_TOOL_LLVM_DWP_BUILD:BOOL=OFF
        -DLLVM_TOOL_LLVM_EXTRACT_BUILD:BOOL=OFF
        -DLLVM_TOOL_LLVM_GO_BUILD:BOOL=OFF
        -DLLVM_TOOL_LLVM_JITLISTENER_BUILD:BOOL=OFF
        -DLLVM_TOOL_LLVM_LINK_BUILD:BOOL=OFF
        -DLLVM_TOOL_LLVM_LTO_BUILD:BOOL=OFF
        -DLLVM_TOOL_LLVM_MCMARKUP_BUILD:BOOL=OFF
        -DLLVM_TOOL_LLVM_MC_BUILD:BOOL=OFF
        -DLLVM_TOOL_LLVM_NM_BUILD:BOOL=OFF
        -DLLVM_TOOL_LLVM_OBJDUMP_BUILD:BOOL=OFF
        -DLLVM_TOOL_LLVM_PROFDATA_BUILD:BOOL=OFF
        -DLLVM_TOOL_LLVM_READOBJ_BUILD:BOOL=OFF
        -DLLVM_TOOL_LLVM_RTDYLD_BUILD:BOOL=OFF
        -DLLVM_TOOL_LLVM_SHLIB_BUILD:BOOL=OFF
        -DLLVM_TOOL_LLVM_SIZE_BUILD:BOOL=OFF
        -DLLVM_TOOL_LLVM_SPLIT_BUILD:BOOL=OFF
        -DLLVM_TOOL_LLVM_STRESS_BUILD:BOOL=OFF
        -DLLVM_TOOL_LLVM_SYMBOLIZER_BUILD:BOOL=OFF
        -DLLVM_TOOL_LTO_BUILD:BOOL=OFF
        -DLLVM_TOOL_MSBUILD_BUILD:BOOL=OFF
        -DLLVM_TOOL_OBJ2YAML_BUILD:BOOL=OFF
        -DLLVM_TOOL_OPT_BUILD:BOOL=OFF
        -DLLVM_TOOL_SANCOV_BUILD:BOOL=OFF
        -DLLVM_TOOL_VERIFY_USELISTORDER_BUILD:BOOL=OFF
        -DLLVM_TOOL_XCODE_TOOLCHAIN_BUILD:BOOL=OFF
        -DLLVM_TOOL_YAML2OBJ_BUILD:BOOL=OFF
    )
    execute_process(
        COMMAND ${CMAKE_COMMAND} ${LLVM_SOURCE_DIR} -G ${CMAKE_GENERATOR} ${SPECIFY_PLATFORM} ${SPECIFY_TOOLSET_OPTION} ${SPECIFY_BUILD_TYPE}
            -DLLVM_INCLUDE_TESTS:BOOL=OFF
            "-DLLVM_TARGETS_TO_BUILD=${LLVM_TARGETS_TO_BUILD}"
            -DLLVM_ENABLE_RTTI:BOOL=ON
            ${LLVM_DISABLE_OBSOLETE_BUILD_TARGETS}
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

