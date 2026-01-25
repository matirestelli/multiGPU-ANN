#ifndef GEN_LARGE_KNNGRAPH_CUH
#define GEN_LARGE_KNNGRAPH_CUH
#include <string>
using namespace std;
void SetupDbSize(long int n);
void GenLargeKNNGraph(const string &vecs_data_path,
                      const string &out_data_path,
                      const int k, int num_shards);
                      
void BuildShardsOnly(const string &vecs_data_path,
                        const string &out_data_path,
                        const int k, int num_shards);
   
void MergeShardsOnly(const string &vecs_data_path,
                        const string &out_data_path,
                        const int k, int num_shards);
   
#endif