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

    typedef enum logic [2:0]
    {
        ALU_IDLE,
        ALU_COMPUTE,
        ALU_GP_S0,
        ALU_GP_S1,
        ALU_DONE
    } alu_state_e;

    localparam int EVEN_LANES = 16;

    typedef enum int unsigned 
    {
        L_SCALAR = 0,
        L_E12 = 1,
        L_E13 = 2,
        L_E23 = 3,
        L_E14 = 4,
        L_E24 = 5,
        L_E34 = 6,
        L_E15 = 7,
        L_E25 = 8,
        L_E35 = 9,
        L_E45 = 10,
        L_E1234 = 11,
        L_E1235 = 12,
        L_E1245 = 13,
        L_E1345 = 14,
        L_E2345 = 15
    } even_lane_e;

    alu_state_e alu_state_q, alu_state_d;
    ga_multivector_t result_d, result_q;
    logic error_d, error_q;

    ga_multivector_t a_d, a_q;
    ga_multivector_t b_d, b_q;
    ga_funct_e       op_d, op_q;

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

        logic signed [(2*FP_W)-1:0] p = a * b;
        logic signed [(2*FP_W)-1:0] r = p + (1 <<< (FP_FRAC-1));
        logic signed [(2*FP_W)-1:0] s = r >>> FP_FRAC;
        logic signed [FP_W:0]       t = {s[FP_W-1], s[FP_W-1:0]};
        return satN(t);

    endfunction

    function automatic logic signed [FP_W-1:0] mac(input logic signed [FP_W-1:0] acc,
                                                    input logic signed [FP_W-1:0] x,
                                                    input logic signed [FP_W-1:0] y);
        return addQ511(acc, mulQ511(x, y));

    endfunction

    function automatic logic signed [FP_W-1:0] macSub(input logic signed [FP_W-1:0] acc,
                                                        input logic signed [FP_W-1:0] x,
                                                        input logic signed [FP_W-1:0] y);
        return subQ511(acc, mulQ511(x, y));

    endfunction

    function automatic logic signed [FP_W-1:0] negQ511(input logic signed [FP_W-1:0] x);

        logic signed [FP_W-1:0] z = '0;
        return subQ511(z, x);

    endfunction

    function automatic logic signed [FP_W-1:0] asQ(input logic [FP_W-1:0] x);
    
        return x;

    endfunction

    function automatic logic signed [FP_W-1:0] sat16_q511(int signed acc_raw);
        int signed r = acc_raw + (1 <<< (FP_FRAC-1));
        int signed s = r >>> FP_FRAC;
        int signed maxv =  (1 <<< (FP_W-1)) - 1;
        int signed minv = -(1 <<< (FP_W-1));
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
        lane[L_E14] = mv.e14;
        lane[L_E24] = mv.e24;
        lane[L_E34] = mv.e34;
        lane[L_E15] = mv.e15;
        lane[L_E25] = mv.e25;
        lane[L_E35] = mv.e35;
        lane[L_E45] = mv.e45;
        lane[L_E1234] = mv.e1234;
        lane[L_E1235] = mv.e1235;
        lane[L_E1245] = mv.e1245;
        lane[L_E1345] = mv.e1345;
        lane[L_E2345] = mv.e2345;

    endfunction

    function automatic ga_multivector_t unpack_even(input logic signed [FP_W-1:0] lane[EVEN_LANES]);

        ga_multivector_t mv = '0;
        mv.scalar = lane[L_SCALAR];
        mv.e12 = lane[L_E12];
        mv.e13 = lane[L_E13];
        mv.e23 = lane[L_E23];
        mv.e14 = lane[L_E14];
        mv.e24 = lane[L_E24];
        mv.e34 = lane[L_E34];
        mv.e15 = lane[L_E15];
        mv.e25 = lane[L_E25];
        mv.e35 = lane[L_E35];
        mv.e45 = lane[L_E45];
        mv.e1234 = lane[L_E1234];
        mv.e1235 = lane[L_E1235];
        mv.e1245 = lane[L_E1245];
        mv.e1345 = lane[L_E1345];
        mv.e2345 = lane[L_E2345];
        return mv;

    endfunction

    int signed gp_partial0_q[EVEN_LANES];
    int signed gp_partial0_d[EVEN_LANES];
    logic signed [FP_W-1:0] al_q_arr[EVEN_LANES], bl_q_arr[EVEN_LANES];
    logic signed [FP_W-1:0] al_d_arr[EVEN_LANES], bl_d_arr[EVEN_LANES];

    always_ff @(posedge clk_i or negedge rst_ni) begin

        if (!rst_ni) begin

            alu_state_q <= ALU_IDLE;
            result_q    <= '0;
            error_q     <= 1'b0;
            a_q         <= '0;
            b_q         <= '0;
            op_q        <= ga_funct_e'('0);

            for (int i=0;i<EVEN_LANES;i++) begin
                gp_partial0_q[i] <= 0;
                al_q_arr[i] <= '0;
                bl_q_arr[i] <= '0;
            end

        end else begin

            alu_state_q <= alu_state_d;
            result_q    <= result_d;
            error_q     <= error_d;
            a_q         <= a_d;
            b_q         <= b_d;
            op_q        <= op_d;

            for (int i=0;i<EVEN_LANES;i++) begin
                gp_partial0_q[i] <= gp_partial0_d[i];
                al_q_arr[i] <= al_d_arr[i];
                bl_q_arr[i] <= bl_d_arr[i];
            end

        end
    end

    always_comb begin

        int signed temp_partial[EVEN_LANES]                 = '{default:0};
        int signed acc[EVEN_LANES]                          = '{default:0};
        logic signed [(2*FP_W)-1:0] _t                      = '0;
        logic signed [FP_W-1:0] out_lane_loc[EVEN_LANES]    = '{default:'0};

         alu_state_d = alu_state_q;
         result_d    = result_q;
         error_d     = error_q;
         ready_o     = 1'b0;
         valid_o     = 1'b0;
         a_d         = a_q;
         b_d         = b_q;
         op_d        = op_q;

        for (int i=0;i<EVEN_LANES;i++) begin
            gp_partial0_d[i] = gp_partial0_q[i];
            al_d_arr[i] = al_q_arr[i];
            bl_d_arr[i] = bl_q_arr[i];
        end

        case (alu_state_q)

        ALU_IDLE: begin

            ready_o = 1'b1;
            if (valid_i) begin
                alu_state_d = ALU_COMPUTE;
                error_d     = 1'b0;
                a_d         = operand_a_i;
                b_d         = operand_b_i;
                op_d        = operation_i;
            end
        end

        ALU_COMPUTE: begin

            if (op_q == GA_FUNCT_MUL) begin

                alu_state_d = ALU_GP_S0;

            end else begin

                result_d = computeGaOperation(a_q, b_q, op_q);
                alu_state_d = ALU_DONE;
                
            end
        end

        ALU_GP_S0: begin

            pack_even(a_q, al_d_arr);
            pack_even(b_q, bl_d_arr);
 
            for (int i=0;i<EVEN_LANES;i++) temp_partial[i] = 0;
 
             begin
                
                _t = $signed(al_d_arr[L_SCALAR]) * $signed(bl_d_arr[L_SCALAR]); temp_partial[L_SCALAR] += int'(_t);
                _t = $signed(al_d_arr[L_E12])    * $signed(bl_d_arr[L_E12]);    temp_partial[L_SCALAR] -= int'(_t);
                _t = $signed(al_d_arr[L_E13])    * $signed(bl_d_arr[L_E13]);    temp_partial[L_SCALAR] -= int'(_t);
                _t = $signed(al_d_arr[L_E23])    * $signed(bl_d_arr[L_E23]);    temp_partial[L_SCALAR] -= int'(_t);
                _t = $signed(al_d_arr[L_E14])    * $signed(bl_d_arr[L_E14]);    temp_partial[L_SCALAR] -= int'(_t);
                _t = $signed(al_d_arr[L_E24])    * $signed(bl_d_arr[L_E24]);    temp_partial[L_SCALAR] -= int'(_t);
                _t = $signed(al_d_arr[L_E34])    * $signed(bl_d_arr[L_E34]);    temp_partial[L_SCALAR] -= int'(_t);
                _t = $signed(al_d_arr[L_E15])    * $signed(bl_d_arr[L_E15]);    temp_partial[L_SCALAR] += int'(_t);
             end
 
             begin

                _t = $signed(al_d_arr[L_SCALAR]) * $signed(bl_d_arr[L_E12]); temp_partial[L_E12] += int'(_t);
                _t = $signed(al_d_arr[L_E12])    * $signed(bl_d_arr[L_SCALAR]); temp_partial[L_E12] += int'(_t);
                _t = $signed(al_d_arr[L_E13])    * $signed(bl_d_arr[L_E23]); temp_partial[L_E12] -= int'(_t);
                _t = $signed(al_d_arr[L_E23])    * $signed(bl_d_arr[L_E13]); temp_partial[L_E12] += int'(_t);
                _t = $signed(al_d_arr[L_E14])    * $signed(bl_d_arr[L_E24]); temp_partial[L_E12] -= int'(_t);
                _t = $signed(al_d_arr[L_E24])    * $signed(bl_d_arr[L_E14]); temp_partial[L_E12] += int'(_t);
                _t = $signed(al_d_arr[L_E34])    * $signed(bl_d_arr[L_E1234]); temp_partial[L_E12] -= int'(_t);
                _t = $signed(al_d_arr[L_E15])    * $signed(bl_d_arr[L_E25]); temp_partial[L_E12] += int'(_t);
             end

             begin

                _t = $signed(al_d_arr[L_SCALAR]) * $signed(bl_d_arr[L_E13]); temp_partial[L_E13] += int'(_t);
                _t = $signed(al_d_arr[L_E12])    * $signed(bl_d_arr[L_E23]); temp_partial[L_E13] += int'(_t);
                _t = $signed(al_d_arr[L_E13])    * $signed(bl_d_arr[L_SCALAR]); temp_partial[L_E13] += int'(_t);
                _t = $signed(al_d_arr[L_E23])    * $signed(bl_d_arr[L_E12]); temp_partial[L_E13] -= int'(_t);
                _t = $signed(al_d_arr[L_E14])    * $signed(bl_d_arr[L_E34]); temp_partial[L_E13] -= int'(_t);
                _t = $signed(al_d_arr[L_E24])    * $signed(bl_d_arr[L_E1234]); temp_partial[L_E13] += int'(_t);
                _t = $signed(al_d_arr[L_E34])    * $signed(bl_d_arr[L_E14]); temp_partial[L_E13] += int'(_t);
                _t = $signed(al_d_arr[L_E15])    * $signed(bl_d_arr[L_E35]); temp_partial[L_E13] += int'(_t);
             end
             
             begin

                _t = $signed(al_d_arr[L_SCALAR]) * $signed(bl_d_arr[L_E23]); temp_partial[L_E23] += int'(_t);
                _t = $signed(al_d_arr[L_E12])    * $signed(bl_d_arr[L_E13]); temp_partial[L_E23] -= int'(_t);
                _t = $signed(al_d_arr[L_E13])    * $signed(bl_d_arr[L_E12]); temp_partial[L_E23] += int'(_t);
                _t = $signed(al_d_arr[L_E23])    * $signed(bl_d_arr[L_SCALAR]); temp_partial[L_E23] += int'(_t);
                _t = $signed(al_d_arr[L_E14])    * $signed(bl_d_arr[L_E1234]); temp_partial[L_E23] -= int'(_t);
                _t = $signed(al_d_arr[L_E24])    * $signed(bl_d_arr[L_E34]); temp_partial[L_E23] -= int'(_t);
                _t = $signed(al_d_arr[L_E34])    * $signed(bl_d_arr[L_E24]); temp_partial[L_E23] += int'(_t);
                _t = $signed(al_d_arr[L_E15])    * $signed(bl_d_arr[L_E1235]); temp_partial[L_E23] += int'(_t);
             end

             begin

                _t = $signed(al_d_arr[L_SCALAR]) * $signed(bl_d_arr[L_E14]); temp_partial[L_E14] += int'(_t);
                _t = $signed(al_d_arr[L_E12])    * $signed(bl_d_arr[L_E24]); temp_partial[L_E14] += int'(_t);
                _t = $signed(al_d_arr[L_E13])    * $signed(bl_d_arr[L_E34]); temp_partial[L_E14] += int'(_t);
                _t = $signed(al_d_arr[L_E23])    * $signed(bl_d_arr[L_E1234]); temp_partial[L_E14] -= int'(_t);
                _t = $signed(al_d_arr[L_E14])    * $signed(bl_d_arr[L_SCALAR]); temp_partial[L_E14] += int'(_t);
                _t = $signed(al_d_arr[L_E24])    * $signed(bl_d_arr[L_E12]); temp_partial[L_E14] -= int'(_t);
                _t = $signed(al_d_arr[L_E34])    * $signed(bl_d_arr[L_E13]); temp_partial[L_E14] -= int'(_t);
                _t = $signed(al_d_arr[L_E15])    * $signed(bl_d_arr[L_E45]); temp_partial[L_E14] += int'(_t);
             end

             begin

                _t = $signed(al_d_arr[L_SCALAR]) * $signed(bl_d_arr[L_E24]); temp_partial[L_E24] += int'(_t);
                _t = $signed(al_d_arr[L_E12])    * $signed(bl_d_arr[L_E14]); temp_partial[L_E24] -= int'(_t);
                _t = $signed(al_d_arr[L_E13])    * $signed(bl_d_arr[L_E1234]); temp_partial[L_E24] += int'(_t);
                _t = $signed(al_d_arr[L_E23])    * $signed(bl_d_arr[L_E34]); temp_partial[L_E24] += int'(_t);
                _t = $signed(al_d_arr[L_E14])    * $signed(bl_d_arr[L_E12]); temp_partial[L_E24] += int'(_t);
                _t = $signed(al_d_arr[L_E24])    * $signed(bl_d_arr[L_SCALAR]); temp_partial[L_E24] += int'(_t);
                _t = $signed(al_d_arr[L_E34])    * $signed(bl_d_arr[L_E23]); temp_partial[L_E24] -= int'(_t);
                _t = $signed(al_d_arr[L_E15])    * $signed(bl_d_arr[L_E1245]); temp_partial[L_E24] += int'(_t);
             end

             begin

                _t = $signed(al_d_arr[L_SCALAR]) * $signed(bl_d_arr[L_E34]); temp_partial[L_E34] += int'(_t);
                _t = $signed(al_d_arr[L_E12])    * $signed(bl_d_arr[L_E1234]); temp_partial[L_E34] -= int'(_t);
                _t = $signed(al_d_arr[L_E13])    * $signed(bl_d_arr[L_E14]); temp_partial[L_E34] -= int'(_t);
                _t = $signed(al_d_arr[L_E23])    * $signed(bl_d_arr[L_E24]); temp_partial[L_E34] -= int'(_t);
                _t = $signed(al_d_arr[L_E14])    * $signed(bl_d_arr[L_E13]); temp_partial[L_E34] += int'(_t);
                _t = $signed(al_d_arr[L_E24])    * $signed(bl_d_arr[L_E23]); temp_partial[L_E34] += int'(_t);
                _t = $signed(al_d_arr[L_E34])    * $signed(bl_d_arr[L_SCALAR]); temp_partial[L_E34] += int'(_t);
                _t = $signed(al_d_arr[L_E15])    * $signed(bl_d_arr[L_E1345]); temp_partial[L_E34] += int'(_t);
             end

             begin

                _t = $signed(al_d_arr[L_SCALAR]) * $signed(bl_d_arr[L_E15]); temp_partial[L_E15] += int'(_t);
                _t = $signed(al_d_arr[L_E12])    * $signed(bl_d_arr[L_E25]); temp_partial[L_E15] += int'(_t);
                _t = $signed(al_d_arr[L_E13])    * $signed(bl_d_arr[L_E35]); temp_partial[L_E15] += int'(_t);
                _t = $signed(al_d_arr[L_E23])    * $signed(bl_d_arr[L_E1235]); temp_partial[L_E15] -= int'(_t);
                _t = $signed(al_d_arr[L_E14])    * $signed(bl_d_arr[L_E45]); temp_partial[L_E15] += int'(_t);
                _t = $signed(al_d_arr[L_E24])    * $signed(bl_d_arr[L_E1245]); temp_partial[L_E15] -= int'(_t);
                _t = $signed(al_d_arr[L_E34])    * $signed(bl_d_arr[L_E1345]); temp_partial[L_E15] -= int'(_t);
                _t = $signed(al_d_arr[L_E15])    * $signed(bl_d_arr[L_SCALAR]); temp_partial[L_E15] += int'(_t);
             end

             begin

                _t = $signed(al_d_arr[L_SCALAR]) * $signed(bl_d_arr[L_E25]); temp_partial[L_E25] += int'(_t);
                _t = $signed(al_d_arr[L_E12])    * $signed(bl_d_arr[L_E15]); temp_partial[L_E25] -= int'(_t);
                _t = $signed(al_d_arr[L_E13])    * $signed(bl_d_arr[L_E1235]); temp_partial[L_E25] += int'(_t);
                _t = $signed(al_d_arr[L_E23])    * $signed(bl_d_arr[L_E35]); temp_partial[L_E25] += int'(_t);
                _t = $signed(al_d_arr[L_E14])    * $signed(bl_d_arr[L_E1245]); temp_partial[L_E25] += int'(_t);
                _t = $signed(al_d_arr[L_E24])    * $signed(bl_d_arr[L_E45]); temp_partial[L_E25] += int'(_t);
                _t = $signed(al_d_arr[L_E34])    * $signed(bl_d_arr[L_E2345]); temp_partial[L_E25] -= int'(_t);
                _t = $signed(al_d_arr[L_E15])    * $signed(bl_d_arr[L_E12]); temp_partial[L_E25] += int'(_t);
             end

             begin

                _t = $signed(al_d_arr[L_SCALAR]) * $signed(bl_d_arr[L_E35]); temp_partial[L_E35] += int'(_t);
                _t = $signed(al_d_arr[L_E12])    * $signed(bl_d_arr[L_E1235]); temp_partial[L_E35] -= int'(_t);
                _t = $signed(al_d_arr[L_E13])    * $signed(bl_d_arr[L_E15]); temp_partial[L_E35] -= int'(_t);
                _t = $signed(al_d_arr[L_E23])    * $signed(bl_d_arr[L_E25]); temp_partial[L_E35] -= int'(_t);
                _t = $signed(al_d_arr[L_E14])    * $signed(bl_d_arr[L_E1345]); temp_partial[L_E35] += int'(_t);
                _t = $signed(al_d_arr[L_E24])    * $signed(bl_d_arr[L_E2345]); temp_partial[L_E35] += int'(_t);
                _t = $signed(al_d_arr[L_E34])    * $signed(bl_d_arr[L_E45]); temp_partial[L_E35] += int'(_t);
                _t = $signed(al_d_arr[L_E15])    * $signed(bl_d_arr[L_E13]); temp_partial[L_E35] += int'(_t);
             end
            
             begin

                _t = $signed(al_d_arr[L_SCALAR]) * $signed(bl_d_arr[L_E45]); temp_partial[L_E45] += int'(_t);
                _t = $signed(al_d_arr[L_E12])    * $signed(bl_d_arr[L_E24]); temp_partial[L_E45] += int'(_t);
                _t = $signed(al_d_arr[L_E13])    * $signed(bl_d_arr[L_E34]); temp_partial[L_E45] += int'(_t);
                _t = $signed(al_d_arr[L_E23])    * $signed(bl_d_arr[L_E1234]); temp_partial[L_E45] -= int'(_t);
                _t = $signed(al_d_arr[L_E14])    * $signed(bl_d_arr[L_E15]); temp_partial[L_E45] -= int'(_t);
                _t = $signed(al_d_arr[L_E24])    * $signed(bl_d_arr[L_E25]); temp_partial[L_E45] -= int'(_t);
                _t = $signed(al_d_arr[L_E34])    * $signed(bl_d_arr[L_E35]); temp_partial[L_E45] -= int'(_t);
                _t = $signed(al_d_arr[L_E15])    * $signed(bl_d_arr[L_E14]); temp_partial[L_E45] += int'(_t);
             end

             begin

                _t = $signed(al_d_arr[L_SCALAR]) * $signed(bl_d_arr[L_E1234]); temp_partial[L_E1234] += int'(_t);
                _t = $signed(al_d_arr[L_E12])    * $signed(bl_d_arr[L_E34]); temp_partial[L_E1234] += int'(_t);
                _t = $signed(al_d_arr[L_E13])    * $signed(bl_d_arr[L_E24]); temp_partial[L_E1234] -= int'(_t);
                _t = $signed(al_d_arr[L_E23])    * $signed(bl_d_arr[L_E14]); temp_partial[L_E1234] += int'(_t);
                _t = $signed(al_d_arr[L_E14])    * $signed(bl_d_arr[L_E23]); temp_partial[L_E1234] += int'(_t);
                _t = $signed(al_d_arr[L_E24])    * $signed(bl_d_arr[L_E13]); temp_partial[L_E1234] -= int'(_t);
                _t = $signed(al_d_arr[L_E34])    * $signed(bl_d_arr[L_E12]); temp_partial[L_E1234] += int'(_t);
                _t = $signed(al_d_arr[L_E15])    * $signed(bl_d_arr[L_E2345]); temp_partial[L_E1234] += int'(_t);
             end

             begin

                _t = $signed(al_d_arr[L_SCALAR]) * $signed(bl_d_arr[L_E1235]); temp_partial[L_E1235] += int'(_t);
                _t = $signed(al_d_arr[L_E12])    * $signed(bl_d_arr[L_E35]); temp_partial[L_E1235] += int'(_t);
                _t = $signed(al_d_arr[L_E13])    * $signed(bl_d_arr[L_E25]); temp_partial[L_E1235] -= int'(_t);
                _t = $signed(al_d_arr[L_E23])    * $signed(bl_d_arr[L_E15]); temp_partial[L_E1235] += int'(_t);
                _t = $signed(al_d_arr[L_E14])    * $signed(bl_d_arr[L_E2345]); temp_partial[L_E1235] += int'(_t);
                _t = $signed(al_d_arr[L_E24])    * $signed(bl_d_arr[L_E1345]); temp_partial[L_E1235] -= int'(_t);
                _t = $signed(al_d_arr[L_E34])    * $signed(bl_d_arr[L_E1245]); temp_partial[L_E1235] += int'(_t);
                _t = $signed(al_d_arr[L_E15])    * $signed(bl_d_arr[L_E23]); temp_partial[L_E1235] += int'(_t);
             end

             begin

                _t = $signed(al_d_arr[L_SCALAR]) * $signed(bl_d_arr[L_E1245]); temp_partial[L_E1245] += int'(_t);
                _t = $signed(al_d_arr[L_E12])    * $signed(bl_d_arr[L_E45]); temp_partial[L_E1245] += int'(_t);
                _t = $signed(al_d_arr[L_E13])    * $signed(bl_d_arr[L_E2345]); temp_partial[L_E1245] -= int'(_t);
                _t = $signed(al_d_arr[L_E23])    * $signed(bl_d_arr[L_E1345]); temp_partial[L_E1245] += int'(_t);
                _t = $signed(al_d_arr[L_E14])    * $signed(bl_d_arr[L_E25]); temp_partial[L_E1245] -= int'(_t);
                _t = $signed(al_d_arr[L_E24])    * $signed(bl_d_arr[L_E15]); temp_partial[L_E1245] += int'(_t);
                _t = $signed(al_d_arr[L_E34])    * $signed(bl_d_arr[L_E1235]); temp_partial[L_E1245] -= int'(_t);
                _t = $signed(al_d_arr[L_E15])    * $signed(bl_d_arr[L_E24]); temp_partial[L_E1245] += int'(_t);

             end

             begin

                _t = $signed(al_d_arr[L_SCALAR]) * $signed(bl_d_arr[L_E1345]); temp_partial[L_E1345] += int'(_t);
                _t = $signed(al_d_arr[L_E12])    * $signed(bl_d_arr[L_E2345]); temp_partial[L_E1345] += int'(_t);
                _t = $signed(al_d_arr[L_E13])    * $signed(bl_d_arr[L_E45]); temp_partial[L_E1345] += int'(_t);
                _t = $signed(al_d_arr[L_E23])    * $signed(bl_d_arr[L_E1245]); temp_partial[L_E1345] -= int'(_t);
                _t = $signed(al_d_arr[L_E14])    * $signed(bl_d_arr[L_E35]); temp_partial[L_E1345] -= int'(_t);
                _t = $signed(al_d_arr[L_E24])    * $signed(bl_d_arr[L_E1235]); temp_partial[L_E1345] += int'(_t);
                _t = $signed(al_d_arr[L_E34])    * $signed(bl_d_arr[L_E15]); temp_partial[L_E1345] += int'(_t);
                _t = $signed(al_d_arr[L_E15])    * $signed(bl_d_arr[L_E34]); temp_partial[L_E1345] += int'(_t);

             end

             begin

                _t = $signed(al_d_arr[L_SCALAR]) * $signed(bl_d_arr[L_E2345]); temp_partial[L_E2345] += int'(_t);
                _t = $signed(al_d_arr[L_E23])    * $signed(bl_d_arr[L_E45]); temp_partial[L_E2345] += int'(_t);
                _t = $signed(al_d_arr[L_E24])    * $signed(bl_d_arr[L_E35]); temp_partial[L_E2345] -= int'(_t);
                _t = $signed(al_d_arr[L_E14])    * $signed(bl_d_arr[L_E1235]); temp_partial[L_E2345] += int'(_t);
                _t = $signed(al_d_arr[L_E24])    * $signed(bl_d_arr[L_E1345]); temp_partial[L_E2345] -= int'(_t);
                _t = $signed(al_d_arr[L_E34])    * $signed(bl_d_arr[L_E25]); temp_partial[L_E2345] += int'(_t);
                _t = $signed(al_d_arr[L_E15])    * $signed(bl_d_arr[L_E1234]); temp_partial[L_E2345] += int'(_t);

             end

            for (int i=0;i<EVEN_LANES;i++) gp_partial0_d[i] = temp_partial[i];
            alu_state_d = ALU_GP_S1;
        end

        ALU_GP_S1: begin

            for (int i=0;i<EVEN_LANES;i++) acc[i] = gp_partial0_q[i];
 
            _t = $signed(al_q_arr[L_E25])    * $signed(bl_q_arr[L_E25]);    acc[L_SCALAR] += int'(_t);
            _t = $signed(al_q_arr[L_E35])    * $signed(bl_q_arr[L_E35]);    acc[L_SCALAR] += int'(_t);
            _t = $signed(al_q_arr[L_E45])    * $signed(bl_q_arr[L_E45]);    acc[L_SCALAR] += int'(_t);
            _t = $signed(al_q_arr[L_E1234])  * $signed(bl_q_arr[L_E1234]);  acc[L_SCALAR] += int'(_t);
            _t = $signed(al_q_arr[L_E1235])  * $signed(bl_q_arr[L_E1235]);  acc[L_SCALAR] -= int'(_t);
            _t = $signed(al_q_arr[L_E1245])  * $signed(bl_q_arr[L_E1245]);  acc[L_SCALAR] -= int'(_t);
            _t = $signed(al_q_arr[L_E1345])  * $signed(bl_q_arr[L_E1345]);  acc[L_SCALAR] -= int'(_t);
            _t = $signed(al_q_arr[L_E2345])  * $signed(bl_q_arr[L_E2345]);  acc[L_SCALAR] -= int'(_t);
            _t = $signed(al_q_arr[L_E25])    * $signed(bl_q_arr[L_E15]);    acc[L_E12] -= int'(_t);
            _t = $signed(al_q_arr[L_E35])    * $signed(bl_q_arr[L_E1235]);  acc[L_E12] += int'(_t);
            _t = $signed(al_q_arr[L_E45])    * $signed(bl_q_arr[L_E1245]);  acc[L_E12] += int'(_t);
            _t = $signed(al_q_arr[L_E1234])  * $signed(bl_q_arr[L_E34]);    acc[L_E12] -= int'(_t);
            _t = $signed(al_q_arr[L_E1235])  * $signed(bl_q_arr[L_E35]);    acc[L_E12] += int'(_t);
            _t = $signed(al_q_arr[L_E1245])  * $signed(bl_q_arr[L_E45]);    acc[L_E12] += int'(_t);
            _t = $signed(al_q_arr[L_E1345])  * $signed(bl_q_arr[L_E2345]);  acc[L_E12] -= int'(_t);
            _t = $signed(al_q_arr[L_E2345])  * $signed(bl_q_arr[L_E1345]);  acc[L_E12] += int'(_t);
            _t = $signed(al_q_arr[L_E25])    * $signed(bl_q_arr[L_E1235]);  acc[L_E13] -= int'(_t);
            _t = $signed(al_q_arr[L_E35])    * $signed(bl_q_arr[L_E15]);    acc[L_E13] -= int'(_t);
            _t = $signed(al_q_arr[L_E25])    * $signed(bl_q_arr[L_E1235]);  acc[L_E13] -= int'(_t);
            _t = $signed(al_q_arr[L_E25])    * $signed(bl_q_arr[L_E1235]);  acc[L_E13] -= int'(_t);
            _t = $signed(al_q_arr[L_E25])    * $signed(bl_q_arr[L_E1235]);  acc[L_E13] -= int'(_t);
            _t = $signed(al_q_arr[L_E25])    * $signed(bl_q_arr[L_E1235]);  acc[L_E13] -= int'(_t);
            _t = $signed(al_q_arr[L_E25])    * $signed(bl_q_arr[L_E1235]);  acc[L_E13] -= int'(_t);
            _t = $signed(al_q_arr[L_E25])    * $signed(bl_q_arr[L_E1235]);  acc[L_E13] -= int'(_t);
            _t = $signed(al_q_arr[L_E25])    * $signed(bl_q_arr[L_E1235]);  acc[L_E23] += int'(_t);
            _t = $signed(al_q_arr[L_E35])    * $signed(bl_q_arr[L_E25]);    acc[L_E23] -= int'(_t);
            _t = $signed(al_q_arr[L_E45])    * $signed(bl_q_arr[L_E2345]);  acc[L_E23] += int'(_t);
            _t = $signed(al_q_arr[L_E1235])  * $signed(bl_q_arr[L_E15]);    acc[L_E23] += int'(_t);
            _t = $signed(al_q_arr[L_E1245])  * $signed(bl_q_arr[L_E1345]);  acc[L_E23] -= int'(_t);
            _t = $signed(al_q_arr[L_E1345])  * $signed(bl_q_arr[L_E1245]);  acc[L_E23] += int'(_t);
            _t = $signed(al_q_arr[L_E2345])  * $signed(bl_q_arr[L_E45]);    acc[L_E23] += int'(_t);
            _t = $signed(al_q_arr[L_E25])    * $signed(bl_q_arr[L_E45]);    acc[L_E14] -= int'(_t);
            _t = $signed(al_q_arr[L_E35])    * $signed(bl_q_arr[L_E1345]);  acc[L_E14] -= int'(_t);
            _t = $signed(al_q_arr[L_E45])    * $signed(bl_q_arr[L_E15]);    acc[L_E14] -= int'(_t);
            _t = $signed(al_q_arr[L_E1234])  * $signed(bl_q_arr[L_E23]);    acc[L_E14] -= int'(_t);
            _t = $signed(al_q_arr[L_E1235])  * $signed(bl_q_arr[L_E2345]);  acc[L_E14] -= int'(_t);
            _t = $signed(al_q_arr[L_E1245])  * $signed(bl_q_arr[L_E25]);    acc[L_E14] -= int'(_t);
            _t = $signed(al_q_arr[L_E1345])  * $signed(bl_q_arr[L_E35]);    acc[L_E14] -= int'(_t);
            _t = $signed(al_q_arr[L_E2345])  * $signed(bl_q_arr[L_E1235]);  acc[L_E14] += int'(_t);
            _t = $signed(al_q_arr[L_E25])    * $signed(bl_q_arr[L_E45]);    acc[L_E24] += int'(_t);
            _t = $signed(al_q_arr[L_E35])    * $signed(bl_q_arr[L_E2345]);  acc[L_E24] -= int'(_t);
            _t = $signed(al_q_arr[L_E45])    * $signed(bl_q_arr[L_E25]);    acc[L_E24] -= int'(_t);
            _t = $signed(al_q_arr[L_E1234])  * $signed(bl_q_arr[L_E13]);    acc[L_E24] += int'(_t);
            _t = $signed(al_q_arr[L_E1235])  * $signed(bl_q_arr[L_E1345]);  acc[L_E24] += int'(_t);
            _t = $signed(al_q_arr[L_E1245])  * $signed(bl_q_arr[L_E15]);    acc[L_E24] += int'(_t);
            _t = $signed(al_q_arr[L_E1345])  * $signed(bl_q_arr[L_E1235]);  acc[L_E24] -= int'(_t);
            _t = $signed(al_q_arr[L_E2345])  * $signed(bl_q_arr[L_E35]);    acc[L_E24] -= int'(_t);
            _t = $signed(al_q_arr[L_E25])    * $signed(bl_q_arr[L_E2345]);  acc[L_E34] += int'(_t);
            _t = $signed(al_q_arr[L_E35])    * $signed(bl_q_arr[L_E45]);    acc[L_E34] -= int'(_t);
            _t = $signed(al_q_arr[L_E45])    * $signed(bl_q_arr[L_E35]);    acc[L_E34] -= int'(_t);
            _t = $signed(al_q_arr[L_E1234])  * $signed(bl_q_arr[L_E12]);    acc[L_E34] -= int'(_t);
            _t = $signed(al_q_arr[L_E1235])  * $signed(bl_q_arr[L_E1245]);  acc[L_E34] -= int'(_t);
            _t = $signed(al_q_arr[L_E1245])  * $signed(bl_q_arr[L_E1235]);  acc[L_E34] += int'(_t);
            _t = $signed(al_q_arr[L_E1345])  * $signed(bl_q_arr[L_E15]);    acc[L_E34] += int'(_t);
            _t = $signed(al_q_arr[L_E2345])  * $signed(bl_q_arr[L_E25]);    acc[L_E34] += int'(_t);
            _t = $signed(al_q_arr[L_E25])    * $signed(bl_q_arr[L_E12]);    acc[L_E15] += int'(_t);
            _t = $signed(al_q_arr[L_E35])    * $signed(bl_q_arr[L_E13]);    acc[L_E15] -= int'(_t);
            _t = $signed(al_q_arr[L_E45])    * $signed(bl_q_arr[L_E14]);    acc[L_E15] -= int'(_t);
            _t = $signed(al_q_arr[L_E1234])  * $signed(bl_q_arr[L_E2345]);  acc[L_E15] -= int'(_t);
            _t = $signed(al_q_arr[L_E1235])  * $signed(bl_q_arr[L_E23]);    acc[L_E15] -= int'(_t);
            _t = $signed(al_q_arr[L_E1245])  * $signed(bl_q_arr[L_E24]);    acc[L_E15] -= int'(_t);
            _t = $signed(al_q_arr[L_E1345])  * $signed(bl_q_arr[L_E34]);    acc[L_E15] -= int'(_t);
            _t = $signed(al_q_arr[L_E2345])  * $signed(bl_q_arr[L_E1234]);  acc[L_E15] += int'(_t);
            _t = $signed(al_q_arr[L_E25])    * $signed(bl_q_arr[L_E12]);    acc[L_E25] += int'(_t);
            _t = $signed(al_q_arr[L_E35])    * $signed(bl_q_arr[L_E23]);    acc[L_E25] -= int'(_t);
            _t = $signed(al_q_arr[L_E45])    * $signed(bl_q_arr[L_E24]);    acc[L_E25] -= int'(_t);
            _t = $signed(al_q_arr[L_E1234])  * $signed(bl_q_arr[L_E1345]);  acc[L_E25] += int'(_t);
            _t = $signed(al_q_arr[L_E1235])  * $signed(bl_q_arr[L_E13]);    acc[L_E25] += int'(_t);
            _t = $signed(al_q_arr[L_E1245])  * $signed(bl_q_arr[L_E14]);    acc[L_E25] += int'(_t);
            _t = $signed(al_q_arr[L_E1345])  * $signed(bl_q_arr[L_E1234]);  acc[L_E25] -= int'(_t);
            _t = $signed(al_q_arr[L_E2345])  * $signed(bl_q_arr[L_E34]);    acc[L_E25] -= int'(_t);
            _t = $signed(al_q_arr[L_E25])    * $signed(bl_q_arr[L_E23]);    acc[L_E35] += int'(_t);
            _t = $signed(al_q_arr[L_E35])    * $signed(bl_q_arr[L_E15]);    acc[L_E35] -= int'(_t);
            _t = $signed(al_q_arr[L_E45])    * $signed(bl_q_arr[L_E34]);    acc[L_E35] -= int'(_t);
            _t = $signed(al_q_arr[L_E1234])  * $signed(bl_q_arr[L_E1245]);  acc[L_E35] -= int'(_t);
            _t = $signed(al_q_arr[L_E1235])  * $signed(bl_q_arr[L_E12]);    acc[L_E35] -= int'(_t);
            _t = $signed(al_q_arr[L_E1245])  * $signed(bl_q_arr[L_E1234]);  acc[L_E35] += int'(_t);
            _t = $signed(al_q_arr[L_E1345])  * $signed(bl_q_arr[L_E14]);    acc[L_E35] += int'(_t);
            _t = $signed(al_q_arr[L_E2345])  * $signed(bl_q_arr[L_E24]);    acc[L_E35] += int'(_t);
            _t = $signed(al_q_arr[L_E25])    * $signed(bl_q_arr[L_E24]);    acc[L_E45] += int'(_t);
            _t = $signed(al_q_arr[L_E35])    * $signed(bl_q_arr[L_E34]);    acc[L_E45] -= int'(_t);
            _t = $signed(al_q_arr[L_E45])    * $signed(bl_q_arr[L_E15]);    acc[L_E45] -= int'(_t);
            _t = $signed(al_q_arr[L_E1234])  * $signed(bl_q_arr[L_E1235]);  acc[L_E45] += int'(_t);
            _t = $signed(al_q_arr[L_E1235])  * $signed(bl_q_arr[L_E1234]);  acc[L_E45] -= int'(_t);
            _t = $signed(al_q_arr[L_E1245])  * $signed(bl_q_arr[L_E12]);    acc[L_E45] -= int'(_t);
            _t = $signed(al_q_arr[L_E1345])  * $signed(bl_q_arr[L_E13]);    acc[L_E45] -= int'(_t);
            _t = $signed(al_q_arr[L_E2345])  * $signed(bl_q_arr[L_E23]);    acc[L_E45] -= int'(_t);
            _t = $signed(al_q_arr[L_E15])    * $signed(bl_q_arr[L_E2345]);  acc[L_E1234] += int'(_t);
            _t = $signed(al_q_arr[L_E25])    * $signed(bl_q_arr[L_E1345]);  acc[L_E1234] -= int'(_t);
            _t = $signed(al_q_arr[L_E35])    * $signed(bl_q_arr[L_E1245]);  acc[L_E1234] += int'(_t);
            _t = $signed(al_q_arr[L_E45])    * $signed(bl_q_arr[L_E1235]);  acc[L_E1234] -= int'(_t);
            _t = $signed(al_q_arr[L_E1234])  * $signed(bl_q_arr[L_SCALAR]);  acc[L_E1234] += int'(_t);
            _t = $signed(al_q_arr[L_E1235])  * $signed(bl_q_arr[L_E45]);    acc[L_E1234] += int'(_t);
            _t = $signed(al_q_arr[L_E1245])  * $signed(bl_q_arr[L_E35]);    acc[L_E1234] -= int'(_t);
            _t = $signed(al_q_arr[L_E1345])  * $signed(bl_q_arr[L_E25]);    acc[L_E1234] += int'(_t);
            _t = $signed(al_q_arr[L_E2345])  * $signed(bl_q_arr[L_E15]);    acc[L_E1234] -= int'(_t);
            for (int i=0;i<EVEN_LANES;i++) out_lane_loc[i] = sat16_q511(acc[i]);
             
             result_d = unpack_even(out_lane_loc);
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

    function automatic ga_multivector_t wedgeProduct_even(
        ga_multivector_t a,
        ga_multivector_t b
    );
        int signed acc[EVEN_LANES];
        logic signed [FP_W-1:0] al[EVEN_LANES], bl[EVEN_LANES];
        logic signed [FP_W-1:0] out_lane[EVEN_LANES];
        
        for (int i=0;i<EVEN_LANES;i++) acc[i] = 0;
        
        pack_even(a, al);
        pack_even(b, bl);
        
        `define ACCP(idx, xa, xb) acc[idx] += int'($signed(xa)) * int'($signed(xb))
        `define ACCN(idx, xa, xb) acc[idx] -= int'($signed(xa)) * int'($signed(xb))
        
        `ACCP(L_SCALAR, al[L_SCALAR], bl[L_SCALAR]);
        `ACCP(L_E12, al[L_SCALAR], bl[L_E12]);
        `ACCP(L_E12, al[L_E12], bl[L_SCALAR]);
        `ACCP(L_E13, al[L_SCALAR], bl[L_E13]);
        `ACCP(L_E13, al[L_E13], bl[L_SCALAR]);
        `ACCP(L_E23, al[L_SCALAR], bl[L_E23]);
        `ACCP(L_E23, al[L_E23], bl[L_SCALAR]);
        `ACCP(L_E14, al[L_SCALAR], bl[L_E14]);
        `ACCP(L_E14, al[L_E14], bl[L_SCALAR]);
        `ACCP(L_E24, al[L_SCALAR], bl[L_E24]);
        `ACCP(L_E24, al[L_E24], bl[L_SCALAR]);
        `ACCP(L_E34, al[L_SCALAR], bl[L_E34]);
        `ACCP(L_E34, al[L_E34], bl[L_SCALAR]);
        `ACCP(L_E15, al[L_SCALAR], bl[L_E15]);
        `ACCP(L_E15, al[L_E15], bl[L_SCALAR]);
        `ACCP(L_E25, al[L_SCALAR], bl[L_E25]);
        `ACCP(L_E25, al[L_E25], bl[L_SCALAR]);
        `ACCP(L_E35, al[L_SCALAR], bl[L_E35]);
        `ACCP(L_E35, al[L_E35], bl[L_SCALAR]);
        `ACCP(L_E45, al[L_SCALAR], bl[L_E45]);
        `ACCP(L_E45, al[L_E45], bl[L_SCALAR]);
        `ACCP(L_E1234, al[L_SCALAR], bl[L_E1234]);
        `ACCP(L_E1234, al[L_E12], bl[L_E34]);
        `ACCN(L_E1234, al[L_E13], bl[L_E24]);
        `ACCP(L_E1234, al[L_E23], bl[L_E14]);
        `ACCP(L_E1234, al[L_E14], bl[L_E23]);
        `ACCN(L_E1234, al[L_E24], bl[L_E13]);
        `ACCP(L_E1234, al[L_E34], bl[L_E12]);
        `ACCP(L_E1234, al[L_E1234], bl[L_SCALAR]);
        `ACCP(L_E1235, al[L_SCALAR], bl[L_E1235]);
        `ACCP(L_E1235, al[L_E12], bl[L_E35]);
        `ACCN(L_E1235, al[L_E13], bl[L_E25]);
        `ACCP(L_E1235, al[L_E23], bl[L_E15]);
        `ACCP(L_E1235, al[L_E15], bl[L_E23]);
        `ACCN(L_E1235, al[L_E25], bl[L_E13]);
        `ACCP(L_E1235, al[L_E35], bl[L_E12]);
        `ACCP(L_E1235, al[L_E1235], bl[L_SCALAR]);
        `ACCP(L_E1245, al[L_SCALAR], bl[L_E1245]);
        `ACCP(L_E1245, al[L_E12], bl[L_E45]);
        `ACCN(L_E1245, al[L_E14], bl[L_E25]);
        `ACCP(L_E1245, al[L_E24], bl[L_E15]);
        `ACCP(L_E1245, al[L_E15], bl[L_E24]);
        `ACCN(L_E1245, al[L_E25], bl[L_E14]);
        `ACCP(L_E1245, al[L_E45], bl[L_E12]);
        `ACCP(L_E1245, al[L_E1245], bl[L_SCALAR]);
        `ACCP(L_E1345, al[L_SCALAR], bl[L_E1345]);
        `ACCP(L_E1345, al[L_E13], bl[L_E45]);
        `ACCN(L_E1345, al[L_E14], bl[L_E35]);
        `ACCP(L_E1345, al[L_E34], bl[L_E15]);
        `ACCP(L_E1345, al[L_E15], bl[L_E34]);
        `ACCN(L_E1345, al[L_E35], bl[L_E14]);
        `ACCP(L_E1345, al[L_E45], bl[L_E13]);
        `ACCP(L_E1345, al[L_E1345], bl[L_SCALAR]);
        `ACCP(L_E2345, al[L_SCALAR], bl[L_E2345]);
        `ACCP(L_E2345, al[L_E23], bl[L_E45]);
        `ACCN(L_E2345, al[L_E24], bl[L_E35]);
        `ACCP(L_E2345, al[L_E34], bl[L_E25]);
        `ACCP(L_E2345, al[L_E25], bl[L_E34]);
        `ACCN(L_E2345, al[L_E35], bl[L_E24]);
        `ACCP(L_E2345, al[L_E45], bl[L_E23]);
        `ACCP(L_E2345, al[L_E2345], bl[L_SCALAR]);

        `undef ACCP
        `undef ACCN

        for (int i=0;i<EVEN_LANES;i++) out_lane[i] = sat16_q511(acc[i]);
        return unpack_even(out_lane);

    endfunction

    function automatic ga_multivector_t dotProduct_even(
        ga_multivector_t a,
        ga_multivector_t b
    );
        int signed acc[EVEN_LANES];
        logic signed [FP_W-1:0] al[EVEN_LANES], bl[EVEN_LANES];
        logic signed [FP_W-1:0] out_lane[EVEN_LANES];
        
        for (int i=0;i<EVEN_LANES;i++) acc[i] = 0;
        
        pack_even(a, al);
        pack_even(b, bl);
        
        `define ACCP(idx, xa, xb) acc[idx] += int'($signed(xa)) * int'($signed(xb))
        `define ACCN(idx, xa, xb) acc[idx] -= int'($signed(xa)) * int'($signed(xb))
        
        `ACCP(L_SCALAR, al[L_SCALAR], bl[L_SCALAR]);
        `ACCN(L_SCALAR, al[L_E12], bl[L_E12]);
        `ACCN(L_SCALAR, al[L_E13], bl[L_E13]);
        `ACCN(L_SCALAR, al[L_E23], bl[L_E23]);
        `ACCN(L_SCALAR, al[L_E14], bl[L_E14]);
        `ACCN(L_SCALAR, al[L_E24], bl[L_E24]);
        `ACCN(L_SCALAR, al[L_E34], bl[L_E34]);
        `ACCP(L_SCALAR, al[L_E15], bl[L_E15]);
        `ACCP(L_SCALAR, al[L_E25], bl[L_E25]);
        `ACCP(L_SCALAR, al[L_E35], bl[L_E35]);
        `ACCP(L_SCALAR, al[L_E45], bl[L_E45]);
        `ACCP(L_SCALAR, al[L_E1234], bl[L_E1234]);
        `ACCN(L_SCALAR, al[L_E1235], bl[L_E1235]);
        `ACCN(L_SCALAR, al[L_E1245], bl[L_E1245]);
        `ACCN(L_SCALAR, al[L_E1345], bl[L_E1345]);
        `ACCN(L_SCALAR, al[L_E2345], bl[L_E2345]);
        `ACCP(L_E12, al[L_SCALAR], bl[L_E12]);
        `ACCN(L_E12, al[L_E34], bl[L_E1234]);
        `ACCP(L_E12, al[L_E35], bl[L_E1235]);
        `ACCP(L_E12, al[L_E45], bl[L_E1245]);
        `ACCP(L_E13, al[L_SCALAR], bl[L_E13]);
        `ACCP(L_E13, al[L_E24], bl[L_E1234]);
        `ACCN(L_E13, al[L_E25], bl[L_E1235]);
        `ACCP(L_E13, al[L_E45], bl[L_E1345]);
        `ACCP(L_E23, al[L_SCALAR], bl[L_E23]);
        `ACCN(L_E23, al[L_E14], bl[L_E1234]);
        `ACCP(L_E23, al[L_E15], bl[L_E1235]);
        `ACCP(L_E23, al[L_E45], bl[L_E2345]);
        `ACCP(L_E14, al[L_SCALAR], bl[L_E14]);
        `ACCN(L_E14, al[L_E23], bl[L_E1234]);
        `ACCN(L_E14, al[L_E25], bl[L_E1245]);
        `ACCN(L_E14, al[L_E35], bl[L_E1345]);
        `ACCP(L_E24, al[L_SCALAR], bl[L_E24]);
        `ACCP(L_E24, al[L_E13], bl[L_E1234]);
        `ACCP(L_E24, al[L_E15], bl[L_E1245]);
        `ACCN(L_E24, al[L_E35], bl[L_E2345]);
        `ACCP(L_E34, al[L_SCALAR], bl[L_E34]);
        `ACCN(L_E34, al[L_E12], bl[L_E1234]);
        `ACCP(L_E34, al[L_E15], bl[L_E1345]);
        `ACCP(L_E34, al[L_E25], bl[L_E2345]);
        `ACCP(L_E15, al[L_SCALAR], bl[L_E15]);
        `ACCN(L_E15, al[L_E23], bl[L_E1235]);
        `ACCN(L_E15, al[L_E24], bl[L_E1245]);
        `ACCN(L_E15, al[L_E34], bl[L_E1345]);
        `ACCP(L_E25, al[L_SCALAR], bl[L_E25]);
        `ACCP(L_E25, al[L_E13], bl[L_E1235]);
        `ACCP(L_E25, al[L_E14], bl[L_E1245]);
        `ACCN(L_E25, al[L_E34], bl[L_E2345]);
        `ACCP(L_E35, al[L_SCALAR], bl[L_E35]);
        `ACCN(L_E35, al[L_E12], bl[L_E1235]);
        `ACCP(L_E35, al[L_E14], bl[L_E1345]);
        `ACCP(L_E35, al[L_E24], bl[L_E2345]);
        `ACCP(L_E45, al[L_SCALAR], bl[L_E45]);
        `ACCN(L_E45, al[L_E12], bl[L_E1245]);
        `ACCN(L_E45, al[L_E13], bl[L_E1345]);
        `ACCN(L_E45, al[L_E23], bl[L_E2345]);
        `ACCP(L_E1234, al[L_SCALAR], bl[L_E1234]);
        `ACCP(L_E1235, al[L_SCALAR], bl[L_E1235]);
        `ACCP(L_E1245, al[L_SCALAR], bl[L_E1245]);
        `ACCP(L_E1345, al[L_SCALAR], bl[L_E1345]);
        `ACCP(L_E2345, al[L_SCALAR], bl[L_E2345]);

        `undef ACCP
        `undef ACCN

        for (int i=0;i<EVEN_LANES;i++) out_lane[i] = sat16_q511(acc[i]);
        return unpack_even(out_lane);

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
        result.e14    = negQ511(a.e14);
        result.e24    = negQ511(a.e24);
        result.e34    = negQ511(a.e34);
        result.e15    = negQ511(a.e15);
        result.e25    = negQ511(a.e25);
        result.e35    = negQ511(a.e35);
        result.e45    = negQ511(a.e45);
        result.e1234  = a.e1234;
        result.e1235  = a.e1235;
        result.e1245  = a.e1245;
        result.e1345  = a.e1345;
        result.e2345  = a.e2345;

        return result;

    endfunction

    function automatic logic signed [FP_W-1:0] normCalculation(
        ga_multivector_t a
    );
        int signed acc_scalar = 0;
        logic signed [FP_W-1:0] al[EVEN_LANES];
        pack_even(a, al);

        for (int i = 0;i < EVEN_LANES; i++) begin
            acc_scalar += int'($signed(al[i])) * int'($signed(al[i]));
        end
        
        return sat16_q511(acc_scalar);

    endfunction

    function automatic ga_multivector_t rotorApplication(
        ga_multivector_t rotor,
        ga_multivector_t vector
    );
        ga_multivector_t revRotor   = reverseOperation(rotor);
        //ga_multivector_t temp       = geometricProduct(rotor, vector);

        return revRotor;//geometricProduct(temp, revRotor);

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
            result.e14          = a.e14 + b.e14;
            result.e24          = a.e24 + b.e24;
            result.e34          = a.e34 + b.e34;
            result.e15          = a.e15 + b.e15;
            result.e25          = a.e25 + b.e25;
            result.e35          = a.e35 + b.e35;
            result.e45          = a.e45 + b.e45;
            result.e1234        = a.e1234 + b.e1234;
            result.e1235        = a.e1235 + b.e1235;
            result.e1245        = a.e1245 + b.e1245;
            result.e1345        = a.e1345 + b.e1345;
            result.e2345        = a.e2345 + b.e2345;
        end

        GA_FUNCT_SUB: begin

            result.scalar      = a.scalar - b.scalar;
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
            result.e1234       = a.e1234 - b.e1234;
            result.e1235       = a.e1235 - b.e1235;
            result.e1245       = a.e1245 - b.e1245;
            result.e1345       = a.e1345 - b.e1345;
            result.e2345       = a.e2345 - b.e2345;

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
