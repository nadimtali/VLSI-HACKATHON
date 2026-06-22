// RISC-V Hackathon - Preparation Assignment 2
// 8-element dot-product accelerator - register file
// Team: Idan Kaynan & Nadim Tali
// Based on original by Alex Grinshpun (Dec 2023)
// Provided AS IS without any warranty of any kind nor EXPLICIT nor IMPLIED

`define ACCELERATOR_REG_CTRL    8'h00   // Control register: bit0=Go (RW), bit31=Done (RO)
`define ACCELERATOR_REG_A       8'h04   // Vector A: 4 packed 8-bit elements
`define ACCELERATOR_REG_B       8'h08   // Vector B: 4 packed 8-bit elements
`define ACCELERATOR_REG_C       8'h0C   // Vector C: 4 packed 8-bit elements
`define ACCELERATOR_REG_D       8'h10   // Vector D: 4 packed 8-bit elements
`define ACCELERATOR_REG_RESULT  8'h14   // Result of A.B + C.D


module accelerator_regs
#(parameter SIM = 0)
(
    input  logic        clk,
    input  logic        wb_rst_i,
    input  logic [7:0]  wb_addr_i,
    input  logic [31:0] wb_dat_i,
    output logic [31:0] wb_dat_o,
    input  logic        wb_we_i,
    input  logic        wb_re_i,
    input  logic        done,         // Status from accelerator
    output logic        go,           // Trigger to accelerator
    output logic [31:0] reg_a,
    output logic [31:0] reg_b,
    output logic [31:0] reg_c,
    output logic [31:0] reg_d,
    input  logic [31:0] reg_result
);

    // Only the Go bit (bit 0) of Control is software-writable;
    // the Done bit (bit 31) is supplied by the accelerator and merged on read.
    logic ctrl_go;

    // -----------------------------------------------------------------
    // Asynchronous read mux
    // -----------------------------------------------------------------
    always_comb begin
        case (wb_addr_i)
            `ACCELERATOR_REG_CTRL   : wb_dat_o = {done, 30'b0, ctrl_go};
            `ACCELERATOR_REG_A      : wb_dat_o = reg_a;
            `ACCELERATOR_REG_B      : wb_dat_o = reg_b;
            `ACCELERATOR_REG_C      : wb_dat_o = reg_c;
            `ACCELERATOR_REG_D      : wb_dat_o = reg_d;
            `ACCELERATOR_REG_RESULT : wb_dat_o = reg_result;
            default                 : wb_dat_o = 32'b0;
        endcase
    end

    // -----------------------------------------------------------------
    // Synchronous writes & reset
    // -----------------------------------------------------------------
    always_ff @(posedge clk or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            reg_a   <= '0;
            reg_b   <= '0;
            reg_c   <= '0;
            reg_d   <= '0;
            ctrl_go <= 1'b0;
        end
        else if (wb_we_i) begin
            case (wb_addr_i)
                `ACCELERATOR_REG_CTRL : ctrl_go <= wb_dat_i[0];
                `ACCELERATOR_REG_A    : reg_a   <= wb_dat_i;
                `ACCELERATOR_REG_B    : reg_b   <= wb_dat_i;
                `ACCELERATOR_REG_C    : reg_c   <= wb_dat_i;
                `ACCELERATOR_REG_D    : reg_d   <= wb_dat_i;
                default               : ;
            endcase
        end
    end

    assign go = ctrl_go;

endmodule
