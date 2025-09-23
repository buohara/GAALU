module uart_controller #(
    parameter CLOCK_FREQ = 100_000_000,
    parameter BAUD_RATE  = 115_200
) (
    input  logic        clk,
    input  logic        rst_n,
    
    input  logic        uart_rx,
    output logic        uart_tx,
    
    output logic        test_start,
    input  logic        test_done,
    input  logic [31:0] pass_count,
    input  logic [31:0] fail_count,
    
    output logic        mem_we,
    output logic [31:0] mem_addr,
    output logic [31:0] mem_wdata,
    input  logic [31:0] mem_rdata
);

    localparam CLKS_PER_BIT     = CLOCK_FREQ / BAUD_RATE;
    localparam BIT_TIMER_WIDTH  = $clog2(CLKS_PER_BIT);
    
    logic [2:0]                 rx_state;
    logic [BIT_TIMER_WIDTH-1:0] rx_clk_count;
    logic [2:0]                 rx_bit_index;
    logic [7:0]                 rx_data_reg;
    logic                       rx_data_valid;
    logic [7:0]                 rx_byte;
    
    logic [2:0]                 tx_state;
    logic [BIT_TIMER_WIDTH-1:0] tx_clk_count;
    logic [2:0]                 tx_bit_index;
    logic [7:0]                 tx_data_reg;
    logic                       tx_active;
    logic                       tx_start;
    logic [7:0]                 tx_byte;
    
    typedef enum logic [2:0] {
        CMD_IDLE,
        CMD_WRITE_ADDR,
        CMD_WRITE_DATA, 
        CMD_READ_ADDR,
        CMD_EXECUTE
    } cmd_state_t;
    
    cmd_state_t cmd_state;
    logic [7:0] cmd_type;
    logic [31:0] cmd_addr_reg;
    logic [31:0] cmd_data_reg;
    logic [1:0] byte_count;
        
    localparam RX_IDLE       = 3'd0;
    localparam RX_START_BIT  = 3'd1;
    localparam RX_DATA_BITS  = 3'd2;
    localparam RX_STOP_BIT   = 3'd3;
    localparam RX_CLEANUP    = 3'd4;
    
    always_ff @(posedge clk or negedge rst_n) begin

        if (!rst_n) begin

            rx_state <= RX_IDLE;
            rx_clk_count <= 0;
            rx_bit_index <= 0;
            rx_data_reg <= 0;
            rx_data_valid <= 1'b0;

        end else begin
            
            rx_data_valid <= 1'b0;
            
            case (rx_state)
                
                RX_IDLE: begin

                    rx_clk_count <= 0;
                    rx_bit_index <= 0;
                    
                    if (uart_rx == 1'b0) begin
                        rx_state <= RX_START_BIT;
                    end

                end
                
                RX_START_BIT: begin

                    if (rx_clk_count == (CLKS_PER_BIT-1)/2) begin
                        if (uart_rx == 1'b0) begin
                            rx_clk_count <= 0;
                            rx_state <= RX_DATA_BITS;
                        end else begin
                            rx_state <= RX_IDLE;
                        end
                    end else begin
                        rx_clk_count <= rx_clk_count + 1;
                    end

                end
                
                RX_DATA_BITS: begin

                    if (rx_clk_count < CLKS_PER_BIT-1) begin
                        rx_clk_count <= rx_clk_count + 1;
                    end else begin
                        rx_clk_count <= 0;
                        rx_data_reg[rx_bit_index] <= uart_rx;
                        
                        if (rx_bit_index < 7) begin
                            rx_bit_index <= rx_bit_index + 1;
                        end else begin
                            rx_bit_index <= 0;
                            rx_state <= RX_STOP_BIT;
                        end
                    end

                end
                
                RX_STOP_BIT: begin

                    if (rx_clk_count < CLKS_PER_BIT-1) begin
                        rx_clk_count <= rx_clk_count + 1;
                    end else begin
                        rx_clk_count <= 0;
                        rx_data_valid <= 1'b1;
                        rx_state <= RX_CLEANUP;
                    end

                end
                
                RX_CLEANUP: begin

                    rx_state <= RX_IDLE;

                end
                
                default: begin

                    rx_state <= RX_IDLE;

                end
            endcase
        end
    end
    
    assign rx_byte = rx_data_reg;
    
    localparam TX_IDLE       = 3'd0;
    localparam TX_START_BIT  = 3'd1;
    localparam TX_DATA_BITS  = 3'd2;
    localparam TX_STOP_BIT   = 3'd3;
    localparam TX_CLEANUP    = 3'd4;
    
    always_ff @(posedge clk or negedge rst_n) begin

        if (!rst_n) begin

            tx_state <= TX_IDLE;
            tx_clk_count <= 0;
            tx_bit_index <= 0;
            tx_data_reg <= 0;
            uart_tx <= 1'b1;
            tx_active <= 1'b0;

        end else begin
            
            case (tx_state)
                
                TX_IDLE: begin

                    uart_tx <= 1'b1;
                    tx_clk_count <= 0;
                    tx_bit_index <= 0;
                    tx_active <= 1'b0;
                    
                    if (tx_start == 1'b1) begin
                        tx_active <= 1'b1;
                        tx_data_reg <= tx_byte;
                        tx_state <= 
                        TX_START_BIT;
                    end

                end
                
                TX_START_BIT: begin

                    uart_tx <= 1'b0;
                    
                    if (tx_clk_count < CLKS_PER_BIT-1) begin
                        tx_clk_count <= tx_clk_count + 1;
                    end else begin
                        tx_clk_count <= 0;
                        tx_state <= TX_DATA_BITS;
                    end

                end
                
                TX_DATA_BITS: begin

                    uart_tx <= tx_data_reg[tx_bit_index];
                    
                    if (tx_clk_count < CLKS_PER_BIT-1) begin
                        tx_clk_count <= tx_clk_count + 1;
                    end else begin
                        tx_clk_count <= 0;
                        
                        if (tx_bit_index < 7) begin
                            tx_bit_index <= tx_bit_index + 1;
                        end else begin
                            tx_bit_index <= 0;
                            tx_state <= TX_STOP_BIT;
                        end
                    end

                end
                
                TX_STOP_BIT: begin

                    uart_tx <= 1'b1;
                    
                    if (tx_clk_count < CLKS_PER_BIT-1) begin
                        tx_clk_count <= tx_clk_count + 1;
                    end else begin
                        tx_clk_count <= 0;
                        tx_state <= TX_CLEANUP;
                    end

                end
                
                TX_CLEANUP: begin

                    tx_active <= 1'b0;
                    tx_state <= TX_IDLE;

                end
                
                default: begin

                    tx_state <= TX_IDLE;

                end

            endcase
        end
    end
    
    always_ff @(posedge clk or negedge rst_n) begin

        if (!rst_n) begin

            cmd_state       <= CMD_IDLE;
            cmd_type        <= 8'h00;
            cmd_addr_reg    <= 32'h00000000;
            cmd_data_reg    <= 32'h00000000;
            byte_count      <= 2'b00;
            mem_we          <= 1'b0;
            mem_addr        <= 32'h00000000;
            mem_wdata       <= 32'h00000000;
            test_start      <= 1'b0;
            tx_start        <= 1'b0;
            tx_byte         <= 8'h00;

        end else begin

            mem_we          <= 1'b0;
            test_start      <= 1'b0;
            tx_start        <= 1'b0;

            case (cmd_state)
                
                CMD_IDLE: begin

                    if (rx_data_valid) begin
                        cmd_type <= rx_byte;
                        byte_count <= 2'b00;
                        
                        case (rx_byte)
                        
                            8'h57: begin
                                cmd_state <= CMD_WRITE_ADDR;
                            end

                            8'h52: begin
                                cmd_state <= CMD_READ_ADDR;
                            end

                            8'h53: begin
                                test_start <= 1'b1;
                                cmd_state <= CMD_EXECUTE;
                            end

                            8'h44: begin
                                tx_byte <= test_done ? 8'h31 : 8'h30;
                                tx_start <= 1'b1;
                                cmd_state <= CMD_EXECUTE;
                            end

                            8'h50: begin
                                cmd_data_reg <= pass_count;
                                byte_count <= 2'b00;
                                cmd_state <= CMD_EXECUTE;
                            end

                            8'h46: begin
                                cmd_data_reg <= fail_count;
                                byte_count <= 2'b00;
                                cmd_state <= CMD_EXECUTE;
                            end

                            default: begin
                                
                                tx_byte <= 8'h4E;  // 'N'
                                tx_start <= 1'b1;
                                cmd_state <= CMD_EXECUTE;
                            end

                        endcase
                    end
                end
                
                CMD_WRITE_ADDR: begin

                    if (rx_data_valid) begin

                        case (byte_count)
                            2'b00: cmd_addr_reg[7:0]   <= rx_byte;
                            2'b01: cmd_addr_reg[15:8]  <= rx_byte;
                            2'b10: cmd_addr_reg[23:16] <= rx_byte;
                            2'b11: cmd_addr_reg[31:24] <= rx_byte;
                        endcase
                        
                        if (byte_count == 2'b11) begin

                            byte_count <= 2'b00;
                            cmd_state <= CMD_WRITE_DATA;

                        end else begin
                            byte_count <= byte_count + 1;
                        end
                    end
                end
                
                CMD_WRITE_DATA: begin

                    if (rx_data_valid) begin

                        case (byte_count)

                            2'b00: cmd_data_reg[7:0]   <= rx_byte;
                            2'b01: cmd_data_reg[15:8]  <= rx_byte;
                            2'b10: cmd_data_reg[23:16] <= rx_byte;
                            2'b11: cmd_data_reg[31:24] <= rx_byte;

                        endcase
                        
                        if (byte_count == 2'b11) begin
                            
                            mem_addr    <= cmd_addr_reg;
                            mem_wdata   <= {rx_byte, cmd_data_reg[23:0]};
                            mem_we      <= 1'b1;

                            tx_byte     <= 8'h4B;
                            tx_start    <= 1'b1;
                            cmd_state   <= CMD_EXECUTE;

                        end else begin
                            byte_count <= byte_count + 1;
                        end
                    end
                end
                
                CMD_READ_ADDR: begin

                    if (rx_data_valid) begin

                        case (byte_count)
                            2'b00: cmd_addr_reg[7:0]   <= rx_byte;
                            2'b01: cmd_addr_reg[15:8]  <= rx_byte;
                            2'b10: cmd_addr_reg[23:16] <= rx_byte;
                            2'b11: cmd_addr_reg[31:24] <= rx_byte;
                        endcase
                        
                        if (byte_count == 2'b11) begin
                            
                            mem_addr <= cmd_addr_reg;
                            cmd_data_reg <= mem_rdata;
                            byte_count <= 2'b00;
                            cmd_state <= CMD_EXECUTE;

                        end else begin
                            byte_count <= byte_count + 1;
                        end
                    end
                end
                
                CMD_EXECUTE: begin

                    if (!tx_active) begin

                        case (cmd_type)

                            8'h50, 8'h46: begin

                                if (byte_count < 2'b11) begin

                                    case (byte_count)

                                        2'b00: tx_byte <= cmd_data_reg[7:0];
                                        2'b01: tx_byte <= cmd_data_reg[15:8];
                                        2'b10: tx_byte <= cmd_data_reg[23:16];
                                        2'b11: tx_byte <= cmd_data_reg[31:24];

                                    endcase

                                    tx_start    <= 1'b1;
                                    byte_count  <= byte_count + 1;

                                end else begin
                                    cmd_state   <= CMD_IDLE;
                                end

                            end

                            8'h52: begin

                                if (byte_count < 2'b11) begin

                                    case (byte_count)

                                        2'b00: tx_byte <= mem_rdata[7:0];
                                        2'b01: tx_byte <= mem_rdata[15:8];
                                        2'b10: tx_byte <= mem_rdata[23:16];
                                        2'b11: tx_byte <= mem_rdata[31:24];

                                    endcase
                                    
                                    tx_start    <= 1'b1;
                                    byte_count  <= byte_count + 1;

                                end else begin
                                    cmd_state <= CMD_IDLE;
                                end
                            end

                            default: begin
                                cmd_state <= CMD_IDLE;
                            end

                        endcase
                    end
                end
                
            endcase
        end
    end

endmodule