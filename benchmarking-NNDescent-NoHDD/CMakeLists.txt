cmake_minimum_required(VERSION 3.8 FATAL_ERROR)
project(gpuknn LANGUAGES CXX CUDA)

enable_language(CUDA)

# Set correct CUDA paths for Sophia at ALCF (cudatoolkit 12.6.0)
set(CUDA_ROOT "/soft/compilers/cudatoolkit/cuda-12.6.0")
set(CUDART_LIBRARY "${CUDA_ROOT}/lib64/libcudart.so")
set(CURAND_LIBRARY "${CUDA_ROOT}/lib64/libcurand.so")
set(CUBLAS_LIBRARY "${CUDA_ROOT}/lib64/libcublas.so")

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
    random_offset_tracker.cpp 
    gpuknn/db_size.cu 
)

target_compile_features(knncuda PUBLIC cxx_std_14)

# CUDA flags
set(CMAKE_CUDA_FLAGS "${CMAKE_CUDA_FLAGS} -D_FILE_OFFSET_BITS=64 -O3 -std=c++14 -arch=sm_80 -rdc=true -Xcompiler -fopenmp -pthread -lcudadevrt")

# C++ flags
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -D_FILE_OFFSET_BITS=64 -std=c++14 -O3 -pthread -fopenmp")

# Main executable
add_executable(gknng main.cu)
set_property(TARGET gknng PROPERTY CUDA_SEPARABLE_COMPILATION ON)
set_property(TARGET gknng PROPERTY CUDA_RESOLVE_DEVICE_SYMBOLS ON)
set_property(TARGET gknng PROPERTY CUDA_ARCHITECTURES 80)
set_property(TARGET knncuda PROPERTY CUDA_ARCHITECTURES 80)

target_link_libraries(gknng
    PRIVATE
    knncuda
    ${CUDART_LIBRARY}
    ${CURAND_LIBRARY}
    ${CUBLAS_LIBRARY}
    -lrt -lpthread -ldl 
)

# Dummy KNN generator
add_executable(generate_dummy_knn generate_dummy_knn.cu)
set_target_properties(generate_dummy_knn PROPERTIES
    CUDA_SEPARABLE_COMPILATION ON
    CUDA_RESOLVE_DEVICE_SYMBOLS ON
    CUDA_ARCHITECTURES 80
)

target_link_libraries(generate_dummy_knn
    PRIVATE
    knncuda
    ${CUDART_LIBRARY}
    ${CURAND_LIBRARY}
    ${CUBLAS_LIBRARY}
    -lrt -lpthread -ldl
)
