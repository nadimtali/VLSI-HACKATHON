/*
 * RISC-V Hackathon - Preparation Assignment 2
 * 8-element dot-product accelerator demo: 8x8 matrix multiplication
 * Team: Idan Kaynan & Nadim Tali
 *
 * Accelerator memory map (base 0x80001300):
 *   0x80001300  Control  bit0 = Go (RW), bit31 = Done (RO)
 *   0x80001304  A        4 packed signed 8-bit elements
 *   0x80001308  B        4 packed signed 8-bit elements
 *   0x8000130C  C        4 packed signed 8-bit elements
 *   0x80001310  D        4 packed signed 8-bit elements
 *   0x80001314  Result   A.B + C.D
 *
 * One accelerator invocation produces one element of the result matrix:
 *   result[i][j] = sum_{k=0..7} A_mat[i][k] * B_mat[k][j]
 *                = (A_mat[i][0..3]).(B_mat[0..3][j])
 *                + (A_mat[i][4..7]).(B_mat[4..7][j])
 */

#if defined(D_NEXYS_A7)
   #include <bsp_printf.h>
   #include <bsp_mem_map.h>
   #include <bsp_version.h>
#else
   PRE_COMPILED_MSG("no platform was defined")
#endif

#include <psp_api.h>
#include <stdio.h>
#include <stdint.h>

/* ---------- Accelerator interface ---------- */
#define ACCEL_REG_CTRL    0x80001300
#define ACCEL_REG_A       0x80001304
#define ACCEL_REG_B       0x80001308
#define ACCEL_REG_C       0x8000130C
#define ACCEL_REG_D       0x80001310
#define ACCEL_REG_RESULT  0x80001314

#define CTRL_GO_BIT       0x00000001u
#define CTRL_DONE_BIT     0x80000000u

#define READ_REG(addr)        (*(volatile unsigned int *)(addr))
#define WRITE_REG(addr, val)  ((*(volatile unsigned int *)(addr)) = (val))

/* ---------- Input matrices (from assignment) ---------- */
static const signed char A_mat[8][8] = {
    { 53, 24, 92, 10, 49, 99, 15, 72},
    { 30, 69, 88, 77, 45, 65, 16, 81},
    { 24,  6, 55, 26, 31, 48, 37, 12},
    {  4, 71, 98, 82, 59, 39, 79, 97},
    { 96, 40, 14, 95, 50, 29, 66, 17},
    {  2, 94, 33, 61, 91, 88, 78, 54},
    { 60, 35, 73, 62, 57, 18, 47, 85},
    { 20, 11, 21, 83, 38, 44, 64, 91}
};

static const signed char B_mat[8][8] = {
    { 30, 66, 84, 88, 13, 49, 19, 93},
    { 28, 31, 67, 14, 79, 17, 27, 45},
    { 50, 56, 47, 24, 34, 57, 70, 82},
    {  8, 60, 54, 76, 80, 33, 40, 95},
    {  4, 75, 22, 29, 59, 41, 64, 29},
    { 95, 12, 71, 53, 14, 38, 22, 16},
    {  7, 37, 68, 41, 61, 12, 58, 55},
    { 99, 65, 25, 20, 46, 91, 32, 68}
};

static int result[8][8];

/* Pack four signed 8-bit elements into a 32-bit word (e0=LSB, e3=MSB). */
static inline unsigned int pack4(signed char e0, signed char e1,
                                 signed char e2, signed char e3)
{
    return ((unsigned int)(unsigned char)e0)        |
           ((unsigned int)(unsigned char)e1) <<  8  |
           ((unsigned int)(unsigned char)e2) << 16  |
           ((unsigned int)(unsigned char)e3) << 24;
}

/* Compute one 8-element dot product through the accelerator. */
static int dot8_via_accel(const signed char *row, const signed char *col)
{
    unsigned int a_pkt = pack4(row[0], row[1], row[2], row[3]);
    unsigned int b_pkt = pack4(col[0], col[1], col[2], col[3]);
    unsigned int c_pkt = pack4(row[4], row[5], row[6], row[7]);
    unsigned int d_pkt = pack4(col[4], col[5], col[6], col[7]);

    WRITE_REG(ACCEL_REG_A, a_pkt);
    WRITE_REG(ACCEL_REG_B, b_pkt);
    WRITE_REG(ACCEL_REG_C, c_pkt);
    WRITE_REG(ACCEL_REG_D, d_pkt);

    /* Pulse Go */
    WRITE_REG(ACCEL_REG_CTRL, CTRL_GO_BIT);

    /* Spin until Done */
    while ((READ_REG(ACCEL_REG_CTRL) & CTRL_DONE_BIT) == 0u) { }

    int res = (int)READ_REG(ACCEL_REG_RESULT);

    /* Drop Go so the accelerator FSM returns to IDLE for the next op */
    WRITE_REG(ACCEL_REG_CTRL, 0);

    return res;
}

int main(void)
{
    signed char col[8];
    int i, j, k;
    int cyc_beg, cyc_end;

    pspMachinePerfMonitorEnableAll();
    pspMachinePerfCounterSet(D_PSP_COUNTER0, D_CYCLES_CLOCKS_ACTIVE);

    printf("RISC-V Hackathon - Preparation Assignment 2\n");
    printf("8-element dot-product accelerator: 8x8 matrix multiplication\n");
    printf("Team: Idan Kaynan, Nadim Tali (2 students)\n");
    printf("============================================\n");

    cyc_beg = pspMachinePerfCounterGet(D_PSP_COUNTER0);

    for (i = 0; i < 8; i++) {
        for (j = 0; j < 8; j++) {
            for (k = 0; k < 8; k++) col[k] = B_mat[k][j];
            result[i][j] = dot8_via_accel(A_mat[i], col);
        }
    }

    cyc_end = pspMachinePerfCounterGet(D_PSP_COUNTER0);

    printf("Result matrix (A * B):\n");
    for (i = 0; i < 8; i++) {
        printf("[ ");
        for (j = 0; j < 8; j++) {
            printf("%6d ", result[i][j]);
        }
        printf("]\n");
    }

    printf("============================================\n");
    printf("Total accelerator-driven multiply: %d cycles\n",
                cyc_end - cyc_beg);
    printf("Done.\n");

    while (1) { }
}
