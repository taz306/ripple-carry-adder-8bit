#!/usr/bin/env bash
# =====================================================================
#  A01 · Buoc 2 — Tong hop logic (Yosys) len thu vien sky130_fd_sc_hd
#  Chay:  bash 04_IMPLEMENTATION/scripts/02_run_synth.sh [duong_dan_liberty]
#
#  Neu khong truyen tham so, script tim file Liberty theo thu tu:
#    1. $LIBERTY
#    2. $PDK_ROOT/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib
#    3. ./sky130_fd_sc_hd__tt_025C_1v80.lib
# =====================================================================
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"
OUT="06_GDSII/synthesis"
mkdir -p "$OUT"

if ! command -v yosys >/dev/null 2>&1; then
  echo "[LOI] Khong tim thay 'yosys'.  Ubuntu/WSL: sudo apt install yosys"
  exit 2
fi

LIB="${1:-${LIBERTY:-}}"
if [ -z "$LIB" ]; then
  CAND="${PDK_ROOT:-/usr/local/share/pdk}/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib"
  [ -f "$CAND" ] && LIB="$CAND"
fi
[ -z "$LIB" ] && [ -f "./sky130_fd_sc_hd__tt_025C_1v80.lib" ] && LIB="./sky130_fd_sc_hd__tt_025C_1v80.lib"

if [ -z "$LIB" ] || [ ! -f "$LIB" ]; then
  echo "[LOI] Khong tim thay file Liberty sky130_fd_sc_hd__tt_025C_1v80.lib"
  echo "      Cach 1: export PDK_ROOT=<thu muc pdk>   (volare / open_pdks)"
  echo "      Cach 2: bash $0 /duong/dan/toi/file.lib"
  exit 3
fi

echo "== Cong cu =="
yosys -V | head -1 | tee "$OUT/tool_versions.txt"
echo "Liberty: $LIB" | tee -a "$OUT/tool_versions.txt"

cat > "$OUT/synth.ys" <<EOF
read_verilog -sv 04_IMPLEMENTATION/rtl/a01_ripple_adder.sv
hierarchy -check -top a01_ripple_adder
proc
opt
fsm
opt
memory
opt
techmap
opt
dfflibmap -liberty $LIB
abc -liberty $LIB
setundef -zero
splitnets
opt_clean -purge
tee -o $OUT/synth_stat.txt stat -liberty $LIB
read_liberty -lib $LIB
tee -o $OUT/synth_check.txt check
write_verilog -noattr $OUT/a01_netlist.v
write_json $OUT/a01_netlist.json
EOF

echo
echo "== Tong hop =="
yosys -Q -s "$OUT/synth.ys" > "$OUT/yosys.log" 2>&1

echo
cat "$OUT/synth_stat.txt"

# --- Kiem tra bat buoc: A01 phai co 0 flip-flop (AC-9) ---------------
echo
if grep -qE "sky130_fd_sc_hd__(df|dl|sd)" "$OUT/synth_stat.txt"; then
  echo "[CANH BAO] Phat hien cell tuan tu trong netlist!"
  echo "           A01 phai co 0 flip-flop (REQ-A01-007 / AC-9)."
  exit 1
else
  echo "[OK] Khong co cell tuan tu — dung dac ta mach to hop (AC-9 DAT)."
fi
echo "Bang chung: $OUT/synth_stat.txt · $OUT/a01_netlist.v"
