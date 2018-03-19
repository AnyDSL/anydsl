function(fetch_anydsl_package _pkg_path _pkg_name _pkg_fullname _pkg_url)
    # TODO: make this consistent
    # set(_pkg_fullname "AnyDSL_${_pkg_name}")
    set(_pkg_branch "AnyDSL_${_pkg_name}_BRANCH")
    if(NOT ${_pkg_branch})
        set(${_pkg_branch} ${AnyDSL_DEFAULT_BRANCH} CACHE STRING "follow branch of repository ${_pkg_url}")
    endif()
    string(TOLOWER ${_pkg_fullname} _pkg_fullname_lower)
    find_path(${_pkg_path}
        NAMES ${_pkg_fullname}-config.cmake ${_pkg_fullname_lower}-config.cmake
        PATHS
            ${${_pkg_path}}
            $ENV{${_pkg_path}}
            ${CMAKE_CURRENT_SOURCE_DIR}/${_pkg_name}/build
            ${ARGN}
        PATH_SUFFIXES
            share/${_pkg_fullname}/cmake
            share/anydsl/cmake
    )
    find_package(Git REQUIRED)
    if(NOT ${_pkg_path} AND NOT EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/${_pkg_name})
        execute_process(COMMAND ${GIT_EXECUTABLE} clone --branch ${${_pkg_branch}} --recursive ${_pkg_url} ${_pkg_name} WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR})
    endif()
    add_subdirectory(${_pkg_name})
    find_path(${_pkg_path}
        NAMES ${_pkg_fullname}-config.cmake ${_pkg_fullname_lower}-config.cmake
        PATHS ${${_pkg_path}} ${CMAKE_CURRENT_BINARY_DIR} ${CMAKE_BINARY_DIR} ${ARGN}
        PATH_SUFFIXES share/${_pkg_fullname}/cmake share/anydsl/cmake
        DOC "path to package ${_pkg_fullname}")
    add_custom_target(pull-${_pkg_name}
        COMMAND ${GIT_EXECUTABLE} fetch --tags origin
        COMMAND ${GIT_EXECUTABLE} checkout ${${_pkg_branch}}
        COMMAND ${GIT_EXECUTABLE} symbolic-ref HEAD
        COMMAND ${GIT_EXECUTABLE} pull
        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/${_pkg_name}
        COMMENT ">>> pull ${_pkg_url} ${${_pkg_branch}}"
    )
endfunction()

