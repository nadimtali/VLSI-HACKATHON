/*
 * RISC-V Hackathon - Preparation Assignment 2
 * Wishbone BFM testbench for the 8-element dot-product accelerator
 * Team: Idan Kaynan & Nadim Tali
 */

module wishbone_accelerator_tb;
`include "wishbone_accelerator_tb_include.svh"

    always #5 wb_clk <= ~wb_clk;
    initial #100 wb_rst <= 0;

    accelerator_top accelerator_top (
        .wb_clk_i (wb_clk),
        .wb_rst_i (wb_rst),
        .wb_adr_i (wb_m2s_addr),
        .wb_dat_i (wb_m2s_data),
        .wb_dat_o (wb_s2m_data),
        .wb_we_i  (wb_m2s_we),
        .wb_stb_i (wb_m2s_stb),
        .wb_cyc_i (wb_m2s_cyc),
        .wb_sel_i (wb_m2s_sel),
        .wb_ack_o (wb_s2m_ack),
        .int_o    (wb_s2m_inta)
    );

    /* Wait for Done bit (bit31 of Control). Polls every few cycles. */
    task automatic wait_done();
        logic [31:0] rd;
        rd = 32'h0;
        while (rd[31] == 1'b0) begin
            wb_read(`ACCELERATOR_REG_CTRL);
            rd = wb_s2m_data;
            repeat (2) @(posedge wb_clk);
        end
    endtask

    initial begin
        $display("============== Test start ==============");

        @(negedge wb_rst);
        repeat (5) @(posedge wb_clk);

        /* -----------------------------------------------------------
         * Test 1 : known small vectors
         *   A = [1, 2, 3, 4]      B = [5, 6, 7, 8]
         *   C = [9,10,11,12]      D = [13,14,15,16]
         *   Expected = 1*5+2*6+3*7+4*8 + 9*13+10*14+11*15+12*16
         *            = 5+12+21+32 + 117+140+165+192
         *            = 70 + 614 = 684 (0x000002AC)
         * --------------------------------------------------------- */
        wb_write(`ACCELERATOR_REG_A, 32'h04030201);
        wb_write(`ACCELERATOR_REG_B, 32'h08070605);
        wb_write(`ACCELERATOR_REG_C, 32'h0C0B0A09);
        wb_write(`ACCELERATOR_REG_D, 32'h100F0E0D);

        wb_write(`ACCELERATOR_REG_CTRL, 32'h00000001);  // Go
        wait_done();
        wb_read (`ACCELERATOR_REG_RESULT);              // expect 684
        wb_write(`ACCELERATOR_REG_CTRL, 32'h00000000);  // clear Go

        repeat (5) @(posedge wb_clk);

        /* -----------------------------------------------------------
         * Test 2 : first element of the matrix product (A_mat[0]).(B_col0)
         *   A_mat[0] = [53, 24, 92, 10, 49, 99, 15, 72]
         *   B_col0   = [30, 28, 50,  8,  4, 95,  7, 99]
         *   Expected = 53*30+24*28+92*50+10*8 + 49*4+99*95+15*7+72*99
         *            = 1590+672+4600+80 + 196+9405+105+7128
         *            = 6942 + 16834 = 23776 (0x00005CE0)
         * --------------------------------------------------------- */
        wb_write(`ACCELERATOR_REG_A, 32'h0A5C1835);   // {10,92,24,53}
        wb_write(`ACCELERATOR_REG_B, 32'h0832_1C1E);   // {8,50,28,30}
        wb_write(`ACCELERATOR_REG_C, 32'h480F6331);   // {72,15,99,49}
        wb_write(`ACCELERATOR_REG_D, 32'h63075F04);   // {99,7,95,4}

        wb_write(`ACCELERATOR_REG_CTRL, 32'h00000001);
        wait_done();
        wb_read (`ACCELERATOR_REG_RESULT);            // expect 23776
        wb_write(`ACCELERATOR_REG_CTRL, 32'h00000000);

        repeat (10) @(posedge wb_clk);
        $display("============== Test complete ==============");
        $finish;
    end

endmodule
