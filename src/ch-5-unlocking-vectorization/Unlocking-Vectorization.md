# Chapter 5: Unlocking Vectorization

Vectorization is one of the most powerful optimization techniques available in modern compilers. By processing multiple data elements simultaneously using SIMD (Single Instruction, Multiple Data) instructions, we can achieve significant performance improvements. This chapter explores how compilers vectorize code and how we can write code to maximize vectorization opportunities.

## Understanding Vectorization

Vectorization transforms scalar operations into vector operations, allowing multiple data elements to be processed in parallel. Modern processors support various SIMD instruction sets:

- SSE (Streaming SIMD Extensions)
- AVX (Advanced Vector Extensions)
- AVX2
- AVX-512

### Basic Vectorization Example

```c
// Original scalar code
void add_arrays(float* a, float* b, float* c, int n) {
    for (int i = 0; i < n; i++) {
        c[i] = a[i] + b[i];
    }
}

// Compiler-generated vectorized code (AVX2)
add_arrays:
    mov    r8d, edi
    and    r8d, -8
    je     .L4
    xor    eax, eax
.L3:
    vmovups ymm0, YMMWORD PTR [rsi+rax*4]
    vaddps  ymm0, ymm0, YMMWORD PTR [rdx+rax*4]
    vmovups YMMWORD PTR [rcx+rax*4], ymm0
    add    rax, 8
    cmp    r8d, eax
    ja     .L3
```

The compiler uses AVX2 instructions to process 8 floats simultaneously.

### Complete Working Example: Image Processing

Let's examine a real-world vectorization example:

```c
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <immintrin.h>

#define WIDTH 1920
#define HEIGHT 1080
#define CHANNELS 3

// Structure to hold image data
typedef struct {
    unsigned char* data;
    int width;
    int height;
    int channels;
} Image;

// Create a new image
Image* create_image(int width, int height, int channels) {
    Image* img = malloc(sizeof(Image));
    img->width = width;
    img->height = height;
    img->channels = channels;
    img->data = malloc(width * height * channels * sizeof(unsigned char));
    return img;
}

// Free image memory
void free_image(Image* img) {
    free(img->data);
    free(img);
}

// Convert RGB to grayscale using vectorization
void rgb_to_grayscale_vectorized(Image* src, Image* dst) {
    const __m256i mask = _mm256_set1_epi32(0x0000FF00);
    const __m256 scale = _mm256_set1_ps(0.299f);
    const __m256 scale2 = _mm256_set1_ps(0.587f);
    const __m256 scale3 = _mm256_set1_ps(0.114f);
    
    for (int y = 0; y < src->height; y++) {
        for (int x = 0; x < src->width; x += 8) {
            // Load 8 RGB pixels
            __m256i rgb = _mm256_loadu_si256((__m256i*)&src->data[y * src->width * 3 + x * 3]);
            
            // Extract R, G, B components
            __m256 r = _mm256_cvtepi32_ps(_mm256_and_si256(rgb, _mm256_set1_epi32(0xFF)));
            __m256 g = _mm256_cvtepi32_ps(_mm256_and_si256(_mm256_srli_epi32(rgb, 8), _mm256_set1_epi32(0xFF)));
            __m256 b = _mm256_cvtepi32_ps(_mm256_and_si256(_mm256_srli_epi32(rgb, 16), _mm256_set1_epi32(0xFF)));
            
            // Calculate grayscale
            __m256 gray = _mm256_fmadd_ps(r, scale,
                         _mm256_fmadd_ps(g, scale2,
                         _mm256_mul_ps(b, scale3)));
            
            // Convert back to integer and store
            __m256i result = _mm256_cvtps_epi32(gray);
            _mm256_storeu_si256((__m256i*)&dst->data[y * dst->width + x], result);
        }
    }
}

// Convert RGB to grayscale (scalar version for comparison)
void rgb_to_grayscale_scalar(Image* src, Image* dst) {
    for (int y = 0; y < src->height; y++) {
        for (int x = 0; x < src->width; x++) {
            unsigned char r = src->data[y * src->width * 3 + x * 3];
            unsigned char g = src->data[y * src->width * 3 + x * 3 + 1];
            unsigned char b = src->data[y * src->width * 3 + x * 3 + 2];
            dst->data[y * dst->width + x] = (unsigned char)(0.299f * r + 0.587f * g + 0.114f * b);
        }
    }
}

int main() {
    // Create source and destination images
    Image* src = create_image(WIDTH, HEIGHT, CHANNELS);
    Image* dst = create_image(WIDTH, HEIGHT, 1);
    
    // Initialize source image with random data
    for (int i = 0; i < WIDTH * HEIGHT * CHANNELS; i++) {
        src->data[i] = rand() % 256;
    }
    
    // Time vectorized version
    clock_t start = clock();
    rgb_to_grayscale_vectorized(src, dst);
    clock_t end = clock();
    double vectorized_time = ((double)(end - start)) / CLOCKS_PER_SEC;
    
    // Time scalar version
    start = clock();
    rgb_to_grayscale_scalar(src, dst);
    end = clock();
    double scalar_time = ((double)(end - start)) / CLOCKS_PER_SEC;
    
    printf("Vectorized time: %f seconds\n", vectorized_time);
    printf("Scalar time: %f seconds\n", scalar_time);
    printf("Speedup: %fx\n", scalar_time / vectorized_time);
    
    // Clean up
    free_image(src);
    free_image(dst);
    
    return 0;
}
```

This example demonstrates:
1. Manual vectorization using AVX2 intrinsics
2. Efficient memory access patterns
3. SIMD arithmetic operations
4. Performance comparison between vectorized and scalar code

## Data Types and Vectorization

Different data types have different vectorization characteristics:

### Integer Vectorization

```c
// Original code
void add_arrays_int(int* a, int* b, int* c, int n) {
    for (int i = 0; i < n; i++) {
        c[i] = a[i] + b[i];
    }
}

// Compiler-generated vectorized code (AVX2)
add_arrays_int:
    mov    r8d, edi
    and    r8d, -8
    je     .L4
    xor    eax, eax
.L3:
    vmovdqu ymm0, YMMWORD PTR [rsi+rax*4]
    vpaddd  ymm0, ymm0, YMMWORD PTR [rdx+rax*4]
    vmovdqu YMMWORD PTR [rcx+rax*4], ymm0
    add    rax, 8
    cmp    r8d, eax
    ja     .L3
```

### Floating-Point Vectorization

```c
// Original code
void multiply_arrays_double(double* a, double* b, double* c, int n) {
    for (int i = 0; i < n; i++) {
        c[i] = a[i] * b[i];
    }
}

// Compiler-generated vectorized code (AVX2)
multiply_arrays_double:
    mov    r8d, edi
    and    r8d, -4
    je     .L4
    xor    eax, eax
.L3:
    vmovapd ymm0, YMMWORD PTR [rsi+rax*8]
    vmulpd  ymm0, ymm0, YMMWORD PTR [rdx+rax*8]
    vmovapd YMMWORD PTR [rcx+rax*8], ymm0
    add    rax, 4
    cmp    r8d, eax
    ja     .L3
```

## Standard Algorithms and Vectorization

Many standard algorithms can be vectorized effectively:

### Vectorized Sorting

```c
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <immintrin.h>

// Vectorized quicksort partition
int partition_vectorized(int* arr, int low, int high) {
    int pivot = arr[high];
    __m256i pivot_vec = _mm256_set1_epi32(pivot);
    int i = low - 1;
    
    for (int j = low; j < high; j += 8) {
        __m256i data = _mm256_loadu_si256((__m256i*)&arr[j]);
        __m256i mask = _mm256_cmpgt_epi32(pivot_vec, data);
        int mask_int = _mm256_movemask_epi8(mask);
        
        while (mask_int) {
            int bit = __builtin_ctz(mask_int);
            int idx = j + (bit / 4);
            if (idx < high) {
                i++;
                int temp = arr[i];
                arr[i] = arr[idx];
                arr[idx] = temp;
            }
            mask_int &= mask_int - 1;
        }
    }
    
    int temp = arr[i + 1];
    arr[i + 1] = arr[high];
    arr[high] = temp;
    return i + 1;
}

// Vectorized quicksort
void quicksort_vectorized(int* arr, int low, int high) {
    if (low < high) {
        int pi = partition_vectorized(arr, low, high);
        quicksort_vectorized(arr, low, pi - 1);
        quicksort_vectorized(arr, pi + 1, high);
    }
}

int main() {
    const int n = 1000000;
    int* arr = malloc(n * sizeof(int));
    
    // Initialize array with random values
    srand(time(NULL));
    for (int i = 0; i < n; i++) {
        arr[i] = rand();
    }
    
    clock_t start = clock();
    quicksort_vectorized(arr, 0, n - 1);
    clock_t end = clock();
    
    double time_taken = ((double)(end - start)) / CLOCKS_PER_SEC;
    printf("Vectorized quicksort took %f seconds\n", time_taken);
    
    free(arr);
    return 0;
}
```

### Vectorized String Operations

```c
#include <stdio.h>
#include <string.h>
#include <immintrin.h>

// Vectorized string comparison
int strcmp_vectorized(const char* s1, const char* s2) {
    __m256i zero = _mm256_setzero_si256();
    
    while (1) {
        __m256i str1 = _mm256_loadu_si256((__m256i*)s1);
        __m256i str2 = _mm256_loadu_si256((__m256i*)s2);
        
        __m256i cmp = _mm256_cmpeq_epi8(str1, str2);
        int mask = _mm256_movemask_epi8(cmp);
        
        if (mask != 0xFFFFFFFF) {
            // Find first mismatch
            int idx = __builtin_ctz(~mask);
            return s1[idx] - s2[idx];
        }
        
        // Check for null terminator
        __m256i null_check = _mm256_cmpeq_epi8(str1, zero);
        if (_mm256_movemask_epi8(null_check)) {
            return 0;
        }
        
        s1 += 32;
        s2 += 32;
    }
}

int main() {
    const char* str1 = "This is a test string for vectorized comparison";
    const char* str2 = "This is a test string for vectorized comparison";
    
    int result = strcmp_vectorized(str1, str2);
    printf("Comparison result: %d\n", result);
    
    return 0;
}
```

## Challenges of Floating-Point Vectorization

Floating-point vectorization presents unique challenges:

1. **Precision Issues**
   - Different rounding modes
   - Order of operations matters
   - FMA instructions affect precision

2. **Special Values**
   - Handling of NaN
   - Handling of infinity
   - Handling of denormals

3. **Performance Considerations**
   - Subnormal number handling
   - Rounding mode changes
   - Exception handling

### Complete Working Example: Matrix Multiplication with Floating-Point

```c
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <immintrin.h>

#define N 1024
#define BLOCK_SIZE 32

void matrix_multiply_float(float A[N][N], float B[N][N], float C[N][N]) {
    for (int i = 0; i < N; i += BLOCK_SIZE) {
        for (int j = 0; j < N; j += BLOCK_SIZE) {
            for (int k = 0; k < N; k += BLOCK_SIZE) {
                // Process block
                for (int ii = i; ii < i + BLOCK_SIZE; ii++) {
                    for (int jj = j; jj < j + BLOCK_SIZE; jj += 8) {
                        __m256 c = _mm256_loadu_ps(&C[ii][jj]);
                        
                        for (int kk = k; kk < k + BLOCK_SIZE; kk++) {
                            __m256 a = _mm256_broadcast_ss(&A[ii][kk]);
                            __m256 b = _mm256_loadu_ps(&B[kk][jj]);
                            c = _mm256_fmadd_ps(a, b, c);
                        }
                        
                        _mm256_storeu_ps(&C[ii][jj], c);
                    }
                }
            }
        }
    }
}

int main() {
    float (*A)[N] = malloc(N * N * sizeof(float));
    float (*B)[N] = malloc(N * N * sizeof(float));
    float (*C)[N] = malloc(N * N * sizeof(float));
    
    // Initialize matrices
    for (int i = 0; i < N; i++) {
        for (int j = 0; j < N; j++) {
            A[i][j] = (float)rand() / RAND_MAX;
            B[i][j] = (float)rand() / RAND_MAX;
            C[i][j] = 0.0f;
        }
    }
    
    clock_t start = clock();
    matrix_multiply_float(A, B, C);
    clock_t end = clock();
    
    double time_taken = ((double)(end - start)) / CLOCKS_PER_SEC;
    printf("Matrix multiplication took %f seconds\n", time_taken);
    
    free(A);
    free(B);
    free(C);
    
    return 0;
}
```

## Summary

Vectorization is a powerful optimization technique that can significantly improve performance. To maximize vectorization opportunities:

1. **Write Vectorization-Friendly Code**
   - Use contiguous memory access
   - Avoid data dependencies
   - Keep loops simple
   - Use appropriate data types

2. **Understand SIMD Capabilities**
   - Know your target architecture
   - Use appropriate instruction sets
   - Consider data alignment
   - Handle edge cases properly

3. **Use Compiler Directives**
   - `#pragma omp simd`
   - `__attribute__((vector_size(N)))`
   - `__restrict` keyword
   - Alignment hints

4. **Profile and Optimize**
   - Measure vectorization effectiveness
   - Identify bottlenecks
   - Consider manual vectorization
   - Balance between vectorization and other optimizations

Remember that while vectorization can provide significant performance improvements, it's not always the best solution. Consider the trade-offs between:
- Development time
- Code maintainability
- Portability
- Performance gains 