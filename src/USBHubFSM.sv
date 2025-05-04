`default_nettype none

// `include "USB.svh"

module USBHubFSM (
  input  wire  clk,
  input  wire  rst_n,
  input  wire  addr_set,
  input  wire  cnfg_set,
  output logic is_conf
);

  enum logic [1:0] {DFLT,
                    ADDR,
                    CNFG} curr_state, next_state;

  assign is_conf = curr_state == CNFG;

  always_comb begin
    next_state = DFLT;
    case (curr_state)
      DFLT: begin
        next_state = (addr_set) ? ADDR : DFLT;
      end
      ADDR: begin
        next_state = (cnfg_set) ? CNFG : ADDR;
      end
    endcase
  end

  always_ff @(posedge clk) begin
    if (~rst_n)
      curr_state <= DFLT;
    else
      curr_state <= next_state;
  end

endmodule : USBHubFSM
