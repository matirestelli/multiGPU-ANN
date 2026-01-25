#pragma once
#include <atomic>

extern double total_HDD_time;
extern double total_Building_time;
extern double total_Merge_time;
extern double total_ANNS_time;

// Mutex for thread safety
extern std::mutex timing_mutex;