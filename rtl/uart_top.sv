
module uart_top
  (
    input  logic         aclk,      // 50 MHz system clock
    input  logic         aresetn,   // async. reset (active low)

    // AXI4-Lite write channel
    input  logic         awvalid,
    input  logic [31:0]  awaddr,
    input  logic         wvalid,
    input  logic [3:0]   wstrb,
    input  logic [31:0]  wdata,
    input  logic         bready,
    output logic         awready,
    output logic         wready,
    output logic [1:0]   bresp,
    output logic         bvalid,

    // AXI4-Lite read channel
    input  logic         arvalid,
    input  logic [31:0]  araddr,
    input  logic         rready,
    output logic         arready,
    output logic [31:0]  rdata,
    output logic [1:0]   rresp,
    output logic         rvalid,

    // UART pins
    output logic         tx_serial,
    input  logic         rx_serial
  );

  // ------------------------------------------------------------
  // TX FIFO 界面
  // ------------------------------------------------------------
  logic       tx_fifo_wrvalid;
  logic       tx_fifo_wrready;
  logic [7:0] tx_fifo_wrdata;

  logic       tx_fifo_rdvalid;
  logic       tx_fifo_rdready;
  logic [7:0] tx_fifo_rddata;

  logic       tx_fifo_empty;
  logic       tx_fifo_full;

  // ------------------------------------------------------------
  // RX FIFO 界面
  // ------------------------------------------------------------
  logic       rx_fifo_wrvalid;
  logic       rx_fifo_wrready;
  logic [7:0] rx_fifo_wrdata;

  logic       rx_fifo_rdvalid;
  logic       rx_fifo_rdready;
  logic [7:0] rx_fifo_rddata;

  logic       rx_fifo_empty;
  logic       rx_fifo_full;

  // ------------------------------------------------------------
  // AXI4-Lite CSR
  // ------------------------------------------------------------
  uart_axi4lite_csr u_csr (
    .aclk            (aclk),
    .aresetn         (aresetn),

    .awaddr          (awaddr),
    .awvalid         (awvalid),
    .awready         (awready),
    .wdata           (wdata),
    .wstrb           (wstrb),
    .wvalid          (wvalid),
    .wready          (wready),
    .bresp           (bresp),
    .bvalid          (bvalid),
    .bready          (bready),

    .araddr          (araddr),
    .arvalid         (arvalid),
    .arready         (arready),
    .rdata           (rdata),
    .rresp           (rresp),
    .rvalid          (rvalid),
    .rready          (rready),

    // TX FIFO side
    .tx_fifo_wrvalid (tx_fifo_wrvalid),
    .tx_fifo_wrready (tx_fifo_wrready),
    .tx_fifo_wrdata  (tx_fifo_wrdata),
    .tx_fifo_empty   (tx_fifo_empty),
    .tx_fifo_full    (tx_fifo_full),

    // RX FIFO side
    .rx_fifo_rdvalid (rx_fifo_rdvalid),
    .rx_fifo_rdready (rx_fifo_rdready),
    .rx_fifo_rddata  (rx_fifo_rddata),
    .rx_fifo_empty   (rx_fifo_empty),
    .rx_fifo_full    (rx_fifo_full)
  );

  // ------------------------------------------------------------
  // TX FIFO : CSR から書き込み、TX CTRL が読み出し
  // ------------------------------------------------------------
  uart_fifo u_tx_fifo (
    .aclk    (aclk),
    .aresetn (aresetn),
    .wrvalid (tx_fifo_wrvalid),
    .wrready (tx_fifo_wrready),
    .wrdata  (tx_fifo_wrdata),
    .rdvalid (tx_fifo_rdvalid),
    .rdready (tx_fifo_rdready),
    .rddata  (tx_fifo_rddata),
    .empty   (tx_fifo_empty),
    .full    (tx_fifo_full)
  );

  // ------------------------------------------------------------
  // RX FIFO : RX CTRL が書き込み、CSR が読み出し
  // ------------------------------------------------------------
  uart_fifo u_rx_fifo (
    .aclk    (aclk),
    .aresetn (aresetn),
    .wrvalid (rx_fifo_wrvalid),
    .wrready (rx_fifo_wrready),
    .wrdata  (rx_fifo_wrdata),
    .rdvalid (rx_fifo_rdvalid),
    .rdready (rx_fifo_rdready),
    .rddata  (rx_fifo_rddata),
    .empty   (rx_fifo_empty),
    .full    (rx_fifo_full)
  );

  // ------------------------------------------------------------
  // TX / RX コントローラ
  // ------------------------------------------------------------
  uart_tx_ctrl u_tx_ctrl (
    .aclk         (aclk),
    .aresetn      (aresetn),
    .tx_fifo_valid(tx_fifo_rdvalid),
    .tx_fifo_ready(tx_fifo_rdready),
    .tx_fifo_data (tx_fifo_rddata),
    .tx_serial    (tx_serial)
  );

  uart_rx_ctrl u_rx_ctrl (
    .aclk         (aclk),
    .aresetn      (aresetn),
    .rx_serial    (rx_serial),
    .rx_fifo_data (rx_fifo_wrdata),
    .rx_fifo_valid(rx_fifo_wrvalid),
    .rx_fifo_ready(rx_fifo_wrready)
  );

endmodule : uart_top
