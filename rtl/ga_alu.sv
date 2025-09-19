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
        result.e4           = a.e4 + b.e4;
        result.e5           = a.e5 + b.e5;
        result.e12          = a.e12 + b.e12;
        result.e13          = a.e13 + b.e13;
        result.e23          = a.e23 + b.e23;
        result.e14          = a.e14 + b.e14;
        result.e24          = a.e24 + b.e24;
        result.e34          = a.e34 + b.e34;
        result.e15          = a.e15 + b.e15;
        result.e25          = a.e25 + b.e25;
        result.e35          = a.e35 + b.e35;
        result.e45          = a.e45 + b.e45;
        result.e123         = a.e123 + b.e123;
        result.e124         = a.e124 + b.e124;
        result.e134         = a.e134 + b.e134;
        result.e234         = a.e234 + b.e234;
        result.e125         = a.e125 + b.e125;
        result.e135         = a.e135 + b.e135;
        result.e235         = a.e235 + b.e235;
        result.e145         = a.e145 + b.e145;
        result.e245         = a.e245 + b.e245;
        result.e345         = a.e345 + b.e345;
        result.e1234        = a.e1234 + b.e1234;
        result.e1235        = a.e1235 + b.e1235;
        result.e1245        = a.e1245 + b.e1245;
        result.e1345        = a.e1345 + b.e1345;
        result.e2345        = a.e2345 + b.e2345;
        result.e12345       = a.e12345 + b.e12345;

        //$display("ga_alu add: a=%128h, b=%128h, res=%128h", a, b, result);

      end

      GA_FUNCT_SUB: begin

        result.scalar      = a.scalar - b.scalar;
        result.e1          = a.e1 - b.e1;
        result.e2          = a.e2 - b.e2;
        result.e3          = a.e3 - b.e3;
        result.e4          = a.e4 - b.e4;
        result.e5          = a.e5 - b.e5;
        result.e12         = a.e12 - b.e12;
        result.e13         = a.e13 - b.e13;
        result.e23         = a.e23 - b.e23;
        result.e14         = a.e14 - b.e14;
        result.e24         = a.e24 - b.e24;
        result.e34         = a.e34 - b.e34;
        result.e15         = a.e15 - b.e15;
        result.e25         = a.e25 - b.e25;
        result.e35         = a.e35 - b.e35;
        result.e45         = a.e45 - b.e45;
        result.e123        = a.e123 - b.e123;
        result.e124        = a.e124 - b.e124;
        result.e134        = a.e134 - b.e134;
        result.e234        = a.e234 - b.e234;
        result.e125        = a.e125 - b.e125;
        result.e135        = a.e135 - b.e135;
        result.e235        = a.e235 - b.e235;
        result.e145        = a.e145 - b.e145;
        result.e245        = a.e245 - b.e245;
        result.e345        = a.e345 - b.e345;
        result.e1234       = a.e1234 - b.e1234;
        result.e1235       = a.e1235 - b.e1235;
        result.e1245       = a.e1245 - b.e1245;
        result.e1345       = a.e1345 - b.e1345;
        result.e2345       = a.e2345 - b.e2345;
        result.e12345      = a.e12345 - b.e12345;

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

    

    //$display("ga_alu full product: a=%128h, b=%128h, res=%128h", a, b, result);
                  
    return result;

  endfunction

  function automatic ga_multivector_t wedgeProduct(
    ga_multivector_t a,
    ga_multivector_t b
  );
    ga_multivector_t result;
    result = '0;

    //$display("ga_alu wedge product: a=%128h, b=%128h, res=%128h", a, b, result);
    
    return result;

  endfunction

  function automatic ga_multivector_t dotProduct(
    ga_multivector_t a,
    ga_multivector_t b
  );
    ga_multivector_t result;

    result        = '0;
      
    //$display("ga_alu dot product: a=%128h, b=%128h, res=%128h", a, b, result);
    
    return result;

  endfunction

  function automatic ga_multivector_t dualOperation(
    ga_multivector_t a
  );
    ga_multivector_t result;
    
    result = '0;
    result.e12345 = a.scalar;
    result.e2345  = a.e1;
    result.e1345  = negQ511(a.e2);
    result.e1245  = a.e3;
    result.e1235  = negQ511(a.e4);
    result.e1234  = a.e5;
    result.e345   = negQ511(a.e12);
    result.e245   = a.e13;
    result.e235   = negQ511(a.e23);
    result.e234   = a.e14;
    result.e145   = negQ511(a.e24);
    result.e135   = a.e34;
    result.e134   = negQ511(a.e15);
    result.e125   = a.e25;
    result.e124   = negQ511(a.e35);
    result.e123   = a.e45;
    result.e45    = a.e123;
    result.e35    = negQ511(a.e124);
    result.e34    = a.e125;
    result.e25    = negQ511(a.e134);
    result.e24    = a.e135;
    result.e23    = negQ511(a.e145);
    result.e15    = a.e234;
    result.e14    = negQ511(a.e235);
    result.e13    = a.e245;
    result.e12    = negQ511(a.e345);
    result.e5     = a.e1234;
    result.e4     = negQ511(a.e1235);
    result.e3     = a.e1245;
    result.e2     = negQ511(a.e1345);
    result.e1     = a.e2345;
    result.scalar = a.e12345;
    
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
    result.e4     = a.e4;
    result.e5     = a.e5;
    result.e12    = negQ511(a.e12);
    result.e13    = negQ511(a.e13);
    result.e23    = negQ511(a.e23);
    result.e14    = negQ511(a.e14);
    result.e24    = negQ511(a.e24);
    result.e34    = negQ511(a.e34);
    result.e15    = negQ511(a.e15);
    result.e25    = negQ511(a.e25);
    result.e35    = negQ511(a.e35);
    result.e45    = negQ511(a.e45);
    result.e123   = negQ511(a.e123);
    result.e124   = negQ511(a.e124);
    result.e134   = negQ511(a.e134);
    result.e234   = negQ511(a.e234);
    result.e125   = negQ511(a.e125);
    result.e135   = negQ511(a.e135);
    result.e235   = negQ511(a.e235);
    result.e145   = negQ511(a.e145);
    result.e245   = negQ511(a.e245);
    result.e345   = negQ511(a.e345);
    result.e1234  = a.e1234;
    result.e1235  = a.e1235;
    result.e1245  = a.e1245;
    result.e1345  = a.e1345;
    result.e2345  = a.e2345;
    result.e12345 = a.e12345;
    
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
    acc = mac(acc, a.e3,     a.e3);
    acc = mac(acc, a.e4,     a.e4);
    acc = mac(acc, a.e5,     a.e5);
    acc = mac(acc, a.e12,    a.e12);
    acc = mac(acc, a.e13,    a.e13);
    acc = mac(acc, a.e23,    a.e23);
    acc = mac(acc, a.e14,    a.e14);
    acc = mac(acc, a.e24,    a.e24);
    acc = mac(acc, a.e34,    a.e34);
    acc = mac(acc, a.e15,    a.e15);
    acc = mac(acc, a.e25,    a.e25);
    acc = mac(acc, a.e35,    a.e35);
    acc = mac(acc, a.e45,    a.e45);
    acc = mac(acc, a.e123,   a.e123);
    acc = mac(acc, a.e124,   a.e124);
    acc = mac(acc, a.e134,   a.e134);
    acc = mac(acc, a.e234,   a.e234);
    acc = mac(acc, a.e125,   a.e125);
    acc = mac(acc, a.e135,   a.e135);
    acc = mac(acc, a.e235,   a.e235);
    acc = mac(acc, a.e145,   a.e145);
    acc = mac(acc, a.e245,   a.e245);
    acc = mac(acc, a.e345,   a.e345);
    acc = mac(acc, a.e1234,  a.e1234);
    acc = mac(acc, a.e1235,  a.e1235);
    acc = mac(acc, a.e1245,  a.e1245);
    acc = mac(acc, a.e1345,  a.e1345);
    acc = mac(acc, a.e2345,  a.e2345);
    acc = mac(acc, a.e12345, a.e12345);

    return acc;

  endfunction

  function automatic ga_multivector_t rotorApplication(
    ga_multivector_t rotor,
    ga_multivector_t vector
  );
    ga_multivector_t revRotor = reverseOperation(rotor);
    ga_multivector_t temp     = geometricProduct(rotor, vector);

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
