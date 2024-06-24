
set(AnyDSL_PKG_Half_VERSION "2.2.0" CACHE STRING "Half version of AnyDSL")
set(AnyDSL_PKG_Half_URL "https://svn.code.sf.net/p/half/code/tags/release-${AnyDSL_PKG_Half_VERSION}" CACHE STRING "where to download Half")


include(FetchContent)


FetchContent_Declare(Half
    URL https://sourceforge.net/projects/half/files/latest/download
    DOWNLOAD_NAME half.zip
)

message(STATUS "Make Half available ...")
FetchContent_GetProperties(Half)
if(NOT half_POPULATED)
    FetchContent_Populate(Half)
endif()

find_path(Half_DIR half.hpp
    PATHS
        ${half_SOURCE_DIR}
        ${half_BINARY_DIR}
    PATH_SUFFIXES
        include
        include/half
    DOC "C++ library for half precision floating point arithmetics."
)
