/*******************************************************************
 * File: mergesort.cu
 * Description: This file contains the CUDA implementation of
 * the MergeSort algorithm.
 * Slower than pure CPU implementation. Algorithm implemented both
 * using indices and using iterators.
 * For N = 2^20, the GPU takes 1.65s to run kernel function with 
 * index implementation, and 2.53s with iterator implementation.
 *
 * Author: jfhansen
 * Last Modification: 28/07/2020
 ******************************************************************/

#include <iostream>
#include <cstddef>
#include <assert.h>
#include <random>
#include <algorithm>
#include <string>
#include <limits>

#include "mergesort.hpp"

const int BLOCKSIZE = 256;

// Declare Kernel function, iterator implementation
// Arguments: src[], dst[], N, width, stride
__global__ void cudaMergeSortIterator(float*, float*, unsigned, unsigned, unsigned);

// Declare device function, iterator implementation
// Arguments: src[], dst[], first, mid, end
__device__ void cudaMergeIterator(float*, float*, float*, float*, float*);

// Declare Kernel function, index implementation
// Arguments: src[], dst[], N, width, stride
__global__ void cudaMergeSortIndexing(float*, float*, unsigned, unsigned, unsigned);

// Declare device function, index implementation
// Arguments: src[], dst[], first, mid, end
__device__ void cudaMergeIndex(float*, float*, unsigned, unsigned, unsigned);

// Returns global thread index
__device__ int getGlobalIdx();

// Performs merge sort with CUDA Kernel
// Arguments: data[], N, threads, blocks
void merge_sort(float*, unsigned, dim3, dim3);

int main(int argc, char *argv[]) {
	std::cout << "Beginning of main." << std::endl;

	size_t N;
	// If CLI argument not passed N = 2^20
	if (argc < 2)
		N = 1 << 20;
	// else fetch N from CLI argument
	else
		N = 1 << (std::stoi(argv[1]));

	std::cout << "N = " << N << std::endl;
	
	//N = 8;
	// Instantiate list on host
	float *h_list, *h_list_cpy;
	h_list = new float[N];
	h_list_cpy = new float[N];

	// Generate values from uniform distribution
	std::mt19937 rng;
	rng.seed(std::random_device()());
	std::uniform_real_distribution<float> dist(-100,100);

	// Fill host list
	std::generate(h_list, h_list+N, [&] { return dist(rng); });
	std::cout << "Generated list." << std::endl;
	
	//for (int i = 0; i < N; i++)
	//	h_list[i] = N-i;

	cudaMemcpy(h_list_cpy, h_list, N*sizeof(float), cudaMemcpyHostToHost);

	// Compute number of threads per block and total number of blocks
	unsigned blockSize = BLOCKSIZE;
	unsigned numBlocks = N/2/blockSize;

	dim3 threads(blockSize);
	dim3 blocks(numBlocks);

	merge_sort(h_list, N, threads, blocks);
	std::cout << "Finished GPU Merge sort." << std::endl;

	// Sort list on host device for comparison
	mergeSort(h_list_cpy, h_list_cpy+N);
	std::cout << "Finished CPU mergesort." << std::endl;

	// Compare sorted lists
	for (size_t i = 0; i < N; i++)
	{
		if (h_list[i] != h_list_cpy[i])
		{
			std::cout << "Element " << i << " does not match, host = " << h_list_cpy[i]
			<< ", device = " << h_list[i] << "." << std::endl;
			break;
		}
	}

	// Check for errors
	cudaError_t err;
	while ( (err = cudaGetLastError()) != cudaSuccess )
		std::cout << "CUDA Error: " << cudaGetErrorString(err) << std::endl;
	return 0;
}

void merge_sort(float *data, unsigned N, dim3 threads, dim3 blocks)
{
	// Allocate device memory
	float *d_data, *d_swap;
	cudaMalloc(&d_data, N*sizeof(float));
	cudaMalloc(&d_swap, N*sizeof(float));

	// Copy data to device
	cudaMemcpy(d_data, data, N*sizeof(float), cudaMemcpyHostToDevice);
	std::cout << "Copied data to device." << std::endl;
	
	float *src, *dst;
	src = d_data;
	dst = d_swap;

	// Calculate number of threads used as stride
	unsigned stride = blocks.x * blocks.y * blocks.z
		* threads.x * threads.y * threads.z;
	
	for (size_t width=2; width<(2*N); width*=2)
	{
		// Call kernel
		cudaMergeSortIterator<<<blocks, threads>>>(src, dst, N, width, stride);
		
		// Swap source and destination pointers for next iteration
		src = (src == d_data) ? d_swap : d_data;
		dst = (dst == d_data) ? d_swap : d_data;
	}
	
	// Copy sorted data to host memory.
	cudaMemcpy(data, src, N*sizeof(float), cudaMemcpyDeviceToHost);
}

__device__ int getGlobalIdx()
{
	int blockId = blockIdx.x + blockIdx.y * gridDim.x 
		+ blockIdx.z * gridDim.x * gridDim.y;
	int threadId = blockId * blockDim.x * blockDim.y * blockDim.z
		+ (threadIdx.z * blockDim.x * blockDim.y)
		+ threadIdx.y * blockDim.x 
		+ threadIdx.x;
	return threadId;
}

__device__ void cudaMergeIndex(float *src, float *dst, unsigned first, unsigned mid, unsigned last)
{
	unsigned i = first;
	unsigned j = mid;
	for (unsigned k = first; k < last; k++)
	{
		if (j >= last || i < mid && src[i] < src[j])
		{
			dst[k] = src[i];
			i++;
		}
		else
		{
			dst[k] = src[j];
			j++;
		}
	}
}

__global__ void cudaMergeSortIndexing(float *src, float *dst, unsigned N, unsigned width, unsigned stride)
{
	// Get global thread index
	unsigned tid = getGlobalIdx();
	
	unsigned first, mid, last;
	// Get index of first element in list that must be merged
	first = tid*width;

	for (size_t pair = tid; pair < (N/width); pair += stride)
	{
		if (first > N)
			break;
		// Get indices of middle element and past last element in list
		mid = min(first + width/2, N);
		last = min(first + width, N);

		// Call merge function on device
		cudaMergeIndex(src, dst, first, mid, last);
		
		first += width*stride;
	}
}

// Device function that merges left and right sublists
__device__ void cudaMergeIterator(float *src, float *dst, float *first, float *mid, float *last)
{
	// Get position of 'first' and 'last' in src array
	size_t pos_first, pos_last;
	pos_first = first - src;
	pos_last = last - src;

	// Iterators for dst array, left list and right list
	float *it, *it_l, *it_r;
	it_l = first;
	it_r = mid;
	
	for (it = (dst+pos_first); it < (dst+pos_last); it++)
	{
		if (it_r >= last || it_l < mid && *it_l < *it_r)
		{
			*it = *it_l;
			it_l++;
		}
		else
		{
			*it = *it_r;
			it_r++;
		}
	}
}

__global__ void cudaMergeSortIterator(float *src, float *dst, unsigned N, unsigned width, unsigned stride)
{
	// Get global thread index
	unsigned tid = getGlobalIdx();
	
	float *first, *mid, *last;
	// Get pointer to first element in list that must be merged
	first = (src + tid*width);

	for (size_t pair = tid; pair < (N/width); pair += stride)
	{
		if ((size_t)(first-src) > N)
			break;
		mid = (first+width/2 > src+N) ? src+N : first+width/2;
		last = (first+width > src+N) ? src+N : first+width;
		
		// Call merge function on device
		cudaMergeIterator(src, dst, first, mid, last);
		
		first += width*stride;
	}
}

