cmake_minimum_required(VERSION 3.8 FATAL_ERROR)
project(gpuknn LANGUAGES CXX CUDA)

enable_language(CUDA)

# Set correct CUDA paths for Polaris at ALCF (cudatoolkit 12.9)
set(CUDA_ROOT "$ENV{CUDA_HOME}")
if(NOT CUDA_ROOT)
    # Fallback for Polaris default CUDA path
    set(CUDA_ROOT "/opt/nvidia/hpc_sdk/Linux_x86_64/25.5/cuda")
endif()
set(CUDART_LIBRARY "${CUDA_ROOT}/targets/x86_64-linux/lib/libcudart.so")
set(CURAND_LIBRARY "/opt/nvidia/hpc_sdk/Linux_x86_64/25.5/REDIST/math_libs/12.9/targets/x86_64-linux/lib/libcurand.so")
set(CUBLAS_LIBRARY "/opt/nvidia/hpc_sdk/Linux_x86_64/25.5/REDIST/math_libs/12.9/targets/x86_64-linux/lib/libcublas.so")

# Include directories for NVIDIA libraries and tools
include_directories(${CUDA_ROOT}/targets/x86_64-linux/include)
include_directories(${CUDA_ROOT}/targets/x86_64-linux/include/nvtx3)

# GPU library
add_library(knncuda STATIC
    gpuknn/gen_large_knngraph.cu
    gpuknn/gen_large_knngraph.cuh
    gpuknn/knncuda.cu
    gpuknn/knncuda.cuh
    gpuknn/nndescent.cu
    gpuknn/nndescent.cuh
    gpuknn/knncuda_tools.cuh
    gpuknn/knncuda_tools.cu
    gpuknn/knnmerge.cuh
    gpuknn/knnmerge.cu
    tools/distfunc.hpp
    tools/filetool.hpp
    tools/nndescent_element.cuh
    tools/knndata_manager.hpp
    xmuknn.h
    xmuknn.cpp
)

target_compile_features(knncuda PUBLIC cxx_std_14)

# CUDA flags
set(CMAKE_CUDA_FLAGS "${CMAKE_CUDA_FLAGS} -D_FILE_OFFSET_BITS=64 -O3 -std=c++14 -arch=sm_80 -rdc=true -Xcompiler -fopenmp -pthread")

# C++ flags
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -D_FILE_OFFSET_BITS=64 -std=c++14 -O3 -pthread -fopenmp")

# Main executable
add_executable(gknng main.cu)
set_property(TARGET gknng PROPERTY CUDA_SEPARABLE_COMPILATION ON)
set_property(TARGET gknng PROPERTY CUDA_RESOLVE_DEVICE_SYMBOLS ON)
set_property(TARGET gknng PROPERTY CUDA_ARCHITECTURES 80)
set_property(TARGET knncuda PROPERTY CUDA_ARCHITECTURES 80)

# Link all libraries correctly
target_link_libraries(gknng
    PRIVATE
    knncuda
    ${CUDART_LIBRARY}
    ${CURAND_LIBRARY}
    ${CUBLAS_LIBRARY}
)

