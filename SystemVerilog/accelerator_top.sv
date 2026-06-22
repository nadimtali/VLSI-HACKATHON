//////////////////////////////////////////////////////////////////////
////  accelerator_top.sv                                          ////
////  RISC-V Hackathon - Preparation Assignment 2                 ////
////  8-element dot-product accelerator                           ////
////  Team: Idan Kaynan & Nadim Tali                              ////
////  Based on original by Alex Grinshpun (2023)                  ////
////  Provided AS IS without any warranty                         ////
//////////////////////////////////////////////////////////////////////

module accelerator_top (

    input               wb_clk_i,

    // WISHBONE interface
    input  logic        wb_rst_i,
    input  logic        wb_stb_i,
    input  logic [2:0]  wb_cti_i,
    input  logic [1:0]  wb_bte_i,
    input  logic        wb_cyc_i,
    input  logic [3:0]  wb_sel_i,
    input  logic        wb_we_i,
    input  logic [7:0]  wb_adr_i,
    input  logic [31:0] wb_dat_i,
    output logic [31:0] wb_dat_o,

    output logic        wb_ack_o,
    output logic        wb_err_o,
    output logic        wb_rty_o,
    output logic        int_o
);

    parameter SIM   = 0;
    parameter debug = 0;

    // Internal nets
    logic [31:0] wb_data_reg_out;
    logic [31:0] wb_data_reg_in;
    logic [7:0]  wb_adr_int;
    logic        we_o;
    logic        re_o;

    logic        go;
    logic        done;
    logic [31:0] reg_a;
    logic [31:0] reg_b;
    logic [31:0] reg_c;
    logic [31:0] reg_d;
    logic [31:0] reg_result;

    assign int_o = 1'b0;

`ifndef XSIM
    ila_accelerator ila_accelerator (
        .clk    (wb_clk_i),
        .probe0 (we_o),
        .probe1 (re_o),
        .probe2 (wb_adr_int),
        .probe3 (wb_data_reg_out),
        .probe4 (wb_data_reg_in),
        .probe5 (reg_a),
        .probe6 (reg_b),
        .probe7 (reg_c),
        .probe8 (reg_d),
        .probe9 (reg_result),
        .probe10({30'h0, done, go})
    );
`endif

    //
    // MODULE INSTANCES
    //

    // WISHBONE interface
    accelerator_wb wb_interface (
        .clk             (wb_clk_i),
        .wb_rst_i        (wb_rst_i),

        .wb_we_i         (wb_we_i),
        .wb_stb_i        (wb_stb_i),
        .wb_cti_i        (wb_cti_i),
        .wb_bte_i        (wb_bte_i),
        .wb_cyc_i        (wb_cyc_i),
        .wb_ack_o        (wb_ack_o),
        .wb_sel_i        (4'b0),
        .wb_adr_i        (wb_adr_i),
        .wb_dat_i        (wb_dat_i),
        .wb_dat_o        (wb_dat_o),
        .wb_err_o        (wb_err_o),
        .wb_rty_o        (wb_rty_o),

        .wb_adr_reg      (wb_adr_int),
        .wb_data_reg_in  (wb_data_reg_in),
        .wb_data_reg_out (wb_data_reg_out),
        .we_o            (we_o),
        .re_o            (re_o)
    );

    // Register file
    accelerator_regs regs (
        .clk        (wb_clk_i),
        .wb_rst_i   (wb_rst_i),

        .wb_addr_i  (wb_adr_int),
        .wb_dat_i   (wb_data_reg_out),
        .wb_dat_o   (wb_data_reg_in),
        .wb_we_i    (we_o),
        .wb_re_i    (re_o),

        .done       (done),
        .go         (go),
        .reg_a      (reg_a),
        .reg_b      (reg_b),
        .reg_c      (reg_c),
        .reg_d      (reg_d),
        .reg_result (reg_result)
    );

    // Compute core
    accelerator accelerator (
        .clk        (wb_clk_i),
        .wb_rst_i   (wb_rst_i),

        .go         (go),
        .reg_a      (reg_a),
        .reg_b      (reg_b),
        .reg_c      (reg_c),
        .reg_d      (reg_d),

        .done       (done),
        .reg_result (reg_result)
    );

endmodule
