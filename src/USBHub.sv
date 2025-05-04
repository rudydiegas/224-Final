`default_nettype none

// `include "USB.svh"

module USBHub (
  input  wire         clk,
  input  wire         rst_n,
  inout  tri          DP,
  inout  tri          DM,
  input  logic        en,

  output logic        end_transmission,
  output logic        error,
  output logic [7:0]  sync_o,
  output pid_t        PID_o,
  output logic [6:0]  addr_o,
  output logic [3:0]  endp_o,
  output logic [10:0] frame_o,
  output logic [63:0] data_o
);
  localparam RESET_TIMEOUT = 19'd480_000;

  logic transmit;
  bus_t serial_in;

  logic rst_USB;
  logic global_rst;
  logic [18:0] reset_cntr;

  logic load_addr;


  ////////////////
  /// HUB DATA ///
  ////////////////

  logic [6:0] hub_addr;

  // logic en;
  // logic end_transmission;
  // logic error;
  // logic [7:0] sync_o;
  // pid_t PID_o;
  // logic [6:0] addr_o;
  // logic [3:0] endp_o;
  // logic [10:0] frame_o;
  // logic [63:0] data_o;

  logic [7:0] sync_i;
  pid_t PID_i;
  logic [6:0] addr_i;
  logic [3:0] endp_i;
  logic [10:0] frame_i;
  logic [63:0] data_i;

  assign serial_in = bus_t'({DP, DM});
  assign rst_USB = reset_cntr == RESET_TIMEOUT;
  assign global_rst = ~rst_n | rst_USB;

  always_ff @(posedge clk) begin
    if (global_rst)
      reset_cntr <= 19'b0;
    else if (serial_in == USB_SE0)
      reset_cntr <= reset_cntr + 19'b1;
    else
      reset_cntr <= 19'b0;
  end

  SIE_down downstream (
    .clk,
    .rst_n(~global_rst),
    .en,
    .serial_in,
    .end_transmission,
    .error,
    .sync_o(sync_i),
    .PID_o(PID_i),
    .addr_o(addr_i),
    .endp_o(endp_i),
    .frame_o(frame_i),
    .data_o(data_i)
  );

  always_ff @(posedge clk) begin
    if (global_rst)
      hub_addr <= 7'b0;
    else if (end_transmission & load_addr)
      hub_addr <= addr_o;
  end

endmodule : USBHub
