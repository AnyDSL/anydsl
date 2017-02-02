
if (NOT SETUP_DIR)
    set(SETUP_DIR ${CMAKE_CURRENT_LIST_DIR})
endif()
get_filename_component(SETUP_DIR ${SETUP_DIR} ABSOLUTE)
# if (NOT GENERATOR)
    # set(GENERATOR "Visual Studio 14 2015 Win64")
# endif ()
if (CMAKE_BUILD_TYPE)
    set(CONFIGURATION_TYPES ${CMAKE_BUILD_TYPE})
elseif (NOT CONFIGURATION_TYPES)
    set(CONFIGURATION_TYPES Debug Release)
endif ()
message(STATUS "SETUP_DIR: ${SETUP_DIR}")
message(STATUS "GENERATOR: ${GENERATOR}")
message(STATUS "CONFIGURATION_TYPES: ${CONFIGURATION_TYPES}")

if (CMAKE_BUILD_TYPE)
    set (SPECIFY_BUILD_TYPE "-DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}")
endif ()
if (GENERATOR)
    set(SPECIFY_GENERATOR -G ${GENERATOR})
endif ()

find_package(Git REQUIRED)

function(decompress _filename)
    message(STATUS "Extracting ${_filename}")
    execute_process(
        COMMAND ${CMAKE_COMMAND} -E tar xf ${_filename}
        WORKING_DIRECTORY ${SETUP_DIR})
endfunction()

function(clone_repository _path _url)
    if(NOT EXISTS ${SETUP_DIR}/${_path})
        execute_process(
            COMMAND ${GIT_EXECUTABLE} clone ${_url} ${_path}
            WORKING_DIRECTORY ${SETUP_DIR})
    endif()
endfunction()

function(configure_build _path)
    file(MAKE_DIRECTORY ${SETUP_DIR}/${_path}/build)
    execute_process(
        COMMAND ${CMAKE_COMMAND} ${SPECIFY_GENERATOR} ${SPECIFY_BUILD_TYPE} ${ARGN} ..
        WORKING_DIRECTORY ${SETUP_DIR}/${_path}/build)
endfunction()

function(compile _path)
    foreach (cfg ${CONFIGURATION_TYPES})
        execute_process(
            COMMAND ${CMAKE_COMMAND} --build ${_path}/build --config ${cfg}
            WORKING_DIRECTORY ${SETUP_DIR})
    endforeach()
endfunction()

# Half
SET ( HALF_VERSION 1.11.0 )
SET ( HALF_URL "http://downloads.sourceforge.net/project/half/half/${HALF_VERSION}/half-${HALF_VERSION}.zip" )

FIND_PATH (Half_DIR half.hpp
    PATHS
        ${Half_DIR}
        $ENV{Half_DIR}
        ${SETUP_DIR}/half-${HALF_VERSION}
    PATH_SUFFIXES
        include
)
if ( NOT Half_DIR )
    set(HALF_FILE half.zip)
    if (NOT EXISTS ${SETUP_DIR}/${HALF_FILE})
        message(STATUS "Downloading ${HALF_URL}")
        file(DOWNLOAD ${HALF_URL} ${SETUP_DIR}/${HALF_FILE})
    endif ()
    decompress(${HALF_FILE})
    FIND_PATH (Half_DIR half.hpp PATHS ${SETUP_DIR}/half-${HALF_VERSION} PATH_SUFFIXES include)
endif ()
message ( STATUS "Half_DIR: ${Half_DIR}" )

# LLVM and clang
SET ( LLVM_VERSION 3.8.1 )
SET ( LLVM_URL "http://llvm.org/releases/${LLVM_VERSION}/llvm-${LLVM_VERSION}.src.tar.xz" )

FIND_PATH (LLVM_DIR LLVMConfig.cmake
    PATHS
        ${LLVM_DIR}
        $ENV{LLVM_DIR}
        ${SETUP_DIR}/llvm/build
    PATH_SUFFIXES
        share/llvm/cmake
)
if ( NOT LLVM_DIR )
    set(LLVM_FILE llvm-${LLVM_VERSION}.tar.xz)
    if (NOT EXISTS ${SETUP_DIR}/${LLVM_FILE})
        message(STATUS "Downloading ${LLVM_URL}")
        file(DOWNLOAD ${LLVM_URL} ${SETUP_DIR}/${LLVM_FILE})
    endif()
    if (NOT EXISTS ${SETUP_DIR}/llvm)
        decompress(${LLVM_FILE})
        file(RENAME ${SETUP_DIR}/llvm-${LLVM_VERSION}.src ${SETUP_DIR}/llvm)
    endif()
    set(CLANG_URL "http://llvm.org/releases/${LLVM_VERSION}/cfe-${LLVM_VERSION}.src.tar.xz")
    set(CLANG_FILE cfe-${LLVM_VERSION}.tar.xz)
    if (NOT EXISTS ${SETUP_DIR}/${CLANG_FILE})
        message(STATUS "Downloading ${CLANG_URL}")
        file(DOWNLOAD ${CLANG_URL} ${SETUP_DIR}/${CLANG_FILE})
    endif()
    if (NOT EXISTS ${SETUP_DIR}/llvm/tools/clang)
        decompress(${CLANG_FILE})
        file(RENAME ${SETUP_DIR}/cfe-${LLVM_VERSION}.src ${SETUP_DIR}/llvm/tools/clang)
    endif()
    set(LLVM_TARGETS AArch64 AMDGPU ARM NVPTX X86)
    # configure_build(llvm -DLLVM_INCLUDE_TESTS:BOOL=OFF "-DLLVM_TARGETS_TO_BUILD=${LLVM_TARGETS}")
    # passing LLVM_TARGETS properly does not work
    file(MAKE_DIRECTORY llvm/build)
    execute_process(
        COMMAND ${CMAKE_COMMAND} ${SPECIFY_GENERATOR} ${SPECIFY_BUILD_TYPE} -DLLVM_INCLUDE_TESTS:BOOL=OFF "-DLLVM_TARGETS_TO_BUILD=${LLVM_TARGETS}" ..
        WORKING_DIRECTORY ${SETUP_DIR}/llvm/build
    )
    compile(llvm)
    FIND_PATH (LLVM_DIR LLVMConfig.cmake PATHS ${SETUP_DIR}/llvm/build PATH_SUFFIXES share/llvm/cmake)
endif ()
message ( STATUS "LLVM_DIR: ${LLVM_DIR}" )

# thorin
SET ( THORIN_URL "https://github.com/AnyDSL/thorin" )

FIND_PATH (THORIN_DIR thorin-config.cmake
    PATHS
        ${THORIN_DIR}
        $ENV{THORIN_DIR}
        ${SETUP_DIR}/thorin/build
    PATH_SUFFIXES
        share/thorin/cmake
)
if ( NOT THORIN_DIR )
    clone_repository(thorin ${THORIN_URL})
    configure_build(thorin -DHalf_DIR=${Half_DIR} -DLLVM_DIR=${LLVM_DIR})
    compile(thorin)
    FIND_PATH (THORIN_DIR thorin-config.cmake PATHS ${SETUP_DIR}/thorin/build PATH_SUFFIXES share/thorin/cmake)
endif ()
message ( STATUS "THORIN_DIR: ${THORIN_DIR}" )

# AnyDSL_runtime
SET ( RUNTIME_URL "https://github.com/AnyDSL/runtime" )

FIND_PATH (AnyDSL_runtime_DIR anydsl_runtime-config.cmake
    PATHS
        ${AnyDSL_runtime_DIR}
        $ENV{AnyDSL_runtime_DIR}
        ${SETUP_DIR}/runtime/build
    PATH_SUFFIXES
        share/AnyDSL_runtime/cmake
)
if ( NOT AnyDSL_runtime_DIR )
    clone_repository(runtime ${RUNTIME_URL})
    # TODO: pass OpenCL, CUDA, TBB
    configure_build(runtime)
    compile(runtime)
    FIND_PATH (AnyDSL_runtime_DIR AnyDSL_runtime-config.cmake PATHS ${SETUP_DIR}/runtime/build PATH_SUFFIXES share/AnyDSL_runtime/cmake)
endif ()
message ( STATUS "AnyDSL_runtime_DIR: ${AnyDSL_runtime_DIR}" )

# impala
SET ( IMPALA_URL "https://github.com/AnyDSL/impala" )

FIND_PATH (IMPALA_DIR impala-config.cmake
    PATHS
        ${IMPALA_DIR}
        $ENV{IMPALA_DIR}
        ${SETUP_DIR}/impala/build
    PATH_SUFFIXES
        share/impala/cmake
)
if ( NOT IMPALA_DIR )
    clone_repository(impala ${IMPALA_URL})
    configure_build(impala -DTHORIN_DIR=${THORIN_DIR} -DAnyDSL_runtime_DIR=${AnyDSL_runtime_DIR})
    compile(impala)
    FIND_PATH (IMPALA_DIR impala-config.cmake PATHS ${SETUP_DIR}/impala/build PATH_SUFFIXES share/impala/cmake)
endif ()
message ( STATUS "IMPALA_DIR: ${IMPALA_DIR}" )
