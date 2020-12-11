set(CMAKE_CXX_COMPILER clang++ CACHE STRING "")
set(CMAKE_C_COMPILER clang CACHE STRING "")
set(CMAKE_CXX_FLAGS "--target=ve-unknown-linux" CACHE STRING "")
set(CMAKE_C_FLAGS "--target=ve-unknown-linux" CACHE STRING "")
set(ANYDSL_TARGET_TRIPLE "ve-unknown-linux" CACHE STRING "")
set(ANYDSL_TARGET_CPU "ve" CACHE STRING "")
set(ANYDSL_TARGET_FEATURES "+vpu" CACHE STRING "")
set(RT_ENABLE_JIT Off CACHE BOOL "")

# Cmake is looking for these in the VH's environment when really should be
# looking for VE packages. LLVM & OpenCL are spurious hits in particluar.
set(CMAKE_DISABLE_FIND_PACKAGE_LLVM True CACHE BOOL "")
set(CMAKE_DISABLE_FIND_PACKAGE_OpenCL True CACHE BOOL "")
set(CMAKE_DISABLE_FIND_PACKAGE_CUDA True CACHE BOOL "")
set(CMAKE_DISABLE_FIND_PACKAGE_HSA True CACHE BOOL "")
set(CMAKE_DISABLE_FIND_PACKAGE_TBB True CACHE BOOL "")
