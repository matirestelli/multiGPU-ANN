#ifndef XMUKNN_KNNDATA_MANAGER_HPP
#define XMUKNN_KNNDATA_MANAGER_HPP
#include <memory>
#include <map>
#include <iostream>
#include <mutex>

#include "filetool.hpp"
#include "nndescent_element.cuh"
using namespace std;
class KNNDataManager {
 private:
  map<int, unique_ptr<float[]>> vecs_data_;
  map<int, unique_ptr<NNDElement[]>> knngs_data_local_;
  map<int, unique_ptr<NNDElement[]>> knngs_data_global_;

  mutex mtx_;
  string data_path_;
  int dim_;
  int shards_num_;
  int min_shards_num_;
  int max_vecs_num_per_shard_;
  int vecs_num_per_shard_;
  int vecs_num_last_shard_;
  int vecs_num_;
  int k_;
 public:
  KNNDataManager(const string &data_path,
                 //const int k = 64,
                 const int k = 8,
                 //const int min_shards_num = 3,
                 const int min_shards_num = 2,
                 const int max_vecs_num_per_shard = 8500000)
      : data_path_(data_path),
        min_shards_num_(min_shards_num),
        max_vecs_num_per_shard_(max_vecs_num_per_shard),
        k_(k) {
    
    cout << "Loading data from: " << GetVecsDataPath() << endl;
    
    int vecs_num = FileTool::GetFVecsNum(GetVecsDataPath());
    dim_ = FileTool::GetFVecsDim(GetVecsDataPath());
    vecs_num_ = vecs_num;
    
    if (vecs_num <= 0 || dim_ <= 0) {
      cerr << "ERROR: Invalid dataset - vecs_num=" << vecs_num << ", dim=" << dim_ << endl;
      exit(-1);
    }
    
    if (vecs_num < max_vecs_num_per_shard_ * min_shards_num) {
      shards_num_ = min_shards_num_;
    } else {
      shards_num_ = vecs_num / max_vecs_num_per_shard_ +
                    (vecs_num % max_vecs_num_per_shard != 0);
    }
    vecs_num_per_shard_ = vecs_num / shards_num_;
    vecs_num_last_shard_ = vecs_num - vecs_num_per_shard_ * (shards_num_ - 1);
    
    // Load all vector data into memory
    LoadAllVectorData();
    
    cout << "Successfully loaded " << vecs_num_ << " vectors of dimension " << dim_ 
         << " into " << shards_num_ << " shards" << endl;
  }
  
  void LoadAllVectorData() {
    cout << "Loading all vector data into memory..." << endl;
    
    for (int shard_id = 0; shard_id < shards_num_; shard_id++) {
      int begin_pos = GetBeginPosition(shard_id);
      int read_num = GetVecsNum(shard_id);
      
      float *vectors = nullptr;
      int dim = 0;
      
      cout << "Loading shard " << shard_id << ": position=" << begin_pos 
           << ", count=" << read_num << endl;
      
      FileTool::ReadBinaryVecs(GetVecsDataPath(), &vectors, &dim, begin_pos, read_num);
      
      if (vectors == nullptr) {
        cerr << "ERROR: Failed to load vectors for shard " << shard_id << endl;
        exit(-1);
      }
      
      if (dim != dim_) {
        cerr << "ERROR: Dimension mismatch in shard " << shard_id 
             << ": expected=" << dim_ << ", got=" << dim << endl;
        exit(-1);
      }
      
      vecs_data_[shard_id] = unique_ptr<float[]>(vectors);
      cout << "Successfully loaded shard " << shard_id << endl;
    }
    cout << "All vector data loaded successfully" << endl;
  }
  void CheckStatus() {
    cout << "Data path: " << data_path_ << endl;
    cout << "Total vecs num: " << vecs_num_ << endl;
    cout << "Shards num: " << shards_num_ << endl;
    cout << "Max vecs num. per shard: " << max_vecs_num_per_shard_ << endl;
    cout << "Vecs num. per shard: " << vecs_num_per_shard_ << endl;
    cout << "Vecs num. of last shard: " << vecs_num_last_shard_ << endl;
    cout << "Vector data loaded for " << vecs_data_.size() << " shards" << endl;
    cout << "Local KNN graphs stored for " << knngs_data_local_.size() << " shards" << endl;
    cout << "Global KNN graphs stored for " << knngs_data_global_.size() << " shards" << endl;
  }
  string GetVecsDataPath() {
    return data_path_ + ".fvecs";
  }
  string GetGraphDataPath() {
    return data_path_ + ".kgraph";
  }
  int GetK() {
    return k_;
  }
  int GetDim() {
    return dim_;
  }
  int GetBeginPosition(const int id) {
    if (id < shards_num_) {
      return id * vecs_num_per_shard_;
    } else {
      cerr << "GetBeginPosition ID: " << id << "exceed the max. num of shards."
           << endl;
      exit(-1);
    }
  }
  int GetVecsNum() {
    return vecs_num_;
  }
  int GetVecsNum(const int id) {
    if (id < shards_num_ - 1) {
      return vecs_num_per_shard_;
    } else if (id == shards_num_ - 1) {
      return vecs_num_last_shard_;
    } else {
      cerr << "GetVecsNum ID: " << id << "exceed the max. num of shards."
           << endl;
      exit(-1);
    }
  }
  int GetShardsNum() {
    return shards_num_;
  }
  const float *GetVectors(const int id) {
    if (id < 0 || id >= shards_num_) {
      cerr << "ERROR: GetVectors - Invalid shard ID " << id 
           << " (valid range: 0-" << (shards_num_-1) << ")" << endl;
      exit(-1);
    }
    
    lock_guard<mutex> local_lock(mtx_);
    auto it = vecs_data_.find(id);
    if (it == vecs_data_.end()) {
      cerr << "ERROR: GetVectors - No vector data found for shard " << id << endl;
      exit(-1);
    }
    
    if (it->second.get() == nullptr) {
      cerr << "ERROR: GetVectors - Null pointer for shard " << id << endl;
      exit(-1);
    }
    
    return it->second.get();
  }
  
  void SetLocalKNNGraph(const int id, NNDElement *knn_graph) {
    if (id < 0 || id >= shards_num_) {
      cerr << "ERROR: SetLocalKNNGraph - Invalid shard ID " << id 
           << " (valid range: 0-" << (shards_num_-1) << ")" << endl;
      exit(-1);
    }
    
    if (knn_graph == nullptr) {
      cerr << "ERROR: SetLocalKNNGraph - Null KNN graph for shard " << id << endl;
      exit(-1);
    }
    
    lock_guard<mutex> local_lock(mtx_);
    knngs_data_local_[id] = unique_ptr<NNDElement[]>(knn_graph);
    cout << "Stored local KNN graph for shard " << id << endl;
  }
  
  void SetGlobalKNNGraph(const int id, NNDElement *knn_graph) {
    if (id < 0 || id >= shards_num_) {
      cerr << "ERROR: SetGlobalKNNGraph - Invalid shard ID " << id 
           << " (valid range: 0-" << (shards_num_-1) << ")" << endl;
      exit(-1);
    }
    
    if (knn_graph == nullptr) {
      cerr << "ERROR: SetGlobalKNNGraph - Null KNN graph for shard " << id << endl;
      exit(-1);
    }
    
    lock_guard<mutex> local_lock(mtx_);
    knngs_data_global_[id] = unique_ptr<NNDElement[]>(knn_graph);
    cout << "Stored global KNN graph for shard " << id << endl;
  }
  
  const NNDElement *GetLocalKNNGraph(const int id) {
    if (id < 0 || id >= shards_num_) {
      cerr << "ERROR: GetLocalKNNGraph - Invalid shard ID " << id 
           << " (valid range: 0-" << (shards_num_-1) << ")" << endl;
      exit(-1);
    }
    
    lock_guard<mutex> local_lock(mtx_);
    auto it = knngs_data_local_.find(id);
    if (it == knngs_data_local_.end()) {
      cerr << "ERROR: GetLocalKNNGraph - No local KNN graph found for shard " << id << endl;
      exit(-1);
    }
    
    if (it->second.get() == nullptr) {
      cerr << "ERROR: GetLocalKNNGraph - Null pointer for shard " << id << endl;
      exit(-1);
    }
    
    return it->second.get();
  }
  
  const NNDElement *GetGlobalKNNGraph(const int id) {
    if (id < 0 || id >= shards_num_) {
      cerr << "ERROR: GetGlobalKNNGraph - Invalid shard ID " << id 
           << " (valid range: 0-" << (shards_num_-1) << ")" << endl;
      exit(-1);
    }
    
    lock_guard<mutex> local_lock(mtx_);
    auto it = knngs_data_global_.find(id);
    if (it == knngs_data_global_.end()) {
      cerr << "ERROR: GetGlobalKNNGraph - No global KNN graph found for shard " << id << endl;
      exit(-1);
    }
    
    if (it->second.get() == nullptr) {
      cerr << "ERROR: GetGlobalKNNGraph - Null pointer for shard " << id << endl;
      exit(-1);
    }
    
    return it->second.get();
  }
  
  NNDElement *GetMutableLocalKNNGraph(const int id) {
    if (id < 0 || id >= shards_num_) {
      cerr << "ERROR: GetMutableLocalKNNGraph - Invalid shard ID " << id 
           << " (valid range: 0-" << (shards_num_-1) << ")" << endl;
      exit(-1);
    }
    
    lock_guard<mutex> local_lock(mtx_);
    auto it = knngs_data_local_.find(id);
    if (it == knngs_data_local_.end()) {
      cerr << "ERROR: GetMutableLocalKNNGraph - No local KNN graph found for shard " << id << endl;
      exit(-1);
    }
    
    if (it->second.get() == nullptr) {
      cerr << "ERROR: GetMutableLocalKNNGraph - Null pointer for shard " << id << endl;
      exit(-1);
    }
    
    return it->second.get();
  }
  
  NNDElement *GetMutableGlobalKNNGraph(const int id) {
    if (id < 0 || id >= shards_num_) {
      cerr << "ERROR: GetMutableGlobalKNNGraph, Invalid shard ID " << id 
           << " (valid range: 0-" << (shards_num_-1) << ")" << endl;
      exit(-1);
    }
    
    lock_guard<mutex> local_lock(mtx_);
    auto it = knngs_data_global_.find(id);
    if (it == knngs_data_global_.end()) {
      cerr << "ERROR: GetMutableGlobalKNNGraph, No global KNN graph found for shard " << id << endl;
      exit(-1);
    }
    
    if (it->second.get() == nullptr) {
      cerr << "ERROR: GetMutableGlobalKNNGraph, Null pointer for shard " << id << endl;
      exit(-1);
    }
    
    return it->second.get();
  }
  
  void WriteAllGlobalKNNGraphsToFile(const string& output_path) {
    cout << "Writing all global KNN graphs to file: " << output_path << endl;
    
    // Create blank file first
    FileTool::CreateBlankKNNGraph(output_path, vecs_num_, k_);
    
    for (int shard_id = 0; shard_id < shards_num_; shard_id++) {
      auto it = knngs_data_global_.find(shard_id);
      if (it == knngs_data_global_.end()) {
        cerr << "ERROR: WriteAllGlobalKNNGraphsToFile - Missing global graph for shard " << shard_id << endl;
        exit(-1);
      }
      
      int begin_pos = GetBeginPosition(shard_id);
      int vecs_count = GetVecsNum(shard_id);
      
      cout << "Writing shard " << shard_id << " to position " << begin_pos 
           << " with " << vecs_count << " vectors" << endl;
      
      FileTool::WriteBinaryVecs(output_path, it->second.get(), begin_pos, vecs_count, k_);
    }
    
    cout << "Successfully wrote all global KNN graphs to file" << endl;
  }
  
  // Load pre-built KNN graphs from disk and prepare RAM as if they were just built
  // This allows the No-HDD version to skip building and go directly to merging
  // Requires both local and global graph files (saved by Cineca version)
  void LoadPreBuiltShardsFromDisk(const string& global_graph_path) {
    cout << "Loading pre-built KNN graphs from disk: " << global_graph_path << endl;
    
    // Construct local graph path from global graph path
    // The local graph is stored in the .kgraph file (data_path_ + ".kgraph")
    string local_graph_path = GetGraphDataPath();
    
    cout << "Local graph path: " << local_graph_path << endl;
    cout << "Global graph path: " << global_graph_path << endl;
    
    // Clear any existing KNN graph data
    knngs_data_local_.clear();
    knngs_data_global_.clear();
    
    for (int shard_id = 0; shard_id < shards_num_; shard_id++) {
      int begin_pos = GetBeginPosition(shard_id);
      int vecs_count = GetVecsNum(shard_id);
      
      cout << "Loading shard " << shard_id << " from position " << begin_pos 
           << " with " << vecs_count << " vectors" << endl;
      
      // Read the LOCAL KNN graph from disk (with local labels 0 to vecs_count-1)
      NNDElement *knn_graph_local = nullptr;
      int k_read_local = 0;
      FileTool::ReadBinaryVecs(local_graph_path, &knn_graph_local, &k_read_local, begin_pos, vecs_count);
      
      if (knn_graph_local == nullptr) {
        cerr << "ERROR: LoadPreBuiltShardsFromDisk - Failed to read local graph for shard " << shard_id << endl;
        exit(-1);
      }
      
      if (k_read_local != k_) {
        cerr << "ERROR: LoadPreBuiltShardsFromDisk - K mismatch for local graph shard " << shard_id 
             << ": expected=" << k_ << ", got=" << k_read_local << endl;
        delete[] knn_graph_local;
        exit(-1);
      }
      
      // Read the GLOBAL KNN graph from disk (with global database labels)
      NNDElement *knn_graph_global = nullptr;
      int k_read_global = 0;
      FileTool::ReadBinaryVecs(global_graph_path, &knn_graph_global, &k_read_global, begin_pos, vecs_count);
      
      if (knn_graph_global == nullptr) {
        cerr << "ERROR: LoadPreBuiltShardsFromDisk - Failed to read global graph for shard " << shard_id << endl;
        delete[] knn_graph_local;
        exit(-1);
      }
      
      if (k_read_global != k_) {
        cerr << "ERROR: LoadPreBuiltShardsFromDisk - K mismatch for global graph shard " << shard_id 
             << ": expected=" << k_ << ", got=" << k_read_global << endl;
        delete[] knn_graph_local;
        delete[] knn_graph_global;
        exit(-1);
      }
      
      // Store both local and global graphs in memory
      knngs_data_local_[shard_id] = unique_ptr<NNDElement[]>(knn_graph_local);
      knngs_data_global_[shard_id] = unique_ptr<NNDElement[]>(knn_graph_global);
      
      cout << "Successfully loaded and stored graphs for shard " << shard_id << endl;
    }
    
    cout << "All pre-built KNN graphs loaded successfully into RAM" << endl;
    cout << "Local KNN graphs stored for " << knngs_data_local_.size() << " shards" << endl;
    cout << "Global KNN graphs stored for " << knngs_data_global_.size() << " shards" << endl;
  }
};
#endif