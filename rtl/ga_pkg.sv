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
    logic [GA_MV_WIDTH-1:0] eo;
    logic [GA_MV_WIDTH-1:0] ei;
    logic [GA_MV_WIDTH-1:0] e12;
    logic [GA_MV_WIDTH-1:0] e13;
    logic [GA_MV_WIDTH-1:0] e23;
    logic [GA_MV_WIDTH-1:0] e1o;
    logic [GA_MV_WIDTH-1:0] e2o;
    logic [GA_MV_WIDTH-1:0] e3o;
    logic [GA_MV_WIDTH-1:0] e1i;
    logic [GA_MV_WIDTH-1:0] e2i;
    logic [GA_MV_WIDTH-1:0] e3i;
    logic [GA_MV_WIDTH-1:0] eoi;
    logic [GA_MV_WIDTH-1:0] e123;
    logic [GA_MV_WIDTH-1:0] e12o;
    logic [GA_MV_WIDTH-1:0] e13o;
    logic [GA_MV_WIDTH-1:0] e23o;
    logic [GA_MV_WIDTH-1:0] e12i;
    logic [GA_MV_WIDTH-1:0] e13i;
    logic [GA_MV_WIDTH-1:0] e23i;
    logic [GA_MV_WIDTH-1:0] e1oi;
    logic [GA_MV_WIDTH-1:0] e2oi;
    logic [GA_MV_WIDTH-1:0] e3oi;
    logic [GA_MV_WIDTH-1:0] e123o;
    logic [GA_MV_WIDTH-1:0] e123i;
    logic [GA_MV_WIDTH-1:0] e12oi;
    logic [GA_MV_WIDTH-1:0] e13oi;
    logic [GA_MV_WIDTH-1:0] e23oi;
    logic [GA_MV_WIDTH-1:0] e123oi;
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
    logic signed [15:0] e1o, e2o, e3o;
    logic signed [15:0] e1i, e2i, e3i;
    logic signed [15:0] eoi;
    logic signed [15:0] e123o, e123i;
    logic signed [15:0] e12oi, e13oi, e23oi;
  } ga_even_multivector_t;

  function automatic ga_even_multivector_t mv_to_even(input ga_multivector_t mv);

    ga_even_multivector_t r;
    r.scalar = mv.scalar;
    r.e12    = mv.e12;    r.e13    = mv.e13;    r.e23    = mv.e23;
    r.e1o    = mv.e1o;    r.e2o    = mv.e2o;    r.e3o    = mv.e3o;
    r.e1i    = mv.e1i;    r.e2i    = mv.e2i;    r.e3i    = mv.e3i;
    r.eoi    = mv.eoi;
    r.e123o  = mv.e123o;  r.e123i  = mv.e123i;
    r.e12oi  = mv.e12oi;  r.e13oi  = mv.e13oi;  r.e23oi  = mv.e23oi;

    return r;

  endfunction

  function automatic ga_multivector_t even_to_mv(input ga_even_multivector_t e);

    ga_multivector_t mv = '0;
    mv.scalar = e.scalar;
    mv.e12    = e.e12;    mv.e13    = e.e13;    mv.e23    = e.e23;
    mv.e1o    = e.e1o;    mv.e2o    = e.e2o;    mv.e3o    = e.e3o;
    mv.e1i    = e.e1i;    mv.e2i    = e.e2i;    mv.e3i    = e.e3i;
    mv.eoi    = e.eoi;
    mv.e123o  = e.e123o;  mv.e123i  = e.e123i;
    mv.e12oi  = e.e12oi;  mv.e13oi  = e.e13oi;  mv.e23oi  = e.e23oi;
    
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
    max_grade1 = ((mv.eo[GA_MV_WIDTH-1]) ? ~mv.eo + 1 : mv.eo) > max_grade1 ? 
                 ((mv.eo[GA_MV_WIDTH-1]) ? ~mv.eo + 1 : mv.eo) : max_grade1;
    max_grade1 = ((mv.ei[GA_MV_WIDTH-1]) ? ~mv.ei + 1 : mv.ei) > max_grade1 ? 
                 ((mv.ei[GA_MV_WIDTH-1]) ? ~mv.ei + 1 : mv.ei) : max_grade1;
    
    max_grade2 = (mv.e12[GA_MV_WIDTH-1]) ? ~mv.e12 + 1 : mv.e12;

    max_grade2 = ((mv.e13[GA_MV_WIDTH-1]) ? ~mv.e13 + 1 : mv.e13) > max_grade2 ? 
                 ((mv.e13[GA_MV_WIDTH-1]) ? ~mv.e13 + 1 : mv.e13) : max_grade2;
    max_grade2 = ((mv.e23[GA_MV_WIDTH-1]) ? ~mv.e23 + 1 : mv.e23) > max_grade2 ? 
                 ((mv.e23[GA_MV_WIDTH-1]) ? ~mv.e23 + 1 : mv.e23) : max_grade2;
    max_grade2 = ((mv.e1o[GA_MV_WIDTH-1]) ? ~mv.e1o + 1 : mv.e1o) > max_grade2 ? 
                 ((mv.e1o[GA_MV_WIDTH-1]) ? ~mv.e1o + 1 : mv.e1o) : max_grade2;
    max_grade2 = ((mv.eoi[GA_MV_WIDTH-1]) ? ~mv.eoi + 1 : mv.eoi) > max_grade2 ? 
                 ((mv.eoi[GA_MV_WIDTH-1]) ? ~mv.eoi + 1 : mv.eoi) : max_grade2;
    
    max_grade3 = (mv.e123[GA_MV_WIDTH-1]) ? ~mv.e123 + 1 : mv.e123;
    max_grade4 = (mv.e123o[GA_MV_WIDTH-1]) ? ~mv.e123o + 1 : mv.e123o;
    max_grade5 = (mv.e123oi[GA_MV_WIDTH-1]) ? ~mv.e123oi + 1 : mv.e123oi;
    
    dominant_grade = 3'b000;
    
    if (max_grade1 > max_grade0) dominant_grade = 3'b001;
    if (max_grade2 > max_grade1 && max_grade2 > max_grade0) dominant_grade = 3'b010;
    if (max_grade3 > max_grade2 && max_grade3 > max_grade1 && max_grade3 > max_grade0) dominant_grade = 3'b011;
    if (max_grade4 > max_grade3 && max_grade4 > max_grade2 && max_grade4 > max_grade1 && max_grade4 > max_grade0) dominant_grade = 3'b100;
    if (max_grade5 > max_grade4 && max_grade5 > max_grade3 && max_grade5 > max_grade2 && max_grade5 > max_grade1 && max_grade5 > max_grade0) dominant_grade = 3'b101;
    
    return dominant_grade;

endfunction

function automatic logic ga_is_scalar(ga_multivector_t mv);

    return (mv.e1 == 0) && (mv.e2 == 0) && (mv.e3 == 0) && (mv.eo == 0) && (mv.ei == 0) &&
           (mv.e12 == 0) && (mv.e13 == 0) && (mv.e23 == 0) && 
           (mv.e1o == 0) && (mv.e2o == 0) && (mv.e3o == 0) && 
           (mv.e1i == 0) && (mv.e2i == 0) && (mv.e3i == 0) && (mv.eoi == 0) &&
           (mv.e123 == 0) && (mv.e12o == 0) && (mv.e13o == 0) && (mv.e23o == 0) && 
           (mv.e12i == 0) && (mv.e13i == 0) && (mv.e23i == 0) && 
           (mv.e1oi == 0) && (mv.e2oi == 0) && (mv.e3oi == 0) &&
           (mv.e123o == 0) && (mv.e123i == 0) && 
           (mv.e12oi == 0) && (mv.e13oi == 0) && (mv.e23oi == 0) &&
           (mv.e123oi == 0);

endfunction

function automatic logic ga_is_vector(ga_multivector_t mv);

    return (mv.scalar == 0) && 

           (mv.e12 == 0) && (mv.e13 == 0) && (mv.e23 == 0) && 
           (mv.e1o == 0) && (mv.e2o == 0) && (mv.e3o == 0) && 
           (mv.e1i == 0) && (mv.e2i == 0) && (mv.e3i == 0) && (mv.eoi == 0) &&
           (mv.e123 == 0) && (mv.e12o == 0) && (mv.e13o == 0) && (mv.e23o == 0) && 
           (mv.e12i == 0) && (mv.e13i == 0) && (mv.e23i == 0) && 
           (mv.e1oi == 0) && (mv.e2oi == 0) && (mv.e3oi == 0) &&
           (mv.e123o == 0) && (mv.e123i == 0) && 
           (mv.e12oi == 0) && (mv.e13oi == 0) && (mv.e23oi == 0) &&
           (mv.e123oi == 0) &&
           ((mv.e1 != 0) || (mv.e2 != 0) || (mv.e3 != 0) || (mv.eo != 0) || (mv.ei != 0));

endfunction

function automatic logic ga_is_bivector(ga_multivector_t mv);

    return (mv.scalar == 0) && 
           (mv.e1 == 0) && (mv.e2 == 0) && (mv.e3 == 0) && (mv.eo == 0) && (mv.ei == 0) &&
           (mv.e123 == 0) && (mv.e12o == 0) && (mv.e13o == 0) && (mv.e23o == 0) && 
           (mv.e12i == 0) && (mv.e13i == 0) && (mv.e23i == 0) && 
           (mv.e1oi == 0) && (mv.e2oi == 0) && (mv.e3oi == 0) &&
           (mv.e123o == 0) && (mv.e123i == 0) && 
           (mv.e12oi == 0) && (mv.e13oi == 0) && (mv.e23oi == 0) &&
           (mv.e123oi == 0) &&
           ((mv.e12 != 0) || (mv.e13 != 0) || (mv.e23 != 0) || 
            (mv.e1o != 0) || (mv.e2o != 0) || (mv.e3o != 0) || 
            (mv.e1i != 0) || (mv.e2i != 0) || (mv.e3i != 0) || (mv.eoi != 0));

endfunction

function automatic logic ga_is_cga_point(ga_multivector_t mv);

    return (mv.scalar == 0) && 
           (mv.eo != 0) &&
           (mv.e12 == 0) && (mv.e13 == 0) && (mv.e23 == 0) && 
           (mv.e1o == 0) && (mv.e2o == 0) && (mv.e3o == 0) && 
           (mv.e1i == 0) && (mv.e2i == 0) && (mv.e3i == 0) && (mv.eoi == 0) &&
           (mv.e123 == 0) && (mv.e12o == 0) && (mv.e13o == 0) && (mv.e23o == 0) && 
           (mv.e12i == 0) && (mv.e13i == 0) && (mv.e23i == 0) && 
           (mv.e1oi == 0) && (mv.e2oi == 0) && (mv.e3oi == 0) &&
           (mv.e123o == 0) && (mv.e123i == 0) && 
           (mv.e12oi == 0) && (mv.e13oi == 0) && (mv.e23oi == 0) &&
           (mv.e123oi == 0);
endfunction

function automatic logic ga_is_cga_sphere(ga_multivector_t mv);
    
    return (mv.scalar == 0) && 
           (mv.e1 == 0) && (mv.e2 == 0) && (mv.e3 == 0) && (mv.eo == 0) && (mv.ei == 0) &&
           (mv.e12 == 0) && (mv.e13 == 0) && (mv.e23 == 0) && 
           (mv.e1o == 0) && (mv.e2o == 0) && (mv.e3o == 0) && 
           (mv.e1i == 0) && (mv.e2i == 0) && (mv.e3i == 0) && (mv.eoi == 0) &&
           (mv.e123 == 0) && (mv.e12o == 0) && (mv.e13o == 0) && (mv.e23o == 0) && 
           (mv.e12i == 0) && (mv.e13i == 0) && (mv.e23i == 0) && 
           (mv.e1oi == 0) && (mv.e2oi == 0) && (mv.e3oi == 0) &&
           (mv.e123oi == 0) &&
           ((mv.e123o != 0) || (mv.e123i != 0) || 
            (mv.e12oi != 0) || (mv.e13oi != 0) || (mv.e23oi != 0));

endfunction

endpackage
