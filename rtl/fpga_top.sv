module fpga_top (
    input  logic        clk_100mhz,
    input  logic        reset_btn,
    input  logic        start_btn,
    output logic [7:0]  leds,
    input  logic        uart_rx,
    output logic        uart_tx
);

    logic clk, rst_n;
    logic pll_locked;
    
    assign rst_n = pll_locked & ~reset_btn;
    
    clk_wiz u_clk_wiz (
        .clk_in1  (clk_100mhz),
        .clk_out1 (clk),
        .locked   (pll_locked)
    );
    
    logic        test_start, test_done;
    logic [31:0] pass_count, fail_count;
    
    logic        mem_we;
    logic [31:0] mem_addr, mem_wdata, mem_rdata;
    
    fpga_test_wrapper u_test_wrapper (
        .clk        (clk),
        .rst_n      (rst_n),
        .start      (test_start),
        .done       (test_done),
        .pass_count (pass_count),
        .fail_count (fail_count),
        .mem_we     (mem_we),
        .mem_addr   (mem_addr),
        .mem_wdata  (mem_wdata),
        .mem_rdata  (mem_rdata)
    );
    
    uart_controller u_uart_ctrl (
        .clk         (clk),
        .rst_n       (rst_n),
        .uart_rx     (uart_rx),
        .uart_tx     (uart_tx),
        .test_start  (test_start),
        .test_done   (test_done),
        .pass_count  (pass_count),
        .fail_count  (fail_count),
        .mem_we      (mem_we),
        .mem_addr    (mem_addr),
        .mem_wdata   (mem_wdata),
        .mem_rdata   (mem_rdata)
    );
    
    assign leds = {test_done, 3'b0, fail_count[3:0]};

endmodule