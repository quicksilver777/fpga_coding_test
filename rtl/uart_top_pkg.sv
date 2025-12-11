// Copyright © 2025 QuEL, Inc. All rights reserved.

package uart_top_pkg;

  typedef enum UART_REG {
    CONTROL = 4'h0,
    STATUS  = 4'h4,
    TX_FIFO = 4'h8,
    RX_FIFO = 4'hc
  } uart_top_reg_map_e;

endpackage : uart_top_pkg
