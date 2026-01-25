// generate_true_knngraph.cpp
// Usage: ./generate_true_knngraph NUM_POINTS K NUM_SHARDS

#include <iostream>
#include <vector>
#include <random>
#include <fstream>
#include <algorithm>
#include <cassert>
#include <cstring>
#include <cmath>

#include "gpuknn/gen_large_knngraph.cuh"
#include "gpuknn/knncuda_tools.cuh"
#include "gpuknn/knnmerge.cuh"
#include "gpuknn/nndescent.cuh"
#include "tools/distfunc.hpp"
#include "tools/evaluate.hpp"
#include "tools/filetool.hpp"
#include "tools/knndata_manager.hpp"
#include "tools/timer.hpp"
#include "xmuknn.h"// For GetDistance

using namespace std;
using namespace xmuknn;

// Function to generate KNN graph with true distances
void GenerateTrueKNNGraph(const string& input_txt_path, int n, int k, int num_shards, const string& out_local_path, const string& out_global_path) {
  float* vectors;
  long int vecs_size, vecs_dim;

  // Read TXT vectors
  FileTool::ReadTxtVecs(input_txt_path, &vectors, &vecs_size, &vecs_dim);
  assert(vecs_size == n);

  // Save as .fvecs (optional)
  string out_fvecs = "../data/vectors.fvecs";
  FileTool::WriteBinaryVecs(out_fvecs, vectors, vecs_size, vecs_dim);

  // Build full distance matrix
  vector<vector<pair<float, int>>> knn_lists(n);
  for (int i = 0; i < n; ++i) {
    for (int j = 0; j < n; ++j) {
      if (i == j) continue;
      float dist = GetDistance(vectors + i * vecs_dim, vectors + j * vecs_dim, vecs_dim);
      knn_lists[i].emplace_back(dist, j);
    }
    // Shuffle with fixed seed before sorting if you want randomness in tie breaks
    std::mt19937 gen(42);
    std::shuffle(knn_lists[i].begin(), knn_lists[i].end(), gen);
    std::sort(knn_lists[i].begin(), knn_lists[i].end());
  }

  // Build NNDElement arrays
  vector<NNDElement> knn_local(n * k), knn_global(n * k);
  int shard_size = n / num_shards;
  for (int i = 0; i < n; ++i) {
    int local_id = i % shard_size;
    int shard_id = i / shard_size;
    int base_pos = shard_id * shard_size;

    for (int j = 0; j < k; ++j) {
      int global_label = knn_lists[i][j].second;
      float dist = knn_lists[i][j].first;

      // Verifica che la label sia valida
      if (global_label < 0 || global_label >= n) {
        cerr << "[ERROR] Invalid global label " << global_label << " for node " << i << endl;
        exit(1);
      }

      int local_label = global_label - base_pos;
      knn_global[i * k + j] = NNDElement(dist, global_label);
      knn_local[i * k + j] = NNDElement(dist, local_label);
    }
  }

  // Debug: stampa i primi 3 nodi
  for (int i = 0; i < std::min(n, 3); ++i) {
    cout << "Node " << i << " global neighbors: ";
    for (int j = 0; j < k; ++j) {
      auto& el = knn_global[i * k + j];
      cout << "(" << el.label() << ", " << el.distance() << ") ";
    }
    cout << endl;
  }

  // Save in binary format
  FileTool::WriteBinaryVecs(out_local_path, knn_local.data(), n, k);
  FileTool::WriteBinaryVecs(out_global_path, knn_global.data(), n, k);

  delete[] vectors;
}

int main(int argc, char* argv[]) {
  if (argc < 4) {
    cerr << "Usage: " << argv[0] << " <num_points> <k> <num_shards>" << endl;
    return -1;
  }

  int n = atoi(argv[1]);
  int k = atoi(argv[2]);
  int num_shards = atoi(argv[3]);

  string txt_input_path = "../data/artificial/SK_data.txt";
  string out_local_path = "../data/knn_local_saved.bin";
  string out_global_path = "../data/knn_global_saved.bin";

  GenerateTrueKNNGraph(txt_input_path, n, k, num_shards, out_local_path, out_global_path);
  cout << "KNN Graphs generated and saved." << endl;
  return 0;
}