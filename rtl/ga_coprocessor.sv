module ga_coprocessor 
  import ga_pkg::*;
#(
  parameter int unsigned GARegFileSize  = 32
) (
  input  logic           clk_i,
  input  logic           rst_ni,
  input  ga_req_t        ga_req_i,
  output ga_resp_t       ga_resp_o,
  output logic           ga_debug_req_o,
  input  logic           ga_debug_we_i,
  input  logic [4:0]     ga_debug_addr_i,
  input  logic [31:0]    ga_debug_wdata_i,
  output logic [31:0]    ga_debug_rdata_o,
  output ga_perf_counters_t ga_perf_o
);
  logic                           ga_rf_we;
  logic [GA_REG_ADDR_WIDTH-1:0]   ga_rf_waddr;
  logic [GA_REG_ADDR_WIDTH-1:0]   ga_rf_raddr_a;
  logic [GA_REG_ADDR_WIDTH-1:0]   ga_rf_raddr_b;

  ga_multivector_t                ga_rf_wdata;
  ga_multivector_t                ga_rf_rdata_a;
  ga_multivector_t                ga_rf_rdata_b;

  ga_multivector_t                ga_alu_operand_a;
  ga_multivector_t                ga_alu_operand_b;
  ga_multivector_t                ga_alu_result;
  ga_funct_e                      ga_alu_op;
  logic                           ga_alu_valid;
  logic                           ga_alu_ready;
  logic                           ga_alu_valid_o;
  logic                           ga_alu_error;

  typedef enum logic [2:0]
  {
    GA_IDLE,
    GA_DECODE,
    GA_READ_REGS,
    GA_EXECUTE,
    GA_WRITE_BACK,
    GA_HOLD_VALID,
    GA_ERROR
  } ga_state_e;

  ga_state_e ga_state_q, ga_state_d;

  ga_req_t            ga_req_q;
  logic               ga_req_valid_q;
  ga_multivector_t    ga_result_q;
  ga_perf_counters_t  ga_perf_q, ga_perf_d;

  always_ff @(posedge clk_i or negedge rst_ni) begin

    if (!rst_ni) begin
      
      ga_state_q      <= GA_IDLE;
      ga_req_q        <= '0;
      ga_req_valid_q  <= 1'b0;
      ga_result_q     <= '0;
      ga_perf_q       <= '0;
    
    end else begin
      
      ga_state_q      <= ga_state_d;
      ga_perf_q       <= ga_perf_d;
      
      if (ga_req_i.valid && ga_resp_o.ready) begin
        
        ga_req_q       <= ga_req_i;
        ga_req_valid_q <= 1'b1;

      end
      
      if (ga_state_q == GA_WRITE_BACK) begin

        ga_result_q <= ga_alu_result;

      end

    end

  end

  always_comb begin

    ga_state_d          = ga_state_q;
    ga_perf_d           = ga_perf_q;
    ga_alu_valid        = 1'b0;
    ga_rf_we            = 1'b0;

    ga_resp_o.ready     = 1'b1;
    ga_resp_o.valid     = 1'b0;
    ga_resp_o.result    = '0;
    ga_resp_o.error     = 1'b0;
    ga_resp_o.busy      = 1'b0;
    ga_resp_o.overflow  = 1'b0;
    ga_resp_o.underflow = 1'b0;

    case (ga_state_q)

      GA_IDLE: begin
        
        if (ga_req_i.valid) begin

          ga_state_d              = GA_DECODE;
          ga_perf_d.ga_ops_total  = ga_perf_q.ga_ops_total + 1;

        end

      end

      GA_DECODE: begin

        ga_resp_o.busy = 1'b1;

        case (ga_req_q.funct)

          GA_FUNCT_ADD, GA_FUNCT_SUB: begin

            ga_perf_d.ga_ops_add  = ga_perf_q.ga_ops_add + 1;
            ga_state_d            = GA_EXECUTE;

          end

          GA_FUNCT_MUL, GA_FUNCT_WEDGE, GA_FUNCT_DOT: begin

            ga_perf_d.ga_ops_mul  = ga_perf_q.ga_ops_mul + 1;
            ga_state_d            = GA_EXECUTE;

          end

          GA_FUNCT_LOAD, GA_FUNCT_STORE: begin

            ga_state_d = GA_EXECUTE;

          end

          GA_FUNCT_DUAL, GA_FUNCT_REV, GA_FUNCT_NORM: begin

            ga_state_d = GA_EXECUTE;
            
          end

          default: begin

            ga_state_d = GA_ERROR;

          end

        endcase

      end

      GA_READ_REGS: begin

        ga_resp_o.busy  = 1'b1;
        ga_state_d      = GA_EXECUTE;

      end

      GA_EXECUTE: begin

        ga_resp_o.busy  = 1'b1;
        ga_alu_valid    = 1'b1;
        
        if (ga_alu_ready) begin

          if (ga_alu_error) begin
            ga_state_d  = GA_ERROR;

          end else begin
            ga_state_d  = GA_WRITE_BACK;

          end

        end
        
        ga_perf_d.ga_cycles_busy = ga_perf_q.ga_cycles_busy + 1;

      end

      GA_WRITE_BACK: begin

        if (ga_alu_valid_o) begin

          ga_resp_o.valid  = 1'b1;
          ga_resp_o.result = ga_alu_result;
          ga_resp_o.busy   = 1'b0;

          if (ga_req_q.we) begin
            ga_rf_we = 1'b1;
          end
          
          if (!ga_req_i.valid) begin
            ga_state_d = GA_IDLE;
          end

        end

      end

      GA_ERROR: begin

        ga_resp_o.valid = 1'b1;
        ga_resp_o.error = 1'b1;
        ga_state_d      = GA_IDLE;

      end

      default: begin

        ga_state_d = GA_IDLE;

      end

    endcase

  end

  assign ga_rf_raddr_a = ga_req_q.ga_reg_a[GA_REG_ADDR_WIDTH-1:0];
  assign ga_rf_raddr_b = ga_req_q.ga_reg_b[GA_REG_ADDR_WIDTH-1:0];
  assign ga_rf_waddr   = ga_req_q.rd_addr[GA_REG_ADDR_WIDTH-1:0];
  assign ga_rf_wdata   = ga_alu_result;

  ga_register_file #(
    .NumRegs(GARegFileSize),
    .DataWidth($bits(ga_multivector_t))
  ) u_ga_register_file (
    .clk_i       (clk_i),
    .rst_ni      (rst_ni),
    .we_i        (ga_rf_we),
    .waddr_i     (ga_rf_waddr),
    .wdata_i     (ga_rf_wdata),
    .raddr_a_i   (ga_rf_raddr_a),
    .raddr_b_i   (ga_rf_raddr_b),
    .rdata_a_o   (ga_rf_rdata_a),
    .rdata_b_o   (ga_rf_rdata_b)
  );

  always_comb begin

    if (ga_req_q.use_ga_regs) begin

      ga_alu_operand_a = ga_rf_rdata_a;
      ga_alu_operand_b = ga_rf_rdata_b;

    end else begin

      ga_alu_operand_a = '0;
      ga_alu_operand_b = '0;

      ga_alu_operand_a = ga_req_q.operand_a;
      ga_alu_operand_b = ga_req_q.operand_b;

    end

  end

  assign ga_alu_op = ga_req_q.funct;

generate

  if (ga_pkg::GA_USE_EVEN) begin : g_even_alu

    initial $display("Even GA ALU in progress.");

    ga_alu_even u_ga_alu_even 
    (
      .clk_i          (clk_i),
      .rst_ni         (rst_ni),
      .operand_a_i    (ga_alu_operand_a),
      .operand_b_i    (ga_alu_operand_b),
      .operation_i    (ga_alu_op),
      .valid_i        (ga_alu_valid),
      .ready_o        (ga_alu_ready),
      .valid_o        (ga_alu_valid_o),
      .result_o       (ga_alu_result),
      .error_o        (ga_alu_error)
    );

  end else begin : g_full_alu

    ga_alu u_ga_alu 
    (
      .clk_i          (clk_i),
      .rst_ni         (rst_ni),
      .operand_a_i    (ga_alu_operand_a),
      .operand_b_i    (ga_alu_operand_b),
      .operation_i    (ga_alu_op),
      .valid_i        (ga_alu_valid),
      .ready_o        (ga_alu_ready),
      .valid_o        (ga_alu_valid_o),
      .result_o       (ga_alu_result),
      .error_o        (ga_alu_error)
    );

  end

endgenerate

  assign ga_debug_req_o     = 1'b0;
  assign ga_debug_rdata_o   = '0;
  assign ga_perf_o          = ga_perf_q;

  `ifdef ASSERT_ON

    assert property (@(posedge clk_i) disable iff (!rst_ni)
      (ga_req_i.valid |-> ga_req_i.ga_reg_a < GARegFileSize))
      else $error("GA register A address out of bounds");
      
    assert property (@(posedge clk_i) disable iff (!rst_ni)
      (ga_req_i.valid |-> ga_req_i.ga_reg_b < GARegFileSize))
      else $error("GA register B address out of bounds");

  `endif

endmodule
