#pragma once
#include <cstddef>
extern __device__  __constant__ long int g_db_size;      // device
namespace xmuknn {
    extern std::size_t h_db_size;       // host shadow (optional)
}