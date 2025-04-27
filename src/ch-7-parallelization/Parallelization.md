# Chapter 7: Parallelization

Parallelization is a crucial optimization technique that allows compilers to automatically transform sequential code into parallel code, taking advantage of modern multi-core processors. This chapter explores various parallelization techniques and how compilers implement them.

## Types of Parallelization

### Loop Parallelization

```c
// Sequential loop
void process_array(int* arr, int n) {
    for (int i = 0; i < n; i++) {
        arr[i] *= 2;
    }
}

// Parallel loop (OpenMP)
void process_array_parallel(int* arr, int n) {
    #pragma omp parallel for
    for (int i = 0; i < n; i++) {
        arr[i] *= 2;
    }
}
```

### Function Parallelization

```c
// Sequential function calls
void process_functions() {
    function1();
    function2();
    function3();
}

// Parallel function calls (OpenMP)
void process_functions_parallel() {
    #pragma omp parallel sections
    {
        #pragma omp section
        function1();
        #pragma omp section
        function2();
        #pragma omp section
        function3();
    }
}
```

## Complete Working Example: Parallel Matrix Multiplication

```c
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <omp.h>

#define N 1024
#define BLOCK_SIZE 32

// Sequential matrix multiplication
void matrix_multiply_seq(float A[N][N], float B[N][N], float C[N][N]) {
    for (int i = 0; i < N; i++) {
        for (int j = 0; j < N; j++) {
            C[i][j] = 0;
            for (int k = 0; k < N; k++) {
                C[i][j] += A[i][k] * B[k][j];
            }
        }
    }
}

// Parallel matrix multiplication
void matrix_multiply_parallel(float A[N][N], float B[N][N], float C[N][N]) {
    #pragma omp parallel for
    for (int i = 0; i < N; i++) {
        for (int j = 0; j < N; j++) {
            C[i][j] = 0;
            for (int k = 0; k < N; k++) {
                C[i][j] += A[i][k] * B[k][j];
            }
        }
    }
}

// Blocked parallel matrix multiplication
void matrix_multiply_blocked(float A[N][N], float B[N][N], float C[N][N]) {
    #pragma omp parallel for
    for (int i = 0; i < N; i += BLOCK_SIZE) {
        for (int j = 0; j < N; j += BLOCK_SIZE) {
            for (int k = 0; k < N; k += BLOCK_SIZE) {
                // Process block
                for (int ii = i; ii < i + BLOCK_SIZE; ii++) {
                    for (int jj = j; jj < j + BLOCK_SIZE; jj++) {
                        float sum = 0;
                        for (int kk = k; kk < k + BLOCK_SIZE; kk++) {
                            sum += A[ii][kk] * B[kk][jj];
                        }
                        C[ii][jj] += sum;
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
        }
    }
    
    // Time sequential multiplication
    clock_t start = clock();
    matrix_multiply_seq(A, B, C);
    clock_t end = clock();
    double seq_time = ((double)(end - start)) / CLOCKS_PER_SEC;
    
    // Time parallel multiplication
    start = clock();
    matrix_multiply_parallel(A, B, C);
    end = clock();
    double parallel_time = ((double)(end - start)) / CLOCKS_PER_SEC;
    
    // Time blocked parallel multiplication
    start = clock();
    matrix_multiply_blocked(A, B, C);
    end = clock();
    double blocked_time = ((double)(end - start)) / CLOCKS_PER_SEC;
    
    printf("Sequential multiplication: %f seconds\n", seq_time);
    printf("Parallel multiplication: %f seconds\n", parallel_time);
    printf("Blocked parallel multiplication: %f seconds\n", blocked_time);
    
    free(A);
    free(B);
    free(C);
    return 0;
}
```

## Data Dependencies and Parallelization

### Loop-Carried Dependencies

```c
// Cannot parallelize due to loop-carried dependency
void prefix_sum(int* arr, int n) {
    for (int i = 1; i < n; i++) {
        arr[i] += arr[i-1];  // Depends on previous iteration
    }
}

// Can parallelize with reduction
void sum_array(int* arr, int n) {
    int sum = 0;
    #pragma omp parallel for reduction(+:sum)
    for (int i = 0; i < n; i++) {
        sum += arr[i];  // No dependencies
    }
}
```

### Complete Working Example: Parallel Reduction

```c
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <omp.h>

#define N 1000000

// Sequential reduction
int reduce_seq(int* arr, int n) {
    int sum = 0;
    for (int i = 0; i < n; i++) {
        sum += arr[i];
    }
    return sum;
}

// Parallel reduction with OpenMP
int reduce_parallel(int* arr, int n) {
    int sum = 0;
    #pragma omp parallel for reduction(+:sum)
    for (int i = 0; i < n; i++) {
        sum += arr[i];
    }
    return sum;
}

// Parallel reduction with manual implementation
int reduce_manual(int* arr, int n) {
    int num_threads = omp_get_max_threads();
    int* partial_sums = malloc(num_threads * sizeof(int));
    
    #pragma omp parallel
    {
        int tid = omp_get_thread_num();
        partial_sums[tid] = 0;
        
        #pragma omp for
        for (int i = 0; i < n; i++) {
            partial_sums[tid] += arr[i];
        }
    }
    
    int sum = 0;
    for (int i = 0; i < num_threads; i++) {
        sum += partial_sums[i];
    }
    
    free(partial_sums);
    return sum;
}

int main() {
    int* arr = malloc(N * sizeof(int));
    
    // Initialize array
    for (int i = 0; i < N; i++) {
        arr[i] = rand() % 100;
    }
    
    // Time sequential reduction
    clock_t start = clock();
    int seq_sum = reduce_seq(arr, N);
    clock_t end = clock();
    double seq_time = ((double)(end - start)) / CLOCKS_PER_SEC;
    
    // Time parallel reduction
    start = clock();
    int parallel_sum = reduce_parallel(arr, N);
    end = clock();
    double parallel_time = ((double)(end - start)) / CLOCKS_PER_SEC;
    
    // Time manual parallel reduction
    start = clock();
    int manual_sum = reduce_manual(arr, N);
    end = clock();
    double manual_time = ((double)(end - start)) / CLOCKS_PER_SEC;
    
    printf("Sequential sum: %d, time: %f seconds\n", seq_sum, seq_time);
    printf("Parallel sum: %d, time: %f seconds\n", parallel_sum, parallel_time);
    printf("Manual parallel sum: %d, time: %f seconds\n", manual_sum, manual_time);
    
    free(arr);
    return 0;
}
```

## Task Parallelism

### Task Creation and Scheduling

```c
#include <omp.h>

void process_tasks() {
    #pragma omp parallel
    {
        #pragma omp single
        {
            for (int i = 0; i < 10; i++) {
                #pragma omp task
                {
                    printf("Task %d executed by thread %d\n", 
                           i, omp_get_thread_num());
                }
            }
        }
    }
}
```

### Complete Working Example: Task-Based Parallelism

```c
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <omp.h>

#define N 1000000
#define TASK_SIZE 10000

// Sequential processing
void process_sequential(int* arr, int n) {
    for (int i = 0; i < n; i++) {
        arr[i] *= 2;
    }
}

// Task-based parallel processing
void process_tasks(int* arr, int n) {
    #pragma omp parallel
    {
        #pragma omp single
        {
            for (int i = 0; i < n; i += TASK_SIZE) {
                int end = (i + TASK_SIZE < n) ? i + TASK_SIZE : n;
                #pragma omp task
                {
                    for (int j = i; j < end; j++) {
                        arr[j] *= 2;
                    }
                }
            }
        }
    }
}

// Task-based processing with dependencies
void process_tasks_with_deps(int* arr, int n) {
    #pragma omp parallel
    {
        #pragma omp single
        {
            for (int i = 0; i < n; i += TASK_SIZE) {
                int end = (i + TASK_SIZE < n) ? i + TASK_SIZE : n;
                #pragma omp task depend(out: arr[i])
                {
                    for (int j = i; j < end; j++) {
                        arr[j] *= 2;
                    }
                }
            }
        }
    }
}

int main() {
    int* arr = malloc(N * sizeof(int));
    
    // Initialize array
    for (int i = 0; i < N; i++) {
        arr[i] = rand() % 100;
    }
    
    // Time sequential processing
    clock_t start = clock();
    process_sequential(arr, N);
    clock_t end = clock();
    double seq_time = ((double)(end - start)) / CLOCKS_PER_SEC;
    
    // Time task-based processing
    start = clock();
    process_tasks(arr, N);
    end = clock();
    double task_time = ((double)(end - start)) / CLOCKS_PER_SEC;
    
    // Time task-based processing with dependencies
    start = clock();
    process_tasks_with_deps(arr, N);
    end = clock();
    double task_dep_time = ((double)(end - start)) / CLOCKS_PER_SEC;
    
    printf("Sequential processing: %f seconds\n", seq_time);
    printf("Task-based processing: %f seconds\n", task_time);
    printf("Task-based with dependencies: %f seconds\n", task_dep_time);
    
    free(arr);
    return 0;
}
```

## Parallelization Challenges

### False Sharing

```c
// Bad: False sharing
struct Data {
    int value1;
    int value2;
    int value3;
    int value4;
};

void process_data(struct Data* data, int n) {
    #pragma omp parallel for
    for (int i = 0; i < n; i++) {
        data[i].value1 *= 2;  // Different threads may access same cache line
    }
}

// Good: Padding to avoid false sharing
struct PaddedData {
    int value1;
    char padding1[60];  // Pad to cache line size
    int value2;
    char padding2[60];
    int value3;
    char padding3[60];
    int value4;
    char padding4[60];
};
```

### Load Balancing

```c
// Bad: Uneven work distribution
void process_uneven(int* arr, int n) {
    #pragma omp parallel for
    for (int i = 0; i < n; i++) {
        // Work increases with i
        for (int j = 0; j < i; j++) {
            arr[i] += j;
        }
    }
}

// Good: Dynamic scheduling
void process_dynamic(int* arr, int n) {
    #pragma omp parallel for schedule(dynamic, 100)
    for (int i = 0; i < n; i++) {
        for (int j = 0; j < i; j++) {
            arr[i] += j;
        }
    }
}
```

## Summary

Parallelization is a powerful optimization technique that can significantly improve performance. Key points to remember:

1. **Understand Parallelization Types**
   - Loop parallelization
   - Function parallelization
   - Task parallelism

2. **Handle Data Dependencies**
   - Identify loop-carried dependencies
   - Use reduction operations
   - Manage task dependencies

3. **Optimize Parallel Performance**
   - Avoid false sharing
   - Balance workload
   - Choose appropriate scheduling
   - Consider cache effects

4. **Use Appropriate Tools**
   - OpenMP directives
   - Task-based parallelism
   - Parallel algorithms

Remember that parallelization is not always the best solution. Consider:
- Overhead of thread creation and management
- Memory bandwidth limitations
- Cache effects
- Algorithmic complexity

Always profile your code to determine if parallelization is beneficial and to identify potential bottlenecks. 