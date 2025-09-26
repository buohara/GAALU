module fpga_test_wrapper #(
    parameter NUM_TESTS = 100
)
(
    input  logic        clk,
    input  logic        rst_n,
    input  logic        start,
    output logic        done,
    output logic [31:0] pass_count,
    output logic [31:0] fail_count,
    input  logic        mem_we,
    input  logic [31:0] mem_addr,
    input  logic [31:0] mem_wdata,
    output logic [31:0] mem_rdata
);
import ga_pkg::*;

    logic [1023:0] test_inputs_mem  [0:NUM_TESTS-1];
    logic [511:0]  test_outputs_mem [0:NUM_TESTS-1];
    logic [3:0]    test_control_mem [0:NUM_TESTS-1];
    logic [511:0]  actual_results   [0:NUM_TESTS-1];
    
    typedef enum logic [2:0] 
    {
        IDLE, LOAD_TEST, EXECUTE, COMPARE, NEXT_TEST, DONE
    } test_state_t;
    
    test_state_t state;
    logic [31:0] test_index;
    logic [31:0] pass_cnt, fail_cnt;
    
    ga_req_t  ga_req;
    ga_resp_t ga_resp;
    
    ga_alu_even u_ga_alu (
        .clk_i      (clk),
        .rst_ni     (rst_n),
        .operand_a_i(ga_req.operand_a),
        .operand_b_i(ga_req.operand_b), 
        .operation_i(ga_req.funct),
        .valid_i    (ga_req.valid),
        .ready_o    (ga_resp.ready),
        .result_o   (ga_resp.result),
        .valid_o    (ga_resp.valid),
        .error_o    (ga_resp.error)
    );

    always_ff @(posedge clk) begin

        if (mem_we) begin

            case (mem_addr[31:28])
                4'h0: test_inputs_mem[mem_addr[15:0]][mem_addr[27:16]*32 +: 32] <= mem_wdata;
                4'h1: test_outputs_mem[mem_addr[15:0]][mem_addr[27:16]*32 +: 32] <= mem_wdata;
                4'h2: test_control_mem[mem_addr[15:0]] <= mem_wdata[3:0];
            endcase

        end
    end
    
    function bit check_tolerance(logic [511:0] actual, logic [511:0] expected, int max_diff);

      logic [15:0] actual_component, expected_component;
      logic signed [15:0] actual_signed, expected_signed;
      int abs_diff;
      
      for (int i = 0; i < 32; i++) begin

        actual_component    = actual[i*16 +: 16];
        expected_component  = expected[i*16 +: 16];
        
        actual_signed       = $signed(actual_component);
        expected_signed     = $signed(expected_component);
        
        abs_diff = (actual_signed > expected_signed) ? 
                  (32'(actual_signed) - 32'(expected_signed)) : 
                  (32'(expected_signed) - 32'(actual_signed));
        
        if (abs_diff > max_diff) begin

          return 1'b0;

        end

      end
      
      return 1'b1;

    endfunction

    always_ff @(posedge clk or negedge rst_n) begin
        
        if (!rst_n) begin

            state <= IDLE;
            test_index <= 0;
            pass_cnt <= 0;
            fail_cnt <= 0;
            ga_req <= '0;

        end else begin
            case (state)
                IDLE: begin

                    if (start) begin
                        state <= LOAD_TEST;
                        test_index <= 0;
                        pass_cnt <= 0;
                        fail_cnt <= 0;
                    end
                end
                
                LOAD_TEST: begin

                    ga_req.valid <= 1'b1;
                    ga_req.operand_a <= test_inputs_mem[test_index][1023:512];
                    ga_req.operand_b <= test_inputs_mem[test_index][511:0];
                    ga_req.funct <= ga_funct_e'(test_control_mem[test_index]);
                    state <= EXECUTE;
                    
                end
                
                EXECUTE: begin

                    if (ga_resp.valid) begin
                        actual_results[test_index] <= ga_resp.result;
                        ga_req.valid <= 1'b0;
                        state <= COMPARE;
                    end
                end
                
                COMPARE: begin

                    if (check_tolerance(ga_resp.result, test_outputs_mem[test_index], 100))
                        pass_cnt <= pass_cnt + 1;
                    else
                        fail_cnt <= fail_cnt + 1;
                    state <= NEXT_TEST;
                end
                
                NEXT_TEST: begin

                    if (test_index < NUM_TESTS - 1) begin
                        test_index <= test_index + 1;
                        state <= LOAD_TEST;
                    end else begin
                        state <= DONE;
                    end
                end
                
                DONE: begin

                end
            endcase
        end
    end
    
    assign done = (state == DONE);
    assign pass_count = pass_cnt;
    assign fail_count = fail_cnt;

endmodule