
module uart_tx_ctrl
  (
    input  logic        aclk,
    input  logic        aresetn,
    input  logic        tx_fifo_valid,
    output logic        tx_fifo_ready,
    input  logic [7:0]  tx_fifo_data,
    output logic        tx_serial
  );

  // 50 MHz / 115200 ≒ 434
  localparam int BAUD_DIV = 434;

  typedef enum logic [1:0] {
    TX_IDLE,
    TX_START,
    TX_DATA,
    TX_STOP
  } tx_state_t;

  tx_state_t   state;
  logic [8:0]  baud_cnt;   // enough for 0..433
  logic [2:0]  bit_idx;
  logic [7:0]  shift_reg;

  always_ff @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
      state         <= TX_IDLE;
      baud_cnt      <= '0;
      bit_idx       <= '0;
      shift_reg     <= 8'h00;
      tx_serial     <= 1'b1;   // idle is '1'
      tx_fifo_ready <= 1'b0;
    end else begin
      tx_fifo_ready <= 1'b0;

      case (state)
        TX_IDLE: begin
          tx_serial <= 1'b1;
          baud_cnt  <= '0;
          bit_idx   <= '0;
          if (tx_fifo_valid) begin
            // 1byte 受取
            shift_reg     <= tx_fifo_data;
            tx_fifo_ready <= 1'b1;  // FIFO からポップ
            state         <= TX_START;
          end
        end

        TX_START: begin
          tx_serial <= 1'b0;  // start bit
          if (baud_cnt == BAUD_DIV-1) begin
            baud_cnt <= '0;
            state    <= TX_DATA;
          end else begin
            baud_cnt <= baud_cnt + 1'b1;
          end
        end

        TX_DATA: begin
          tx_serial <= shift_reg[bit_idx];
          if (baud_cnt == BAUD_DIV-1) begin
            baud_cnt <= '0;
            if (bit_idx == 3'd7) begin
              state   <= TX_STOP;
            end else begin
              bit_idx <= bit_idx + 1'b1;
            end
          end else begin
            baud_cnt <= baud_cnt + 1'b1;
          end
        end

        TX_STOP: begin
          tx_serial <= 1'b1;  // stop bit
          if (baud_cnt == BAUD_DIV-1) begin
            baud_cnt <= '0;
            state    <= TX_IDLE;
          end else begin
            baud_cnt <= baud_cnt + 1'b1;
          end
        end

        default: state <= TX_IDLE;
      endcase
    end
  end

endmodule : uart_tx_ctrl
