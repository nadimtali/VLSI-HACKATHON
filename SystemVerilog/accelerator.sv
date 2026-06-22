// RISC-V Hackathon - Preparation Assignment 2
// 8-element signed dot-product accelerator
// Result = A[3]*B[3] + A[2]*B[2] + A[1]*B[1] + A[0]*B[0]
//        + C[3]*D[3] + C[2]*D[2] + C[1]*D[1] + C[0]*D[0]
// Each of A, B, C, D is a 32-bit register packing four 8-bit signed elements:
//   element 0 -> bits  [7:0]
//   element 1 -> bits [15:8]
//   element 2 -> bits [23:16]
//   element 3 -> bits [31:24]
// Team: Idan Kaynan & Nadim Tali
// Based on original by Alex Grinshpun (Dec 2023)

module accelerator
(
    input  logic        clk,
    input  logic        wb_rst_i,

    input  logic        go,                   // Start signal from Control reg bit 0
    input  logic [31:0] reg_a,
    input  logic [31:0] reg_b,
    input  logic [31:0] reg_c,
    input  logic [31:0] reg_d,

    output logic        done,                 // Reflected to Control reg bit 31
    output logic [31:0] reg_result            // Latched dot-product result
);

    logic rst_n;
    assign rst_n = ~wb_rst_i;

    // -----------------------------------------------------------------
    // Combinational dot-product (signed 8-bit elements, 32-bit accumulate)
    // -----------------------------------------------------------------
    logic signed [31:0] dot_product;
    assign dot_product =
        $signed(reg_a[ 7: 0]) * $signed(reg_b[ 7: 0]) +
        $signed(reg_a[15: 8]) * $signed(reg_b[15: 8]) +
        $signed(reg_a[23:16]) * $signed(reg_b[23:16]) +
        $signed(reg_a[31:24]) * $signed(reg_b[31:24]) +
        $signed(reg_c[ 7: 0]) * $signed(reg_d[ 7: 0]) +
        $signed(reg_c[15: 8]) * $signed(reg_d[15: 8]) +
        $signed(reg_c[23:16]) * $signed(reg_d[23:16]) +
        $signed(reg_c[31:24]) * $signed(reg_d[31:24]);

    // -----------------------------------------------------------------
    // Tiny FSM: IDLE -> COMPUTE -> DONE -> IDLE
    //   - on rising-level of `go`, transition through COMPUTE (latches result)
    //   - DONE asserted in DONE state until SW clears Go
    // -----------------------------------------------------------------
    typedef enum logic [1:0] {S_IDLE, S_COMPUTE, S_DONE} state_t;
    state_t state, next_state;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) state <= S_IDLE;
        else        state <= next_state;
    end

    always_comb begin
        next_state = state;
        unique case (state)
            S_IDLE   : if ( go) next_state = S_COMPUTE;
            S_COMPUTE:          next_state = S_DONE;
            S_DONE   : if (!go) next_state = S_IDLE;
            default  :          next_state = S_IDLE;
        endcase
    end

    // Latch the result when entering S_DONE (i.e. while in S_COMPUTE)
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            reg_result <= 32'h0;
        else if (state == S_COMPUTE)
            reg_result <= dot_product;
    end

    assign done = (state == S_DONE);

endmodule
