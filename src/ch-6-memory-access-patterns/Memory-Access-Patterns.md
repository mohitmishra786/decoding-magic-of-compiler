# Chapter 6: Memory Access Patterns

Understanding and optimizing memory access patterns is crucial for writing high-performance code. This chapter explores how different memory access patterns affect performance and how to write code that maximizes cache utilization.

## Memory Hierarchy and Access Patterns

Modern computer systems have a complex memory hierarchy:

1. **Registers** (fastest, smallest)
2. **L1 Cache** (~1ns, 32-64KB)
3. **L2 Cache** (~10ns, 256KB-1MB)
4. **L3 Cache** (~30ns, 2-32MB)
5. **Main Memory** (~100ns, GBs)
6. **Storage** (slowest, largest)

### Cache Line Basics

A cache line is typically 64 bytes on modern processors. When you access a memory location, the entire cache line containing that location is loaded into the cache.

```c
// Example of cache line access
struct Data {
    int values[16];  // 64 bytes = 1 cache line
};

void process_data(struct Data* data, int n) {
    for (int i = 0; i < n; i++) {
        data[i].values[0] *= 2;  // Accesses entire cache line
    }
}
```

## Common Memory Access Patterns

### Sequential Access

```c
// Good: Sequential access pattern
void sum_array(int* arr, int n) {
    int sum = 0;
    for (int i = 0; i < n; i++) {
        sum += arr[i];  // Sequential access
    }
}

// Bad: Random access pattern
void sum_random(int* arr, int* indices, int n) {
    int sum = 0;
    for (int i = 0; i < n; i++) {
        sum += arr[indices[i]];  // Random access
    }
}
```

### Strided Access

```c
// Good: Unit stride
void process_matrix_row_major(int matrix[][N], int n) {
    for (int i = 0; i < n; i++) {
        for (int j = 0; j < n; j++) {
            matrix[i][j] *= 2;  // Unit stride
        }
    }
}

// Bad: Large stride
void process_matrix_col_major(int matrix[][N], int n) {
    for (int j = 0; j < n; j++) {
        for (int i = 0; i < n; i++) {
            matrix[i][j] *= 2;  // Large stride
        }
    }
}
```

### Complete Working Example: Matrix Transposition

```c
#include <stdio.h>
#include <stdlib.h>
#include <time.h>

#define N 1024
#define BLOCK_SIZE 32

// Naive matrix transposition
void transpose_naive(int A[N][N], int B[N][N]) {
    for (int i = 0; i < N; i++) {
        for (int j = 0; j < N; j++) {
            B[j][i] = A[i][j];
        }
    }
}

// Cache-friendly matrix transposition
void transpose_blocked(int A[N][N], int B[N][N]) {
    for (int i = 0; i < N; i += BLOCK_SIZE) {
        for (int j = 0; j < N; j += BLOCK_SIZE) {
            // Process block
            for (int ii = i; ii < i + BLOCK_SIZE; ii++) {
                for (int jj = j; jj < j + BLOCK_SIZE; jj++) {
                    B[jj][ii] = A[ii][jj];
                }
            }
        }
    }
}

// SIMD-optimized matrix transposition
void transpose_simd(int A[N][N], int B[N][N]) {
    for (int i = 0; i < N; i += 8) {
        for (int j = 0; j < N; j += 8) {
            // Process 8x8 block using SIMD
            for (int ii = i; ii < i + 8; ii++) {
                for (int jj = j; jj < j + 8; jj++) {
                    B[jj][ii] = A[ii][jj];
                }
            }
        }
    }
}

int main() {
    int (*A)[N] = malloc(N * N * sizeof(int));
    int (*B)[N] = malloc(N * N * sizeof(int));
    
    // Initialize matrix
    for (int i = 0; i < N; i++) {
        for (int j = 0; j < N; j++) {
            A[i][j] = i * N + j;
        }
    }
    
    // Time naive transposition
    clock_t start = clock();
    transpose_naive(A, B);
    clock_t end = clock();
    double naive_time = ((double)(end - start)) / CLOCKS_PER_SEC;
    
    // Time blocked transposition
    start = clock();
    transpose_blocked(A, B);
    end = clock();
    double blocked_time = ((double)(end - start)) / CLOCKS_PER_SEC;
    
    // Time SIMD transposition
    start = clock();
    transpose_simd(A, B);
    end = clock();
    double simd_time = ((double)(end - start)) / CLOCKS_PER_SEC;
    
    printf("Naive transposition: %f seconds\n", naive_time);
    printf("Blocked transposition: %f seconds\n", blocked_time);
    printf("SIMD transposition: %f seconds\n", simd_time);
    
    free(A);
    free(B);
    return 0;
}
```

## Cache-Friendly Data Structures

### Array of Structures vs Structure of Arrays

```c
// Array of Structures (AoS)
struct Particle {
    float x, y, z;
    float vx, vy, vz;
    float mass;
};

// Structure of Arrays (SoA)
struct Particles {
    float* x, *y, *z;
    float* vx, *vy, *vz;
    float* mass;
};

// Complete Working Example: Particle Simulation
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <immintrin.h>

#define N 1000000

// AoS implementation
void update_particles_aos(struct Particle* particles, int n) {
    for (int i = 0; i < n; i++) {
        particles[i].x += particles[i].vx;
        particles[i].y += particles[i].vy;
        particles[i].z += particles[i].vz;
    }
}

// SoA implementation
void update_particles_soa(struct Particles* particles, int n) {
    for (int i = 0; i < n; i += 8) {
        __m256 x = _mm256_loadu_ps(&particles->x[i]);
        __m256 y = _mm256_loadu_ps(&particles->y[i]);
        __m256 z = _mm256_loadu_ps(&particles->z[i]);
        __m256 vx = _mm256_loadu_ps(&particles->vx[i]);
        __m256 vy = _mm256_loadu_ps(&particles->vy[i]);
        __m256 vz = _mm256_loadu_ps(&particles->vz[i]);
        
        x = _mm256_add_ps(x, vx);
        y = _mm256_add_ps(y, vy);
        z = _mm256_add_ps(z, vz);
        
        _mm256_storeu_ps(&particles->x[i], x);
        _mm256_storeu_ps(&particles->y[i], y);
        _mm256_storeu_ps(&particles->z[i], z);
    }
}

int main() {
    // Allocate and initialize AoS
    struct Particle* particles_aos = malloc(N * sizeof(struct Particle));
    for (int i = 0; i < N; i++) {
        particles_aos[i].x = (float)rand() / RAND_MAX;
        particles_aos[i].y = (float)rand() / RAND_MAX;
        particles_aos[i].z = (float)rand() / RAND_MAX;
        particles_aos[i].vx = (float)rand() / RAND_MAX;
        particles_aos[i].vy = (float)rand() / RAND_MAX;
        particles_aos[i].vz = (float)rand() / RAND_MAX;
        particles_aos[i].mass = 1.0f;
    }
    
    // Allocate and initialize SoA
    struct Particles particles_soa;
    particles_soa.x = malloc(N * sizeof(float));
    particles_soa.y = malloc(N * sizeof(float));
    particles_soa.z = malloc(N * sizeof(float));
    particles_soa.vx = malloc(N * sizeof(float));
    particles_soa.vy = malloc(N * sizeof(float));
    particles_soa.vz = malloc(N * sizeof(float));
    particles_soa.mass = malloc(N * sizeof(float));
    
    for (int i = 0; i < N; i++) {
        particles_soa.x[i] = (float)rand() / RAND_MAX;
        particles_soa.y[i] = (float)rand() / RAND_MAX;
        particles_soa.z[i] = (float)rand() / RAND_MAX;
        particles_soa.vx[i] = (float)rand() / RAND_MAX;
        particles_soa.vy[i] = (float)rand() / RAND_MAX;
        particles_soa.vz[i] = (float)rand() / RAND_MAX;
        particles_soa.mass[i] = 1.0f;
    }
    
    // Time AoS update
    clock_t start = clock();
    update_particles_aos(particles_aos, N);
    clock_t end = clock();
    double aos_time = ((double)(end - start)) / CLOCKS_PER_SEC;
    
    // Time SoA update
    start = clock();
    update_particles_soa(&particles_soa, N);
    end = clock();
    double soa_time = ((double)(end - start)) / CLOCKS_PER_SEC;
    
    printf("AoS update: %f seconds\n", aos_time);
    printf("SoA update: %f seconds\n", soa_time);
    
    // Clean up
    free(particles_aos);
    free(particles_soa.x);
    free(particles_soa.y);
    free(particles_soa.z);
    free(particles_soa.vx);
    free(particles_soa.vy);
    free(particles_soa.vz);
    free(particles_soa.mass);
    
    return 0;
}
```

## Prefetching and Cache Control

### Hardware Prefetching

Modern processors have hardware prefetchers that detect sequential access patterns and prefetch data into the cache.

```c
// Good: Sequential access with hardware prefetching
void process_array(int* arr, int n) {
    for (int i = 0; i < n; i++) {
        arr[i] *= 2;
    }
}

// Bad: Random access defeats prefetching
void process_random(int* arr, int* indices, int n) {
    for (int i = 0; i < n; i++) {
        arr[indices[i]] *= 2;
    }
}
```

### Software Prefetching

```c
#include <xmmintrin.h>

void process_array_with_prefetch(int* arr, int n) {
    for (int i = 0; i < n; i += 16) {
        // Prefetch next cache line
        _mm_prefetch((char*)&arr[i + 16], _MM_HINT_T0);
        
        // Process current cache line
        for (int j = 0; j < 16; j++) {
            arr[i + j] *= 2;
        }
    }
}
```

## Cache Alignment and Padding

### Structure Padding

```c
// Unpadded structure (may cause cache conflicts)
struct Unpadded {
    char a;
    int b;
    char c;
    double d;
};

// Padded structure (cache-friendly)
struct Padded {
    char a;
    char padding1[3];  // Align b to 4 bytes
    int b;
    char c;
    char padding2[7];  // Align d to 8 bytes
    double d;
};
```

### Complete Working Example: Cache Alignment

```c
#include <stdio.h>
#include <stdlib.h>
#include <time.h>

#define N 1000000

// Unaligned access
void process_unaligned(char* data, int n) {
    for (int i = 0; i < n; i++) {
        data[i] *= 2;
    }
}

// Aligned access
void process_aligned(char* data, int n) {
    // Align to cache line boundary
    int offset = ((uintptr_t)data) % 64;
    if (offset != 0) {
        data += (64 - offset);
        n -= (64 - offset);
    }
    
    for (int i = 0; i < n; i++) {
        data[i] *= 2;
    }
}

int main() {
    char* data = malloc(N + 64);  // Extra space for alignment
    
    // Initialize data
    for (int i = 0; i < N + 64; i++) {
        data[i] = rand() % 256;
    }
    
    // Time unaligned access
    clock_t start = clock();
    process_unaligned(data, N);
    clock_t end = clock();
    double unaligned_time = ((double)(end - start)) / CLOCKS_PER_SEC;
    
    // Time aligned access
    start = clock();
    process_aligned(data, N);
    end = clock();
    double aligned_time = ((double)(end - start)) / CLOCKS_PER_SEC;
    
    printf("Unaligned access: %f seconds\n", unaligned_time);
    printf("Aligned access: %f seconds\n", aligned_time);
    
    free(data);
    return 0;
}
```

## Summary

Optimizing memory access patterns is crucial for performance. Key points to remember:

1. **Understand the Memory Hierarchy**
   - Cache sizes and latencies
   - Cache line size
   - Memory bandwidth

2. **Write Cache-Friendly Code**
   - Use sequential access patterns
   - Minimize stride sizes
   - Consider data structure layout
   - Align data properly

3. **Leverage Hardware Features**
   - Hardware prefetching
   - Cache line utilization
   - SIMD instructions

4. **Profile and Optimize**
   - Use performance counters
   - Measure cache misses
   - Consider different data layouts
   - Balance between memory and compute

Remember that memory access patterns can have a significant impact on performance, often more than algorithmic complexity. Always profile your code to identify memory bottlenecks and optimize accordingly. 