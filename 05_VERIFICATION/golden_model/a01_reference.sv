module a01_reference (
    input  logic [7:0] a,
    input  logic [7:0] b,
    output logic [7:0] sum,
    output logic       c,
    output logic       z,
    output logic       n,
    output logic       v
);
    logic [8:0] full_sum;

    always @(*) begin
        full_sum = {1'b0, a} + {1'b0, b};
        sum = full_sum[7:0];
        c = full_sum[8];
        z = (sum == 8'h00);
        n = sum[7];
        v = (~(a[7] ^ b[7])) & (sum[7] ^ a[7]);
    end
endmodule
