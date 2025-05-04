`default_nettype none

module my_chip (
    input logic [11:0] io_in, // Inputs to your chip
    output logic [11:0] io_out, // Outputs from your chip
    input logic clock,
    input logic reset // Important: Reset is ACTIVE-HIGH
);
  assign io_out[11:8] = 4'b0;

  USBHub top (
    .clk(clock),
    .rst_n(~reset),
    .DP(io_in[0]),
    .DM(io_in[1]),
    .en(1'b1),
    .end_transmission(),
    .error(),
    .sync_o(io_out[7:0]),
    .PID_o(),
    .addr_o(),
    .endp_o(),
    .frame_o(),
    .data_o()
  );

endmodule
