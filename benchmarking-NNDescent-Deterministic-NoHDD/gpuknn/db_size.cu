// db_size.cu
#include "db_size.cuh"
__device__ __constant__ long int g_db_size;             // allocates 4 bytes on every GPU
namespace xmuknn {
    std::size_t h_db_size = 0;
}