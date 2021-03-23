
find_package(Git REQUIRED)

message(STATUS "Patching LLVM ${LLVM_VERSION}")
message(STATUS "CMAKE_CURRENT_LIST_DIR: ${CMAKE_CURRENT_LIST_DIR}")
message(STATUS "CMAKE_CURRENT_LIST_DIR: ${CMAKE_CURRENT_LIST_DIR}")
set(PATCH_COMMAND ${GIT_EXECUTABLE} apply --ignore-space-change --ignore-whitespace)

# all LLVM versions
execute_process(
	COMMAND ${PATCH_COMMAND} ${CMAKE_CURRENT_LIST_DIR}/nvptx_feature_ptx60.patch
)

# LLVM 10 only
if((${LLVM_VERSION} VERSION_GREATER_EQUAL 10) AND (${LLVM_VERSION} VERSION_LESS 11))
execute_process(
	COMMAND ${PATCH_COMMAND} ${CMAKE_CURRENT_LIST_DIR}/type_traits.patch
)
endif()
