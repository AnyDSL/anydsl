set(AnyDSL_PKG_RV_TAG "origin/AnyDSL_pruned" CACHE STRING "LLVM is build with this git tag of RV")

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

message(STATUS "rv_SOURCE_DIR: ${rv_SOURCE_DIR}")
add_subdirectory(${rv_SOURCE_DIR} ${rv_BINARY_DIR})

find_path(RV_DIR rv-config.cmake
    PATHS
        ${rv_BINARY_DIR}
        ${CMAKE_CURRENT_BINARY_DIR}
        ${CMAKE_BINARY_DIR}
    PATH_SUFFIXES
        share/anydsl/cmake
)

#set(RV_DIR ${rv_BINARY_DIR}/share/anydsl/cmake)

message(STATUS "rv found in ${RV_DIR}")
