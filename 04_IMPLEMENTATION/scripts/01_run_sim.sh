#!/usr/bin/env bash
# =====================================================================
#  A01 · Buoc 1 — Mo phong chuc nang (Icarus Verilog)
#  Chay tu THU MUC GOC cua du an:   bash 04_IMPLEMENTATION/scripts/01_run_sim.sh
# =====================================================================
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

OUT="05_VERIFICATION"
mkdir -p "$OUT/waveforms"

if ! command -v iverilog >/dev/null 2>&1; then
  echo "[LOI] Khong tim thay 'iverilog'."
  echo "      Ubuntu/WSL : sudo apt install iverilog"
  echo "      OSS CAD    : source <oss-cad-suite>/environment"
  exit 2
fi

echo "== Cong cu =="
iverilog -V | head -1 | tee "$OUT/tool_versions.txt"

echo
echo "== Bien dich =="
iverilog -g2012 -o "$OUT/a01_sim" \
    04_IMPLEMENTATION/rtl/a01_ripple_adder.sv \
    05_VERIFICATION/golden_model/a01_reference.sv \
    05_VERIFICATION/assertions/a01_sva.sv \
    05_VERIFICATION/testbench/a01_tb.sv

echo "== Chay mo phong (65.536 to hop — mat vai giay) =="
cd "$OUT"
vvp a01_sim | tee simulation.log
mv -f a01_waves.vcd waveforms/a01_waves.vcd 2>/dev/null || true
cd "$ROOT"

echo
if grep -q "KET QUA: PASS" "$OUT/simulation.log"; then
  echo "[OK] Mo phong PASS. Bang chung: $OUT/simulation.log"
  echo "     Waveform      : $OUT/waveforms/a01_waves.vcd"
  echo "     Ma tran ca    : $OUT/tc_results.csv"
else
  echo "[LOI] Mo phong FAIL — doc $OUT/simulation.log"
  exit 1
fi
