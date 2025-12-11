
// uart_rx_ctrl.sv
// 50MHz クロック / 115200bps, 8N1 受信コントローラ
// RX シリアル入力を 1byte に組み立てて FIFO へ渡す

module uart_rx_ctrl
  (
    input  logic       aclk,
    input  logic       aresetn,
    input  logic       rx_serial,
    output logic [7:0] rx_fifo_data,
    output logic       rx_fifo_valid,
    input  logic       rx_fifo_ready
  );

  // 50 MHz / 115200 ≒ 434
  localparam int BAUD_DIV = 434;
  localparam int HALF_DIV = BAUD_DIV/2;   // スタートビット中央サンプル用

  typedef enum logic [1:0] {
    RX_IDLE,
    RX_START,
    RX_DATA,
    RX_STOP
  } rx_state_t;

  rx_state_t  state;
  logic [8:0] baud_cnt;
  logic [2:0] bit_idx;
  logic [7:0] shift_reg;

  // ------------------------------------------------------------
  // 受信状態機械
  // ------------------------------------------------------------
  always_ff @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
      state     <= RX_IDLE;
      baud_cnt  <= '0;
      bit_idx   <= '0;
      shift_reg <= 8'h00;
    end else begin
      case (state)
        RX_IDLE: begin
          baud_cnt <= '0;
          bit_idx  <= '0;
          // start ビット検出（ラインが 0 に落ちたら）
          if (rx_serial == 1'b0) begin
            state    <= RX_START;
            baud_cnt <= '0;
          end
        end

        RX_START: begin
          // start ビット中央まで待機
          if (baud_cnt == HALF_DIV-1) begin
            baud_cnt <= '0;
            state    <= RX_DATA;
            bit_idx  <= 3'd0;
          end else begin
            baud_cnt <= baud_cnt + 1'b1;
          end
        end

        RX_DATA: begin
          // 各データビットの終端でサンプリング
          if (baud_cnt == BAUD_DIV-1) begin
            baud_cnt               <= '0;
            shift_reg[bit_idx]     <= rx_serial;
            if (bit_idx == 3'd7) begin
              state   <= RX_STOP;
            end else begin
              bit_idx <= bit_idx + 1'b1;
            end
          end else begin
            baud_cnt <= baud_cnt + 1'b1;
          end
        end

        RX_STOP: begin
          // stop ビット期間を 1bit 分待つ
          if (baud_cnt == BAUD_DIV-1) begin
            baud_cnt <= '0;
            state    <= RX_IDLE;   // このサイクルで shift_reg に 1byte 完成
          end else begin
            baud_cnt <= baud_cnt + 1'b1;
          end
        end

        default: state <= RX_IDLE;
      endcase
    end
  end

  // ------------------------------------------------------------
  // FIFO への valid/ready ハンドシェイク
  //   stop ビット完了サイクルで shift_reg をそのまま FIFO に渡す
  // ------------------------------------------------------------
  always_ff @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
      rx_fifo_valid <= 1'b0;
      rx_fifo_data  <= 8'h00;
    end else begin
      // FIFO がデータを受理したら valid を下げる
      if (rx_fifo_valid && rx_fifo_ready) begin
        rx_fifo_valid <= 1'b0;
      end

      // stop ビット計測完了サイクルで新しい 1byte をプッシュ
      // （この always と状態機械の always は同じクロックで動き、
      //  non-blocking なので state/baud_cnt の「旧値」を参照できる）
      if (state == RX_STOP && baud_cnt == BAUD_DIV-1) begin
        if (!rx_fifo_valid || rx_fifo_ready) begin
          rx_fifo_data  <= shift_reg;  // 直近受信した 1byte
          rx_fifo_valid <= 1'b1;
        end
      end
    end
  end

endmodule : uart_rx_ctrl
