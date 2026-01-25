// random_offset_tracker.h
#pragma once
#include <atomic>

// This tells other files that this variable exists somewhere
extern std::atomic<unsigned long long> g_rng_call_counter;