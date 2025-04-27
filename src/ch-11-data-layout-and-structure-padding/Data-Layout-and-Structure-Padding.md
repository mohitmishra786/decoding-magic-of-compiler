# Chapter 11: Data Layout and Structure Padding

The way data is laid out in memory has profound implications for performance. Modern processors access memory most efficiently when data is properly aligned, leading compilers to insert padding between structure members to ensure optimal access patterns. This chapter explores the intricacies of data layout, structure padding, and their impact on performance.

## Memory Alignment Fundamentals

Memory alignment refers to placing data at memory addresses that are multiples of the data's size or the processor's word size. Most modern processors are designed to access memory most efficiently when data is naturally aligned.

### Architecture Alignment Requirements

Different processors have different alignment requirements:

```c
// On a 64-bit x86 system:
char a;     // 1 byte, can be placed at any address
short b;    // 2 bytes, preferably aligned at addresses divisible by 2
int c;      // 4 bytes, preferably aligned at addresses divisible by 4
long d;     // 8 bytes, preferably aligned at addresses divisible by 8
double e;   // 8 bytes, preferably aligned at addresses divisible by 8
```

### Alignment Impact on Performance

Misaligned memory access can result in significant performance penalties:

1. **Hardware Penalties**: Some processors may trap on misaligned access, requiring the OS to emulate the operation
2. **Extra Memory Operations**: Accessing data that crosses cache line boundaries requires multiple memory operations
3. **Cache Utilization**: Misaligned data uses cache space inefficiently

```c
// Demonstrating potential misalignment
void potential_misaligned_access(void* ptr) {
    int* misaligned_ptr = (int*)((char*)ptr + 1); // Offset by 1 byte
    *misaligned_ptr = 42; // Potentially misaligned write
}
```

## Structure Padding

To ensure that each field in a structure is properly aligned, compilers automatically insert padding between structure members.

### Basic Structure Padding

```c
struct PaddedExample {
    char a;      // 1 byte
    // 3 bytes padding
    int b;       // 4 bytes
    short c;     // 2 bytes
    // 6 bytes padding
    double d;    // 8 bytes
}; // Total: 24 bytes
```

The compiler inserts padding to ensure each member is aligned according to its requirements, even though this increases the total structure size.

### Structure Packing

Sometimes, you may want to eliminate padding to save memory, especially in scenarios like file I/O or network protocols:

```c
// GCC/Clang syntax
struct __attribute__((packed)) PackedExample {
    char a;      // 1 byte
    int b;       // 4 bytes
    short c;     // 2 bytes
    double d;    // 8 bytes
}; // Total: 15 bytes

// MSVC syntax
#pragma pack(push, 1)
struct PackedExample {
    char a;      // 1 byte
    int b;       // 4 bytes
    short c;     // 2 bytes
    double d;    // 8 bytes
}; // Total: 15 bytes
#pragma pack(pop)
```

However, packed structures often come with severe performance penalties due to misaligned access.

## Complete Working Example: Measuring Alignment Impact

```c
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <stdint.h>
#include <string.h>

#define ARRAY_SIZE 10000000
#define ITERATIONS 100

// Aligned structure
struct AlignedStruct {
    int a;
    double b;
    char c;
    long d;
};

// Packed structure (misaligned)
struct __attribute__((packed)) PackedStruct {
    int a;
    double b;
    char c;
    long d;
};

// Manually optimized structure (sorted by size)
struct OptimizedStruct {
    double b;
    long d;
    int a;
    char c;
    // Compiler will add 3 bytes of padding here
};

// Test functions
void test_aligned(struct AlignedStruct* array, int size) {
    for (int i = 0; i < size; i++) {
        array[i].a += 1;
        array[i].b *= 1.01;
        array[i].c += 1;
        array[i].d |= 0xFF;
    }
}

void test_packed(struct PackedStruct* array, int size) {
    for (int i = 0; i < size; i++) {
        array[i].a += 1;
        array[i].b *= 1.01;
        array[i].c += 1;
        array[i].d |= 0xFF;
    }
}

void test_optimized(struct OptimizedStruct* array, int size) {
    for (int i = 0; i < size; i++) {
        array[i].a += 1;
        array[i].b *= 1.01;
        array[i].c += 1;
        array[i].d |= 0xFF;
    }
}

int main() {
    // Allocate and initialize arrays
    struct AlignedStruct* aligned_array = malloc(ARRAY_SIZE * sizeof(struct AlignedStruct));
    struct PackedStruct* packed_array = malloc(ARRAY_SIZE * sizeof(struct PackedStruct));
    struct OptimizedStruct* optimized_array = malloc(ARRAY_SIZE * sizeof(struct OptimizedStruct));
    
    // Initialize with random data
    for (int i = 0; i < ARRAY_SIZE; i++) {
        aligned_array[i].a = rand();
        aligned_array[i].b = (double)rand() / RAND_MAX;
        aligned_array[i].c = rand() % 256;
        aligned_array[i].d = (long)rand() << 32 | rand();
        
        // Copy values to other arrays
        packed_array[i].a = aligned_array[i].a;
        packed_array[i].b = aligned_array[i].b;
        packed_array[i].c = aligned_array[i].c;
        packed_array[i].d = aligned_array[i].d;
        
        optimized_array[i].a = aligned_array[i].a;
        optimized_array[i].b = aligned_array[i].b;
        optimized_array[i].c = aligned_array[i].c;
        optimized_array[i].d = aligned_array[i].d;
    }
    
    // Print structure sizes
    printf("Structure sizes:\n");
    printf("AlignedStruct: %zu bytes\n", sizeof(struct AlignedStruct));
    printf("PackedStruct: %zu bytes\n", sizeof(struct PackedStruct));
    printf("OptimizedStruct: %zu bytes\n", sizeof(struct OptimizedStruct));
    
    // Time aligned access
    clock_t start = clock();
    for (int i = 0; i < ITERATIONS; i++) {
        test_aligned(aligned_array, ARRAY_SIZE);
    }
    clock_t end = clock();
    double aligned_time = ((double)(end - start)) / CLOCKS_PER_SEC;
    
    // Time packed access
    start = clock();
    for (int i = 0; i < ITERATIONS; i++) {
        test_packed(packed_array, ARRAY_SIZE);
    }
    end = clock();
    double packed_time = ((double)(end - start)) / CLOCKS_PER_SEC;
    
    // Time optimized access
    start = clock();
    for (int i = 0; i < ITERATIONS; i++) {
        test_optimized(optimized_array, ARRAY_SIZE);
    }
    end = clock();
    double optimized_time = ((double)(end - start)) / CLOCKS_PER_SEC;
    
    // Report results
    printf("\nPerformance results:\n");
    printf("Aligned access: %.3f seconds\n", aligned_time);
    printf("Packed access: %.3f seconds\n", packed_time);
    printf("Optimized access: %.3f seconds\n", optimized_time);
    
    printf("\nRelative performance:\n");
    printf("Packed vs Aligned: %.2fx slower\n", packed_time / aligned_time);
    printf("Optimized vs Aligned: %.2fx faster\n", aligned_time / optimized_time);
    
    // Clean up
    free(aligned_array);
    free(packed_array);
    free(optimized_array);
    
    return 0;
}
```

## Structure Member Ordering

The order of members in a structure affects both its size and access performance. Reordering members can minimize padding and improve cache utilization.

### Size-Based Ordering

A common optimization technique is to order structure members by descending size:

```c
// Poor ordering (lots of padding)
struct BadOrder {
    char a;      // 1 byte
    // 7 bytes padding
    double b;    // 8 bytes
    short c;     // 2 bytes
    // 2 bytes padding
    int d;       // 4 bytes
    char e;      // 1 byte
    // 7 bytes padding
}; // Total: 32 bytes

// Better ordering (minimized padding)
struct GoodOrder {
    double b;    // 8 bytes
    int d;       // 4 bytes
    short c;     // 2 bytes
    char a;      // 1 byte
    char e;      // 1 byte
    // 0 bytes padding
}; // Total: 16 bytes
```

### Access-Pattern Ordering

Sometimes, members should be ordered based on their access patterns rather than size:

```c
// Optimized for frequent access pattern
struct OptimizedForAccess {
    // Frequently accessed together
    int x;
    int y;
    int z;
    
    // Rarely accessed
    char metadata[100];
};
```

## Cache-Friendly Data Structures

Understand how data structure layout affects cache behavior to design cache-friendly structures.

### Structure of Arrays vs. Array of Structures

Two common approaches to organizing collections of structured data:

```c
// Array of Structures (AoS)
struct Particle {
    float x, y, z;       // Position
    float vx, vy, vz;    // Velocity
    float mass;          // Mass
    int id;              // Identifier
};
struct Particle particles[1000];

// Structure of Arrays (SoA)
struct ParticleSystem {
    float x[1000], y[1000], z[1000];      // Positions
    float vx[1000], vy[1000], vz[1000];   // Velocities
    float mass[1000];                      // Masses
    int id[1000];                          // Identifiers
};
```

SoA often provides better cache utilization when processing a single attribute across many objects.

### Complete Working Example: AoS vs. SoA Performance

```c
#include <stdio.h>
#include <stdlib.h>
#include <time.h>

#define NUM_PARTICLES 1000000
#define ITERATIONS 100

// Array of Structures (AoS) approach
typedef struct {
    float x, y, z;       // Position
    float vx, vy, vz;    // Velocity
    float mass;          // Mass
    int active;          // Whether particle is active
} Particle;

// Structure of Arrays (SoA) approach
typedef struct {
    float* x, *y, *z;    // Positions
    float* vx, *vy, *vz; // Velocities
    float* mass;         // Masses
    int* active;         // Activity flags
} ParticleSystem;

// Update functions
void update_aos(Particle* particles, int count) {
    for (int i = 0; i < count; i++) {
        if (particles[i].active) {
            particles[i].x += particles[i].vx;
            particles[i].y += particles[i].vy;
            particles[i].z += particles[i].vz;
        }
    }
}

void update_soa(ParticleSystem* system, int count) {
    for (int i = 0; i < count; i++) {
        if (system->active[i]) {
            system->x[i] += system->vx[i];
            system->y[i] += system->vy[i];
            system->z[i] += system->vz[i];
        }
    }
}

// Position-only update (common in physics simulations)
void update_position_aos(Particle* particles, int count) {
    for (int i = 0; i < count; i++) {
        if (particles[i].active) {
            particles[i].x += particles[i].vx;
            particles[i].y += particles[i].vy;
            particles[i].z += particles[i].vz;
        }
    }
}

void update_position_soa(ParticleSystem* system, int count) {
    for (int i = 0; i < count; i++) {
        if (system->active[i]) {
            system->x[i] += system->vx[i];
            system->y[i] += system->vy[i];
            system->z[i] += system->vz[i];
        }
    }
}

// Mass-only update
void update_mass_aos(Particle* particles, int count, float factor) {
    for (int i = 0; i < count; i++) {
        if (particles[i].active) {
            particles[i].mass *= factor;
        }
    }
}

void update_mass_soa(ParticleSystem* system, int count, float factor) {
    for (int i = 0; i < count; i++) {
        if (system->active[i]) {
            system->mass[i] *= factor;
        }
    }
}

int main() {
    // Allocate memory for AoS approach
    Particle* particles = malloc(NUM_PARTICLES * sizeof(Particle));
    
    // Allocate memory for SoA approach
    ParticleSystem system;
    system.x = malloc(NUM_PARTICLES * sizeof(float));
    system.y = malloc(NUM_PARTICLES * sizeof(float));
    system.z = malloc(NUM_PARTICLES * sizeof(float));
    system.vx = malloc(NUM_PARTICLES * sizeof(float));
    system.vy = malloc(NUM_PARTICLES * sizeof(float));
    system.vz = malloc(NUM_PARTICLES * sizeof(float));
    system.mass = malloc(NUM_PARTICLES * sizeof(float));
    system.active = malloc(NUM_PARTICLES * sizeof(int));
    
    // Initialize with random data
    srand(time(NULL));
    for (int i = 0; i < NUM_PARTICLES; i++) {
        // Generate random values
        float x = (float)rand() / RAND_MAX * 100.0f;
        float y = (float)rand() / RAND_MAX * 100.0f;
        float z = (float)rand() / RAND_MAX * 100.0f;
        float vx = ((float)rand() / RAND_MAX - 0.5f) * 2.0f;
        float vy = ((float)rand() / RAND_MAX - 0.5f) * 2.0f;
        float vz = ((float)rand() / RAND_MAX - 0.5f) * 2.0f;
        float mass = (float)rand() / RAND_MAX * 10.0f;
        int active = rand() % 2;
        
        // Set AoS data
        particles[i].x = x;
        particles[i].y = y;
        particles[i].z = z;
        particles[i].vx = vx;
        particles[i].vy = vy;
        particles[i].vz = vz;
        particles[i].mass = mass;
        particles[i].active = active;
        
        // Set SoA data
        system.x[i] = x;
        system.y[i] = y;
        system.z[i] = z;
        system.vx[i] = vx;
        system.vy[i] = vy;
        system.vz[i] = vz;
        system.mass[i] = mass;
        system.active[i] = active;
    }
    
    // Benchmark complete update
    clock_t start, end;
    double aos_time, soa_time;
    
    start = clock();
    for (int i = 0; i < ITERATIONS; i++) {
        update_aos(particles, NUM_PARTICLES);
    }
    end = clock();
    aos_time = ((double)(end - start)) / CLOCKS_PER_SEC;
    
    start = clock();
    for (int i = 0; i < ITERATIONS; i++) {
        update_soa(&system, NUM_PARTICLES);
    }
    end = clock();
    soa_time = ((double)(end - start)) / CLOCKS_PER_SEC;
    
    printf("Complete update:\n");
    printf("AoS time: %.3f seconds\n", aos_time);
    printf("SoA time: %.3f seconds\n", soa_time);
    printf("SoA speedup: %.2fx\n\n", aos_time / soa_time);
    
    // Benchmark position-only update
    start = clock();
    for (int i = 0; i < ITERATIONS; i++) {
        update_position_aos(particles, NUM_PARTICLES);
    }
    end = clock();
    aos_time = ((double)(end - start)) / CLOCKS_PER_SEC;
    
    start = clock();
    for (int i = 0; i < ITERATIONS; i++) {
        update_position_soa(&system, NUM_PARTICLES);
    }
    end = clock();
    soa_time = ((double)(end - start)) / CLOCKS_PER_SEC;
    
    printf("Position-only update:\n");
    printf("AoS time: %.3f seconds\n", aos_time);
    printf("SoA time: %.3f seconds\n", soa_time);
    printf("SoA speedup: %.2fx\n\n", aos_time / soa_time);
    
    // Benchmark mass-only update
    start = clock();
    for (int i = 0; i < ITERATIONS; i++) {
        update_mass_aos(particles, NUM_PARTICLES, 0.999f);
    }
    end = clock();
    aos_time = ((double)(end - start)) / CLOCKS_PER_SEC;
    
    start = clock();
    for (int i = 0; i < ITERATIONS; i++) {
        update_mass_soa(&system, NUM_PARTICLES, 0.999f);
    }
    end = clock();
    soa_time = ((double)(end - start)) / CLOCKS_PER_SEC;
    
    printf("Mass-only update:\n");
    printf("AoS time: %.3f seconds\n", aos_time);
    printf("SoA time: %.3f seconds\n", soa_time);
    printf("SoA speedup: %.2fx\n", aos_time / soa_time);
    
    // Clean up
    free(particles);
    free(system.x);
    free(system.y);
    free(system.z);
    free(system.vx);
    free(system.vy);
    free(system.vz);
    free(system.mass);
    free(system.active);
    
    return 0;
}
```

## Alignment Control

Most languages and compilers provide mechanisms to control data alignment.

### Alignment Directives

```c
// C11 alignas
alignas(16) int aligned_array[4];

// GCC/Clang attribute
int __attribute__((aligned(16))) aligned_array[4];

// MSVC declspec
__declspec(align(16)) int aligned_array[4];
```

### Aligned Allocation

```c
#include <stdlib.h>

// C11 aligned allocation
void* aligned_ptr = aligned_alloc(16, size);

// POSIX aligned allocation
int posix_memalign(&void* ptr, 16, size);

// C++17 aligned allocation
void* aligned_ptr = std::aligned_alloc(16, size);
```

## Field Packing and Bit Fields

For extremely memory-constrained environments, bit fields allow packing multiple values into a single word:

```c
struct PackedFlags {
    unsigned int is_active : 1;    // 1 bit
    unsigned int mode : 3;         // 3 bits
    unsigned int priority : 4;     // 4 bits
    unsigned int reserved : 24;    // 24 bits
};
```

This structure uses only 4 bytes (32 bits) of memory to store four distinct values.

### Complete Working Example: Bit Field Performance

```c
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <stdint.h>

#define ARRAY_SIZE 10000000
#define ITERATIONS 100

// Regular structure
struct RegularStruct {
    int is_active;   // 4 bytes
    int mode;        // 4 bytes
    int priority;    // 4 bytes
}; // Total: 12 bytes

// Bit field structure
struct BitFieldStruct {
    unsigned int is_active : 1;    // 1 bit
    unsigned int mode : 3;         // 3 bits
    unsigned int priority : 4;     // 4 bits
    unsigned int reserved : 24;    // 24 bits
}; // Total: 4 bytes

// Update functions
void update_regular(struct RegularStruct* array, int size) {
    for (int i = 0; i < size; i++) {
        if (array[i].is_active) {
            array[i].priority = (array[i].priority + 1) % 16;
            array[i].mode = (array[i].mode + 1) % 8;
        }
    }
}

void update_bitfield(struct BitFieldStruct* array, int size) {
    for (int i = 0; i < size; i++) {
        if (array[i].is_active) {
            array[i].priority = (array[i].priority + 1) % 16;
            array[i].mode = (array[i].mode + 1) % 8;
        }
    }
}

int main() {
    // Allocate and initialize arrays
    struct RegularStruct* regular_array = malloc(ARRAY_SIZE * sizeof(struct RegularStruct));
    struct BitFieldStruct* bitfield_array = malloc(ARRAY_SIZE * sizeof(struct BitFieldStruct));
    
    // Initialize with random data
    for (int i = 0; i < ARRAY_SIZE; i++) {
        regular_array[i].is_active = rand() % 2;
        regular_array[i].mode = rand() % 8;
        regular_array[i].priority = rand() % 16;
        
        bitfield_array[i].is_active = regular_array[i].is_active;
        bitfield_array[i].mode = regular_array[i].mode;
        bitfield_array[i].priority = regular_array[i].priority;
        bitfield_array[i].reserved = 0;
    }
    
    // Print structure sizes
    printf("Structure sizes:\n");
    printf("RegularStruct: %zu bytes\n", sizeof(struct RegularStruct));
    printf("BitFieldStruct: %zu bytes\n", sizeof(struct BitFieldStruct));
    printf("Memory saving: %.1f%%\n", 
           (1.0 - (double)sizeof(struct BitFieldStruct) / sizeof(struct RegularStruct)) * 100);
    
    // Time regular access
    clock_t start = clock();
    for (int i = 0; i < ITERATIONS; i++) {
        update_regular(regular_array, ARRAY_SIZE);
    }
    clock_t end = clock();
    double regular_time = ((double)(end - start)) / CLOCKS_PER_SEC;
    
    // Time bitfield access
    start = clock();
    for (int i = 0; i < ITERATIONS; i++) {
        update_bitfield(bitfield_array, ARRAY_SIZE);
    }
    end = clock();
    double bitfield_time = ((double)(end - start)) / CLOCKS_PER_SEC;
    
    // Report results
    printf("\nPerformance results:\n");
    printf("Regular structure: %.3f seconds\n", regular_time);
    printf("Bit field structure: %.3f seconds\n", bitfield_time);
    
    printf("\nRelative performance:\n");
    if (bitfield_time > regular_time) {
        printf("Bit fields are %.2fx slower\n", bitfield_time / regular_time);
    } else {
        printf("Bit fields are %.2fx faster\n", regular_time / bitfield_time);
    }
    
    // Clean up
    free(regular_array);
    free(bitfield_array);
    
    return 0;
}
```

## Data Layout for SIMD Processing

Properly aligned data is essential for efficient SIMD (Single Instruction, Multiple Data) processing.

### SIMD-Friendly Data Layout

```c
// SIMD-friendly structure layout
struct SimdFriendly {
    float x[4];  // Process all 4 components together
    float y[4];
    float z[4];
    int flags[4];
} __attribute__((aligned(16)));
```

### SIMD-Friendly Arrays

```c
// Align arrays for SIMD processing
alignas(32) float positions_x[1024];
alignas(32) float positions_y[1024];
alignas(32) float positions_z[1024];
```

## Cross-Platform Data Layout Considerations

Different platforms may have different alignment requirements and structure padding behaviors.

### Portable Structure Definitions

```c
// Cross-platform structure with explicit padding
struct PortableStruct {
    uint32_t id;            // 4 bytes
    uint8_t flags;          // 1 byte
    uint8_t padding[3];     // 3 bytes explicit padding
    float values[4];        // 16 bytes
} __attribute__((packed));  // Ensure consistent layout
```

### Endianness Considerations

When sharing data between different platforms, consider endianness issues:

```c
// Reading a binary value with endianness handling
uint32_t read_uint32(const void* data) {
    const uint8_t* bytes = (const uint8_t*)data;
    
    // Little-endian read
    return (uint32_t)bytes[0] | 
           ((uint32_t)bytes[1] << 8) | 
           ((uint32_t)bytes[2] << 16) | 
           ((uint32_t)bytes[3] << 24);
}
```

## Summary

Efficient data layout is a critical but often overlooked aspect of performance optimization:

1. **Understand Memory Alignment**
   - Hardware requires aligned access for optimal performance
   - Different data types have different alignment requirements
   - Misaligned access can severely impact performance

2. **Optimize Structure Layout**
   - Be aware of structure padding and how to minimize it
   - Order members strategically to reduce padding
   - Consider access patterns when designing structures

3. **Choose Appropriate Data Organizations**
   - AoS vs. SoA has significant performance implications
   - Memory access patterns determine optimal organization
   - Different operations favor different organizations

4. **Use Language and Compiler Features**
   - Control alignment and padding with language features
   - Use bit fields for highly space-constrained scenarios
   - Ensure SIMD-compatible data layouts where appropriate

5. **Consider Platform-Specific Issues**
   - Be aware of cross-platform alignment differences
   - Handle endianness when sharing binary data
   - Implement portable structure definitions when necessary

Proper data layout can yield performance improvements as significant as algorithmic optimizations, and is an essential skill for any performance-conscious developer. 