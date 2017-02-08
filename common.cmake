
function(decompress _filename)
    message(STATUS "Extracting ${_filename}")
    execute_process(
        COMMAND ${CMAKE_COMMAND} -E tar xf ${_filename}
        WORKING_DIRECTORY ${SETUP_DIR})
endfunction()

function(clone_repository _path _url _branch)
    if ( EXISTS ${SETUP_DIR}/${_path} )
        execute_process(
            COMMAND ${GIT_EXECUTABLE} pull origin ${_branch}
            WORKING_DIRECTORY ${SETUP_DIR}/${_path})
    else ()
        execute_process(
            COMMAND ${GIT_EXECUTABLE} clone --branch ${_branch} --recursive ${_url} ${_path}
            WORKING_DIRECTORY ${SETUP_DIR})
    endif ()
endfunction()

function(configure_build _path)
    file(MAKE_DIRECTORY ${SETUP_DIR}/${_path})
    execute_process(
        COMMAND ${CMAKE_COMMAND} ${SPECIFY_GENERATOR} ${SPECIFY_BUILD_TYPE} ${ARGN} ..
        WORKING_DIRECTORY ${SETUP_DIR}/${_path}
        RESULT_VARIABLE _result)
    if (_result )
        message(FATAL_ERROR "configure_build(${_path} returned ${_result}")
    endif()
endfunction()

function(compile _path)
    string(REPLACE "/" "_" _id ${_path})
    foreach (cfg ${CONFIGURATION_TYPES})
        set(_logfile ${SETUP_DIR}/build_${_id}_${cfg}.log)
        message(STATUS "Compiling ${_path} -> ${_logfile}")
        execute_process(
            COMMAND ${CMAKE_COMMAND} --build ${_path} --config ${cfg} ${ARGN}
            WORKING_DIRECTORY ${SETUP_DIR}
            OUTPUT_FILE ${_logfile}
            RESULT_VARIABLE _result)
        if (_result )
            message(FATAL_ERROR "compile(${_path} returned ${_result}")
        endif()
    endforeach()
endfunction()

function(run_tests _path)
    string(REPLACE "/" "_" _id ${_path})
    # set(cfg Release)
    foreach (cfg ${CONFIGURATION_TYPES})
        set(_logfile ${SETUP_DIR}/testing_${_id}_${cfg}.xml)
        message(STATUS "Running tests for ${_path} (${cfg}) -> ${_logfile}")
        execute_process(
            COMMAND ctest -C ${cfg} --no-compress-output -T Test
            WORKING_DIRECTORY ${SETUP_DIR}/${_path})
        file(STRINGS ${SETUP_DIR}/${_path}/Testing/TAG _tag LIMIT_COUNT 1)
        file(RENAME ${SETUP_DIR}/${_path}/Testing/${_tag}/Test.xml ${_logfile})
    endforeach()
endfunction()
