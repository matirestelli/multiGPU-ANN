//non deterministic version with hdd
#include <limits.h>  // for PATH_MAX
#include <nvToolsExt.h>
#include <unistd.h>
#include <unistd.h>  // for getcwd
#include <iomanip>

#include <algorithm>
#include <cstdlib>  // for system
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

#define NUM_GPU 3


using namespace std;

void SetupDbSize(long int n)
{
  //set up in each gpu the size of the database
  //this is used in the knnmerge to check for correctness of the label
  printf("Setting up db_size = %ld\n", n);
    for (int dev = 0; dev < NUM_GPU; ++dev) {
        cudaSetDevice(dev);                             // select GPU
        cudaMemcpyToSymbol(g_db_size, &n, sizeof(long int)); // upload 4 B
        printf("GPU %d: db_size = %ld\n", dev, n);
    }
    xmuknn::h_db_size = static_cast<std::size_t>(n);    // (host copy)
}


void ReadGraph(const string &graph_path, NNDElement **knn_graph_ptr,
               const int read_pos, const int read_num) {
  NNDElement *&knn_graph = *knn_graph_ptr;
  int dim;
  FileTool::ReadBinaryVecs(graph_path, &knn_graph, &dim, read_pos, read_num);
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

  NNDElement *knn_graph;
  data_manager.ActivateShard(i);  // 0.12s

  float *vectors_dev;
  CUDA_ERROR_CHECK(cudaMalloc(&vectors_dev, (size_t)data_manager.GetVecsNum(i) *
                               data_manager.GetDim() * sizeof(float)));
  CUDA_ERROR_CHECK(cudaMemcpy(vectors_dev, data_manager.GetVectors(i),
             (size_t)data_manager.GetVecsNum(i) * data_manager.GetDim() *
                 sizeof(float),
             cudaMemcpyHostToDevice));
  cout << "Building No. " << i << endl;
  knn_timer.start();
  gpuknn::NNDescent(&knn_graph, vectors_dev, data_manager.GetVecsNum(i),
                    data_manager.GetDim(), 6, false);
  cout << "End building No." << i << " in " << knn_timer.end() << " seconds"
       << endl;

  // provo a stampare ogni grafo di ogni shards
  //  Dump del grafo locale puro per confronto determinismo
  {
    std::ofstream ofs("shard_" + std::to_string(i) + ".txt");
    for (int j = 0; j < data_manager.GetVecsNum(i); ++j) {
      ofs << data_manager.GetK();
      for (int k = 0; k < data_manager.GetK(); ++k) {
        ofs << " " << knn_graph[j * data_manager.GetK() + k].label();
      }
      ofs << "\n";
    }
    ofs.close();
    std::cout << "Shard " << i << " saved to file shard_" << i << ".txt\n";
  }

  thread th1([&data_manager, knn_graph, out_data_path, i, &mtx]() {
    mtx.lock();
    cerr << "Start writing thread............." << endl;
    Timer writer_timer;
    writer_timer.start();
    WriteGraph(data_manager.GetGraphDataPath(), knn_graph,
               data_manager.GetVecsNum(i), data_manager.GetK(),
               data_manager.GetBeginPosition(i));
    for (int j = 0; j < data_manager.GetVecsNum(i) * data_manager.GetK(); j++) {
      knn_graph[j].SetLabel(knn_graph[j].label() +
                            data_manager.GetBeginPosition(i));
    }
    WriteGraph(out_data_path, knn_graph, data_manager.GetVecsNum(i),
               data_manager.GetK(), data_manager.GetBeginPosition(i));
    data_manager.DiscardShard(i);
    delete[] knn_graph;
    cerr << "End writing thread " << i << " .............."
         << writer_timer.end() << endl;
    mtx.unlock();
  });

  // because error in nsight
  // th1.detach();
  th1.join();

  // At the end of BuildEachShard, dump a copy of the local KNN graph for comparison
  {
    int vecs_num = data_manager.GetVecsNum(i);
    int k = data_manager.GetK();
    NNDElement *local_graph = new NNDElement[vecs_num * k];
    FileTool::ReadBinaryVecs(data_manager.GetGraphDataPath(), &local_graph, &k, data_manager.GetBeginPosition(i), vecs_num);
    if (local_graph != nullptr) {
      std::ofstream ofs("shard_" + std::to_string(i) + "_local_dump.txt");
      if (ofs.is_open()) {
        for (int j = 0; j < vecs_num; ++j) {
          ofs << k;
          for (int n = 0; n < k; ++n) {
            ofs << " " << local_graph[j * k + n].label();
          }
          ofs << "\n";
        }
        ofs.close();
      }
      delete[] local_graph;
    }
  }
  cudaFree(vectors_dev);

  mtx.lock();
  mtx.unlock();
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

  // 0.45s
  NNDElement *result_first = 0, *result_second = 0;
  data_manager.ActivateShard(i);
  ReadGraph(out_data_path, &result_first, data_manager.GetBeginPosition(i),
            data_manager.GetVecsNum(i));
  printf("Shard %d foi read e ira comecar\n", i);

  for (int j = i + 1; j < shards_num; j++) {
    std::string label = "Merge GPU " + std::to_string(id_gpu) +
                        ": shard i=" + std::to_string(i) +
                        ": shard j=" + std::to_string(j);
    nvtxRangePush(label.c_str());

    NNDElement *result_knn_graph_dev;
    Timer timer;
    timer.start();
    data_manager.ActivateShard(j);

    int total_nodes = data_manager.GetVecsNum(i) + data_manager.GetVecsNum(j);
    NNDElement *debug_host_knngraph = new NNDElement[total_nodes * NEIGHB_NUM_PER_LIST];
    int* host_graph_old = new int[total_nodes * MERGE_SAMPLE_NUM * 2];
    int* host_graph_new = new int[total_nodes * MERGE_SAMPLE_NUM * 2];
    int* host_size_old = new int[total_nodes];
    int* host_size_new = new int[total_nodes];
    int* debug_parameters_shrink_graph = new int[total_nodes * 4];
    int* dbg_new_pre_sort_host = new int[total_nodes * MERGE_SAMPLE_NUM* 2];
    int* dbg_old_pre_sort_host = new int[total_nodes * MERGE_SAMPLE_NUM* 2];
    int* dbg_new_post_sort_host = new int[total_nodes * MERGE_SAMPLE_NUM* 2];
    int* dbg_old_post_sort_host = new int[total_nodes * MERGE_SAMPLE_NUM* 2];

    gpuknn::KNNMergeFromHost(
        &result_knn_graph_dev, data_manager.GetVectors(i),
        data_manager.GetVecsNum(i), data_manager.GetKNNGraph(i),
        data_manager.GetVectors(j), data_manager.GetVecsNum(j),
        data_manager.GetKNNGraph(j), debug_host_knngraph, host_graph_old,
        host_graph_new, host_size_old,
        host_size_new, debug_parameters_shrink_graph, dbg_new_pre_sort_host, dbg_old_pre_sort_host, dbg_new_post_sort_host, dbg_old_post_sort_host);
    cout << "Merge costs: J = " << j << " I = " << i << " " << timer.end()
         << endl;
        // stampa di ogni punto dei suoi 12 vicini + distanze
        /*
         std::ostringstream filename;
         filename << "../results/it0_reverse_graph_merged_knngraph_J" << j << "_I" << i << ".txt";
         std::ofstream out(filename.str());
         
         for (int node = 0; node < total_nodes; ++node) {
           out << "datapoint " << node << " -> ";
           for (int k = 0; k < NEIGHB_NUM_PER_LIST; ++k) {
             const auto& elem = debug_host_knngraph[node * NEIGHB_NUM_PER_LIST + k];
             out << std::setw(5) << elem.label()
                 << "(" << std::fixed << std::setprecision(2) << elem.distance() << ") ";
           }
           out << "\n";
         }
         
         out.close();
         delete[] debug_host_knngraph;
         */
        //stampa dei vicini vecchi e nuovi di ogni punto del database
        // DEBUG DUMPS COMMENTED OUT - keeping only shard dumps
        /*
            {
        std::ostringstream fname_before;
        fname_before << "../results/reversed_graph_before_shrink_J"
                    << j << "_I" << i << ".txt";
        std::ofstream out_before(fname_before.str());

        for (int node = 0; node < total_nodes; ++node) {
            int base = node * (MERGE_SAMPLE_NUM * 2);
            int k    = MERGE_SAMPLE_NUM;

            int old_fwd = debug_parameters_shrink_graph[2*total_nodes + node];
            int old_rev = debug_parameters_shrink_graph[3*total_nodes + node];
            int new_fwd = debug_parameters_shrink_graph[0*total_nodes + node];
            int new_rev = debug_parameters_shrink_graph[1*total_nodes + node];

            out_before << "datapoint " << node << '\n';

            out_before << "  old forward (" << old_fwd << "): ";
            for (int n = 0; n < old_fwd; ++n)
                out_before << host_graph_old[base + n] << ' ';

            out_before << "\n  old reverse (" << old_rev << "): ";
            for (int n = 0; n < old_rev; ++n)
                out_before << host_graph_old[base + k + n] << ' ';

            out_before << "\n  new forward (" << new_fwd << "): ";
            for (int n = 0; n < new_fwd; ++n)
                out_before << host_graph_new[base + n] << ' ';

            out_before << "\n  new reverse (" << new_rev << "): ";
            for (int n = 0; n < new_rev; ++n)
                out_before << host_graph_new[base + k + n] << ' ';

            out_before << "\n\n";
        }   // destructor closes out_before here
    }

    // ---------- second dump: inside-shrink debug ---------------------------
    {
        std::ostringstream fname_inside;
        fname_inside << "../results/mapped_inside_shrink_debug_neighbors_J"
                    << j << "_I" << i << ".txt";
        std::ofstream out_inside(fname_inside.str());

        const int P = MERGE_SAMPLE_NUM * 2;   // 24 slots

        auto dump_row = [&](const char *tag, const int *row) {
            out_inside << tag;
            for (int s = 0; s < P; ++s) out_inside << ' ' << row[s];
            out_inside << '\n';
        };

        for (int node = 0; node < total_nodes; ++node) {
            out_inside << "datapoint " << node
                      << "  (block " << node << ")\n";

            dump_row("  new_pre  :", dbg_new_pre_sort_host  + node*P);
            dump_row("  old_pre  :", dbg_old_pre_sort_host  + node*P);
            dump_row("  new_post :", dbg_new_post_sort_host + node*P);
            dump_row("  old_post :", dbg_old_post_sort_host + node*P);
        }   // destructor closes out_inside here
    }
        */
          delete[] host_size_old;
          delete[] host_size_new;
          delete[] debug_host_knngraph;

    mtx.lock();
    mtx.unlock();

    Timer update_graph_timer;
    update_graph_timer.start();

    ReadGraph(out_data_path, &result_second, data_manager.GetBeginPosition(j),
              data_manager.GetVecsNum(j));
    NNDElement *result_first_dev;
    CUDA_ERROR_CHECK(cudaMalloc(&result_first_dev, (size_t)data_manager.GetVecsNum(i) *
                                      data_manager.GetK() * sizeof(NNDElement)));
    CUDA_ERROR_CHECK(cudaMemcpy(result_first_dev, result_first,
               (size_t)data_manager.GetVecsNum(i) * data_manager.GetK() *
                   sizeof(NNDElement),
               cudaMemcpyHostToDevice));
    NNDElement *result_second_dev;
    CUDA_ERROR_CHECK(cudaMalloc(&result_second_dev, (size_t)data_manager.GetVecsNum(j) *
                                       data_manager.GetK() *
                                       sizeof(NNDElement)));
    CUDA_ERROR_CHECK(cudaMemcpy(result_second_dev, result_second,
               (size_t)data_manager.GetVecsNum(j) * data_manager.GetK() *
                   sizeof(NNDElement),
               cudaMemcpyHostToDevice));
    PreProcIDKernel<<<data_manager.GetVecsNum(i) + data_manager.GetVecsNum(j),
                      data_manager.GetK()>>>(
        result_knn_graph_dev, data_manager.GetVecsNum(i),
        data_manager.GetVecsNum(i) + data_manager.GetVecsNum(j),
        data_manager.GetK(), data_manager.GetBeginPosition(i),
        data_manager.GetBeginPosition(j));
    CUDA_ERROR_KERNEL_CHECK();
    CUDA_ERROR_CHECK(cudaDeviceSynchronize());   // <-- catches runtime faults
    auto status = cudaGetLastError();
    if (status != cudaSuccess) {
      cerr << "PreProcID failed" << endl;
      cerr << cudaGetErrorString(status) << endl;
      exit(-1);
    }
    UpdateKNNGraphKernel<<<data_manager.GetVecsNum(i), WARP_SIZE>>>(
        result_first_dev, result_knn_graph_dev, 0);
    CUDA_ERROR_KERNEL_CHECK();
    UpdateKNNGraphKernel<<<data_manager.GetVecsNum(j), WARP_SIZE>>>(
        result_second_dev, result_knn_graph_dev, data_manager.GetVecsNum(i));
    CUDA_ERROR_KERNEL_CHECK();
    CUDA_ERROR_CHECK(cudaDeviceSynchronize());   // <-- catches runtime faults
    CUDA_ERROR_CHECK(cudaMemcpy(result_first, result_first_dev,
               (size_t)data_manager.GetVecsNum(i) * data_manager.GetK() *
                   sizeof(NNDElement),
               cudaMemcpyDeviceToHost));
    CUDA_ERROR_CHECK(cudaMemcpy(result_second, result_second_dev,
               (size_t)data_manager.GetVecsNum(j) * data_manager.GetK() *
                   sizeof(NNDElement),
               cudaMemcpyDeviceToHost));
    status = cudaGetLastError();
    if (status != cudaSuccess) {
      cerr << cudaGetErrorString(status) << endl;
      exit(-1);
    }
    cudaFree(result_first_dev);
    cudaFree(result_second_dev);
    cudaFree(result_knn_graph_dev);
    cerr << "Update graph costs: " << update_graph_timer.end() << endl;
    int vecs_num = data_manager.GetVecsNum(j);
    int k = data_manager.GetK();
    int begin_pos = data_manager.GetBeginPosition(j);
    data_manager.DiscardShard(j);

    // Espera o atual ser discartado
    if (j == allow_next) {
      nvtxMark("Unlock mutex for next gpu to start");
      multi_merge.unlock();
    }

    thread write_th([&result_second_dev, &result_second, vecs_num, k, begin_pos,
                     j, &out_data_path, &mtx]() {
      // Timer timer;
      // timer.start();
      mtx.lock();
      Timer write_graph_timer;
      write_graph_timer.start();
      WriteGraph(out_data_path, result_second, vecs_num, k, begin_pos);
      delete[] result_second;
      mtx.unlock();
      cout << "Write KNN graph costs: " << write_graph_timer.end() << endl;
    });
    // write_th.detach();
    write_th.join();

    nvtxRangePop();
  }

  // Isso aqui não tem pq ser thread.
  int vecs_num = data_manager.GetVecsNum(i);
  int k = data_manager.GetK();
  int begin_pos = data_manager.GetBeginPosition(i);
  WriteGraph(out_data_path, result_first, vecs_num, k, begin_pos);
  data_manager.DiscardShard(i);

  delete[] result_first;

  float merge_time = merge_timer.end();
  cerr << "No. " << i << " mergers cost: " << merge_time << endl;
  cerr << "No. " << i << " avg. cost: " << merge_time / (shards_num - i - 1)
       << "\n\n"
       << endl;

  auto status = cudaGetLastError();
  if (status != cudaSuccess) {
    cerr << cudaGetErrorString(status) << endl;
    exit(-1);
  }
}

// separete the buoild and merge phase
// 1. Build each shard
void BuildShardsOnly(const string &vecs_data_path, const string &out_data_path,
                     const int k, int num_shards) {
  assert(k == NEIGHB_NUM_PER_LIST);
  KNNDataManager data_manager(vecs_data_path, k, num_shards, 10000000);
  assert(data_manager.GetDim() == VEC_DIM);
  data_manager.CheckStatus();

  FileTool::CreateBlankKNNGraph(data_manager.GetGraphDataPath(),
                                data_manager.GetVecsNum(), data_manager.GetK());
  FileTool::CreateBlankKNNGraph(out_data_path, data_manager.GetVecsNum(),
                                data_manager.GetK());

  int iters = num_shards / NUM_GPU;
  for (int s = 0; s < iters; s++) {
    vector<thread> threads;
    for (int i = 0; i < NUM_GPU; i++) {
      threads.emplace_back([&data_manager, out_data_path, s, i]() {
        BuildEachShard(data_manager, out_data_path, (NUM_GPU * s + i));
      });
    }
    for (auto &t : threads) t.join();
  }

  // saving the knng created for each shard in two different files: one with
  // local labels and one with global ones
  std::ifstream original_local(data_manager.GetGraphDataPath(),
                               std::ios::binary);
  std::ofstream saved_local("../data/knn_local_saved.bin", std::ios::binary);

  std::ifstream original_global(out_data_path, std::ios::binary);
  std::ofstream saved_global("../data/knn_global_saved.bin", std::ios::binary);

  if (original_local && saved_local && original_global && saved_global) {
    saved_local << original_local.rdbuf();
    saved_global << original_global.rdbuf();
    std::cout << "Saved full binary KNN graphs to backup files\n";
  } else {
    std::cerr << "ERROR: Could not open source or destination .bin files\n";
  }
}

// 2. Merge each shard
void MergeShardsOnly(const string &vecs_data_path, const string &out_data_path,
                     const int k, int num_shards) {
  assert(k == NEIGHB_NUM_PER_LIST);

  // Print current working directory
  char cwd[PATH_MAX];
  if (getcwd(cwd, sizeof(cwd)) != nullptr) {
    std::cout << "Current working directory: " << cwd << std::endl;
  } else {
    perror("getcwd() error");
  }

  // Overwrite files used by data_manager with previously saved graphs
  std::string cmd_local =
      "cp ../data/knn_local_saved.bin " + vecs_data_path + ".kgraph";
  std::string cmd_global = "cp ../data/knn_global_saved.bin " + out_data_path;
  int ret1 = system(cmd_local.c_str());
  int ret2 = system(cmd_global.c_str());
  if (ret1 != 0 || ret2 != 0) {
    std::cerr << "ERROR: Copy failed for one or both files.\n";
    exit(1);
  } else {
    std::cout << "Graph files copied to expected locations.\n";
  }

  KNNDataManager data_manager(vecs_data_path, k, num_shards, 10000000);
  assert(data_manager.GetDim() == VEC_DIM);
  data_manager.CheckStatus();

  int iters = num_shards / NUM_GPU;
  for (int s = 0; s < iters; s++) {
    vector<thread> threads;
    for (int i = 0; i < NUM_GPU; i++) {
      sleep(1);
      int allow_begin = NUM_GPU * s + i + NUM_GPU;
      if (allow_begin >= num_shards) allow_begin = num_shards - 1;
      threads.emplace_back([&data_manager, out_data_path, s, i, allow_begin]() {
        MultiMerge(data_manager, out_data_path, i, NUM_GPU * s + i,
                   allow_begin);
      });
      sleep(1);
    }
    for (auto &t : threads) t.join();
  }
  MultiMerge(data_manager, out_data_path, NUM_GPU - 1, num_shards - 2, -1,
             true);
}

// full version of both build and merge
void GenLargeKNNGraph(const string &vecs_data_path, const string &out_data_path,
                      const int k, int num_shards) {
  assert(k == NEIGHB_NUM_PER_LIST);
  KNNDataManager data_manager(vecs_data_path, k, num_shards, 10000000);
  assert(data_manager.GetDim() == VEC_DIM);
  data_manager.CheckStatus();

  // Blank knngraph costs: 0.07
  printf("-> %d\n", data_manager.GetVecsNum());
  FileTool::CreateBlankKNNGraph(data_manager.GetGraphDataPath(),
                                data_manager.GetVecsNum(), data_manager.GetK());
  FileTool::CreateBlankKNNGraph(out_data_path, data_manager.GetVecsNum(),
                                data_manager.GetK());
  printf("Iniciou?");
  Timer knn_timer;
  knn_timer.start();

  int shards_num = data_manager.GetShardsNum();

  int iters = num_shards / NUM_GPU;

  nvtxMark("Building Shards Phase");
  for (int s = 0; s < iters; s++) {
    vector<thread> threads;

    for (int i = 0; i < NUM_GPU; i++)
      threads.push_back(thread([&data_manager, out_data_path, s, i]() {
        BuildEachShard(data_manager, out_data_path, (NUM_GPU * s + i));
      }));

    for (auto &t : threads) t.join();
  }

  cerr << "Building shards costs: " << knn_timer.end() << endl;
  sleep(2);

  printf("\nIniciando o merge\n");

  nvtxMark("Start MultiGPU Merge Phase");

  for (int s = 0; s < iters; s++) {
    vector<thread> threads;

    for (int i = 0; i < NUM_GPU; i++) {
      sleep(1);
      int allow_begin = NUM_GPU * s + i + NUM_GPU;

      if (allow_begin >= num_shards) allow_begin = num_shards - 1;

      threads.push_back(
          thread([&data_manager, out_data_path, s, i, allow_begin]() {
            int gpu_id = i % NUM_GPU;
            std::string range_name =
                "Merge Phase | gpuID: " + std::to_string(gpu_id) +
                " | shard: " + std::to_string(NUM_GPU * s + i);
            nvtxMark(range_name.c_str());

            MultiMerge(data_manager, out_data_path, i, NUM_GPU * s + i,
                       allow_begin);
          }));
      sleep(1);
    }
    for (auto &t : threads) t.join();

    threads.clear();
  }

  printf("Iniciando o último merge\n");
  MultiMerge(data_manager, out_data_path, NUM_GPU - 1, shards_num - 2, -1,
             true);

  // data_manager.CheckStatus();

  return;
}