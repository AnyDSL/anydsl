set(CMAKE_CXX_COMPILER clang++ CACHE STRING "")
set(CMAKE_C_COMPILER clang CACHE STRING "")
set(CMAKE_CXX_FLAGS "--target=ve-unknown-linux" CACHE STRING "")
set(CMAKE_C_FLAGS "--target=ve-unknown-linux" CACHE STRING "")
set(ANYDSL_TARGET_TRIPLE "ve-unknown-linux" CACHE STRING "")
set(ANYDSL_TARGET_CPU "ve" CACHE STRING "")
set(ANYDSL_TARGET_FEATURES "+vpu" CACHE STRING "")
set(RT_ENABLE_JIT Off CACHE BOOL "")
