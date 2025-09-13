module ga_register_file #(
  parameter int unsigned NumRegs   = 32,
  parameter int unsigned DataWidth = 256
) (
  input  logic                      clk_i,
  input  logic                      rst_ni,

  input  logic                      we_i,
  input  logic [$clog2(NumRegs)-1:0] waddr_i,
  input  logic [DataWidth-1:0]      wdata_i,

  input  logic [$clog2(NumRegs)-1:0] raddr_a_i,
  output logic [DataWidth-1:0]      rdata_a_o,

  input  logic [$clog2(NumRegs)-1:0] raddr_b_i,
  output logic [DataWidth-1:0]      rdata_b_o
);

  logic [DataWidth-1:0] registers [NumRegs];

  always_ff @(posedge clk_i or negedge rst_ni) begin
    
    if (!rst_ni) begin
      
      for (int i = 0; i < NumRegs; i++) begin
        registers[i] <= '0;
      
      end
    end else begin
      
      if (we_i) begin
        registers[waddr_i] <= wdata_i;
      
      end
    end
  end

  always_comb begin
    
    if (raddr_a_i == '0) begin
      rdata_a_o = '0;
    end else begin
      rdata_a_o = registers[raddr_a_i];
    end

  end

  always_comb begin
    
    if (raddr_b_i == '0) begin
      rdata_b_o = '0;
    end else begin
      rdata_b_o = registers[raddr_b_i];
    end

  end

  `ifdef ASSERT_ON

    assert property (@(posedge clk_i) disable iff (!rst_ni)
      (we_i |-> waddr_i < NumRegs))
      else $error("Write address out of bounds");

    assert property (@(posedge clk_i) disable iff (!rst_ni)
      (raddr_a_i < NumRegs))
      else $error("Read address A out of bounds");

    assert property (@(posedge clk_i) disable iff (!rst_ni)  
      (raddr_b_i < NumRegs))
      else $error("Read address B out of bounds");
  `endif

endmodule
