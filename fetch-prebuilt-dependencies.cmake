
if (NOT SETUP_DIR)
    set(SETUP_DIR ${CMAKE_CURRENT_LIST_DIR})
endif()
get_filename_component(SETUP_DIR ${SETUP_DIR} ABSOLUTE)

if (NOT PLATFORM)
    message(FATAL_ERROR "You need to set PLATFORM (e.g. -DPLATFORM=msvc14-x64)")
endif()

message(STATUS "SETUP_DIR: ${SETUP_DIR}")
message(STATUS "PLATFORM: ${PLATFORM}")

include(common.cmake)

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
SET ( LLVM_FILE llvm-3.8.1-${PLATFORM} )
SET ( LLVM_ARCHIVE ${LLVM_FILE}.zip )
SET ( LLVM_URL "https://cloud.dfki.de/owncloud/index.php/s/OSbrh2q6AfAj8Pv/download?path=%2F&files=${LLVM_ARCHIVE}" )

FIND_PATH (LLVM_DIR LLVMConfig.cmake
    PATHS
        ${LLVM_DIR}
        $ENV{LLVM_DIR}
        ${SETUP_DIR}/llvm/build
    PATH_SUFFIXES
        share/llvm/cmake
)
if ( NOT LLVM_DIR )
    if (NOT EXISTS ${SETUP_DIR}/${LLVM_ARCHIVE})
        message(STATUS "Downloading ${LLVM_URL}")
        file(DOWNLOAD ${LLVM_URL} ${SETUP_DIR}/${LLVM_ARCHIVE})
    endif()
    if (NOT EXISTS ${SETUP_DIR}/llvm)
        decompress(${LLVM_ARCHIVE})
        file(RENAME ${SETUP_DIR}/${LLVM_FILE} ${SETUP_DIR}/llvm)
    endif()
    FIND_PATH (LLVM_DIR LLVMConfig.cmake PATHS ${SETUP_DIR}/llvm ${SETUP_DIR}/llvm/build PATH_SUFFIXES share/llvm/cmake)
endif ()
message ( STATUS "LLVM_DIR: ${LLVM_DIR}" )
