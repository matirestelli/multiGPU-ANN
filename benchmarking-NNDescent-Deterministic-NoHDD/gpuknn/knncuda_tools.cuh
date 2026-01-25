#ifndef XMUKNN_KNNCUDA_TOOLS_CUH
#define XMUKNN_KNNCUDA_TOOLS_CUH
#include <string>
#include <vector>
#pragma once
#include <iostream>
#include <cuda_runtime.h>

#include "../tools/nndescent_element.cuh"

using namespace std;

// Uncomment the following lines to enable CUDA error checking macros.
// These macros will print error messages if CUDA calls or kernel launches fail.
/*
#define CUDA_ERROR_CHECK(call)                                              \
  {                                                                         \
    cudaError_t err__ = (call);                                             \
    if (err__ != cudaSuccess) {                                             \
      int gpu_id__ = -1;                                                    \
      cudaGetDevice(&gpu_id__);                                             \
      std::cerr << "[GPU " << gpu_id__ << "] " << __FILE__ << ':'           \
                << __LINE__ << " in " << #call << " -> "                    \
                << cudaGetErrorString(err__) << " ("                        \
                << static_cast<int>(err__) << ')' << std::endl;            \
    }                                                                       \
  }

#define CUDA_ERROR_KERNEL_CHECK()                                          \
  {                                                                         \
    cudaError_t err__ = cudaGetLastError();                                 \
    if (err__ != cudaSuccess) {                                             \
      int gpu_id__ = -1;                                                    \
      cudaGetDevice(&gpu_id__);                                             \
      std::cerr << "[GPU " << gpu_id__ << "] " << __FILE__ << ':'           \
                << __LINE__ << " kernel-launch -> "                         \
                << cudaGetErrorString(err__) << " ("                        \
                << static_cast<int>(err__) << ')' << std::endl;            \
    }                                                                       \
                                                                            \
    err__ = cudaDeviceSynchronize();                                        \
    if (err__ != cudaSuccess) {                                             \
      int gpu_id__ = -1;                                                    \
      cudaGetDevice(&gpu_id__);                                             \
      std::cerr << "[GPU " << gpu_id__ << "] " << __FILE__ << ':'           \
                << __LINE__ << " kernel-exec  -> "                          \
                << cudaGetErrorString(err__) << " ("                        \
                << static_cast<int>(err__) << ')' << std::endl;            \
    }                                                                       \
  }

  */

//use this if no need for macros for error checking
#define CUDA_ERROR_CHECK(call) { (void)(call); }
#define CUDA_ERROR_KERNEL_CHECK() {}



void DevRNGLongLong(unsigned long long *dev_data, int n);
void GenerateRandomKNNGraphIndex(int **knn_graph_index, const int graph_size,
                                 const int neighb_num);
__device__ int GetItNum(const int sum_num, const int num_per_it);
void ToHostKNNGraph(vector<vector<NNDElement>> *origin_knn_graph_ptr,
                    const NNDElement *knn_graph_dev, const int size,
                    const int neighb_num);
void ToHostKNNGraph(NNDElement **host_knn_graph_ptr,
                    const NNDElement *knn_graph_dev, const int size,
                    const int neighb_num);
void OutputHostKNNGraph(const vector<vector<NNDElement>> &knn_graph,
                        const string &out_path,
                        const bool output_distance = false);
size_t PredPeakGPUMemory(const int vecs_num, const int vecs_dim, const int k,
                         const int sample_num, const bool thrust_random = true);
__host__ __device__ uint64_t xorshift64star(uint64_t x);
#endif