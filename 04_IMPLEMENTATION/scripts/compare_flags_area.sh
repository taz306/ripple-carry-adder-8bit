#!/usr/bin/env bash
# =====================================================================
#  A01 · Do DIEN TICH TANG THEM do bon co C, Z, N, V
#
#  Tra loi cau hoi ky thuat #3 cua Charter (muc 2):
#  "Bon co C, Z, N, V ton them bao nhieu phan dien tich so voi chi tinh tong?"
#
#  Cach do: tong hop HAI phien ban roi lay hieu.
#    (a) ban day du  : sum + 4 co
#    (b) ban rut gon : chi sum
#
#  Chay:  bash 04_IMPLEMENTATION/scripts/compare_flags_area.sh [liberty.lib]
# =====================================================================
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"
WORK="06_GDSII/synthesis/flag_area_study"
mkdir -p "$WORK"

LIB="${1:-${LIBERTY:-}}"
if [ -z "$LIB" ] && [ -n "${PDK_ROOT:-}" ]; then
  LIB="$PDK_ROOT/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib"
fi
if [ -z "$LIB" ] || [ ! -f "$LIB" ]; then
  echo "[LOI] Khong tim thay Liberty. Dung: bash $0 /duong/dan/file.lib"; exit 2
fi

# --- (b) Ban chi tinh SUM, cung kien truc ripple tuong minh ----------
cat > "$WORK/a01_sum_only.sv" <<'EOF'
// Ban RUT GON: chi tinh sum, khong co co trang thai.
// Kien truc ripple giu NGUYEN de phep so sanh cong bang.
module a01_sum_only (
    input  logic [7:0] a,
    input  logic [7:0] b,
    output logic [7:0] sum
);
    logic [8:0] carry;
    assign carry[0] = 1'b0;
    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin : GEN_FA
            assign sum[i]     = a[i] ^ b[i] ^ carry[i];
            assign carry[i+1] = (a[i] & b[i]) | (a[i] & carry[i]) | (b[i] & carry[i]);
        end
    endgenerate
endmodule
EOF

synth () {          # $1 = file .sv   $2 = top   $3 = ten bao cao
  yosys -Q -p "
    read_verilog -sv $1
    hierarchy -check -top $2
    proc; opt; techmap; opt
    abc -liberty $LIB
    setundef -zero; splitnets; opt_clean -purge
    tee -o $WORK/$3 stat -liberty $LIB
  " > "$WORK/${3%.txt}.log" 2>&1
}

echo "== Tong hop ban DAY DU (sum + 4 co) =="
synth 04_IMPLEMENTATION/rtl/a01_ripple_adder.sv a01_ripple_adder full_stat.txt

echo "== Tong hop ban RUT GON (chi sum) =="
synth "$WORK/a01_sum_only.sv" a01_sum_only sumonly_stat.txt

area () { grep -oP 'Chip area for module .*?: \K[0-9.]+' "$WORK/$1" | tail -1; }
cells () { grep -oP 'Number of cells:\s+\K[0-9]+' "$WORK/$1" | tail -1; }

AF=$(area full_stat.txt);    CF=$(cells full_stat.txt)
AS=$(area sumonly_stat.txt); CS=$(cells sumonly_stat.txt)

python3 - "$AF" "$CF" "$AS" "$CS" "$WORK" <<'PY'
import sys
af, cf, asu, cs, work = float(sys.argv[1]), int(sys.argv[2]), float(sys.argv[3]), int(sys.argv[4]), sys.argv[5]
d_a, d_c = af - asu, cf - cs
pct = d_a / asu * 100 if asu else 0
out = f"""# A01 — Chi phi dien tich cua bon co trang thai

Do bang cach tong hop hai phien ban cung kien truc ripple, cung thu vien,
cung script; chi khac o cho co hay khong co logic sinh co.

| Phien ban | So cell | Dien tich (um^2) |
|---|---:|---:|
| Chi tinh SUM              | {cs} | {asu:.4f} |
| SUM + 4 co (C, Z, N, V)   | {cf} | {af:.4f} |
| **Chenh lech**            | **+{d_c}** | **+{d_a:.4f}** |
| **Ty le tang**            | | **+{pct:.1f}%** |

## Doc ket qua

- `C` va `N` ton **0 cong**: `C` = `carry[8]` da co san, `N` = `sum[7]` chi la day noi.
- Toan bo phan tang them thuoc ve `Z` (cay NOR 8 ngo) va `V` (2 XOR + 1 INV + 1 AND).
- Ca `Z` lan `V` deu **noi tiep sau** `sum`, nen ngoai dien tich chung con co the
  **keo dai duong toi han**. Phai doi chieu `06_GDSII/sta/` de biet endpoint that.

Dieu kien tao ra so lieu: xem `02_SPECIFICATION/parameters.md` §2.
"""
open(f"{work}/../../physical_report_flag_area.md","w").write(out)
print(out)
PY

echo "Da ghi: 06_GDSII/physical_report_flag_area.md"
