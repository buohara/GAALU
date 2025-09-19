/**
 * Package with constants and types used by GA coprocessor
 */

package ga_pkg;

`ifdef GA_EVEN
  parameter bit GA_USE_EVEN = 1'b1;
`else
  parameter bit GA_USE_EVEN = 1'b0;
`endif

  typedef enum logic [3:0]
  {
    GA_FUNCT_ADD       = 4'b0000,
    GA_FUNCT_SUB       = 4'b0001,
    GA_FUNCT_MUL       = 4'b0010,
    GA_FUNCT_WEDGE     = 4'b0011,
    GA_FUNCT_DOT       = 4'b0100,
    GA_FUNCT_DUAL      = 4'b0101,
    GA_FUNCT_REV       = 4'b0110,
    GA_FUNCT_NORM      = 4'b0111,
    GA_FUNCT_LOAD      = 4'b1000,
    GA_FUNCT_STORE     = 4'b1001,
    GA_FUNCT_ROTATE    = 4'b1010,
    GA_FUNCT_REFLECT   = 4'b1011
  } ga_funct_e;

  parameter int GA_MV_WIDTH = 16;
  parameter int GA_MV_SIZE  = 512;
  
  typedef struct packed
  {
    logic [GA_MV_WIDTH-1:0] scalar;
    logic [GA_MV_WIDTH-1:0] e1;
    logic [GA_MV_WIDTH-1:0] e2;
    logic [GA_MV_WIDTH-1:0] e3;
    logic [GA_MV_WIDTH-1:0] e4;
    logic [GA_MV_WIDTH-1:0] e5;
    logic [GA_MV_WIDTH-1:0] e12;
    logic [GA_MV_WIDTH-1:0] e13;
    logic [GA_MV_WIDTH-1:0] e23;
    logic [GA_MV_WIDTH-1:0] e14;
    logic [GA_MV_WIDTH-1:0] e24;
    logic [GA_MV_WIDTH-1:0] e34;
    logic [GA_MV_WIDTH-1:0] e15;
    logic [GA_MV_WIDTH-1:0] e25;
    logic [GA_MV_WIDTH-1:0] e35;
    logic [GA_MV_WIDTH-1:0] e45;
    logic [GA_MV_WIDTH-1:0] e123;
    logic [GA_MV_WIDTH-1:0] e124;
    logic [GA_MV_WIDTH-1:0] e134;
    logic [GA_MV_WIDTH-1:0] e234;
    logic [GA_MV_WIDTH-1:0] e125;
    logic [GA_MV_WIDTH-1:0] e135;
    logic [GA_MV_WIDTH-1:0] e235;
    logic [GA_MV_WIDTH-1:0] e145;
    logic [GA_MV_WIDTH-1:0] e245;
    logic [GA_MV_WIDTH-1:0] e345;
    logic [GA_MV_WIDTH-1:0] e1234;
    logic [GA_MV_WIDTH-1:0] e1235;
    logic [GA_MV_WIDTH-1:0] e1245;
    logic [GA_MV_WIDTH-1:0] e1345;
    logic [GA_MV_WIDTH-1:0] e2345;
    logic [GA_MV_WIDTH-1:0] e12345;
  } ga_multivector_t;

  typedef struct packed
  {
    logic [GA_MV_SIZE - 1:0] data;
    logic [2:0]  grade;
    logic [2:0]  basis;
  } ga_element_t;

  typedef struct packed
  {
    logic                     valid;
    ga_multivector_t          operand_a;
    ga_multivector_t          operand_b;
    logic [4:0]               rd_addr;
    logic [4:0]               ga_reg_a;
    logic [4:0]               ga_reg_b;
    ga_funct_e                funct;
    logic                     we;
    logic                     use_ga_regs;
  } ga_req_t;

  typedef struct packed 
  {
    logic                     valid;
    logic                     ready;
    logic [GA_MV_SIZE - 1:0]  result;
    logic                     error;
    logic                     busy;
    logic                     overflow;
    logic                     underflow;
  } ga_resp_t;

  parameter int GA_NUM_REGS       = 32;
  parameter int GA_REG_ADDR_WIDTH = $clog2(GA_NUM_REGS);

  typedef enum logic [1:0] 
  {
    GA_PRECISION_FP32  = 2'b00,
    GA_PRECISION_FP64  = 2'b01,
    GA_PRECISION_FIXED = 2'b10,
    GA_PRECISION_INT   = 2'b11
  } ga_precision_e;

  typedef enum logic [2:0] 
  {
    GA_ALGEBRA_3D      = 3'b000,
    GA_ALGEBRA_2D      = 3'b001,
    GA_ALGEBRA_4D_STA  = 3'b010,
    GA_ALGEBRA_5D_CGA  = 3'b011,
    GA_ALGEBRA_CUSTOM  = 3'b111
  } ga_algebra_e;
  
  typedef struct packed 
  {
    logic [31:0] ga_ops_total;
    logic [31:0] ga_ops_add;
    logic [31:0] ga_ops_mul;
    logic [31:0] ga_ops_geometric;
    logic [31:0] ga_cycles_busy;
    logic [31:0] ga_stalls;
  } ga_perf_counters_t;

  typedef struct packed
  {
    logic signed [15:0] scalar;
    logic signed [15:0] e12, e13, e23;
    logic signed [15:0] e14, e24, e34;
    logic signed [15:0] e15, e25, e35;
    logic signed [15:0] e45;
    logic signed [15:0] e1234, e1235;
    logic signed [15:0] e1245, e1345, e2345;
  } ga_even_multivector_t;

  function automatic ga_even_multivector_t mv_to_even(input ga_multivector_t mv);

    ga_even_multivector_t r;
    r.scalar = mv.scalar;
    r.e12    = mv.e12;    r.e13    = mv.e13;    r.e23    = mv.e23;
    r.e14    = mv.e14;    r.e24    = mv.e24;    r.e34    = mv.e34;
    r.e15    = mv.e15;    r.e25    = mv.e25;    r.e35    = mv.e35;
    r.e45    = mv.e45;
    r.e1234  = mv.e1234;  r.e1235  = mv.e1235;
    r.e1245  = mv.e1245;  r.e1345  = mv.e1345;  r.e2345  = mv.e2345;

    return r;

  endfunction

  function automatic ga_multivector_t even_to_mv(input ga_even_multivector_t e);

    ga_multivector_t mv = '0;
    mv.scalar = e.scalar;
    mv.e12    = e.e12;    mv.e13    = e.e13;    mv.e23    = e.e23;
    mv.e14    = e.e14;    mv.e24    = e.e24;    mv.e34    = e.e34;
    mv.e15    = e.e15;    mv.e25    = e.e25;    mv.e35    = e.e35;
    mv.e45    = e.e45;
    mv.e1234  = e.e1234;  mv.e1235  = e.e1235;
    mv.e1245  = e.e1245;  mv.e1345  = e.e1345;  mv.e2345  = e.e2345;
    
    return mv;

  endfunction

  function automatic ga_multivector_t mask_even(input ga_multivector_t mv);

    return even_to_mv(mv_to_even(mv));

  endfunction

  function automatic logic [2:0] ga_get_grade(ga_multivector_t mv);
    
    logic [GA_MV_WIDTH-1:0] max_grade0, max_grade1, max_grade2, max_grade3, max_grade4, max_grade5;
    logic [2:0] dominant_grade;
    
    max_grade0 = (mv.scalar[GA_MV_WIDTH-1]) ? ~mv.scalar + 1 : mv.scalar;
    
    max_grade1 = (mv.e1[GA_MV_WIDTH-1]) ? ~mv.e1 + 1 : mv.e1;

    max_grade1 = ((mv.e2[GA_MV_WIDTH-1]) ? ~mv.e2 + 1 : mv.e2) > max_grade1 ? 
                 ((mv.e2[GA_MV_WIDTH-1]) ? ~mv.e2 + 1 : mv.e2) : max_grade1;
    max_grade1 = ((mv.e3[GA_MV_WIDTH-1]) ? ~mv.e3 + 1 : mv.e3) > max_grade1 ? 
                 ((mv.e3[GA_MV_WIDTH-1]) ? ~mv.e3 + 1 : mv.e3) : max_grade1;
    max_grade1 = ((mv.e4[GA_MV_WIDTH-1]) ? ~mv.e4 + 1 : mv.e4) > max_grade1 ? 
                 ((mv.e4[GA_MV_WIDTH-1]) ? ~mv.e4 + 1 : mv.e4) : max_grade1;
    max_grade1 = ((mv.e5[GA_MV_WIDTH-1]) ? ~mv.e5 + 1 : mv.e5) > max_grade1 ? 
                 ((mv.e5[GA_MV_WIDTH-1]) ? ~mv.e5 + 1 : mv.e5) : max_grade1;
    
    max_grade2 = (mv.e12[GA_MV_WIDTH-1]) ? ~mv.e12 + 1 : mv.e12;

    max_grade2 = ((mv.e13[GA_MV_WIDTH-1]) ? ~mv.e13 + 1 : mv.e13) > max_grade2 ? 
                 ((mv.e13[GA_MV_WIDTH-1]) ? ~mv.e13 + 1 : mv.e13) : max_grade2;
    max_grade2 = ((mv.e23[GA_MV_WIDTH-1]) ? ~mv.e23 + 1 : mv.e23) > max_grade2 ? 
                 ((mv.e23[GA_MV_WIDTH-1]) ? ~mv.e23 + 1 : mv.e23) : max_grade2;
    max_grade2 = ((mv.e14[GA_MV_WIDTH-1]) ? ~mv.e14 + 1 : mv.e14) > max_grade2 ? 
                 ((mv.e14[GA_MV_WIDTH-1]) ? ~mv.e14 + 1 : mv.e14) : max_grade2;
    max_grade2 = ((mv.e45[GA_MV_WIDTH-1]) ? ~mv.e45 + 1 : mv.e45) > max_grade2 ? 
                 ((mv.e45[GA_MV_WIDTH-1]) ? ~mv.e45 + 1 : mv.e45) : max_grade2;
    
    max_grade3 = (mv.e123[GA_MV_WIDTH-1]) ? ~mv.e123 + 1 : mv.e123;
    max_grade4 = (mv.e1234[GA_MV_WIDTH-1]) ? ~mv.e1234 + 1 : mv.e1234;
    max_grade5 = (mv.e12345[GA_MV_WIDTH-1]) ? ~mv.e12345 + 1 : mv.e12345;
    
    dominant_grade = 3'b000;
    
    if (max_grade1 > max_grade0) dominant_grade = 3'b001;
    if (max_grade2 > max_grade1 && max_grade2 > max_grade0) dominant_grade = 3'b010;
    if (max_grade3 > max_grade2 && max_grade3 > max_grade1 && max_grade3 > max_grade0) dominant_grade = 3'b011;
    if (max_grade4 > max_grade3 && max_grade4 > max_grade2 && max_grade4 > max_grade1 && max_grade4 > max_grade0) dominant_grade = 3'b100;
    if (max_grade5 > max_grade4 && max_grade5 > max_grade3 && max_grade5 > max_grade2 && max_grade5 > max_grade1 && max_grade5 > max_grade0) dominant_grade = 3'b101;
    
    return dominant_grade;

endfunction

function automatic logic ga_is_scalar(ga_multivector_t mv);

    return (mv.e1 == 0) && (mv.e2 == 0) && (mv.e3 == 0) && (mv.e4 == 0) && (mv.e5 == 0) &&
           (mv.e12 == 0) && (mv.e13 == 0) && (mv.e23 == 0) && 
           (mv.e14 == 0) && (mv.e24 == 0) && (mv.e34 == 0) && 
           (mv.e15 == 0) && (mv.e25 == 0) && (mv.e35 == 0) && (mv.e45 == 0) &&
           (mv.e123 == 0) && (mv.e124 == 0) && (mv.e134 == 0) && (mv.e234 == 0) && 
           (mv.e125 == 0) && (mv.e135 == 0) && (mv.e235 == 0) && 
           (mv.e145 == 0) && (mv.e245 == 0) && (mv.e345 == 0) &&
           (mv.e1234 == 0) && (mv.e1235 == 0) && 
           (mv.e1245 == 0) && (mv.e1345 == 0) && (mv.e2345 == 0) &&
           (mv.e12345 == 0);

endfunction

function automatic logic ga_is_vector(ga_multivector_t mv);

    return (mv.scalar == 0) && 

           (mv.e12 == 0) && (mv.e13 == 0) && (mv.e23 == 0) && 
           (mv.e14 == 0) && (mv.e24 == 0) && (mv.e34 == 0) && 
           (mv.e15 == 0) && (mv.e25 == 0) && (mv.e35 == 0) && (mv.e45 == 0) &&
           (mv.e123 == 0) && (mv.e124 == 0) && (mv.e134 == 0) && (mv.e234 == 0) && 
           (mv.e125 == 0) && (mv.e135 == 0) && (mv.e235 == 0) && 
           (mv.e145 == 0) && (mv.e245 == 0) && (mv.e345 == 0) &&
           (mv.e1234 == 0) && (mv.e1235 == 0) && 
           (mv.e1245 == 0) && (mv.e1345 == 0) && (mv.e2345 == 0) &&
           (mv.e12345 == 0) &&
           ((mv.e1 != 0) || (mv.e2 != 0) || (mv.e3 != 0) || (mv.e4 != 0) || (mv.e5 != 0));

endfunction

function automatic logic ga_is_bivector(ga_multivector_t mv);

    return (mv.scalar == 0) && 
           (mv.e1 == 0) && (mv.e2 == 0) && (mv.e3 == 0) && (mv.e4 == 0) && (mv.e5 == 0) &&
           (mv.e123 == 0) && (mv.e124 == 0) && (mv.e134 == 0) && (mv.e234 == 0) && 
           (mv.e125 == 0) && (mv.e135 == 0) && (mv.e235 == 0) && 
           (mv.e145 == 0) && (mv.e245 == 0) && (mv.e345 == 0) &&
           (mv.e1234 == 0) && (mv.e1235 == 0) && 
           (mv.e1245 == 0) && (mv.e1345 == 0) && (mv.e2345 == 0) &&
           (mv.e12345 == 0) &&
           ((mv.e12 != 0) || (mv.e13 != 0) || (mv.e23 != 0) || 
            (mv.e14 != 0) || (mv.e24 != 0) || (mv.e34 != 0) || 
            (mv.e15 != 0) || (mv.e25 != 0) || (mv.e35 != 0) || (mv.e45 != 0));

endfunction

function automatic logic ga_is_cga_point(ga_multivector_t mv);

    return (mv.scalar == 0) && 
           (mv.e4 != 0) &&
           (mv.e12 == 0) && (mv.e13 == 0) && (mv.e23 == 0) && 
           (mv.e14 == 0) && (mv.e24 == 0) && (mv.e34 == 0) && 
           (mv.e15 == 0) && (mv.e25 == 0) && (mv.e35 == 0) && (mv.e45 == 0) &&
           (mv.e123 == 0) && (mv.e124 == 0) && (mv.e134 == 0) && (mv.e234 == 0) && 
           (mv.e125 == 0) && (mv.e135 == 0) && (mv.e235 == 0) && 
           (mv.e145 == 0) && (mv.e245 == 0) && (mv.e345 == 0) &&
           (mv.e1234 == 0) && (mv.e1235 == 0) && 
           (mv.e1245 == 0) && (mv.e1345 == 0) && (mv.e2345 == 0) &&
           (mv.e12345 == 0);
endfunction

function automatic logic ga_is_cga_sphere(ga_multivector_t mv);
    
    return (mv.scalar == 0) && 
           (mv.e1 == 0) && (mv.e2 == 0) && (mv.e3 == 0) && (mv.e4 == 0) && (mv.e5 == 0) &&
           (mv.e12 == 0) && (mv.e13 == 0) && (mv.e23 == 0) && 
           (mv.e14 == 0) && (mv.e24 == 0) && (mv.e34 == 0) && 
           (mv.e15 == 0) && (mv.e25 == 0) && (mv.e35 == 0) && (mv.e45 == 0) &&
           (mv.e123 == 0) && (mv.e124 == 0) && (mv.e134 == 0) && (mv.e234 == 0) && 
           (mv.e125 == 0) && (mv.e135 == 0) && (mv.e235 == 0) && 
           (mv.e145 == 0) && (mv.e245 == 0) && (mv.e345 == 0) &&
           (mv.e12345 == 0) &&
           ((mv.e1234 != 0) || (mv.e1235 != 0) || 
            (mv.e1245 != 0) || (mv.e1345 != 0) || (mv.e2345 != 0));

endfunction

endpackage
