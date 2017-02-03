
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
