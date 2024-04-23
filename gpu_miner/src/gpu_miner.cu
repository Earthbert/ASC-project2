#include <stdio.h>
#include <stdint.h>
#include "../include/utils.cuh"
#include <string.h>
#include <stdlib.h>
#include <inttypes.h>

__constant__ BYTE gpu_difficulty_5_zeros[SHA256_HASH_SIZE] = "0000099999999999999999999999999999999999999999999999999999999999";


__global__ void findNonce(BYTE *block_content, int current_length, BYTE *block_hash, bool *found, uint64_t *nonce) {
    int thread_id = blockIdx.x * blockDim.x + threadIdx.x;
    int total_threads = gridDim.x * blockDim.x;
    uint64_t l_start = thread_id * MAX_NONCE / total_threads;
    uint64_t l_end = (thread_id + 1) * MAX_NONCE / total_threads;

    char local_nonce_string[NONCE_SIZE];
    BYTE local_block_hash[SHA256_HASH_SIZE];
    BYTE local_block_content[BLOCK_SIZE];
    d_strcpy((char *)local_block_content, (const char *)block_content);

    for (uint64_t local_nonce = l_start; *found != true && local_nonce < l_end; local_nonce++) {
        intToString(local_nonce, local_nonce_string);
        d_strcpy((char *)local_block_content + current_length, local_nonce_string);
        apply_sha256(local_block_content, d_strlen((const char *)local_block_content), local_block_hash, 1);

        if (*found == false && compare_hashes(local_block_hash, gpu_difficulty_5_zeros) <= 0) {
            d_strcpy((char *)block_hash, (const char *)local_block_hash);
            *found = true;
            *nonce = local_nonce;
        }
    }
}

int cuda_get_sm_count() {
    cudaDeviceProp prop;
    cudaGetDeviceProperties(&prop, 0);
    return prop.multiProcessorCount;
}

int main(int argc, char **argv) {
    BYTE hashed_tx1[SHA256_HASH_SIZE], hashed_tx2[SHA256_HASH_SIZE], hashed_tx3[SHA256_HASH_SIZE], hashed_tx4[SHA256_HASH_SIZE],
        tx12[SHA256_HASH_SIZE * 2], tx34[SHA256_HASH_SIZE * 2], hashed_tx12[SHA256_HASH_SIZE], hashed_tx34[SHA256_HASH_SIZE],
        tx1234[SHA256_HASH_SIZE * 2], top_hash[SHA256_HASH_SIZE], block_content[BLOCK_SIZE];
    BYTE block_hash[SHA256_HASH_SIZE] = "0000000000000000000000000000000000000000000000000000000000000000"; // TODO: Update
    uint64_t nonce = 0;
    size_t current_length;

    // Top hash
    apply_sha256(tx1, strlen((const char *)tx1), hashed_tx1, 1);
    apply_sha256(tx2, strlen((const char *)tx2), hashed_tx2, 1);
    apply_sha256(tx3, strlen((const char *)tx3), hashed_tx3, 1);
    apply_sha256(tx4, strlen((const char *)tx4), hashed_tx4, 1);
    strcpy((char *)tx12, (const char *)hashed_tx1);
    strcat((char *)tx12, (const char *)hashed_tx2);
    apply_sha256(tx12, strlen((const char *)tx12), hashed_tx12, 1);
    strcpy((char *)tx34, (const char *)hashed_tx3);
    strcat((char *)tx34, (const char *)hashed_tx4);
    apply_sha256(tx34, strlen((const char *)tx34), hashed_tx34, 1);
    strcpy((char *)tx1234, (const char *)hashed_tx12);
    strcat((char *)tx1234, (const char *)hashed_tx34);
    apply_sha256(tx1234, strlen((const char *)tx34), top_hash, 1);

    // prev_block_hash + top_hash
    strcpy((char *)block_content, (const char *)prev_block_hash);
    strcat((char *)block_content, (const char *)top_hash);
    current_length = strlen((char *)block_content);

    cudaEvent_t start, stop;
    startTiming(&start, &stop);

    int block_size = 256;
    int nr_blocks = cuda_get_sm_count();

    BYTE *d_block_content, *d_block_hash;
    bool *d_found;
    uint64_t *d_nonce;

    cudaMalloc((void **)&d_block_content, BLOCK_SIZE);
    cudaMalloc((void **)&d_block_hash, SHA256_HASH_SIZE);
    cudaMalloc((void **)&d_found, sizeof(bool));
    cudaMalloc((void **)&d_nonce, sizeof(uint64_t));

    cudaMemcpy(d_block_content, block_content, BLOCK_SIZE, cudaMemcpyHostToDevice);
    {
        bool found = false;
        cudaMemcpy(d_found, &found, sizeof(bool), cudaMemcpyHostToDevice);
    }

    findNonce << <nr_blocks, block_size >> > (d_block_content, current_length, d_block_hash, d_found, d_nonce);

    float seconds = stopTiming(&start, &stop);

    cudaMemcpy(block_hash, d_block_hash, SHA256_HASH_SIZE, cudaMemcpyDeviceToHost);
    cudaMemcpy(&nonce, d_nonce, sizeof(uint64_t), cudaMemcpyDeviceToHost);

    printResult(block_hash, nonce, seconds);

    cudaFree(d_block_content);
    cudaFree(d_block_hash);
    cudaFree(d_found);
    cudaFree(d_nonce);

    return 0;
}
