# VLSI-HACKATHON
# DNA Sequence Alignment Hardware Acceleration – VLSI Hackathon

Team: Idan Kaynan & Nadim Tali

## Overview

This project was developed as part of a VLSI/FPGA hackathon focused on accelerating DNA sequence alignment using hardware-oriented optimization.

The goal of the project was to improve the performance of a DNA sequence alignment algorithm by analyzing the original software implementation, identifying the main bottlenecks, and optimizing the computation for an FPGA/RISC-V environment.

The alignment algorithm compares an input DNA sequence against a reference sequence and calculates a score using a dynamic-programming matrix. Since this matrix calculation is repeated many times and requires a large amount of memory access, it was the main target for optimization.

## What We Did

During the hackathon, we started by understanding the original software implementation and the way the scoring matrix is calculated.

Each cell in the matrix depends on previous values, mainly:

- The cell above
- The cell to the left
- The diagonal cell

After understanding the baseline implementation, we focused on reducing memory usage, improving data representation, and making the algorithm more suitable for hardware acceleration.

## Main Optimizations

### 1. Rolling Rows Optimization

The original approach stores the full dynamic-programming matrix.

We improved this by using rolling rows. Instead of keeping the entire matrix in memory, we only keep the previous row and the current row.

This works because each new row only depends on values from the previous row and the current row being calculated.

This optimization reduces memory usage and makes the algorithm more hardware-friendly.

### 2. 2-Bit DNA Encoding

DNA sequences are made from only four possible bases:

```txt
A, C, G, T
```

Because there are only four values, each DNA base can be represented using 2 bits instead of a full character.

Example encoding:

```txt
A = 00
C = 01
G = 10
T = 11
```

This reduces the amount of memory needed to store the sequences and makes DNA comparisons simpler and faster in hardware.

### 3. Hardware-Oriented Acceleration

After improving the software logic, we adapted the computation for an FPGA-based RISC-V environment.

The idea was to move the heavy repeated computation closer to hardware, while the processor controls the general program flow.

This gave us experience with hardware/software co-design, memory-mapped hardware logic, Vivado synthesis, timing analysis, and performance measurement.

### 4. Vivado Synthesis and Performance Testing

We used Vivado to synthesize the design and check the hardware results.

We analyzed:

- LUT usage
- Register usage
- Resource utilization
- Timing
- Maximum frequency / Fmax
- Cycle count
- Correctness of the final alignment result

Our optimized implementation reached around the 12k cycle range, showing a strong improvement compared to the original baseline.

## Tools Used

- Vivado
- FPGA-based RISC-V environment
- C
- SystemVerilog
- Memory-mapped hardware acceleration
- Simulation and synthesis reports

## Key Concepts

- VLSI design
- FPGA acceleration
- DNA sequence alignment
- Dynamic programming
- Rolling-row optimization
- 2-bit data encoding
- Hardware/software co-design
- Memory optimization
- Vivado synthesis
- Cycle-count performance analysis

## What We Learned

Through this hackathon, we gained hands-on experience with optimizing a software algorithm for hardware execution.

We learned how to identify performance bottlenecks, reduce memory usage, simplify data representation, and think about the algorithm from a hardware perspective.

We also gained practical experience using Vivado, reading synthesis and utilization reports, checking timing, and measuring performance using cycle counts.

## Final Result

The final implementation produced the correct DNA alignment behavior while using a more efficient and hardware-friendly approach.

By combining rolling-row memory optimization, 2-bit DNA encoding, and FPGA-oriented design, we improved the performance of the DNA alignment algorithm and made it more suitable for hardware acceleration.

## Notes

This project was completed under hackathon time constraints, so the main focus was on building a working optimized solution and proving the performance improvement.

The most important parts of the project were understanding the algorithm, improving the memory usage, optimizing the data representation, and evaluating the result using Vivado and cycle-count measurements.
