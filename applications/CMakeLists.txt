cmake_minimum_required(VERSION 3.4 FATAL_ERROR)

file(GLOB _application_paths "*/CMakeLists.txt")

foreach(_appfullpath ${_application_paths})
	get_filename_component(_apppath ${_appfullpath} DIRECTORY)
	get_filename_component(_appdir ${_apppath} NAME)

    set(_appoption "AnyDSL_BUILD_${_appdir}")
	option(${_appoption} OFF)
	if(NOT ${_appoption})
		message(STATUS "Found application ${_appdir} (skipped)")
	else()
		message(STATUS "Build with application ${_appdir}")
		add_subdirectory(${_appdir})
	endif()
endforeach()
