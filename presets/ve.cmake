set(CMAKE_CXX_COMPILER clang++ CACHE STRING "")
set(CMAKE_C_COMPILER clang CACHE STRING "")
set(CMAKE_CXX_FLAGS "--target=ve-linux -mno-vepacked" CACHE STRING "")
set(CMAKE_C_FLAGS "--target=ve-linux -mno-vepacked " CACHE STRING "")
set(ANYDSL_TARGET_TRIPLE "ve-linux" CACHE STRING "")
set(ANYDSL_TARGET_CPU "generic" CACHE STRING "")
set(ANYDSL_TARGET_FEATURES "+vpu,-packed" CACHE STRING "")
set(RT_ENABLE_JIT Off CACHE BOOL "")

# FIXME: libinit problem with shared libraries in llvm-ve
set(AnyDSL_runtime_BUILD_SHARED CACHE BOOL Off)

# Cmake is looking for these in the VH's environment when really should be
# looking for VE packages. LLVM and OpenCL is spurious hits in particluar.
# set(CMAKE_DISABLE_FIND_PACKAGE_LLVM True CACHE BOOL "")
set(CMAKE_DISABLE_FIND_PACKAGE_OpenCL True CACHE BOOL "")
set(CMAKE_DISABLE_FIND_PACKAGE_CUDA True CACHE BOOL "")
set(CMAKE_DISABLE_FIND_PACKAGE_HSA True CACHE BOOL "")
set(CMAKE_DISABLE_FIND_PACKAGE_TBB True CACHE BOOL "")
