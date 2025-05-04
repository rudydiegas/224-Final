`default_nettype none

module BitStuff_down (
  input  wire  clk,
  input  wire  rst_n,
  input  wire  en,
  input  wire  serial_in,
  input  wire  is_EOP,
  output logic is_stuffed
);

  logic [2:0] ones_cnt;

  assign is_stuffed = ones_cnt == 3'd6;

  always_ff @(posedge clk) begin
    if (~rst_n)
      ones_cnt <= 3'b0;
    else if (en)
      if (serial_in & ~is_EOP)
        ones_cnt <= ones_cnt + 3'b1;
      else
        ones_cnt <= 3'b0;
  end

endmodule : BitStuff_down
