`default_nettype none

// `include "../../USB.svh"

module NRZI_down (
  input  wire  clk,
  input  wire  rst_n,
  input  wire  en,
  input  bus_t serial_in,
  output logic in_transmission,
  output logic start_transmission,
  output logic end_transmission,
  output logic is_EOP,
  output logic serial_out
);

  bus_t past_serial;
  logic same_serial;
  logic in_transmission_reg;
  logic past_in_transmission;

  assign same_serial = past_serial == serial_in;
  assign serial_out = (same_serial & in_transmission);
  assign is_EOP = (past_serial == USB_SE0) | (serial_in == USB_SE0);
  assign in_transmission = in_transmission_reg | ~same_serial;
  assign start_transmission = ~past_in_transmission & in_transmission;
  assign end_transmission = past_in_transmission & ~in_transmission;

  always_ff @(posedge clk) begin
    if (~rst_n)
      past_serial <= USB_J;
    else if (en)
      past_serial <= serial_in;
  end

  always_ff @(posedge clk) begin
    if (~rst_n)
      in_transmission_reg <= 1'b0;
    else if (en)
      if (is_EOP & (serial_in == USB_J))
        in_transmission_reg <= 1'b0;
      else if (~same_serial)
        in_transmission_reg <= 1'b1;
  end

  always_ff @(posedge clk) begin
    if (~rst_n)
      past_in_transmission <= 1'b0;
    else if (en)
      past_in_transmission <= in_transmission;
  end

endmodule : NRZI_down
