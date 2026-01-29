#include <assert.h>
#include <cuda_profiler_api.h>
//#include <nvToolsExt.h>
#include <string.h>
#include <unistd.h>

#include <algorithm>
#include <chrono>
#include <iostream>
#include <istream>
#include <vector>

#include "gpuknn/gen_large_knngraph.cuh"
#include "gpuknn/knncuda_tools.cuh"
#include "gpuknn/knnmerge.cuh"
#include "gpuknn/nndescent.cuh"
#include "tools/distfunc.hpp"
#include "tools/evaluate.hpp"
#include "tools/filetool.hpp"
#include "tools/knndata_manager.hpp"
#include "tools/timer.hpp"
#include "xmuknn.h"


using namespace std;
using namespace xmuknn;

#define K_neighbors 32  // Number of neighbors (must match NEIGHB_NUM_PER_LIST in nndescent.cuh)

void ToTxtResult(const string &kgraph_path, const string &out_path,
                 long int n) {
  NNDElement *result_graph;
  int num, dim;
  FileTool::ReadBinaryVecs(kgraph_path, &result_graph, &num, &dim);

  num = n;

  int *result_index_graph = new int[n * dim];

  for (int i = 0; i < num; i++) {
    for (int j = 0; j < dim; j++) {
      result_index_graph[i * dim + j] = result_graph[(i)*dim + j].label();
    }
  }
  FileTool::WriteTxtVecs(out_path, result_index_graph, num, dim);

  delete[] result_graph;
  delete[] result_index_graph;
}

void TestConstructLargeKNNGraph(int shards, int n) {
  SetupDbSize(n);
  string ref_path = "../../shared_data/vectors";

  string result_path = "../results/NNDescent-KNNG.kgraph";

  Timer timer;
  timer.start();

  int K = K_neighbors;

  GenLargeKNNGraph(ref_path, result_path, K, shards);

  printf("Time cost = %lf \n", timer.end());
  //nvtxMark("Write final result Phase");

  ToTxtResult(result_path, result_path + ".txt", n);
}

void TestBuildShardsOnly(int shards, long int n) {
  SetupDbSize(n);  // Setup DB size for GPU operations
  string ref_path = "../../shared_data/vectors";
  string result_path = "../results/NNDescent-KNNG.kgraph";
  int K = K_neighbors;

  Timer timer;
  timer.start();

  BuildShardsOnly(ref_path, result_path, K, shards);

  printf("BuildShardsOnly time cost = %lf \n", timer.end());
  
  // Convert to TXT for debugging
  ToTxtResult(result_path, result_path + ".txt", n);
}

void TestMergeShardsOnly(int shards, long int n) {
  SetupDbSize(n);
  string ref_path = "../../shared_data/vectors";
  string result_path = "../results/NNDescent-KNNG.kgraph";
  int K = K_neighbors;

  Timer timer;
  timer.start();

  MergeShardsOnly(ref_path, result_path, K, shards);

  printf("MergeShardsOnly time cost = %lf \n", timer.end());

  ToTxtResult(result_path, result_path + ".txt", n);
}

// main with added try-catch block for debugging

int main(int argc, char *argv[]) {
  try {
    /*
    In the main function we have two steps that must be done. The first one is
    that the .txt file that contains the data must be turned into a .fvecs file,
    to be possible to process it. To do this the variable PREPARE should be set
    to true; if we already have the .fvecs file, it must be set to false, to
    construct the kNNG.
    */

    bool PREPARE = true;
    int shards = 2;
    long int n = 10000;
    string mode = "full";  // default mode

    // ./main true|false
    if (argc >= 2) {
      if (strcmp(argv[1], "false") == 0)
        PREPARE = false;
      else if (strcmp(argv[1], "true") != 0) {
        cerr << "Invalid PREPARE value. Use 'true' or 'false'.\n";
        return -1;
      }
    }

    if (!PREPARE) {
      if (argc >= 4) {
        shards = atoi(argv[2]);
        n = atoi(argv[3]);
      }
      if (argc >= 5) {
        mode = argv[4];
      }

      printf("SHARDS SET TO %d.\n", shards);
      printf("N SET TO %ld.\n", n);
      printf("MODE SET TO %s.\n", mode.c_str());
    } else {
      printf("PREPARE ONLY: converting TXT to FVEC.\n");
    }

    if (PREPARE) {
      string base_path = "../../shared_data/artificial/SK_data.txt";
      float *vectors;
      long int vecs_size, vecs_dim;

      FileTool::ReadTxtVecs(base_path, &vectors, &vecs_size, &vecs_dim);
      printf("DIM = %ld\n", vecs_dim);

      // Arquivo em que será criado o .fvecs que será utilizado
      string out_path = "../../shared_data/vectors.fvecs";

      // Escrita em binário
      FileTool::WriteBinaryVecs(out_path, vectors, vecs_size, vecs_dim);
    } else {
      cudaProfilerStart();

      string ref_path = "../../shared_data/vectors";
      string result_path = "../results/NNDescent-KNNG.kgraph";
      int K = K_neighbors;

      if (mode == "full") {
        TestConstructLargeKNNGraph(shards,
                                   n);  // Combined build+merge in memory only
      } else if (mode == "build_only") {
        TestBuildShardsOnly(shards, n);  // Build shards and save to disk
      } else if (mode == "merge_only") {
        TestMergeShardsOnly(shards, n);  // Load from disk and merge
        
      } else {
        cerr << "Unknown mode: " << mode << endl;
        return -1;
      }

      cudaProfilerStop();
    }

    sleep(2);
    return 0;
  } catch (const std::exception &e) {
    std::cerr << "[std::exception] Caught: " << e.what() << std::endl;
  } catch (const std::string &msg) {
    std::cerr << "[string] Caught: " << msg << std::endl;
  } catch (const char *msg) {
    std::cerr << "[const char*] Caught: " << msg << std::endl;
  } catch (...) {
    std::cerr << "[unknown] An unknown exception occurred!" << std::endl;
  }

  return -1;  // return error code in case of exception
}
