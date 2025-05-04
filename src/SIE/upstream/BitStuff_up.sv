`default_nettype none

module BitStuff_up
(input  wire  clk,
 input  wire  reset_n,
 input  wire  setup_done,
 input  wire  pkt_done,
 input  wire  serial_out,
 output logic stuff_zero);

  enum logic [1:0] {BS_IDLE,
                    BS_WAIT,
                    BS_CALC} curr_state, next_state;

  logic cnt_en, cnt_clr, cnt_done;
  logic [2:0] cnt;

  always_comb begin
	// next state logic
    next_state = BS_IDLE;
    case (curr_state)
      BS_IDLE: next_state = (serial_out) ? BS_WAIT : BS_IDLE;
      BS_WAIT: next_state = (setup_done) ? BS_CALC : BS_WAIT;
      BS_CALC: next_state = (pkt_done) ? BS_IDLE : BS_CALC;
    endcase

    // output logic
    cnt_clr = 1'b0;
    cnt_en = 1'b0;
    case (curr_state)
      BS_IDLE: cnt_clr = 1'b1;
      BS_CALC: begin
        cnt_en = serial_out;
        cnt_clr = ~serial_out | cnt_done;
      end
    endcase
  end

  assign cnt_done = cnt == `BITSTUFF_LEN;
  assign stuff_zero = cnt_done;

  // state transition
  always_ff @(posedge clk)
    if (~reset_n)
      curr_state <= BS_IDLE;
    else
      curr_state <= next_state;

  // counter for the number of 1s received from serial_out
  always_ff @(posedge clk)
    if (~reset_n | cnt_clr)
      cnt <= '0;
    else if (cnt_en)
      cnt <= cnt + 3'd1;

endmodule : BitStuff_up
