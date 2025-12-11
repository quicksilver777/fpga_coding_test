
module uart_fifo
  (
    input  logic       aclk,
    input  logic       aresetn,
    // write side
    input  logic       wrvalid,
    output logic       wrready,
    input  logic [7:0] wrdata,
    // read side
    output logic       rdvalid,
    input  logic       rdready,
    output logic [7:0] rddata,
    // status
    output logic       empty,
    output logic       full
  );

  localparam int DEPTH   = 16;
  localparam int PTR_WID = $clog2(DEPTH);

  logic [7:0]              mem [DEPTH-1:0];
  logic [PTR_WID-1:0]      wr_ptr, rd_ptr;
  logic [PTR_WID:0]        count;  // 0..DEPTH

  wire write_fire = wrvalid && wrready;
  wire read_fire  = rdvalid && rdready;

  assign full    = (count == DEPTH);
  assign empty   = (count == 0);
  assign wrready = !full;
  assign rdvalid = !empty;
  assign rddata  = mem[rd_ptr];

  always_ff @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
      wr_ptr <= '0;
      rd_ptr <= '0;
      count  <= '0;
    end else begin
      // write
      if (write_fire) begin
        mem[wr_ptr] <= wrdata;
        wr_ptr      <= wr_ptr + 1'b1;
      end

      // read
      if (read_fire) begin
        rd_ptr <= rd_ptr + 1'b1;
      end

      // count
      unique case ({write_fire, read_fire})
        2'b10: count <= count + 1'b1;
        2'b01: count <= count - 1'b1;
        default: ;
      endcase
    end
  end

endmodule : uart_fifo
