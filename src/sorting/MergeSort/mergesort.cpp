/************************************************************************
 * File: mergesort.cpp
 * Description: This file contains the definition of the Merge Sort algorithm
 * as well as possible helper functions. 
 * 
 * Author: jfhansen
 * Last modification: 23/07/2020
 ***********************************************************************/

#include <iostream>
#include <vector>
#include <iterator>

template <class T>
// Performs mergeSort on list of container type vector with generic stored type
// in range [first,last).
void mergeSort(typename std::vector<T>::iterator &first, typename std::vector<T>::iterator &last)
{
    if (first < last)
    {
        // Find middle element
        auto mid = (first+last)/2;
        // Perform mergeSort on first half of list.
        mergeSort(first, mid);
        // Perform mergeSort on second half of list.
        mergeSort(mid+1, last);
        // Merge both halves of list.
        merge(first, mid, last);
    }
}

template <class T>
void merge(typename std::vector<T>::iterator &first, typename std::vector<T>::iterator &mid, 
    typename std::vector<T>::iterator &last)
{
    size_t n1 = mid - first;
    size_t n2 = last - mid;

    std::vector<T> left, right;
    left.reserve(n1);
    right.reserve(n2);

    left.insert(left.begin(), first, mid);
    right.insert(right.begin(), mid, last);

    typename std::vector<T>::iterator it, it_l, it_r;
    it_l = left.begin();
    it_r = right.begin();
    for (it = first; it < last; it++)
    {
        if (*it_l <= *it_r && it_l != left.end())
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

int main() {
    std::vector<double> list = {9,4,6,3,8,7,1,5,2};
    std::cout << "Hello, World!" << std::endl;
    mergeSort(list.begin(), list.end());
    return 0;
}