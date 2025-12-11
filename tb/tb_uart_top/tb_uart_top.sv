`timescale 1ns/1ps

module tb_uart_top;

  // ------------------------------------------------------------
  // DUT との接続信号
  // ------------------------------------------------------------
  logic         aclk;
  logic         aresetn;

  // AXI4-Lite write channel
  logic         awvalid;
  logic [31:0]  awaddr;
  logic         wvalid;
  logic [3:0]   wstrb;
  logic [31:0]  wdata;
  logic         bready;
  logic         awready;
  logic         wready;
  logic [1:0]   bresp;
  logic         bvalid;

  // AXI4-Lite read channel
  logic         arvalid;
  logic [31:0]  araddr;
  logic         rready;
  logic         arready;
  logic [31:0]  rdata;
  logic [1:0]   rresp;
  logic         rvalid;

  // UART pins
  wire          tx_serial;
  wire          rx_serial;

  // ループバック (TX → RX)
  assign rx_serial = tx_serial;

  // レジスタアドレス（word アライン［5:2］使用を想定）
  localparam [31:0] ADDR_CONTROL = 32'h0000_0000; // 0x00
  localparam [31:0] ADDR_STATUS  = 32'h0000_0004; // 0x04
  localparam [31:0] ADDR_TX_DATA = 32'h0000_0008; // 0x08
  localparam [31:0] ADDR_RX_DATA = 32'h0000_000C; // 0x0C

  // ------------------------------------------------------------
  // DUT
  // ------------------------------------------------------------
  uart_top dut (
    .aclk      (aclk),
    .aresetn   (aresetn),

    .awvalid   (awvalid),
    .awaddr    (awaddr),
    .wvalid    (wvalid),
    .wstrb     (wstrb),
    .wdata     (wdata),
    .bready    (bready),
    .awready   (awready),
    .wready    (wready),
    .bresp     (bresp),
    .bvalid    (bvalid),

    .arvalid   (arvalid),
    .araddr    (araddr),
    .rready    (rready),
    .arready   (arready),
    .rdata     (rdata),
    .rresp     (rresp),
    .rvalid    (rvalid),

    .tx_serial (tx_serial),
    .rx_serial (rx_serial)
  );

  // ------------------------------------------------------------
  // クロック & リセット
  //   50 MHz → 周期 20ns （#10 でトグル）
  // ------------------------------------------------------------
  initial begin
    aclk = 1'b0;
    forever #10 aclk = ~aclk;
  end

  initial begin
    aresetn = 1'b0;
    #200;              // 200ns リセット
    aresetn = 1'b1;
  end

  // ------------------------------------------------------------
  // AXI4-Lite Write タスク
  // ------------------------------------------------------------
  task automatic axi_write(
      input [31:0] addr,
      input [31:0] data,
      input [3:0]  strb = 4'hF
  );
    begin
      @(posedge aclk);
      awaddr  <= addr;
      wdata   <= data;
      wstrb   <= strb;
      awvalid <= 1'b1;
      wvalid  <= 1'b1;
      bready  <= 1'b1;

      // AW/W ready を待つ
      wait (awready && wready);
      @(posedge aclk);
      awvalid <= 1'b0;
      wvalid  <= 1'b0;

      // Bvalid を待つ
      wait (bvalid);
      @(posedge aclk);
      bready  <= 1'b0;
    end
  endtask

  // ------------------------------------------------------------
  // AXI4-Lite Read タスク
  // ------------------------------------------------------------
  task automatic axi_read(
      input  [31:0] addr,
      output [31:0] data
  );
    begin
      @(posedge aclk);
      araddr  <= addr;
      arvalid <= 1'b1;
      rready  <= 1'b1;

      // ARready を待つ
      wait (arready);
      @(posedge aclk);
      arvalid <= 1'b0;

      // Rvalid を待つ
      wait (rvalid);
      data = rdata;
      @(posedge aclk);
      rready <= 1'b0;
    end
  endtask

  // ------------------------------------------------------------
  // テストシーケンス
  // ------------------------------------------------------------
  integer      i;
  logic [31:0] tmp;

  initial begin
    // 初期値
    awvalid = 0; wvalid = 0; bready = 0;
    arvalid = 0; rready = 0;
    awaddr  = 0; wdata  = 0; wstrb = 0;
    araddr  = 0;

    // リセット解除待ち
    wait (aresetn == 1'b1);
    @(posedge aclk);

    $display("[%0t] Reset deasserted", $time);

    // 1) CONTROL レジスタ: TX/RX 有効 (bit0/bit1 を 1 に)
    axi_write(ADDR_CONTROL, 32'h0000_0003);

    // 2) 送信データを FIFO に 4 バイト書き込み
    for (i = 0; i < 4; i++) begin
      axi_write(ADDR_TX_DATA, {24'h0, (8'h41 + i[7:0])}); // 'A','B','C','D'
      $display("[%0t] TX_DATA write: 0x%02x", $time, (8'h41 + i[7:0]));
    end

    // 3) UART で実際に 4 byte 送受信が完了するまで待機
    //    1bit あたり ≒ 8.68us, 1byte(10bit) ≒ 86.8us
    //    4byte 分として余裕を見て 1ms 待つ
    #(1_000_000);
//    #(1_500_000);

    // 4) STATUS 読み出し
    axi_read(ADDR_STATUS, tmp);
    $display("[%0t] STATUS = 0x%08x", $time, tmp);

    // 5) RX_DATA を 4 バイト読み出し
    for (i = 0; i < 4; i++) begin
      axi_read(ADDR_RX_DATA, tmp);
      $display("[%0t] RX_DATA[%0d] = 0x%02x", $time, i, tmp[7:0]);
    end

    // 6) 終了
    #100_000;
    $finish;
  end

endmodule
