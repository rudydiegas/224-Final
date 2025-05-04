`default_nettype none

module data_recovery (
  input  wire  clk,
  input  wire  rst_n,
  input  wire  serial_in,
  output logic valid,
  output logic serial_out

  // FOR ChipInterface DEBUGGING
  // output logic edge_detected,
  // output logic [3:0] sipo_O,
);

  logic valid_cond;
  logic edge_detected;
  logic [1:0] sample_ind;
  // logic [2:0] num_ones;
  logic [1:0] num_ones;
  logic [3:0] sipo;

  // TODO: REMOVE
  // assign sipo_O = sipo;

  assign valid_cond = sample_ind == 2'd3;
  assign edge_detected = sipo[0] ^ serial_in;
  // assign num_ones = sipo[0] + sipo[1] + sipo[2] + sipo[3];
  // assign serial_out = (num_ones == 3'd3) | (num_ones == 3'd4);

  // technically could just use sipo[3:1] because those 3 samples will
  // always be the good ones. uncomment code below if low on size lol
  //
  assign num_ones = sipo[1] + sipo[2] + sipo[3];
  assign serial_out = num_ones == 2'd3;

  // want to delay valid by one cycle to use the registered serial_in
  always_ff @(posedge clk) begin
    if (~rst_n)
      valid <= 1'b0;
    else if (valid)
      valid <= 1'b0;
    else if (valid_cond)
      valid <= 1'b1;
  end

  always_ff @(posedge clk) begin
    if (~rst_n)
      sample_ind <= 2'b0;
    // if an edge is detected, the current serial_in is different and
    // it will be in the sipo on the next clock cycle. so we'll have 1
    // valid bit in the sipo on the next clock cycle, hence 1
    else if (edge_detected)
      sample_ind <= 2'b1;
    else
      sample_ind <= sample_ind + 2'b1;
  end

  always_ff @(posedge clk) begin
    if (~rst_n)
      sipo <= 4'b0;
    else
      sipo <= {sipo[2:0], serial_in};
  end

endmodule : data_recovery
