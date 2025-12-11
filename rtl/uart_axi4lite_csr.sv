module uart_axi4lite_csr
  (
    input  logic        aclk,
    input  logic        aresetn,

    // AXI4-Lite write channel
    input  logic [31:0] awaddr,
    input  logic        awvalid,
    output logic        awready,
    input  logic [31:0] wdata,
    input  logic [3:0]  wstrb,
    input  logic        wvalid,
    output logic        wready,
    output logic [1:0]  bresp,
    output logic        bvalid,
    input  logic        bready,

    // AXI4-Lite read channel
    input  logic [31:0] araddr,
    input  logic        arvalid,
    output logic        arready,
    output logic [31:0] rdata,
    output logic [1:0]  rresp,
    output logic        rvalid,
    input  logic        rready,

    // TX FIFO interface
    output logic        tx_fifo_wrvalid,
    input  logic        tx_fifo_wrready,
    output logic [7:0]  tx_fifo_wrdata,
    input  logic        tx_fifo_empty,
    input  logic        tx_fifo_full,

    // RX FIFO interface
    input  logic        rx_fifo_rdvalid,
    output logic        rx_fifo_rdready,
    input  logic [7:0]  rx_fifo_rddata,
    input  logic        rx_fifo_empty,
    input  logic        rx_fifo_full
  );

  localparam [3:0] ADDR_CONTROL = 4'h0; // 0x00
  localparam [3:0] ADDR_STATUS  = 4'h1; // 0x04
  localparam [3:0] ADDR_TX_DATA = 4'h2; // 0x08
  localparam [3:0] ADDR_RX_DATA = 4'h3; // 0x0C

  logic [31:0] control_reg;

  wire [3:0] awaddr_dec = awaddr[5:2];
  wire [3:0] araddr_dec = araddr[5:2];

  wire write_en = awvalid && wvalid;
  wire read_en  = arvalid && rready;

  // ============================================================
  // WRITE
  // ============================================================
  always_ff @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
      control_reg     <= 32'h0;
      tx_fifo_wrvalid <= 1'b0;
      tx_fifo_wrdata  <= 8'h00;
    end else begin
      tx_fifo_wrvalid <= 1'b0;

      if (write_en) begin
        case (awaddr_dec)
          ADDR_CONTROL: begin
            if (wstrb[0]) control_reg[7:0]   <= wdata[7:0];
            if (wstrb[1]) control_reg[15:8]  <= wdata[15:8];
            if (wstrb[2]) control_reg[23:16] <= wdata[23:16];
            if (wstrb[3]) control_reg[31:24] <= wdata[31:24];
          end

          ADDR_TX_DATA: begin
            if (!tx_fifo_full) begin
              tx_fifo_wrdata  <= wdata[7:0];
              tx_fifo_wrvalid <= 1'b1;
            end
          end
        endcase
      end
    end
  end

  assign awready = 1'b1;
  assign wready  = 1'b1;
  assign bresp   = 2'b00;
  assign bvalid  = 1'b1;

  // ============================================================
  // RX FIFO POP は「RX_DATA アクセス時のみ」
  // ============================================================
  always_ff @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
      rx_fifo_rdready <= 1'b0;
    end else begin
      rx_fifo_rdready <= 1'b0;

      // RX_DATA が読まれた瞬間だけ 1cycle POP
      if (read_en && araddr_dec == ADDR_RX_DATA && !rx_fifo_empty) begin
        rx_fifo_rdready <= 1'b1;
      end
    end
  end

  // ============================================================
  // READ DATA（FIFO 直結）
  // ============================================================
  always_comb begin
    case (araddr_dec)
      ADDR_CONTROL: rdata = control_reg;

      ADDR_STATUS: begin
        rdata      = 32'h0;
        rdata[0]   = tx_fifo_empty;
        rdata[1]   = tx_fifo_full;
        rdata[2]   = rx_fifo_empty;
        rdata[3]   = rx_fifo_full;
      end

      // FIFO の現在値をそのまま返す（ラッチなし・ズレなし）
      ADDR_RX_DATA: rdata = {24'h0, rx_fifo_rddata};

      default: rdata = 32'h0;
    endcase
  end

  assign arready = 1'b1;
  assign rvalid  = arvalid;
  assign rresp   = 2'b00;

endmodule
