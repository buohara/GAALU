/**
 * Geometric Algebra Arithmetic Logic Unit
 * 
 * This module implements the core arithmetic operations for geometric algebra
 * including geometric product, outer product, inner product, and other GA operations.
 */

module ga_alu
  import ga_pkg::*;
(
  input  logic                clk_i,
  input  logic                rst_ni,
  input  ga_multivector_t     operand_a_i,
  input  ga_multivector_t     operand_b_i,
  input  ga_funct_e           operation_i,
  input  logic                valid_i,
  output logic                ready_o,
  output ga_multivector_t     result_o,
  output logic                valid_o,
  output logic                error_o
);
  typedef enum logic [1:0]
  {
    ALU_IDLE,
    ALU_COMPUTE,
    ALU_DONE
  } alu_state_e;

  alu_state_e alu_state_q, alu_state_d;
  ga_multivector_t result_d, result_q;
  logic error_d, error_q;

  ga_multivector_t a_d, a_q;
  ga_multivector_t b_d, b_q;
  ga_funct_e       op_d, op_q;

  always_ff @(posedge clk_i or negedge rst_ni) begin
    
    if (!rst_ni) begin

      alu_state_q <= ALU_IDLE;
      result_q    <= '0;
      error_q     <= 1'b0;
      a_q         <= '0;
      b_q         <= '0;
      op_q        <= ga_funct_e'('0);

    end else begin
      
      alu_state_q <= alu_state_d;
      result_q    <= result_d;
      error_q     <= error_d;
      a_q         <= a_d;
      b_q         <= b_d;
      op_q        <= op_d;

    end

  end

  always_comb begin

    alu_state_d = alu_state_q;
    result_d    = result_q;
    error_d     = error_q;
    ready_o     = 1'b0;
    valid_o     = 1'b0;
    a_d         = a_q;
    b_d         = b_q;
    op_d        = op_q;

    case (alu_state_q)

      ALU_IDLE: begin

        ready_o = 1'b1;

        if (valid_i) begin
          
          alu_state_d = ALU_COMPUTE;
          error_d     = 1'b0;
          valid_o     = 1'b0;
          a_d         = operand_a_i;
          b_d         = operand_b_i;
          op_d        = operation_i;

        end

      end

      ALU_COMPUTE: begin

        result_d    = computeGaOperation(a_q, b_q, op_q);
        alu_state_d = ALU_DONE;

      end

      ALU_DONE: begin

        valid_o     = 1'b1;
        alu_state_d = ALU_IDLE;

      end

      default: begin

        alu_state_d = ALU_IDLE;

      end
    endcase
  end

  function automatic ga_multivector_t computeGaOperation(
    ga_multivector_t a,
    ga_multivector_t b,
    ga_funct_e op
  );
    ga_multivector_t result;
    result = '0;

    case (op)

      GA_FUNCT_ADD: begin

        result.scalar       = a.scalar + b.scalar;
        result.e1           = a.e1 + b.e1;
        result.e2           = a.e2 + b.e2;
        result.e3           = a.e3 + b.e3;
        result.eo           = a.eo + b.eo;
        result.ei           = a.ei + b.ei;
        result.e12          = a.e12 + b.e12;
        result.e13          = a.e13 + b.e13;
        result.e23          = a.e23 + b.e23;
        result.e1o          = a.e1o + b.e1o;
        result.e2o          = a.e2o + b.e2o;
        result.e3o          = a.e3o + b.e3o;
        result.e1i          = a.e1i + b.e1i;
        result.e2i          = a.e2i + b.e2i;
        result.e3i          = a.e3i + b.e3i;
        result.eoi          = a.eoi + b.eoi;
        result.e123         = a.e123 + b.e123;
        result.e12o         = a.e12o + b.e12o;
        result.e13o         = a.e13o + b.e13o;
        result.e23o         = a.e23o + b.e23o;
        result.e12i         = a.e12i + b.e12i;
        result.e13i         = a.e13i + b.e13i;
        result.e23i         = a.e23i + b.e23i;
        result.e1oi         = a.e1oi + b.e1oi;
        result.e2oi         = a.e2oi + b.e2oi;
        result.e3oi         = a.e3oi + b.e3oi;
        result.e123o        = a.e123o + b.e123o;
        result.e123i        = a.e123i + b.e123i;
        result.e12oi        = a.e12oi + b.e12oi;
        result.e13oi        = a.e13oi + b.e13oi;
        result.e23oi        = a.e23oi + b.e23oi;
        result.e123oi       = a.e123oi + b.e123oi;

        //$display("ga_alu add: a=%128h, b=%128h, res=%128h", a, b, result);

      end

      GA_FUNCT_SUB: begin

        result.scalar      = a.scalar - b.scalar;
        result.e1          = a.e1 - b.e1;
        result.e2          = a.e2 - b.e2;
        result.e3          = a.e3 - b.e3;
        result.eo          = a.eo - b.eo;
        result.ei          = a.ei - b.ei;
        result.e12         = a.e12 - b.e12;
        result.e13         = a.e13 - b.e13;
        result.e23         = a.e23 - b.e23;
        result.e1o         = a.e1o - b.e1o;
        result.e2o         = a.e2o - b.e2o;
        result.e3o         = a.e3o - b.e3o;
        result.e1i         = a.e1i - b.e1i;
        result.e2i         = a.e2i - b.e2i;
        result.e3i         = a.e3i - b.e3i;
        result.eoi         = a.eoi - b.eoi;
        result.e123        = a.e123 - b.e123;
        result.e12o        = a.e12o - b.e12o;
        result.e13o        = a.e13o - b.e13o;
        result.e23o        = a.e23o - b.e23o;
        result.e12i        = a.e12i - b.e12i;
        result.e13i        = a.e13i - b.e13i;
        result.e23i        = a.e23i - b.e23i;
        result.e1oi        = a.e1oi - b.e1oi;
        result.e2oi        = a.e2oi - b.e2oi;
        result.e3oi        = a.e3oi - b.e3oi;
        result.e123o       = a.e123o - b.e123o;
        result.e123i       = a.e123i - b.e123i;
        result.e12oi       = a.e12oi - b.e12oi;
        result.e13oi       = a.e13oi - b.e13oi;
        result.e23oi       = a.e23oi - b.e23oi;
        result.e123oi      = a.e123oi - b.e123oi;

        //$display("ga_alu sub: a=%128h, b=%128h, res=%128h", a, b, result);

      end

      GA_FUNCT_MUL: begin
        result = geometricProduct(a, b);
      end

      GA_FUNCT_WEDGE: begin
        result = wedgeProduct(a, b);
      end

      GA_FUNCT_DOT: begin
        result = dotProduct(a, b);
      end

      GA_FUNCT_DUAL: begin
        result = dualOperation(a);
      end

      GA_FUNCT_REV: begin
        result = reverseOperation(a);
      end

      GA_FUNCT_NORM: begin
        result.scalar = normCalculation(a);
      end

      GA_FUNCT_ROTATE: begin
        result = rotorApplication(a, b);
      end

      GA_FUNCT_REFLECT: begin
        result = reflectionOperation(a, b);
      end

      default: begin
        result = '0;
      end
    endcase

    return result;

  endfunction

  localparam int FP_W     = 16;
  localparam int FP_FRAC  = 11;

  function automatic logic signed [FP_W-1:0] satN(input logic signed [FP_W:0] x);
    
    logic signed [FP_W-1:0] MAXV = {1'b0, {(FP_W-1){1'b1}}};
    logic signed [FP_W-1:0] MINV = {1'b1, {(FP_W-1){1'b0}}};
    if (x > $signed({1'b0, MAXV})) return MAXV;
    if (x < $signed({1'b1, MINV})) return MINV;
    return x[FP_W-1:0];

  endfunction

  function automatic logic signed [FP_W-1:0] addQ511(input logic signed [FP_W-1:0] a,
                                                     input logic signed [FP_W-1:0] b);
    logic signed [FP_W:0] s = a + b;
    return satN(s);

  endfunction

  function automatic logic signed [FP_W-1:0] subQ511(input logic signed [FP_W-1:0] a,
                                                     input logic signed [FP_W-1:0] b);
    logic signed [FP_W:0] s = a - b;
    return satN(s);

  endfunction

  function automatic logic signed [FP_W-1:0] mulQ511(input logic signed [FP_W-1:0] a,
                                                     input logic signed [FP_W-1:0] b);
    /* verilator no_inline_task */
    logic signed [(2*FP_W)-1:0] p = a * b;
    logic signed [(2*FP_W)-1:0] r = p + (1 <<< (FP_FRAC-1));
    logic signed [(2*FP_W)-1:0] s = r >>> FP_FRAC;
    logic signed [FP_W:0]       t = {s[FP_W-1], s[FP_W-1:0]};
    
    return satN(t);

  endfunction

  function automatic logic signed [FP_W-1:0] mac(input logic signed [FP_W-1:0] acc,
                                                 input logic signed [FP_W-1:0] x,
                                                 input logic signed [FP_W-1:0] y);  
    /* verilator no_inline_task */
    return addQ511(acc, mulQ511(x, y));

  endfunction

  function automatic logic signed [FP_W-1:0] macSub(input logic signed [FP_W-1:0] acc,
                                                    input logic signed [FP_W-1:0] x,
                                                    input logic signed [FP_W-1:0] y);
    /* verilator no_inline_task */
    return subQ511(acc, mulQ511(x, y));

  endfunction

  function automatic logic signed [FP_W-1:0] negQ511(input logic signed [FP_W-1:0] x);
    
    logic signed [FP_W-1:0] z = '0;
    return subQ511(z, x);

  endfunction

  function automatic logic signed [FP_W-1:0] asQ(input logic [FP_W-1:0] x);
    
    return x;
  
  endfunction

  function automatic ga_multivector_t geometricProduct(
    ga_multivector_t a,
    ga_multivector_t b
  );
    ga_multivector_t result;
    
    result = '0;

    result.scalar = mac(result.scalar, a.scalar, b.scalar);
    result.scalar = mac(result.scalar, a.e1, b.e1);
    result.scalar = mac(result.scalar, a.e2, b.e2);
    result.scalar = mac(result.scalar, a.e12, b.e12);
    result.scalar = mac(result.scalar, a.e3, b.e3);
    result.scalar = mac(result.scalar, a.e13, b.e13);
    result.scalar = mac(result.scalar, a.e23, b.e23);
    result.scalar = mac(result.scalar, a.e123, b.e123);
    result.scalar = macSub(result.scalar, a.eo, b.ei);
    result.scalar = macSub(result.scalar, a.e1o, b.e1i);
    result.scalar = macSub(result.scalar, a.e2o, b.e2i);
    result.scalar = macSub(result.scalar, a.e12o, b.e12i);
    result.scalar = macSub(result.scalar, a.e3o, b.e3i);
    result.scalar = macSub(result.scalar, a.e13o, b.e13i);
    result.scalar = macSub(result.scalar, a.e23o, b.e23i);
    result.scalar = macSub(result.scalar, a.e123o, b.e123i);
    result.scalar = macSub(result.scalar, a.ei, b.eo);
    result.scalar = macSub(result.scalar, a.e1i, b.e1o);
    result.scalar = macSub(result.scalar, a.e2i, b.e2o);
    result.scalar = macSub(result.scalar, a.e12i, b.e12o);
    result.scalar = macSub(result.scalar, a.e3i, b.e3o);
    result.scalar = macSub(result.scalar, a.e13i, b.e13o);
    result.scalar = macSub(result.scalar, a.e23i, b.e23o);
    result.scalar = macSub(result.scalar, a.e123i, b.e123o);
    result.scalar = macSub(result.scalar, a.eoi, b.scalar);
    result.scalar = macSub(result.scalar, a.eoi, b.eoi);
    result.scalar = macSub(result.scalar, a.e1oi, b.e1);
    result.scalar = macSub(result.scalar, a.e1oi, b.e1oi);
    result.scalar = macSub(result.scalar, a.e2oi, b.e2);
    result.scalar = macSub(result.scalar, a.e2oi, b.e2oi);
    result.scalar = macSub(result.scalar, a.e12oi, b.e12);
    result.scalar = macSub(result.scalar, a.e12oi, b.e12oi);
    result.scalar = macSub(result.scalar, a.e3oi, b.e3);
    result.scalar = macSub(result.scalar, a.e3oi, b.e3oi);
    result.scalar = macSub(result.scalar, a.e13oi, b.e13);
    result.scalar = macSub(result.scalar, a.e13oi, b.e13oi);
    result.scalar = macSub(result.scalar, a.e23oi, b.e23);
    result.scalar = macSub(result.scalar, a.e23oi, b.e23oi);
    result.scalar = macSub(result.scalar, a.e123oi, b.e123);
    result.scalar = macSub(result.scalar, a.e123oi, b.e123oi);

    result.e1 = mac(result.e1, a.scalar, b.e1);
    result.e1 = mac(result.e1, a.e1, b.scalar);
    result.e1 = macSub(result.e1, a.e2, b.e12);
    result.e1 = macSub(result.e1, a.e12, b.e2);
    result.e1 = macSub(result.e1, a.e3, b.e13);
    result.e1 = macSub(result.e1, a.e13, b.e3);
    result.e1 = mac(result.e1, a.e23, b.e123);
    result.e1 = mac(result.e1, a.e123, b.e23);
    result.e1 = mac(result.e1, a.eo, b.e1i);
    result.e1 = mac(result.e1, a.e1o, b.ei);
    result.e1 = macSub(result.e1, a.e2o, b.e12i);
    result.e1 = macSub(result.e1, a.e12o, b.e2i);
    result.e1 = macSub(result.e1, a.e3o, b.e13i);
    result.e1 = macSub(result.e1, a.e13o, b.e3i);
    result.e1 = mac(result.e1, a.e23o, b.e123i);
    result.e1 = mac(result.e1, a.e123o, b.e23i);
    result.e1 = mac(result.e1, a.ei, b.e1o);
    result.e1 = mac(result.e1, a.e1i, b.eo);
    result.e1 = macSub(result.e1, a.e2i, b.e12o);
    result.e1 = macSub(result.e1, a.e12i, b.e2o);
    result.e1 = macSub(result.e1, a.e3i, b.e13o);
    result.e1 = macSub(result.e1, a.e13i, b.e3o);
    result.e1 = mac(result.e1, a.e23i, b.e123o);
    result.e1 = mac(result.e1, a.e123i, b.e23o);
    result.e1 = macSub(result.e1, a.eoi, b.e1);
    result.e1 = macSub(result.e1, a.eoi, b.e1oi);
    result.e1 = macSub(result.e1, a.e1oi, b.scalar);
    result.e1 = macSub(result.e1, a.e1oi, b.eoi);
    result.e1 = mac(result.e1, a.e2oi, b.e12);
    result.e1 = mac(result.e1, a.e2oi, b.e12oi);
    result.e1 = mac(result.e1, a.e12oi, b.e2);
    result.e1 = mac(result.e1, a.e12oi, b.e2oi);
    result.e1 = mac(result.e1, a.e3oi, b.e13);
    result.e1 = mac(result.e1, a.e3oi, b.e13oi);
    result.e1 = mac(result.e1, a.e13oi, b.e3);
    result.e1 = mac(result.e1, a.e13oi, b.e3oi);
    result.e1 = macSub(result.e1, a.e23oi, b.e123);
    result.e1 = macSub(result.e1, a.e23oi, b.e123oi);
    result.e1 = macSub(result.e1, a.e123oi, b.e23);
    result.e1 = macSub(result.e1, a.e123oi, b.e23oi);

    result.e2 = mac(result.e2, a.scalar, b.e2);
    result.e2 = mac(result.e2, a.e1, b.e12);
    result.e2 = mac(result.e2, a.e2, b.scalar);
    result.e2 = mac(result.e2, a.e12, b.e1);
    result.e2 = macSub(result.e2, a.e3, b.e23);
    result.e2 = macSub(result.e2, a.e13, b.e123);
    result.e2 = macSub(result.e2, a.e23, b.e3);
    result.e2 = macSub(result.e2, a.e123, b.e13);
    result.e2 = mac(result.e2, a.eo, b.e2i);
    result.e2 = mac(result.e2, a.e1o, b.e12i);
    result.e2 = mac(result.e2, a.e2o, b.ei);
    result.e2 = mac(result.e2, a.e12o, b.e1i);
    result.e2 = macSub(result.e2, a.e3o, b.e23i);
    result.e2 = macSub(result.e2, a.e13o, b.e123i);
    result.e2 = macSub(result.e2, a.e23o, b.e3i);
    result.e2 = macSub(result.e2, a.e123o, b.e13i);
    result.e2 = mac(result.e2, a.ei, b.e2o);
    result.e2 = mac(result.e2, a.e1i, b.e12o);
    result.e2 = mac(result.e2, a.e2i, b.eo);
    result.e2 = mac(result.e2, a.e12i, b.e1o);
    result.e2 = macSub(result.e2, a.e3i, b.e23o);
    result.e2 = macSub(result.e2, a.e13i, b.e123o);
    result.e2 = macSub(result.e2, a.e23i, b.e3o);
    result.e2 = macSub(result.e2, a.e123i, b.e13o);
    result.e2 = macSub(result.e2, a.eoi, b.e2);
    result.e2 = macSub(result.e2, a.eoi, b.e2oi);
    result.e2 = macSub(result.e2, a.e1oi, b.e12);
    result.e2 = macSub(result.e2, a.e1oi, b.e12oi);
    result.e2 = macSub(result.e2, a.e2oi, b.scalar);
    result.e2 = macSub(result.e2, a.e2oi, b.eoi);
    result.e2 = macSub(result.e2, a.e12oi, b.e1);
    result.e2 = macSub(result.e2, a.e12oi, b.e1oi);
    result.e2 = mac(result.e2, a.e3oi, b.e23);
    result.e2 = mac(result.e2, a.e3oi, b.e23oi);
    result.e2 = mac(result.e2, a.e13oi, b.e123);
    result.e2 = mac(result.e2, a.e13oi, b.e123oi);
    result.e2 = mac(result.e2, a.e23oi, b.e3);
    result.e2 = mac(result.e2, a.e23oi, b.e3oi);
    result.e2 = mac(result.e2, a.e123oi, b.e13);
    result.e2 = mac(result.e2, a.e123oi, b.e13oi);

    result.e12 = mac(result.e12, a.scalar, b.e12);
    result.e12 = mac(result.e12, a.e1, b.e2);
    result.e12 = macSub(result.e12, a.e2, b.e1);
    result.e12 = macSub(result.e12, a.e12, b.scalar);
    result.e12 = mac(result.e12, a.e3, b.e123);
    result.e12 = mac(result.e12, a.e13, b.e23);
    result.e12 = macSub(result.e12, a.e23, b.e13);
    result.e12 = macSub(result.e12, a.e123, b.e3);
    result.e12 = macSub(result.e12, a.eo, b.e12i);
    result.e12 = macSub(result.e12, a.e1o, b.e2i);
    result.e12 = mac(result.e12, a.e2o, b.e1i);
    result.e12 = mac(result.e12, a.e12o, b.ei);
    result.e12 = macSub(result.e12, a.e3o, b.e123i);
    result.e12 = macSub(result.e12, a.e13o, b.e23i);
    result.e12 = mac(result.e12, a.e23o, b.e13i);
    result.e12 = mac(result.e12, a.e123o, b.e3i);
    result.e12 = macSub(result.e12, a.ei, b.e12o);
    result.e12 = macSub(result.e12, a.e1i, b.e2o);
    result.e12 = mac(result.e12, a.e2i, b.e1o);
    result.e12 = mac(result.e12, a.e12i, b.eo);
    result.e12 = macSub(result.e12, a.e3i, b.e123o);
    result.e12 = macSub(result.e12, a.e13i, b.e23o);
    result.e12 = mac(result.e12, a.e23i, b.e13o);
    result.e12 = mac(result.e12, a.e123i, b.e3o);
    result.e12 = macSub(result.e12, a.eoi, b.e12);
    result.e12 = macSub(result.e12, a.eoi, b.e12oi);
    result.e12 = macSub(result.e12, a.e1oi, b.e2);
    result.e12 = macSub(result.e12, a.e1oi, b.e2oi);
    result.e12 = mac(result.e12, a.e2oi, b.e1);
    result.e12 = mac(result.e12, a.e2oi, b.e1oi);
    result.e12 = mac(result.e12, a.e12oi, b.scalar);
    result.e12 = mac(result.e12, a.e12oi, b.eoi);
    result.e12 = macSub(result.e12, a.e3oi, b.e123);
    result.e12 = macSub(result.e12, a.e3oi, b.e123oi);
    result.e12 = macSub(result.e12, a.e13oi, b.e23);
    result.e12 = macSub(result.e12, a.e13oi, b.e23oi);
    result.e12 = mac(result.e12, a.e23oi, b.e13);
    result.e12 = mac(result.e12, a.e23oi, b.e13oi);
    result.e12 = mac(result.e12, a.e123oi, b.e3);
    result.e12 = mac(result.e12, a.e123oi, b.e3oi);

    result.e3 = mac(result.e3, a.scalar, b.e3);
    result.e3 = mac(result.e3, a.e1, b.e13);
    result.e3 = mac(result.e3, a.e2, b.e23);
    result.e3 = mac(result.e3, a.e12, b.e123);
    result.e3 = mac(result.e3, a.e3, b.scalar);
    result.e3 = mac(result.e3, a.e13, b.e1);
    result.e3 = mac(result.e3, a.e23, b.e2);
    result.e3 = mac(result.e3, a.e123, b.e12);
    result.e3 = mac(result.e3, a.eo, b.e3i);
    result.e3 = mac(result.e3, a.e1o, b.e13i);
    result.e3 = mac(result.e3, a.e2o, b.e23i);
    result.e3 = mac(result.e3, a.e12o, b.e123i);
    result.e3 = mac(result.e3, a.e3o, b.ei);
    result.e3 = mac(result.e3, a.e13o, b.e1i);
    result.e3 = mac(result.e3, a.e23o, b.e2i);
    result.e3 = mac(result.e3, a.e123o, b.e12i);
    result.e3 = mac(result.e3, a.ei, b.e3o);
    result.e3 = mac(result.e3, a.e1i, b.e13o);
    result.e3 = mac(result.e3, a.e2i, b.e23o);
    result.e3 = mac(result.e3, a.e12i, b.e123o);
    result.e3 = mac(result.e3, a.e3i, b.eo);
    result.e3 = mac(result.e3, a.e13i, b.e1o);
    result.e3 = mac(result.e3, a.e23i, b.e2o);
    result.e3 = mac(result.e3, a.e123i, b.e12o);
    result.e3 = macSub(result.e3, a.eoi, b.e3);
    result.e3 = macSub(result.e3, a.eoi, b.e3oi);
    result.e3 = macSub(result.e3, a.e1oi, b.e13);
    result.e3 = macSub(result.e3, a.e1oi, b.e13oi);
    result.e3 = macSub(result.e3, a.e2oi, b.e23);
    result.e3 = macSub(result.e3, a.e2oi, b.e23oi);
    result.e3 = macSub(result.e3, a.e12oi, b.e123);
    result.e3 = macSub(result.e3, a.e12oi, b.e123oi);
    result.e3 = macSub(result.e3, a.e3oi, b.scalar);
    result.e3 = macSub(result.e3, a.e3oi, b.eoi);
    result.e3 = macSub(result.e3, a.e13oi, b.e1);
    result.e3 = macSub(result.e3, a.e13oi, b.e1oi);
    result.e3 = macSub(result.e3, a.e23oi, b.e2);
    result.e3 = macSub(result.e3, a.e23oi, b.e2oi);
    result.e3 = macSub(result.e3, a.e123oi, b.e12);
    result.e3 = macSub(result.e3, a.e123oi, b.e12oi);

    result.e13 = mac(result.e13, a.scalar, b.e13);
    result.e13 = mac(result.e13, a.e1, b.e3);
    result.e13 = macSub(result.e13, a.e2, b.e123);
    result.e13 = macSub(result.e13, a.e12, b.e23);
    result.e13 = macSub(result.e13, a.e3, b.e1);
    result.e13 = macSub(result.e13, a.e13, b.scalar);
    result.e13 = mac(result.e13, a.e23, b.e12);
    result.e13 = mac(result.e13, a.e123, b.e2);
    result.e13 = macSub(result.e13, a.eo, b.e13i);
    result.e13 = macSub(result.e13, a.e1o, b.e3i);
    result.e13 = mac(result.e13, a.e2o, b.e123i);
    result.e13 = mac(result.e13, a.e12o, b.e23i);
    result.e13 = mac(result.e13, a.e3o, b.e1i);
    result.e13 = mac(result.e13, a.e13o, b.ei);
    result.e13 = macSub(result.e13, a.e23o, b.e12i);
    result.e13 = macSub(result.e13, a.e123o, b.e2i);
    result.e13 = macSub(result.e13, a.ei, b.e13o);
    result.e13 = macSub(result.e13, a.e1i, b.e3o);
    result.e13 = mac(result.e13, a.e2i, b.e123o);
    result.e13 = mac(result.e13, a.e12i, b.e23o);
    result.e13 = mac(result.e13, a.e3i, b.e1o);
    result.e13 = mac(result.e13, a.e13i, b.eo);
    result.e13 = macSub(result.e13, a.e23i, b.e12o);
    result.e13 = macSub(result.e13, a.e123i, b.e2o);
    result.e13 = macSub(result.e13, a.eoi, b.e13);
    result.e13 = macSub(result.e13, a.eoi, b.e13oi);
    result.e13 = macSub(result.e13, a.e1oi, b.e3);
    result.e13 = macSub(result.e13, a.e1oi, b.e3oi);
    result.e13 = mac(result.e13, a.e2oi, b.e123);
    result.e13 = mac(result.e13, a.e2oi, b.e123oi);
    result.e13 = mac(result.e13, a.e12oi, b.e23);
    result.e13 = mac(result.e13, a.e12oi, b.e23oi);
    result.e13 = mac(result.e13, a.e3oi, b.e1);
    result.e13 = mac(result.e13, a.e3oi, b.e1oi);
    result.e13 = mac(result.e13, a.e13oi, b.scalar);
    result.e13 = mac(result.e13, a.e13oi, b.eoi);
    result.e13 = macSub(result.e13, a.e23oi, b.e12);
    result.e13 = macSub(result.e13, a.e23oi, b.e12oi);
    result.e13 = macSub(result.e13, a.e123oi, b.e2);
    result.e13 = macSub(result.e13, a.e123oi, b.e2oi);

    result.e23 = mac(result.e23, a.scalar, b.e23);
    result.e23 = mac(result.e23, a.e1, b.e123);
    result.e23 = mac(result.e23, a.e2, b.e3);
    result.e23 = mac(result.e23, a.e12, b.e13);
    result.e23 = macSub(result.e23, a.e3, b.e2);
    result.e23 = macSub(result.e23, a.e13, b.e12);
    result.e23 = macSub(result.e23, a.e23, b.scalar);
    result.e23 = macSub(result.e23, a.e123, b.e1);
    result.e23 = macSub(result.e23, a.eo, b.e23i);
    result.e23 = macSub(result.e23, a.e1o, b.e123i);
    result.e23 = macSub(result.e23, a.e2o, b.e3i);
    result.e23 = macSub(result.e23, a.e12o, b.e13i);
    result.e23 = mac(result.e23, a.e3o, b.e2i);
    result.e23 = mac(result.e23, a.e13o, b.e12i);
    result.e23 = mac(result.e23, a.e23o, b.ei);
    result.e23 = mac(result.e23, a.e123o, b.e1i);
    result.e23 = macSub(result.e23, a.ei, b.e23o);
    result.e23 = macSub(result.e23, a.e1i, b.e123o);
    result.e23 = macSub(result.e23, a.e2i, b.e3o);
    result.e23 = macSub(result.e23, a.e12i, b.e13o);
    result.e23 = mac(result.e23, a.e3i, b.e2o);
    result.e23 = mac(result.e23, a.e13i, b.e12o);
    result.e23 = mac(result.e23, a.e23i, b.eo);
    result.e23 = mac(result.e23, a.e123i, b.e1o);
    result.e23 = macSub(result.e23, a.eoi, b.e23);
    result.e23 = macSub(result.e23, a.eoi, b.e23oi);
    result.e23 = macSub(result.e23, a.e1oi, b.e123);
    result.e23 = macSub(result.e23, a.e1oi, b.e123oi);
    result.e23 = macSub(result.e23, a.e2oi, b.e3);
    result.e23 = macSub(result.e23, a.e2oi, b.e3oi);
    result.e23 = macSub(result.e23, a.e12oi, b.e13);
    result.e23 = macSub(result.e23, a.e12oi, b.e13oi);
    result.e23 = mac(result.e23, a.e3oi, b.e2);
    result.e23 = mac(result.e23, a.e3oi, b.e2oi);
    result.e23 = mac(result.e23, a.e13oi, b.e12);
    result.e23 = mac(result.e23, a.e13oi, b.e12oi);
    result.e23 = mac(result.e23, a.e23oi, b.scalar);
    result.e23 = mac(result.e23, a.e23oi, b.eoi);
    result.e23 = mac(result.e23, a.e123oi, b.e1);
    result.e23 = mac(result.e23, a.e123oi, b.e1oi);

    result.e123 = mac(result.e123, a.scalar, b.e123);
    result.e123 = mac(result.e123, a.e1, b.e23);
    result.e123 = macSub(result.e123, a.e2, b.e13);
    result.e123 = macSub(result.e123, a.e12, b.e3);
    result.e123 = mac(result.e123, a.e3, b.e12);
    result.e123 = mac(result.e123, a.e13, b.e2);
    result.e123 = macSub(result.e123, a.e23, b.e1);
    result.e123 = macSub(result.e123, a.e123, b.scalar);
    result.e123 = mac(result.e123, a.eo, b.e123i);
    result.e123 = mac(result.e123, a.e1o, b.e23i);
    result.e123 = macSub(result.e123, a.e2o, b.e13i);
    result.e123 = macSub(result.e123, a.e12o, b.e3i);
    result.e123 = mac(result.e123, a.e3o, b.e12i);
    result.e123 = mac(result.e123, a.e13o, b.e2i);
    result.e123 = macSub(result.e123, a.e23o, b.e1i);
    result.e123 = macSub(result.e123, a.e123o, b.ei);
    result.e123 = mac(result.e123, a.ei, b.e123o);
    result.e123 = mac(result.e123, a.e1i, b.e23o);
    result.e123 = macSub(result.e123, a.e2i, b.e13o);
    result.e123 = macSub(result.e123, a.e12i, b.e3o);
    result.e123 = mac(result.e123, a.e3i, b.e12o);
    result.e123 = mac(result.e123, a.e13i, b.e2o);
    result.e123 = macSub(result.e123, a.e23i, b.e1o);
    result.e123 = macSub(result.e123, a.e123i, b.eo);
    result.e123 = macSub(result.e123, a.eoi, b.e123);
    result.e123 = macSub(result.e123, a.eoi, b.e123oi);
    result.e123 = macSub(result.e123, a.e1oi, b.e23);
    result.e123 = macSub(result.e123, a.e1oi, b.e23oi);
    result.e123 = mac(result.e123, a.e2oi, b.e13);
    result.e123 = mac(result.e123, a.e2oi, b.e13oi);
    result.e123 = mac(result.e123, a.e12oi, b.e3);
    result.e123 = mac(result.e123, a.e12oi, b.e3oi);
    result.e123 = macSub(result.e123, a.e3oi, b.e12);
    result.e123 = macSub(result.e123, a.e3oi, b.e12oi);
    result.e123 = macSub(result.e123, a.e13oi, b.e2);
    result.e123 = macSub(result.e123, a.e13oi, b.e2oi);
    result.e123 = mac(result.e123, a.e23oi, b.e1);
    result.e123 = mac(result.e123, a.e23oi, b.e1oi);
    result.e123 = mac(result.e123, a.e123oi, b.scalar);
    result.e123 = mac(result.e123, a.e123oi, b.eoi);

    result.eo = mac(result.eo, a.scalar, b.eo);
    result.eo = mac(result.eo, a.e1, b.e1o);
    result.eo = mac(result.eo, a.e2, b.e2o);
    result.eo = mac(result.eo, a.e12, b.e12o);
    result.eo = mac(result.eo, a.e3, b.e3o);
    result.eo = mac(result.eo, a.e13, b.e13o);
    result.eo = mac(result.eo, a.e23, b.e23o);
    result.eo = mac(result.eo, a.e123, b.e123o);
    result.eo = mac(result.eo, a.eo, b.scalar);
    result.eo = mac(result.eo, a.eo, b.eoi);
    result.eo = mac(result.eo, a.e1o, b.e1);
    result.eo = mac(result.eo, a.e1o, b.e1oi);
    result.eo = mac(result.eo, a.e2o, b.e2);
    result.eo = mac(result.eo, a.e2o, b.e2oi);
    result.eo = mac(result.eo, a.e12o, b.e12);
    result.eo = mac(result.eo, a.e12o, b.e12oi);
    result.eo = mac(result.eo, a.e3o, b.e3);
    result.eo = mac(result.eo, a.e3o, b.e3oi);
    result.eo = mac(result.eo, a.e13o, b.e13);
    result.eo = mac(result.eo, a.e13o, b.e13oi);
    result.eo = mac(result.eo, a.e23o, b.e23);
    result.eo = mac(result.eo, a.e23o, b.e23oi);
    result.eo = mac(result.eo, a.e123o, b.e123);
    result.eo = mac(result.eo, a.e123o, b.e123oi);

    result.e1o = mac(result.e1o, a.scalar, b.e1o);
    result.e1o = mac(result.e1o, a.e1, b.eo);
    result.e1o = macSub(result.e1o, a.e2, b.e12o);
    result.e1o = macSub(result.e1o, a.e12, b.e2o);
    result.e1o = macSub(result.e1o, a.e3, b.e13o);
    result.e1o = macSub(result.e1o, a.e13, b.e3o);
    result.e1o = mac(result.e1o, a.e23, b.e123o);
    result.e1o = mac(result.e1o, a.e123, b.e23o);
    result.e1o = macSub(result.e1o, a.eo, b.e1);
    result.e1o = macSub(result.e1o, a.eo, b.e1oi);
    result.e1o = macSub(result.e1o, a.e1o, b.scalar);
    result.e1o = macSub(result.e1o, a.e1o, b.eoi);
    result.e1o = mac(result.e1o, a.e2o, b.e12);
    result.e1o = mac(result.e1o, a.e2o, b.e12oi);
    result.e1o = mac(result.e1o, a.e12o, b.e2);
    result.e1o = mac(result.e1o, a.e12o, b.e2oi);
    result.e1o = mac(result.e1o, a.e3o, b.e13);
    result.e1o = mac(result.e1o, a.e3o, b.e13oi);
    result.e1o = mac(result.e1o, a.e13o, b.e3);
    result.e1o = mac(result.e1o, a.e13o, b.e3oi);
    result.e1o = macSub(result.e1o, a.e23o, b.e123);
    result.e1o = macSub(result.e1o, a.e23o, b.e123oi);
    result.e1o = macSub(result.e1o, a.e123o, b.e23);
    result.e1o = macSub(result.e1o, a.e123o, b.e23oi);

    result.e2o = mac(result.e2o, a.scalar, b.e2o);
    result.e2o = mac(result.e2o, a.e1, b.e12o);
    result.e2o = mac(result.e2o, a.e2, b.eo);
    result.e2o = mac(result.e2o, a.e12, b.e1o);
    result.e2o = macSub(result.e2o, a.e3, b.e23o);
    result.e2o = macSub(result.e2o, a.e13, b.e123o);
    result.e2o = macSub(result.e2o, a.e23, b.e3o);
    result.e2o = macSub(result.e2o, a.e123, b.e13o);
    result.e2o = macSub(result.e2o, a.eo, b.e2);
    result.e2o = macSub(result.e2o, a.eo, b.e2oi);
    result.e2o = macSub(result.e2o, a.e1o, b.e12);
    result.e2o = macSub(result.e2o, a.e1o, b.e12oi);
    result.e2o = macSub(result.e2o, a.e2o, b.scalar);
    result.e2o = macSub(result.e2o, a.e2o, b.eoi);
    result.e2o = macSub(result.e2o, a.e12o, b.e1);
    result.e2o = macSub(result.e2o, a.e12o, b.e1oi);
    result.e2o = mac(result.e2o, a.e3o, b.e23);
    result.e2o = mac(result.e2o, a.e3o, b.e23oi);
    result.e2o = mac(result.e2o, a.e13o, b.e123);
    result.e2o = mac(result.e2o, a.e13o, b.e123oi);
    result.e2o = mac(result.e2o, a.e23o, b.e3);
    result.e2o = mac(result.e2o, a.e23o, b.e3oi);
    result.e2o = mac(result.e2o, a.e123o, b.e13);
    result.e2o = mac(result.e2o, a.e123o, b.e13oi);

    result.e12o = mac(result.e12o, a.scalar, b.e12o);
    result.e12o = mac(result.e12o, a.e1, b.e2o);
    result.e12o = macSub(result.e12o, a.e2, b.e1o);
    result.e12o = macSub(result.e12o, a.e12, b.eo);
    result.e12o = mac(result.e12o, a.e3, b.e123o);
    result.e12o = mac(result.e12o, a.e13, b.e23o);
    result.e12o = macSub(result.e12o, a.e23, b.e13o);
    result.e12o = macSub(result.e12o, a.e123, b.e3o);
    result.e12o = mac(result.e12o, a.eo, b.e12);
    result.e12o = mac(result.e12o, a.eo, b.e12oi);
    result.e12o = mac(result.e12o, a.e1o, b.e2);
    result.e12o = mac(result.e12o, a.e1o, b.e2oi);
    result.e12o = macSub(result.e12o, a.e2o, b.e1);
    result.e12o = macSub(result.e12o, a.e2o, b.e1oi);
    result.e12o = macSub(result.e12o, a.e12o, b.scalar);
    result.e12o = macSub(result.e12o, a.e12o, b.eoi);
    result.e12o = mac(result.e12o, a.e3o, b.e123);
    result.e12o = mac(result.e12o, a.e3o, b.e123oi);
    result.e12o = mac(result.e12o, a.e13o, b.e23);
    result.e12o = mac(result.e12o, a.e13o, b.e23oi);
    result.e12o = macSub(result.e12o, a.e23o, b.e13);
    result.e12o = macSub(result.e12o, a.e23o, b.e13oi);
    result.e12o = macSub(result.e12o, a.e123o, b.e3);
    result.e12o = macSub(result.e12o, a.e123o, b.e3oi);

    result.e3o = mac(result.e3o, a.scalar, b.e3o);
    result.e3o = mac(result.e3o, a.e1, b.e13o);
    result.e3o = mac(result.e3o, a.e2, b.e23o);
    result.e3o = mac(result.e3o, a.e12, b.e123o);
    result.e3o = mac(result.e3o, a.e3, b.eo);
    result.e3o = mac(result.e3o, a.e13, b.e1o);
    result.e3o = mac(result.e3o, a.e23, b.e2o);
    result.e3o = mac(result.e3o, a.e123, b.e12o);
    result.e3o = macSub(result.e3o, a.eo, b.e3);
    result.e3o = macSub(result.e3o, a.eo, b.e3oi);
    result.e3o = macSub(result.e3o, a.e1o, b.e13);
    result.e3o = macSub(result.e3o, a.e1o, b.e13oi);
    result.e3o = macSub(result.e3o, a.e2o, b.e23);
    result.e3o = macSub(result.e3o, a.e2o, b.e23oi);
    result.e3o = macSub(result.e3o, a.e12o, b.e123);
    result.e3o = macSub(result.e3o, a.e12o, b.e123oi);
    result.e3o = macSub(result.e3o, a.e3o, b.scalar);
    result.e3o = macSub(result.e3o, a.e3o, b.eoi);
    result.e3o = macSub(result.e3o, a.e13o, b.e1);
    result.e3o = macSub(result.e3o, a.e13o, b.e1oi);
    result.e3o = macSub(result.e3o, a.e23o, b.e2);
    result.e3o = macSub(result.e3o, a.e23o, b.e2oi);
    result.e3o = macSub(result.e3o, a.e123o, b.e12);
    result.e3o = macSub(result.e3o, a.e123o, b.e12oi);

    result.e13o = mac(result.e13o, a.scalar, b.e13o);
    result.e13o = mac(result.e13o, a.e1, b.e3o);
    result.e13o = macSub(result.e13o, a.e2, b.e123o);
    result.e13o = macSub(result.e13o, a.e12, b.e23o);
    result.e13o = macSub(result.e13o, a.e3, b.e1o);
    result.e13o = macSub(result.e13o, a.e13, b.eo);
    result.e13o = mac(result.e13o, a.e23, b.e12o);
    result.e13o = mac(result.e13o, a.e123, b.e2o);
    result.e13o = mac(result.e13o, a.eo, b.e13);
    result.e13o = mac(result.e13o, a.eo, b.e13oi);
    result.e13o = mac(result.e13o, a.e1o, b.e3);
    result.e13o = mac(result.e13o, a.e1o, b.e3oi);
    result.e13o = macSub(result.e13o, a.e2o, b.e123);
    result.e13o = macSub(result.e13o, a.e2o, b.e123oi);
    result.e13o = macSub(result.e13o, a.e12o, b.e23);
    result.e13o = macSub(result.e13o, a.e12o, b.e23oi);
    result.e13o = macSub(result.e13o, a.e3o, b.e1);
    result.e13o = macSub(result.e13o, a.e3o, b.e1oi);
    result.e13o = macSub(result.e13o, a.e13o, b.scalar);
    result.e13o = macSub(result.e13o, a.e13o, b.eoi);
    result.e13o = mac(result.e13o, a.e23o, b.e12);
    result.e13o = mac(result.e13o, a.e23o, b.e12oi);
    result.e13o = mac(result.e13o, a.e123o, b.e2);
    result.e13o = mac(result.e13o, a.e123o, b.e2oi);

    result.e23o = mac(result.e23o, a.scalar, b.e23o);
    result.e23o = mac(result.e23o, a.e1, b.e123o);
    result.e23o = mac(result.e23o, a.e2, b.e3o);
    result.e23o = mac(result.e23o, a.e12, b.e13o);
    result.e23o = macSub(result.e23o, a.e3, b.e2o);
    result.e23o = macSub(result.e23o, a.e13, b.e12o);
    result.e23o = macSub(result.e23o, a.e23, b.eo);
    result.e23o = macSub(result.e23o, a.e123, b.e1o);
    result.e23o = mac(result.e23o, a.eo, b.e23);
    result.e23o = mac(result.e23o, a.eo, b.e23oi);
    result.e23o = mac(result.e23o, a.e1o, b.e123);
    result.e23o = mac(result.e23o, a.e1o, b.e123oi);
    result.e23o = mac(result.e23o, a.e2o, b.e3);
    result.e23o = mac(result.e23o, a.e2o, b.e3oi);
    result.e23o = mac(result.e23o, a.e12o, b.e13);
    result.e23o = mac(result.e23o, a.e12o, b.e13oi);
    result.e23o = macSub(result.e23o, a.e3o, b.e2);
    result.e23o = macSub(result.e23o, a.e3o, b.e2oi);
    result.e23o = macSub(result.e23o, a.e13o, b.e12);
    result.e23o = macSub(result.e23o, a.e13o, b.e12oi);
    result.e23o = macSub(result.e23o, a.e23o, b.scalar);
    result.e23o = macSub(result.e23o, a.e23o, b.eoi);
    result.e23o = macSub(result.e23o, a.e123o, b.e1);
    result.e23o = macSub(result.e23o, a.e123o, b.e1oi);

    result.e123o = mac(result.e123o, a.scalar, b.e123o);
    result.e123o = mac(result.e123o, a.e1, b.e23o);
    result.e123o = macSub(result.e123o, a.e2, b.e13o);
    result.e123o = macSub(result.e123o, a.e12, b.e3o);
    result.e123o = mac(result.e123o, a.e3, b.e12o);
    result.e123o = mac(result.e123o, a.e13, b.e2o);
    result.e123o = macSub(result.e123o, a.e23, b.e1o);
    result.e123o = macSub(result.e123o, a.e123, b.eo);
    result.e123o = macSub(result.e123o, a.eo, b.e123);
    result.e123o = macSub(result.e123o, a.eo, b.e123oi);
    result.e123o = macSub(result.e123o, a.e1o, b.e23);
    result.e123o = macSub(result.e123o, a.e1o, b.e23oi);
    result.e123o = mac(result.e123o, a.e2o, b.e13);
    result.e123o = mac(result.e123o, a.e2o, b.e13oi);
    result.e123o = mac(result.e123o, a.e12o, b.e3);
    result.e123o = mac(result.e123o, a.e12o, b.e3oi);
    result.e123o = macSub(result.e123o, a.e3o, b.e12);
    result.e123o = macSub(result.e123o, a.e3o, b.e12oi);
    result.e123o = macSub(result.e123o, a.e13o, b.e2);
    result.e123o = macSub(result.e123o, a.e13o, b.e2oi);
    result.e123o = mac(result.e123o, a.e23o, b.e1);
    result.e123o = mac(result.e123o, a.e23o, b.e1oi);
    result.e123o = mac(result.e123o, a.e123o, b.scalar);
    result.e123o = mac(result.e123o, a.e123o, b.eoi);

    result.ei = mac(result.ei, a.scalar, b.ei);
    result.ei = mac(result.ei, a.e1, b.e1i);
    result.ei = mac(result.ei, a.e2, b.e2i);
    result.ei = mac(result.ei, a.e12, b.e12i);
    result.ei = mac(result.ei, a.e3, b.e3i);
    result.ei = mac(result.ei, a.e13, b.e13i);
    result.ei = mac(result.ei, a.e23, b.e23i);
    result.ei = mac(result.ei, a.e123, b.e123i);
    result.ei = mac(result.ei, a.ei, b.scalar);
    result.ei = macSub(result.ei, a.ei, b.eoi);
    result.ei = mac(result.ei, a.e1i, b.e1);
    result.ei = macSub(result.ei, a.e1i, b.e1oi);
    result.ei = mac(result.ei, a.e2i, b.e2);
    result.ei = macSub(result.ei, a.e2i, b.e2oi);
    result.ei = mac(result.ei, a.e12i, b.e12);
    result.ei = macSub(result.ei, a.e12i, b.e12oi);
    result.ei = mac(result.ei, a.e3i, b.e3);
    result.ei = macSub(result.ei, a.e3i, b.e3oi);
    result.ei = mac(result.ei, a.e13i, b.e13);
    result.ei = macSub(result.ei, a.e13i, b.e13oi);
    result.ei = mac(result.ei, a.e23i, b.e23);
    result.ei = macSub(result.ei, a.e23i, b.e23oi);
    result.ei = mac(result.ei, a.e123i, b.e123);
    result.ei = macSub(result.ei, a.e123i, b.e123oi);
    result.ei = macSub(result.ei, a.eoi, b.ei);
    result.ei = macSub(result.ei, a.eoi, b.ei);
    result.ei = macSub(result.ei, a.e1oi, b.e1i);
    result.ei = macSub(result.ei, a.e1oi, b.e1i);
    result.ei = macSub(result.ei, a.e2oi, b.e2i);
    result.ei = macSub(result.ei, a.e2oi, b.e2i);
    result.ei = macSub(result.ei, a.e12oi, b.e12i);
    result.ei = macSub(result.ei, a.e12oi, b.e12i);
    result.ei = macSub(result.ei, a.e3oi, b.e3i);
    result.ei = macSub(result.ei, a.e3oi, b.e3i);
    result.ei = macSub(result.ei, a.e13oi, b.e13i);
    result.ei = macSub(result.ei, a.e13oi, b.e13i);
    result.ei = macSub(result.ei, a.e23oi, b.e23i);
    result.ei = macSub(result.ei, a.e23oi, b.e23i);
    result.ei = macSub(result.ei, a.e123oi, b.e123i);
    result.ei = macSub(result.ei, a.e123oi, b.e123i);

    result.e1i = mac(result.e1i, a.scalar, b.e1i);
    result.e1i = mac(result.e1i, a.e1, b.ei);
    result.e1i = macSub(result.e1i, a.e2, b.e12i);
    result.e1i = macSub(result.e1i, a.e12, b.e2i);
    result.e1i = macSub(result.e1i, a.e3, b.e13i);
    result.e1i = macSub(result.e1i, a.e13, b.e3i);
    result.e1i = mac(result.e1i, a.e23, b.e123i);
    result.e1i = mac(result.e1i, a.e123, b.e23i);
    result.e1i = macSub(result.e1i, a.ei, b.e1);
    result.e1i = mac(result.e1i, a.ei, b.e1oi);
    result.e1i = macSub(result.e1i, a.e1i, b.scalar);
    result.e1i = mac(result.e1i, a.e1i, b.eoi);
    result.e1i = mac(result.e1i, a.e2i, b.e12);
    result.e1i = macSub(result.e1i, a.e2i, b.e12oi);
    result.e1i = mac(result.e1i, a.e12i, b.e2);
    result.e1i = macSub(result.e1i, a.e12i, b.e2oi);
    result.e1i = mac(result.e1i, a.e3i, b.e13);
    result.e1i = macSub(result.e1i, a.e3i, b.e13oi);
    result.e1i = mac(result.e1i, a.e13i, b.e3);
    result.e1i = macSub(result.e1i, a.e13i, b.e3oi);
    result.e1i = macSub(result.e1i, a.e23i, b.e123);
    result.e1i = mac(result.e1i, a.e23i, b.e123oi);
    result.e1i = macSub(result.e1i, a.e123i, b.e23);
    result.e1i = mac(result.e1i, a.e123i, b.e23oi);
    result.e1i = macSub(result.e1i, a.eoi, b.e1i);
    result.e1i = macSub(result.e1i, a.eoi, b.e1i);
    result.e1i = macSub(result.e1i, a.e1oi, b.ei);
    result.e1i = macSub(result.e1i, a.e1oi, b.ei);
    result.e1i = mac(result.e1i, a.e2oi, b.e12i);
    result.e1i = mac(result.e1i, a.e2oi, b.e12i);
    result.e1i = mac(result.e1i, a.e12oi, b.e2i);
    result.e1i = mac(result.e1i, a.e12oi, b.e2i);
    result.e1i = mac(result.e1i, a.e3oi, b.e13i);
    result.e1i = mac(result.e1i, a.e3oi, b.e13i);
    result.e1i = mac(result.e1i, a.e13oi, b.e3i);
    result.e1i = mac(result.e1i, a.e13oi, b.e3i);
    result.e1i = macSub(result.e1i, a.e23oi, b.e123i);
    result.e1i = macSub(result.e1i, a.e23oi, b.e123i);
    result.e1i = macSub(result.e1i, a.e123oi, b.e23i);
    result.e1i = macSub(result.e1i, a.e123oi, b.e23i);

    result.e2i = mac(result.e2i, a.scalar, b.e2i);
    result.e2i = mac(result.e2i, a.e1, b.e12i);
    result.e2i = mac(result.e2i, a.e2, b.ei);
    result.e2i = mac(result.e2i, a.e12, b.e1i);
    result.e2i = macSub(result.e2i, a.e3, b.e23i);
    result.e2i = macSub(result.e2i, a.e13, b.e123i);
    result.e2i = macSub(result.e2i, a.e23, b.e3i);
    result.e2i = macSub(result.e2i, a.e123, b.e13i);
    result.e2i = macSub(result.e2i, a.ei, b.e2);
    result.e2i = mac(result.e2i, a.ei, b.e2oi);
    result.e2i = macSub(result.e2i, a.e1i, b.e12);
    result.e2i = mac(result.e2i, a.e1i, b.e12oi);
    result.e2i = macSub(result.e2i, a.e2i, b.scalar);
    result.e2i = mac(result.e2i, a.e2i, b.eoi);
    result.e2i = macSub(result.e2i, a.e12i, b.e1);
    result.e2i = mac(result.e2i, a.e12i, b.e1oi);
    result.e2i = mac(result.e2i, a.e3i, b.e23);
    result.e2i = macSub(result.e2i, a.e3i, b.e23oi);
    result.e2i = mac(result.e2i, a.e13i, b.e123);
    result.e2i = macSub(result.e2i, a.e13i, b.e123oi);
    result.e2i = mac(result.e2i, a.e23i, b.e3);
    result.e2i = macSub(result.e2i, a.e23i, b.e3oi);
    result.e2i = mac(result.e2i, a.e123i, b.e13);
    result.e2i = macSub(result.e2i, a.e123i, b.e13oi);
    result.e2i = macSub(result.e2i, a.eoi, b.e2i);
    result.e2i = macSub(result.e2i, a.eoi, b.e2i);
    result.e2i = macSub(result.e2i, a.e1oi, b.e12i);
    result.e2i = macSub(result.e2i, a.e1oi, b.e12i);
    result.e2i = macSub(result.e2i, a.e2oi, b.ei);
    result.e2i = macSub(result.e2i, a.e2oi, b.ei);
    result.e2i = macSub(result.e2i, a.e12oi, b.e1i);
    result.e2i = macSub(result.e2i, a.e12oi, b.e1i);
    result.e2i = mac(result.e2i, a.e3oi, b.e23i);
    result.e2i = mac(result.e2i, a.e3oi, b.e23i);
    result.e2i = mac(result.e2i, a.e13oi, b.e123i);
    result.e2i = mac(result.e2i, a.e13oi, b.e123i);
    result.e2i = mac(result.e2i, a.e23oi, b.e3i);
    result.e2i = mac(result.e2i, a.e23oi, b.e3i);
    result.e2i = mac(result.e2i, a.e123oi, b.e13i);
    result.e2i = mac(result.e2i, a.e123oi, b.e13i);

    result.e12i = mac(result.e12i, a.scalar, b.e12i);
    result.e12i = mac(result.e12i, a.e1, b.e2i);
    result.e12i = macSub(result.e12i, a.e2, b.e1i);
    result.e12i = macSub(result.e12i, a.e12, b.ei);
    result.e12i = mac(result.e12i, a.e3, b.e123i);
    result.e12i = mac(result.e12i, a.e13, b.e23i);
    result.e12i = macSub(result.e12i, a.e23, b.e13i);
    result.e12i = macSub(result.e12i, a.e123, b.e3i);
    result.e12i = mac(result.e12i, a.ei, b.e12);
    result.e12i = macSub(result.e12i, a.ei, b.e12oi);
    result.e12i = mac(result.e12i, a.e1i, b.e2);
    result.e12i = macSub(result.e12i, a.e1i, b.e2oi);
    result.e12i = macSub(result.e12i, a.e2i, b.e1);
    result.e12i = mac(result.e12i, a.e2i, b.e1oi);
    result.e12i = macSub(result.e12i, a.e12i, b.scalar);
    result.e12i = mac(result.e12i, a.e12i, b.eoi);
    result.e12i = mac(result.e12i, a.e3i, b.e123);
    result.e12i = macSub(result.e12i, a.e3i, b.e123oi);
    result.e12i = mac(result.e12i, a.e13i, b.e23);
    result.e12i = macSub(result.e12i, a.e13i, b.e23oi);
    result.e12i = macSub(result.e12i, a.e23i, b.e13);
    result.e12i = mac(result.e12i, a.e23i, b.e13oi);
    result.e12i = macSub(result.e12i, a.e123i, b.e3);
    result.e12i = mac(result.e12i, a.e123i, b.e3oi);
    result.e12i = macSub(result.e12i, a.eoi, b.e12i);
    result.e12i = macSub(result.e12i, a.eoi, b.e12i);
    result.e12i = macSub(result.e12i, a.e1oi, b.e2i);
    result.e12i = macSub(result.e12i, a.e1oi, b.e2i);
    result.e12i = mac(result.e12i, a.e2oi, b.e1i);
    result.e12i = mac(result.e12i, a.e2oi, b.e1i);
    result.e12i = mac(result.e12i, a.e12oi, b.ei);
    result.e12i = mac(result.e12i, a.e12oi, b.ei);
    result.e12i = macSub(result.e12i, a.e3oi, b.e123i);
    result.e12i = macSub(result.e12i, a.e3oi, b.e123i);
    result.e12i = macSub(result.e12i, a.e13oi, b.e23i);
    result.e12i = macSub(result.e12i, a.e13oi, b.e23i);
    result.e12i = mac(result.e12i, a.e23oi, b.e13i);
    result.e12i = mac(result.e12i, a.e23oi, b.e13i);
    result.e12i = mac(result.e12i, a.e123oi, b.e3i);
    result.e12i = mac(result.e12i, a.e123oi, b.e3i);

    result.e3i = mac(result.e3i, a.scalar, b.e3i);
    result.e3i = mac(result.e3i, a.e1, b.e13i);
    result.e3i = mac(result.e3i, a.e2, b.e23i);
    result.e3i = mac(result.e3i, a.e12, b.e123i);
    result.e3i = mac(result.e3i, a.e3, b.ei);
    result.e3i = mac(result.e3i, a.e13, b.e1i);
    result.e3i = mac(result.e3i, a.e23, b.e2i);
    result.e3i = mac(result.e3i, a.e123, b.e12i);
    result.e3i = macSub(result.e3i, a.ei, b.e3);
    result.e3i = mac(result.e3i, a.ei, b.e3oi);
    result.e3i = macSub(result.e3i, a.e1i, b.e13);
    result.e3i = mac(result.e3i, a.e1i, b.e13oi);
    result.e3i = macSub(result.e3i, a.e2i, b.e23);
    result.e3i = mac(result.e3i, a.e2i, b.e23oi);
    result.e3i = macSub(result.e3i, a.e12i, b.e123);
    result.e3i = mac(result.e3i, a.e12i, b.e123oi);
    result.e3i = macSub(result.e3i, a.e3i, b.scalar);
    result.e3i = mac(result.e3i, a.e3i, b.eoi);
    result.e3i = macSub(result.e3i, a.e13i, b.e1);
    result.e3i = mac(result.e3i, a.e13i, b.e1oi);
    result.e3i = macSub(result.e3i, a.e23i, b.e2);
    result.e3i = mac(result.e3i, a.e23i, b.e2oi);
    result.e3i = macSub(result.e3i, a.e123i, b.e12);
    result.e3i = mac(result.e3i, a.e123i, b.e12oi);
    result.e3i = macSub(result.e3i, a.eoi, b.e3i);
    result.e3i = macSub(result.e3i, a.eoi, b.e3i);
    result.e3i = macSub(result.e3i, a.e1oi, b.e13i);
    result.e3i = macSub(result.e3i, a.e1oi, b.e13i);
    result.e3i = macSub(result.e3i, a.e2oi, b.e23i);
    result.e3i = macSub(result.e3i, a.e2oi, b.e23i);
    result.e3i = macSub(result.e3i, a.e12oi, b.e123i);
    result.e3i = macSub(result.e3i, a.e12oi, b.e123i);
    result.e3i = macSub(result.e3i, a.e3oi, b.ei);
    result.e3i = macSub(result.e3i, a.e3oi, b.ei);
    result.e3i = macSub(result.e3i, a.e13oi, b.e1i);
    result.e3i = macSub(result.e3i, a.e13oi, b.e1i);
    result.e3i = macSub(result.e3i, a.e23oi, b.e2i);
    result.e3i = macSub(result.e3i, a.e23oi, b.e2i);
    result.e3i = macSub(result.e3i, a.e123oi, b.e12i);
    result.e3i = macSub(result.e3i, a.e123oi, b.e12i);

    result.e13i = mac(result.e13i, a.scalar, b.e13i);
    result.e13i = mac(result.e13i, a.e1, b.e3i);
    result.e13i = macSub(result.e13i, a.e2, b.e123i);
    result.e13i = macSub(result.e13i, a.e12, b.e23i);
    result.e13i = macSub(result.e13i, a.e3, b.e1i);
    result.e13i = macSub(result.e13i, a.e13, b.ei);
    result.e13i = mac(result.e13i, a.e23, b.e12i);
    result.e13i = mac(result.e13i, a.e123, b.e2i);
    result.e13i = mac(result.e13i, a.ei, b.e13);
    result.e13i = macSub(result.e13i, a.ei, b.e13oi);
    result.e13i = mac(result.e13i, a.e1i, b.e3);
    result.e13i = macSub(result.e13i, a.e1i, b.e3oi);
    result.e13i = macSub(result.e13i, a.e2i, b.e123);
    result.e13i = mac(result.e13i, a.e2i, b.e123oi);
    result.e13i = macSub(result.e13i, a.e12i, b.e23);
    result.e13i = mac(result.e13i, a.e12i, b.e23oi);
    result.e13i = macSub(result.e13i, a.e3i, b.e1);
    result.e13i = mac(result.e13i, a.e3i, b.e1oi);
    result.e13i = macSub(result.e13i, a.e13i, b.scalar);
    result.e13i = mac(result.e13i, a.e13i, b.eoi);
    result.e13i = mac(result.e13i, a.e23i, b.e12);
    result.e13i = macSub(result.e13i, a.e23i, b.e12oi);
    result.e13i = mac(result.e13i, a.e123i, b.e2);
    result.e13i = macSub(result.e13i, a.e123i, b.e2oi);
    result.e13i = macSub(result.e13i, a.eoi, b.e13i);
    result.e13i = macSub(result.e13i, a.eoi, b.e13i);
    result.e13i = macSub(result.e13i, a.e1oi, b.e3i);
    result.e13i = macSub(result.e13i, a.e1oi, b.e3i);
    result.e13i = mac(result.e13i, a.e2oi, b.e123i);
    result.e13i = mac(result.e13i, a.e2oi, b.e123i);
    result.e13i = mac(result.e13i, a.e12oi, b.e23i);
    result.e13i = mac(result.e13i, a.e12oi, b.e23i);
    result.e13i = mac(result.e13i, a.e3oi, b.e1i);
    result.e13i = mac(result.e13i, a.e3oi, b.e1i);
    result.e13i = mac(result.e13i, a.e13oi, b.ei);
    result.e13i = mac(result.e13i, a.e13oi, b.ei);
    result.e13i = macSub(result.e13i, a.e23oi, b.e12i);
    result.e13i = macSub(result.e13i, a.e23oi, b.e12i);
    result.e13i = macSub(result.e13i, a.e123oi, b.e2i);
    result.e13i = macSub(result.e13i, a.e123oi, b.e2i);

    result.e23i = mac(result.e23i, a.scalar, b.e23i);
    result.e23i = mac(result.e23i, a.e1, b.e123i);
    result.e23i = mac(result.e23i, a.e2, b.e3i);
    result.e23i = mac(result.e23i, a.e12, b.e13i);
    result.e23i = macSub(result.e23i, a.e3, b.e2i);
    result.e23i = macSub(result.e23i, a.e13, b.e12i);
    result.e23i = macSub(result.e23i, a.e23, b.ei);
    result.e23i = macSub(result.e23i, a.e123, b.e1i);
    result.e23i = mac(result.e23i, a.ei, b.e23);
    result.e23i = macSub(result.e23i, a.ei, b.e23oi);
    result.e23i = mac(result.e23i, a.e1i, b.e123);
    result.e23i = macSub(result.e23i, a.e1i, b.e123oi);
    result.e23i = mac(result.e23i, a.e2i, b.e3);
    result.e23i = macSub(result.e23i, a.e2i, b.e3oi);
    result.e23i = mac(result.e23i, a.e12i, b.e13);
    result.e23i = macSub(result.e23i, a.e12i, b.e13oi);
    result.e23i = macSub(result.e23i, a.e3i, b.e2);
    result.e23i = mac(result.e23i, a.e3i, b.e2oi);
    result.e23i = macSub(result.e23i, a.e13i, b.e12);
    result.e23i = mac(result.e23i, a.e13i, b.e12oi);
    result.e23i = macSub(result.e23i, a.e23i, b.scalar);
    result.e23i = mac(result.e23i, a.e23i, b.eoi);
    result.e23i = macSub(result.e23i, a.e123i, b.e1);
    result.e23i = mac(result.e23i, a.e123i, b.e1oi);
    result.e23i = macSub(result.e23i, a.eoi, b.e23i);
    result.e23i = macSub(result.e23i, a.eoi, b.e23i);
    result.e23i = macSub(result.e23i, a.e1oi, b.e123i);
    result.e23i = macSub(result.e23i, a.e1oi, b.e123i);
    result.e23i = macSub(result.e23i, a.e2oi, b.e3i);
    result.e23i = macSub(result.e23i, a.e2oi, b.e3i);
    result.e23i = macSub(result.e23i, a.e12oi, b.e13i);
    result.e23i = macSub(result.e23i, a.e12oi, b.e13i);
    result.e23i = mac(result.e23i, a.e3oi, b.e2i);
    result.e23i = mac(result.e23i, a.e3oi, b.e2i);
    result.e23i = mac(result.e23i, a.e13oi, b.e12i);
    result.e23i = mac(result.e23i, a.e13oi, b.e12i);
    result.e23i = mac(result.e23i, a.e23oi, b.ei);
    result.e23i = mac(result.e23i, a.e23oi, b.ei);
    result.e23i = mac(result.e23i, a.e123oi, b.e1i);
    result.e23i = mac(result.e23i, a.e123oi, b.e1i);

    result.e123i = mac(result.e123i, a.scalar, b.e123i);
    result.e123i = mac(result.e123i, a.e1, b.e23i);
    result.e123i = macSub(result.e123i, a.e2, b.e13i);
    result.e123i = macSub(result.e123i, a.e12, b.e3i);
    result.e123i = mac(result.e123i, a.e3, b.e12i);
    result.e123i = mac(result.e123i, a.e13, b.e2i);
    result.e123i = macSub(result.e123i, a.e23, b.e1i);
    result.e123i = macSub(result.e123i, a.e123, b.ei);
    result.e123i = macSub(result.e123i, a.ei, b.e123);
    result.e123i = mac(result.e123i, a.ei, b.e123oi);
    result.e123i = macSub(result.e123i, a.e1i, b.e23);
    result.e123i = mac(result.e123i, a.e1i, b.e23oi);
    result.e123i = mac(result.e123i, a.e2i, b.e13);
    result.e123i = macSub(result.e123i, a.e2i, b.e13oi);
    result.e123i = mac(result.e123i, a.e12i, b.e3);
    result.e123i = macSub(result.e123i, a.e12i, b.e3oi);
    result.e123i = macSub(result.e123i, a.e3i, b.e12);
    result.e123i = mac(result.e123i, a.e3i, b.e12oi);
    result.e123i = macSub(result.e123i, a.e13i, b.e2);
    result.e123i = mac(result.e123i, a.e13i, b.e2oi);
    result.e123i = mac(result.e123i, a.e23i, b.e1);
    result.e123i = macSub(result.e123i, a.e23i, b.e1oi);
    result.e123i = mac(result.e123i, a.e123i, b.scalar);
    result.e123i = macSub(result.e123i, a.e123i, b.eoi);
    result.e123i = macSub(result.e123i, a.eoi, b.e123i);
    result.e123i = macSub(result.e123i, a.eoi, b.e123i);
    result.e123i = macSub(result.e123i, a.e1oi, b.e23i);
    result.e123i = macSub(result.e123i, a.e1oi, b.e23i);
    result.e123i = mac(result.e123i, a.e2oi, b.e13i);
    result.e123i = mac(result.e123i, a.e2oi, b.e13i);
    result.e123i = mac(result.e123i, a.e12oi, b.e3i);
    result.e123i = mac(result.e123i, a.e12oi, b.e3i);
    result.e123i = macSub(result.e123i, a.e3oi, b.e12i);
    result.e123i = macSub(result.e123i, a.e3oi, b.e12i);
    result.e123i = macSub(result.e123i, a.e13oi, b.e2i);
    result.e123i = macSub(result.e123i, a.e13oi, b.e2i);
    result.e123i = mac(result.e123i, a.e23oi, b.e1i);
    result.e123i = mac(result.e123i, a.e23oi, b.e1i);
    result.e123i = mac(result.e123i, a.e123oi, b.ei);
    result.e123i = mac(result.e123i, a.e123oi, b.ei);

    result.eoi = mac(result.eoi, a.scalar, b.eoi);
    result.eoi = mac(result.eoi, a.e1, b.e1oi);
    result.eoi = mac(result.eoi, a.e2, b.e2oi);
    result.eoi = mac(result.eoi, a.e12, b.e12oi);
    result.eoi = mac(result.eoi, a.e3, b.e3oi);
    result.eoi = mac(result.eoi, a.e13, b.e13oi);
    result.eoi = mac(result.eoi, a.e23, b.e23oi);
    result.eoi = mac(result.eoi, a.e123, b.e123oi);
    result.eoi = mac(result.eoi, a.eo, b.ei);
    result.eoi = mac(result.eoi, a.e1o, b.e1i);
    result.eoi = mac(result.eoi, a.e2o, b.e2i);
    result.eoi = mac(result.eoi, a.e12o, b.e12i);
    result.eoi = mac(result.eoi, a.e3o, b.e3i);
    result.eoi = mac(result.eoi, a.e13o, b.e13i);
    result.eoi = mac(result.eoi, a.e23o, b.e23i);
    result.eoi = mac(result.eoi, a.e123o, b.e123i);
    result.eoi = macSub(result.eoi, a.ei, b.eo);
    result.eoi = macSub(result.eoi, a.e1i, b.e1o);
    result.eoi = macSub(result.eoi, a.e2i, b.e2o);
    result.eoi = macSub(result.eoi, a.e12i, b.e12o);
    result.eoi = macSub(result.eoi, a.e3i, b.e3o);
    result.eoi = macSub(result.eoi, a.e13i, b.e13o);
    result.eoi = macSub(result.eoi, a.e23i, b.e23o);
    result.eoi = macSub(result.eoi, a.e123i, b.e123o);
    result.eoi = macSub(result.eoi, a.eoi, b.scalar);
    result.eoi = macSub(result.eoi, a.eoi, b.eoi);
    result.eoi = macSub(result.eoi, a.e1oi, b.e1);
    result.eoi = macSub(result.eoi, a.e1oi, b.e1oi);
    result.eoi = macSub(result.eoi, a.e2oi, b.e2);
    result.eoi = macSub(result.eoi, a.e2oi, b.e2oi);
    result.eoi = macSub(result.eoi, a.e12oi, b.e12);
    result.eoi = macSub(result.eoi, a.e12oi, b.e12oi);
    result.eoi = macSub(result.eoi, a.e3oi, b.e3);
    result.eoi = macSub(result.eoi, a.e3oi, b.e3oi);
    result.eoi = macSub(result.eoi, a.e13oi, b.e13);
    result.eoi = macSub(result.eoi, a.e13oi, b.e13oi);
    result.eoi = macSub(result.eoi, a.e23oi, b.e23);
    result.eoi = macSub(result.eoi, a.e23oi, b.e23oi);
    result.eoi = macSub(result.eoi, a.e123oi, b.e123);
    result.eoi = macSub(result.eoi, a.e123oi, b.e123oi);

    result.e1oi = mac(result.e1oi, a.scalar, b.e1oi);
    result.e1oi = mac(result.e1oi, a.e1, b.eoi);
    result.e1oi = macSub(result.e1oi, a.e2, b.e12oi);
    result.e1oi = macSub(result.e1oi, a.e12, b.e2oi);
    result.e1oi = macSub(result.e1oi, a.e3, b.e13oi);
    result.e1oi = macSub(result.e1oi, a.e13, b.e3oi);
    result.e1oi = mac(result.e1oi, a.e23, b.e123oi);
    result.e1oi = mac(result.e1oi, a.e123, b.e23oi);
    result.e1oi = macSub(result.e1oi, a.eo, b.e1i);
    result.e1oi = macSub(result.e1oi, a.e1o, b.ei);
    result.e1oi = mac(result.e1oi, a.e2o, b.e12i);
    result.e1oi = mac(result.e1oi, a.e12o, b.e2i);
    result.e1oi = mac(result.e1oi, a.e3o, b.e13i);
    result.e1oi = mac(result.e1oi, a.e13o, b.e3i);
    result.e1oi = macSub(result.e1oi, a.e23o, b.e123i);
    result.e1oi = macSub(result.e1oi, a.e123o, b.e23i);
    result.e1oi = mac(result.e1oi, a.ei, b.e1o);
    result.e1oi = mac(result.e1oi, a.e1i, b.eo);
    result.e1oi = macSub(result.e1oi, a.e2i, b.e12o);
    result.e1oi = macSub(result.e1oi, a.e12i, b.e2o);
    result.e1oi = macSub(result.e1oi, a.e3i, b.e13o);
    result.e1oi = macSub(result.e1oi, a.e13i, b.e3o);
    result.e1oi = mac(result.e1oi, a.e23i, b.e123o);
    result.e1oi = mac(result.e1oi, a.e123i, b.e23o);
    result.e1oi = macSub(result.e1oi, a.eoi, b.e1);
    result.e1oi = macSub(result.e1oi, a.eoi, b.e1oi);
    result.e1oi = macSub(result.e1oi, a.e1oi, b.scalar);
    result.e1oi = macSub(result.e1oi, a.e1oi, b.eoi);
    result.e1oi = mac(result.e1oi, a.e2oi, b.e12);
    result.e1oi = mac(result.e1oi, a.e2oi, b.e12oi);
    result.e1oi = mac(result.e1oi, a.e12oi, b.e2);
    result.e1oi = mac(result.e1oi, a.e12oi, b.e2oi);
    result.e1oi = mac(result.e1oi, a.e3oi, b.e13);
    result.e1oi = mac(result.e1oi, a.e3oi, b.e13oi);
    result.e1oi = mac(result.e1oi, a.e13oi, b.e3);
    result.e1oi = mac(result.e1oi, a.e13oi, b.e3oi);
    result.e1oi = macSub(result.e1oi, a.e23oi, b.e123);
    result.e1oi = macSub(result.e1oi, a.e23oi, b.e123oi);
    result.e1oi = macSub(result.e1oi, a.e123oi, b.e23);
    result.e1oi = macSub(result.e1oi, a.e123oi, b.e23oi);

    result.e2oi = mac(result.e2oi, a.scalar, b.e2oi);
    result.e2oi = mac(result.e2oi, a.e1, b.e12oi);
    result.e2oi = mac(result.e2oi, a.e2, b.eoi);
    result.e2oi = mac(result.e2oi, a.e12, b.e1oi);
    result.e2oi = macSub(result.e2oi, a.e3, b.e23oi);
    result.e2oi = macSub(result.e2oi, a.e13, b.e123oi);
    result.e2oi = macSub(result.e2oi, a.e23, b.e3oi);
    result.e2oi = macSub(result.e2oi, a.e123, b.e13oi);
    result.e2oi = macSub(result.e2oi, a.eo, b.e2i);
    result.e2oi = macSub(result.e2oi, a.e1o, b.e12i);
    result.e2oi = macSub(result.e2oi, a.e2o, b.ei);
    result.e2oi = macSub(result.e2oi, a.e12o, b.e1i);
    result.e2oi = mac(result.e2oi, a.e3o, b.e23i);
    result.e2oi = mac(result.e2oi, a.e13o, b.e123i);
    result.e2oi = mac(result.e2oi, a.e23o, b.e3i);
    result.e2oi = mac(result.e2oi, a.e123o, b.e13i);
    result.e2oi = mac(result.e2oi, a.ei, b.e2o);
    result.e2oi = mac(result.e2oi, a.e1i, b.e12o);
    result.e2oi = mac(result.e2oi, a.e2i, b.eo);
    result.e2oi = mac(result.e2oi, a.e12i, b.e1o);
    result.e2oi = macSub(result.e2oi, a.e3i, b.e23o);
    result.e2oi = macSub(result.e2oi, a.e13i, b.e123o);
    result.e2oi = macSub(result.e2oi, a.e23i, b.e3o);
    result.e2oi = macSub(result.e2oi, a.e123i, b.e13o);
    result.e2oi = macSub(result.e2oi, a.eoi, b.e2);
    result.e2oi = macSub(result.e2oi, a.eoi, b.e2oi);
    result.e2oi = macSub(result.e2oi, a.e1oi, b.e12);
    result.e2oi = macSub(result.e2oi, a.e1oi, b.e12oi);
    result.e2oi = macSub(result.e2oi, a.e2oi, b.scalar);
    result.e2oi = macSub(result.e2oi, a.e2oi, b.eoi);
    result.e2oi = macSub(result.e2oi, a.e12oi, b.e1);
    result.e2oi = macSub(result.e2oi, a.e12oi, b.e1oi);
    result.e2oi = mac(result.e2oi, a.e3oi, b.e23);
    result.e2oi = mac(result.e2oi, a.e3oi, b.e23oi);
    result.e2oi = mac(result.e2oi, a.e13oi, b.e123);
    result.e2oi = mac(result.e2oi, a.e13oi, b.e123oi);
    result.e2oi = mac(result.e2oi, a.e23oi, b.e3);
    result.e2oi = mac(result.e2oi, a.e23oi, b.e3oi);
    result.e2oi = mac(result.e2oi, a.e123oi, b.e13);
    result.e2oi = mac(result.e2oi, a.e123oi, b.e13oi);

    result.e12oi = mac(result.e12oi, a.scalar, b.e12oi);
    result.e12oi = mac(result.e12oi, a.e1, b.e2oi);
    result.e12oi = macSub(result.e12oi, a.e2, b.e1oi);
    result.e12oi = macSub(result.e12oi, a.e12, b.eoi);
    result.e12oi = mac(result.e12oi, a.e3, b.e123oi);
    result.e12oi = mac(result.e12oi, a.e13, b.e23oi);
    result.e12oi = macSub(result.e12oi, a.e23, b.e13oi);
    result.e12oi = macSub(result.e12oi, a.e123, b.e3oi);
    result.e12oi = mac(result.e12oi, a.eo, b.e12i);
    result.e12oi = mac(result.e12oi, a.e1o, b.e2i);
    result.e12oi = macSub(result.e12oi, a.e2o, b.e1i);
    result.e12oi = macSub(result.e12oi, a.e12o, b.ei);
    result.e12oi = mac(result.e12oi, a.e3o, b.e123i);
    result.e12oi = mac(result.e12oi, a.e13o, b.e23i);
    result.e12oi = macSub(result.e12oi, a.e23o, b.e13i);
    result.e12oi = macSub(result.e12oi, a.e123o, b.e3i);
    result.e12oi = macSub(result.e12oi, a.ei, b.e12o);
    result.e12oi = macSub(result.e12oi, a.e1i, b.e2o);
    result.e12oi = mac(result.e12oi, a.e2i, b.e1o);
    result.e12oi = mac(result.e12oi, a.e12i, b.eo);
    result.e12oi = macSub(result.e12oi, a.e3i, b.e123o);
    result.e12oi = macSub(result.e12oi, a.e13i, b.e23o);
    result.e12oi = mac(result.e12oi, a.e23i, b.e13o);
    result.e12oi = mac(result.e12oi, a.e123i, b.e3o);
    result.e12oi = macSub(result.e12oi, a.eoi, b.e12);
    result.e12oi = macSub(result.e12oi, a.eoi, b.e12oi);
    result.e12oi = macSub(result.e12oi, a.e1oi, b.e2);
    result.e12oi = macSub(result.e12oi, a.e1oi, b.e2oi);
    result.e12oi = mac(result.e12oi, a.e2oi, b.e1);
    result.e12oi = mac(result.e12oi, a.e2oi, b.e1oi);
    result.e12oi = mac(result.e12oi, a.e12oi, b.scalar);
    result.e12oi = mac(result.e12oi, a.e12oi, b.eoi);
    result.e12oi = macSub(result.e12oi, a.e3oi, b.e123);
    result.e12oi = macSub(result.e12oi, a.e3oi, b.e123oi);
    result.e12oi = macSub(result.e12oi, a.e13oi, b.e23);
    result.e12oi = macSub(result.e12oi, a.e13oi, b.e23oi);
    result.e12oi = mac(result.e12oi, a.e23oi, b.e13);
    result.e12oi = mac(result.e12oi, a.e23oi, b.e13oi);
    result.e12oi = mac(result.e12oi, a.e123oi, b.e3);
    result.e12oi = mac(result.e12oi, a.e123oi, b.e3oi);

    result.e3oi = mac(result.e3oi, a.scalar, b.e3oi);
    result.e3oi = mac(result.e3oi, a.e1, b.e13oi);
    result.e3oi = mac(result.e3oi, a.e2, b.e23oi);
    result.e3oi = mac(result.e3oi, a.e12, b.e123oi);
    result.e3oi = mac(result.e3oi, a.e3, b.eoi);
    result.e3oi = mac(result.e3oi, a.e13, b.e1oi);
    result.e3oi = mac(result.e3oi, a.e23, b.e2oi);
    result.e3oi = mac(result.e3oi, a.e123, b.e12oi);
    result.e3oi = macSub(result.e3oi, a.eo, b.e3i);
    result.e3oi = macSub(result.e3oi, a.e1o, b.e13i);
    result.e3oi = macSub(result.e3oi, a.e2o, b.e23i);
    result.e3oi = macSub(result.e3oi, a.e12o, b.e123i);
    result.e3oi = macSub(result.e3oi, a.e3o, b.ei);
    result.e3oi = macSub(result.e3oi, a.e13o, b.e1i);
    result.e3oi = macSub(result.e3oi, a.e23o, b.e2i);
    result.e3oi = macSub(result.e3oi, a.e123o, b.e12i);
    result.e3oi = mac(result.e3oi, a.ei, b.e3o);
    result.e3oi = mac(result.e3oi, a.e1i, b.e13o);
    result.e3oi = mac(result.e3oi, a.e2i, b.e23o);
    result.e3oi = mac(result.e3oi, a.e12i, b.e123o);
    result.e3oi = mac(result.e3oi, a.e3i, b.eo);
    result.e3oi = mac(result.e3oi, a.e13i, b.e1o);
    result.e3oi = mac(result.e3oi, a.e23i, b.e2o);
    result.e3oi = mac(result.e3oi, a.e123i, b.e12o);
    result.e3oi = macSub(result.e3oi, a.eoi, b.e3);
    result.e3oi = macSub(result.e3oi, a.eoi, b.e3oi);
    result.e3oi = macSub(result.e3oi, a.e1oi, b.e13);
    result.e3oi = macSub(result.e3oi, a.e1oi, b.e13oi);
    result.e3oi = macSub(result.e3oi, a.e2oi, b.e23);
    result.e3oi = macSub(result.e3oi, a.e2oi, b.e23oi);
    result.e3oi = macSub(result.e3oi, a.e12oi, b.e123);
    result.e3oi = macSub(result.e3oi, a.e12oi, b.e123oi);
    result.e3oi = macSub(result.e3oi, a.e3oi, b.scalar);
    result.e3oi = macSub(result.e3oi, a.e3oi, b.eoi);
    result.e3oi = macSub(result.e3oi, a.e13oi, b.e1);
    result.e3oi = macSub(result.e3oi, a.e13oi, b.e1oi);
    result.e3oi = macSub(result.e3oi, a.e23oi, b.e2);
    result.e3oi = macSub(result.e3oi, a.e23oi, b.e2oi);
    result.e3oi = macSub(result.e3oi, a.e123oi, b.e12);
    result.e3oi = macSub(result.e3oi, a.e123oi, b.e12oi);

    result.e13oi = mac(result.e13oi, a.scalar, b.e13oi);
    result.e13oi = mac(result.e13oi, a.e1, b.e3oi);
    result.e13oi = macSub(result.e13oi, a.e2, b.e123oi);
    result.e13oi = macSub(result.e13oi, a.e12, b.e23oi);
    result.e13oi = macSub(result.e13oi, a.e3, b.e1oi);
    result.e13oi = macSub(result.e13oi, a.e13, b.eoi);
    result.e13oi = mac(result.e13oi, a.e23, b.e12oi);
    result.e13oi = mac(result.e13oi, a.e123, b.e2oi);
    result.e13oi = mac(result.e13oi, a.eo, b.e13i);
    result.e13oi = mac(result.e13oi, a.e1o, b.e3i);
    result.e13oi = macSub(result.e13oi, a.e2o, b.e123i);
    result.e13oi = macSub(result.e13oi, a.e12o, b.e23i);
    result.e13oi = macSub(result.e13oi, a.e3o, b.e1i);
    result.e13oi = macSub(result.e13oi, a.e13o, b.ei);
    result.e13oi = mac(result.e13oi, a.e23o, b.e12i);
    result.e13oi = mac(result.e13oi, a.e123o, b.e2i);
    result.e13oi = macSub(result.e13oi, a.ei, b.e13o);
    result.e13oi = macSub(result.e13oi, a.e1i, b.e3o);
    result.e13oi = mac(result.e13oi, a.e2i, b.e123o);
    result.e13oi = mac(result.e13oi, a.e12i, b.e23o);
    result.e13oi = mac(result.e13oi, a.e3i, b.e1o);
    result.e13oi = mac(result.e13oi, a.e13i, b.eo);
    result.e13oi = macSub(result.e13oi, a.e23i, b.e12o);
    result.e13oi = macSub(result.e13oi, a.e123i, b.e2o);
    result.e13oi = macSub(result.e13oi, a.eoi, b.e13);
    result.e13oi = macSub(result.e13oi, a.eoi, b.e13oi);
    result.e13oi = macSub(result.e13oi, a.e1oi, b.e3);
    result.e13oi = macSub(result.e13oi, a.e1oi, b.e3oi);
    result.e13oi = mac(result.e13oi, a.e2oi, b.e123);
    result.e13oi = mac(result.e13oi, a.e2oi, b.e123oi);
    result.e13oi = mac(result.e13oi, a.e12oi, b.e23);
    result.e13oi = mac(result.e13oi, a.e12oi, b.e23oi);
    result.e13oi = mac(result.e13oi, a.e3oi, b.e1);
    result.e13oi = mac(result.e13oi, a.e3oi, b.e1oi);
    result.e13oi = mac(result.e13oi, a.e13oi, b.scalar);
    result.e13oi = mac(result.e13oi, a.e13oi, b.eoi);
    result.e13oi = macSub(result.e13oi, a.e23oi, b.e12);
    result.e13oi = macSub(result.e13oi, a.e23oi, b.e12oi);
    result.e13oi = macSub(result.e13oi, a.e123oi, b.e2);
    result.e13oi = macSub(result.e13oi, a.e123oi, b.e2oi);

    result.e23oi = mac(result.e23oi, a.scalar, b.e23oi);
    result.e23oi = mac(result.e23oi, a.e1, b.e123oi);
    result.e23oi = mac(result.e23oi, a.e2, b.e3oi);
    result.e23oi = mac(result.e23oi, a.e12, b.e13oi);
    result.e23oi = macSub(result.e23oi, a.e3, b.e2oi);
    result.e23oi = macSub(result.e23oi, a.e13, b.e12oi);
    result.e23oi = macSub(result.e23oi, a.e23, b.eoi);
    result.e23oi = macSub(result.e23oi, a.e123, b.e1oi);
    result.e23oi = mac(result.e23oi, a.eo, b.e23i);
    result.e23oi = mac(result.e23oi, a.e1o, b.e123i);
    result.e23oi = mac(result.e23oi, a.e2o, b.e3i);
    result.e23oi = mac(result.e23oi, a.e12o, b.e13i);
    result.e23oi = macSub(result.e23oi, a.e3o, b.e2i);
    result.e23oi = macSub(result.e23oi, a.e13o, b.e12i);
    result.e23oi = macSub(result.e23oi, a.e23o, b.ei);
    result.e23oi = macSub(result.e23oi, a.e123o, b.e1i);
    result.e23oi = macSub(result.e23oi, a.ei, b.e23o);
    result.e23oi = macSub(result.e23oi, a.e1i, b.e123o);
    result.e23oi = macSub(result.e23oi, a.e2i, b.e3o);
    result.e23oi = macSub(result.e23oi, a.e12i, b.e13o);
    result.e23oi = mac(result.e23oi, a.e3i, b.e2o);
    result.e23oi = mac(result.e23oi, a.e13i, b.e12o);
    result.e23oi = mac(result.e23oi, a.e23i, b.eo);
    result.e23oi = mac(result.e23oi, a.e123i, b.e1o);
    result.e23oi = macSub(result.e23oi, a.eoi, b.e23);
    result.e23oi = macSub(result.e23oi, a.eoi, b.e23oi);
    result.e23oi = macSub(result.e23oi, a.e1oi, b.e123);
    result.e23oi = macSub(result.e23oi, a.e1oi, b.e123oi);
    result.e23oi = macSub(result.e23oi, a.e2oi, b.e3);
    result.e23oi = macSub(result.e23oi, a.e2oi, b.e3oi);
    result.e23oi = macSub(result.e23oi, a.e12oi, b.e13);
    result.e23oi = macSub(result.e23oi, a.e12oi, b.e13oi);
    result.e23oi = mac(result.e23oi, a.e3oi, b.e2);
    result.e23oi = mac(result.e23oi, a.e3oi, b.e2oi);
    result.e23oi = mac(result.e23oi, a.e13oi, b.e12);
    result.e23oi = mac(result.e23oi, a.e13oi, b.e12oi);
    result.e23oi = mac(result.e23oi, a.e23oi, b.scalar);
    result.e23oi = mac(result.e23oi, a.e23oi, b.eoi);
    result.e23oi = mac(result.e23oi, a.e123oi, b.e1);
    result.e23oi = mac(result.e23oi, a.e123oi, b.e1oi);

    result.e123oi = mac(result.e123oi, a.scalar, b.e123oi);
    result.e123oi = mac(result.e123oi, a.e1, b.e23oi);
    result.e123oi = macSub(result.e123oi, a.e2, b.e13oi);
    result.e123oi = macSub(result.e123oi, a.e12, b.e3oi);
    result.e123oi = mac(result.e123oi, a.e3, b.e12oi);
    result.e123oi = mac(result.e123oi, a.e13, b.e2oi);
    result.e123oi = macSub(result.e123oi, a.e23, b.e1oi);
    result.e123oi = macSub(result.e123oi, a.e123, b.eoi);
    result.e123oi = macSub(result.e123oi, a.eo, b.e123i);
    result.e123oi = macSub(result.e123oi, a.e1o, b.e23i);
    result.e123oi = mac(result.e123oi, a.e2o, b.e13i);
    result.e123oi = mac(result.e123oi, a.e12o, b.e3i);
    result.e123oi = macSub(result.e123oi, a.e3o, b.e12i);
    result.e123oi = macSub(result.e123oi, a.e13o, b.e2i);
    result.e123oi = mac(result.e123oi, a.e23o, b.e1i);
    result.e123oi = mac(result.e123oi, a.e123o, b.ei);
    result.e123oi = mac(result.e123oi, a.ei, b.e123o);
    result.e123oi = mac(result.e123oi, a.e1i, b.e23o);
    result.e123oi = macSub(result.e123oi, a.e2i, b.e13o);
    result.e123oi = macSub(result.e123oi, a.e12i, b.e3o);
    result.e123oi = mac(result.e123oi, a.e3i, b.e12o);
    result.e123oi = mac(result.e123oi, a.e13i, b.e2o);
    result.e123oi = macSub(result.e123oi, a.e23i, b.e1o);
    result.e123oi = macSub(result.e123oi, a.e123i, b.eo);
    result.e123oi = macSub(result.e123oi, a.eoi, b.e123);
    result.e123oi = macSub(result.e123oi, a.eoi, b.e123oi);
    result.e123oi = macSub(result.e123oi, a.e1oi, b.e23);
    result.e123oi = macSub(result.e123oi, a.e1oi, b.e23oi);
    result.e123oi = mac(result.e123oi, a.e2oi, b.e13);
    result.e123oi = mac(result.e123oi, a.e2oi, b.e13oi);
    result.e123oi = mac(result.e123oi, a.e12oi, b.e3);
    result.e123oi = mac(result.e123oi, a.e12oi, b.e3oi);
    result.e123oi = macSub(result.e123oi, a.e3oi, b.e12);
    result.e123oi = macSub(result.e123oi, a.e3oi, b.e12oi);
    result.e123oi = macSub(result.e123oi, a.e13oi, b.e2);
    result.e123oi = macSub(result.e123oi, a.e13oi, b.e2oi);
    result.e123oi = mac(result.e123oi, a.e23oi, b.e1);
    result.e123oi = mac(result.e123oi, a.e23oi, b.e1oi);
    result.e123oi = mac(result.e123oi, a.e123oi, b.scalar);
    result.e123oi = mac(result.e123oi, a.e123oi, b.eoi);

    //$display("ga_alu full product: a=%128h, b=%128h, res=%128h", a, b, result);
                  
    return result;

  endfunction

  function automatic ga_multivector_t wedgeProduct(
    ga_multivector_t a,
    ga_multivector_t b
  );
    ga_multivector_t result;
    result = '0;

    result.scalar = mac(result.scalar, a.scalar, b.scalar);

    result.e1 = mac(result.e1, a.scalar, b.e1);
    result.e1 = mac(result.e1, a.e1, b.scalar);

    result.e2 = mac(result.e2, a.scalar, b.e2);
    result.e2 = mac(result.e2, a.e2, b.scalar);

    result.e12 = mac(result.e12, a.scalar, b.e12);
    result.e12 = mac(result.e12, a.e1, b.e2);
    result.e12 = macSub(result.e12, a.e2, b.e1);
    result.e12 = macSub(result.e12, a.e12, b.scalar);

    result.e3 = mac(result.e3, a.scalar, b.e3);
    result.e3 = mac(result.e3, a.e3, b.scalar);

    result.e13 = mac(result.e13, a.scalar, b.e13);
    result.e13 = mac(result.e13, a.e1, b.e3);
    result.e13 = macSub(result.e13, a.e3, b.e1);
    result.e13 = macSub(result.e13, a.e13, b.scalar);

    result.e23 = mac(result.e23, a.scalar, b.e23);
    result.e23 = mac(result.e23, a.e2, b.e3);
    result.e23 = macSub(result.e23, a.e3, b.e2);
    result.e23 = macSub(result.e23, a.e23, b.scalar);

    result.e123 = mac(result.e123, a.scalar, b.e123);
    result.e123 = mac(result.e123, a.e1, b.e23);
    result.e123 = macSub(result.e123, a.e2, b.e13);
    result.e123 = macSub(result.e123, a.e12, b.e3);
    result.e123 = mac(result.e123, a.e3, b.e12);
    result.e123 = mac(result.e123, a.e13, b.e2);
    result.e123 = macSub(result.e123, a.e23, b.e1);
    result.e123 = macSub(result.e123, a.e123, b.scalar);

    result.eo = mac(result.eo, a.scalar, b.eo);
    result.eo = mac(result.eo, a.eo, b.scalar);

    result.e1o = mac(result.e1o, a.scalar, b.e1o);
    result.e1o = mac(result.e1o, a.e1, b.eo);
    result.e1o = macSub(result.e1o, a.eo, b.e1);
    result.e1o = macSub(result.e1o, a.e1o, b.scalar);

    result.e2o = mac(result.e2o, a.scalar, b.e2o);
    result.e2o = mac(result.e2o, a.e2, b.eo);
    result.e2o = macSub(result.e2o, a.eo, b.e2);
    result.e2o = macSub(result.e2o, a.e2o, b.scalar);

    result.e12o = mac(result.e12o, a.scalar, b.e12o);
    result.e12o = mac(result.e12o, a.e1, b.e2o);
    result.e12o = macSub(result.e12o, a.e2, b.e1o);
    result.e12o = macSub(result.e12o, a.e12, b.eo);
    result.e12o = mac(result.e12o, a.eo, b.e12);
    result.e12o = mac(result.e12o, a.e1o, b.e2);
    result.e12o = macSub(result.e12o, a.e2o, b.e1);
    result.e12o = macSub(result.e12o, a.e12o, b.scalar);

    result.e3o = mac(result.e3o, a.scalar, b.e3o);
    result.e3o = mac(result.e3o, a.e3, b.eo);
    result.e3o = macSub(result.e3o, a.eo, b.e3);
    result.e3o = macSub(result.e3o, a.e3o, b.scalar);

    result.e13o = mac(result.e13o, a.scalar, b.e13o);
    result.e13o = mac(result.e13o, a.e1, b.e3o);
    result.e13o = macSub(result.e13o, a.e3, b.e1o);
    result.e13o = macSub(result.e13o, a.e13, b.eo);
    result.e13o = mac(result.e13o, a.eo, b.e13);
    result.e13o = mac(result.e13o, a.e1o, b.e3);
    result.e13o = macSub(result.e13o, a.e3o, b.e1);
    result.e13o = macSub(result.e13o, a.e13o, b.scalar);

    result.e23o = mac(result.e23o, a.scalar, b.e23o);
    result.e23o = mac(result.e23o, a.e2, b.e3o);
    result.e23o = macSub(result.e23o, a.e3, b.e2o);
    result.e23o = macSub(result.e23o, a.e23, b.eo);
    result.e23o = mac(result.e23o, a.eo, b.e23);
    result.e23o = mac(result.e23o, a.e2o, b.e3);
    result.e23o = macSub(result.e23o, a.e3o, b.e2);
    result.e23o = macSub(result.e23o, a.e23o, b.scalar);

    result.e123o = mac(result.e123o, a.scalar, b.e123o);
    result.e123o = mac(result.e123o, a.e1, b.e23o);
    result.e123o = macSub(result.e123o, a.e2, b.e13o);
    result.e123o = macSub(result.e123o, a.e12, b.e3o);
    result.e123o = mac(result.e123o, a.e3, b.e12o);
    result.e123o = mac(result.e123o, a.e13, b.e2o);
    result.e123o = macSub(result.e123o, a.e23, b.e1o);
    result.e123o = macSub(result.e123o, a.e123, b.eo);
    result.e123o = macSub(result.e123o, a.eo, b.e123);
    result.e123o = macSub(result.e123o, a.e1o, b.e23);
    result.e123o = mac(result.e123o, a.e2o, b.e13);
    result.e123o = mac(result.e123o, a.e12o, b.e3);
    result.e123o = macSub(result.e123o, a.e3o, b.e12);
    result.e123o = macSub(result.e123o, a.e13o, b.e2);
    result.e123o = mac(result.e123o, a.e23o, b.e1);
    result.e123o = mac(result.e123o, a.e123o, b.scalar);

    result.ei = mac(result.ei, a.scalar, b.ei);
    result.ei = mac(result.ei, a.ei, b.scalar);

    result.e1i = mac(result.e1i, a.scalar, b.e1i);
    result.e1i = mac(result.e1i, a.e1, b.ei);
    result.e1i = macSub(result.e1i, a.ei, b.e1);
    result.e1i = macSub(result.e1i, a.e1i, b.scalar);

    result.e2i = mac(result.e2i, a.scalar, b.e2i);
    result.e2i = mac(result.e2i, a.e2, b.ei);
    result.e2i = macSub(result.e2i, a.ei, b.e2);
    result.e2i = macSub(result.e2i, a.e2i, b.scalar);

    result.e12i = mac(result.e12i, a.scalar, b.e12i);
    result.e12i = mac(result.e12i, a.e1, b.e2i);
    result.e12i = macSub(result.e12i, a.e2, b.e1i);
    result.e12i = macSub(result.e12i, a.e12, b.ei);
    result.e12i = mac(result.e12i, a.ei, b.e12);
    result.e12i = mac(result.e12i, a.e1i, b.e2);
    result.e12i = macSub(result.e12i, a.e2i, b.e1);
    result.e12i = macSub(result.e12i, a.e12i, b.scalar);

    result.e3i = mac(result.e3i, a.scalar, b.e3i);
    result.e3i = mac(result.e3i, a.e3, b.ei);
    result.e3i = macSub(result.e3i, a.ei, b.e3);
    result.e3i = macSub(result.e3i, a.e3i, b.scalar);

    result.e13i = mac(result.e13i, a.scalar, b.e13i);
    result.e13i = mac(result.e13i, a.e1, b.e3i);
    result.e13i = macSub(result.e13i, a.e3, b.e1i);
    result.e13i = macSub(result.e13i, a.e13, b.ei);
    result.e13i = mac(result.e13i, a.ei, b.e13);
    result.e13i = mac(result.e13i, a.e1i, b.e3);
    result.e13i = macSub(result.e13i, a.e3i, b.e1);
    result.e13i = macSub(result.e13i, a.e13i, b.scalar);

    result.e23i = mac(result.e23i, a.scalar, b.e23i);
    result.e23i = mac(result.e23i, a.e2, b.e3i);
    result.e23i = macSub(result.e23i, a.e3, b.e2i);
    result.e23i = macSub(result.e23i, a.e23, b.ei);
    result.e23i = mac(result.e23i, a.ei, b.e23);
    result.e23i = mac(result.e23i, a.e2i, b.e3);
    result.e23i = macSub(result.e23i, a.e3i, b.e2);
    result.e23i = macSub(result.e23i, a.e23i, b.scalar);

    result.e123i = mac(result.e123i, a.scalar, b.e123i);
    result.e123i = mac(result.e123i, a.e1, b.e23i);
    result.e123i = macSub(result.e123i, a.e2, b.e13i);
    result.e123i = macSub(result.e123i, a.e12, b.e3i);
    result.e123i = mac(result.e123i, a.e3, b.e12i);
    result.e123i = mac(result.e123i, a.e13, b.e2i);
    result.e123i = macSub(result.e123i, a.e23, b.e1i);
    result.e123i = macSub(result.e123i, a.e123, b.ei);
    result.e123i = macSub(result.e123i, a.ei, b.e123);
    result.e123i = macSub(result.e123i, a.e1i, b.e23);
    result.e123i = mac(result.e123i, a.e2i, b.e13);
    result.e123i = mac(result.e123i, a.e12i, b.e3);
    result.e123i = macSub(result.e123i, a.e3i, b.e12);
    result.e123i = macSub(result.e123i, a.e13i, b.e2);
    result.e123i = mac(result.e123i, a.e23i, b.e1);
    result.e123i = mac(result.e123i, a.e123i, b.scalar);

    result.eoi = mac(result.eoi, a.scalar, b.eoi);
    result.eoi = mac(result.eoi, a.eo, b.ei);
    result.eoi = macSub(result.eoi, a.ei, b.eo);
    result.eoi = macSub(result.eoi, a.eoi, b.scalar);

    result.e1oi = mac(result.e1oi, a.scalar, b.e1oi);
    result.e1oi = mac(result.e1oi, a.e1, b.eoi);
    result.e1oi = macSub(result.e1oi, a.eo, b.e1i);
    result.e1oi = macSub(result.e1oi, a.e1o, b.ei);
    result.e1oi = mac(result.e1oi, a.ei, b.e1o);
    result.e1oi = mac(result.e1oi, a.e1i, b.eo);
    result.e1oi = macSub(result.e1oi, a.eoi, b.e1);
    result.e1oi = macSub(result.e1oi, a.e1oi, b.scalar);

    result.e2oi = mac(result.e2oi, a.scalar, b.e2oi);
    result.e2oi = mac(result.e2oi, a.e2, b.eoi);
    result.e2oi = macSub(result.e2oi, a.eo, b.e2i);
    result.e2oi = macSub(result.e2oi, a.e2o, b.ei);
    result.e2oi = mac(result.e2oi, a.ei, b.e2o);
    result.e2oi = mac(result.e2oi, a.e2i, b.eo);
    result.e2oi = macSub(result.e2oi, a.eoi, b.e2);
    result.e2oi = macSub(result.e2oi, a.e2oi, b.scalar);

    result.e12oi = mac(result.e12oi, a.scalar, b.e12oi);
    result.e12oi = mac(result.e12oi, a.e1, b.e2oi);
    result.e12oi = macSub(result.e12oi, a.e2, b.e1oi);
    result.e12oi = macSub(result.e12oi, a.e12, b.eoi);
    result.e12oi = mac(result.e12oi, a.eo, b.e12i);
    result.e12oi = mac(result.e12oi, a.e1o, b.e2i);
    result.e12oi = macSub(result.e12oi, a.e2o, b.e1i);
    result.e12oi = macSub(result.e12oi, a.e12o, b.ei);
    result.e12oi = macSub(result.e12oi, a.ei, b.e12o);
    result.e12oi = macSub(result.e12oi, a.e1i, b.e2o);
    result.e12oi = mac(result.e12oi, a.e2i, b.e1o);
    result.e12oi = mac(result.e12oi, a.e12i, b.eo);
    result.e12oi = macSub(result.e12oi, a.eoi, b.e12);
    result.e12oi = macSub(result.e12oi, a.e1oi, b.e2);
    result.e12oi = mac(result.e12oi, a.e2oi, b.e1);
    result.e12oi = mac(result.e12oi, a.e12oi, b.scalar);

    result.e3oi = mac(result.e3oi, a.scalar, b.e3oi);
    result.e3oi = mac(result.e3oi, a.e3, b.eoi);
    result.e3oi = macSub(result.e3oi, a.eo, b.e3i);
    result.e3oi = macSub(result.e3oi, a.e3o, b.ei);
    result.e3oi = mac(result.e3oi, a.ei, b.e3o);
    result.e3oi = mac(result.e3oi, a.e3i, b.eo);
    result.e3oi = macSub(result.e3oi, a.eoi, b.e3);
    result.e3oi = macSub(result.e3oi, a.e3oi, b.scalar);

    result.e13oi = mac(result.e13oi, a.scalar, b.e13oi);
    result.e13oi = mac(result.e13oi, a.e1, b.e3oi);
    result.e13oi = macSub(result.e13oi, a.e3, b.e1oi);
    result.e13oi = macSub(result.e13oi, a.e13, b.eoi);
    result.e13oi = mac(result.e13oi, a.eo, b.e13i);
    result.e13oi = mac(result.e13oi, a.e1o, b.e3i);
    result.e13oi = macSub(result.e13oi, a.e3o, b.e1i);
    result.e13oi = macSub(result.e13oi, a.e13o, b.ei);
    result.e13oi = macSub(result.e13oi, a.ei, b.e13o);
    result.e13oi = macSub(result.e13oi, a.e1i, b.e3o);
    result.e13oi = mac(result.e13oi, a.e3i, b.e1o);
    result.e13oi = mac(result.e13oi, a.e13i, b.eo);
    result.e13oi = macSub(result.e13oi, a.eoi, b.e13);
    result.e13oi = macSub(result.e13oi, a.e1oi, b.e3);
    result.e13oi = mac(result.e13oi, a.e3oi, b.e1);
    result.e13oi = mac(result.e13oi, a.e13oi, b.scalar);

    result.e23oi = mac(result.e23oi, a.scalar, b.e23oi);
    result.e23oi = mac(result.e23oi, a.e2, b.e3oi);
    result.e23oi = macSub(result.e23oi, a.e3, b.e2oi);
    result.e23oi = macSub(result.e23oi, a.e23, b.eoi);
    result.e23oi = mac(result.e23oi, a.eo, b.e23i);
    result.e23oi = mac(result.e23oi, a.e2o, b.e3i);
    result.e23oi = macSub(result.e23oi, a.e3o, b.e2i);
    result.e23oi = macSub(result.e23oi, a.e23o, b.ei);
    result.e23oi = macSub(result.e23oi, a.ei, b.e23o);
    result.e23oi = macSub(result.e23oi, a.e2i, b.e3o);
    result.e23oi = mac(result.e23oi, a.e3i, b.e2o);
    result.e23oi = mac(result.e23oi, a.e23i, b.eo);
    result.e23oi = macSub(result.e23oi, a.eoi, b.e23);
    result.e23oi = macSub(result.e23oi, a.e2oi, b.e3);
    result.e23oi = mac(result.e23oi, a.e3oi, b.e2);
    result.e23oi = mac(result.e23oi, a.e23oi, b.scalar);

    result.e123oi = mac(result.e123oi, a.scalar, b.e123oi);
    result.e123oi = mac(result.e123oi, a.e1, b.e23oi);
    result.e123oi = macSub(result.e123oi, a.e2, b.e13oi);
    result.e123oi = macSub(result.e123oi, a.e12, b.e3oi);
    result.e123oi = mac(result.e123oi, a.e3, b.e12oi);
    result.e123oi = mac(result.e123oi, a.e13, b.e2oi);
    result.e123oi = macSub(result.e123oi, a.e23, b.e1oi);
    result.e123oi = macSub(result.e123oi, a.e123, b.eoi);
    result.e123oi = macSub(result.e123oi, a.eo, b.e123i);
    result.e123oi = macSub(result.e123oi, a.e1o, b.e23i);
    result.e123oi = mac(result.e123oi, a.e2o, b.e13i);
    result.e123oi = mac(result.e123oi, a.e12o, b.e3i);
    result.e123oi = macSub(result.e123oi, a.e3o, b.e12i);
    result.e123oi = macSub(result.e123oi, a.e13o, b.e2i);
    result.e123oi = mac(result.e123oi, a.e23o, b.e1i);
    result.e123oi = mac(result.e123oi, a.e123o, b.ei);
    result.e123oi = mac(result.e123oi, a.ei, b.e123o);
    result.e123oi = mac(result.e123oi, a.e1i, b.e23o);
    result.e123oi = macSub(result.e123oi, a.e2i, b.e13o);
    result.e123oi = macSub(result.e123oi, a.e12i, b.e3o);
    result.e123oi = mac(result.e123oi, a.e3i, b.e12o);
    result.e123oi = mac(result.e123oi, a.e13i, b.e2o);
    result.e123oi = macSub(result.e123oi, a.e23i, b.e1o);
    result.e123oi = macSub(result.e123oi, a.e123i, b.eo);
    result.e123oi = macSub(result.e123oi, a.eoi, b.e123);
    result.e123oi = macSub(result.e123oi, a.e1oi, b.e23);
    result.e123oi = mac(result.e123oi, a.e2oi, b.e13);
    result.e123oi = mac(result.e123oi, a.e12oi, b.e3);
    result.e123oi = macSub(result.e123oi, a.e3oi, b.e12);
    result.e123oi = macSub(result.e123oi, a.e13oi, b.e2);
    result.e123oi = mac(result.e123oi, a.e23oi, b.e1);
    result.e123oi = mac(result.e123oi, a.e123oi, b.scalar);
    
    //$display("ga_alu wedge product: a=%128h, b=%128h, res=%128h", a, b, result);
    
    return result;

  endfunction

  function automatic ga_multivector_t dotProduct(
    ga_multivector_t a,
    ga_multivector_t b
  );
    ga_multivector_t result;

    result        = '0;
    result.scalar = mac(result.scalar, a.scalar, b.scalar);
    result.scalar = mac(result.scalar, a.e1, b.e1);
    result.scalar = mac(result.scalar, a.e2, b.e2);
    result.scalar = macSub(result.scalar, a.e12, b.e12);
    result.scalar = mac(result.scalar, a.e3, b.e3);
    result.scalar = macSub(result.scalar, a.e13, b.e13);
    result.scalar = macSub(result.scalar, a.e23, b.e23);
    result.scalar = macSub(result.scalar, a.e123, b.e123);
    result.scalar = macSub(result.scalar, a.eo, b.ei);
    result.scalar = mac(result.scalar, a.e1o, b.e1i);
    result.scalar = mac(result.scalar, a.e2o, b.e2i);
    result.scalar = mac(result.scalar, a.e12o, b.e12i);
    result.scalar = mac(result.scalar, a.e3o, b.e3i);
    result.scalar = mac(result.scalar, a.e13o, b.e13i);
    result.scalar = mac(result.scalar, a.e23o, b.e23i);
    result.scalar = macSub(result.scalar, a.e123o, b.e123i);
    result.scalar = macSub(result.scalar, a.ei, b.eo);
    result.scalar = mac(result.scalar, a.e1i, b.e1o);
    result.scalar = mac(result.scalar, a.e2i, b.e2o);
    result.scalar = mac(result.scalar, a.e12i, b.e12o);
    result.scalar = mac(result.scalar, a.e3i, b.e3o);
    result.scalar = mac(result.scalar, a.e13i, b.e13o);
    result.scalar = mac(result.scalar, a.e23i, b.e23o);
    result.scalar = macSub(result.scalar, a.e123i, b.e123o);
    result.scalar = mac(result.scalar, a.eoi, b.eoi);
    result.scalar = mac(result.scalar, a.e1oi, b.e1oi);
    result.scalar = mac(result.scalar, a.e2oi, b.e2oi);
    result.scalar = macSub(result.scalar, a.e12oi, b.e12oi);
    result.scalar = mac(result.scalar, a.e3oi, b.e3oi);
    result.scalar = macSub(result.scalar, a.e13oi, b.e13oi);
    result.scalar = macSub(result.scalar, a.e23oi, b.e23oi);
    result.scalar = macSub(result.scalar, a.e123oi, b.e123oi);

    result.e1 = mac(result.e1, a.scalar, b.e1);
    result.e1 = mac(result.e1, a.e1, b.scalar);
    result.e1 = macSub(result.e1, a.e2, b.e12);
    result.e1 = mac(result.e1, a.e12, b.e2);
    result.e1 = macSub(result.e1, a.e3, b.e13);
    result.e1 = mac(result.e1, a.e13, b.e3);
    result.e1 = macSub(result.e1, a.e23, b.e123);
    result.e1 = macSub(result.e1, a.e123, b.e23);
    result.e1 = mac(result.e1, a.eo, b.e1i);
    result.e1 = macSub(result.e1, a.e1o, b.ei);
    result.e1 = mac(result.e1, a.e2o, b.e12i);
    result.e1 = mac(result.e1, a.e12o, b.e2i);
    result.e1 = mac(result.e1, a.e3o, b.e13i);
    result.e1 = mac(result.e1, a.e13o, b.e3i);
    result.e1 = macSub(result.e1, a.e23o, b.e123i);
    result.e1 = mac(result.e1, a.e123o, b.e23i);
    result.e1 = mac(result.e1, a.ei, b.e1o);
    result.e1 = macSub(result.e1, a.e1i, b.eo);
    result.e1 = mac(result.e1, a.e2i, b.e12o);
    result.e1 = mac(result.e1, a.e12i, b.e2o);
    result.e1 = mac(result.e1, a.e3i, b.e13o);
    result.e1 = mac(result.e1, a.e13i, b.e3o);
    result.e1 = macSub(result.e1, a.e23i, b.e123o);
    result.e1 = mac(result.e1, a.e123i, b.e23o);
    result.e1 = macSub(result.e1, a.eoi, b.e1);
    result.e1 = mac(result.e1, a.eoi, b.e1oi);
    result.e1 = mac(result.e1, a.e1oi, b.eoi);
    result.e1 = mac(result.e1, a.e2oi, b.e12);
    result.e1 = macSub(result.e1, a.e2oi, b.e12oi);
    result.e1 = mac(result.e1, a.e12oi, b.e2oi);
    result.e1 = mac(result.e1, a.e3oi, b.e13);
    result.e1 = macSub(result.e1, a.e3oi, b.e13oi);
    result.e1 = mac(result.e1, a.e13oi, b.e3oi);
    result.e1 = mac(result.e1, a.e23oi, b.e123);
    result.e1 = macSub(result.e1, a.e23oi, b.e123oi);
    result.e1 = macSub(result.e1, a.e123oi, b.e23oi);

    result.e2 = mac(result.e2, a.scalar, b.e2);
    result.e2 = mac(result.e2, a.e1, b.e12);
    result.e2 = mac(result.e2, a.e2, b.scalar);
    result.e2 = macSub(result.e2, a.e12, b.e1);
    result.e2 = macSub(result.e2, a.e3, b.e23);
    result.e2 = mac(result.e2, a.e13, b.e123);
    result.e2 = mac(result.e2, a.e23, b.e3);
    result.e2 = mac(result.e2, a.e123, b.e13);
    result.e2 = mac(result.e2, a.eo, b.e2i);
    result.e2 = macSub(result.e2, a.e1o, b.e12i);
    result.e2 = macSub(result.e2, a.e2o, b.ei);
    result.e2 = macSub(result.e2, a.e12o, b.e1i);
    result.e2 = mac(result.e2, a.e3o, b.e23i);
    result.e2 = mac(result.e2, a.e13o, b.e123i);
    result.e2 = mac(result.e2, a.e23o, b.e3i);
    result.e2 = macSub(result.e2, a.e123o, b.e13i);
    result.e2 = mac(result.e2, a.ei, b.e2o);
    result.e2 = macSub(result.e2, a.e1i, b.e12o);
    result.e2 = macSub(result.e2, a.e2i, b.eo);
    result.e2 = macSub(result.e2, a.e12i, b.e1o);
    result.e2 = mac(result.e2, a.e3i, b.e23o);
    result.e2 = mac(result.e2, a.e13i, b.e123o);
    result.e2 = mac(result.e2, a.e23i, b.e3o);
    result.e2 = macSub(result.e2, a.e123i, b.e13o);
    result.e2 = macSub(result.e2, a.eoi, b.e2);
    result.e2 = mac(result.e2, a.eoi, b.e2oi);
    result.e2 = macSub(result.e2, a.e1oi, b.e12);
    result.e2 = mac(result.e2, a.e1oi, b.e12oi);
    result.e2 = mac(result.e2, a.e2oi, b.eoi);
    result.e2 = macSub(result.e2, a.e12oi, b.e1oi);
    result.e2 = mac(result.e2, a.e3oi, b.e23);
    result.e2 = macSub(result.e2, a.e3oi, b.e23oi);
    result.e2 = macSub(result.e2, a.e13oi, b.e123);
    result.e2 = mac(result.e2, a.e13oi, b.e123oi);
    result.e2 = mac(result.e2, a.e23oi, b.e3oi);
    result.e2 = mac(result.e2, a.e123oi, b.e13oi);

    result.e12 = mac(result.e12, a.scalar, b.e12);
    result.e12 = mac(result.e12, a.e12, b.scalar);
    result.e12 = mac(result.e12, a.e3, b.e123);
    result.e12 = mac(result.e12, a.e123, b.e3);
    result.e12 = macSub(result.e12, a.eo, b.e12i);
    result.e12 = macSub(result.e12, a.e12o, b.ei);
    result.e12 = mac(result.e12, a.e3o, b.e123i);
    result.e12 = mac(result.e12, a.e123o, b.e3i);
    result.e12 = macSub(result.e12, a.ei, b.e12o);
    result.e12 = macSub(result.e12, a.e12i, b.eo);
    result.e12 = mac(result.e12, a.e3i, b.e123o);
    result.e12 = mac(result.e12, a.e123i, b.e3o);
    result.e12 = mac(result.e12, a.eoi, b.e12oi);
    result.e12 = macSub(result.e12, a.e1oi, b.e2);
    result.e12 = mac(result.e12, a.e2oi, b.e1);
    result.e12 = mac(result.e12, a.e12oi, b.eoi);
    result.e12 = mac(result.e12, a.e3oi, b.e123oi);
    result.e12 = mac(result.e12, a.e13oi, b.e23);
    result.e12 = macSub(result.e12, a.e23oi, b.e13);
    result.e12 = mac(result.e12, a.e123oi, b.e3oi);

    result.e3 = mac(result.e3, a.scalar, b.e3);
    result.e3 = mac(result.e3, a.e1, b.e13);
    result.e3 = mac(result.e3, a.e2, b.e23);
    result.e3 = macSub(result.e3, a.e12, b.e123);
    result.e3 = mac(result.e3, a.e3, b.scalar);
    result.e3 = macSub(result.e3, a.e13, b.e1);
    result.e3 = macSub(result.e3, a.e23, b.e2);
    result.e3 = macSub(result.e3, a.e123, b.e12);
    result.e3 = mac(result.e3, a.eo, b.e3i);
    result.e3 = macSub(result.e3, a.e1o, b.e13i);
    result.e3 = macSub(result.e3, a.e2o, b.e23i);
    result.e3 = macSub(result.e3, a.e12o, b.e123i);
    result.e3 = macSub(result.e3, a.e3o, b.ei);
    result.e3 = macSub(result.e3, a.e13o, b.e1i);
    result.e3 = macSub(result.e3, a.e23o, b.e2i);
    result.e3 = mac(result.e3, a.e123o, b.e12i);
    result.e3 = mac(result.e3, a.ei, b.e3o);
    result.e3 = macSub(result.e3, a.e1i, b.e13o);
    result.e3 = macSub(result.e3, a.e2i, b.e23o);
    result.e3 = macSub(result.e3, a.e12i, b.e123o);
    result.e3 = macSub(result.e3, a.e3i, b.eo);
    result.e3 = macSub(result.e3, a.e13i, b.e1o);
    result.e3 = macSub(result.e3, a.e23i, b.e2o);
    result.e3 = mac(result.e3, a.e123i, b.e12o);
    result.e3 = macSub(result.e3, a.eoi, b.e3);
    result.e3 = mac(result.e3, a.eoi, b.e3oi);
    result.e3 = macSub(result.e3, a.e1oi, b.e13);
    result.e3 = mac(result.e3, a.e1oi, b.e13oi);
    result.e3 = macSub(result.e3, a.e2oi, b.e23);
    result.e3 = mac(result.e3, a.e2oi, b.e23oi);
    result.e3 = mac(result.e3, a.e12oi, b.e123);
    result.e3 = macSub(result.e3, a.e12oi, b.e123oi);
    result.e3 = mac(result.e3, a.e3oi, b.eoi);
    result.e3 = macSub(result.e3, a.e13oi, b.e1oi);
    result.e3 = macSub(result.e3, a.e23oi, b.e2oi);
    result.e3 = macSub(result.e3, a.e123oi, b.e12oi);

    result.e13 = mac(result.e13, a.scalar, b.e13);
    result.e13 = macSub(result.e13, a.e2, b.e123);
    result.e13 = mac(result.e13, a.e13, b.scalar);
    result.e13 = macSub(result.e13, a.e123, b.e2);
    result.e13 = macSub(result.e13, a.eo, b.e13i);
    result.e13 = macSub(result.e13, a.e2o, b.e123i);
    result.e13 = macSub(result.e13, a.e13o, b.ei);
    result.e13 = macSub(result.e13, a.e123o, b.e2i);
    result.e13 = macSub(result.e13, a.ei, b.e13o);
    result.e13 = macSub(result.e13, a.e2i, b.e123o);
    result.e13 = macSub(result.e13, a.e13i, b.eo);
    result.e13 = macSub(result.e13, a.e123i, b.e2o);
    result.e13 = mac(result.e13, a.eoi, b.e13oi);
    result.e13 = macSub(result.e13, a.e1oi, b.e3);
    result.e13 = macSub(result.e13, a.e2oi, b.e123oi);
    result.e13 = macSub(result.e13, a.e12oi, b.e23);
    result.e13 = mac(result.e13, a.e3oi, b.e1);
    result.e13 = mac(result.e13, a.e13oi, b.eoi);
    result.e13 = mac(result.e13, a.e23oi, b.e12);
    result.e13 = macSub(result.e13, a.e123oi, b.e2oi);

    result.e23 = mac(result.e23, a.scalar, b.e23);
    result.e23 = mac(result.e23, a.e1, b.e123);
    result.e23 = mac(result.e23, a.e23, b.scalar);
    result.e23 = mac(result.e23, a.e123, b.e1);
    result.e23 = macSub(result.e23, a.eo, b.e23i);
    result.e23 = mac(result.e23, a.e1o, b.e123i);
    result.e23 = macSub(result.e23, a.e23o, b.ei);
    result.e23 = mac(result.e23, a.e123o, b.e1i);
    result.e23 = macSub(result.e23, a.ei, b.e23o);
    result.e23 = mac(result.e23, a.e1i, b.e123o);
    result.e23 = macSub(result.e23, a.e23i, b.eo);
    result.e23 = mac(result.e23, a.e123i, b.e1o);
    result.e23 = mac(result.e23, a.eoi, b.e23oi);
    result.e23 = mac(result.e23, a.e1oi, b.e123oi);
    result.e23 = macSub(result.e23, a.e2oi, b.e3);
    result.e23 = mac(result.e23, a.e12oi, b.e13);
    result.e23 = mac(result.e23, a.e3oi, b.e2);
    result.e23 = macSub(result.e23, a.e13oi, b.e12);
    result.e23 = mac(result.e23, a.e23oi, b.eoi);
    result.e23 = mac(result.e23, a.e123oi, b.e1oi);

    result.e123 = mac(result.e123, a.scalar, b.e123);
    result.e123 = mac(result.e123, a.e123, b.scalar);
    result.e123 = mac(result.e123, a.eo, b.e123i);
    result.e123 = macSub(result.e123, a.e123o, b.ei);
    result.e123 = mac(result.e123, a.ei, b.e123o);
    result.e123 = macSub(result.e123, a.e123i, b.eo);
    result.e123 = mac(result.e123, a.eoi, b.e123oi);
    result.e123 = macSub(result.e123, a.e12oi, b.e3);
    result.e123 = mac(result.e123, a.e13oi, b.e2);
    result.e123 = macSub(result.e123, a.e23oi, b.e1);
    result.e123 = mac(result.e123, a.e123oi, b.eoi);

    result.eo = mac(result.eo, a.scalar, b.eo);
    result.eo = mac(result.eo, a.e1, b.e1o);
    result.eo = mac(result.eo, a.e2, b.e2o);
    result.eo = macSub(result.eo, a.e12, b.e12o);
    result.eo = mac(result.eo, a.e3, b.e3o);
    result.eo = macSub(result.eo, a.e13, b.e13o);
    result.eo = macSub(result.eo, a.e23, b.e23o);
    result.eo = macSub(result.eo, a.e123, b.e123o);
    result.eo = mac(result.eo, a.eo, b.scalar);
    result.eo = mac(result.eo, a.eo, b.eoi);
    result.eo = macSub(result.eo, a.e1o, b.e1);
    result.eo = macSub(result.eo, a.e1o, b.e1oi);
    result.eo = macSub(result.eo, a.e2o, b.e2);
    result.eo = macSub(result.eo, a.e2o, b.e2oi);
    result.eo = macSub(result.eo, a.e12o, b.e12);
    result.eo = macSub(result.eo, a.e12o, b.e12oi);
    result.eo = macSub(result.eo, a.e3o, b.e3);
    result.eo = macSub(result.eo, a.e3o, b.e3oi);
    result.eo = macSub(result.eo, a.e13o, b.e13);
    result.eo = macSub(result.eo, a.e13o, b.e13oi);
    result.eo = macSub(result.eo, a.e23o, b.e23);
    result.eo = macSub(result.eo, a.e23o, b.e23oi);
    result.eo = mac(result.eo, a.e123o, b.e123);
    result.eo = mac(result.eo, a.e123o, b.e123oi);
    result.eo = macSub(result.eo, a.eoi, b.eo);
    result.eo = macSub(result.eo, a.eoi, b.eo);
    result.eo = macSub(result.eo, a.e1oi, b.e1o);
    result.eo = macSub(result.eo, a.e1oi, b.e1o);
    result.eo = macSub(result.eo, a.e2oi, b.e2o);
    result.eo = macSub(result.eo, a.e2oi, b.e2o);
    result.eo = mac(result.eo, a.e12oi, b.e12o);
    result.eo = mac(result.eo, a.e12oi, b.e12o);
    result.eo = macSub(result.eo, a.e3oi, b.e3o);
    result.eo = macSub(result.eo, a.e3oi, b.e3o);
    result.eo = mac(result.eo, a.e13oi, b.e13o);
    result.eo = mac(result.eo, a.e13oi, b.e13o);
    result.eo = mac(result.eo, a.e23oi, b.e23o);
    result.eo = mac(result.eo, a.e23oi, b.e23o);
    result.eo = mac(result.eo, a.e123oi, b.e123o);
    result.eo = mac(result.eo, a.e123oi, b.e123o);

    result.e1o = mac(result.e1o, a.scalar, b.e1o);
    result.e1o = macSub(result.e1o, a.e2, b.e12o);
    result.e1o = macSub(result.e1o, a.e3, b.e13o);
    result.e1o = macSub(result.e1o, a.e23, b.e123o);
    result.e1o = macSub(result.e1o, a.eo, b.e1oi);
    result.e1o = mac(result.e1o, a.e1o, b.scalar);
    result.e1o = macSub(result.e1o, a.e2o, b.e12oi);
    result.e1o = macSub(result.e1o, a.e12o, b.e2);
    result.e1o = macSub(result.e1o, a.e3o, b.e13oi);
    result.e1o = macSub(result.e1o, a.e13o, b.e3);
    result.e1o = mac(result.e1o, a.e23o, b.e123oi);
    result.e1o = macSub(result.e1o, a.e123o, b.e23);
    result.e1o = macSub(result.e1o, a.e1oi, b.eo);
    result.e1o = macSub(result.e1o, a.e1oi, b.eo);
    result.e1o = macSub(result.e1o, a.e12oi, b.e2o);
    result.e1o = macSub(result.e1o, a.e12oi, b.e2o);
    result.e1o = macSub(result.e1o, a.e13oi, b.e3o);
    result.e1o = macSub(result.e1o, a.e13oi, b.e3o);
    result.e1o = mac(result.e1o, a.e123oi, b.e23o);
    result.e1o = mac(result.e1o, a.e123oi, b.e23o);

    result.e2o = mac(result.e2o, a.scalar, b.e2o);
    result.e2o = mac(result.e2o, a.e1, b.e12o);
    result.e2o = macSub(result.e2o, a.e3, b.e23o);
    result.e2o = mac(result.e2o, a.e13, b.e123o);
    result.e2o = macSub(result.e2o, a.eo, b.e2oi);
    result.e2o = mac(result.e2o, a.e1o, b.e12oi);
    result.e2o = mac(result.e2o, a.e2o, b.scalar);
    result.e2o = mac(result.e2o, a.e12o, b.e1);
    result.e2o = macSub(result.e2o, a.e3o, b.e23oi);
    result.e2o = macSub(result.e2o, a.e13o, b.e123oi);
    result.e2o = macSub(result.e2o, a.e23o, b.e3);
    result.e2o = mac(result.e2o, a.e123o, b.e13);
    result.e2o = macSub(result.e2o, a.e2oi, b.eo);
    result.e2o = macSub(result.e2o, a.e2oi, b.eo);
    result.e2o = mac(result.e2o, a.e12oi, b.e1o);
    result.e2o = mac(result.e2o, a.e12oi, b.e1o);
    result.e2o = macSub(result.e2o, a.e23oi, b.e3o);
    result.e2o = macSub(result.e2o, a.e23oi, b.e3o);
    result.e2o = macSub(result.e2o, a.e123oi, b.e13o);
    result.e2o = macSub(result.e2o, a.e123oi, b.e13o);

    result.e12o = mac(result.e12o, a.scalar, b.e12o);
    result.e12o = mac(result.e12o, a.e3, b.e123o);
    result.e12o = mac(result.e12o, a.eo, b.e12oi);
    result.e12o = mac(result.e12o, a.e12o, b.scalar);
    result.e12o = macSub(result.e12o, a.e3o, b.e123oi);
    result.e12o = macSub(result.e12o, a.e123o, b.e3);
    result.e12o = macSub(result.e12o, a.e12oi, b.eo);
    result.e12o = macSub(result.e12o, a.e12oi, b.eo);
    result.e12o = macSub(result.e12o, a.e123oi, b.e3o);
    result.e12o = macSub(result.e12o, a.e123oi, b.e3o);

    result.e3o = mac(result.e3o, a.scalar, b.e3o);
    result.e3o = mac(result.e3o, a.e1, b.e13o);
    result.e3o = mac(result.e3o, a.e2, b.e23o);
    result.e3o = macSub(result.e3o, a.e12, b.e123o);
    result.e3o = macSub(result.e3o, a.eo, b.e3oi);
    result.e3o = mac(result.e3o, a.e1o, b.e13oi);
    result.e3o = mac(result.e3o, a.e2o, b.e23oi);
    result.e3o = mac(result.e3o, a.e12o, b.e123oi);
    result.e3o = mac(result.e3o, a.e3o, b.scalar);
    result.e3o = mac(result.e3o, a.e13o, b.e1);
    result.e3o = mac(result.e3o, a.e23o, b.e2);
    result.e3o = macSub(result.e3o, a.e123o, b.e12);
    result.e3o = macSub(result.e3o, a.e3oi, b.eo);
    result.e3o = macSub(result.e3o, a.e3oi, b.eo);
    result.e3o = mac(result.e3o, a.e13oi, b.e1o);
    result.e3o = mac(result.e3o, a.e13oi, b.e1o);
    result.e3o = mac(result.e3o, a.e23oi, b.e2o);
    result.e3o = mac(result.e3o, a.e23oi, b.e2o);
    result.e3o = mac(result.e3o, a.e123oi, b.e12o);
    result.e3o = mac(result.e3o, a.e123oi, b.e12o);

    result.e13o = mac(result.e13o, a.scalar, b.e13o);
    result.e13o = macSub(result.e13o, a.e2, b.e123o);
    result.e13o = mac(result.e13o, a.eo, b.e13oi);
    result.e13o = mac(result.e13o, a.e2o, b.e123oi);
    result.e13o = mac(result.e13o, a.e13o, b.scalar);
    result.e13o = mac(result.e13o, a.e123o, b.e2);
    result.e13o = macSub(result.e13o, a.e13oi, b.eo);
    result.e13o = macSub(result.e13o, a.e13oi, b.eo);
    result.e13o = mac(result.e13o, a.e123oi, b.e2o);
    result.e13o = mac(result.e13o, a.e123oi, b.e2o);

    result.e23o = mac(result.e23o, a.scalar, b.e23o);
    result.e23o = mac(result.e23o, a.e1, b.e123o);
    result.e23o = mac(result.e23o, a.eo, b.e23oi);
    result.e23o = macSub(result.e23o, a.e1o, b.e123oi);
    result.e23o = mac(result.e23o, a.e23o, b.scalar);
    result.e23o = macSub(result.e23o, a.e123o, b.e1);
    result.e23o = macSub(result.e23o, a.e23oi, b.eo);
    result.e23o = macSub(result.e23o, a.e23oi, b.eo);
    result.e23o = macSub(result.e23o, a.e123oi, b.e1o);
    result.e23o = macSub(result.e23o, a.e123oi, b.e1o);

    result.e123o = mac(result.e123o, a.scalar, b.e123o);
    result.e123o = macSub(result.e123o, a.eo, b.e123oi);
    result.e123o = mac(result.e123o, a.e123o, b.scalar);
    result.e123o = macSub(result.e123o, a.e123oi, b.eo);
    result.e123o = macSub(result.e123o, a.e123oi, b.eo);

    result.ei = mac(result.ei, a.scalar, b.ei);
    result.ei = mac(result.ei, a.e1, b.e1i);
    result.ei = mac(result.ei, a.e2, b.e2i);
    result.ei = macSub(result.ei, a.e12, b.e12i);
    result.ei = mac(result.ei, a.e3, b.e3i);
    result.ei = macSub(result.ei, a.e13, b.e13i);
    result.ei = macSub(result.ei, a.e23, b.e23i);
    result.ei = macSub(result.ei, a.e123, b.e123i);
    result.ei = mac(result.ei, a.ei, b.scalar);
    result.ei = macSub(result.ei, a.ei, b.eoi);
    result.ei = macSub(result.ei, a.e1i, b.e1);
    result.ei = mac(result.ei, a.e1i, b.e1oi);
    result.ei = macSub(result.ei, a.e2i, b.e2);
    result.ei = mac(result.ei, a.e2i, b.e2oi);
    result.ei = macSub(result.ei, a.e12i, b.e12);
    result.ei = mac(result.ei, a.e12i, b.e12oi);
    result.ei = macSub(result.ei, a.e3i, b.e3);
    result.ei = mac(result.ei, a.e3i, b.e3oi);
    result.ei = macSub(result.ei, a.e13i, b.e13);
    result.ei = mac(result.ei, a.e13i, b.e13oi);
    result.ei = macSub(result.ei, a.e23i, b.e23);
    result.ei = mac(result.ei, a.e23i, b.e23oi);
    result.ei = mac(result.ei, a.e123i, b.e123);
    result.ei = macSub(result.ei, a.e123i, b.e123oi);

    result.e1i = mac(result.e1i, a.scalar, b.e1i);
    result.e1i = macSub(result.e1i, a.e2, b.e12i);
    result.e1i = macSub(result.e1i, a.e3, b.e13i);
    result.e1i = macSub(result.e1i, a.e23, b.e123i);
    result.e1i = mac(result.e1i, a.ei, b.e1oi);
    result.e1i = mac(result.e1i, a.e1i, b.scalar);
    result.e1i = mac(result.e1i, a.e2i, b.e12oi);
    result.e1i = macSub(result.e1i, a.e12i, b.e2);
    result.e1i = mac(result.e1i, a.e3i, b.e13oi);
    result.e1i = macSub(result.e1i, a.e13i, b.e3);
    result.e1i = macSub(result.e1i, a.e23i, b.e123oi);
    result.e1i = macSub(result.e1i, a.e123i, b.e23);

    result.e2i = mac(result.e2i, a.scalar, b.e2i);
    result.e2i = mac(result.e2i, a.e1, b.e12i);
    result.e2i = macSub(result.e2i, a.e3, b.e23i);
    result.e2i = mac(result.e2i, a.e13, b.e123i);
    result.e2i = mac(result.e2i, a.ei, b.e2oi);
    result.e2i = macSub(result.e2i, a.e1i, b.e12oi);
    result.e2i = mac(result.e2i, a.e2i, b.scalar);
    result.e2i = mac(result.e2i, a.e12i, b.e1);
    result.e2i = mac(result.e2i, a.e3i, b.e23oi);
    result.e2i = mac(result.e2i, a.e13i, b.e123oi);
    result.e2i = macSub(result.e2i, a.e23i, b.e3);
    result.e2i = mac(result.e2i, a.e123i, b.e13);

    result.e12i = mac(result.e12i, a.scalar, b.e12i);
    result.e12i = mac(result.e12i, a.e3, b.e123i);
    result.e12i = macSub(result.e12i, a.ei, b.e12oi);
    result.e12i = mac(result.e12i, a.e12i, b.scalar);
    result.e12i = mac(result.e12i, a.e3i, b.e123oi);
    result.e12i = macSub(result.e12i, a.e123i, b.e3);

    result.e3i = mac(result.e3i, a.scalar, b.e3i);
    result.e3i = mac(result.e3i, a.e1, b.e13i);
    result.e3i = mac(result.e3i, a.e2, b.e23i);
    result.e3i = macSub(result.e3i, a.e12, b.e123i);
    result.e3i = mac(result.e3i, a.ei, b.e3oi);
    result.e3i = macSub(result.e3i, a.e1i, b.e13oi);
    result.e3i = macSub(result.e3i, a.e2i, b.e23oi);
    result.e3i = macSub(result.e3i, a.e12i, b.e123oi);
    result.e3i = mac(result.e3i, a.e3i, b.scalar);
    result.e3i = mac(result.e3i, a.e13i, b.e1);
    result.e3i = mac(result.e3i, a.e23i, b.e2);
    result.e3i = macSub(result.e3i, a.e123i, b.e12);

    result.e13i = mac(result.e13i, a.scalar, b.e13i);
    result.e13i = macSub(result.e13i, a.e2, b.e123i);
    result.e13i = macSub(result.e13i, a.ei, b.e13oi);
    result.e13i = macSub(result.e13i, a.e2i, b.e123oi);
    result.e13i = mac(result.e13i, a.e13i, b.scalar);
    result.e13i = mac(result.e13i, a.e123i, b.e2);

    result.e23i = mac(result.e23i, a.scalar, b.e23i);
    result.e23i = mac(result.e23i, a.e1, b.e123i);
    result.e23i = macSub(result.e23i, a.ei, b.e23oi);
    result.e23i = mac(result.e23i, a.e1i, b.e123oi);
    result.e23i = mac(result.e23i, a.e23i, b.scalar);
    result.e23i = macSub(result.e23i, a.e123i, b.e1);

    result.e123i = mac(result.e123i, a.scalar, b.e123i);
    result.e123i = mac(result.e123i, a.ei, b.e123oi);
    result.e123i = mac(result.e123i, a.e123i, b.scalar);

    result.eoi = mac(result.eoi, a.scalar, b.eoi);
    result.eoi = mac(result.eoi, a.e1, b.e1oi);
    result.eoi = mac(result.eoi, a.e2, b.e2oi);
    result.eoi = macSub(result.eoi, a.e12, b.e12oi);
    result.eoi = mac(result.eoi, a.e3, b.e3oi);
    result.eoi = macSub(result.eoi, a.e13, b.e13oi);
    result.eoi = macSub(result.eoi, a.e23, b.e23oi);
    result.eoi = macSub(result.eoi, a.e123, b.e123oi);
    result.eoi = mac(result.eoi, a.eoi, b.scalar);
    result.eoi = mac(result.eoi, a.e1oi, b.e1);
    result.eoi = mac(result.eoi, a.e2oi, b.e2);
    result.eoi = macSub(result.eoi, a.e12oi, b.e12);
    result.eoi = mac(result.eoi, a.e3oi, b.e3);
    result.eoi = macSub(result.eoi, a.e13oi, b.e13);
    result.eoi = macSub(result.eoi, a.e23oi, b.e23);
    result.eoi = macSub(result.eoi, a.e123oi, b.e123);

    result.e1oi = mac(result.e1oi, a.scalar, b.e1oi);
    result.e1oi = macSub(result.e1oi, a.e2, b.e12oi);
    result.e1oi = macSub(result.e1oi, a.e3, b.e13oi);
    result.e1oi = macSub(result.e1oi, a.e23, b.e123oi);
    result.e1oi = mac(result.e1oi, a.e1oi, b.scalar);
    result.e1oi = mac(result.e1oi, a.e12oi, b.e2);
    result.e1oi = mac(result.e1oi, a.e13oi, b.e3);
    result.e1oi = macSub(result.e1oi, a.e123oi, b.e23);

    result.e2oi = mac(result.e2oi, a.scalar, b.e2oi);
    result.e2oi = mac(result.e2oi, a.e1, b.e12oi);
    result.e2oi = macSub(result.e2oi, a.e3, b.e23oi);
    result.e2oi = mac(result.e2oi, a.e13, b.e123oi);
    result.e2oi = mac(result.e2oi, a.e2oi, b.scalar);
    result.e2oi = macSub(result.e2oi, a.e12oi, b.e1);
    result.e2oi = mac(result.e2oi, a.e23oi, b.e3);
    result.e2oi = mac(result.e2oi, a.e123oi, b.e13);

    result.e12oi = mac(result.e12oi, a.scalar, b.e12oi);
    result.e12oi = mac(result.e12oi, a.e3, b.e123oi);
    result.e12oi = mac(result.e12oi, a.e12oi, b.scalar);
    result.e12oi = mac(result.e12oi, a.e123oi, b.e3);

    result.e3oi = mac(result.e3oi, a.scalar, b.e3oi);
    result.e3oi = mac(result.e3oi, a.e1, b.e13oi);
    result.e3oi = mac(result.e3oi, a.e2, b.e23oi);
    result.e3oi = macSub(result.e3oi, a.e12, b.e123oi);
    result.e3oi = mac(result.e3oi, a.e3oi, b.scalar);
    result.e3oi = macSub(result.e3oi, a.e13oi, b.e1);
    result.e3oi = macSub(result.e3oi, a.e23oi, b.e2);
    result.e3oi = macSub(result.e3oi, a.e123oi, b.e12);

    result.e13oi = mac(result.e13oi, a.scalar, b.e13oi);
    result.e13oi = macSub(result.e13oi, a.e2, b.e123oi);
    result.e13oi = mac(result.e13oi, a.e13oi, b.scalar);
    result.e13oi = macSub(result.e13oi, a.e123oi, b.e2);

    result.e23oi = mac(result.e23oi, a.scalar, b.e23oi);
    result.e23oi = mac(result.e23oi, a.e1, b.e123oi);
    result.e23oi = mac(result.e23oi, a.e23oi, b.scalar);
    result.e23oi = mac(result.e23oi, a.e123oi, b.e1);

    result.e123oi = mac(result.e123oi, a.scalar, b.e123oi);
    result.e123oi = mac(result.e123oi, a.e123oi, b.scalar);
    
    //$display("ga_alu dot product: a=%128h, b=%128h, res=%128h", a, b, result);
    
    return result;

  endfunction

  function automatic ga_multivector_t dualOperation(
    ga_multivector_t a
  );
    ga_multivector_t result;
    
    result        = '0;
    result.e123oi = a.scalar;
    result.e23oi  = a.e1;
    result.e13oi  = negQ511(a.e2);
    result.e12oi  = a.e3;
    result.e3oi   = negQ511(a.eo);
    result.e2oi   = a.ei;
    result.e1oi   = negQ511(a.e12);
    result.eoi    = a.e13;
    result.e3i    = negQ511(a.e23);
    result.e2i    = a.e1o;
    result.e1i    = negQ511(a.e2o);
    result.ei     = a.e3o;
    result.e3o    = a.e1i;
    result.e2o    = negQ511(a.e2i);
    result.e1o    = a.e3i;
    result.eo     = negQ511(a.eoi);
    result.e23    = negQ511(a.e1oi);
    result.e13    = a.e2oi;
    result.e12    = negQ511(a.e3oi);
    result.e3     = a.e12oi;
    result.e2     = negQ511(a.e13oi);
    result.e1     = a.e23oi;
    result.scalar = a.e123oi;
    
    return result;

  endfunction

  function automatic ga_multivector_t reverseOperation(
    ga_multivector_t a
  );
    ga_multivector_t result;
    
    result.scalar = a.scalar;
    result.e1     = a.e1;
    result.e2     = a.e2;
    result.e3     = a.e3;
    result.eo     = a.eo;
    result.ei     = a.ei;
    result.e12    = negQ511(a.e12);
    result.e13    = negQ511(a.e13);
    result.e23    = negQ511(a.e23);
    result.e1o    = negQ511(a.e1o);
    result.e2o    = negQ511(a.e2o);
    result.e3o    = negQ511(a.e3o);
    result.e1i    = negQ511(a.e1i);
    result.e2i    = negQ511(a.e2i);
    result.e3i    = negQ511(a.e3i);
    result.eoi    = negQ511(a.eoi);
    result.e123   = negQ511(a.e123);
    result.e12o   = negQ511(a.e12o);
    result.e13o   = negQ511(a.e13o);
    result.e23o   = negQ511(a.e23o);
    result.e12i   = negQ511(a.e12i);
    result.e13i   = negQ511(a.e13i);
    result.e23i   = negQ511(a.e23i);
    result.e1oi   = negQ511(a.e1oi);
    result.e2oi   = negQ511(a.e2oi);
    result.e3oi   = negQ511(a.e3oi);
    result.e123o  = a.e123o;
    result.e123i  = a.e123i;
    result.e12oi  = a.e12oi;
    result.e13oi  = a.e13oi;
    result.e23oi  = a.e23oi;
    result.e123oi = a.e123oi;
    
    return result;

  endfunction

  function automatic logic signed [FP_W-1:0] normCalculation(
    ga_multivector_t a
  );
    logic signed [FP_W-1:0] acc;
    
    acc = '0;
    acc = mac(acc, a.scalar, a.scalar);
    acc = mac(acc, a.e1,     a.e1);
    acc = mac(acc, a.e2,     a.e2);
    acc = mac(acc, a.e12,    a.e12);
    acc = mac(acc, a.e3,     a.e3);
    acc = mac(acc, a.e13,    a.e13);
    acc = mac(acc, a.e23,    a.e23);
    acc = mac(acc, a.e123,   a.e123);
    acc = mac(acc, a.eo,     a.eo);
    acc = mac(acc, a.e1o,    a.e1o);
    acc = mac(acc, a.e2o,    a.e2o);
    acc = mac(acc, a.e12o,   a.e12o);
    acc = mac(acc, a.e3o,    a.e3o);
    acc = mac(acc, a.e13o,   a.e13o);
    acc = mac(acc, a.e23o,   a.e23o);
    acc = mac(acc, a.e123o,  a.e123o);
    acc = mac(acc, a.ei,     a.ei);
    acc = mac(acc, a.e1i,    a.e1i);
    acc = mac(acc, a.e2i,    a.e2i);
    acc = mac(acc, a.e12i,   a.e12i);
    acc = mac(acc, a.e3i,    a.e3i);
    acc = mac(acc, a.e13i,   a.e13i);
    acc = mac(acc, a.e23i,   a.e23i);
    acc = mac(acc, a.e123i,  a.e123i);
    acc = mac(acc, a.eoi,    a.eoi);
    acc = mac(acc, a.e1oi,   a.e1oi);
    acc = mac(acc, a.e2oi,   a.e2oi);
    acc = mac(acc, a.e12oi,  a.e12oi);
    acc = mac(acc, a.e3oi,   a.e3oi);
    acc = mac(acc, a.e13oi,  a.e13oi);
    acc = mac(acc, a.e23oi,  a.e23oi);
    acc = mac(acc, a.e123oi, a.e123oi);

    return acc;

  endfunction

  function automatic ga_multivector_t rotorApplication(
    ga_multivector_t rotor,
    ga_multivector_t vector
  );
    ga_multivector_t revRotor = reverseOperation(rotor);
    ga_multivector_t temp = geometricProduct(rotor, vector);

    return geometricProduct(temp, revRotor);

  endfunction

  function automatic ga_multivector_t reflectionOperation(
    ga_multivector_t vector,
    ga_multivector_t normal
  );

    return vector;

  endfunction

  assign result_o = result_q;
  assign error_o = error_q;

endmodule
