`default_nettype none

module CRC16_down (
  input  wire  clk,
  input  wire  rst_n,
  input  wire  en,
  input  wire  serial_in,
  input  wire  is_stuffed,
  input  wire  in_transmission,
  input  wire  end_transmission,
  output logic CRC16_ready,
  output logic [15:0] CRC16_reg
);

  logic CRC_en;
  logic [3:0] setup_cnt;
  logic [6:0] CRC_data_cnt;

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
        if ((CRC_data_cnt == 7'd79) & ~is_stuffed)
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
  assign CRC16_ready = curr_state == CRC_HOLD;

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
      CRC_data_cnt <= 7'b0;
    else if (en)
      if (end_transmission)
        CRC_data_cnt <= 7'b0;
      else if (CRC_en & ~is_stuffed)
        CRC_data_cnt <= CRC_data_cnt + 7'b1;
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

  always_ff @(posedge clk)
    if (~rst_n)
      CRC16_reg <= '1;
    else if (en)
      if (end_transmission)
        CRC16_reg <= '1;
      else if (CRC_en & ~is_stuffed) begin
        CRC16_reg[0]  <= serial_in ^ CRC16_reg[15];
        CRC16_reg[1]  <= CRC16_reg[0];
        CRC16_reg[2]  <= serial_in ^ CRC16_reg[15] ^ CRC16_reg[1];
        CRC16_reg[3]  <= CRC16_reg[2];
        CRC16_reg[4]  <= CRC16_reg[3];
        CRC16_reg[5]  <= CRC16_reg[4];
        CRC16_reg[6]  <= CRC16_reg[5];
        CRC16_reg[7]  <= CRC16_reg[6];
        CRC16_reg[8]  <= CRC16_reg[7];
        CRC16_reg[9]  <= CRC16_reg[8];
        CRC16_reg[10] <= CRC16_reg[9];
        CRC16_reg[11] <= CRC16_reg[10];
        CRC16_reg[12] <= CRC16_reg[11];
        CRC16_reg[13] <= CRC16_reg[12];
        CRC16_reg[14] <= CRC16_reg[13];
        CRC16_reg[15] <= serial_in ^ CRC16_reg[15] ^ CRC16_reg[14];
      end

endmodule : CRC16_down
