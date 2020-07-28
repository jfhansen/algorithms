/************************************************************************
 * File: benchmark.cpp
 * Description: This file contains the benchmarking of the MergeSort
 * algorithm. 
 * 
 * Author: jfhansen
 * Last modification: 25/07/2020
 ***********************************************************************/

#include <benchmark/benchmark.h>
#include <iostream>
#include <cstddef>
#include <algorithm>
#include <random>
#include <thread>
#include <vector>
#include <assert.h>
#include <string>

#include "mergesort.hpp"

static void BM_merge_sort(benchmark::State &s)
{
    // Fetch length of list
    size_t N = 1 << s.range(0);

    // Instantiate list
    double *list = new double[N];

    // Generate random values from uniform distribution
    std::mt19937 rng;
    std::uniform_real_distribution<double> dist(-100,100);

    // Fill list
    std::generate(list, list+N, [&] { return dist(rng); } );

    // Perform main loop of benchmark
    for (auto _ : s)
        mergeSort(list, list+N);

    delete [] list;
}

static void BM_merge_sort_vec(benchmark::State &s)
{
    // Fetch length of list
    size_t N = 1 << s.range(0);

    // Instantiate list
    std::vector<double> *list = new std::vector<double>;
    list->resize(N);

    // Generate random values from uniform distribution
    std::mt19937 rng;
    std::uniform_real_distribution<double> dist(-100,100);

    // Fill list
    std::generate(list->begin(), list->end(), [&] { return dist(rng); } );

    // Perform main loop of benchmark
    for (auto _ : s)
        mergeSort(list->begin(), list->end());

}

BENCHMARK(BM_merge_sort)->DenseRange(10,13)->Unit(benchmark::kMillisecond);
BENCHMARK(BM_merge_sort_vec)->DenseRange(10,13)->Unit(benchmark::kMillisecond);

BENCHMARK_MAIN();