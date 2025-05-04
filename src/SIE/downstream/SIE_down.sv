`default_nettype none

// `include "../../USB.svh"

module SIE_down (
  input  wire  clk,
  input  wire  rst_n,
  input  wire  en,
  input  bus_t serial_in,

  //////////////////////
  /// OUTPUT CONTROL ///
  //////////////////////

  output logic end_transmission,
  output logic error,

  ///////////////////
  /// OUTPUT DATA ///
  ///////////////////

  output logic [7:0]  sync_o,
  output pid_t        PID_o,
  output logic [6:0]  addr_o,
  output logic [3:0]  endp_o,
  output logic [10:0] frame_o,
  output logic [63:0] data_o
);

  logic in_transmission;
  logic start_transmission;
  logic is_EOP;
  logic is_stuffed;
  logic nrz_data;
  logic CRC5_ready;
  logic CRC16_ready;
  logic bit_cnt_clr;

  logic sync_en;
  logic PID_en;
  logic token_en;
  logic data_en;

  logic sync_error;
  logic PID_error;
  logic CRC5_error;
  logic CRC16_error;
  logic EOP_error;

  logic sync_error_en;
  logic PID_error_en;
  logic CRC5_error_en;
  logic CRC16_error_en;
  logic EOP_error_en;

  logic [4:0] CRC5_reg;
  logic [4:0] CRC5_calc;
  logic [15:0] CRC16_reg;
  logic [15:0] CRC16_calc;

  logic [5:0] bit_cnt;

  pid_t PID_val;
  pid_t PID_val_trns;
  logic [3:0] PID_val_n;
  logic [6:0] address;
  logic [3:0] endpoint;

  logic [7:0] rcvd_sync;
  logic [7:0] rcvd_PID;
  logic [10:0] rcvd_token;
  logic [63:0] rcvd_data;

  NRZI_down SIE_NRZI_down (
    .clk,
    .rst_n,
    .en,
    .serial_in,
    .in_transmission,
    .start_transmission,
    .end_transmission,
    .is_EOP,
    .serial_out(nrz_data)
  );

  BitStuff_down SIE_BitStuff_down (
    .clk,
    .rst_n,
    .en,
    .serial_in(nrz_data),
    .is_EOP,
    .is_stuffed
  );

  CRC5_down SIE_CRC5_down (
    .clk,
    .rst_n,
    .en,
    .serial_in(nrz_data),
    .is_stuffed,
    .in_transmission,
    .end_transmission,
    .CRC5_ready,
    .CRC5_reg
  );

  CRC16_down SIE_CRC16_down (
    .clk,
    .rst_n,
    .en,
    .serial_in(nrz_data),
    .is_stuffed,
    .in_transmission,
    .end_transmission,
    .CRC16_ready,
    .CRC16_reg
  );

  always_ff @(posedge clk) begin
    if (~rst_n)
      CRC5_calc <= 5'b0;
    else if (en & CRC5_ready)
      CRC5_calc <= CRC5_reg;
  end

  always_ff @(posedge clk) begin
    if (~rst_n)
      CRC16_calc <= 16'b0;
    else if (en & CRC16_ready)
      CRC16_calc <= CRC16_reg;
  end

  always_ff @(posedge clk) begin
    if (~rst_n)
      bit_cnt <= 6'b0;
    else if (en)
      if (bit_cnt_clr)
        bit_cnt <= 6'b0;
      else if (in_transmission & ~is_stuffed)
        bit_cnt <= bit_cnt + 6'b1;
  end

  enum logic [2:0] {SYNC,
                    PID,
                    TOKEN,
                    DATA,
                    CRC5,
                    CRC16,
                    EOP} curr_state, next_state, prev_state;

  always_comb begin

    ////////////////////////
    /// NEXT STATE LOGIC ///
    ////////////////////////

    next_state = SYNC;
    case (curr_state)
      SYNC: begin
        next_state = ((bit_cnt == 6'd7) & ~is_stuffed) ? PID : SYNC;
      end
      PID: begin
        if ((bit_cnt == 6'd7) & ~is_stuffed)
          if ((PID_val_trns == PID_DATA0) | (PID_val_trns == PID_DATA1))
            next_state = DATA;
          else if ((PID_val_trns == PID_ACK) | (PID_val_trns == PID_NAK) |
                   (PID_val_trns == PID_PRE) | (PID_val_trns == PID_STALL))
            next_state = EOP;
          else
            next_state = TOKEN;
        else
          next_state = PID;
      end
      TOKEN: begin
        next_state = ((bit_cnt == 6'd10) & ~is_stuffed) ? CRC5 : TOKEN;
      end
      DATA: begin
        next_state = ((bit_cnt == 6'd63) & ~is_stuffed) ? CRC16 : DATA;
      end
      CRC5: begin
        next_state = ((bit_cnt == 6'd4) & ~is_stuffed) ? EOP : CRC5;
      end
      CRC16: begin
        next_state = ((bit_cnt == 6'd15) & ~is_stuffed) ? EOP : CRC16;
      end
      EOP: begin
        next_state = ((bit_cnt == 6'd2) & ~is_stuffed) ? SYNC : EOP;
      end
    endcase

    ///////////////////
    /// BIT_CNT_CLR ///
    ///////////////////

    bit_cnt_clr = 1'b0;
    case (curr_state)
      SYNC: begin
        bit_cnt_clr = (bit_cnt == 6'd7) & ~is_stuffed;
      end
      PID: begin
        bit_cnt_clr = (bit_cnt == 6'd7) & ~is_stuffed;
      end
      TOKEN: begin
        bit_cnt_clr = (bit_cnt == 6'd10) & ~is_stuffed;
      end
      DATA: begin
        bit_cnt_clr = (bit_cnt == 6'd63) & ~is_stuffed;
      end
      CRC5: begin
        bit_cnt_clr = (bit_cnt == 6'd4) & ~is_stuffed;
      end
      CRC16: begin
        bit_cnt_clr = (bit_cnt == 6'd15) & ~is_stuffed;
      end
      EOP: begin
        bit_cnt_clr = (bit_cnt == 6'd2) & ~is_stuffed;
      end
    endcase

    ///////////////////
    /// ERROR LOGIC ///
    ///////////////////

    sync_error_en = 1'b0;
    PID_error_en = 1'b0;
    CRC5_error_en = 1'b0;
    CRC16_error_en = 1'b0;
    EOP_error_en = 1'b0;
    case (curr_state)
      PID: begin
        sync_error_en = (bit_cnt == 6'b0) & ~is_stuffed & (rcvd_sync != 8'b1);
      end
      TOKEN: begin
        PID_error_en = (bit_cnt == 6'b0) & ~is_stuffed & (PID_val != ~PID_val_n);
      end
      DATA: begin
        PID_error_en = (bit_cnt == 6'b0) & ~is_stuffed & (PID_val != ~PID_val_n);
      end
      EOP: begin
        PID_error_en = (bit_cnt == 6'b0) & ~is_stuffed &
                       (prev_state == PID) & (PID_val != ~PID_val_n);

        CRC5_error_en = (bit_cnt == 6'b0) & ~is_stuffed &
                        (prev_state == CRC5) & (CRC5_reg != `CRC5_RESIDUE);

        CRC16_error_en = (bit_cnt == 6'b0) & ~is_stuffed &
                         (prev_state == CRC16) & (CRC16_reg != `CRC16_RESIDUE);

        EOP_error_en = ((bit_cnt == 6'd0) & ~is_stuffed & ~is_EOP) |
                       ((bit_cnt == 6'd1) & ~is_stuffed & ~is_EOP) |
                       ((bit_cnt == 6'd2) & ~is_stuffed & (serial_in != USB_J));
      end
    endcase
  end

  //////////////////////////
  /// PACKET STORE LOGIC ///
  //////////////////////////

  assign sync_en = (curr_state == SYNC) & in_transmission & ~is_stuffed;
  assign PID_en = (curr_state == PID) & ~is_stuffed;
  assign token_en = (curr_state == TOKEN) & ~is_stuffed;
  assign data_en = (curr_state == DATA) & ~is_stuffed;

  /////////////////
  /// FSM STATE ///
  /////////////////

  always_ff @(posedge clk) begin
    if (~rst_n)
      curr_state <= SYNC;
    else if (en)
      curr_state <= next_state;
  end

  always_ff @(posedge clk) begin
    if (~rst_n)
      prev_state <= SYNC;
    else if (en)
      prev_state <= curr_state;
  end

  /////////////////////
  /// PACKET FIELDS ///
  /////////////////////

  assign sync_o = rcvd_sync;
  assign PID_o = pid_t'(rcvd_PID[3:0]);
  assign addr_o = rcvd_token[6:0];
  assign endp_o = rcvd_token[10:7];
  assign frame_o = rcvd_token;
  assign data_o = rcvd_data;

  always_ff @(posedge clk) begin
    if (~rst_n)
      rcvd_sync <= 8'b0;
    else if (en & sync_en)
      rcvd_sync <= {rcvd_sync[6:0], nrz_data};
  end

  assign PID_val = pid_t'(rcvd_PID[3:0]);
  assign PID_val_trns = pid_t'(rcvd_PID[4:1]);
  assign PID_val_n = rcvd_PID[7:4];

  always_ff @(posedge clk) begin
    if (~rst_n)
      rcvd_PID <= 8'b0;
    else if (en & PID_en)
      rcvd_PID <= {nrz_data, rcvd_PID[7:1]};
  end

  assign address = rcvd_token[6:0];
  assign endpoint = rcvd_token[10:7];

  always_ff @(posedge clk) begin
    if (~rst_n)
      rcvd_token <= 11'b0;
    else if (en & token_en)
      rcvd_token <= {nrz_data, rcvd_token[10:1]};
  end

  always_ff @(posedge clk) begin
    if (~rst_n)
      rcvd_data <= 64'b0;
    else if (en & data_en)
      rcvd_data <= {nrz_data, rcvd_data[63:1]};
  end

  ///////////////////
  /// ERROR LOGIC ///
  ///////////////////

  assign error = sync_error | PID_error | CRC5_error | CRC16_error | EOP_error;

  always_ff @(posedge clk) begin
    if (~rst_n)
      sync_error <= 1'b0;
    else if (en)
      if (start_transmission)
        sync_error <= 1'b0;
      else if (sync_error_en)
        sync_error <= 1'b1;
  end

  always_ff @(posedge clk) begin
    if (~rst_n)
      PID_error <= 1'b0;
    else if (en)
      if (start_transmission)
        PID_error <= 1'b0;
      else if (PID_error_en)
        PID_error <= 1'b1;
  end

  always_ff @(posedge clk) begin
    if (~rst_n)
      CRC5_error <= 1'b0;
    else if (en)
      if (start_transmission)
        CRC5_error <= 1'b0;
      else if (CRC5_error_en)
        CRC5_error <= 1'b1;
  end

  always_ff @(posedge clk) begin
    if (~rst_n)
      CRC16_error <= 1'b0;
    else if (en)
      if (start_transmission)
        CRC16_error <= 1'b0;
      else if (CRC16_error_en)
        CRC16_error <= 1'b1;
  end

  always_ff @(posedge clk) begin
    if (~rst_n)
      EOP_error <= 1'b0;
    else if (en)
      if (start_transmission)
        EOP_error <= 1'b0;
      else if (EOP_error_en)
        EOP_error <= 1'b1;
  end

endmodule : SIE_down
