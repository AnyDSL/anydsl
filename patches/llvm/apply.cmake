
find_package(Git REQUIRED)

message(STATUS "Patching LLVM ${LLVM_VERSION}")
message(STATUS "CMAKE_CURRENT_LIST_DIR: ${CMAKE_CURRENT_LIST_DIR}")
set(PATCH_COMMAND ${GIT_EXECUTABLE} apply --ignore-space-change --ignore-whitespace)

# all LLVM versions
execute_process(
	COMMAND ${PATCH_COMMAND} --directory llvm ${CMAKE_CURRENT_LIST_DIR}/nvptx_feature.patch
)
