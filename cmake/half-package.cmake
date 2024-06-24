set(AnyDSL_PKG_Half_VERSION "2.2.0" CACHE STRING "Half version of AnyDSL")
set(AnyDSL_PKG_Half_URL "https://sourceforge.net/projects/half/files/half/${AnyDSL_PKG_Half_VERSION}/half-${AnyDSL_PKG_Half_VERSION}.zip/download" CACHE STRING "where to download Half")

find_package(Half QUIET)
if(((NOT Half_FOUND) OR AnyDSL_PKG_Half_AUTOBUILD) AND NOT CMAKE_DISABLE_FIND_PACKAGE_Half)
    if (NOT AnyDSL_PKG_Half_AUTOBUILD)
        message(WARNING
"AnyDSL_PKG_Half_AUTOBUILD was set to OFF, but CMake could not find Half.
We will therefore download it anyways.
To get rid of this warning, either set Half_DIR or enable AnyDSL_PKG_Half_AUTOBUILD.")
    endif()

    include(FetchContent)

    FetchContent_Declare(Half
        URL ${AnyDSL_PKG_Half_URL}
        DOWNLOAD_NAME half.zip
        DOWNLOAD_EXTRACT_TIMESTAMP OFF
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
endif()
