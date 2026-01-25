#ifndef XMUKNN_KNNMERGE_CUH
#define XMUKNN_KNNMERGE_CUH
#include <vector>

#include "../tools/nndescent_element.cuh"
namespace gpuknn {
void KNNMerge(NNDElement **knngraph_merged_dev_ptr,
              float *vectors_first_dev, const int vectors_first_size,
              NNDElement *knngraph_first_dev,
              float *vectors_second_dev, const int vectors_second_size,
              NNDElement *knngraph_second_dev, const bool free_sub_data = false);

void KNNMergeFromHost(NNDElement **knngraph_merged_dev_ptr,
                      const float *vectors_first, const int vectors_first_size,
                      const NNDElement *knngraph_first, const float *vectors_second,
                      const int vectors_second_size,
                      const NNDElement *knngraph_second, NNDElement *debug_host_graph, int *host_graph_old,
                      int *host_graph_new, int *host_size_old,
                      int *host_size_new, int* debug_parameters_shrink_graph, int *dbg_new_pre_sort_host, int *dbg_old_pre_sort_host, int *dbg_new_post_sort_host, int *dbg_old_post_sort_host);
                      
std::vector<std::vector<NNDElement>> KNNMerge(
    const float *vectors_first, const int vectors_first_size,
    const std::vector<std::vector<NNDElement>> &knngraph_first,
    const float *vectors_second, const int vectors_second_size,
    const std::vector<std::vector<NNDElement>> &knngraph_second);

void KNNJMerge(NNDElement **knngraph_merged_dev_ptr, float *vectors_first_dev,
               const int vectors_first_size, NNDElement *knngraph_first_dev,
               float *vectors_second_dev, const int vectors_second_size,
               NNDElement *knngraph_second_dev);
}  // namespace gpuknn
#endif
