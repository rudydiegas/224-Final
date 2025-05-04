`default_nettype none

module CRC5_down (
  input  wire  clk,
  input  wire  rst_n,
  input  wire  en,
  input  wire  serial_in,
  input  wire  is_stuffed,
  input  wire  in_transmission,
  input  wire  end_transmission,
  output logic CRC5_ready,
  output logic [4:0] CRC5_reg
);

  logic CRC_en;
  logic [3:0] setup_cnt;
  logic [3:0] CRC_data_cnt;

  enum logic [1:0] {CRC_IDLE,
                    CRC_CALC,
                    CRC_HOLD} curr_state, next_state;

  always_comb begin
    // next state logic
    next_state = CRC_IDLE;
    unique case (curr_state)
      CRC_IDLE: begin
        if ((setup_cnt == 4'd15) & ~is_stuffed)
          next_state = CRC_CALC;
        else
          next_state = CRC_IDLE;
      end
      CRC_CALC: begin
        if ((CRC_data_cnt == 4'd15) & ~is_stuffed)
          next_state = CRC_HOLD;
        else
          next_state = CRC_CALC;
      end
      CRC_HOLD: begin
        next_state = CRC_HOLD;
      end
    endcase
  end

  assign CRC_en = curr_state == CRC_CALC;
  assign CRC5_ready = curr_state == CRC_HOLD;

  always_ff @(posedge clk) begin
    if (~rst_n)
      curr_state <= CRC_IDLE;
    else if (en)
      if (end_transmission)
        curr_state <= CRC_IDLE;
      else
        curr_state <= next_state;
  end

  always_ff @(posedge clk) begin
    if (~rst_n)
      CRC_data_cnt <= 4'b0;
    else if (en)
      if (end_transmission)
        CRC_data_cnt <= 4'b0;
      else if (CRC_en & ~is_stuffed)
        CRC_data_cnt <= CRC_data_cnt + 4'b1;
  end

  always_ff @(posedge clk) begin
    if (~rst_n)
      setup_cnt <= 4'b0;
    else if (en)
      if (end_transmission)
        setup_cnt <= 4'b0;
      else if (in_transmission & ~is_stuffed)
        setup_cnt <= setup_cnt + 4'b1;
  end

  always_ff @(posedge clk) begin
    if (~rst_n)
      CRC5_reg <= '1;
    else if (en)
      if (end_transmission)
        CRC5_reg <= '1;
      else if (CRC_en & ~is_stuffed) begin
        CRC5_reg[0] <= serial_in ^ CRC5_reg[4];
        CRC5_reg[1] <= CRC5_reg[0];
        CRC5_reg[2] <= serial_in ^ CRC5_reg[4] ^ CRC5_reg[1];
        CRC5_reg[3] <= CRC5_reg[2];
        CRC5_reg[4] <= CRC5_reg[3];
      end
  end

endmodule : CRC5_down
