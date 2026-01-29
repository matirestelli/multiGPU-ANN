#include <assert.h>
#include <unistd.h>

#include <string.h>


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


//#include <nvToolsExt.h>
#include <cuda_profiler_api.h>

using namespace std;
using namespace xmuknn;





void ToTxtResult(const string &kgraph_path, const string &out_path, long int n) {
  NNDElement *result_graph;
  int num, dim;
  FileTool::ReadBinaryVecs(kgraph_path, &result_graph, &num, &dim);

  num = n;

  int *result_index_graph = new int[n * dim];


  for (int i = 0; i < num; i++) {
    for (int j = 0; j < dim; j++) {
      result_index_graph[i * dim + j] = result_graph[(i) * dim + j].label();
    }
  }
  FileTool::WriteTxtVecs(out_path, result_index_graph, num, dim);

  delete[] result_graph;
  delete[] result_index_graph;
}


void TestConstructLargeKNNGraph(int shards,int n) {


  string ref_path = "../../shared_data/vectors";

  string result_path = "../results/NNDescent-KNNG.kgraph";


  Timer timer;
  timer.start();

  int K = 32;  // Must match NEIGHB_NUM_PER_LIST in nndescent.cuh
  
  GenLargeKNNGraph(ref_path, result_path, K,shards);


  printf("Time cost = %lf \n",timer.end());
  //nvtxMark("Write final result Phase");

  ToTxtResult(result_path,result_path + ".txt",n);





}


//main with added try-catch block for debugging 

int main(int argc, char *argv[]) {
  try {
    /*
    In the main function we have two steps that must be done. The first one is that the .txt file that contains the data must be turned into a .fvecs file,
    to be possible to process it. To do this the variable PREPARE should be set to true; if we already have the .fvecs file, it must be set to false, to construct 
    the kNNG.
    */
   

    bool PREPARE = true;
    int shards = 30;
    long int n = 1000000;

    // ./main true|false
    if (argc == 2) {
      printf("PREPARE SET TO %s. Running will be initiated.\n", argv[1]);
      if (strcmp(argv[1], "false") == 0)
        PREPARE = false;
    }
    // ./main true|false SHARDS N
    else if (argc == 4) {
      printf("PREPARE SET TO %s.\n", argv[1]);

      if (strcmp(argv[1], "false") == 0)
        PREPARE = false;

      shards = atoi(argv[2]);
      printf("SHARDS SET TO %d.\n", shards);

      n = atoi(argv[3]);
      printf("N SET TO %ld.\n", n);
    }
    else {
      printf("Standard settings will be used (PREPARE=true, SHARDS=30, N=1000000).\n");
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
      cudaProfilerStart();  // <-- Start profiling
      TestConstructLargeKNNGraph(shards, n);
      cudaProfilerStop();   // <-- Stop profiling

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

