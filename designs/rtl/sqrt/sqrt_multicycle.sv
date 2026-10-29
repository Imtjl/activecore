module sqrt_multicycle (
      input               clk_i
    , input               rst_i
    , input               start_i
    , input        [31:0] x_bi
    , output logic        busy_o
    , output logic [31:0] y_bo
);

logic [31:0] x, y, m, b;

assign b = y | m;
assign busy_o = m != 0;
assign y_bo = y;

always_ff @(posedge clk_i) begin
    if (rst_i) begin
        x <= 0;
        y <= 0;
        m <= 0;
    end else if (start_i) begin
        x <= x_bi;
        y <= 0;
        m <= 32'h4000_0000;
    end else if (busy_o) begin
        x <= x >= b ? x - b : x;
        y <= x >= b ? (y >> 1) | m : y >> 1;
        m <= m >> 2;
    end
end

endmodule
