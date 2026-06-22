# VLSI-HACKATHON
RISC-V Hackathon - Preparation Assignment 2
============================================
8-element Dot-Product Accelerator -- 8x8 Matrix Multiplication

Team: Nadim Tali & Idan Kaynan


CONTENTS
========

SystemVerilog/
  accelerator.sv             -- 8-element signed dot-product compute core (modified)
  accelerator_regs.sv        -- WB-mapped register file (modified)
  accelerator_top.sv         -- Top-level wrapper (modified)
  accelerator_wb.sv          -- Wishbone interface (unchanged)
  wishbone_accelerator_tb.sv -- Wishbone BFM testbench (modified)

C_Program/
  accelerator.c              -- 8x8 matrix multiplication using the accelerator

Screenshots/
  vivado_simulation.png      -- Vivado behavioral simulation waveform
  fpga_ila_capture.png       -- ILA waveform from real FPGA run
  output_screenshot.png      -- Debug Terminal output of the result matrix


NOTES
=====

1. The expected result matrix in the original assignment PDF was incorrect.
   The corrected expected matrix (broadcast as a PNG) starts with 23776 in
   position [0][0], not 15291.  Our implementation matches the corrected
   expected values exactly:

       [ 23776  20092  21851  16691  15017  21082  16983  23229 ]
       [ 22334  23679  24155  18596  23260  22078  19503  29159 ]
       [  9977  11460  13313  10692  10046   9902  11078  14000 ]
       [ 21761  26994  25991  18887  28861  23371  24453  32669 ]
       [ 10560  21705  24604  22597  20648  14808  15894  27601 ]
       [ 19446  22831  26215  18501  27297  18515  21338  24926 ]
       [ 17608  24608  22017  18468  21379  21062  19165  29337 ]
       [ 16411  19478  18473  16604  19431  17382  15491  23476 ]

2. Performance: 64 dot-product accelerator invocations completed in
   ~41,891 cycles, giving roughly 654 cycles per accelerator call
   (write 4 inputs + Go pulse + spin-wait for Done + read result + clear Go).

3. Accelerator memory map (base 0x80001300):
       0x80001300  Control  bit0=Go (RW), bit31=Done (RO)
       0x80001304  A        4 packed signed 8-bit elements
       0x80001308  B        4 packed signed 8-bit elements
       0x8000130C  C        4 packed signed 8-bit elements
       0x80001310  D        4 packed signed 8-bit elements
       0x80001314  Result   A.B + C.D
