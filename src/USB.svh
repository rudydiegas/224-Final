// Credit to 18-341 P5-USB for some definitions in this file

`ifndef USB_VALS
  `define USB_VALS

  // defines for magic numbers
  `define BITSTUFF_LEN 6

  // USB field lengths
  `define SYNC_BITS 8
  `define PID_BITS 4
  `define ADDR_BITS 7
  `define ENDP_BITS 4
  `define DATA_BITS 64
  `define FRAME_BITS 11
  `define CRC5_BITS 5
  `define CRC16_BITS 16
  `define EOP_BITS 3

  `define CRC5_CALC_LEN (`SYNC_BITS + \
                         (2 * `PID_BITS) + \
                         `ADDR_BITS + \
                         `ENDP_BITS)

  `define CRC16_CALC_LEN (`SYNC_BITS + \
                          (2 * `PID_BITS) + \
                          `DATA_BITS - 1)

  // Lengths for calculations of packets
  `define TOKEN_PKT_LEN (`SYNC_BITS + \
                         (2 * `PID_BITS) + \
                         `ADDR_BITS + \
                         `ENDP_BITS + \
                         `CRC5_BITS + \
                         `EOP_BITS)

  `define DATA_PKT_LEN (`SYNC_BITS + \
                        (2 * `PID_BITS) + \
                        `DATA_BITS + \
                        `CRC16_BITS + \
                        `EOP_BITS)

  `define HANDSHAKE_PKT_LEN (`SYNC_BITS + \
                             (2 * `PID_BITS) + \
                             `EOP_BITS)

  `define SOF_PKT_LEN (`SYNC_BITS + \
                       (2 * `PID_BITS) + \
                       `FRAME_BITS + \
                       `CRC5_BITS + \
                       `EOP_BITS)

  `define SYNC 8'b00000001
  `define ADDR_ENDP 4'h4
  `define DATA_ENDP 4'h8
  `define CRC16_RESIDUE 16'h80_0D
  `define CRC5_RESIDUE 5'h0C
  `define TIMEOUT 256
  `define STUFF_LENGTH 7
  `define TX_RETRIES 8

  typedef enum logic [`PID_BITS-1:0] {
    // TOKEN
    PID_OUT   = 4'b0001,
    PID_IN    = 4'b1001,
    PID_SOF   = 4'b0101,
    PID_SETUP = 4'b1101,

    // DATA
    PID_DATA0 = 4'b0011,
    PID_DATA1 = 4'b1011,

    // HANDSHAKE
    PID_ACK   = 4'b0010,
    PID_NAK   = 4'b1010,
    PID_STALL = 4'b1110,

    // SPECIAL
    PID_PRE   = 4'b1100,

    // SIMULATION
    PID_X     = 4'bxxxx
  } pid_t;

  typedef enum logic [7:0] {
    GET_STATUS        = 8'd0,
    CLEAR_FEATURE     = 8'd1,
    // RESERVED       = 8'd2,
    SET_FEATURE       = 8'd3,
    // RESERVED       = 8'd4,
    SET_ADDRESS       = 8'd5,
    GET_DESCRIPTOR    = 8'd6,
    SET_DESCRIPTOR    = 8'd7,
    GET_CONFIGURATION = 8'd8,
    SET_CONFIGURATION = 8'd9,
    GET_INTERFACE     = 8'd10,
    SET_INTERFACE     = 8'd11,
    SYNCH_FRAME       = 8'd12
  } bRequest_t;

  typedef enum logic [1:0] {
    STANDARD = 2'd0,
    CLASS    = 2'd1,
    VENDOR   = 2'd2
  } requestType_t;

  typedef enum logic [4:0] {
    DEVICE_R    = 5'd0,
    INTERFACE_R = 5'd1,
    ENDPOINT_R  = 5'd2,
    PORT_R      = 5'd3
  } requestRecipient_t;

  typedef struct packed {
    logic transferDir;
    requestType_t requestType;
    requestRecipient_t recipient;
  } bmRequestType_t;

  typedef struct packed {
    bmRequestType_t bmRequestType;
    bRequest_t bRequest;
    logic [15:0] wValue;
    logic [15:0] wIndex;
    logic [15:0] wLength;
  } setupData_t;

  typedef enum logic [7:0] {
    DEVICE_D        = 8'd1,
    CONFIGURATION_D = 8'd2,
    STRING_D        = 8'd3,
    INTERFACE_D     = 8'd4,
    ENDPOINT_D      = 8'd5
  } descType_t;

  // full-speed device definitions
  typedef enum logic [1:0] {
    USB_J   = 2'b10,
    USB_K   = 2'b01,
    USB_SE0 = 2'b00,
    USB_SE1 = 2'b11,
    USB_NC  = 2'bzz,
    USB_X   = 2'bxx
  } bus_t;

  // generic fixed size packet
  typedef struct packed {
    pid_t pid;
    logic [`ADDR_BITS-1:0]    addr;
    logic [`ENDP_BITS-1:0]    endp;
    logic [`DATA_BITS-1:0] payload;
  } pkt_t;

  // debugging fixed size packet
  typedef struct packed {
    logic [`SYNC_BITS-1:0]    sync;
    logic [`PID_BITS-1:0]      pid;
    logic [`PID_BITS-1:0]    pid_n;
    logic [`ADDR_BITS-1:0]    addr;
    logic [`ENDP_BITS-1:0]    endp;
    logic [`DATA_BITS-1:0] payload;
  } debug_pkt_t;

`endif
