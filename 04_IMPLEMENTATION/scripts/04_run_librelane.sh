#!/usr/bin/env bash
# =====================================================================
#  A01 · Buoc 4 — Physical design RTL→GDSII (LibreLane / OpenLane 2)
#
#  DAY LA PHAN "MO RONG" TU NGUYEN theo Charter muc 3 — KHONG phai
#  dieu kien dat. Chi chay khi moi truong da duoc xac minh.
#
#  Chay:  bash 04_IMPLEMENTATION/scripts/04_run_librelane.sh
# =====================================================================
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"
CFG="04_IMPLEMENTATION/scripts/config_librelane.json"

echo "===== KIEM TRA MOI TRUONG ====="
MISSING=0
for c in yosys openroad klayout magic netgen python3; do
  if command -v "$c" >/dev/null 2>&1; then
    printf "  %-10s OK  (%s)\n" "$c" "$(command -v $c)"
  else
    printf "  %-10s THIEU\n" "$c"
    MISSING=1
  fi
done

if python3 -c "import librelane" 2>/dev/null; then
  echo "  librelane  OK (python module)"
  RUNNER="python3 -m librelane"
elif python3 -c "import openlane" 2>/dev/null; then
  echo "  openlane2  OK (python module)"
  RUNNER="python3 -m openlane"
else
  echo "  librelane  THIEU"
  MISSING=1
fi

echo
echo "  PDK_ROOT = ${PDK_ROOT:-<chua dat>}"
if [ -z "${PDK_ROOT:-}" ] || [ ! -d "${PDK_ROOT:-/nonexistent}/sky130A" ]; then
  echo "  [CANH BAO] Chua thay PDK sky130A."
  MISSING=1
fi

if [ "$MISSING" -ne 0 ]; then
  cat <<'EOT'

=====================================================================
 CHUA DU MOI TRUONG — DUNG LAI, KHONG TAO KET QUA GIA
=====================================================================
Can day du truoc khi chay physical design:
  1. Yosys                        (tong hop)
  2. OpenROAD                     (floorplan / place / cts / route)
  3. KLayout hoac Magic           (streaming ra GDS, DRC)
  4. Netgen                       (LVS)
  5. PDK sky130A da cai (volare)  + LEF / tech LEF / Liberty
  6. LibreLane hoac OpenLane 2

Cai dat goi y (WSL Ubuntu):
  pip install librelane
  pip install volare && volare enable --pdk sky130 <commit>
  export PDK_ROOT=$HOME/.volare

Ghi nho (Charter muc 3): day la MO RONG TU NGUYEN.
Thieu buoc nay KHONG lam bai truot.
EOT
  exit 2
fi

echo
echo "===== CHAY FLOW ====="
$RUNNER "$CFG" 2>&1 | tee 06_GDSII/librelane_run.log

echo
echo "===== THU GOM BANG CHUNG ====="
RUNDIR=$(ls -dt runs/*/ 2>/dev/null | head -1 || true)
if [ -z "$RUNDIR" ]; then
  echo "[LOI] Khong tim thay thu muc runs/. Doc 06_GDSII/librelane_run.log."
  exit 1
fi
echo "Thu muc run: $RUNDIR"

copy_if () { [ -e "$1" ] && cp -r "$1" "$2" && echo "  -> $2"; }

copy_if "$RUNDIR/final/gds"                 06_GDSII/gds/
copy_if "$RUNDIR/reports/signoff"           06_GDSII/sta/
copy_if "$RUNDIR/reports/drc"               06_GDSII/drc/
copy_if "$RUNDIR/reports/lvs"               06_GDSII/lvs/
copy_if "$RUNDIR/reports/floorplan"         06_GDSII/floorplan/
copy_if "$RUNDIR/reports/placement"         06_GDSII/placement/
copy_if "$RUNDIR/reports/routing"           06_GDSII/routing/
copy_if "$RUNDIR/reports/power"             06_GDSII/power/

cat <<'EOT'

=====================================================================
 DOC KY TRUOC KHI VIET KET LUAN
=====================================================================
 "Co file GDS" CHI chung minh: mot co so du lieu GDS da duoc sinh ra.
 No KHONG tu no chung minh:
   · chuc nang dung        -> can mo phong gate-level
   · timing dat            -> can bao cao STA sau routing
   · DRC/LVS sach          -> can doc chinh bao cao DRC/LVS
   · che tao duoc          -> NGOAI PHAM VI de tai
 Xem 07_TRACEABILITY/limitations.md.
EOT
