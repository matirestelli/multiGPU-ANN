// random_offset_tracker.cpp
#include <atomic>

// This global atomic counter is used by all RNG calls to set unique offsets
std::atomic<unsigned long long> g_rng_call_counter(0);