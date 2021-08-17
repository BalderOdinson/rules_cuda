#include <cstdio>
#include "sum.cuh"

__global__ void cuda_hello(){
    printf("Hello World from GPU %d!\n", sum(2, 3));
}

void hello_world_gpu() {
    cuda_hello<<<1,1>>>();
    cudaDeviceSynchronize();
}
