module sqrt_comb (
      input        [31:0] x_bi
    , output logic [31:0] y_bo
);

logic [31:0] x, y, m, b;

always_comb begin
    x = x_bi;
    y = 0;
    m = 32'h4000_0000;
    for (int i = 0; i < 16; i++) begin
        b = y | m;
        y = y >> 1;
        if (x >= b) begin
            x = x - b;
            y = y | m;
        end
        m = m >> 2;
    end
    y_bo = y;
end

endmodule
