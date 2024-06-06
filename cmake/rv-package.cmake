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
