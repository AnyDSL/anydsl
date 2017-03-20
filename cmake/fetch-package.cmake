function(fetch_anydsl_package _outvar _pkg_name _pkg_fullname _pkg_url)
    # TODO: make this consistent
    # set(_pkg_fullname "AnyDSL_${_pkg_name}")
    set(_pkg_branch "AnyDSL_${_pkg_name}_BRANCH")
    if(NOT ${_pkg_branch})
        set(${_pkg_branch} ${AnyDSL_DEFAULT_BRANCH} CACHE STRING "follow branch of repository ${_pkg_url}")
    endif()
    find_path(_pkg_path ${_pkg_fullname}-config.cmake
        PATHS
            ${${_outvar}}
            $ENV{${_outvar}}
            ${CMAKE_CURRENT_SOURCE_DIR}/${_pkg_name}/build
            ${ARGN}
        PATH_SUFFIXES
            share/${_pkg_fullname}/cmake
    )
    if(NOT _pkg_path AND NOT EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/${_pkg_name})
        find_package(Git REQUIRED)
        execute_process(COMMAND ${GIT_EXECUTABLE} clone --branch ${${_pkg_branch}} --recursive ${_pkg_url} ${_pkg_name} WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR})
    endif()
    add_subdirectory(${_pkg_name})
    find_path(_pkg_path ${_pkg_fullname}-config.cmake PATHS ${${_outvar}} ${CMAKE_CURRENT_BINARY_DIR} ${CMAKE_BINARY_DIR} ${ARGN} PATH_SUFFIXES share/${_pkg_fullname}/cmake)
    set(${_outvar} ${_pkg_path} CACHE PATH "path to package ${_pkg_fullname}")
    unset(_pkg_path CACHE)
endfunction()
