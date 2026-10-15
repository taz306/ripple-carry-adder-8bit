`timescale 1ns/1ps

module a01_tb;
    logic [7:0] a, b;
    logic [7:0] sum_dut, sum_ref;
    logic c_dut, z_dut, n_dut, v_dut;
    logic c_ref, z_ref, n_ref, v_ref;

    integer i, j;
    integer fd;
    integer errors;
    integer checks;
    logic [8:0] expected_full;

    a01_ripple_adder dut (
        .a(a), .b(b), .sum(sum_dut),
        .c(c_dut), .z(z_dut), .n(n_dut), .v(v_dut)
    );

    a01_reference ref_model (
        .a(a), .b(b), .sum(sum_ref),
        .c(c_ref), .z(z_ref), .n(n_ref), .v(v_ref)
    );

    initial begin
        $dumpfile("a01_waves.vcd");
        $dumpvars(0, a01_tb);

        fd = $fopen("tc_results.csv", "w");
        if (fd == 0) begin
            $display("ERROR: khong mo duoc tc_results.csv");
            $fatal(1);
        end
        $fwrite(fd, "A,B,SUM,C,Z,N,V,RESULT\n");

        errors = 0;
        checks = 0;

        // Ca bat buoc va cac ca tu thiet ke duoc ghi rieng.
        check_case(0,   0,   "REQ_0_PLUS_0");
        check_case(255, 0,   "REQ_255_PLUS_0");
        check_case(255, 1,   "REQ_255_PLUS_1");
        check_case(127, 1,   "REQ_127_PLUS_1");
        check_case(200, 100, "REQ_200_PLUS_100");
        check_case(1,   1,   "CUSTOM_1_PLUS_1");
        check_case(128, 128, "CUSTOM_128_PLUS_128");

        // Exhaustive: kiem tra moi cap dau vao 8-bit.
        for (i = 0; i < 256; i = i + 1) begin
            for (j = 0; j < 256; j = j + 1) begin
                a = i;
                b = j;
                #1;
                checks = checks + 1;

                if ({c_dut, sum_dut} !== {c_ref, sum_ref} ||
                    z_dut !== z_ref ||
                    n_dut !== n_ref ||
                    v_dut !== v_ref) begin
                    errors = errors + 1;
                    if (errors <= 20)
                        $display("MISMATCH A=%0d B=%0d DUT sum=%h C=%b Z=%b N=%b V=%b REF sum=%h C=%b Z=%b N=%b V=%b",
                            i, j, sum_dut, c_dut, z_dut, n_dut, v_dut,
                            sum_ref, c_ref, z_ref, n_ref, v_ref);
                end
            end
        end

        $fclose(fd);
        if (errors == 0) begin
            $display("So cap dau vao kiem tra exhaustive: %0d", checks);
            $display("KET QUA: PASS");
            $finish;
        end else begin
            $display("KET QUA: FAIL - %0d loi trong %0d cap", errors, checks);
            $fatal(1);
        end
    end

    task automatic check_case(
        input integer av,
        input integer bv,
        input [8*32-1:0] label
    );
        begin
            a = av;
            b = bv;
            #1;
            expected_full = av + bv;
            if ({c_dut, sum_dut} !== expected_full ||
                z_dut !== (expected_full[7:0] == 8'h00) ||
                n_dut !== expected_full[7] ||
                v_dut !== ((~(a[7] ^ b[7])) &
                           (expected_full[7] ^ a[7]))) begin
                $display("CA BAT BUOC/TU THIET KE LOI: %0s A=%0d B=%0d",
                         label, av, bv);
                errors = errors + 1;
            end
            $fwrite(fd, "%0d,%0d,%02h,%0b,%0b,%0b,%0b,%s\n",
                    av, bv, sum_dut, c_dut, z_dut, n_dut, v_dut,
                    (errors == 0) ? "PASS" : "CHECK");
        end
    endtask
endmodule
