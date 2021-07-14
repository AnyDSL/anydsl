# Find the Half library
#
# To set manually the paths, define these environment variables:
#  Half_DIR           - Include path
#
# Once done this will define
#  Half_INCLUDE_DIRS  - where to find Half library include file
#  Half_FOUND         - True if Half library is found

if(NOT Half_FIND_VERSION)
    set(Half_FIND_VERSION 1.11.0)
endif()
set(Half_URL "https://svn.code.sf.net/p/half/code/tags/release-${Half_FIND_VERSION}")

find_path(Half_DIR half.hpp
    PATHS
        ${Half_DIR}
        $ENV{Half_DIR}
        ${AnyDSL_CONTRIB_DIR}/half
    PATH_SUFFIXES
        include
    DOC "C++ library for half precision floating point arithmetics."
)
if(NOT Half_DIR AND Half_FIND_REQUIRED)
    find_package(Git REQUIRED)
    file(MAKE_DIRECTORY ${AnyDSL_CONTRIB_DIR})
    execute_process(COMMAND ${GIT_EXECUTABLE} svn clone ${Half_URL} ${AnyDSL_CONTRIB_DIR}/half)
    find_path(Half_DIR half.hpp PATHS ${AnyDSL_CONTRIB_DIR}/half PATH_SUFFIXES include)
endif()

find_path(Half_INCLUDE_DIR half.hpp PATHS ${Half_DIR} PATH_SUFFIXES include)

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(Half DEFAULT_MSG Half_INCLUDE_DIR)

set(Half_INCLUDE_DIRS ${Half_INCLUDE_DIR})

mark_as_advanced(Half_INCLUDE_DIR)
