module ga_alu_even
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

    localparam int EVEN_LANES = 16;

    typedef enum int unsigned 
    {
        L_SCALAR = 0,
        L_E12 = 1,
        L_E13 = 2,
        L_E23 = 3,
        L_E1O = 4,
        L_E2O = 5,
        L_E3O = 6,
        L_E1I = 7,
        L_E2I = 8,
        L_E3I = 9,
        L_EOI = 10,
        L_E123O = 11,
        L_E123I = 12,
        L_E12OI = 13,
        L_E13OI = 14,
        L_E23OI = 15
    } even_lane_e;

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

    function automatic logic signed [FP_W-1:0] sat16_q511(longint signed acc_raw);

        longint signed r = acc_raw + (1 <<< (FP_FRAC-1));
        longint signed s = r >>> FP_FRAC;
        longint signed maxv =  (1 <<< (FP_W-1)) - 1;
        longint signed minv = -(1 <<< (FP_W-1));
        if (s > maxv) s = maxv;
        if (s < minv) s = minv;

        return s[FP_W-1:0];

    endfunction

    function automatic void pack_even(input ga_multivector_t mv,
                                    output logic signed [FP_W-1:0] lane[EVEN_LANES]);
                                    
        lane[L_SCALAR] = mv.scalar;
        lane[L_E12] = mv.e12;
        lane[L_E13] = mv.e13;
        lane[L_E23] = mv.e23;
        lane[L_E1O] = mv.e1o;
        lane[L_E2O] = mv.e2o;
        lane[L_E3O] = mv.e3o;
        lane[L_E1I] = mv.e1i;
        lane[L_E2I] = mv.e2i;
        lane[L_E3I] = mv.e3i;
        lane[L_EOI] = mv.eoi;
        lane[L_E123O] = mv.e123o;
        lane[L_E123I] = mv.e123i;
        lane[L_E12OI] = mv.e12oi;
        lane[L_E13OI] = mv.e13oi;
        lane[L_E23OI] = mv.e23oi;

    endfunction

    function automatic ga_multivector_t unpack_even(input logic signed [FP_W-1:0] lane[EVEN_LANES]);

        ga_multivector_t mv = '0;
        mv.scalar = lane[L_SCALAR];
        mv.e12 = lane[L_E12];
        mv.e13 = lane[L_E13];
        mv.e23 = lane[L_E23];
        mv.e1o = lane[L_E1O];
        mv.e2o = lane[L_E2O];
        mv.e3o = lane[L_E3O];
        mv.e1i = lane[L_E1I];
        mv.e2i = lane[L_E2I];
        mv.e3i = lane[L_E3I];
        mv.eoi = lane[L_EOI];
        mv.e123o = lane[L_E123O];
        mv.e123i = lane[L_E123I];
        mv.e12oi = lane[L_E12OI];
        mv.e13oi = lane[L_E13OI];
        mv.e23oi = lane[L_E23OI];
        return mv;

    endfunction

    function automatic ga_multivector_t geometricProduct_even(
        ga_multivector_t a,
        ga_multivector_t b
    );
        longint signed acc[EVEN_LANES];
        logic signed [FP_W-1:0] al[EVEN_LANES], bl[EVEN_LANES];
        logic signed [FP_W-1:0] out_lane[EVEN_LANES];
        
        for (int i = 0; i < EVEN_LANES; i++) 
            acc[i] = 0;
        
        pack_even(a, al);
        pack_even(b, bl);

        `define ACCP(idx, xa, xb) acc[idx] += longint'($signed(xa)) * longint'($signed(xb))
        `define ACCN(idx, xa, xb) acc[idx] -= longint'($signed(xa)) * longint'($signed(xb))

        `ACCP(L_SCALAR, al[L_SCALAR], bl[L_SCALAR]);
        `ACCN(L_SCALAR, al[L_E12], bl[L_E12]);
        `ACCN(L_SCALAR, al[L_E13], bl[L_E13]);
        `ACCN(L_SCALAR, al[L_E23], bl[L_E23]);
        `ACCP(L_SCALAR, al[L_E1O], bl[L_E1I]);
        `ACCP(L_SCALAR, al[L_E2O], bl[L_E2I]);
        `ACCP(L_SCALAR, al[L_E3O], bl[L_E3I]);
        `ACCN(L_SCALAR, al[L_E123O], bl[L_E123I]);
        `ACCP(L_SCALAR, al[L_E1I], bl[L_E1O]);
        `ACCP(L_SCALAR, al[L_E2I], bl[L_E2O]);
        `ACCP(L_SCALAR, al[L_E3I], bl[L_E3O]);
        `ACCN(L_SCALAR, al[L_E123I], bl[L_E123O]);
        `ACCN(L_SCALAR, al[L_EOI], bl[L_SCALAR]);
        `ACCP(L_SCALAR, al[L_EOI], bl[L_EOI]);
        `ACCP(L_SCALAR, al[L_E12OI], bl[L_E12]);
    // Removed self-product contribution of e12oi into scalar (should be 0)
    //`ACCN(L_SCALAR, al[L_E12OI], bl[L_E12OI]);
        `ACCP(L_SCALAR, al[L_E13OI], bl[L_E13]);
    // Removed self-product contribution of e13oi into scalar (should be 0)
    //`ACCN(L_SCALAR, al[L_E13OI], bl[L_E13OI]);
        `ACCP(L_SCALAR, al[L_E23OI], bl[L_E23]);
    // Removed self-product contribution of e23oi into scalar (should be 0)
    //`ACCN(L_SCALAR, al[L_E23OI], bl[L_E23OI]);

        `ACCP(L_E12, al[L_SCALAR], bl[L_E12]);
        `ACCP(L_E12, al[L_E12], bl[L_SCALAR]);
        `ACCN(L_E12, al[L_E13], bl[L_E23]);
        `ACCP(L_E12, al[L_E23], bl[L_E13]);
        `ACCP(L_E12, al[L_E1O], bl[L_E2I]);
        `ACCN(L_E12, al[L_E2O], bl[L_E1I]);
        `ACCP(L_E12, al[L_E3O], bl[L_E123I]);
        `ACCP(L_E12, al[L_E123O], bl[L_E3I]);
        `ACCP(L_E12, al[L_E1I], bl[L_E2O]);
        `ACCN(L_E12, al[L_E2I], bl[L_E1O]);
        `ACCP(L_E12, al[L_E3I], bl[L_E123O]);
        `ACCP(L_E12, al[L_E123I], bl[L_E3O]);
        `ACCN(L_E12, al[L_EOI], bl[L_E12]);
        `ACCP(L_E12, al[L_EOI], bl[L_E12OI]);
        `ACCN(L_E12, al[L_E12OI], bl[L_SCALAR]);
        `ACCP(L_E12, al[L_E12OI], bl[L_EOI]);
        `ACCP(L_E12, al[L_E13OI], bl[L_E23]);
        `ACCN(L_E12, al[L_E13OI], bl[L_E23OI]);
        `ACCN(L_E12, al[L_E23OI], bl[L_E13]);
        `ACCP(L_E12, al[L_E23OI], bl[L_E13OI]);

        `ACCP(L_E13, al[L_SCALAR], bl[L_E13]);
        `ACCP(L_E13, al[L_E12], bl[L_E23]);
        `ACCP(L_E13, al[L_E13], bl[L_SCALAR]);
        `ACCN(L_E13, al[L_E23], bl[L_E12]);
        `ACCP(L_E13, al[L_E1O], bl[L_E3I]);
        `ACCN(L_E13, al[L_E2O], bl[L_E123I]);
        `ACCN(L_E13, al[L_E3O], bl[L_E1I]);
        `ACCN(L_E13, al[L_E123O], bl[L_E2I]);
        `ACCP(L_E13, al[L_E1I], bl[L_E3O]);
        `ACCN(L_E13, al[L_E2I], bl[L_E123O]);
        `ACCN(L_E13, al[L_E3I], bl[L_E1O]);
        `ACCN(L_E13, al[L_E123I], bl[L_E2O]);
        `ACCN(L_E13, al[L_EOI], bl[L_E13]);
        `ACCP(L_E13, al[L_EOI], bl[L_E13OI]);
        `ACCN(L_E13, al[L_E12OI], bl[L_E23]);
        `ACCP(L_E13, al[L_E12OI], bl[L_E23OI]);
        `ACCN(L_E13, al[L_E13OI], bl[L_SCALAR]);
        `ACCP(L_E13, al[L_E13OI], bl[L_EOI]);
        `ACCP(L_E13, al[L_E23OI], bl[L_E12]);
        `ACCN(L_E13, al[L_E23OI], bl[L_E12OI]);

        `ACCP(L_E23, al[L_SCALAR], bl[L_E23]);
        `ACCN(L_E23, al[L_E12], bl[L_E13]);
        `ACCP(L_E23, al[L_E13], bl[L_E12]);
        `ACCP(L_E23, al[L_E23], bl[L_SCALAR]);
        `ACCP(L_E23, al[L_E1O], bl[L_E123I]);
        `ACCP(L_E23, al[L_E2O], bl[L_E3I]);
        `ACCN(L_E23, al[L_E3O], bl[L_E2I]);
        `ACCP(L_E23, al[L_E123O], bl[L_E1I]);
        `ACCP(L_E23, al[L_E1I], bl[L_E123O]);
        `ACCP(L_E23, al[L_E2I], bl[L_E3O]);
        `ACCN(L_E23, al[L_E3I], bl[L_E2O]);
        `ACCP(L_E23, al[L_E123I], bl[L_E1O]);
        `ACCN(L_E23, al[L_EOI], bl[L_E23]);
        `ACCP(L_E23, al[L_EOI], bl[L_E23OI]);
        `ACCP(L_E23, al[L_E12OI], bl[L_E13]);
        `ACCN(L_E23, al[L_E12OI], bl[L_E13OI]);
        `ACCN(L_E23, al[L_E13OI], bl[L_E12]);
        `ACCP(L_E23, al[L_E13OI], bl[L_E12OI]);
        `ACCN(L_E23, al[L_E23OI], bl[L_SCALAR]);
        `ACCP(L_E23, al[L_E23OI], bl[L_EOI]);

        `ACCP(L_E1O, al[L_SCALAR], bl[L_E1O]);
        `ACCP(L_E1O, al[L_E12], bl[L_E2O]);
        `ACCP(L_E1O, al[L_E13], bl[L_E3O]);
        `ACCN(L_E1O, al[L_E23], bl[L_E123O]);
        `ACCP(L_E1O, al[L_E1O], bl[L_SCALAR]);
        `ACCP(L_E1O, al[L_E1O], bl[L_EOI]);
        `ACCN(L_E1O, al[L_E2O], bl[L_E12]);
        `ACCN(L_E1O, al[L_E2O], bl[L_E12OI]);
        `ACCN(L_E1O, al[L_E3O], bl[L_E13]);
        `ACCN(L_E1O, al[L_E3O], bl[L_E13OI]);
        `ACCN(L_E1O, al[L_E123O], bl[L_E23]);
        `ACCN(L_E1O, al[L_E123O], bl[L_E23OI]);
        `ACCN(L_E1O, al[L_EOI], bl[L_E1O]);
        `ACCN(L_E1O, al[L_EOI], bl[L_E1O]);
        `ACCN(L_E1O, al[L_E12OI], bl[L_E2O]);
        `ACCN(L_E1O, al[L_E12OI], bl[L_E2O]);
        `ACCN(L_E1O, al[L_E13OI], bl[L_E3O]);
        `ACCN(L_E1O, al[L_E13OI], bl[L_E3O]);
        `ACCP(L_E1O, al[L_E23OI], bl[L_E123O]);
        `ACCP(L_E1O, al[L_E23OI], bl[L_E123O]);

        `ACCP(L_E2O, al[L_SCALAR], bl[L_E2O]);
        `ACCN(L_E2O, al[L_E12], bl[L_E1O]);
        `ACCP(L_E2O, al[L_E13], bl[L_E123O]);
        `ACCP(L_E2O, al[L_E23], bl[L_E3O]);
        `ACCP(L_E2O, al[L_E1O], bl[L_E12]);
        `ACCP(L_E2O, al[L_E1O], bl[L_E12OI]);
        `ACCP(L_E2O, al[L_E2O], bl[L_SCALAR]);
        `ACCP(L_E2O, al[L_E2O], bl[L_EOI]);
        `ACCN(L_E2O, al[L_E3O], bl[L_E23]);
        `ACCN(L_E2O, al[L_E3O], bl[L_E23OI]);
        `ACCP(L_E2O, al[L_E123O], bl[L_E13]);
        `ACCP(L_E2O, al[L_E123O], bl[L_E13OI]);
        `ACCN(L_E2O, al[L_EOI], bl[L_E2O]);
        `ACCN(L_E2O, al[L_EOI], bl[L_E2O]);
        `ACCP(L_E2O, al[L_E12OI], bl[L_E1O]);
        `ACCP(L_E2O, al[L_E12OI], bl[L_E1O]);
        `ACCN(L_E2O, al[L_E13OI], bl[L_E123O]);
        `ACCN(L_E2O, al[L_E13OI], bl[L_E123O]);
        `ACCN(L_E2O, al[L_E23OI], bl[L_E3O]);
        `ACCN(L_E2O, al[L_E23OI], bl[L_E3O]);

        `ACCP(L_E3O, al[L_SCALAR], bl[L_E3O]);
        `ACCN(L_E3O, al[L_E12], bl[L_E123O]);
        `ACCN(L_E3O, al[L_E13], bl[L_E1O]);
        `ACCN(L_E3O, al[L_E23], bl[L_E2O]);
        `ACCP(L_E3O, al[L_E1O], bl[L_E13]);
        `ACCP(L_E3O, al[L_E1O], bl[L_E13OI]);
        `ACCP(L_E3O, al[L_E2O], bl[L_E23]);
        `ACCP(L_E3O, al[L_E2O], bl[L_E23OI]);
        `ACCP(L_E3O, al[L_E3O], bl[L_SCALAR]);
        `ACCP(L_E3O, al[L_E3O], bl[L_EOI]);
        `ACCN(L_E3O, al[L_E123O], bl[L_E12]);
        `ACCN(L_E3O, al[L_E123O], bl[L_E12OI]);
        `ACCN(L_E3O, al[L_EOI], bl[L_E3O]);
        `ACCN(L_E3O, al[L_EOI], bl[L_E3O]);
        `ACCP(L_E3O, al[L_E12OI], bl[L_E123O]);
        `ACCP(L_E3O, al[L_E12OI], bl[L_E123O]);
        `ACCP(L_E3O, al[L_E13OI], bl[L_E1O]);
        `ACCP(L_E3O, al[L_E13OI], bl[L_E1O]);
        `ACCP(L_E3O, al[L_E23OI], bl[L_E2O]);
        `ACCP(L_E3O, al[L_E23OI], bl[L_E2O]);

        `ACCP(L_E1I, al[L_SCALAR], bl[L_E1I]);
        `ACCP(L_E1I, al[L_E12], bl[L_E2I]);
        `ACCP(L_E1I, al[L_E13], bl[L_E3I]);
        `ACCN(L_E1I, al[L_E23], bl[L_E123I]);
        `ACCP(L_E1I, al[L_E1I], bl[L_SCALAR]);
        `ACCN(L_E1I, al[L_E1I], bl[L_EOI]);
        `ACCN(L_E1I, al[L_E2I], bl[L_E12]);
        `ACCP(L_E1I, al[L_E2I], bl[L_E12OI]);
        `ACCN(L_E1I, al[L_E3I], bl[L_E13]);
        `ACCP(L_E1I, al[L_E3I], bl[L_E13OI]);
        `ACCN(L_E1I, al[L_E123I], bl[L_E23]);
        `ACCP(L_E1I, al[L_E123I], bl[L_E23OI]);

        `ACCP(L_E2I, al[L_SCALAR], bl[L_E2I]);
        `ACCN(L_E2I, al[L_E12], bl[L_E1I]);
        `ACCP(L_E2I, al[L_E13], bl[L_E123I]);
        `ACCP(L_E2I, al[L_E23], bl[L_E3I]);
        `ACCP(L_E2I, al[L_E1I], bl[L_E12]);
        `ACCN(L_E2I, al[L_E1I], bl[L_E12OI]);
        `ACCP(L_E2I, al[L_E2I], bl[L_SCALAR]);
        `ACCN(L_E2I, al[L_E2I], bl[L_EOI]);
        `ACCN(L_E2I, al[L_E3I], bl[L_E23]);
        `ACCP(L_E2I, al[L_E3I], bl[L_E23OI]);
        `ACCP(L_E2I, al[L_E123I], bl[L_E13]);
        `ACCN(L_E2I, al[L_E123I], bl[L_E13OI]);

        `ACCP(L_E3I, al[L_SCALAR], bl[L_E3I]);
        `ACCN(L_E3I, al[L_E12], bl[L_E123I]);
        `ACCN(L_E3I, al[L_E13], bl[L_E1I]);
        `ACCN(L_E3I, al[L_E23], bl[L_E2I]);
        `ACCP(L_E3I, al[L_E1I], bl[L_E13]);
        `ACCN(L_E3I, al[L_E1I], bl[L_E13OI]);
        `ACCP(L_E3I, al[L_E2I], bl[L_E23]);
        `ACCN(L_E3I, al[L_E2I], bl[L_E23OI]);
        `ACCP(L_E3I, al[L_E3I], bl[L_SCALAR]);
        `ACCN(L_E3I, al[L_E3I], bl[L_EOI]);
        `ACCN(L_E3I, al[L_E123I], bl[L_E12]);
        `ACCP(L_E3I, al[L_E123I], bl[L_E12OI]);

        `ACCP(L_EOI, al[L_SCALAR], bl[L_EOI]);
        `ACCN(L_EOI, al[L_E12], bl[L_E12OI]);
        `ACCN(L_EOI, al[L_E13], bl[L_E13OI]);
        `ACCN(L_EOI, al[L_E23], bl[L_E23OI]);
        `ACCN(L_EOI, al[L_E1O], bl[L_E1I]);
        `ACCN(L_EOI, al[L_E2O], bl[L_E2I]);
        `ACCN(L_EOI, al[L_E3O], bl[L_E3I]);
        `ACCP(L_EOI, al[L_E123O], bl[L_E123I]);
        `ACCP(L_EOI, al[L_E1I], bl[L_E1O]);
        `ACCP(L_EOI, al[L_E2I], bl[L_E2O]);
        `ACCP(L_EOI, al[L_E3I], bl[L_E3O]);
        `ACCN(L_EOI, al[L_E123I], bl[L_E123O]);
        `ACCP(L_EOI, al[L_EOI], bl[L_SCALAR]);
        `ACCN(L_EOI, al[L_EOI], bl[L_EOI]);
        `ACCN(L_EOI, al[L_E12OI], bl[L_E12]);
    
        `ACCN(L_EOI, al[L_E13OI], bl[L_E13]);
        `ACCN(L_EOI, al[L_E23OI], bl[L_E23]);

        `ACCP(L_E123O, al[L_SCALAR], bl[L_E123O]);
        `ACCP(L_E123O, al[L_E12], bl[L_E3O]);
        `ACCN(L_E123O, al[L_E13], bl[L_E2O]);
        `ACCP(L_E123O, al[L_E23], bl[L_E1O]);
        `ACCP(L_E123O, al[L_E1O], bl[L_E23]);
        `ACCP(L_E123O, al[L_E1O], bl[L_E23OI]);
        `ACCN(L_E123O, al[L_E2O], bl[L_E13]);
        `ACCN(L_E123O, al[L_E2O], bl[L_E13OI]);
        `ACCP(L_E123O, al[L_E3O], bl[L_E12]);
        `ACCP(L_E123O, al[L_E3O], bl[L_E12OI]);
        `ACCP(L_E123O, al[L_E123O], bl[L_SCALAR]);
        `ACCP(L_E123O, al[L_E123O], bl[L_EOI]);
        `ACCN(L_E123O, al[L_EOI], bl[L_E123O]);
        `ACCN(L_E123O, al[L_EOI], bl[L_E123O]);
        `ACCN(L_E123O, al[L_E12OI], bl[L_E3O]);
        `ACCN(L_E123O, al[L_E12OI], bl[L_E3O]);
        `ACCP(L_E123O, al[L_E13OI], bl[L_E2O]);
        `ACCP(L_E123O, al[L_E13OI], bl[L_E2O]);
        `ACCN(L_E123O, al[L_E23OI], bl[L_E1O]);
        `ACCN(L_E123O, al[L_E23OI], bl[L_E1O]);

        `ACCP(L_E123I, al[L_SCALAR], bl[L_E123I]);
        `ACCP(L_E123I, al[L_E12], bl[L_E3I]);
        `ACCN(L_E123I, al[L_E13], bl[L_E2I]);
        `ACCP(L_E123I, al[L_E23], bl[L_E1I]);
        `ACCP(L_E123I, al[L_E1I], bl[L_E23]);
        `ACCN(L_E123I, al[L_E1I], bl[L_E23OI]);
        `ACCN(L_E123I, al[L_E2I], bl[L_E13]);
        `ACCP(L_E123I, al[L_E2I], bl[L_E13OI]);
        `ACCP(L_E123I, al[L_E3I], bl[L_E12]);
        `ACCN(L_E123I, al[L_E3I], bl[L_E12OI]);
        `ACCP(L_E123I, al[L_E123I], bl[L_SCALAR]);
        `ACCN(L_E123I, al[L_E123I], bl[L_EOI]);

        `ACCP(L_E12OI, al[L_SCALAR], bl[L_E12OI]);
        `ACCP(L_E12OI, al[L_E12], bl[L_EOI]);
        `ACCN(L_E12OI, al[L_E13], bl[L_E23OI]);
        `ACCP(L_E12OI, al[L_E23], bl[L_E13OI]);
        `ACCN(L_E12OI, al[L_E1O], bl[L_E2I]);
        `ACCP(L_E12OI, al[L_E2O], bl[L_E1I]);
        `ACCN(L_E12OI, al[L_E3O], bl[L_E123I]);
        `ACCN(L_E12OI, al[L_E123O], bl[L_E3I]);
        `ACCP(L_E12OI, al[L_E1I], bl[L_E2O]);
        `ACCN(L_E12OI, al[L_E2I], bl[L_E1O]);
        `ACCP(L_E12OI, al[L_E3I], bl[L_E123O]);
        `ACCP(L_E12OI, al[L_E123I], bl[L_E3O]);
        `ACCP(L_E12OI, al[L_EOI], bl[L_E12]);
        `ACCN(L_E12OI, al[L_EOI], bl[L_E12OI]);
        `ACCP(L_E12OI, al[L_E12OI], bl[L_SCALAR]);
        `ACCN(L_E12OI, al[L_E12OI], bl[L_EOI]);
        `ACCN(L_E12OI, al[L_E13OI], bl[L_E23]);
        `ACCP(L_E12OI, al[L_E13OI], bl[L_E23OI]);
        `ACCP(L_E12OI, al[L_E23OI], bl[L_E13]);
        `ACCN(L_E12OI, al[L_E23OI], bl[L_E13OI]);

        `ACCP(L_E13OI, al[L_SCALAR], bl[L_E13OI]);
        `ACCP(L_E13OI, al[L_E12], bl[L_E23OI]);
        `ACCP(L_E13OI, al[L_E13], bl[L_EOI]);
        `ACCN(L_E13OI, al[L_E23], bl[L_E12OI]);
        `ACCN(L_E13OI, al[L_E1O], bl[L_E3I]);
        `ACCP(L_E13OI, al[L_E2O], bl[L_E123I]);
        `ACCP(L_E13OI, al[L_E3O], bl[L_E1I]);
        `ACCP(L_E13OI, al[L_E123O], bl[L_E2I]);
        `ACCP(L_E13OI, al[L_E1I], bl[L_E3O]);
        `ACCN(L_E13OI, al[L_E2I], bl[L_E123O]);
        `ACCN(L_E13OI, al[L_E3I], bl[L_E1O]);
        `ACCN(L_E13OI, al[L_E123I], bl[L_E2O]);
        `ACCP(L_E13OI, al[L_EOI], bl[L_E13]);
        `ACCN(L_E13OI, al[L_EOI], bl[L_E13OI]);
        `ACCP(L_E13OI, al[L_E12OI], bl[L_E23]);
        `ACCN(L_E13OI, al[L_E12OI], bl[L_E23OI]);
        `ACCP(L_E13OI, al[L_E13OI], bl[L_SCALAR]);
        `ACCN(L_E13OI, al[L_E13OI], bl[L_EOI]);
        `ACCN(L_E13OI, al[L_E23OI], bl[L_E12]);
        `ACCP(L_E13OI, al[L_E23OI], bl[L_E12OI]);

        `ACCP(L_E23OI, al[L_SCALAR], bl[L_E23OI]);
        `ACCN(L_E23OI, al[L_E12], bl[L_E13OI]);
        `ACCP(L_E23OI, al[L_E13], bl[L_E12OI]);
        `ACCP(L_E23OI, al[L_E23], bl[L_EOI]);
        `ACCN(L_E23OI, al[L_E1O], bl[L_E123I]);
        `ACCN(L_E23OI, al[L_E2O], bl[L_E3I]);
        `ACCP(L_E23OI, al[L_E3O], bl[L_E2I]);
        `ACCN(L_E23OI, al[L_E123O], bl[L_E1I]);
        `ACCP(L_E23OI, al[L_E1I], bl[L_E123O]);
        `ACCP(L_E23OI, al[L_E2I], bl[L_E3O]);
        `ACCN(L_E23OI, al[L_E3I], bl[L_E2O]);
        `ACCP(L_E23OI, al[L_E123I], bl[L_E1O]);
        `ACCP(L_E23OI, al[L_EOI], bl[L_E23]);
        `ACCN(L_E23OI, al[L_EOI], bl[L_E23OI]);
        `ACCN(L_E23OI, al[L_E12OI], bl[L_E13]);
        `ACCP(L_E23OI, al[L_E12OI], bl[L_E13OI]);
        `ACCP(L_E23OI, al[L_E13OI], bl[L_E12]);
        `ACCN(L_E23OI, al[L_E13OI], bl[L_E12OI]);
        `ACCP(L_E23OI, al[L_E23OI], bl[L_SCALAR]);
        `ACCN(L_E23OI, al[L_E23OI], bl[L_EOI]);

        `undef ACCP
        `undef ACCN

        for (int i=0;i<EVEN_LANES;i++) out_lane[i] = sat16_q511(acc[i]);
        return unpack_even(out_lane);

    endfunction

    function automatic ga_multivector_t wedgeProduct_even(
        ga_multivector_t a,
        ga_multivector_t b
    );

        longint signed acc[EVEN_LANES];
        logic signed [FP_W-1:0] al[EVEN_LANES], bl[EVEN_LANES];
        logic signed [FP_W-1:0] out_lane[EVEN_LANES];
        
        for (int i=0;i<EVEN_LANES;i++) acc[i] = 0;
        
        pack_even(a, al);
        pack_even(b, bl);
        
        `define ACCP(idx, xa, xb) acc[idx] += longint'($signed(xa)) * longint'($signed(xb))
        `define ACCN(idx, xa, xb) acc[idx] -= longint'($signed(xa)) * longint'($signed(xb))
        
        `ACCP(L_SCALAR, al[L_SCALAR], bl[L_SCALAR]);

        `ACCP(L_E12, al[L_SCALAR], bl[L_E12]);
        `ACCP(L_E12, al[L_E12], bl[L_SCALAR]);

        `ACCP(L_E13, al[L_SCALAR], bl[L_E13]);
        `ACCP(L_E13, al[L_E13], bl[L_SCALAR]);

        `ACCP(L_E23, al[L_SCALAR], bl[L_E23]);
        `ACCP(L_E23, al[L_E23], bl[L_SCALAR]);

        `ACCP(L_E1O, al[L_SCALAR], bl[L_E1O]);
        `ACCP(L_E1O, al[L_E1O], bl[L_SCALAR]);

        `ACCP(L_E2O, al[L_SCALAR], bl[L_E2O]);
        `ACCP(L_E2O, al[L_E2O], bl[L_SCALAR]);

        `ACCP(L_E3O, al[L_SCALAR], bl[L_E3O]);
        `ACCP(L_E3O, al[L_E3O], bl[L_SCALAR]);

        `ACCP(L_E1I, al[L_SCALAR], bl[L_E1I]);
        `ACCP(L_E1I, al[L_E1I], bl[L_SCALAR]);

        `ACCP(L_E2I, al[L_SCALAR], bl[L_E2I]);
        `ACCP(L_E2I, al[L_E2I], bl[L_SCALAR]);

        `ACCP(L_E3I, al[L_SCALAR], bl[L_E3I]);
        `ACCP(L_E3I, al[L_E3I], bl[L_SCALAR]);

        `ACCP(L_EOI, al[L_SCALAR], bl[L_EOI]);
        `ACCP(L_EOI, al[L_EOI], bl[L_SCALAR]);

        `ACCP(L_E123O, al[L_SCALAR], bl[L_E123O]);
        `ACCP(L_E123O, al[L_E12], bl[L_E3O]);
        `ACCN(L_E123O, al[L_E13], bl[L_E2O]);
        `ACCP(L_E123O, al[L_E23], bl[L_E1O]);
        `ACCP(L_E123O, al[L_E1O], bl[L_E23]);
        `ACCN(L_E123O, al[L_E2O], bl[L_E13]);
        `ACCP(L_E123O, al[L_E3O], bl[L_E12]);
        `ACCP(L_E123O, al[L_E123O], bl[L_SCALAR]);

        `ACCP(L_E123I, al[L_SCALAR], bl[L_E123I]);
        `ACCP(L_E123I, al[L_E12], bl[L_E3I]);
        `ACCN(L_E123I, al[L_E13], bl[L_E2I]);
        `ACCP(L_E123I, al[L_E23], bl[L_E1I]);
        `ACCP(L_E123I, al[L_E1I], bl[L_E23]);
        `ACCN(L_E123I, al[L_E2I], bl[L_E13]);
        `ACCP(L_E123I, al[L_E3I], bl[L_E12]);
        `ACCP(L_E123I, al[L_E123I], bl[L_SCALAR]);

        `ACCP(L_E12OI, al[L_SCALAR], bl[L_E12OI]);
        `ACCP(L_E12OI, al[L_E12], bl[L_EOI]);
        `ACCN(L_E12OI, al[L_E1O], bl[L_E2I]);
        `ACCP(L_E12OI, al[L_E2O], bl[L_E1I]);
        `ACCP(L_E12OI, al[L_E1I], bl[L_E2O]);
        `ACCN(L_E12OI, al[L_E2I], bl[L_E1O]);
        `ACCP(L_E12OI, al[L_EOI], bl[L_E12]);
        `ACCP(L_E12OI, al[L_E12OI], bl[L_SCALAR]);

        `ACCP(L_E13OI, al[L_SCALAR], bl[L_E13OI]);
        `ACCP(L_E13OI, al[L_E13], bl[L_EOI]);
        `ACCN(L_E13OI, al[L_E1O], bl[L_E3I]);
        `ACCP(L_E13OI, al[L_E3O], bl[L_E1I]);
        `ACCP(L_E13OI, al[L_E1I], bl[L_E3O]);
        `ACCN(L_E13OI, al[L_E3I], bl[L_E1O]);
        `ACCP(L_E13OI, al[L_EOI], bl[L_E13]);
        `ACCP(L_E13OI, al[L_E13OI], bl[L_SCALAR]);

        `ACCP(L_E23OI, al[L_SCALAR], bl[L_E23OI]);
        `ACCP(L_E23OI, al[L_E23], bl[L_EOI]);
        `ACCN(L_E23OI, al[L_E2O], bl[L_E3I]);
        `ACCP(L_E23OI, al[L_E3O], bl[L_E2I]);
        `ACCP(L_E23OI, al[L_E2I], bl[L_E3O]);
        `ACCN(L_E23OI, al[L_E3I], bl[L_E2O]);
        `ACCP(L_E23OI, al[L_EOI], bl[L_E23]);
        `ACCP(L_E23OI, al[L_E23OI], bl[L_SCALAR]);

        `undef ACCP
        `undef ACCN

        for (int i=0;i<EVEN_LANES;i++) out_lane[i] = sat16_q511(acc[i]);
        return unpack_even(out_lane);

    endfunction

    function automatic ga_multivector_t dotProduct_even(
        ga_multivector_t a,
        ga_multivector_t b
    );
        longint signed acc[EVEN_LANES];
        logic signed [FP_W-1:0] al[EVEN_LANES], bl[EVEN_LANES];
        logic signed [FP_W-1:0] out_lane[EVEN_LANES];
        
        for (int i=0;i<EVEN_LANES;i++) acc[i] = 0;
        
        pack_even(a, al);
        pack_even(b, bl);
        
        `define ACCP(idx, xa, xb) acc[idx] += longint'($signed(xa)) * longint'($signed(xb))
        `define ACCN(idx, xa, xb) acc[idx] -= longint'($signed(xa)) * longint'($signed(xb))
        
        `ACCP(L_SCALAR, al[L_SCALAR], bl[L_SCALAR]);
        `ACCN(L_SCALAR, al[L_E12], bl[L_E12]);
        `ACCN(L_SCALAR, al[L_E13], bl[L_E13]);
        `ACCN(L_SCALAR, al[L_E23], bl[L_E23]);
        `ACCP(L_SCALAR, al[L_E1O], bl[L_E1I]);
        `ACCP(L_SCALAR, al[L_E2O], bl[L_E2I]);
        `ACCP(L_SCALAR, al[L_E3O], bl[L_E3I]);
        `ACCN(L_SCALAR, al[L_E123O], bl[L_E123I]);
        `ACCP(L_SCALAR, al[L_E1I], bl[L_E1O]);
        `ACCP(L_SCALAR, al[L_E2I], bl[L_E2O]);
        `ACCP(L_SCALAR, al[L_E3I], bl[L_E3O]);
        `ACCN(L_SCALAR, al[L_E123I], bl[L_E123O]);
        `ACCP(L_SCALAR, al[L_EOI], bl[L_EOI]);
        `ACCN(L_SCALAR, al[L_E12OI], bl[L_E12OI]);
        `ACCN(L_SCALAR, al[L_E13OI], bl[L_E13OI]);
        `ACCN(L_SCALAR, al[L_E23OI], bl[L_E23OI]);
        `ACCP(L_E12, al[L_SCALAR], bl[L_E12]);
        `ACCP(L_E12, al[L_E12], bl[L_SCALAR]);
        `ACCP(L_E12, al[L_E3O], bl[L_E123I]);
        `ACCP(L_E12, al[L_E123O], bl[L_E3I]);
        `ACCP(L_E12, al[L_E3I], bl[L_E123O]);
        `ACCP(L_E12, al[L_E123I], bl[L_E3O]);
        `ACCP(L_E12, al[L_EOI], bl[L_E12OI]);
        `ACCP(L_E12, al[L_E12OI], bl[L_EOI]);
        `ACCP(L_E13, al[L_SCALAR], bl[L_E13]);
        `ACCP(L_E13, al[L_E13], bl[L_SCALAR]);
        `ACCN(L_E13, al[L_E2O], bl[L_E123I]);
        `ACCN(L_E13, al[L_E123O], bl[L_E2I]);
        `ACCN(L_E13, al[L_E2I], bl[L_E123O]);
        `ACCN(L_E13, al[L_E123I], bl[L_E2O]);
        `ACCP(L_E13, al[L_EOI], bl[L_E13OI]);
        `ACCP(L_E13, al[L_E13OI], bl[L_EOI]);
        `ACCP(L_E23, al[L_SCALAR], bl[L_E23]);
        `ACCP(L_E23, al[L_E23], bl[L_SCALAR]);
        `ACCP(L_E23, al[L_E1O], bl[L_E123I]);
        `ACCP(L_E23, al[L_E123O], bl[L_E1I]);
        `ACCP(L_E23, al[L_E1I], bl[L_E123O]);
        `ACCP(L_E23, al[L_E123I], bl[L_E1O]);
        `ACCP(L_E23, al[L_EOI], bl[L_E23OI]);
        `ACCP(L_E23, al[L_E23OI], bl[L_EOI]);
        `ACCP(L_E1O, al[L_SCALAR], bl[L_E1O]);
        `ACCN(L_E1O, al[L_E23], bl[L_E123O]);
        `ACCP(L_E1O, al[L_E1O], bl[L_SCALAR]);
        `ACCN(L_E1O, al[L_E2O], bl[L_E12OI]);
        `ACCN(L_E1O, al[L_E3O], bl[L_E13OI]);
        `ACCN(L_E1O, al[L_E123O], bl[L_E23]);
        `ACCN(L_E1O, al[L_E12OI], bl[L_E2O]);
        `ACCN(L_E1O, al[L_E13OI], bl[L_E3O]);
        `ACCP(L_E2O, al[L_SCALAR], bl[L_E2O]);
        `ACCP(L_E2O, al[L_E13], bl[L_E123O]);
        `ACCP(L_E2O, al[L_E1O], bl[L_E12OI]);
        `ACCP(L_E2O, al[L_E2O], bl[L_SCALAR]);
        `ACCN(L_E2O, al[L_E3O], bl[L_E23OI]);
        `ACCP(L_E2O, al[L_E123O], bl[L_E13]);
        `ACCP(L_E2O, al[L_E12OI], bl[L_E1O]);
        `ACCN(L_E2O, al[L_E23OI], bl[L_E3O]);
        `ACCP(L_E3O, al[L_SCALAR], bl[L_E3O]);
        `ACCN(L_E3O, al[L_E12], bl[L_E123O]);
        `ACCP(L_E3O, al[L_E1O], bl[L_E13OI]);
        `ACCP(L_E3O, al[L_E2O], bl[L_E23OI]);
        `ACCP(L_E3O, al[L_E3O], bl[L_SCALAR]);
        `ACCN(L_E3O, al[L_E123O], bl[L_E12]);
        `ACCP(L_E3O, al[L_E13OI], bl[L_E1O]);
        `ACCP(L_E3O, al[L_E23OI], bl[L_E2O]);
        `ACCP(L_E1I, al[L_SCALAR], bl[L_E1I]);
        `ACCN(L_E1I, al[L_E23], bl[L_E123I]);
        `ACCP(L_E1I, al[L_E1I], bl[L_SCALAR]);
        `ACCP(L_E1I, al[L_E2I], bl[L_E12OI]);
        `ACCP(L_E1I, al[L_E3I], bl[L_E13OI]);
        `ACCN(L_E1I, al[L_E123I], bl[L_E23]);
        `ACCP(L_E2I, al[L_SCALAR], bl[L_E2I]);
        `ACCP(L_E2I, al[L_E13], bl[L_E123I]);
        `ACCN(L_E2I, al[L_E1I], bl[L_E12OI]);
        `ACCP(L_E2I, al[L_E2I], bl[L_SCALAR]);
        `ACCP(L_E2I, al[L_E3I], bl[L_E23OI]);
        `ACCP(L_E2I, al[L_E123I], bl[L_E13]);
        `ACCP(L_E3I, al[L_SCALAR], bl[L_E3I]);
        `ACCN(L_E3I, al[L_E12], bl[L_E123I]);
        `ACCN(L_E3I, al[L_E1I], bl[L_E13OI]);
        `ACCN(L_E3I, al[L_E2I], bl[L_E23OI]);
        `ACCP(L_E3I, al[L_E3I], bl[L_SCALAR]);
        `ACCN(L_E3I, al[L_E123I], bl[L_E12]);
        `ACCP(L_EOI, al[L_SCALAR], bl[L_EOI]);
        `ACCN(L_EOI, al[L_E12], bl[L_E12OI]);
        `ACCN(L_EOI, al[L_E13], bl[L_E13OI]);
        `ACCN(L_EOI, al[L_E23], bl[L_E23OI]);
        `ACCP(L_EOI, al[L_EOI], bl[L_SCALAR]);
        `ACCN(L_EOI, al[L_E12OI], bl[L_E12]);
        `ACCN(L_EOI, al[L_E13OI], bl[L_E13]);
        `ACCN(L_EOI, al[L_E23OI], bl[L_E23]);
        `ACCP(L_E123O, al[L_SCALAR], bl[L_E123O]);
        `ACCP(L_E123O, al[L_E123O], bl[L_SCALAR]);
        `ACCP(L_E123I, al[L_SCALAR], bl[L_E123I]);
        `ACCP(L_E123I, al[L_E123I], bl[L_SCALAR]);
        `ACCP(L_E12OI, al[L_SCALAR], bl[L_E12OI]);
        `ACCP(L_E12OI, al[L_E12OI], bl[L_SCALAR]);
        `ACCP(L_E13OI, al[L_SCALAR], bl[L_E13OI]);
        `ACCP(L_E13OI, al[L_E13OI], bl[L_SCALAR]);
        `ACCP(L_E23OI, al[L_SCALAR], bl[L_E23OI]);
        `ACCP(L_E23OI, al[L_E23OI], bl[L_SCALAR]);

        `undef ACCP
        `undef ACCN
        
        for (int i=0;i<EVEN_LANES;i++) out_lane[i] = sat16_q511(acc[i]);
        return unpack_even(out_lane);

    endfunction

    function automatic ga_multivector_t geometricProduct(
        ga_multivector_t a, ga_multivector_t b
    );

        return geometricProduct_even(a, b);

    endfunction

    function automatic ga_multivector_t wedgeProduct(
        ga_multivector_t a, ga_multivector_t b
    );
        return wedgeProduct_even(a, b);

    endfunction

    function automatic ga_multivector_t dotProduct(
        ga_multivector_t a, ga_multivector_t b
    );
        return dotProduct_even(a, b);

    endfunction

    function automatic ga_multivector_t dualOperation(
        ga_multivector_t a
    );
        ga_multivector_t result = '0;
        return result;

    endfunction

    function automatic ga_multivector_t reverseOperation(
        ga_multivector_t a
    );
        ga_multivector_t result;
        
        result.scalar = a.scalar;
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
        result.e123o  = a.e123o;
        result.e123i  = a.e123i;
        result.e12oi  = a.e12oi;
        result.e13oi  = a.e13oi;
        result.e23oi  = a.e23oi;
        
        return result;

    endfunction

    function automatic logic signed [FP_W-1:0] normCalculation(
        ga_multivector_t a
    );
        longint signed acc_scalar = 0;
        logic signed [FP_W-1:0] al[EVEN_LANES];
        pack_even(a, al);

        for (int i = 0;i < EVEN_LANES; i++) begin
            acc_scalar += longint'($signed(al[i])) * longint'($signed(al[i]));
        end
        
        return sat16_q511(acc_scalar);

    endfunction

    function automatic ga_multivector_t rotorApplication(
        ga_multivector_t rotor,
        ga_multivector_t vector
    );
        ga_multivector_t revRotor   = reverseOperation(rotor);
        ga_multivector_t temp       = geometricProduct(rotor, vector);

        return geometricProduct(temp, revRotor);

    endfunction

    function automatic ga_multivector_t reflectionOperation(
        ga_multivector_t vector,
        ga_multivector_t normal
    );

        return vector;

    endfunction

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
            result.e123o        = a.e123o + b.e123o;
            result.e123i        = a.e123i + b.e123i;
            result.e12oi        = a.e12oi + b.e12oi;
            result.e13oi        = a.e13oi + b.e13oi;
            result.e23oi        = a.e23oi + b.e23oi;

            //$display("ga_alu add: a=%128h, b=%128h, res=%128h", a, b, result);

        end

        GA_FUNCT_SUB: begin

            result.scalar      = a.scalar - b.scalar;
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
            result.e123o       = a.e123o - b.e123o;
            result.e123i       = a.e123i - b.e123i;
            result.e12oi       = a.e12oi - b.e12oi;
            result.e13oi       = a.e13oi - b.e13oi;
            result.e23oi       = a.e23oi - b.e23oi;

            //$display("ga_alu sub: a=%128h, b=%128h, res=%128h", a, b, result);

        end

        GA_FUNCT_MUL: begin
            result = geometricProduct_even(a, b);
        end

        GA_FUNCT_WEDGE: begin
            result = wedgeProduct_even(a, b);
        end

        GA_FUNCT_DOT: begin
            result = dotProduct_even(a, b);
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

    assign result_o = result_q;
    assign error_o  = error_q;

endmodule
