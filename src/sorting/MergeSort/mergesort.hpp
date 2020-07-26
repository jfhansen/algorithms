/************************************************************************
 * File: mergesort.cpp
 * Description: This file contains the definition of the Merge Sort algorithm
 * as well as possible helper functions. 
 * 
 * Author: jfhansen
 * Last modification: 25/07/2020
 ***********************************************************************/

#include <iostream>
#include <vector>
#include <iterator>
#include <algorithm>
#include <limits>
#include <random>

#ifndef MERGESORT_HPP
#define MERGESORT_HPP


template <class It>
void merge(It first, It mid, It last)
{
    size_t n1 = mid - first;
    size_t n2 = last - mid;

    typename It::value_type *left = new typename It::value_type[n1+1];
    typename It::value_type *right = new typename It::value_type[n2+1];

    std::copy(first, mid, left);
    std::copy(mid, last, right);
    left[n1] = std::numeric_limits<typename It::value_type>::max();
    right[n2] = std::numeric_limits<typename It::value_type>::max();

    It it;
    for (it = first; it < last; it++)
    {
        if (*left <= *right)
        {
            *it = *left;
            left++;
        }
        else
        {
            *it = *right;
            right++;
        }
    }
}

template <class It>
// Performs mergeSort on list of container type vector with generic stored type
// in range [first,last).
void mergeSort(It first, It last)
{
    if (first + 1< last)
    {
        // Find middle element
        It mid = first + (last-first)/2;
        // Perform mergeSort on first half of list.
        mergeSort(first, mid);
        // Perform mergeSort on second half of list.
        mergeSort(mid, last);
        // Merge both halves of list.
        merge(first, mid, last);
    }
}

template <class T>
void merge(T *first, T *mid, T *last)
{
    size_t n1 = mid - first;
    size_t n2 = last - mid;

    T *left, *right;
    left = new T[n1+1];
    right = new T[n2+1];

    std::copy(first, mid, left);
    std::copy(mid, last, right);
    *(left+n1) = std::numeric_limits<T>::max();
    *(right+n2) = std::numeric_limits<T>::max();

    T *it, *it_l, *it_r;
    it_l = left;
    it_r = right;
    for (it = first; it < last; it++)
    {
        if (*it_l <= *it_r && it_l != left+n1)
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

template <class T>
// Performs mergeSort on list of container type vector with generic stored type
// in range [first,last).
void mergeSort(T *first, T *last)
{
    if (first + 1 < last)
    {
        // Find middle element
        T *mid = first + (last-first)/2;
        // Perform mergeSort on first half of list.
        mergeSort(first, mid);
        // Perform mergeSort on second half of list.
        mergeSort(mid, last);
        // Merge both halves of list.
        merge(first, mid, last);
    }
}

#endif