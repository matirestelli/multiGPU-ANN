//no hdd version deterministic
#include <limits.h>  // for PATH_MAX
#include <nvToolsExt.h>
#include <unistd.h>
#include <unistd.h>  // for getcwd
#include <iomanip>

#include <algorithm>
#include <cstdlib>  // for system
#include <fstream>
#include <iostream>
#include <sstream>
#include <string>
#include <thread>
#include <vector>

#include "../tools/knndata_manager.hpp"
#include "../tools/nndescent_element.cuh"
#include "../tools/timer.hpp"
#include "cuda_runtime.h"
#include "device_launch_parameters.h"
#include "gen_large_knngraph.cuh"
#include "knncuda_tools.cuh"
#include "knnmerge.cuh"
#include "nndescent.cuh"
#include "db_size.cuh"

double total_HDD_time = 0.0;
double total_Building_time = 0.0;
double total_Merge_time = 0.0;
double total_ANNS_time = 0.0;
std::mutex timing_mutex;

#define NUM_GPU 3


using namespace std;

void SetupDbSize(long int n)
{
  //set up in each gpu the size of the database
  //this is used in the knnmerge to check for correctness of the label
  printf("Setting up db_size = %ld\n", n);
    for (int dev = 0; dev < NUM_GPU; ++dev) {
        // OLD (no error check): cudaSetDevice(dev);
        CUDA_ERROR_CHECK(cudaSetDevice(dev));           // select GPU
        // OLD (no error check): cudaMemcpyToSymbol(g_db_size, &n, sizeof(long int));
        CUDA_ERROR_CHECK(cudaMemcpyToSymbol(g_db_size, &n, sizeof(long int))); // upload 4 B
        printf("GPU %d: db_size = %ld\n", dev, n);
    }
    xmuknn::h_db_size = static_cast<std::size_t>(n);    // (host copy)
}


void ReadGraph(const string &graph_path, NNDElement **knn_graph_ptr,
               const int read_pos, const int read_num) {
  NNDElement *&knn_graph = *knn_graph_ptr;
  int dim;
  FileTool::ReadBinaryVecs(graph_path, &knn_graph, &dim, read_pos, read_num);
  // ADDED: Validate read succeeded
  if (knn_graph == nullptr) {
    cerr << "ERROR: ReadGraph failed - null pointer returned for " << graph_path 
         << " at pos=" << read_pos << ", count=" << read_num << endl;
    exit(-1);
  }
  printf("Read %d vecs from %s\n", read_num, graph_path.c_str());
}

void WriteGraph(const string &graph_path, const NNDElement *knn_graph,
                const int graph_size, const int k, const int write_pos) {
  FileTool::WriteBinaryVecs(graph_path, knn_graph, write_pos, graph_size, k);
}

void WriteTXTGraph(const string &graph_path, const NNDElement *knn_graph,
                   const int graph_size, const int k, const int write_pos) {
  ofstream out(graph_path);
  for (int i = 0; i < graph_size; i++) {
    out << k << "\t";
    for (int j = 0; j < k; j++) {
      auto elem = knn_graph[i * k + j];
      out << elem.distance() << "\t" << elem.label() << "\t";
    }
    out << endl;
  }
  out.close();
}

void BuildEachShard(KNNDataManager &data_manager, const string &out_data_path,
                    int id) {
  Timer knn_timer;

  int i = id;

  cout << "GPU " << id % NUM_GPU << " is activated" << endl;

  cudaSetDevice(id % NUM_GPU);

  mutex mtx;

  NNDElement *knn_graph_local = nullptr;
  NNDElement *knn_graph_global = nullptr;
  // Get vector data from memory (already loaded)
  const float *vectors = data_manager.GetVectors(i);
  if (vectors == nullptr) {
    cerr << "ERROR: BuildEachShard - Failed to get vectors for shard " << i << endl;
    exit(-1);
  }

  float *vectors_dev;
  CUDA_ERROR_CHECK(cudaMalloc(&vectors_dev, (size_t)data_manager.GetVecsNum(i) *
                               data_manager.GetDim() * sizeof(float)));
  CUDA_ERROR_CHECK(cudaMemcpy(vectors_dev, data_manager.GetVectors(i),
             (size_t)data_manager.GetVecsNum(i) * data_manager.GetDim() *
                 sizeof(float),
             cudaMemcpyHostToDevice));
  cout << "Building No. " << i << endl;
  knn_timer.start();
  
  gpuknn::NNDescent(&knn_graph_local, vectors_dev, data_manager.GetVecsNum(i),
                    data_manager.GetDim(), 6, false);
  
  if (knn_graph_local == nullptr) {
    cerr << "ERROR: BuildEachShard - NNDescent returned null for shard " << i << endl;
    cudaFree(vectors_dev);
    exit(-1);
  }
  
  cout << "End building No." << i << " in " << knn_timer.end() << " seconds"
       << endl;

  // Create global KNN graph by adjusting labels  
  knn_graph_global = new NNDElement[data_manager.GetVecsNum(i) * data_manager.GetK()];
  for (int j = 0; j < data_manager.GetVecsNum(i) * data_manager.GetK(); j++) {
    knn_graph_global[j] = knn_graph_local[j];
    knn_graph_global[j].SetLabel(knn_graph_local[j].label() +
                            data_manager.GetBeginPosition(i));
  }

  // Store both graphs in data manager
  data_manager.SetLocalKNNGraph(i, knn_graph_local);
  data_manager.SetGlobalKNNGraph(i, knn_graph_global);

  // OLD (no error check): cudaFree(vectors_dev);
  CUDA_ERROR_CHECK(cudaFree(vectors_dev));

  // OLD DEBUG: Empty mutex lock/unlock - commented out for performance
  //mtx.lock();
  //mtx.unlock();
}

int MergeList(const NNDElement *A, const int m, const NNDElement *B,
              const int n, NNDElement *C, const int max_size) {
  int i = 0, j = 0, cnt = 0;
  while ((i < m) && (j < n)) {
    if (A[i] <= B[j]) {
      C[cnt++] = A[i++];
      if (cnt >= max_size) goto EXIT;
    } else {
      C[cnt++] = B[j++];
      if (cnt >= max_size) goto EXIT;
    }
  }

  if (i == m) {
    for (; j < n; j++) {
      C[cnt++] = B[j];
      if (cnt >= max_size) goto EXIT;
    }
  } else {
    for (; i < m; i++) {
      C[cnt++] = A[i];
      if (cnt >= max_size) goto EXIT;
    }
  }
EXIT:
  return cnt;
}

void UpdateKNNGraph(NNDElement **old_graph_ptr, const NNDElement *new_graph,
                    const int graph_size, const int k) {
  NNDElement *&old_graph = *old_graph_ptr;
  NNDElement *tmp_list = new NNDElement[k * 2];
  for (int i = 0; i < graph_size; i++) {
    MergeList(&old_graph[i * k], k, &new_graph[i * k], k, tmp_list, k * 2);
    unique(tmp_list, tmp_list + k * 2);
    for (int j = 0; j < k; j++) {
      old_graph[i * k + j] = tmp_list[j];
    }
  }
  delete[] tmp_list;
}

__device__ void UniqueMergeSequential(const NNDElement *A, const int m,
                                      const NNDElement *B, const int n,
                                      NNDElement *C, const int k) {
  int i = 0, j = 0, cnt = 0;
  while ((i < m) && (j < n)) {
    if (A[i] <= B[j]) {
      C[cnt++] = A[i++];
      if (cnt >= k) goto EXIT;
      while (i < m && A[i] <= C[cnt - 1]) i++;
      while (j < n && B[j] <= C[cnt - 1]) j++;
    } else {
      C[cnt++] = B[j++];
      if (cnt >= k) goto EXIT;
      while (i < m && A[i] <= C[cnt - 1]) i++;
      while (j < n && B[j] <= C[cnt - 1]) j++;
    }
  }

  if (i == m) {
    for (; j < n; j++) {
      if (B[j] > C[cnt - 1]) {
        C[cnt++] = B[j];
      }
      if (cnt >= k) goto EXIT;
    }
    for (; i < m; i++) {
      if (A[i] > C[cnt - 1]) {
        C[cnt++] = A[i];
      }
      if (cnt >= k) goto EXIT;
    }
  } else {
    for (; i < m; i++) {
      if (A[i] > C[cnt - 1]) {
        C[cnt++] = A[i];
      }
      if (cnt >= k) goto EXIT;
    }
    for (; j < n; j++) {
      if (B[j] > C[cnt - 1]) {
        C[cnt++] = B[j];
      }
      if (cnt >= k) goto EXIT;
    }
  }

EXIT:
  return;
}

__global__ void UpdateKNNGraphKernel(NNDElement *result_graph,
                                     const NNDElement *new_graph,
                                     const int start_pos) {
  int list_id = blockIdx.x + start_pos;
  int result_list_id = blockIdx.x;
  int tx = threadIdx.x;
  __shared__ NNDElement a_cache[NEIGHB_NUM_PER_LIST];
  __shared__ NNDElement b_cache[NEIGHB_NUM_PER_LIST];
  __shared__ NNDElement c_cache[NEIGHB_NUM_PER_LIST];
  int it_num = GetItNum(NEIGHB_NUM_PER_LIST, WARP_SIZE);
  for (int i = 0; i < it_num; i++) {
    int pos = i * WARP_SIZE + tx;
    if (pos < NEIGHB_NUM_PER_LIST) {
      a_cache[pos] = result_graph[result_list_id * NEIGHB_NUM_PER_LIST + pos];
      b_cache[pos] = new_graph[list_id * NEIGHB_NUM_PER_LIST + pos];
    }
  }
  if (tx == 0) {
    UniqueMergeSequential(a_cache, NEIGHB_NUM_PER_LIST, b_cache,
                          NEIGHB_NUM_PER_LIST, c_cache, NEIGHB_NUM_PER_LIST);
  }
  for (int i = 0; i < it_num; i++) {
    int pos = i * WARP_SIZE + tx;
    if (pos < NEIGHB_NUM_PER_LIST) {
      result_graph[result_list_id * NEIGHB_NUM_PER_LIST + pos] = c_cache[pos];
    }
  }
}

__global__ void PreProcIDKernel(NNDElement *result_knn_graph,
                                const int first_graph_size,
                                const int graph_size, const int k,
                                const int offset_a, const int offset_b) {
  int list_id = blockIdx.x;
  int neighb_id = threadIdx.x;
  auto &elem = result_knn_graph[list_id * k + neighb_id];
  if (elem.label() >= first_graph_size) {
    elem.SetLabel(elem.label() - first_graph_size + offset_b);
  } else {
    elem.SetLabel(elem.label() + offset_a);
  }
  return;
}

void PreProcID(NNDElement *result_knn_graph_host, const int first_graph_size,
               const int graph_size, const int k, const int offset_a,
               const int offset_b) {
  for (int i = 0; i < graph_size; i++) {
    for (int j = 0; j < k; j++) {
      auto &elem = result_knn_graph_host[i * k + j];
      if (elem.label() >= first_graph_size) {
        elem.SetLabel(elem.label() - first_graph_size + offset_b);
      } else {
        elem.SetLabel(elem.label() + offset_a);
      }
    }
  }
}

recursive_mutex multi_merge;

void MultiMerge(KNNDataManager &data_manager, const string &out_data_path,
                int id_gpu, int begin, int allow_next, bool isLast = false) {
  // Define a GPU que irá realizar a tarefa

  int shards_num = data_manager.GetShardsNum();

  if (begin >= shards_num - 2 && !isLast) return;

  cudaSetDevice(id_gpu);

  int i = begin;

  // Sync
  multi_merge.lock();

  printf("Shard %d foi ativado e ira comecar\n", begin);
  mutex mtx;
  printf("END para %d -> %ld \n\n", begin, &mtx);

  Timer merge_timer;
  merge_timer.start();

  // Get the current global KNN graphs from memory - no disk I/O needed
  NNDElement *result_first = nullptr;
  NNDElement *result_second = nullptr;
  try {
    // Get mutable pointer to modify during merging
    result_first = data_manager.GetMutableGlobalKNNGraph(i);
    if (result_first == nullptr) {
      cerr << "ERROR: MultiMerge - Failed to get global graph for shard " << i << endl;
      multi_merge.unlock();
      exit(-1);
    }
    printf("Shard %d foi read e ira comecar\n", i);
  } catch (const exception& e) {
    cerr << "ERROR: MultiMerge - Exception getting global graph for shard " << i 
         << ": " << e.what() << endl;
    multi_merge.unlock();
    exit(-1);
  }

  for (int j = i + 1; j < shards_num; j++) {
    // OLD PROFILING: NVTX range with string construction - commented out for performance
    std::string label = "Merge GPU " + std::to_string(id_gpu) +
                        ": shard i=" + std::to_string(i) +
                        ": shard j=" + std::to_string(j);
    nvtxRangePush(label.c_str());

    NNDElement *result_knn_graph_dev = nullptr;
    Timer timer;
    timer.start();

    // Get vector data and local KNN graphs from memory
    const float *vectors_i = data_manager.GetVectors(i);
    const float *vectors_j = data_manager.GetVectors(j);
    const NNDElement *local_knn_i = data_manager.GetLocalKNNGraph(i);
    const NNDElement *local_knn_j = data_manager.GetLocalKNNGraph(j);
    
    if (vectors_i == nullptr || vectors_j == nullptr || 
        local_knn_i == nullptr || local_knn_j == nullptr) {
      cerr << "ERROR: MultiMerge - Null pointers for shard data i=" << i 
           << ", j=" << j << endl;
      nvtxRangePop();
      multi_merge.unlock();
      exit(-1);
    }

    int total_nodes = data_manager.GetVecsNum(i) + data_manager.GetVecsNum(j);

    gpuknn::KNNMergeFromHost(
        &result_knn_graph_dev, vectors_i,
        data_manager.GetVecsNum(i), local_knn_i,
        vectors_j, data_manager.GetVecsNum(j),
        local_knn_j);
    
    if (result_knn_graph_dev == nullptr) {
      cerr << "ERROR: MultiMerge - KNNMergeFromHost returned null for shards " 
           << i << " and " << j << endl;
      nvtxRangePop();
      multi_merge.unlock();
      exit(-1);
    }
    
    cout << "Merge costs: J = " << j << " I = " << i << " " << timer.end()
         << endl;
    // OLD DEBUG: Empty mutex lock/unlock - commented out for performance
    //mtx.lock();
    //mtx.unlock();

    Timer update_graph_timer;
    update_graph_timer.start();

    // Get the current global graph for shard j from memory (no disk I/O)
    try {
      result_second = data_manager.GetMutableGlobalKNNGraph(j);
      if (result_second == nullptr) {
        cerr << "ERROR: MultiMerge - Failed to get global graph for shard " << j << endl;
        cudaFree(result_knn_graph_dev);
        nvtxRangePop();
        exit(-1);
      }
    } catch (const exception& e) {
      cerr << "ERROR: MultiMerge - Exception getting global graph for shard " << j 
           << ": " << e.what() << endl;
      cudaFree(result_knn_graph_dev);
      nvtxRangePop();
      exit(-1);
    }

    // Allocate GPU memory for current global graphs
    NNDElement *result_first_dev = nullptr;
    size_t first_graph_size = (size_t)data_manager.GetVecsNum(i) * data_manager.GetK() * sizeof(NNDElement);
    CUDA_ERROR_CHECK(cudaMalloc(&result_first_dev, first_graph_size));
    if (result_first_dev == nullptr) {
      cerr << "ERROR: MultiMerge - Failed to allocate GPU memory for first graph" << endl;
      cudaFree(result_knn_graph_dev);
      nvtxRangePop();
      exit(-1);
    }
    
    CUDA_ERROR_CHECK(cudaMemcpy(result_first_dev, result_first, first_graph_size, cudaMemcpyHostToDevice));
    
    NNDElement *result_second_dev = nullptr;
    size_t second_graph_size = (size_t)data_manager.GetVecsNum(j) * data_manager.GetK() * sizeof(NNDElement);
    CUDA_ERROR_CHECK(cudaMalloc(&result_second_dev, second_graph_size));
    if (result_second_dev == nullptr) {
      cerr << "ERROR: MultiMerge - Failed to allocate GPU memory for second graph" << endl;
      cudaFree(result_first_dev);
      cudaFree(result_knn_graph_dev);
      nvtxRangePop();
      exit(-1);
    }
    
    CUDA_ERROR_CHECK(cudaMemcpy(result_second_dev, result_second, second_graph_size, cudaMemcpyHostToDevice));
    
    
    
    PreProcIDKernel<<<data_manager.GetVecsNum(i) + data_manager.GetVecsNum(j),
                      data_manager.GetK()>>>(
        result_knn_graph_dev, data_manager.GetVecsNum(i),
        data_manager.GetVecsNum(i) + data_manager.GetVecsNum(j),
        data_manager.GetK(), data_manager.GetBeginPosition(i),
        data_manager.GetBeginPosition(j));
    //CUDA_ERROR_KERNEL_CHECK();  // OLD DEBUG: commented out for performance
    
  // OLD DEBUG: Sync barrier and error check - commented out for performance

    CUDA_ERROR_CHECK(cudaDeviceSynchronize());   // <-- catches runtime faults
    auto status = cudaGetLastError();
    if (status != cudaSuccess) {
      cerr << "PreProcID failed" << endl;
      cerr << cudaGetErrorString(status) << endl;
      exit(-1);
    }

  
    
  
    UpdateKNNGraphKernel<<<data_manager.GetVecsNum(i), WARP_SIZE>>>(
        result_first_dev, result_knn_graph_dev, 0);
    //CUDA_ERROR_KERNEL_CHECK();  // OLD DEBUG: commented out for performance
  
    
    
    UpdateKNNGraphKernel<<<data_manager.GetVecsNum(j), WARP_SIZE>>>(
        result_second_dev, result_knn_graph_dev, data_manager.GetVecsNum(i));
    //CUDA_ERROR_KERNEL_CHECK();  // OLD DEBUG: commented out for performance
    
 
    // OLD DEBUG: Sync barrier - commented out for performance
    CUDA_ERROR_CHECK(cudaDeviceSynchronize());   // <-- catches runtime faults
    // Copy updated graphs back to host
    CUDA_ERROR_CHECK(cudaMemcpy(result_first, result_first_dev, first_graph_size, cudaMemcpyDeviceToHost));
    CUDA_ERROR_CHECK(cudaMemcpy(result_second, result_second_dev, second_graph_size, cudaMemcpyDeviceToHost));
    
    // OLD DEBUG: Redundant error check after memcpy - commented out for performance
    //auto status = cudaGetLastError();
    //if (status != cudaSuccess) {
    //  cerr << "ERROR: MultiMerge - CUDA error during memcpy: " << cudaGetErrorString(status) << endl;
    //  cudaFree(result_first_dev);
    //  cudaFree(result_second_dev);
    //  cudaFree(result_knn_graph_dev);
    //  // nvtxRangePop();
    //  exit(-1);
    //}
    
    // Clean up GPU memory
    // OLD (no error check): cudaFree(result_first_dev);
    CUDA_ERROR_CHECK(cudaFree(result_first_dev));
    // OLD (no error check): cudaFree(result_second_dev);
    CUDA_ERROR_CHECK(cudaFree(result_second_dev));
    // OLD (no error check): cudaFree(result_knn_graph_dev);
    CUDA_ERROR_CHECK(cudaFree(result_knn_graph_dev));
    
    cerr << "Update graph costs: " << update_graph_timer.end() << endl;

    // The updated graphs are now in result_first and result_second
    // They will be used in the next iteration (result_first is persistent)
    // result_second contains the updated global graph for shard j

    // No need to discard shards since we keep everything in memory
    // No file writing needed since we'll write everything at the end
    // OLD VERSION: Had detached thread to write result_second to file - removed this functionality
    // NEW VERSION: Updated global graphs stay in memory for next iterations
    
    // Espera o atual ser discartado
    if (j == allow_next) {
      nvtxMark("Unlock mutex for next gpu to start");
      multi_merge.unlock();
    }
    


nvtxRangePop();
  }

  // Store the final merged result_first back in the data manager
  // This ensures the accumulated merges are preserved for the final output
  // (result_first contains the merged graph for shard i after all merges)
  // Note: result_first pointer is already stored in the data manager maps,
  // so the updates made during merging are automatically reflected
  
  float merge_time = merge_timer.end();
  cerr << "No. " << i << " mergers cost: " << merge_time << endl;
  cerr << "No. " << i << " avg. cost: " << merge_time / (shards_num - i - 1)
       << "\n\n"
       << endl;

  // OLD DEBUG: Final error check - commented out for performance
  //auto status = cudaGetLastError();
  //if (status != cudaSuccess) {
  //  cerr << "ERROR: MultiMerge - Final CUDA error: " << cudaGetErrorString(status) << endl;
  //  exit(-1);
  //}
  

}

// separate the build and merge phase
// 1. Build each shard - all data stays in memory
void BuildShardsOnly(const string &vecs_data_path, const string &out_data_path,
                     const int k, int num_shards) {
  assert(k == NEIGHB_NUM_PER_LIST);
  
  cout << "Starting BuildShardsOnly - all data will be kept in memory" << endl;
  
  KNNDataManager data_manager(vecs_data_path, k, num_shards, 10000000);
  assert(data_manager.GetDim() == VEC_DIM);
  data_manager.CheckStatus();

  // No need to create blank files - everything stays in memory
  cout << "Building " << num_shards << " shards using " << NUM_GPU << " GPUs" << endl;

  int iters = num_shards / NUM_GPU;
  for (int s = 0; s < iters; s++) {
    vector<thread> threads;
    for (int i = 0; i < NUM_GPU; i++) {
      int shard_id = NUM_GPU * s + i;
      if (shard_id < num_shards) {
        threads.emplace_back([&data_manager, out_data_path, shard_id]() {
          BuildEachShard(data_manager, out_data_path, shard_id);
        });
      }
    }
    for (auto &t : threads) t.join();
  }

  cout << "All shards built successfully - data kept in memory" << endl;
  data_manager.CheckStatus();
  
  // When BuildShardsOnly is used standalone, save global graphs to disk for debugging
  cout << "Saving global KNN graphs to disk for standalone build mode" << endl;
  data_manager.WriteAllGlobalKNNGraphsToFile(out_data_path);
  cout << "BuildShardsOnly completed - global graphs saved to: " << out_data_path << endl;
}

// 2. Merge each shard - loads pre-built global graphs from disk and merges in memory
// 
// IMPORTANT: This function expects pre-built KNN graphs from the Cineca version.
// You must manually copy TWO files from Cineca's build output BEFORE running merge_only:
//
// File 1: vectors.kgraph (LOCAL labels: 0 to shard_size-1)
//   - Created by Cineca's first WriteGraph() call in BuildEachShard
//   - Location: ../data/vectors.kgraph
//   - Contains: KNN graphs with local neighbor labels relative to each shard
//   - Purpose: Used during merge to compute new neighbors between shards
//
// File 2: NNDescent-KNNG.kgraph (GLOBAL labels: absolute database positions)
//   - Created by Cineca's second WriteGraph() call in BuildEachShard (after label conversion)
//   - Location: ../results/NNDescent-KNNG.kgraph  
//   - Contains: KNN graphs with global neighbor labels (local + shard begin position)
//   - Purpose: Starting point for merging - gets updated with new neighbors found during merge
//
// Copy commands (run from Cineca folder):
//   cp ../data/vectors.kgraph /path/to/No-HDD/data/vectors.kgraph
//   cp ../results/NNDescent-KNNG.kgraph /path/to/No-HDD/results/NNDescent-KNNG.kgraph
//
void MergeShardsOnly(const string &vecs_data_path, const string &out_data_path,
                     const int k, int num_shards) {
  assert(k == NEIGHB_NUM_PER_LIST);

  cout << "Starting MergeShardsOnly - loading pre-built graphs from Cineca and merging in memory" << endl;

  // Print current working directory
  char cwd[PATH_MAX];
  if (getcwd(cwd, sizeof(cwd)) != nullptr) {
    std::cout << "Current working directory: " << cwd << std::endl;
  } else {
    perror("getcwd() error");
  }

  // Verify that the required files exist (they should be copied from Cineca version)
  std::string local_graph_path = vecs_data_path + ".kgraph";  // ../data/vectors.kgraph
  std::string global_graph_path = out_data_path;               // ../results/NNDescent-KNNG.kgraph
  
  // Check if files exist
  std::ifstream check_local(local_graph_path, std::ios::binary);
  std::ifstream check_global(global_graph_path, std::ios::binary);
  
  if (!check_local.is_open()) {
    std::cerr << "ERROR: Local graph file not found: " << local_graph_path << "\n";
    std::cerr << "Please copy from Cineca: ../data/vectors.kgraph (contains LOCAL labels)\n";
    exit(1);
  }
  if (!check_global.is_open()) {
    std::cerr << "ERROR: Global graph file not found: " << global_graph_path << "\n";
    std::cerr << "Please copy from Cineca: ../results/NNDescent-KNNG.kgraph (contains GLOBAL labels)\n";
    exit(1);
  }
  
  check_local.close();
  check_global.close();
  
  std::cout << "Pre-built graph files found:\n";
  std::cout << "  Local graph (for merge computation): " << local_graph_path << "\n";
  std::cout << "  Global graph (to be updated): " << global_graph_path << "\n";

  // Create data manager - loads all vector data
  KNNDataManager data_manager(vecs_data_path, k, num_shards, 10000000);
  assert(data_manager.GetDim() == VEC_DIM);
  data_manager.CheckStatus();

  // Use the new method to load pre-built KNN graphs from disk into memory
  cout << "Loading pre-built KNN graphs from disk using LoadPreBuiltShardsFromDisk..." << endl;
  data_manager.LoadPreBuiltShardsFromDisk(out_data_path);
  
  cout << "All pre-built graphs loaded successfully from disk" << endl;
  data_manager.CheckStatus();
  
  // Now perform merging using the same logic as GenLargeKNNGraph
  int shards_num = data_manager.GetShardsNum();
  int iters = num_shards / NUM_GPU;

  cout << "Starting merge phase with " << NUM_GPU << " GPUs" << endl;
  
  for (int s = 0; s < iters; s++) {
    vector<thread> threads;

    for (int i = 0; i < NUM_GPU; i++) {
      sleep(1);
      int shard_id = NUM_GPU * s + i;
      int allow_begin = shard_id + NUM_GPU;

      if (allow_begin >= num_shards) allow_begin = num_shards - 1;

      if (shard_id < num_shards - 1) {  // Only merge if there are more shards
        threads.push_back(
            thread([&data_manager, out_data_path, s, i, allow_begin, shard_id]() {
              int gpu_id = i % NUM_GPU;
              std::string range_name =
                  "Merge Phase | gpuID: " + std::to_string(gpu_id) +
                  " | shard: " + std::to_string(shard_id);
              nvtxMark(range_name.c_str());

              MultiMerge(data_manager, out_data_path, i, shard_id, allow_begin);
            }));
      }
      sleep(1);
    }
    for (auto &t : threads) t.join();
    threads.clear();
  }

  // Final merge if needed
  if (shards_num > 2) {
    MultiMerge(data_manager, out_data_path, NUM_GPU - 1, shards_num - 2, -1, true);
  }

  // Write final merged results back to disk
  data_manager.WriteAllGlobalKNNGraphsToFile(out_data_path);
  
  cout << "MergeShardsOnly completed successfully" << endl;
}

// full version of both build and merge - all in memory
void GenLargeKNNGraph(const string &vecs_data_path, const string &out_data_path,
                      const int k, int num_shards) {
  assert(k == NEIGHB_NUM_PER_LIST);
  
  KNNDataManager data_manager(vecs_data_path, k, num_shards, 10000000);
  assert(data_manager.GetDim() == VEC_DIM);
  data_manager.CheckStatus();

  Timer total_ANNS_timer;
  total_ANNS_timer.start();
  
  // Blank knngraph costs: 0.07
  printf("-> %d\n", data_manager.GetVecsNum());
  printf("Iniciou?");

  int shards_num = data_manager.GetShardsNum();
  int iters = num_shards / NUM_GPU;

  Timer knn_timer;
  knn_timer.start();

  nvtxMark("Building Shards Phase");
  
  for (int s = 0; s < iters; s++) {
    vector<thread> threads;

    for (int i = 0; i < NUM_GPU; i++) {
      int shard_id = NUM_GPU * s + i;
      if (shard_id < num_shards) {
        threads.push_back(thread([&data_manager, out_data_path, shard_id]() {
          BuildEachShard(data_manager, out_data_path, shard_id);
        }));
      }
    }

    for (auto &t : threads) t.join();
  }

  double total_building_time = knn_timer.end();
  cerr << "Building shards costs: " << total_building_time << endl;
  {
    std::lock_guard<std::mutex> lock(timing_mutex);
    total_Building_time += total_building_time;
  }
  sleep(2);

  printf("\nIniciando o merge\n");
  nvtxMark("Start MultiGPU Merge Phase");

  Timer merge_timer;
  merge_timer.start();

  for (int s = 0; s < iters; s++) {
    vector<thread> threads;

    for (int i = 0; i < NUM_GPU; i++) {
      sleep(1);
      int shard_id = NUM_GPU * s + i;
      int allow_begin = shard_id + NUM_GPU;

      if (allow_begin >= num_shards) allow_begin = num_shards - 1;

      if (shard_id < num_shards - 1) {  // Only merge if there are more shards
        threads.push_back(
            thread([&data_manager, out_data_path, s, i, allow_begin, shard_id]() {
              int gpu_id = i % NUM_GPU;
              std::string range_name =
                  "Merge Phase | gpuID: " + std::to_string(gpu_id) +
                  " | shard: " + std::to_string(shard_id);
              nvtxMark(range_name.c_str());

              MultiMerge(data_manager, out_data_path, i, shard_id, allow_begin);
            }));
      }
      sleep(1);
    }
    for (auto &t : threads) t.join();
    threads.clear();
  }

  // Only do final merge if there's actually a remaining shard to merge
  // With 3 shards and 3 GPUs, all merges are done in the loop above
  if (shards_num > NUM_GPU) {
    printf("Iniciando o último merge\n");
    MultiMerge(data_manager, out_data_path, NUM_GPU - 1, shards_num - 2, -1,
               true);
  } else {
    printf("All merges completed in main loop - skipping final merge\n");
  }

  double total_merge_time = merge_timer.end();
  {
    std::lock_guard<std::mutex> lock(timing_mutex);
    total_Merge_time += total_merge_time;
  }

  // Write final merged results to disk
  printf("Writing final merged KNN graphs to disk...\n");
  data_manager.WriteAllGlobalKNNGraphsToFile(out_data_path);
  printf("Final merged graphs written to: %s\n", out_data_path.c_str());
  
  double total_ANNS_time_value = total_ANNS_timer.end();
  {
    std::lock_guard<std::mutex> lock(timing_mutex);
    total_ANNS_time += total_ANNS_time_value;
  }

  cerr << "Total time cost: " << total_ANNS_time_value << " seconds" << endl;

  // Print timing results to console
  std::cerr << "\n========================================" << std::endl;
  std::cerr << "TIMING RESULTS (No-HDD version):" << std::endl;
  std::cerr << "========================================" << std::endl;
  std::cerr << "Total HDD time: " << total_HDD_time << " seconds" << std::endl;
  std::cerr << "Total Building time: " << total_Building_time << " seconds" << std::endl;
  std::cerr << "Total Merge time: " << total_Merge_time << " seconds" << std::endl;
  std::cerr << "Total ANNS time: " << total_ANNS_time << " seconds" << std::endl;
  std::cerr << "========================================\n" << std::endl;

  // Save timing results to file
  std::ostringstream filename;
  filename << "../results/"
          << data_manager.GetVecsNum()
          << "_k" << NEIGHB_NUM_PER_LIST
          << "_s" << num_shards
          << "_NoHDD.txt";

  std::ofstream outfile(filename.str());
  if (!outfile.is_open()) {
      std::cerr << "Error: could not open file " << filename.str() << std::endl;
  } else {
      outfile << "Total HDD time: " << total_HDD_time << " seconds" << std::endl;
      outfile << "Total Building time: " << total_Building_time << " seconds" << std::endl;
      outfile << "Total Merge time: " << total_Merge_time << " seconds" << std::endl;
      outfile << "Total ANNS time: " << total_ANNS_time << " seconds" << std::endl;
      outfile.close();
      std::cerr << "Timing results saved to " << filename.str() << std::endl;
  }
  
  return;
}

