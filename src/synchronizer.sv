`default_nettype none

module synchronizer #(
  parameter WIDTH = 8
  ) (
  input  wire  clk,
  input  wire  rst_n,
  input  wire  [WIDTH-1:0] async,
  output logic [WIDTH-1:0] sync
);

  logic [WIDTH-1:0] async_0;

  always_ff @(posedge clk) begin
    if (~rst_n) begin
      async_0 <= {WIDTH-1{1'b0}};
      sync <= {WIDTH-1{1'b0}};
    end
    else begin
      async_0 <= async;
      sync <= async_0;
    end
  end

endmodule : synchronizer
