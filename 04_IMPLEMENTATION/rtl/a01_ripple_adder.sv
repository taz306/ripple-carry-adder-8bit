// =====================================================================
//  A01 — Bo cong 8-bit noi tiep carry (ripple-carry) co co trang thai
// ---------------------------------------------------------------------
//  De         : A01 · Nhom A — So hoc to hop
//  Loai mach  : TO HOP THUAN (khong clock, khong reset, 0 flip-flop)
//  Nguon      : Project Charter A01, muc 4 (giao dien) va muc 9 (phan tich)
//  Truy vet   : REQ-A01-001 … REQ-A01-007
//
//  RANG BUOC KIEN TRUC BAT BUOC
//  ----------------------------
//  KHONG duoc viet `assign sum = a + b;`.
//  Charter muc 9 yeu cau dem so tang carry tren duong toi han, nen chuoi
//  ripple phai duoc mo ta TUONG MINH. Toan tu '+' cho phep cong cu tong
//  hop tu chon kien truc (thuong la CLA), lam mat thu can quan sat.
//  Toan tu '+' CHI duoc dung trong golden model o 05_VERIFICATION/.
// =====================================================================

module a01_ripple_adder (
    input  logic [7:0] a,    // Tong hien tai / toan hang A
    input  logic [7:0] b,    // So buoc moi do duoc / toan hang B
    output logic [7:0] sum,  // 8 bit thap cua A + B
    output logic       c,    // Tran KHONG DAU  : A + B >= 256
    output logic       z,    // Ket qua bang 0  : sum == 0
    output logic       n,    // Bit dau         : sum[7]
    output logic       v     // Tran CO DAU (bu 2)
);

    // -----------------------------------------------------------------
    // Chuoi carry 9 bit: carry[0] la carry vao, carry[8] la carry ra.
    // Day chinh la duong phu thuoc NOI TIEP quyet dinh do tre cua khoi.
    // -----------------------------------------------------------------
    logic [8:0] carry;

    // De la bo CONG (khong phai cong/tru) => carry vao = 0.
    assign carry[0] = 1'b0;

    // -----------------------------------------------------------------
    // 8 tang full-adder noi tiep.
    // 'generate' o day la NHAN BAN KHONG GIAN (8 ban sao phan cung),
    // KHONG phai vong lap theo thoi gian.
    // -----------------------------------------------------------------
    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin : GEN_FA
            // Tong tung bit: chi 1 tang XOR SAU KHI carry[i] da on dinh
            assign sum[i]     = a[i] ^ b[i] ^ carry[i];

            // Carry ra cua tang i = ham da so (majority) cua 3 bit vao.
            // Day la mat xich thu i cua chuoi ripple.
            assign carry[i+1] = (a[i] & b[i])
                              | (a[i] & carry[i])
                              | (b[i] & carry[i]);
        end
    endgenerate

    // -----------------------------------------------------------------
    // Bon co trang thai
    // -----------------------------------------------------------------

    // C: tran khong dau — lay THANG tu cuoi chuoi carry, 0 cong them.
    assign c = carry[8];

    // Z: ket qua bang 0 — can cay NOR 8 ngo, NOI TIEP SAU sum.
    assign z = (sum == 8'h00);

    // N: bit dau khi dien giai bu 2 — chi la day noi, 0 cong them.
    assign n = sum[7];

    // V: tran co dau.
    //   Chi xay ra khi HAI toan hang CUNG DAU (a[7] == b[7])
    //   ma ket qua lai KHAC DAU voi chung (sum[7] != a[7]).
    //   => neu a[7] != b[7] thi V luon bang 0.
    assign v = ~(a[7] ^ b[7]) & (sum[7] ^ a[7]);

endmodule
